# 🚨 CheckDarn - Real-time Incident Reporting App

> **แอปพลิเคชันรายงานเหตุการณ์เรียลไทม์** ที่ช่วยให้ผู้ใช้สามารถรายงานและติดตามเหตุการณ์ต่างๆ ในพื้นที่ของตนแบบเรียลไทม์

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg)](https://flutter.dev/)
[![Firebase](https://img.shields.io/badge/Firebase-Latest-orange.svg)](https://firebase.google.com/)
[![Status](https://img.shields.io/badge/Status-Production%20Ready-green.svg)]()
[![Version](https://img.shields.io/badge/Version-1.2.0-blue.svg)]()

## 🌟 ฟีเจอร์หลัก

### 📍 แผนที่เรียลไทม์
- 🗺️ แสดงเหตุการณ์บนแผนที่ **OpenStreetMap** แบบเรียลไทม์
- 📍 ตำแหน่งปัจจุบันของผู้ใช้พร้อม **Custom Location Marker**
- 🎯 กรองเหตุการณ์ตามประเภท (8 หมวดหมู่)
- 📌 หมุดแบ่งตามหมวดหมู่ด้วย **EventMarker component**
- 🔍 ปรับขนาดรัศมีการค้นหา (10-100 กม.)
- ⏰ แสดงเฉพาะเหตุการณ์ล่าสุด (7 วัน พร้อม Auto-cleanup)

### 📝 รายงานเหตุการณ์
- 📸 รายงานเหตุการณ์ใหม่พร้อมรูปภาพ (WebP compression)
- 🏷️ เลือกประเภทเหตุการณ์ 8 ประเภท
- 🎯 **Location Picker** สำหรับเลือกตำแหน่งแม่นยำ
- 📍 บันทึกตำแหน่ง GPS อัตโนมัติ
- 🔐 ระบบ **Authentication ด้วย Google Sign-In**
- ⚡ **TURBO Transaction mode** - บันทึกข้อมูลแบบ atomic

### 📋 รายการเหตุการณ์
- 🔄 แสดงรายการเหตุการณ์ทั้งหมดแบบ **Real-time**
- 🎛️ กรองตามหมวดหมู่ด้วย Bottom Navigation
- ↻ รีเฟรชข้อมูลแบบ Pull-to-refresh
- 🃏 **Event Cards** ที่แสดงข้อมูลครบถ้วน

### 🔍 รายละเอียดเหตุการณ์
- 📊 ข้อมูลครบถ้วนของเหตุการณ์
- 🖼️ รูปภาพประกอบ
- 🗺️ แผนที่แสดงตำแหน่งเหตุการณ์
- ⏱️ ข้อมูลเวลาและระยะทาง
- **📍 พิกัด GPS** - แสดงพิกัดแม่นยำพร้อมปุ่มคัดลอก (เฉพาะโพสใหม่)
- ✨ **EventPopup widget** ที่ปรับปรุงใหม่

### 🛡️ ระบบความปลอดภัย
- 🔒 **Firebase Security Rules** - ป้องกันการเข้าถึงข้อมูลโดยไม่ได้รับอนุญาต
- 👤 **User Statistics** - ติดตามการใช้งานของผู้ใช้
- ⏰ **Daily Limits** - จำกัดการโพสต์ 10 ครั้งต่อวัน
- 🧹 **Auto Cleanup** - ลบข้อมูลเก่าอัตโนมัติ (7 วัน)

## 🏷️ ประเภทเหตุการณ์

| อีโมจิ | ประเภท       | สี                | HEX Code  | ใช้งาน                                   |
|--------|--------------|-------------------|-----------|------------------------------------------|
| 🚓     | ด่านตรวจ     | Navy Blue         | `#1A237E` | จุดตรวจทางหลวง, ด่านตำรวจ                |
| 🚑     | อุบัติเหตุ   | Strong Red        | `#D32F2F` | เหตุการณ์อุบัติเหตุทางรถยนต์              |
| 🔥     | ไฟไหม้       | Deep Orange       | `#F4511E` | เหตุเพลิงไหม้                            |
| 🌧     | ฝนตก/น้ำท่วม | Slate Blue        | `#3F51B5` | พื้นที่น้ำท่วม, ฝนตกหนัก                 |
| 🌊     | สึนามิ       | Teal              | `#0097A7` | เตือนภัยสึนามิ                           |
| 🌍     | แผ่นดินไหว   | Earth Brown       | `#5D4037` | เหตุการณ์แผ่นดินไหว                      |
| 🐶     | สัตว์หาย     | Lime Green        | `#689F38` | สัตว์เลี้ยงหาย                          |
| ❓      | คำถามทั่วไป  | Soft Purple       | `#7B1FA2` | คำถามและข้อมูลทั่วไป                     |

## 🏗️ โครงสร้างโปรเจกต์

```
lib/
├── main.dart                         # 🚀 Entry point ของแอป
├── firebase_options.dart             # 🔧 Firebase configuration
├── screens/
│   ├── map_screen.dart               # 🗺️ แผนที่เรียลไทม์ + Vertical Slider
│   ├── report_screen.dart            # 📝 รายงานเหตุการณ์ใหม่
│   ├── list_screen.dart              # 📋 รายการเหตุการณ์ทั้งหมด
│   └── location_picker_screen.dart   # 📍 เลือกตำแหน่งบนแผนที่
├── widgets/
│   ├── location_marker.dart          # 📍 Custom location marker (Scale 1.68)
│   ├── event_marker.dart             # 📌 Custom event marker (Scale 1.365)
│   ├── event_popup.dart              # 💬 Event detail popup with GPS coordinates
│   ├── location_button.dart          # 🔘 Location button (48px)
│   ├── bottom_bar.dart               # 📱 Bottom navigation bar
│   ├── profile_popup.dart            # 👤 User profile popup
│   ├── category_selector_dialog.dart # 🎛️ Category filter dialog
│   └── comment_bottom_sheet.dart     # 💬 Comment system
├── models/
│   └── event_model.dart              # 📊 Event data model + Categories
├── services/
│   ├── firebase_service.dart         # 🔥 Firebase operations + Security
│   ├── auth_service.dart             # 🔐 Google Authentication
│   └── geocoding_service.dart        # 🌍 Location services
├── utils/
│   └── formatters.dart               # 🛠️ Helper functions
└── theme/
    └── app_theme.dart                # 🎨 กำหนด ThemeData (สี, ฟอนต์)

functions/                            # ☁️ Firebase Cloud Functions
├── index.js                          # 🧹 Auto cleanup functions
└── package.json                      # 📦 Dependencies
```

## ⚙️ เทคโนโลยีที่ใช้

### 📱 Frontend
- **Flutter 3.x** - Cross-platform mobile framework
- **Dart** - Programming language
- **flutter_map** - OpenStreetMap integration
- **Material Design 3** - UI/UX framework

### ☁️ Backend & Services
- **Firebase Authentication** - Google Sign-In
- **Cloud Firestore** - Real-time database with Security Rules
- **Firebase Storage** - Image storage with WebP compression
- **Firebase Cloud Functions** - Auto cleanup & monitoring
- **OpenStreetMap** - Free map tiles

### 🎨 Custom Components
- **LocationMarker** - Custom location pin with triangle tip
- **EventMarker** - Category-based event markers (simplified design)
- **EventPopup** - Enhanced popup with GPS coordinates display and copy functionality
- **LocationButton** - Reusable location button with loading states

## 🚀 การติดตั้งและใช้งาน

### 1. ข้อกำหนดระบบ
```bash
Flutter SDK: >=3.0.0
Dart SDK: >=2.17.0
Android: API level 21+ (Android 5.0+)
iOS: 11.0+
```

### 2. ติดตั้ง Dependencies
```bash
# Clone repository
git clone https://github.com/krit1989/checkdarn-app.git
cd checkdarn-app

# Install dependencies
flutter pub get
```

### 3. ตั้งค่า Firebase
1. สร้างโปรเจกต์ใน [Firebase Console](https://console.firebase.google.com/)
2. เปิดใช้งาน:
   - ✅ Authentication (Google Sign-In)
   - ✅ Firestore Database
   - ✅ Storage
   - ✅ Cloud Functions
3. ดาวน์โหลดไฟล์ config:
   - `google-services.json` → `android/app/`
   - `GoogleService-Info.plist` → `ios/Runner/`

### 4. ตั้งค่า Google Sign-In
1. ไปที่ [Google Cloud Console](https://console.cloud.google.com/)
2. เปิดใช้งาน Google Sign-In API
3. สร้าง OAuth 2.0 credentials
4. เพิ่ม SHA-1 fingerprint:
```bash
# Get SHA-1 fingerprint
cd android && ./gradlew signingReport
```

### 5. Deploy Firebase Rules & Functions
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Deploy Security Rules
firebase deploy --only firestore:rules

# Deploy Cloud Functions
firebase deploy --only functions
```

### 6. รันแอปพลิเคชัน
```bash
# Debug mode
flutter run

# Release mode
flutter run --release
```

### 7. สร้าง APK/App Bundle
```bash
# APK สำหรับ Android
flutter build apk --release

# App Bundle สำหรับ Google Play Store
flutter build appbundle --release

# iOS สำหรับ App Store
flutter build ios --release
```

## 🔒 ระบบความปลอดภัย

### Firebase Security Rules
```javascript
// Firestore Rules - ป้องกันการเข้าถึงข้อมูลโดยไม่ได้รับอนุญาต
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Reports collection - อ่านได้ทุกคน, เขียนได้เฉพาะผู้ที่ login
    match /reports/{reportId} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    // User stats - เฉพาะเจ้าของข้อมูล
    match /user_stats/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // User limits - จำกัดการใช้งาน
    match /userLimits/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### การจำกัดการใช้งาน
- 📊 **Daily Limits**: 10 โพสต์ต่อวัน
- 🕐 **Auto Cleanup**: ลบข้อมูลเก่าอัตโนมัติ (7 วัน)
- 👤 **User Tracking**: ติดตามสถิติการใช้งาน
- 🔐 **Authentication Required**: ต้องล็อกอินก่อนโพสต์

## 🆕 ฟีเจอร์ใหม่ล่าสุด

### 📍 ระบบพิกัด GPS (NEW!)
- ✨ แสดงพิกัดแม่นยำในป๊อปอัพเหตุการณ์ (6 ตำแหน่งทศนิยม)
- 📋 ปุ่มคัดลอกพิกัดไปยัง Clipboard
- 🔄 รองรับเฉพาะโพสใหม่ที่สร้างหลังจากอัปเดต
- 📐 รูปแบบพิกัด: `latitude, longitude` (เช่น `13.123456, 100.123456`)

### ⚡ TURBO Transaction Mode
- 🚀 บันทึกข้อมูลแบบ atomic operation
- 📊 อัปเดต user statistics พร้อมกับรายงาน
- 🔒 Transaction safety สำหรับความถูกต้องของข้อมูล

### 🧹 Auto Cleanup System
- ⏰ ลบข้อมูลเก่าอัตโนมัติทุก 24 ชั่วโมง
- 🗑️ ลบรูปภาพใน Storage ที่ไม่ใช้แล้ว
- 📊 รายงานสถานะการทำความสะอาด

## 📱 UI/UX Design

### 🎨 Color Scheme
```dart
// Primary Colors
primaryColor: Color(0xFFFF9800)     // Orange
secondaryColor: Color(0xFF4673E5)   // Blue
backgroundColor: Color(0xFFEDF0F7)  // Light Gray

// Category Colors (8 colors for different event types)
checkpoint: Color(0xFF1A237E)       // Navy Blue
accident: Color(0xFFD32F2F)         // Strong Red
fire: Color(0xFFF4511E)             // Deep Orange
flood: Color(0xFF3F51B5)            // Slate Blue
```

### 📐 Component Sizes
- **Radius Slider**: 36x180px ตำแหน่ง right:22
- **Profile Button**: 35px 
- **Event Markers**: Scale 1.365 (ขยายขนาด 36.5%)
- **Location Marker**: Scale 1.68 (ขยายขนาด 68%)
- **Location Button**: 48px

### 🎭 Animations & Interactions
- ✨ Smooth map transitions
- 🔄 Pull-to-refresh animations
- 💫 Loading states
- 🎯 Marker clustering (optional)

## 📊 ฟีเจอร์การวิเคราะห์

### 📈 User Statistics
```javascript
// Cloud Functions - Status Check
exports.getCleanupStatus = functions.https.onRequest(async (req, res) => {
  // ตรวจสอบจำนวนโพสต์ทั้งหมด
  // นับโพสต์เก่าที่ต้องลบ
  // นับจำนวน comments
  // แสดงสถานะระบบ
});
```

### 🧹 Auto Cleanup
```javascript
// ลบข้อมูลเก่าอัตโนมัติ
exports.cleanupOldReports = functions.pubsub
  .schedule('every 24 hours')
  .timeZone('Asia/Bangkok')
  .onRun(async (context) => {
    // ลบโพสต์เก่ากว่า 7 วัน
    // ลบรูปภาพใน Storage
    // ลบ subcollections (comments, likes)
  });
```

## 🔧 การพัฒนาต่อ

### 🎯 Roadmap
- [ ] **Push Notifications** - แจ้งเตือนเหตุการณ์ใกล้เคียง
- [ ] **Offline Mode** - ใช้งานได้แม้ไม่มีอินเทอร์เน็ต
- [ ] **AR Mode** - แสดงเหตุการณ์ผ่าน Augmented Reality
- [ ] **Voice Reporting** - รายงานด้วยเสียง
- [ ] **Machine Learning** - ตรวจสอบข้อมูลเท็จอัตโนมัติ
- [ ] **Multi-language** - รองรับหลายภาษา

### 🐛 Known Issues
- Firebase Composite Index warning (ปกติสำหรับโปรเจคใหม่)
- พิกัด GPS แสดงเฉพาะโพสใหม่เท่านั้น

## 📄 การมีส่วนร่วม

### 🤝 Contributing Guidelines
1. Fork repository
2. สร้าง feature branch (`git checkout -b feature/amazing-feature`)
3. Commit การเปลี่ยนแปลง (`git commit -m 'Add amazing feature'`)
4. Push ไปยัง branch (`git push origin feature/amazing-feature`)
5. สร้าง Pull Request

### 🔍 Code Style
- ใช้ `dart format` สำหรับ formatting
- ปฏิบัติตาม [Flutter Style Guide](https://dart.dev/guides/language/effective-dart/style)
- เขียน comments เป็นภาษาไทยสำหรับ business logic

## 📝 เวอร์ชันและการอัปเดต

### 🏷️ Version 1.2.0 (ปัจจุบัน)
- ✅ GPS Coordinates Display
- ✅ TURBO Transaction Mode
- ✅ Auto Cleanup System
- ✅ Enhanced Security Rules
- ✅ User Statistics Tracking
- ✅ WebP Image Compression
- ✅ Daily Usage Limits

### 📅 Version History
| Version | Date | Features |
|---------|------|----------|
| 1.2.0 | กรกฎาคม 2025 | GPS Coordinates, Auto Cleanup, Enhanced Security |
| 1.1.0 | มิถุนายน 2025 | Real-time Updates, Custom Markers |
| 1.0.0 | พฤษภาคม 2025 | Initial Release |

## 📞 ติดต่อและสนับสนุน

### 🏢 Developer Information
- **Developer**: Kritchapon Prommali
- **Email**: kritchapon1989@gmail.com
- **GitHub**: [@krit1989](https://github.com/krit1989)

### 🆘 การรายงานปัญหา
หากพบปัญหาหรือต้องการเสนอแนะ:
1. สร้าง [Issue](https://github.com/krit1989/checkdarn-app/issues) ใน GitHub
2. ใส่ label ที่เหมาะสม (bug, enhancement, question)
3. อธิบายปัญหาให้ละเอียด พร้อมหลักฐาน (screenshots, logs)

### 📄 License
โปรเจกต์นี้อยู่ภายใต้ [MIT License](LICENSE)

---

<div align="center">

### 🌟 ขอบคุณที่ใช้ CheckDarn!

**Made with ❤️ in Thailand**

[🏠 Home](/) | [📖 Docs](/docs) | [🐛 Issues](https://github.com/krit1989/checkdarn-app/issues) | [💬 Discussions](https://github.com/krit1989/checkdarn-app/discussions)

</div>
