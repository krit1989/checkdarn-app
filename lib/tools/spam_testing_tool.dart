// 🧪 เครื่องมือทดสอบระบบ Rate Limiting
// ไฟล์นี้ใช้เพื่อทดสอบว่าระบบป้องกัน spam ทำงานจริงหรือไม่

import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import '../models/event_model.dart';
import 'package:latlong2/latlong.dart';
import 'dart:io';

class SpamTestingTool {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔍 ตรวจสอบสถิติการโพสต์ของผู้ใช้
  static Future<Map<String, dynamic>> getUserPostStats(String userId) async {
    try {
      final now = DateTime.now();

      // ตรวจสอบใน 1 นาทีที่ผ่านมา
      final last1Minute = now.subtract(Duration(minutes: 1));
      final posts1Min = await _firestore
          .collection('reports')
          .where('userId', isEqualTo: userId)
          .where('timestamp', isGreaterThan: Timestamp.fromDate(last1Minute))
          .where('status', isEqualTo: 'active')
          .get();

      // ตรวจสอบใน 1 ชั่วโมงที่ผ่านมา
      final last1Hour = now.subtract(Duration(hours: 1));
      final posts1Hour = await _firestore
          .collection('reports')
          .where('userId', isEqualTo: userId)
          .where('timestamp', isGreaterThan: Timestamp.fromDate(last1Hour))
          .where('status', isEqualTo: 'active')
          .get();

      // ตรวจสอบในวันนี้
      final today = DateTime(now.year, now.month, now.day);
      final postsToday = await _firestore
          .collection('reports')
          .where('userId', isEqualTo: userId)
          .where('timestamp', isGreaterThan: Timestamp.fromDate(today))
          .where('status', isEqualTo: 'active')
          .get();

      // ตรวจสอบตามหมวดหมู่วันนี้
      final categoryStats = <String, int>{};
      for (final doc in postsToday.docs) {
        final category = doc.data()['category'] as String? ?? 'unknown';
        categoryStats[category] = (categoryStats[category] ?? 0) + 1;
      }

      return {
        'userId': userId,
        'postsInLast1Minute': posts1Min.docs.length,
        'postsInLast1Hour': posts1Hour.docs.length,
        'postsToday': postsToday.docs.length,
        'categoryBreakdown': categoryStats,
        'limits': {
          'perMinute': 1,
          'perHour': 3,
          'perDay': 5,
          'categoryLimits': {
            'animalLost': 3,
            'accident': 4,
            'traffic': 5,
            'other': 3,
          }
        },
        'canPost': {
          'minute': posts1Min.docs.length < 1,
          'hour': posts1Hour.docs.length < 3,
          'day': postsToday.docs.length < 5,
        },
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('❌ Error getting user stats: $e');
      return {'error': e.toString()};
    }
  }

  /// 🚨 ทดสอบการสร้างโพสต์หลายครั้งติดต่อกัน (เพื่อทดสอบ rate limiting)
  static Future<List<Map<String, dynamic>>> testSpamPrevention(
    String testUserId, {
    int numberOfAttempts = 6, // พยายามโพสต์ 6 ครั้ง (เกินขีดจำกัด 5)
  }) async {
    final results = <Map<String, dynamic>>[];

    print('🧪 Starting spam test for user: $testUserId');
    print('🎯 Attempting $numberOfAttempts posts in quick succession...');

    for (int i = 1; i <= numberOfAttempts; i++) {
      try {
        print('\n📝 Attempt $i/$numberOfAttempts');

        // ตรวจสอบว่าสามารถโพสต์ได้หรือไม่
        final canPost = await FirebaseService.canUserPostToday(testUserId);

        if (canPost) {
          // พยายามโพสต์จริง (แบบทดสอบ)
          final testReport = await _createTestPost(testUserId, i);
          results.add({
            'attempt': i,
            'success': true,
            'action': 'POST_CREATED',
            'reportId': testReport['reportId'],
            'timestamp': DateTime.now().toIso8601String(),
            'message': 'Post created successfully'
          });
          print('✅ Attempt $i: SUCCESS - Post created');
        } else {
          results.add({
            'attempt': i,
            'success': false,
            'action': 'RATE_LIMITED',
            'timestamp': DateTime.now().toIso8601String(),
            'message': 'Rate limit exceeded'
          });
          print('🚫 Attempt $i: BLOCKED - Rate limit exceeded');
        }

        // รอ 0.5 วินาทีเพื่อจำลองการโพสต์เร็วๆ
        await Future.delayed(Duration(milliseconds: 500));
      } catch (e) {
        results.add({
          'attempt': i,
          'success': false,
          'action': 'ERROR',
          'error': e.toString(),
          'timestamp': DateTime.now().toIso8601String(),
          'message': 'Error occurred during attempt'
        });
        print('❌ Attempt $i: ERROR - $e');
      }
    }

    return results;
  }

  /// 📊 สร้างรายงานการทดสอบ
  static Future<void> generateSpamTestReport(String testUserId) async {
    print('\n🧪 === SPAM PREVENTION TEST REPORT ===');

    // ขั้นตอนที่ 1: ดูสถิติปัจจุบัน
    print('\n📊 Step 1: Current User Statistics');
    final initialStats = await getUserPostStats(testUserId);
    _printStats(initialStats);

    // ขั้นตอนที่ 2: ทดสอบ spam
    print('\n🚨 Step 2: Spam Prevention Test');
    final spamResults =
        await testSpamPrevention(testUserId, numberOfAttempts: 8);

    // ขั้นตอนที่ 3: วิเคราะห์ผลลัพธ์
    print('\n📈 Step 3: Test Results Analysis');
    final successfulPosts =
        spamResults.where((r) => r['success'] == true).length;
    final blockedPosts =
        spamResults.where((r) => r['action'] == 'RATE_LIMITED').length;
    final errors = spamResults.where((r) => r['action'] == 'ERROR').length;

    print('✅ Successful posts: $successfulPosts');
    print('🚫 Blocked by rate limiting: $blockedPosts');
    print('❌ Errors: $errors');

    // ขั้นตอนที่ 4: สถิติหลังทดสอบ
    print('\n📊 Step 4: Updated User Statistics');
    final finalStats = await getUserPostStats(testUserId);
    _printStats(finalStats);

    // สรุป
    print('\n🎯 TEST SUMMARY:');
    if (successfulPosts <= 5 && blockedPosts > 0) {
      print('✅ PASS: Rate limiting is working correctly!');
      print('   - Maximum of 5 posts were allowed');
      print('   - Additional attempts were properly blocked');
    } else {
      print('❌ FAIL: Rate limiting may not be working properly');
      print('   - Expected: Max 5 successful posts, some blocked');
      print('   - Actual: $successfulPosts successful, $blockedPosts blocked');
    }
  }

  /// 🏭 สร้างโพสต์ทดสอบ
  static Future<Map<String, dynamic>> _createTestPost(
      String userId, int attemptNumber) async {
    final docRef = FirebaseFirestore.instance.collection('reports').doc();

    await docRef.set({
      'id': docRef.id,
      'userId': userId,
      'userName': 'Test User (Spam Test)',
      'category': 'other',
      'categoryKey': 'other',
      'title': 'TEST POST #$attemptNumber (Spam Prevention Test)',
      'description':
          'This is a test post created during spam prevention testing. Attempt #$attemptNumber',
      'location': GeoPoint(13.7563, 100.5018), // Bangkok coordinates
      'district': 'Test District',
      'province': 'Test Province',
      'locationString': 'Test Location',
      'status': 'active',
      'timestamp': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'ttl': Timestamp.fromDate(DateTime.now().add(Duration(days: 30))),
      'imageUrl': null,
      'isTestData': true, // มาร์คว่าเป็นข้อมูลทดสอบ
    });

    return {
      'reportId': docRef.id,
      'userId': userId,
      'attemptNumber': attemptNumber,
    };
  }

  /// 🧹 ล้างข้อมูลทดสอบ
  static Future<void> cleanupTestData() async {
    try {
      print('🧹 Cleaning up test data...');

      final testPosts = await FirebaseFirestore.instance
          .collection('reports')
          .where('isTestData', isEqualTo: true)
          .get();

      for (final doc in testPosts.docs) {
        await doc.reference.delete();
      }

      print('✅ Cleaned up ${testPosts.docs.length} test posts');
    } catch (e) {
      print('❌ Error cleaning up test data: $e');
    }
  }

  /// 📊 แสดงสถิติ
  static void _printStats(Map<String, dynamic> stats) {
    if (stats.containsKey('error')) {
      print('❌ Error: ${stats['error']}');
      return;
    }

    print('👤 User: ${stats['userId']}');
    print('⏱️  Posts in last 1 minute: ${stats['postsInLast1Minute']}/1');
    print('⏰ Posts in last 1 hour: ${stats['postsInLast1Hour']}/3');
    print('📅 Posts today: ${stats['postsToday']}/5');
    print('📊 Category breakdown: ${stats['categoryBreakdown']}');

    final canPost = stats['canPost'] as Map<String, dynamic>;
    print('🔍 Can post now?');
    print('   - Minute check: ${canPost['minute'] ? '✅' : '🚫'}');
    print('   - Hour check: ${canPost['hour'] ? '✅' : '🚫'}');
    print('   - Day check: ${canPost['day'] ? '✅' : '🚫'}');
  }
}
