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

  AlertSoundType _currentSoundType = AlertSoundType.beep;
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
    await _flutterTts.setSpeechRate(0.8);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  /// โหลดการตั้งค่าจาก SharedPreferences
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final soundTypeIndex = prefs.getInt(_soundTypeKey) ?? 1;
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
        String ttsMessage = message;
        if (currentSpeed != null && speedLimit != null) {
          ttsMessage =
              "ความเร็วปัจจุบัน $currentSpeed กิโลเมตรต่อชั่วโมง เกินกำหนด $speedLimit กิโลเมตรต่อชั่วโมง";
        }
        await _speak(ttsMessage);
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

  /// เล่นเสียงบี๊บ
  Future<void> _playBeepSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/beep.mp3'));
    } catch (e) {
      print('Error playing beep sound: $e');
    }
  }

  /// เล่นเสียงเตือนภัย
  Future<void> _playWarningSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/warning.mp3'));
    } catch (e) {
      print('Error playing warning sound: $e');
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

    await playSpeedAlert(
      message: "ทดสอบเสียงแจ้งเตือน",
      currentSpeed: 85,
      speedLimit: 80,
    );

    // คืนค่าเดิม
    _currentSoundType = originalType;
    _isSoundEnabled = originalEnabled;
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
        return 'เสียงบี๊บ';
      case AlertSoundType.warning:
        return 'เสียงเตือนภัย';
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
        return 'เสียงบี๊บสั้นๆ';
      case AlertSoundType.warning:
        return 'เสียงเตือนภัยแบบไซเรน';
      case AlertSoundType.tts:
        return 'อ่านข้อความเป็นเสียงพูด';
    }
  }
}
