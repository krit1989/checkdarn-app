# 🚨 Emergency Verified Reports Cleanup System

## ปัญหาที่แก้ไข

ระบบพบปัญหาที่รายงานที่ได้รับการยืนยัน (verified) และถูกปฏิเสธ (rejected) ยังคงอยู่ใน `camera_reports` collection แม้ว่าระบบจะต้องลบออกโดยอัตโนมัติแล้ว

### ข้อมูลที่พบปัญหา:
- รายงาน `newCamera` ที่มี `status: "verified"` ยังคงอยู่
- รายงาน `removedCamera` ที่มี `status: "verified"` และ `actuallyDeleted: true` ยังคงอยู่
- ระบบ auto-removal ที่อยู่ใน `submitVote` method อาจไม่ทำงาน

## วิธีแก้ปัญหา

### 1. Emergency Cleanup Method
สร้าง method ใหม่ `removeAllStuckVerifiedReports()` ใน `CameraReportService`:

```dart
static Future<int> removeAllStuckVerifiedReports({bool requireAdmin = true})
```

**คุณสมบัติ:**
- ลบรายงานที่มี `status: "verified"` หรือ `status: "rejected"` ทั้งหมด
- ตรวจสอบสิทธิ์ admin ก่อนดำเนินการ
- บันทึก log ทุกการลบใน `emergency_cleanup_log` collection
- ใช้ batch operations เพื่อความเร็วและความปลอดภัย

### 2. Auto-Trigger on App Launch
แก้ไข `_performInitialCleanup()` ใน `camera_report_screen.dart`:

```dart
final deletedCount = await CameraReportService.removeAllStuckVerifiedReports(
  requireAdmin: true
);
```

**การทำงาน:**
- เรียกใช้ emergency cleanup แทน regular cleanup
- ทำงานเฉพาะกับ admin users เท่านั้น
- รีเฟรชข้อมูลทันทีหลังการลบ

## สิทธิ์ Admin

**Admin Emails ที่มีสิทธิ์:**
- `kritchapon.developer@gmail.com`
- `admin@checkdarn.com`  
- `krit1989@outlook.com`

## การทำงานของระบบ

### เมื่อเปิดแอป (Admin Users):
1. รอ 2 วินาทีให้แอปโหลดเสร็จ
2. ตรวจสอบสิทธิ์ admin
3. ค้นหารายงานที่มี `status: "verified"` หรือ `"rejected"`
4. ลบรายงานทั้งหมดที่พบพร้อมบันทึก log
5. รีเฟรชข้อมูลในหน้าจอ

### เมื่อเปิดแอป (Regular Users):
1. ข้ามการทำ cleanup (แสดงข้อความ "User is not admin")
2. โหลดข้อมูลปกติ

## Logging System

### Collections ที่ใช้บันทึก:
- `emergency_cleanup_log` - บันทึกรายละเอียดแต่ละรายงานที่ถูกลบ
- `emergency_cleanup_summary` - สรุปผลการทำความสะอาด
- `emergency_cleanup_errors` - บันทึกข้อผิดพลาด

### ข้อมูลที่บันทึก:
```json
{
  "reportId": "document_id",
  "reportType": "newCamera|removedCamera|speedChanged",
  "status": "verified|rejected",
  "selectedCameraId": "camera_id",
  "roadName": "road_name",
  "removedAt": "timestamp",
  "reason": "emergency_stuck_report_cleanup"
}
```

## การใช้งาน Manual

### วิธีที่ 1: ผ่าน Flutter App
1. ล็อกอินด้วย admin email
2. เปิดหน้า Camera Report
3. ระบบจะทำ cleanup อัตโนมัติ

### วิธีที่ 2: Emergency Script
```bash
dart emergency_cleanup_verified_reports.dart
```

### วิธีที่ 3: Firebase Console (Manual)
1. เข้า Firebase Console
2. ไป Firestore Database
3. เลือก collection: `camera_reports`  
4. กรอง: `status == "verified"` OR `status == "rejected"`
5. ลบเอกสารทั้งหมดที่พบ

## ผลลัพธ์ที่คาดหวัง

✅ **หลังการ Cleanup:**
- `camera_reports` collection จะมีเฉพาะรายงานที่ `status: "pending"`
- รายงาน verified/rejected จะถูกลบออกทั้งหมด
- ข้อมูล log จะถูกบันทึกไว้สำหรับ audit trail
- UI จะแสดงเฉพาะรายงานที่รอการโหวต

✅ **ข้อมูลที่ไม่ถูกกระทบ:**
- `speed_cameras` collection (กล้องที่สร้างจาก verified newCamera reports)
- `camera_votes` collection (ประวัติการโหวต)
- Collections อื่นๆ ทั้งหมด

## การตรวจสอบ

### คำสั่งตรวจสอบใน Firebase Console:
```javascript
// ตรวจสอบรายงานที่เหลืออยู่
db.collection('camera_reports')
  .where('status', '==', 'verified')
  .get()
  .then(snapshot => {
    console.log(`Found ${snapshot.size} stuck verified reports`);
  });

// ตรวจสอบ cleanup logs  
db.collection('emergency_cleanup_summary')
  .orderBy('cleanupTimestamp', 'desc')
  .limit(1)
  .get()
  .then(snapshot => {
    if (!snapshot.empty) {
      const data = snapshot.docs[0].data();
      console.log(`Last cleanup: ${data.reportsDeleted} reports deleted`);
    }
  });
```

## Version History

- **v1.0**: ระบบ auto-removal ใน `submitVote` method (มีปัญหา)
- **v2.0**: เพิ่ม Emergency Cleanup System (แก้ปัญหาสำเร็จ) ✅

## APK Build Info

- **Size**: 59.5MB
- **Build Type**: Release
- **Emergency Cleanup**: ✅ Included
- **Admin Protection**: ✅ Email-based validation
