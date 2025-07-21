import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui' as ui;
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/event_model.dart';
import '../services/geocoding_service.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';
import '../utils/formatters.dart';
import '../widgets/bottom_bar.dart';
import '../widgets/category_selector_dialog.dart';
import '../widgets/profile_popup.dart';
import '../widgets/location_marker.dart';
import '../widgets/event_marker.dart';
import '../widgets/location_button.dart';
import '../widgets/comment_bottom_sheet.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng currentPosition = const LatLng(13.7563, 100.5018); // ตำแหน่งปัจจุบัน
  late MapController mapController;
  double searchRadius = 10.0; // รัศมีการค้นหาในหน่วยกิโลเมตร (10-100 km)
  LocationInfo? currentLocationInfo; // ข้อมูลที่อยู่ปัจจุบัน
  bool isLoadingLocation = false; // สถานะการโหลดข้อมูลที่อยู่
  Timer? _realtimeTimer; // Timer สำหรับปรับปรุงหมุดแบบเรียลไทม์
  bool _isUserLoggedIn = false; // สถานะการล็อกอิน
  bool _showProfileMenu = false; // สถานะการแสดงเมนูโปรไฟล์

  List<EventCategory> selectedCategories = EventCategory.values.toList();

  @override
  void initState() {
    super.initState();
    mapController = MapController();
    selectedCategories =
        EventCategory.values.toList(); // เลือกทั้งหมดโดย default
    _loadSavedSettings(); // โหลดการตั้งค่าที่บันทึกไว้
    _getCurrentLocation(); // หาตำแหน่งจริง
    _startRealtimeUpdates(); // เริ่มการปรับปรุงหมุดแบบเรียลไทม์
    _checkLoginStatus(); // ตรวจสอบสถานะล็อกอิน
  }

  @override
  void dispose() {
    _realtimeTimer?.cancel(); // ยกเลิก Timer เมื่อหน้าจอปิด
    super.dispose();
  }

  // ฟังก์ชันโหลดการตั้งค่าที่บันทึกไว้
  Future<void> _loadSavedSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        searchRadius =
            prefs.getDouble('search_radius') ?? 50.0; // เริ่มต้นที่ 50 km
      });
      print('Loaded search radius: $searchRadius km');
    } catch (e) {
      print('Error loading saved settings: $e');
    }
  }

  // ฟังก์ชันบันทึกการตั้งค่า
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('search_radius', searchRadius);
      print('Saved search radius: $searchRadius km');
    } catch (e) {
      print('Error saving settings: $e');
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
  }

  // ฟังก์ชันตรวจสอบสถานะล็อกอิน
  Future<void> _checkLoginStatus() async {
    try {
      await AuthService.initialize(); // เริ่มต้น AuthService
      setState(() {
        _isUserLoggedIn = AuthService.isLoggedIn;
      });
      print('Debug: Login status checked - isLoggedIn: $_isUserLoggedIn');
    } catch (e) {
      print('Error checking login status: $e');
    }
  }

  // ฟังก์ชันหาตำแหน่งปัจจุบัน
  Future<void> _getCurrentLocation() async {
    try {
      setState(() => isLoadingLocation = true);

      // ตรวจสอบการเปิดใช้งาน Location Services
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationErrorSnackbar('กรุณาเปิดใช้งานตำแหน่งในอุปกรณ์');
        return;
      }

      // ตรวจสอบ Permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showLocationErrorSnackbar('ไม่อนุญาตให้เข้าถึงตำแหน่ง');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showLocationErrorSnackbar('ตั้งค่าอนุญาตใน Device Settings');
        return;
      }

      // หาตำแหน่งปัจจุบัน
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // อัปเดตตำแหน่งและขยับแผนที่
      final userPosition = LatLng(position.latitude, position.longitude);
      setState(() => currentPosition = userPosition);
      mapController.move(userPosition, 15.0);
      await _getLocationInfo(userPosition);
    } catch (e) {
      _showLocationErrorSnackbar('ไม่สามารถหาตำแหน่งได้: ${e.toString()}');
    } finally {
      setState(() => isLoadingLocation = false);
    }
  }

  void _showLocationErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
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
    }
  }

  // ฟังก์ชันแสดง popup เลือกหมวดหมู่
  void _showCategorySelector() {
    showDialog(
      context: context,
      builder: (context) => CategorySelectorDialog(
        initiallySelectedCategories: selectedCategories,
        onCategoriesSelected: (categories) {
          setState(() {
            selectedCategories = categories;
          });
        },
      ),
    );
  }

  // ฟังก์ชันแสดง popup โปรไฟล์
  void _showProfilePopup() {
    showDialog(
      context: context,
      builder: (context) => ProfilePopup(
        onLogout: () {
          setState(() {
            _isUserLoggedIn = false;
          });
        },
      ),
    );
  }

  // ฟังก์ชันแสดง popup ข้อมูลเหตุการณ์แบบเต็มหน้าจอ
  void _showEventPopup(
      BuildContext context, Map<String, dynamic> data, EventCategory category) {
    // ดึงข้อมูลเหมือนใน list_screen.dart
    final title = data['title'] ??
        (data['description']?.toString().isNotEmpty == true
            ? data['description'].toString().length > 30
                ? '${data['description'].toString().substring(0, 30)}...'
                : data['description'].toString()
            : 'ไม่มีหัวข้อ');
    final imageUrl = data['imageUrl'] as String?;
    final timestamp = data['timestamp'] as Timestamp?;
    final reportId = data['id'] ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize:
            0.9, // เพิ่มจาก 85% เป็น 90% เพื่อให้ใกล้ AppBar มากขึ้น
        minChildSize: 0.5, // ขั้นต่ำ 50%
        maxChildSize: 0.98, // เพิ่มสูงสุดเป็น 98% เพื่อให้เกือบถึงขอบบน
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
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // แถวที่ 1: emoji + หัวข้อเหตุการณ์
                      Row(
                        children: [
                          Text(
                            category.emoji,
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              category.label,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
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
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],

                      // แถวที่ 4: รูปภาพ (ถ้ามี)
                      if (imageUrl != null &&
                          imageUrl.isNotEmpty &&
                          imageUrl.trim() != '') ...[
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () {
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
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return const Center(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.broken_image,
                                                      size: 48,
                                                      color: Colors.white),
                                                  SizedBox(height: 8),
                                                  Text('ไม่สามารถโหลดรูปภาพได้',
                                                      style: TextStyle(
                                                          color: Colors.white)),
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
                            width: double.infinity,
                            height: 180, // ลดความสูงจาก 200 เป็น 180
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value:
                                          loadingProgress.expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                              Color(0xFFFF9800)),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.broken_image,
                                            size: 32, color: Colors.grey),
                                        SizedBox(height: 4),
                                        Text('ไม่สามารถโหลดรูปภาพได้',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey)),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ],

                      // แถวที่ 5: เวลา
                      if (timestamp != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Text(
                              '🕐',
                              style: TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${DateTimeFormatters.formatDate(timestamp)} · ${DateTimeFormatters.formatTimestamp(timestamp)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
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
                            ),
                          ),
                        ],
                      ),

                      // ช่องว่างด้านล่างเพื่อไม่ให้เนื้อหาติดขอบ
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),

              // Footer with comment button - ติดด้านล่าง
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Colors.grey[200]!, width: 1),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: FutureBuilder<QuerySnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('reports')
                        .doc(reportId)
                        .collection('comments')
                        .get(),
                    builder: (context, snapshot) {
                      int commentCount = 0;
                      if (snapshot.hasData) {
                        commentCount = snapshot.data!.docs.length;
                      }

                      return ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context)
                              .pop(); // ปิด bottom sheet ปัจจุบัน
                          _showCommentSheet(reportId, title, category.name);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF9800),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(
                          Icons.chat_bubble_outline,
                          size: 18,
                          color: Colors.white,
                        ),
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'แสดงความคิดเห็น',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            if (commentCount > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$commentCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ฟังก์ชันแสดงความคิดเห็น
  void _showCommentSheet(String reportId, String title, String category) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentBottomSheet(
        reportId: reportId,
        reportType: category,
      ),
    );
  }

  // ฟังก์ชันกลับไปยังตำแหน่งตัวเองและปรับแนวแมพ
  void _goToMyLocation() {
    try {
      // รีเซ็ตการหมุนของแผนที่ให้กลับมาเป็น 0 (หันหน้าไปทางเหนือ)
      mapController.moveAndRotate(currentPosition, 15.0, 0.0);
    } catch (e) {
      print('Error moving map: $e');
      // หากเกิดข้อผิดพลาด ลองใช้ move ธรรมดา
      try {
        mapController.move(currentPosition, 15.0);
      } catch (e2) {
        print('Error with fallback move: $e2');
        setState(() {});
      }
    }
  }

  // สร้าง markers สำหรับเหตุการณ์จาก Firebase (เฉพาะในรัศมีและไม่เกิน 24 ชั่วโมง - ทดสอบ)

  List<Marker> _buildEventMarkersFromFirebase(List<DocumentSnapshot> docs) {
    final now = DateTime.now();
    final fortyEightHoursAgo =
        now.subtract(const Duration(hours: 48)); // 48 ชั่วโมงสำหรับความสดใหม่

    print('Debug: 🔥 === BUILDING MARKERS ===');
    print('Debug: 🔥 Total docs = ${docs.length}');
    print('Debug: 🔥 Current time = $now');
    print('Debug: 🔥 Forty eight hours ago = $fortyEightHoursAgo');
    print('Debug: 🔥 Current position = $currentPosition');
    print('Debug: 🔥 Search radius = $searchRadius km');
    print(
        'Debug: 🔥 Selected categories = ${selectedCategories.map((c) => c.toString().split('.').last).toList()}');

    // Filter เฉพาะโพสต์ที่สดใหม่ (48 ชั่วโมง) และอยู่ในรัศมี
    final filteredDocs = docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) {
        print('Debug: Doc data is null for doc ${doc.id}');
        return false;
      }

      // Debug: ตรวจสอบข้อมูลในเอกสาร
      print('🔥 Document ID: ${doc.id}');
      print('📌 Data: $data');

      // ตรวจสอบหมวดหมู่
      final category = data['category'] as String? ??
          data['type'] as String?; // รองรับทั้งสอง field

      final eventCategory = FirebaseService.getCategoryFromName(category ?? '');
      final isCategorySelected = selectedCategories.contains(eventCategory);
      print(
          '🔄 Category: $category | Event Category: $eventCategory | Selected: $isCategorySelected');

      if (!isCategorySelected) {
        return false;
      }

      // ตรวจสอบเวลา - ต้องไม่เกิน 48 ชั่วโมง (สำหรับความสดใหม่)
      DateTime? timestamp =
          DateTimeFormatters.parseTimestamp(data['timestamp']);

      if (timestamp == null) {
        print('Debug: No timestamp for doc ${doc.id} - REJECTED');
        return false; // ไม่แสดงโพสต์ที่ไม่มี timestamp
      }

      final isWithin48Hours = timestamp.isAfter(fortyEightHoursAgo);
      print('⏰ Timestamp: $timestamp | Within 48h: $isWithin48Hours');

      if (!isWithin48Hours) {
        return false;
      }

      // ตรวจสอบพิกัด - ต้องมีพิกัด
      final lat = (data['lat'] ?? 0.0) as double;
      final lng = (data['lng'] ?? 0.0) as double;

      if (lat == 0.0 && lng == 0.0) {
        print('📍 No coordinates for doc ${doc.id}');
        return false;
      }

      // ตรวจสอบระยะทาง - ต้องอยู่ในรัศมี
      final distance = FirebaseService.calculateDistance(
        currentPosition.latitude,
        currentPosition.longitude,
        lat,
        lng,
      );

      final isWithinRadius = distance <= searchRadius;
      print('📍 Distance: $distance km | Within radius: $isWithinRadius');

      if (!isWithinRadius) {
        return false;
      }

      print(
          'Debug: Event ACCEPTED - $category at $timestamp, distance = $distance km for doc ${doc.id}');
      return true;
    }).toList();

    print('Debug: Filtered docs count = ${filteredDocs.length}');

    if (filteredDocs.isEmpty) {
      print('Debug: ⚠️  No fresh markers found!');
      print(
          'Debug: - Selected categories: ${selectedCategories.map((c) => c.toString().split('.').last).toList()}');
      print('Debug: - Search radius: $searchRadius km');
      print('Debug: - Time window: last 48 hours (for freshness)');
    } else {
      print('Debug: ✅ Found ${filteredDocs.length} fresh events');
    }

    final markers = filteredDocs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final category =
          data['category'] as String? ?? data['type'] as String? ?? '';
      final eventCategory = FirebaseService.getCategoryFromName(category);
      final lat = (data['lat'] ?? 0.0) as double;
      final lng = (data['lng'] ?? 0.0) as double;
      final latLng = LatLng(lat, lng);

      print(
          'Debug: Creating marker for doc ${doc.id} at $latLng with category $eventCategory');

      final marker = Marker(
        point: latLng,
        width: 23 * 1.365, // เพิ่มจาก 1.3 เป็น 1.365 (เพิ่ม 5%)
        height: 30 * 1.365, // เพิ่มจาก 1.3 เป็น 1.365 (เพิ่ม 5%)
        child: EventMarker(
          category: eventCategory,
          scale: 1.365, // เพิ่มจาก 1.3 เป็น 1.365 (เพิ่ม 5%)
          onTap: () {
            // ส่ง doc.id แทน data['id'] เพื่อให้ได้ reportId ที่ถูกต้อง
            final dataWithId = Map<String, dynamic>.from(data);
            dataWithId['id'] = doc.id; // เพิ่ม doc.id เข้าไปใน data
            _showEventPopup(context, dataWithId, eventCategory);
          },
        ),
      );

      print('Debug: Successfully created marker for doc ${doc.id}');
      return marker;
    }).toList();

    print('Debug: 🔥 Final markers count = ${markers.length}');
    print('Debug: 🔥 === MARKERS BUILDING COMPLETE ===');
    return markers;
  }

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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'CheckDarn',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        backgroundColor: const Color(0xFFFDC621),
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
        actions: [
          // ปุ่มโปรไฟล์กลม หรือ ปุ่มล็อกอิน
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: AuthService.isLoggedIn
                  ? _showProfilePopup
                  : () async {
                      final success =
                          await AuthService.showLoginDialog(context);
                      if (success && mounted) {
                        setState(() {
                          _isUserLoggedIn = AuthService.isLoggedIn;
                        });
                      }
                    },
              child: Container(
                width: 35, // เพิ่มจาก 32 เป็น 35 (เพิ่ม 10%)
                height: 35, // เพิ่มจาก 32 เป็น 35 (เพิ่ม 10%)
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF4673E5),
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
                child: AuthService.isLoggedIn &&
                        AuthService.currentUser?.photoURL != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(
                            17.5), // ปรับตามขนาดใหม่ (35/2 = 17.5)
                        child: Image.network(
                          AuthService.currentUser!.photoURL!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(
                                Icons.person,
                                color: Colors.black,
                                size: 21, // เพิ่มจาก 19 เป็น 21 (เพิ่ม 10%)
                              ),
                            );
                          },
                        ),
                      )
                    : const Center(
                        child: Icon(
                          Icons.person,
                          color: Colors.black,
                          size: 21, // เพิ่มจาก 19 เป็น 21 (เพิ่ม 10%)
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () {
          // ปิดเมนูโปรไฟล์เมื่อคลิกที่อื่น
          if (_showProfileMenu) {
            setState(() {
              _showProfileMenu = false;
            });
          }
        },
        child: Stack(
          children: [
            // แผนที่ FlutterMap ที่ทำงานได้แน่นอน
            FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: currentPosition,
                initialZoom: 15.0,
                minZoom: 5.0,
                maxZoom: 18.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.checkdarn',
                ),
                // วงรัศมีการค้นหา
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: currentPosition,
                      radius: searchRadius * 1000, // แปลงเป็นเมตร
                      useRadiusInMeter: true,
                      color: const Color(0xFF4673E5).withValues(alpha: 0.15),
                      borderColor:
                          const Color(0xFF4673E5).withValues(alpha: 0.5),
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),
                // หมุดตำแหน่งผู้ใช้
                MarkerLayer(
                  markers: [
                    Marker(
                      point: currentPosition,
                      width: 38.64, // เพิ่มจาก 36.8 เป็น 38.64 (เพิ่ม 5%)
                      height: 50.4, // เพิ่มจาก 48 เป็น 50.4 (เพิ่ม 5%)
                      child: const LocationMarker(
                          scale: 1.68), // เพิ่มจาก 1.6 เป็น 1.68 (เพิ่ม 5%)
                    ),
                  ],
                ),
                // หมุดเหตุการณ์จาก Firebase
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseService.getReportsStream(),
                  builder: (context, snapshot) {
                    print(
                        'Debug: StreamBuilder state = ${snapshot.connectionState}');

                    if (snapshot.hasError) {
                      print('Debug: StreamBuilder error = ${snapshot.error}');
                      return const MarkerLayer(
                          markers: []); // แสดงแผนที่เปล่าเมื่อเกิดข้อผิดพลาด
                    }

                    // แสดงหมุดเปล่าขณะรอข้อมูลครั้งแรก แต่ยังคงแสดง MarkerLayer
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      print('Debug: StreamBuilder waiting for first data...');
                      return const MarkerLayer(
                          markers: []); // แสดง MarkerLayer เปล่าแทน SizedBox.shrink()
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      print('Debug: StreamBuilder no data or empty docs');
                      return const MarkerLayer(
                          markers: []); // แสดงแผนที่เปล่าเมื่อไม่มีข้อมูล
                    }

                    final docs = snapshot.data!.docs;
                    print(
                        'Debug: ✅ StreamBuilder received ${docs.length} documents from Firebase');
                    final markers = _buildEventMarkersFromFirebase(docs);
                    print(
                        'Debug: ✅ Created ${markers.length} markers for map - DISPLAYING NOW');

                    // แสดงหมุดด้วย Key เพื่อให้ Flutter rebuild ได้ถูกต้อง
                    return MarkerLayer(
                      key: ValueKey(
                          'markers_${docs.length}_${selectedCategories.length}_${searchRadius.toInt()}'),
                      markers: markers,
                    );
                  },
                ),
              ],
            ),

            // แท่งสไลด์บาร์รัศมีการค้นหา (แนวตั้ง)
            Positioned(
              right:
                  22, // ปรับให้อยู่ตรงกลางของปุ่มค้นหาตำแหน่ง (16 + 24 - 18 = 22)
              top: 320, // กลับไปตำแหน่งเดิม
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
                      'กม.',
                      style: TextStyle(
                        fontSize: 10, // เพิ่มจาก 8 เป็น 10
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(
                        height: 0), // ลบระยะห่างระหว่าง "กม." กับสไลด์
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

            // ปุ่มกลับมาหาตำแหน่งตัวเอง
            Positioned(
              right: 16, // ปรับตำแหน่งให้อยู่ตรงกลางของ Slider ใหม่
              top: 520, // กลับไปตำแหน่งเดิม (320 + 180 + 20 = 520)
              child: LocationButton(
                onPressed: _goToMyLocation,
                isLoading: isLoadingLocation,
                size: 48, // เพิ่มจาก 40 เป็น 48 (เพิ่ม 20%)
              ),
            ),

            // แถบหมวดหมู่แนวนอนด้านล่าง
            BottomBar(
              selectedCategories: selectedCategories,
              onCategorySelectorTap: _showCategorySelector,
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Painter สำหรับวาดแผนที่พื้นฐาน
class SimpleMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // วาดถนนหลัก
    paint.color = Colors.white.withValues(alpha: 0.8);
    paint.strokeWidth = 3;
    paint.style = PaintingStyle.stroke;

    // ถนนแนวนอน (6 เส้น)
    for (int i = 1; i < 7; i++) {
      final y = size.height * i / 7;
      canvas.drawLine(
        Offset(size.width * 0.1, y),
        Offset(size.width * 0.9, y),
        paint,
      );
    }

    // ถนนแนวตั้ง (5 เส้น)
    for (int i = 1; i < 6; i++) {
      final x = size.width * i / 6;
      canvas.drawLine(
        Offset(x, size.height * 0.1),
        Offset(x, size.height * 0.9),
        paint,
      );
    }

    // วาดแม่น้ำ (เส้นโค้ง)
    paint.color = const Color(0xFF42A5F5);
    paint.strokeWidth = 6;
    paint.style = PaintingStyle.stroke;
    final riverPath = ui.Path();
    riverPath.moveTo(size.width * 0.15, size.height * 0.3);
    riverPath.quadraticBezierTo(size.width * 0.4, size.height * 0.7,
        size.width * 0.85, size.height * 0.5);
    canvas.drawPath(riverPath, paint);

    // วาดพื้นที่สีเขียว (สวนสาธารณะ)
    paint.color = const Color(0xFF66BB6A).withValues(alpha: 0.4);
    paint.style = PaintingStyle.fill;

    // สวนที่ 1
    final park1 = Rect.fromLTWH(size.width * 0.15, size.height * 0.15,
        size.width * 0.25, size.height * 0.2);
    canvas.drawOval(park1, paint);

    // สวนที่ 2
    final park2 = Rect.fromLTWH(size.width * 0.6, size.height * 0.6,
        size.width * 0.3, size.height * 0.25);
    canvas.drawOval(park2, paint);

    // วาดอาคารสำคัญ
    paint.color = const Color(0xFF90A4AE);
    paint.style = PaintingStyle.fill;

    // อาคาร 1
    final building1 = Rect.fromLTWH(size.width * 0.3, size.height * 0.4,
        size.width * 0.08, size.height * 0.12);
    canvas.drawRect(building1, paint);

    // อาคาร 2
    final building2 = Rect.fromLTWH(size.width * 0.7, size.height * 0.25,
        size.width * 0.06, size.height * 0.1);
    canvas.drawRect(building2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
