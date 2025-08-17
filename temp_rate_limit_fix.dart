// แก้ไขชั่วคราวสำหรับ rate limiting
// ให้แทนที่ในไฟล์ firebase_service.dart

static Future<bool> canUserPostToday(String userId) async {
  try {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    
    print('🔍 Checking daily post limit for user: $userId');
    print('⏰ Check range: ${startOfDay.toIso8601String()} to ${now.toIso8601String()}');

    // Query แบบง่ายๆ ที่ไม่ต้องการ composite index
    final querySnapshot = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .get()
        .timeout(const Duration(seconds: 8));

    // กรองข้อมูลที่มี status = 'active' ฝั่ง client
    final activePosts = querySnapshot.docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['status'] == 'active';
    }).toList();

    final postsToday = activePosts.length;
    print('📊 Posts today: $postsToday / $_maxPostsPerDay');

    // แจ้งเตือนเมื่อใกล้ถึงขีดจำกัด
    if (postsToday >= 3 && postsToday < _maxPostsPerDay) {
      print('⚠️ Warning: User approaching daily limit ($postsToday/${_maxPostsPerDay})');
    }

    final canPost = postsToday < _maxPostsPerDay;
    print(canPost ? '✅ User can post' : '🚫 Daily limit exceeded');
    
    return canPost;
  } catch (e) {
    print('❌ Error checking daily post limit: $e');
    
    // การจัดการ error ที่เข้มงวดกว่า
    final errorMessage = e.toString().toLowerCase();
    
    if (errorMessage.contains('permission-denied') ||
        errorMessage.contains('unauthorized')) {
      print('🚫 Permission denied - blocking post');
      throw Exception('ไม่มีสิทธิ์ในการตรวจสอบข้อมูล กรุณาล็อกอินใหม่');
    }
    
    if (errorMessage.contains('failed-precondition') ||
        errorMessage.contains('requires an index') ||
        errorMessage.contains('index') ||
        errorMessage.contains('composite')) {
      print('🔧 Index missing - allowing post temporarily');
      print('📋 Please wait 1-2 minutes for index to be ready');
      return true; // อนุญาตชั่วคราวเมื่อ index ยังไม่พร้อม
    }
    
    if (errorMessage.contains('timeout') ||
        errorMessage.contains('deadline-exceeded')) {
      print('⏰ Timeout - allowing post');
      return true; // อนุญาตเมื่อ timeout
    }
    
    if (errorMessage.contains('network') ||
        errorMessage.contains('unavailable')) {
      print('🌐 Network issue - allowing post');
      return true; // อนุญาตเมื่อมีปัญหาเครือข่าย
    }
    
    // สำหรับ error อื่นๆ ให้บล็อกเพื่อความปลอดภัย
    print('⚠️ Unknown error - blocking post for security: $e');
    throw Exception('เกิดข้อผิดพลาดในการตรวจสอบข้อมูล กรุณาลองใหม่อีกครั้ง');
  }
}
