import 'package:latlong2/latlong.dart';

class SpeedCamera {
  final String id;
  final LatLng location;
  final int speedLimit; // ขีดจำกัดความเร็ว (km/h)
  final String roadName; // ชื่อถนน
  final CameraType type; // ประเภทกล้อง
  final bool isActive; // สถานะทำงาน
  final String? description; // รายละเอียดเพิ่มเติม

  const SpeedCamera({
    required this.id,
    required this.location,
    required this.speedLimit,
    required this.roadName,
    required this.type,
    this.isActive = true,
    this.description,
  });

  factory SpeedCamera.fromJson(Map<String, dynamic> json) {
    LatLng location;

    // รองรับทั้ง format เก่า (latitude/longitude แยก) และ format ใหม่ (location object)
    if (json['location'] != null) {
      // Format ใหม่: มี location object (GeoPoint จาก Firestore)
      final locationData = json['location'];
      if (locationData is Map<String, dynamic>) {
        // Location เป็น Map (จาก GeoPoint.toJson())
        location = LatLng(
          locationData['latitude'] as double,
          locationData['longitude'] as double,
        );
      } else {
        // Location เป็น object อื่น - fallback ไป latitude/longitude
        location = LatLng(
          json['latitude'] as double,
          json['longitude'] as double,
        );
      }
    } else {
      // Format เก่า: latitude/longitude แยกกัน
      location = LatLng(
        json['latitude'] as double,
        json['longitude'] as double,
      );
    }

    return SpeedCamera(
      id: json['id'] as String,
      location: location,
      speedLimit: json['speedLimit'] as int,
      roadName: json['roadName'] as String,
      type: CameraType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => CameraType.fixed,
      ),
      isActive: json['isActive'] as bool? ?? true,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'location': {
        'latitude': location.latitude,
        'longitude': location.longitude,
      },
      // Keep backward compatibility
      'latitude': location.latitude,
      'longitude': location.longitude,
      'speedLimit': speedLimit,
      'roadName': roadName,
      'type': type.name,
      'isActive': isActive,
      'description': description,
    };
  }

  @override
  String toString() {
    return 'SpeedCamera(id: $id, location: $location, speedLimit: $speedLimit, roadName: $roadName)';
  }
}

enum CameraType {
  fixed, // กล้องติดตั้งถาวร
  mobile, // กล้องเคลื่อนที่
  average, // กล้องเฉลี่ยความเร็ว
  redLight, // กล้องไฟแดง + ความเร็ว
}

extension CameraTypeExtension on CameraType {
  String get displayName {
    switch (this) {
      case CameraType.fixed:
        return 'กล้องติดตั้งถาวร';
      case CameraType.mobile:
        return 'กล้องเคลื่อนที่';
      case CameraType.average:
        return 'กล้องเฉลี่ยความเร็ว';
      case CameraType.redLight:
        return 'กล้องไฟแดง';
    }
  }

  String get emoji {
    switch (this) {
      case CameraType.fixed:
        return '📷';
      case CameraType.mobile:
        return '🚔';
      case CameraType.average:
        return '📊';
      case CameraType.redLight:
        return '🚦';
    }
  }
}
