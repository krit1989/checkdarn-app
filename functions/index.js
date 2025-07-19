const functions = require('firebase-functions');
const admin = require('firebase-admin');
const { getStorage } = require('firebase-admin/storage');

// Initialize Firebase Admin
admin.initializeApp();

/**
 * 🧹 Scheduled Function: ลบข้อมูลเก่าแบบครบถ้วน
 * 
 * ฟังก์ชันนี้จะทำงานทุก 24 ชั่วโมง เพื่อลบข้อมูลที่เก่ากว่า 7 วัน
 * รวมถึง subcollections และไฟล์รูปภาพใน Storage
 * 
 * วิธีการทำงาน:
 * 1. หาโพสต์ที่เก่ากว่า 7 วัน
 * 2. ลบ comments subcollection ทั้งหมด
 * 3. ลบไฟล์รูปภาพใน Firebase Storage
 * 4. ลบโพสต์หลัก
 */
exports.cleanupOldReports = functions.pubsub
  .schedule('every 24 hours')
  .timeZone('Asia/Bangkok')
  .onRun(async (context) => {
    const db = admin.firestore();
    const bucket = getStorage().bucket();
    
    // กำหนดช่วงเวลา: เก่ากว่า 7 วัน
    const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
    console.log(`🧹 เริ่มทำความสะอาดข้อมูลที่เก่ากว่า: ${sevenDaysAgo.toISOString()}`);

    try {
      // 🔍 หาโพสต์ที่เก่ากว่า 7 วัน
      const snapshot = await db.collection('reports')
        .where('timestamp', '<', sevenDaysAgo)
        .get();

      console.log(`📊 พบโพสต์เก่า ${snapshot.size} รายการ`);

      if (snapshot.empty) {
        console.log('✅ ไม่มีข้อมูลเก่าที่ต้องลบ');
        return null;
      }

      let deletedCount = 0;
      let errorCount = 0;

      // 🔄 วนลูปลบแต่ละโพสต์
      for (const doc of snapshot.docs) {
        const postId = doc.id;
        const data = doc.data();
        
        try {
          console.log(`🗑️ กำลังลบโพสต์: ${postId}`);

          // 📝 1. ลบ comments subcollection
          await deleteSubcollection(db, `reports/${postId}/comments`);

          // 📝 2. ลบ likes subcollection (ถ้ามี)
          await deleteSubcollection(db, `reports/${postId}/likes`);

          // 📝 3. ลบ shares subcollection (ถ้ามี)
          await deleteSubcollection(db, `reports/${postId}/shares`);

          // 🖼️ 4. ลบไฟล์รูปภาพใน Storage
          if (data.imageUrl) {
            await deleteImageFromStorage(bucket, postId, data.imageUrl);
          }

          // 📄 5. ลบโพสต์หลัก
          await doc.ref.delete();

          deletedCount++;
          console.log(`✅ ลบโพสต์ ${postId} สำเร็จ`);

        } catch (error) {
          errorCount++;
          console.error(`❌ ไม่สามารถลบโพสต์ ${postId}:`, error);
        }
      }

      // 📊 สรุปผลการทำงาน
      console.log(`🎉 ทำความสะอาดเสร็จสิ้น:`);
      console.log(`   ✅ ลบสำเร็จ: ${deletedCount} รายการ`);
      console.log(`   ❌ ลบไม่สำเร็จ: ${errorCount} รายการ`);

      return {
        success: true,
        deletedCount,
        errorCount,
        timestamp: new Date().toISOString()
      };

    } catch (error) {
      console.error('❌ เกิดข้อผิดพลาดในการทำความสะอาด:', error);
      throw error;
    }
  });

/**
 * 🗂️ ฟังก์ชันลบ subcollection
 * @param {admin.firestore.Firestore} db - Firestore instance
 * @param {string} collectionPath - เส้นทาง collection ที่ต้องการลบ
 */
async function deleteSubcollection(db, collectionPath) {
  try {
    const subcollectionSnapshot = await db.collection(collectionPath).get();
    
    if (subcollectionSnapshot.empty) {
      console.log(`📁 ไม่มีข้อมูลใน ${collectionPath}`);
      return;
    }

    console.log(`📁 กำลังลบ ${subcollectionSnapshot.size} รายการจาก ${collectionPath}`);

    // ลบแบบ batch (ทีละ 500 รายการ)
    const batchSize = 500;
    const docs = subcollectionSnapshot.docs;
    
    for (let i = 0; i < docs.length; i += batchSize) {
      const batch = db.batch();
      const batchDocs = docs.slice(i, i + batchSize);
      
      batchDocs.forEach(doc => {
        batch.delete(doc.ref);
      });
      
      await batch.commit();
      console.log(`   ✅ ลบ batch ${Math.ceil((i + 1) / batchSize)} สำเร็จ`);
    }

    console.log(`✅ ลบ ${collectionPath} ทั้งหมดเสร็จสิ้น`);

  } catch (error) {
    console.error(`❌ ไม่สามารถลบ ${collectionPath}:`, error);
    throw error;
  }
}

/**
 * 🖼️ ฟังก์ชันลบไฟล์รูปภาพจาก Storage
 * @param {admin.storage.Storage} bucket - Storage bucket
 * @param {string} postId - ID ของโพสต์
 * @param {string} imageUrl - URL ของรูปภาพ
 */
async function deleteImageFromStorage(bucket, postId, imageUrl) {
  try {
    // 🔍 หาชื่อไฟล์จาก URL
    let fileName = null;
    
    // วิธีที่ 1: ใช้ postId เป็นชื่อไฟล์
    const possibleNames = [
      `images/${postId}.jpg`,
      `images/${postId}.jpeg`,
      `images/${postId}.png`,
      `images/${postId}.webp`,
    ];

    // วิธีที่ 2: แยกชื่อไฟล์จาก URL
    if (imageUrl.includes('firebase')) {
      const urlParts = imageUrl.split('/');
      const fileNameWithParams = urlParts[urlParts.length - 1];
      const actualFileName = fileNameWithParams.split('?')[0];
      possibleNames.push(decodeURIComponent(actualFileName));
    }

    // 🗑️ ลองลบไฟล์ที่เป็นไปได้
    let deleted = false;
    for (const fileName of possibleNames) {
      try {
        const file = bucket.file(fileName);
        const [exists] = await file.exists();
        
        if (exists) {
          await file.delete();
          console.log(`🖼️ ลบรูปภาพสำเร็จ: ${fileName}`);
          deleted = true;
          break;
        }
      } catch (deleteError) {
        // ไม่ต้องทำอะไร ลองชื่อไฟล์ถัดไป
      }
    }

    if (!deleted) {
      console.log(`⚠️ ไม่พบไฟล์รูปภาพสำหรับโพสต์ ${postId}`);
    }

  } catch (error) {
    console.warn(`⚠️ ไม่สามารถลบรูปภาพของโพสต์ ${postId}:`, error.message);
    // ไม่ throw error เพราะไม่อยากให้การลบโพสต์ล้มเหลว
  }
}

/**
 * 🛠️ Manual Cleanup Function (สำหรับทดสอบ)
 * 
 * เรียกใช้ด้วย: 
 * firebase functions:shell
 * > manualCleanup()
 */
exports.manualCleanup = functions.https.onRequest(async (req, res) => {
  try {
    // ตรวจสอบ admin key (เพื่อความปลอดภัย)
    const adminKey = req.query.adminKey;
    if (adminKey !== 'your-secret-admin-key-here') {
      return res.status(403).json({ error: 'Unauthorized' });
    }

    console.log('🧹 เริ่ม Manual Cleanup...');
    
    // เรียกใช้ฟังก์ชันเดียวกับ scheduled function
    const result = await exports.cleanupOldReports.run();
    
    res.json({
      success: true,
      message: 'Manual cleanup completed',
      result: result
    });

  } catch (error) {
    console.error('❌ Manual cleanup failed:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * 📊 Status Check Function
 * 
 * ตรวจสอบสถานะและจำนวนข้อมูลในระบบ
 */
exports.getCleanupStatus = functions.https.onRequest(async (req, res) => {
  try {
    const db = admin.firestore();
    const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
    
    // นับจำนวนโพสต์ทั้งหมด
    const totalPostsSnapshot = await db.collection('reports').get();
    const totalPosts = totalPostsSnapshot.size;
    
    // นับจำนวนโพสต์เก่า
    const oldPostsSnapshot = await db.collection('reports')
      .where('timestamp', '<', sevenDaysAgo)
      .get();
    const oldPosts = oldPostsSnapshot.size;
    
    // นับจำนวน comments ทั้งหมด
    let totalComments = 0;
    for (const doc of totalPostsSnapshot.docs) {
      const commentsSnapshot = await db.collection(`reports/${doc.id}/comments`).get();
      totalComments += commentsSnapshot.size;
    }

    res.json({
      success: true,
      data: {
        totalPosts,
        oldPosts,
        totalComments,
        cutoffDate: sevenDaysAgo.toISOString(),
        lastUpdated: new Date().toISOString()
      }
    });

  } catch (error) {
    console.error('❌ Status check failed:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});
