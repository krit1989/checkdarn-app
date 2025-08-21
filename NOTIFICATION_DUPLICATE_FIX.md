# 🚨 แก้ไขปัญหาแจ้งเตือนซ้ำ (Duplicate Notifications)

## 🔍 **สาเหตุของปัญหา:**

### การส่งแจ้งเตือนซ้ำเกิดจาก **Hybrid Strategy** ในไฟล์ `functions/index.js`:

1. **Topics Notification** (ครั้งที่ 1) - บรรทัด 1026
   ```javascript
   topicResults = await sendTopicNotifications(topicSelection.topics, notificationData, reportId);
   ```

2. **Individual Tokens Notification** (ครั้งที่ 2) - บรรทัด 1078+
   ```javascript
   return await sendNotificationsInBatches(tokens, reportData, reportId, {...});
   ```

### ผลลัพธ์: **ผู้ใช้คนเดียวกันได้รับแจ้งเตือน 2 ครั้ง**
- ครั้งที่ 1: จาก FCM Topic subscription 📡
- ครั้งที่ 2: จาก Individual token 📱

---

## 🛠️ **วิธีแก้ไข:**

### เปลี่ยนจาก Hybrid Strategy เป็น Either/Or Strategy

#### แก้ไขในไฟล์ `functions/index.js` บรรทัด 1012-1025:

**เดิม:**
```javascript
// 📡 ส่งแจ้งเตือนผ่าน Topics ก่อน (ถ้าเปิดใช้งาน)
let topicResults = [];
if (topicSelection.useTopics && topicSelection.topics.length > 0) {
  console.log('📡 Sending topic notifications...');
  
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
```

**ใหม่:**
```javascript
// 🚫 แก้ไข: ส่งแจ้งเตือนแบบใดแบบหนึ่ง (หลีกเลี่ยงการส่งซ้ำ)
let topicResults = [];

// ถ้าใช้ Topics Strategy ให้ส่งเฉพาะ Topics เท่านั้น
if (topicSelection.useTopics && topicSelection.topics.length > 0) {
  console.log('📡 Using Topics-only strategy to avoid duplicate notifications');
  
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
  
  // 🚫 หยุดการส่ง individual tokens เพื่อหลีกเลี่ยงการซ้ำ
  console.log('✅ Topics sent successfully, skipping individual tokens to prevent duplicates');
  return { 
    success: true, 
    sentCount: topicSelection.topicUserCount || 0, 
    reason: 'topics_only_no_duplicates',
    topicResults: topicResults,
    hybridStrategy: {
      topicNotifications: topicSelection.topics.length,
      individualNotifications: 0,
      estimatedTopicRecipients: topicSelection.topicUserCount || 0,
      duplicatesAvoided: true
    },
    debug: {
      totalUsers: usersSnapshot.size,
      filteredUsers: filteredUsers.length,
      validUserCount: validUserCount,
      invalidUserCount: invalidUserCount,
      message: 'Individual tokens skipped to prevent duplicate notifications'
    }
  };
}
```

---

## 🔧 **ทางเลือกอื่น:**

### วิธีที่ 2: ปิดการใช้งาน Topics ชั่วคราว

แก้ไขในไฟล์ `functions/index.js` บรรทัด 357:

```javascript
// เดิม
ENABLE_TOPICS: true,      // เปิดใช้งาน FCM Topics เพื่อประหยัดค่าใช้จ่าย

// ใหม่
ENABLE_TOPICS: false,     // ปิดใช้งาน FCM Topics ชั่วคราวเพื่อหลีกเลี่ยงการซ้ำ
```

### วิธีที่ 3: ปรับ Topic Threshold

แก้ไขในไฟล์ `functions/index.js` บรรทัด 374:

```javascript
// เดิม
const topicThreshold = 50; // ถ้ามีผู้ใช้มากกว่า 50 คน ให้ใช้ Topics

// ใหม่ (เพิ่มค่าให้สูงขึ้น)
const topicThreshold = 1000; // ถ้ามีผู้ใช้มากกว่า 1000 คน ให้ใช้ Topics
```

---

## 🧪 **วิธีทดสอบ:**

1. **Deploy การแก้ไข:**
   ```bash
   firebase deploy --only functions
   ```

2. **สร้างโพสต์ทดสอบ** และดูว่าได้รับแจ้งเตือนกี่ครั้ง

3. **ตรวจสอบ Firebase Functions Logs:**
   ```bash
   firebase functions:log
   ```

4. **หาข้อความ log:**
   - `✅ Topics sent successfully, skipping individual tokens to prevent duplicates`
   - `duplicatesAvoided: true`

---

## 📊 **ผลที่คาดหวัง:**

- ✅ ผู้ใช้ได้รับแจ้งเตือนเพียง **1 ครั้งต่อโพสต์**
- ✅ ลดค่าใช้จ่าย FCM 
- ✅ ประสบการณ์ผู้ใช้ดีขึ้น
- ✅ Log แสดงข้อความ "duplicates avoided"

---

## 🔍 **สำหรับ Debug เพิ่มเติม:**

### ตรวจสอบ Topic Subscriptions:
```javascript
// ใน Firebase Console > Cloud Messaging
// ดูจำนวน subscribers ของแต่ละ topic
```

### ตรวจสอบว่าผู้ใช้ subscribe topics ใดบ้าง:
```bash
# ใน Firebase Functions Log หา:
📡 Selected topics: general_alerts, region_bangkok
```

**หมายเหตุ:** การแก้ไขนี้จะลดจำนวนแจ้งเตือนลงครึ่งหนึ่ง และแก้ปัญหาการได้รับซ้ำ! 🎯
