import 'package:flutter/material.dart';

class CategoryHelpers {
  static Color getCategoryColor(String categoryKey) {
    switch (categoryKey) {
      case 'checkpoint':
        return const Color(0xFF4CAF50); // สีเขียว
      case 'accident':
        return const Color(0xFFFF5722); // สีแดงส้ม
      case 'floodRain':
        return const Color(0xFF2196F3); // สีฟ้า
      case 'tsunami':
        return const Color(0xFF00BCD4); // สีฟ้าอ่อน
      case 'earthquake':
        return const Color(0xFF795548); // สีน้ำตาล
      case 'animalLost':
        return const Color(0xFFFF9800); // สีส้ม
      default:
        return const Color(0xFF9E9E9E); // สีเทา
    }
  }

  static IconData getCategoryIcon(String categoryKey) {
    switch (categoryKey) {
      case 'checkpoint':
        return Icons.local_police;
      case 'accident':
        return Icons.car_crash;
      case 'floodRain':
        return Icons.water_drop;
      case 'tsunami':
        return Icons.waves;
      case 'earthquake':
        return Icons.terrain;
      case 'animalLost':
        return Icons.pets;
      default:
        return Icons.help_outline;
    }
  }

  static String getCategoryName(String categoryKey) {
    switch (categoryKey) {
      case 'checkpoint':
        return 'ด่านตรวจ';
      case 'accident':
        return 'อุบัติเหตุ';
      case 'floodRain':
        return 'ฝน/น้ำท่วม';
      case 'tsunami':
        return 'สึนามิ';
      case 'earthquake':
        return 'แผ่นดินไหว';
      case 'animalLost':
        return 'สัตว์หาย';
      default:
        return 'อื่นๆ';
    }
  }
}
