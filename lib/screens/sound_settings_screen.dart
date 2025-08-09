import 'package:flutter/material.dart';
import '../services/sound_manager.dart';
import '../generated/gen_l10n/app_localizations.dart';

class SoundSettingsScreen extends StatefulWidget {
  const SoundSettingsScreen({super.key});

  @override
  State<SoundSettingsScreen> createState() => _SoundSettingsScreenState();
}

class _SoundSettingsScreenState extends State<SoundSettingsScreen> {
  final SoundManager _soundManager = SoundManager();
  late AlertSoundType _selectedSoundType;
  late bool _isSoundEnabled;

  @override
  void initState() {
    super.initState();
    _selectedSoundType = _soundManager.currentSoundType;
    _isSoundEnabled = _soundManager.isSoundEnabled;

    // ถ้าค่าปัจจุบันเป็น beep หรือ warning ให้เปลี่ยนเป็น tts อัตโนมัติ
    if (_selectedSoundType == AlertSoundType.beep ||
        _selectedSoundType == AlertSoundType.warning) {
      _selectedSoundType = AlertSoundType.tts;
      // บันทึกการเปลี่ยนแปลงลง SoundManager
      _soundManager.setSoundType(AlertSoundType.tts);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFEDF0F7), // เปลี่ยนให้เหมือนกับ settings screen
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).soundSettingsTitle,
          style: const TextStyle(
            fontFamily: 'NotoSansThai',
            fontWeight: FontWeight.w600,
            color: Colors.black, // เปลี่ยนเป็นสีดำ
          ),
        ),
        centerTitle: true, // ให้ข้อความอยู่กลาง
        backgroundColor: const Color(
            0xFFFDC621), // เปลี่ยนเป็นสีเหลืองแบบเดียวกับ list screen
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.black, // เปลี่ยนเป็นสีดำ
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        // เปลี่ยนจาก Container เป็น SingleChildScrollView
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // เปิด/ปิดเสียง
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: SwitchListTile(
                title: Text(
                  AppLocalizations.of(context).enableSoundNotifications,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                    fontFamily: 'NotoSansThai',
                  ),
                ),
                subtitle: Text(
                  AppLocalizations.of(context).enableDisableSoundDesc,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    fontFamily: 'NotoSansThai',
                  ),
                ),
                value: _isSoundEnabled,
                activeColor: const Color(0xFF4673E5),
                activeTrackColor: const Color(0xFF4673E5).withOpacity(0.3),
                onChanged: (value) async {
                  setState(() {
                    _isSoundEnabled = value;
                  });
                  await _soundManager.setSoundEnabled(value);
                },
                secondary: Icon(
                  _isSoundEnabled ? Icons.volume_up : Icons.volume_off,
                  color: const Color(0xFF4673E5),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // เลือกประเภทเสียง
            Text(
              AppLocalizations.of(context).selectSoundType,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                fontFamily: 'NotoSansThai',
              ),
            ),

            const SizedBox(height: 12),

            // แสดงเฉพาะตัวเลือกที่อนุญาต (ไม่มี beep และ warning)
            ...AlertSoundType.values
                .where((soundType) =>
                    soundType != AlertSoundType.beep &&
                    soundType != AlertSoundType.warning)
                .map((soundType) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  leading: Icon(
                    _getSoundIcon(soundType),
                    size: 24,
                    color: const Color(0xFF4673E5),
                  ),
                  title: Text(
                    _getSoundDisplayName(soundType),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                      fontFamily: 'NotoSansThai',
                    ),
                  ),
                  subtitle: Text(
                    _getSoundDescription(soundType),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      fontFamily: 'NotoSansThai',
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ปุ่มทดสอบเสียง
                      IconButton(
                        icon: const Icon(Icons.play_arrow),
                        onPressed: _isSoundEnabled
                            ? () => _testSound(soundType)
                            : null,
                        tooltip: AppLocalizations.of(context).testSound,
                      ),
                      // Radio button
                      Radio<AlertSoundType>(
                        value: soundType,
                        groupValue: _selectedSoundType,
                        activeColor: const Color(0xFF4673E5),
                        onChanged: _isSoundEnabled
                            ? (AlertSoundType? value) async {
                                if (value != null) {
                                  setState(() {
                                    _selectedSoundType = value;
                                  });
                                  await _soundManager.setSoundType(value);
                                }
                              }
                            : null,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),

            const SizedBox(height: 16),

            // คำอธิบาย
            Container(
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).soundTips,
                      style: const TextStyle(
                        fontFamily: 'NotoSansThai',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context).soundTipsDescription,
                      style: const TextStyle(fontFamily: 'NotoSansThai'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getSoundDescription(AlertSoundType soundType) {
    switch (soundType) {
      case AlertSoundType.none:
        return AppLocalizations.of(context).noSoundDescription;
      case AlertSoundType.beep:
        return AppLocalizations.of(context).beepSoundDescription;
      case AlertSoundType.warning:
        return AppLocalizations.of(context).warningSoundDescription;
      case AlertSoundType.tts:
        return AppLocalizations.of(context).ttsSoundDescription;
    }
  }

  String _getSoundDisplayName(AlertSoundType soundType) {
    switch (soundType) {
      case AlertSoundType.none:
        return AppLocalizations.of(context).noSoundDisplayName;
      case AlertSoundType.beep:
        return AppLocalizations.of(context).beepSoundDescription;
      case AlertSoundType.warning:
        return AppLocalizations.of(context).warningSoundDescription;
      case AlertSoundType.tts:
        return AppLocalizations.of(context).thaiVoiceDisplayName;
    }
  }

  IconData _getSoundIcon(AlertSoundType soundType) {
    switch (soundType) {
      case AlertSoundType.none:
        return Icons.volume_off;
      case AlertSoundType.beep:
        return Icons.volume_up;
      case AlertSoundType.warning:
        return Icons.warning;
      case AlertSoundType.tts:
        return Icons.record_voice_over;
    }
  }

  Future<void> _testSound(AlertSoundType soundType) async {
    try {
      await _soundManager.testSound(soundType);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)
                  .testSoundSuccess(_getSoundDisplayName(soundType)),
              style: const TextStyle(fontFamily: 'NotoSansThai'),
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).cannotPlaySound(e.toString()),
              style: const TextStyle(fontFamily: 'NotoSansThai'),
            ),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
