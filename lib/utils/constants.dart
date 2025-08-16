import 'package:flutter/material.dart';

class AppColors {
  // Primary colors - CheckDarn ใหม่
  static const Color primary = Color(0xFF2979FF); // ฟ้า - ปุ่มหลัก/ส่ง
  static const Color primaryDark = Color(0xFF1976D2);
  static const Color primaryLight = Color(0xFFBBDEFB);

  // Accent colors
  static const Color accent = Color(0xFFFF9800);
  static const Color accentDark = Color(0xFFF57C00);

  // Text colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);

  // Background colors
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);

  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // Category colors - CheckDarn ใหม่
  static const Color categoryCheckpoint = Color(0xFFE53935); // แดงสด - ด่านตรวจ
  static const Color categoryAccident = Color(0xFFFB8C00); // ส้ม - อุบัติเหตุ
  static const Color categoryFire = Color(0xFFFF5722); // แดงส้ม - ไฟไหม้
  static const Color categoryDisaster =
      Color(0xFF1E88E5); // น้ำเงิน - ภัยพิบัติ
  static const Color categoryLostPet =
      Color(0xFF43A047); // เขียว - สัตว์เลี้ยงหาย
  static const Color categoryQuestion = Color(0xFF9C27B0); // ม่วง - คำถามทั่วไป

  // UI Element colors
  static const Color buttonSecondary =
      Color(0xFFEEEEEE); // เทาอ่อน - ปุ่มเพิ่มรูป
  static const Color border = Color(0xFFE0E0E0); // เทา - ขอบกรอบ
}

class AppConstants {
  // UI Constants
  static const double borderRadius = 12.0;
  static const double padding = 16.0;
  static const double margin = 8.0;

  // Map Constants
  static const double defaultZoom = 15.0;
  static const double maxRadius = 5000.0; // 5km in meters
  static const double minRadius = 100.0; // 100m in meters

  // Animation durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // API Constants
  static const int timeoutDuration = 30; // seconds
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
}

class EventCategory {
  // หมวดหมู่ใหม่สำหรับ CheckDarn - 8 หมวดหมู่ (ตาม event model)
  static const String checkpoint = 'checkpoint'; // ด่านตรวจ 🚓
  static const String accident = 'accident'; // อุบัติเหตุ 🚑
  static const String fire = 'fire'; // ไฟไหม้ 🔥
  static const String floodRain = 'floodRain'; // ฝนตก/น้ำท่วม 🌧
  static const String tsunami = 'tsunami'; // สึนามิ 🌊
  static const String earthquake = 'earthquake'; // แผ่นดินไหว 🌍
  static const String animalLost = 'animalLost'; // สัตว์เลี้ยงหาย 🐶
  static const String question = 'question'; // คำถามทั่วไป ❓

  static const Map<String, String> categoryNames = {
    checkpoint: 'ด่านตรวจ',
    accident: 'อุบัติเหตุ',
    fire: 'ไฟไหม้',
    floodRain: 'ฝนตก/น้ำท่วม',
    tsunami: 'สึนามิ',
    earthquake: 'แผ่นดินไหว',
    animalLost: 'สัตว์เลี้ยงหาย',
    question: 'คำถามทั่วไป',
  };

  static const Map<String, Color> categoryColors = {
    checkpoint: AppColors.categoryCheckpoint, // สีแดง
    accident: AppColors.categoryAccident, // สีส้ม
    fire: AppColors.categoryFire, // สีแดงส้ม
    floodRain: AppColors.categoryDisaster, // สีน้ำเงิน
    tsunami: Colors.cyan, // สีฟ้า
    earthquake: Colors.amber, // สีเหลือง
    animalLost: AppColors.categoryLostPet, // สีเขียว
    question: AppColors.categoryQuestion, // สีม่วง
  };

  static const Map<String, IconData> categoryIcons = {
    checkpoint: Icons.local_police, // 🚓 ด่านตรวจ
    accident: Icons.medical_services, // 🚑 อุบัติเหตุ
    fire: Icons.local_fire_department, // 🔥 ไฟไหม้
    floodRain: Icons.cloud_circle, // 🌧 ฝนตก/น้ำท่วม
    tsunami: Icons.waves, // 🌊 สึนามิ
    earthquake: Icons.public, // 🌍 แผ่นดินไหว
    animalLost: Icons.pets, // 🐶 สัตว์เลี้ยงหาย
    question: Icons.help_outline, // ❓ คำถามทั่วไป
  };

  static List<String> get allCategories => [
        checkpoint,
        accident,
        fire,
        floodRain,
        tsunami,
        earthquake,
        animalLost,
        question,
      ];

  // สร้าง eventCategories สำหรับ dropdown
  static List<CategoryItem> get eventCategories => [
        CategoryItem(
          id: 1,
          name: categoryNames[checkpoint]!,
          color: categoryColors[checkpoint]!,
          icon: categoryIcons[checkpoint]!,
        ),
        CategoryItem(
          id: 2,
          name: categoryNames[accident]!,
          color: categoryColors[accident]!,
          icon: categoryIcons[accident]!,
        ),
        CategoryItem(
          id: 3,
          name: categoryNames[fire]!,
          color: categoryColors[fire]!,
          icon: categoryIcons[fire]!,
        ),
        CategoryItem(
          id: 4,
          name: categoryNames[floodRain]!,
          color: categoryColors[floodRain]!,
          icon: categoryIcons[floodRain]!,
        ),
        CategoryItem(
          id: 5,
          name: categoryNames[tsunami]!,
          color: categoryColors[tsunami]!,
          icon: categoryIcons[tsunami]!,
        ),
        CategoryItem(
          id: 6,
          name: categoryNames[earthquake]!,
          color: categoryColors[earthquake]!,
          icon: categoryIcons[earthquake]!,
        ),
        CategoryItem(
          id: 7,
          name: categoryNames[animalLost]!,
          color: categoryColors[animalLost]!,
          icon: categoryIcons[animalLost]!,
        ),
        CategoryItem(
          id: 8,
          name: categoryNames[question]!,
          color: categoryColors[question]!,
          icon: categoryIcons[question]!,
        ),
      ];
}

class CategoryItem {
  final int id;
  final String name;
  final Color color;
  final IconData icon;

  const CategoryItem({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
  });
}
