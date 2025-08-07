# 🔄 **ระบบ Retry สำหรับ FCM Token หมดอายุ**

## 📋 **สรุประบบ**

เราได้สร้างระบบ Retry ที่ครอบคลุมทั้ง **Frontend (Flutter)** และ **Backend (Cloud Functions)** เพื่อจัดการกับปัญหา FCM Token หมดอายุและการส่ง notification ล้มเหลว

---

## 🎯 **ฟีเจอร์หลักที่เพิ่มเข้ามา**

### **Frontend (Flutter)**

1. **🔄 Token Refresh System**
   - ตรวจสอบ Token อัตโนมัติเมื่อ app เริ่มต้น
   - พยายาม refresh สูงสุด 3 ครั้ง
   - ช่วงเวลา retry: 1, 5, 15 นาที

2. **📥 Retry Queue System**
   - เก็บข้อความที่ส่งไม่สำเร็จไว้ใน queue
   - ประมวลผลอัตโนมัติเมื่อ token ใหม่มาถึง
   - จัดการข้อผิดพลาดแบบ graceful

3. **⚡ Smart Error Handling**
   - จับ error เมื่อแสดง notification ไม่สำเร็จ
   - เพิ่มเข้า retry queue อัตโนมัติ
   - รายงานสถานะระบบแบบ real-time

4. **🔧 Debug Tools**
   - บังคับ refresh token
   - ประมวลผล retry queue ด้วยตนเอง
   - ตรวจสอบสถานะระบบ
   - ล้าง retry queue

### **Backend (Cloud Functions)**

1. **📤 Advanced Notification Sending**
   - ตรวจสอบ FCM response codes
   - แยกแยะ Invalid vs Retryable errors
   - ลบ invalid tokens อัตโนมัติ

2. **🔄 Exponential Backoff Retry**
   - Retry ทุก 5 นาทีสำหรับข้อความที่ล้มเหลว
   - สูงสุด 3 ครั้งต่อข้อความ
   - ลบออกจาก queue เมื่อสำเร็จหรือครบจำนวน

3. **🧹 Automatic Cleanup**
   - ลบ retry queue entries ที่เก่าเกิน 24 ชั่วโมง
   - ทำความสะอาด invalid tokens
   - รายงานสถิติการทำงาน

---

## 🏗️ **โครงสร้างไฟล์**

```
checkdarn-app/
├── lib/services/
│   └── notification_service.dart          ✨ อัปเดตด้วยระบบ Retry
├── functions/
│   ├── notification_retry.js              ✨ ระบบ Retry สำหรับ Backend
│   └── index.js                           (นำเข้า notification_retry)
├── NOTIFICATION_RETRY_USAGE_EXAMPLES.js   ✨ ตัวอย่างการใช้งาน
└── NOTIFICATION_RETRY_SYSTEM_SUMMARY.md   ✨ เอกสารสรุป (ไฟล์นี้)
```

---

## 🚀 **วิธีการทำงาน**

### **เมื่อ Token หมดอายุ:**

1. **Flutter App** ได้รับ `onTokenRefresh` callback
2. **อัปเดต token** ใหม่ใน Firestore
3. **ประมวลผล** ข้อความที่ค้างใน retry queue
4. **รีเซ็ต** retry attempts

### **เมื่อส่ง Notification ไม่สำเร็จ:**

1. **Cloud Functions** ตรวจสอบ FCM response
2. **แยกประเภท error:**
   - `Invalid Token` → ลบออกจากฐานข้อมูล
   - `Retryable Error` → เพิ่มเข้า retry queue
3. **Retry ทุก 5 นาที** จนกว่าจะสำเร็จหรือครบจำนวน

### **เมื่อมี Network Error:**

1. **Flutter** เก็บข้อความไว้ใน local retry queue
2. **พยายาม refresh token** ตาม schedule
3. **ส่งข้อความที่ค้าง** เมื่อ token กลับมาใช้ได้

---

## 🔧 **การใช้งาน**

### **เริ่มต้นระบบ (main.dart):**
```dart
await NotificationService.initialize();
```

### **ตรวจสอบสถานะ:**
```dart
final status = NotificationService.retryStatus;
print('Retry Status: $status');
```

### **Debug Functions:**
```dart
// บังคับ refresh token
await NotificationService.forceTokenRefresh();

// ประมวลผล queue
await NotificationService.forceProcessRetryQueue();

// ล้าง queue
NotificationService.clearRetryQueue();
```

### **จัดการ Login/Logout:**
```dart
// เมื่อ Login
await NotificationService.updateTokenOnLogin();

// เมื่อ Logout
await NotificationService.removeTokenOnLogout();
```

---

## 📊 **การตรวจสอบและ Debug**

### **สถานะระบบ:**
```dart
final status = NotificationService.retryStatus;
// {
//   'isRefreshing': false,
//   'retryAttempts': 0,
//   'maxRetryAttempts': 3,
//   'queueSize': 0,
//   'hasActiveTimer': false
// }
```

### **Cloud Functions Logs:**
```bash
firebase functions:log --only processRetryQueue,cleanupRetryQueue
```

### **Firestore Collections:**
- `user_tokens` - FCM tokens ของผู้ใช้
- `notification_retry_queue` - คิวข้อความที่ต้อง retry

---

## ⚙️ **การปรับแต่ง**

### **ปรับช่วงเวลา Retry (Flutter):**
```dart
static const List<int> _retryDelayMinutes = [1, 5, 15]; // นาที
static const int _maxRetryAttempts = 3;
```

### **ปรับการตั้งค่า Backend:**
```javascript
const RETRY_CONFIG = {
  maxAttempts: 3,
  delays: [5, 15, 30], // นาที
  exponentialBackoff: true
};
```

---

## 🛡️ **Security & Performance**

### **Firestore Security Rules:**
```javascript
match /notification_retry_queue/{entryId} {
  allow read, write: if false; // เฉพาะ Cloud Functions
}

match /user_tokens/{tokenId} {
  allow read, write: if request.auth.uid == resource.data.userId;
}
```

### **Performance Optimizations:**
- จำกัด retry queue processing ทีละ 50 items
- ใช้ batch operations สำหรับ token cleanup
- ทำความสะอาด old entries ทุก 24 ชั่วโมง

---

## 🎉 **ผลลัพธ์**

✅ **Token หมดอายุ** → ระบบจะ refresh อัตโนมัติ
✅ **ข้อความส่งไม่สำเร็จ** → จะ retry จนกว่าจะสำเร็จ
✅ **Invalid tokens** → ลบออกจากฐานข้อมูลอัตโนมัติ
✅ **Network issues** → เก็บไว้ใน queue และส่งใหม่ภายหลัง
✅ **Resource cleanup** → ทำความสะอาดอัตโนมัติ

---

## 🚀 **การ Deploy**

1. **อัปเดต Flutter App:**
   ```bash
   flutter build apk --release
   ```

2. **Deploy Cloud Functions:**
   ```bash
   firebase deploy --only functions
   ```

3. **อัปเดต Security Rules:**
   ```bash
   firebase deploy --only firestore:rules
   ```

---

ระบบ Retry นี้จะทำให้ผู้ใช้ไม่พลาดการแจ้งเตือนสำคัญ และช่วยให้ระบบทำงานได้อย่างเสถียรแม้ในสถานการณ์ที่มีปัญหาเครือข่ายหรือ token หมดอายุ! 🎯
