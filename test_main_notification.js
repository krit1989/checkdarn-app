const admin = require('firebase-admin');

// Initialize Firebase Admin (ถ้ายังไม่ได้ init)
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
    projectId: 'checkdarn-app'
  });
}

async function testMainNotificationFunction() {
  try {
    console.log('🧪 Testing main notification function by creating a test report...');
    
    // สร้างโพสต์ทดสอบใน reports collection
    const testReport = {
      userId: 'test_reporter_123', // ใช้ userId ที่ไม่มีในระบบ
      category: 'checkpoint',
      description: 'ทดสอบระบบแจ้งเตือนโพสต์ใหม่ - การทดสอบหลังจากแก้ไข token validation',
      lat: 13.7563,
      lng: 100.5018,
      location: 'กรุงเทพมหานคร',
      district: 'เขตปทุมวัน',
      province: 'กรุงเทพมหานคร',
      subDistrict: 'แขวงปทุมวัน',
      roadName: 'ถนนพระราม 1',
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      displayName: 'ผู้ทดสอบระบบ',
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    };
    
    // สร้างโพสต์ในฐานข้อมูล (จะ trigger ฟังก์ชัน sendNewPostNotification)
    const docRef = await admin.firestore().collection('reports').add(testReport);
    
    console.log(`✅ Test report created with ID: ${docRef.id}`);
    console.log('📱 This should trigger the main notification function');
    console.log('🔍 Check Firebase Console logs to see the notification results');
    
    // รอสักครู่แล้วลบโพสต์ทดสอบ
    setTimeout(async () => {
      try {
        await docRef.delete();
        console.log('🗑️ Test report deleted');
      } catch (error) {
        console.error('❌ Error deleting test report:', error);
      }
    }, 10000); // ลบหลัง 10 วินาที
    
  } catch (error) {
    console.error('❌ Error testing main notification function:', error);
  }
}

// เรียกใช้ฟังก์ชันทดสอบ
testMainNotificationFunction();
