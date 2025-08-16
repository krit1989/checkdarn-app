import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../services/sound_manager.dart';

void main() {
  group('SoundManager Tests', () {
    setUpAll(() {
      // ตั้งค่า Flutter binding ในเทส
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() {
      // Reset any platform channel method calls
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/shared_preferences'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'getAll') {
            return <String, dynamic>{};
          }
          return null;
        },
      );

      // Mock AudioPlayer platform channels
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('xyz.luan/audioplayers.global'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'init') {
            return null;
          }
          return null;
        },
      );

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('xyz.luan/audioplayers'),
        (MethodCall methodCall) async {
          return null;
        },
      );

      // Mock Flutter TTS platform channel
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter_tts'),
        (MethodCall methodCall) async {
          return null;
        },
      );
    });

    tearDown(() {
      // Clean up platform channels after each test
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/shared_preferences'),
        null,
      );

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('xyz.luan/audioplayers.global'),
        null,
      );

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('xyz.luan/audioplayers'),
        null,
      );

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter_tts'),
        null,
      );
    });

    test('1. ประเภทเสียง: enum ครบ (none, beep, warning, tts)', () {
      // Test all AlertSoundType enum values exist
      expect(AlertSoundType.values.length, equals(4));
      expect(AlertSoundType.values.contains(AlertSoundType.none), isTrue);
      expect(AlertSoundType.values.contains(AlertSoundType.beep), isTrue);
      expect(AlertSoundType.values.contains(AlertSoundType.warning), isTrue);
      expect(AlertSoundType.values.contains(AlertSoundType.tts), isTrue);
    });

    test('2. ทำงานกับ enum: เทียบค่า, แปลง string, ใช้ใน collection/switch',
        () {
      // Test enum comparison
      expect(AlertSoundType.none == AlertSoundType.none, isTrue);
      expect(AlertSoundType.beep != AlertSoundType.tts, isTrue);

      // Test string conversion
      expect(AlertSoundType.none.toString(), equals('AlertSoundType.none'));
      expect(AlertSoundType.beep.toString(), equals('AlertSoundType.beep'));
      expect(
          AlertSoundType.warning.toString(), equals('AlertSoundType.warning'));
      expect(AlertSoundType.tts.toString(), equals('AlertSoundType.tts'));

      // Test in collection
      final soundTypes = {AlertSoundType.none, AlertSoundType.beep};
      expect(soundTypes.contains(AlertSoundType.none), isTrue);
      expect(soundTypes.contains(AlertSoundType.tts), isFalse);

      // Test in switch (simulate switch logic)
      String getSoundName(AlertSoundType type) {
        switch (type) {
          case AlertSoundType.none:
            return 'silent';
          case AlertSoundType.beep:
            return 'beep';
          case AlertSoundType.warning:
            return 'warning';
          case AlertSoundType.tts:
            return 'voice';
        }
      }

      expect(getSoundName(AlertSoundType.none), equals('silent'));
      expect(getSoundName(AlertSoundType.beep), equals('beep'));
      expect(getSoundName(AlertSoundType.warning), equals('warning'));
      expect(getSoundName(AlertSoundType.tts), equals('voice'));
    });

    test('3. ตรวจ index ของ enum ต่อเนื่อง (0,1,2,3)', () {
      // Test enum indices are continuous
      expect(AlertSoundType.none.index, equals(0));
      expect(AlertSoundType.beep.index, equals(1));
      expect(AlertSoundType.warning.index, equals(2));
      expect(AlertSoundType.tts.index, equals(3));

      // Test continuity
      expect(AlertSoundType.beep.index - AlertSoundType.none.index, equals(1));
      expect(
          AlertSoundType.warning.index - AlertSoundType.beep.index, equals(1));
      expect(
          AlertSoundType.tts.index - AlertSoundType.warning.index, equals(1));
    });

    test('4. type safety ของ enum', () {
      // Test enum type safety
      AlertSoundType soundType = AlertSoundType.tts;
      expect(soundType.toString(), contains('AlertSoundType'));
      expect(soundType is! String, isTrue);
      expect(soundType is! int, isTrue);

      // Test enum value assignment
      soundType = AlertSoundType.beep;
      expect(soundType, equals(AlertSoundType.beep));

      // Test enum in generic collections
      List<AlertSoundType> soundTypes = [
        AlertSoundType.none,
        AlertSoundType.beep,
        AlertSoundType.warning,
        AlertSoundType.tts,
      ];
      expect(soundTypes.length, equals(4));
      expect(soundTypes.every((type) => type.index >= 0), isTrue);
    });

    test('5. ไม่ผูกกับแพลตฟอร์ม: ไม่ต้องใช้ AudioPlayer/TTS จริง', () {
      // Test that SoundManager can be instantiated without real platform dependencies
      expect(() => SoundManager(), returnsNormally);

      // Test singleton pattern
      final manager1 = SoundManager();
      final manager2 = SoundManager();
      expect(identical(manager1, manager2), isTrue);

      // Test that we can access enum properties without platform calls
      expect(manager1.currentSoundType.toString(), contains('AlertSoundType'));
      expect(manager1.isSoundEnabled, isA<bool>());
    });

    test('6. ตั้งค่า Flutter binding ในเทส', () {
      // Test that Flutter binding is properly set up
      expect(TestWidgetsFlutterBinding.ensureInitialized(), isNotNull);
      expect(WidgetsBinding.instance, isNotNull);

      // Test platform channel handling is working
      expect(TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger,
          isNotNull);
    });

    test('7. ครอบคลุมการใช้งานจริง - enum operations', () {
      // Test realistic enum usage scenarios

      // Scenario 1: User selects sound type
      AlertSoundType userSelection = AlertSoundType.tts;
      expect(userSelection, equals(AlertSoundType.tts));

      // Scenario 2: Filtering available sound types
      final availableSounds = AlertSoundType.values
          .where((type) => type != AlertSoundType.none)
          .toList();
      expect(availableSounds.length, equals(3));
      expect(availableSounds.contains(AlertSoundType.none), isFalse);

      // Scenario 3: Sound type validation
      bool isValidSoundType(dynamic value) {
        return value is AlertSoundType && AlertSoundType.values.contains(value);
      }

      expect(isValidSoundType(AlertSoundType.beep), isTrue);
      expect(isValidSoundType('beep'), isFalse);
      expect(isValidSoundType(999), isFalse);
    });

    test('8. ครอบคลุมการใช้งานจริง - SoundManager basic operations', () {
      // Test SoundManager can be created and basic properties accessed
      final soundManager = SoundManager();

      // Test initial state (without platform calls)
      expect(soundManager.currentSoundType, isA<AlertSoundType>());
      expect(soundManager.isSoundEnabled, isA<bool>());

      // Test singleton consistency
      final anotherInstance = SoundManager();
      expect(soundManager.currentSoundType,
          equals(anotherInstance.currentSoundType));
      expect(
          soundManager.isSoundEnabled, equals(anotherInstance.isSoundEnabled));
    });

    test('9. ครอบคลุมการใช้งานจริง - enum index persistence', () {
      // Test that enum index can be used for persistence (like SharedPreferences)
      final soundType = AlertSoundType.warning;
      final index = soundType.index;

      // Simulate saving to persistence
      expect(index, equals(2));

      // Simulate loading from persistence
      final restoredType = AlertSoundType.values[index];
      expect(restoredType, equals(AlertSoundType.warning));
      expect(restoredType, equals(soundType));

      // Test all enum values can be persisted and restored
      for (final type in AlertSoundType.values) {
        final savedIndex = type.index;
        final restored = AlertSoundType.values[savedIndex];
        expect(restored, equals(type));
      }
    });

    test('10. ครอบคลุมการใช้งานจริง - complete workflow', () {
      // Test complete workflow without platform dependencies

      // 1. Create SoundManager instance
      final soundManager = SoundManager();
      expect(soundManager, isNotNull);

      // 2. Check default values
      expect(soundManager.currentSoundType, isA<AlertSoundType>());
      expect(soundManager.isSoundEnabled, isA<bool>());

      // 3. Test enum operations in realistic context
      final allSoundTypes = AlertSoundType.values;
      expect(allSoundTypes.length, equals(4));

      // 4. Test sound type categorization
      final silentTypes =
          allSoundTypes.where((type) => type == AlertSoundType.none);
      final audibleTypes =
          allSoundTypes.where((type) => type != AlertSoundType.none);
      expect(silentTypes.length, equals(1));
      expect(audibleTypes.length, equals(3));

      // 5. Test enum comparison in realistic scenario
      bool isSilentMode(AlertSoundType type) => type == AlertSoundType.none;
      bool isVoiceMode(AlertSoundType type) => type == AlertSoundType.tts;

      expect(isSilentMode(AlertSoundType.none), isTrue);
      expect(isSilentMode(AlertSoundType.beep), isFalse);
      expect(isVoiceMode(AlertSoundType.tts), isTrue);
      expect(isVoiceMode(AlertSoundType.warning), isFalse);

      // 6. Verify singleton pattern maintains consistency
      final secondInstance = SoundManager();
      expect(identical(soundManager, secondInstance), isTrue);
    });
  });
}
