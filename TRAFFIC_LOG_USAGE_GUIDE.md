# วิธีการใช้งาน Traffic Log System สำหรับปฏิบัติตาม พ.ร.บ.คอมพิวเตอร์ 2560

## 🎯 Quick Start Guide

### 1. เพิ่ม Dependencies ใน pubspec.yaml
```yaml
dependencies:
  device_info_plus: ^11.1.0
  package_info_plus: ^8.0.2
  crypto: ^3.0.6
```

### 2. ใช้งาน Traffic Log Service ในแอป

#### ใน main.dart:
```dart
import 'package:check_darn/services/traffic_log_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // เริ่มต้น Traffic Log Service
  await TrafficLogService.initialize();
  
  runApp(MyApp());
}
```

#### ใน map_screen.dart (หรือหน้าหลักของแอป):
```dart
import '../services/traffic_log_service.dart';

class MapScreen extends StatefulWidget {
  @override
  void initState() {
    super.initState();
    
    // Log การเปิดหน้าหลัก
    TrafficLogService.logActivity(TrafficLogService.actionViewReports);
  }
}
```

#### การ Log กิจกรรมต่างๆ:
```dart
// เมื่อผู้ใช้โพสรายงาน
await TrafficLogService.logPostReport(
  category: 'speed_camera',
  location: {'lat': 13.7563, 'lng': 100.5018},
  hasImage: true,
);

// เมื่อผู้ใช้ล็อกอิน
await TrafficLogService.logLogin('google');

// เมื่อผู้ใช้โหวต
await TrafficLogService.logVoteReport(
  reportId: 'report123',
  isUpvote: true,
);
```

### 3. Deploy Cloud Functions

```bash
cd functions/
npm install
firebase deploy --only functions:cleanupTrafficLogs,functions:getTrafficLogsStats,functions:exportTrafficLogs
```

หรือใช้ script ที่เตรียมไว้:
```bash
./deploy_traffic_log_functions.sh
```

### 4. ตั้งค่า Firestore Security Rules

อัปเดต `firestore.rules`:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Traffic Logs - Server-side only
    match /traffic_logs/{logId} {
      allow read, write: if false;
    }
    
    // Audit Logs - Admin only
    match /audit_logs/{auditId} {
      allow read: if isAdmin();
      allow write: if false;
    }
    
    function isAdmin() {
      return request.auth != null &&
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
  }
}
```

### 5. สำหรับ Admin - ดูสถิติการใช้งาน

เพิ่มหน้า Admin Dashboard:
```dart
import 'package:check_darn/screens/traffic_log_admin_screen.dart';

// Navigate to admin screen
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => TrafficLogAdminScreen(),
  ),
);
```

## 📊 ข้อมูลที่เก็บตามกฎหมาย

### ข้อมูลที่ระบบเก็บ:
- ✅ วันเวลาการใช้บริการ
- ✅ กิจกรรมของผู้ใช้ (hash แล้ว)
- ✅ ข้อมูลอุปกรณ์ (hash แล้ว)
- ✅ ตำแหน่งทั่วไป (ระดับเขต/อำเภอ)
- ✅ Session information

### ข้อมูลที่ไม่เก็บ:
- ❌ พิกัดละเอียด
- ❌ IP Address เต็ม
- ❌ User ID จริง
- ❌ ข้อมูลส่วนตัวที่ระบุตัวตนได้

## 🔒 การปกป้องข้อมูลส่วนตัว

### 1. Data Hashing:
```dart
// User ID ถูก hash ด้วย SHA-256
String hashedUserId = sha256.convert(utf8.encode('user_$userId')).toString();
```

### 2. Location Generalization:
```dart
// พิกัดถูกปัดเศษเป็นระดับเขต/อำเภอ
final generalLat = (lat * 100).round() / 100; // ปัด 2 ทศนิยม
```

### 3. Automatic Cleanup:
- ข้อมูลจะถูกลบอัตโนมัติหลัง 90 วัน
- Cloud Function ทำงานทุกวันตี 2 นาฬิกา

## 📋 ตัวอย่างการใช้งาน

### สำหรับ Developer:
```dart
// ใน initState() ของ main screen
TrafficLogService.initialize();

// เมื่อมีการโพสรายงาน
await TrafficLogService.logPostReport(
  category: 'traffic_police',
  location: currentLocation,
  hasImage: widget.selectedImage != null,
  hasDescription: descriptionController.text.isNotEmpty,
);

// เมื่อมีการดูรายงาน
await TrafficLogService.logViewReports(
  location: currentPosition,
  searchRadius: searchRadius,
  resultCount: filteredReports.length,
);
```

### สำหรับ Admin:
```dart
// ดูสถิติการใช้งาน
final stats = await FirebaseFunctions.instance
    .httpsCallable('getTrafficLogsStats')
    .call({
      'startDate': DateTime.now().subtract(Duration(days: 30)).toIso8601String(),
      'endDate': DateTime.now().toIso8601String(),
    });
```

## 💰 Cost Estimation

### Firestore Usage:
- **เขียนข้อมูล**: ~1,000 logs/วัน = 30,000/เดือน
- **เก็บข้อมูล**: 90 วัน × 30KB/log × 1,000 = 2.7GB
- **ต้นทุนประมาณ**: ~$1.08/เดือน

### Cloud Functions:
- **cleanupTrafficLogs**: 1 ครั้ง/วัน = $0.001/เดือน
- **getTrafficLogsStats**: 10 ครั้ง/เดือน = $0.001/เดือน
- **ต้นทุนประมาณ**: ~$0.002/เดือน

### รวมทั้งหมด: ~$1.10/เดือน สำหรับ compliance

## ⚠️ สิ่งที่ต้องระวัง

1. **ไม่เก็บข้อมูลส่วนตัวที่ละเอียด**
2. **ตรวจสอบ Admin role ก่อนเข้าถึงข้อมูล**
3. **Backup Security Rules อย่างสม่ำเสมอ**
4. **Monitor costs เป็นประจำ**
5. **Test Cloud Functions ก่อน deploy**

## 📞 Support

หากมีปัญหาหรือคำถาม:
- 📧 Email: admin@checkdarn.app
- 📱 GitHub Issues: [Repository URL]
- 📋 Documentation: [Docs URL]

---

**หมายเหตุ**: ระบบนี้ออกแบบมาเพื่อปฏิบัติตาม พ.ร.บ.คอมพิวเตอร์ 2560 มาตรา 26 โดยเก็บข้อมูลที่จำเป็นเท่านั้น และปกป้องข้อมูลส่วนตัวของผู้ใช้อย่างเต็มที่
