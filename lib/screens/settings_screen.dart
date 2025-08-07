import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/smart_security_service.dart';
import 'sound_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isNewEventNotificationEnabled = true;
  bool _isSoundNotificationEnabled = true;
  bool _isVibrationNotificationEnabled = true;

  @override
  void initState() {
    super.initState();
    _initializeSmartSecurity();
  }

  Future<void> _initializeSmartSecurity() async {
    await SmartSecurityService.initialize();
    SmartSecurityService.setSecurityLevel(SecurityLevel.medium);
  }

  Future<bool> _validateSettingsActionSimple({
    String? action,
    Map<String, dynamic>? context,
  }) async {
    try {
      final result = await SmartSecurityService.checkPageSecurity(
        'settings_page',
        context: {
          'action': action ?? 'generic',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          ...(context ?? {}),
        },
      );
      return result.isAllowed;
    } catch (e) {
      print('Smart Security validation failed: $e');
      return false;
    }
  }

  Future<void> _handleSecureNotificationToggle(
    String notificationType,
    bool newValue,
    Function(bool) originalCallback,
  ) async {
    if (!await _validateSettingsActionSimple(
      action: 'notification_toggle',
      context: {
        'notification_type': notificationType,
        'new_value': newValue,
        'user_email': AuthService.currentUser?.email,
      },
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('การตรวจสอบความปลอดภัยล้มเหลว'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    originalCallback(newValue);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDF0F7),
      appBar: AppBar(
        title: const Text(
          'การตั้งค่า',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
            fontFamily: 'NotoSansThai',
          ),
        ),
        backgroundColor: const Color(0xFFFDC621),
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () async {
            if (!await _validateSettingsActionSimple(
              action: 'navigation_back',
              context: {'exit_type': 'back_button'},
            )) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('การตรวจสอบความปลอดภัยล้มเหลว'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Section
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(20),
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
              child: Row(
                children: [
                  // Profile Image
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF4673E5),
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                    child: AuthService.isLoggedIn &&
                            AuthService.currentUser?.photoURL != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: Image.network(
                              AuthService.currentUser!.photoURL!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                );
                              },
                            ),
                          )
                        : const Center(
                            child: Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                  ),
                  const SizedBox(width: 16),
                  // Profile Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'K Design',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                            fontFamily: 'NotoSansThai',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AuthService.currentUser?.email ??
                              'kumcupdesign@gmail.com',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            fontFamily: 'NotoSansThai',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Edit Profile Button
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 24),
              child: OutlinedButton.icon(
                onPressed: () async {
                  // Smart Security validation for profile edit
                  if (!await _validateSettingsActionSimple(
                    action: 'edit_profile',
                    context: {
                      'user_email': AuthService.currentUser?.email,
                      'is_logged_in': AuthService.isLoggedIn,
                    },
                  )) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('การตรวจสอบความปลอดภัยล้มเหลว'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  // TODO: Navigate to edit profile screen
                },
                icon: const Icon(
                  Icons.edit,
                  color: Color(0xFF4673E5),
                  size: 18,
                ),
                label: const Text(
                  'จัดการโปรไฟล์',
                  style: TextStyle(
                    color: Color(0xFF4673E5),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'NotoSansThai',
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(
                    color: Color(0xFF4673E5),
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),

            // Notification Settings
            Container(
              margin: const EdgeInsets.only(bottom: 24),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.notifications,
                          color: Color(0xFF4673E5),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'การแจ้งเตือน',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                            fontFamily: 'NotoSansThai',
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildNotificationToggle(
                    'เปิดการแจ้งเตือน',
                    'รับการแจ้งเตือนเหตุการณ์ใหม่',
                    _isNewEventNotificationEnabled,
                    (value) => _handleSecureNotificationToggle(
                      'new_event',
                      value,
                      (v) => setState(() => _isNewEventNotificationEnabled = v),
                    ),
                  ),
                  _buildNotificationToggle(
                    'เสียงแจ้งเตือน',
                    'เล่นเสียงเมื่อมีการแจ้งเตือน',
                    _isSoundNotificationEnabled,
                    (value) => _handleSecureNotificationToggle(
                      'sound',
                      value,
                      (v) => setState(() => _isSoundNotificationEnabled = v),
                    ),
                  ),
                  _buildNotificationToggle(
                    'การสั่นแจ้งเตือน',
                    'สั่นเครื่องเมื่อมีการแจ้งเตือน',
                    _isVibrationNotificationEnabled,
                    (value) => _handleSecureNotificationToggle(
                      'vibration',
                      value,
                      (v) =>
                          setState(() => _isVibrationNotificationEnabled = v),
                    ),
                    isLast: true,
                  ),
                ],
              ),
            ),

            // General Settings
            Container(
              margin: const EdgeInsets.only(bottom: 24),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.settings,
                          color: Color(0xFF4673E5),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'ทั่วไป',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                            fontFamily: 'NotoSansThai',
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildSettingsItem(
                    'เสียงแจ้งเตือนโหมดกล้องจับความเร็ว',
                    'เสียงพูดภาษาไทย',
                    Icons.arrow_forward_ios,
                    () async {
                      // Smart Security validation for sound settings
                      if (!await _validateSettingsActionSimple(
                        action: 'sound_settings',
                        context: {
                          'user_email': AuthService.currentUser?.email,
                          'navigation': 'sound_settings_screen',
                        },
                      )) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('การตรวจสอบความปลอดภัยล้มเหลว'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SoundSettingsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildSettingsItem(
                    'ภาษา',
                    'ไทย',
                    Icons.arrow_forward_ios,
                    () {
                      // TODO: Navigate to language settings
                    },
                  ),
                  _buildSettingsItem(
                    'แชร์แอปให้เพื่อน',
                    'บอกต่อให้คนรู้จัก',
                    Icons.share,
                    () {
                      // TODO: Share app functionality
                    },
                  ),
                  _buildSettingsItem(
                    'รีวิวแอป',
                    'ให้คะแนนและรีวิวใน App Store',
                    Icons.star,
                    () {
                      // TODO: Navigate to app store review
                    },
                    isLast: true,
                  ),
                ],
              ),
            ),

            // About Section
            Container(
              margin: const EdgeInsets.only(bottom: 24),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info,
                          color: Color(0xFF4673E5),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'เกี่ยวกับแอป',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                            fontFamily: 'NotoSansThai',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'เวอร์ชัน',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'NotoSansThai',
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '1.0.0',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            fontFamily: 'NotoSansThai',
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                  _buildSettingsItem(
                    'เงื่อนไขการใช้งาน',
                    null,
                    Icons.arrow_forward_ios,
                    () {
                      // TODO: Navigate to terms of service
                    },
                  ),
                  _buildSettingsItem(
                    'นโยบายความเป็นส่วนตัว',
                    null,
                    Icons.arrow_forward_ios,
                    () {
                      // TODO: Navigate to privacy policy
                    },
                  ),
                  _buildSettingsItem(
                    'ติดต่อเรา',
                    'ส่งข้อเสนอแนะหรือรายงานปัญหา',
                    Icons.arrow_forward_ios,
                    () {
                      // TODO: Navigate to contact/feedback
                    },
                    isLast: true,
                  ),
                ],
              ),
            ),

            // Logout Button
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 32),
              child: ElevatedButton(
                onPressed: () async {
                  // Smart Security validation for logout
                  if (!await _validateSettingsActionSimple(
                    action: 'logout_attempt',
                    context: {
                      'user_email': AuthService.currentUser?.email,
                      'is_logged_in': AuthService.isLoggedIn,
                    },
                  )) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('การตรวจสอบความปลอดภัยล้มเหลว'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  // Show confirmation dialog
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text(
                        'ออกจากระบบ',
                        style: TextStyle(fontFamily: 'NotoSansThai'),
                      ),
                      content: const Text(
                        'คุณต้องการออกจากระบบหรือไม่?',
                        style: TextStyle(fontFamily: 'NotoSansThai'),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text(
                            'ยกเลิก',
                            style: TextStyle(fontFamily: 'NotoSansThai'),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text(
                            'ออกจากระบบ',
                            style: TextStyle(
                              color: Colors.red,
                              fontFamily: 'NotoSansThai',
                            ),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    // Additional security validation for actual logout
                    if (!await _validateSettingsActionSimple(
                      action: 'logout_confirmed',
                      context: {
                        'confirmation': true,
                        'user_email': AuthService.currentUser?.email,
                      },
                    )) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('การออกจากระบบล้มเหลว'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    await AuthService.signOut();
                    if (mounted) {
                      Navigator.pop(context);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFE5E5),
                  foregroundColor: Colors.red,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'ออกจากระบบ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'NotoSansThai',
                      ),
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

  Widget _buildNotificationToggle(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged, {
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: Colors.grey.shade200,
                  width: 0.5,
                ),
              ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                    fontFamily: 'NotoSansThai',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    fontFamily: 'NotoSansThai',
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF4673E5),
            activeTrackColor: const Color(0xFF4673E5).withOpacity(0.3),
            inactiveThumbColor: Colors.grey.shade400,
            inactiveTrackColor: Colors.grey.shade300,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(
    String title,
    String? subtitle,
    IconData trailingIcon,
    VoidCallback onTap, {
    bool isLast = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(
                    color: Colors.grey.shade200,
                    width: 0.5,
                  ),
                ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                      fontFamily: 'NotoSansThai',
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                        fontFamily: 'NotoSansThai',
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              trailingIcon,
              size: 16,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
