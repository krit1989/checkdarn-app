const admin = require('firebase-admin');

// Initialize with minimal config
admin.initializeApp({
  projectId: 'checkdarn-app'
});

const db = admin.firestore();

async function createTestReport() {
  try {
    console.log('🧪 Creating test report...');
    
    const testReport = {
      userId: 'test-user-' + Date.now(),
      description: 'Test FCM sendEachForMulticast fix - ' + new Date().toISOString(),
      category: 'traffic',
      lat: 13.7563,
      lng: 100.5018,
      location: 'Bangkok Test',
      district: 'Test District',
      province: 'Bangkok',
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      status: 'pending'
    };
    
    // สร้าง document ใหม่
    const reportRef = await db.collection('reports').add(testReport);
    console.log('✅ Test report created:', reportRef.id);
    console.log('📱 This should trigger sendNewPostNotificationByToken function');
    
    // รอสักครู่แล้วดู logs
    console.log('⏳ Waiting 10 seconds then checking logs...');
    setTimeout(() => {
      console.log('🗑️ Cleaning up test report...');
      reportRef.delete().then(() => {
        console.log('✅ Test report deleted');
        process.exit(0);
      });
    }, 10000);
    
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

createTestReport();
