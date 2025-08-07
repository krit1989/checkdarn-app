const admin = require('firebase-admin');
const functions = require('firebase-functions');

/**
 * 🔄 **Notification Retry System for Cloud Functions**
 * ระบบ Retry สำหรับ FCM Token ที่หมดอายุใน Backend
 * 
 * ฟีเจอร์:
 * - ตรวจสอบ FCM Response และจัดการ Invalid Token
 * - Retry Queue สำหรับข้อความที่ส่งไม่สำเร็จ
 * - Token Cleanup อัตโนมัติ
 * - Exponential Backoff สำหรับการ Retry
 */

// Collection สำหรับ Retry Queue
const RETRY_QUEUE_COLLECTION = 'notification_retry_queue';
const USER_TOKENS_COLLECTION = 'user_tokens';

// การตั้งค่า Retry
const RETRY_CONFIG = {
  maxAttempts: 3,
  delays: [5, 15, 30], // นาที
  exponentialBackoff: true
};

/**
 * 📤 **ส่ง Notification พร้อม Retry Logic**
 * @param {Object} notificationData - ข้อมูล notification
 * @param {Array} tokens - FCM tokens
 * @param {string} type - ประเภทการแจ้งเตือน
 * @returns {Promise<Object>} ผลลัพธ์การส่ง
 */
async function sendNotificationWithRetry(notificationData, tokens, type = 'general') {
  try {
    console.log(`🔔 Sending ${type} notification to ${tokens.length} tokens`);

    const message = {
      notification: notificationData.notification,
      data: notificationData.data || {},
      tokens: tokens
    };

    // ส่ง notification
    const response = await admin.messaging().sendMulticast(message);
    
    console.log(`✅ Sent successfully: ${response.successCount}/${tokens.length}`);
    console.log(`❌ Failed: ${response.failureCount}/${tokens.length}`);

    // ตรวจสอบ Failed Tokens
    if (response.failureCount > 0) {
      await handleFailedTokens(response, message, tokens, type);
    }

    return {
      success: true,
      successCount: response.successCount,
      failureCount: response.failureCount,
      totalTokens: tokens.length
    };

  } catch (error) {
    console.error('❌ Error sending notification:', error);
    
    // เพิ่มเข้า Retry Queue
    await addToRetryQueue({
      message: { notification: notificationData.notification, data: notificationData.data },
      tokens: tokens,
      type: type,
      error: error.message
    });

    return {
      success: false,
      error: error.message,
      totalTokens: tokens.length
    };
  }
}

/**
 * 🔍 **จัดการ Token ที่ส่งไม่สำเร็จ**
 * @param {Object} response - FCM Response
 * @param {Object} message - Message ที่ส่ง
 * @param {Array} originalTokens - Token เดิม
 * @param {string} type - ประเภทการแจ้งเตือน
 */
async function handleFailedTokens(response, message, originalTokens, type) {
  try {
    const failedTokens = [];
    const invalidTokens = [];
    const retryableTokens = [];

    response.responses.forEach((resp, index) => {
      if (!resp.success) {
        const token = originalTokens[index];
        const errorCode = resp.error?.code;

        console.log(`❌ Token failed: ${token.substring(0, 20)}... - Error: ${errorCode}`);

        failedTokens.push(token);

        // จำแนกประเภท Error
        if (isInvalidTokenError(errorCode)) {
          invalidTokens.push(token);
        } else if (isRetryableError(errorCode)) {
          retryableTokens.push(token);
        }
      }
    });

    // ลบ Invalid Tokens
    if (invalidTokens.length > 0) {
      console.log(`🗑️ Removing ${invalidTokens.length} invalid tokens`);
      await removeInvalidTokens(invalidTokens);
    }

    // เพิ่ม Retryable Tokens เข้า Queue
    if (retryableTokens.length > 0) {
      console.log(`🔄 Adding ${retryableTokens.length} tokens to retry queue`);
      await addToRetryQueue({
        message: message,
        tokens: retryableTokens,
        type: type,
        reason: 'retryable_error'
      });
    }

  } catch (error) {
    console.error('❌ Error handling failed tokens:', error);
  }
}

/**
 * 🚫 **ตรวจสอบว่าเป็น Invalid Token Error หรือไม่**
 * @param {string} errorCode - Error code จาก FCM
 * @returns {boolean}
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
 * @param {string} errorCode - Error code จาก FCM
 * @returns {boolean}
 */
function isRetryableError(errorCode) {
  const retryableErrorCodes = [
    'messaging/internal-error',
    'messaging/server-unavailable',
    'messaging/timeout',
    'messaging/quota-exceeded'
  ];
  return retryableErrorCodes.includes(errorCode);
}

/**
 * 🗑️ **ลบ Invalid Tokens จาก Firestore**
 * @param {Array} invalidTokens - Invalid tokens
 */
async function removeInvalidTokens(invalidTokens) {
  try {
    const batch = admin.firestore().batch();
    let batchCount = 0;

    for (const token of invalidTokens) {
      // ค้นหา documents ที่มี token นี้
      const tokenQuery = await admin.firestore()
        .collection(USER_TOKENS_COLLECTION)
        .where('fcmToken', '==', token)
        .get();

      tokenQuery.docs.forEach(doc => {
        batch.delete(doc.ref);
        batchCount++;
      });

      // Commit batch เมื่อครบ 500 operations
      if (batchCount >= 450) {
        await batch.commit();
        batchCount = 0;
      }
    }

    // Commit batch สุดท้าย
    if (batchCount > 0) {
      await batch.commit();
    }

    console.log(`✅ Removed ${invalidTokens.length} invalid tokens from database`);

  } catch (error) {
    console.error('❌ Error removing invalid tokens:', error);
  }
}

/**
 * 📥 **เพิ่มข้อความเข้า Retry Queue**
 * @param {Object} data - ข้อมูลที่จะ retry
 */
async function addToRetryQueue(data) {
  try {
    const queueItem = {
      message: data.message,
      tokens: data.tokens,
      type: data.type,
      attemptCount: 1,
      maxAttempts: RETRY_CONFIG.maxAttempts,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      nextAttempt: new Date(Date.now() + RETRY_CONFIG.delays[0] * 60000),
      lastError: data.error || data.reason || 'unknown',
      status: 'pending'
    };

    await admin.firestore()
      .collection(RETRY_QUEUE_COLLECTION)
      .add(queueItem);

    console.log(`📥 Added to retry queue: ${data.type} (${data.tokens.length} tokens)`);

  } catch (error) {
    console.error('❌ Error adding to retry queue:', error);
  }
}

/**
 * 🔄 **ประมวลผล Retry Queue (Cloud Function)**
 * ทำงานทุก 5 นาที
 */
exports.processRetryQueue = functions.pubsub
  .schedule('every 5 minutes')
  .onRun(async (context) => {
    try {
      console.log('🔄 Processing retry queue...');

      const now = new Date();
      const queueSnapshot = await admin.firestore()
        .collection(RETRY_QUEUE_COLLECTION)
        .where('status', '==', 'pending')
        .where('nextAttempt', '<=', now)
        .limit(50) // ประมวลผลทีละ 50 รายการ
        .get();

      if (queueSnapshot.empty) {
        console.log('📭 Retry queue is empty');
        return null;
      }

      console.log(`📤 Processing ${queueSnapshot.size} items from retry queue`);

      const promises = queueSnapshot.docs.map(async (doc) => {
        const data = doc.data();
        
        try {
          // พยายามส่งอีกครั้ง
          const response = await admin.messaging().sendMulticast({
            notification: data.message.notification,
            data: data.message.data || {},
            tokens: data.tokens
          });

          if (response.failureCount === 0) {
            // สำเร็จ - ลบออกจาก queue
            await doc.ref.delete();
            console.log(`✅ Retry successful for ${data.type}`);
          } else if (data.attemptCount < data.maxAttempts) {
            // ยังส่งไม่สำเร็จ แต่ยังไม่ครบจำนวนครั้ง
            const nextAttemptDelay = RETRY_CONFIG.delays[data.attemptCount] || 30;
            
            await doc.ref.update({
              attemptCount: data.attemptCount + 1,
              lastAttempt: admin.firestore.FieldValue.serverTimestamp(),
              nextAttempt: new Date(Date.now() + nextAttemptDelay * 60000),
              lastError: `Failed attempt ${data.attemptCount + 1}`
            });
            
            console.log(`🔄 Retry attempt ${data.attemptCount + 1}/${data.maxAttempts} for ${data.type}`);
          } else {
            // ครบจำนวนครั้งแล้ว - อัปเดตสถานะเป็น failed
            await doc.ref.update({
              status: 'failed',
              finalAttempt: admin.firestore.FieldValue.serverTimestamp(),
              lastError: 'Max retry attempts exceeded'
            });
            
            console.log(`❌ Max retry attempts exceeded for ${data.type}`);
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

      return null;

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
  .onRun(async (context) => {
    try {
      console.log('🧹 Cleaning up retry queue...');

      const oneDayAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);
      
      const oldItemsSnapshot = await admin.firestore()
        .collection(RETRY_QUEUE_COLLECTION)
        .where('createdAt', '<', oneDayAgo)
        .get();

      if (oldItemsSnapshot.empty) {
        console.log('🧹 No old items to clean up');
        return null;
      }

      const batch = admin.firestore().batch();
      oldItemsSnapshot.docs.forEach(doc => {
        batch.delete(doc.ref);
      });

      await batch.commit();
      console.log(`🧹 Cleaned up ${oldItemsSnapshot.size} old retry queue items`);

      return null;

    } catch (error) {
      console.error('❌ Error cleaning up retry queue:', error);
      return null;
    }
  });

// Export ฟังก์ชันหลัก
module.exports = {
  sendNotificationWithRetry,
  handleFailedTokens,
  addToRetryQueue,
  removeInvalidTokens
};
