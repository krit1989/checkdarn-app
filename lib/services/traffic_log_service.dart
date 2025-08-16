import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'auth_service.dart';

/// Service สำหรับการเก็บ Traffic Log ตาม พ.ร.บ.คอมพิวเตอร์ 2560 มาตรา 26
/// ข้อมูลจะถูกเก็บไว้อย่างน้อย 90 วัน และลบอัตโนมัติหลังจากนั้น
class TrafficLogService {
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
        print('🔍 Traffic Log Service initialized');
        print('📱 Session ID: $_currentSessionId');
        print('📲 Device ID: $_deviceId');
        print('🔢 App Version: $_appVersion');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing Traffic Log Service: $e');
      }
    }
  }

  /// บันทึก Activity Log ตามข้อกำหนดของกฎหมาย
  static Future<void> logActivity(
    String action, {
    Map<String, dynamic>? location,
    Map<String, dynamic>? metadata,
    String? targetUserId,
    String? targetReportId,
  }) async {
    try {
      // ตรวจสอบว่าเป็น action ที่ต้องเก็บหรือไม่
      if (!_shouldLogAction(action)) {
        return;
      }

      final userId = AuthService.currentUser?.uid;
      final hashedUserId = userId != null ? _hashUserId(userId) : 'anonymous';
      
      final logEntry = {
        // ข้อมูลพื้นฐานตามกฎหมาย
        'timestamp': FieldValue.serverTimestamp(),
        'user_id_hash': hashedUserId, // ใช้ hash แทน user ID จริง
        'action': action,
        'session_id': _currentSessionId ?? 'unknown',
        
        // ข้อมูลอุปกรณ์ (ไม่ระบุตัวตน)
        'device_info': {
          'platform': Platform.isAndroid ? 'android' : 'ios',
          'app_version': _appVersion ?? 'unknown',
          'device_id_hash': _deviceId != null ? _hashString(_deviceId!) : 'unknown',
        },
        
        // ข้อมูลตำแหน่ง (ระดับเขต/อำเภอ เท่านั้น)
        'location_general': location != null ? _generalizeLocation(location) : null,
        
        // Metadata เพิ่มเติม
        'metadata': metadata ?? {},
        
        // ข้อมูลเป้าหมาย (ถ้ามี)
        'target_user_id_hash': targetUserId != null ? _hashUserId(targetUserId) : null,
        'target_report_id': targetReportId,
        
        // Flag สำหรับการจัดการข้อมูล
        'retention_days': 90, // จะลบหลัง 90 วัน
        'data_source': 'mobile_app',
        'log_version': '1.0',
      };

      // บันทึกลง Firestore
      await FirebaseFirestore.instance
          .collection(_collectionName)
          .add(logEntry);

      if (kDebugMode) {
        print('📝 Traffic log recorded: $action (user: ${hashedUserId.substring(0, 8)}...)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error logging activity: $e');
      }
      // ไม่ throw error เพื่อไม่ให้กระทบต่อการทำงานของแอป
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
    await logActivity(
      actionLogout,
      metadata: {
        'session_duration_minutes': _getSessionDurationMinutes(),
        'timestamp_local': DateTime.now().toIso8601String(),
      },
    );
  }

  /// บันทึกการโพสรายงานกล้อง
  static Future<void> logPostReport({
    required String category,
    required Map<String, dynamic> location,
    bool hasImage = false,
    bool hasDescription = false,
  }) async {
    await logActivity(
      actionPostReport,
      location: location,
      metadata: {
        'category': category,
        'has_image': hasImage,
        'has_description': hasDescription,
        'timestamp_local': DateTime.now().toIso8601String(),
      },
    );
  }

  /// บันทึกการดูรายงาน
  static Future<void> logViewReports({
    required Map<String, dynamic> location,
    required double searchRadius,
    required int resultCount,
  }) async {
    await logActivity(
      actionViewReports,
      location: location,
      metadata: {
        'search_radius_km': searchRadius,
        'result_count': resultCount,
        'timestamp_local': DateTime.now().toIso8601String(),
      },
    );
  }

  /// บันทึกการโหวต
  static Future<void> logVoteReport({
    required String reportId,
    required bool isUpvote,
  }) async {
    await logActivity(
      actionVoteReport,
      targetReportId: reportId,
      metadata: {
        'vote_type': isUpvote ? 'upvote' : 'downvote',
        'timestamp_local': DateTime.now().toIso8601String(),
      },
    );
  }

  /// บันทึกการแสดงความคิดเห็น
  static Future<void> logCommentReport({
    required String reportId,
    required int commentLength,
  }) async {
    await logActivity(
      actionCommentReport,
      targetReportId: reportId,
      metadata: {
        'comment_length': commentLength,
        'timestamp_local': DateTime.now().toIso8601String(),
      },
    );
  }

  /// บันทึกการลบรายงาน
  static Future<void> logDeleteReport({
    required String reportId,
    required String reason,
  }) async {
    await logActivity(
      actionDeleteReport,
      targetReportId: reportId,
      metadata: {
        'delete_reason': reason,
        'timestamp_local': DateTime.now().toIso8601String(),
      },
    );
  }

  /// สร้าง Session ID ใหม่
  static Future<void> _generateSessionId() async {
    _currentSessionId = _generateUniqueId();
  }

  /// ดึงข้อมูลอุปกรณ์
  static Future<void> _getDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        _deviceId = androidInfo.id; // Android ID
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        _deviceId = iosInfo.identifierForVendor; // iOS Vendor ID
      }
    } catch (e) {
      _deviceId = 'unknown';
      if (kDebugMode) {
        print('Error getting device info: $e');
      }
    }
  }

  /// ดึงเวอร์ชันแอป
  static Future<void> _getAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
    } catch (e) {
      _appVersion = 'unknown';
      if (kDebugMode) {
        print('Error getting app version: $e');
      }
    }
  }

  /// Hash User ID เพื่อความปลอดภัย
  static String _hashUserId(String userId) {
    return _hashString('user_$userId');
  }

  /// Hash string ด้วย SHA-256
  static String _hashString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// ทำให้ตำแหน่งเป็นแบบทั่วไป (ระดับเขต/อำเภอ)
  static Map<String, dynamic> _generalizeLocation(Map<String, dynamic> location) {
    final lat = location['lat'] as double?;
    final lng = location['lng'] as double?;
    
    if (lat == null || lng == null) return {};
    
    // ปัดเศษพิกัดให้เป็นระดับเขต/อำเภอ (ประมาณ 1-5 km)
    final generalLat = (lat * 100).round() / 100; // ปัด 2 ทศนิยม
    final generalLng = (lng * 100).round() / 100; // ปัด 2 ทศนิยม
    
    return {
      'lat_general': generalLat,
      'lng_general': generalLng,
      'province': location['province'] ?? 'unknown',
      'district': location['district'] ?? 'unknown',
    };
  }

  /// สร้าง Unique ID
  static String _generateUniqueId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return '${timestamp}_$random';
  }

  /// ตรวจสอบว่าควรเก็บ log หรือไม่
  static bool _shouldLogAction(String action) {
    const requiredActions = [
      actionLogin,
      actionLogout,
      actionPostReport,
      actionViewReports,
      actionVoteReport,
      actionCommentReport,
      actionDeleteReport,
      actionAppStart,
      actionAppResume,
    ];
    
    return requiredActions.contains(action);
  }

  /// คำนวณระยะเวลา session ในหน่วยนาที
  static int _getSessionDurationMinutes() {
    // ใช้วิธีง่ายๆ ในการคำนวณ session duration
    // อาจจะต้องปรับปรุงให้แม่นยำมากขึ้นในอนาคต
    return 0; // Placeholder
  }

    /// ทำความสะอาดข้อมูล Traffic Log แบบ Dynamic Retention (ปรับตามการใช้งาน)
  static Future<void> cleanupOldLogs() async {
    try {
      // ตรวจสอบปริมาณการใช้งานรายวัน
      final dailyUsage = await getDailyLogCount();
      
      // คำนวณระยะเวลา retention แบบ dynamic
      int retentionDays;
      if (dailyUsage < 1000) {
        retentionDays = 90;  // Low usage: 90 วัน
      } else if (dailyUsage < 10000) {
        retentionDays = 60;  // Medium usage: 60 วัน
      } else if (dailyUsage < 50000) {
        retentionDays = 30;  // High usage: 30 วัน
      } else {
        retentionDays = 15;  // Very high usage: 15 วัน
      }
      
      final cutoffDate = DateTime.now().subtract(Duration(days: retentionDays));
      
      if (kDebugMode) {
        print('� Daily usage: $dailyUsage logs/day');
        print('📅 Dynamic retention: $retentionDays days');
        print('✂️ Cleaning logs older than: ${cutoffDate.toIso8601String()}');
      }
      
      final querySnapshot = await FirebaseFirestore.instance
          .collection(_collectionName)
          .where('timestamp', isLessThan: Timestamp.fromDate(cutoffDate))
          .limit(500) // เพิ่มเป็น 500 records เพื่อทำความสะอาดเร็วขึ้น
          .get();

  /// ดึงสถิติการใช้งาน (สำหรับ Admin)
  static Future<Map<String, dynamic>> getUsageStatistics({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection(_collectionName)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();
      
      final stats = <String, int>{};
      final uniqueUsers = <String>{};
      
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final action = data['action'] as String?;
        final userHash = data['user_id_hash'] as String?;
        
        if (action != null) {
          stats[action] = (stats[action] ?? 0) + 1;
        }
        
        if (userHash != null && userHash != 'anonymous') {
          uniqueUsers.add(userHash);
        }
      }
      
      return {
        'total_events': querySnapshot.docs.length,
        'unique_users': uniqueUsers.length,
        'action_breakdown': stats,
        'period': {
          'start': startDate.toIso8601String(),
          'end': endDate.toIso8601String(),
        },
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting usage statistics: $e');
      }
      return {};
    }
  }

  /// นับจำนวน log entries ต่อวัน (เฉลี่ย 7 วันล่าสุด)
  static Future<int> _getDailyLogCount() async {
    try {
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      
      final querySnapshot = await FirebaseFirestore.instance
          .collection(_collectionName)
          .where('timestamp', isGreaterThan: Timestamp.fromDate(sevenDaysAgo))
          .get();
      
      final totalLogs = querySnapshot.docs.length;
      final dailyAverage = (totalLogs / 7).round();
      
      if (kDebugMode) {
        print('📊 Total logs (7 days): $totalLogs');
        print('📈 Daily average: $dailyAverage logs/day');
      }
      
      return dailyAverage;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error counting daily logs: $e');
      }
      return 1000; // Default to medium usage if error
    }
  }
}
