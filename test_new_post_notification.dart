import 'package:cloud_firestore/cloud_firestore.dart';

/*
 * 🧪 ทดสอบการแจ้งเตือนโพสต์ใหม่ที่มีชื่อคนโพส (ปิดบางส่วน)
 * 
 * วิธีใช้:
 * 1. เปิด Terminal ใน VS Code
 * 2. รัน: dart test_new_post_notification.dart
 * 
 * ฟังก์ชันนี้จะ:
 * - สร้างโพสต์ทดสอบ
 * - Trigger การแจ้งเตือนที่มีชื่อคนโพส (ปิดบางส่วน)
 * - แสดงข้อความแจ้งเตือนที่ส่งให้ผู้ใช้อื่น
 */

void main() async {
  print('🧪 กำลังทดสอบการแจ้งเตือนโพสต์ใหม่ที่มีชื่อคนโพส...');

  try {
    final firestore = FirebaseFirestore.instance;

    // ข้อมูลโพสต์ทดสอบ
    final testReport = {
      'userId': 'test_user_123', // ID ของคนโพส
      'displayName': 'สมชาย ใจดี', // ชื่อคนโพส (จะถูกปิดเป็น "สมช***")
      'description': 'มีการตรวจจับความเร็วบริเวณนี้ ขอให้ขับขี่อย่างระมัดระวัง',
      'category': 'checkpoint',
      'location': 'ถนนพหลโยธิน',
      'district': 'หาดใหญ่',
      'province': 'สงขลา',
      'roadName': 'ถนนพหลโยธิน',
      'subDistrict': 'หาดใหญ่',
      'timestamp': FieldValue.serverTimestamp(),
      'latitude': 7.0187,
      'longitude': 100.4713,
      'isVerified': false,
      'likeCount': 0,
      'commentCount': 0,
      'imageUrl': null,
    };

    print('📝 ข้อมูลโพสต์ทดสอบ:');
    print('   👤 ชื่อคนโพส: ${testReport['displayName']}');
    print('   📍 หมวดหมู่: ${testReport['category']}');
    print(
        '   🌍 ตำแหน่ง: ${testReport['district']}, ${testReport['province']}');
    print('   💬 รายละเอียด: ${testReport['description']}');
    print('');

    // สร้างโพสต์ทดสอบใน Firestore
    print('📤 กำลังสร้างโพสต์ทดสอบ...');

    final docRef = await firestore.collection('reports').add(testReport);

    print('✅ สร้างโพสต์ทดสอบสำเร็จ!');
    print('📄 Document ID: ${docRef.id}');
    print('');

    print('🔔 คาดหวังผลลัพธ์การแจ้งเตือน:');
    print('   📱 Title: 🚓 ด่านตรวจ - หาดใหญ่, สงขลา');
    print(
        '   💬 Body: สมช*** รายงาน: มีการตรวจจับความเร็วบริเวณนี้ ขอให้ขับขี่อย่างระมัดระวัง');
    print('   📊 ส่งให้: ผู้ใช้ทั้งหมด (ยกเว้นคนโพส test_user_123)');
    print('');

    print('🔍 ตรวจสอบใน Firebase Console:');
    print('   1. Firebase Console > Functions > Logs');
    print('   2. ดู log ของ sendNewPostNotification');
    print('   3. ตรวจสอบข้อความแจ้งเตือนที่ส่งออก');
    print('');

    print('📱 ตรวจสอบในแอป Flutter:');
    print('   1. แอปของผู้ใช้อื่น (ไม่ใช่ test_user_123) ควรได้รับแจ้งเตือน');
    print('   2. ข้อความแจ้งเตือนควรมีชื่อ "สมช***" ใน body');
    print('   3. กดที่แจ้งเตือนควรเปิดโพสต์ที่สร้างใหม่');
    print('');

    // รอสักครู่แล้วลบโพสต์ทดสอบ
    print('⏳ รอ 30 วินาที แล้วลบโพสต์ทดสอบ...');
    await Future.delayed(Duration(seconds: 30));

    await docRef.delete();
    print('🗑️ ลบโพสต์ทดสอบแล้ว');
    print('');

    print('✅ การทดสอบเสร็จสิ้น!');
  } catch (error) {
    print('❌ เกิดข้อผิดพลาดในการทดสอบ:');
    print('   Error: $error');
    print('');
    print('💡 วิธีแก้ไข:');
    print('   1. ตรวจสอบการเชื่อมต่อ Firebase');
    print('   2. ตรวจสอบสิทธิ์การเขียนข้อมูลใน Firestore');
    print('   3. ตรวจสอบการตั้งค่า Functions');
  }
}
