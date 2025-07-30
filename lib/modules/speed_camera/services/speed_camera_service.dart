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

      // === กล้องจับความเร็วจังหวัดระยอง ===

      // โตโยต้าระยอง
      SpeedCamera(
        id: 'rayong_toyota_001',
        location: const LatLng(12.682739, 101.263314),
        speedLimit: 90, // ถนนหลัก
        roadName: 'ถนนสุขุมวิท',
        type: CameraType.fixed,
        description: 'โตโยต้าระยอง',
      ),

      // โรงพยาบาลระยอง
      SpeedCamera(
        id: 'rayong_hospital_002',
        location: const LatLng(12.681832, 101.276501),
        speedLimit: 90, // ถนนหลัก
        roadName: 'ถนนสุขุมวิท',
        type: CameraType.fixed,
        description: 'รพ.ระยอง',
      ),

      // สรรพากรระยอง
      SpeedCamera(
        id: 'rayong_revenue_003',
        location: const LatLng(12.667918, 101.296249),
        speedLimit: 90, // ถนนหลัก
        roadName: 'ถนนสุขุมวิท',
        type: CameraType.fixed,
        description: 'สรรพากร ระยอง',
      ),

      // พีทีที LGV
      SpeedCamera(
        id: 'rayong_ptt_lgv_004',
        location: const LatLng(12.660460, 101.320307),
        speedLimit: 60, // เขตเมือง
        roadName: 'ถนนสุขุมวิท',
        type: CameraType.fixed,
        description: 'พีทีที LGV',
      ),

      // วัดตะพงนอก
      SpeedCamera(
        id: 'rayong_wat_tapong_005',
        location: const LatLng(12.648805, 101.344112),
        speedLimit: 90, // ถนนหลัก
        roadName: 'ถนนสุขุมวิท',
        type: CameraType.fixed,
        description: 'วัดตะพงนอก',
      ),

      // เจเจ เครื่องครัว
      SpeedCamera(
        id: 'rayong_jj_kitchen_006',
        location: const LatLng(12.640898, 101.399628),
        speedLimit: 120, // ทางหลวงพิเศษ
        roadName: 'ถนนสุขุมวิท',
        type: CameraType.fixed,
        description: 'เจเจ เครื่องครัว',
      ),

      // BMW
      SpeedCamera(
        id: 'rayong_bmw_007',
        location: const LatLng(12.641372, 101.405702),
        speedLimit: 120, // ทางหลวงพิเศษ
        roadName: 'ถนนสุขุมวิท',
        type: CameraType.fixed,
        description: 'BMW',
      ),

      // PT บ้านเพ
      SpeedCamera(
        id: 'rayong_pt_banphe_008',
        location: const LatLng(12.642290, 101.419683),
        speedLimit: 90, // ถนนหลัก
        roadName: 'ถนนสุขุมวิท',
        type: CameraType.fixed,
        description: 'PT บ้านเพ',
      ),

      // ตำรวจทางหลวงสวนสน
      SpeedCamera(
        id: 'rayong_police_suanson_009',
        location: const LatLng(12.661185, 101.471284),
        speedLimit: 90, // ถนนหลัก
        roadName: 'ถนนสุขุมวิท',
        type: CameraType.fixed,
        description: 'ตำรวจทางหลวงสวนสน',
      ),

      // สวนลุงสุนระยอง
      SpeedCamera(
        id: 'rayong_uncle_sun_010',
        location: const LatLng(12.678339, 101.523056),
        speedLimit: 120, // ทางหลวงพิเศษ
        roadName: 'ถนนสุขุมวิท',
        type: CameraType.fixed,
        description: 'สวนลุงสุนระยอง',
      ),

      // วัดสองสลึง
      SpeedCamera(
        id: 'rayong_wat_song_salueang_011',
        location: const LatLng(12.712509, 101.558611),
        speedLimit: 90, // ถนนหลัก
        roadName: 'ถนนสุขุมวิท',
        type: CameraType.fixed,
        description: 'วัดสองสลึง',
      ),

      // ตลาดผลไม้ป้ากัลยา
      SpeedCamera(
        id: 'rayong_fruit_market_012',
        location: const LatLng(12.716883, 101.566770),
        speedLimit: 90, // ถนนหลัก
        roadName: 'ถนนสุขุมวิท',
        type: CameraType.fixed,
        description: 'ตลาดผลไม้ป้ากัลยา',
      ),

      // บายพาสเลี่ยงแกลง
      SpeedCamera(
        id: 'rayong_bypass_klaeng_013',
        location: const LatLng(12.758812, 101.619012),
        speedLimit: 90, // ถนนหลัก
        roadName: 'ถนนบายพาสแกลง',
        type: CameraType.fixed,
        description: 'บายพาสเลี่ยงแกลง',
      ),

      // พีทีหนองน้ำขุ่น
      SpeedCamera(
        id: 'rayong_pt_nongnamkhun_014',
        location: const LatLng(12.768635, 101.631719),
        speedLimit: 120, // ทางหลวงพิเศษ
        roadName: 'ถนนสุขุมวิท',
        type: CameraType.fixed,
        description: 'พีทีหนองน้ำขุ่น',
      ),

      // ร้านทองเยาวราช
      SpeedCamera(
        id: 'rayong_gold_yaowarat_015',
        location: const LatLng(12.780082, 101.645424),
        speedLimit: 120, // ทางหลวงพิเศษ
        roadName: 'ถนนสุขุมวิท',
        type: CameraType.fixed,
        description: 'ร้านทองเยาวราช',
      ),

      // แยกสามย่าน แกลง
      SpeedCamera(
        id: 'rayong_samyan_klaeng_016',
        location: const LatLng(12.782776, 101.649986),
        speedLimit: 90, // ถนนหลัก
        roadName: 'ถนนสุขุมวิท',
        type: CameraType.redLight,
        description: 'แยกสามย่าน แกลง',
      ),

      // ปตท แกลง
      SpeedCamera(
        id: 'rayong_ptt_klaeng_017',
        location: const LatLng(12.792164, 101.645969),
        speedLimit: 90, // ถนนหลัก
        roadName: 'ถนนสุขุมวิท',
        type: CameraType.fixed,
        description: 'ปตท แกลง',
      ),

      // แยกบายพาสท่าเกวียน
      SpeedCamera(
        id: 'rayong_bypass_thakwian_018',
        location: const LatLng(12.806262, 101.638181),
        speedLimit: 90, // ถนนหลัก
        roadName: 'ถนนบายพาสแกลง',
        type: CameraType.redLight,
        description: 'แยกบายพาสท่าเกวียน',
      ),

      // อบต
      SpeedCamera(
        id: 'rayong_tambon_admin_019',
        location: const LatLng(12.825886, 101.629028),
        speedLimit: 90, // ถนนหลัก
        roadName: 'ถนนสุขุมวิท',
        type: CameraType.fixed,
        description: 'อบต',
      ),

      // บ้านลุงแว่น
      SpeedCamera(
        id: 'rayong_uncle_waen_020',
        location: const LatLng(12.829838, 101.628008),
        speedLimit: 90, // ถนนหลัก
        roadName: 'ถนนสุขุมวิท',
        type: CameraType.fixed,
        description: 'บ้านลุงแว่น',
      ),

      // === กล้องจับความเร็วระยอง ชุดที่ 2 ===

      // เซ็นทรัลระยอง
      SpeedCamera(
        id: 'rayong_central_021',
        location: const LatLng(12.697739, 101.266253),
        speedLimit: 90, // ถนนหลัก
        roadName: 'ถนนสุขุมวิท',
        type: CameraType.fixed,
        description: 'เซ็นทรัล ระยอง',
      ),

      // บายพาสยอง
      SpeedCamera(
        id: 'rayong_bypass_yong_022',
        location: const LatLng(12.707487, 101.238154),
        speedLimit: 90, // ถนนหลัก
        roadName: 'ถนนบายพาส',
        type: CameraType.fixed,
        description: 'บายพาสยอง',
      ),

      // เลี่ยงเมืองยอง
      SpeedCamera(
        id: 'rayong_bypass_city_023',
        location: const LatLng(12.704022, 101.225315),
        speedLimit: 90, // ถนนหลัก
        roadName: 'ถนนเลี่ยงเมือง',
        type: CameraType.fixed,
        description: 'เลี่ยงเมืองยอง',
      ),

      // เนินพระ
      SpeedCamera(
        id: 'rayong_noen_phra_024',
        location: const LatLng(12.691430, 101.208772),
        speedLimit: 90, // ถนนหลัก
        roadName: 'ถนนสุขุมวิท',
        type: CameraType.fixed,
        description: 'เนินพระ',
      ),

      // อภิชาติออโต้
      SpeedCamera(
        id: 'rayong_apichart_auto_025',
        location: const LatLng(12.683766, 101.218963),
        speedLimit: 90, // ถนนหลัก
        roadName: 'ถนนสุขุมวิท',
        type: CameraType.fixed,
        description: 'อภิชาติออโต้',
      ),

      // ช่างหนุ่ย
      SpeedCamera(
        id: 'rayong_chang_nui_026',
        location: const LatLng(12.683520, 101.234861),
        speedLimit: 90, // ถนนหลัก
        roadName: 'ถนนสุขุมวิท',
        type: CameraType.fixed,
        description: 'ช่างหนุ่ย',
      ),

      // โฮมโปรยอง
      SpeedCamera(
        id: 'rayong_homepro_027',
        location: const LatLng(12.683296, 101.244322),
        speedLimit: 90, // ถนนหลัก
        roadName: 'ถนนสุขุมวิท',
        type: CameraType.fixed,
        description: 'โฮมโปรยอง',
      ),

      // คลีนิกหมอเอกภพ
      SpeedCamera(
        id: 'rayong_clinic_ekkaphop_028',
        location: const LatLng(12.682428, 101.267440),
        speedLimit: 90, // ถนนหลัก
        roadName: 'ถนนสุขุมวิท',
        type: CameraType.fixed,
        description: 'คลีนิกหมอเอกภพ',
      ),

      // หลังเซนทรัล
      SpeedCamera(
        id: 'rayong_behind_central_029',
        location: const LatLng(12.691144, 101.269000),
        speedLimit: 90, // ถนนหลัก
        roadName: 'ถนนสุขุมวิท',
        type: CameraType.fixed,
        description: 'หลังเซนทรัล',
      ),

      // หลังเซน
      SpeedCamera(
        id: 'rayong_behind_zen_030',
        location: const LatLng(12.686713, 101.271745),
        speedLimit: 90, // ถนนหลัก
        roadName: 'ถนนสุขุมวิท',
        type: CameraType.fixed,
        description: 'หลังเซน',
      ),

      // บจก กิจสัมพัน
      SpeedCamera(
        id: 'rayong_kitsamphan_031',
        location: const LatLng(12.700094, 101.253565),
        speedLimit: 90, // ถนนหลัก
        roadName: 'ถนนสุขุมวิท',
        type: CameraType.fixed,
        description: 'บจก กิจสัมพัน',
      ),

      // บิ้กซียอง
      SpeedCamera(
        id: 'rayong_bigc_032',
        location: const LatLng(12.697981, 101.266695),
        speedLimit: 90, // ถนนหลัก
        roadName: 'ถนนสุขุมวิท',
        type: CameraType.fixed,
        description: 'บิ้กซียอง',
      ),

      // คอกพิทยอง
      SpeedCamera(
        id: 'rayong_coke_pit_033',
        location: const LatLng(12.696865, 101.278372),
        speedLimit: 120, // ทางหลวงพิเศษ
        roadName: 'ถนนสุขุมวิท',
        type: CameraType.fixed,
        description: 'คอกพิทยอง',
      ),

      // แพล้นปูนเชิงเนิน
      SpeedCamera(
        id: 'rayong_plan_cement_034',
        location: const LatLng(12.688094, 101.297516),
        speedLimit: 90, // ถนนหลัก
        roadName: 'ถนนสุขุมวิท',
        type: CameraType.fixed,
        description: 'แพล้นปูนเชิงเนิน',
      ),

      // ไทวัสดุ
      SpeedCamera(
        id: 'rayong_thai_material_035',
        location: const LatLng(12.672094, 101.305252),
        speedLimit: 90, // ถนนหลัก
        roadName: 'ถนนสุขุมวิท',
        type: CameraType.fixed,
        description: 'ไทวัสดุ',
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
