import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum AlertSoundType {
  none, // ไม่เล่นเสียง
  beep, // เสียงบี๊บ
  warning, // เสียงเตือนภัย
  tts, // เสียงพูด (Text-to-Speech)
}

class SoundManager {
  static final SoundManager _instance = SoundManager._internal();
  factory SoundManager() => _instance;
  SoundManager._internal();

  // Audio และ TTS instances
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _flutterTts = FlutterTts();

  AlertSoundType _currentSoundType =
      AlertSoundType.tts; // เปลี่ยนจาก beep เป็น tts
  bool _isSoundEnabled = true;

  static const String _soundTypeKey = 'alert_sound_type';
  static const String _soundEnabledKey = 'sound_enabled';

  // Getters
  AlertSoundType get currentSoundType => _currentSoundType;
  bool get isSoundEnabled => _isSoundEnabled;

  /// Initialize TTS และ load settings
  Future<void> initialize() async {
    await _initializeTts();
    await _loadSettings();
  }

  /// กำหนดค่า TTS
  Future<void> _initializeTts() async {
    await _flutterTts.setLanguage('th-TH');
    await _flutterTts.setSpeechRate(0.7); // เปลี่ยนจาก 0.6 เป็น 0.7
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  /// โหลดการตั้งค่าจาก SharedPreferences
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final soundTypeIndex =
        prefs.getInt(_soundTypeKey) ?? 3; // เปลี่ยนจาก 1 เป็น 3 (tts)
    _currentSoundType = AlertSoundType.values[soundTypeIndex];

    _isSoundEnabled = prefs.getBool(_soundEnabledKey) ?? true;
  }

  /// บันทึกการตั้งค่าลง SharedPreferences
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_soundTypeKey, _currentSoundType.index);
    await prefs.setBool(_soundEnabledKey, _isSoundEnabled);
  }

  /// เปลี่ยนประเภทเสียงแจ้งเตือน
  Future<void> setSoundType(AlertSoundType soundType) async {
    _currentSoundType = soundType;
    await _saveSettings();
  }

  /// เปิด/ปิดเสียงแจ้งเตือน
  Future<void> setSoundEnabled(bool enabled) async {
    _isSoundEnabled = enabled;
    await _saveSettings();
  }

  /// เล่นเสียงแจ้งเตือนความเร็ว
  Future<void> playSpeedAlert({
    required String message,
    int? currentSpeed,
    int? speedLimit,
  }) async {
    if (!_isSoundEnabled) return;

    switch (_currentSoundType) {
      case AlertSoundType.none:
        break;
      case AlertSoundType.beep:
        await _playBeepSound();
        break;
      case AlertSoundType.warning:
        await _playWarningSound();
        break;
      case AlertSoundType.tts:
        // ใช้ข้อความที่ส่งมาโดยตรง - ไม่สร้างใหม่
        await _speak(message);
        break;
    }
  }

  /// เล่นเสียงแจ้งเตือนเมื่อใกล้กล้อง
  Future<void> playProximityAlert({
    required String message,
    double? distance,
  }) async {
    if (!_isSoundEnabled) return;

    switch (_currentSoundType) {
      case AlertSoundType.none:
        break;
      case AlertSoundType.beep:
        await _playBeepSound();
        break;
      case AlertSoundType.warning:
        await _playWarningSound();
        break;
      case AlertSoundType.tts:
        String ttsMessage = message;
        if (distance != null) {
          final distanceText = distance >= 1000
              ? "${(distance / 1000).toStringAsFixed(1)} กิโลเมตร"
              : "${distance.round()} เมตร";
          ttsMessage = "กล้องจับความเร็วอยู่ห่างจากคุณ $distanceText";
        }
        await _speak(ttsMessage);
        break;
    }
  }

  /// เล่นเสียงแจ้งเตือนล่วงหน้า
  Future<void> playPredictiveAlert({
    required String message,
    String? roadName,
    int? speedLimit,
  }) async {
    if (!_isSoundEnabled) return;

    switch (_currentSoundType) {
      case AlertSoundType.none:
        break;
      case AlertSoundType.beep:
        await _playBeepSound();
        break;
      case AlertSoundType.warning:
        await _playWarningSound();
        break;
      case AlertSoundType.tts:
        String ttsMessage = message;
        if (roadName != null && speedLimit != null) {
          ttsMessage =
              "กำลังเข้าสู่ $roadName จำกัดความเร็ว $speedLimit กิโลเมตรต่อชั่วโมง";
        }
        await _speak(ttsMessage);
        break;
    }
  }

  /// เล่นเสียงบี๊บแบบ Progressive สำหรับระบบเรดาร์กล้อง
  Future<void> playProgressiveBeep() async {
    if (!_isSoundEnabled) return;

    switch (_currentSoundType) {
      case AlertSoundType.none:
        break;
      case AlertSoundType.beep:
      case AlertSoundType.warning:
        // เล่นเสียงบี๊บแบบเดี่ยวๆ (ไม่ใช่ 3 ครั้ง)
        await _playSingleBeep();
        break;
      case AlertSoundType.tts:
        // สำหรับ TTS ให้เล่นเสียงบี๊บแทน
        await _playSingleBeep();
        break;
    }
  }

  /// เล่นเสียงบี๊บ 3 ครั้งติดต่อกัน (ใช้ไฟล์เสียงจริง)
  Future<void> _playBeepSound() async {
    try {
      print('=== TRIPLE BEEP SOUND (REAL AUDIO) ===');

      // เล่นเสียงบี๊บ 3 ครั้งติดต่อกัน
      for (int i = 0; i < 3; i++) {
        await _audioPlayer.stop();
        await _audioPlayer.setVolume(1.0);
        await _audioPlayer.play(AssetSource('sounds/beep.wav'));
        print('BEEP ${i + 1}/3: Real audio file played successfully');

        // รอให้เสียงเล่นจบก่อนเล่นครั้งถัดไป (beep.wav ยาว 300ms + buffer 100ms)
        await Future.delayed(const Duration(milliseconds: 400));
      }
      print('TRIPLE BEEP: All 3 beeps completed successfully');
    } catch (e) {
      print('ERROR in _playBeepSound: $e');
      // ถ้าเล่นเสียงจริงไม่ได้ ให้ใช้ TTS สำรอง 3 ครั้ง
      try {
        await _flutterTts.setSpeechRate(1.2);
        await _flutterTts.setPitch(1.3);

        for (int i = 0; i < 3; i++) {
          await _flutterTts.speak('บี๊บ');
          await Future.delayed(const Duration(milliseconds: 600));
          print('TTS BEEP ${i + 1}/3: TTS fallback played successfully');
        }

        await _flutterTts.setSpeechRate(0.7);
        await _flutterTts.setPitch(1.0);
        print('TRIPLE BEEP: TTS fallback completed successfully');
      } catch (e2) {
        print('ERROR in TTS fallback: $e2');
      }
    }
  }

  /// เล่นเสียงบี๊บครั้งเดียว สำหรับ Progressive Beep
  Future<void> _playSingleBeep() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setVolume(0.8); // ลดเสียงเล็กน้อยสำหรับ Progressive
      await _audioPlayer.play(AssetSource('sounds/beep.wav'));
    } catch (e) {
      print('ERROR in _playSingleBeep: $e');
      // ถ้าเล่นเสียงจริงไม่ได้ ให้ใช้ TTS สำรอง
      try {
        await _flutterTts.setSpeechRate(1.5);
        await _flutterTts.setPitch(1.2);
        await _flutterTts.speak('บี๊บ');
        await _flutterTts.setSpeechRate(0.7);
        await _flutterTts.setPitch(1.0);
      } catch (e2) {
        print('ERROR in single beep TTS fallback: $e2');
      }
    }
  }

  /// เล่นเสียงเตือนภัย (ใช้ไฟล์เสียงจริง)
  Future<void> _playWarningSound() async {
    try {
      print('=== WARNING SOUND (REAL AUDIO) ===');

      await _audioPlayer.stop();
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.play(AssetSource('sounds/warning.wav'));
      print('WARNING: Real audio file played successfully');
    } catch (e) {
      print('ERROR in _playWarningSound: $e');
      // ถ้าเล่นเสียงจริงไม่ได้ ให้ใช้ TTS สำรอง
      try {
        await _flutterTts.setSpeechRate(0.8);
        await _flutterTts.setPitch(0.8);
        await _flutterTts.speak('เตือนภัย');
        await Future.delayed(const Duration(milliseconds: 800));
        await _flutterTts.setSpeechRate(0.7);
        await _flutterTts.setPitch(1.0);
        print('WARNING: TTS fallback played successfully');
      } catch (e2) {
        print('ERROR in TTS fallback: $e2');
      }
    }
  }

  /// พูดข้อความ
  Future<void> _speak(String message) async {
    try {
      await _flutterTts.speak(message);
    } catch (e) {
      print('Error speaking message: $e');
    }
  }

  /// ทดสอบเสียง
  Future<void> testSound(AlertSoundType soundType) async {
    final originalType = _currentSoundType;
    final originalEnabled = _isSoundEnabled;

    _currentSoundType = soundType;
    _isSoundEnabled = true;

    print('Testing sound type: $soundType');

    try {
      switch (soundType) {
        case AlertSoundType.beep:
          await _playBeepSound();
          break;
        case AlertSoundType.warning:
          await _playWarningSound();
          break;
        case AlertSoundType.tts:
          await _speak("ทดสอบเสียงภาษาไทย");
          break;
        case AlertSoundType.none:
          print('No sound test for none type');
          break;
      }
    } catch (e) {
      print('Error testing sound: $e');
    }

    // คืนค่าเดิม
    _currentSoundType = originalType;
    _isSoundEnabled = originalEnabled;
  }

  /// ทดสอบไฟล์เสียงโดยตรง (สำหรับ debug)
  Future<void> testDirectSound(String soundFile) async {
    try {
      print('=== DIRECT SOUND TEST: $soundFile ===');
      print('Audio player state before play: ${_audioPlayer.state}');

      // ตรวจสอบไฟล์ก่อนเล่น
      print('Testing asset path: assets/sounds/$soundFile');

      await _audioPlayer.stop();
      await Future.delayed(const Duration(milliseconds: 100));
      await _audioPlayer.setVolume(1.0); // ตั้งระดับเสียงเต็ม

      // ลองเล่นด้วยวิธีต่างกัน
      try {
        await _audioPlayer.play(AssetSource('sounds/$soundFile'));
        print('SUCCESS: AssetSource method worked for $soundFile');
      } catch (e1) {
        print('FAILED: AssetSource method: $e1');

        // ลองวิธีอื่น
        try {
          await _audioPlayer.play(AssetSource(soundFile));
          print('SUCCESS: Direct file method worked for $soundFile');
        } catch (e2) {
          print('FAILED: Direct file method: $e2');
        }
      }

      print('Audio player state after play: ${_audioPlayer.state}');

      // รอให้เสียงเล่นจบ
      await Future.delayed(const Duration(milliseconds: 1000));
      print('Direct sound test completed for: $soundFile');
    } catch (e) {
      print('CRITICAL ERROR in direct sound test for $soundFile: $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }

  /// ทดสอบเสียงทั้งหมดพร้อมกัน
  Future<void> testAllSounds() async {
    print('=== SoundManager: Testing ALL sounds ===');
    print('Current sound enabled: $_isSoundEnabled');
    print('Current sound type: $_currentSoundType');
    print('NOTE: beep และ warning ใช้เสียงจริง, TTS ใช้สำหรับอ่านข้อมูลกล้อง');

    try {
      // ทดสอบเสียงบี๊บ (เสียงจริง)
      print('\n--- Testing beep sound (REAL AUDIO) ---');
      await _playBeepSound();
      await Future.delayed(const Duration(seconds: 2));

      // ทดสอบเสียงเตือน (เสียงจริง)
      print('\n--- Testing warning sound (REAL AUDIO) ---');
      await _playWarningSound();
      await Future.delayed(const Duration(seconds: 2));

      // ทดสอบเสียง TTS สำหรับอ่านข้อมูลกล้อง
      print('\n--- Testing TTS for camera information ---');
      await _flutterTts.speak(
          'กล้องจับความเร็วข้างหน้า จำกัดความเร็ว 90 กิโลเมตรต่อชั่วโมง');

      print('\n=== All sound tests completed ===');
      print('✅ เสียงจริงสำหรับ beep และ warning');
      print('✅ เสียงพูดสำหรับข้อมูลกล้อง');
    } catch (e) {
      print('ERROR in testAllSounds: $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }

  /// ปิดการทำงาน
  Future<void> dispose() async {
    await _audioPlayer.dispose();
    await _flutterTts.stop();
  }
}

/// Extension สำหรับ AlertSoundType
extension AlertSoundTypeExtension on AlertSoundType {
  /// ชื่อแสดงผลภาษาไทย
  String get displayName {
    switch (this) {
      case AlertSoundType.none:
        return 'ปิดเสียง';
      case AlertSoundType.beep:
        return 'เสียงบี๊บจริง';
      case AlertSoundType.warning:
        return 'เสียงเตือนภัยจริง';
      case AlertSoundType.tts:
        return 'เสียงพูด';
    }
  }

  /// ไอคอนแสดงผล
  String get iconName {
    switch (this) {
      case AlertSoundType.none:
        return 'volume_off';
      case AlertSoundType.beep:
        return 'volume_up';
      case AlertSoundType.warning:
        return 'warning';
      case AlertSoundType.tts:
        return 'record_voice_over';
    }
  }

  /// คำอธิบาย
  String get description {
    switch (this) {
      case AlertSoundType.none:
        return 'ไม่มีเสียงแจ้งเตือน';
      case AlertSoundType.beep:
        return 'เสียงบี๊บจริงๆ (ไม่ใช่เสียงพูด)';
      case AlertSoundType.warning:
        return 'เสียงเตือนภัยจริงๆ (แบบไซเรน)';
      case AlertSoundType.tts:
        return 'อ่านข้อความเป็นเสียงพูด';
    }
  }
}
