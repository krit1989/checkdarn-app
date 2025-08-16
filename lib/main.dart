import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // สำหรับ kIsWeb
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'routes/app_routes.dart';
import 'services/firebase_service.dart';
import 'services/auth_service.dart';
import 'services/cleanup_service.dart';
import 'services/enhanced_cache_service.dart';
import 'services/notification_service.dart';
import 'services/push_notification_service.dart';
import 'services/smart_location_service.dart';
import 'services/topic_subscription_service.dart';
import 'providers/language_provider.dart';
import 'generated/gen_l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // เก็บแค่ Firebase core initialization - จำเป็นต้องมี
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // เริ่มแอพทันที - ย้ายงานหนักไปทำทีหลัง
  runApp(const MyApp());

  // ทำงานหนักหลังจากแอพเริ่มแล้ว (ไม่บล็อค UI)
  _initializeBackgroundServices();
}

/// ย้ายงานหนักมาทำเป็น background หลังแอพเริ่มแล้ว
void _initializeBackgroundServices() async {
  // รอให้แอพเริ่มต้นเสร็จก่อน
  await Future.delayed(const Duration(milliseconds: 500));

  try {
    // 🚀 เปิด Local Persistence เพื่อเพิ่มความเร็ว (Platform-specific)
    if (kIsWeb) {
      // Web persistence ใช้วิธีอื่น
      print('✅ Firebase persistence skipped for Web (will use browser cache)');
    } else {
      // สำหรับ Mobile จะตั้งค่าใน Settings ด้านล่าง
      print('✅ Firebase persistence will be set via Settings for Mobile');
    }

    // ตั้งค่า Firestore settings สำหรับประสิทธิภาพที่ดีขึ้น
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED, // เพิ่ม cache
    );

    // Initialize services แบบ background
    await AuthService.initialize();
    await EnhancedCacheService.initialize();
    await FirebaseService.initializeAndMigrate();

    // 🔔 เริ่ม Notification Services
    await NotificationService.initialize();
    await PushNotificationService.initialize();

    // 🗺️ เริ่ม Topic Subscription Service (ประหยัดค่าใช้จ่าย 99.9%!)
    _startTopicSubscriptionService();

    // 🌍 เริ่ม Smart Location Service (Geographic Targeting)
    _startSmartLocationService();

    // 🚀 เริ่ม Smart Prefetch System
    _startSmartPrefetch();

    // 🧹 เริ่มระบบลบโพสต์อัตโนมัติ (ทุก 24 ชั่วโมง)
    CleanupService.startAutoCleanup();

    print('✅ Background services initialized successfully!');
  } catch (e) {
    print('⚠️ Background services initialization error: $e');
  }
}

/// 🚀 Smart Prefetch System - โหลดข้อมูลล่วงหน้าแบบฉลาด
void _startSmartPrefetch() {
  // เริ่ม prefetch หลังจาก app โหลดเสร็จ 2 วินาทีเพื่อไม่รบกวน startup
  Future.delayed(const Duration(seconds: 2), () {
    FirebaseService.prefetchRecentReports();
    print('🚀 Smart prefetch started - data will load instantly!');
  });
}

/// 🗺️ **Topic Subscription Service Starter**
/// เริ่ม Auto Subscribe Topics ตามตำแหน่ง เพื่อประหยัดค่าใช้จ่าย 99.9%
void _startTopicSubscriptionService() {
  // เริ่มหลังจาก app โหลดเสร็จ 3 วินาที เพื่อไม่รบกวน startup
  Future.delayed(const Duration(seconds: 3), () async {
    try {
      List<String> topics =
          await TopicSubscriptionService.subscribeToLocationTopics();
      if (topics.isNotEmpty) {
        print('🎯 Topic subscription updated successfully - Cost optimized!');

        // แสดงข้อมูล topics ปัจจุบัน
        Map<String, dynamic> stats =
            await TopicSubscriptionService.getTopicStats();
        print('📊 Current topics: ${topics}');
        print('💰 Saving 99.9% compared to mass broadcasting!');
        print('📈 Stats: ${stats}');
      } else {
        print('⚠️ Topic subscription update failed, will retry later');

        // Retry หลังจาก 30 วินาที
        Future.delayed(const Duration(seconds: 30), () {
          TopicSubscriptionService.subscribeToLocationTopics();
        });
      }
    } catch (e) {
      print('❌ Error starting topic subscription service: $e');
    }
  });
}

/// 🌍 **Smart Location Service Starter**
/// เริ่มระบบติดตามตำแหน่งอย่างฉลาดสำหรับ Geographic Targeting
void _startSmartLocationService() {
  // เริ่มหลังจาก app โหลดเสร็จ 4 วินาที เพื่อไม่รบกวน startup
  Future.delayed(const Duration(seconds: 4), () async {
    try {
      // อัปเดตตำแหน่งครั้งแรก
      bool success =
          await SmartLocationService.updateUserLocation(forceUpdate: true);
      if (success) {
        print(
            '🌍 Smart Location Service: Initial location updated successfully');

        // เริ่มติดตามตำแหน่งแบบเรียลไทม์
        SmartLocationService.startLocationTracking();
        print('🎯 Smart Location Service: Real-time tracking started');
      } else {
        print('⚠️ Smart Location Service: Initial location update failed');
      }
    } catch (e) {
      print('❌ Error starting Smart Location Service: $e');
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => LanguageProvider()),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          return MaterialApp(
            title: 'CheckDarn - แผนที่เหตุการณ์',
            locale: languageProvider.currentLocale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en', ''), // English
              Locale('th', ''), // Thai
            ],
            theme: ThemeData(
              primarySwatch: Colors.blue,
              fontFamily: 'Sarabun',
            ),
            navigatorKey:
                NotificationService.navigatorKey, // เพิ่ม global navigator key
            initialRoute: AppRoutes.splash,
            routes: AppRoutes.routes,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
