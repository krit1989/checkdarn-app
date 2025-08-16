import 'dart:async';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../models/speed_camera_model.dart';
import '../services/speed_camera_service.dart';

/// 📹 **Camera Manager**
/// ระบบจัดการกล้องจับความเร็วที่แยกออกมา
/// มีฟีเจอร์การค้นหาและการจัดการที่มีประสิทธิภาพ
class CameraManager {
  final List<SpeedCamera> _cameras = [];

  // Cache สำหรับการค้นหาที่เร็วขึ้น
  final Map<String, SpeedCamera> _cameraMap = {};
  DateTime? _lastLoadTime;

  /// โหลดข้อมูลกล้องทั้งหมด
  Future<void> loadCameras() async {
    try {
      final cameras = await SpeedCameraService.getSpeedCameras();
      _cameras.clear();
      _cameras.addAll(cameras);

      // สร้าง cache map สำหรับการค้นหาที่เร็วขึ้น
      _cameraMap.clear();
      for (final camera in cameras) {
        _cameraMap[camera.id] = camera;
      }

      _lastLoadTime = DateTime.now();
      print('📹 CameraManager: Loaded ${cameras.length} cameras');
    } catch (e) {
      print('❌ CameraManager: Error loading cameras: $e');
      rethrow;
    }
  }

  /// ค้นหากล้องใกล้ที่สุด
  SpeedCamera? findNearestCamera(LatLng position) {
    if (_cameras.isEmpty) return null;

    SpeedCamera? nearest;
    double minDistance = double.infinity;

    for (final camera in _cameras) {
      final distance = _calculateDistance(position, camera.location);

      if (distance < minDistance) {
        minDistance = distance;
        nearest = camera;
      }
    }

    return nearest;
  }

  /// ค้นหากล้องในรัศมีที่กำหนด (เมตร)
  List<SpeedCamera> findCamerasInRadius(
      LatLng position, double radiusInMeters) {
    if (_cameras.isEmpty) return [];

    final result = <SpeedCamera>[];

    for (final camera in _cameras) {
      final distance = _calculateDistance(position, camera.location);
      if (distance <= radiusInMeters) {
        result.add(camera);
      }
    }

    return result;
  }

  /// ค้นหากล้องในทิศทางการเดินทาง
  List<SpeedCamera> findCamerasInTravelDirection(
      LatLng position, double heading, double radiusInMeters,
      {double angleThreshold = 45.0}) {
    if (_cameras.isEmpty) return [];

    final result = <SpeedCamera>[];

    for (final camera in _cameras) {
      final distance = _calculateDistance(position, camera.location);
      if (distance > radiusInMeters) continue;

      final bearing = Geolocator.bearingBetween(
        position.latitude,
        position.longitude,
        camera.location.latitude,
        camera.location.longitude,
      );

      if (_isCameraInTravelDirection(bearing, heading, angleThreshold)) {
        result.add(camera);
      }
    }

    return result;
  }

  /// ค้นหากล้องตาม ID
  SpeedCamera? findCameraById(String id) {
    return _cameraMap[id];
  }

  /// ค้นหากล้องตามชื่อถนน
  List<SpeedCamera> findCamerasByRoadName(String roadName) {
    if (_cameras.isEmpty) return [];

    final lowerRoadName = roadName.toLowerCase();
    return _cameras.where((camera) {
      return camera.roadName.toLowerCase().contains(lowerRoadName);
    }).toList();
  }

  /// ค้นหากล้องที่มีความเร็วจำกัดตามที่กำหนด
  List<SpeedCamera> findCamerasBySpeedLimit(int speedLimit) {
    return _cameras.where((camera) => camera.speedLimit == speedLimit).toList();
  }

  /// รีเฟรชข้อมูลกล้องหากเวลาผ่านไปมากกว่าที่กำหนด
  Future<bool> refreshIfNeeded(
      {Duration maxAge = const Duration(minutes: 10)}) async {
    if (_lastLoadTime == null ||
        DateTime.now().difference(_lastLoadTime!).compareTo(maxAge) > 0) {
      await loadCameras();
      return true;
    }
    return false;
  }

  /// ตรวจสอบว่ากล้องอยู่ในทิศทางการเดินทางหรือไม่
  bool _isCameraInTravelDirection(
      double cameraBearing, double travelHeading, double threshold) {
    // คำนวณความแตกต่างของมุม
    double angleDiff = (cameraBearing - travelHeading).abs();
    if (angleDiff > 180) {
      angleDiff = 360 - angleDiff;
    }

    return angleDiff <= threshold;
  }

  /// คำนวณระยะทางระหว่างจุดสองจุด (เมตร)
  double _calculateDistance(LatLng from, LatLng to) {
    return Geolocator.distanceBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );
  }

  /// ค้นหากล้องที่ได้รับการยืนยันจากชุมชน
  List<SpeedCamera> findCommunityVerifiedCameras() {
    return _cameras.where((camera) {
      return camera.description?.contains('Community verified') == true ||
          camera.description?.contains('ชุมชนยืนยัน') == true;
    }).toList();
  }

  /// คำนวณระยะทางถึงกล้องใกล้ที่สุด
  double calculateDistanceToNearest(LatLng position) {
    final nearest = findNearestCamera(position);
    if (nearest == null) return double.infinity;

    return _calculateDistance(position, nearest.location);
  }

  /// สถิติข้อมูลกล้อง
  Map<String, dynamic> getStatistics() {
    final communityVerified = findCommunityVerifiedCameras();
    final speedLimitGroups = <int, int>{};

    for (final camera in _cameras) {
      speedLimitGroups[camera.speedLimit] =
          (speedLimitGroups[camera.speedLimit] ?? 0) + 1;
    }

    return {
      'totalCameras': _cameras.length,
      'communityVerified': communityVerified.length,
      'speedLimitGroups': speedLimitGroups,
      'lastLoadTime': _lastLoadTime?.toIso8601String(),
    };
  }

  // Getters
  List<SpeedCamera> get allCameras => List.unmodifiable(_cameras);
  int get cameraCount => _cameras.length;
  bool get isEmpty => _cameras.isEmpty;
  bool get isNotEmpty => _cameras.isNotEmpty;
  DateTime? get lastLoadTime => _lastLoadTime;

  /// ล้างข้อมูลกล้องทั้งหมด
  void clear() {
    _cameras.clear();
    _cameraMap.clear();
    _lastLoadTime = null;
  }

  /// ทำความสะอาดทรัพยากร
  void dispose() {
    clear();
  }
}
