import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

// สคริปต์สำหรับทำความสะอาดข้อมูล test ที่ผิดพลาด
void main() async {
  await Firebase.initializeApp();

  final firestore = FirebaseFirestore.instance;

  print('🧹 เริ่มทำความสะอาดข้อมูล test...');

  try {
    // 1. ลบ reports ที่มีข้อความเกี่ยวกับ "แผ่นดินไหวแถวพานทอง"
    print('📝 กำลังหา reports ที่มีข้อความผิด...');

    final querySnapshot = await firestore
        .collection('reports')
        .where('description', isEqualTo: 'มีแผ่นดินไหวแถวพานทองครับ')
        .get();

    print('พบ ${querySnapshot.docs.length} รายการที่ต้องลบ');

    for (final doc in querySnapshot.docs) {
      final data = doc.data();
      print('กำลังลบ: ${doc.id}');
      print('  - Title: ${data['title']}');
      print('  - Description: ${data['description']}');
      print('  - Location: ${data['location']}');
      print('  - Coordinates: (${data['lat']}, ${data['lng']})');

      await doc.reference.delete();
      print('  ✅ ลบสำเร็จ');
    }

    // 2. ลบ reports ที่มี location = "Phan Thong, Chonburi" แต่พิกัดผิด
    print('\n📍 กำลังหา reports ที่มี location ผิด...');

    final locationQuery = await firestore
        .collection('reports')
        .where('location', isEqualTo: 'Phan Thong, Chonburi')
        .get();

    print('พบ ${locationQuery.docs.length} รายการที่มี location ผิด');

    for (final doc in locationQuery.docs) {
      final data = doc.data();
      print('กำลังลบ: ${doc.id}');
      print('  - Title: ${data['title']}');
      print('  - Location: ${data['location']}');
      print('  - Coordinates: (${data['lat']}, ${data['lng']})');

      await doc.reference.delete();
      print('  ✅ ลบสำเร็จ');
    }

    // 3. ลบ reports ที่มีพิกัด test เดิม (13.0827, 101.0028)
    print('\n🎯 กำลังหา reports ที่มีพิกัด test เดิม...');

    final testCoordQuery = await firestore
        .collection('reports')
        .where('lat', isEqualTo: 13.0827)
        .get();

    final docsToDelete = testCoordQuery.docs.where((doc) {
      final data = doc.data();
      return data['lng'] == 101.0028;
    }).toList();

    print('พบ ${docsToDelete.length} รายการที่มีพิกัด test เดิม');

    for (final doc in docsToDelete) {
      final data = doc.data();
      print('กำลังลบ: ${doc.id}');
      print('  - Title: ${data['title']}');
      print('  - Location: ${data['location']}');
      print('  - Coordinates: (${data['lat']}, ${data['lng']})');

      await doc.reference.delete();
      print('  ✅ ลบสำเร็จ');
    }

    // 4. ลบ reports ที่มี userId = 'test_user_123'
    print('\n👤 กำลังหา reports ที่เป็น test user...');

    final testUserQuery = await firestore
        .collection('reports')
        .where('userId', isEqualTo: 'test_user_123')
        .get();

    print('พบ ${testUserQuery.docs.length} รายการที่เป็น test user');

    for (final doc in testUserQuery.docs) {
      final data = doc.data();
      print('กำลังลบ: ${doc.id}');
      print('  - Title: ${data['title']}');
      print('  - UserId: ${data['userId']}');
      print('  - Location: ${data['location']}');

      await doc.reference.delete();
      print('  ✅ ลบสำเร็จ');
    }

    print('\n🎉 ทำความสะอาดข้อมูลเสร็จสิ้น!');

    // แสดงข้อมูลที่เหลือ
    print('\n📊 ตรวจสอบข้อมูลที่เหลือ...');
    final remainingQuery = await firestore
        .collection('reports')
        .orderBy('timestamp', descending: true)
        .limit(5)
        .get();

    print('Reports ล่าสุด ${remainingQuery.docs.length} รายการ:');
    for (int i = 0; i < remainingQuery.docs.length; i++) {
      final doc = remainingQuery.docs[i];
      final data = doc.data();
      print('${i + 1}. ${doc.id}');
      print('   Title: ${data['title']}');
      print('   Location: ${data['location']}');
      print('   Coordinates: (${data['lat']}, ${data['lng']})');
      if (data['timestamp'] != null) {
        final timestamp = data['timestamp'] as Timestamp;
        print('   Time: ${timestamp.toDate().toString()}');
      }
      print('');
    }
  } catch (e) {
    print('❌ เกิดข้อผิดพลาด: $e');
  }
}
