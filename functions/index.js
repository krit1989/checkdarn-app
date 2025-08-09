const functions = require('firebase-functions');
const admin = require('firebase-admin');
const { getStorage } = require('firebase-admin/storage');
const { v4: uuidv4 } = require('uuid');

// Initialize Firebase Admin
admin.initializeApp();

// 🔄 **Retry Queue Collection**
const RETRY_QUEUE = 'notification_retry_queue';

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

/**
 * 🔍 Debug Token Status Function
 * 
 * ตรวจสอบสถานะ FCM Tokens และ User Data
 */
exports.debugTokenStatus = functions.https.onRequest(async (req, res) => {
  try {
    const db = admin.firestore();
    
    // ตรวจสอบ user_tokens collection
    const userTokensSnapshot = await db.collection('user_tokens').get();
    
    const tokenStats = {
      totalUsers: userTokensSnapshot.size,
      usersWithTokens: 0,
      totalTokens: 0,
      emptyTokenUsers: 0,
      userDetails: []
    };
    
    userTokensSnapshot.docs.forEach(doc => {
      const data = doc.data();
      const userId = doc.id;
      
      const userInfo = {
        userId: userId,
        hasTokens: data.tokens && Array.isArray(data.tokens) && data.tokens.length > 0,
        tokenCount: data.tokens ? data.tokens.length : 0,
        platform: data.platform || 'unknown',
        lastUpdated: data.lastUpdated ? data.lastUpdated.toDate().toISOString() : null,
        isActive: data.isActive !== false // default true if not specified
      };
      
      if (userInfo.hasTokens) {
        tokenStats.usersWithTokens++;
        tokenStats.totalTokens += userInfo.tokenCount;
      } else {
        tokenStats.emptyTokenUsers++;
      }
      
      tokenStats.userDetails.push(userInfo);
    });
    
    // ตรวจสอบ users collection (เก่า)
    const usersSnapshot = await db.collection('users').get();
    const oldUserTokens = [];
    
    usersSnapshot.docs.forEach(doc => {
      const data = doc.data();
      if (data.fcmToken) {
        oldUserTokens.push({
          userId: doc.id,
          token: data.fcmToken.substring(0, 20) + '...',
          lastTokenUpdate: data.lastTokenUpdate ? data.lastTokenUpdate.toDate().toISOString() : null
        });
      }
    });

    res.json({
      success: true,
      data: {
        userTokensCollection: tokenStats,
        oldUsersCollection: {
          totalUsers: usersSnapshot.size,
          usersWithFcmToken: oldUserTokens.length,
          tokenDetails: oldUserTokens
        },
        lastChecked: new Date().toISOString()
      }
    });

  } catch (error) {
    console.error('❌ Debug token status failed:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// ============================================================================
// 🔔 PUSH NOTIFICATION FUNCTIONS
// ============================================================================

/**
 * 🔔 เมื่อมีโพสใหม่ - ส่งแจ้งเตือนให้ผู้ใช้อื่น (ยกเว้นคนโพส)
 * 
 * กฎ: เวลาที่มีโพสใหม่ ห้ามเตือนคนโพส
 * หมายเหตุ: ปิดการใช้งานเพื่อป้องกันการแจ้งเตือนซ้ำ ใช้ sendNotificationWithRetry แทน
 */
// exports.sendNewPostNotification = functions.firestore
//   .document('reports/{reportId}')
//   .onCreate(async (snap, context) => {
//     // ปิดการใช้งานเพื่อป้องกันการแจ้งเตือนซ้ำ
//     console.log('⚠️ sendNewPostNotification is disabled to prevent duplicate notifications');
//     return null;
//   });

/**
 * 🔔 เมื่อมีคอมเม้นใหม่ - ส่งแจ้งเตือนให้คนโพส (พร้อม Retry)
 * 
 * กฎ: เวลาที่มีคนคอมเม้น ให้เด้งแจ้งเตือนคนโพส
 */
exports.sendNewCommentNotification = functions.firestore
  .document('reports/{reportId}/comments/{commentId}')
  .onCreate(async (snap, context) => {
    const maxRetries = 3;
    const retryDelay = [5, 15, 30]; // นาที
    
    try {
      const reportId = context.params.reportId;
      const commentId = context.params.commentId;
      const commentData = snap.data();
      
      console.log(`💬 New comment with retry: ${commentId} on report: ${reportId}`);
      console.log(`📝 Comment by: ${commentData.userId}`);
      console.log(`🔍 Comment data structure:`, JSON.stringify(commentData, null, 2));
      
      // ดึงข้อมูลโพสต์หลัก
      const reportDoc = await admin.firestore()
        .collection('reports')
        .doc(reportId)
        .get();
      
      if (!reportDoc.exists) {
        console.log('❌ Report not found');
        return null;
      }
      
      const reportData = reportDoc.data();
      const postAuthorId = reportData.userId;
      
      // ถ้าคนคอมเม้นเป็นคนโพสเอง ไม่ต้องส่งแจ้งเตือน
      if (commentData.userId === postAuthorId) {
        console.log('⚠️ Comment author is the same as post author, no notification sent');
        return null;
      }
      
      // ดึง FCM token ของคนโพส
      const authorTokenDoc = await admin.firestore()
        .collection('user_tokens')
        .doc(postAuthorId)
        .get();
      
      if (!authorTokenDoc.exists) {
        console.log('⚠️ Post author has no token document');
        return null;
      }
      
      const authorTokenData = authorTokenDoc.data();
      if (!authorTokenData.tokens || !Array.isArray(authorTokenData.tokens) || authorTokenData.tokens.length === 0) {
        console.log('⚠️ Post author has no active FCM tokens');
        return null;
      }
      
      // ใช้ token แรกที่พบ
      const authorToken = authorTokenData.tokens[0];
      
      // สร้างข้อความแจ้งเตือนที่ดีขึ้นพร้อมข้อมูลพื้นที่
      const commenterName = commentData.displayName || 'ผู้ใช้';
      
      // ปิดบางส่วนของชื่อ (แสดงแค่ 6 ตัวแรก แล้วใส่ ********)
      const maskedName = commenterName.length > 6 
        ? `${commenterName.substring(0, 6)}********`
        : `${commenterName}********`;
      
      // ดึงข้อความคอมเม้น (ลองหลาย field name)
      const commentText = commentData.text || commentData.comment || commentData.message || commentData.content || '';
      console.log(`💬 Comment text found: "${commentText}"`);
      
      // สร้าง preview ของคอมเม้นต์
      const shortComment = commentText.length > 25 
        ? `${commentText.substring(0, 22)}...`
        : commentText;
      
      const notificationTitle = '💬 ความคิดเห็นใหม่';
      const notificationBody = shortComment 
        ? `${maskedName}: "${shortComment}"`
        : `${maskedName} แสดงความคิดเห็นในโพสต์ของคุณ`;
      
      // ส่งข้อความแจ้งเตือน
      const message = {
        notification: {
          title: notificationTitle,
          body: notificationBody,
        },
        data: {
          type: 'new_comment',
          reportId: reportId,
          commentId: commentId,
          category: reportData.category || '',
          location: reportData.location || '',
          district: reportData.district || '',
          province: reportData.province || '',
          roadName: reportData.roadName || '',
          subDistrict: reportData.subDistrict || '',
          fullLocation: buildLocationString(reportData) || '',
          // เพิ่มข้อมูลสำหรับการนำทาง
          action: 'open_comment',
          targetScreen: 'report_detail',
          scrollToComment: 'true',
          showComments: 'true',
          autoOpenComments: 'true',
          openCommentsSection: 'true',
          expandComments: 'true',
          focusComment: 'true',
          commenterName: maskedName,
          commentText: shortComment || '',
          commentTimestamp: Date.now().toString(),
          // เพิ่มข้อมูลเพื่อให้แน่ใจว่าจะเปิดคอมเมนต์
          shouldOpenComments: 'true',
          highlightCommentId: commentId,
          navigateToComment: 'true'
        },
        token: authorToken
      };
      
      try {
        const response = await admin.messaging().send(message);
        console.log(`✅ Comment notification sent successfully: ${response}`);
        
        return {
          success: true,
          messageId: response
        };
        
      } catch (sendError) {
        console.error('❌ Failed to send comment notification:', sendError);
        
        // ตรวจสอบประเภท error
        const errorCode = sendError.code;
        
        if (isInvalidTokenError(errorCode)) {
          // ลบ invalid token
          await removeInvalidTokens([authorToken]);
          console.log('🗑️ Removed invalid token for comment notification');
          return null;
          
        } else if (isRetryableError(errorCode)) {
          // เพิ่มเข้า retry queue
          await admin.firestore().collection(RETRY_QUEUE).add({
            message: {
              notification: message.notification,
              data: message.data,
              tokens: [authorToken] // แปลงเป็น array เพื่อความสอดคล้อง
            },
            attemptCount: 1,
            lastAttempt: admin.firestore.FieldValue.serverTimestamp(),
            nextAttempt: new Date(Date.now() + retryDelay[0] * 60000),
            maxAttempts: maxRetries,
            type: 'new_comment',
            reportId: reportId,
            commentId: commentId,
            targetUserId: postAuthorId,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            error: sendError.message
          });
          
          console.log('🔄 Added comment notification to retry queue');
          return {
            success: false,
            addedToRetryQueue: true,
            error: sendError.message
          };
        } else {
          // Error ที่ไม่สามารถ retry ได้
          console.error('❌ Non-retryable error for comment notification:', sendError);
          return null;
        }
      }
      
    } catch (error) {
      console.error('❌ Error in sendNewCommentNotification:', error);
      
      // เพิ่มข้อผิดพลาดทั้งหมดเข้า retry queue
      try {
        await admin.firestore().collection(RETRY_QUEUE).add({
          message: {
            notification: {
              title: '💬 มีความคิดเห็นใหม่!',
              body: 'มีคนแสดงความคิดเห็นในโพสต์ของคุณ'
            },
            data: {
              type: 'new_comment',
              reportId: context.params.reportId,
              commentId: context.params.commentId,
            }
          },
          attemptCount: 1,
          lastAttempt: admin.firestore.FieldValue.serverTimestamp(),
          nextAttempt: new Date(Date.now() + 5 * 60000), // 5 นาที
          maxAttempts: 3,
          type: 'new_comment_error',
          reportId: context.params.reportId,
          commentId: context.params.commentId,
          error: error.message,
          createdAt: admin.firestore.FieldValue.serverTimestamp()
        });
        
        console.log('🔄 Added comment notification error to retry queue');
      } catch (retryError) {
        console.error('❌ Failed to add comment notification to retry queue:', retryError);
      }
      
      return null;
    }
  });

/**
 * 🧹 ทำความสะอาด FCM Tokens ที่ไม่ใช้งานแล้ว
 */
async function cleanupInvalidTokens(response, tokens) {
  try {
    const invalidTokens = [];
    
    response.responses.forEach((resp, idx) => {
      if (!resp.success) {
        const error = resp.error;
        if (error.code === 'messaging/registration-token-not-registered' ||
            error.code === 'messaging/invalid-registration-token') {
          invalidTokens.push(tokens[idx]);
        }
      }
    });
    
    if (invalidTokens.length > 0) {
      console.log(`🧹 Cleaning up ${invalidTokens.length} invalid tokens`);
      
      // ลบ invalid tokens จากฐานข้อมูล
      const batch = admin.firestore().batch();
      const tokensSnapshot = await admin.firestore()
        .collection('user_tokens')
        .where('token', 'in', invalidTokens)
        .get();
      
      tokensSnapshot.docs.forEach(doc => {
        batch.update(doc.ref, {
          isActive: false,
          lastUpdated: admin.firestore.FieldValue.serverTimestamp()
        });
      });
      
      await batch.commit();
      console.log(`✅ Cleaned up ${invalidTokens.length} invalid tokens`);
    }
    
  } catch (error) {
    console.error('❌ Error cleaning up invalid tokens:', error);
  }
}

/**
 * 🧹 ลบ FCM Token เดียวที่ไม่ใช้งานแล้ว
 */
async function cleanupSingleInvalidToken(invalidToken) {
  try {
    console.log(`🧹 Cleaning up single invalid token: ${invalidToken.substring(0, 20)}...`);
    
    const tokensSnapshot = await admin.firestore()
      .collection('user_tokens')
      .where('token', '==', invalidToken)
      .get();
    
    if (!tokensSnapshot.empty) {
      const tokenDoc = tokensSnapshot.docs[0];
      await tokenDoc.ref.update({
        isActive: false,
        lastUpdated: admin.firestore.FieldValue.serverTimestamp()
      });
      
      console.log(`✅ Cleaned up invalid token for user: ${tokenDoc.data().userId}`);
    }
    
  } catch (error) {
    console.error('❌ Error cleaning up single invalid token:', error);
  }
}

/**
 * 🗺️ สร้างข้อความตำแหน่งที่อ่านง่ายและครบถ้วน
 * @param {Object} reportData - ข้อมูลรายงาน
 * @returns {string} - ข้อความตำแหน่งที่จัดรูปแบบแล้ว
 */
function buildLocationString(reportData) {
  const parts = [];
  
  // ลำดับความสำคัญ: อำเภอ > จังหวัด > ตำบล > ถนน
  if (reportData.district) {
    parts.push(reportData.district);
  }
  
  if (reportData.province && reportData.province !== reportData.district) {
    parts.push(reportData.province);
  }
  
  // เพิ่มข้อมูลถนนถ้ามี (แต่ไม่ยาวเกินไป)
  if (reportData.roadName && reportData.roadName.length <= 15) {
    parts.unshift(reportData.roadName); // ใส่ไว้หน้าสุด
  }
  
  // เพิ่มข้อมูลตำบลถ้ามีและไม่ซ้ำกับอำเภอ
  if (reportData.subDistrict && 
      reportData.subDistrict !== reportData.district && 
      parts.length < 3) { // จำกัดไม่เกิน 3 ส่วน
    parts.splice(-1, 0, reportData.subDistrict); // ใส่ก่อนจังหวัด
  }
  
  if (parts.length === 0) {
    // ถ้าไม่มีข้อมูลตำแหน่ง ลองใช้ location field
    if (reportData.location) {
      return reportData.location.length <= 20 ? reportData.location : null;
    }
    return null;
  }
  
  return parts.join(', ');
}

/**
 * 🏷️ ดึง emoji สำหรับหมวดหมู่ (ตรงกับ Flutter event_model_new.dart)
 */
function getCategoryEmoji(category) {
  const emojiMap = {
    'checkpoint': '🚓',
    'accident': '🚑',
    'fire': '🔥',
    'floodRain': '🌧',
    'tsunami': '🌊',
    'earthquake': '🌍',
    'animalLost': '🐶',
    'question': '❓'
  };
  return emojiMap[category] || '📍';
}

/**
 * 🏷️ ดึงชื่อหมวดหมู่ภาษาไทย (ตรงกับ Flutter event_model_new.dart)
 */
function getCategoryName(category) {
  const nameMap = {
    'checkpoint': 'ด่านตรวจ',
    'accident': 'อุบัติเหตุ',
    'fire': 'ไฟไหม้',
    'floodRain': 'ฝนตก/น้ำท่วม',
    'tsunami': 'สึนามิ',
    'earthquake': 'แผ่นดินไหว',
    'animalLost': 'สัตว์หาย',
    'question': 'คำถามทั่วไป'
  };
  return nameMap[category] || 'เหตุการณ์';
}

/**
 * 📍 **ส่งแจ้งเตือนตามพื้นที่** (Geographic Targeting)
 * ส่งแจ้งเตือนให้เฉพาะผู้ใช้ในพื้นที่ใกล้เคียงเท่านั้น
 */
exports.sendLocationBasedNotification = functions.https.onCall(async (data, context) => {
  try {
    // ตรวจสอบ authentication
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'กรุณาล็อกอินก่อนใช้งาน'
      );
    }

    const { reportId, targetProvinces, targetDistricts, message, title } = data;
    
    console.log(`📍 Sending location-based notification for report: ${reportId}`);
    console.log(`🎯 Target provinces: ${JSON.stringify(targetProvinces)}`);
    console.log(`🎯 Target districts: ${JSON.stringify(targetDistricts)}`);

    // ดึงข้อมูลโพสต์
    const reportDoc = await admin.firestore()
      .collection('reports')
      .doc(reportId)
      .get();

    if (!reportDoc.exists) {
      throw new functions.https.HttpsError(
        'not-found',
        'ไม่พบรายงานที่ระบุ'
      );
    }

    const reportData = reportDoc.data();

    // สร้าง query สำหรับหาผู้ใช้ในพื้นที่เป้าหมาย
    let userQuery = admin.firestore().collection('user_tokens');

    // กรองตามจังหวัด
    if (targetProvinces && targetProvinces.length > 0) {
      userQuery = userQuery.where('province', 'in', targetProvinces);
    }

    // กรองตามอำเภอ
    if (targetDistricts && targetDistricts.length > 0) {
      userQuery = userQuery.where('district', 'in', targetDistricts);
    }

    const targetUsersSnapshot = await userQuery.get();
    
    const tokens = [];
    targetUsersSnapshot.docs.forEach(doc => {
      const userData = doc.data();
      if (userData.tokens && Array.isArray(userData.tokens)) {
        userData.tokens.forEach(token => {
          if (token && token.length > 0) {
            tokens.push(token);
          }
        });
      }
    });

    if (tokens.length === 0) {
      return {
        success: false,
        message: 'ไม่พบผู้ใช้ในพื้นที่เป้าหมาย'
      };
    }

    // สร้างข้อความแจ้งเตือน
    const categoryEmoji = getCategoryEmoji(reportData.category);
    const categoryName = getCategoryName(reportData.category);
    const locationInfo = buildLocationString(reportData);

    const notificationMessage = {
      notification: {
        title: title || `🚨 ${categoryName}${locationInfo ? ` - ${locationInfo}` : ''}`,
        body: message || reportData.description || 'มีเหตุการณ์ใหม่ในพื้นที่ของคุณ',
      },
      data: {
        type: 'location_alert',
        reportId: reportId,
        category: reportData.category || '',
        location: reportData.location || '',
        district: reportData.district || '',
        province: reportData.province || '',
        fullLocation: locationInfo || '',
        urgency: 'high'
      },
      tokens: tokens
    };

    const response = await admin.messaging().sendEachForMulticast(notificationMessage);
    
    console.log(`📍 Location-based notification sent: ${response.successCount}/${tokens.length}`);

    return {
      success: true,
      successCount: response.successCount,
      failureCount: response.failureCount,
      targetUsers: targetUsersSnapshot.size,
      sentTokens: tokens.length,
      targetLocation: locationInfo
    };

  } catch (error) {
    console.error('❌ Error in sendLocationBasedNotification:', error);
    throw new functions.https.HttpsError(
      'internal',
      'ไม่สามารถส่งแจ้งเตือนได้',
      error.message
    );
  }
});

// ============================================================================
// 🔄 NOTIFICATION RETRY SYSTEM
// ============================================================================

/**
 * � **ส่งแจ้งเตือนโพสต์ใหม่ พร้อม Retry Logic**
 * ส่งแจ้งเตือนให้ผู้ใช้ทั้งหมด (ยกเว้นคนโพส) เมื่อมีโพสต์ใหม่
 */
exports.sendNewPostNotification = functions.firestore
  .document('reports/{reportId}')
  .onCreate(async (snapshot, context) => {
    const maxRetries = 3;
    const retryDelay = [5, 15, 30]; // นาที
    
    try {
      const reportId = context.params.reportId;
      const reportData = snapshot.data();
      const reporterId = reportData.userId;

      console.log(`🔔 New post with retry: ${reportId} by ${reporterId}`);

      // 🔍 ตรวจสอบว่ามีผู้ใช้ในระบบหรือไม่
      const allUsersSnapshot = await admin.firestore()
        .collection('user_tokens')
        .get();

      console.log(`📊 Total user_tokens documents: ${allUsersSnapshot.size}`);

      // Debug: แสดงข้อมูลทั้งหมดใน user_tokens collection
      allUsersSnapshot.docs.forEach((doc, index) => {
        const data = doc.data();
        console.log(`   User ${index + 1}: ${doc.id}`);
        console.log(`      tokens: ${JSON.stringify(data.tokens)}`);
        console.log(`      isActive: ${data.isActive}`);
        console.log(`      platform: ${data.platform}`);
      });

      // 1. ดึง token จาก Firestore (ตรวจสอบ structure ใหม่)
      const tokensSnapshot = await admin.firestore()
        .collection('user_tokens')
        .where('tokens', '!=', [])
        .get();

      console.log(`📊 Documents with non-empty tokens: ${tokensSnapshot.size}`);

      if (tokensSnapshot.empty) {
        console.log('⚠️ No users with valid tokens in database');
        console.log('💡 Suggestion: Check if Flutter app is saving tokens correctly');
        return null;
      }

      // กรองเอาเฉพาะผู้ใช้ที่ไม่ใช่คนโพส และมี tokens array
      const tokens = [];
      tokensSnapshot.docs.forEach(tokenDoc => {
        const tokenData = tokenDoc.data();
        const userId = tokenDoc.id; // userId เป็น document ID
        
        console.log(`   Checking user: ${userId} (reporter: ${reporterId})`);
        
        if (userId !== reporterId && tokenData.tokens && Array.isArray(tokenData.tokens)) {
          // เพิ่ม tokens ทั้งหมดของ user นี้
          tokenData.tokens.forEach(token => {
            if (token && token.length > 0) {
              tokens.push(token);
              console.log(`      ✅ Added token: ${token.substring(0, 20)}...`);
            }
          });
        } else if (userId === reporterId) {
          console.log(`      ⏭️ Skipped reporter's tokens`);
        } else {
          console.log(`      ⚠️ No valid tokens for user ${userId}`);
        }
      });

      if (tokens.length === 0) {
        console.log('⚠️ No target tokens after filtering');
        console.log(`💡 Reporter ID: ${reporterId}`);
        console.log(`💡 Available users: ${tokensSnapshot.docs.map(doc => doc.id).join(', ')}`);
        return null;
      }

      console.log(`📤 Found ${tokens.length} valid tokens for notification`)

      // 2. ดึงข้อมูลชื่อผู้โพส
      let posterName = 'ผู้ใช้';
      
      // ลองดึงชื่อจากโพสต์ก่อน (มักจะมี displayName)
      if (reportData.displayName) {
        posterName = reportData.displayName;
      } else {
        try {
          // ถ้าไม่มีในโพสต์ ลองดึงจาก user_tokens collection
          const posterTokenDoc = await admin.firestore()
            .collection('user_tokens')
            .doc(reporterId)
            .get();
          
          if (posterTokenDoc.exists) {
            const posterData = posterTokenDoc.data();
            posterName = posterData.displayName || posterData.username || posterData.name || 'ผู้ใช้';
          } else {
            // ถ้าไม่มีใน user_tokens ลองดึงจาก users collection
            const posterDoc = await admin.firestore()
              .collection('users')
              .doc(reporterId)
              .get();
            
            if (posterDoc.exists) {
              const posterData = posterDoc.data();
              posterName = posterData.displayName || posterData.username || posterData.name || 'ผู้ใช้';
            }
          }
        } catch (error) {
          console.log('⚠️ Could not fetch poster name:', error.message);
        }
      }
      
      // ปิดบางส่วนของชื่อคนโพส (แสดงแค่ 6 ตัวแรก แล้วใส่ ********)
      const maskedPosterName = posterName.length > 6 
        ? `${posterName.substring(0, 6)}********`
        : `${posterName}********`;

      // 3. สร้างข้อความแจ้งเตือนที่มีรายละเอียดและตำแหน่งที่ชัดเจน
      const categoryEmoji = getCategoryEmoji(reportData.category);
      const categoryName = getCategoryName(reportData.category);
      
      // สร้างข้อมูลตำแหน่งที่ครบถ้วน
      const locationInfo = buildLocationString(reportData);
      
      // ปรับปรุงข้อความแจ้งเตือนให้น่าสนใจและมีข้อมูลครบถ้วน พร้อมชื่อคนโพส
      const notificationTitle = `${categoryEmoji} ${categoryName}${locationInfo ? ` - ${locationInfo}` : ''}`;
      
      // สร้าง body ที่มีรายละเอียดและชื่อคนโพส
      let baseDescription = reportData.description || 'มีเหตุการณ์ใหม่';
      
      // จำกัดความยาวของคำอธิบายเพื่อให้มีที่สำหรับชื่อคนโพส
      if (baseDescription.length > 60) {
        baseDescription = baseDescription.substring(0, 57) + '...';
      }
      
      const notificationBody = `${maskedPosterName}: ${baseDescription}`;
      
      console.log(`📝 Poster name: ${posterName} -> Masked: ${maskedPosterName}`);
      console.log(`🔍 Report data displayName: ${reportData.displayName}`);
      console.log(`🔍 Reporter ID: ${reporterId}`);
      
      const message = {
        notification: {
          title: notificationTitle,
          body: notificationBody,
        },
        data: {
          type: 'new_post',
          reportId: reportId,
          category: reportData.category || '',
          location: reportData.location || '',
          district: reportData.district || '',
          province: reportData.province || '',
          roadName: reportData.roadName || '',
          subDistrict: reportData.subDistrict || '',
          fullLocation: buildLocationString(reportData) || '',
          // เพิ่มข้อมูลการนำทาง
          action: 'open_post',
          targetScreen: 'report_detail',
          // เพิ่มข้อมูลชื่อคนโพส
          posterName: maskedPosterName,
          originalPosterName: posterName
        },
        tokens: tokens
      };

      console.log(`📤 Attempting to send notification to ${tokens.length} tokens`);
      const response = await admin.messaging().sendEachForMulticast(message);
      
      console.log(`✅ Success: ${response.successCount}, Failed: ${response.failureCount}`);

      // 3. ตรวจสอบผลลัพธ์และจัดการ Failed Tokens
      if (response.failureCount > 0) {
        const failedTokens = [];
        const invalidTokens = [];
        
        response.responses.forEach((resp, idx) => {
          if (!resp.success) {
            const token = tokens[idx];
            const errorCode = resp.error?.code;
            
            console.log(`❌ Token failed: ${token.substring(0, 20)}... - Error: ${errorCode}`);
            
            // แยกประเภท error
            if (isInvalidTokenError(errorCode)) {
              invalidTokens.push(token);
            } else if (isRetryableError(errorCode)) {
              failedTokens.push(token);
            }
          }
        });

        // ลบ Invalid Tokens
        if (invalidTokens.length > 0) {
          console.log(`🗑️ Removing ${invalidTokens.length} invalid tokens`);
          await removeInvalidTokens(invalidTokens);
        }

        // 4. บันทึกไว้ใน retry queue สำหรับ Retryable Tokens
        if (failedTokens.length > 0) {
          console.log(`🔄 Adding ${failedTokens.length} tokens to retry queue`);
          
          await admin.firestore().collection(RETRY_QUEUE).add({
            message: {
              notification: message.notification,
              data: message.data,
              tokens: failedTokens
            },
            originalTokens: tokens,
            failedTokens: failedTokens,
            attemptCount: 1,
            lastAttempt: admin.firestore.FieldValue.serverTimestamp(),
            nextAttempt: new Date(Date.now() + retryDelay[0] * 60000),
            maxAttempts: maxRetries,
            type: 'new_post',
            reportId: reportId,
            createdAt: admin.firestore.FieldValue.serverTimestamp()
          });
        }
      }

      return {
        success: true,
        successCount: response.successCount,
        failureCount: response.failureCount,
        totalTokens: tokens.length
      };

    } catch (error) {
      console.error('❌ Error in sendNewPostNotification:', error);
      
      // ไม่ส่งแจ้งเตือนถ้าเกิด error
      return null;
    }
  });

/**
 * 🔄 **Retry Worker - ทำงานทุก 5 นาที**
 * ประมวลผล notification ที่ส่งไม่สำเร็จ
 */
exports.processRetryQueue = functions.pubsub
  .schedule('every 5 minutes')
  .timeZone('Asia/Bangkok')
  .onRun(async (context) => {
    try {
      console.log('🔄 Processing retry queue...');
      
      const now = new Date();
      const queue = await admin.firestore()
        .collection(RETRY_QUEUE)
        .where('nextAttempt', '<=', now)
        .limit(50) // ประมวลผลทีละ 50 รายการ
        .get();

      if (queue.empty) {
        console.log('📭 Retry queue is empty');
        return null;
      }

      console.log(`📤 Processing ${queue.size} items from retry queue`);

      const promises = queue.docs.map(async (doc) => {
        const data = doc.data();
        
        try {
          console.log(`🔄 Retrying ${data.type} - Attempt ${data.attemptCount}/${data.maxAttempts}`);
          
          // ส่ง notification อีกครั้ง
          const response = await admin.messaging().sendEachForMulticast(data.message);
          
          console.log(`📊 Retry result - Success: ${response.successCount}, Failed: ${response.failureCount}`);
          
          if (response.failureCount === 0) {
            // สำเร็จ - ลบออกจาก queue
            await doc.ref.delete();
            console.log(`✅ Retry successful for ${data.type}, removed from queue`);
            
          } else if (data.attemptCount < data.maxAttempts) {
            // ยังส่งไม่สำเร็จ แต่ยังไม่ครบจำนวนครั้ง
            const nextAttemptIndex = Math.min(data.attemptCount, 2); // สูงสุดคือ index 2
            const retryDelay = [5, 15, 30]; // นาที
            const nextAttemptDelay = retryDelay[nextAttemptIndex];
            
            // อัปเดต failed tokens
            const newFailedTokens = [];
            response.responses.forEach((resp, idx) => {
              if (!resp.success && !isInvalidTokenError(resp.error?.code)) {
                newFailedTokens.push(data.message.tokens[idx]);
              }
            });
            
            await doc.ref.update({
              attemptCount: data.attemptCount + 1,
              lastAttempt: admin.firestore.FieldValue.serverTimestamp(),
              nextAttempt: new Date(Date.now() + nextAttemptDelay * 60000),
              'message.tokens': newFailedTokens,
              lastError: `Failed attempt ${data.attemptCount + 1}: ${response.failureCount} failures`
            });
            
            console.log(`🔄 Retry attempt ${data.attemptCount + 1}/${data.maxAttempts} scheduled for ${nextAttemptDelay} minutes`);
            
          } else {
            // ครบจำนวนครั้งแล้ว - อัปเดตสถานะเป็น failed
            await doc.ref.update({
              status: 'failed',
              finalAttempt: admin.firestore.FieldValue.serverTimestamp(),
              lastError: 'Max retry attempts exceeded'
            });
            
            console.log(`❌ Max retry attempts exceeded for ${data.type}`);
          }
          
          // ทำความสะอาด invalid tokens
          const invalidTokens = [];
          response.responses.forEach((resp, idx) => {
            if (!resp.success && isInvalidTokenError(resp.error?.code)) {
              invalidTokens.push(data.message.tokens[idx]);
            }
          });
          
          if (invalidTokens.length > 0) {
            await removeInvalidTokens(invalidTokens);
          }

        } catch (error) {
          console.error(`❌ Error processing retry item ${doc.id}:`, error);
          
          // อัปเดต error ล่าสุด
          await doc.ref.update({
            lastError: error.message,
            lastAttempt: admin.firestore.FieldValue.serverTimestamp()
          });
        }
      });

      await Promise.all(promises);
      console.log('✅ Retry queue processing completed');

      return {
        success: true,
        processedItems: queue.size,
        timestamp: new Date().toISOString()
      };

    } catch (error) {
      console.error('❌ Error processing retry queue:', error);
      return null;
    }
  });

/**
 * 🧹 **ทำความสะอาด Retry Queue**
 * ลบรายการที่เก่าเกิน 24 ชั่วโมง
 */
exports.cleanupRetryQueue = functions.pubsub
  .schedule('every 24 hours')
  .timeZone('Asia/Bangkok')
  .onRun(async (context) => {
    try {
      console.log('🧹 Cleaning up retry queue...');

      const oneDayAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);
      
      const oldItemsSnapshot = await admin.firestore()
        .collection(RETRY_QUEUE)
        .where('createdAt', '<', oneDayAgo)
        .get();

      if (oldItemsSnapshot.empty) {
        console.log('🧹 No old retry queue items to clean up');
        return null;
      }

      const batch = admin.firestore().batch();
      oldItemsSnapshot.docs.forEach(doc => {
        batch.delete(doc.ref);
      });

      await batch.commit();
      console.log(`🧹 Cleaned up ${oldItemsSnapshot.size} old retry queue items`);

      return {
        success: true,
        cleanedItems: oldItemsSnapshot.size,
        timestamp: new Date().toISOString()
      };

    } catch (error) {
      console.error('❌ Error cleaning up retry queue:', error);
      return null;
    }
  });

/**
 * 🚫 **ตรวจสอบว่าเป็น Invalid Token Error หรือไม่**
 */
function isInvalidTokenError(errorCode) {
  const invalidErrorCodes = [
    'messaging/invalid-registration-token',
    'messaging/registration-token-not-registered',
    'messaging/invalid-package-name'
  ];
  return invalidErrorCodes.includes(errorCode);
}

/**
 * 🔄 **ตรวจสอบว่าเป็น Retryable Error หรือไม่**
 */
function isRetryableError(errorCode) {
  const retryableErrorCodes = [
    'messaging/internal-error',
    'messaging/server-unavailable',
    'messaging/timeout',
    'messaging/quota-exceeded',
    'messaging/third-party-auth-error'
  ];
  return retryableErrorCodes.includes(errorCode);
}

/**
 * 🗑️ **ลบ Invalid Tokens จาก Firestore**
 */
async function removeInvalidTokens(invalidTokens) {
  try {
    console.log(`🗑️ Removing ${invalidTokens.length} invalid tokens from database`);
    
    const batch = admin.firestore().batch();
    let batchCount = 0;

    for (const token of invalidTokens) {
      // ค้นหา documents ที่มี token นี้
      const tokenQuery = await admin.firestore()
        .collection('user_tokens')
        .where('token', '==', token)
        .get();

      tokenQuery.docs.forEach(doc => {
        batch.update(doc.ref, {
          isActive: false,
          lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
          invalidReason: 'Token no longer valid'
        });
        batchCount++;
      });

      // Commit batch เมื่อครบ 450 operations (เผื่อไว้)
      if (batchCount >= 450) {
        await batch.commit();
        console.log(`   ✅ Committed batch of ${batchCount} updates`);
        batchCount = 0;
      }
    }

    // Commit batch สุดท้าย
    if (batchCount > 0) {
      await batch.commit();
      console.log(`   ✅ Committed final batch of ${batchCount} updates`);
    }

    console.log(`✅ Removed ${invalidTokens.length} invalid tokens from database`);

  } catch (error) {
    console.error('❌ Error removing invalid tokens:', error);
    throw error;
  }
}

/**
 * 📊 **ตรวจสอบสถานะ Retry Queue**
 */
exports.getRetryQueueStatus = functions.https.onRequest(async (req, res) => {
  try {
    const db = admin.firestore();
    
    // นับจำนวนรายการใน retry queue
    const totalSnapshot = await db.collection(RETRY_QUEUE).get();
    const totalItems = totalSnapshot.size;
    
    // นับรายการที่รอการประมวลผล
    const now = new Date();
    const pendingSnapshot = await db.collection(RETRY_QUEUE)
      .where('nextAttempt', '<=', now)
      .get();
    const pendingItems = pendingSnapshot.size;
    
    // นับรายการที่ล้มเหลว
    const failedSnapshot = await db.collection(RETRY_QUEUE)
      .where('status', '==', 'failed')
      .get();
    const failedItems = failedSnapshot.size;
    
    // รายการล่าสุด
    const recentSnapshot = await db.collection(RETRY_QUEUE)
      .orderBy('createdAt', 'desc')
      .limit(5)
      .get();
    
    const recentItems = recentSnapshot.docs.map(doc => ({
      id: doc.id,
      type: doc.data().type,
      attemptCount: doc.data().attemptCount,
      maxAttempts: doc.data().maxAttempts,
      createdAt: doc.data().createdAt?.toDate?.()?.toISOString(),
      nextAttempt: doc.data().nextAttempt?.toDate?.()?.toISOString(),
      status: doc.data().status || 'pending'
    }));

    res.json({
      success: true,
      data: {
        totalItems,
        pendingItems,
        failedItems,
        activeItems: totalItems - failedItems,
        recentItems,
        lastUpdated: new Date().toISOString()
      }
    });

  } catch (error) {
    console.error('❌ Error getting retry queue status:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});
