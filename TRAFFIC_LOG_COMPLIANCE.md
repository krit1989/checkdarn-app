# การปฏิบัติตาม พ.ร.บ.คอมพิวเตอร์ 2560 มาตรา 26

## ข้อมูลที่ต้องเก็บตามกฎหมาย (Traffic Log)

### 1. ข้อมูลที่ต้องเก็บอย่างน้อย 90 วัน:
- **วันเวลา** ที่มีการใช้บริการ
- **หมายเลข IP Address** ของผู้ใช้
- **ข้อมูลการล็อกอิน/ออก** 
- **การเข้าถึงระบบ** และกิจกรรมหลัก
- **ข้อมูลการส่งข้อความ/รูปภาพ** (metadata)

### 2. สำหรับแอป CheckDarn (Speed Camera App)

#### ข้อมูลที่ควรเก็บ:
```javascript
// Traffic Log Structure
{
  timestamp: "2025-01-15T10:30:00Z",
  user_id: "user_xxx_masked",
  ip_address: "xxx.xxx.xxx.xxx",
  action: "post_camera_report|view_reports|login|logout",
  location: {
    lat: 13.7563,
    lng: 100.5018,
    accuracy: "city_level" // ไม่เก็บพิกัดละเอียด
  },
  device_info: {
    platform: "android|ios",
    app_version: "1.0.0"
  },
  session_id: "session_xxx"
}
```

## แนวทางการดำเนินการ

### Option 1: ใช้ Firebase + Cloud Functions
```javascript
// cloud_functions/traffic_log.js
exports.logTrafficData = functions.https.onCall(async (data, context) => {
  const logEntry = {
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    user_id: context.auth?.uid || 'anonymous',
    ip_address: context.rawRequest.ip,
    action: data.action,
    location: data.location,
    device_info: data.device_info,
    session_id: data.session_id
  };
  
  // เก็บใน collection แยก
  await admin.firestore()
    .collection('traffic_logs')
    .add(logEntry);
});
```

### Option 2: ใช้ Google Cloud Logging
```dart
// lib/services/traffic_log_service.dart
class TrafficLogService {
  static Future<void> logUserActivity({
    required String action,
    LatLng? location,
    Map<String, dynamic>? metadata,
  }) async {
    final logEntry = {
      'timestamp': FieldValue.serverTimestamp(),
      'user_id': AuthService.getCurrentUserId(),
      'action': action,
      'location': location != null ? {
        'lat': location.latitude,
        'lng': location.longitude,
      } : null,
      'device_info': {
        'platform': Platform.isAndroid ? 'android' : 'ios',
        'app_version': await _getAppVersion(),
      },
      'session_id': await _getSessionId(),
      'metadata': metadata,
    };
    
    await FirebaseFirestore.instance
        .collection('traffic_logs')
        .add(logEntry);
  }
}
```

### Option 3: ใช้บริการภายนอก (Recommended)
```yaml
# pubspec.yaml
dependencies:
  logging: ^1.1.1
  http: ^0.13.5
```

```dart
// lib/services/compliance_log_service.dart
class ComplianceLogService {
  static const String _logEndpoint = 'https://your-compliance-server.com/api/logs';
  
  static Future<void> logActivity(String action) async {
    final logData = {
      'timestamp': DateTime.now().toIso8601String(),
      'action': action,
      'app_id': 'checkdarn_app',
      // ไม่ส่งข้อมูลส่วนตัวที่ละเอียด
    };
    
    try {
      await http.post(
        Uri.parse(_logEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(logData),
      );
    } catch (e) {
      print('Log upload failed: $e');
    }
  }
}
```

## การตั้งค่า Auto-Delete หลัง 90 วัน

### Firebase Rules สำหรับ Traffic Logs:
```javascript
// firestore.rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Traffic logs - อ่านได้เฉพาะ admin
    match /traffic_logs/{document} {
      allow read, write: if false; // ไม่ให้ client access โดยตรง
    }
  }
}
```

### Cloud Function สำหรับ Auto-Delete:
```javascript
// functions/cleanup_logs.js
exports.cleanupOldLogs = functions.pubsub
  .schedule('0 2 * * *') // ทุกวันตี 2
  .timeZone('Asia/Bangkok')
  .onRun(async (context) => {
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - 90);
    
    const oldLogs = await admin.firestore()
      .collection('traffic_logs')
      .where('timestamp', '<', cutoffDate)
      .limit(500)
      .get();
    
    const batch = admin.firestore().batch();
    oldLogs.docs.forEach(doc => batch.delete(doc.ref));
    
    await batch.commit();
    console.log(`Deleted ${oldLogs.size} old log entries`);
  });
```

## ข้อแนะนำเพิ่มเติม

### 1. ปกป้องข้อมูลส่วนตัว:
- **ไม่เก็บพิกัดละเอียด** - ใช้ระดับเขต/อำเภอ
- **Mask IP Address** - เก็บเฉพาะ 3 octet แรก
- **Hash User ID** - ใช้ one-way hash

### 2. การจัดเก็บ:
- ใช้ **Cloud Storage** สำหรับ long-term storage
- **Compress logs** เป็น JSON files รายเดือน
- **Encrypt** ข้อมูลก่อนเก็บ

### 3. การควบคุมการเข้าถึง:
- เฉพาะ **Admin role** เท่านั้น
- ใช้ **Audit trail** สำหรับการเข้าถึง logs
- มี **Legal process** สำหรับการขอข้อมูล

## ตัวอย่างการใช้งานในแอป

```dart
// เมื่อผู้ใช้โพสรายงานกล้อง
await TrafficLogService.logUserActivity(
  action: 'post_camera_report',
  location: currentLocation,
  metadata: {
    'category': 'speed_camera',
    'has_image': imageUrl != null,
  },
);

// เมื่อผู้ใช้ล็อกอิน
await TrafficLogService.logUserActivity(
  action: 'user_login',
  metadata: {
    'login_method': 'google',
  },
);
```

## Cost Analysis

### Firebase Firestore:
- **Writes**: ~1,000 logs/day = 30,000/month = $0.54/month
- **Storage**: 90 days × 30KB/log × 1,000 = 2.7GB = $0.54/month
- **รวม**: ~$1.08/month สำหรับ compliance logging

### แนะนำ: เริ่มต้นด้วย Firebase Firestore + Cloud Functions
- ง่ายต่อการ implement
- ควบคุมต้นทุนได้
- สามารถขยายระบบได้ในอนาคต

คุณต้องการให้ฉันช่วย implement ส่วนไหนก่อนครับ?
