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
- **📍 พิกัด GPS** - แสดงพิกัดแม่นยำพร้อมปุ่มคัดลอก (เฉพาะโพสใหม่)
- EventPopup widget ที่ปรับปรุงใหม่

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
│   ├── map_screen.dart             # แผนที่เรียลไทม์ + Vertical Slider
│   ├── report_screen.dart          # รายงานเหตุการณ์ใหม่
│   ├── list_screen.dart            # รายการเหตุการณ์ทั้งหมด
│   └── location_picker_screen.dart # เลือกตำแหน่งบนแผนที่
├── widgets/
│   ├── location_marker.dart        # Custom location marker (Scale 1.68)
│   ├── event_marker.dart           # Custom event marker (Scale 1.365)
│   ├── event_popup.dart            # Event detail popup with GPS coordinates
│   ├── location_button.dart        # Location button (48px)
│   ├── bottom_bar.dart             # Bottom navigation bar
│   ├── profile_popup.dart          # User profile popup
│   ├── category_selector_dialog.dart # Category filter dialog
│   └── comment_bottom_sheet.dart   # Comment system
├── models/
│   └── event_model.dart            # Event data model + Categories
├── services/
│   ├── firebase_service.dart       # Firebase operations
│   ├── auth_service.dart           # Google Authentication
│   └── geocoding_service.dart      # Location services
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
- **EventMarker** - Category-based event markers (simplified design)
- **EventPopup** - Enhanced popup with GPS coordinates display and copy functionality
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

### 4. Config UI Components

#### ส่วนประกอบหลัก
- **Radius Slider**: ขนาด 36x180px ตำแหน่ง right:22
- **Profile Button**: ขนาด 35px 
- **Event Markers**: Scale 1.365 (ขยายขนาด 36.5%)
- **Location Marker**: Scale 1.68 (ขยายขนาด 68%)
- **Location Button**: ขนาด 48px

#### Event Categories & Colors
```dart
enum EventCategory {
  checkpoint,  // สีแดงเข้ม #9C3A3A
  accident,    // สีเหลือง #FDC621
  earthquake,  // สีเทาน้ำเงิน #607D8B
  question,    // สีเทาอ่อน #90A4AE
  flood,       // สีน้ำเงิน #2196F3
  fire,        // สีส้ม #FF5722
  crime,       // สีม่วง #9C27B0
  other,       // สีเทา #9E9E9E
}
```

### 5. เพิ่มฟอนต์ไทย

1. ฟอนต์ Kanit และ Sarabun ถูกใช้ผ่าน Google Fonts
2. การตั้งค่าอยู่ในไฟล์ `lib/theme/app_theme.dart`

1. ฟอนต์ Kanit และ Sarabun ถูกใช้ผ่าน Google Fonts
2. การตั้งค่าอยู่ในไฟล์ `lib/theme/app_theme.dart`

## คุณสมบัติหลัก

### 🗺️ แผนที่อินเทอร์แอกทีฟ
- แสดงเหตุการณ์แบบเรียลไทม์บนแผนที่
- **Vertical Slider** สำหรับปรับรัศมีการค้นหา (36x180px)
- **Custom Markers** แบ่งตามประเภทเหตุการณ์ (Scale 1.365)
- **Location Marker** แสดงตำแหน่งผู้ใช้ (Scale 1.68)
- **Profile Button** ขนาด 35px สำหรับจัดการผู้ใช้

### 📝 ระบบรายงานเหตุการณ์
- เลือกประเภทเหตุการณ์จาก 8 หมวดหมู่
- อัปโหลดรูปภาพประกอบ
- เลือกตำแหน่งบนแผนที่ได้
- **บันทึกพิกัด GPS อัตโนมัติ** สำหรับการแสดงผลในป๊อปอัพ
- ระบบคอมเมนต์สำหรับแต่ละเหตุการณ์

### 🏷️ หมวดหมู่เหตุการณ์
- **Checkpoint** (จุดตรวจ) - สีแดงเข้ม #9C3A3A
- **Accident** (อุบัติเหตุ) - สีเหลือง #FDC621
- **Earthquake** (แผ่นดินไหว) - สีเทาน้ำเงิน #607D8B
- **Question** (คำถาม) - สีเทาอ่อน #90A4AE
- **Flood** (น้ำท่วม) - สีน้ำเงิน #2196F3
- **Fire** (ไฟไหม้) - สีส้ม #FF5722
- **Crime** (อาชญากรรม) - สีม่วง #9C27B0
- **Other** (อื่นๆ) - สีเทา #9E9E9E

### 🔐 ระบบยืนยันตัวตน
- เข้าสู่ระบบผ่าน Google Account
- จัดการโปรไฟล์ผู้ใช้
- ความปลอดภัยข้อมูลด้วย Firebase

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

### 📍 ระบบพิกัด GPS (ใหม่!)
- แสดงพิกัดแม่นยำในป๊อปอัพเหตุการณ์ (6 ตำแหน่งทศนิยม)
- ปุ่มคัดลอกพิกัดไปยัง Clipboard
- รองรับเฉพาะโพสใหม่ที่สร้างหลังจากอัปเดต
- รูปแบบพิกัด: `latitude, longitude` (เช่น `13.123456, 100.123456`)
- โพสเก่าที่ไม่มีพิกัดจะไม่แสดงแถวพิกัด (ซ่อนอัตโนมัติ)

> **หมายเหตุ:** ฟีเจอร์พิกัดจะใช้ได้กับโพสใหม่เท่านั้น เนื่องจากโพสเก่าในฐานข้อมูลไม่มีข้อมูลพิกัด

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

### หน้ารายละเอียดเหตุการณ์
- แสดงรายการแบบ real-time
- กรองตามหมวดหมู่
- รายละเอียดเหตุการณ์
- **พิกัด GPS พร้อมปุ่มคัดลอก** (สำหรับโพสใหม่)

---

## เวอร์ชัน

**เวอร์ชันปัจจุบัน:** 1.1.0
- ✅ Custom Location & Event Markers
- ✅ Real-time data streaming
- ✅ Google Authentication
- ✅ Location Picker
- ✅ Category-based filtering
- ✅ 48-hour freshness filter
- ✅ Radius-based search (10-100 km)
- ✅ **GPS Coordinates Display** - แสดงพิกัดในป๊อปอัพพร้อมปุ่มคัดลอก
- ✅ **Enhanced EventPopup** - ป๊อปอัพที่ปรับปรุงใหม่

**อัปเดตล่าสุด:** กรกฎาคม 2025
- ✨ เพิ่มการแสดงพิกัด GPS ในป๊อปอัพเหตุการณ์
- ✨ เพิ่มปุ่มคัดลอกพิกัดไปยัง Clipboard
- 🔧 ปรับปรุง EventPopup widget ให้รองรับพิกัด
- 🔧 อัปเดต FirebaseService ให้บันทึกพิกัดสำหรับโพสใหม่
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
