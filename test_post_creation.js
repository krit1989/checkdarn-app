const admin = require('firebase-admin');

// Initialize Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp();
}

async function createTestPost() {
  try {
    console.log('🧪 สร้างโพสทดสอบ...');
    
    const testPost = {
      title: 'Test Post for Notification',
      description: 'ทดสอบระบบแจ้งเตือน',
      lat: 13.7563,
      lng: 100.5018,
      type: 'police',
      userId: 'test-user-123',
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      status: 'active',
      votes: {},
      voteCount: 0
    };

    const result = await admin.firestore()
      .collection('reports')
      .add(testPost);
    
    console.log(`✅ สร้างโพสทดสอบสำเร็จ! Document ID: ${result.id}`);
    console.log('📱 ตรวจสอบ Firebase Functions logs เพื่อดูว่า notification trigger ทำงานหรือไม่');
    
  } catch (error) {
    console.error('❌ Error:', error);
  }
}

createTestPost();
