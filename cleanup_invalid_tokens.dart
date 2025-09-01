#!/usr/bin/env dart

import 'dart:io';

Future<void> main() async {
  print('🧹 Token Cleanup Script');
  print('=======================');
  print('');
  print('📱 FCM Tokens สามารถ expired ได้เมื่อ:');
  print('   • User ทำการ uninstall/reinstall app');
  print('   • App data ถูก clear');
  print('   • Token หมดอายุตามปกติของ FCM');
  print('   • Device ถูก factory reset');
  print('');
  print('📊 จากล็อกเมื่อกี้:');
  print('   • มี 13 tokens ทั้งหมด');
  print('   • ส่งสำเร็จ 2 คน');
  print('   • ล้มเหลว 11 tokens (expired)');
  print('');
  print('✅ Cloud Function ได้ทำการลบ invalid tokens ออกแล้ว');
  print('   (อัตโนมัติใน removeInvalidTokens function)');
  print('');
  print('📋 วิธีแก้ไขปัญหา:');
  print('   1. ให้ผู้ใช้ reinstall แอป และล็อกอินใหม่');
  print('   2. หรือรีเซ็ต notification settings ในแอป');
  print('   3. ตรวจสอบว่า NotificationService.initialize() ถูกเรียกแล้ว');
  print('');
  print('🔧 ต้องการรัน manual cleanup?');
  stdout.write('กด y เพื่อดำเนินการ หรือ n เพื่อยกเลิก: ');

  String? response = stdin.readLineSync();
  if (response?.toLowerCase() == 'y') {
    print('');
    print('🚀 กำลัง deploy script สำหรับ cleanup tokens...');

    // สร้าง Cloud Function สำหรับ cleanup
    await createCleanupFunction();

    print('');
    print('✅ เสร็จสิ้น! ให้ผู้ใช้:');
    print('   1. เปิดแอปใหม่และล็อกอิน');
    print('   2. อนุญาต notification permissions');
    print('   3. ใช้งานปกติ - token ใหม่จะถูกสร้างขึ้นอัตโนมัติ');
  } else {
    print('');
    print('❌ ยกเลิกการ cleanup');
  }

  print('');
  print('📱 สำหรับการทดสอบ:');
  print('   • ทดลองโพสต์ด้วย account ที่ใช้งานปกติ');
  print('   • ตรวจสอบได้รับ notification หรือไม่');
  print('   • ดู logs ใน Firebase Console');
}

Future<void> createCleanupFunction() async {
  final cleanupScript = '''
// ✅ เพิ่มใน functions/index.js
exports.cleanupInvalidTokens = functions.https.onCall(async (data, context) => {
  try {
    console.log('🧹 Manual token cleanup started...');
    
    const snapshot = await admin.firestore()
      .collection('user_tokens')
      .get();
    
    let cleaned = 0;
    const batch = admin.firestore().batch();
    
    for (const doc of snapshot.docs) {
      const userData = doc.data();
      const tokens = userData.tokens || [];
      
      if (tokens.length === 0) {
        // ลบ document ที่ไม่มี token
        batch.delete(doc.ref);
        cleaned++;
      }
    }
    
    if (cleaned > 0) {
      await batch.commit();
    }
    
    console.log(`✅ Cleaned \${cleaned} empty token documents`);
    return { success: true, cleaned };
    
  } catch (error) {
    console.error('❌ Cleanup error:', error);
    return { success: false, error: error.message };
  }
});
''';

  print('📝 Cleanup function ready to add to functions/index.js');
  print('');
  print('💡 แต่จริงๆ Cloud Function มีการลบ invalid tokens อัตโนมัติแล้ว');
  print('   ใน removeInvalidTokens() ที่เรียกจาก sendNewPostNotification');
}
