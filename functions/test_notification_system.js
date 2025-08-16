// สคริปต์ทดสอบระบบแจ้งเตือนแบบง่าย
const admin = require('firebase-admin');

// Initialize Firebase Admin (ใช้ default credentials)
try {
  admin.initializeApp();
  console.log('✅ Firebase Admin initialized successfully');
} catch (error) {
  console.log('❌ Firebase Admin initialization error:', error.message);
  process.exit(1);
}

async function testNotificationSystem() {
  try {
    console.log('🔍 === TESTING NOTIFICATION SYSTEM ===');
    
    // ทดสอบ 1: ตรวจสอบข้อมูล reports ล่าสุด
    console.log('\n1. ตรวจสอบ reports ล่าสุด...');
    const reportsSnapshot = await admin.firestore()
      .collection('reports')
      .orderBy('timestamp', 'desc')
      .limit(5)
      .get();
    
    console.log(`📊 จำนวน reports ทั้งหมด: ${reportsSnapshot.size}`);
    
    reportsSnapshot.forEach((doc, index) => {
      const data = doc.data();
      console.log(`\n📄 Report ${index + 1} (ID: ${doc.id}):`);
      console.log(`   Title: ${data.title || 'ไม่มีหัวข้อ'}`);
      console.log(`   Description: ${data.description || 'ไม่มีรายละเอียด'}`);
      console.log(`   Timestamp: ${data.timestamp ? new Date(data.timestamp.seconds * 1000).toLocaleString('th-TH') : 'ไม่มีเวลา'}`);
      
      // ตรวจสอบข้อมูล location
      if (data.lat && data.lng) {
        console.log(`   ✅ Location (lat/lng): ${data.lat}, ${data.lng}`);
      } else if (data.location && data.location.latitude && data.location.longitude) {
        console.log(`   ✅ Location (object): ${data.location.latitude}, ${data.location.longitude}`);
      } else {
        console.log(`   ❌ ไม่มีข้อมูล location ที่ถูกต้อง!`);
        console.log(`   📋 ข้อมูลทั้งหมดของ report นี้:`, JSON.stringify(data, null, 2));
      }
    });
    
    // ทดสอบ 2: ตรวจสอบ notification logs
    console.log('\n\n2. ตรวจสอบ notification logs...');
    const notificationLogsSnapshot = await admin.firestore()
      .collection('notification_logs')
      .orderBy('timestamp', 'desc')
      .limit(3)
      .get();
    
    console.log(`📊 จำนวน notification logs: ${notificationLogsSnapshot.size}`);
    
    notificationLogsSnapshot.forEach((doc, index) => {
      const data = doc.data();
      console.log(`\n📝 Notification Log ${index + 1} (ID: ${doc.id}):`);
      console.log(`   Report ID: ${data.reportId}`);
      console.log(`   Type: ${data.type}`);
      console.log(`   Topics: ${data.topics ? data.topics.join(', ') : 'ไม่มี'}`);
      console.log(`   Success: ${data.summary ? data.summary.success_count : 'ไม่ทราบ'}`);
      console.log(`   Failed: ${data.summary ? data.summary.fail_count : 'ไม่ทราบ'}`);
      console.log(`   Timestamp: ${data.timestamp ? new Date(data.timestamp.seconds * 1000).toLocaleString('th-TH') : 'ไม่มีเวลา'}`);
    });
    
    // ทดสอบ 3: ตรวจสอบ notification errors
    console.log('\n\n3. ตรวจสอบ notification errors...');
    const errorLogsSnapshot = await admin.firestore()
      .collection('notification_errors')
      .orderBy('timestamp', 'desc')
      .limit(3)
      .get();
    
    console.log(`📊 จำนวน notification errors: ${errorLogsSnapshot.size}`);
    
    errorLogsSnapshot.forEach((doc, index) => {
      const data = doc.data();
      console.log(`\n❌ Notification Error ${index + 1} (ID: ${doc.id}):`);
      console.log(`   Report ID: ${data.reportId}`);
      console.log(`   Error: ${data.error}`);
      console.log(`   Timestamp: ${data.timestamp ? new Date(data.timestamp.seconds * 1000).toLocaleString('th-TH') : 'ไม่มีเวลา'}`);
    });
    
    console.log('\n🎉 === TESTING COMPLETE ===');
    
  } catch (error) {
    console.error('❌ Error during testing:', error);
  } finally {
    process.exit(0);
  }
}

// เรียกใช้ฟังก์ชันทดสอบ
testNotificationSystem();
