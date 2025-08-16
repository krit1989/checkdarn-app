const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
admin.initializeApp({
  projectId: 'checkdarn-app'
});

async function testNotification() {
  try {
    console.log('🧪 Testing notification function...');
    
    // สร้าง test report document ใน Firestore เพื่อ trigger function
    const testReport = {
      latitude: 13.7563,
      longitude: 100.5018,
      description: 'Test report for notification function',
      userId: 'test-user-123',
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      status: 'pending'
    };
    
    // เพิ่ม document ใหม่ลงใน reports collection
    const reportRef = await admin.firestore().collection('reports').add(testReport);
    console.log('✅ Test report created with ID:', reportRef.id);
    console.log('📱 This should trigger the notification function...');
    
    // รอสักครู่แล้วลบ test report
    setTimeout(async () => {
      await reportRef.delete();
      console.log('🗑️ Test report cleaned up');
      process.exit(0);
    }, 5000);
    
  } catch (error) {
    console.error('❌ Error testing notification:', error);
    process.exit(1);
  }
}

testNotification();
