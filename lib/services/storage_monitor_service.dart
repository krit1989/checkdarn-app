import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'budget_monitoring_service.dart';

/// Service สำหรับตรวจสอบการใช้งาน Firebase Storage
/// สำหรับ Firebase Blaze Plan (Pay-as-you-go) พร้อม Budget Monitoring
class StorageMonitorService {
  static const double maxStorageGB =
      10.0; // Blaze Plan เริ่มต้น 10GB สำหรับการใช้งาน
  static const double warningThresholdPercent = 80.0; // แจ้งเตือนที่ 80%
  static const double emergencyThresholdPercent = 95.0; // โหมดฉุกเฉินที่ 95%

  /// ตรวจสอบการใช้งาน Storage ปัจจุบัน (รวม Budget Monitoring)
  static Future<Map<String, dynamic>> getStorageUsage() async {
    try {
      // ตรวจสอบ Budget status ก่อน
      final budgetStatus =
          await BudgetMonitoringService.getCurrentBudgetStatus();
      final canUpload = budgetStatus['can_upload'] ?? true;
      final budgetCompressionMode =
          budgetStatus['compression_mode'] ?? 'normal';

      // นับจำนวนไฟล์และขนาดรวม (เป็นการประมาณ)
      final cameraReports = await FirebaseFirestore.instance
          .collection('camera_reports')
          .where('imageUrl', isNotEqualTo: null)
          .get();

      // ประมาณขนาดโดยใช้จำนวนรูป × ขนาดเฉลี่ย
      final totalImages = cameraReports.docs.length;
      final estimatedSizeBytes =
          totalImages * 200 * 1024; // คืนเป็น 200KB ต่อรูป (Blaze Plan)
      final estimatedSizeGB = estimatedSizeBytes / (1024 * 1024 * 1024);

      final usagePercent = (estimatedSizeGB / maxStorageGB) * 100;
      final remainingGB = maxStorageGB - estimatedSizeGB;

      // คำนวณการใช้งานรายวัน (ย้อนหลัง 7 วัน)
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      final recentReports = await FirebaseFirestore.instance
          .collection('camera_reports')
          .where('timestamp', isGreaterThan: Timestamp.fromDate(sevenDaysAgo))
          .where('imageUrl', isNotEqualTo: null)
          .get();

      final dailyAverageImages = recentReports.docs.length / 7;
      final dailyAverageMB =
          dailyAverageImages * 0.2; // 200KB = 0.2MB (Blaze Plan)

      // ประมาณวันที่เหลือ
      final remainingMB = remainingGB * 1024;
      final estimatedDaysLeft =
          dailyAverageMB > 0 ? (remainingMB / dailyAverageMB).round() : 999;

      if (kDebugMode) {
        print('📊 Storage Usage Analysis (Blaze Plan - 10GB):');
        print('   Total images: $totalImages');
        print('   Estimated size: ${estimatedSizeGB.toStringAsFixed(3)} GB');
        print('   Usage: ${usagePercent.toStringAsFixed(1)}%');
        print('   Remaining: ${remainingGB.toStringAsFixed(3)} GB');
        print('   Daily average: ${dailyAverageMB.toStringAsFixed(2)} MB');
        print('   Estimated days left: $estimatedDaysLeft');
      }

      return {
        'total_images': totalImages,
        'estimated_size_gb': double.parse(estimatedSizeGB.toStringAsFixed(2)),
        'usage_percent': double.parse(usagePercent.toStringAsFixed(1)),
        'remaining_gb': double.parse(remainingGB.toStringAsFixed(2)),
        'daily_average_mb': double.parse(dailyAverageMB.toStringAsFixed(1)),
        'estimated_days_left': estimatedDaysLeft,
        'warning_level': _getWarningLevel(usagePercent),
        'can_upload': canUpload, // ใช้จาก Budget Monitoring
        'compression_mode': budgetCompressionMode, // ใช้จาก Budget Monitoring
        'budget_status': budgetStatus['status'],
        'budget_message': budgetStatus['message'],
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting storage usage: $e');
      }
      return {
        'error': e.toString(),
        'can_upload': true,
        'compression_mode': 'normal',
      };
    }
  }

  /// กำหนดระดับการแจ้งเตือน
  static String _getWarningLevel(double usagePercent) {
    if (usagePercent >= emergencyThresholdPercent) {
      return 'emergency'; // 🔴 ฉุกเฉิน
    } else if (usagePercent >= warningThresholdPercent) {
      return 'warning'; // 🟡 เตือน
    } else if (usagePercent >= 50) {
      return 'caution'; // 🟠 ระวัง
    } else {
      return 'normal'; // 🟢 ปกติ
    }
  }

  /// กำหนดโหมดการบีบอัด (รวมกับ Budget Monitoring)
  static Future<String> getOptimalCompressionMode() async {
    // ใช้จาก Budget Monitoring ก่อน
    final budgetMode =
        await BudgetMonitoringService.getOptimalCompressionMode();
    if (budgetMode != 'normal') {
      return budgetMode;
    }

    // ถ้า Budget Monitoring บอกว่าปกติ ให้ใช้จาก Storage usage
    final usage = await getStorageUsage();
    final usagePercent = usage['usage_percent'] ?? 0.0;
    return _getCompressionMode(usagePercent);
  }

  /// กำหนดโหมดการบีบอัด (ปรับสำหรับ Blaze Plan)
  static String _getCompressionMode(double usagePercent) {
    if (usagePercent >= emergencyThresholdPercent) {
      return 'emergency'; // บีบอัดแรงสุด 150KB, 50%
    } else if (usagePercent >= warningThresholdPercent) {
      return 'aggressive'; // บีบอัดแรง 180KB, 55%
    } else if (usagePercent >= 50) {
      return 'moderate'; // บีบอัดปกติ 200KB, 60%
    } else {
      return 'normal'; // บีบอัดเบา 250KB, 70%
    }
  }

  /// ได้รับการตั้งค่าการบีบอัดตามการใช้งาน (ปรับสำหรับ Blaze Plan)
  static Map<String, dynamic> getCompressionSettings(String mode) {
    switch (mode) {
      case 'emergency':
        return {
          'quality': 50,
          'maxWidth': 600,
          'maxHeight': 400,
          'targetSize': 150 * 1024, // 150KB
          'description': 'โหมดฉุกเฉิน - บีบอัดสูง',
        };
      case 'aggressive':
        return {
          'quality': 55,
          'maxWidth': 700,
          'maxHeight': 500,
          'targetSize': 180 * 1024, // 180KB
          'description': 'โหมดประหยัด - บีบอัดปานกลาง',
        };
      case 'moderate':
        return {
          'quality': 60,
          'maxWidth': 800,
          'maxHeight': 600,
          'targetSize': 200 * 1024, // 200KB
          'description': 'โหมดปกติ - บีบอัดเบา',
        };
      case 'normal':
      default:
        return {
          'quality': 70,
          'maxWidth': 1000,
          'maxHeight': 800,
          'targetSize': 250 * 1024, // 250KB
          'description': 'โหมดมาตรฐาน - คุณภาพดี',
        };
    }
  }

  /// ตรวจสอบว่าสามารถอัปโหลดได้หรือไม่ (ใช้ Budget Monitoring)
  static Future<bool> canUploadImage() async {
    return await BudgetMonitoringService.canUploadImage();
  }

  /// แจ้งเตือนผู้ใช้เกี่ยวกับการใช้งาน Storage
  static String getStorageMessage(Map<String, dynamic> usage) {
    final usagePercent = usage['usage_percent'] ?? 0.0;
    final remainingGB = usage['remaining_gb'] ?? 5.0;
    final daysLeft = usage['estimated_days_left'] ?? 999;

    if (usagePercent >= emergencyThresholdPercent) {
      return '🔴 พื้นที่เก็บข้อมูลเกือบเต็ม! เหลือ ${remainingGB.toStringAsFixed(2)}GB (${usagePercent.toStringAsFixed(1)}%) \nจะปิดรับรูปชั่วคราวเพื่อประหยัดพื้นที่';
    } else if (usagePercent >= warningThresholdPercent) {
      return '🟡 พื้นที่เก็บข้อมูลใกล้เต็ม! เหลือ ${remainingGB.toStringAsFixed(2)}GB (${usagePercent.toStringAsFixed(1)}%) \nเปิดโหมดประหยัดอัตโนมัติ';
    } else if (usagePercent >= 50) {
      return '🟠 พื้นที่เก็บข้อมูลใช้ไปแล้ว ${usagePercent.toStringAsFixed(1)}% \nเหลือประมาณ $daysLeft วัน';
    } else {
      return '🟢 พื้นที่เก็บข้อมูลเพียงพอ (${usagePercent.toStringAsFixed(1)}% ของ 10GB Blaze Plan)';
    }
  }

  /// บันทึกสถิติการใช้งาน
  static Future<void> logStorageUsage() async {
    try {
      final usage = await getStorageUsage();

      // บันทึกลง Firestore สำหรับการวิเคราะห์
      await FirebaseFirestore.instance.collection('storage_logs').add({
        ...usage,
        'timestamp': FieldValue.serverTimestamp(),
        'logged_by': 'auto_system',
      });

      if (kDebugMode) {
        print('📝 Storage usage logged successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error logging storage usage: $e');
      }
    }
  }

  /// ทำความสะอาดข้อมูล Storage logs เก่า
  static Future<void> cleanupStorageLogs() async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      final oldLogs = await FirebaseFirestore.instance
          .collection('storage_logs')
          .where('timestamp', isLessThan: Timestamp.fromDate(thirtyDaysAgo))
          .limit(100)
          .get();

      final batch = FirebaseFirestore.instance.batch();

      for (final doc in oldLogs.docs) {
        batch.delete(doc.reference);
      }

      if (oldLogs.docs.isNotEmpty) {
        await batch.commit();
        if (kDebugMode) {
          print('🗑️ Cleaned up ${oldLogs.docs.length} old storage logs');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error cleaning up storage logs: $e');
      }
    }
  }

  /// แนะนำการปรับปรุง
  static List<String> getOptimizationSuggestions(Map<String, dynamic> usage) {
    final usagePercent = usage['usage_percent'] ?? 0.0;
    final dailyAverage = usage['daily_average_mb'] ?? 0.0;
    final suggestions = <String>[];

    if (usagePercent > 80) {
      suggestions.add('🔧 เปิดโหมดบีบอัดแรงขึ้นอัตโนมัติ');
      suggestions.add('🗑️ ลบรูปเก่าที่มีอายุมากกว่า 60 วัน');
    }

    if (dailyAverage > 50) {
      // เพิ่มจาก 10MB เป็น 50MB สำหรับ Blaze Plan
      suggestions.add('📉 ลดขนาดรูปเป้าหมายเป็น 200KB');
      suggestions.add('🎯 ปรับคุณภาพภาพเป็น 60%');
    }

    if (usagePercent > 50) {
      suggestions.add('📱 แนะนำให้ผู้ใช้ลดขนาดรูปก่อนอัปโหลด');
      suggestions.add('⚡ เปิดใช้ WebP format เพื่อประหยัดพื้นที่ 30%');
    }

    if (suggestions.isEmpty) {
      suggestions.add('✅ การใช้งานอยู่ในเกณฑ์ปกติ');
    }

    return suggestions;
  }
}
