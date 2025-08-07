import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
import '../services/push_notification_service.dart';
import '../services/auth_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _notificationsEnabled = true;
  bool _newPostNotifications = true;
  bool _commentNotifications = true;
  bool _systemNotifications = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      setState(() => _isLoading = true);

      final prefs = await SharedPreferences.getInstance();

      setState(() {
        _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
        _newPostNotifications = prefs.getBool('new_post_notifications') ?? true;
        _commentNotifications = prefs.getBool('comment_notifications') ?? true;
        _systemNotifications = prefs.getBool('system_notifications') ?? true;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading notification settings: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool('notifications_enabled', _notificationsEnabled);
      await prefs.setBool('new_post_notifications', _newPostNotifications);
      await prefs.setBool('comment_notifications', _commentNotifications);
      await prefs.setBool('system_notifications', _systemNotifications);

      // อัปเดต FCM token ตามการตั้งค่า
      if (_notificationsEnabled) {
        await NotificationService.updateTokenOnLogin();
      } else {
        await NotificationService.disableNotifications();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ บันทึกการตั้งค่าเรียบร้อย',
                style: TextStyle(fontFamily: 'NotoSansThai')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Error saving notification settings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ เกิดข้อผิดพลาด: $e',
                style: TextStyle(fontFamily: 'NotoSansThai')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _testNotification() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔔 กำลังทดสอบการแจ้งเตือน...',
              style: TextStyle(fontFamily: 'NotoSansThai')),
        ),
      );

      // ส่งทดสอบผ่าน PushNotificationService
      await PushNotificationService.sendTestNotification();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ ส่งการแจ้งเตือนทดสอบแล้ว',
                style: TextStyle(fontFamily: 'NotoSansThai')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Error testing notification: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ เกิดข้อผิดพลาดในการทดสอบ: $e',
                style: TextStyle(fontFamily: 'NotoSansThai')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDF0F7),
      appBar: AppBar(
        title: const Text(
          'การแจ้งเตือน',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black,
            fontFamily: 'NotoSansThai',
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFFDC621),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.black,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.save,
              color: Colors.black,
            ),
            onPressed: _saveSettings,
            tooltip: 'บันทึกการตั้งค่า',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFF9800),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // การตั้งค่าหลัก
                  _buildSectionCard(
                    title: '⚙️ การตั้งค่าหลัก',
                    children: [
                      _buildSwitchTile(
                        title: 'เปิดการแจ้งเตือน',
                        subtitle: 'รับการแจ้งเตือนจากแอป CheckDarn',
                        value: _notificationsEnabled,
                        onChanged: (value) {
                          setState(() {
                            _notificationsEnabled = value;
                            if (!value) {
                              _newPostNotifications = false;
                              _commentNotifications = false;
                              _systemNotifications = false;
                            }
                          });
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // การตั้งค่าประเภทการแจ้งเตือน
                  _buildSectionCard(
                    title: '🔔 ประเภทการแจ้งเตือน',
                    children: [
                      _buildSwitchTile(
                        title: 'เหตุการณ์ใหม่',
                        subtitle:
                            'แจ้งเตือนเมื่อมีการรายงานเหตุการณ์ใหม่ใกล้คุณ',
                        value: _newPostNotifications && _notificationsEnabled,
                        onChanged: _notificationsEnabled
                            ? (value) {
                                setState(() => _newPostNotifications = value);
                              }
                            : null,
                      ),
                      _buildSwitchTile(
                        title: 'ความคิดเห็น',
                        subtitle:
                            'แจ้งเตือนเมื่อมีคนแสดงความคิดเห็นในโพสต์ของคุณ',
                        value: _commentNotifications && _notificationsEnabled,
                        onChanged: _notificationsEnabled
                            ? (value) {
                                setState(() => _commentNotifications = value);
                              }
                            : null,
                      ),
                      _buildSwitchTile(
                        title: 'ระบบ',
                        subtitle: 'แจ้งเตือนจากระบบและการอัปเดต',
                        value: _systemNotifications && _notificationsEnabled,
                        onChanged: _notificationsEnabled
                            ? (value) {
                                setState(() => _systemNotifications = value);
                              }
                            : null,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ข้อมูลสถานะ
                  _buildSectionCard(
                    title: '📊 สถานะ',
                    children: [
                      _buildInfoTile(
                        icon: '👤',
                        title: 'ผู้ใช้',
                        subtitle: AuthService.getMaskedDisplayName(),
                      ),
                      _buildInfoTile(
                        icon: '📱',
                        title: 'อุปกรณ์',
                        subtitle: _notificationsEnabled
                            ? 'เชื่อมต่อแล้ว'
                            : 'ปิดการแจ้งเตือน',
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ปุ่มทดสอบ
                  if (_notificationsEnabled) ...[
                    _buildSectionCard(
                      title: '🧪 ทดสอบ',
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: ElevatedButton.icon(
                            onPressed: _testNotification,
                            icon: const Icon(Icons.notifications_active),
                            label: const Text(
                              'ทดสอบการแจ้งเตือน',
                              style: TextStyle(fontFamily: 'NotoSansThai'),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF9800),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // คำแนะนำ
                  _buildSectionCard(
                    title: '💡 คำแนะนำ',
                    children: [
                      _buildInfoTile(
                        icon: '🔒',
                        title: 'ความเป็นส่วนตัว',
                        subtitle: 'เราจะไม่แจ้งเตือนให้คุณเมื่อคุณโพสต์เอง',
                      ),
                      _buildInfoTile(
                        icon: '⚡',
                        title: 'ประหยัดแบตเตอรี่',
                        subtitle:
                            'ปิดการแจ้งเตือนที่ไม่จำเป็นเพื่อประหยัดแบตเตอรี่',
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                fontFamily: 'NotoSansThai',
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: onChanged != null ? Colors.black87 : Colors.grey,
                    fontFamily: 'NotoSansThai',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color:
                        onChanged != null ? Colors.grey[600] : Colors.grey[400],
                    fontFamily: 'NotoSansThai',
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFFFF9800),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required String icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                    fontFamily: 'NotoSansThai',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontFamily: 'NotoSansThai',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
