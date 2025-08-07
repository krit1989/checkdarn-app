import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // สำหรับ kIsWeb
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'routes/app_routes.dart';
import 'services/firebase_service.dart';
import 'services/auth_service.dart';
import 'services/cleanup_service.dart';
import 'services/enhanced_cache_service.dart';
import 'services/notification_service.dart';
import 'services/push_notification_service.dart';

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
      await FirebaseFirestore.instance.enablePersistence(
        const PersistenceSettings(synchronizeTabs: true),
      );
      print('✅ Firebase persistence enabled for Web!');
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CheckDarn - แผนที่เหตุการณ์',
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
  }
}
