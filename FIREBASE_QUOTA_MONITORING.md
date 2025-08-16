# 🔥 Firebase Project Quota Monitoring Guide

## 📊 **Cloud Functions Quotas**

### **Free Tier Limits:**
```
✅ Invocations: 2M/month (ปัจจุบันใช้ ~900/month)
✅ Compute Time: 400,000 GB-seconds/month 
✅ Outbound Networking: 5GB/month
```

### **ถ้าเกิน Quota จะเกิดอะไร:**
1. **Functions หยุดทำงาน** - แจ้งเตือนไม่ส่ง
2. **Auto cleanup หยุด** - ข้อมูลเก่าสะสม
3. **Retry system หยุด** - Notification lost

### **การตรวจสอบ:**
```bash
# ดู usage ปัจจุบัน
firebase projects:list
firebase functions:log --limit 100

# Monitor quota
https://console.firebase.google.com/project/YOUR_PROJECT/usage
```

---

## 📱 **FCM (Firebase Cloud Messaging) Quotas**

### **Free Tier Limits:**
```
✅ Messages: ไม่จำกัด (Topic-based)
⚠️ Messages: 10M/month (Token-based)
✅ Topics: ไม่จำกัดจำนวน
```

### **ปัจจุบันใช้ Topic-based = ฟรี 100%**
```javascript
// ✅ ไม่เสียเงิน
await admin.messaging().send({
  topic: 'th_1376_10050_20km',
  notification: { ... }
});

// ❌ เสียเงิน (ถ้าใช้มาก)
await admin.messaging().sendEachForMulticast({
  tokens: [...1000_tokens...],
  notification: { ... }
});
```

---

## 🗄️ **Firestore Quotas**

### **Free Tier Limits:**
```
✅ Reads: 50,000/day (ปัจจุบันใช้ ~1,000/day)
✅ Writes: 20,000/day (ปัจจุบันใช้ ~100/day)
✅ Deletes: 20,000/day (cleanup ใช้ ~50/day)
✅ Storage: 1GB (ปัจจุบันใช้ ~10MB)
```

### **ถ้าเกิน Quota:**
1. **Read/Write หยุด** - แอปไม่ทำงาน
2. **Auto cleanup หยุด** - Storage เต็ม
3. **Topic subscription หยุด** - ไม่รับแจ้งเตือน

---

## 📈 **Quota Monitoring Script**

```javascript
// functions/quota_monitor.js
exports.checkQuotaUsage = functions.pubsub
  .schedule('every 1 hours')
  .onRun(async (context) => {
    const usage = await getProjectUsage();
    
    if (usage.functions > 80) { // 80% ของ quota
      await sendQuotaAlert('Functions quota at 80%');
    }
    
    if (usage.firestore > 80) {
      await sendQuotaAlert('Firestore quota at 80%');
    }
  });

async function getProjectUsage() {
  // ใช้ Google Cloud Monitoring API
  return {
    functions: calculateFunctionUsage(),
    firestore: calculateFirestoreUsage(),
    storage: calculateStorageUsage()
  };
}
```

---

## 🚨 **แก้ไขเมื่อใกล้เกิน Quota**

### **1. Functions Quota:**
```javascript
// ลด frequency
.schedule('every 2 hours') // จาก 1 ชั่วโมง

// ลด batch size
.limit(10) // จาก 50
```

### **2. Firestore Quota:**
```javascript
// ใช้ cache มากขึ้น
const cached = await cache.get('reports');
if (cached) return cached;

// Batch operations
const batch = db.batch();
// ทำ multiple operations พร้อมกัน
```

### **3. Upgrade เป็น Blaze Plan:**
```
Pay-as-you-go pricing
- Functions: $0.40/1M invocations
- Firestore: $0.36/100K operations
- ยังคงมี Free tier included
```
