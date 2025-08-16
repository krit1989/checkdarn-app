import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'auth_service.dart';

/// 🌍 **Smart Location Service**
/// ระบบติดตามและอัปเดตตำแหน่งผู้ใช้อย่างฉลาดสำหรับ Geographic Targeting
///
/// **ฟีเจอร์หลัก:**
/// - ติดตามตำแหน่งผู้ใช้แบบเรียลไทม์
/// - อัปเดตข้อมูลตำแหน่งใน user_tokens collection
/// - Reverse geocoding เพื่อหาชื่อจังหวัด/อำเภอ
/// - Smart update (อัปเดตเฉพาะเมื่อมีการเปลี่ยนแปลงตำแหน่งอย่างมีนัยสำคัญ)
class SmartLocationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ระยะห่างขั้นต่ำที่จะอัปเดตตำแหน่ง (เมตร)
  static const double _minimumDistanceForUpdate = 1000; // 1 กิโลเมตร

  // เวลาขั้นต่ำระหว่างการอัปเดต (นาที)
  static const int _minimumUpdateIntervalMinutes = 15;

  static Position? _lastKnownPosition;
  static DateTime? _lastUpdateTime;

  /// 🚀 **อัปเดตตำแหน่งผู้ใช้สำหรับ Smart Geographic Targeting**
  static Future<bool> updateUserLocation({bool forceUpdate = false}) async {
    try {
      final String? userId = AuthService.currentUser?.uid;
      if (userId == null) {
        print(
            '⚠️ SmartLocationService: User not logged in, cannot update location');
        return false;
      }

      // ตรวจสอบเวลาการอัปเดตครั้งล่าสุด
      if (!forceUpdate && _lastUpdateTime != null) {
        final timeSinceLastUpdate = DateTime.now().difference(_lastUpdateTime!);
        if (timeSinceLastUpdate.inMinutes < _minimumUpdateIntervalMinutes) {
          print(
              '🕒 SmartLocationService: Too soon to update (${timeSinceLastUpdate.inMinutes} minutes ago)');
          return false;
        }
      }

      // ดึงข้อมูลตำแหน่งปัจจุบัน
      Map<String, dynamic> locationData = await _getCurrentLocationData();

      // ตรวจสอบระยะทางจากตำแหน่งล่าสุด
      if (!forceUpdate && _lastKnownPosition != null) {
        final distance = Geolocator.distanceBetween(
          _lastKnownPosition!.latitude,
          _lastKnownPosition!.longitude,
          locationData['lat'],
          locationData['lng'],
        );

        if (distance < _minimumDistanceForUpdate) {
          print(
              '📍 SmartLocationService: Position not changed significantly (${distance.toStringAsFixed(0)}m)');
          return false;
        }
      }

      // อัปเดตข้อมูลตำแหน่งใน user_tokens collection
      await _firestore.collection('user_tokens').doc(userId).update({
        'lastKnownLat': locationData['lat'],
        'lastKnownLng': locationData['lng'],
        'lastKnownProvince': locationData['province'],
        'lastKnownDistrict': locationData['district'],
        'lastKnownSubDistrict': locationData['subDistrict'],
        'lastLocationUpdate': FieldValue.serverTimestamp(),
        'locationAccuracy': locationData['accuracy'],
      });

      // อัปเดตตัวแปร cache
      _lastKnownPosition = Position(
        latitude: locationData['lat'],
        longitude: locationData['lng'],
        timestamp: DateTime.now(),
        accuracy: locationData['accuracy'],
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
      _lastUpdateTime = DateTime.now();

      print('🌍 SmartLocationService: User location updated successfully');
      print(
          '📍 Location: ${locationData['province']}, ${locationData['district']}');
      print('📊 Accuracy: ${locationData['accuracy'].toStringAsFixed(1)}m');
      return true;
    } catch (e) {
      print('❌ SmartLocationService: Error updating user location: $e');
      return false;
    }
  }

  /// 🌍 **ดึงข้อมูลตำแหน่งปัจจุบันพร้อม Reverse Geocoding (Public)**
  static Future<Map<String, dynamic>> getCurrentLocationData() async {
    return await _getCurrentLocationData();
  }

  /// 🏛️ **ตำแหน่งเริ่มต้น (กรุงเทพฯ) (Public)**
  static Map<String, dynamic> getDefaultLocation() {
    return _getDefaultLocation();
  }

  /// 🌍 **ดึงข้อมูลตำแหน่งปัจจุบันพร้อม Reverse Geocoding (Private)**
  static Future<Map<String, dynamic>> _getCurrentLocationData() async {
    try {
      // ตรวจสอบ permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        print(
            '⚠️ SmartLocationService: Location permission denied, using default location');
        return _getDefaultLocation();
      }

      // ตรวจสอบ location services
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print(
            '⚠️ SmartLocationService: Location services disabled, using default location');
        return _getDefaultLocation();
      }

      // ดึงตำแหน่งปัจจุบัน
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      // แปลงพิกัดเป็นที่อยู่
      Map<String, String> addressData =
          await _reverseGeocode(position.latitude, position.longitude);

      return {
        'lat': position.latitude,
        'lng': position.longitude,
        'province': addressData['province'] ?? 'ไม่ทราบจังหวัด',
        'district': addressData['district'] ?? 'ไม่ทราบอำเภอ',
        'subDistrict': addressData['subDistrict'] ?? 'ไม่ทราบตำบล',
        'accuracy': position.accuracy,
      };
    } catch (e) {
      print('❌ SmartLocationService: Error getting location data: $e');
      return _getDefaultLocation();
    }
  }

  /// 🗺️ **Reverse Geocoding - แปลงพิกัดเป็นที่อยู่**
  static Future<Map<String, String>> _reverseGeocode(
      double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;

        return {
          'province': placemark.administrativeArea ?? 'ไม่ทราบจังหวัด',
          'district': placemark.locality ?? 'ไม่ทราบอำเภอ',
          'subDistrict': placemark.subLocality ?? 'ไม่ทราบตำบล',
        };
      }
    } catch (e) {
      print('❌ SmartLocationService: Reverse geocoding error: $e');
    }

    return {
      'province': 'ไม่ทราบจังหวัด',
      'district': 'ไม่ทราบอำเภอ',
      'subDistrict': 'ไม่ทราบตำบล',
    };
  }

  /// 🏛️ **ตำแหน่งเริ่มต้น (กรุงเทพฯ)**
  static Map<String, dynamic> _getDefaultLocation() {
    return {
      'lat': 13.7563,
      'lng': 100.5018,
      'province': 'กรุงเทพมหานคร',
      'district': 'เขตพญาไท',
      'subDistrict': 'แขวงทุ่งพญาไท',
      'accuracy': 0.0,
    };
  }

  /// 📊 **ดึงข้อมูลตำแหน่งล่าสุดจากแคช**
  static Map<String, dynamic>? getLastKnownLocation() {
    if (_lastKnownPosition == null) return null;

    return {
      'lat': _lastKnownPosition!.latitude,
      'lng': _lastKnownPosition!.longitude,
      'accuracy': _lastKnownPosition!.accuracy,
      'timestamp': _lastKnownPosition!.timestamp,
    };
  }

  /// 🔄 **บังคับอัปเดตตำแหน่งทันที**
  static Future<bool> forceUpdateLocation() async {
    return await updateUserLocation(forceUpdate: true);
  }

  /// 📱 **เริ่มติดตามตำแหน่งแบบเรียลไทม์**
  static StreamSubscription<Position>? _positionStreamSubscription;

  static void startLocationTracking() {
    // หยุด stream เก่าก่อน (ถ้ามี)
    stopLocationTracking();

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 500, // อัปเดตทุก 500 เมตร
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        print(
            '📍 SmartLocationService: Position changed: ${position.latitude}, ${position.longitude}');
        // อัปเดตตำแหน่งเมื่อมีการเปลี่ยนแปลง
        updateUserLocation();
      },
      onError: (error) {
        print('❌ SmartLocationService: Location tracking error: $error');
      },
    );

    print('🎯 SmartLocationService: Started real-time location tracking');
  }

  /// ⏹️ **หยุดติดตามตำแหน่ง**
  static void stopLocationTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    print('⏹️ SmartLocationService: Stopped location tracking');
  }

  /// 📏 **คำนวณระยะทางระหว่างจุดสองจุด (กิโลเมตร)**
  static double calculateDistance(
      double lat1, double lng1, double lat2, double lng2) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2) /
        1000; // แปลงเป็น km
  }
}
