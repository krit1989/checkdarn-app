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
import '../services/sound_manager.dart';
import '../screens/sound_settings_screen.dart';
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
  bool _isFollowingUser = true; // Auto-follow mode

  StreamSubscription<Position>? _positionSubscription;
  Timer? _speedUpdateTimer;
  double _smoothTravelHeading = 0.0; // สำหรับ smooth rotation

  // ระบบ Predict Movement
  List<Position> _positionHistory = [];
  LatLng? _predictedPosition;
  List<SpeedCamera> _predictedCameras = [];

  // ระบบสถิติและ Analytics
  DateTime? _lastAlertTime;

  // ระบบเสียงแจ้งเตือน
  final SoundManager _soundManager = SoundManager();

  @override
  void initState() {
    super.initState();
    mapController = MapController();
    _getCurrentLocation();
    _loadSpeedCameras();
    _startSpeedTracking();
    _initializeSoundManager();
  }

  Future<void> _initializeSoundManager() async {
    await _soundManager.initialize();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _speedUpdateTimer?.cancel();
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

        // ย้ายแผนที่ไปยังตำแหน่งปัจจุบัน
        mapController.move(currentPosition, 15.0);
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

        // Auto-follow: ย้ายกล้องตามผู้ใช้แบบนุ่มนวล
        if (_isFollowingUser) {
          _smoothMoveCamera(newPosition);
        }

        _updateNearestCamera();

        // ระบบ Predict Movement
        if (_positionHistory.length >= 3) {
          _predictMovementAndCheck();
        }
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

    // เล่นเสียงแจ้งเตือน
    _soundManager.playPredictiveAlert(
      message:
          "คาดการณ์: จะพบกล้องจับความเร็วใน 10 วินาที บน ${nearestPredicted.roadName}",
      roadName: nearestPredicted.roadName,
      speedLimit: nearestPredicted.speedLimit,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '🔮 คาดการณ์: จะพบกล้องจับความเร็วใน 10 วินาที\n'
          '📍 ${nearestPredicted.roadName} (จำกัด ${nearestPredicted.speedLimit} km/h)',
          style: const TextStyle(fontFamily: 'Kanit', color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1158F2),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _smoothMoveCamera(LatLng newPosition) {
    // เคลื่อนไหวกล้องแบบนุ่มนวล - ไม่หมุนแผนที่
    mapController.move(newPosition, mapController.camera.zoom);
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
    final excessSpeed = currentSpeed - camera.speedLimit;

    // เล่นเสียงแจ้งเตือนเมื่อเร็วเกิน
    _soundManager.playSpeedAlert(
      message: "เร็วเกิน ${excessSpeed.toInt()} km/h",
      currentSpeed: currentSpeed.toInt(),
      speedLimit: camera.speedLimit,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '🚨 ${isAhead ? 'ข้างหน้า' : 'ใกล้เคียง'}: กล้องจับความเร็ว ${distance.toInt()}m\n'
          '⚠️ เร็วเกิน ${excessSpeed.toInt()} km/h (จำกัด ${camera.speedLimit} km/h)',
          style: const TextStyle(fontFamily: 'Kanit', color: Colors.white),
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _showProximityAlert(SpeedCamera camera, double distance) {
    // เล่นเสียงแจ้งเตือนเมื่อใกล้กล้อง
    _soundManager.playProximityAlert(
      message:
          "กล้องจับความเร็วข้างหน้า ${distance.toInt()} เมตร จำกัด ${camera.speedLimit} km/h",
      distance: distance,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '📍 กล้องจับความเร็วข้างหน้า ${distance.toInt()}m\n'
          'จำกัดความเร็ว ${camera.speedLimit} km/h',
          style: const TextStyle(fontFamily: 'Kanit', color: Colors.white),
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 5),
      ),
    );
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

  Widget _buildTravelDirectionMarker() {
    // ใช้ทิศทางการเดินทางจาก GPS
    final angle = _smoothTravelHeading * (3.14159 / 180); // องศาเป็น Radian
    final markerColor = const Color(0xFF1158F2); // สีน้ำเงินหลักของแอป

    return Container(
      decoration: BoxDecoration(
        color: markerColor,
        shape: BoxShape.circle,
        boxShadow: [
          const BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
          // เอฟเฟกต์ Glow รอบๆ
          BoxShadow(
            color: markerColor.withValues(alpha: 0.5),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // วงกลมพื้นหลัง
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: markerColor,
              shape: BoxShape.circle,
            ),
          ),

          // ลูกศรนำทางแสดงตลอดเวลา
          Transform.rotate(
            angle: angle,
            child: const Icon(
              Icons.navigation,
              color: Colors.white,
              size: 24,
            ),
          ),

          // จุดขาวเล็กตรงกลาง
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDistance(double distanceInMeters) {
    if (distanceInMeters >= 1000) {
      // แสดงเป็นกิโลเมตร (1 ทศนิยม)
      final km = distanceInMeters / 1000;
      return '${km.toStringAsFixed(1)} กม.';
    } else {
      // แสดงเป็นเมตร
      return '${distanceInMeters.toInt()} เมตร';
    }
  }

  // ตรวจสอบทิศทางของกล้องเทียบกับการเดินทาง
  bool _isCameraInDirection() {
    if (nearestCamera == null || currentSpeed < 5.0) return false;

    final cameraDirection = Geolocator.bearingBetween(
      currentPosition.latitude,
      currentPosition.longitude,
      nearestCamera!.location.latitude,
      nearestCamera!.location.longitude,
    );

    return _isCameraInTravelDirection(cameraDirection);
  }

  // ไอคอนแสดงทิศทางของกล้อง
  IconData _getCameraDirectionIcon() {
    if (!_isCameraInDirection()) {
      return Icons.turn_slight_right; // กล้องด้านข้าง
    }

    if (distanceToNearestCamera <= 300) {
      return Icons.warning; // ใกล้มาก
    } else if (distanceToNearestCamera <= 500) {
      return Icons.arrow_upward; // ข้างหน้าใกล้
    } else {
      return Icons.arrow_upward_outlined; // ข้างหน้าไกล
    }
  }

  // ข้อความแสดงทิศทางของกล้อง
  String _getCameraDirectionText() {
    if (!_isCameraInDirection()) {
      return 'ด้านข้าง';
    }

    if (distanceToNearestCamera <= 300) {
      return 'ใกล้มาก!';
    } else if (distanceToNearestCamera <= 500) {
      return 'ข้างหน้า';
    } else {
      return 'ข้างหน้าไกล';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // ทำให้พื้นหลังใส
      extendBodyBehindAppBar: true, // ขยาย body ไปหลัง AppBar
      appBar: AppBar(
        backgroundColor: Colors.transparent, // AppBar ใส
        elevation: 0, // ไม่มีเงา
        toolbarHeight: 0, // ซ่อน toolbar แต่เก็บ safe area
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent, // Status bar ใส
          statusBarIconBrightness: Brightness.dark, // ไอคอนสีเข้ม
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
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.checkdarn.app',
              ),

              // แสดงเฉพาะกล้องจับความเร็ว - ไม่มีหมุดโพสต์
              if (!isLoadingCameras)
                MarkerLayer(
                  markers: [
                    // Marker ตำแหน่งผู้ใช้ - ลูกศรชี้ทิศทางการเดินทาง
                    Marker(
                      point: currentPosition,
                      width: 40,
                      height: 40,
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
                                ? 1.5 // เพิ่มจาก 1.2 เป็น 1.5 เพื่อให้เห็นชัดขึ้น
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

          // Title badge (ย้ายไปด้านซ้าย)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8, // ลดระยะจาก 16 เป็น 8
            left: 16, // เปลี่ยนจาก right เป็น left
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFC107), // สีเหลือง
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                  const Text(
                    'กล้องจับความเร็ว',
                    style: TextStyle(
                      color: Colors.black,
                      fontFamily: 'Kanit',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ปุ่มตั้งค่าเสียง (แถวเดียวกับ badge)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8, // แถวเดียวกับ badge
            right: 16,
            child: Tooltip(
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
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9), // สีขาว
                  borderRadius:
                      BorderRadius.circular(8), // สี่เหลี่ยมโค้งเล็กน้อย
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: SvgPicture.asset(
                    'assets/icons/speed_camera_screen/settings.svg',
                    width: 22, // เพิ่มขนาดจาก 20 เป็น 22
                    height: 22, // เพิ่มขนาดจาก 20 เป็น 22
                    colorFilter: ColorFilter.mode(
                      _soundManager.isSoundEnabled
                          ? Colors.black // เปลี่ยนจากสีฟ้าเป็นดำ
                          : Colors.grey.shade600, // สีเทาเมื่อปิด
                      BlendMode.srcIn,
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SoundSettingsScreen(),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // Follow mode toggle button
          Positioned(
            top: MediaQuery.of(context).padding.top + 62,
            right: 16,
            child: Column(
              children: [
                // ปุ่ม Follow mode
                Tooltip(
                  message: _isFollowingUser
                      ? 'กำลังติดตามตำแหน่งอัตโนมัติ\nแตะเพื่อปิด'
                      : 'แตะเพื่อติดตามตำแหน่งอัตโนมัติ',
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
                      color: _isFollowingUser
                          ? const Color(0xFF4CAF50)
                              .withValues(alpha: 0.9) // เขียว = กำลังติดตาม
                          : Colors.black
                              .withValues(alpha: 0.7), // เทา = ไม่ติดตาม
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
                      icon: Icon(
                        _isFollowingUser
                            ? Icons.my_location
                            : Icons.location_searching,
                        color: Colors.white,
                        size: 16,
                      ),
                      onPressed: () {
                        setState(() {
                          _isFollowingUser = !_isFollowingUser;
                        });

                        // ถ้าเปิด follow mode ให้ย้ายไปตำแหน่งปัจจุบันทันที
                        if (_isFollowingUser) {
                          _smoothMoveCamera(currentPosition);
                        }

                        // แสดง SnackBar ชั่วคราวเพื่อยืนยันการเปลี่ยนแปลง
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              _isFollowingUser
                                  ? '🎯 เปิดการติดตามตำแหน่งอัตโนมัติ'
                                  : '🔓 ปิดการติดตามตำแหน่งอัตโนมัติ',
                              style: const TextStyle(fontFamily: 'Kanit'),
                            ),
                            duration: const Duration(seconds: 5),
                            backgroundColor: _isFollowingUser
                                ? const Color(0xFF4CAF50)
                                : Colors.grey.shade600,
                          ),
                        );
                      },
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
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

          // Bottom speed panel - เพิ่ม debug info
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // แสดงความเร็วปัจจุบัน
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildSpeedCard(
                        'ความเร็วปัจจุบัน',
                        '${currentSpeed.toInt()}',
                        'km/h',
                        currentSpeed > (nearestCamera?.speedLimit ?? 120)
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

                  const SizedBox(height: 12),

                  // แสดงข้อมูลกล้องใกล้สุด
                  if (nearestCamera != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: distanceToNearestCamera <= 500
                            ? Colors.red.withValues(alpha: 0.1)
                            : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.speed,
                            color: distanceToNearestCamera <= 500
                                ? Colors.red
                                : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'กล้องใกล้สุด: ${_formatDistance(distanceToNearestCamera)}',
                                  style: const TextStyle(
                                    fontFamily: 'Kanit',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  nearestCamera!.roadName,
                                  style: TextStyle(
                                    fontFamily: 'Kanit',
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                // แสดงทิศทางของกล้อง
                                if (currentSpeed > 5.0)
                                  Row(
                                    children: [
                                      Icon(
                                        _getCameraDirectionIcon(),
                                        size: 16,
                                        color: _isCameraInDirection()
                                            ? const Color(0xFF1158F2)
                                            : Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _getCameraDirectionText(),
                                        style: TextStyle(
                                          fontFamily: 'Kanit',
                                          fontSize: 11,
                                          color: _isCameraInDirection()
                                              ? const Color(0xFF1158F2)
                                              : Colors.grey.shade600,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
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
