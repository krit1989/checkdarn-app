# การจำกัดการใช้งานเพื่อป้องกันเกินโควตาฟรี

## 📊 ข้อจำกัดที่เพิ่มเข้ามา

### 1. 📝 จำกัดจำนวนโพสต์ต่อวัน
- **ขีดจำกัด**: 10 โพสต์ต่อคนต่อวัน
- **การตรวจสอบ**: ตรวจสอบอัตโนมัติก่อนส่งโพสต์
- **ข้อความแสดง**: "เกินขีดจำกัด: โพสต์ได้สูงสุด 10 ครั้งต่อวัน กรุณารอ 24 ชั่วโมง"

### 2. 🖼️ การบีบอัดรูปภาพ
- **ขนาดสูงสุด**: 300KB ต่อรูป (ลดจาก 5MB)
- **ความละเอียดสูงสุด**: 1080x1080 พิกเซล
- **คุณภาพ**: เริ่มต้น 70% และปรับลงตามขนาดไฟล์
- **รูปแบบ**: แปลงเป็น JPEG อัตโนมัติ

## 🔧 การทำงานของระบบ

### การตรวจสอบโพสต์ต่อวัน
```dart
// ใน firebase_service.dart
static Future<bool> canUserPostToday(String userId) async {
  final today = DateTime.now();
  final startOfDay = DateTime(today.year, today.month, today.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));

  final todayPosts = await _firestore
      .collection(_collection)
      .where('userId', isEqualTo: userId)
      .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
      .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
      .where('status', isEqualTo: 'active')
      .get();

  return todayPosts.docs.length < 10; // จำกัด 10 โพสต์
}
```

### การบีบอัดรูปภาพ
```dart
// ใน image_compression_service.dart
static Future<File?> compressImage(File imageFile) async {
  int quality = 70; // เริ่มต้น 70%
  
  for (int attempt = 0; attempt < 5; attempt++) {
    final result = await FlutterImageCompress.compressAndGetFile(
      imageFile.absolute.path,
      targetPath,
      quality: quality,
      minWidth: 1080,
      minHeight: 1080,
      format: CompressFormat.jpeg,
    );
    
    if (result != null && result.lengthSync() <= 300 * 1024) {
      return File(result.path); // สำเร็จ!
    }
    
    quality = (quality * 0.8).round(); // ลดคุณภาพ 20%
  }
}
```

## 📈 ประโยชน์ที่ได้รับ

### การป้องกันเกินโควตาฟรี
- **Firestore**: ลดจำนวน reads/writes
- **Cloud Storage**: ลดการใช้ bandwidth และพื้นที่เก็บข้อมูล
- **Firebase Hosting**: ไม่กระทบเพราะไม่ได้ใช้

### การประหยัดทรัพยากร
- **ขนาดรูป**: ลดจาก 5MB เป็น 300KB (ลด 94%)
- **จำนวนโพสต์**: จำกัดจาก ไม่จำกัด เป็น 10/วัน
- **การใช้ Internet**: ลดการใช้ bandwidth อย่างมาก

## 🚦 โควตาฟรีของ Firebase

### Spark Plan (ฟรี) - ขีดจำกัดต่อเดือน

#### Firestore Database
- **Reads**: 50,000 operations
- **Writes**: 20,000 operations  
- **Deletes**: 20,000 operations
- **Storage**: 1 GB

#### Cloud Storage
- **Storage**: 5 GB
- **Download**: 1 GB/day
- **Upload**: 1 GB/day

### การคำนวณการใช้งานด้วยข้อจำกัดใหม่

#### สมมติมีผู้ใช้ 100 คน ใช้งานทุกวัน
```
โพสต์ต่อเดือน = 100 คน × 10 โพสต์/วัน × 30 วัน = 30,000 โพสต์

Firestore Operations:
- Writes (สร้างโพสต์): 30,000 operations
- Reads (อ่านโพสต์): ขึ้นกับการดู (ควรอยู่ในขีดจำกัด)

Cloud Storage:
- รูปภาพ: 30,000 รูป × 300KB = 9 GB
- ⚠️ เกิน 5GB - ต้องพิจารณาลดเพิ่มเติม
```

## 🎯 การปรับปรุงเพิ่มเติม (แนะนำ)

### 1. ลดขนาดรูปเพิ่มเติม
```dart
static const int _maxFileSize = 200 * 1024; // 200KB แทน 300KB
static const int _maxWidth = 800; // 800px แทน 1080px
static const int _maxHeight = 800; // 800px แทน 1080px
```

### 2. จำกัดการแนบรูป
```dart
// ไม่อนุญาตแนบรูปทุกโพสต์
// หรือจำกัดเฉพาะโพสต์สำคัญ
if (category == EventCategory.accident || category == EventCategory.floodRain) {
  // อนุญาตแนบรูป
} else {
  // ไม่อนุญาตแนบรูป
}
```

### 3. ลดจำนวนโพสต์ต่อวัน
```dart
static const int _maxPostsPerDay = 5; // ลดเป็น 5 โพสต์/วัน
```

### 4. TTL เร็วขึ้น
```dart
final expireAt = now.add(const Duration(days: 3)); // 3 วันแทน 7 วัน
```

## 📱 การแสดงในแอป

### หน้า Report Screen
- แสดงข้อความ: "📝 จำกัด 10 โพสต์/วัน • 🖼️ รูปสูงสุด 300KB"
- ตรวจสอบขีดจำกัดก่อนส่งโพสต์
- แสดงข้อผิดพลาดเมื่อเกินขีดจำกัด

### หน้า List Screen  
- แสดงข้อความ: "🗑️ ลบอัตโนมัติด้วย TTL หลัง 7 วัน"
- รายการโพสต์จะน้อยลงตามขีดจำกัด

## 🔄 การทดสอบ

### ทดสอบขีดจำกัดโพสต์
1. โพสต์ 10 ครั้งในวันเดียวกัน
2. พยายามโพสต์ครั้งที่ 11
3. ต้องได้ข้อความ "เกินขีดจำกัด"

### ทดสอบการบีบอัดรูป  
1. เลือกรูปขนาดใหญ่ (> 1MB)
2. ตรวจสอบขนาดหลังบีบอัด
3. ต้องเล็กกว่า 300KB

## 💡 สรุป

การเพิ่มข้อจำกัดเหล่านี้จะช่วย:
- ✅ ป้องกันเกินโควตาฟรี
- ✅ ลดค่าใช้จ่าย 
- ✅ เพิ่มประสิทธิภาพแอป
- ✅ ควบคุมการใช้งานให้เหมาะสม

**ผลลัพธ์**: แอปสามารถรองรับผู้ใช้ได้มากขึ้นโดยไม่เสียเงินเพิ่มเติม! 🎉
