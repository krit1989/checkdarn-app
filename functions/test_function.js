/**
 * 🧪 Create Test Report Function - สำหรับทดสอบการทำงานของ notification
 */
exports.createTestReport = functions.https.onRequest(async (req, res) => {
  try {
    const { 
      userId = 'test_reporter_' + Date.now(),
      category = 'checkpoint',
      description = 'ทดสอบระบบแจ้งเตือนโพสต์ใหม่',
      lat = 13.7563,
      lng = 100.5018,
      autoDelete = true
    } = req.body || req.query;
    
    console.log('🧪 Creating test report to trigger notification...');
    
    // สร้างโพสต์ทดสอบ
    const testReport = {
      userId: userId,
      category: category,
      description: description,
      lat: parseFloat(lat),
      lng: parseFloat(lng),
      location: 'กรุงเทพมหานคร',
      district: 'เขตปทุมวัน',
      province: 'กรุงเทพมหานคร',
      subDistrict: 'แขวงปทุมวัน',
      roadName: 'ถนนพระราม 1',
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      displayName: 'ผู้ทดสอบระบบ',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      isTestReport: true // เพิ่ม flag เพื่อระบุว่าเป็น test
    };
    
    // สร้างโพสต์ในฐานข้อมูล (จะ trigger ฟังก์ชัน sendNewPostNotification)
    const docRef = await admin.firestore().collection('reports').add(testReport);
    
    console.log(`✅ Test report created with ID: ${docRef.id}`);
    console.log('📱 This should trigger the main notification function');
    
    // ตั้งเวลาลบโพสต์ทดสอบถ้าระบุ
    if (autoDelete === true || autoDelete === 'true') {
      setTimeout(async () => {
        try {
          await docRef.delete();
          console.log(`🗑️ Test report ${docRef.id} deleted after 30 seconds`);
        } catch (error) {
          console.error('❌ Error deleting test report:', error);
        }
      }, 30000); // ลบหลัง 30 วินาที
    }
    
    res.json({
      success: true,
      message: 'Test report created successfully',
      reportId: docRef.id,
      autoDelete: autoDelete,
      testData: testReport,
      instructions: [
        '1. Check Firebase Console logs for notification function execution',
        '2. Check if notifications were sent to users',
        '3. Report will be auto-deleted in 30 seconds if autoDelete=true'
      ]
    });
    
  } catch (error) {
    console.error('❌ Error creating test report:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});
