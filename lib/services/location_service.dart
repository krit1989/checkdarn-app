import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Check if location services are enabled and permissions are granted
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check location permission status
  static Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Request location permission
  static Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Get current location
  static Future<Position?> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      // Check permissions
      LocationPermission permission = await checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      // Try to get last known position first (faster)
      final lastKnown = await getLastKnownPosition();
      if (lastKnown != null) {
        final now = DateTime.now();
        final positionTime = lastKnown.timestamp;
        // ใช้ position เก่าถ้าไม่เก่าเกิน 5 นาที
        if (now.difference(positionTime).inMinutes < 5) {
          return lastKnown;
        }
      }

      // Get current position with timeout
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium, // ลดความแม่นยำเพื่อความเร็ว
        timeLimit: const Duration(seconds: 8), // เพิ่ม timeout
      );
    } catch (e) {
      // ถ้า error ลอง fallback ไปใช้ last known position
      try {
        return await getLastKnownPosition();
      } catch (e2) {
        return null;
      }
    }
  }

  /// Get location stream for real-time updates
  static Stream<Position> getLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium, // ลดความแม่นยำเพื่อประสิทธิภาพ
        distanceFilter: 15, // Update every 15 meters (เพิ่มจาก 10)
        timeLimit: Duration(seconds: 10), // เพิ่ม timeout
      ),
    ).timeout(
      const Duration(seconds: 12), // Global timeout สำหรับ stream
      onTimeout: (sink) {
        // ถ้า timeout ให้ปิด stream
        sink.close();
      },
    );
  }

  /// Calculate distance between two points in meters
  static double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Check if a point is within a radius from a center point
  static bool isWithinRadius(
    double centerLat,
    double centerLng,
    double pointLat,
    double pointLng,
    double radiusInMeters,
  ) {
    double distance = calculateDistance(
      centerLat,
      centerLng,
      pointLat,
      pointLng,
    );
    return distance <= radiusInMeters;
  }

  /// Open device location settings
  static Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Open app settings
  static Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  /// Get last known position
  static Future<Position?> getLastKnownPosition() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (e) {
      return null;
    }
  }
}
