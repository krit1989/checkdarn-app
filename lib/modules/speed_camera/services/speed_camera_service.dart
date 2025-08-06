import '../models/speed_camera_model.dart';
import 'package:latlong2/latlong.dart';
import 'camera_report_service.dart';
import 'dart:math' as math;

class SpeedCameraService {
  // static const String _baseUrl = 'https://data.go.th/api/speed-cameras'; // Mock URL - for future use

  /// ดึงข้อมูลกล้องจับความเร็วทั้งหมด (Community Verified เท่านั้น)
  static Future<List<SpeedCamera>> getSpeedCameras() async {
    try {
      print('🔍 Loading speed cameras from Community sources only...');

      // โหลด Community Verified Cameras จาก Firebase เท่านั้น
      List<SpeedCamera> communityCameras = [];
      try {
        communityCameras = await CameraReportService.getAllSpeedCameras(
          forceRefresh: true, // FORCE REFRESH เพื่อดูกล้องใหม่
        );
        print('🏘️ Community cameras loaded: ${communityCameras.length}');

        // Debug: แสดงรายชื่อกล้อง community
        for (int i = 0; i < communityCameras.length; i++) {
          final camera = communityCameras[i];
          print(
              '   Community Camera ${i + 1}: ${camera.roadName} (${camera.description})');
        }
      } catch (e) {
        print('❌ Error loading community cameras: $e');
        // ถ้าเกิด error ให้คืนค่า list ว่าง แทนที่จะใช้ mock data
        return [];
      }

      print(
          '✅ Total cameras loaded: ${communityCameras.length} (Community only)');

      return communityCameras;

      /*
      // สำหรับอนาคต: API Call จริง
      final response = await http.get(
        Uri.parse('$_baseUrl/cameras'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> camerasJson = data['data'] ?? [];
        
        return camerasJson
            .map((json) => SpeedCamera.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to load speed cameras: ${response.statusCode}');
      }
      */
    } catch (e) {
      print('❌ Error loading speed cameras: $e');
      // ถ้า error ให้ return list ว่าง แทนที่จะใช้ mock data
      return [];
    }
  }

  /// ดึงข้อมูลกล้องที่ใกล้ที่สุด
  static SpeedCamera? findNearestCamera(
    LatLng currentLocation,
    List<SpeedCamera> cameras, {
    double maxDistance = 5000, // เมตร
  }) {
    if (cameras.isEmpty) return null;

    SpeedCamera? nearestCamera;
    double nearestDistance = maxDistance;

    for (final camera in cameras) {
      final distance = _calculateDistance(currentLocation, camera.location);
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearestCamera = camera;
      }
    }

    return nearestCamera;
  }

  /// ดึงข้อมูลกล้องทั้งหมดที่อยู่ในระยะที่กำหนด
  static List<SpeedCamera> getCamerasInRange(
    LatLng currentLocation,
    List<SpeedCamera> cameras, {
    double range = 2000, // เมตร
  }) {
    return cameras.where((camera) {
      final distance = _calculateDistance(currentLocation, camera.location);
      return distance <= range;
    }).toList();
  }

  /// คำนวณระยะทางระหว่างสองจุด (เมตร)
  static double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // รัศมีโลกในหน่วยเมตร

    final double lat1Rad = point1.latitude * (math.pi / 180);
    final double lat2Rad = point2.latitude * (math.pi / 180);
    final double deltaLatRad =
        (point2.latitude - point1.latitude) * (math.pi / 180);
    final double deltaLngRad =
        (point2.longitude - point1.longitude) * (math.pi / 180);

    final double a = math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.sin(deltaLngRad / 2) *
            math.sin(deltaLngRad / 2);
    final double c = 2 * math.asin(math.sqrt(a));

    return earthRadius * c;
  }

  /// กรองกล้องตามประเภท
  static List<SpeedCamera> filterCamerasByType(
    List<SpeedCamera> cameras,
    CameraType type,
  ) {
    return cameras.where((camera) => camera.type == type).toList();
  }

  /// กรองกล้องตามจำกัดความเร็ว
  static List<SpeedCamera> filterCamerasBySpeedLimit(
    List<SpeedCamera> cameras, {
    int? minSpeed,
    int? maxSpeed,
  }) {
    return cameras.where((camera) {
      if (minSpeed != null && camera.speedLimit < minSpeed) return false;
      if (maxSpeed != null && camera.speedLimit > maxSpeed) return false;
      return true;
    }).toList();
  }

  /// จัดเรียงกล้องตามระยะทาง
  static List<SpeedCamera> sortCamerasByDistance(
    LatLng currentLocation,
    List<SpeedCamera> cameras,
  ) {
    final List<MapEntry<SpeedCamera, double>> camerasWithDistance = cameras
        .map((camera) => MapEntry(
              camera,
              _calculateDistance(currentLocation, camera.location),
            ))
        .toList();

    camerasWithDistance.sort((a, b) => a.value.compareTo(b.value));

    return camerasWithDistance.map((entry) => entry.key).toList();
  }

  /// ค้นหากล้องตามชื่อถนน
  static List<SpeedCamera> searchCamerasByRoadName(
    List<SpeedCamera> cameras,
    String query,
  ) {
    final String lowerQuery = query.toLowerCase();
    return cameras
        .where((camera) =>
            camera.roadName.toLowerCase().contains(lowerQuery) ||
            (camera.description?.toLowerCase().contains(lowerQuery) ?? false))
        .toList();
  }

  /// ดึงกล้องตาม ID
  static Future<SpeedCamera?> getCameraById(String cameraId) async {
    try {
      print('🔍 Getting camera by ID: $cameraId');

      // ดึงกล้องทั้งหมดแล้วหากล้องที่ตรงตาม ID
      final cameras = await CameraReportService.getAllSpeedCameras();

      for (final camera in cameras) {
        if (camera.id == cameraId) {
          print('✅ Found camera: ${camera.roadName}');
          return camera;
        }
      }

      print('❌ Camera not found with ID: $cameraId');
      return null;
    } catch (e) {
      print('❌ Error getting camera by ID: $e');
      return null;
    }
  }

  /// ตรวจสอบว่ากล้องยังใช้งานได้หรือไม่
  static Future<bool> isCameraActive(String cameraId) async {
    // สำหรับ Community cameras ให้ตรวจสอบจาก Firebase
    try {
      final cameras = await CameraReportService.getAllSpeedCameras();
      return cameras.any((camera) => camera.id == cameraId);
    } catch (e) {
      print('❌ Error checking camera status: $e');
      return false;
    }
  }

  /// อัปเดตสถานะกล้อง (สำหรับการรายงานปัญหา)
  static Future<void> reportCameraIssue(
    String cameraId,
    String issueType,
    String description,
  ) async {
    // ใช้ CameraReportService ในการรายงานปัญหา
    // TODO: Implement camera issue reporting
    print('📝 Reporting camera issue: $cameraId - $issueType: $description');
  }

  /// ดึงข้อมูลสถิติการใช้งานกล้อง
  static Map<String, dynamic> getCameraStatistics(List<SpeedCamera> cameras) {
    final typeCount = <CameraType, int>{};
    final speedRanges = <String, int>{
      'low': 0, // ≤ 60 km/h
      'medium': 0, // 61-90 km/h
      'high': 0, // > 90 km/h
    };

    for (final camera in cameras) {
      // นับประเภทกล้อง
      typeCount[camera.type] = (typeCount[camera.type] ?? 0) + 1;

      // นับช่วงความเร็ว
      if (camera.speedLimit <= 60) {
        speedRanges['low'] = speedRanges['low']! + 1;
      } else if (camera.speedLimit <= 90) {
        speedRanges['medium'] = speedRanges['medium']! + 1;
      } else {
        speedRanges['high'] = speedRanges['high']! + 1;
      }
    }

    return {
      'total': cameras.length,
      'typeCount': typeCount,
      'speedRanges': speedRanges,
    };
  }
}
