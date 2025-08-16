# 💰 คู่มือการลดค่าใช้จ่ายระบบแจ้งเตือน

## 📊 สรุปการปรับปรุงระบบ

### ก่อนการปรับปรุง
- ส่งแจ้งเตือนให้ผู้ใช้ทั้งหมด (ไม่จำกัด)
- ไม่มีการกรองตามพื้นที่
- ส่งทุก token ของผู้ใช้แต่ละคน (อาจมีหลายอุปกรณ์)
- ไม่มีระบบควบคุมโควต้า

### หลังการปรับปรุง ✨
- ระบบโควต้ารายวัน: **5,000 แจ้งเตือน/วัน** (ลดจาก 50,000)
- การกรองตามพื้นที่: **รัศมี 30 กม.** และส่งแค่ 50% ให้ผู้ใช้ไกล
- **1 token ต่อผู้ใช้** เท่านั้น
- โหมดบำรุงรักษาสำหรับหยุดส่งชั่วคราว
- ระบบ Topic subscriptions เพื่อประหยัดค่าใช้จ่าย

## 🎯 ฟีเจอร์ประหยัดค่าใช้จ่าย

### 1. ระบบโควต้ารายวัน
```javascript
// ตรวจสอบโควต้าก่อนส่งแจ้งเตือน
const quotaCheck = await checkAndUpdateDailyQuota(tokens.length);
if (!quotaCheck.allowed) {
  // หยุดส่งเมื่อเกินโควต้า
  return { success: false, reason: 'daily_quota_exceeded' };
}
```

**ประโยชน์**: ควบคุมค่าใช้จ่ายไม่ให้เกิน 5,000 แจ้งเตือนต่อวัน

### 2. การกรองตามพื้นที่อัจฉริยะ
```javascript
// กรองผู้ใช้ตามระยะทาง
if (ENABLE_GEOGRAPHIC_FILTER) {
  filteredUsers = filterUsersByDistanceWithCostSaving(
    reportData.lat, reportData.lng, filteredUsers, 30 // 30 กม.
  );
}
```

**ประโยชน์**: 
- ผู้ใช้ใกล้ (< 24 กม.): ส่งให้ทุกคน 100%
- ผู้ใช้ไกล (24-30 กม.): ส่งให้แค่ 50%
- ผู้ใช้ไม่มีตำแหน่ง: ส่งให้แค่ 30%

### 3. ส่งเพียง 1 token ต่อผู้ใช้
```javascript
if (ONE_TOKEN_PER_USER) {
  const bestToken = selectBestTokenForUser(userData);
  if (bestToken) tokens.push(bestToken);
}
```

**ประโยชน์**: ลดการส่งซ้ำซ้อนสำหรับผู้ใช้ที่มีหลายอุปกรณ์

### 4. ระบบ Topic Subscriptions
```javascript
// ให้ผู้ใช้เลือกรับแจ้งเตือนเฉพาะหมวดที่สนใจ
await admin.messaging().subscribeToTopic(token, `category_${category}`);

// ส่งแจ้งเตือนผ่าน topic (ประหยัดกว่า)
const message = {
  topic: `category_accident`,
  notification: { ... }
};
```

**ประโยชน์**: ผู้ใช้รับเฉพาะแจ้งเตือนที่สนใจ + ลดค่าใช้จ่าย Firebase

## 🛠️ การใช้งานฟีเจอร์ใหม่

### 1. ตรวจสอบสถานะโควต้า
```bash
curl https://us-central1-your-project.cloudfunctions.net/getNotificationQuotaStatus
```

### 2. เปิด/ปิดโหมดบำรุงรักษา
```javascript
// จากฝั่ง Flutter/Client
await functions.httpsCallable('setMaintenanceMode')({
  'enabled': true,
  'reason': 'System maintenance'
});
```

### 3. จัดการ Topic Subscriptions
```javascript
// สมัครสมาชิก topics
await functions.httpsCallable('manageTopicSubscriptions')({
  'token': fcmToken,
  'categories': ['accident', 'fire'],
  'action': 'subscribe'
});
```

### 4. ส่งแจ้งเตือนผ่าน Topic
```javascript
await functions.httpsCallable('sendNotificationByTopic')({
  'reportId': reportId,
  'category': 'accident',
  'customTitle': 'อุบัติเหตุร้ายแรง!',
  'customBody': 'กรุณาหลีกเลี่ยงเส้นทางนี้'
});
```

## 📊 การติดตามประสิทธิภาพ

### 1. Enhanced System Health
```bash
curl https://us-central1-your-project.cloudfunctions.net/getEnhancedSystemHealth
```

ได้ข้อมูล:
- สถานะโควต้าการส่งวันนี้
- การตั้งค่าประหยัดค่าใช้จ่าย
- สถานะโหมดบำรุงรักษา
- ประสิทธิภาพระบบ

### 2. ตัวอย่างผลลัพธ์ที่คาดหวัง
```json
{
  "data": {
    "quota": {
      "current": 127,
      "max": 5000,
      "remaining": 4873,
      "usagePercentage": "2.5%",
      "status": "healthy"
    },
    "costOptimization": {
      "geographicFilterEnabled": true,
      "oneTokenPerUser": true,
      "farUserProbability": 0.5,
      "maxDailyNotifications": 5000
    }
  }
}
```

## 💡 การประมาณการประหยัด

### สถานการณ์จริง (สมมติ)
- ผู้ใช้ทั้งหมด: 10,000 คน
- โพสต์ใหม่วันละ: 100 โพสต์
- ผู้ใช้เฉลี่ยมี 2 อุปกรณ์

### ก่อนปรับปรุง
```
100 โพสต์ × 10,000 ผู้ใช้ × 2 token = 2,000,000 แจ้งเตือน/วัน
```

### หลังปรับปรุง
```
100 โพสต์ × 3,000 ผู้ใช้ใกล้ × 1 token = 300,000 แจ้งเตือน/วัน
100 โพสต์ × 1,500 ผู้ใช้ไกล × 1 token = 150,000 แจ้งเตือน/วัน

รวม: 450,000 แจ้งเตือน/วัน (ลดได้ 77.5%)
```

**แต่เราจำกัดไว้ที่ 5,000/วัน = ลดได้ 99.75%! 🎉**

## ⚠️ ข้อควรระวัง

### 1. การตั้งค่าโควต้า
- ตั้งค่า `MAX_DAILY_NOTIFICATIONS` ให้เหมาะสมกับงบประมาณ
- ติดตามการใช้งานผ่าน `getNotificationQuotaStatus`

### 2. การกรองพื้นที่
- ตรวจสอบว่าผู้ใช้มีข้อมูลตำแหน่งที่ถูกต้อง
- ปรับ `MAX_RADIUS_KM` ตามขนาดพื้นที่บริการ

### 3. Topic Subscriptions
- ให้ผู้ใช้เลือกสมัครสมาชิก topic ตามความสนใจ
- ใช้สำหรับแจ้งเตือนทั่วไปแทนการส่งตรงไปยัง token

## 🚀 แผนการต่อไป

1. **ระบบ AI Filtering**: ใช้ AI คัดกรองแจ้งเตือนที่สำคัญ
2. **Time-based Filtering**: ส่งแจ้งเตือนตามเวลาที่เหมาะสม
3. **User Behavior Analysis**: วิเคราะห์พฤติกรรมเพื่อส่งแจ้งเตือนที่ relevant
4. **Batch Optimization**: ปรับปรุง batch size ตาม network conditions

---

**🎯 เป้าหมาย**: ลดค่าใช้จ่าย Firebase Cloud Messaging ลง **95%+** โดยยังคงประสิทธิภาพการแจ้งเตือนไว้ได้
