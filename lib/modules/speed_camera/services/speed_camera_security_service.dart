import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

/// Security service เฉพาะสำหรับ Speed Camera Screen
/// ป้องกันการใช้งานในทางที่ผิดและการหลีกเลี่ยงกฎหมาย
class SpeedCameraSecurityService {
  // ==================== ANTI-EVASION CONSTANTS ====================

  // การใช้งานที่น่าสงสัย
  static const int MAX_CONTINUOUS_HOURS = 12; // ใช้งานต่อเนื่องเกิน 12 ชั่วโมง
  static const int MAX_HIGH_SPEED_ALERTS =
      20; // แจ้งเตือนความเร็วสูงเกิน 20 ครั้ง/ชั่วโมง
  static const int MAX_LOCATION_JUMPS =
      5; // GPS กระโดดตำแหน่งเกิน 5 ครั้ง/ชั่วโมง
  static const double SUSPICIOUS_SPEED_THRESHOLD =
      180.0; // ความเร็วต้องสงสัย กม./ชม.
  static const double LOCATION_JUMP_THRESHOLD =
      2000.0; // การกระโดดตำแหน่งเกิน 2 กม.

  // Rate limiting
  static const int MAX_MAP_INTERACTIONS =
      1000; // การโต้ตอบแผนที่ต่อนาที (เพิ่มจาก 100 เป็น 1000)
  static const int MAX_BEEP_REQUESTS = 60; // คำขอเสียงแจ้งเตือนต่อนาที

  // ==================== TRACKING VARIABLES ====================

  static DateTime _sessionStartTime = DateTime.now();
  static int _highSpeedAlertCount = 0;
  static int _locationJumpCount = 0;
  static int _mapInteractionCount = 0;
  static int _beepRequestCount = 0;
  static int _totalViolationScore = 0;

  static final List<Position> _speedHistory = [];
  static final List<DateTime> _highSpeedEvents = [];
  static final List<DateTime> _locationJumpEvents = [];

  static Timer? _hourlyResetTimer;
  static Timer? _behaviorAnalysisTimer;

  // ==================== INITIALIZATION ====================

  /// เริ่มต้นระบบความปลอดภัย
  static void initialize() {
    _sessionStartTime = DateTime.now();
    _resetCounters();
    _startPeriodicResets();
    _startBehaviorAnalysis();

    if (kDebugMode) {
      debugPrint('🔒 Speed Camera Security Service initialized');
      debugPrint('🔒 Session started at: $_sessionStartTime');
    }
  }

  /// เริ่ม timer สำหรับรีเซ็ตตัวนับแบบ periodic
  static void _startPeriodicResets() {
    // รีเซ็ตตัวนับทุกชั่วโมง
    _hourlyResetTimer = Timer.periodic(const Duration(hours: 1), (timer) {
      _resetHourlyCounters();
    });
  }

  /// เริ่มการวิเคราะห์พฤติกรรมผู้ใช้
  static void _startBehaviorAnalysis() {
    // วิเคราะห์พฤติกรรมทุก 5 นาที
    _behaviorAnalysisTimer =
        Timer.periodic(const Duration(minutes: 5), (timer) {
      _analyzeBehaviorPattern();
    });
  }

  // ==================== MAIN VALIDATION FUNCTIONS ====================

  /// ตรวจสอบความปลอดภัยของ GPS data
  static SecurityCheckResult validateGPSData(Position position) {
    final result = SecurityCheckResult();

    // ตรวจสอบ 1: พิกัดอยู่ในขอบเขตที่สมเหตุสมผล
    if (!_isValidCoordinates(position.latitude, position.longitude)) {
      result.addViolation('invalid_coordinates',
          'GPS coordinates outside reasonable bounds: ${position.latitude}, ${position.longitude}');
    }

    // ตรวจสอบ 2: ความเร็วสมเหตุสมผล
    final speedKmh = position.speed * 3.6;
    if (speedKmh > SUSPICIOUS_SPEED_THRESHOLD) {
      result.addViolation(
          'suspicious_speed', 'Unrealistic speed: ${speedKmh.toInt()} km/h');
      _trackHighSpeedEvent(speedKmh);
    }

    // ตรวจสอบ 3: การกระโดดตำแหน่ง
    if (_speedHistory.isNotEmpty) {
      final lastPosition = _speedHistory.last;
      final distance = Geolocator.distanceBetween(
        lastPosition.latitude,
        lastPosition.longitude,
        position.latitude,
        position.longitude,
      );

      final timeDiff =
          position.timestamp.difference(lastPosition.timestamp).inSeconds;
      if (distance > LOCATION_JUMP_THRESHOLD && timeDiff < 60) {
        result.addViolation('location_jump',
            'Impossible location jump: ${distance.toInt()}m in ${timeDiff}s');
        _trackLocationJumpEvent();
      }
    }

    // ตรวจสอบ 4: ความถี่ของข้อมูล GPS
    if (!_isValidGPSFrequency(position)) {
      result.addViolation('gps_frequency', 'GPS data frequency suspicious');
    }

    // เก็บประวัติ GPS
    _speedHistory.add(position);
    if (_speedHistory.length > 100) {
      _speedHistory.removeAt(0);
    }

    return result;
  }

  /// ตรวจสอบการใช้งานที่ผิดปกติ
  static SecurityCheckResult checkUsagePattern() {
    final result = SecurityCheckResult();
    final now = DateTime.now();
    final sessionDuration = now.difference(_sessionStartTime);

    // ตรวจสอบ 1: ใช้งานนานเกินไป
    if (sessionDuration.inHours > MAX_CONTINUOUS_HOURS) {
      result.addViolation('excessive_usage',
          'Continuous usage for ${sessionDuration.inHours} hours');
    }

    // ตรวจสอบ 2: การแจ้งเตือนความเร็วสูงบ่อยเกินไป
    if (_highSpeedAlertCount > MAX_HIGH_SPEED_ALERTS) {
      result.addViolation('excessive_speed_alerts',
          'High speed alerts: $_highSpeedAlertCount/hour');
    }

    // ตรวจสอบ 3: การกระโดดตำแหน่งบ่อยเกินไป
    if (_locationJumpCount > MAX_LOCATION_JUMPS) {
      result.addViolation('excessive_location_jumps',
          'Location jumps: $_locationJumpCount/hour');
    }

    // ตรวจสอบ 4: การโต้ตอบแผนที่มากเกินไป
    if (_mapInteractionCount > MAX_MAP_INTERACTIONS) {
      result.addViolation('excessive_map_interaction',
          'Map interactions: $_mapInteractionCount/minute');
    }

    return result;
  }

  /// ตรวจสอบก่อนเล่นเสียงแจ้งเตือน
  static bool canPlayAlert() {
    _beepRequestCount++;

    if (_beepRequestCount > MAX_BEEP_REQUESTS) {
      if (kDebugMode) {
        debugPrint(
            '🚨 Alert blocked: Too many beep requests ($_beepRequestCount/min)');
      }
      return false;
    }

    if (_totalViolationScore > 50) {
      if (kDebugMode) {
        debugPrint(
            '🚨 Alert blocked: High violation score ($_totalViolationScore)');
      }
      return false;
    }

    return true;
  }

  /// บันทึกการโต้ตอบแผนที่
  static void recordMapInteraction() {
    _mapInteractionCount++;

    if (_mapInteractionCount > MAX_MAP_INTERACTIONS) {
      if (kDebugMode) {
        debugPrint(
            '⚠️ Excessive map interaction detected: $_mapInteractionCount');
      }
    }
  }

  // ==================== HELPER FUNCTIONS ====================

  /// ตรวจสอบพิกัดที่ถูกต้อง
  static bool _isValidCoordinates(double lat, double lng) {
    // ประเทศไทย + buffer สำหรับพื้นที่ใกล้เคียง
    return lat >= 4.0 && lat <= 22.0 && lng >= 96.0 && lng <= 107.0;
  }

  /// ตรวจสอบความถี่ของข้อมูล GPS
  static bool _isValidGPSFrequency(Position position) {
    if (_speedHistory.isEmpty) return true;

    final lastPosition = _speedHistory.last;
    final timeDiff =
        position.timestamp.difference(lastPosition.timestamp).inMilliseconds;

    // ข้อมูล GPS มาเร็วเกินไป (< 500ms) หรือช้าเกินไป (> 30s)
    return timeDiff >= 500 && timeDiff <= 30000;
  }

  /// ติดตามเหตุการณ์ความเร็วสูง
  static void _trackHighSpeedEvent(double speed) {
    final now = DateTime.now();
    _highSpeedEvents.add(now);
    _highSpeedAlertCount++;

    // ลบเหตุการณ์เก่าที่เกิน 1 ชั่วโมง
    _highSpeedEvents.removeWhere((time) => now.difference(time).inHours >= 1);

    if (kDebugMode) {
      debugPrint(
          '🚨 High speed event: ${speed.toInt()} km/h (Total: $_highSpeedAlertCount)');
    }
  }

  /// ติดตามเหตุการณ์การกระโดดตำแหน่ง
  static void _trackLocationJumpEvent() {
    final now = DateTime.now();
    _locationJumpEvents.add(now);
    _locationJumpCount++;

    // ลบเหตุการณ์เก่าที่เกิน 1 ชั่วโมง
    _locationJumpEvents
        .removeWhere((time) => now.difference(time).inHours >= 1);

    if (kDebugMode) {
      debugPrint('🚨 Location jump event (Total: $_locationJumpCount)');
    }
  }

  /// วิเคราะห์พฤติกรรมผู้ใช้
  static void _analyzeBehaviorPattern() {
    final sessionDuration =
        DateTime.now().difference(_sessionStartTime).inMinutes;

    // คำนวณ pattern score
    int patternScore = 0;

    if (_highSpeedAlertCount > 10) patternScore += 20;
    if (_locationJumpCount > 3) patternScore += 30;
    if (sessionDuration > 480) patternScore += 25; // > 8 ชั่วโมง
    if (_mapInteractionCount > 50) patternScore += 15;

    _totalViolationScore = patternScore;

    if (kDebugMode && patternScore > 30) {
      debugPrint(
          '⚠️ Suspicious behavior pattern detected (Score: $patternScore)');
      debugPrint('   - High speed alerts: $_highSpeedAlertCount');
      debugPrint('   - Location jumps: $_locationJumpCount');
      debugPrint('   - Session duration: ${sessionDuration}min');
      debugPrint('   - Map interactions: $_mapInteractionCount');
    }
  }

  // ==================== RESET FUNCTIONS ====================

  /// รีเซ็ตตัวนับทั้งหมด
  static void _resetCounters() {
    _highSpeedAlertCount = 0;
    _locationJumpCount = 0;
    _mapInteractionCount = 0;
    _beepRequestCount = 0;
    _totalViolationScore = 0;
    _speedHistory.clear();
    _highSpeedEvents.clear();
    _locationJumpEvents.clear();
  }

  /// รีเซ็ตตัวนับรายชั่วโมง
  static void _resetHourlyCounters() {
    _highSpeedAlertCount = 0;
    _locationJumpCount = 0;

    if (kDebugMode) {
      debugPrint('🔄 Hourly counters reset');
    }
  }

  /// รีเซ็ตตัวนับรายนาที
  static void resetMinuteCounters() {
    _mapInteractionCount = 0;
    _beepRequestCount = 0;
  }

  // ==================== STATUS & CLEANUP ====================

  /// ดูสถานะปัจจุบัน
  static Map<String, dynamic> getSecurityStatus() {
    final sessionDuration = DateTime.now().difference(_sessionStartTime);

    return {
      'session_duration_hours': sessionDuration.inHours,
      'high_speed_alerts': _highSpeedAlertCount,
      'location_jumps': _locationJumpCount,
      'map_interactions': _mapInteractionCount,
      'beep_requests': _beepRequestCount,
      'violation_score': _totalViolationScore,
      'is_suspicious': _totalViolationScore > 30,
    };
  }

  /// ล้างข้อมูลและปิดระบบ
  static void dispose() {
    _hourlyResetTimer?.cancel();
    _behaviorAnalysisTimer?.cancel();
    _resetCounters();

    if (kDebugMode) {
      debugPrint('🔒 Speed Camera Security Service disposed');
      final sessionDuration = DateTime.now().difference(_sessionStartTime);
      debugPrint(
          '🔒 Total session duration: ${sessionDuration.inMinutes} minutes');
    }
  }
}

// ==================== SECURITY CHECK RESULT CLASS ====================

/// ผลลัพธ์ของการตรวจสอบความปลอดภัย
class SecurityCheckResult {
  final List<SecurityViolation> violations = [];

  bool get isValid => violations.isEmpty;
  bool get hasCriticalViolations => violations.any((v) => v.isCritical);

  void addViolation(String type, String description,
      {bool isCritical = false}) {
    violations.add(SecurityViolation(type, description, isCritical));

    if (kDebugMode) {
      final icon = isCritical ? '🚨' : '⚠️';
      debugPrint('$icon Security violation: $type - $description');
    }
  }

  @override
  String toString() {
    if (isValid) return 'SecurityCheck: PASSED';

    return 'SecurityCheck: FAILED (${violations.length} violations)';
  }
}

/// การละเมิดความปลอดภัย
class SecurityViolation {
  final String type;
  final String description;
  final bool isCritical;
  final DateTime timestamp;

  SecurityViolation(this.type, this.description, this.isCritical)
      : timestamp = DateTime.now();

  @override
  String toString() {
    return '${isCritical ? 'CRITICAL' : 'WARNING'}: $type - $description';
  }
}
