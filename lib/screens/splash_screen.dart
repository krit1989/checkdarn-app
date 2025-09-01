import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../routes/app_routes.dart';
import '../generated/gen_l10n/app_localizations.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // ซ่อน status bar
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500), // เพิ่มเวลา animation
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _animationController,
          curve: const Interval(0.0, 0.6, curve: Curves.easeOut)),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
          parent: _animationController,
          curve: const Interval(0.2, 0.8, curve: Curves.elasticOut)),
    );

    _animationController.forward();

    // Navigate to map screen after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        AppRoutes.pushReplacement(context, AppRoutes.map);
      }
    });
  }

  @override
  void dispose() {
    // คืนค่า status bar เมื่อออกจากหน้านี้
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFC107), // สีเหลืองเดิม
      body: Container(
        // ลบ SafeArea เพื่อให้เต็มจอ
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFC107), // เหลืองสว่าง
              Color(0xFFFFB300), // เหลืองเข้มนิดหน่อย
            ],
          ),
        ),
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 2),

                    // App logo with shadow - ใช้รูปโลโก้จริง
                    Container(
                      width: 100, // เปลี่ยนให้ตรงกับหน้า login
                      height: 100, // เปลี่ยนให้ตรงกับหน้า login
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(24), // ตรงกับหน้า login
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withValues(alpha: 0.15), // ตรงกับหน้า login
                            blurRadius: 20, // ตรงกับหน้า login
                            offset: const Offset(0, 8), // ตรงกับหน้า login
                            spreadRadius: 0, // ลบ spreadRadius
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(24), // ตรงกับหน้า login
                        child: Image.asset(
                          'assets/images/app_icon.png',
                          width: 100, // เปลี่ยนให้ตรงกับหน้า login
                          height: 100, // เปลี่ยนให้ตรงกับหน้า login
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback ถ้าโหลดรูปไม่ได้
                            return const Icon(
                              Icons.location_on,
                              size: 50, // ตรงกับหน้า login
                              color: Color(0xFF4285F4),
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 32), // ลดจาก 40

                    // App name with better typography
                    Text(
                      AppLocalizations.of(context).welcome,
                      style: const TextStyle(
                        fontSize:
                            36, // ลดจาก 42 ให้ตรงกับ "CheckDarn" ในหน้า login
                        fontWeight: FontWeight.bold,
                        color: Colors.black87, // สีเดิม
                        fontFamily: 'NotoSansThai',
                        letterSpacing: 1.5, // ลดจาก 2
                        shadows: [
                          Shadow(
                            color: Colors.black12,
                            offset: Offset(1, 1), // ลดจาก 2,2
                            blurRadius: 3, // ลดจาก 4
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8), // ลดจาก 12

                    // App subtitle
                    const Text(
                      'CheckDarn',
                      style: TextStyle(
                        fontSize: 18, // ลดจาก 20
                        color: Colors.black54, // สีเดิม
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8, // ลดจาก 1
                      ),
                    ),

                    const SizedBox(height: 24), // ลดจาก 30

                    const Spacer(flex: 3),

                    // App slogan moved to bottom
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10), // ลดจาก 24,12
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(20), // ลดจาก 25
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withValues(alpha: 0.08), // ลดจาก 0.1
                            blurRadius: 8, // ลดจาก 10
                            offset: const Offset(0, 4), // ลดจาก 5
                          ),
                        ],
                      ),
                      child: Text(
                        AppLocalizations.of(context).appSlogan,
                        style: const TextStyle(
                          fontSize: 14, // ลดจาก 16
                          color: Colors.black87, // สีเดิม
                          fontWeight: FontWeight.w500,
                          fontFamily: 'NotoSansThai',
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 40), // เพิ่มระยะห่างจากด้านล่าง
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
