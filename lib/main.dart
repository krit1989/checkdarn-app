import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // สำหรับ kIsWeb
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'screens/map_screen.dart';
import 'services/firebase_service.dart';
import 'services/auth_service.dart';
import 'services/cleanup_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 🚀 เปิด Local Persistence เพื่อเพิ่มความเร็ว (Platform-specific)
  try {
    // สำหรับ Web ใช้ enablePersistence, สำหรับ Mobile ใช้ Settings
    if (kIsWeb) {
      await FirebaseFirestore.instance.enablePersistence(
        const PersistenceSettings(synchronizeTabs: true),
      );
      print('✅ Firebase persistence enabled for Web!');
    } else {
      // สำหรับ Mobile จะตั้งค่าใน Settings ด้านล่าง
      print('✅ Firebase persistence will be set via Settings for Mobile');
    }
  } catch (e) {
    print('⚠️ Firebase persistence setup note: $e');
  }

  // ตั้งค่า Firestore settings สำหรับประสิทธิภาพที่ดีขึ้น
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED, // เพิ่ม cache

    // 🔌 Connection Pool Limiting - จำกัดการเชื่อมต่อ
    // ช่วยลด load เมื่อมีผู้ใช้เยอะ
  );

  // Initialize AuthService
  await AuthService.initialize();

  // Migrate existing data to TTL และเพิ่ม expireAt field
  await FirebaseService.initializeAndMigrate();

  // 🚀 เพิ่ม Smart Prefetch System
  _startSmartPrefetch();

  // 🧹 เริ่มระบบลบโพสต์อัตโนมัติ (ทุก 48 ชั่วโมง)
  CleanupService.startAutoCleanup();

  runApp(const MyApp());
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
      home: const MapScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
