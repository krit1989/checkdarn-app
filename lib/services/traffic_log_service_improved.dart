import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'auth_service.dart';

/// Service สำหรับการเก็บ Traffic Log ตาม พ.ร.บ.คอมพิวเตอร์ 2560 มาตรา 26
/// ข้อมูลจะถูกเก็บไว้แบบ Dynamic Retention (15-90 วัน) ตามปริมาณการใช้งาน
/// และลบอัตโนมัติหลังจากนั้น
class ImprovedTrafficLogService {
  static const String _collectionName = 'traffic_logs';

  // การกำหนดประเภทของกิจกรรมที่ต้องเก็บ log
  static const String actionLogin = 'user_login';
  static const String actionLogout = 'user_logout';
  static const String actionPostReport = 'post_camera_report';
  static const String actionViewReports = 'view_reports';
  static const String actionUpdateLocation = 'update_location';
  static const String actionSearchReports = 'search_reports';
  static const String actionVoteReport = 'vote_report';
  static const String actionCommentReport = 'comment_report';
  static const String actionDeleteReport = 'delete_report';
  static const String actionAppStart = 'app_start';
  static const String actionAppResume = 'app_resume';

  static String? _currentSessionId;
  static String? _deviceId;
  static String? _appVersion;

  /// เริ่มต้น Traffic Log Service
  static Future<void> initialize() async {
    try {
      await _generateSessionId();
      await _getDeviceInfo();
      await _getAppVersion();

      // Log การเปิดแอป
      await logActivity(actionAppStart);

      if (kDebugMode) {
        print('🔍 Improved Traffic Log Service initialized');
        print('📱 Session ID: $_currentSessionId');
        print('📲 Device ID: $_deviceId');
        print('🔢 App Version: $_appVersion');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing Improved Traffic Log Service: $e');
      }
    }
  }

  /// สร้าง Session ID แบบ hash
  static Future<void> _generateSessionId() async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final random = DateTime.now().microsecond.toString();
      final input = '$timestamp$random${Platform.operatingSystem}';

      final bytes = utf8.encode(input);
      final digest = sha256.convert(bytes);
      _currentSessionId = digest.toString().substring(0, 16);
    } catch (e) {
      _currentSessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// ดึงข้อมูลอุปกรณ์แบบ hash
  static Future<void> _getDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      String deviceIdentifier;

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceIdentifier = '${androidInfo.model}_${androidInfo.id}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceIdentifier = '${iosInfo.model}_${iosInfo.identifierForVendor}';
      } else {
        deviceIdentifier = 'unknown_device';
      }

      // Hash device identifier
      final bytes = utf8.encode(deviceIdentifier);
      final digest = sha256.convert(bytes);
      _deviceId = digest.toString().substring(0, 16);
    } catch (e) {
      _deviceId = 'device_unknown';
    }
  }

  /// ดึงข้อมูลเวอร์ชันแอป
  static Future<void> _getAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _appVersion = packageInfo.version;
    } catch (e) {
      _appVersion = '1.0.0';
    }
  }

  /// Hash IP Address สำหรับการปกป้องความเป็นส่วนตัว
  static String _hashIpAddress(String ipAddress) {
    // ปัด IP เป็นช่วง subnet เพื่อลดความละเอียด
    final parts = ipAddress.split('.');
    if (parts.length == 4) {
      // เปลี่ยน octet สุดท้ายเป็น 0 (เช่น 192.168.1.123 -> 192.168.1.0)
      final maskedIp = '${parts[0]}.${parts[1]}.${parts[2]}.0';
      return maskedIp;
    }
    return 'unknown';
  }

  /// ปัดเศษพิกัดให้เป็นระดับเขต/อำเภอ (เพื่อปกป้องความเป็นส่วนตัว)
  static Map<String, double>? _roundLocation(Map<String, dynamic>? location) {
    if (location == null) return null;

    final lat = location['lat'] as double?;
    final lng = location['lng'] as double?;

    if (lat == null || lng == null) return null;

    // ปัดเศษให้เป็น 2 ทศนิยม (~1km accuracy)
    return {
      'lat': double.parse(lat.toStringAsFixed(2)),
      'lng': double.parse(lng.toStringAsFixed(2)),
    };
  }

  /// บันทึกกิจกรรมลง Traffic Log (ปรับปรุงแล้ว)
  static Future<void> logActivity(
    String action, {
    Map<String, dynamic>? location,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Hash User ID
      final userId = AuthService.currentUser?.uid;
      final hashedUserId = userId != null
          ? sha256.convert(utf8.encode(userId)).toString().substring(0, 16)
          : 'anonymous';

      // สร้าง log entry
      final logEntry = {
        'session_id': _currentSessionId ?? 'unknown',
        'user_id_hash': hashedUserId,
        'device_id_hash': _deviceId ?? 'unknown',
        'action': action,
        'timestamp': FieldValue.serverTimestamp(),
        'ip_address':
            _hashIpAddress('192.168.1.1'), // จะต้องดึงจาก context จริง
        'location': _roundLocation(location),
        'device_info': {
          'platform': Platform.operatingSystem,
          'version': Platform.operatingSystemVersion,
        },
        'app_version': _appVersion ?? '1.0.0',
        'metadata': metadata ?? {},
      };

      // บันทึกลง Firestore
      await FirebaseFirestore.instance
          .collection(_collectionName)
          .add(logEntry);

      if (kDebugMode) {
        print(
            '📝 Traffic log recorded: $action (user: ${hashedUserId.substring(0, 8)}...)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error logging activity: $e');
      }
      // ไม่ throw error เพื่อไม่ให้กระทบต่อการทำงานของแอป
    }
  }

  /// ทำความสะอาดข้อมูล Traffic Log แบบ Dynamic Retention (ปรับตามการใช้งาน)
  static Future<void> cleanupOldLogs() async {
    try {
      // ตรวจสอบปริมาณการใช้งานรายวัน (เฉลี่ย 7 วันล่าสุด)
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      final usageQuery = await FirebaseFirestore.instance
          .collection(_collectionName)
          .where('timestamp', isGreaterThan: Timestamp.fromDate(sevenDaysAgo))
          .get();

      final totalLogs = usageQuery.docs.length;
      final dailyUsage = totalLogs > 0 ? (totalLogs / 7).round() : 0;

      // คำนวณระยะเวลา retention แบบ dynamic
      int retentionDays;
      String usageLevel;

      if (dailyUsage < 1000) {
        retentionDays = 90; // Low usage: 90 วัน
        usageLevel = 'LOW';
      } else if (dailyUsage < 10000) {
        retentionDays = 60; // Medium usage: 60 วัน
        usageLevel = 'MEDIUM';
      } else if (dailyUsage < 50000) {
        retentionDays = 30; // High usage: 30 วัน
        usageLevel = 'HIGH';
      } else {
        retentionDays = 15; // Very high usage: 15 วัน
        usageLevel = 'VERY HIGH';
      }

      final cutoffDate = DateTime.now().subtract(Duration(days: retentionDays));

      if (kDebugMode) {
        print('📊 === DYNAMIC RETENTION ANALYSIS ===');
        print('🔧 Total logs (7 days): $totalLogs');
        print('📈 Daily usage: $dailyUsage logs/day');
        print('🎯 Usage level: $usageLevel');
        print('📅 Dynamic retention: $retentionDays days');
        print('✂️ Cleaning logs older than: ${cutoffDate.toIso8601String()}');
      }

      // ลบข้อมูลเก่าที่เกินกำหนด
      final querySnapshot = await FirebaseFirestore.instance
          .collection(_collectionName)
          .where('timestamp', isLessThan: Timestamp.fromDate(cutoffDate))
          .limit(500) // เพิ่มเป็น 500 records เพื่อทำความสะอาดเร็วขึ้น
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final batch = FirebaseFirestore.instance.batch();

        for (final doc in querySnapshot.docs) {
          batch.delete(doc.reference);
        }

        await batch.commit();

        if (kDebugMode) {
          print('🗑️ Cleaned up ${querySnapshot.docs.length} old traffic logs');
          print('⚡ Retention: $retentionDays days (level: $usageLevel)');
          print(
              '💾 Storage saved: ~${(querySnapshot.docs.length * 0.5).toStringAsFixed(1)} KB');
        }
      } else {
        if (kDebugMode) {
          print('✅ No old logs to clean (retention: $retentionDays days)');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error cleaning up traffic logs: $e');
      }
    }
  }

  /// แสดงสถิติการใช้งาน Storage และการจัดการ
  static Future<Map<String, dynamic>> getStorageStats() async {
    try {
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));

      // นับ logs ใน 7 วันล่าสุด
      final recentQuery = await FirebaseFirestore.instance
          .collection(_collectionName)
          .where('timestamp', isGreaterThan: Timestamp.fromDate(sevenDaysAgo))
          .get();

      // นับ logs ทั้งหมด
      final totalQuery =
          await FirebaseFirestore.instance.collection(_collectionName).get();

      final recentLogs = recentQuery.docs.length;
      final totalLogs = totalQuery.docs.length;
      final dailyAverage = recentLogs > 0 ? (recentLogs / 7).round() : 0;

      // คำนวณขนาดประมาณ (0.5 KB ต่อ log entry)
      final estimatedSizeKB = (totalLogs * 0.5).round();
      final estimatedSizeMB = (estimatedSizeKB / 1024).toStringAsFixed(2);

      // คำนวณ retention period ตามการใช้งาน
      int retentionDays;
      String usageLevel;

      if (dailyAverage < 1000) {
        retentionDays = 90;
        usageLevel = 'LOW';
      } else if (dailyAverage < 10000) {
        retentionDays = 60;
        usageLevel = 'MEDIUM';
      } else if (dailyAverage < 50000) {
        retentionDays = 30;
        usageLevel = 'HIGH';
      } else {
        retentionDays = 15;
        usageLevel = 'VERY HIGH';
      }

      return {
        'total_logs': totalLogs,
        'recent_logs_7_days': recentLogs,
        'daily_average': dailyAverage,
        'usage_level': usageLevel,
        'retention_days': retentionDays,
        'estimated_size_kb': estimatedSizeKB,
        'estimated_size_mb': estimatedSizeMB,
        'last_updated': now.toIso8601String(),
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting storage stats: $e');
      }
      return {};
    }
  }

  /// บันทึก Login Activity
  static Future<void> logLogin(String loginMethod) async {
    await logActivity(
      actionLogin,
      metadata: {
        'login_method': loginMethod,
        'timestamp_local': DateTime.now().toIso8601String(),
      },
    );
  }

  /// บันทึก Logout Activity
  static Future<void> logLogout() async {
    await logActivity(actionLogout);
  }

  /// บันทึกการโพสรายงานกล้อง
  static Future<void> logPostReport({
    required String category,
    required Map<String, double> location,
    String? description,
  }) async {
    await logActivity(
      actionPostReport,
      location: {
        'lat': location['lat'],
        'lng': location['lng'],
      },
      metadata: {
        'category': category,
        'has_description': description != null && description.isNotEmpty,
        'description_length': description?.length ?? 0,
      },
    );
  }

  /// บันทึกการดูรายงาน
  static Future<void> logViewReports({
    required Map<String, double> location,
    required double searchRadius,
    required int resultCount,
  }) async {
    await logActivity(
      actionViewReports,
      location: {
        'lat': location['lat'],
        'lng': location['lng'],
      },
      metadata: {
        'search_radius': searchRadius,
        'result_count': resultCount,
      },
    );
  }

  /// แสดงสถิติการจัดการ Traffic Log
  static Future<void> showManagementStats() async {
    try {
      final stats = await getStorageStats();

      if (kDebugMode) {
        print('📊 === TRAFFIC LOG MANAGEMENT STATS ===');
        print('📝 Total logs: ${stats['total_logs']}');
        print('🔥 Recent (7 days): ${stats['recent_logs_7_days']}');
        print('📈 Daily average: ${stats['daily_average']} logs/day');
        print('🎯 Usage level: ${stats['usage_level']}');
        print('📅 Retention period: ${stats['retention_days']} days');
        print('💾 Storage size: ${stats['estimated_size_mb']} MB');
        print('🔄 Last updated: ${stats['last_updated']}');
        print('==========================================');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error showing management stats: $e');
      }
    }
  }
}
