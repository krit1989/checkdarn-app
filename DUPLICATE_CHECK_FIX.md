# 🎯 แก้ไขระบบตรวจสอบ Duplicate Reports แยกตามประเภท

## ❌ **ปัญหาเดิม:**
ระบบตรวจสอบ duplicate รวมทุกประเภทรายงานเข้าด้วยกัน ทำให้:
- ไม่สามารถรายงาน **speedChanged** ได้ถ้ามี **newCamera** ในบริเวณเดียวกัน
- ไม่สามารถรายงาน **removedCamera** ได้ถ้ามี **speedChanged** ในบริเวณเดียวกัน
- สร้างความสับสนเพราะแต่ละประเภทมีจุดประสงค์ต่างกัน

## ✅ **การแก้ไขใหม่:**
แยกการตรวจสอบ duplicate ตามประเภทรายงาน:

### **1. รายงานกล้องใหม่ (newCamera)**
```dart
// ตรวจสอบเฉพาะรายงาน newCamera ในรัศมี 50 เมตร
final nearbyNewCameraReports = await _findNearbyReportsByType(
  latitude, longitude, 50, CameraReportType.newCamera
);
```
- **เงื่อนไข**: ใช้ระยะรัศมี 50 เมตร
- **ข้อความ**: "มีการรายงานกล้องใหม่ในบริเวณนี้แล้ว"

### **2. รายงานกล้องถูกถอด (removedCamera)**
```dart
// ตรวจสอบเฉพาะรายงาน removedCamera กับ Camera ID เดียวกัน
final existingRemovalReports = await _firestore
  .collection(_reportsCollection)
  .where('type', isEqualTo: 'removedCamera')
  .where('selectedCameraId', isEqualTo: selectedCameraId)
  .where('status', whereIn: ['pending', 'verified']).get();
```
- **เงื่อนไข**: ใช้ Camera ID ที่แน่นอน
- **ข้อความ**: "มีการรายงานกล้องตัวนี้ถูกถอดแล้ว"

### **3. รายงานการเปลี่ยนความเร็ว (speedChanged)**
```dart
// ตรวจสอบเฉพาะรายงาน speedChanged กับ Camera ID เดียวกัน
final existingSpeedChangeReports = await _firestore
  .collection(_reportsCollection)
  .where('type', isEqualTo: 'speedChanged')
  .where('selectedCameraId', isEqualTo: selectedCameraId)
  .where('status', whereIn: ['pending', 'verified']).get();
```
- **เงื่อนไข**: ใช้ Camera ID ที่แน่นอน
- **ข้อความ**: "มีการรายงานการเปลี่ยนความเร็วของกล้องตัวนี้แล้ว"

## 🔧 **เมธอดใหม่ที่เพิ่ม:**

### `_findNearbyReportsByType()`
```dart
static Future<List<CameraReport>> _findNearbyReportsByType(
    double lat, double lng, double radiusMeters, CameraReportType type) async {
  final snapshot = await _firestore
      .collection(_reportsCollection)
      .where('type', isEqualTo: type.toString().split('.').last)
      .where('latitude', isGreaterThan: lat - latRange)
      .where('latitude', isLessThan: lat + latRange)
      .where('status', whereIn: ['pending', 'verified'])
      .get();
  // ... กรองระยะทางและส่งกลับ
}
```

## 📋 **ตารางเปรียบเทียบ:**

| ประเภทรายงาน | เงื่อนไขตรวจสอบ | ข้อความ Error |
|-------------|----------------|---------------|
| **newCamera** | ระยะรัศมี 50m + ประเภทเดียวกัน | "มีการรายงานกล้องใหม่ในบริเวณนี้แล้ว" |
| **removedCamera** | Camera ID เดียวกัน + ประเภทเดียวกัน | "มีการรายงานกล้องตัวนี้ถูกถอดแล้ว" |
| **speedChanged** | Camera ID เดียวกัน + ประเภทเดียวกัน | "มีการรายงานการเปลี่ยนความเร็วของกล้องตัวนี้แล้ว" |

## 🎯 **ประโยชน์ของการแก้ไข:**

### **1. ความยืดหยุ่น**
- สามารถรายงานหลายประเภทในพื้นที่เดียวกันได้
- แต่ละประเภทมีเงื่อนไขที่เหมาะสม

### **2. ความแม่นยำ**
- newCamera: ใช้ระยะทาง (สำหรับกล้องใหม่ในบริเวณใกล้เคียง)
- removedCamera/speedChanged: ใช้ Camera ID (สำหรับกล้องเฉพาะตัว)

### **3. UX ที่ดีขึ้น**
- ข้อความ error ชัดเจนและเฉพาะเจาะจง
- ไม่มีการบล็อกที่ไม่จำเป็น

## 📝 **ตัวอย่างการใช้งาน:**

### **สถานการณ์ที่ 1: ได้แล้ว ✅**
```
ตำแหน่ง: ถนนสุขุมวิท กม.5
- รายงาน newCamera: สำเร็จ
- รายงาน speedChanged (กล้องเดียวกัน): สำเร็จ ✅
- รายงาน removedCamera (กล้องเดียวกัน): สำเร็จ ✅
```

### **สถานการณ์ที่ 2: ยังไม่ได้ ❌**
```
กล้อง ID: cam_123
- รายงาน speedChanged ครั้งที่ 1: สำเร็จ
- รายงาน speedChanged ครั้งที่ 2: ❌ "มีการรายงานการเปลี่ยนความเร็วของกล้องตัวนี้แล้ว"
```

## 🚀 **พร้อมใช้งาน:**
- ✅ Code แก้ไขแล้ว
- ✅ ไม่มี compile errors
- ✅ Logic ทำงานแยกประเภทแล้ว
- ✅ Error messages ชัดเจนขึ้น

**ตอนนี้ผู้ใช้สามารถรายงานการเปลี่ยนความเร็วได้โดยไม่ติด duplicate error กับรายงานประเภทอื่น!** 🎉
