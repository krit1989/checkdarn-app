import 'package:cloud_firestore/cloud_firestore.dart';

class CommentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const int _maxCommentsPerDay = 10; // 10 คอมเมนต์ต่อคนต่อวัน
  static const int _maxCommentLength = 200; // 200 ตัวอักษร

  /// ตรวจสอบว่าผู้ใช้คอมเมนต์เกินขีดจำกัดวันนี้แล้วหรือยัง
  static Future<bool> canUserCommentToday(String userId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // นับคอมเมนต์ทั้งหมดของผู้ใช้วันนี้
      final todayComments = await _firestore
          .collectionGroup('comments') // ค้นหาทุก comments collection
          .where('userId', isEqualTo: userId)
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      final commentCount = todayComments.docs.length;
      print(
          'Debug: User $userId has commented $commentCount times today (limit: $_maxCommentsPerDay)');

      return commentCount < _maxCommentsPerDay;
    } catch (e) {
      print('Error checking daily comment limit: $e');
      return true; // ถ้าเกิดข้อผิดพลาด ให้อนุญาตคอมเมนต์ได้
    }
  }

  /// เพิ่มคอมเมนต์ใหม่
  static Future<String> addComment({
    required String reportId,
    required String comment,
    required String userId,
    String? displayName, // เพิ่ม displayName เป็น optional
  }) async {
    try {
      // ตรวจสอบความยาวข้อความ
      if (comment.trim().length > _maxCommentLength) {
        throw Exception('ความคิดเห็นยาวเกินไป');
      }

      if (comment.trim().isEmpty) {
        throw Exception('กรุณาพิมพ์ความคิดเห็น');
      }

      // ตรวจสอบขีดจำกัดคอมเมนต์ต่อวัน
      final canComment = await canUserCommentToday(userId);
      if (!canComment) {
        throw Exception('ไม่สามารถคอมเมนต์ได้ในขณะนี้');
      }

      // ฟิลเตอร์คำหยาบอย่างง่าย
      final filteredComment = _filterBadWords(comment.trim());

      final now = DateTime.now();
      final expireAt =
          now.add(const Duration(days: 7)); // หมดอายุตาม TTL เดียวกับโพสต์

      final docRef = await _firestore
          .collection('reports')
          .doc(reportId)
          .collection('comments')
          .add({
        'comment': filteredComment,
        'userId': userId,
        'displayName': displayName ?? 'ผู้ใช้ไม่ระบุชื่อ', // เพิ่ม displayName
        'timestamp': FieldValue.serverTimestamp(),
        'expireAt': Timestamp.fromDate(expireAt), // TTL สำหรับคอมเมนต์
        'reported': false, // สำหรับการรายงานคอมเมนต์
        'reportCount': 0, // จำนวนการรายงาน
      });

      print('Comment added successfully with ID: ${docRef.id}');

      // 🔔 ส่งแจ้งเตือนให้เจ้าของโพสต์ (ถ้าไม่ใช่คนเดียวกัน)
      await _notifyPostOwner(reportId, userId, filteredComment, displayName);

      return docRef.id;
    } catch (e) {
      print('Error adding comment: $e');
      rethrow;
    }
  }

  /// ดึงคอมเมนต์ของโพสต์
  static Stream<QuerySnapshot> getCommentsStream(String reportId) {
    return _firestore
        .collection('reports')
        .doc(reportId)
        .collection('comments')
        .orderBy('timestamp', descending: true) // ใหม่ไปเก่า
        .limit(50) // จำกัด 50 คอมเมนต์ล่าสุด
        .snapshots();
  }

  /// รายงานคอมเมนต์ที่ไม่เหมาะสม
  static Future<void> reportComment({
    required String reportId,
    required String commentId,
    required String reporterId,
  }) async {
    try {
      final commentRef = _firestore
          .collection('reports')
          .doc(reportId)
          .collection('comments')
          .doc(commentId);

      await commentRef.update({
        'reportCount': FieldValue.increment(1),
        'reported': true,
        'lastReportedBy': reporterId,
        'lastReportedAt': FieldValue.serverTimestamp(),
      });

      print('Comment reported successfully');
    } catch (e) {
      print('Error reporting comment: $e');
      rethrow;
    }
  }

  /// นับจำนวนคอมเมนต์ของโพสต์
  static Future<int> getCommentCount(String reportId) async {
    try {
      final snapshot = await _firestore
          .collection('reports')
          .doc(reportId)
          .collection('comments')
          .get();

      return snapshot.docs.length;
    } catch (e) {
      print('Error getting comment count: $e');
      return 0;
    }
  }

  /// ฟิลเตอร์คำหยาบ (อย่างง่าย)
  static String _filterBadWords(String text) {
    final badWords = [
      'ห่า',
      'เหี้ย',
      'สัส',
      'ควาย',
      'ไอ้สัส',
      'เศร้า',
      'โง่',
      'ปี้',
      'แม่ง',
      'ฟาค',
      'fuck',
      'shit',
      'damn'
    ];

    String filteredText = text;
    for (String word in badWords) {
      final regex = RegExp(word, caseSensitive: false);
      filteredText = filteredText.replaceAll(regex, '*' * word.length);
    }

    return filteredText;
  }

  /// ฟอร์แมทเวลาสำหรับคอมเมนต์
  static String formatCommentTime(Timestamp? timestamp) {
    if (timestamp == null) return 'เมื่อสักครู่';

    final dateTime = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'เมื่อสักครู่';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} นาทีที่แล้ว';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} ชม.ที่แล้ว';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} วันที่แล้ว';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year + 543}';
    }
  }

  /// ข้อมูลขีดจำกัด
  static int get maxCommentsPerDay => _maxCommentsPerDay;
  static int get maxCommentLength => _maxCommentLength;

  /// 🔔 แจ้งเตือนเจ้าของโพสต์เมื่อมีคอมเมนต์ใหม่
  /// - ไม่ต้องใช้ Index เพิ่ม เพราะใช้ doc.get() แทน query
  /// - ตรวจสอบว่าคนคอมเมนต์ไม่ใช่เจ้าของโพสต์เอง
  static Future<void> _notifyPostOwner(
    String reportId,
    String commenterUserId,
    String comment,
    String? commenterDisplayName,
  ) async {
    try {
      // ดึงข้อมูลโพสต์เพื่อหาเจ้าของ
      final reportDoc =
          await _firestore.collection('reports').doc(reportId).get();

      if (!reportDoc.exists) {
        print('Report not found: $reportId');
        return;
      }

      final reportData = reportDoc.data() as Map<String, dynamic>;
      final postOwnerId = reportData['userId'] as String?;
      final postTitle = reportData['title'] as String? ??
          reportData['description'] as String? ??
          'โพสต์';

      // ตรวจสอบว่าคนคอมเมนต์ไม่ใช่เจ้าของโพสต์เอง
      if (postOwnerId == null || postOwnerId == commenterUserId) {
        print('Skip notification: same user or no owner');
        return;
      }

      print('🔔 Sending notification to post owner: $postOwnerId');
      print('📝 Post: $postTitle');
      print(
          '💬 Comment: ${comment.length > 50 ? comment.substring(0, 50) + '...' : comment}');
      print('👤 Commenter: ${commenterDisplayName ?? 'ผู้ใช้ไม่ระบุชื่อ'}');

      // TODO: ส่งแจ้งเตือนจริงๆ ผ่าน FCM
      // - ดึง FCM token ของ postOwnerId
      // - ส่ง push notification
      // - บันทึกประวัติการแจ้งเตือน (ถ้าต้องการ)
    } catch (e) {
      print('Error notifying post owner: $e');
      // ไม่ throw error เพื่อไม่ให้กระทบการเพิ่มคอมเมนต์
    }
  }
}
