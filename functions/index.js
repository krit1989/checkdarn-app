const functions = require('firebase-functions');
const admin = require('firebase-admin');
const { getStorage } = require('firebase-admin/storage');
const { v4: uuidv4 } = require('uuid');
const sharp = require('sharp');

// Initialize Firebase Admin
admin.initializeApp();

// 📷 **Image Compression Configuration**
const IMAGE_CONFIG = {
  QUALITY: 80,        // คุณภาพรูปภาพ (80%)
  MAX_WIDTH: 1200,    // ความกว้างสูงสุด
  MAX_HEIGHT: 1200,   // ความสูงสูงสุด
  FORMAT: 'webp',     // รูปแบบไฟล์ที่ประหยัดพื้นที่
  THUMBNAIL_SIZE: 300 // ขนาด thumbnail
};

/**
 * 🖼️ บีบอัดรูปภาพเพื่อประหยัด Storage
 * @param {Buffer} imageBuffer - Buffer ของรูปภาพ
 * @param {Object} options - ตัวเลือกการบีบอัด
 * @returns {Object} รูปภาพที่บีบอัดแล้ว
 */
async function compressImage(imageBuffer, options = {}) {
  try {
    const config = { ...IMAGE_CONFIG, ...options };
    
    // บีบอัดรูปภาพหลัก
    const compressedImage = await sharp(imageBuffer)
      .resize(config.MAX_WIDTH, config.MAX_HEIGHT, {
        fit: 'inside',
        withoutEnlargement: true
      })
      .webp({ quality: config.QUALITY })
      .toBuffer();

    // สร้าง thumbnail
    const thumbnail = await sharp(imageBuffer)
      .resize(config.THUMBNAIL_SIZE, config.THUMBNAIL_SIZE, {
        fit: 'cover',
        position: 'center'
      })
      .webp({ quality: 70 })
      .toBuffer();

    const originalSize = imageBuffer.length;
    const compressedSize = compressedImage.length;
    const savings = ((originalSize - compressedSize) / originalSize * 100).toFixed(1);

    console.log(`📷 Image compressed: ${originalSize} → ${compressedSize} bytes (${savings}% savings)`);

    return {
      compressedImage,
      thumbnail,
      metadata: {
        originalSize,
        compressedSize,
        savings: parseFloat(savings),
        format: 'webp'
      }
    };
  } catch (error) {
    console.error('❌ Image compression failed:', error);
    throw error;
  }
}

// 🛡️ **Token Validation Function - IMPROVED**
function isValidToken(token) {
  // ตรวจสอบ FCM token format ที่ถูกต้อง
  if (!token || typeof token !== 'string') return false;
  
  // FCM tokens ขึ้นต้นด้วย c, d, e, f และมีความยาวประมาณ 152+ characters
  // แต่ในการทดสอบอาจมี token ที่สั้นกว่า ดังนั้นลดข้อกำหนดลง
  if (token.length < 140) return false; // ลดจาก 152+ เป็น 140+
  
  // ตรวจสอบรูปแบบพื้นฐาน: ต้องมี colon (:) และ APA91b
  if (!token.includes(':') || !token.includes('APA91b')) return false;
  
  // ตรวจสอบว่าขึ้นต้นด้วยตัวอักษรที่ถูกต้อง
  const firstChar = token.charAt(0).toLowerCase();
  if (!['c', 'd', 'e', 'f'].includes(firstChar)) return false;
  
  // ตรวจสอบว่ามีอักขระที่ไม่อนุญาต
  if (!/^[a-zA-Z0-9_:-]+$/.test(token)) return false;
  
  return true;
}

// 💀 **Dead Letter Queue Function**
async function sendToDeadLetterQueue(data, reason, error = null) {
  try {
    const deadLetterData = {
      ...data,
      failedAt: admin.firestore.FieldValue.serverTimestamp(),
      reason: reason,
      error: error ? error.toString() : null,
      retryCount: data.attemptCount || 0,
      ttl: new Date(Date.now() + (NOTIFICATION_CONFIG.DEAD_LETTER_RETENTION_DAYS * 24 * 60 * 60 * 1000))
    };

    await admin.firestore().collection('dead_letters').add(deadLetterData);
    console.log(`💀 Sent to dead letter queue: ${reason}`);
    
    // 📊 อัปเดต telemetry สำหรับ dead letters
    await updateTelemetry('dead_letter_created', {
      reason: reason,
      hasError: error !== null,
      retryCount: data.attemptCount || 0
    });
    
  } catch (deadLetterError) {
    console.error('❌ Failed to send to dead letter queue:', deadLetterError);
  }
}

// 📊 **Enhanced Telemetry Function**
async function updateTelemetry(event, data = {}) {
  try {
    const telemetryData = {
      event: event,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      ...data,
      // เพิ่มข้อมูล context
      functionName: process.env.FUNCTION_NAME || 'unknown',
      region: process.env.FUNCTION_REGION || 'unknown',
    };

    await admin.firestore().collection('telemetry').add(telemetryData);
  } catch (error) {
    console.error('📊 Telemetry error (non-critical):', error);
  }
}

// 💾 **Enhanced Cache System** (เพื่อลด Firestore reads)
const cache = new Map();
const CACHE_STATS = {
  hits: 0,
  misses: 0,
  sets: 0,
  evictions: 0
};

/**
 * 🎯 Enhanced Cache Management
 */
class EnhancedCache {
  constructor(maxSize = 1000, ttlSeconds = 300) {
    this.cache = new Map();
    this.maxSize = maxSize;
    this.ttlSeconds = ttlSeconds;
    this.stats = { hits: 0, misses: 0, sets: 0, evictions: 0 };
  }

  get(key) {
    const cached = this.cache.get(key);
    if (cached && Date.now() - cached.timestamp < this.ttlSeconds * 1000) {
      this.stats.hits++;
      return cached.data;
    }
    
    if (cached) {
      this.cache.delete(key); // ลบข้อมูลหมดอาย
    }
    
    this.stats.misses++;
    return null;
  }

  set(key, data) {
    // ตรวจสอบขนาด cache
    if (this.cache.size >= this.maxSize) {
      this.evictOldest();
    }

    this.cache.set(key, {
      data: data,
      timestamp: Date.now()
    });
    
    this.stats.sets++;
  }

  evictOldest() {
    const oldestKey = this.cache.keys().next().value;
    if (oldestKey) {
      this.cache.delete(oldestKey);
      this.stats.evictions++;
    }
  }

  getStats() {
    const hitRate = this.stats.hits + this.stats.misses > 0 
      ? (this.stats.hits / (this.stats.hits + this.stats.misses) * 100).toFixed(1)
      : 0;
    
    return {
      ...this.stats,
      hitRate: `${hitRate}%`,
      size: this.cache.size,
      maxSize: this.maxSize
    };
  }

  clear() {
    this.cache.clear();
  }
}

// สร้าง cache instances สำหรับประเภทข้อมูลต่างๆ
const userCache = new EnhancedCache(500, 600);    // 10 นาที สำหรับข้อมูลผู้ใช้
const tokenCache = new EnhancedCache(1000, 300);  // 5 นาที สำหรับ FCM tokens
const locationCache = new EnhancedCache(200, 1800); // 30 นาที สำหรับข้อมูลตำแหน่ง

/**
 * 💾 Cached Firestore Query
 * @param {string} cacheKey - คีย์สำหรับ cache
 * @param {Function} queryFunction - ฟังก์ชันสำหรับ query Firestore
 * @param {EnhancedCache} cacheInstance - instance ของ cache ที่จะใช้
 * @returns {any} ข้อมูลจาก cache หรือ Firestore
 */
async function cachedFirestoreQuery(cacheKey, queryFunction, cacheInstance = tokenCache) {
  // ลองหาใน cache ก่อน
  const cachedData = cacheInstance.get(cacheKey);
  if (cachedData !== null) {
    console.log(`💾 Cache hit for key: ${cacheKey}`);
    return cachedData;
  }

  // ถ้าไม่มีใน cache ให้ query จาก Firestore
  console.log(`🔍 Cache miss for key: ${cacheKey}, querying Firestore...`);
  const data = await queryFunction();
  
  // เก็บผลลัพธ์ใน cache
  cacheInstance.set(cacheKey, data);
  console.log(`💾 Cached data for key: ${cacheKey}`);
  
  return data;
}

const circuitBreaker = {
  isOpen: false,
  failureCount: 0,
  successCount: 0,
  lastFailureTime: null,
  resetTimeout: 5 * 60 * 1000, // 5 นาที (default)
  consecutiveSuccesses: 0 // เพิ่มตัวแปรนับ success ต่อเนื่อง
};

function getCachedData(key, defaultValue = null) {
  const cached = cache.get(key);
  if (cached && Date.now() - cached.timestamp < NOTIFICATION_CONFIG.CACHE_TTL * 1000) {
    return cached.data;
  }
  return defaultValue;
}

function setCachedData(key, data) {
  cache.set(key, {
    data: data,
    timestamp: Date.now()
  });
}

// 🔌 **Circuit Breaker Functions** (Enhanced)
function recordSuccess() {
  circuitBreaker.successCount++;
  circuitBreaker.consecutiveSuccesses++; // เพิ่มการนับ success ต่อเนื่อง
  circuitBreaker.failureCount = Math.max(0, circuitBreaker.failureCount - 1);
  
  // 🎯 ปรับ reset timeout ตาม success ต่อเนื่อง
  if (circuitBreaker.consecutiveSuccesses >= NOTIFICATION_CONFIG.SUCCESS_THRESHOLD) {
    circuitBreaker.resetTimeout = NOTIFICATION_CONFIG.REDUCED_RESET_TIMEOUT;
    console.log(`⚡ Reduced reset timeout to ${circuitBreaker.resetTimeout / 1000 / 60} minutes due to consecutive successes`);
  }
  
  // รีเซ็ต circuit breaker หากมีความสำเร็จเพียงพอ
  if (circuitBreaker.isOpen && circuitBreaker.successCount >= 5) {
    circuitBreaker.isOpen = false;
    circuitBreaker.failureCount = 0;
    console.log('✅ Circuit breaker reset - service is healthy');
    
    // 📊 บันทึก telemetry
    updateTelemetry('circuit_breaker_reset', {
      successCount: circuitBreaker.successCount,
      consecutiveSuccesses: circuitBreaker.consecutiveSuccesses
    });
  }
}

function recordFailure() {
  circuitBreaker.failureCount++;
  circuitBreaker.consecutiveSuccesses = 0; // รีเซ็ต consecutive successes
  circuitBreaker.resetTimeout = 5 * 60 * 1000; // รีเซ็ตกลับเป็น default
  circuitBreaker.lastFailureTime = Date.now();
  
  const errorRate = circuitBreaker.failureCount / (circuitBreaker.failureCount + circuitBreaker.successCount);
  
  if (errorRate > NOTIFICATION_CONFIG.ERROR_THRESHOLD) {
    circuitBreaker.isOpen = true;
    console.error(`🚨 Circuit breaker opened! Error rate: ${(errorRate * 100).toFixed(1)}%`);
    
    // 📊 บันทึก telemetry
    updateTelemetry('circuit_breaker_opened', {
      errorRate: errorRate,
      failureCount: circuitBreaker.failureCount,
      successCount: circuitBreaker.successCount
    });
  }
}

function isCircuitBreakerOpen() {
  if (!circuitBreaker.isOpen) return false;
  
  // ตรวจสอบว่าควรรีเซ็ตหรือไม่
  if (Date.now() - circuitBreaker.lastFailureTime > circuitBreaker.resetTimeout) {
    circuitBreaker.isOpen = false;
    circuitBreaker.failureCount = 0;
    console.log('🔄 Circuit breaker reset after timeout');
    return false;
  }
  
  return true;
}

// 🧹 **Cache Cleanup** (ทำความสะอาดทุก 10 นาที)
setInterval(() => {
  const now = Date.now();
  for (const [key, value] of cache.entries()) {
    if (now - value.timestamp > NOTIFICATION_CONFIG.CACHE_TTL * 1000) {
      cache.delete(key);
    }
  }
}, 10 * 60 * 1000); // 10 นาที

// 🔄 **Retry Queue Collection**
const RETRY_QUEUE = 'notification_retry_queue';

// 📊 **Notification Settings** (สำหรับควบคุมค่าใช้จ่าย)
const NOTIFICATION_CONFIG = {
  MAX_RADIUS_KM: 30,        // รัศมีสูงสุดสำหรับการแจ้งเตือน (กิโลเมตร) - ลดจาก 50 เป็น 30
  BATCH_SIZE: 100,          // จำนวน tokens ต่อ batch - เพิ่มจาก 50 เป็น 100 เพื่อลด function calls
  MAX_DAILY_NOTIFICATIONS: 5000, // จำนวนแจ้งเตือนสูงสุดต่อวัน - ลดจาก 50000 เป็น 5000
  ENABLE_GEOGRAPHIC_FILTER: true, // เปิด/ปิดการกรองตามพื้นที่ - เปิดใช้งานทันที!
  BATCH_DELAY_MS: 50,       // หน่วงเวลาระหว่าง batch (milliseconds) - ลดจาก 100 เป็น 50
  MAX_RETRIES: 2,           // จำนวน retry สูงสุด - ลดจาก 3 เป็น 2
  CACHE_TTL: 300,           // Cache TTL ในวินาที (5 นาที)
  ERROR_THRESHOLD: 0.2,     // Circuit breaker threshold (20% error rate) - ปรับจาก 0.3
  EXPONENTIAL_BACKOFF_BASE: 5, // เริ่มต้น 5 นาที สำหรับ exponential backoff
  DEAD_LETTER_RETENTION_DAYS: 7, // เก็บ dead letters 7 วัน
  SUCCESS_THRESHOLD: 10,    // จำนวน success ต่อเนื่องเพื่อลด reset timeout
  REDUCED_RESET_TIMEOUT: 2 * 60 * 1000, // 2 นาที สำหรับกรณี success ต่อเนื่อง
  MAINTENANCE_MODE: false,  // โหมดบำรุงรักษา - หยุดส่งแจ้งเตือนชั่วคราว
  ONE_TOKEN_PER_USER: true, // ส่งเพียง 1 token ต่อผู้ใช้เพื่อลดค่าใช้จ่าย
  FAR_USER_PROBABILITY: 0.5, // โอกาสส่งแจ้งเตือนให้ผู้ใช้ที่อยู่ไกล (50%)
  ENABLE_TOPICS: false,      // ปิดใช้งาน FCM Topics ชั่วคราวเพื่อหลีกเลี่ยงการซ้ำ
  TOPIC_USAGE_RATIO: 0.7,  // ใช้ Topics 70% และ Individual tokens 30%
};

// 📡 **FCM Topics Configuration** (ประหยัดค่าใช้จ่าย)
const FCM_TOPICS = {
  EMERGENCY: 'emergency_alerts',     // แจ้งเตือนฉุกเฉิน
  FLOOD: 'flood_alerts',            // น้ำท่วม
  ACCIDENT: 'accident_alerts',      // อุบัติเหตุ
  TRAFFIC: 'traffic_alerts',        // จราจร
  GENERAL: 'general_alerts',        // ทั่วไป
  REGIONAL_PREFIX: 'region_',       // คำนำหน้าสำหรับภูมิภาค เช่น region_bangkok
};

/**
 * 📡 Smart Topic Selection สำหรับลดค่าใช้จ่าย
 * @param {Object} reportData - ข้อมูลรายงาน
 * @param {Array} filteredUsers - ผู้ใช้ที่ผ่านการกรอง
 * @returns {Object} ผลลัพธ์การเลือก topic/tokens
 */
async function smartTopicSelection(reportData, filteredUsers) {
  if (!NOTIFICATION_CONFIG.ENABLE_TOPICS) {
    return { useTopics: false, topics: [], individualTokens: filteredUsers };
  }

  const totalUsers = filteredUsers.length;
  const topicThreshold = 50; // ถ้ามีผู้ใช้มากกว่า 50 คน ให้ใช้ Topics

  // ตัดสินใจว่าจะใช้ Topics หรือไม่
  const shouldUseTopics = totalUsers >= topicThreshold;
  
  if (!shouldUseTopics) {
    console.log(`👥 Users count (${totalUsers}) below topic threshold (${topicThreshold}), using individual tokens`);
    return { 
      useTopics: false, 
      topics: [], 
      individualTokens: filteredUsers,
      reason: 'below_threshold'
    };
  }

  // เลือก Topics ตามประเภทรายงาน
  const selectedTopics = [];
  const category = reportData.category?.toLowerCase() || '';

  // เลือก topic หลักตามประเภท
  if (category.includes('flood') || category.includes('น้ำท่วม')) {
    selectedTopics.push(FCM_TOPICS.FLOOD);
  } else if (category.includes('accident') || category.includes('อุบัติเหตุ')) {
    selectedTopics.push(FCM_TOPICS.ACCIDENT);
  } else if (category.includes('traffic') || category.includes('จราจร')) {
    selectedTopics.push(FCM_TOPICS.TRAFFIC);
  } else {
    selectedTopics.push(FCM_TOPICS.GENERAL);
  }

  // เพิ่ม regional topic ถ้ามีข้อมูลจังหวัด
  if (reportData.province) {
    const provinceTopic = `${FCM_TOPICS.REGIONAL_PREFIX}${reportData.province.toLowerCase()}`;
    selectedTopics.push(provinceTopic);
  }

  // แบ่งผู้ใช้: 70% ใช้ Topics, 30% ใช้ Individual tokens
  const topicRatio = NOTIFICATION_CONFIG.TOPIC_USAGE_RATIO;
  const topicUserCount = Math.floor(totalUsers * topicRatio);
  const individualUserCount = totalUsers - topicUserCount;

  console.log(`📡 Topic strategy: ${topicUserCount} users via topics, ${individualUserCount} via individual tokens`);
  console.log(`📡 Selected topics: ${selectedTopics.join(', ')}`);

  return {
    useTopics: true,
    topics: selectedTopics,
    individualTokens: filteredUsers.slice(0, individualUserCount),
    topicUserCount: topicUserCount,
    individualUserCount: individualUserCount,
    strategy: 'hybrid'
  };
}

/**
 * 📡 ส่งแจ้งเตือนผ่าน FCM Topics
 * @param {Array} topics - รายการ topics
 * @param {Object} notificationData - ข้อมูลแจ้งเตือน
 * @param {string} reportId - ID ของรายงาน
 * @returns {Object} ผลลัพธ์การส่ง
 */
async function sendTopicNotifications(topics, notificationData, reportId) {
  const results = [];
  
  for (const topic of topics) {
    try {
      console.log(`📡 Sending notification to topic: ${topic}`);
      
      const message = {
        topic: topic,
        notification: {
          title: notificationData.title,
          body: notificationData.body,
        },
        data: {
          type: 'new_post',
          reportId: reportId,
          action: 'open_post',
          category: notificationData.category || '',
          location: notificationData.location || '',
          district: notificationData.district || '',
          province: notificationData.province || '',
          notificationType: 'topic',
          topic: topic
        },
        android: {
          priority: 'high',
          notification: {
            channel_id: 'high_importance_channel',
            priority: 'high'
          }
        },
        apns: {
          payload: {
            aps: {
              alert: {
                title: notificationData.title,
                body: notificationData.body
              },
              badge: 1,
              sound: 'default'
            }
          }
        }
      };

      const response = await admin.messaging().send(message);
      console.log(`✅ Topic notification sent successfully to ${topic}:`, response);
      
      results.push({
        topic: topic,
        success: true,
        messageId: response
      });

    } catch (error) {
      console.error(`❌ Failed to send topic notification to ${topic}:`, error);
      results.push({
        topic: topic,
        success: false,
        error: error.message
      });
    }
  }

  return results;
}

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
 * 🖼️ ฟังก์ชันบีบอัดรูปภาพอัตโนมัติเมื่อมีการอัปโหลด
 * 
 * Trigger เมื่อมีไฟล์ใหม่ใน Storage
 * จะบีบอัดรูปภาพและสร้าง thumbnail อัตโนมัติ
 */
exports.compressUploadedImage = functions.storage.object().onFinalize(async (object) => {
  const filePath = object.name;
  const contentType = object.contentType;
  const bucket = getStorage().bucket(object.bucket);

  // ตรวจสอบว่าเป็นไฟล์รูปภาพหรือไม่
  if (!contentType || !contentType.startsWith('image/')) {
    console.log('📎 Not an image file, skipping compression');
    return null;
  }

  // ตรวจสอบว่าไฟล์อยู่ในโฟลเดอร์รูปภาพหรือไม่
  if (!filePath.startsWith('images/')) {
    console.log('📁 File not in images folder, skipping compression');
    return null;
  }

  // หลีกเลี่ยงการประมวลผลไฟล์ที่บีบอัดแล้ว
  if (filePath.includes('_compressed') || filePath.includes('_thumb')) {
    console.log('🔄 Already processed file, skipping');
    return null;
  }

  try {
    console.log(`🖼️ Starting compression for: ${filePath}`);
    
    // ดาวน์โหลดไฟล์จาก Storage
    const file = bucket.file(filePath);
    const [imageBuffer] = await file.download();
    
    // บีบอัดรูปภาพ
    const compressedResult = await compressImage(imageBuffer);
    
    // สร้างชื่อไฟล์ใหม่
    const fileExtension = filePath.split('.').pop();
    const baseFileName = filePath.replace(`.${fileExtension}`, '');
    const compressedPath = `${baseFileName}_compressed.webp`;
    const thumbnailPath = `${baseFileName}_thumb.webp`;
    
    // อัปโหลดรูปภาพที่บีบอัดแล้ว
    const compressedFile = bucket.file(compressedPath);
    await compressedFile.save(compressedResult.compressedImage, {
      metadata: {
        contentType: 'image/webp',
        metadata: {
          originalSize: compressedResult.metadata.originalSize.toString(),
          compressedSize: compressedResult.metadata.compressedSize.toString(),
          savings: compressedResult.metadata.savings.toString(),
          processedAt: new Date().toISOString()
        }
      }
    });

    // อัปโหลด thumbnail
    const thumbnailFile = bucket.file(thumbnailPath);
    await thumbnailFile.save(compressedResult.thumbnail, {
      metadata: {
        contentType: 'image/webp',
        metadata: {
          type: 'thumbnail',
          processedAt: new Date().toISOString()
        }
      }
    });

    console.log(`✅ Image compression completed: ${compressedResult.metadata.savings}% savings`);
    console.log(`📁 Files created: ${compressedPath}, ${thumbnailPath}`);

    // อัปเดตข้อมูลใน Firestore (ถ้าจำเป็น)
    const reportId = baseFileName.split('/').pop();
    if (reportId) {
      try {
        await admin.firestore().collection('reports').doc(reportId).update({
          compressedImageUrl: `gs://${object.bucket}/${compressedPath}`,
          thumbnailUrl: `gs://${object.bucket}/${thumbnailPath}`,
          compressionMetadata: compressedResult.metadata,
          lastCompressed: admin.firestore.FieldValue.serverTimestamp()
        });
        console.log(`📝 Updated Firestore document for report: ${reportId}`);
      } catch (firestoreError) {
        console.warn('⚠️ Could not update Firestore document:', firestoreError.message);
      }
    }

    return null;

  } catch (error) {
    console.error('❌ Image compression failed:', error);
    return null;
  }
});


/**
 * 🔔 เมื่อมีโพสใหม่ - ส่งแจ้งเตือนให้ผู้ใช้อื่น (ยกเว้นคนโพส) - COST-OPTIMIZED VERSION
 * 
 * กฎ: เวลาที่มีโพสใหม่ ห้ามเตือนคนโพส
 * ✨ ปรับปรุงเพื่อลดค่าใช้จ่าย:
 * - ตรวจสอบโควต้ารายวัน
 * - กรองตามพื้นที่จริงๆ
 * - ส่งเพียง 1 token ต่อผู้ใช้
 * - ระบบโหมดบำรุงรักษา
 */
exports.sendNewPostNotification = functions.firestore
  .document('reports/{reportId}')
  .onCreate(async (snapshot, context) => {
    console.log('🚨 COST-OPTIMIZED NOTIFICATION FUNCTION TRIGGERED!');
    console.log('📊 Function startup time:', new Date().toISOString());
    console.log('📱 Report ID:', context.params.reportId);
    
    try {
      const reportId = context.params.reportId;
      const reportData = snapshot.data();
      const reporterId = reportData.userId;

      console.log(`🔔 New post notification for: ${reportId} by ${reporterId}`);
      console.log('📍 Report data:', JSON.stringify({
        category: reportData.category,
        lat: reportData.lat,
        lng: reportData.lng,
        hasDescription: !!reportData.description
      }));

      // �️ ตรวจสอบโหมดบำรุงรักษา
      if (NOTIFICATION_CONFIG.MAINTENANCE_MODE) {
        console.log('⚠️ System in maintenance mode - notifications disabled');
        return { success: false, reason: 'maintenance_mode' };
      }

      // 📍 ตรวจสอบข้อมูลพื้นฐาน
      if (!reportData.lat || !reportData.lng) {
        console.log('⚠️ Missing location data - lat:', reportData.lat, 'lng:', reportData.lng);
        return { success: false, reason: 'missing_location' };
      }

      // 👥 ดึงผู้ใช้ทั้งหมดที่ active ยกเว้นผู้โพส (ใช้ Cache)
      console.log('👥 Fetching active users with cache...');
      
      const usersSnapshot = await cachedFirestoreQuery(
        'active_users',
        async () => {
          return await admin.firestore()
            .collection('user_tokens')
            .where('isActive', '==', true)
            .get();
        },
        userCache
      );

      console.log(`📊 Found ${usersSnapshot.size} total active users`);

      if (usersSnapshot.empty) {
        console.log('⚠️ No active users found in database');
        return { success: true, sentCount: 0, reason: 'no_active_users' };
      }

      // 🎯 กรองตามพื้นที่หากเปิดใช้งาน
      let filteredUsers = usersSnapshot.docs.filter(doc => doc.id !== reporterId);
      console.log(`👥 After removing reporter: ${filteredUsers.length} users`);

      if (NOTIFICATION_CONFIG.ENABLE_GEOGRAPHIC_FILTER && reportData.lat && reportData.lng) {
        console.log('🗺️ Applying geographic filter...');
        filteredUsers = filterUsersByDistanceWithCostSaving(
          reportData.lat,
          reportData.lng,
          filteredUsers,
          NOTIFICATION_CONFIG.MAX_RADIUS_KM
        );
        console.log(`🎯 After geographic filter: ${filteredUsers.length} users`);
      }

      // 📡 Smart Topic Selection เพื่อประหยัดค่าใช้จ่าย
      const topicSelection = await smartTopicSelection(reportData, filteredUsers);
      console.log(`📡 Topic selection result:`, {
        useTopics: topicSelection.useTopics,
        topicsCount: topicSelection.topics?.length || 0,
        individualTokensCount: topicSelection.individualTokens?.length || 0
      });

      // 🎫 รวบรวม tokens จากผู้ใช้ที่จะได้รับแจ้งเตือนแบบ individual
      const tokens = [];
      let validUserCount = 0;
      let invalidUserCount = 0;
      
      topicSelection.individualTokens.forEach(doc => {
        const userData = doc.data();
        const userId = doc.id;
        
        if (NOTIFICATION_CONFIG.ONE_TOKEN_PER_USER) {
          // เลือก token ที่ดีที่สุดสำหรับผู้ใช้นี้
          const bestToken = selectBestTokenForUser(userData);
          if (bestToken) {
            tokens.push(bestToken);
            validUserCount++;
            console.log(`✅ Selected token for user ${userId}: ${bestToken.substring(0, 20)}...`);
          } else {
            invalidUserCount++;
            console.log(`❌ No valid token for user ${userId}`);
          }
        } else {
          // โหมดเก่า: รวบรวมทุก token (สำหรับ backup)
          let userTokens = [];
          
          if (userData.token && typeof userData.token === 'string') {
            userTokens.push(userData.token);
          }
          
          if (userData.tokens && Array.isArray(userData.tokens)) {
            userTokens = userTokens.concat(userData.tokens);
          }
          
          if (userData.tokens && typeof userData.tokens === 'object' && !Array.isArray(userData.tokens)) {
            userTokens = userTokens.concat(Object.values(userData.tokens));
          }
          
          const validTokens = userTokens.filter(token => isValidToken(token));
          if (validTokens.length > 0) {
            tokens.push(...validTokens);
            validUserCount++;
          } else {
            invalidUserCount++;
          }
        }
      });

      console.log(`📊 Token summary: ${tokens.length} individual tokens from ${validUserCount} users, ${invalidUserCount} users without valid tokens`);

      // 📡 ส่งแจ้งเตือนผ่าน Topics ก่อน (ถ้าเปิดใช้งาน)
      let topicResults = [];
      if (topicSelection.useTopics && topicSelection.topics.length > 0) {
        console.log('� Sending topic notifications...');
        
        const notificationData = {
          title: `${getCategoryEmoji(reportData.category)} ${getCategoryName(reportData.category)}${buildLocationString(reportData) ? ` - ${buildLocationString(reportData)}` : ''}`,
          body: reportData.description || 'มีเหตุการณ์ใหม่ในพื้นที่ของคุณ',
          category: reportData.category || '',
          location: reportData.location || '',
          district: reportData.district || '',
          province: reportData.province || ''
        };

        topicResults = await sendTopicNotifications(topicSelection.topics, notificationData, reportId);
        console.log(`📡 Topic notifications sent to ${topicSelection.topics.length} topics`);
      }

      // ตรวจสอบว่ายังมี individual tokens ให้ส่งหรือไม่
      if (tokens.length === 0) {
        console.log('📭 No individual tokens to send, only topic notifications');
        return { 
          success: true, 
          sentCount: 0, 
          reason: 'topics_only',
          topicResults: topicResults,
          hybridStrategy: {
            topicNotifications: topicSelection.topics.length,
            individualNotifications: 0,
            estimatedTopicRecipients: topicSelection.topicUserCount || 0
          },
          debug: {
            totalUsers: usersSnapshot.size,
            filteredUsers: filteredUsers.length,
            validUserCount: validUserCount,
            invalidUserCount: invalidUserCount
          }
        };
      }

      // � ตรวจสอบโควต้าการส่งรายวัน
      console.log('📊 Checking daily quota...');
      const quotaCheck = await checkAndUpdateDailyQuota(tokens.length);
      
      if (!quotaCheck.allowed) {
        console.log(`⚠️ Daily quota exceeded! Current: ${quotaCheck.currentCount}, Remaining: ${quotaCheck.remaining}, Would exceed: ${quotaCheck.wouldExceed}`);
        
        // ส่งเฉพาะจำนวนที่เหลือถ้ามี
        if (quotaCheck.remaining > 0) {
          const allowedTokens = tokens.slice(0, quotaCheck.remaining);
          console.log(`📤 Sending to remaining quota: ${allowedTokens.length} notifications`);
          
          // อัปเดตโควต้าสำหรับจำนวนที่จะส่งจริง
          await checkAndUpdateDailyQuota(allowedTokens.length);
          
          return await sendNotificationsInBatches(allowedTokens, reportData, reportId, {
            quotaLimited: true,
            originalTokenCount: tokens.length,
            allowedTokenCount: allowedTokens.length
          });
        } else {
          return { 
            success: false, 
            reason: 'daily_quota_exceeded',
            quotaInfo: quotaCheck
          };
        }
      }

      console.log(`✅ Daily quota check passed: ${quotaCheck.currentCount}/${NOTIFICATION_CONFIG.MAX_DAILY_NOTIFICATIONS}`);

      // 🚀 ส่งแจ้งเตือนแบบ batch
      return await sendNotificationsInBatches(tokens, reportData, reportId, {
        quotaInfo: quotaCheck,
        geographicFilterUsed: NOTIFICATION_CONFIG.ENABLE_GEOGRAPHIC_FILTER,
        oneTokenPerUser: NOTIFICATION_CONFIG.ONE_TOKEN_PER_USER
      });

    } catch (error) {
      console.error('❌ Error in cost-optimized notification function:', error);
      console.error('❌ Error stack:', error.stack);
      return { 
        success: false, 
        error: error.message,
        stack: error.stack 
      };
    }
  });

/**
 * � ส่งแจ้งเตือนแบบ batch พร้อมการควบคุมค่าใช้จ่าย
 * @param {Array} tokens - array ของ FCM tokens
 * @param {Object} reportData - ข้อมูลรายงาน
 * @param {string} reportId - ID ของรายงาน
 * @param {Object} metadata - ข้อมูลเพิ่มเติม
 * @returns {Object} - ผลลัพธ์การส่ง
 */
async function sendNotificationsInBatches(tokens, reportData, reportId, metadata = {}) {
  try {
    console.log(`🚀 Starting batch notification for ${tokens.length} tokens`);
    
    // 📝 สร้างข้อความแจ้งเตือน
    const categoryEmoji = getCategoryEmoji(reportData.category);
    const categoryName = getCategoryName(reportData.category);
    const locationInfo = buildLocationString(reportData);

    const notificationTitle = `${categoryEmoji} ${categoryName}${locationInfo ? ` - ${locationInfo}` : ''}`;
    const notificationBody = reportData.description || 'มีเหตุการณ์ใหม่ในพื้นที่ของคุณ';

    console.log('📝 Notification content:');
    console.log('  Title:', notificationTitle);
    console.log('  Body:', notificationBody.substring(0, 50) + '...');

    // 📊 ตัวแปรสำหรับเก็บสถิติ
    let totalSent = 0;
    let totalFailed = 0;
    let batchCount = 0;
    const batchResults = [];
    const invalidTokens = [];

    // 🔄 แบ่งส่งเป็น batches
    for (let i = 0; i < tokens.length; i += NOTIFICATION_CONFIG.BATCH_SIZE) {
      batchCount++;
      const batchTokens = tokens.slice(i, i + NOTIFICATION_CONFIG.BATCH_SIZE);
      const batchStartTime = Date.now();
      
      console.log(`📦 Processing batch ${batchCount}/${Math.ceil(tokens.length / NOTIFICATION_CONFIG.BATCH_SIZE)} (${batchTokens.length} tokens)`);

      try {
        // สร้างข้อความสำหรับ batch นี้
        const messages = batchTokens.map(token => ({
          notification: {
            title: notificationTitle,
            body: notificationBody,
          },
          data: {
            type: 'new_post',
            reportId: reportId,
            action: 'open_post',
            category: reportData.category || '',
            location: reportData.location || '',
            district: reportData.district || '',
            province: reportData.province || '',
            fullLocation: locationInfo || '',
            batchId: `${reportId}_${batchCount}`,
            totalBatches: Math.ceil(tokens.length / NOTIFICATION_CONFIG.BATCH_SIZE).toString()
          },
          token: token
        }));

        // ส่งแจ้งเตือน
        const response = await admin.messaging().sendEach(messages);
        
        const batchDuration = Date.now() - batchStartTime;
        console.log(`📊 Batch ${batchCount} result: ${response.successCount} sent, ${response.failureCount} failed (${batchDuration}ms)`);

        totalSent += response.successCount;
        totalFailed += response.failureCount;

        // 🧹 จัดการกับ tokens ที่ล้มเหลว
        if (response.failureCount > 0) {
          response.responses.forEach((resp, idx) => {
            if (!resp.success) {
              const errorCode = resp.error?.code;
              const token = batchTokens[idx];
              
              console.log(`❌ Failed token in batch ${batchCount}:`, errorCode, resp.error?.message?.substring(0, 100));
              
              if (isInvalidTokenError(errorCode)) {
                invalidTokens.push(token);
              }
            }
          });
        }

        batchResults.push({
          batchNumber: batchCount,
          tokensCount: batchTokens.length,
          successCount: response.successCount,
          failureCount: response.failureCount,
          duration: batchDuration
        });

        // 🛌 หน่วงเวลาระหว่าง batches (ยกเว้น batch สุดท้าย)
        if (i + NOTIFICATION_CONFIG.BATCH_SIZE < tokens.length) {
          console.log(`⏳ Waiting ${NOTIFICATION_CONFIG.BATCH_DELAY_MS}ms before next batch...`);
          await new Promise(resolve => setTimeout(resolve, NOTIFICATION_CONFIG.BATCH_DELAY_MS));
        }

      } catch (batchError) {
        console.error(`❌ Error in batch ${batchCount}:`, batchError);
        totalFailed += batchTokens.length;
        
        batchResults.push({
          batchNumber: batchCount,
          tokensCount: batchTokens.length,
          successCount: 0,
          failureCount: batchTokens.length,
          error: batchError.message
        });
      }
    }

    // 🧹 ลบ invalid tokens
    if (invalidTokens.length > 0) {
      console.log(`🧹 Removing ${invalidTokens.length} invalid tokens from database`);
      try {
        await removeInvalidTokens(invalidTokens);
      } catch (cleanupError) {
        console.error('❌ Error removing invalid tokens:', cleanupError);
      }
    }

    // 📊 สรุปผลลัพธ์
    const result = {
      success: true,
      sentCount: totalSent,
      failedCount: totalFailed,
      totalTokens: tokens.length,
      batchCount: batchCount,
      invalidTokensRemoved: invalidTokens.length,
      costOptimization: {
        oneTokenPerUser: metadata.oneTokenPerUser || false,
        geographicFilterUsed: metadata.geographicFilterUsed || false,
        quotaLimited: metadata.quotaLimited || false,
        originalTokenCount: metadata.originalTokenCount || tokens.length,
        allowedTokenCount: metadata.allowedTokenCount || tokens.length
      },
      quotaInfo: metadata.quotaInfo || null,
      batchResults: batchResults,
      performanceMetrics: {
        avgBatchDuration: batchResults.length > 0 
          ? batchResults.reduce((sum, batch) => sum + (batch.duration || 0), 0) / batchResults.length 
          : 0,
        successRate: tokens.length > 0 ? (totalSent / tokens.length * 100).toFixed(1) + '%' : '0%'
      }
    };

    console.log('✅ Batch notification completed:', {
      totalSent,
      totalFailed,
      totalTokens: tokens.length,
      batchCount,
      successRate: result.performanceMetrics.successRate
    });

    return result;

  } catch (error) {
    console.error('❌ Error in sendNotificationsInBatches:', error);
    return {
      success: false,
      error: error.message,
      sentCount: 0,
      failedCount: tokens.length,
      totalTokens: tokens.length
    };
  }
}

/**
 * 📊 ฟังก์ชันตรวจสอบสถานะโควต้าการส่งแจ้งเตือน
 */
exports.getNotificationQuotaStatus = functions.https.onRequest(async (req, res) => {
  try {
    const today = new Date().toISOString().split('T')[0];
    const counterDoc = await admin.firestore()
      .collection('notification_counters')
      .doc(today)
      .get();
    
    const currentCount = counterDoc.exists ? (counterDoc.data().count || 0) : 0;
    const remaining = Math.max(0, NOTIFICATION_CONFIG.MAX_DAILY_NOTIFICATIONS - currentCount);
    const usagePercentage = (currentCount / NOTIFICATION_CONFIG.MAX_DAILY_NOTIFICATIONS * 100).toFixed(1);
    
    // ดึงข้อมูลสถิติ 7 วันที่ผ่านมา
    const weeklyStats = [];
    for (let i = 0; i < 7; i++) {
      const date = new Date();
      date.setDate(date.getDate() - i);
      const dateStr = date.toISOString().split('T')[0];
      
      const dayDoc = await admin.firestore()
        .collection('notification_counters')
        .doc(dateStr)
        .get();
      
      weeklyStats.push({
        date: dateStr,
        count: dayDoc.exists ? (dayDoc.data().count || 0) : 0,
        lastUpdated: dayDoc.exists ? dayDoc.data().lastUpdated?.toDate?.()?.toISOString() : null
      });
    }

    res.json({
      success: true,
      data: {
        today: {
          date: today,
          currentCount: currentCount,
          maxDaily: NOTIFICATION_CONFIG.MAX_DAILY_NOTIFICATIONS,
          remaining: remaining,
          usagePercentage: usagePercentage + '%',
          status: remaining > 1000 ? 'healthy' : remaining > 100 ? 'warning' : 'critical'
        },
        configuration: {
          maxDailyNotifications: NOTIFICATION_CONFIG.MAX_DAILY_NOTIFICATIONS,
          maxRadius: NOTIFICATION_CONFIG.MAX_RADIUS_KM,
          batchSize: NOTIFICATION_CONFIG.BATCH_SIZE,
          geographicFilterEnabled: NOTIFICATION_CONFIG.ENABLE_GEOGRAPHIC_FILTER,
          oneTokenPerUser: NOTIFICATION_CONFIG.ONE_TOKEN_PER_USER,
          maintenanceMode: NOTIFICATION_CONFIG.MAINTENANCE_MODE
        },
        weeklyStats: weeklyStats,
        lastUpdated: new Date().toISOString()
      }
    });

  } catch (error) {
    console.error('❌ Error getting quota status:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * 🛠️ ฟังก์ชันสำหรับควบคุมโหมดบำรุงรักษา
 */
exports.setMaintenanceMode = functions.https.onCall(async (data, context) => {
  try {
    // ตรวจสอบ authentication (ควรเป็น admin)
    if (!context.auth || !context.auth.token.admin) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Only administrators can control maintenance mode'
      );
    }

    const { enabled, reason } = data;
    const isEnabled = Boolean(enabled);
    
    // อัปเดต configuration (ในการใช้งานจริงควรเก็บใน Firestore)
    console.log(`🛠️ ${isEnabled ? 'Enabling' : 'Disabling'} maintenance mode. Reason: ${reason || 'Not specified'}`);
    
    // บันทึกการเปลี่ยนแปลง
    await admin.firestore().collection('system_config').doc('maintenance').set({
      enabled: isEnabled,
      reason: reason || null,
      updatedBy: context.auth.uid,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      previousState: NOTIFICATION_CONFIG.MAINTENANCE_MODE
    });

    // อัปเดต configuration (ในโค้ดจริงควรอ่านจาก Firestore)
    // NOTIFICATION_CONFIG.MAINTENANCE_MODE = isEnabled;

    return {
      success: true,
      maintenanceMode: isEnabled,
      reason: reason,
      message: `Maintenance mode ${isEnabled ? 'enabled' : 'disabled'} successfully`
    };

  } catch (error) {
    console.error('❌ Error setting maintenance mode:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to update maintenance mode',
      error.message
    );
  }
});

/**
 * 📊 ฟังก์ชันสำหรับจัดการการสมัครสมาชิก topics ตามหมวดหมู่
 */
exports.manageTopicSubscriptions = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'กรุณาล็อกอินก่อนใช้งาน'
      );
    }

    const { token, categories, action } = data; // action: 'subscribe' หรือ 'unsubscribe'
    
    if (!token || !isValidToken(token)) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Invalid FCM token provided'
      );
    }

    if (!categories || !Array.isArray(categories)) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Categories must be an array'
      );
    }

    const validCategories = ['checkpoint', 'accident', 'fire', 'floodRain', 'tsunami', 'earthquake', 'animalLost', 'question'];
    const filteredCategories = categories.filter(cat => validCategories.includes(cat));

    if (filteredCategories.length === 0) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'No valid categories provided'
      );
    }

    const results = [];
    
    for (const category of filteredCategories) {
      const topicName = `category_${category}`;
      
      try {
        if (action === 'subscribe') {
          await admin.messaging().subscribeToTopic(token, topicName);
          console.log(`✅ Subscribed token to topic: ${topicName}`);
        } else if (action === 'unsubscribe') {
          await admin.messaging().unsubscribeFromTopic(token, topicName);
          console.log(`❌ Unsubscribed token from topic: ${topicName}`);
        }
        
        results.push({
          category: category,
          topic: topicName,
          success: true,
          action: action
        });
        
      } catch (error) {
        console.error(`❌ Error ${action}ing token to/from topic ${topicName}:`, error);
        results.push({
          category: category,
          topic: topicName,
          success: false,
          error: error.message,
          action: action
        });
      }
    }

    // บันทึกการเปลี่ยนแปลง preferences ของผู้ใช้
    await admin.firestore()
      .collection('user_preferences')
      .doc(context.auth.uid)
      .set({
        subscribedCategories: action === 'subscribe' 
          ? admin.firestore.FieldValue.arrayUnion(...filteredCategories)
          : admin.firestore.FieldValue.arrayRemove(...filteredCategories),
        lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
        token: token
      }, { merge: true });

    return {
      success: true,
      results: results,
      action: action,
      processedCategories: filteredCategories.length
    };

  } catch (error) {
    console.error('❌ Error managing topic subscriptions:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to manage topic subscriptions',
      error.message
    );
  }
});

/**
 * 📡 ส่งแจ้งเตือนผ่าน topics (ประหยัดค่าใช้จ่ายมากกว่า)
 */
exports.sendNotificationByTopic = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'กรุณาล็อกอินก่อนใช้งาน'
      );
    }

    const { reportId, category, customTitle, customBody } = data;
    
    // ดึงข้อมูลรายงาน
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
    const topicName = `category_${category || reportData.category}`;
    
    // สร้างข้อความแจ้งเตือน
    const categoryEmoji = getCategoryEmoji(reportData.category);
    const categoryName = getCategoryName(reportData.category);
    const locationInfo = buildLocationString(reportData);

    const message = {
      topic: topicName,
      notification: {
        title: customTitle || `${categoryEmoji} ${categoryName}${locationInfo ? ` - ${locationInfo}` : ''}`,
        body: customBody || reportData.description || 'มีเหตุการณ์ใหม่ในหมวดหมู่ที่คุณสนใจ',
      },
      data: {
        type: 'topic_notification',
        reportId: reportId,
        category: reportData.category || '',
        topic: topicName,
        action: 'open_post'
      }
    };

    const response = await admin.messaging().send(message);
    
    console.log(`📡 Topic notification sent to ${topicName}:`, response);

    return {
      success: true,
      messageId: response,
      topic: topicName,
      category: category || reportData.category
    };

  } catch (error) {
    console.error('❌ Error sending topic notification:', error);
    throw new functions.https.HttpsError(
      'internal',
      'ไม่สามารถส่งแจ้งเตือนได้',
      error.message
    );
  }
});

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
 * 🧹 ฟังก์ชันตรวจสอบว่า error code เป็น invalid token หรือไม่
 */
function isInvalidTokenError(errorCode) {
  const invalidTokenErrors = [
    'messaging/registration-token-not-registered',
    'messaging/invalid-registration-token',
    'messaging/unregistered-device',
    'messaging/invalid-argument'
  ];
  return invalidTokenErrors.includes(errorCode);
}

/**
 * 🔄 ฟังก์ชันตรวจสอบว่า error สามารถ retry ได้หรือไม่
 */
function isRetryableError(errorCode) {
  const retryableErrors = [
    'messaging/internal-error',
    'messaging/quota-exceeded',
    'messaging/server-unavailable',
    'messaging/timeout',
    'messaging/unavailable'
  ];
  return retryableErrors.includes(errorCode);
}

/**
 * 🗑️ ลบ invalid tokens จากฐานข้อมูล
 */
async function removeInvalidTokens(invalidTokens) {
  try {
    console.log(`🗑️ Removing ${invalidTokens.length} invalid tokens...`);
    
    const batch = admin.firestore().batch();
    let updateCount = 0;
    
    for (const invalidToken of invalidTokens) {
      // ค้นหาผู้ใช้ที่มี token นี้ใน field 'token'
      const tokenQuery1 = await admin.firestore()
        .collection('user_tokens')
        .where('token', '==', invalidToken)
        .get();
      
      tokenQuery1.docs.forEach(doc => {
        batch.update(doc.ref, {
          token: admin.firestore.FieldValue.delete(),
          lastUpdated: admin.firestore.FieldValue.serverTimestamp()
        });
        updateCount++;
        console.log(`  🗑️ Removing token from user ${doc.id} (token field)`);
      });
      
      // ค้นหาผู้ใช้ที่มี token นี้ใน field 'tokens' array
      const tokenQuery2 = await admin.firestore()
        .collection('user_tokens')
        .where('tokens', 'array-contains', invalidToken)
        .get();
      
      tokenQuery2.docs.forEach(doc => {
        batch.update(doc.ref, {
          tokens: admin.firestore.FieldValue.arrayRemove(invalidToken),
          lastUpdated: admin.firestore.FieldValue.serverTimestamp()
        });
        updateCount++;
        console.log(`  🗑️ Removing token from user ${doc.id} (tokens array)`);
      });
    }
    
    if (updateCount > 0) {
      await batch.commit();
      console.log(`✅ Successfully removed ${updateCount} invalid token references`);
    } else {
      console.log('ℹ️ No token references found to remove');
    }
    
  } catch (error) {
    console.error('❌ Error removing invalid tokens:', error);
  }
}

/**
 * 🧮 ตรวจสอบและอัปเดตโควต้าการส่งแจ้งเตือนรายวัน
 * @param {number} requestedCount - จำนวนแจ้งเตือนที่ต้องการส่ง
 * @returns {Object} - {allowed: boolean, currentCount: number, remaining: number}
 */
async function checkAndUpdateDailyQuota(requestedCount) {
  try {
    const today = new Date().toISOString().split('T')[0];
    const counterRef = admin.firestore().collection('notification_counters').doc(today);
    
    // ใช้ transaction เพื่อป้องกัน race condition
    const result = await admin.firestore().runTransaction(async (transaction) => {
      const counterDoc = await transaction.get(counterRef);
      const currentCount = counterDoc.exists ? (counterDoc.data().count || 0) : 0;
      const newCount = currentCount + requestedCount;
      
      if (newCount > NOTIFICATION_CONFIG.MAX_DAILY_NOTIFICATIONS) {
        return {
          allowed: false,
          currentCount: currentCount,
          remaining: Math.max(0, NOTIFICATION_CONFIG.MAX_DAILY_NOTIFICATIONS - currentCount),
          wouldExceed: newCount - NOTIFICATION_CONFIG.MAX_DAILY_NOTIFICATIONS
        };
      }
      
      // อัปเดต counter
      transaction.set(counterRef, {
        count: newCount,
        lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
        date: today
      }, { merge: true });
      
      return {
        allowed: true,
        currentCount: newCount,
        remaining: NOTIFICATION_CONFIG.MAX_DAILY_NOTIFICATIONS - newCount,
        previousCount: currentCount
      };
    });
    
    console.log(`📊 Daily quota check: ${result.currentCount}/${NOTIFICATION_CONFIG.MAX_DAILY_NOTIFICATIONS}`);
    return result;
    
  } catch (error) {
    console.error('❌ Error checking daily quota:', error);
    // ในกรณีเกิดข้อผิดพลาด ให้อนุญาตส่งเพื่อไม่ให้ระบบหยุดทำงาน
    return { allowed: true, currentCount: 0, remaining: NOTIFICATION_CONFIG.MAX_DAILY_NOTIFICATIONS, error: error.message };
  }
}

/**
 * 🎯 กรองผู้ใช้ตามระยะทางพร้อมระบบประหยัดค่าใช้จ่าย
 * @param {number} reportLat - ละติจูดของรายงาน
 * @param {number} reportLng - ลองจิจูดของรายงาน
 * @param {Array} userDocs - documents ของผู้ใช้
 * @param {number} maxRadiusKm - รัศมีสูงสุดในกิโลเมตร
 * @returns {Array} - ผู้ใช้ที่อยู่ในรัศมีที่กำหนด
 */
function filterUsersByDistanceWithCostSaving(reportLat, reportLng, userDocs, maxRadiusKm = 30) {
  const filteredUsers = [];
  const farUserThreshold = maxRadiusKm * 0.8; // 80% ของรัศมีสูงสุด
  
  for (const doc of userDocs) {
    const userData = doc.data();
    
    // ถ้าไม่มีข้อมูลตำแหน่ง ให้ส่งแจ้งเตือนไปด้วย (แต่จำกัดจำนวน)
    if (!userData.lastKnownLat || !userData.lastKnownLng) {
      // สุ่มส่งให้ผู้ใช้ที่ไม่มีตำแหน่ง (30% เท่านั้น)
      if (Math.random() < 0.3) {
        filteredUsers.push(doc);
      }
      continue;
    }
    
    const distance = calculateDistance(
      reportLat, reportLng,
      userData.lastKnownLat, userData.lastKnownLng
    );
    
    if (distance <= maxRadiusKm) {
      // ถ้าอยู่ในรัศมีที่อนุญาต
      if (distance <= farUserThreshold) {
        // ผู้ใช้ใกล้ - ส่งแจ้งเตือนทุกคน
        filteredUsers.push(doc);
      } else {
        // ผู้ใช้ไกล - ส่งแจ้งเตือนตามความน่าจะเป็นที่กำหนด
        if (Math.random() < NOTIFICATION_CONFIG.FAR_USER_PROBABILITY) {
          filteredUsers.push(doc);
        }
      }
    }
  }
  
  console.log(`🎯 Geographic filter: ${filteredUsers.length}/${userDocs.length} users selected`);
  return filteredUsers;
}

/**
 * 🔍 เลือก token ที่ดีที่สุดสำหรับผู้ใช้แต่ละคน
 * @param {Object} userData - ข้อมูลผู้ใช้
 * @returns {string|null} - token ที่ดีที่สุด หรือ null ถ้าไม่มี
 */
function selectBestTokenForUser(userData) {
  let allTokens = [];
  
  // รวบรวม tokens จากทุก field
  if (userData.token && typeof userData.token === 'string') {
    allTokens.push(userData.token);
  }
  
  if (userData.tokens && Array.isArray(userData.tokens)) {
    allTokens = allTokens.concat(userData.tokens);
  }
  
  if (userData.tokens && typeof userData.tokens === 'object' && !Array.isArray(userData.tokens)) {
    allTokens = allTokens.concat(Object.values(userData.tokens));
  }
  
  // เลือก token ที่ถูกต้องตัวแรก (ในอนาคตอาจเลือกตาม platform หรือ last active)
  for (const token of allTokens) {
    if (isValidToken(token)) {
      return token;
    }
  }
  
  return null;
}
/**
 * 📏 คำนวณระยะทางระหว่าง 2 จุด (Haversine formula)
 * @param {number} lat1 - ละติจูดจุดที่ 1
 * @param {number} lon1 - ลองจิจูดจุดที่ 1  
 * @param {number} lat2 - ละติจูดจุดที่ 2
 * @param {number} lon2 - ลองจิจูดจุดที่ 2
 * @returns {number} - ระยะทางในหน่วยกิโลเมตร
 */
function calculateDistance(lat1, lon1, lat2, lon2) {
  const R = 6371; // รัศมีโลกในหน่วยกิโลเมตร
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLon = (lon2 - lon1) * Math.PI / 180;
  const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
            Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
            Math.sin(dLon/2) * Math.sin(dLon/2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
  return R * c;
}

/**
 * 🎯 กรองผู้ใช้ตามระยะทาง
 * @param {number} reportLat - ละติจูดของรายงาน
 * @param {number} reportLng - ลองจิจูดของรายงาน
 * @param {Array} userDocs - documents ของผู้ใช้
 * @param {number} maxRadiusKm - รัศมีสูงสุดในกิโลเมตร
 * @returns {Array} - ผู้ใช้ที่อยู่ในรัศมีที่กำหนด
 */
function filterUsersByDistance(reportLat, reportLng, userDocs, maxRadiusKm = 50) {
  return userDocs.filter(doc => {
    const userData = doc.data();
    
    // ตรวจสอบว่ามีข้อมูลตำแหน่งหรือไม่
    if (!userData.lastKnownLat || !userData.lastKnownLng) {
      return true; // ถ้าไม่มีตำแหน่ง ให้ส่งแจ้งเตือนไปด้วย
    }
    
    const distance = calculateDistance(
      reportLat, reportLng,
      userData.lastKnownLat, userData.lastKnownLng
    );
    
    return distance <= maxRadiusKm;
  });
}

/**
 * �🗺️ สร้างข้อความตำแหน่งที่อ่านง่ายและครบถ้วน
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
exports.processRetryQueue = functions.pubsub
  .schedule('every 10 minutes')
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
            // 🚀 ใช้ Exponential Backoff แทนการกำหนดเวลาคงที่
            const exponentialDelay = Math.min(
              NOTIFICATION_CONFIG.EXPONENTIAL_BACKOFF_BASE * Math.pow(2, data.attemptCount), 
              300 // สูงสุด 5 นาที
            );
            
            console.log(`🔄 Using exponential backoff: ${exponentialDelay} minutes for attempt ${data.attemptCount + 1}`);
            
            // อัปเดต failed tokens
            const newFailedTokens = [];
            response.responses.forEach((resp, idx) => {
              if (!resp.success && !isInvalidTokenError(resp.error?.code)) {
                newFailedTokens.push(data.message.tokens[idx]);
              }
            });
            
            // ✅ ตรวจสอบว่ายังมี valid tokens หรือไม่
            if (newFailedTokens.length === 0) {
              console.log(`🧹 No valid tokens remaining, removing from queue`);
              await doc.ref.delete();
              return;
            }
            
            await doc.ref.update({
              attemptCount: data.attemptCount + 1,
              lastAttempt: admin.firestore.FieldValue.serverTimestamp(),
              nextAttempt: new Date(Date.now() + exponentialDelay * 60000),
              'message.tokens': newFailedTokens,
              lastError: `Failed attempt ${data.attemptCount + 1}: ${response.failureCount} failures`,
              exponentialDelay: exponentialDelay
            });
            
            console.log(`🔄 Retry attempt ${data.attemptCount + 1}/${data.maxAttempts} scheduled for ${exponentialDelay} minutes`);
            
          } else {
            // 💀 ครบจำนวนครั้งแล้ว - ส่งไป Dead Letter Queue
            console.log(`❌ Max retry attempts exceeded for ${data.type}`);
            
            // ส่งไป Dead Letter Queue ก่อนลบ
            await sendToDeadLetterQueue(data, 'MAX_RETRIES_EXCEEDED', null);
            
            // 📊 บันทึก telemetry สำหรับ max retries
            await updateTelemetry('max_retries_exceeded', {
              type: data.type,
              attemptCount: data.attemptCount,
              maxAttempts: data.maxAttempts,
              remainingTokens: data.message.tokens.length,
              reportId: data.reportId
            });
            
            // ลบออกจาก retry queue
            await doc.ref.delete();
            console.log(`💀 Moved to dead letter queue and removed from retry queue`);
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
 * 🗑️ **ลบ Invalid Tokens จาก Firestore แบบ Batch** (ปรับปรุงประสิทธิภาพ + รองรับ Map structure)
 */
async function removeInvalidTokens(invalidTokens) {
  try {
    console.log(`🗑️ Removing ${invalidTokens.length} invalid tokens from database`);
    
    // 🚀 ใช้ batch operations เพื่อลด write operations
    const batches = [];
    let currentBatch = admin.firestore().batch();
    let operationCount = 0;
    const BATCH_LIMIT = 450; // เผื่อไว้จาก Firestore limit 500

    for (const token of invalidTokens) {
      // ค้นหา documents ที่มี token นี้ (รองรับทั้ง Array และ Map structure)
      const arrayTokenQuery = admin.firestore()
        .collection('user_tokens')
        .where('tokens', 'array-contains', token)
        .limit(1)
        .get();

      const mapTokenQuery = admin.firestore()
        .collection('user_tokens')
        .limit(50) // จำกัดเพื่อประสิทธิภาพ
        .get();

      const [arrayResults, mapResults] = await Promise.all([arrayTokenQuery, mapTokenQuery]);

      // จัดการ Array structure
      arrayResults.docs.forEach(doc => {
        const tokenData = doc.data();
        const updatedTokens = tokenData.tokens.filter(t => t !== token);
        
        currentBatch.update(doc.ref, {
          tokens: updatedTokens,
          lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
          invalidTokensRemoved: admin.firestore.FieldValue.increment(1)
        });
        operationCount++;
      });

      // จัดการ Map structure
      mapResults.docs.forEach(doc => {
        const tokenData = doc.data();
        
        if (tokenData.tokens && typeof tokenData.tokens === 'object' && !Array.isArray(tokenData.tokens)) {
          // หา device ID ที่มี invalid token
          const deviceToRemove = Object.keys(tokenData.tokens).find(
            deviceId => tokenData.tokens[deviceId] === token
          );
          
          if (deviceToRemove) {
            const updatedTokens = { ...tokenData.tokens };
            delete updatedTokens[deviceToRemove];
            
            currentBatch.update(doc.ref, {
              tokens: updatedTokens,
              lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
              invalidTokensRemoved: admin.firestore.FieldValue.increment(1),
              removedDeviceId: deviceToRemove
            });
            operationCount++;
            
            console.log(`   🗑️ Removed token from device: ${deviceToRemove}`);
          }
        }
      });

      // สร้าง batch ใหม่เมื่อใกล้ถึง limit
      if (operationCount >= BATCH_LIMIT) {
        batches.push(currentBatch);
        currentBatch = admin.firestore().batch();
        operationCount = 0;
      }
    }

    // เพิ่ม batch สุดท้าย
    if (operationCount > 0) {
      batches.push(currentBatch);
    }

    // Execute ทุก batches
    const promises = batches.map((batch, index) => {
      console.log(`   🚀 Executing batch ${index + 1}/${batches.length}`);
      return batch.commit();
    });

    await Promise.all(promises);
    console.log(`✅ Removed ${invalidTokens.length} invalid tokens using ${batches.length} batches`);

  } catch (error) {
    console.error('❌ Error removing invalid tokens:', error);
    throw error;
  }
}

/**
 * 📊 **ตรวจสอบสถานะ System Health & Circuit Breaker**
 */
exports.getSystemHealth = functions.https.onRequest(async (req, res) => {
  try {
    const db = admin.firestore();
    
    // ตรวจสอบสถานะ Retry Queue
    const totalRetryItems = await db.collection(RETRY_QUEUE).get();
    
    // ตรวจสอบสถานะ Cache
    const cacheStats = {
      totalItems: cache.size,
      items: Array.from(cache.keys()).map(key => ({
        key: key,
        age: Math.round((Date.now() - cache.get(key).timestamp) / 1000),
        ttl: NOTIFICATION_CONFIG.CACHE_TTL
      }))
    };
    
    // คำนวณ Error Rate
    const totalOperations = circuitBreaker.successCount + circuitBreaker.failureCount;
    const errorRate = totalOperations > 0 ? (circuitBreaker.failureCount / totalOperations) : 0;
    
    // สุขภาพของระบบ
    const systemHealth = {
      status: circuitBreaker.isOpen ? 'degraded' : 'healthy',
      circuitBreaker: {
        isOpen: circuitBreaker.isOpen,
        successCount: circuitBreaker.successCount,
        failureCount: circuitBreaker.failureCount,
        errorRate: `${(errorRate * 100).toFixed(2)}%`,
        threshold: `${(NOTIFICATION_CONFIG.ERROR_THRESHOLD * 100).toFixed(0)}%`,
        lastFailureTime: circuitBreaker.lastFailureTime 
          ? new Date(circuitBreaker.lastFailureTime).toISOString() 
          : null
      },
      cache: cacheStats,
      retryQueue: {
        totalItems: totalRetryItems.size,
        status: totalRetryItems.size < 100 ? 'healthy' : totalRetryItems.size < 500 ? 'warning' : 'critical'
      },
      configuration: {
        batchSize: NOTIFICATION_CONFIG.BATCH_SIZE,
        maxRadius: NOTIFICATION_CONFIG.MAX_RADIUS_KM,
        geographicFilter: NOTIFICATION_CONFIG.ENABLE_GEOGRAPHIC_FILTER,
        maxRetries: NOTIFICATION_CONFIG.MAX_RETRIES,
        cacheTtl: NOTIFICATION_CONFIG.CACHE_TTL
      },
      lastUpdated: new Date().toISOString()
    };

    res.json({
      success: true,
      data: systemHealth
    });

  } catch (error) {
    console.error('❌ Error getting system health:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

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

// 🧹 **Scheduled Cache Cleanup Function**
exports.cleanCache = functions.pubsub
  .schedule('every 10 minutes')
  .timeZone('Asia/Bangkok')
  .onRun(async (context) => {
    try {
      const initialSize = cache.size;
      console.log(`🧹 Starting cache cleanup - Current size: ${initialSize}`);
      
      const now = Date.now();
      let cleanedCount = 0;

      // ลบ entries ที่หมดอายุ
      for (const [key, value] of cache.entries()) {
        if (now - value.timestamp > NOTIFICATION_CONFIG.CACHE_TTL * 1000) {
          cache.delete(key);
          cleanedCount++;
        }
      }

      console.log(`✅ Cache cleanup completed - Removed: ${cleanedCount}, Remaining: ${cache.size}`);
      
      // 📊 บันทึก telemetry
      await updateTelemetry('cache_cleanup', {
        initialSize: initialSize,
        cleanedCount: cleanedCount,
        finalSize: cache.size,
        cleanupRatio: initialSize > 0 ? (cleanedCount / initialSize) : 0
      });

      return { cleanedCount, remainingSize: cache.size };
    } catch (error) {
      console.error('❌ Error in cache cleanup:', error);
      return { error: error.message };
    }
  });

// 💀 **Scheduled Dead Letter Queue Cleanup**
exports.cleanDeadLetters = functions.pubsub
  .schedule('every 24 hours')
  .timeZone('Asia/Bangkok')
  .onRun(async (context) => {
    try {
      console.log('💀 Starting dead letter queue cleanup...');
      
      const expiredDate = new Date(Date.now() - (NOTIFICATION_CONFIG.DEAD_LETTER_RETENTION_DAYS * 24 * 60 * 60 * 1000));
      
      const snapshot = await admin.firestore()
        .collection('dead_letters')
        .where('ttl', '<', expiredDate)
        .get();

      console.log(`💀 Found ${snapshot.size} expired dead letters`);

      if (snapshot.empty) {
        console.log('✅ No expired dead letters to clean');
        return { cleanedCount: 0 };
      }

      let cleanedCount = 0;
      const batch = admin.firestore().batch();

      snapshot.docs.forEach(doc => {
        batch.delete(doc.ref);
        cleanedCount++;
      });

      await batch.commit();

      console.log(`✅ Cleaned ${cleanedCount} expired dead letters`);
      
      // 📊 บันทึก telemetry
      await updateTelemetry('dead_letters_cleanup', {
        cleanedCount: cleanedCount,
        retentionDays: NOTIFICATION_CONFIG.DEAD_LETTER_RETENTION_DAYS
      });

      return { cleanedCount };
    } catch (error) {
      console.error('❌ Error in dead letter cleanup:', error);
      return { error: error.message };
    }
  });

// 📊 **Enhanced System Health Function**
exports.getEnhancedSystemHealth = functions.https.onRequest(async (req, res) => {
  try {
    // ข้อมูลพื้นฐาน - ใช้ข้อมูลเดียวกับ getSystemHealth แต่ไม่เรียก function โดยตรง
    const now = Date.now();
    const cacheInfo = {
      size: cache.size,
      entries: Array.from(cache.entries()).map(([key, value]) => ({
        key,
        age: Math.round((now - value.timestamp) / 1000),
        expired: (now - value.timestamp) > NOTIFICATION_CONFIG.CACHE_TTL * 1000
      }))
    };

    // Circuit breaker info
    const circuitBreakerInfo = {
      isOpen: circuitBreaker.isOpen,
      failureCount: circuitBreaker.failureCount,
      successCount: circuitBreaker.successCount,
      consecutiveSuccesses: circuitBreaker.consecutiveSuccesses,
      lastFailureTime: circuitBreaker.lastFailureTime,
      resetTimeout: circuitBreaker.resetTimeout
    };

    // ข้อมูล Dead Letter Queue
    const deadLetterSnapshot = await admin.firestore()
      .collection('dead_letters')
      .get();
    
    // ข้อมูลโควต้าการส่งแจ้งเตือนวันนี้
    const today = new Date().toISOString().split('T')[0];
    const counterDoc = await admin.firestore()
      .collection('notification_counters')
      .doc(today)
      .get();
    
    const currentQuota = counterDoc.exists ? (counterDoc.data().count || 0) : 0;
    const quotaInfo = {
      current: currentQuota,
      max: NOTIFICATION_CONFIG.MAX_DAILY_NOTIFICATIONS,
      remaining: Math.max(0, NOTIFICATION_CONFIG.MAX_DAILY_NOTIFICATIONS - currentQuota),
      usagePercentage: (currentQuota / NOTIFICATION_CONFIG.MAX_DAILY_NOTIFICATIONS * 100).toFixed(1) + '%',
      status: currentQuota < NOTIFICATION_CONFIG.MAX_DAILY_NOTIFICATIONS * 0.8 ? 'healthy' : 
              currentQuota < NOTIFICATION_CONFIG.MAX_DAILY_NOTIFICATIONS * 0.95 ? 'warning' : 'critical'
    };
    
    // ข้อมูล Telemetry ล่าสุด
    const telemetrySnapshot = await admin.firestore()
      .collection('telemetry')
      .orderBy('timestamp', 'desc')
      .limit(10)
      .get();

    const telemetryData = telemetrySnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      timestamp: doc.data().timestamp?.toDate?.()?.toISOString()
    }));

    // ข้อมูลการตั้งค่าโหมดบำรุงรักษา
    const maintenanceDoc = await admin.firestore()
      .collection('system_config')
      .doc('maintenance')
      .get();
    
    const maintenanceInfo = maintenanceDoc.exists ? maintenanceDoc.data() : { enabled: false };

    res.json({
      success: true,
      data: {
        cache: cacheInfo,
        circuitBreaker: circuitBreakerInfo,
        quota: quotaInfo,
        maintenance: {
          enabled: maintenanceInfo.enabled || NOTIFICATION_CONFIG.MAINTENANCE_MODE,
          reason: maintenanceInfo.reason || null,
          updatedAt: maintenanceInfo.updatedAt?.toDate?.()?.toISOString(),
          updatedBy: maintenanceInfo.updatedBy || null
        },
        costOptimization: {
          maxRadius: NOTIFICATION_CONFIG.MAX_RADIUS_KM,
          batchSize: NOTIFICATION_CONFIG.BATCH_SIZE,
          geographicFilterEnabled: NOTIFICATION_CONFIG.ENABLE_GEOGRAPHIC_FILTER,
          oneTokenPerUser: NOTIFICATION_CONFIG.ONE_TOKEN_PER_USER,
          farUserProbability: NOTIFICATION_CONFIG.FAR_USER_PROBABILITY,
          maxDailyNotifications: NOTIFICATION_CONFIG.MAX_DAILY_NOTIFICATIONS
        },
        config: {
          threshold: `${(NOTIFICATION_CONFIG.ERROR_THRESHOLD * 100).toFixed(0)}%`,
          successThreshold: NOTIFICATION_CONFIG.SUCCESS_THRESHOLD,
          reducedResetTimeout: NOTIFICATION_CONFIG.REDUCED_RESET_TIMEOUT / 1000 / 60 + ' minutes',
          batchDelay: NOTIFICATION_CONFIG.BATCH_DELAY_MS + 'ms'
        },
        deadLetterQueue: {
          totalItems: deadLetterSnapshot.size,
          retentionDays: NOTIFICATION_CONFIG.DEAD_LETTER_RETENTION_DAYS
        },
        recentTelemetry: telemetryData,
        enhancedFeatures: {
          tokenValidation: true,
          deadLetterQueue: true,
          telemetryTracking: true,
          enhancedCircuitBreaker: true,
          scheduledCleanup: true,
          costOptimization: true,
          geographicFiltering: true,
          quotaManagement: true,
          maintenanceMode: true,
          topicSubscriptions: true
        },
        systemInfo: {
          timestamp: new Date().toISOString(),
          uptime: process.uptime(),
          nodeVersion: process.version,
          region: process.env.FUNCTION_REGION || 'unknown'
        }
      }
    });

  } catch (error) {
    console.error('❌ Error getting enhanced system health:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
  });