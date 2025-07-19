import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class CleanupService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'reports';
  static Timer? _cleanupTimer;

  /// เริ่มต้นระบบลบโพสต์อัตโนมัติ
  static void startAutoCleanup() {
    print('🧹 Starting auto cleanup service...');

    // รันทันทีครั้งแรก
    _performCleanup();

    // ตั้งให้รันทุก 1 ชั่วโมง
    _cleanupTimer = Timer.periodic(const Duration(hours: 1), (timer) {
      _performCleanup();
    });

    print('🧹 Auto cleanup service started - runs every 1 hour');
  }

  /// หยุดระบบลบอัตโนมัติ
  static void stopAutoCleanup() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    print('🧹 Auto cleanup service stopped');
  }

  /// ลบโพสต์ที่เก่ากว่า 48 ชั่วโมง (ใช้ Batch สำหรับ Firebase ฟรี)
  static Future<void> _performCleanup() async {
    try {
      final cutoffTime = DateTime.now().subtract(const Duration(hours: 48));
      final cutoffTimestamp = Timestamp.fromDate(cutoffTime);

      print('🧹 Starting cleanup for posts older than: $cutoffTime');

      // ค้นหาโพสต์ที่เก่ากว่า 48 ชั่วโมง (จำกัด 15 รายการต่อครั้งเพื่อประหยัด quota)
      final oldPostsQuery = await _firestore
          .collection(_collection)
          .where('timestamp', isLessThan: cutoffTimestamp)
          .limit(
              15) // จำกัดจำนวนเพื่อประหยัด Firebase quota และหลีกเลี่ยง batch size limit
          .get();

      if (oldPostsQuery.docs.isEmpty) {
        print('🧹 No old posts found to cleanup');
        return;
      }

      print(
          '🧹 Found ${oldPostsQuery.docs.length} old posts to delete (batch mode)');

      // ใช้ Batch Write สำหรับประสิทธิภาพดีกว่า
      final batch = _firestore.batch();
      int deletedCount = 0;

      for (final doc in oldPostsQuery.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>?;
          final timestamp = data?['timestamp'] as Timestamp?;
          final category = data?['category'] ?? 'unknown';

          print(
              '🗑️ Adding to batch delete: ${doc.id} - Category: $category, Age: ${timestamp?.toDate()}');

          // เพิ่มการลบโพสต์เข้า batch
          batch.delete(doc.reference);
          deletedCount++;

          // ลบ comments แบบ batch ด้วย (แต่จำกัดจำนวน)
          await _addCommentDeletionsToBatch(batch, doc.id);
        } catch (e) {
          print('❌ Error adding post ${doc.id} to batch: $e');
        }
      }

      // Execute batch write (ประหยัด write operations มาก)
      if (deletedCount > 0) {
        await batch.commit();
        print(
            '🧹 Batch cleanup completed - Deleted $deletedCount posts with comments');
      }
    } catch (e) {
      print('❌ Error during cleanup: $e');
    }
  }

  /// เพิ่มการลบ comments เข้า batch (จำกัดจำนวนเพื่อประหยัด quota)
  static Future<void> _addCommentDeletionsToBatch(
      WriteBatch batch, String postId) async {
    try {
      // จำกัดการ read comments เพื่อประหยัด Firebase quota
      final commentsQuery = await _firestore
          .collection(_collection)
          .doc(postId)
          .collection('comments')
          .limit(
              5) // จำกัดจำนวน comments เพื่อไม่ให้ batch เต็ม (Firebase มี limit 500 operations/batch)
          .get();

      if (commentsQuery.docs.isNotEmpty) {
        print(
            '🗑️ Adding ${commentsQuery.docs.length} comments to batch for post $postId');

        for (final commentDoc in commentsQuery.docs) {
          batch.delete(commentDoc.reference);
        }
      }
    } catch (e) {
      print('❌ Error adding comments to batch for post $postId: $e');
    }
  }

  /// ลบโพสต์เก่าด้วยตนเอง (สำหรับทดสอบ)
  static Future<int> manualCleanup() async {
    print('🧹 Starting manual cleanup...');

    // รันหลายรอบเพื่อให้ลบหมด (เพราะจำกัด 15 รายการต่อครั้ง)
    int totalRounds = 0;
    bool hasOldPosts = true;

    while (hasOldPosts && totalRounds < 10) {
      // จำกัดไม่เกิน 10 รอบเพื่อป้องกัน infinite loop
      await _performCleanup();
      totalRounds++;

      // ตรวจสอบว่ายังมีโพสต์เก่าอีกไหม
      final cutoffTime = DateTime.now().subtract(const Duration(hours: 48));
      final cutoffTimestamp = Timestamp.fromDate(cutoffTime);
      final oldPostsCheck = await _firestore
          .collection(_collection)
          .where('timestamp', isLessThan: cutoffTimestamp)
          .limit(1)
          .get();

      hasOldPosts = oldPostsCheck.docs.isNotEmpty;

      if (hasOldPosts) {
        print('🧹 Still have old posts, running round ${totalRounds + 1}...');
      }
    }

    // ตรวจสอบจำนวนโพสต์ที่เหลือ
    final freshPosts = await _firestore
        .collection(_collection)
        .where('timestamp',
            isGreaterThan: Timestamp.fromDate(
                DateTime.now().subtract(const Duration(hours: 48))))
        .get();

    print('🧹 Manual cleanup completed after $totalRounds rounds');
    print('📊 Fresh posts (48h): ${freshPosts.docs.length}');

    return freshPosts.docs.length;
  }

  /// ดูสถิติโพสต์
  static Future<Map<String, int>> getPostStatistics() async {
    try {
      final now = DateTime.now();
      final fortyEightHoursAgo = now.subtract(const Duration(hours: 48));

      // จำนวนโพสต์ทั้งหมด
      final totalQuery = await _firestore.collection(_collection).get();

      // จำนวนโพสต์สดใหม่ (48 ชั่วโมง)
      final freshQuery = await _firestore
          .collection(_collection)
          .where('timestamp',
              isGreaterThan: Timestamp.fromDate(fortyEightHoursAgo))
          .get();

      return {
        'total': totalQuery.docs.length,
        'fresh': freshQuery.docs.length,
        'old': totalQuery.docs.length - freshQuery.docs.length,
      };
    } catch (e) {
      print('❌ Error getting statistics: $e');
      return {'total': 0, 'fresh': 0, 'old': 0};
    }
  }
}
