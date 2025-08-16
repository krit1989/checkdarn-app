import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/event_model.dart';
import '../services/geocoding_service.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';
import '../services/smart_security_service.dart';
import '../services/traffic_log_service_improved.dart';
import '../utils/formatters.dart';
import '../widgets/bottom_bar.dart';
import '../widgets/category_selector_dialog.dart';
import '../widgets/location_marker.dart';
import '../widgets/event_marker.dart';
import '../widgets/location_button.dart';
import '../widgets/comment_bottom_sheet.dart';
import '../services/comment_service.dart';
import '../generated/gen_l10n/app_localizations.dart';
import 'settings_screen.dart';

// High-Performance LRU Cache สำหรับ Markers
class MarkerLRUCache {
  final int maxSize;
  final Map<String, Marker> _cache = <String, Marker>{};
  final List<String> _accessOrder = <String>[];

  MarkerLRUCache({this.maxSize = 200}); // เพิ่มจาก 100 เป็น 200

  Marker? get(String key) {
    if (_cache.containsKey(key)) {
      // Move to end (most recently used)
      _accessOrder.remove(key);
      _accessOrder.add(key);
      return _cache[key];
    }
    return null;
  }

  void put(String key, Marker marker) {
    if (_cache.containsKey(key)) {
      // Update existing
      _accessOrder.remove(key);
    } else if (_cache.length >= maxSize) {
      // Remove least recently used
      final lru = _accessOrder.removeAt(0);
      _cache.remove(lru);
    }

    _cache[key] = marker;
    _accessOrder.add(key);
  }

  void clear() {
    _cache.clear();
    _accessOrder.clear();
  }

  int get length => _cache.length;
  bool get isEmpty => _cache.isEmpty;
}

// Performance Throttler สำหรับลดการทำงานบ่อยเกินไป
class PerformanceThrottler {
  final Duration duration;
  Timer? _timer;
  VoidCallback? _callback;

  PerformanceThrottler({required this.duration});

  void run(VoidCallback callback) {
    _callback = callback;
    _timer?.cancel();
    _timer = Timer(duration, () {
      _callback?.call();
      _callback = null;
    });
  }

  void dispose() {
    _timer?.cancel();
    _callback = null;
  }
}

// Enum สำหรับประเภท Navigation Bar
enum NavigationBarType {
  hasNavigationBar, // มี Navigation Bar แบบดั้งเดิม (Samsung, OnePlus)
  gestureOnly, // ใช้ Gesture เท่านั้น (iPhone X+, Android gesture)
  fallback, // โหมดสำรองสำหรับอุปกรณ์ที่ไม่แน่ใจ
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  LatLng? currentPosition =
      _defaultPosition; // เริ่มต้นด้วย Bangkok แล้วค่อยอัปเดตเป็นตำแหน่งจริง
  late MapController mapController;
  double searchRadius = 20.0; // ลดเป็น 20 km เพื่อประหยัด Firebase reads
  LocationInfo? currentLocationInfo; // ข้อมูลที่อยู่ปัจจุบัน
  bool isLoadingLocation = false; // ไม่แสดง loading แล้ว ให้แสดงแผนที่เลย
  bool isLoadingMyLocation = false; // Loading state แยกสำหรับปุ่ม My Location
  double loadingProgress = 0.0; // Progress bar สำหรับหน้าโหลด
  Timer? _progressTimer; // Timer สำหรับ progress bar
  Timer? _realtimeTimer; // Timer สำหรับปรับปรุงหมุดแบบเรียลไทม์
  bool _isUserLoggedIn = false; // สถานะการล็อกอิน
  late AnimationController
      _mapAnimationController; // Animation controller สำหรับแผนที่
  double _currentZoom = 15.0; // เก็บ zoom level ปัจจุบัน

  // ตำแหน่งเริ่มต้นสำรอง (กรุงเทพฯ) ใช้เมื่อหาตำแหน่งจริงไม่ได้
  static const LatLng _defaultPosition = LatLng(13.7563, 100.5018);

  // High-Performance Caching System - แทนที่ระบบเก่า
  late final MarkerLRUCache _optimizedMarkerCache;
  late final PerformanceThrottler _locationThrottler;
  late final PerformanceThrottler _markerUpdateThrottler;

  // Simplified Cache Variables
  List<DocumentSnapshot> _cachedDocuments = [];
  List<Marker> _optimizedMarkers = []; // ใช้แทน _cachedMarkers
  DateTime? _lastFirebaseUpdate;
  double _lastCachedZoom = 0.0;
  LatLng? _lastCachedPosition;
  double _lastCachedRadius = 0.0;

  // Performance Control Flags
  bool _isUpdatingMarkers = false;
  bool _isPanning = false; // เพิ่มเพื่อตรวจสอบการ pan

  // Smart Button Position Cache
  double? _cachedButtonPosition;
  double? _lastScreenHeight;
  double? _lastBottomPadding;

  // Optimized performance constants
  static const Duration _cacheValidDuration =
      Duration(minutes: 10); // ลดลงเพื่อ freshness
  static const double _clusterZoomThreshold = 14.0; // ปรับให้เหมาะสม
  static const double _clusterDistanceKm = 1.5; // ลดระยะ cluster
  static const Duration _throttleDuration =
      Duration(milliseconds: 300); // สำหรับ throttling

  List<EventCategory> selectedCategories = EventCategory.values.toList();

  @override
  void initState() {
    super.initState();

    // Initialize high-performance caching system
    _optimizedMarkerCache = MarkerLRUCache(maxSize: 200);
    _locationThrottler = PerformanceThrottler(duration: _throttleDuration);
    _markerUpdateThrottler = PerformanceThrottler(duration: _throttleDuration);

    // เริ่มต้น Traffic Log Service สำหรับปฏิบัติตาม พ.ร.บ.คอมพิวเตอร์ 2560
    ImprovedTrafficLogService.initialize();

    // เริ่มต้น MapController และ Animation อย่างเดียวก่อน
    mapController = MapController();
    _mapAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300), // ลดเวลา animation
      vsync: this,
    );

    selectedCategories = EventCategory.values.toList();

    // ตั้งค่า System UI ทันทีเมื่อ init เพื่อป้องกัน Status Bar สีดำ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setLoadingScreenNavigationBar();

      // เลื่อนงานหนักไปทำหลัง frame แรกเสร็จ - ใช้ throttler
      _locationThrottler.run(() {
        if (mounted) {
          _initializeHeavyServices();
        }
      });
    });

    // เพิ่ม observer สำหรับ app lifecycle
    WidgetsBinding.instance.addObserver(this);

    // Listen for map events ด้วย throttling
    mapController.mapEventStream.listen((event) {
      if (event is MapEventMoveEnd) {
        _isPanning = false; // รีเซ็ต panning flag
        _markerUpdateThrottler.run(() {
          if (mounted) {
            _handleMapUpdate();
          }
        });
      } else if (event is MapEventMove) {
        _isPanning = true; // ตั้ง panning flag
      }
    });
  }

  // Optimized map update handler - แทนที่ _debouncedMapUpdate
  void _handleMapUpdate() {
    _currentZoom = mapController.camera.zoom;

    // อัปเดต state เฉพาะเมื่อจำเป็น
    if (mounted && !_isUpdatingMarkers) {
      setState(() {});
    }
  }

  // แยกงานหนักออกมาเป็น method แยก
  Future<void> _initializeHeavyServices() async {
    try {
      // เพิ่มการตั้งค่าสำรองด้วย Future.delayed
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

      // ตรวจสอบและจัดการ Navigation Bar อัจฉริยะ
      _initializeSmartNavigationBarControl();

      // เริ่มต้น Smart Security Service สำหรับ Map Screen (MEDIUM RISK)
      _initializeSmartSecurity();

      // เริ่ม progress timer สำหรับหน้าโหลด
      _startProgressTimer();

      // หาตำแหน่งจริงทันทีก่อน - สำคัญที่สุด
      if (kDebugMode) {
        debugPrint(
            '🚀 MapScreen initState: Starting location detection immediately...');
      }
      _getCurrentLocationImmediately();

      // ตรวจสอบสถานะ Location สำหรับการ debug
      if (kDebugMode) {
        _checkLocationStatus();
      }

      // เลื่อนส่วนอื่นๆ ไปทำหลัง location เจอแล้ว (เพิ่ม delay)
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          _initializeOtherServices();
        }
      });

      // 🌐 เริ่มระบบตรวจสอบ Internet Connection
      _initializeNetworkMonitoring();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error initializing heavy services: $e');
      }
    }
  }

  // ==================== SMART SECURITY SYSTEM ====================

  /// เริ่มระบบ Smart Security สำหรับ Map Screen (MEDIUM RISK)
  void _initializeSmartSecurity() {
    SmartSecurityService.initialize();
    SmartSecurityService.setSecurityLevel(SecurityLevel.medium);
    print('🔒 Smart Security initialized for Map Screen (MEDIUM RISK)');
  }

  // ==================== NETWORK MONITORING SYSTEM ====================

  /// เริ่มระบบตรวจสอบ Internet Connection
  void _initializeNetworkMonitoring() {
    try {
      // ใช้ Connectivity package ตรวจสอบสถานะ network
      // เริ่มฟัง network changes
      _startNetworkListener();

      if (kDebugMode) {
        debugPrint('🌐 Network monitoring initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Network monitoring initialization failed: $e');
      }
    }
  }

  /// ฟังการเปลี่ยนแปลงสถานะ Internet
  void _startNetworkListener() {
    // จะตรวจสอบทุก 30 วินาที และเมื่อ app resume
    Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _checkNetworkAndSyncTopics();
      } else {
        timer.cancel();
      }
    });
  }

  /// ตรวจสอบ Network และ Sync Topics ถ้าจำเป็น
  Future<void> _checkNetworkAndSyncTopics() async {
    try {
      // ตรวจสอบว่ามี internet หรือไม่โดยการ ping Firebase
      final hasInternet = await _checkInternetConnection();

      // ไม่ต้องอัพเดต UI state แล้ว - ทำงานในเบื้องหลังเท่านั้น

      if (hasInternet) {
        // ถ้ามี internet ให้ตรวจสอบว่า Topic subscriptions ยังใช้งานได้หรือไม่
        await _syncTopicsIfNeeded();

        if (kDebugMode) {
          debugPrint('🌐 Internet available - topics synced');
        }
      } else {
        if (kDebugMode) {
          debugPrint('📴 No internet - using cached data');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Network check failed: $e');
      }
    }
  }

  /// ตรวจสอบการเชื่อมต่อ Internet จริง
  Future<bool> _checkInternetConnection() async {
    try {
      // ลองเชื่อมต่อ Firebase แบบสั้นๆ
      await FirebaseFirestore.instance
          .collection('test_connection')
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 5));

      return true; // ถ้าเชื่อมต่อได้แสดงว่ามี internet
    } catch (e) {
      return false; // ถ้าเชื่อมต่อไม่ได้แสดงว่าไม่มี internet
    }
  }

  /// Sync Topics ถ้าจำเป็น
  Future<void> _syncTopicsIfNeeded() async {
    try {
      // ตรวจสอบว่า topic subscriptions ล่าสุดหรือยัง
      final prefs = await SharedPreferences.getInstance();
      final lastSync = prefs.getInt('last_topic_sync') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      // ถ้าผ่านมานานกว่า 6 ชั่วโมงให้ sync ใหม่
      if (now - lastSync > 21600000) {
        // 6 hours
        if (currentPosition != null) {
          // ใช้ TopicSubscriptionService ถ้ามี
          if (kDebugMode) {
            debugPrint('🔄 Auto-syncing topics after 6 hours');
          }

          // บันทึกเวลา sync
          await prefs.setInt('last_topic_sync', now);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Topic sync failed: $e');
      }
    }
  }

  // ==================== LOCATION PERMISSION SYSTEM ====================

  /// ตรวจสอบและจัดการ Location Permission อย่างฉลาด
  Future<void> _checkLocationPermissionStatus() async {
    try {
      final permission = await Geolocator.checkPermission();
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      String status = 'unknown';

      if (!serviceEnabled) {
        status = 'service_disabled';
      } else if (permission == LocationPermission.denied) {
        status = 'denied';
      } else if (permission == LocationPermission.deniedForever) {
        status = 'denied_forever';
      } else if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        status = 'granted';
      }

      // ไม่ต้องอัพเดต UI state แล้ว - ทำงานในเบื้องหลังเท่านั้น

      if (kDebugMode) {
        debugPrint('📍 Location permission status: $status');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error checking location permission: $e');
      }
    }
  }

  /// แสดง Dialog อธิบายเหตุผลการขอ Location Permission (ปรับปรุงให้ไม่กรอบการ์ด)

  /// แสดง Dialog แนะนำให้ไปตั้งค่า Permission ใน Settings (ปรับปรุงให้ไม่กรอบการ์ด)
  Future<void> _showLocationSettingsDialog() async {
    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 300, // จำกัดความกว้างสูงสุด
            maxHeight: 420, // จำกัดความสูงสูงสุด
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                const Row(
                  children: [
                    Icon(Icons.settings, color: Colors.red, size: 22),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '⚙️ เปิด Location Permission',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Content
                const Text(
                  'กรุณาเปิด Location Permission ในการตั้งค่า:',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
                const Text(
                  '📱 Settings > Privacy & Security > Location Services',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '🔍 หา "CheckDarn" และเปิดการใช้งาน',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F9FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '💡 หรือใช้การเลือกจังหวัดด้วยตนเองแทน',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF0369A1),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(color: Colors.grey),
                          ),
                        ),
                        child: const Text(
                          'เลือกจังหวัดเอง',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Geolocator.openAppSettings();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4673E5),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'เปิด Settings',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// แสดง Dialog เลือกจังหวัดด้วยตนเอง (Fallback)
  Future<void> _showManualLocationSelector() async {
    if (!mounted) return;

    const provinces = [
      'กรุงเทพมหานคร',
      'นนทบุรี',
      'ปทุมธานี',
      'สมุทรปราการ',
      'สมุทรสาคร',
      'เชียงใหม่',
      'เชียงราย',
      'ลำพูน',
      'ลำปาง',
      'แพร่',
      'ขอนแก่น',
      'นครราชสีมา',
      'อุดรธานี',
      'อุบลราชธานี',
      'สกลนคร',
      'ชลบุรี',
      'ระยอง',
      'จันทบุรี',
      'ตราด',
      'ฉะเชิงเทรา',
      'สงขลา',
      'ภูเก็ต',
      'กระบี่',
      'สุราษฎร์ธานี',
      'นครศรีธรรมราช',
    ];

    String? selectedProvince;

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 280, // จำกัดความกว้างสูงสุด
            maxHeight: 500, // จำกัดความสูงสูงสุด
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFF4673E5),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '📍 เลือกจังหวัดของคุณ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // List
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: provinces.length,
                  itemBuilder: (context, index) {
                    final province = provinces[index];
                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 2),
                      title: Text(
                        province,
                        style: const TextStyle(fontSize: 14),
                      ),
                      onTap: () {
                        selectedProvince = province;
                        Navigator.of(context).pop();
                      },
                    );
                  },
                ),
              ),

              // Actions
              Container(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: Colors.grey),
                      ),
                    ),
                    child: const Text(
                      'ยกเลิก',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (selectedProvince != null) {
      await _useManualLocationSelection(selectedProvince!);
    }
  }

  /// ใช้การเลือกจังหวัดด้วยตนเอง
  Future<void> _useManualLocationSelection(String province) async {
    try {
      // บันทึกการเลือกจังหวัด
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('manual_selected_province', province);
      await prefs.setInt(
          'manual_location_timestamp', DateTime.now().millisecondsSinceEpoch);

      // ใช้พิกัดจุดกลางของจังหวัดที่เลือก
      final provinceCoords = _getProvinceCoordinates(province);
      if (provinceCoords != null) {
        setState(() {
          currentPosition = provinceCoords;
        });

        _smoothMoveMap(provinceCoords, 12.0);
        await _getLocationInfo(provinceCoords);

        if (kDebugMode) {
          debugPrint('📍 Using manual location: $province at $provinceCoords');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📍 ใช้ตำแหน่ง: $province'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error setting manual location: $e');
      }
    }
  }

  /// ดึงพิกัดจุดกลางของจังหวัด
  LatLng? _getProvinceCoordinates(String province) {
    const provinceCoords = {
      'กรุงเทพมหานคร': LatLng(13.7563, 100.5018),
      'นนทบุรี': LatLng(13.8621, 100.5144),
      'ปทุมธานี': LatLng(14.0208, 100.5250),
      'สมุทรปราการ': LatLng(13.5990, 100.5998),
      'สมุทรสาคร': LatLng(13.5476, 100.2740),
      'เชียงใหม่': LatLng(18.7883, 98.9853),
      'เชียงราย': LatLng(19.9105, 99.8407),
      'ลำพูน': LatLng(18.5745, 99.0096),
      'ลำปาง': LatLng(18.2932, 99.4956),
      'ขอนแก่น': LatLng(16.4419, 102.8360),
      'นครราชสีมา': LatLng(14.9799, 102.0977),
      'อุดรธานี': LatLng(17.4138, 102.7859),
      'ชลบุรี': LatLng(13.3611, 100.9847),
      'ระยอง': LatLng(12.6810, 101.2758),
      'จันทบุรี': LatLng(12.6103, 102.1038),
      'สงขลา': LatLng(7.1756, 100.6114),
      'ภูเก็ต': LatLng(7.8804, 98.3923),
      'กระบี่': LatLng(8.0863, 98.9063),
      'สุราษฎร์ธานี': LatLng(9.1382, 99.3215),
    };

    return provinceCoords[province];
  }

  /// ตรวจสอบการทำงานด้วย Smart Security Service
  bool _validateMapAction(String action) {
    try {
      // ใช้ Smart Security Level เป็นเกณฑ์พื้นฐาน
      final currentLevel = SmartSecurityService.getCurrentSecurityLevel();

      // ถ้าเป็น Medium Security Level (Map) ให้ตรวจสอบพื้นฐาน
      if (currentLevel == SecurityLevel.medium ||
          currentLevel == SecurityLevel.high) {
        // บันทึกการใช้งานใน Smart Security Service
        // ในอนาคตสามารถเพิ่มการตรวจสอบ rate limiting ได้ที่นี่
        if (kDebugMode) {
          print('🔒 Map action validated: $action (level: $currentLevel)');
        }
        return true;
      }

      return true;
    } catch (e) {
      print('❌ Map Security validation error: $e');
      return true; // ให้ผ่านในกรณีที่เกิดข้อผิดพลาด
    }
  }

  // ==================== NAVIGATION BAR SYSTEM ====================

  // ระบบตรวจสอบและจัดการ Navigation Bar อัจฉริยะ
  void _initializeSmartNavigationBarControl() {
    // ตรวจสอบประเภทของอุปกรณ์และ Navigation Bar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _detectAndSetupNavigationBar();
    });
  }

  // ตรวจสอบและตั้งค่า Navigation Bar ตามอุปกรณ์
  void _detectAndSetupNavigationBar() {
    try {
      // ตรวจสอบขนาดหน้าจอและ padding
      final MediaQueryData mediaQuery = MediaQuery.of(context);
      final double bottomPadding = mediaQuery.viewPadding.bottom;
      final double screenHeight = mediaQuery.size.height;
      final double screenWidth = mediaQuery.size.width;

      if (kDebugMode) {
        debugPrint('🔍 Device Analysis:');
        debugPrint('   Screen: ${screenWidth}x${screenHeight}');
        debugPrint('   Bottom Padding: $bottomPadding');
        debugPrint('   Has Navigation Bar: ${bottomPadding > 0}');
      }

      // กำหนดโหมดตามประเภทอุปกรณ์
      if (bottomPadding > 0) {
        // อุปกรณ์ที่มี Navigation Bar (เช่น Samsung, OnePlus)
        _setNavigationBarMode(NavigationBarType.hasNavigationBar);
      } else {
        // อุปกรณ์ที่ไม่มี Navigation Bar (เช่น iPhone X+, Gesture-only Android)
        _setNavigationBarMode(NavigationBarType.gestureOnly);
      }

      // ตั้งค่าเพิ่มเติมสำหรับอุปกรณ์พิเศษ
      _applyDeviceSpecificSettings(screenWidth, screenHeight, bottomPadding);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error detecting navigation bar: $e');
      }
      // ใช้การตั้งค่าเริ่มต้นที่ปลอดภัย
      _setNavigationBarMode(NavigationBarType.fallback);
    }
  }

  // กำหนดโหมด Navigation Bar
  void _setNavigationBarMode(NavigationBarType type) {
    switch (type) {
      case NavigationBarType.hasNavigationBar:
        // อุปกรณ์ที่มี Navigation Bar แบบดั้งเดิม
        SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.edgeToEdge,
          overlays: [],
        );
        SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.dark,
          systemNavigationBarDividerColor: Colors.transparent,
        ));
        if (kDebugMode) debugPrint('✅ Mode: Has Navigation Bar');
        break;

      case NavigationBarType.gestureOnly:
        // อุปกรณ์ที่ใช้ Gesture navigation เท่านั้น
        SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.edgeToEdge,
          overlays: [],
        );
        SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.dark,
          systemNavigationBarDividerColor: Colors.transparent,
        ));
        if (kDebugMode) debugPrint('✅ Mode: Gesture Only');
        break;

      case NavigationBarType.fallback:
        // โหมดสำรองสำหรับอุปกรณ์ที่ไม่แน่ใจ
        SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.immersiveSticky,
        );
        SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.dark,
          systemNavigationBarDividerColor: Colors.transparent,
        ));
        if (kDebugMode) debugPrint('✅ Mode: Fallback (Immersive)');
        break;
    }
  }

  // ตั้งค่าเพิ่มเติมสำหรับอุปกรณ์เฉพาะ
  void _applyDeviceSpecificSettings(
      double width, double height, double bottomPadding) {
    // ตรวจสอบอัตราส่วนหน้าจอ
    final double aspectRatio = height / width;

    if (kDebugMode) {
      debugPrint('📱 Device Specific Settings:');
      debugPrint('   Aspect Ratio: ${aspectRatio.toStringAsFixed(2)}');
    }

    // Samsung Galaxy series (มักมี Navigation Bar)
    if (bottomPadding > 20 && aspectRatio > 2.0) {
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false,
      ));
      if (kDebugMode) debugPrint('🔧 Applied Samsung-specific settings');
    }

    // OnePlus/Oppo series (Navigation Bar แบบ customizable)
    else if (bottomPadding > 15 && bottomPadding < 25) {
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false,
      ));
      if (kDebugMode) debugPrint('🔧 Applied OnePlus/Oppo-specific settings');
    }

    // Xiaomi series (MIUI customizations)
    else if (bottomPadding > 10 && width > 400) {
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
      ));
      if (kDebugMode) debugPrint('🔧 Applied Xiaomi-specific settings');
    }

    // iPhone-like devices (Gesture only)
    else if (bottomPadding == 0 && aspectRatio > 2.0) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      if (kDebugMode) debugPrint('🔧 Applied iPhone-like settings');
    }
  }

  // ตั้งค่า Navigation Bar สำหรับหน้า Loading
  void _setLoadingScreenNavigationBar() {
    try {
      // ใช้ edgeToEdge แทน immersiveSticky เพื่อความเสถียร
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.edgeToEdge,
        overlays: [],
      );
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark, // เปลี่ยนตามพื้นหลังสีเหลือง
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false,
      ));

      if (kDebugMode) debugPrint('🚀 Loading screen: System UI configured');
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Error setting loading screen: $e');
    }
  } // คืนค่า Navigation Bar เมื่อเข้าหน้าแผนที่

  void _restoreMainScreenNavigationBar() {
    try {
      final MediaQueryData mediaQuery = MediaQuery.of(context);
      final double bottomPadding = mediaQuery.viewPadding.bottom;

      if (bottomPadding > 0) {
        // มี Navigation Bar - ให้แสดงสีขาว
        SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.edgeToEdge,
          overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
        );

        SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.white, // สีขาว
          systemNavigationBarIconBrightness: Brightness.dark,
          systemNavigationBarDividerColor: Colors.grey, // เส้นแบ่งสีเทาอ่อน
          systemNavigationBarContrastEnforced: true, // เพิ่ม contrast
        ));
      } else {
        // ไม่มี Navigation Bar (gesture navigation) - ใช้ edgeToEdge
        SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.edgeToEdge,
          overlays: [SystemUiOverlay.top],
        );

        SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.transparent, // โปร่งใสสำหรับ gesture
          systemNavigationBarIconBrightness: Brightness.dark,
          systemNavigationBarDividerColor: Colors.transparent,
          systemNavigationBarContrastEnforced: false,
        ));
      }

      if (kDebugMode)
        debugPrint(
            '🔄 Main screen: Navigation restored (hasNavBar: ${bottomPadding > 0})');
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Error restoring navigation: $e');
    }
  }

  // Optimized map movement handler with throttling
  void _handleMapMove() {
    // ใช้ throttler แทน Timer แบบเก่า
    _markerUpdateThrottler.run(() {
      if (mounted && !_isPanning && !_isUpdatingMarkers) {
        _loadDataForVisibleArea();
      }
    });
  }

  // Load data for visible area only
  void _loadDataForVisibleArea() {
    final bounds = mapController.camera.visibleBounds;
    final center = bounds.center;
    final radius = _calculateVisibleRadius(bounds);

    print(
        '📍 Loading data for visible area: center=${center}, radius=${radius}km');

    // ไม่อัปเดต currentPosition - ปล่อยให้อยู่ที่เดิม
    // เพื่อไม่ให้ตำแหน่งหมุดเปลี่ยน
    setState(() {});
  }

  // Calculate visible radius from map bounds
  double _calculateVisibleRadius(LatLngBounds bounds) {
    final center = bounds.center;
    final corner = LatLng(bounds.north, bounds.east);
    final distance = _calculateDistanceInKm(
      center.latitude,
      center.longitude,
      corner.latitude,
      corner.longitude,
    );
    return distance.clamp(1.0, searchRadius); // Min 1km, Max search radius
  }

  // Calculate distance between two points in kilometers
  double _calculateDistanceInKm(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth radius in kilometers

    final double dLat = (lat2 - lat1) * (math.pi / 180);
    final double dLon = (lon2 - lon1) * (math.pi / 180);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * (math.pi / 180)) *
            math.cos(lat2 * (math.pi / 180)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  // ฟังก์ชันคำนวณตำแหน่งปุ่มให้ฉลาดตาม Navigation Bar และ Bottom Bar (ปรับปรุง performance)
  double _calculateSmartButtonPosition(double basePosition) {
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // ตรวจสอบ cache - ถ้าขนาดหน้าจอไม่เปลี่ยน ใช้ค่าเก่า
    if (_cachedButtonPosition != null &&
        _lastScreenHeight == screenHeight &&
        _lastBottomPadding == bottomPadding) {
      return _cachedButtonPosition!;
    }

    // คำนวณความสูงของ Bottom Bar (ประมาณ 90px + bottom padding)
    final bottomBarHeight = 90.0 + bottomPadding;

    // ตรวจสอบขนาดหน้าจอและ Navigation Bar
    final aspectRatio = screenHeight / screenWidth;

    // แสดง debug ข้อมูลเฉพาะครั้งแรกหรือเมื่อขนาดเปลี่ยน
    if (_cachedButtonPosition == null && kDebugMode) {
      debugPrint('🎯 Smart Button Position Calculation:');
      debugPrint('   - Base position: $basePosition');
      debugPrint('   - Bottom padding: $bottomPadding');
      debugPrint('   - Screen size: ${screenWidth}x$screenHeight');
      debugPrint('   - Aspect ratio: $aspectRatio');
      debugPrint('   - Bottom bar height: $bottomBarHeight');
    }

    double adjustedPosition;

    // กรณีมี Navigation Bar ชัดเจน (bottom padding > 20)
    if (bottomPadding > 20) {
      adjustedPosition =
          basePosition + bottomBarHeight + 20; // เพิ่มระยะห่างพิเศษ 20px
      if (_cachedButtonPosition == null && kDebugMode) {
        debugPrint('   - Device with Navigation Bar detected');
        debugPrint('   - Adjusted position: $adjustedPosition');
      }
    }
    // กรณี Navigation Bar แบบ customizable (bottom padding 10-20)
    else if (bottomPadding >= 10 && bottomPadding <= 20) {
      adjustedPosition =
          basePosition + bottomBarHeight + 15; // เพิ่มระยะห่างปานกลาง 15px
      if (_cachedButtonPosition == null && kDebugMode) {
        debugPrint('   - Device with customizable Navigation Bar detected');
        debugPrint('   - Adjusted position: $adjustedPosition');
      }
    }
    // กรณีหน้าจอยาว (iPhone-like) แต่ไม่มี Navigation Bar
    else if (aspectRatio > 2.0 && bottomPadding < 10) {
      adjustedPosition =
          basePosition + bottomBarHeight + 10; // เพิ่มระยะห่างเล็กน้อย 10px
      if (_cachedButtonPosition == null && kDebugMode) {
        debugPrint('   - Tall screen without Navigation Bar detected');
        debugPrint('   - Adjusted position: $adjustedPosition');
      }
    }
    // กรณีปกติ (ไม่มี Navigation Bar หรือ gesture only)
    else {
      adjustedPosition =
          basePosition + bottomBarHeight + 5; // เพิ่มระยะห่างขั้นต่ำ 5px
      if (_cachedButtonPosition == null && kDebugMode) {
        debugPrint('   - Standard device detected');
        debugPrint('   - Adjusted position: $adjustedPosition');
      }
    }

    // บันทึก cache
    _cachedButtonPosition = adjustedPosition;
    _lastScreenHeight = screenHeight;
    _lastBottomPadding = bottomPadding;

    return adjustedPosition;
  }

  // เริ่มต้น progress timer สำหรับหน้าโหลด
  void _startProgressTimer() {
    _progressTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      setState(() {
        loadingProgress += 0.02; // เพิ่ม 2% ทุก 50ms = 100% ใน 2.5 วินาที
        if (loadingProgress >= 1.0) {
          loadingProgress = 1.0;
          timer.cancel();
        }
      });
    });
  }

  // เลื่อนการ initialize services อื่นๆ มาทำหลัง
  Future<void> _initializeOtherServices() async {
    _loadSavedSettings();
    _startRealtimeUpdates();
    _checkLoginStatus();
  }

  @override
  void dispose() {
    // ลบ observer
    WidgetsBinding.instance.removeObserver(this);

    // คืนค่า System UI เป็นปกติสำหรับแอปอื่น
    try {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.edgeToEdge,
        overlays: SystemUiOverlay.values,
      );
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarContrastEnforced: true, // คืนค่าเป็น default
      ));

      if (kDebugMode) debugPrint('🔄 System UI restored for other apps');
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Error restoring system UI: $e');
    }

    _realtimeTimer?.cancel(); // ยกเลิก Timer เมื่อหน้าจอปิด
    _progressTimer?.cancel(); // ยกเลิก progress timer

    // Dispose throttlers
    _locationThrottler.dispose();
    _markerUpdateThrottler.dispose();

    _mapAnimationController.dispose(); // Dispose animation controller
    mapController.dispose(); // Dispose mapController

    // เคลียร์ performance caches - ใช้ตัวแปรใหม่
    _cachedDocuments.clear();
    _optimizedMarkers.clear();
    _optimizedMarkerCache.clear();

    // Cleanup Smart Security tracking
    print('🔒 Smart Security cleanup for Map Screen');

    // เคลียร์ image cache เพื่อจัดการ memory
    WidgetsBinding.instance.addPostFrameCallback((_) {
      imageCache.clear();
    });

    super.dispose();
  }

  // ตรวจสอบ app lifecycle เพื่อ refresh markers เมื่อกลับมาจากหน้าอื่น
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Log app lifecycle สำหรับ Traffic Log
    if (state == AppLifecycleState.resumed) {
      ImprovedTrafficLogService.logActivity(
          ImprovedTrafficLogService.actionAppResume);
    }

    if (state == AppLifecycleState.resumed && mounted) {
      // เมื่อ app resume (กลับจากหน้าอื่น) ให้ตรวจสอบว่ามีโพสใหม่ไหม
      Future.delayed(const Duration(milliseconds: 500), () async {
        if (mounted) {
          try {
            final prefs = await SharedPreferences.getInstance();
            final hasNewPost = prefs.getBool('has_new_post') ?? false;

            if (hasNewPost) {
              // เคลียร์ flag
              await prefs.setBool('has_new_post', false);
              if (kDebugMode) {
                debugPrint('🆕 New post detected - invalidating cache');
              }
            } else {
              if (kDebugMode) {
                debugPrint('🔄 App resumed - normal cache invalidation');
              }
            }

            // Invalidate cache ในทุกกรณี
            _invalidateMarkersCache();
          } catch (e) {
            if (kDebugMode) {
              debugPrint('Error checking new post flag: $e');
            }
            // ถ้า error ก็ refresh ปกติ
            _invalidateMarkersCache();
          }
        }
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // ตรวจจับเมื่อกลับมาหน้า MapScreen จาก navigation
    final route = ModalRoute.of(context);
    if (route != null && route.isCurrent && mounted) {
      // ตรวจสอบ flag เมื่อกลับมาหน้านี้
      Future.delayed(const Duration(milliseconds: 300), () async {
        if (mounted) {
          try {
            final prefs = await SharedPreferences.getInstance();
            final hasNewPost = prefs.getBool('has_new_post') ?? false;

            if (hasNewPost) {
              // เคลียร์ flag
              await prefs.setBool('has_new_post', false);
              if (kDebugMode) {
                debugPrint(
                    '🔄 Returned to MapScreen - new post detected, refreshing...');
              }
              _invalidateMarkersCache();
            }
          } catch (e) {
            if (kDebugMode) {
              debugPrint(
                  'Error checking new post flag in didChangeDependencies: $e');
            }
          }
        }
      });
    }
  }

  // ฟังก์ชันโหลดการตั้งค่าที่บันทึกไว้
  Future<void> _loadSavedSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        searchRadius = prefs.getDouble('search_radius') ??
            20.0; // เปลี่ยนเป็น 20 km เพื่อประหยัด Firebase
      });
      print('Loaded search radius: $searchRadius km');
      if (kDebugMode) {
        debugPrint('Loaded search radius: $searchRadius km');
      }
    } catch (e) {
      print('Error loading saved settings: $e');
      if (kDebugMode) {
        debugPrint('Error loading saved settings: $e');
      }
    }
  }

  // ฟังก์ชันบันทึกการตั้งค่า
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('search_radius', searchRadius);

      // Clear cache เมื่อรัศมีเปลี่ยน เพื่อให้ markers อัปเดตทันที
      _invalidateMarkersCache();

      print('Saved search radius: $searchRadius km');
      if (kDebugMode) {
        debugPrint('Saved search radius: $searchRadius km - cache invalidated');
      }
    } catch (e) {
      print('Error saving settings: $e');
      if (kDebugMode) {
        debugPrint('Error saving settings: $e');
      }
    }
  }

  // ฟังก์ชัน clear cache เพื่อให้ markers อัปเดตแบบเรียลไทม์ (Optimized)
  void _invalidateMarkersCache({bool force = false}) {
    // ใช้ throttler แทนการเช็คเวลาเอง
    if (!force) {
      _markerUpdateThrottler.run(() => _performCacheInvalidation());
    } else {
      _performCacheInvalidation();
    }
  }

  void _performCacheInvalidation() {
    setState(() {
      _cachedDocuments.clear();
      _optimizedMarkers.clear();
      _optimizedMarkerCache.clear();
      _lastFirebaseUpdate = null;
      _lastCachedPosition = null;
      _lastCachedZoom = 0.0;
      _lastCachedRadius = 0.0;

      // รีเซ็ต button position cache ด้วย
      _cachedButtonPosition = null;
      _lastScreenHeight = null;
      _lastBottomPadding = null;
    });

    if (kDebugMode) {
      debugPrint(
          '🗑️ Optimized cache invalidated - will rebuild on next frame');
    }
  }

  // ฟังก์ชันเริ่มการปรับปรุงหมุดแบบเรียลไทม์
  void _startRealtimeUpdates() {
    // ปิดการใช้งาน Timer เพราะ StreamBuilder จัดการ real-time updates อยู่แล้ว
    // _realtimeTimer?.cancel();
    // _realtimeTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
    //   if (mounted) {
    //     print('Debug: Refreshing markers...');
    //   }
    // });
    print('Debug: StreamBuilder handles real-time updates automatically');
    if (kDebugMode) {
      debugPrint(
          'Debug: StreamBuilder handles real-time updates automatically');
    }
  }

  // ฟังก์ชันตรวจสอบสถานะล็อกอิน - ปรับปรุงเพื่อลด warning
  Future<void> _checkLoginStatus() async {
    try {
      // ตรวจสอบว่า AuthService ถูก initialize แล้วหรือยัง
      if (!AuthService.isInitialized) {
        if (kDebugMode) {
          debugPrint('AuthService not initialized yet, initializing...');
        }
        await AuthService.initialize(); // เริ่มต้น AuthService ถ้ายังไม่ได้ทำ
      }

      setState(() {
        _isUserLoggedIn = AuthService.isLoggedIn;
      });

      if (kDebugMode) {
        debugPrint(
            'Debug: Login status checked - isLoggedIn: $_isUserLoggedIn');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error checking login status: $e');
      }
      // ใน case ที่ error ให้ใช้ fallback
      setState(() {
        _isUserLoggedIn = false;
      });
    }
  }

  // Helper method สำหรับตรวจสอบ login status อย่างปลอดภัย
  bool _isUserLoggedInSafely() {
    if (!AuthService.isInitialized) {
      return false; // ถ้ายังไม่ initialize ให้ถือว่า not logged in
    }
    return AuthService.isLoggedIn;
  }

  // ฟังก์ชันหาตำแหน่งปัจจุบันทันทีใน initState
  Future<void> _getCurrentLocationImmediately() async {
    try {
      if (kDebugMode) {
        debugPrint('🔍 Starting GPS location detection...');
        debugPrint('🔧 Checking location prerequisites...');
      }

      // ตรวจสอบสถานะ Location Permission ก่อน
      await _checkLocationPermissionStatus();

      // เพิ่มเวลา timeout ให้นานขึ้น - ให้โอกาส GPS ทำงานได้สมบูรณ์
      Future.delayed(const Duration(seconds: 15), () {
        if (mounted && (currentPosition == null || isLoadingLocation)) {
          if (kDebugMode) {
            debugPrint(
                '⏰ GPS timeout after 15 seconds - using default location');
          }
          _useDefaultLocationImmediately();
        }
      });

      // ขอ permission ก่อนทำอะไรอื่น เพื่อให้ popup ขึ้นทันทีตอนเปิดแอพ
      if (kDebugMode) {
        debugPrint('🔧 Requesting location permissions first...');
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (kDebugMode) {
        debugPrint('📋 Current permission status: $permission');
      }

      // Progressive permission request with rationale
      if (permission == LocationPermission.denied) {
        if (kDebugMode) {
          debugPrint('⚠️ Requesting location permission with rationale...');
        }

        // ขอ permission ผ่านระบบ
        permission = await Geolocator.requestPermission();

        if (kDebugMode) {
          debugPrint('📋 Permission after request: $permission');
        }
      }

      // ตรวจสอบผลลัพธ์หลังจากขอ permission
      if (permission == LocationPermission.denied) {
        if (kDebugMode) {
          debugPrint('❌ Location permission DENIED by user');
        }
        await _showManualLocationSelector();
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        if (kDebugMode) {
          debugPrint('❌ Location permission PERMANENTLY DENIED');
          debugPrint('💡 Please enable location in app settings');
        }
        await _showLocationSettingsDialog();
        return;
      }

      if (kDebugMode) {
        debugPrint('✅ Location permission granted: $permission');
      }

      // ข้าม last known position และไปหา current position ใหม่เลย
      if (kDebugMode) {
        debugPrint(
            '📋 Skipping last known position - getting fresh GPS location...');
      }

      // ตรวจสอบการเปิดใช้งาน Location Services
      if (kDebugMode) {
        debugPrint('🔧 Checking if location services are enabled...');
      }
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (kDebugMode) {
          debugPrint('❌ Location services are DISABLED');
          debugPrint(
              '💡 Please enable location in device Settings > Privacy & Security > Location Services');
        }
        await _showLocationSettingsDialog();
        return;
      } else {
        if (kDebugMode) {
          debugPrint('✅ Location services are enabled');
        }
      }

      // ลองหาตำแหน่งปัจจุบัน
      if (kDebugMode) {
        debugPrint('🔍 Getting current GPS position...');
      }
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high, // เพิ่มความแม่นยำให้สูงสุด
          timeLimit:
              const Duration(seconds: 12), // เพิ่มเวลา timeout ให้นานขึ้น
        );

        if (kDebugMode) {
          debugPrint(
              '✅ GPS position acquired: ${position.latitude}, ${position.longitude}');
          debugPrint(
              '📊 Accuracy: ${position.accuracy}m, Speed: ${position.speed}m/s');
        }

        if (mounted) {
          final newPosition = LatLng(position.latitude, position.longitude);
          setState(() {
            currentPosition = newPosition;
            isLoadingLocation = false;
          });

          // รอ 100ms แล้วค่อยย้ายแผนที่ เพื่อให้ MapController พร้อม
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              _smoothMoveMap(newPosition, 15.0);
              if (kDebugMode) {
                debugPrint(
                    '🎯 Map moved to GPS location: ${newPosition.latitude}, ${newPosition.longitude}');
              }
            }
          });
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ Failed to get GPS position: $e');
        }
        _useDefaultLocationImmediately();
      }
    } catch (e) {
      _useDefaultLocationImmediately();
      if (kDebugMode) {
        debugPrint(
            '⚠️ Location initialization error: $e - using default location');
      }
    }
  }

  // ฟังก์ชันตรวจสอบสถานะ Location Services และ Permissions (สำหรับการ debug)
  Future<void> _checkLocationStatus() async {
    if (kDebugMode) {
      debugPrint('🔧 === LOCATION STATUS DIAGNOSIS ===');

      try {
        // ตรวจสอบ Location Services
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        debugPrint(
            '📡 Location Services: ${serviceEnabled ? "✅ ENABLED" : "❌ DISABLED"}');

        // ตรวจสอบ Permissions
        LocationPermission permission = await Geolocator.checkPermission();
        debugPrint('🔐 Location Permission: $permission');

        // ตรวจสอบ Last Known Position
        Position? lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          debugPrint(
              '📍 Last Known Position: ${lastKnown.latitude}, ${lastKnown.longitude}');
        } else {
          debugPrint('📍 Last Known Position: ❌ NONE');
        }

        // แนะนำการแก้ไข
        if (!serviceEnabled) {
          debugPrint('💡 FIX: Enable Location Services in device Settings');
        }
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          debugPrint('💡 FIX: Grant location permission to this app');
        }

        debugPrint('🔧 === END DIAGNOSIS ===');
      } catch (e) {
        debugPrint('❌ Error checking location status: $e');
      }
    }
  }

  // ฟังก์ชันใช้ตำแหน่งเริ่มต้นทันที
  void _useDefaultLocationImmediately() {
    if (kDebugMode) {
      debugPrint(
          '⚠️ Using fallback default location (Bangkok): $_defaultPosition');
      debugPrint('💡 Note: GPS may not be working or timed out');
      debugPrint('🔄 User can press My Location button to retry GPS detection');
    }
    setState(() {
      currentPosition = _defaultPosition;
      isLoadingLocation = false;
    });
    if (mounted) {
      _getLocationInfo(_defaultPosition);
    }
  }

  // ฟังก์ชันดึงข้อมูลที่อยู่จากพิกัด
  Future<void> _getLocationInfo(LatLng position) async {
    try {
      final locationInfo = await GeocodingService.getLocationInfo(position);
      setState(() {
        currentLocationInfo = locationInfo;
      });
    } catch (e) {
      print('Error getting location info: $e');
      if (kDebugMode) {
        debugPrint('Error getting location info: $e');
      }
    }
  }

  // ฟังก์ชันจัดการ Long Press บนแผนที่เพื่อย้ายหมุดและดูโพสในบริเวณนั้น (เฉพาะนิ้วเดียว)
  void _onMapLongPress(TapPosition tapPosition, LatLng point) async {
    // ==================== SMART SECURITY CHECK ====================

    // ตรวจสอบด้วย Smart Security Service
    if (!_validateMapAction('long_press_move_marker')) {
      print('🔒 Long press blocked by Smart Security');
      return;
    }

    // ตรวจสอบว่าเป็นการกดค้างด้วยนิ้วเดียวเท่านั้น
    if (_activePointers > 1) {
      if (kDebugMode) {
        debugPrint(
            '🚫 Long press ignored - multi-finger detected ($_activePointers fingers)');
      }
      return; // ไม่ทำอะไรถ้ากดด้วยหลายนิ้ว
    }

    if (kDebugMode) {
      debugPrint('✅ Single finger long press detected - moving to view posts');
    }

    // Log การเปลี่ยนตำแหน่งการค้นหา
    ImprovedTrafficLogService.logActivity(
      ImprovedTrafficLogService.actionUpdateLocation,
      location: {
        'lat': point.latitude,
        'lng': point.longitude,
      },
      metadata: {
        'action_type': 'long_press_move',
        'previous_lat': currentPosition?.latitude,
        'previous_lng': currentPosition?.longitude,
      },
    );

    // แสดง loading แบบสั้นๆ
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              AppLocalizations.of(context).searchingPostsInArea,
              style: const TextStyle(fontFamily: 'NotoSansThai'),
            ),
          ],
        ),
        duration: const Duration(seconds: 1),
      ),
    );

    try {
      // ดึงข้อมูลที่อยู่ของตำแหน่งใหม่
      final locationInfo = await GeocodingService.getLocationInfo(point);

      // ซ่อน loading snackbar
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // อัปเดตตำแหน่งปัจจุบันและข้อมูลตำแหน่ง
      setState(() {
        currentPosition = point;
        currentLocationInfo = locationInfo;
      });

      // ย้ายกล้องไปยังตำแหน่งใหม่
      _smoothMoveMap(point, mapController.camera.zoom);

      // ล้าง cache เพื่อให้แสดงหมุดในบริเวณใหม่
      _invalidateMarkersCache();

      // แสดงข้อความแจ้งผลลัพธ์
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).movedToViewPosts(
              locationInfo?.displayName ??
                  AppLocalizations.of(context).selectedLocation,
            ),
            style: const TextStyle(fontFamily: 'NotoSansThai'),
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      if (kDebugMode) {
        debugPrint(
            'Moved to new location: ${point.latitude}, ${point.longitude}');
        debugPrint('Address: ${locationInfo?.displayName}');
      }
    } catch (e) {
      // ซ่อน loading snackbar
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // แสดงข้อผิดพลาด
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).cannotGetLocationInfo(e.toString()),
            style: const TextStyle(fontFamily: 'NotoSansThai'),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ฟังก์ชัน smooth move แผนที่ - ย้ายกล้องไปตรงกลางจอ
  void _smoothMoveMap(LatLng target, double zoom) {
    try {
      // ใช้ move เพื่อให้ตำแหน่งอยู่ตรงกลางจอ
      mapController.move(target, zoom);
      if (kDebugMode) {
        debugPrint(
            '🗺️ Map moved successfully to: ${target.latitude}, ${target.longitude}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error moving map: $e - retrying in 500ms');
      }
      // รอแล้วลองใหม่
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          try {
            mapController.move(target, zoom);
            if (kDebugMode) {
              debugPrint(
                  '🗺️ Map moved successfully on retry to: ${target.latitude}, ${target.longitude}');
            }
          } catch (retryError) {
            if (kDebugMode) {
              debugPrint('❌ Failed to move map even on retry: $retryError');
            }
          }
        }
      });
    }
  }

  // Variables for advanced drag detection (simplified)
  Offset? _panStartPosition;
  DateTime? _panStartTime;
  int _activePointers = 0; // เพิ่มตัวแปรนับจำนวนนิ้วที่สัมผัสหน้าจอ

  // ฟังก์ชันแสดง popup เลือกหมวดหมู่
  void _showCategorySelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      isDismissible: true,
      enableDrag: true,
      useSafeArea: true,
      clipBehavior: Clip.antiAlias,
      builder: (context) => CategorySelectorDialog(
        initiallySelectedCategories: selectedCategories,
        onCategoriesSelected: (categories) {
          setState(() {
            selectedCategories = categories;
          });

          // Clear cache เมื่อหมวดหมู่เปลี่ยน เพื่อให้ markers อัปเดตทันที
          _invalidateMarkersCache();

          // Track analytics
          // trackAction('category_changes'); // ปิดการใช้งาน analytics
        },
      ),
    );
  }

  // ฟังก์ชันนำทางไปหน้า Settings
  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    ).then((_) {
      // Refresh state when returning from settings
      if (mounted) {
        setState(() {
          _isUserLoggedIn = AuthService.isLoggedIn;
        });
      }
    });
  }

  // ฟังก์ชันแสดง popup ข้อมูลเหตุการณ์แบบเต็มหน้าจอ
  void _showEventPopup(
      BuildContext context, Map<String, dynamic> data, EventCategory category) {
    // ดึงข้อมูลเหมือนใน list_screen.dart
    final imageUrl = data['imageUrl'] as String?;
    final timestamp = data['timestamp'] as Timestamp?;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true, // ใช้ root navigator สำหรับประสิทธิภาพที่ดีกว่า
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54, // เพิ่มสีพื้นหลังเมื่อแสดงป้อปอัพ
      isDismissible: true,
      enableDrag: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.98,
        snap: false, // ปิด snap เพื่อให้ลื่นต่อเนื่อง
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle bar สำหรับดึง
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 8, bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Content area
              Flexible(
                // เปลี่ยนจาก Expanded เป็น Flexible
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // แถวที่ 1: emoji + หัวข้อเหตุการณ์ + เวลา
                      Row(
                        children: [
                          Text(
                            category.emoji,
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              category.label(context),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                                fontFamily: 'NotoSansThai',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // เวลาที่ผ่านมา
                          if (timestamp != null) ...[
                            Text(
                              DateTimeFormatters.formatTimestamp(timestamp),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w400,
                                fontFamily: 'NotoSansThai',
                              ),
                            ),
                          ],
                        ],
                      ),

                      // แถวที่ 2: รายละเอียด (ถ้ามี)
                      if (data['description'] != null &&
                          data['description'].toString().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFFF9800).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFFFF9800)
                                  .withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '${data['description']}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                              height: 1.4,
                              fontFamily: 'NotoSansThai',
                            ),
                          ),
                        ),
                      ],

                      // แถวที่ 3: ตำแหน่ง/สถานที่
                      if (data['location'] != null &&
                          data['location'].toString().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Text(
                              '📍',
                              style: TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${data['location']}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w400,
                                  fontFamily: 'NotoSansThai',
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],

                      // แถวที่ 4: วันเดือนปี
                      if (timestamp != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Text(
                              '🗓️',
                              style: TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              DateTimeFormatters.formatDate(timestamp),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w400,
                                fontFamily: 'NotoSansThai',
                              ),
                            ),
                          ],
                        ),
                      ],

                      // แถวที่ 5: รูปภาพ (ถ้ามี)
                      if (imageUrl != null &&
                          imageUrl.isNotEmpty &&
                          imageUrl.trim() != '') ...[
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () {
                            // Pre-cache รูปภาพก่อนแสดงป้อปอัพ
                            if (imageUrl.isNotEmpty) {
                              precacheImage(NetworkImage(imageUrl), context);
                            }
                            // แสดงรูปภาพแบบเต็มจอ
                            showDialog(
                              context: context,
                              builder: (context) => Dialog(
                                backgroundColor: Colors.black,
                                insetPadding: EdgeInsets.zero,
                                child: Stack(
                                  children: [
                                    Center(
                                      child: InteractiveViewer(
                                        child: Image.network(
                                          imageUrl,
                                          fit: BoxFit.contain,
                                          cacheWidth:
                                              1200, // จำกัดขนาดแคชสำหรับรูปเต็มจอ
                                          cacheHeight: 800,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Center(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.broken_image,
                                                      size: 48,
                                                      color: Colors.white),
                                                  SizedBox(height: 8),
                                                  Text(
                                                      AppLocalizations.of(
                                                              context)
                                                          .cannotLoadImage,
                                                      style: TextStyle(
                                                          color: Colors.white,
                                                          fontFamily:
                                                              'NotoSansThai')),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 40,
                                      right: 20,
                                      child: IconButton(
                                        icon: const Icon(Icons.close,
                                            color: Colors.white, size: 30),
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black, // พื้นหลังสีดำสวยงาม
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxHeight: 300, // จำกัดความสูงสูงสุด
                                ),
                                child: AspectRatio(
                                  aspectRatio: 16 / 9, // กำหนดสัดส่วน 16:9
                                  child: Image.network(
                                    imageUrl,
                                    fit: BoxFit
                                        .contain, // รักษาสัดส่วนเดิมของรูป
                                    headers: const {
                                      'User-Agent': 'CheckDarn/1.0',
                                    },
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        color: Colors.grey[100],
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            value: loadingProgress
                                                        .expectedTotalBytes !=
                                                    null
                                                ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                    loadingProgress
                                                        .expectedTotalBytes!
                                                : null,
                                            valueColor:
                                                const AlwaysStoppedAnimation<
                                                    Color>(Color(0xFFFF9800)),
                                          ),
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[100],
                                        child: Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.broken_image,
                                                  size: 32, color: Colors.grey),
                                              SizedBox(height: 4),
                                              Text(
                                                  AppLocalizations.of(context)
                                                      .cannotLoadImage,
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey,
                                                      fontFamily:
                                                          'NotoSansThai')),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],

                      // แถวที่ 6: ชื่อคนโพส
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.person_outline,
                            size: 16,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _getMaskedPosterName(data),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w400,
                              fontFamily: 'NotoSansThai',
                            ),
                          ),
                        ],
                      ),

                      // เพิ่มระยะห่างก่อน Divider
                      const SizedBox(height: 8),

                      // Comment button with count display
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // ส่วนที่ไม่สามารถกดได้
                            const Spacer(),
                            // ส่วนที่กดได้ (เฉพาะไอคอนและข้อความ) - แสดงจำนวนคอมเมนต์
                            StreamBuilder<QuerySnapshot>(
                              stream: CommentService.getCommentsStream(
                                  data['id'] ?? ''),
                              builder: (context, snapshot) {
                                final commentCount = snapshot.hasData
                                    ? snapshot.data!.docs.length
                                    : 0;
                                final hasError = snapshot.hasError;
                                final isLoading = snapshot.connectionState ==
                                    ConnectionState.waiting;

                                return InkWell(
                                  onTap: () => _showCommentSheet(
                                    data['id'] ?? '',
                                    category.label(context),
                                    category.name,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.chat_bubble_outline,
                                          size: 16,
                                          color: Color(0xFFFF9800),
                                        ),
                                        const SizedBox(width: 4),
                                        if (isLoading)
                                          const SizedBox(
                                            width: 12,
                                            height: 12,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Color(0xFFFF9800)),
                                            ),
                                          )
                                        else
                                          Text(
                                            !hasError && commentCount > 0
                                                ? '${AppLocalizations.of(context).comments} ($commentCount)'
                                                : AppLocalizations.of(context)
                                                    .comments,
                                            style: const TextStyle(
                                              color: Color(0xFFFF9800),
                                              fontWeight: FontWeight.w200,
                                              fontSize: 14,
                                              fontFamily: 'NotoSansThai',
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 16), // เพิ่ม margin ขวา
                          ],
                        ),
                      ),

                      // ช่องว่างด้านล่างเพื่อไม่ให้เนื้อหาติดขอบ
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ฟังก์ชันแสดงความคิดเห็น (ปรับปรุงประสิทธิภาพ)
  void _showCommentSheet(String reportId, String title, String category) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true, // ใช้ root navigator สำหรับประสิทธิภาพที่ดีกว่า
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54, // เพิ่มสีพื้นหลังเมื่อแสดงป้อปอัพ
      builder: (context) => CommentBottomSheet(
        reportId: reportId,
        reportType: category,
      ),
    );
  }

  // ฟังก์ชันกลับไปยังตำแหน่งจริงของผู้ใช้ (ปรับปรุงประสิทธิภาพ)
  void _goToMyLocation() async {
    try {
      setState(() => isLoadingMyLocation = true); // ใช้ loading state แยก

      // Log การใช้งานปุ่ม My Location
      ImprovedTrafficLogService.logActivity(
        ImprovedTrafficLogService.actionUpdateLocation,
        metadata: {
          'action_type': 'my_location_button',
          'current_zoom': _currentZoom,
        },
      );

      if (kDebugMode) {
        debugPrint('🔍 [My Location Button] Starting location search...');
      }

      // ตรวจสอบการเชื่อมต่ออินเทอร์เน็ตก่อน
      bool hasNetwork = await _checkInternetConnection();
      if (!hasNetwork) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'ไม่มีการเชื่อมต่ออินเทอร์เน็ต กรุณาตรวจสอบการเชื่อมต่อของคุณ'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }

      // ตรวจสอบ Location Permission ก่อน
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        // ขอ permission ผ่านระบบ
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        await _showLocationSettingsDialog();
        return;
      }

      if (permission == LocationPermission.denied) {
        await _showManualLocationSelector();
        return;
      }

      // ตรวจสอบการเปิดใช้งาน Location Services ก่อน
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (kDebugMode) {
          debugPrint('❌ [My Location Button] Location services are disabled');
        }
        await _showLocationSettingsDialog();
        return;
      }

      if (kDebugMode) {
        debugPrint(
            '✅ [My Location Button] Permissions OK, getting position...');
      }

      // หาตำแหน่งจริงใหม่ด้วย GPS แบบไม่บล็อก UI
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10), // เพิ่มเวลาให้มากขึ้น
      );

      if (kDebugMode) {
        debugPrint(
            '✅ [My Location Button] Got GPS position: ${position.latitude}, ${position.longitude}');
        debugPrint('📊 [My Location Button] Accuracy: ${position.accuracy}m');
      }

      final actualPosition = LatLng(position.latitude, position.longitude);

      // อัปเดตตำแหน่งปัจจุบัน
      setState(() {
        currentPosition = actualPosition;
      });

      // ย้ายกล้องไปยังตำแหน่งใหม่เพียงครั้งเดียว
      _smoothMoveMap(actualPosition, 15.0);

      // ดึงข้อมูลที่อยู่ใหม่ในพื้นหลัง (ไม่บล็อก UI)
      _getLocationInfo(actualPosition);

      if (kDebugMode) {
        debugPrint(
            '📍 [My Location Button] Successfully updated to GPS location: $actualPosition');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [My Location Button] Error getting GPS location: $e');
      }

      // ถ้าหาตำแหน่งใหม่ไม่ได้ ให้ใช้ตำแหน่งเดิม
      if (currentPosition != null) {
        try {
          _smoothMoveMap(currentPosition!, 15.0);
        } catch (e2) {
          if (kDebugMode) {
            debugPrint(
                '❌ [My Location Button] Error moving to current position: $e2');
          }
        }
      }
    } finally {
      setState(() => isLoadingMyLocation = false); // ปิด loading state แยก
    }
  }

  // ฟังก์ชันกรองเอกสารแยกออกมาเพื่อประสิทธิภาพ - เพิ่ม caching
  List<DocumentSnapshot> _filterDocuments(List<DocumentSnapshot> docs) {
    // ตรวจสอบ cache validity ด้วยเวลา
    final currentTime = DateTime.now();
    final cacheAge = _lastFirebaseUpdate != null
        ? currentTime.difference(_lastFirebaseUpdate!)
        : Duration.zero;

    // ตรวจสอบการเปลี่ยนแปลงของรัศมี
    final radiusChanged = (_lastCachedRadius - searchRadius).abs() > 0.1;

    if (cacheAge > _cacheValidDuration || radiusChanged) {
      _cachedDocuments.clear();
      _optimizedMarkers.clear();
      _optimizedMarkerCache.clear(); // Clear LRU cache ด้วย
      _lastCachedRadius = searchRadius; // อัปเดตรัศมีที่ cache
      if (kDebugMode) {
        if (radiusChanged) {
          debugPrint(
              'Debug: � Search radius changed from $_lastCachedRadius to $searchRadius km - cache cleared');
        } else {
          debugPrint(
              'Debug: �🗑️ Cache expired, cleared after ${cacheAge.inMinutes}m ${cacheAge.inSeconds % 60}s');
        }
      }
    }

    // ตรวจสอบว่า currentPosition ไม่เป็น null ก่อน
    if (currentPosition == null) return [];

    // ถ้าข้อมูลไม่เปลี่ยนและ cache ยังใหม่ (ภายใน cache valid duration) และรัศมีไม่เปลี่ยน
    if (_lastFirebaseUpdate != null &&
        currentTime.difference(_lastFirebaseUpdate!) < _cacheValidDuration &&
        !radiusChanged &&
        _cachedDocuments.isNotEmpty &&
        _lastCachedPosition != null &&
        currentPosition != null &&
        _calculateDistanceInKm(
              _lastCachedPosition!.latitude,
              _lastCachedPosition!.longitude,
              currentPosition!.latitude,
              currentPosition!.longitude,
            ) <
            0.5) {
      // ใช้ cache ถ้าเคลื่อนที่น้อยกว่า 500 เมตร และรัศมีไม่เปลี่ยน
      if (kDebugMode) {
        debugPrint(
            'Debug: 📦 Using cached data (${_cachedDocuments.length} docs)');
      }
      return _cachedDocuments;
    }

    final now = DateTime.now();
    final twentyFourHoursAgo = now.subtract(const Duration(hours: 24));

    final filteredDocs = docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return false;

      // ตรวจสอบหมวดหมู่
      final category = data['category'] as String? ?? data['type'] as String?;
      final eventCategory = FirebaseService.getCategoryFromName(category ?? '');
      if (!selectedCategories.contains(eventCategory)) return false;

      // ตรวจสอบเวลา - ต้องไม่เกิน 24 ชั่วโมง
      DateTime? timestamp =
          DateTimeFormatters.parseTimestamp(data['timestamp']);
      if (timestamp == null || !timestamp.isAfter(twentyFourHoursAgo))
        return false;

      // ตรวจสอบพิกัด
      final lat = (data['lat'] ?? 0.0) as double;
      final lng = (data['lng'] ?? 0.0) as double;
      if (lat == 0.0 && lng == 0.0) return false;

      // ตรวจสอบระยะทาง - ใช้รัศมีปัจจุบัน
      if (currentPosition == null) return false; // ป้องกัน null

      final distance = FirebaseService.calculateDistance(
        currentPosition!.latitude,
        currentPosition!.longitude,
        lat,
        lng,
      );
      return distance <= searchRadius;
    }).toList();

    // อัปเดต cache
    _cachedDocuments = filteredDocs;
    _lastFirebaseUpdate = currentTime;
    _lastCachedPosition = currentPosition;
    _lastCachedRadius = searchRadius; // เก็บรัศมีที่ใช้ในการ cache

    if (kDebugMode) {
      debugPrint(
          'Debug: 🔄 Updated cache with ${filteredDocs.length} documents (radius: $searchRadius km)');
    }

    return filteredDocs;
  } // สร้าง markers สำหรับเหตุการณ์จาก Firebase (เฉพาะในรัศมีและไม่เกิน 24 ชั่วโมง - ทดสอบ)

  // สร้าง markers สำหรับเหตุการณ์จาก Firebase (High-Performance Version)
  List<Marker> _buildEventMarkersFromFirebase(List<DocumentSnapshot> docs) {
    // ป้องกัน concurrent updates
    if (_isUpdatingMarkers) return _optimizedMarkers;
    _isUpdatingMarkers = true;

    try {
      if (kDebugMode) {
        debugPrint('Debug: 🔥 === BUILDING OPTIMIZED MARKERS ===');
        debugPrint('Debug: 🔥 Total docs = ${docs.length}');
        debugPrint('Debug: 🔥 Current position = $currentPosition');
        debugPrint('Debug: 🔥 Search radius = $searchRadius km');
        debugPrint('Debug: 🔥 Current zoom = $_currentZoom');
      }

      final filteredDocs = _filterDocuments(docs);

      // Log การดูรายงานเพื่อปฏิบัติตาม พ.ร.บ.คอมพิวเตอร์ 2560
      if (currentPosition != null) {
        ImprovedTrafficLogService.logViewReports(
          location: {
            'lat': currentPosition!.latitude,
            'lng': currentPosition!.longitude,
          },
          searchRadius: searchRadius,
          resultCount: filteredDocs.length,
        );
      }

      // Smart caching with LRU
      final zoomDiff = (_currentZoom - _lastCachedZoom).abs();
      final cacheValid = zoomDiff < 0.5 && _optimizedMarkers.isNotEmpty;

      // ใช้ clustering สำหรับ zoom level ต่ำ (Optimized)
      if (_currentZoom < _clusterZoomThreshold && filteredDocs.length > 5) {
        // ลดจาก 10 เป็น 5
        if (cacheValid && _optimizedMarkers.isNotEmpty) {
          if (kDebugMode) {
            debugPrint(
                'Debug: 🚀 Using cached clustered markers (${_optimizedMarkers.length})');
          }
          return _optimizedMarkers;
        }

        final clusteredMarkers = _buildOptimizedClusteredMarkers(filteredDocs);
        _optimizedMarkers = clusteredMarkers;
        _lastCachedZoom = _currentZoom;

        if (kDebugMode) {
          debugPrint(
              'Debug: 🎯 Built ${clusteredMarkers.length} optimized clustered markers from ${filteredDocs.length} docs');
        }

        return clusteredMarkers;
      }

      // Individual markers for high zoom levels (Optimized)
      if (cacheValid && filteredDocs.length <= _optimizedMarkers.length + 3) {
        // ลดจาก 5 เป็น 3
        if (kDebugMode) {
          debugPrint(
              'Debug: 🚀 Using cached individual markers (${_optimizedMarkers.length})');
        }
        return _optimizedMarkers;
      }

      if (kDebugMode) {
        debugPrint('Debug: Filtered docs count = ${filteredDocs.length}');
        if (filteredDocs.isEmpty) {
          debugPrint('Debug: ⚠️  No fresh markers found!');
          _optimizedMarkers = [];
          return [];
        } else {
          debugPrint('Debug: ✅ Found ${filteredDocs.length} fresh events');
        }
      }

      // สร้าง markers ใหม่ด้วย LRU cache
      final markers = <Marker>[];

      for (final doc in filteredDocs) {
        final data = doc.data() as Map<String, dynamic>;
        final docId = doc.id;

        // ตรวจสอบ LRU cache ก่อน
        final cachedMarker = _optimizedMarkerCache.get(docId);
        if (cachedMarker != null) {
          markers.add(cachedMarker);
          continue;
        }

        // สร้าง marker ใหม่ (เฉพาะเมื่อไม่มีใน cache)
        final category =
            data['category'] as String? ?? data['type'] as String? ?? '';
        final eventCategory = FirebaseService.getCategoryFromName(category);
        final lat = (data['lat'] ?? 0.0) as double;
        final lng = (data['lng'] ?? 0.0) as double;
        final latLng = LatLng(lat, lng);

        final marker = Marker(
          point: latLng,
          width: 55 * 1.16,
          height: 55 * 1.16,
          child: EventMarker(
            category: eventCategory,
            scale: 1.16,
            isPost: true,
            onTap: () {
              final dataWithId = Map<String, dynamic>.from(data);
              dataWithId['id'] = doc.id;
              _showEventPopup(context, dataWithId, eventCategory);
            },
          ),
        );

        markers.add(marker);

        // เก็บใน LRU cache
        _optimizedMarkerCache.put(docId, marker);
      }

      // อัปเดต optimized markers
      _optimizedMarkers = markers;
      _lastCachedZoom = _currentZoom;

      if (kDebugMode) {
        debugPrint(
            'Debug: 🔥 Final optimized markers count = ${markers.length}');
        debugPrint('Debug: 🔥 Cache size = ${_optimizedMarkerCache.length}');
        debugPrint('Debug: 🔥 === OPTIMIZED MARKERS BUILDING COMPLETE ===');
      }

      return markers;
    } finally {
      _isUpdatingMarkers = false;
    }
  }

  // สร้าง optimized clustered markers สำหรับ zoom level ต่ำ
  List<Marker> _buildOptimizedClusteredMarkers(List<DocumentSnapshot> docs) {
    if (docs.isEmpty) return [];

    // แยกกลุ่ม documents ตามระยะทาง (Optimized)
    final clusters = <List<DocumentSnapshot>>[];
    final processed = <bool>[];

    for (int i = 0; i < docs.length; i++) {
      processed.add(false);
    }

    for (int i = 0; i < docs.length; i++) {
      if (processed[i]) continue;

      final cluster = <DocumentSnapshot>[docs[i]];
      processed[i] = true;

      final data1 = docs[i].data() as Map<String, dynamic>;
      final lat1 = (data1['lat'] ?? 0.0) as double;
      final lng1 = (data1['lng'] ?? 0.0) as double;

      // หา documents อื่นที่อยู่ใกล้ๆ
      for (int j = i + 1; j < docs.length; j++) {
        if (processed[j]) continue;

        final data2 = docs[j].data() as Map<String, dynamic>;
        final lat2 = (data2['lat'] ?? 0.0) as double;
        final lng2 = (data2['lng'] ?? 0.0) as double;

        final distance = _calculateDistanceInKm(lat1, lng1, lat2, lng2);

        if (distance <= _clusterDistanceKm) {
          cluster.add(docs[j]);
          processed[j] = true;
        }
      }

      clusters.add(cluster);
    }

    // สร้าง markers จาก clusters
    final markers = <Marker>[];

    for (final cluster in clusters) {
      if (cluster.length == 1) {
        // สร้าง marker เดี่ยว
        final doc = cluster.first;
        final data = doc.data() as Map<String, dynamic>;
        final category =
            data['category'] as String? ?? data['type'] as String? ?? '';
        final eventCategory = FirebaseService.getCategoryFromName(category);
        final lat = (data['lat'] ?? 0.0) as double;
        final lng = (data['lng'] ?? 0.0) as double;
        final latLng = LatLng(lat, lng);

        final marker = Marker(
          point: latLng,
          width: 55 * 1.16,
          height: 55 * 1.16,
          child: EventMarker(
            category: eventCategory,
            scale: 1.16,
            isPost: true,
            onTap: () {
              final dataWithId = Map<String, dynamic>.from(data);
              dataWithId['id'] = doc.id;
              _showEventPopup(context, dataWithId, eventCategory);
            },
          ),
        );

        markers.add(marker);
      } else {
        // สร้าง cluster marker
        final clusterData = cluster.first.data() as Map<String, dynamic>;
        final lat = (clusterData['lat'] ?? 0.0) as double;
        final lng = (clusterData['lng'] ?? 0.0) as double;
        final latLng = LatLng(lat, lng);

        final marker = Marker(
          point: latLng,
          width: 60,
          height: 60,
          child: _buildClusterMarker(cluster),
        );

        markers.add(marker);
      }
    }

    // เก็บ cluster groups สำหรับการใช้งานในอนาคต
    // เก็บ cluster information เพื่อการ debug (ไม่จำเป็นสำหรับ performance)
    for (int i = 0; i < clusters.length; i++) {
      if (kDebugMode) {
        debugPrint('Cluster $i has ${clusters[i].length} documents');
      }
    }

    return markers;
  }

  // สร้าง widget สำหรับ cluster marker
  Widget _buildClusterMarker(List<DocumentSnapshot> clusterDocs) {
    final count = clusterDocs.length;

    return GestureDetector(
      onTap: () {
        // แสดงรายการเหตุการณ์ใน cluster
        _showClusterPopup(clusterDocs);
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF4673E5),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            count.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  // แสดง popup สำหรับ cluster
  void _showClusterPopup(List<DocumentSnapshot> clusterDocs) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'เหตุการณ์ในบริเวณนี้ (${clusterDocs.length} รายการ)',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'NotoSansThai',
                      ),
                    ),
                  ],
                ),
              ),

              // รายการเหตุการณ์
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: clusterDocs.length,
                  itemBuilder: (context, index) {
                    final doc = clusterDocs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final category = data['category'] as String? ??
                        data['type'] as String? ??
                        '';
                    final eventCategory =
                        FirebaseService.getCategoryFromName(category);

                    final title = data['title'] ??
                        (data['description']?.toString().isNotEmpty == true
                            ? data['description'].toString().length > 30
                                ? '${data['description'].toString().substring(0, 30)}...'
                                : data['description'].toString()
                            : 'ไม่มีหัวข้อ');

                    final timestamp = data['timestamp'] as Timestamp?;
                    final timeAgo = timestamp != null
                        ? DateTimeFormatters.formatTimeAgo(timestamp.toDate())
                        : '';

                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        child: EventMarker(
                          category: eventCategory,
                          scale: 0.7,
                          isPost: true,
                        ),
                      ),
                      title: Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'NotoSansThai',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        timeAgo,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        final dataWithId = Map<String, dynamic>.from(data);
                        dataWithId['id'] = doc.id;
                        _showEventPopup(context, dataWithId, eventCategory);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build clustered markers for low zoom levels
  // ดึงชื่อคนโพสแบบ masked (เหมือน list_screen.dart)
  String _getMaskedPosterName(Map<String, dynamic> data) {
    final userId = data['userId'] as String?;

    if (userId == null || userId.isEmpty) {
      return 'ผู้ใช้ไม่ระบุชื่อ';
    }

    // ถ้าเป็นผู้ใช้ปัจจุบัน ใช้ AuthService
    if (AuthService.currentUser?.uid == userId) {
      return AuthService.getMaskedDisplayName();
    }

    // ตรวจสอบฟิลด์ต่างๆ ในลำดับความสำคัญ
    final displayName = data['displayName']?.toString() ??
        data['userName']?.toString() ??
        data['posterName']?.toString();

    // ถ้ามี displayName ใน data ให้ใช้ชื่อนั้น
    if (displayName != null && displayName.isNotEmpty) {
      return _maskDisplayName(displayName);
    }

    // ถ้าไม่มี displayName ให้ mask userId
    if (userId == 'anonymous') {
      return 'ผู้ใช้ไม่ระบุชื่อ';
    }

    // Mask userId
    if (userId.length <= 8) return userId;
    return '${userId.substring(0, 4)}${'*' * (userId.length - 4)}';
  }

  // ฟังก์ชัน mask ชื่อ (คล้ายกับใน AuthService)
  String _maskDisplayName(String name) {
    final parts = name.trim().split(' ');

    if (parts.isEmpty) return 'ผู้ใช้ไม่ระบุชื่อ';

    if (parts.length == 1) {
      // ถ้ามีคำเดียว เช่น "kritchapon" -> "krit*****"
      final firstPart = parts[0];
      if (firstPart.length <= 4) {
        return firstPart; // ถ้าสั้นเกินไป ไม่ mask
      }
      return '${firstPart.substring(0, 4)}${'*' * (firstPart.length - 4)}';
    } else {
      // ถ้ามีหลายคำ เช่น "Krit P" -> "Krit *"
      final firstName = parts[0];
      final lastNameLength = parts.sublist(1).join(' ').length;
      return '$firstName ${'*' * lastNameLength}';
    }
  }

  @override
  Widget build(BuildContext context) {
    // ไม่แสดง loading screen แล้ว - ให้แสดงแผนที่เลย
    // ยกเลิกการเช็ค isLoadingLocation เพื่อลบ progress bar ออก

    // คืนค่า Navigation Bar เมื่อเข้าหน้าแผนที่หลัก
    _restoreMainScreenNavigationBar();

    return Scaffold(
      extendBodyBehindAppBar: true, // ให้ body ขยายไปข้างหลัง AppBar
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80), // ลดความสูงลงเล็กน้อย
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.transparent, // ทำให้พื้นหลัง AppBar โปร่งใส
          ),
          child: SafeArea(
            child: Container(
              margin: const EdgeInsets.only(top: 10, left: 12, right: 12),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical:
                      6), // ลด padding อีกครั้ง จาก h:16,v:8 เป็น h:12,v:6
              decoration: BoxDecoration(
                color: const Color(0xFFFDC621),
                borderRadius: BorderRadius.circular(25), // โค้งมนทั้งแถบ
                // ลบ boxShadow ออกเพื่อไม่ให้มีเงาดำๆ
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // ส่วนโลโก้ CheckDarn
                  const Text(
                    'CheckDarn',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      fontFamily: 'NotoSansThai',
                    ),
                  ),

                  // ส่วนกลาง - โปรไฟล์
                  Row(
                    children: [
                      // ส่วนโปรไฟล์
                      GestureDetector(
                        onTap: () async {
                          try {
                            // ตรวจสอบการ initialize ก่อนใช้งาน
                            if (!AuthService.isInitialized) {
                              await AuthService.initialize();
                            }

                            if (AuthService.isLoggedIn) {
                              _navigateToSettings();
                            } else {
                              final success =
                                  await AuthService.showLoginDialog(context);
                              if (success && mounted) {
                                setState(() {
                                  _isUserLoggedIn = _isUserLoggedInSafely();
                                });
                              }
                            }
                          } catch (e) {
                            if (kDebugMode) {
                              debugPrint('Error in profile tap: $e');
                            }
                          }
                        },
                        child: Container(
                          width: 35,
                          height: 35,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF4673E5),
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          child: _isUserLoggedIn &&
                                  AuthService.isInitialized &&
                                  AuthService.currentUser?.photoURL != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(17.5),
                                  child: Image.network(
                                    AuthService.currentUser!.photoURL!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Center(
                                        child: Icon(
                                          Icons.person,
                                          color: Colors.black,
                                          size: 21,
                                        ),
                                      );
                                    },
                                  ),
                                )
                              : const Center(
                                  child: Icon(
                                    Icons.person,
                                    color: Colors.black,
                                    size: 21,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // แผนที่ FlutterMap ที่ปรับปรุงประสิทธิภาพแล้ว
          FlutterMap(
            key: ValueKey(
                currentPosition), // rebuild เมื่อ currentPosition เปลี่ยน
            mapController: mapController,
            options: MapOptions(
              initialCenter: currentPosition ??
                  _defaultPosition, // ใช้ Bangkok เป็นค่าเริ่มต้น แล้วค่อยย้ายไปตำแหน่งจริง
              initialZoom: 15.0,
              minZoom: 5.0,
              maxZoom: 18.0,
              // Google Maps-like smooth interaction settings
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all &
                    ~InteractiveFlag.rotate, // ปิด rotate เพื่อประสิทธิภาพ
                scrollWheelVelocity: 0.002, // ลดความไวของ scroll wheel
                pinchZoomWinGestures:
                    MultiFingerGesture.pinchZoom, // เปิด pinch zoom
                pinchMoveWinGestures:
                    MultiFingerGesture.pinchMove, // เปิด pinch move
                enableMultiFingerGestureRace:
                    true, // เปิด multi-finger gestures
              ),
              // ปรับปรุงประสิทธิภาพการโหลดแผนที่
              cameraConstraint:
                  CameraConstraint.unconstrained(), // ไม่จำกัดการเคลื่อนไหว
              keepAlive: true, // เก็บ state ของแผนที่
              // Enhanced pointer event handlers - แก้ปัญหา tap หลัง drag
              onPointerDown: (event, point) {
                _activePointers++; // เพิ่มจำนวนนิ้วที่สัมผัสหน้าจอ
                _panStartPosition = event.position;
                _panStartTime = DateTime.now();
                _isPanning = false; // Reset panning state

                if (kDebugMode) {
                  debugPrint(
                      '🎯 Pointer down at: ${event.position}, active pointers: $_activePointers');
                }
              },
              onPointerUp: (event, point) {
                _activePointers =
                    (_activePointers - 1).clamp(0, 10); // ลดจำนวนนิ้ว

                if (kDebugMode) {
                  debugPrint(
                      '🎯 Pointer up - _isPanning: $_isPanning, active pointers: $_activePointers');
                }

                // หน่วงเวลาก่อน reset variables
                Timer(const Duration(milliseconds: 150), () {
                  _isPanning = false;
                  _panStartPosition = null;
                  _panStartTime = null;
                });
              },
              onPointerCancel: (event, point) {
                _activePointers =
                    (_activePointers - 1).clamp(0, 10); // ลดจำนวนนิ้ว
                _isPanning = false;
                _panStartPosition = null;
                _panStartTime = null;

                if (kDebugMode) {
                  debugPrint(
                      '🚫 Pointer cancelled, active pointers: $_activePointers');
                }
              },
              // Enhanced performance callbacks
              onPositionChanged: (MapCamera position, bool hasGesture) {
                if (kDebugMode && hasGesture) {
                  debugPrint(
                      '📍 Position changed: hasGesture=$hasGesture, zoom=${position.zoom}');
                }

                if (hasGesture) {
                  // ==================== SMART SECURITY CHECK ====================

                  // ตรวจสอบด้วย Smart Security Service สำหรับการเคลื่อนไหวแผนที่
                  if (!_validateMapAction('map_position_change')) {
                    if (kDebugMode) {
                      debugPrint(
                          '🔒 Map position change blocked by Smart Security');
                    }
                    return;
                  }

                  // ตรวจสอบว่ากำลังลากจริงหรือไม่
                  if (_panStartPosition != null && _panStartTime != null) {
                    final now = DateTime.now();
                    final duration = now.difference(_panStartTime!);
                    if (duration.inMilliseconds > 100) {
                      // หลังจากลากไป 100ms
                      if (!_isPanning) {
                        _isPanning = true;
                      }
                    }
                  }

                  _currentZoom = position.zoom;
                  _handleMapMove(); // Use debounced update during gestures
                }
              },
              onLongPress: _onMapLongPress,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.checkdarn',
                fallbackUrl:
                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                maxZoom: 18,
                maxNativeZoom: 18,
                // Performance optimized tile provider
                tileProvider: NetworkTileProvider(),
                // ปรับปรุงประสิทธิภาพการโหลด tiles
                panBuffer: 3, // เพิ่มจาก 2 เป็น 3 เพื่อโหลดล่วงหน้า
                keepBuffer: 4, // เพิ่มจาก 2 เป็น 4 เพื่อเก็บ cache นานขึ้น
                // เพิ่มการตั้งค่าสำหรับ caching
                tileBounds: null, // ไม่จำกัด bounds
                additionalOptions: const {
                  'attribution': '© OpenStreetMap contributors',
                  'crossOrigin': 'anonymous', // ป้องกันปัญหา CORS
                },
                // เพิ่ม error handling
                errorTileCallback: (tile, error, stackTrace) {
                  if (kDebugMode) {
                    debugPrint('Tile loading error: $error');
                  }
                },
              ),
              // วงรัศมีการค้นหา
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: currentPosition ??
                        const LatLng(
                            13.7563, 100.5018), // ใช้ตำแหน่งสำรองถ้าไม่มี
                    radius: searchRadius * 1000, // แปลงเป็นเมตร
                    useRadiusInMeter: true,
                    color: const Color(0xFF4673E5).withValues(alpha: 0.15),
                    borderColor: const Color(0xFF4673E5).withValues(alpha: 0.5),
                    borderStrokeWidth: 2,
                  ),
                ],
              ),
              // หมุดตำแหน่งผู้ใช้ - optimized with key
              if (currentPosition != null)
                MarkerLayer(
                  key: const ValueKey('user_position_marker'),
                  markers: [
                    Marker(
                      point: currentPosition!, // safe เพราะเช็คแล้วใน if
                      width: 38.64, // เพิ่มจาก 36.8 เป็น 38.64 (เพิ่ม 5%)
                      height: 50.4, // เพิ่มจาก 48 เป็น 50.4 (เพิ่ม 5%)
                      child: const LocationMarker(
                          scale: 1.68), // เพิ่มจาก 1.6 เป็น 1.68 (เพิ่ม 5%)
                    ),
                  ],
                ),
              // หมุดเหตุการณ์จาก Firebase - Optimized with better caching
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseService.getReportsStream(),
                builder: (context, snapshot) {
                  // ใช้ optimized markers เมื่อไม่มีข้อมูลใหม่หรือเกิด error
                  if (snapshot.hasError) {
                    if (kDebugMode) {
                      debugPrint('🚨 Firebase Stream Error: ${snapshot.error}');
                    }
                    return MarkerLayer(
                      key: const ValueKey('error_cached_markers'),
                      markers: _optimizedMarkers,
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    // แสดง cached markers ระหว่างรอ (ไม่ rebuild ถ้าไม่จำเป็น)
                    if (_optimizedMarkers.isNotEmpty) {
                      return MarkerLayer(
                        key: const ValueKey('loading_cached_markers'),
                        markers: _optimizedMarkers,
                      );
                    }
                    // แสดง loading indicator เฉพาะครั้งแรก
                    return const MarkerLayer(markers: []);
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    if (kDebugMode) {
                      debugPrint('📭 No Firebase data available');
                    }
                    return MarkerLayer(
                      key: const ValueKey('empty_markers'),
                      markers: const [],
                    );
                  }

                  final docs = snapshot.data!.docs;

                  // สร้าง optimized markers ใหม่เฉพาะเมื่อข้อมูลเปลี่ยนแปลงจริงๆ
                  final markers = _buildEventMarkersFromFirebase(docs);

                  if (kDebugMode &&
                      markers.length != _optimizedMarkers.length) {
                    debugPrint(
                        '🔄 Built fresh optimized markers: ${markers.length} (was ${_optimizedMarkers.length})');
                  }

                  return MarkerLayer(
                    key: ValueKey(
                        'optimized_markers_${markers.length}_${selectedCategories.length}_${searchRadius.toInt()}'),
                    markers: markers,
                  );
                },
              ),
            ],
          ),

          // แท่งสไลด์บาร์รัศมีการค้นหา (แนวตั้ง)
          Positioned(
            right: 22,
            top: 280, // ปรับจาก 120 เป็น 280 เพื่อให้อยู่กลางๆ หน้าจอ
            child: Container(
              width: 36, // ลดจาก 40 เป็น 36 (ลด 10%)
              height: 180, // เพิ่มจาก 158 เป็น 180 (เพิ่ม 14%)
              padding: const EdgeInsets.symmetric(
                  vertical: 7,
                  horizontal: 5), // ปรับ padding: บน-ล่าง 7px, ซ้าย-ขวา 5px
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(
                    18), // ปรับ radius ตามขนาดใหม่ (36/2 = 18)
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${searchRadius.toInt()}',
                    style: const TextStyle(
                      fontSize: 12, // เพิ่มจาก 10 เป็น 12
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4673E5),
                    ),
                  ),
                  Text(
                    AppLocalizations.of(context).kilometerShort,
                    style: const TextStyle(
                      fontSize: 10, // เพิ่มจาก 8 เป็น 10
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 0), // ลบระยะห่างระหว่าง "กม." กับสไลด์
                  Expanded(
                    child: RotatedBox(
                      quarterTurns: 3, // หมุน 270 องศา เพื่อให้เป็นแนวตั้ง
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4, // เพิ่มจาก 3 เป็น 4
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 8, // เพิ่มจาก 6 เป็น 8
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 16, // เพิ่มจาก 12 เป็น 16
                          ),
                        ),
                        child: Slider(
                          value: searchRadius,
                          min: 10.0,
                          max: 100.0,
                          divisions: 18,
                          activeColor: const Color(0xFF4673E5),
                          inactiveColor: Colors.grey.shade300,
                          onChanged: (value) {
                            setState(() {
                              searchRadius = value;
                            });
                            _saveSettings(); // บันทึกค่าทันทีเมื่อมีการเปลี่ยนแปลง
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ปุ่มกลับมาตำแหน่งจริงของผู้ใช้ (รวมหาตำแหน่งใหม่) - ปรับให้ฉลาดตาม Navigation Bar
          Positioned(
            right: 16,
            bottom: _calculateSmartButtonPosition(
                60), // ใช้ตำแหน่งฐาน 60 สำหรับปุ่มบน
            child: LocationButton(
              onPressed: _goToMyLocation,
              isLoading: isLoadingMyLocation, // ใช้ loading state แยก
              size: 48,
              icon: Icons.my_location,
              tooltip: 'กลับมาตำแหน่งจริงของฉัน',
              iconColor: const Color(0xFF4673E5),
            ),
          ),

          // แถบหมวดหมู่แนวนอนด้านล่าง
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Bottom Bar
                BottomBar(
                  selectedCategories: selectedCategories,
                  onCategorySelectorTap: _showCategorySelector,
                ),
                // Bottom Safety Area - จัดการกรณี Navigation Bar โปร่งใสหรือไม่มี
                Container(
                  width: double.infinity,
                  height: MediaQuery.of(context).viewPadding.bottom > 0
                      ? MediaQuery.of(context).viewPadding.bottom
                      : 20, // สำหรับอุปกรณ์ที่ไม่มี Navigation Bar
                  color: Colors.white, // พื้นหลังสีขาวเพื่อไม่ให้โล่ง
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Painter สำหรับวาดแผนที่พื้นฐาน
/// Analytics and Performance Extensions
extension MapScreenAnalytics on _MapScreenState {
  /// Start analytics tracking
  void startAnalytics() {
    // Analytics disabled for now
    if (kDebugMode) {
      debugPrint('🔕 Analytics tracking disabled');
    }
  }
}
