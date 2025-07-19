import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class GeocodingService {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org';

  /// ค้นหาข้อมูลที่อยู่จากพิกัด (Reverse Geocoding)
  static Future<LocationInfo?> getLocationInfo(LatLng position) async {
    try {
      final url = Uri.parse(
          '$_baseUrl/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&addressdetails=1&zoom=18&accept-language=th,en');

      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'CheckDarn App 1.0',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return LocationInfo.fromJson(data);
      }
    } catch (e) {
      print('Error in reverse geocoding: $e');
    }
    return null;
  }
}

class LocationInfo {
  final String? displayName;
  final String? province; // จังหวัด
  final String? district; // อำเภอ/เขต
  final String? subDistrict; // ตำบล/แขวง
  final String? village; // หมู่บ้าน
  final String? road; // ถนน
  final String? houseNumber; // เลขที่
  final String? postcode; // รหัสไปรษณีย์
  final String? country;
  final String? countryCode;

  LocationInfo({
    this.displayName,
    this.province,
    this.district,
    this.subDistrict,
    this.village,
    this.road,
    this.houseNumber,
    this.postcode,
    this.country,
    this.countryCode,
  });

  factory LocationInfo.fromJson(Map<String, dynamic> json) {
    final address = json['address'] as Map<String, dynamic>? ?? {};

    return LocationInfo(
      displayName: json['display_name'],
      // ลองหาจังหวัดจากหลายฟิลด์
      province:
          address['state'] ?? address['province'] ?? address['state_district'],
      // ลองหาอำเภอจากหลายฟิลด์
      district: address['county'] ??
          address['district'] ??
          address['city_district'] ??
          address['municipality'] ??
          address['city'],
      // ลองหาตำบลจากหลายฟิลด์ (เพิ่มเติม)
      subDistrict: address['suburb'] ??
          address['subdistrict'] ??
          address['village'] ??
          address['neighbourhood'] ??
          address['quarter'] ??
          address['residential'],
      village: address['hamlet'] ?? address['village'],
      road: address['road'] ?? address['street'],
      houseNumber: address['house_number'],
      postcode: address['postcode'],
      country: address['country'],
      countryCode: address['country_code'],
    );
  }

  /// สร้างข้อความแสดงที่อยู่แบบสั้น
  String get shortAddress {
    List<String> parts = [];

    // ตรวจสอบว่าเป็นกรุงเทพฯ หรือไม่ (ใช้ระบบแขวง/เขต)
    final isBangkok = province?.contains('กรุงเทพ') == true ||
        district?.contains('เขต') == true;

    if (isBangkok) {
      // กรุงเทพฯ: แขวง/เขต/กรุงเทพ
      if (subDistrict != null) parts.add('แขวง$subDistrict');
      if (district != null) parts.add(district!);
      if (province != null) parts.add(province!);
    } else {
      // จังหวัดอื่น: แสดงเฉพาะข้อมูลที่มี (ไม่ใส่ตัวย่อ)
      if (subDistrict != null) parts.add(subDistrict!);
      if (district != null) parts.add(district!);
      if (province != null) parts.add(province!);
    }

    return parts.isNotEmpty ? parts.join(' ') : 'ไม่พบข้อมูลที่อยู่';
  }

  /// สร้างข้อความแสดงที่อยู่แบบยาว
  String get fullAddress {
    List<String> parts = [];

    if (road != null) parts.add(road!);

    // ตรวจสอบว่าเป็นกรุงเทพฯ หรือไม่
    final isBangkok = province?.contains('กรุงเทพ') == true ||
        district?.contains('เขต') == true;

    if (isBangkok) {
      // กรุงเทพฯ: แขวง/เขต/กรุงเทพ
      if (subDistrict != null) parts.add('แขวง$subDistrict');
      if (district != null) parts.add(district!);
      if (province != null) parts.add(province!);
    } else {
      // จังหวัดอื่น: แสดงเฉพาะข้อมูลที่มี (ไม่ใส่คำนำหน้า)
      if (subDistrict != null) parts.add(subDistrict!);
      if (district != null) parts.add(district!);
      if (province != null) parts.add(province!);
    }

    if (postcode != null) parts.add(postcode!);

    return parts.isNotEmpty
        ? parts.join(' ')
        : displayName ?? 'ไม่พบข้อมูลที่อยู่';
  }

  @override
  String toString() => shortAddress;
}
