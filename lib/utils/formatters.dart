import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DateTimeFormatters {
  // ⭐ แปลง Timestamp เป็นเวลาท้องถิ่น + Time Zone support (null-safe)
  static String formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'ไม่มีข้อมูลเวลา';

    final now = DateTime.now().toLocal(); // ใช้เวลาท้องถิ่น
    final date = timestamp.toDate().toLocal(); // แปลงเป็นเวลาท้องถิ่น
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} วันที่แล้ว';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ชั่วโมงที่แล้ว';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} นาทีที่แล้ว';
    } else {
      return 'เมื่อสักครู่';
    }
  }

  // ⭐ แสดงวันที่เวลาแบบเวลาท้องถิ่น (null-safe)
  static String formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'ไม่มีข้อมูลเวลา';
    return DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate().toLocal());
  }

  // ⭐ แสดงวันที่เวลาแบบละเอียด พร้อมเวลาท้องถิ่น (null-safe)
  static String formatDateDetailed(Timestamp? timestamp) {
    if (timestamp == null) return 'ไม่มีข้อมูลเวลา';
    return DateFormat('dd MMMM yyyy เวลา HH:mm น.', 'th')
        .format(timestamp.toDate().toLocal());
  }

  // ⭐ ฟังก์ชันใหม่: จัดการ Timestamp หลายรูปแบบ พร้อม null-safety
  static DateTime? parseTimestamp(dynamic timestampData) {
    if (timestampData == null) {
      print('Debug: Timestamp data is null');
      return null;
    }

    try {
      if (timestampData is Timestamp) {
        return timestampData.toDate().toLocal();
      } else if (timestampData is String) {
        if (timestampData.isEmpty) {
          print('Debug: Timestamp string is empty');
          return null;
        }
        return DateTime.parse(timestampData).toLocal();
      } else if (timestampData is int) {
        if (timestampData <= 0) {
          print('Debug: Invalid timestamp integer: $timestampData');
          return null;
        }
        // Unix timestamp (milliseconds)
        return DateTime.fromMillisecondsSinceEpoch(timestampData).toLocal();
      } else if (timestampData is DateTime) {
        return timestampData.toLocal();
      } else {
        print(
            'Debug: Unsupported timestamp type: ${timestampData.runtimeType}');
        return null;
      }
    } catch (e) {
      print(
          'Error parsing timestamp: $timestampData (type: ${timestampData.runtimeType}), error: $e');
      return null;
    }
  }

  // ⭐ ฟังก์ชันใหม่: แปลง Timestamp แบบปลอดภัย พร้อม fallback
  static DateTime parseTimestampSafe(dynamic timestampData,
      {DateTime? fallback}) {
    final parsed = parseTimestamp(timestampData);
    return parsed ?? fallback ?? DateTime.now().toLocal();
  }

  // ⭐ ฟังก์ชันใหม่: แสดงเวลาจาก DateTime (null-safe)
  static String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'ไม่มีข้อมูลเวลา';
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime.toLocal());
  }

  // ⭐ ฟังก์ชันใหม่: คำนวณเวลาผ่านมา จาก DateTime (null-safe)
  static String formatTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return 'ไม่มีข้อมูลเวลา';

    final now = DateTime.now().toLocal();
    final date = dateTime.toLocal();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} วันที่แล้ว';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ชั่วโมงที่แล้ว';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} นาทีที่แล้ว';
    } else {
      return 'เมื่อสักครู่';
    }
  }

  // ⭐ ฟังก์ชันใหม่: แปลงข้อมูล timestamp โดยตรงเป็น string (null-safe)
  static String formatTimestampSafe(dynamic timestampData,
      {String fallbackText = 'ไม่มีข้อมูลเวลา'}) {
    final dateTime = parseTimestamp(timestampData);
    return dateTime != null ? formatTimeAgo(dateTime) : fallbackText;
  }

  // ⭐ ฟังก์ชันใหม่: แปลงข้อมูล timestamp เป็นวันที่เวลา (null-safe)
  static String formatTimestampToDateTime(dynamic timestampData,
      {String fallbackText = 'ไม่มีข้อมูลเวลา'}) {
    final dateTime = parseTimestamp(timestampData);
    return dateTime != null ? formatDateTime(dateTime) : fallbackText;
  }

  // ⭐ ฟังก์ชันใหม่: สำหรับทดสอบ Time Zone
  static String getTimeZoneInfo() {
    final now = DateTime.now();
    final local = now.toLocal();
    final utc = now.toUtc();

    return 'Local: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(local)}\n'
        'UTC: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(utc)}\n'
        'Offset: ${local.timeZoneOffset}';
  }
}

class CategoryHelpers {
  static Color getCategoryColor(String category) {
    switch (category) {
      case 'animalLost':
        return Colors.red;
      case 'incident':
        return Colors.orange;
      case 'checkpoint':
        return Colors.blue;
      case 'other':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  static String getCategoryName(String category) {
    switch (category) {
      case 'animalLost':
        return 'สัตว์หาย';
      case 'incident':
        return 'เหตุการณ์';
      case 'checkpoint':
        return 'ด่าน';
      case 'other':
        return 'อื่นๆ';
      default:
        return 'ไม่ระบุ';
    }
  }

  static String getCategoryKey(dynamic category) {
    if (category is String) {
      return category; // หากเป็น string อยู่แล้ว
    }

    // หากเป็น EventCategory enum
    final categoryString = category.toString();
    if (categoryString.contains('EventCategory.')) {
      return categoryString.split('.').last;
    }

    return 'other'; // fallback
  }

  static IconData getCategoryIcon(String category) {
    switch (category) {
      case 'animalLost':
        return Icons.pets;
      case 'incident':
        return Icons.warning;
      case 'checkpoint':
        return Icons.security;
      case 'other':
        return Icons.info;
      default:
        return Icons.help_outline;
    }
  }
}

class ImageHelpers {
  static Widget buildImageLoadingIndicator(
    BuildContext context,
    ImageChunkEvent? loadingProgress,
    Color? color,
  ) {
    if (loadingProgress == null) return const SizedBox.shrink();

    return Center(
      child: CircularProgressIndicator(
        value: loadingProgress.expectedTotalBytes != null
            ? loadingProgress.cumulativeBytesLoaded /
                loadingProgress.expectedTotalBytes!
            : null,
        color: color ?? Theme.of(context).primaryColor,
        strokeWidth: 2,
      ),
    );
  }

  static Widget buildImageErrorWidget(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported,
              color: Colors.grey,
              size: 32,
            ),
            SizedBox(height: 8),
            Text(
              'ไม่สามารถโหลดรูปภาพได้',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
