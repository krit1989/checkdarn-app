#!/usr/bin/env dart
// Debug Firebase UID - ตรวจสอบว่าผู้ใช้แต่ละอีเมลมี UID แยกกันหรือไม่

import 'dart:io';

void main() async {
  print('🔍 === Firebase UID Debug Guide ===\n');

  print('📧 การตรวจสอบ UID แต่ละอีเมล:');
  print('');

  print('✅ วิธีการดู UID ในแอป:');
  print('1. ล็อกอินด้วยอีเมลแรก');
  print('2. ไปหน้า Report และเปิด Flutter console');
  print('3. มองหา log message: "👤 User ID: [UID]"');
  print('4. บันทึก UID นี้ไว้');
  print('5. ล็อกเอาต์');
  print('6. ล็อกอินด้วยอีเมลที่สอง');
  print('7. เปิด console ดู UID อีกครั้ง');
  print('8. เปรียบเทียบ UID ทั้งสองตัว');
  print('');

  print('🔍 === Log Messages ที่ควรเห็น ===');
  print('');
  print('📊 เมื่อพยายามโพสต์:');
  print('   👤 User ID: [UID]');
  print('   👤 User email: [EMAIL]');
  print('   👤 User display name: [NAME]');
  print('   🔍 Checking rate limit for user: [UID]');
  print('   📅 Date range: [START] to [END]');
  print('   📊 Found X posts in the last 1 day(s) (limit: 5)');
  print('');

  print('✅ Expected Results:');
  print('   - UID ต่างกัน = อีเมลต่างกัน → โพสต์ได้');
  print('   - UID เดียวกัน = มีปัญหา → ต้องแก้ไข');
  print('');

  print('🚨 === Possible Issues ===');
  print('');
  print('❌ ปัญหาที่เป็นไปได้:');
  print('1. Google Sign-In cache ผิดพลาด');
  print('2. Firebase Auth ไม่ได้ logout สะอาด');
  print('3. App ใช้ Anonymous Auth แทน Google');
  print('4. Keychain/SharedPreferences cache เก่า');
  print('5. Firebase project configuration ผิด');
  print('');

  print('🔧 === Solutions ===');
  print('');
  print('🔄 ลองแก้ไขตามลำดับ:');
  print('1. Force logout และ clear cache:');
  print('   - ล็อกเอาต์จากแอป');
  print('   - ล็อกเอาต์จาก Google account บนเบราว์เซอร์');
  print('   - รีสตาร์ทแอป');
  print('   - ล็อกอินใหม่');
  print('');

  print('2. ลบแอปและติดตั้งใหม่:');
  print('   - Uninstall app');
  print('   - Install APK ใหม่');
  print('   - ล็อกอินด้วยอีเมลอื่น');
  print('');

  print('3. เช็คใน Firebase Console:');
  print('   - เปิด https://console.firebase.google.com/');
  print('   - ไป Authentication > Users');
  print('   - ดูว่ามีผู้ใช้กี่คนและ UID อะไรบ้าง');
  print('');

  print('📱 === Testing Steps ===');
  print('');
  print('🧪 ขั้นตอนทดสอบ:');
  print('1. ล็อกอินด้วยอีเมลแรก');
  print('2. พยายามโพสต์ และดู console log');
  print('3. บันทึก UID และจำนวนโพสต์ที่นับได้');
  print('4. ล็อกเอาต์สะอาด');
  print('5. ล็อกอินด้วยอีเมลที่สอง');
  print('6. พยายามโพสต์อีกครั้ง');
  print('7. เปรียบเทียบ UID และ rate limit results');
  print('');

  print('📋 === Expected vs Actual ===');
  print('');
  print('✅ ผลที่ควรจะเป็น:');
  print('   Email 1: UID = abc123... (5/5 posts used)');
  print('   Email 2: UID = xyz789... (0/5 posts used) ✓');
  print('');

  print('❌ ถ้าผลออกมาเป็น:');
  print('   Email 1: UID = abc123... (5/5 posts used)');
  print('   Email 2: UID = abc123... (5/5 posts used) ❌');
  print('   → มีปัญหา authentication caching');
  print('');

  print('🔍 === Next Steps ===');
  print('');
  print('หลังจากทดสอบแล้ว:');
  print('1. ส่ง screenshot ของ console logs');
  print('2. ส่ง UID ของทั้งสองอีเมล');
  print('3. ส่ง screenshot Firebase Console > Users');
  print('4. บอกว่าได้ผลลัพธ์อย่างไร');
  print('');

  print('✅ === Debug Complete ===');
  print('กด Ctrl+C เพื่อออก และไปทดสอบใน Flutter app');
}
