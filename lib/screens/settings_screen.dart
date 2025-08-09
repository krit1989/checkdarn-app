import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/smart_security_service.dart';
import '../providers/language_provider.dart';
import 'sound_settings_screen.dart';
import 'terms_of_service_screen.dart';
import 'privacy_policy_screen.dart';
import '../generated/gen_l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isNewEventNotificationEnabled = true;

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
        SnackBar(
          content: Text(AppLocalizations.of(context).securityValidationFailed),
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
        title: Text(
          AppLocalizations.of(context).settings,
          style: const TextStyle(
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
                SnackBar(
                  content: Text(
                      AppLocalizations.of(context).securityValidationFailed),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            16 + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            children: [
              // Profile Section
              Container(
                margin: const EdgeInsets.only(bottom: 18), // ลดจาก 24 เป็น 18
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

              // Notification Settings
              Container(
                margin: const EdgeInsets.only(bottom: 18), // ลดจาก 24 เป็น 18
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
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                          16, 16, 16, 8), // ลด padding ด้านล่างเป็น 8
                      child: Row(
                        children: [
                          const Icon(
                            Icons.notifications,
                            color: Color(0xFF4673E5),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AppLocalizations.of(context).notifications,
                            style: const TextStyle(
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
                      AppLocalizations.of(context).enableNotifications,
                      AppLocalizations.of(context).enableNotificationsDesc,
                      _isNewEventNotificationEnabled,
                      (value) => _handleSecureNotificationToggle(
                        'new_event',
                        value,
                        (v) =>
                            setState(() => _isNewEventNotificationEnabled = v),
                      ),
                    ),
                    _buildSettingsItem(
                      AppLocalizations.of(context).speedCameraSoundAlert,
                      AppLocalizations.of(context).thaiVoice,
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
                            SnackBar(
                              content: Text(AppLocalizations.of(context)
                                  .securityValidationFailed),
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
                      isLast: true, // เป็นรายการสุดท้ายในการ์ดการแจ้งเตือน
                    ),
                  ],
                ),
              ),

              // General Settings
              Container(
                margin: const EdgeInsets.only(bottom: 18), // ลดจาก 24 เป็น 18
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
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                          16, 16, 16, 8), // ลด padding ด้านล่างเป็น 8
                      child: Row(
                        children: [
                          const Icon(
                            Icons.settings,
                            color: Color(0xFF4673E5),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AppLocalizations.of(context).general,
                            style: const TextStyle(
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
                      AppLocalizations.of(context).language,
                      Provider.of<LanguageProvider>(context)
                          .getCurrentLanguageDisplayName(),
                      Icons.arrow_forward_ios,
                      () async {
                        // Smart Security validation for language settings
                        if (!await _validateSettingsActionSimple(
                          action: 'language_settings',
                          context: {
                            'user_email': AuthService.currentUser?.email,
                            'current_language': Provider.of<LanguageProvider>(
                                    context,
                                    listen: false)
                                .currentLanguage,
                          },
                        )) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(AppLocalizations.of(context)
                                  .securityValidationFailed),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        // Show language selection dialog
                        showDialog(
                          context: context,
                          builder: (context) => Consumer<LanguageProvider>(
                            builder: (context, languageProvider, child) {
                              return AlertDialog(
                                title: Text(
                                  AppLocalizations.of(context).selectLanguage,
                                  style: const TextStyle(
                                    fontFamily: 'NotoSansThai',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      leading: const Text('🇹🇭',
                                          style: TextStyle(fontSize: 24)),
                                      title: Text(
                                        AppLocalizations.of(context).thai,
                                        style: const TextStyle(
                                            fontFamily: 'NotoSansThai'),
                                      ),
                                      trailing: Radio<String>(
                                        value: 'th',
                                        groupValue:
                                            languageProvider.currentLanguage,
                                        onChanged: (value) async {
                                          if (value != null) {
                                            await languageProvider
                                                .setLanguage(value);
                                            Navigator.pop(context);
                                          }
                                        },
                                      ),
                                      onTap: () async {
                                        await languageProvider
                                            .setLanguage('th');
                                        Navigator.pop(context);
                                      },
                                    ),
                                    ListTile(
                                      leading: const Text('🇺🇸',
                                          style: TextStyle(fontSize: 24)),
                                      title: Text(
                                        AppLocalizations.of(context).english,
                                        style: const TextStyle(
                                            fontFamily: 'NotoSansThai'),
                                      ),
                                      trailing: Radio<String>(
                                        value: 'en',
                                        groupValue:
                                            languageProvider.currentLanguage,
                                        onChanged: (value) async {
                                          if (value != null) {
                                            await languageProvider
                                                .setLanguage(value);
                                            Navigator.pop(context);
                                          }
                                        },
                                      ),
                                      onTap: () async {
                                        await languageProvider
                                            .setLanguage('en');
                                        Navigator.pop(context);
                                      },
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text(
                                      AppLocalizations.of(context).close,
                                      style: const TextStyle(
                                        fontFamily: 'NotoSansThai',
                                        color: Color(0xFF4673E5),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        );
                      },
                    ),
                    _buildSettingsItem(
                      AppLocalizations.of(context).shareApp,
                      AppLocalizations.of(context).shareAppDesc,
                      Icons.share,
                      () {
                        // TODO: Share app functionality
                      },
                    ),
                    _buildSettingsItem(
                      AppLocalizations.of(context).reviewApp,
                      AppLocalizations.of(context).reviewAppDesc,
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
                margin: const EdgeInsets.only(bottom: 18), // ลดจาก 24 เป็น 18
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
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                          16, 16, 16, 8), // ลด padding ด้านล่างเป็น 8
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info,
                            color: Color(0xFF4673E5),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AppLocalizations.of(context).aboutApp,
                            style: const TextStyle(
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
                          Text(
                            AppLocalizations.of(context).version,
                            style: const TextStyle(
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
                      AppLocalizations.of(context).termsOfService,
                      null,
                      Icons.arrow_forward_ios,
                      () async {
                        debugPrint('🔥 TERMS BUTTON CLICKED IN SETTINGS');

                        // Smart Security validation
                        if (!await _validateSettingsActionSimple(
                          action: 'view_terms',
                          context: {'source': 'settings_screen'},
                        )) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(AppLocalizations.of(context)
                                  .securityValidationFailed),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        debugPrint('🔥 NAVIGATING TO TERMS SCREEN');
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TermsOfServiceScreen(),
                          ),
                        );
                        debugPrint('🔥 NAVIGATION COMPLETED');
                      },
                    ),
                    _buildSettingsItem(
                      AppLocalizations.of(context).privacyPolicy,
                      null,
                      Icons.arrow_forward_ios,
                      () async {
                        debugPrint('🔒 PRIVACY POLICY BUTTON CLICKED');

                        // Smart Security validation
                        if (!await _validateSettingsActionSimple(
                          action: 'view_privacy',
                          context: {'source': 'settings_screen'},
                        )) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(AppLocalizations.of(context)
                                  .securityValidationFailed),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        debugPrint('🔒 NAVIGATING TO PRIVACY POLICY SCREEN');
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PrivacyPolicyScreen(),
                          ),
                        );
                        debugPrint('🔒 NAVIGATION COMPLETED');
                      },
                    ),
                    _buildSettingsItem(
                      AppLocalizations.of(context).contactUs,
                      AppLocalizations.of(context).sendFeedbackOrReport,
                      Icons.arrow_forward_ios,
                      () async {
                        // Smart Security validation for contact
                        if (!await _validateSettingsActionSimple(
                          action: 'contact_us',
                          context: {
                            'user_email': AuthService.currentUser?.email,
                            'source': 'settings_screen',
                          },
                        )) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                AppLocalizations.of(context)
                                    .securityValidationFailed,
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        // Show contact options dialog
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(
                              AppLocalizations.of(context).contactUs,
                              style: const TextStyle(
                                fontFamily: 'NotoSansThai',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(context).email,
                                  style: const TextStyle(
                                    fontFamily: 'NotoSansThai',
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                SelectableText(
                                  'checkdarn.app@gmail.com',
                                  style: const TextStyle(
                                    fontFamily: 'NotoSansThai',
                                    color: Color(0xFF4673E5),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  AppLocalizations.of(context).reportProblem,
                                  style: const TextStyle(
                                    fontFamily: 'NotoSansThai',
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(
                                  AppLocalizations.of(context).close,
                                  style: const TextStyle(
                                    fontFamily: 'NotoSansThai',
                                    color: Color(0xFF4673E5),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      isLast: true,
                    ),
                  ],
                ),
              ),

              // Logout Button
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 28), // ลดจาก 32 เป็น 28
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
                        SnackBar(
                          content: Text(AppLocalizations.of(context)
                              .securityValidationFailed),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    // Show confirmation dialog
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(
                          AppLocalizations.of(context).logoutTitle,
                          style: const TextStyle(fontFamily: 'NotoSansThai'),
                        ),
                        content: Text(
                          AppLocalizations.of(context).logoutMessage,
                          style: const TextStyle(fontFamily: 'NotoSansThai'),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(
                              AppLocalizations.of(context).cancel,
                              style:
                                  const TextStyle(fontFamily: 'NotoSansThai'),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text(
                              AppLocalizations.of(context).logout,
                              style: const TextStyle(
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
                          SnackBar(
                            content:
                                Text(AppLocalizations.of(context).logoutFailed),
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.logout, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context).logout,
                        style: const TextStyle(
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
