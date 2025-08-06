import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'dart:async';
import 'dart:math';
import '../models/speed_camera_model.dart';
import '../services/speed_camera_service.dart';
import '../../../services/smart_security_service.dart';
import '../../../services/sound_manager.dart';
import '../../../services/smart_tile_provider.dart';
import '../../../services/connection_manager.dart';
import '../../../services/map_cache_manager.dart';
import '../../../services/auth_service.dart';
import '../../../screens/sound_settings_screen.dart';
import 'camera_report_screen.dart';
import '../widgets/speed_camera_marker.dart';
import '../widgets/circular_speed_widget.dart';

class SpeedCameraScreen extends StatefulWidget {
  const SpeedCameraScreen({super.key});

  @override
  State<SpeedCameraScreen> createState() => _SpeedCameraScreenState();
}

class _SpeedCameraScreenState extends State<SpeedCameraScreen>
    with WidgetsBindingObserver {
  LatLng currentPosition = const LatLng(13.7563, 100.5018); // Default Bangkok
  late MapController mapController;
  List<SpeedCamera> speedCameras = [];
  bool isLoadingLocation = false;
  bool isLoadingCameras = true;
  double currentSpeed = 0.0;
  SpeedCamera? nearestCamera;
  double distanceToNearestCamera = 0.0;
  // Intelligent Auto-Follow System - ระบบติดตามอัจฉริยะ
  DateTime? _lastUserInteraction; // ติดตามการโต้ตอบของผู้ใช้
  bool _userIsManuallyControlling = false; // ผู้ใช้กำลังควบคุมแผนที่เอง

  // Badge Alert System - ระบบแจ้งเตือนใน Badge
  String _badgeText = 'กล้องจับความเร็ว';
  Color _badgeColor =
      const Color(0xFFFFC107); // เปลี่ยนกลับเป็นสีเหลืองแบบเดิม (สีหลักของแอพ)
  Timer? _badgeResetTimer;

  StreamSubscription<Position>? _positionSubscription;
  Timer? _speedUpdateTimer;
  Timer? _followModeResetTimer; // Timer สำหรับกลับมา auto-follow
  double _smoothTravelHeading = 0.0; // สำหรับ smooth rotation

  // ระบบ Predict Movement
  List<Position> _positionHistory = [];
  LatLng? _predictedPosition;
  List<SpeedCamera> _predictedCameras = [];

  // ระบบสถิติและ Analytics
  DateTime? _lastAlertTime;

  // ระบบเสียงแจ้งเตือน
  final SoundManager _soundManager = SoundManager();

  // Progressive Beep Alert System - ระบบเสียงบี๊บแบบค่อยเป็นค่อยไป
  Timer? _progressiveBeepTimer;
  SpeedCamera? _currentBeepCamera;
  double _lastBeepDistance = 0.0;
  bool _isProgressiveBeepActive = false;

  // Smart Progressive Beep - ป้องกันการเตือนซ้ำ
  Set<String> _alertedCameras = {};
  Timer? _cameraCleanupTimer;

  // Smart Security System variables
  bool _isSecurityModeActive = false;
  DateTime _sessionStartTime = DateTime.now();

  // Performance & Resource Protection - ป้องกันการใช้ทรัพยากรมากเกินไป
  int _mapMovementCount = 0;
  DateTime? _lastMapMovement;
  final int _maxMapMovements =
      5000; // เพิ่มจาก 1000 เป็น 5000 (อนุญาตให้ใช้งานได้มากขึ้น)
  Timer? _resourceMonitorTimer;
  DateTime? _lastExcessiveWarning; // เพิ่มสำหรับ throttle warnings
  final Duration _warningThrottle =
      const Duration(seconds: 10); // เตือนทุก 10 วินาที

  // Data Validation & Integrity - ตรวจสอบความถูกต้องของข้อมูล
  double? _previousLatitude;
  double? _previousLongitude;
  final double _maxReasonableSpeed =
      180.0; // ลดจาก 200 เป็น 180 กม./ชม. (เข้มงวดขึ้น)
  final double _maxLocationJump =
      500.0; // ลดจาก 1000 เป็น 500 เมตร (เข้มงวดขึ้น)

  // GPS Anti-Spoofing System - ป้องกัน Fake GPS
  final double _maxAcceptableAccuracy =
      50.0; // ความแม่นยำต่ำสุดที่ยอมรับ (เมตร)
  final double _maxAcceptableSpeedAccuracy = 2.0; // ความแม่นยำความเร็วต่ำสุด
  Position? _lastTrustedPosition; // ตำแหน่งล่าสุดที่เชื่อถือได้
  int _gpsAnomalyCount = 0; // นับจำนวนความผิดปกติของ GPS
  final int _maxGpsAnomalies =
      5; // จำนวนความผิดปกติสูงสุดก่อนเปิด Security Mode

  // Enhanced Security Thresholds - ปรับค่าเพื่อความเข้มงวดขึ้น
  final Duration _maxSessionDuration =
      Duration(hours: 6); // ลดจาก 8 เป็น 6 ชั่วโมง

  // Smart map system
  SmartTileProvider? _smartTileProvider; // เปลี่ยนเป็น nullable
  Timer? _connectionCheckTimer;
  Timer? _preloadTimer;

  // Smart Login Detection System - ระบบตรวจจับการใช้งานจริงเพื่อเด้งล็อกอิน
  bool _hasShownLoginPrompt = false; // ป้องกันการเด้งหลายครั้ง
  int _movementCount = 0; // นับจำนวนการเคลื่อนไหว
  DateTime? _firstMovementTime; // เวลาที่เริ่มเคลื่อนไหวครั้งแรก
  double _totalDistanceTraveled = 0.0; // ระยะทางรวมที่เดินทาง
  LatLng? _lastMovementPosition; // ตำแหน่งล่าสุดสำหรับคำนวณระยะทาง

  // Auto-refresh tracking system - ระบบติดตามการรีเฟรชอัตโนมัติ
  bool _hasJustVoted = false; // ติดตามว่าเพิ่งโหวตเสร็จ
  DateTime? _lastVotingTime; // เวลาล่าสุดที่โหวต
  final Duration _votingRefreshWindow =
      Duration(minutes: 2); // ช่วงเวลาสำหรับรีเฟรชหลังโหวต
  Timer? _loginPromptTimer; // Timer สำหรับเด้งล็อกอินหลังจากเวลาที่กำหนด
  int _appInteractionCount = 0; // จำนวนการโต้ตอบกับแอป (แตะกล้อง, ดูข้อมูล)

  // Missing member variables for Smart Security System
  Timer? _securityCheckTimer;
  List<Position> _speedHistory = [];
  int _suspiciousActivityCount = 0;
  final int _maxSuspiciousActivity = 10;
  final Duration _securityCooldown = const Duration(minutes: 5);
  DateTime? _lastLocationUpdateTime;
  double? _lastValidSpeed;

  // Login Detection Thresholds - เงื่อนไขสำหรับเด้งล็อกอิน
  static const int _minMovementCount = 3; // ต้องเคลื่อนไหวอย่างน้อย 3 ครั้ง
  static const double _minTravelDistance =
      100.0; // ต้องเดินทางอย่างน้อย 100 เมตร
  static const Duration _maxTimeBeforePrompt =
      Duration(seconds: 45); // เด้งล็อกอินหลัง 45 วินาที
  static const int _minInteractionCount = 2; // ต้องมีการโต้ตอบอย่างน้อย 2 ครั้ง

  @override
  void initState() {
    super.initState();
    mapController = MapController();

    // เริ่มระบบ Smart Security สำหรับ Speed Camera (HIGH RISK)
    _initializeSmartSecurity();

    _getCurrentLocation();
    _loadSpeedCameras();
    _startSpeedTracking();
    _initializeSoundManager();
    _startConnectionMonitoring();
    _enableWakelock(); // เปิด wakelock เพื่อไม่ให้หน้าจอดับ
    _startCameraCleanupTimer(); // เริ่มระบบล้างข้อมูลกล้องที่เตือนแล้ว
    _startResourceMonitoring(); // เริ่มตรวจสอบการใช้ทรัพยากร
    _initializeSmartLoginDetection(); // เริ่มระบบตรวจจับการใช้งานเพื่อเด้งล็อกอิน

    // Initialize smart map system หลังจาก widget build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSmartMapSystem();
    });

    // เพิ่ม WidgetsBindingObserver สำหรับตรวจจับการกลับมาที่หน้าจอ
    WidgetsBinding.instance.addObserver(this);
  }

  // ==================== SMART SECURITY SYSTEM ====================

  /// เริ่มระบบ Smart Security สำหรับ Speed Camera (HIGH RISK)
  void _initializeSmartSecurity() {
    SmartSecurityService.initialize();
    SmartSecurityService.setSecurityLevel(SecurityLevel.high);
    print('🔒 Smart Security initialized for Speed Camera (HIGH RISK)');

    // เริ่ม security monitoring ทุก 30 วินาที (ยกเว้นใน Debug Mode)
    if (!kDebugMode) {
      _securityCheckTimer =
          Timer.periodic(const Duration(seconds: 30), (timer) {
        _performSecurityCheck();
      });
    } else {
      print('🔧 Debug Mode: Security monitoring disabled');
    }

    // บันทึกเวลาเริ่มต้น session
    _sessionStartTime = DateTime.now();
  }

  // ==================== AUTO-REFRESH SYSTEM ====================

  /// ตรวจจับการเปลี่ยนแปลงสถานะแอป สำหรับ Auto-Refresh หลังจากโหวต
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    print('🔄 App lifecycle changed: $state');

    switch (state) {
      case AppLifecycleState.resumed:
        print('� App resumed - checking for voting refresh needs');

        // ตรวจสอบว่าเพิ่งโหวตเสร็จหรือไม่
        final shouldRefreshAfterVoting = _hasJustVoted ||
            (_lastVotingTime != null &&
                DateTime.now().difference(_lastVotingTime!) <
                    _votingRefreshWindow);

        if (shouldRefreshAfterVoting) {
          print(
              '🗳️ Detected recent voting activity - triggering auto-refresh');
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              _refreshSpeedCamerasAfterVoting();
            }
          });

          // รีเซ็ตสถานะการโหวต
          _hasJustVoted = false;
        } else {
          print('📱 Regular app resume - performing standard refresh');
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              _refreshSpeedCamerasAfterVoting();
            }
          });
        }
        break;
      case AppLifecycleState.paused:
        print('📱 App paused');
        break;
      case AppLifecycleState.inactive:
        print('📱 App inactive');
        break;
      case AppLifecycleState.detached:
        print('📱 App detached');
        break;
      case AppLifecycleState.hidden:
        print('📱 App hidden');
        break;
    }
  }

  /// รีเฟรชข้อมูลกล้องจับความเร็วหลังจากโหวต
  Future<void> _refreshSpeedCamerasAfterVoting() async {
    try {
      print('🔄 === AUTO-REFRESH AFTER VOTING ===');
      print('🔄 Starting comprehensive camera data refresh...');

      // แสดงแจ้งเตือนว่ากำลังรีเฟรช
      if (mounted) {
        _showBadgeAlert(
          'กำลังอัปเดตข้อมูลกล้อง...',
          Colors.green,
          2000, // 2 วินาที
        );
      }

      // ขั้นตอนที่ 1: รอให้ข้อมูลซิงค์จาก server
      await Future.delayed(const Duration(milliseconds: 1000));

      print('🔄 Step 1: Loading updated speed camera data...');

      // โหลดข้อมูลกล้องใหม่ผ่าน method เดิมที่มี force refresh ในตัว
      await _loadSpeedCameras();

      // ขั้นตอนที่ 2: ตรวจสอบว่าได้ข้อมูลใหม่หรือไม่
      print('🔄 Step 2: Verifying updated camera count...');
      final totalCameras = speedCameras.length;
      print('✅ Total cameras after refresh: $totalCameras');

      // ขั้นตอนที่ 3: หากมีกล้องชุมชน ให้แสดงข้อมูล
      final communityCameras = speedCameras
          .where((camera) =>
              camera.description?.contains('Community verified') == true ||
              camera.description?.contains('ชุมชนยืนยัน') == true)
          .toList();

      if (communityCameras.isNotEmpty) {
        print(
            '🏘️ Community verified cameras found: ${communityCameras.length}');
        for (final camera in communityCameras.take(3)) {
          print('   - ${camera.roadName} (${camera.description})');
        }
      }

      if (mounted) {
        print('✅ Camera data refreshed successfully');
        print('✅ Total cameras loaded: ${speedCameras.length}');
        print('✅ Community cameras: ${communityCameras.length}');

        // แสดงแจ้งเตือนสำเร็จ
        if (communityCameras.isNotEmpty) {
          _showBadgeAlert(
            '🎉 พบกล้องใหม่ ${communityCameras.length} จุด ที่ชุมชนยืนยัน!',
            Colors.green,
            5000, // 5 วินาที
          );
        } else {
          _showBadgeAlert(
            '✅ ข้อมูลกล้องอัปเดตเรียบร้อย',
            Colors.green,
            3000, // 3 วินาที
          );
        }
      }

      print('🔄 === AUTO-REFRESH COMPLETED ===');
    } catch (e) {
      print('❌ Error refreshing camera data: $e');

      // ถ้าเกิดข้อผิดพลาด ให้แสดงข้อความแจ้งเตือน
      if (mounted) {
        _showBadgeAlert(
          '⚠️ ไม่สามารถอัปเดตข้อมูลได้',
          Colors.orange,
          3000, // 3 วินาที
        );
      }
    }
  }

  // ==================== SMART LOGIN DETECTION SYSTEM ====================

  /// เริ่มระบบตรวจจับพฤติกรรมการใช้งานเพื่อเด้งล็อกอิน
  void _initializeSmartLoginDetection() {
    // ถ้าผู้ใช้ล็อกอินอยู่แล้ว ไม่ต้องทำอะไร
    if (AuthService.isLoggedIn) return;

    print('🔍 Initializing smart login detection...');

    // เริ่ม timer สำหรับเด้งล็อกอินหลังจากเวลาที่กำหนด (fallback)
    _loginPromptTimer = Timer(_maxTimeBeforePrompt, () {
      if (!_hasShownLoginPrompt && !AuthService.isLoggedIn) {
        _showSmartLoginPrompt('time_based');
      }
    });
  }

  /// ตรวจสอบเงื่อนไขการเด้งล็อกอิน
  void _checkLoginPromptConditions() {
    // ถ้าเด้งแล้วหรือล็อกอินอยู่แล้ว ไม่ต้องทำอะไร
    if (_hasShownLoginPrompt || AuthService.isLoggedIn) return;

    bool shouldPrompt = false;
    String reason = '';

    // เงื่อนไขที่ 1: เคลื่อนไหวและเดินทางระยะทางพอสมควร
    if (_movementCount >= _minMovementCount &&
        _totalDistanceTraveled >= _minTravelDistance) {
      shouldPrompt = true;
      reason = 'movement_based';
    }

    // เงื่อนไขที่ 2: มีการโต้ตอบกับแอปพอสมควร
    if (_appInteractionCount >= _minInteractionCount) {
      shouldPrompt = true;
      reason =
          reason.isEmpty ? 'interaction_based' : '${reason}_and_interaction';
    }

    // เงื่อนไขที่ 3: ใช้งานมาระยะหนึ่งแล้ว (มีการเคลื่อนไหวและโต้ตอบ)
    if (_firstMovementTime != null &&
        DateTime.now().difference(_firstMovementTime!).inSeconds >= 30 &&
        _movementCount >= 2 &&
        _appInteractionCount >= 1) {
      shouldPrompt = true;
      reason = reason.isEmpty ? 'usage_pattern' : '${reason}_and_usage';
    }

    if (shouldPrompt) {
      _showSmartLoginPrompt(reason);
    }
  }

  /// แสดงหน้าล็อกอินแบบ Smart พร้อมข้อความที่เหมาะสม
  void _showSmartLoginPrompt(String reason) {
    if (_hasShownLoginPrompt) return;
    _hasShownLoginPrompt = true;

    print('📱 Showing smart login prompt: $reason');

    // ยกเลิก timer หากมี
    _loginPromptTimer?.cancel();

    String title = 'เพื่อประสบการณ์ที่ดีขึ้น';
    String message = '';

    switch (reason) {
      case 'movement_based':
        message =
            'เราเห็นว่าคุณกำลังใช้งานแอปจริงๆ\nล็อกอินเพื่อบันทึกสถิติการเดินทางและมีส่วนร่วมกับชุมชนครับ';
        break;
      case 'interaction_based':
        message =
            'ดูเหมือนคุณสนใจข้อมูลกล้องความเร็ว\nล็อกอินเพื่อรายงานกล้องใหม่และโหวตข้อมูลได้ครับ';
        break;
      case 'time_based':
        message =
            'คุณใช้แอปมาสักพักแล้ว\nล็อกอินเพื่อปลดล็อกฟีเจอร์เพิ่มเติมไหมครับ';
        break;
      default:
        message =
            'ล็อกอินเพื่อใช้งานฟีเจอร์เต็มรูปแบบ\nรายงานกล้อง โหวต และบันทึกสถิติการเดินทาง';
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ไอคอน
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1158F2).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.account_circle,
                    size: 40,
                    color: Color(0xFF1158F2),
                  ),
                ),
                const SizedBox(height: 20),

                // หัวข้อ
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'NotoSansThai',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // ข้อความ
                Text(
                  message,
                  style: const TextStyle(
                    fontFamily: 'NotoSansThai',
                    fontSize: 14,
                    color: Colors.black54,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // ปุ่ม
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'ไว้ทีหลัง',
                          style: TextStyle(
                            fontFamily: 'NotoSansThai',
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.of(context).pop();

                          final success =
                              await AuthService.showLoginDialog(context);
                          if (success) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'ล็อกอินสำเร็จ! ยินดีต้อนรับครับ',
                                    style:
                                        TextStyle(fontFamily: 'NotoSansThai'),
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1158F2),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'ล็อกอิน',
                          style: TextStyle(
                            fontFamily: 'NotoSansThai',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// บันทึกการเคลื่อนไหวสำหรับระบบ Smart Login Detection
  void _recordMovementForLoginDetection(LatLng newPosition) {
    // เพิ่มจำนวนการเคลื่อนไหว
    _movementCount++;

    // บันทึกเวลาเคลื่อนไหวครั้งแรก
    if (_firstMovementTime == null) {
      _firstMovementTime = DateTime.now();
    }

    // คำนวณระยะทางที่เดินทาง
    if (_lastMovementPosition != null) {
      final distance = Geolocator.distanceBetween(
        _lastMovementPosition!.latitude,
        _lastMovementPosition!.longitude,
        newPosition.latitude,
        newPosition.longitude,
      );
      _totalDistanceTraveled += distance;
    }

    _lastMovementPosition = newPosition;

    // ตรวจสอบเงื่อนไขการเด้งล็อกอิน
    _checkLoginPromptConditions();
  }

  /// บันทึกการโต้ตอบกับแอปสำหรับระบบ Smart Login Detection
  void _recordAppInteraction() {
    _appInteractionCount++;
    _checkLoginPromptConditions();
  }

  // ==================== SMART SECURITY VALIDATION ====================

  /// ตรวจสอบการทำงานด้วย Smart Security Service (Hybrid Mode)
  bool _validateSpeedCameraActionSimple(String action) {
    try {
      // ใช้ Smart Security Level เป็นเกณฑ์พื้นฐาน
      final currentLevel = SmartSecurityService.getCurrentSecurityLevel();

      // ถ้าเป็น High Security Level (Speed Camera) ให้ตรวจสอบเข้มงวดขึ้น
      if (currentLevel == SecurityLevel.high) {
        // ตรวจสอบเวลาการใช้งาน
        final sessionDuration = DateTime.now().difference(_sessionStartTime);
        if (sessionDuration.inHours > 6) {
          print('🔒 Session too long for high security action: $action');
          _isSecurityModeActive = true;
          return false;
        }

        // ตรวจสอบความเร็วที่สมเหตุสมผล
        if (currentSpeed > 200) {
          print('🔒 Unrealistic speed detected: ${currentSpeed.toInt()} km/h');
          return false;
        }
      }

      return true;
    } catch (e) {
      print('❌ Security validation error: $e');
      return true; // ให้ผ่านในกรณีที่เกิดข้อผิดพลาด
    }
  }

  // ==================== SECURITY & ANTI-ABUSE SYSTEM ====================

  /// ตรวจสอบความปลอดภัยและพฤติกรรมผิดปกติ
  void _performSecurityCheck() {
    final now = DateTime.now();
    final sessionDuration = now.difference(_sessionStartTime);

    // ใช้ Smart Security แทน legacy security service
    print('🔒 Smart Security monitoring active');

    // ตรวจสอบ: การใช้งานนานเกินไป (บอกเป็นนัยว่าอาจใช้เพื่อหลีกเลี่ยงการจับ)
    if (sessionDuration.inHours > 8) {
      _trackSuspiciousActivity('long_session', 'Session longer than 8 hours');
    }

    // ตรวจสอบ: ความเร็วผิดปกติ
    if (_speedHistory.length >= 5) {
      final avgSpeed =
          _speedHistory.map((p) => p.speed * 3.6).reduce((a, b) => a + b) /
              _speedHistory.length;
      if (avgSpeed > _maxReasonableSpeed) {
        _trackSuspiciousActivity(
            'unrealistic_speed', 'Average speed: ${avgSpeed.toInt()} km/h');
      } else {
        _lastValidSpeed = avgSpeed; // เก็บความเร็วที่ถูกต้อง
      }
    }

    // ตรวจสอบ: การเปลี่ยนตำแหน่งแบบกระโดด (GPS spoofing)
    if (_previousLatitude != null && _previousLongitude != null) {
      final distance = Geolocator.distanceBetween(
        _previousLatitude!,
        _previousLongitude!,
        currentPosition.latitude,
        currentPosition.longitude,
      );

      final timeDiff = _lastLocationUpdateTime != null
          ? now.difference(_lastLocationUpdateTime!).inSeconds
          : 1;

      if (distance > _maxLocationJump && timeDiff < 5) {
        _trackSuspiciousActivity(
            'location_jump', 'Jumped ${distance.toInt()}m in ${timeDiff}s');
      }
    }

    // อัพเดตตำแหน่งก่อนหน้า
    _previousLatitude = currentPosition.latitude;
    _previousLongitude = currentPosition.longitude;
    _lastLocationUpdateTime = now;

    // ตรวจสอบสถานะความปลอดภัย
    _evaluateSecurityStatus();
  }

  /// ตรวจสอบความน่าเชื่อถือของ GPS
  bool _isGpsTrusted(Position position) {
    // ตรวจสอบความแม่นยำ
    if (position.accuracy > _maxAcceptableAccuracy) {
      _gpsAnomalyCount++;
      print('⚠️ GPS accuracy too low: ${position.accuracy}m');
      return false;
    }

    // ตรวจสอบความแม่นยำความเร็ว
    if (position.speedAccuracy > _maxAcceptableSpeedAccuracy) {
      _gpsAnomalyCount++;
      print('⚠️ GPS speed accuracy too low: ${position.speedAccuracy}');
      return false;
    }

    // ตรวจสอบการกระโดดตำแหน่งผิดปกติ
    if (_lastTrustedPosition != null) {
      final distance = Geolocator.distanceBetween(
        _lastTrustedPosition!.latitude,
        _lastTrustedPosition!.longitude,
        position.latitude,
        position.longitude,
      );

      final timeDiff = position.timestamp
          .difference(_lastTrustedPosition!.timestamp)
          .inSeconds;
      final maxPossibleDistance =
          (position.speed * timeDiff) + 100; // เผื่อ 100m

      if (distance > maxPossibleDistance && distance > 500) {
        _gpsAnomalyCount++;
        print('⚠️ Impossible GPS jump: ${distance}m in ${timeDiff}s');
        return false;
      }
    }

    // ตรวจสอบความเร็วผิดปกติ
    final speedKmh = position.speed * 3.6;
    if (speedKmh > _maxReasonableSpeed) {
      _gpsAnomalyCount++;
      print('⚠️ Unrealistic speed: ${speedKmh}km/h');
      return false;
    }

    // ถ้าผ่านการตรวจสอบทั้งหมด
    _lastTrustedPosition = position;
    if (_gpsAnomalyCount > 0) {
      _gpsAnomalyCount--; // ลดค่าความผิดปกติเมื่อมีข้อมูลที่ถูกต้อง
    }

    return true;
  }

  /// ตรวจสอบช่วงเวลาการใช้งาน
  void _checkSessionDuration() {
    final now = DateTime.now();
    final sessionLength = now.difference(_sessionStartTime);

    if (sessionLength > _maxSessionDuration) {
      _trackSuspiciousActivity(
          'long_session', 'Session duration: ${sessionLength.inHours} hours');
    }
  }

  /// ติดตามกิจกรรมที่น่าสงสัย
  void _trackSuspiciousActivity(String type, String details) {
    _suspiciousActivityCount++;

    print('🚨 Suspicious activity detected: $type - $details');
    print('🚨 Total suspicious activities: $_suspiciousActivityCount');

    // บันทึกลงใน analytics (อนาคตอาจส่งไป server)
    if (mounted) {
      // ส่งข้อมูลไป analytics หรือ logging service
      _logSecurityEvent(type, details);
    }
  }

  /// ประเมินสถานะความปลอดภัยและดำเนินการตามนั้น
  void _evaluateSecurityStatus() {
    if (_suspiciousActivityCount >= _maxSuspiciousActivity) {
      if (!_isSecurityModeActive) {
        _activateSecurityMode();
      }
    }
  }

  /// เปิดใช้โหมดความปลอดภัย
  void _activateSecurityMode() {
    _isSecurityModeActive = true;

    print('🔴 SECURITY MODE ACTIVATED');
    print(
        '🔴 Limiting app functionality for ${_securityCooldown.inMinutes} minutes');

    // แสดงแจ้งเตือนให้ผู้ใช้
    if (mounted) {
      _showBadgeAlert(
        '🔒 ระบบตรวจพบการใช้งานผิดปกติ',
        Colors.orange,
        10000, // 10 วินาที
      );
    }

    // ลดการทำงานของระบบ
    _progressiveBeepTimer?.cancel();
    _badgeResetTimer?.cancel();

    // ตั้งเวลาปิดโหมดความปลอดภัย
    Timer(_securityCooldown, () {
      _deactivateSecurityMode();
    });
  }

  /// ปิดโหมดความปลอดภัย
  void _deactivateSecurityMode() {
    _isSecurityModeActive = false;
    _suspiciousActivityCount = 0;

    print('🟢 Security mode deactivated');

    if (mounted) {
      _showBadgeAlert(
        '✅ ระบบกลับสู่การทำงานปกติ',
        Colors.green,
        5000, // 5 วินาที
      );
    }
  }

  /// บันทึกเหตุการณ์ความปลอดภัย
  void _logSecurityEvent(String eventType, String details) {
    final event = {
      'timestamp': DateTime.now().toIso8601String(),
      'type': eventType,
      'details': details,
      'session_duration':
          DateTime.now().difference(_sessionStartTime).inMinutes,
      'current_speed': currentSpeed.toInt(),
      'last_valid_speed':
          _lastValidSpeed?.toInt() ?? 0, // ใช้ความเร็วที่ถูกต้องล่าสุด
      'suspicious_count': _suspiciousActivityCount,
    };

    print('📊 Security Event Logged: $event');
    // ในอนาคตอาจส่งไป Firebase Analytics หรือ logging service
  }

  // ==================== RESOURCE PROTECTION SYSTEM ====================

  /// เริ่มตรวจสอบการใช้ทรัพยากร
  void _startResourceMonitoring() {
    print('📊 Starting resource monitoring...');

    // ตรวจสอบการใช้ทรัพยากรทุกนาที
    _resourceMonitorTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkResourceUsage();
      // Reset minute counters for the Smart Security Service
      print('🔄 Resetting security counters');
    });
  }

  /// ตรวจสอบการใช้ทรัพยากรมากเกินไป
  void _checkResourceUsage() {
    final now = DateTime.now();

    // รีเซ็ตตัวนับการเคลื่อนไหวแผนที่ทุก 5 นาที (เปลี่ยนจาก 1 นาที)
    if (_lastMapMovement != null &&
        now.difference(_lastMapMovement!).inMinutes >= 5) {
      print('📊 Map movements in last 5 minutes: $_mapMovementCount');

      if (_mapMovementCount > _maxMapMovements) {
        _trackSuspiciousActivity('excessive_map_movement',
            'Map moved $_mapMovementCount times in 5 minutes');
      }

      _mapMovementCount = 0;
      _lastMapMovement = now;
    }

    // ตรวจสอบ memory และ performance metrics
    _checkPerformanceMetrics();
  }

  /// ตรวจสอบ performance metrics
  void _checkPerformanceMetrics() {
    // ตรวจสอบจำนวน timer ที่ทำงาน
    final activeTimers = [
      _progressiveBeepTimer,
      _badgeResetTimer,
      _followModeResetTimer,
      _securityCheckTimer,
      _resourceMonitorTimer,
      _connectionCheckTimer,
      _preloadTimer,
      _cameraCleanupTimer,
    ].where((timer) => timer != null).length;

    if (activeTimers > 8) {
      print('⚠️ Too many active timers: $activeTimers');
      _trackSuspiciousActivity(
          'excessive_timers', 'Active timers: $activeTimers');
    }

    // ตรวจสอบจำนวน speed cameras ที่โหลด
    if (speedCameras.length > 10000) {
      print('⚠️ Too many speed cameras loaded: ${speedCameras.length}');
    }

    print(
        '📊 Performance check - Timers: $activeTimers, Cameras: ${speedCameras.length}');
  }

  // ==================== DATA VALIDATION SYSTEM ====================

  /// ตรวจสอบความปลอดภัยก่อนเริ่ม Progressive Beep
  bool _isSecureToPlayBeep() {
    if (_isSecurityModeActive) {
      print('🔒 Progressive beep blocked - Security mode active');
      return false;
    }

    if (_suspiciousActivityCount >= _maxSuspiciousActivity / 2) {
      print('⚠️ Progressive beep limited - Suspicious activity detected');
      return false;
    }

    return true;
  }

  Future<void> _initializeSmartMapSystem() async {
    try {
      // Initialize smart map components
      await ConnectionManager.initialize();
      await MapCacheManager.initialize();

      _smartTileProvider = SmartTileProvider(
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        additionalOptions: {
          'User-Agent': 'CheckDarn Speed Camera App/1.0',
        },
      );

      // Update UI หลังจาก initialize
      if (mounted) {
        setState(() {
          // Smart tile provider พร้อมใช้งานแล้ว
        });
      }
    } catch (e) {
      print('Error initializing smart map system: $e');
    }
  }

  void _startConnectionMonitoring() {
    // Check connection every 30 seconds for background monitoring
    _connectionCheckTimer =
        Timer.periodic(const Duration(seconds: 30), (timer) async {
      await ConnectionManager.checkConnection();
      // Connection status is checked but not displayed in UI anymore
    });
  }

  Future<void> _initializeSoundManager() async {
    await _soundManager.initialize();
  }

  // ระบบล้างข้อมูลกล้องที่เตือนแล้ว - ทุก 5 นาที
  void _startCameraCleanupTimer() {
    _cameraCleanupTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      final oldSize = _alertedCameras.length;
      _alertedCameras.clear();

      print('=== CAMERA CLEANUP ===');
      print('Cleared ${oldSize} alerted cameras');
      print('Progressive Beep system reset');
      print('=====================');
    });
  }

  // ฟังก์ชันเปิด wakelock เพื่อป้องกันหน้าจอดับ
  Future<void> _enableWakelock() async {
    try {
      await WakelockPlus.enable();
      print('✅ Wakelock enabled - Screen will stay on');
    } catch (e) {
      print('❌ Failed to enable wakelock: $e');
    }
  }

  // ฟังก์ชันปิด wakelock เมื่อออกจากหน้า
  Future<void> _disableWakelock() async {
    try {
      await WakelockPlus.disable();
      print('🔒 Wakelock disabled - Screen can turn off normally');
    } catch (e) {
      print('❌ Failed to disable wakelock: $e');
    }
  }

  @override
  void dispose() {
    // ลบ WidgetsBindingObserver
    WidgetsBinding.instance.removeObserver(this);

    _positionSubscription?.cancel();
    _speedUpdateTimer?.cancel();
    _connectionCheckTimer?.cancel();
    _preloadTimer?.cancel();
    _followModeResetTimer?.cancel(); // เพิ่ม timer ใหม่
    _badgeResetTimer?.cancel(); // เพิ่ม badge timer
    _progressiveBeepTimer?.cancel(); // เพิ่ม progressive beep timer
    _cameraCleanupTimer?.cancel(); // เพิ่ม camera cleanup timer
    _loginPromptTimer?.cancel(); // เพิ่ม login prompt timer

    // ==================== SECURITY CLEANUP ====================
    _securityCheckTimer?.cancel(); // ยกเลิก security monitoring
    _resourceMonitorTimer?.cancel(); // ยกเลิก resource monitoring

    // ล้างข้อมูล security
    print('🔒 Smart Security system cleaned up');
    _speedHistory.clear();
    _alertedCameras.clear();
    _suspiciousActivityCount = 0;

    print('🔒 Security system cleaned up');
    print('📊 Resource monitoring stopped');

    _soundManager.dispose();
    mapController.dispose();
    _disableWakelock(); // ปิด wakelock เมื่อออกจากหน้า
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => isLoadingLocation = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showLocationError('ไม่ได้รับอนุญาตให้เข้าถึงตำแหน่ง');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showLocationError('กรุณาเปิดอนุญาตตำแหน่งในการตั้งค่า');
        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          currentPosition = LatLng(position.latitude, position.longitude);
          isLoadingLocation = false;
        });

        // ย้ายแผนที่ไปยังตำแหน่งปัจจุบัน (ตรวจสอบว่า FlutterMap render แล้ว)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            try {
              mapController.move(currentPosition, 15.0);
            } catch (e) {
              print('MapController not ready yet: $e');
              // ลองอีกครั้งหลัง 1 วินาที
              Future.delayed(const Duration(seconds: 1), () {
                if (mounted) {
                  try {
                    mapController.move(currentPosition, 15.0);
                  } catch (e) {
                    print('MapController still not ready: $e');
                  }
                }
              });
            }
          }
        });
      }
    } catch (e) {
      print('Error getting location: $e');
      if (mounted) {
        setState(() => isLoadingLocation = false);
        _showLocationError('ไม่สามารถระบุตำแหน่งได้');
      }
    }
  }

  Future<void> _loadSpeedCameras() async {
    try {
      final cameras = await SpeedCameraService.getSpeedCameras();
      if (mounted) {
        setState(() {
          speedCameras = cameras;
          isLoadingCameras = false;
        });
        _updateNearestCamera();
      }
    } catch (e) {
      print('Error loading speed cameras: $e');
      if (mounted) {
        setState(() => isLoadingCameras = false);
        _showError('ไม่สามารถโหลดข้อมูลกล้องจับความเร็วได้');
      }
    }
  }

  void _startSpeedTracking() {
    // ติดตามความเร็วและทิศทางการเดินทางแบบ real-time
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter:
            currentSpeed > 30 ? 8 : 5, // ปรับ distance filter ตามความเร็ว
        timeLimit: const Duration(seconds: 10), // เพิ่ม timeout
      ),
    ).listen((Position position) {
      if (mounted) {
        final newPosition = LatLng(position.latitude, position.longitude);

        // ==================== SECURITY VALIDATION ====================

        // ตรวจสอบความถูกต้องของข้อมูล GPS ด้วย Enhanced Anti-Spoofing
        if (!_isGpsTrusted(position)) {
          print('🚨 Untrusted GPS data detected, skipping update');

          // ตรวจสอบว่าควรเปิด Security Mode หรือไม่
          if (_gpsAnomalyCount >= _maxGpsAnomalies) {
            _trackSuspiciousActivity('gps_spoofing',
                'GPS anomalies: $_gpsAnomalyCount, accuracy: ${position.accuracy}m');
          }
          return;
        }

        // ตรวจสอบระยะเวลาการใช้งาน
        _checkSessionDuration();

        // เพิ่มประวัติความเร็วสำหรับการตรวจสอบความปลอดภัย
        _speedHistory.add(position);
        if (_speedHistory.length > 20) {
          _speedHistory.removeAt(0); // เก็บเฉพาะ 20 จุดล่าสุด
        }

        // ตรวจสอบความเร็วที่สมเหตุสมผล
        final speedKmh = position.speed * 3.6;
        if (speedKmh > _maxReasonableSpeed) {
          _trackSuspiciousActivity('unrealistic_speed',
              'Speed: ${speedKmh.toInt()} km/h at ${position.latitude}, ${position.longitude}');
        } else {
          _lastValidSpeed = speedKmh;
        }

        // เพิ่มประวัติตำแหน่งสำหรับระบบ Predict Movement
        _positionHistory.add(position);
        if (_positionHistory.length > 10) {
          _positionHistory.removeAt(0); // เก็บเฉพาะ 10 จุดล่าสุด
        }

        setState(() {
          currentPosition = newPosition;
          currentSpeed = position.speed * 3.6; // m/s เป็น km/h

          // บันทึกการเคลื่อนไหวสำหรับระบบ Smart Login Detection
          _recordMovementForLoginDetection(newPosition);

          // อัปเดตทิศทางการเดินทางจาก GPS (เฉพาะเมื่อเคลื่อนที่)
          if (currentSpeed > 5.0 && position.heading.isFinite) {
            // ตรวจสอบความแตกต่างของมุมก่อนการอัปเดต
            final headingDiff = (position.heading - _smoothTravelHeading).abs();
            final normalizedDiff =
                headingDiff > 180 ? 360 - headingDiff : headingDiff;

            // อัปเดตเฉพาะเมื่อมีการเปลี่ยนแปลงที่มีนัยสำคัญ (> 1.5 องศา)
            // ลดจาก 2.0 เป็น 1.5 เพื่อความไวในการตอบสนอง
            if (normalizedDiff > 1.5) {
              _smoothTravelHeading =
                  _interpolateHeading(_smoothTravelHeading, position.heading);
            }
          }
        });

        // Intelligent Auto-Follow: ย้ายกล้องตามผู้ใช้แบบอัจฉริยะ
        if (!_userIsManuallyControlling) {
          _intelligentMoveCamera(newPosition);
        }

        _updateNearestCamera();

        // ระบบ Predict Movement
        if (_positionHistory.length >= 3) {
          _predictMovementAndCheck();
        }

        // Smart preload tiles around new position
        _schedulePreloadTiles(newPosition);
      }
    });
  }

  // ระบบทำนายการเคลื่อนที่และตรวจสอบกล้องล่วงหน้า
  void _predictMovementAndCheck() {
    if (_positionHistory.length < 3) return;

    // คำนวณความเร็วและทิศทางเฉลี่ยจากประวัติ 3 จุดล่าสุด
    final recentPositions =
        _positionHistory.sublist(_positionHistory.length - 3);
    final avgSpeed =
        recentPositions.map((p) => p.speed * 3.6).reduce((a, b) => a + b) / 3;
    final avgHeading =
        recentPositions.map((p) => p.heading).reduce((a, b) => a + b) / 3;

    if (avgSpeed > 10.0 && avgHeading.isFinite) {
      // ทำนายตำแหน่งล่วงหน้า 10 วินาที
      final predictedDistanceMeters =
          (avgSpeed / 3.6) * 10; // แปลงเป็น m/s * 10 วินาที

      try {
        final predictedLat = currentPosition.latitude +
            (predictedDistanceMeters * cos(avgHeading * pi / 180)) / 111000;
        final predictedLng = currentPosition.longitude +
            (predictedDistanceMeters * sin(avgHeading * pi / 180)) /
                (111000 * cos(currentPosition.latitude * pi / 180));

        _predictedPosition = LatLng(predictedLat, predictedLng);

        // ตรวจสอบกล้องในเส้นทางที่ทำนาย
        _checkPredictedPath();
      } catch (e) {
        // ถ้าคำนวณผิดพลาด ใช้วิธีง่ายๆ
        print('Prediction calculation error: $e');
      }
    }
  }

  // ตรวจสอบกล้องในเส้นทางที่ทำนาย
  void _checkPredictedPath() {
    if (_predictedPosition == null) return;

    _predictedCameras.clear();

    for (final camera in speedCameras) {
      final distanceToPredicted = Geolocator.distanceBetween(
        _predictedPosition!.latitude,
        _predictedPosition!.longitude,
        camera.location.latitude,
        camera.location.longitude,
      );

      // ถ้ากล้องอยู่ใกล้เส้นทางที่ทำนาย (ภายใน 200 เมตร)
      if (distanceToPredicted <= 200) {
        final cameraDirection = Geolocator.bearingBetween(
          currentPosition.latitude,
          currentPosition.longitude,
          camera.location.latitude,
          camera.location.longitude,
        );

        // ตรวจสอบว่ากล้องอยู่ในทิศทางการเดินทาง
        if (_isCameraInTravelDirection(cameraDirection)) {
          _predictedCameras.add(camera);
        }
      }
    }

    // แจ้งเตือนล่วงหน้าถ้ามีกล้องในเส้นทาง
    if (_predictedCameras.isNotEmpty && currentSpeed > 50) {
      _showPredictiveAlert();
    }
  }

  // แจ้งเตือนเชิงทำนาย
  void _showPredictiveAlert() {
    final now = DateTime.now();
    // แจ้งเตือนทุก 30 วินาที เพื่อไม่ให้รบกวนมากเกินไป
    if (_lastAlertTime != null &&
        now.difference(_lastAlertTime!).inSeconds < 30) {
      return;
    }

    _lastAlertTime = now;
    final nearestPredicted = _predictedCameras.first;

    // สร้างข้อความที่ sync กัน
    const badgeMessage = '🔮 จะพบกล้องใน 10 วินาที';
    final ttsMessage =
        'คาดการณ์ จะพบกล้องจับความเร็วใน 10 วินาที บน ${nearestPredicted.roadName} จำกัด ${nearestPredicted.speedLimit} กิโลเมตรต่อชั่วโมง';

    // Debug log
    print('=== PREDICTIVE ALERT SYNC ===');
    print('Badge: "$badgeMessage"');
    print('TTS: "$ttsMessage"');

    // เล่นเสียงแจ้งเตือน
    _soundManager.playPredictiveAlert(
      message: ttsMessage,
      roadName: nearestPredicted.roadName,
      speedLimit: nearestPredicted.speedLimit,
    );

    // แสดงแจ้งเตือนใน Badge
    _showBadgeAlert(
      badgeMessage,
      const Color(0xFF1158F2),
      6000, // 6 วินาที
    );
  }

  // ระบบเคลื่อนไหวกล้องอัจฉริยะ - ปรับตามความเร็วและพฤติกรรม
  void _intelligentMoveCamera(LatLng newPosition) {
    try {
      // คำนวณความเร็วการเคลื่อนไหวตามความเร็วของยานพาหนะ
      double targetZoom = mapController.camera.zoom;

      // ปรับ zoom อัตโนมัติตามความเร็ว - ปรับปรุงให้นุ่มนวลขึ้น
      if (currentSpeed < 30) {
        targetZoom = 16.5; // ซูมใกล้เมื่อขับช้า
      } else if (currentSpeed < 60) {
        targetZoom = 15.5; // ซูมกลางเมื่อขับปกติ
      } else if (currentSpeed < 90) {
        targetZoom = 14.5; // ซูมไกลเมื่อขับเร็ว
      } else {
        targetZoom = 13.5; // ซูมไกลมากเมื่อขับเร็วมาก
      }

      // เคลื่อนไหวแบบนุ่มนวลพร้อมปรับ zoom - ใช้ค่า target zoom ที่คำนวณได้
      final currentZoom = mapController.camera.zoom;
      final smoothZoom = currentZoom +
          ((targetZoom - currentZoom) * 0.1); // Gradual zoom change

      mapController.move(newPosition, smoothZoom);
    } catch (e) {
      print('MapController error in intelligent camera movement: $e');
    }
  }

  // ตรวจจับการโต้ตอบของผู้ใช้กับแผนที่
  void _onMapInteraction() {
    final now = DateTime.now();

    // บันทึกการโต้ตอบสำหรับระบบ Smart Login Detection
    _recordAppInteraction();

    // ==================== SMART SECURITY CHECK ====================

    // ตรวจสอบด้วย Smart Security Service
    if (!_validateSpeedCameraActionSimple('map_interaction')) {
      print('🔒 Map interaction blocked by Smart Security');
      return;
    }

    // นับการเคลื่อนไหวแผนที่แบบ throttled (ทุก 100ms)
    if (_lastMapMovement == null ||
        now.difference(_lastMapMovement!).inMilliseconds >= 100) {
      _mapMovementCount++;
      _lastMapMovement = now;
    }

    // ตรวจสอบการใช้งานมากเกินไป (แต่ throttle warnings)
    if (_mapMovementCount > _maxMapMovements) {
      // เตือนเฉพาะเมื่อผ่านไป 10 วินาทีจากการเตือนครั้งล่าสุด
      if (_lastExcessiveWarning == null ||
          now.difference(_lastExcessiveWarning!).inSeconds >=
              _warningThrottle.inSeconds) {
        print(
            '⚠️ Excessive map interaction detected: $_mapMovementCount movements');
        _trackSuspiciousActivity(
            'excessive_map_interaction', 'Map moved $_mapMovementCount times');

        _lastExcessiveWarning = now;
      }

      // ลิมิตการทำงานถ้าใช้งานมากเกินไป
      if (_isSecurityModeActive) {
        print('🔒 Map interaction blocked - Security mode active');
        return;
      }
    }

    setState(() {
      _userIsManuallyControlling = true;
      _lastUserInteraction = now;
    });

    // ยกเลิก timer เก่า
    _followModeResetTimer?.cancel();

    // คำนวณเวลาที่ผ่านไปนับจากการโต้ตอบครั้งล่าสุด
    final timeSinceLastInteraction = _lastUserInteraction != null
        ? now.difference(_lastUserInteraction!).inSeconds
        : 0;

    // ปรับเวลารอตามความถี่ของการโต้ตอบ
    final waitTime = timeSinceLastInteraction < 5
        ? const Duration(seconds: 15) // รอนานขึ้นถ้าโต้ตอบบ่อย
        : const Duration(seconds: 10); // เวลาปกติ

    // ตั้ง timer ใหม่เพื่อกลับมา auto-follow
    _followModeResetTimer = Timer(waitTime, () {
      if (mounted) {
        setState(() {
          _userIsManuallyControlling = false;
        });

        // ไม่แจ้งเตือน - ให้ไอคอนเล็กๆ บอกสถานะก็พอ
      }
    });
  }

  double _interpolateHeading(double currentHeading, double targetHeading) {
    // คำนวณมุมที่สั้นที่สุดสำหรับการหมุน (จัดการกับ 360 -> 0 degrees)
    double diff = targetHeading - currentHeading;

    if (diff > 180) {
      diff -= 360;
    } else if (diff < -180) {
      diff += 360;
    }

    // Adaptive smooth interpolation - ปรับตามความเร็วแบบละเอียด
    double smoothFactor = 0.25; // ค่าเริ่มต้นลดลงเพื่อความนุ่มนวล

    // ปรับตามความเร็วแบบ gradient
    if (currentSpeed > 80) {
      smoothFactor = 0.6; // ความเร็วสูงมาก = การเปลี่ยนทิศทางเร็วมาก
    } else if (currentSpeed > 60) {
      smoothFactor = 0.5; // ความเร็วสูง = การเปลี่ยนทิศทางเร็วขึ้น
    } else if (currentSpeed > 40) {
      smoothFactor = 0.35; // ความเร็วปานกลาง
    } else if (currentSpeed > 20) {
      smoothFactor = 0.3; // ความเร็วต่ำ
    } else if (currentSpeed > 5) {
      smoothFactor = 0.2; // ความเร็วต่ำมาก = การเปลี่ยนทิศทางช้าลง
    } else {
      smoothFactor = 0.1; // เกือบหยุด = การเปลี่ยนทิศทางช้ามาก
    }

    // เพิ่มการปกป้องจากการกระโดดมุมมาก - ปรับปรุงการคำนวณ
    if (diff.abs() > 60) {
      smoothFactor *= 0.3; // ลดมากเมื่อมุมต่างมากกว่า 60 องศา
    } else if (diff.abs() > 30) {
      smoothFactor *= 0.5; // ลดปานกลางเมื่อมุมต่างมากกว่า 30 องศา
    } else if (diff.abs() > 15) {
      smoothFactor *= 0.7; // ลดเล็กน้อยเมื่อมุมต่างมากกว่า 15 องศา
    }

    // คำนวณทิศทางใหม่
    final newHeading = currentHeading + (diff * smoothFactor);

    // ให้แน่ใจว่าผลลัพธ์อยู่ในช่วง 0-360 องศา
    if (newHeading < 0) {
      return newHeading + 360;
    } else if (newHeading >= 360) {
      return newHeading - 360;
    }

    return newHeading;
  }

  // Smart tile preloading with performance optimization
  void _schedulePreloadTiles(LatLng position) {
    // Cancel existing timer
    _preloadTimer?.cancel();

    // ปรับเวลา preload ตามความเร็ว
    final preloadDelay = currentSpeed > 50
        ? const Duration(milliseconds: 1500) // ความเร็วสูง = preload เร็วขึ้น
        : const Duration(seconds: 2);

    _preloadTimer = Timer(preloadDelay, () async {
      try {
        // ตรวจสอบว่า SmartTileProvider และ MapController พร้อมใช้งาน
        if (_smartTileProvider != null) {
          final zoom = mapController.camera.zoom.round();
          // ปรับ radius ตามความเร็ว
          final radius = currentSpeed > 60 ? 3 : 2;
          await _smartTileProvider!
              .preloadTilesAround(position, zoom, radius: radius);
        }
      } catch (e) {
        print('Error preloading tiles: $e');
        // ถ้า MapController ไม่พร้อม ใช้ zoom level เริ่มต้น
        try {
          if (_smartTileProvider != null) {
            await _smartTileProvider!
                .preloadTilesAround(position, 15, radius: 2);
          }
        } catch (e2) {
          print('Error preloading tiles with default zoom: $e2');
        }
      }
    });
  }

  void _updateNearestCamera() {
    if (speedCameras.isEmpty) return;

    double minDistance = double.infinity;
    SpeedCamera? closest;
    double cameraDirection = 0.0;

    for (final camera in speedCameras) {
      final distance = Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        camera.location.latitude,
        camera.location.longitude,
      );

      if (distance < minDistance) {
        minDistance = distance;
        closest = camera;
        // คำนวณทิศทางของกล้องเทียบกับตำแหน่งปัจจุบัน
        cameraDirection = Geolocator.bearingBetween(
          currentPosition.latitude,
          currentPosition.longitude,
          camera.location.latitude,
          camera.location.longitude,
        );
      }
    }

    setState(() {
      nearestCamera = closest;
      distanceToNearestCamera = minDistance;
    });

    // รีเซ็ตกล้องที่เตือนแล้วเมื่อห่างเกิน 100 เมตร
    if (closest != null && minDistance > 100) {
      final removedCount = _alertedCameras.length;
      _alertedCameras.removeWhere((cameraId) {
        // หาระยะทางของกล้องที่เตือนแล้วทั้งหมด
        final alertedCamera = speedCameras.firstWhere(
          (cam) => cam.id == cameraId,
          orElse: () => speedCameras.first, // fallback ถ้าไม่เจอ
        );
        final distanceToAlertedCamera = Geolocator.distanceBetween(
          currentPosition.latitude,
          currentPosition.longitude,
          alertedCamera.location.latitude,
          alertedCamera.location.longitude,
        );
        return distanceToAlertedCamera > 100; // ลบออกถ้าห่างเกิน 100 เมตร
      });

      if (removedCount != _alertedCameras.length) {
        print('=== CAMERA RESET BY DISTANCE ===');
        print(
            'Removed ${removedCount - _alertedCameras.length} cameras from alerted list');
        print('Remaining alerted cameras: ${_alertedCameras.length}');
        print('=================================');
      }
    }

    // แจ้งเตือนอัจฉริยะตามความเร็วและทิศทาง
    if (closest != null) {
      _checkAdvancedWarning(closest, minDistance, cameraDirection);
    }
  }

  // แจ้งเตือนอัจฉริยะตามความเร็ว ทิศทาง และระยะทาง
  void _checkAdvancedWarning(
      SpeedCamera camera, double distance, double cameraDirection) {
    final alertDistance =
        _calculateOptimalAlertDistance(currentSpeed, camera.speedLimit);

    if (distance <= alertDistance) {
      // ตรวจสอบว่ากล้องอยู่ในทิศทางการเดินทาง (±45 องศา)
      final isInTravelDirection = _isCameraInTravelDirection(cameraDirection);

      // แจ้งเตือนเฉพาะเมื่อกล้องอยู่ด้านหน้าและเร็วเกินกำหนด
      if (isInTravelDirection && currentSpeed > camera.speedLimit) {
        _showAdvancedSpeedAlert(camera, distance, isInTravelDirection);
      } else if (isInTravelDirection && distance <= 300) {
        // แจ้งเตือนเบาๆ เมื่อใกล้กล้อง (ไม่ขึ้นกับความเร็ว)
        _showProximityAlert(camera, distance);
      }
    }

    // Progressive Beep Alert - เมื่ออยู่ในระยะ 50 เมตร และเคลื่อนที่
    if (distance <= 50 && currentSpeed > 5.0) {
      final isInTravelDirection = _isCameraInTravelDirection(cameraDirection);
      if (isInTravelDirection) {
        _startProgressiveBeep(camera, distance);
      }
    } else if (distance > 60 || currentSpeed <= 5.0) {
      // หยุด Progressive Beep เมื่อห่างจากกล้อง หรือหยุด/ขับช้าเกินไป (ไฟแดง/ติดรถ)
      _stopProgressiveBeep();
    }

    // ตรวจสอบเมื่ออยู่ใกล้กล้องมาก (≤ 50m)
    if (distance <= 50 && currentSpeed > 10) {
      _logCameraPassing(camera);
    }
  }

  // บันทึกสถิติการใกล้กล้อง
  void _logCameraPassing(SpeedCamera camera) {
    final wasOverSpeed = currentSpeed > camera.speedLimit;

    // หยุด Progressive Beep เมื่ออยู่ใกล้กล้องมาก (≤ 50m)
    _stopProgressiveBeep();

    // เล่นเสียงแจ้งเตือนเมื่ออยู่ใกล้กล้อง
    if (wasOverSpeed) {
      _soundManager.playProximityAlert(
        message: 'อยู่ใกล้กล้องจับความเร็ว โปรดลดความเร็ว',
        distance: 50.0,
      );

      // แสดงแจ้งเตือนใน Badge
      _showBadgeAlert(
        '⚠️ อยู่ใกล้กล้อง โปรดลดความเร็ว',
        Colors.orange,
        5000, // 5 วินาที
      );
    } else {
      _soundManager.playProximityAlert(
        message: 'อยู่ใกล้กล้องจับความเร็ว ความเร็วเหมาะสม',
        distance: 50.0,
      );

      // แสดงแจ้งเตือนใน Badge
      _showBadgeAlert(
        '✅ อยู่ใกล้กล้อง ความเร็วเหมาะสม',
        Colors.green,
        4000, // 4 วินาที
      );
    }

    print('Near camera: ${camera.roadName}, Speed: ${currentSpeed.toInt()}, '
        'Limit: ${camera.speedLimit}, Over: $wasOverSpeed');

    // อาจจะส่งข้อมูลไป Analytics ในอนาคต
  }

  // คำนวณ Beep Interval ตามระยะทาง - Progressive Timing
  int _calculateBeepInterval(double distance) {
    if (distance <= 10) {
      return 500; // 0.5 วินาที (ติดๆ)
    } else if (distance <= 20) {
      return 1000; // 1 วินาที
    } else if (distance <= 30) {
      return 2000; // 2 วินาที
    } else if (distance <= 50) {
      return 3000; // 3 วินาที
    } else {
      return 0; // ไม่เล่นเสียง
    }
  }

  // เริ่ม Progressive Beep Alert
  void _startProgressiveBeep(SpeedCamera camera, double distance) {
    // ==================== SMART SECURITY CHECK ====================

    // ตรวจสอบความปลอดภัยด้วย Smart Security Service
    if (!_validateSpeedCameraActionSimple('progressive_beep')) {
      print('🔒 Progressive beep blocked by Smart Security');
      return;
    }

    // ตรวจสอบว่าเตือนกล้องนี้แล้วหรือยัง
    if (_alertedCameras.contains(camera.id)) {
      print('=== PROGRESSIVE BEEP SKIPPED ===');
      print('Camera already alerted: ${camera.roadName}');
      print('Distance: ${distance.toInt()}m');
      print('Reason: Preventing duplicate alerts');
      print('=================================');
      return; // เคยเตือนแล้ว ไม่เตือนซ้ำ
    }

    // ตรวจสอบว่าเป็นกล้องเดียวกันและระยะใกล้เคียงกันหรือไม่
    if (_currentBeepCamera?.id == camera.id &&
        (distance - _lastBeepDistance).abs() < 5) {
      return; // ไม่ต้องเริ่มใหม่ถ้าเป็นกล้องเดียวกันและระยะไม่เปลี่ยนมาก
    }

    // เพิ่มกล้องเข้าลิสต์ที่เตือนแล้ว
    _alertedCameras.add(camera.id);

    // หยุด Progressive Beep เก่า
    _stopProgressiveBeep();

    // เริ่ม Progressive Beep ใหม่
    _currentBeepCamera = camera;
    _lastBeepDistance = distance;
    _isProgressiveBeepActive = true;

    final beepInterval = _calculateBeepInterval(distance);
    if (beepInterval > 0) {
      print('=== PROGRESSIVE BEEP START ===');
      print('Camera: ${camera.roadName}');
      print('Distance: ${distance.toInt()}m');
      print('Beep interval: ${beepInterval}ms');
      print('Added to alerted list: ${camera.id}');
      print('Total alerted cameras: ${_alertedCameras.length}');
      print(
          'Security status: ${_isSecurityModeActive ? "RESTRICTED" : "NORMAL"}');
      print('================================');

      // เล่นเสียงทันที
      _soundManager.playProgressiveBeep();

      // ตั้ง Timer สำหรับเสียงต่อไป
      _progressiveBeepTimer = Timer.periodic(
        Duration(milliseconds: beepInterval),
        (timer) {
          if (!_isProgressiveBeepActive || !mounted) {
            timer.cancel();
            return;
          }

          // ตรวจสอบความปลอดภัยอีกครั้งก่อนเล่นเสียงต่อไป
          if (!_isSecureToPlayBeep()) {
            timer.cancel();
            _stopProgressiveBeep();
            return;
          }

          _soundManager.playProgressiveBeep();
        },
      );

      // แสดง Badge แจ้งสถานะ
      _showBadgeAlert(
        '🔊 เรดาร์กล้อง ${distance.toInt()}m',
        const Color(0xFF1158F2),
        beepInterval + 1000, // แสดงนานกว่า interval เล็กน้อย
      );
    }
  }

  // หยุด Progressive Beep Alert
  void _stopProgressiveBeep() {
    if (_isProgressiveBeepActive) {
      print('=== PROGRESSIVE BEEP STOP ===');
      _progressiveBeepTimer?.cancel();
      _progressiveBeepTimer = null;
      _currentBeepCamera = null;
      _lastBeepDistance = 0.0;
      _isProgressiveBeepActive = false;
    }
  }

  // คำนวณระยะแจ้งเตือนที่เหมาะสม - ปรับปรุงตาม 100km/h = 800m
  double _calculateOptimalAlertDistance(double speed, int speedLimit) {
    // กำหนดจุดอ้างอิง: 100 km/h = 800 เมตร
    const referenceSpeed = 100.0; // km/h
    const referenceDistance = 800.0; // เมตร

    // คำนวณระยะตามสัดส่วนของความเร็ว
    // ใช้สูตร: distance = (speed/100)² × 800
    // เพื่อให้ระยะเพิ่มขึ้นแบบกำลังสองตามความเร็ว
    final speedRatio = speed / referenceSpeed;
    final calculatedDistance = speedRatio * speedRatio * referenceDistance;

    // จำกัดระยะ: ขั้นต่ำ 200m, สูงสุด 1000m
    final finalDistance = calculatedDistance.clamp(200.0, 1000.0);

    // Debug log สำหรับตรวจสอบ
    print('=== ALERT DISTANCE CALCULATION ===');
    print('Speed: ${speed.toStringAsFixed(1)} km/h');
    print('Speed ratio: ${speedRatio.toStringAsFixed(2)}');
    print('Calculated distance: ${calculatedDistance.toStringAsFixed(1)} m');
    print('Final distance: ${finalDistance.toStringAsFixed(1)} m');
    print('====================================');

    return finalDistance;
  }

  // ตรวจสอบว่ากล้องอยู่ในทิศทางการเดินทาง
  bool _isCameraInTravelDirection(double cameraDirection) {
    if (currentSpeed < 5.0) return true; // ถ้าไม่เคลื่อนที่ให้แจ้งเตือนทุกทิศ

    // คำนวณความแตกต่างของมุม
    double angleDiff = (cameraDirection - _smoothTravelHeading).abs();
    if (angleDiff > 180) {
      angleDiff = 360 - angleDiff;
    }

    return angleDiff <= 45; // กล้องอยู่ในช่วง ±45 องศาจากทิศทางการเดินทาง
  }

  void _showAdvancedSpeedAlert(
      SpeedCamera camera, double distance, bool isAhead) {
    // สร้างตัวแปรสำหรับค่าที่ใช้ทั้งใน UI และเสียง เพื่อให้แน่ใจว่าตรงกัน
    final uiSpeed = currentSpeed.toInt(); // ใช้ค่าเดียวกับใน UI
    final excessSpeed = uiSpeed - camera.speedLimit;
    final badgeMessage = '🚨 เร็วเกิน ${excessSpeed} km/h';
    final ttsMessage = 'เร็วเกิน ${excessSpeed} กิโลเมตรต่อชั่วโมง';

    // Debug: ตรวจสอบค่าความเร็ว
    print('=== SPEED ALERT SYNC DEBUG ===');
    print('Raw currentSpeed: $currentSpeed');
    print('UI Speed (toInt): $uiSpeed');
    print('Speed limit: ${camera.speedLimit}');
    print('Excess speed: $excessSpeed');
    print('Badge shows: "$badgeMessage"');
    print('TTS says: "$ttsMessage"');
    print('Values should now be identical!');

    // เล่นเสียงแจ้งเตือน - ใช้ค่าเดียวกับ UI
    _soundManager.playSpeedAlert(
      message: ttsMessage,
      currentSpeed: uiSpeed,
      speedLimit: camera.speedLimit,
    );

    // แสดงแจ้งเตือนใน Badge
    _showBadgeAlert(
      badgeMessage,
      Colors.orange,
      5000, // 5 วินาที
    );
  }

  void _showProximityAlert(SpeedCamera camera, double distance) {
    // สร้างตัวแปรสำหรับค่าที่ใช้ทั้งใน UI และเสียง
    final distanceInt = distance.toInt();
    final badgeMessage = '📍 กล้องข้างหน้า ${distanceInt}m';
    final ttsMessage =
        'กล้องจับความเร็วข้างหน้า ${distanceInt} เมตร จำกัด ${camera.speedLimit} กิโลเมตรต่อชั่วโมง';

    // Debug log
    print('=== PROXIMITY ALERT SYNC ===');
    print('Distance: ${distanceInt}m');
    print('Badge: "$badgeMessage"');
    print('TTS: "$ttsMessage"');

    // เล่นเสียงแจ้งเตือนเมื่อใกล้กล้อง
    _soundManager.playProximityAlert(
      message: ttsMessage,
      distance: distance,
    );

    // แสดงแจ้งเตือนใน Badge
    _showBadgeAlert(
      badgeMessage,
      Colors.orange,
      4000, // 4 วินาที
    );
  }

  // ฟังก์ชันแสดงแจ้งเตือนใน Badge
  void _showBadgeAlert(String message, Color color, int durationMs) {
    // ยกเลิก timer เก่า
    _badgeResetTimer?.cancel();

    setState(() {
      _badgeText = message;
      _badgeColor = color;
    });

    // ตั้ง timer เพื่อกลับไปเป็นข้อความปกติ
    _badgeResetTimer = Timer(Duration(milliseconds: durationMs), () {
      if (mounted) {
        setState(() {
          _badgeText = 'กล้องจับความเร็ว';
          _badgeColor =
              const Color(0xFFFFC107); // กลับเป็นสีเหลืองแบบเดิม (สีหลักของแอพ)
        });
      }
    });
  }

  void _showLocationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(message, style: const TextStyle(fontFamily: 'NotoSansThai')),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(message, style: const TextStyle(fontFamily: 'NotoSansThai')),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  // ระบบเคลื่อนไหวกล้องอัจฉริยะ - ปรับตามความเร็วและพฤติกรรม

  Widget _buildTravelDirectionMarker() {
    // ใช้ทิศทางการเดินทางจาก GPS
    final markerColor = const Color(0xFF1158F2); // สีน้ำเงินหลักของแอป

    // คำนวณ duration ตามความเร็ว - เร็วขึ้นเมื่อความเร็วสูง
    final animationDuration = currentSpeed > 60
        ? const Duration(milliseconds: 150) // ความเร็วสูง = หมุนเร็ว
        : currentSpeed > 30
            ? const Duration(milliseconds: 250) // ความเร็วปานกลาง
            : const Duration(
                milliseconds: 400); // ความเร็วต่ำ = หมุนช้า นุ่มนวล

    return Stack(
      alignment: Alignment.center,
      children: [
        // วงรัศมีเดียว - ขอบไม่เข้ม (เพิ่มขนาดเล็กน้อย)
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: markerColor.withValues(alpha: 0.2), // สีฟ้าใสๆ
            shape: BoxShape.circle,
            border: Border.all(
              color: markerColor.withValues(alpha: 0.2), // ขอบไม่เข้ม
              width: 1,
            ),
          ),
        ),

        // ลูกศรนำทางสีน้ำเงิน - แบบสมูทและนุ่มนวล
        AnimatedRotation(
          turns: _smoothTravelHeading / 360, // แปลงจากองศาเป็น turns (0-1)
          duration: animationDuration, // ใช้ duration ที่คำนวณตามความเร็ว
          curve: Curves.easeInOutCubic, // curve ที่นุ่มนวลมากขึ้น
          child: Icon(
            Icons.navigation,
            color: markerColor, // สีน้ำเงินเดิม
            size: 48, // ขนาด 1.5 เท่า
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // ทำให้พื้นหลังใส
      extendBodyBehindAppBar: true, // ขยาย body ไปหลัง AppBar
      extendBody:
          true, // ขยาย body ไปทั่วทั้งหน้าจอ เพื่อป้องกัน navigation bar
      resizeToAvoidBottomInset: false, // ป้องกัน navigation bar โผล่ขึ้นมา
      appBar: AppBar(
        backgroundColor: Colors.transparent, // AppBar ใส
        elevation: 0, // ไม่มีเงา
        toolbarHeight: 0, // ซ่อน toolbar แต่เก็บ safe area
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent, // Status bar ใส
          statusBarIconBrightness: Brightness.dark, // ไอคอนสีเข้ม
          systemNavigationBarColor: Colors.transparent, // Navigation bar ใส
          systemNavigationBarIconBrightness:
              Brightness.dark, // ไอคอน navigation bar สีเข้ม
        ),
      ),
      body: Stack(
        children: [
          // แผนที่หลัก - แสดงเฉพาะกล้องจับความเร็ว
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: currentPosition,
              initialZoom: 15.0,
              minZoom:
                  5.0, // ลดจาก 8.0 เป็น 5.0 เพื่อให้ซูมออกเห็นทั่วประเทศไทย
              maxZoom: 18.0,
              // ตรวจจับการโต้ตอบของผู้ใช้
              onTap: (tapPosition, point) => _onMapInteraction(),
              onLongPress: (tapPosition, point) => _onMapInteraction(),
              onPositionChanged: (position, hasGesture) {
                if (hasGesture) {
                  _onMapInteraction();
                }
              },
            ),
            children: [
              TileLayer(
                tileProvider:
                    _smartTileProvider, // จะเป็น null ในตอนแรก แต่ Flutter จะจัดการให้
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.checkdarn.app',
                maxZoom: 18,
                additionalOptions: const {
                  'User-Agent': 'CheckDarn Speed Camera App/1.0',
                },
              ),

              // แสดงเฉพาะกล้องจับความเร็ว - ไม่มีหมุดโพสต์
              if (!isLoadingCameras)
                MarkerLayer(
                  markers: [
                    // Marker ตำแหน่งผู้ใช้ - ลูกศรชี้ทิศทางการเดินทาง
                    Marker(
                      point: currentPosition,
                      width: 70, // เพิ่มจาก 60 เป็น 70 เพื่อให้เข้ากับรัศมีใหม่
                      height:
                          70, // เพิ่มจาก 60 เป็น 70 เพื่อให้เข้ากับรัศมีใหม่
                      child: _buildTravelDirectionMarker(),
                    ),

                    // Markers กล้องจับความเร็ว
                    ...speedCameras.map((camera) => Marker(
                          point: camera.location,
                          width: 40, // ลดจาก 50 เป็น 40
                          height: 40, // ลดจาก 50 เป็น 40
                          child: AnimatedScale(
                            scale: nearestCamera?.id == camera.id &&
                                    distanceToNearestCamera <= 500
                                ? 1.1 // ขยายเล็กน้อย 1.1 เท่า (10%)
                                : 1.0,
                            duration: const Duration(milliseconds: 300),
                            child: SpeedCameraMarker(
                              camera: camera,
                              onTap: () =>
                                  _recordAppInteraction(), // บันทึกการโต้ตอบ
                            ),
                          ),
                        )),
                  ],
                ),
            ],
          ),

          // Title badge แบบยาวพร้อมปุ่มตั้งค่า
          Positioned(
            top: 0, // ใช้เฉพาะ SafeArea และ margin เหมือน map screen
            left: 0, // ใช้ full width แล้วให้ Container จัดการ margin
            right: 0, // ใช้ full width แล้วให้ Container จัดการ margin
            child: SafeArea(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(
                    top: 10, left: 12, right: 12), // เท่ากับ map screen
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6), // เท่ากับ map screen
                decoration: BoxDecoration(
                  color: _badgeColor, // ใช้สีจากตัวแปร (สีขาวเป็นค่าเริ่มต้น)
                  borderRadius: BorderRadius.circular(
                      25), // เปลี่ยนจาก 20 เป็น 25 เหมือน map screen
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // ส่วนซ้าย - ปุ่มตั้งค่าเสียง
                    Tooltip(
                      message: 'ตั้งค่าเสียงแจ้งเตือน',
                      textStyle: const TextStyle(
                        fontFamily: 'NotoSansThai',
                        fontSize: 12,
                        color: Colors.white,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: GestureDetector(
                        onTap: () {
                          _recordAppInteraction(); // บันทึกการโต้ตอบ
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SoundSettingsScreen(),
                            ),
                          );
                        },
                        child: Padding(
                          padding:
                              const EdgeInsets.all(8.0), // เพิ่ม touch area
                          child: SvgPicture.asset(
                            'assets/icons/speed_camera_screen/settings.svg',
                            width: 20, // ปรับขนาดให้พอดีกับ badge
                            height: 20,
                            colorFilter: ColorFilter.mode(
                              _soundManager.isSoundEnabled
                                  ? Colors.black // เปลี่ยนเป็นสีดำ
                                  : Colors.black54, // สีดำอ่อนเมื่อปิด
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // ใช้ AnimatedSwitcher สำหรับเปลี่ยนข้อความแบบ fade
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        transitionBuilder:
                            (Widget child, Animation<double> animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.3, 0),
                                end: Offset.zero,
                              ).animate(CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOut,
                              )),
                              child: child,
                            ),
                          );
                        },
                        child: Text(
                          _badgeText,
                          key: ValueKey(
                              _badgeText), // สำคัญสำหรับ AnimatedSwitcher
                          style: const TextStyle(
                            color: Colors.black, // เปลี่ยนเป็นสีดำ
                            fontFamily: 'NotoSansThai',
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ),

                    const SizedBox(width: 8), // เพิ่มระยะห่างเล็กน้อย

                    // ส่วนขวา - ปุ่มเพิ่มกล้อง (แทนไอคอนกล้อง)
                    GestureDetector(
                      onTap: () async {
                        _recordAppInteraction(); // บันทึกการโต้ตอบ

                        print(
                            '📱 Navigating to CameraReportScreen for voting/reporting...');

                        // นำทางไปหน้า CameraReportScreen และรับผลลัพธ์
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CameraReportScreen(
                              initialLocation: currentPosition,
                              initialRoadName: nearestCamera?.roadName,
                            ),
                          ),
                        );

                        // ตรวจสอบผลลัพธ์ที่กลับมา
                        if (mounted) {
                          print('🔄 Returned from CameraReportScreen');
                          print('🔄 Result: $result');

                          // ไม่ว่าจะมีผลลัพธ์หรือไม่ ให้รีเฟรชข้อมูลกล้องเสมอ
                          // เพราะอาจมีการโหวตหรือรายงานใหม่
                          _hasJustVoted = true;
                          _lastVotingTime = DateTime.now();

                          print(
                              '🔄 Triggering comprehensive refresh after returning from voting/reporting...');
                          await _refreshSpeedCamerasAfterVoting();
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: SvgPicture.asset(
                          'assets/icons/speed_camera_screen/add.svg',
                          width: 20,
                          height: 20,
                          colorFilter: const ColorFilter.mode(
                            Colors.black, // เปลี่ยนเป็นสีดำ
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Loading indicator
          if (isLoadingLocation || isLoadingCameras)
            Container(
              color: Colors.black26,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'กำลังโหลดข้อมูล...',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'NotoSansThai',
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Floating circular speed widget - แสดงเฉพาะเมื่อโหลดข้อมูลเสร็จแล้ว
          if (!isLoadingLocation && !isLoadingCameras)
            Positioned(
              bottom: 100,
              left: 20,
              child: CircularSpeedWidget(
                currentSpeed: currentSpeed,
                speedLimit: nearestCamera?.speedLimit.toDouble(),
                isMoving: currentSpeed > 5.0,
              ),
            ),
        ],
      ),
    );
  }
}
