# CheckDarn - Real-time Incident Reporting App

แอปพลิเคชันรายงานเหตุการณ์เรียลไทม์ที่ช่วยให้ผู้ใช้สามารถรายงานและติดตามเหตุการณ์ต่างๆ ในพื้นที่ของตน

## ฟีเจอร์หลัก

### 📍 แผนที่เรียลไทม์
- แสดงเหตุการณ์บนแผนที่ OpenStreetMap
- ตำแหน่งปัจจุบันของผู้ใช้พร้อม Custom Location Marker
- กรองเหตุการณ์ตามประเภท (8 หมวดหมู่)
- หมุดแบ่งตามหมวดหมู่ด้วย EventMarker component
- ปรับขนาดรัศมีการค้นหา (10-100 กม.)
- แสดงเฉพาะเหตุการณ์ล่าสุด (48 ชั่วโมง)

### 📝 รายงานเหตุการณ์
- รายงานเหตุการณ์ใหม่พร้อมรูปภาพ
- เลือกประเภทเหตุการณ์ 8 ประเภท
- Location Picker สำหรับเลือกตำแหน่งแม่นยำ
- บันทึกตำแหน่ง GPS อัตโนมัติ
- ระบบ Authentication ด้วย Google Sign-In

### 📋 รายการเหตุการণ์
- แสดงรายการเหตุการณ์ทั้งหมดแบบ Real-time
- กรองตามหมวดหมู่ด้วย Bottom Navigation
- รีเฟรชข้อมูลแบบ Pull-to-refresh
- Event Cards ที่แสดงข้อมูลครบถ้วน

### 🔍 รายละเอียดเหตุการณ์
- ข้อมูลครบถ้วนของเหตุการณ์
- รูปภาพประกอบ
- แผนที่แสดงตำแหน่งเหตุการณ์
- ข้อมูลเวลาและระยะทาง

## ประเภทเหตุการณ์

- � **ด่านตรวจ** - จุดตรวจทางหลวง, ด่านตำรวจ
- 🚑 **อุบัติเหตุ** - เหตุการณ์อุบัติเหตุทางรถยนต์
- � **ไฟไหม้** - เหตุเพลิงไหม้
- 🌧 **ฝนตก/น้ำท่วม** - พื้นที่น้ำท่วม, ฝนตกหนัก
- 🌊 **สึนามิ** - เตือนภัยสึนามิ
- 🌍 **แผ่นดินไหว** - เหตุการณ์แผ่นดินไหว
- 🐶 **สัตว์หาย** - สัตว์เลี้ยงหาย
- ❓ **คำถามทั่วไป** - คำถามและข้อมูลทั่วไป

## โครงสร้างโปรเจกต์

```
lib/
├── main.dart                       # Entry point ของแอป
├── screens/
│   ├── splash_screen.dart          # หน้า Welcome
│   ├── map_screen.dart             # แผนที่เรียลไทม์
│   ├── report_screen.dart          # รายงานเหตุการณ์ใหม่
│   ├── list_screen.dart            # รายการเหตุการณ์ทั้งหมด
│   └── location_picker_screen.dart # เลือกตำแหน่งบนแผนที่
├── widgets/
│   ├── location_marker.dart        # Custom location marker
│   ├── event_marker.dart           # Custom event marker
│   ├── location_button.dart        # Reusable location button
│   ├── bottom_bar.dart             # Bottom navigation bar
│   ├── event_popup.dart            # Event detail popup
│   └── profile_popup.dart          # User profile popup
├── widgets/
│   ├── event_card.dart             # การ์ดเหตุการณ์ในหน้า list
│   ├── category_filter.dart        # ปุ่มกรองหมวดหมู่
│   ├── map_pin_icon.dart           # ไอคอนหมุดแสดงบนแผนที่
│   └── common_button.dart          # ปุ่มส่ง / แชร์ / แจ้งว่าเท็จ
├── models/
│   ├── event_model.dart            # โครงสร้างข้อมูลเหตุการณ์
│   └── category_model.dart         # ประเภทเหตุการณ์
├── services/
│   ├── location_service.dart       # จัดการ GPS, รัศมี, permission
│   ├── event_service.dart          # CRUD เหตุการณ์ (Firebase)
│   └── image_upload_service.dart   # อัปโหลดรูปภาพ
├── utils/
│   ├── constants.dart              # สีหลัก, font, category map
│   └── helpers.dart                # ฟังก์ชันช่วย format เวลา, ระยะทาง
├── routes/
│   └── app_routes.dart             # Routing ระหว่างหน้า
├── models/
│   └── event_model.dart            # Model สำหรับเหตุการณ์
├── services/
│   ├── firebase_service.dart       # จัดการ Firebase operations
│   ├── auth_service.dart           # จัดการ Authentication
│   └── geocoding_service.dart      # จัดการ Location services
├── utils/
│   └── formatters.dart             # Helper functions
└── theme/
    └── app_theme.dart              # กำหนด ThemeData (สี, ฟอนต์)
```

## เทคโนโลยีที่ใช้

### Frontend
- **Flutter** - Cross-platform mobile framework
- **Dart** - Programming language
- **flutter_map** - OpenStreetMap integration
- **Material Design 3** - UI/UX framework

### Backend & Services
- **Firebase Authentication** - Google Sign-In
- **Cloud Firestore** - Real-time database
- **Firebase Storage** - Image storage
- **OpenStreetMap** - Map tiles

### Custom Components
- **LocationMarker** - Custom location pin with triangle tip
- **EventMarker** - Category-based event markers
- **LocationButton** - Reusable location button with loading states

## การติดตั้ง

### 1. ติดตั้ง Dependencies

```bash
flutter pub get
```

### 2. ตั้งค่า Firebase

1. สร้างโปรเจกต์ใน [Firebase Console](https://console.firebase.google.com/)
2. เปิดใช้งาน Authentication (Google Sign-In), Firestore, และ Storage  
3. ดาวน์โหลดไฟล์ `google-services.json` (Android) และ `GoogleService-Info.plist` (iOS)
4. วางไฟล์ในตำแหน่งที่เหมาะสม

### 3. ตั้งค่า Google Sign-In

1. ไปที่ [Google Cloud Console](https://console.cloud.google.com/)
2. เปิดใช้งาน Google Sign-In API
3. สร้าง OAuth 2.0 credentials
4. เพิ่ม SHA-1 fingerprint สำหรับ Android

### 4. เพิ่มฟอนต์ไทย

1. ฟอนต์ Kanit และ Sarabun ถูกใช้ผ่าน Google Fonts
2. การตั้งค่าอยู่ในไฟล์ `lib/theme/app_theme.dart`

## การใช้งาน

### การรันแอป

```bash
flutter run
```

### การสร้าง APK

```bash
flutter build apk --release
```

### การสร้าง iOS

```bash
flutter build ios --release
```

## ฟีเจอร์เพิ่มเติม

### ระบบ Authentication
- Google Sign-In integration
- User profile management
- ตรวจสอบสถานะการล็อกอิน

### ระบบตำแหน่ง
- ตรวจสอบ permission ตำแหน่ง
- แสดงเหตุการณ์ในรัศมีที่กำหนด (10-100 กม.)
- คำนวณระยะทางจากตำแหน่งปัจจุบัน
- Location Picker สำหรับเลือกตำแหน่งแม่นยำ

### การจัดการรูปภาพ
- ถ่ายรูปจากกล้อง
- เลือกรูปจากแกลเลอรี่
- อัปโหลดไปยัง Firebase Storage
- ตรวจสอบขนาดไฟล์

### Real-time Updates
- StreamBuilder สำหรับข้อมูลเรียลไทม์
- แสดงเฉพาะเหตุการณ์ใน 48 ชั่วโมงล่าสุด
- กรองตามหมวดหมู่และระยะทาง

## สี Theme ของแต่ละหมวดหมู่

| อีโมจิ | ประเภท       | สี          | HEX Code  | ความหมาย                                         |
|--------|--------------|-------------|-----------|--------------------------------------------------|
| 🚓     | ด่านตรวจ     | Navy Blue   | `#1A237E` | ให้ความรู้สึกเข้มข้น จริงจัง เป็นสีของหน่วยงาน   |
| 🚑     | อุบัติเหตุ   | Strong Red  | `#D32F2F` | สีแดงเตือนภัย ชัดเจนกว่าการใช้แดงสด              |
| 🔥     | ไฟไหม้       | Deep Orange | `#F4511E` | สีส้มอมแดง ร้อนแรง สื่อถึงไฟชัดเจน               |
| 🌧     | ฝนตก/น้ำท่วม | Slate Blue  | `#3F51B5` | น้ำเงินอมม่วง ให้ความรู้สึกเย็นและฝนตก           |
| 🌊     | สึนามิ       | Teal        | `#0097A7` | ฟ้าอมเขียว สื่อถึงคลื่น/ทะเล และอันตราย          |
| 🌍     | แผ่นดินไหว   | Earth Brown | `#5D4037` | น้ำตาลเข้ม เป็นสีดิน สื่อถึงแผ่นดิน              |
| 🐶     | สัตว์หาย     | Lime Green  | `#689F38` | สีเขียวให้ความรู้สึกหวังดี ช่วยเหลือ             |
| ❓      | คำถามทั่วไป  | Soft Purple | `#7B1FA2` | ม่วงกลาง ๆ สบายตา สื่อถึงความสงสัยแบบไม่เร่งด่วน |

## การพัฒนาต่อ

### ฟีเจอร์ที่ควรเพิ่ม

1. **ระบบผู้ใช้ (✅ ทำแล้ว)**
   - Google Sign-In authentication
   - โปรไฟล์ผู้ใช้
   - ระบบ logout

2. **การแจ้งเตือน**
   - Push notifications
   - แจ้งเตือนเหตุการณ์ใกล้เคียง
   - แจ้งเตือนการยืนยัน

3. **ระบบการประเมิน**
   - ให้คะแนนผู้รายงาน
   - ระบบการยืนยันเหตุการณ์
   - แจ้งข้อมูลเท็จ

## Screenshots

### หน้าแผนที่
- แสดงหมุดเหตุการณ์ตามหมวดหมู่
- ปรับรัศมีการค้นหา
- กรองตามประเภทเหตุการณ์

### หน้ารายงานเหตุการณ์
- เลือกตำแหน่งบนแผนที่
- เลือกหมวดหมู่เหตุการณ์
- อัปโหลดรูปภาพ

### หน้ารายการเหตุการณ์
- แสดงรายการแบบ real-time
- กรองตามหมวดหมู่
- รายละเอียดเหตุการณ์

---

## เวอร์ชัน

**เวอร์ชันปัจจุบัน:** 1.0.0
- ✅ Custom Location & Event Markers
- ✅ Real-time data streaming
- ✅ Google Authentication
- ✅ Location Picker
- ✅ Category-based filtering
- ✅ 48-hour freshness filter
- ✅ Radius-based search (10-100 km)

**อัปเดตล่าสุด:** มกราคม 2025
- เพิ่ม EventMarker และ LocationMarker components
- อัปเดตสีหมวดหมู่ให้สื่อความหมายชัดเจน
- ปรับปรุง UI/UX และลบเงาไม่จำเป็น
- ใช้ OpenStreetMap แทน Google Maps
   - ระบบ reputation
   - รางวัลสำหรับผู้รายงานที่ดี

4. **การวิเคราะห์ข้อมูล**
   - สถิติเหตุการณ์
   - แนวโน้มในแต่ละพื้นที่
   - รายงานสรุป

5. **ฟีเจอร์เพิ่มเติม**
   - แชร์เหตุการณ์
   - ความคิดเห็น
   - ติดตามเหตุการณ์
   - โหมดมืด

## การมีส่วนร่วม

หากต้องการร่วมพัฒนาโปรเจกต์นี้:

1. Fork repository
2. สร้าง feature branch
3. Commit การเปลี่ยนแปลง
4. สร้าง Pull Request

## ลิขสิทธิ์

โปรเจกต์นี้อยู่ภายใต้ลิขสิทธิ์ MIT License

## ติดต่อ

หากมีคำถามหรือข้อเสนอแนะ กรุณาสร้าง Issue ใน repository นี้
