# การตั้งค่า Time-To-Live (TTL) สำหรับ Firestore (ฟรี)

## วิธีการตั้งค่า TTL ใน Firebase Console

### ขั้นตอนที่ 1: เข้าสู่ Firebase Console
1. เปิดเบราว์เซอร์และไปที่ [Firebase Console](https://console.firebase.google.com)
2. เลือกโปรเจกต์ `checkdarn-app` ของคุณ

### ขั้นตอนที่ 2: ไปที่ Firestore Database
1. ในเมนูซ้าย คลิกที่ **"Firestore Database"**
2. เลือกแท็บ **"Indexes"** ที่ด้านบน
3. คลิกแท็บ **"TTL Policies"**

### ขั้นตอนที่ 3: สร้าง TTL Policy
1. กดปุ่ม **"Create Policy"**
2. ตั้งค่าดังนี้:
   - **Collection ID**: `reports`
   - **TTL Field**: `expireAt`
3. กด **"Save"** เพื่อบันทึก

## การทำงานของ TTL

### อัตโนมัติ
- Firestore จะตรวจสอบเอกสารทุกๆ **24 ชั่วโมง**
- เมื่อเวลาปัจจุบันเกินค่าในฟิลด์ `expireAt` เอกสารจะถูกลบ
- การลบอาจไม่เกิดขึ้นทันที แต่จะเกิดขึ้นภายใน **72 ชั่วโมง** หลังจากเวลาหมดอายุ

### ไม่เสียเงินเพิ่มเติม
- TTL เป็นฟีเจอร์ฟรีของ Firestore
- ไม่ต้องใช้ Cloud Functions
- ไม่ต้องอัปเกรดเป็น Blaze Plan

## โครงสร้างข้อมูลใหม่

เมื่อสร้างรายงานใหม่ ระบบจะเพิ่มฟิลด์ `expireAt` อัตโนมัติ:

```json
{
  "type": "อุบัติเหตุ",
  "description": "รถชนกันบนถนน",
  "timestamp": "2025-07-17T13:00:00Z",
  "expireAt": "2025-07-24T13:00:00Z",  // 7 วันหลังจาก timestamp
  "lat": 13.7563,
  "lng": 100.5018,
  "district": "บางรัก",
  "province": "กรุงเทพมหานคร",
  "status": "active"
}
```

## การ Migrate ข้อมูลเก่า

ระบบจะทำการ migrate ข้อมูลเก่าที่ยังไม่มี `expireAt` field อัตโนมัติเมื่อเปิดแอปครั้งแรก:

1. ค้นหาเอกสารที่ไม่มี `expireAt` field
2. คำนวณ `expireAt` จาก `timestamp + 7 วัน`
3. อัปเดตเอกสารด้วย batch operation

## การตรวจสอบสถานะ

### ใน Firebase Console
1. ไปที่ **Firestore Database** > **Indexes** > **TTL Policies**
2. จะแสดงจำนวนเอกสารที่ตั้งค่าให้หมดอายุ
3. สามารถดูสถานะการทำงานของ TTL Policy ได้

### ใน App Logs
ระบบจะแสดง logs เมื่อ:
- สร้างรายงานใหม่พร้อม `expireAt`
- ทำการ migrate ข้อมูลเก่า
- เริ่มต้น TTL initialization

## ข้อดีของ TTL เทียบกับ Client-side Cleanup

| ฟีเจอร์ | TTL | Client-side Cleanup |
|---------|-----|-------------------|
| **ค่าใช้จ่าย** | ฟรี | ฟรี |
| **การทำงาน** | อัตโนมัติ 100% | ต้องเปิดแอป |
| **ประสิทธิภาพ** | Server-side | Client-side |
| **ความแน่นอน** | แน่นอนภายใน 72 ชม. | ขึ้นกับการใช้แอป |
| **ทรัพยากร** | ไม่กระทบแอป | ใช้ bandwidth |

## หมายเหตุสำคัญ

1. **Delay การลบ**: TTL อาจมี delay สูงสุด 72 ชั่วโมงหลังจากเวลาหมดอายุ
2. **Field Required**: เอกสารต้องมี `expireAt` field ที่เป็น Timestamp
3. **ไม่สามารถยกเลิกได้**: เมื่อถึงเวลาหมดอายุ เอกสารจะถูกลบอัตโนมัติ
4. **Backup**: ถ้าต้องการเก็บข้อมูลยาวกว่า 7 วัน ให้ทำ backup ก่อนหมดอายุ

## คำสั่ง Debug

เพื่อตรวจสอบการทำงานของ TTL:

```bash
# ดู logs ของแอป
flutter logs

# Build และรันแอปใหม่
flutter clean
flutter pub get
flutter run
```

---

**เสร็จสิ้น!** 🎉

ตอนนี้แอป CheckDarn ของคุณจะใช้ TTL ของ Firestore ในการลบข้อมูลอัตโนมัติหลัง 7 วัน โดยไม่เสียเงินเพิ่มเติมและทำงานได้อย่างมีประสิทธิภาพ
