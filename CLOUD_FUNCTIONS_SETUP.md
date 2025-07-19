# 🧹 Cloud Functions Setup Guide
## ระบบลบข้อมูลแบบครบถ้วน (Complete Cleanup System)

### 📋 ภาพรวม

Cloud Functions ที่สร้างขึ้นจะทำงาน 3 หน้าที่หลัก:
1. **🕐 Scheduled Cleanup**: ลบข้อมูลเก่าอัตโนมัติทุก 24 ชั่วโมง
2. **🛠️ Manual Cleanup**: เรียกลบข้อมูลด้วยตนเอง (สำหรับทดสอบ)
3. **📊 Status Check**: ตรวจสอบสถานะและจำนวนข้อมูล

---

## 🚀 การติดตั้ง

### 1. เตรียม Firebase CLI
```bash
# ติดตั้ง Firebase CLI (ถ้ายังไม่มี)
npm install -g firebase-tools

# Login เข้า Firebase
firebase login

# ตรวจสอบ project
firebase projects:list
```

### 2. Setup Functions
```bash
# ไปที่โฟลเดอร์ functions
cd /Users/kritchaponprommali/CheckDarn/functions

# ติดตั้ง dependencies
npm install

# ตรวจสอบไฟล์
ls -la
# ต้องมี: index.js, package.json
```

### 3. Deploy Functions
```bash
# Deploy ครั้งแรก
firebase deploy --only functions

# หรือ deploy เฉพาะ function ที่ต้องการ
firebase deploy --only functions:cleanupOldReports
firebase deploy --only functions:manualCleanup
firebase deploy --only functions:getCleanupStatus
```

---

## 🔧 การใช้งาน

### 📅 Scheduled Cleanup (อัตโนมัติ)

ระบบจะทำงานทุก 24 ชั่วโมงโดยอัตโนมัติ:

```javascript
// ตั้งเวลาให้ทำงานทุกวันเวลา 00:00 (timezone: Asia/Bangkok)
.schedule('every 24 hours')
.timeZone('Asia/Bangkok')
```

**สิ่งที่จะถูกลบ:**
- โพสต์ที่เก่ากว่า 7 วัน
- Comments ทั้งหมดของโพสต์นั้น
- ไฟล์รูปภาพใน Firebase Storage
- Subcollections อื่นๆ (likes, shares)

### 🛠️ Manual Cleanup

เรียกใช้งานด้วยตนเอง:

```bash
# ผ่าน HTTP Request
curl "https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/manualCleanup?adminKey=your-secret-admin-key-here"

# ผ่าน Firebase Emulator (สำหรับทดสอบ)
firebase functions:shell
> manualCleanup()
```

### 📊 Status Check

ตรวจสอบสถานะปัจจุบัน:

```bash
curl "https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/getCleanupStatus"
```

**Response ตัวอย่าง:**
```json
{
  "success": true,
  "data": {
    "totalPosts": 150,
    "oldPosts": 12,
    "totalComments": 89,
    "cutoffDate": "2025-07-10T17:00:00.000Z",
    "lastUpdated": "2025-07-17T17:00:00.000Z"
  }
}
```

---

## 🔍 การตรวจสอบ Logs

### ดู Logs ใน Firebase Console
1. ไปที่ [Firebase Console](https://console.firebase.google.com)
2. เลือก Project
3. ไปที่ **Functions** → **Logs**

### ดู Logs ผ่าน CLI
```bash
# ดู logs ทั้งหมด
firebase functions:log

# ดู logs เฉพาะ function
firebase functions:log --only cleanupOldReports

# ดู logs แบบ real-time
firebase functions:log --follow
```

**ตัวอย่าง Log Messages:**
```
🧹 เริ่มทำความสะอาดข้อมูลที่เก่ากว่า: 2025-07-10T17:00:00.000Z
📊 พบโพสต์เก่า 12 รายการ
🗑️ กำลังลบโพสต์: ABC123
📁 กำลังลบ 5 รายการจาก reports/ABC123/comments
🖼️ ลบรูปภาพสำเร็จ: images/ABC123.jpg
✅ ลบโพสต์ ABC123 สำเร็จ
🎉 ทำความสะอาดเสร็จสิ้น: ✅ ลบสำเร็จ: 12 รายการ ❌ ลบไม่สำเร็จ: 0 รายการ
```

---

## 🛡️ Security & Best Practices

### 1. Admin Key Protection
```javascript
// เปลี่ยน admin key ในไฟล์ index.js
const adminKey = req.query.adminKey;
if (adminKey !== 'your-secret-admin-key-here') {
  return res.status(403).json({ error: 'Unauthorized' });
}
```

**แนะนำ:** ใช้ Environment Variables
```bash
# ตั้งค่า environment variable
firebase functions:config:set admin.key="your-super-secret-key"

# ใน code
const adminKey = functions.config().admin.key;
```

### 2. Error Handling
- ระบบจะไม่หยุดทำงานแม้ลบไฟล์บางไฟล์ไม่สำเร็จ
- Log ทุก error เพื่อ debugging
- Retry mechanism สำหรับ network errors

### 3. Performance Optimization
- ลบแบบ batch (500 รายการต่อครั้ง)
- ใช้ Cloud Scheduler แทน cron job
- Timezone ตั้งเป็น Asia/Bangkok

---

## 📊 Cost Estimation

### Cloud Functions
```
Invocations: 1 ต่อวัน × 30 วัน = 30 invocations/เดือน
Duration: ~2 นาทีต่อครั้ง = 60 นาที/เดือน
Cost: ฟรี (อยู่ในขีดจำกัด Free Tier)
```

### Firestore Operations
```
สมมติลบ 100 โพสต์/เดือน:
- Delete operations: 100 posts + 500 comments = 600 operations
- Cost: ฟรี (อยู่ในขีดจำกัด 20k operations/วัน)
```

### Cloud Storage
```
ลบไฟล์ 100 ไฟล์/เดือน = 100 delete operations
Cost: ฟรี (Storage operations มีขีดจำกัดสูง)
```

**สรุป: ค่าใช้จ่าย ≈ 0 บาท/เดือน** (ในขีดจำกัดฟรี)

---

## 🧪 การทดสอบ

### 1. ทดสอบบน Local Emulator
```bash
# เริ่ม emulator
firebase emulators:start --only functions,firestore

# ทดสอบ function
curl "http://localhost:5001/YOUR_PROJECT/YOUR_REGION/manualCleanup?adminKey=test-key"
```

### 2. ทดสอบบน Production
```bash
# สร้างข้อมูลทดสอบ (โพสต์เก่า)
# หรือปรับเวลาใน function จาก 7 วันเป็น 1 ชั่วโมง

# เรียก manual cleanup
curl "https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/manualCleanup?adminKey=your-key"

# ตรวจสอบผลลัพธ์
curl "https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/getCleanupStatus"
```

---

## 🔄 การปรับแต่ง

### เปลี่ยนช่วงเวลาลบข้อมูล
```javascript
// จาก 7 วันเป็น 3 วัน
const threeDaysAgo = new Date(Date.now() - 3 * 24 * 60 * 60 * 1000);

// จาก 24 ชั่วโมงเป็น 12 ชั่วโมง
.schedule('every 12 hours')
```

### เพิ่ม Subcollections อื่น
```javascript
// เพิ่มในฟังก์ชัน cleanup
await deleteSubcollection(db, `reports/${postId}/reactions`);
await deleteSubcollection(db, `reports/${postId}/views`);
```

### Notification เมื่อทำงานเสร็จ
```javascript
// ใช้ Firebase Cloud Messaging
const messaging = admin.messaging();
await messaging.send({
  topic: 'admin',
  notification: {
    title: 'Cleanup Complete',
    body: `Deleted ${deletedCount} old posts`
  }
});
```

---

## 🆘 Troubleshooting

### Function ไม่ทำงาน
```bash
# ตรวจสอบ logs
firebase functions:log --only cleanupOldReports

# ตรวจสอบ permissions
firebase projects:get-iam-policy

# Re-deploy
firebase deploy --only functions:cleanupOldReports
```

### ลบข้อมูลไม่สำเร็จ
1. ตรวจสอบ Firestore Security Rules
2. ตรวจสอบ Storage Bucket permissions
3. ดู error logs ใน Console

### Performance ช้า
1. เพิ่ม timeout:
```javascript
.runWith({ timeoutSeconds: 540 }) // 9 นาที
```

2. เพิ่ม memory:
```javascript
.runWith({ memory: '1GB' })
```

---

## 📚 เอกสารเพิ่มเติม

- [Firebase Functions Documentation](https://firebase.google.com/docs/functions)
- [Cloud Scheduler Documentation](https://cloud.google.com/scheduler/docs)
- [Firestore Batch Operations](https://firebase.google.com/docs/firestore/manage-data/transactions)

---

## ✅ Checklist การ Deploy

- [ ] ติดตั้ง Firebase CLI
- [ ] สร้างไฟล์ functions/index.js
- [ ] สร้างไฟล์ functions/package.json
- [ ] เปลี่ยน admin key
- [ ] Deploy functions
- [ ] ทดสอบ manual cleanup
- [ ] ตรวจสอบ logs
- [ ] ทดสอบ scheduled function (รอ 24 ชั่วโมง หรือปรับเวลาสำหรับทดสอบ)

**🎉 พร้อมใช้งาน!**
