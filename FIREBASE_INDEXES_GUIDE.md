# Firebase Indexes สำหรับประสิทธิภาพที่ดีกว่า

## Indexes ที่แนะนำให้สร้าง

### 1. Index สำหรับ Query หลัก (Map Screen)

```javascript
// Collection: reports
// ใน Firebase Console > Firestore > Indexes

// Index 1: สำหรับค้นหาตามเวลาและสถานะ
{
  collection: "reports",
  fields: [
    { fieldPath: "status", order: "ASCENDING" },
    { fieldPath: "timestamp", order: "DESCENDING" },
    { fieldPath: "__name__", order: "DESCENDING" }
  ]
}

// Index 2: สำหรับค้นหาตามหมวดหมู่และเวลา
{
  collection: "reports",
  fields: [
    { fieldPath: "category", order: "ASCENDING" },
    { fieldPath: "timestamp", order: "DESCENDING" },
    { fieldPath: "__name__", order: "DESCENDING" }
  ]
}

// Index 3: สำหรับ Geo Query (ถ้าใช้ geopoint)
{
  collection: "reports", 
  fields: [
    { fieldPath: "location", order: "ASCENDING" },
    { fieldPath: "timestamp", order: "DESCENDING" }
  ]
}
```

### 2. วิธีสร้าง Indexes

#### ผ่าน Firebase Console:
1. เข้า Firebase Console → Project → Firestore Database
2. ไปที่ Indexes tab
3. คลิก "Create Index" 
4. เพิ่ม fields ตามที่แนะนำข้างต้น

#### ผ่าน Firebase CLI:
```bash
# สร้างไฟล์ firestore.indexes.json
firebase firestore:indexes

# Deploy indexes
firebase deploy --only firestore:indexes
```

### 3. การปรับปรุง Query ใน Code

```dart
// ใน firebase_service.dart - ปรับปรุง getReportsStream()
static Stream<QuerySnapshot> getReportsStream() {
  return FirebaseFirestore.instance
      .collection('reports')
      .where('status', isEqualTo: 'active')
      .orderBy('timestamp', descending: true)
      .limit(100) // จำกัดจำนวนเพื่อประสิทธิภาพ
      .snapshots();
}

// เพิ่ม Query สำหรับ category filter
static Stream<QuerySnapshot> getReportsByCategory(List<String> categories) {
  return FirebaseFirestore.instance
      .collection('reports')
      .where('category', whereIn: categories)
      .where('status', isEqualTo: 'active')
      .orderBy('timestamp', descending: true)
      .limit(50)
      .snapshots();
}
```

### 4. Performance Tips

- **Limit Results**: ใช้ `.limit()` ในทุก query
- **Use Pagination**: สำหรับ list ที่มีข้อมูลเยอะ
- **Cache Strategy**: ใช้ `Source.cache` เมื่อเหมาะสม
- **Index Optimization**: ตรวจสอบ usage ใน Firebase Console

### 5. การตรวจสอบประสิทธิภาพ

```dart
// เพิ่มใน firebase_service.dart
static Future<void> enableOfflineSupport() async {
  await FirebaseFirestore.instance.enableNetwork();
  await FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
}
```

### 6. Error Handling สำหรับ Missing Indexes

เมื่อเจอ error `The query requires an index`:
1. Copy URL จาก error message
2. เปิด URL เพื่อสร้าง index อัตโนมัติ
3. รอ index ประมาณ 2-5 นาที
4. ทดสอบแอปอีกครั้ง

### 7. การ Monitor Performance

ใน Firebase Console → Performance Monitoring:
- ดู query performance
- ตรวจสอบ index usage
- วิเคราะห์ slow queries

## สรุป

การสร้าง indexes ที่เหมาะสมจะช่วย:
- ลดเวลาโหลดข้อมูล 80-90%
- ประหยัด Firestore reads
- ปรับปรุง user experience อย่างมาก
