const admin = require('firebase-admin');

// Initialize Firebase Admin
admin.initializeApp();

/*
 * 🧪 ทดสอบการแจ้งเตือนโพสต์ใหม่ที่มีชื่อคนโพส (ปิดบางส่วน)
 * 
 * วิธีใช้:
 * 1. เปิด Terminal ใน VS Code
 * 2. cd /Users/kritchaponprommali/checkdarn-app
 * 3. รัน: node test_notification_with_poster_name.js
 * 
 * ฟังก์ชันนี้จะ:
 * - สร้างโพสต์ทดสอบ
 * - Trigger การแจ้งเตือนที่มีชื่อคนโพส (ปิดบางส่วน)
 * - แสดงข้อความแจ้งเตือนที่ส่งให้ผู้ใช้อื่น
 */

async function testNewPostNotificationWithPosterName() {
  console.log('🧪 กำลังทดสอบการแจ้งเตือนโพสต์ใหม่ที่มีชื่อคนโพส...');
  
  try {
    const db = admin.firestore();
    
    // 1. สร้างข้อมูลผู้ใช้ทดสอบก่อน (เพื่อให้มีชื่อในระบบ)
    const testUserId = 'test_poster_' + Date.now();
    const testUserData = {
      displayName: 'สมชาย ใจดี',
      username: 'somchai_jaidee',
      email: 'somchai@test.com',
      tokens: [], // ไม่มี token เพื่อไม่ให้ได้รับแจ้งเตือนตัวเอง
      isActive: true,
      platform: 'android',
      lastUpdated: admin.firestore.FieldValue.serverTimestamp()
    };
    
    console.log('👤 สร้างข้อมูลผู้ใช้ทดสอบ...');
    await db.collection('user_tokens').doc(testUserId).set(testUserData);
    console.log(`✅ สร้างผู้ใช้ ID: ${testUserId} ชื่อ: ${testUserData.displayName}`);
    
    // 2. ข้อมูลโพสต์ทดสอบ
    const testReport = {
      userId: testUserId,
      description: 'มีการตรวจจับความเร็วบริเวณนี้ ขอให้ขับขี่อย่างระมัดระวัง และระวังตำรวจที่ซ่อนอยู่',
      category: 'checkpoint',
      location: 'ถนนพหลโยธิน',
      district: 'หาดใหญ่',
      province: 'สงขลา',
      roadName: 'ถนนพหลโยธิน',
      subDistrict: 'หาดใหญ่',
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      latitude: 7.0187,
      longitude: 100.4713,
      isVerified: false,
      likeCount: 0,
      commentCount: 0,
      imageUrl: null,
    };
    
    console.log('📝 ข้อมูลโพสต์ทดสอบ:');
    console.log(`   👤 ชื่อคนโพส: ${testUserData.displayName} (จะแสดงเป็น "สมช***")`);
    console.log(`   📍 หมวดหมู่: ${testReport.category}`);
    console.log(`   🌍 ตำแหน่ง: ${testReport.district}, ${testReport.province}`);
    console.log(`   💬 รายละเอียด: ${testReport.description}`);
    console.log('');
    
    // 3. สร้างโพสต์ทดสอบใน Firestore
    console.log('📤 กำลังสร้างโพสต์ทดสอบ...');
    
    const docRef = await db.collection('reports').add(testReport);
    
    console.log('✅ สร้างโพสต์ทดสอบสำเร็จ!');
    console.log(`📄 Document ID: ${docRef.id}`);
    console.log('');
    
    console.log('🔔 คาดหวังผลลัพธ์การแจ้งเตือน:');
    console.log('   📱 Title: 🚓 ด่านตรวจ - หาดใหญ่, สงขลา');
    console.log('   💬 Body: สมช*** รายงาน: มีการตรวจจับความเร็วบริเวณนี้ ขอให้ขับขี่อย่างระมัดระวัง...');
    console.log(`   📊 ส่งให้: ผู้ใช้ทั้งหมด (ยกเว้นคนโพส ${testUserId})`);
    console.log('');
    
    console.log('🔍 ตรวจสอบผลลัพธ์:');
    console.log('   1. Firebase Console > Functions > Logs');
    console.log('   2. ดู log ของ sendNewPostNotification');
    console.log('   3. ตรวจสอบว่า "Poster name: สมชาย ใจดี -> Masked: สมช***"');
    console.log('   4. ตรวจสอบข้อความแจ้งเตือนที่ส่งออก');
    console.log('');
    
    // 4. รอสักครู่เพื่อให้ function ประมวลผล
    console.log('⏳ รอ 15 วินาทีเพื่อให้ Firebase Function ประมวลผล...');
    await new Promise(resolve => setTimeout(resolve, 15000));
    
    // 5. ตรวจสอบผลลัพธ์ใน Firebase Functions Logs
    console.log('📊 ดูผลลัพธ์ใน Firebase Console:');
    console.log('   https://console.firebase.google.com/project/checkdarn-app/functions/logs');
    console.log('');
    
    // 6. ทำความสะอาด - ลบข้อมูลทดสอบ
    console.log('🧹 กำลังทำความสะอาดข้อมูลทดสอบ...');
    
    await docRef.delete();
    console.log('🗑️ ลบโพสต์ทดสอบแล้ว');
    
    await db.collection('user_tokens').doc(testUserId).delete();
    console.log('🗑️ ลบข้อมูลผู้ใช้ทดสอบแล้ว');
    
    console.log('');
    console.log('✅ การทดสอบเสร็จสิ้น!');
    console.log('');
    console.log('📱 สิ่งที่ควรเกิดขึ้นในแอป Flutter:');
    console.log('   1. ผู้ใช้อื่นควรได้รับแจ้งเตือน');
    console.log('   2. ข้อความแจ้งเตือนมี "สมช***" ใน body');
    console.log('   3. กดแจ้งเตือนเพื่อเปิดโพสต์');
    console.log('   4. ข้อมูลพื้นที่แสดงในหัวข้อแจ้งเตือน');
    
  } catch (error) {
    console.error('❌ เกิดข้อผิดพลาดในการทดสอบ:');
    console.error('   Error:', error.message);
    console.log('');
    console.log('💡 วิธีแก้ไข:');
    console.log('   1. ตรวจสอบการเชื่อมต่อ Firebase');
    console.log('   2. ตรวจสอบสิทธิ์การเขียนข้อมูลใน Firestore');
    console.log('   3. ตรวจสอบการตั้งค่า Firebase Admin SDK');
    console.log('   4. ตรวจสอบว่า Functions ถูก deploy แล้ว');
  }
  
  // ปิดการเชื่อมต่อ
  process.exit(0);
}

// รันการทดสอบ
testNewPostNotificationWithPosterName();
