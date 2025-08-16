import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class LocationInfo {
  final String? displayName;
  final String? province;
  final String? district;
  final String? subDistrict;
  final String? village;
  final String? road;
  final String? houseNumber;
  final String? postcode;
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

  @override
  String toString() {
    return 'LocationInfo{displayName: $displayName, province: $province, district: $district, subDistrict: $subDistrict, road: $road}';
  }
}

class GeocodingService {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org';

  /// ค้นหาข้อมูลที่อยู่จากพิกัด (Reverse Geocoding)
  static Future<LocationInfo?> getLocationInfo(LatLng position) async {
    try {
      final url = Uri.parse(
          '$_baseUrl/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&addressdetails=1&zoom=18&accept-language=th,en');

      print('🌐 Calling URL: $url');

      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'CheckDarn App 1.0',
        },
      );

      print('📡 Response status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final locationInfo = LocationInfo.fromJson(data);
        print('🏠 Parsed LocationInfo: $locationInfo');
        return locationInfo;
      }
    } catch (e) {
      print('❌ Error in reverse geocoding: $e');
    }
    return null;
  }
}

void main() async {
  print('🔍 Testing geocoding service...');

  // ทดสอบกับพิกัดกรุงเทพฯ (ควรได้กรุงเทพฯ)
  print('\n📍 Testing Bangkok coordinates:');
  final bangkokResult =
      await GeocodingService.getLocationInfo(const LatLng(13.7563, 100.5018));
  print('Bangkok result: $bangkokResult');

  // ทดสอบกับพิกัดจังหวัดชลบุรี (อำเภอพานทอง) - จากข้อมูลที่พบในโค้ด
  print('\n📍 Testing Chonburi (Phan Thong) coordinates:');
  final chonburiResult =
      await GeocodingService.getLocationInfo(const LatLng(13.0827, 101.0028));
  print('Chonburi result: $chonburiResult');

  // ทดสอบกับพิกัดจังหวัดเชียงใหม่ (ควรได้เชียงใหม่)
  print('\n📍 Testing Chiang Mai coordinates:');
  final chiangMaiResult =
      await GeocodingService.getLocationInfo(const LatLng(18.7883, 98.9853));
  print('Chiang Mai result: $chiangMaiResult');

  // ทดสอบกับพิกัดภูเก็ต (ควรได้ภูเก็ต)
  print('\n📍 Testing Phuket coordinates:');
  final phuketResult =
      await GeocodingService.getLocationInfo(const LatLng(7.8804, 98.3923));
  print('Phuket result: $phuketResult');
}
