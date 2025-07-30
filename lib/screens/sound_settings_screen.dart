import 'package:flutter/material.dart';
import '../services/sound_manager.dart';

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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFEDF0F7), // เปลี่ยนเป็นสีเดียวกับ list screen
      appBar: AppBar(
        title: const Text(
          'ตั้งค่าเสียงแจ้งเตือน',
          style: TextStyle(
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
            Card(
              child: SwitchListTile(
                title: const Text(
                  'เปิดใช้งานเสียงแจ้งเตือน',
                  style: TextStyle(
                      fontFamily: 'NotoSansThai', fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'เปิด/ปิดเสียงแจ้งเตือนทั้งหมด',
                  style: TextStyle(fontFamily: 'NotoSansThai'),
                ),
                value: _isSoundEnabled,
                onChanged: (value) async {
                  setState(() {
                    _isSoundEnabled = value;
                  });
                  await _soundManager.setSoundEnabled(value);
                },
                secondary: Icon(
                  _isSoundEnabled ? Icons.volume_up : Icons.volume_off,
                  color: const Color(0xFF1158F2),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // เลือกประเภทเสียง
            const Text(
              '🔊 เลือกประเภทเสียงแจ้งเตือน',
              style: TextStyle(
                fontFamily: 'NotoSansThai',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87, // เปลี่ยนจากสีขาวเป็นสีเข้ม
              ),
            ),

            const SizedBox(height: 12),

            // เปลี่ยนจาก Expanded เป็น Column เพื่อให้ scroll ได้ทั้งหน้า
            ...AlertSoundType.values.map((soundType) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(
                    _getSoundIcon(soundType),
                    size: 24,
                    color: const Color(0xFF1158F2),
                  ),
                  title: Text(
                    soundType.displayName,
                    style: const TextStyle(
                      fontFamily: 'NotoSansThai',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    _getSoundDescription(soundType),
                    style: const TextStyle(fontFamily: 'NotoSansThai'),
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
                        tooltip: 'ทดสอบเสียง',
                      ),
                      // Radio button
                      Radio<AlertSoundType>(
                        value: soundType,
                        groupValue: _selectedSoundType,
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
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '💡 คำแนะนำ',
                      style: TextStyle(
                        fontFamily: 'NotoSansThai',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• เสียงพูด: เหมาะสำหรับการขับขี่ยาว ให้ข้อมูลละเอียด\n'
                      '• เสียงบี๊บ/ระฆัง: เหมาะสำหรับการขับขี่ในเมือง สั้นกระชับ\n'
                      '• เสียงเตือนภัย: เหมาะสำหรับเส้นทางเสี่ยง แจ้งเตือนชัดเจน',
                      style: TextStyle(fontFamily: 'NotoSansThai'),
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
        return 'ไม่มีเสียงแจ้งเตือน เงียบสนิท';
      case AlertSoundType.beep:
        return 'เสียงบี๊บสั้นๆ เรียบง่าย';
      case AlertSoundType.warning:
        return 'เสียงเตือนภัยแบบไซเรน';
      case AlertSoundType.tts:
        return 'อ่านข้อความเป็นเสียงพูดภาษาไทย';
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
              'ทดสอบเสียง: ${soundType.displayName}',
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
              'ไม่สามารถเล่นเสียงได้: $e',
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
