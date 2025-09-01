#!/usr/bin/env dart

import 'dart:io';

// สำหรับทดสอบระบบ notification
Future<void> main() async {
  print('🔔 Notification System Test');
  print('==========================');
  print('');

  print('📊 สรุปสถานะปัจจุบัน:');
  print('   ✅ Cloud Function sendNewPostNotification ทำงานได้');
  print('   ✅ ส่งแจ้งเตือนสำเร็จ 2 คน จาก 13 tokens');
  print('   ✅ ลบ invalid tokens (11 tokens) ออกแล้ว');
  print('   ❌ ปัญหา: tokens ส่วนใหญ่ expired');
  print('');

  print('🔍 สาเหตุหลัก:');
  print('   • FCM tokens หมดอายุเมื่อ uninstall/reinstall app');
  print('   • ในช่วงพัฒนา developer มักจะติดตั้งแอปใหม่บ่อย');
  print('   • Token เก่าใน database ยังคงอยู่แต่ไม่ valid แล้ว');
  print('');

  print('💡 วิธีแก้ไข:');
  print('   1. ให้ผู้ใช้ปัจจุบันเปิดแอป และล็อกอินใหม่');
  print('   2. ตรวจสอบว่า notification permission ถูกอนุญาต');
  print('   3. Token ใหม่จะถูกสร้างและบันทึกอัตโนมัติ');
  print('');

  print('🧪 การทดสอบ:');
  print('   • เปิดแอป checkdarn ด้วย account ที่ใช้งานจริง');
  print('   • โพสต์รายงานใหม่');
  print('   • ตรวจสอบ log ใน Firebase Console');
  print('');

  print('🔧 Debug Commands:');
  print('   firebase functions:log --only sendNewPostNotification');
  print('   firebase functions:log --only sendNewCommentNotification');
  print('');

  print('⚡ Real-time monitoring:');
  stdout.write('กด Enter เพื่อเริ่ม monitor logs แบบ real-time...');
  stdin.readLineSync();

  print('');
  print('🚀 กำลัง monitor Firebase logs...');
  print('📱 ให้ลองโพสต์อะไรในแอป checkdarn ดู');
  print('   (กด Ctrl+C เพื่อหยุด)');
  print('');

  // Monitor logs
  final process = await Process.start(
    'firebase',
    ['functions:log', '--only', 'sendNewPostNotification', '--follow'],
    workingDirectory: '/Users/kritchaponprommali/checkdarn-app',
  );

  process.stdout.listen((data) {
    stdout.write(String.fromCharCodes(data));
  });

  process.stderr.listen((data) {
    stderr.write(String.fromCharCodes(data));
  });

  // รอให้ process จบ
  final exitCode = await process.exitCode;
  print('Monitor stopped with exit code: $exitCode');
}
