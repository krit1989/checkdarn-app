import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';
import 'dart:math';
import '../models/speed_camera_model.dart';
import '../services/speed_camera_service.dart';
import '../../../services/sound_manager.dart';
import '../../../services/smart_tile_provider.dart';
import '../../../services/connection_manager.dart';
import '../../../services/map_cache_manager.dart';
import '../../../screens/sound_settings_screen.dart';
import 'camera_report_screen.dart';
import '../widgets/speed_camera_marker.dart';

class SpeedCameraScreen extends StatefulWidget {
  const SpeedCameraScreen({super.key});

  @override
  State<SpeedCameraScreen> createState() => _SpeedCameraScreenState();
}

class _SpeedCameraScreenState extends State<SpeedCameraScreen> {
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
  Color _badgeColor = const Color(0xFFFFC107);
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

  // Smart map system
  SmartTileProvider? _smartTileProvider; // เปลี่ยนเป็น nullable
  Timer? _connectionCheckTimer;
  Timer? _preloadTimer;

  @override
  void initState() {
    super.initState();
    mapController = MapController();
    _getCurrentLocation();
    _loadSpeedCameras();
    _startSpeedTracking();
    _initializeSoundManager();
    _startConnectionMonitoring();

    // Initialize smart map system หลังจาก widget build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSmartMapSystem();
    });
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

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _speedUpdateTimer?.cancel();
    _connectionCheckTimer?.cancel();
    _preloadTimer?.cancel();
    _followModeResetTimer?.cancel(); // เพิ่ม timer ใหม่
    _badgeResetTimer?.cancel(); // เพิ่ม badge timer
    _soundManager.dispose();
    mapController.dispose();
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
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // อัปเดตทุก 5 เมตร
      ),
    ).listen((Position position) {
      if (mounted) {
        final newPosition = LatLng(position.latitude, position.longitude);

        // เพิ่มประวัติตำแหน่งสำหรับระบบ Predict Movement
        _positionHistory.add(position);
        if (_positionHistory.length > 10) {
          _positionHistory.removeAt(0); // เก็บเฉพาะ 10 จุดล่าสุด
        }

        setState(() {
          currentPosition = newPosition;
          currentSpeed = position.speed * 3.6; // m/s เป็น km/h

          // อัปเดตทิศทางการเดินทางจาก GPS (เฉพาะเมื่อเคลื่อนที่)
          if (currentSpeed > 5.0 && position.heading.isFinite) {
            _smoothTravelHeading =
                _interpolateHeading(_smoothTravelHeading, position.heading);
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

      // ปรับ zoom อัตโนมัติตามความเร็ว
      if (currentSpeed < 30) {
        targetZoom = 16.0; // ซูมใกล้เมื่อขับช้า
      } else if (currentSpeed < 60) {
        targetZoom = 15.0; // ซูมกลางเมื่อขับปกติ
      } else {
        targetZoom = 14.0; // ซูมไกลเมื่อขับเร็ว
      }

      // เคลื่อนไหวแบบนุ่มนวลพร้อมปรับ zoom
      mapController.move(newPosition, targetZoom);
    } catch (e) {
      print('MapController error in intelligent camera movement: $e');
    }
  }

  // ตรวจจับการโต้ตอบของผู้ใช้กับแผนที่
  void _onMapInteraction() {
    final now = DateTime.now();

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

    // Smooth interpolation (ปรับค่า 0.3 เพื่อความนุ่มนวล)
    return currentHeading + (diff * 0.3);
  }

  // Smart tile preloading
  void _schedulePreloadTiles(LatLng position) {
    // Cancel existing timer
    _preloadTimer?.cancel();

    // Schedule preload after 2 seconds to avoid too frequent calls
    _preloadTimer = Timer(const Duration(seconds: 2), () async {
      try {
        // ตรวจสอบว่า SmartTileProvider และ MapController พร้อมใช้งาน
        if (_smartTileProvider != null) {
          final zoom = mapController.camera.zoom.round();
          await _smartTileProvider!
              .preloadTilesAround(position, zoom, radius: 2);
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

    // นับกล้องที่ผ่าน
    if (distance <= 50 && currentSpeed > 10) {
      _logCameraPassing(camera);
    }
  }

  // บันทึกสถิติการผ่านกล้อง
  void _logCameraPassing(SpeedCamera camera) {
    final wasOverSpeed = currentSpeed > camera.speedLimit;

    print('Camera passed: ${camera.roadName}, Speed: ${currentSpeed.toInt()}, '
        'Limit: ${camera.speedLimit}, Over: $wasOverSpeed');

    // อาจจะส่งข้อมูลไป Analytics ในอนาคต
  }

  // คำนวณระยะแจ้งเตือนที่เหมาะสม
  double _calculateOptimalAlertDistance(double speed, int speedLimit) {
    // ยิ่งเร็วยิ่งแจ้งเตือนไกลขึ้น
    final brakingDistance = (speed * speed) / (2 * 8); // สูตรการเบรก (m)
    final reactionDistance = speed * 1.5; // ระยะการตอบสนอง (m)
    final calculatedDistance =
        brakingDistance + reactionDistance + 200; // บัฟเฟอร์ 200m

    // ระยะขั้นต่ำ 300m, สูงสุด 800m
    return calculatedDistance.clamp(300.0, 800.0);
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
      Colors.red,
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
          _badgeColor = const Color(0xFFFFC107);
        });
      }
    });
  }

  void _showLocationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Kanit')),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Kanit')),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  // ระบบเคลื่อนไหวกล้องอัจฉริยะ - ปรับตามความเร็วและพฤติกรรม

  Widget _buildTravelDirectionMarker() {
    // ใช้ทิศทางการเดินทางจาก GPS
    final angle = _smoothTravelHeading * (3.14159 / 180); // องศาเป็น Radian
    final markerColor = const Color(0xFF1158F2); // สีน้ำเงินหลักของแอป

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

        // ลูกศรนำทางสีน้ำเงิน - แบบเรียบง่าย
        Transform.rotate(
          angle: angle,
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
              minZoom: 8.0,
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
                  color: _badgeColor, // ใช้สีจากตัวแปร
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
                    // ส่วนซ้าย - ไอคอนและข้อความ
                    SvgPicture.asset(
                      'assets/icons/speed_camera_screen/speed camera2.svg',
                      width: 16,
                      height: 16,
                      colorFilter: const ColorFilter.mode(
                        Colors.black,
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 6),

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
                            color: Colors.black,
                            fontFamily: 'Kanit',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ),

                    const SizedBox(width: 8), // เพิ่มระยะห่างเล็กน้อย

                    // ส่วนขวา - ปุ่มตั้งค่าเสียง (ไม่มีกรอบพื้นหลัง)
                    Tooltip(
                      message: 'ตั้งค่าเสียงแจ้งเตือน',
                      textStyle: const TextStyle(
                        fontFamily: 'Kanit',
                        fontSize: 12,
                        color: Colors.white,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: GestureDetector(
                        onTap: () {
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
                                  ? Colors.black
                                  : Colors.grey.shade600, // สีเทาเมื่อปิด
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Report camera button - ตอนนี้อยู่ตำแหน่งเดียว
          Positioned(
            top: MediaQuery.of(context).padding.top +
                62, // ปรับตำแหน่งให้ไม่ทับกับ badge ใหม่
            right: 12, // เปลี่ยนจาก 16 เป็น 12 ให้สอดคล้องกับ badge
            child: Tooltip(
              message: 'รายงานกล้องจับความเร็ว',
              textStyle: const TextStyle(
                fontFamily: 'Kanit',
                fontSize: 12,
                color: Colors.white,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFC107)
                      .withValues(alpha: 0.9), // สีเหลือง
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.add_location_alt,
                    color: Colors.black,
                    size: 18,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CameraReportScreen(
                          initialLocation: currentPosition,
                          initialRoadName: nearestCamera?.roadName,
                        ),
                      ),
                    );
                  },
                  padding: EdgeInsets.zero,
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
                        fontFamily: 'Kanit',
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Bottom speed panel - DraggableScrollableSheet with smart bottom margin
          // แสดงการ์ดเฉพาะเมื่อโหลดข้อมูลเสร็จแล้ว
          if (!isLoadingLocation && !isLoadingCameras)
            DraggableScrollableSheet(
              initialChildSize: 0.30, // เริ่มต้นที่ 30% - แสดงข้อมูลเต็ม
              minChildSize: 0.08, // ต่ำสุด 8% - ซ่อนเกือบหมดแต่ยังมองเห็น
              maxChildSize: 0.30, // สูงสุด 30% - พอดีกับที่ต้องการ
              snap: true, // snap ไปยังตำแหน่งที่กำหนด
              snapSizes: const [
                0.08, // ซ่อนเกือบหมด - เหลือไว้นิดนึงเพื่อให้ดึงขึ้นได้
                0.30, // แสดงข้อมูลเต็ม - ตรงกับ initial และ max
              ], // 2 ระดับที่สอดคล้องกัน
              builder: (context, scrollController) {
                // ระบบตรวจสอบ Navigation Bar อัจฉริยะ
                final mediaQuery = MediaQuery.of(context);
                final bottomPadding = mediaQuery.viewPadding.bottom;
                final bottomInset = mediaQuery.viewInsets.bottom;
                final screenHeight = mediaQuery.size.height;

                // ตรวจสอบว่ามี navigation bar หรือไม่
                final hasNavigationBar = bottomPadding > 0;
                final hasKeyboard = bottomInset > 0;

                // คำนวณขนาดการ์ดปัจจุบัน
                final currentSheetHeight = scrollController.hasClients
                    ? scrollController.offset
                    : 0.30 * screenHeight; // ค่าเริ่มต้น 30%

                // กำหนด smart margin ตามสถานการณ์
                double smartBottomMargin = 0;
                if (hasNavigationBar && !hasKeyboard) {
                  // มี navigation bar แต่ไม่มีคีย์บอร์ด
                  if (currentSheetHeight < 0.08 * screenHeight) {
                    // การ์ดซ่อนเกือบหมด - ให้ margin น้อยหน่อย
                    smartBottomMargin = bottomPadding * 0.3;
                  } else {
                    // การ์ดแสดงปกติ - ใช้ margin เต็ม
                    smartBottomMargin = bottomPadding;
                  }
                } else if (hasKeyboard) {
                  // มีคีย์บอร์ดเปิด - ไม่ต้อง margin เพิ่ม
                  smartBottomMargin = 0;
                }

                return Container(
                  // ใช้ Smart Bottom Margin ที่คำนวณแล้ว
                  margin: EdgeInsets.only(
                    bottom: smartBottomMargin,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      children: [
                        // Drag handle bar
                        Container(
                          margin: const EdgeInsets.only(top: 8, bottom: 8),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),

                        // Content - ปรับการแสดงผลตามขนาดการ์ด
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // แสดงความเร็วปัจจุบัน - แสดงเสมอ
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildSpeedCard(
                                    'ความเร็วปัจจุบัน',
                                    '${currentSpeed.toInt()}',
                                    'km/h',
                                    currentSpeed >
                                            (nearestCamera?.speedLimit ?? 120)
                                        ? Colors.red
                                        : const Color(0xFF1158F2),
                                  ),
                                  if (nearestCamera != null)
                                    _buildSpeedCard(
                                      'จำกัดความเร็ว',
                                      '${nearestCamera!.speedLimit}',
                                      'km/h',
                                      Colors.orange,
                                    ),
                                ],
                              ),

                              // เพิ่มพื้นที่ว่างท้าย
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ), // ปิด DraggableScrollableSheet
        ],
      ),
    );
  }

  Widget _buildSpeedCard(String label, String value, String unit, Color color) {
    final speedLimit = nearestCamera?.speedLimit ?? 120;
    final speedRatio = currentSpeed / speedLimit;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Kanit',
              fontSize: 14, // เพิ่มขนาดจาก 12
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Kanit',
                  fontSize: 32, // เพิ่มขนาดจาก 24
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                unit,
                style: TextStyle(
                  fontFamily: 'Kanit',
                  fontSize: 18, // เพิ่มขนาดจาก 14
                  color: color,
                ),
              ),
            ],
          ),

          // เพิ่ม Progress Bar สำหรับความเร็วปัจจุบัน (ต้องจำกัดความกว้าง)
          if (label == 'ความเร็วปัจจุบัน') ...[
            const SizedBox(height: 8),
            SizedBox(
              width: 120, // จำกัดความกว้างเพื่อไม่ให้เป็น infinity
              child: LinearProgressIndicator(
                value: speedRatio.clamp(0.0, 1.5), // จำกัดไม่เกิน 150%
                backgroundColor: Colors.grey.withValues(alpha: 0.3),
                valueColor: AlwaysStoppedAnimation<Color>(
                  speedRatio > 1.0 ? Colors.red : color,
                ),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              speedRatio > 1.0
                  ? 'เร็วเกิน ${((speedRatio - 1.0) * 100).toInt()}%'
                  : 'ปลอดภัย',
              style: TextStyle(
                fontFamily: 'Kanit',
                fontSize: 10,
                color: speedRatio > 1.0 ? Colors.red : Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
