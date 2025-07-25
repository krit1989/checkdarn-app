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
      // กล้องบนถนนพระราม 4
      SpeedCamera(
        id: 'cam_001',
        location: const LatLng(13.7307, 100.5418),
        speedLimit: 80,
        roadName: 'ถนนพระราม 4',
        type: CameraType.fixed,
        description: 'หน้าสนามกีฬาแห่งชาติ',
      ),

      // กล้องบนถนนสุขุมวิท
      SpeedCamera(
        id: 'cam_002',
        location: const LatLng(13.7367, 100.5568),
        speedLimit: 60,
        roadName: 'ถนนสุขุมวิท',
        type: CameraType.fixed,
        description: 'ใกล้ Terminal 21',
      ),

      // กล้องบนถนนพหลโยธิน
      SpeedCamera(
        id: 'cam_003',
        location: const LatLng(13.8097, 100.5568),
        speedLimit: 90,
        roadName: 'ถนนพหลโยธิน',
        type: CameraType.fixed,
        description: 'ช่วงรังสิต',
      ),

      // กล้องบนถนนเพชรบุรี
      SpeedCamera(
        id: 'cam_004',
        location: const LatLng(13.7519, 100.5389),
        speedLimit: 80,
        roadName: 'ถนนเพชรบุรี',
        type: CameraType.average,
        description: 'หน้า MBK Center',
      ),

      // กล้องบนถนนรัชดาภิเษก
      SpeedCamera(
        id: 'cam_005',
        location: const LatLng(13.7650, 100.5388),
        speedLimit: 80,
        roadName: 'ถนนรัชดาภิเษก',
        type: CameraType.fixed,
        description: 'ใกล้ห้วยขวาง',
      ),

      // กล้องบนทางด่วน
      SpeedCamera(
        id: 'cam_006',
        location: const LatLng(13.7234, 100.5665),
        speedLimit: 120,
        roadName: 'ทางด่วนศรีรัช',
        type: CameraType.fixed,
        description: 'ช่วงสะพานพุทธ',
      ),

      // กล้องบนถนนพระรามที่ 2
      SpeedCamera(
        id: 'cam_007',
        location: const LatLng(13.7108, 100.4865),
        speedLimit: 90,
        roadName: 'ถนนพระรามที่ 2',
        type: CameraType.fixed,
        description: 'ช่วงวงเวียนใหญ่',
      ),

      // กล้องบนถนนเจริญกรุง
      SpeedCamera(
        id: 'cam_008',
        location: const LatLng(13.7278, 100.5200),
        speedLimit: 60,
        roadName: 'ถนนเจริญกรุง',
        type: CameraType.redLight,
        description: 'สี่แยกตลาดพลู',
      ),

      // กล้องบนถนนงามวงศ์วาน
      SpeedCamera(
        id: 'cam_009',
        location: const LatLng(13.8567, 100.5200),
        speedLimit: 80,
        roadName: 'ถนนงามวงศ์วาน',
        type: CameraType.mobile,
        description: 'ช่วงหลักสี่',
      ),

      // กล้องตรงข้ามวัดหนองตำลึง
      SpeedCamera(
        id: 'wat_nong_tamleung_001',
        location: const LatLng(13.415608, 101.066296),
        speedLimit: 80,
        roadName: 'ถนนเทพารักษ์',
        type: CameraType.fixed,
        description: 'ตรงข้ามวัดหนองตำลึง',
      ),

      // กล้องตลาดรถเมย์หนองตำลึง
      SpeedCamera(
        id: 'nong_tamleung_market_002',
        location: const LatLng(13.416935, 101.072607),
        speedLimit: 80,
        roadName: 'ถนนเทพารักษ์',
        type: CameraType.average,
        description: 'ตลาดรถเมย์หนองตำลึง',
      ),

      // กล้องปั้มเชล
      SpeedCamera(
        id: 'shell_station_003',
        location: const LatLng(13.418538, 101.079593),
        speedLimit: 80,
        roadName: 'ถนนเทพารักษ์',
        type: CameraType.fixed,
        description: 'ปั้มเชล',
      ),

      // กล้องอีซุซุ
      SpeedCamera(
        id: 'isuzu_004',
        location: const LatLng(13.419532, 101.084152),
        speedLimit: 80,
        roadName: 'ถนนเทพารักษ์',
        type: CameraType.redLight,
        description: 'อีซุซุ',
      ),

      // กล้องดับเพลิงหนองกะขะ
      SpeedCamera(
        id: 'fire_station_nong_kaka_005',
        location: const LatLng(13.419955, 101.092905),
        speedLimit: 80,
        roadName: 'ถนนเทพารักษ์',
        type: CameraType.mobile,
        description: 'ดับเพลิงหนองกะขะ',
      ),

      // กล้องโตโยต้า
      SpeedCamera(
        id: 'toyota_006',
        location: const LatLng(13.422553, 101.103420),
        speedLimit: 80,
        roadName: 'ถนนเทพารักษ์',
        type: CameraType.fixed,
        description: 'โตโยต้า',
      ),

      // กล้องแยกมาบโป่ง
      SpeedCamera(
        id: 'mab_pong_junction_007',
        location: const LatLng(13.424520, 101.109515),
        speedLimit: 60,
        roadName: 'ถนนเทพารักษ์',
        type: CameraType.redLight,
        description: 'แยกมาบโป่ง',
      ),

      // กล้องปตทมาบโป่ง
      SpeedCamera(
        id: 'ptt_mab_pong_008',
        location: const LatLng(13.429068, 101.108987),
        speedLimit: 80,
        roadName: 'ถนนเทพารักษ์',
        type: CameraType.fixed,
        description: 'ปตทมาบโป่ง',
      ),

      // กล้องตลาดเดอะวอร์ค
      SpeedCamera(
        id: 'the_work_market_009',
        location: const LatLng(13.437994, 101.106309),
        speedLimit: 80,
        roadName: 'ถนนเทพารักษ์',
        type: CameraType.average,
        description: 'ตลาดเดอะวอร์ค',
      ),

      // กล้องตรงข้ามดีมาร์เก็ต
      SpeedCamera(
        id: 'opposite_d_market_010',
        location: const LatLng(13.441337, 101.105050),
        speedLimit: 80,
        roadName: 'ถนนเทพารักษ์',
        type: CameraType.fixed,
        description: 'ตรงข้ามดีมาร์เก็ต',
      ),

      // กล้องดีมาร์เก็ต
      SpeedCamera(
        id: 'd_market_011',
        location: const LatLng(13.441183, 101.105379),
        speedLimit: 80,
        roadName: 'ถนนเทพารักษ์',
        type: CameraType.mobile,
        description: 'ดีมาร์เก็ต',
      ),

      // กล้องแยกเฟส9
      SpeedCamera(
        id: 'phase9_junction_012',
        location: const LatLng(13.443804, 101.103453),
        speedLimit: 80,
        roadName: 'ถนนเทพารักษ์',
        type: CameraType.redLight,
        description: 'แยกเฟส9',
      ),

      // กล้องไทยวันเดอร์ฟูล
      SpeedCamera(
        id: 'thai_wonderful_013',
        location: const LatLng(13.453604, 101.096536),
        speedLimit: 80,
        roadName: 'ถนนเทพารักษ์',
        type: CameraType.fixed,
        description: 'ไทยวันเดอร์ฟูล',
      ),

      // กล้องโรงเรียนพานทองสภา
      SpeedCamera(
        id: 'panthong_sabha_school_014',
        location: const LatLng(13.463307, 101.092410),
        speedLimit: 60,
        roadName: 'ถนนเทพารักษ์',
        type: CameraType.fixed,
        description: 'โรงเรียนพานทองสภา',
      ),

      // กล้องโลตัสกลางพานทอง
      SpeedCamera(
        id: 'lotus_panthong_015',
        location: const LatLng(13.462390, 101.092818),
        speedLimit: 80,
        roadName: 'ถนนเทพารักษ์',
        type: CameraType.average,
        description: 'โลตัสกลางพานทอง',
      ),

      // กล้องโสภาภัณ
      SpeedCamera(
        id: 'sopapan_016',
        location: const LatLng(13.457542, 101.094636),
        speedLimit: 80,
        roadName: 'ถนนเทพารักษ์',
        type: CameraType.mobile,
        description: 'โสภาภัณ',
      ),

      // กล้องโรงงานอาจีกา
      SpeedCamera(
        id: 'agiga_factory_017',
        location: const LatLng(13.450818, 101.098528),
        speedLimit: 80,
        roadName: 'ถนนเทพารักษ์',
        type: CameraType.fixed,
        description: 'โรงงานอาจีกา',
      ),

      // === กล้องบนเส้นทางแกลง - ท่าเกวียน ===

      // กล้อง TJH para
      SpeedCamera(
        id: 'tjh_para_018',
        location: const LatLng(12.829227, 101.628086),
        speedLimit: 90,
        roadName: 'ถนนแกลง-บ้านบึง',
        type: CameraType.fixed,
        description: 'TJH para',
      ),

      // กล้องชัยเจริญมอเตอร์
      SpeedCamera(
        id: 'chaicharoen_motor_019',
        location: const LatLng(12.812271, 101.636426),
        speedLimit: 90,
        roadName: 'ถนนแกลง-บ้านบึง',
        type: CameraType.average,
        description: 'ชัยเจริญมอเตอร์',
      ),

      // กล้องบายพาสท่าเกวียน
      SpeedCamera(
        id: 'tha_kwian_bypass_020',
        location: const LatLng(12.806457, 101.638312),
        speedLimit: 90,
        roadName: 'ถนนแกลง-บ้านบึง',
        type: CameraType.redLight,
        description: 'บายพาสท่าเกวียน',
      ),

      // กล้องสามย่านแกลง
      SpeedCamera(
        id: 'sam_yan_klaeng_021',
        location: const LatLng(12.787217, 101.649743),
        speedLimit: 80,
        roadName: 'ถนนแกลง-บ้านบึง',
        type: CameraType.fixed,
        description: 'สามย่านแกลง',
      ),

      // กล้องโลตัสแกลง
      SpeedCamera(
        id: 'lotus_klaeng_022',
        location: const LatLng(12.785672, 101.659718),
        speedLimit: 80,
        roadName: 'ถนนแกลง-บ้านบึง',
        type: CameraType.mobile,
        description: 'โลตัสแกลง',
      ),

      // กล้องแกลง ยอง
      SpeedCamera(
        id: 'klaeng_yong_023',
        location: const LatLng(12.783924, 101.656172),
        speedLimit: 80,
        roadName: 'ถนนแกลง-บ้านบึง',
        type: CameraType.average,
        description: 'แกลง ยอง',
      ),

      // กล้องรุ่งทวีอะไหล่ยนต์
      SpeedCamera(
        id: 'rung_thawi_parts_024',
        location: const LatLng(12.781863, 101.647372),
        speedLimit: 80,
        roadName: 'ถนนแกลง-บ้านบึง',
        type: CameraType.fixed,
        description: 'รุ่งทวีอะไหล่ยนต์',
      ),

      // กล้องเควิน รีสอร์ท
      SpeedCamera(
        id: 'kevin_resort_025',
        location: const LatLng(12.839286, 101.624131),
        speedLimit: 90,
        roadName: 'ถนนแกลง-บ้านบึง',
        type: CameraType.redLight,
        description: 'เควิน รีสอร์ท',
      ),

      // กล้องพีที แกลง
      SpeedCamera(
        id: 'pt_klaeng_026',
        location: const LatLng(12.822411, 101.630809),
        speedLimit: 90,
        roadName: 'ถนนแกลง-บ้านบึง',
        type: CameraType.fixed,
        description: 'พีที แกลง',
      ),

      // กล้องแยกบ้านนา
      SpeedCamera(
        id: 'ban_na_junction_027',
        location: const LatLng(12.798015, 101.665889),
        speedLimit: 80,
        roadName: 'ถนนแกลง-บ้านบึง',
        type: CameraType.redLight,
        description: 'แยกบ้านนา',
      ),

      // กล้องบนถนนลาดพร้าว
      SpeedCamera(
        id: 'cam_010',
        location: const LatLng(13.7967, 100.5678),
        speedLimit: 80,
        roadName: 'ถนนลาดพร้าว',
        type: CameraType.fixed,
        description: 'หน้า Union Mall',
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
