import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// 📍 **Location Manager**
/// ระบบจัดการตำแหน่ง GPS และการติดตามที่แยกออกมา
/// มีระบบป้องกัน GPS Spoofing และการตรวจสอบความน่าเชื่อถือ
class LocationManager {
  // Current state
  final ValueNotifier<LatLng> currentPositionNotifier = ValueNotifier(
    const LatLng(13.7563, 100.5018), // Default Bangkok
  );
  final ValueNotifier<double> currentSpeedNotifier = ValueNotifier(0.0);
  final ValueNotifier<double> headingNotifier = ValueNotifier(0.0);

  // GPS tracking
  StreamSubscription<Position>? _positionSubscription;
  List<Position> _positionHistory = [];
  Position? _lastTrustedPosition;

  // Anti-spoofing system
  int _gpsAnomalyCount = 0;
  final int _maxGpsAnomalies = 5;
  final double _maxAcceptableAccuracy = 50.0; // เมตร
  final double _maxAcceptableSpeedAccuracy = 2.0;
  final double _maxLocationJump = 500.0; // เมตร
  final double _maxReasonableSpeed = 180.0; // km/h

  // Callbacks
  final Function(Position)? onPositionUpdate;
  final Function(String)? onSecurityAlert;

  LocationManager({
    this.onPositionUpdate,
    this.onSecurityAlert,
  });

  // Getters
  LatLng get currentPosition => currentPositionNotifier.value;
  double get currentSpeed => currentSpeedNotifier.value;
  double get heading => headingNotifier.value;
  List<Position> get positionHistory => List.unmodifiable(_positionHistory);
  bool get isTracking => _positionSubscription != null;

  /// เริ่มติดตามตำแหน่ง
  Future<void> startTracking() async {
    if (_positionSubscription != null) {
      print('📍 LocationManager: Already tracking');
      return;
    }

    try {
      // ขอสิทธิ์การเข้าถึงตำแหน่ง
      final permission = await _requestLocationPermission();
      if (!permission) {
        throw Exception('Location permission denied');
      }

      // เริ่มติดตามตำแหน่ง - ใช้ settings ตามแพลตฟอร์ม
      final locationSettings = Platform.isAndroid
          ? AndroidSettings(
              accuracy: LocationAccuracy.bestForNavigation,
              distanceFilter: 0,
              intervalDuration: const Duration(
                  milliseconds: 300), // 300ms สำหรับ Android - ไวขึ้น
            )
          : AppleSettings(
              accuracy: LocationAccuracy.bestForNavigation,
              distanceFilter: 1, // ลดแบตบน iOS
              pauseLocationUpdatesAutomatically: true,
            );

      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        _handlePositionUpdate,
        onError: _handleLocationError,
      );

      print('📍 LocationManager: Started tracking');
    } catch (e) {
      print('❌ LocationManager: Error starting tracking: $e');
      rethrow;
    }
  }

  /// หยุดติดตามตำแหน่ง
  Future<void> stopTracking() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    print('📍 LocationManager: Stopped tracking');
  }

  /// ขอสิทธิ์การเข้าถึงตำแหน่ง
  Future<bool> _requestLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return false;
      }

      return true;
    } catch (e) {
      print('❌ LocationManager: Error requesting permission: $e');
      return false;
    }
  }

  /// จัดการการอัปเดตตำแหน่ง
  void _handlePositionUpdate(Position position) {
    try {
      // ลดความซับซ้อนของการตรวจสอบ
      if (!_isGpsTrusted(position)) return;

      final newSpeed = position.speed * 3.6; // m/s -> km/h

      // อัปเดตค่าแบบ immediate
      currentSpeedNotifier.value = newSpeed;
      currentPositionNotifier.value =
          LatLng(position.latitude, position.longitude);

      // อัปเดตทิศทางแบบไม่ต้อง interpolate เมื่อความเร็วสูง
      if (newSpeed > 10 && position.heading.isFinite) {
        headingNotifier.value = position.heading;
      }

      // เพิ่มในประวัติ
      _addToHistory(position);

      // เรียก callback
      onPositionUpdate?.call(position);
    } catch (e) {
      print('❌ LocationManager: Error handling position update: $e');
    }
  }

  /// ตรวจสอบความน่าเชื่อถือของ GPS
  bool _isGpsTrusted(Position position) {
    // ตรวจสอบความแม่นยำ
    if (position.accuracy > _maxAcceptableAccuracy) {
      _gpsAnomalyCount++;
      _reportSecurityIssue('GPS accuracy too low: ${position.accuracy}m');
      return false;
    }

    // ตรวจสอบความแม่นยำความเร็ว
    if (position.speedAccuracy > _maxAcceptableSpeedAccuracy) {
      _gpsAnomalyCount++;
      _reportSecurityIssue(
          'GPS speed accuracy too low: ${position.speedAccuracy}');
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

      if (distance > maxPossibleDistance && distance > _maxLocationJump) {
        _gpsAnomalyCount++;
        _reportSecurityIssue(
            'Impossible GPS jump: ${distance}m in ${timeDiff}s');
        return false;
      }
    }

    // ตรวจสอบความเร็วผิดปกติ
    final speedKmh = position.speed * 3.6;
    if (speedKmh > _maxReasonableSpeed) {
      _gpsAnomalyCount++;
      _reportSecurityIssue('Unrealistic speed: ${speedKmh}km/h');
      return false;
    }

    // ถ้าผ่านการตรวจสอบทั้งหมด
    _lastTrustedPosition = position;
    if (_gpsAnomalyCount > 0) {
      _gpsAnomalyCount--; // ลดค่าความผิดปกติเมื่อมีข้อมูลที่ถูกต้อง
    }

    return true;
  }

  /// รายงานปัญหาความปลอดภัย
  void _reportSecurityIssue(String issue) {
    print('🚨 LocationManager Security: $issue');
    print('🚨 GPS anomaly count: $_gpsAnomalyCount/$_maxGpsAnomalies');

    onSecurityAlert?.call(issue);

    if (_gpsAnomalyCount >= _maxGpsAnomalies) {
      onSecurityAlert?.call('GPS_SPOOFING_DETECTED');
    }
  }

  /// เพิ่มตำแหน่งในประวัติ
  void _addToHistory(Position position) {
    _positionHistory.add(position);

    // เก็บเฉพาะ 20 ตำแหน่งล่าสุด
    if (_positionHistory.length > 20) {
      _positionHistory.removeAt(0);
    }
  }

  /// จัดการข้อผิดพลาดของตำแหน่ง
  void _handleLocationError(Object error) {
    print('❌ LocationManager: Position stream error: $error');
    onSecurityAlert?.call('LOCATION_ERROR: $error');
  }

  /// ดึงตำแหน่งปัจจุบันครั้งเดียว
  Future<Position?> getCurrentPosition() async {
    try {
      final permission = await _requestLocationPermission();
      if (!permission) return null;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (_isGpsTrusted(position)) {
        return position;
      }
      return null;
    } catch (e) {
      print('❌ LocationManager: Error getting current position: $e');
      return null;
    }
  }

  /// คำนวณความเร็วเฉลี่ยจากประวัติ
  double getAverageSpeed({int lastNPositions = 5}) {
    if (_positionHistory.length < 2) return 0.0;

    final positions = _positionHistory.length > lastNPositions
        ? _positionHistory.sublist(_positionHistory.length - lastNPositions)
        : _positionHistory;

    final speeds = positions.map((p) => p.speed * 3.6).toList();
    return speeds.reduce((a, b) => a + b) / speeds.length;
  }

  /// ทำนายตำแหน่งล่วงหน้า
  LatLng? predictFuturePosition({int secondsAhead = 10}) {
    if (_positionHistory.length < 3) return null;

    final recent = _positionHistory.sublist(_positionHistory.length - 3);
    final avgSpeed = recent.map((p) => p.speed).reduce((a, b) => a + b) / 3;
    final avgHeading = recent.map((p) => p.heading).reduce((a, b) => a + b) / 3;

    if (avgSpeed < 2.0 || !avgHeading.isFinite) return null;

    try {
      final distanceMeters = avgSpeed * secondsAhead;
      final currentPos = currentPosition;

      final predictedLat = currentPos.latitude +
          (distanceMeters * cos(avgHeading * pi / 180)) / 111000;
      final predictedLng = currentPos.longitude +
          (distanceMeters * sin(avgHeading * pi / 180)) /
              (111000 * cos(currentPos.latitude * pi / 180));

      return LatLng(predictedLat, predictedLng);
    } catch (e) {
      print('❌ LocationManager: Error predicting position: $e');
      return null;
    }
  }

  /// สถิติระบบ GPS
  Map<String, dynamic> getGpsStatistics() {
    return {
      'anomalyCount': _gpsAnomalyCount,
      'maxAnomalies': _maxGpsAnomalies,
      'historySize': _positionHistory.length,
      'isTracking': isTracking,
      'lastTrustedPosition': _lastTrustedPosition?.timestamp.toIso8601String(),
      'averageSpeed': getAverageSpeed(),
    };
  }

  /// รีเซ็ตระบบความปลอดภัย
  void resetSecurityCounters() {
    _gpsAnomalyCount = 0;
    print('📍 LocationManager: Security counters reset');
  }

  /// ทำความสะอาดทรัพยากร
  void dispose() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _positionHistory.clear();
    currentPositionNotifier.dispose();
    currentSpeedNotifier.dispose();
    headingNotifier.dispose();
  }
}
