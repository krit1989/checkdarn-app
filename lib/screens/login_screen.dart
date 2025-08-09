import 'package:flutter/material.dart';
import '../generated/gen_l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../services/smart_security_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeSmartSecurity();

    // Setup animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    // Start animations
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _initializeSmartSecurity() async {
    await SmartSecurityService.initialize();
    SmartSecurityService.setSecurityLevel(SecurityLevel.critical);
  }

  Future<bool> _validateLoginActionSimple({
    String? action,
    Map<String, dynamic>? context,
  }) async {
    try {
      final result = await SmartSecurityService.checkPageSecurity(
        'login_page',
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

  Future<void> _handleSecureNavigation(bool result) async {
    if (!await _validateLoginActionSimple(
      action: 'navigation',
      context: {
        'result': result,
        'exit_type': result ? 'success' : 'cancel',
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
    Navigator.of(context).pop(result);
  }

  Future<void> _handleGoogleSignIn() async {
    // Smart Security validation - CRITICAL RISK operation
    if (!await _validateLoginActionSimple(
      action: 'google_signin',
      context: {
        'provider': 'google',
        'is_loading': _isLoading,
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

    setState(() {
      _isLoading = true;
    });

    try {
      print('🚀 เริ่มกระบวนการล็อกอิน...');

      final result = await AuthService.signInWithGoogle(context: context);

      if (result != null) {
        // ล็อกอินสำเร็จ
        if (mounted) {
          await _handleSecureNavigation(true);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'เข้าสู่ระบบสำเร็จ! ยินดีต้อนรับ ${result.user?.displayName ?? 'ผู้ใช้'}',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        // ผู้ใช้ยกเลิก
        if (mounted) {
          await _handleSecureNavigation(false);
        }
      }
    } catch (e) {
      print('❌ Login error: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ล็อกอินไม่สำเร็จ: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDF0F7),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Close button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 40),
                    const Spacer(),
                    IconButton(
                      onPressed: _isLoading
                          ? null
                          : () => _handleSecureNavigation(false),
                      icon: Icon(
                        Icons.close,
                        color: _isLoading ? Colors.grey : Colors.black54,
                        size: 28,
                      ),
                    ),
                  ],
                ),

                // Main content
                Expanded(
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // App logo/icon
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Image.asset(
                              'assets/images/app_icon.png',
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                // Fallback ถ้าโหลดรูปไม่ได้
                                return Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4285F4),
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: const Icon(
                                    Icons.location_on,
                                    color: Colors.white,
                                    size: 50,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Welcome text
                        Text(
                          AppLocalizations.of(context).welcomeTo,
                          style: const TextStyle(
                            fontSize: 24,
                            color: Colors.black54,
                            fontWeight: FontWeight.w300,
                          ),
                        ),

                        const SizedBox(height: 8),

                        const Text(
                          'CheckDarn',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),

                        const SizedBox(height: 16),

                        Text(
                          'แพลตฟอร์มรายงานเหตุการณ์\nในชุมชนของคุณ',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 48),

                        // Google Sign In Button
                        Container(
                          width: double.infinity,
                          height: 54,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: _isLoading ? null : _handleGoogleSignIn,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (_isLoading)
                                      const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Color(0xFF4285F4),
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    else
                                      SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: Image.network(
                                          'https://developers.google.com/identity/images/g-logo.png',
                                          width: 24,
                                          height: 24,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Container(
                                              width: 24,
                                              height: 24,
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: const Center(
                                                child: Text(
                                                  'G',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF4285F4),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    const SizedBox(width: 16),
                                    Text(
                                      _isLoading
                                          ? 'กำลังเข้าสู่ระบบ...'
                                          : 'เข้าสู่ระบบด้วย Google',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: _isLoading
                                            ? Colors.grey.shade500
                                            : Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Skip button
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () => _handleSecureNavigation(false),
                          child: Text(
                            'ข้ามไปก่อน',
                            style: TextStyle(
                              fontSize: 16,
                              color: _isLoading
                                  ? Colors.grey
                                  : Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom info
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    'การเข้าสู่ระบบจะช่วยให้คุณสามารถ\nรายงานเหตุการณ์และแสดงความคิดเห็นได้',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
