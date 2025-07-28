import '../models/speed_camera_model.dart';
import 'package:latlong2/latlong.dart';

class SpeedCameraService {
  // static const String _baseUrl = 'https://data.go.th/api/speed-cameras'; // Mock URL - for future use

  /// ดึงข้อมูลกล้องจับความเร็วทั้งหมด
  static Future<List<SpeedCamera>> getSpeedCameras() async {
    try {
      // ในขณะนี้ใช้ Mock Data แทน API จริง
      return _getMockSpeedCameras();

      // TODO: เมื่อมี API จริง ให้ใช้โค้ดนี้
      /*
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
      print('Error loading speed cameras: $e');
      // ถ้า error ให้ return mock data แทน
      return _getMockSpeedCameras();
    }
  }

  /// ดึงข้อมูลกล้องในพื้นที่ระบุ
  static Future<List<SpeedCamera>> getSpeedCamerasInArea({
    required LatLng center,
    required double radiusKm,
  }) async {
    final allCameras = await getSpeedCameras();

    return allCameras.where((camera) {
      final distance = _calculateDistance(center, camera.location);
      return distance <= radiusKm;
    }).toList();
  }

  /// คำนวณระยะห่างระหว่างจุด 2 จุด (กิโลเมตร)
  static double _calculateDistance(LatLng point1, LatLng point2) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Kilometer, point1, point2);
  }

  /// Mock data สำหรับทดสอบ - กล้องจับความเร็วในกรุงเทพฯ และชลบุรี
  static List<SpeedCamera> _getMockSpeedCameras() {
    return [
      // === กล้องความเร็วต่ำ (สีเขียว) ===

      // กล้องในโซนโรงเรียน
      SpeedCamera(
        id: 'school_zone_001',
        location: const LatLng(13.7367, 100.5568),
        speedLimit: 30, // โซนโรงเรียน
        roadName: 'ถนนสุขุมวิท',
        type: CameraType.fixed,
        description: 'โซนโรงเรียน - ใกล้ Terminal 21',
      ),

      // กล้องในชุมชน
      SpeedCamera(
        id: 'community_002',
        location: const LatLng(13.7278, 100.5200),
        speedLimit: 50, // ชุมชน
        roadName: 'ถนนเจริญกรุง',
        type: CameraType.redLight,
        description: 'ชุมชนตลาดพลู',
      ),

      // กล้องในเขตเมือง
      SpeedCamera(
        id: 'city_zone_003',
        location: const LatLng(13.424520, 101.109515),
        speedLimit: 60, // เขตเมือง
        roadName: 'ถนนเทพารักษ์',
        type: CameraType.redLight,
        description: 'แยกมาบโป่ง - เขตเมือง',
      ),

      SpeedCamera(
        id: 'school_zone_004',
        location: const LatLng(13.463307, 101.092410),
        speedLimit: 40, // โซนโรงเรียน
        roadName: 'ถนนเทพารักษ์',
        type: CameraType.fixed,
        description: 'โรงเรียนพานทองสภา',
      ),

      // === กล้องความเร็วกลาง (สีส้ม) ===

      // กล้องบนถนนปกติ
      SpeedCamera(
        id: 'normal_road_001',
        location: const LatLng(13.7307, 100.5418),
        speedLimit: 70, // ถนนปกติ
        roadName: 'ถนนพระราม 4',
        type: CameraType.fixed,
        description: 'หน้าสนามกีฬาแห่งชาติ',
      ),

      SpeedCamera(
        id: 'normal_road_002',
        location: const LatLng(13.7519, 100.5389),
        speedLimit: 80, // ถนนหลัก
        roadName: 'ถนนเพชรบุรี',
        type: CameraType.average,
        description: 'หน้า MBK Center',
      ),

      SpeedCamera(
        id: 'normal_road_003',
        location: const LatLng(13.7650, 100.5388),
        speedLimit: 75, // ถนนปกติ
        roadName: 'ถนนรัชดาภิเษก',
        type: CameraType.fixed,
        description: 'ใกล้ห้วยขวาง',
      ),

      SpeedCamera(
        id: 'normal_road_004',
        location: const LatLng(13.8567, 100.5200),
        speedLimit: 85, // ถนนใหญ่
        roadName: 'ถนนงามวงศ์วาน',
        type: CameraType.mobile,
        description: 'ช่วงหลักสี่',
      ),

      SpeedCamera(
        id: 'normal_road_005',
        location: const LatLng(13.8097, 100.5568),
        speedLimit: 90, // ถนนหลักใหญ่
        roadName: 'ถนนพหลโยธิน',
        type: CameraType.fixed,
        description: 'ช่วงรังสิต',
      ),

      // === กล้องความเร็วสูง (สีแดง) ===

      // กล้องบนทางด่วน
      SpeedCamera(
        id: 'highway_001',
        location: const LatLng(13.7234, 100.5665),
        speedLimit: 120, // ทางด่วน
        roadName: 'ทางด่วนศรีรัช',
        type: CameraType.fixed,
        description: 'ช่วงสะพานพุทธ',
      ),

      SpeedCamera(
        id: 'highway_002',
        location: const LatLng(13.7108, 100.4865),
        speedLimit: 100, // ทางหลวง
        roadName: 'ถนนพระรามที่ 2',
        type: CameraType.fixed,
        description: 'ช่วงวงเวียนใหญ่',
      ),

      SpeedCamera(
        id: 'highway_003',
        location: const LatLng(12.829227, 101.628086),
        speedLimit: 110, // ทางหลวงพิเศษ
        roadName: 'ถนนแกลง-บ้านบึง',
        type: CameraType.fixed,
        description: 'TJH para - ทางหลวงพิเศษ',
      ),

      SpeedCamera(
        id: 'highway_004',
        location: const LatLng(12.812271, 101.636426),
        speedLimit: 95, // ทางหลวง
        roadName: 'ถนนแกลง-บ้านบึง',
        type: CameraType.average,
        description: 'ชัยเจริญมอเตอร์',
      ),

      // === กล้องเพิ่มเติมเพื่อความหลากหลาย ===

      SpeedCamera(
        id: 'mixed_001',
        location: const LatLng(13.415608, 101.066296),
        speedLimit: 65, // เขตกึ่งเมือง
        roadName: 'ถนนเทพารักษ์',
        type: CameraType.fixed,
        description: 'ตรงข้ามวัดหนองตำลึง',
      ),

      SpeedCamera(
        id: 'mixed_002',
        location: const LatLng(13.416935, 101.072607),
        speedLimit: 45, // พื้นที่พาณิชย์
        roadName: 'ถนนเทพารักษ์',
        type: CameraType.average,
        description: 'ตลาดรถเมย์หนองตำลึง',
      ),

      SpeedCamera(
        id: 'mixed_003',
        location: const LatLng(13.418538, 101.079593),
        speedLimit: 80, // ถนนหลัก
        roadName: 'ถนนเทพารักษ์',
        type: CameraType.fixed,
        description: 'ปั้มเชล',
      ),

      SpeedCamera(
        id: 'mixed_004',
        location: const LatLng(13.419532, 101.084152),
        speedLimit: 55, // เขตอุตสาหกรรม
        roadName: 'ถนนเทพารักษ์',
        type: CameraType.redLight,
        description: 'อีซุซุ - เขตอุตสาหกรรม',
      ),

      SpeedCamera(
        id: 'mixed_005',
        location: const LatLng(13.7967, 100.5678),
        speedLimit: 105, // ถนนใหญ่พิเศษ
        roadName: 'ถนนลาดพร้าว',
        type: CameraType.fixed,
        description: 'หน้า Union Mall - ถนนใหญ่',
      ),

      // เพิ่มกล้องที่มีค่าขอบเขต
      SpeedCamera(
        id: 'border_001',
        location: const LatLng(13.422553, 101.103420),
        speedLimit: 60, // ขอบเขตสีเขียว-ส้ม
        roadName: 'ถนนเทพารักษ์',
        type: CameraType.fixed,
        description: 'โตโยต้า',
      ),

      SpeedCamera(
        id: 'border_002',
        location: const LatLng(13.429068, 101.108987),
        speedLimit: 90, // ขอบเขตสีส้ม-แดง
        roadName: 'ถนนเทพารักษ์',
        type: CameraType.fixed,
        description: 'ปตทมาบโป่ง',
      ),

      // กล้องดับเพลิงหนองกะขะ
      SpeedCamera(
        id: 'nong_krakha_001',
        location: const LatLng(13.420019, 101.093376),
        speedLimit: 90, // ขอบเขตสีส้ม-แดง
        roadName: 'ถนนสุขประยูร',
        type: CameraType.fixed,
        description: 'ดับเพลิงหนองกะขะ',
      ),

      // กล้องตลาดดีมาร์เก็ท
      SpeedCamera(
        id: 'dee_market_001',
        location: const LatLng(13.440931, 101.105507),
        speedLimit: 120, // ความเร็วสูง (สีแดง)
        roadName: 'ถนนเทพารักษ์',
        type: CameraType.fixed,
        description: 'ตลาดดีมาร์เก็ท',
      ),
    ];
  }

  /// ดึงข้อมูลกล้องที่ใกล้ที่สุด
  static SpeedCamera? findNearestCamera(
      LatLng userLocation, List<SpeedCamera> cameras) {
    if (cameras.isEmpty) return null;

    SpeedCamera? nearest;
    double minDistance = double.infinity;

    for (final camera in cameras) {
      final distance = _calculateDistance(userLocation, camera.location);
      if (distance < minDistance) {
        minDistance = distance;
        nearest = camera;
      }
    }

    return nearest;
  }

  /// ตรวจสอบว่าผู้ใช้ใกล้กล้องหรือไม่ (ระยะเป็นเมตร)
  static bool isNearCamera(LatLng userLocation, SpeedCamera camera,
      {double thresholdMeters = 500}) {
    const Distance distance = Distance();
    final distanceMeters =
        distance.as(LengthUnit.Meter, userLocation, camera.location);
    return distanceMeters <= thresholdMeters;
  }

  /// คำนวณระยะห่างเป็นเมตร
  static double getDistanceInMeters(LatLng point1, LatLng point2) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Meter, point1, point2);
  }
}
