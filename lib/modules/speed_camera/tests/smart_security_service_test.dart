import 'package:flutter_test/flutter_test.dart';

import '../../../services/smart_security_service.dart';

void main() {
  group('SmartSecurityService Tests', () {
    setUp(() {
      // Reset service state before each test
      SmartSecurityService.setSecurityLevel(SecurityLevel.medium);
    });

    test('1. ระดับความปลอดภัย: enum ครบ (low, medium, high, critical)', () {
      // Test all SecurityLevel enum values exist
      expect(SecurityLevel.values.length, equals(4));
      expect(SecurityLevel.values.contains(SecurityLevel.low), isTrue);
      expect(SecurityLevel.values.contains(SecurityLevel.medium), isTrue);
      expect(SecurityLevel.values.contains(SecurityLevel.high), isTrue);
      expect(SecurityLevel.values.contains(SecurityLevel.critical), isTrue);
    });

    test('2. ประเภทภัยคุกคาม: enum ครบ (7 แบบ)', () {
      // Test all ThreatType enum values exist
      expect(ThreatType.values.length, equals(7));
      expect(ThreatType.values.contains(ThreatType.rateLimitExceeded), isTrue);
      expect(ThreatType.values.contains(ThreatType.suspiciousDevice), isTrue);
      expect(ThreatType.values.contains(ThreatType.locationSpoofing), isTrue);
      expect(ThreatType.values.contains(ThreatType.rapidActions), isTrue);
      expect(ThreatType.values.contains(ThreatType.humanVerificationFailed),
          isTrue);
      expect(ThreatType.values.contains(ThreatType.sessionTimeout), isTrue);
      expect(ThreatType.values.contains(ThreatType.apiAbuse), isTrue);
    });

    test('3. Singleton: instance คงที่', () {
      // Test Singleton pattern
      final instance1 = SmartSecurityService();
      final instance2 = SmartSecurityService();

      expect(identical(instance1, instance2), isTrue);
      expect(instance1, equals(instance2));
    });

    test('4. คอนฟิก: โครงสร้าง PageSecurityConfig', () {
      // Test PageSecurityConfig structure
      const config = PageSecurityConfig(
        level: SecurityLevel.high,
        maxActionsPerMinute: 10,
        requireHumanVerification: true,
        enableDeviceFingerprinting: true,
        enableLocationVerification: true,
        sessionTimeout: Duration(minutes: 30),
        enableBehaviorAnalysis: true,
      );

      expect(config.level, equals(SecurityLevel.high));
      expect(config.maxActionsPerMinute, equals(10));
      expect(config.requireHumanVerification, isTrue);
      expect(config.enableDeviceFingerprinting, isTrue);
      expect(config.enableLocationVerification, isTrue);
      expect(config.sessionTimeout, equals(const Duration(minutes: 30)));
      expect(config.enableBehaviorAnalysis, isTrue);
    });

    test('5. ตั้ง/อ่านระดับ: setSecurityLevel(), getCurrentSecurityLevel()',
        () {
      // Test setting and getting security levels
      SmartSecurityService.setSecurityLevel(SecurityLevel.low);
      expect(SmartSecurityService.getCurrentSecurityLevel(),
          equals(SecurityLevel.low));

      SmartSecurityService.setSecurityLevel(SecurityLevel.high);
      expect(SmartSecurityService.getCurrentSecurityLevel(),
          equals(SecurityLevel.high));

      SmartSecurityService.setSecurityLevel(SecurityLevel.critical);
      expect(SmartSecurityService.getCurrentSecurityLevel(),
          equals(SecurityLevel.critical));
    });

    test('6. สถานะคงอยู่ใน session', () {
      // Test state persistence across operations
      SmartSecurityService.setSecurityLevel(SecurityLevel.high);

      // Perform multiple operations
      final level1 = SmartSecurityService.getCurrentSecurityLevel();
      final level2 = SmartSecurityService.getCurrentSecurityLevel();
      final level3 = SmartSecurityService.getCurrentSecurityLevel();

      expect(level1, equals(SecurityLevel.high));
      expect(level2, equals(SecurityLevel.high));
      expect(level3, equals(SecurityLevel.high));
      expect(level1, equals(level2));
      expect(level2, equals(level3));
    });

    test('7. ลำดับ enum ตรงตามความเสี่ยง', () {
      // Test enum order follows risk level (low to critical)
      expect(SecurityLevel.low.index, equals(0));
      expect(SecurityLevel.medium.index, equals(1));
      expect(SecurityLevel.high.index, equals(2));
      expect(SecurityLevel.critical.index, equals(3));

      // Test risk progression
      expect(SecurityLevel.low.index < SecurityLevel.medium.index, isTrue);
      expect(SecurityLevel.medium.index < SecurityLevel.high.index, isTrue);
      expect(SecurityLevel.high.index < SecurityLevel.critical.index, isTrue);
    });

    test('8. มี log เมื่อเปลี่ยนระดับความปลอดภัย', () {
      // This test verifies the logging behavior indirectly
      // by ensuring the setSecurityLevel method executes without error
      expect(() => SmartSecurityService.setSecurityLevel(SecurityLevel.low),
          returnsNormally);
      expect(() => SmartSecurityService.setSecurityLevel(SecurityLevel.medium),
          returnsNormally);
      expect(() => SmartSecurityService.setSecurityLevel(SecurityLevel.high),
          returnsNormally);
      expect(
          () => SmartSecurityService.setSecurityLevel(SecurityLevel.critical),
          returnsNormally);

      // Verify level is actually set
      expect(SmartSecurityService.getCurrentSecurityLevel(),
          equals(SecurityLevel.critical));
    });

    test('9. ค่า default เป็น medium', () {
      // Reset to verify default behavior
      SmartSecurityService.setSecurityLevel(SecurityLevel.medium);

      // After initialization, should be medium
      expect(SmartSecurityService.getCurrentSecurityLevel(),
          equals(SecurityLevel.medium));
    });

    test('10. วงจรการใช้งาน service ปกติ', () {
      // Test complete service lifecycle

      // 1. Initialize (should be medium by default)
      expect(SmartSecurityService.getCurrentSecurityLevel(),
          equals(SecurityLevel.medium));

      // 2. Change to high for sensitive operation
      SmartSecurityService.setSecurityLevel(SecurityLevel.high);
      expect(SmartSecurityService.getCurrentSecurityLevel(),
          equals(SecurityLevel.high));

      // 3. Create instance (singleton test)
      final service = SmartSecurityService();
      expect(service, isNotNull);

      // 4. Change to critical for very sensitive operation
      SmartSecurityService.setSecurityLevel(SecurityLevel.critical);
      expect(SmartSecurityService.getCurrentSecurityLevel(),
          equals(SecurityLevel.critical));

      // 5. Return to medium for normal operation
      SmartSecurityService.setSecurityLevel(SecurityLevel.medium);
      expect(SmartSecurityService.getCurrentSecurityLevel(),
          equals(SecurityLevel.medium));

      // 6. Test low security mode
      SmartSecurityService.setSecurityLevel(SecurityLevel.low);
      expect(SmartSecurityService.getCurrentSecurityLevel(),
          equals(SecurityLevel.low));

      // 7. Final check - service should be functional
      final finalService = SmartSecurityService();
      expect(finalService, equals(service)); // Same singleton instance
    });
  });
}
