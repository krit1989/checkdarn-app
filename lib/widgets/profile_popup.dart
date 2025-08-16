import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/smart_security_service.dart';
import '../screens/notification_settings_screen.dart';

class ProfilePopup extends StatefulWidget {
  final VoidCallback onLogout;

  const ProfilePopup({super.key, required this.onLogout});

  @override
  State<ProfilePopup> createState() => _ProfilePopupState();
}

class _ProfilePopupState extends State<ProfilePopup> {
  @override
  void initState() {
    super.initState();
    _initializeSmartSecurity();
  }

  Future<void> _initializeSmartSecurity() async {
    await SmartSecurityService.initialize();
    SmartSecurityService.setSecurityLevel(SecurityLevel.high);
  }

  Future<bool> _validateProfileActionSimple({
    String? action,
    Map<String, dynamic>? context,
  }) async {
    try {
      final result = await SmartSecurityService.checkPageSecurity(
        'profile_popup',
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

  Future<void> _handleSecureLogout() async {
    if (!await _validateProfileActionSimple(
      action: 'logout_from_popup',
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
    widget.onLogout();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 320,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            if (AuthService.isLoggedIn) _buildUserInfoSection(),
            _buildMenuItems(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFFE4EDF4),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: const Center(
        child: Text(
          'CheckDarn',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfoSection() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF4673E5),
                ),
                child: AuthService.currentUser?.photoURL != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          AuthService.currentUser!.photoURL!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 24,
                              ),
                            );
                          },
                        ),
                      )
                    : const Center(
                        child: Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            AuthService.currentUser?.displayName ?? 'ผู้ใช้',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.grey,
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AuthService.currentUser?.email ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          child: OutlinedButton(
            onPressed: () async {
              // Smart Security validation for Google account management
              if (!await _validateProfileActionSimple(
                action: 'manage_google_account',
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
              // TODO: เพิ่มฟังก์ชันจัดการบัญชี Google
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF4673E5)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text(
              'จัดการบัญชี Google',
              style: TextStyle(
                color: Color(0xFF4673E5),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildMenuItems() {
    return Column(
      children: [
        _buildMenuDivider(),
        _buildMenuItem(
          icon: '🔔',
          title: 'การแจ้งเตือนของฉัน',
          onTap: () async {
            if (!await _validateProfileActionSimple(
              action: 'view_notifications',
              context: {
                'user_email': AuthService.currentUser?.email,
                'source': 'profile_popup',
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
            // Navigate to notification settings
            Navigator.of(context).pop(); // ปิด popup ก่อน
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const NotificationSettingsScreen(),
              ),
            );
          },
        ),
        _buildMenuItem(
          icon: '📤',
          title: 'แชร์แอปให้เพื่อน',
          onTap: () async {
            if (!await _validateProfileActionSimple(
              action: 'share_app',
              context: {'source': 'profile_popup'},
            )) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('การตรวจสอบความปลอดภัยล้มเหลว'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
            // TODO: Share app functionality
          },
        ),
        _buildMenuItem(
          icon: '🌐',
          title: 'เปลี่ยนภาษา',
          onTap: () async {
            if (!await _validateProfileActionSimple(
              action: 'change_language',
              context: {'source': 'profile_popup'},
            )) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('การตรวจสอบความปลอดภัยล้มเหลว'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
            // TODO: Language change functionality
          },
        ),
        _buildMenuDivider(),
        _buildMenuItem(
          icon: '🔒',
          title: 'ออกจากระบบ',
          onTap: _handleSecureLogout,
          isLogout: true,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildMenuItem({
    required String icon,
    required String title,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isLogout ? Colors.red.shade600 : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      color: Colors.grey.shade300,
    );
  }
}
