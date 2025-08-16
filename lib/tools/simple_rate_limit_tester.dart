import 'dart:async';
import '../services/firebase_service.dart';

/// 🧪 เครื่องมือทดสอบ Rate Limiting แบบง่าย
class RateLimitTester {
  /// 🔍 ทดสอบว่าระบบ rate limiting ทำงานหรือไม่
  static Future<void> testRateLimiting(String testUserId) async {
    print('\n🧪 === RATE LIMITING TEST ===');
    print('👤 Testing user: $testUserId');
    print('⏰ Current time: ${DateTime.now()}');

    // ทดสอบ 6 ครั้งติดต่อกัน
    for (int i = 1; i <= 6; i++) {
      print('\n📝 Test attempt $i/6');

      try {
        final canPost = await FirebaseService.canUserPostToday(testUserId);

        if (canPost) {
          print('✅ Attempt $i: ALLOWED - User can post');
        } else {
          print('🚫 Attempt $i: BLOCKED - Rate limit exceeded');
        }

        // รอ 0.5 วินาที
        await Future.delayed(Duration(milliseconds: 500));
      } catch (e) {
        print('❌ Attempt $i: ERROR - $e');
      }
    }

    print('\n🎯 Test completed!');
  }

  /// 📊 ดูสถิติผู้ใช้ปัจจุบัน
  static Future<void> checkUserStats(String userId) async {
    print('\n📊 === USER STATISTICS ===');
    print('👤 User ID: $userId');

    try {
      // เช็คว่าสามารถโพสต์ได้หรือไม่
      final canPost = await FirebaseService.canUserPostToday(userId);
      print('🔍 Can post today: ${canPost ? '✅ YES' : '🚫 NO'}');

      // เช็คตามหมวดหมู่
      print('\n📋 Category limits check:');
      // สัตว์หาย
      // final canPostAnimal = await FirebaseService.canUserPostCategory(userId, EventCategory.animalLost);
      // print('🐕 Animal Lost: ${canPostAnimal ? '✅ OK' : '🚫 LIMIT REACHED'}');
    } catch (e) {
      print('❌ Error checking stats: $e');
    }
  }
}

/// 🎯 ตัวอย่างการใช้งาน
/// 
/// เรียกฟังก์ชันนี้จาก debug console หรือ test file:
/// 
/// ```dart
/// // ทดสอบ rate limiting
/// await RateLimitTester.testRateLimiting('test-user-123');
/// 
/// // ดูสถิติผู้ใช้
/// await RateLimitTester.checkUserStats('real-user-id');
/// ```
