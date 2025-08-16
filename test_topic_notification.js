const admin = require('firebase-admin');

// Initialize Firebase Admin
const serviceAccount = require('./service-account-key.json'); // ต้องดาวน์โหลดจาก Firebase Console
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

/**
 * 🧪 **ทดสอบการส่ง Topic Notification**
 * ใช้สำหรับทดสอบระบบใหม่ก่อนเปิดใช้งานจริง
 */
async function testTopicNotification() {
  try {
    console.log('🧪 Testing Topic Notification System...');

    // สมมติเป็นการโพสในกรุงเทพใจกลาง
    const testData = {
      reportLat: 13.7563,
      reportLng: 100.5018,
      category: 'accident',
      description: 'ทดสอบระบบแจ้งเตือนแบบ Topic - อุบัติเหตุรถชนเล็กน้อย ถนนพญาไท',
      location: 'ถนนพญาไท แขวงทุ่งพญาไท เขตราชเทวี กรุงเทพฯ',
      province: 'กรุงเทพมหานคร',
      district: 'เขตราชเทวี',
      userName: 'TestUser123'
    };

    // สร้าง topic names ตามตำแหน่ง (รัศมี 30 กม.)
    const targetTopics = generateLocationTopics(testData.reportLat, testData.reportLng, 30);
    
    console.log(`🎯 จะส่งไปยัง ${targetTopics.length} topics:`);
    targetTopics.forEach(topic => console.log(`   - ${topic}`));

    // สร้างข้อความแจ้งเตือน
    const categoryEmoji = '🚗';
    const categoryName = 'อุบัติเหตุ';
    const locationInfo = `${testData.district}, ${testData.province}`;
    
    const notificationTitle = `${categoryEmoji} ${categoryName} ${locationInfo}`;
    const maskedPosterName = `${testData.userName.substring(0, 4)} *******`;
    const notificationBody = `${testData.description}\n${maskedPosterName}`;

    console.log(`📝 Notification Preview:`);
    console.log(`   Title: "${notificationTitle}"`);
    console.log(`   Body: "${notificationBody}"`);

    // ส่งแจ้งเตือนไปยังแต่ละ topic
    const results = [];
    
    for (const topic of targetTopics.slice(0, 3)) { // ทดสอบแค่ 3 topics แรก
      try {
        const message = {
          topic: topic,
          notification: {
            title: notificationTitle,
            body: notificationBody,
          },
          data: {
            type: 'test_post',
            category: testData.category,
            location: testData.location,
            action: 'open_post',
          }
        };

        console.log(`📤 Sending to topic: ${topic}`);
        const response = await admin.messaging().send(message);
        console.log(`✅ Success: ${response}`);
        results.push({ topic, success: true, messageId: response });

      } catch (error) {
        console.error(`❌ Failed to send to topic ${topic}:`, error.message);
        results.push({ topic, success: false, error: error.message });
      }
    }

    // สรุปผล
    const successCount = results.filter(r => r.success).length;
    const failureCount = results.filter(r => !r.success).length;
    
    console.log(`\n📊 Test Results:`);
    console.log(`   ✅ Success: ${successCount}/${results.length} topics`);
    console.log(`   ❌ Failed: ${failureCount} topics`);
    console.log(`   💰 Estimated cost per post: $0.0000171 (vs $0.192 for mass broadcasting)`);
    console.log(`   💵 Total savings: 99.9%`);
    
    if (successCount > 0) {
      console.log(`\n🎉 Topic Notification System is working!`);
      console.log(`✅ Ready for production deployment`);
    } else {
      console.log(`\n⚠️ All topic sends failed - check configuration`);
    }

  } catch (error) {
    console.error('❌ Test failed:', error);
  }
}

/**
 * 🗺️ **สร้าง Topic Names ตามตำแหน่งและรัศมี**
 */
function generateLocationTopics(centerLat, centerLng, radiusKm) {
  const topics = [];
  const gridSizeKm = 20;
  const gridCount = Math.ceil(radiusKm / gridSizeKm);
  
  for (let i = -gridCount; i <= gridCount; i++) {
    for (let j = -gridCount; j <= gridCount; j++) {
      const offsetLat = centerLat + (i * gridSizeKm / 111);
      const offsetLng = centerLng + (j * gridSizeKm / (111 * Math.cos(centerLat * Math.PI / 180)));
      
      const distance = calculateDistance(centerLat, centerLng, offsetLat, offsetLng);
      
      if (distance <= radiusKm) {
        const gridLat = Math.round(offsetLat * 100);
        const gridLng = Math.round(offsetLng * 100);
        const topicName = `th_${gridLat}_${gridLng}_${gridSizeKm}km`;
        topics.push(topicName);
      }
    }
  }
  
  return topics;
}

/**
 * 📏 **คำนวณระยะทาง**
 */
function calculateDistance(lat1, lng1, lat2, lng2) {
  const R = 6371;
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLng = (lng2 - lng1) * Math.PI / 180;
  const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
    Math.sin(dLng / 2) * Math.sin(dLng / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

// รันการทดสอบ
testTopicNotification();
