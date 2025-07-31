import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

/// Security Level สำหรับแต่ละหน้า
enum SecurityLevel {
  low, // FAQ, About Us (ไม่ต้องป้องกันหนัก)
  medium, // ส่วนใหญ่ของแอป (Rate Limiting + Fingerprinting)
  high, // Login, Settings, Payment (ป้องกันเต็มรูปแบบ)
  critical // Admin, Financial (ป้องกันสูงสุด)
}

/// ประเภทของการโจมตี
enum ThreatType {
  rateLimitExceeded,
  suspiciousDevice,
  locationSpoofing,
  rapidActions,
  humanVerificationFailed,
  sessionTimeout,
  apiAbuse
}

/// ข้อมูลการป้องกันสำหรับแต่ละหน้า
class PageSecurityConfig {
  final SecurityLevel level;
  final int maxActionsPerMinute;
  final bool requireHumanVerification;
  final bool enableDeviceFingerprinting;
  final bool enableLocationVerification;
  final Duration sessionTimeout;
  final bool enableBehaviorAnalysis;

  const PageSecurityConfig({
    required this.level,
    this.maxActionsPerMinute = 30,
    this.requireHumanVerification = false,
    this.enableDeviceFingerprinting = true,
    this.enableLocationVerification = false,
    this.sessionTimeout = const Duration(hours: 2),
    this.enableBehaviorAnalysis = false,
  });
}

/// Smart Security Service - ระบบป้องกันอัจฉริยะ
class SmartSecurityService {
  static final SmartSecurityService _instance =
      SmartSecurityService._internal();
  factory SmartSecurityService() => _instance;
  SmartSecurityService._internal();

  // Static variables for compatibility
  static SecurityLevel _globalSecurityLevel = SecurityLevel.medium;

  /// Set global security level for compatibility with legacy code
  static void setSecurityLevel(SecurityLevel level) {
    _globalSecurityLevel = level;
    print('🔒 Global security level set to: $level');
  }

  /// Get current global security level
  static SecurityLevel getCurrentSecurityLevel() {
    return _globalSecurityLevel;
  }

  // ==================== CONFIGURATION ====================

  /// กำหนดค่าการป้องกันสำหรับแต่ละหน้า
  static const Map<String, PageSecurityConfig> _pageConfigs = {
    // HIGH RISK PAGES - ป้องกันเต็มรูปแบบ
    'login': PageSecurityConfig(
      level: SecurityLevel.high,
      maxActionsPerMinute: 5,
      requireHumanVerification: true,
      enableDeviceFingerprinting: true,
      enableBehaviorAnalysis: true,
      sessionTimeout: Duration(minutes: 30),
    ),
    'settings': PageSecurityConfig(
      level: SecurityLevel.high,
      maxActionsPerMinute: 20,
      requireHumanVerification: false,
      enableDeviceFingerprinting: true,
      enableBehaviorAnalysis: true,
    ),
    'profile': PageSecurityConfig(
      level: SecurityLevel.high,
      maxActionsPerMinute: 15,
      requireHumanVerification: false,
      enableDeviceFingerprinting: true,
      enableBehaviorAnalysis: true,
    ),

    // MEDIUM RISK PAGES - ป้องกันปานกลาง
    'map': PageSecurityConfig(
      level: SecurityLevel.medium,
      maxActionsPerMinute: 50,
      enableDeviceFingerprinting: true,
      enableLocationVerification: true,
      enableBehaviorAnalysis: true,
    ),
    'speed_camera': PageSecurityConfig(
      level: SecurityLevel.medium,
      maxActionsPerMinute: 40,
      enableDeviceFingerprinting: true,
      enableLocationVerification: true,
      enableBehaviorAnalysis: true,
    ),
    'report': PageSecurityConfig(
      level: SecurityLevel.medium,
      maxActionsPerMinute: 10, // จำกัดการรายงานไม่ให้มากเกินไป
      requireHumanVerification: false,
      enableDeviceFingerprinting: true,
      enableLocationVerification: true,
    ),

    // LOW RISK PAGES - ป้องกันเบื้องต้น
    'help': PageSecurityConfig(
      level: SecurityLevel.low,
      maxActionsPerMinute: 100,
      enableDeviceFingerprinting: false,
      enableBehaviorAnalysis: false,
    ),
    'about': PageSecurityConfig(
      level: SecurityLevel.low,
      maxActionsPerMinute: 100,
      enableDeviceFingerprinting: false,
      enableBehaviorAnalysis: false,
    ),
    'faq': PageSecurityConfig(
      level: SecurityLevel.low,
      maxActionsPerMinute: 100,
      enableDeviceFingerprinting: false,
      enableBehaviorAnalysis: false,
    ),
  };

  // ==================== STATE MANAGEMENT ====================

  static final Map<String, List<DateTime>> _pageActionHistory = {};
  static final Map<String, int> _pageSuspiciousCount = {};
  static final Map<String, DateTime> _pageLastActivity = {};
  static final Set<String> _bannedDevices = {};
  static String? _deviceFingerprint;
  static final Map<String, dynamic> _deviceInfo = {};
  static final Map<String, List<dynamic>> _behaviorHistory = {};

  // ==================== MAIN API METHODS ====================

  /// ตรวจสอบการป้องกันสำหรับหน้าที่กำหนด
  static Future<SecurityCheckResult> checkPageSecurity(
    String pageId, {
    Map<String, dynamic>? context,
  }) async {
    final config = _getPageConfig(pageId);
    final results = <SecurityCheck>[];

    print(
        '🛡️ Checking security for page: $pageId (Level: ${config.level.name})');

    // 1. Rate Limiting Check
    final rateLimitResult = _checkRateLimit(pageId, config.maxActionsPerMinute);
    results.add(rateLimitResult);

    // 2. Device Fingerprinting Check
    if (config.enableDeviceFingerprinting) {
      final deviceResult = await _checkDeviceFingerprint(pageId);
      results.add(deviceResult);
    }

    // 3. Human Verification Check
    if (config.requireHumanVerification) {
      final humanResult = _checkHumanVerification(pageId);
      results.add(humanResult);
    }

    // 4. Location Verification Check
    if (config.enableLocationVerification && context != null) {
      final locationResult = await _checkLocationVerification(pageId, context);
      results.add(locationResult);
    }

    // 5. Behavior Analysis Check
    if (config.enableBehaviorAnalysis && context != null) {
      final behaviorResult = _analyzeBehavior(pageId, context);
      results.add(behaviorResult);
    }

    // 6. Session Timeout Check
    final sessionResult = _checkSessionTimeout(pageId, config.sessionTimeout);
    results.add(sessionResult);

    // Evaluate overall result
    final hasBlocking = results.any((r) => r.action == SecurityAction.block);
    final hasWarning = results.any((r) => r.action == SecurityAction.warn);

    return SecurityCheckResult(
      pageId: pageId,
      level: config.level,
      isAllowed: !hasBlocking,
      action: hasBlocking
          ? SecurityAction.block
          : hasWarning
              ? SecurityAction.warn
              : SecurityAction.allow,
      checks: results,
      timestamp: DateTime.now(),
    );
  }

  /// บันทึกการกระทำของผู้ใช้
  static void recordUserAction(
    String pageId,
    String actionType, {
    Map<String, dynamic>? context,
  }) {
    final now = DateTime.now();

    // บันทึกลงใน action history
    _pageActionHistory.putIfAbsent(pageId, () => []);
    _pageActionHistory[pageId]!.add(now);

    // อัปเดตเวลากิจกรรมล่าสุด
    _pageLastActivity[pageId] = now;

    // บันทึกพฤติกรรม
    if (context != null) {
      _behaviorHistory.putIfAbsent(pageId, () => []);
      _behaviorHistory[pageId]!.add({
        'action': actionType,
        'timestamp': now,
        'context': context,
      });

      // เก็บประวัติไม่เกิน 100 รายการต่อหน้า
      if (_behaviorHistory[pageId]!.length > 100) {
        _behaviorHistory[pageId]!.removeAt(0);
      }
    }

    // ทำความสะอาดข้อมูลเก่า
    _cleanupOldData(pageId);

    print('📝 Recorded action: $pageId -> $actionType');
  }

  /// แสดง Human Verification Challenge
  static Future<bool> showHumanVerification(
      BuildContext context, String pageId) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => _HumanVerificationDialog(pageId: pageId),
        ) ??
        false;
  }

  /// ปิดกั้นอุปกรณ์
  static void banDevice(String reason) {
    if (_deviceFingerprint != null) {
      _bannedDevices.add(_deviceFingerprint!);
      _saveSecurityData();
      print(
          '🚫 Device banned: ${_deviceFingerprint!.substring(0, 8)}... Reason: $reason');
    }
  }

  /// ตรวจสอบว่าอุปกรณ์ถูกปิดกั้นหรือไม่
  static bool isDeviceBanned() {
    return _deviceFingerprint != null &&
        _bannedDevices.contains(_deviceFingerprint);
  }

  /// รีเซ็ตข้อมูลการป้องกันสำหรับหน้าที่กำหนด
  static void resetPageSecurity(String pageId) {
    _pageActionHistory.remove(pageId);
    _pageSuspiciousCount.remove(pageId);
    _pageLastActivity.remove(pageId);
    _behaviorHistory.remove(pageId);
    print('🔄 Reset security data for page: $pageId');
  }

  /// เริ่มต้นระบบการป้องกัน
  static Future<void> initialize() async {
    await _generateDeviceFingerprint();
    await _loadSecurityData();
    print('🛡️ Smart Security Service initialized');
  }

  // ==================== PRIVATE METHODS ====================

  /// ดึงค่าการกำหนดสำหรับหน้า
  static PageSecurityConfig _getPageConfig(String pageId) {
    return _pageConfigs[pageId] ??
        const PageSecurityConfig(
          level: SecurityLevel.low,
          maxActionsPerMinute: 50,
        );
  }

  /// ตรวจสอบ Rate Limiting
  static SecurityCheck _checkRateLimit(String pageId, int maxActions) {
    final now = DateTime.now();
    final oneMinuteAgo = now.subtract(const Duration(minutes: 1));

    // กรองเฉพาะการกระทำในช่วง 1 นาทีที่ผ่านมา
    final recentActions = _pageActionHistory[pageId]
            ?.where((time) => time.isAfter(oneMinuteAgo))
            .toList() ??
        [];

    final actionCount = recentActions.length;
    final isExceeded = actionCount >= maxActions;

    if (isExceeded) {
      _incrementSuspiciousCount(pageId);
    }

    return SecurityCheck(
      type: 'rate_limit',
      isValid: !isExceeded,
      action: isExceeded ? SecurityAction.block : SecurityAction.allow,
      message: isExceeded
          ? 'Rate limit exceeded: $actionCount/$maxActions actions per minute'
          : 'Rate limit OK: $actionCount/$maxActions',
      details: {
        'current_actions': actionCount,
        'max_actions': maxActions,
        'time_window': '1 minute',
      },
    );
  }

  /// ตรวจสอบ Device Fingerprint
  static Future<SecurityCheck> _checkDeviceFingerprint(String pageId) async {
    if (_deviceFingerprint == null) {
      await _generateDeviceFingerprint();
    }

    final isBanned = _bannedDevices.contains(_deviceFingerprint);

    if (isBanned) {
      _incrementSuspiciousCount(pageId);
    }

    return SecurityCheck(
      type: 'device_fingerprint',
      isValid: !isBanned,
      action: isBanned ? SecurityAction.block : SecurityAction.allow,
      message: isBanned ? 'Device is banned' : 'Device fingerprint OK',
      details: {
        'fingerprint': _deviceFingerprint?.substring(0, 8),
        'is_banned': isBanned,
      },
    );
  }

  /// ตรวจสอบ Human Verification
  static SecurityCheck _checkHumanVerification(String pageId) {
    final suspiciousCount = _pageSuspiciousCount[pageId] ?? 0;
    final needsVerification = suspiciousCount >= 3;

    return SecurityCheck(
      type: 'human_verification',
      isValid: !needsVerification,
      action: needsVerification ? SecurityAction.verify : SecurityAction.allow,
      message: needsVerification
          ? 'Human verification required'
          : 'Human verification not needed',
      details: {
        'suspicious_count': suspiciousCount,
        'threshold': 3,
      },
    );
  }

  /// ตรวจสอบ Location Verification
  static Future<SecurityCheck> _checkLocationVerification(
      String pageId, Map<String, dynamic> context) async {
    // ตรวจสอบการกระโดดตำแหน่งที่ไม่สมจริง
    final currentLat = context['latitude'] as double?;
    final currentLng = context['longitude'] as double?;

    if (currentLat == null || currentLng == null) {
      return SecurityCheck(
        type: 'location_verification',
        isValid: true,
        action: SecurityAction.allow,
        message: 'No location data provided',
        details: {},
      );
    }

    // ตรวจสอบกับตำแหน่งก่อนหน้า (ถ้ามี)
    final behaviorHistory = _behaviorHistory[pageId] ?? [];
    if (behaviorHistory.isNotEmpty) {
      final lastLocation = behaviorHistory.last['context'];
      if (lastLocation != null &&
          lastLocation['latitude'] != null &&
          lastLocation['longitude'] != null) {
        final distance = Geolocator.distanceBetween(
          lastLocation['latitude'],
          lastLocation['longitude'],
          currentLat,
          currentLng,
        );

        final timeDiff = DateTime.now()
            .difference(behaviorHistory.last['timestamp'])
            .inMinutes;

        // ตรวจสอบความเร็วที่ไม่สมจริง (เกิน 1000 กม./ชม.)
        if (timeDiff > 0) {
          final speedKmh = (distance / 1000) / (timeDiff / 60);
          if (speedKmh > 1000) {
            _incrementSuspiciousCount(pageId);
            return SecurityCheck(
              type: 'location_verification',
              isValid: false,
              action: SecurityAction.warn,
              message: 'Unrealistic location change detected',
              details: {
                'distance_km': (distance / 1000).toStringAsFixed(1),
                'time_minutes': timeDiff,
                'speed_kmh': speedKmh.toStringAsFixed(1),
              },
            );
          }
        }
      }
    }

    return SecurityCheck(
      type: 'location_verification',
      isValid: true,
      action: SecurityAction.allow,
      message: 'Location verification passed',
      details: {
        'latitude': currentLat,
        'longitude': currentLng,
      },
    );
  }

  /// วิเคราะห์พฤติกรรม
  static SecurityCheck _analyzeBehavior(
      String pageId, Map<String, dynamic> context) {
    final history = _behaviorHistory[pageId] ?? [];

    if (history.length < 5) {
      return SecurityCheck(
        type: 'behavior_analysis',
        isValid: true,
        action: SecurityAction.allow,
        message: 'Insufficient data for behavior analysis',
        details: {'history_count': history.length},
      );
    }

    // วิเคราะห์รูปแบบการกระทำ
    final recentActions = history.length > 10
        ? history.skip(history.length - 10).toList()
        : history;
    final actionTypes = recentActions.map((h) => h['action']).toList();
    final uniqueActions = actionTypes.toSet().length;
    final totalActions = actionTypes.length;

    // ตรวจสอบการกระทำซ้ำมากเกินไป
    final repetitionRatio = uniqueActions / totalActions;
    final isRepetitive = repetitionRatio < 0.3; // ถ้าซ้ำเกิน 70%

    if (isRepetitive) {
      _incrementSuspiciousCount(pageId);
    }

    return SecurityCheck(
      type: 'behavior_analysis',
      isValid: !isRepetitive,
      action: isRepetitive ? SecurityAction.warn : SecurityAction.allow,
      message: isRepetitive
          ? 'Repetitive behavior pattern detected'
          : 'Behavior pattern normal',
      details: {
        'repetition_ratio': (repetitionRatio * 100).toInt(),
        'unique_actions': uniqueActions,
        'total_actions': totalActions,
      },
    );
  }

  /// ตรวจสอบ Session Timeout
  static SecurityCheck _checkSessionTimeout(String pageId, Duration timeout) {
    final lastActivity = _pageLastActivity[pageId];

    if (lastActivity == null) {
      return SecurityCheck(
        type: 'session_timeout',
        isValid: true,
        action: SecurityAction.allow,
        message: 'New session',
        details: {},
      );
    }

    final timeSinceLastActivity = DateTime.now().difference(lastActivity);
    final isExpired = timeSinceLastActivity > timeout;

    return SecurityCheck(
      type: 'session_timeout',
      isValid: !isExpired,
      action: isExpired ? SecurityAction.block : SecurityAction.allow,
      message: isExpired ? 'Session expired' : 'Session active',
      details: {
        'last_activity': lastActivity.toIso8601String(),
        'time_since_activity': timeSinceLastActivity.inMinutes,
        'timeout_minutes': timeout.inMinutes,
      },
    );
  }

  /// สร้าง Device Fingerprint
  static Future<void> _generateDeviceFingerprint() async {
    try {
      final platform = defaultTargetPlatform.name;
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      _deviceInfo.addAll({
        'platform': platform,
        'timestamp': timestamp,
      });

      final fingerprint = _deviceInfo.values.join('|');
      _deviceFingerprint = fingerprint.hashCode.toString();

      print(
          '🔍 Generated device fingerprint: ${_deviceFingerprint?.substring(0, 8)}...');
    } catch (e) {
      print('⚠️ Error generating device fingerprint: $e');
      _deviceFingerprint = 'unknown_device';
    }
  }

  /// เพิ่มจำนวนกิจกรรมน่าสงสัย
  static void _incrementSuspiciousCount(String pageId) {
    _pageSuspiciousCount[pageId] = (_pageSuspiciousCount[pageId] ?? 0) + 1;
    print(
        '🚨 Suspicious activity count for $pageId: ${_pageSuspiciousCount[pageId]}');
  }

  /// ทำความสะอาดข้อมูลเก่า
  static void _cleanupOldData(String pageId) {
    final now = DateTime.now();
    final oneHourAgo = now.subtract(const Duration(hours: 1));

    // ลบ action history ที่เก่าเกิน 1 ชั่วโมง
    _pageActionHistory[pageId]
        ?.removeWhere((time) => time.isBefore(oneHourAgo));

    // ลบ behavior history ที่เก่าเกิน 1 ชั่วโมง
    _behaviorHistory[pageId]?.removeWhere((item) {
      final timestamp = item['timestamp'] as DateTime;
      return timestamp.isBefore(oneHourAgo);
    });
  }

  /// บันทึกข้อมูลการป้องกัน
  static Future<void> _saveSecurityData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('banned_devices', _bannedDevices.toList());
    } catch (e) {
      print('⚠️ Error saving security data: $e');
    }
  }

  /// โหลดข้อมูลการป้องกัน
  static Future<void> _loadSecurityData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bannedDevices = prefs.getStringList('banned_devices') ?? [];
      _bannedDevices.addAll(bannedDevices);
    } catch (e) {
      print('⚠️ Error loading security data: $e');
    }
  }
}

// ==================== DATA CLASSES ====================

/// ผลการตรวจสอบการป้องกัน
class SecurityCheckResult {
  final String pageId;
  final SecurityLevel level;
  final bool isAllowed;
  final SecurityAction action;
  final List<SecurityCheck> checks;
  final DateTime timestamp;

  SecurityCheckResult({
    required this.pageId,
    required this.level,
    required this.isAllowed,
    required this.action,
    required this.checks,
    required this.timestamp,
  });

  /// หาการตรวจสอบที่ล้มเหลว
  List<SecurityCheck> get failedChecks =>
      checks.where((check) => !check.isValid).toList();

  /// หาการตรวจสอบที่ต้องการ Human Verification
  List<SecurityCheck> get verificationChecks =>
      checks.where((check) => check.action == SecurityAction.verify).toList();
}

/// การตรวจสอบการป้องกันแต่ละรายการ
class SecurityCheck {
  final String type;
  final bool isValid;
  final SecurityAction action;
  final String message;
  final Map<String, dynamic> details;

  SecurityCheck({
    required this.type,
    required this.isValid,
    required this.action,
    required this.message,
    required this.details,
  });
}

/// การกระทำที่ระบบควรทำ
enum SecurityAction {
  allow, // อนุญาต
  warn, // เตือน
  block, // ปิดกั้น
  verify, // ต้องยืนยันตัวตน
}

// ==================== UI COMPONENTS ====================

/// Dialog สำหรับ Human Verification
class _HumanVerificationDialog extends StatefulWidget {
  final String pageId;

  const _HumanVerificationDialog({required this.pageId});

  @override
  State<_HumanVerificationDialog> createState() =>
      _HumanVerificationDialogState();
}

class _HumanVerificationDialogState extends State<_HumanVerificationDialog> {
  final List<String> _emojis = ['🚗', '📱', '🏠', '🌟'];
  late String _correctEmoji;

  @override
  void initState() {
    super.initState();
    _correctEmoji = _emojis[DateTime.now().second % _emojis.length];
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Text('🤖'),
          SizedBox(width: 8),
          Text('ยืนยันตัวตนมนุษย์'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('กรุณาแตะที่ $_correctEmoji'),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            children: _emojis
                .map((emoji) => GestureDetector(
                      onTap: () => _onEmojiTap(emoji),
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child:
                              Text(emoji, style: const TextStyle(fontSize: 24)),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  void _onEmojiTap(String emoji) {
    final isCorrect = emoji == _correctEmoji;

    if (isCorrect) {
      // รีเซ็ตจำนวนกิจกรรมน่าสงสัย
      SmartSecurityService._pageSuspiciousCount[widget.pageId] = 0;
    } else {
      SmartSecurityService._incrementSuspiciousCount(widget.pageId);
    }

    Navigator.of(context).pop(isCorrect);
  }
}
