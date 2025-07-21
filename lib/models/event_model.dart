import 'package:flutter/material.dart';

enum EventCategory {
  checkpoint, // ด่านตรวจ 🚓
  accident, // อุบัติเหตุ 🚑
  fire, // ไฟไหม้ 🔥
  floodRain, // ฝนตก/น้ำท่วม 🌧
  tsunami, // สึนามิ 🌊
  earthquake, // แผ่นดินไหว 🌍
  animalLost, // สัตว์หาย 🐶
  question, // คำถามทั่วไป ❓
}

extension EventCategoryExtension on EventCategory {
  String get label {
    switch (this) {
      case EventCategory.checkpoint:
        return "ด่านตรวจ";
      case EventCategory.accident:
        return "อุบัติเหตุ";
      case EventCategory.fire:
        return "ไฟไหม้";
      case EventCategory.floodRain:
        return "ฝนตก/น้ำท่วม";
      case EventCategory.tsunami:
        return "สึนามิ";
      case EventCategory.earthquake:
        return "แผ่นดินไหว";
      case EventCategory.animalLost:
        return "สัตว์หาย";
      case EventCategory.question:
        return "คำถามทั่วไป";
    }
  }

  String get shortLabel {
    switch (this) {
      case EventCategory.checkpoint:
        return "Checkpoints";
      case EventCategory.accident:
        return "Accidents";
      case EventCategory.fire:
        return "Fire";
      case EventCategory.floodRain:
        return "Hazards";
      case EventCategory.tsunami:
        return "Tsunami";
      case EventCategory.earthquake:
        return "Earthquake";
      case EventCategory.animalLost:
        return "Lost";
      case EventCategory.question:
        return "Question";
    }
  }

  String get emoji {
    switch (this) {
      case EventCategory.checkpoint:
        return "🚓";
      case EventCategory.accident:
        return "🚑";
      case EventCategory.fire:
        return "🔥";
      case EventCategory.floodRain:
        return "🌧";
      case EventCategory.tsunami:
        return "🌊";
      case EventCategory.earthquake:
        return "🌍";
      case EventCategory.animalLost:
        return "🐶";
      case EventCategory.question:
        return "❓";
    }
  }

  Color get color {
    switch (this) {
      case EventCategory.checkpoint:
        return const Color(0xFF9C3A3A); // สีแดงอมน้ำตาลตามรูป
      case EventCategory.accident:
        return const Color(0xFFFDC621); // เหลืองเหมือน AppBar
      case EventCategory.fire:
        return const Color(0xFFF4511E); // Deep Orange - สีส้มอมแดง ร้อนแรง
      case EventCategory.floodRain:
        return const Color(
            0xFF3F51B5); // Slate Blue - น้ำเงินอมม่วง เย็นและฝนตก
      case EventCategory.tsunami:
        return const Color(0xFF0097A7); // Teal - ฟ้าอมเขียว สื่อถึงคลื่น/ทะเล
      case EventCategory.earthquake:
        return const Color(
            0xFF607D8B); // Blue Grey - สีเทาน้ำเงิน สื่อถึงหิน/แผ่นดิน
      case EventCategory.animalLost:
        return const Color(0xFF689F38); // Lime Green - เขียวให้ความรู้สึกหวังดี
      case EventCategory.question:
        return const Color(0xFF2196F3); // สีน้ำเงินสดใส - เป็นมิตรและน่าสนใจ
    }
  }

  String get stringValue {
    switch (this) {
      case EventCategory.checkpoint:
        return "checkpoint";
      case EventCategory.accident:
        return "accident";
      case EventCategory.fire:
        return "fire";
      case EventCategory.floodRain:
        return "floodRain";
      case EventCategory.tsunami:
        return "tsunami";
      case EventCategory.earthquake:
        return "earthquake";
      case EventCategory.animalLost:
        return "animalLost";
      case EventCategory.question:
        return "question";
    }
  }

  static EventCategory fromString(String value) {
    switch (value) {
      case "checkpoint":
        return EventCategory.checkpoint;
      case "accident":
        return EventCategory.accident;
      case "fire":
        return EventCategory.fire;
      case "floodRain":
        return EventCategory.floodRain;
      case "tsunami":
        return EventCategory.tsunami;
      case "earthquake":
        return EventCategory.earthquake;
      case "animalLost":
        return EventCategory.animalLost;
      case "question":
        return EventCategory.question;
      default:
        return EventCategory.checkpoint; // default fallback
    }
  }
}

class EventModel {
  final String id;
  final String title;
  final String description;
  final EventCategory category; // เปลี่ยนจาก String เป็น EventCategory
  final double latitude;
  final double longitude;
  final DateTime createdAt;
  final String? imageUrl;
  final String? reporterName;
  final String? reporterPhone;
  final bool isVerified;
  final int verificationCount;
  final int falseReportCount;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    this.imageUrl,
    this.reporterName,
    this.reporterPhone,
    this.isVerified = false,
    this.verificationCount = 0,
    this.falseReportCount = 0,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category:
          EventCategoryExtension.fromString(json['category'] ?? 'checkpoint'),
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] ?? 0),
      imageUrl: json['imageUrl'],
      reporterName: json['reporterName'],
      reporterPhone: json['reporterPhone'],
      isVerified: json['isVerified'] ?? false,
      verificationCount: json['verificationCount'] ?? 0,
      falseReportCount: json['falseReportCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category.stringValue, // แปลงเป็น String เพื่อเก็บใน Firebase
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'imageUrl': imageUrl,
      'reporterName': reporterName,
      'reporterPhone': reporterPhone,
      'isVerified': isVerified,
      'verificationCount': verificationCount,
      'falseReportCount': falseReportCount,
    };
  }

  EventModel copyWith({
    String? id,
    String? title,
    String? description,
    EventCategory? category,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    String? imageUrl,
    String? reporterName,
    String? reporterPhone,
    bool? isVerified,
    int? verificationCount,
    int? falseReportCount,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      imageUrl: imageUrl ?? this.imageUrl,
      reporterName: reporterName ?? this.reporterName,
      reporterPhone: reporterPhone ?? this.reporterPhone,
      isVerified: isVerified ?? this.isVerified,
      verificationCount: verificationCount ?? this.verificationCount,
      falseReportCount: falseReportCount ?? this.falseReportCount,
    );
  }

  @override
  String toString() {
    return 'EventModel(id: $id, title: $title, category: ${category.label}, latitude: $latitude, longitude: $longitude)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
