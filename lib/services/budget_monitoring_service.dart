import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Service สำหรับติดตาม Budget และควบคุมต้นทุนของ Firebase Blaze Plan
class BudgetMonitoringService {
  static const String _collectionBudgetAlerts = 'budget_alerts';
  static const String _collectionStorageStats = 'storage_stats';
  static const String _collectionAppSettings = 'app_settings';

  // Budget thresholds (USD)
  static const double warningBudget = 10.0; // $10 - เตือน
  static const double criticalBudget = 20.0; // $20 - วิกฤต
  static const double emergencyBudget = 25.0; // $25 - ฉุกเฉิน

  /// ดึงสถานะ Budget ล่าสุด
  static Future<Map<String, dynamic>> getCurrentBudgetStatus() async {
    try {
      // ดึง budget alert ล่าสุด
      final alertQuery = await FirebaseFirestore.instance
          .collection(_collectionBudgetAlerts)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (alertQuery.docs.isEmpty) {
        return {
          'status': 'normal',
          'cost_amount': 0.0,
          'budget_amount': emergencyBudget,
          'usage_percent': 0.0,
          'alert_level': 'info',
          'can_upload': true,
          'message': 'Budget tracking ปกติ',
        };
      }

      final latestAlert = alertQuery.docs.first.data();
      final usagePercent = latestAlert['usage_percent'] ?? 0.0;
      final costAmount = latestAlert['cost_amount'] ?? 0.0;
      final alertLevel = latestAlert['alert_level'] ?? 'info';

      // ตรวจสอบการตั้งค่าปัจจุบัน
      final appSettingsDoc = await FirebaseFirestore.instance
          .collection(_collectionAppSettings)
          .doc('storage_control')
          .get();

      final settings = appSettingsDoc.data() ?? {};
      final uploadEnabled = settings['upload_enabled'] ?? true;
      final compressionMode = settings['compression_mode'] ?? 'normal';

      if (kDebugMode) {
        print('💰 Budget Status:');
        print('   Cost: \$${costAmount.toStringAsFixed(2)}');
        print('   Usage: ${usagePercent.toStringAsFixed(1)}%');
        print('   Alert Level: $alertLevel');
        print('   Upload Enabled: $uploadEnabled');
        print('   Compression: $compressionMode');
      }

      return {
        'status': _getBudgetStatus(usagePercent),
        'cost_amount': costAmount,
        'budget_amount': latestAlert['budget_amount'] ?? emergencyBudget,
        'usage_percent': usagePercent,
        'alert_level': alertLevel,
        'can_upload': uploadEnabled,
        'compression_mode': compressionMode,
        'message': _getBudgetMessage(usagePercent, costAmount),
        'timestamp': latestAlert['timestamp'],
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting budget status: $e');
      }
      return {
        'status': 'error',
        'error': e.toString(),
        'can_upload': true, // ให้ upload ได้ในกรณี error
        'message': 'ไม่สามารถตรวจสอบ budget ได้',
      };
    }
  }

  /// ตรวจสอบว่าสามารถ upload รูปได้หรือไม่
  static Future<bool> canUploadImage() async {
    try {
      final budgetStatus = await getCurrentBudgetStatus();
      return budgetStatus['can_upload'] ?? true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking upload permission: $e');
      }
      return true; // ให้ upload ได้ในกรณี error
    }
  }

  /// ดึงโหมดการบีบอัดที่เหมาะสม
  static Future<String> getOptimalCompressionMode() async {
    try {
      final budgetStatus = await getCurrentBudgetStatus();
      return budgetStatus['compression_mode'] ?? 'normal';
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting compression mode: $e');
      }
      return 'normal';
    }
  }

  /// ดึงสถิติการใช้งาน Storage ล่าสุด
  static Future<Map<String, dynamic>> getStorageStatistics() async {
    try {
      final statsQuery = await FirebaseFirestore.instance
          .collection(_collectionStorageStats)
          .orderBy('timestamp', descending: true)
          .limit(7) // ดึง 7 วันล่าสุด
          .get();

      if (statsQuery.docs.isEmpty) {
        return {
          'current_size_gb': 0.0,
          'current_images': 0,
          'daily_average_mb': 0.0,
          'cost_estimate_usd': 0.0,
          'trend': 'stable',
        };
      }

      final currentStats = statsQuery.docs.first.data();
      final currentSizeGB = currentStats['estimated_size_gb'] ?? 0.0;
      final currentImages = currentStats['total_images'] ?? 0;
      final costEstimate = currentStats['cost_estimate_usd'] ?? 0.0;

      // คำนวณแนวโน้ม
      double dailyAverageMB = 0.0;
      String trend = 'stable';

      if (statsQuery.docs.length >= 2) {
        final oldestStats = statsQuery.docs.last.data();
        final oldSizeGB = oldestStats['estimated_size_gb'] ?? 0.0;

        final daysDiff = statsQuery.docs.length - 1;
        final sizeDiffMB = (currentSizeGB - oldSizeGB) * 1024;
        dailyAverageMB = daysDiff > 0 ? sizeDiffMB / daysDiff : 0.0;

        // กำหนดแนวโน้ม
        if (dailyAverageMB > 50) {
          trend = 'increasing_fast';
        } else if (dailyAverageMB > 20) {
          trend = 'increasing';
        } else if (dailyAverageMB < -10) {
          trend = 'decreasing';
        }
      }

      if (kDebugMode) {
        print('📊 Storage Statistics:');
        print('   Size: ${currentSizeGB.toStringAsFixed(2)} GB');
        print('   Images: $currentImages');
        print('   Daily growth: ${dailyAverageMB.toStringAsFixed(1)} MB/day');
        print('   Cost estimate: \$${costEstimate.toStringAsFixed(2)}');
        print('   Trend: $trend');
      }

      return {
        'current_size_gb': currentSizeGB,
        'current_images': currentImages,
        'daily_average_mb': dailyAverageMB,
        'cost_estimate_usd': costEstimate,
        'trend': trend,
        'timestamp': currentStats['timestamp'],
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting storage statistics: $e');
      }
      return {
        'error': e.toString(),
        'current_size_gb': 0.0,
        'current_images': 0,
        'daily_average_mb': 0.0,
        'cost_estimate_usd': 0.0,
        'trend': 'unknown',
      };
    }
  }

  /// ส่ง notification เมื่อเกิน budget
  static Future<void> handleBudgetExceeded(
      String alertLevel, double usagePercent) async {
    try {
      // บันทึก log การเกิน budget
      await FirebaseFirestore.instance.collection('budget_exceeded_logs').add({
        'alert_level': alertLevel,
        'usage_percent': usagePercent,
        'timestamp': FieldValue.serverTimestamp(),
        'action_taken': _getActionTaken(alertLevel),
      });

      if (kDebugMode) {
        print(
            '🚨 Budget exceeded: $alertLevel (${usagePercent.toStringAsFixed(1)}%)');
        print('   Action: ${_getActionTaken(alertLevel)}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling budget exceeded: $e');
      }
    }
  }

  /// คำนวณค่าใช้จ่ายประมาณการรายเดือน
  static Future<Map<String, dynamic>> estimateMonthlyBudget() async {
    try {
      final storageStats = await getStorageStatistics();
      final dailyGrowthMB = storageStats['daily_average_mb'] ?? 0.0;
      final currentSizeGB = storageStats['current_size_gb'] ?? 0.0;

      // ประมาณการ 30 วัน
      final monthlyGrowthGB = (dailyGrowthMB * 30) / 1024;
      final projectedSizeGB = currentSizeGB + monthlyGrowthGB;

      // คำนวณต้นทุน Firebase Storage ($0.026/GB/month)
      final freeTier = 1.0; // 1GB ฟรี
      final chargeableGB =
          (projectedSizeGB - freeTier).clamp(0.0, double.infinity);
      final storageCost = chargeableGB * 0.026;

      // ประมาณ Firestore cost (reads/writes)
      final estimatedFirestoreCost = 2.0; // $2 ประมาณการ

      // รวมต้นทุน
      final totalEstimatedCost = storageCost + estimatedFirestoreCost;

      if (kDebugMode) {
        print('📊 Monthly Budget Estimate:');
        print('   Current size: ${currentSizeGB.toStringAsFixed(2)} GB');
        print('   Projected size: ${projectedSizeGB.toStringAsFixed(2)} GB');
        print('   Storage cost: \$${storageCost.toStringAsFixed(2)}');
        print(
            '   Firestore cost: \$${estimatedFirestoreCost.toStringAsFixed(2)}');
        print('   Total: \$${totalEstimatedCost.toStringAsFixed(2)}');
      }

      return {
        'current_size_gb': currentSizeGB,
        'projected_size_gb': projectedSizeGB,
        'monthly_growth_gb': monthlyGrowthGB,
        'storage_cost_usd': storageCost,
        'firestore_cost_usd': estimatedFirestoreCost,
        'total_estimated_cost_usd': totalEstimatedCost,
        'is_within_budget': totalEstimatedCost <= emergencyBudget,
        'budget_usage_percent': (totalEstimatedCost / emergencyBudget) * 100,
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error estimating monthly budget: $e');
      }
      return {
        'error': e.toString(),
        'total_estimated_cost_usd': 0.0,
        'is_within_budget': true,
      };
    }
  }

  /// ดึงแนะนำการประหยัดต้นทุน
  static Future<List<String>> getCostSavingRecommendations() async {
    try {
      final budgetStatus = await getCurrentBudgetStatus();
      final storageStats = await getStorageStatistics();

      final usagePercent = budgetStatus['usage_percent'] ?? 0.0;
      final dailyGrowthMB = storageStats['daily_average_mb'] ?? 0.0;

      final recommendations = <String>[];

      if (usagePercent > 80) {
        recommendations.add('🔴 เปิดโหมดบีบอัดสูงสุด (100KB/รูป)');
        recommendations.add('🗑️ ลบรูปเก่าอัตโนมัติทุก 15 วัน');
        recommendations.add('⏸️ พิจารณาหยุดรับรูปชั่วคราว');
      } else if (usagePercent > 50) {
        recommendations.add('🟡 เปิดโหมดบีบอัดแรง (150KB/รูป)');
        recommendations.add('📉 ลดขนาดรูปสูงสุดเป็น 800px');
      }

      if (dailyGrowthMB > 100) {
        recommendations.add('📊 การเติบโตเร็วเกินไป ควรตรวจสอบการใช้งาน');
        recommendations.add('🎯 ตั้ง compression เป็น aggressive mode');
      }

      // แนะนำทั่วไป
      recommendations.addAll([
        '💰 ตั้ง Budget Alert ใน Firebase Console',
        '📱 ใช้ WebP format เพื่อประหยัดพื้นที่ 30%',
        '🔄 ตรวจสอบสถิติการใช้งานทุกสัปดาห์',
        '📈 พิจารณาใช้ CDN ถ้าผู้ใช้เยอะ',
      ]);

      return recommendations;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting recommendations: $e');
      }
      return ['❌ ไม่สามารถดึงแนะนำได้ กรุณาลองใหม่'];
    }
  }

  // Helper methods
  static String _getBudgetStatus(double usagePercent) {
    if (usagePercent >= 90) return 'emergency';
    if (usagePercent >= 80) return 'critical';
    if (usagePercent >= 50) return 'warning';
    return 'normal';
  }

  static String _getBudgetMessage(double usagePercent, double costAmount) {
    if (usagePercent >= 90) {
      return '🔴 งบประมาณใกล้หมด! (\$${costAmount.toStringAsFixed(2)}) ระบบจำกัดการใช้งาน';
    } else if (usagePercent >= 80) {
      return '🟡 งบประมาณใกล้เต็ม (\$${costAmount.toStringAsFixed(2)}) โหมดประหยัด';
    } else if (usagePercent >= 50) {
      return '🟠 ใช้งบประมาณไปแล้ว ${usagePercent.toStringAsFixed(1)}%';
    } else {
      return '🟢 งบประมาณปกติ (\$${costAmount.toStringAsFixed(2)})';
    }
  }

  static String _getActionTaken(String alertLevel) {
    switch (alertLevel) {
      case 'emergency':
        return 'ปิดการ upload รูป, เปิดโหมดบีบอัดสูงสุด';
      case 'critical':
        return 'เปิดโหมดประหยัดสูง, ลบรูปเก่าอัตโนมัติ';
      case 'warning':
        return 'เปิดโหมดบีบอัดปานกลาง';
      default:
        return 'ไม่มีการดำเนินการ';
    }
  }
}
