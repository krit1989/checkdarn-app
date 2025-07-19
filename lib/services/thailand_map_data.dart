import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class ThailandMapData {
  // ข้อมูลพิกัดจังหวัดไทยทั้ง 77 จังหวัด
  static const Map<String, LatLng> provinces = {
    'กรุงเทพมหานคร': LatLng(13.7563, 100.5018),
    'นนทบุรี': LatLng(13.8621, 100.5144),
    'ปทุมธานี': LatLng(14.0208, 100.5250),
    'สมุทรปราการ': LatLng(13.5990, 100.5998),
    'นครปฐม': LatLng(13.8199, 100.0620),
    'สมุทรสาคร': LatLng(13.5475, 100.2740),
    'สมุทรสงคราม': LatLng(13.4140, 100.0020),
    'เชียงใหม่': LatLng(18.7883, 98.9853),
    'เชียงราย': LatLng(19.9105, 99.8406),
    'ลำพูน': LatLng(18.5741, 99.0210),
    'ลำปาง': LatLng(18.2932, 99.4240),
    'อุตรดิตถ์': LatLng(17.6200, 100.0992),
    'แพร่': LatLng(18.1440, 100.1400),
    'น่าน': LatLng(18.7756, 100.7730),
    'พะเยา': LatLng(19.1926, 99.8964),
    'แม่ฮ่องสอน': LatLng(19.3011, 97.9658),
    'นครราชสีมา': LatLng(14.9799, 102.0977),
    'บุรีรัมย์': LatLng(14.9930, 103.1029),
    'สุรินทร์': LatLng(14.8825, 103.4937),
    'ศีสะเกษ': LatLng(15.1186, 104.3228),
    'อุบลราชธานี': LatLng(15.2286, 104.8558),
    'ยโสธร': LatLng(15.7919, 104.1452),
    'ชัยภูมิ': LatLng(15.8070, 102.0309),
    'อำนาจเจริญ': LatLng(15.8650, 104.6260),
    'หนองบัวลำภู': LatLng(17.2042, 102.4280),
    'ขอนแก่น': LatLng(16.4419, 102.8359),
    'อุดรธานี': LatLng(17.4138, 102.7873),
    'เลย': LatLng(17.4860, 101.7223),
    'หนองคาย': LatLng(17.8782, 102.7412),
    'มหาสารคาม': LatLng(16.1849, 103.3020),
    'ร้อยเอ็ด': LatLng(16.0544, 103.6530),
    'กาฬสินธุ์': LatLng(16.4322, 103.5056),
    'สกลนคร': LatLng(17.1557, 104.1357),
    'นครพนม': LatLng(17.4093, 104.7686),
    'มุกดาหาร': LatLng(16.5466, 104.7231),
    'ตาก': LatLng(16.8840, 99.1256),
    'สุโขทัย': LatLng(17.0078, 99.8236),
    'พิษณุโลก': LatLng(16.8211, 100.2659),
    'กำแพงเพชร': LatLng(16.4827, 99.5223),
    'พิจิตร': LatLng(16.4373, 100.3488),
    'เพชรบูรณ์': LatLng(16.4190, 101.1609),
    'อุทัยธานี': LatLng(15.3793, 100.0244),
    'ชัยนาท': LatLng(15.1858, 100.1250),
    'สิงห์บุรี': LatLng(14.8936, 100.3967),
    'อ่างทอง': LatLng(14.5896, 100.4552),
    'พระนครศรีอยุธยา': LatLng(14.3692, 100.5877),
    'ลพบุรี': LatLng(14.7995, 100.6534),
    'สระบุรี': LatLng(14.5289, 100.9100),
    'กาญจนบุรี': LatLng(14.0227, 99.5328),
    'สุพรรณบุรี': LatLng(14.4745, 100.1212),
    'ราชบุรี': LatLng(13.5282, 99.8097),
    'เพชรบุรี': LatLng(13.1110, 99.9398),
    'ประจวบคีรีขันธ์': LatLng(11.8124, 99.7974),
    'ชุมพร': LatLng(10.4930, 99.1797),
    'ระนอง': LatLng(9.9656, 98.6348),
    'สุราษฎร์ธานี': LatLng(9.1382, 99.3215),
    'พังงา': LatLng(8.4504, 98.5348),
    'ภูเก็ต': LatLng(7.8804, 98.3923),
    'กระบี่': LatLng(8.0863, 98.9063),
    'นครศรีธรรมราช': LatLng(8.4304, 99.9631),
    'ตรัง': LatLng(7.5563, 99.6114),
    'พัทลุง': LatLng(7.6166, 100.0741),
    'สตูล': LatLng(6.6238, 100.0668),
    'สงขลา': LatLng(7.1756, 100.6135),
    'ปัตตานี': LatLng(6.8681, 101.2501),
    'ยะลา': LatLng(6.5411, 101.2800),
    'นราธิวาส': LatLng(6.4254, 101.8253),
  };

  // ขอบเขตประเทศไทย
  static const LatLng northEast = LatLng(20.4638, 105.6390);
  static const LatLng southWest = LatLng(5.6127, 97.3438);
  static const LatLng center = LatLng(13.7563, 100.5018); // กรุงเทพ

  // สีสำหรับจังหวัดต่างๆ
  static const Color provinceColor = Color(0xFF4673E5);
  static const Color highlightColor = Color(0xFFFF6B6B);
  static const Color borderColor = Color(0xFF2C3E50);

  // ค้นหาจังหวัดใกล้เคียง
  static List<MapEntry<String, LatLng>> findNearbyProvinces(
      LatLng center, double radiusKm) {
    final Distance distance = Distance();
    return provinces.entries
        .where((entry) =>
            distance.as(LengthUnit.Kilometer, center, entry.value) <= radiusKm)
        .toList()
      ..sort((a, b) => distance
          .as(LengthUnit.Kilometer, center, a.value)
          .compareTo(distance.as(LengthUnit.Kilometer, center, b.value)));
  }

  // หาจังหวัดที่ใกล้ที่สุด
  static MapEntry<String, LatLng>? findNearestProvince(LatLng target) {
    if (provinces.isEmpty) return null;

    final Distance distance = Distance();
    MapEntry<String, LatLng>? nearest;
    double minDistance = double.infinity;

    for (final entry in provinces.entries) {
      final dist = distance.as(LengthUnit.Kilometer, target, entry.value);
      if (dist < minDistance) {
        minDistance = dist;
        nearest = entry;
      }
    }

    return nearest;
  }
}
