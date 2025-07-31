# Smart Protection System - คู่มือการใช้งาน

## ระบบ Smart Protection คือ?
ระบบรักษาความปลอดภัยแบบอัจฉริยะที่ปรับระดับการป้องกันตามความเสี่ยงของหน้า

## การแบ่งระดับความเสี่ยง

### 🔴 HIGH RISK - ป้องกันสูงสุด
- **Screen**: Login, SignUp, Payment, Profile Edit
- **Features**: GPS Anti-Spoofing, Rate Limiting, Device Fingerprinting, Human Verification
- **Use Case**: การล็อกอิน, การชำระเงิน, การแก้ไขข้อมูลสำคัญ

### 🟡 MEDIUM RISK - ป้องกันปานกลาง  
- **Screen**: Map, Speed Camera, Settings
- **Features**: Basic Rate Limiting, Location Validation, API Abuse Protection
- **Use Case**: การใช้แผนที่, การตั้งค่า, การใช้ข้อมูล GPS

### 🟢 LOW RISK - ป้องกันพื้นฐาน
- **Screen**: FAQ, About, Terms of Service, Profile View
- **Features**: Basic Logging, Simple Rate Limiting
- **Use Case**: การดูข้อมูล, การอ่านเนื้อหา

## ตัวอย่างการใช้งาน

### 1. สำหรับ Login Screen (HIGH RISK)
```dart
// ในไฟล์ login_screen.dart
class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _smartSecurity = SmartSecurityService();

  @override
  void initState() {
    super.initState();
    _smartSecurity.initializeSecurity(SecurityLevel.high);
  }

  Future<void> _handleLogin() async {
    // ตรวจสอบความปลอดภัยก่อนล็อกอิน
    final securityCheck = await _smartSecurity.validateAction(
      'login_attempt', 
      context,
      requireHumanVerification: true,
      checkDeviceFingerprint: true,
      validateGPS: true
    );

    if (!securityCheck.isValid) {
      // แสดง error หรือ challenge
      if (securityCheck.requiresChallenge) {
        await _smartSecurity.showHumanVerificationChallenge(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(securityCheck.reason))
        );
      }
      return;
    }

    // ดำเนินการล็อกอินปกติ
    await performLogin();
  }
}
```

### 2. สำหรับ Map Screen (MEDIUM RISK)
```dart
// ในไฟล์ map_screen.dart - เพิ่มเติมจากที่มีอยู่
class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _smartSecurity = SmartSecurityService();

  @override
  void initState() {
    super.initState();
    _smartSecurity.initializeSecurity(SecurityLevel.medium);
  }

  void _onMapTap(LatLng position) async {
    // ตรวจสอบการคลิกแผนที่
    final securityCheck = await _smartSecurity.validateAction(
      'map_tap', 
      context,
      additionalData: {
        'lat': position.latitude,
        'lng': position.longitude
      }
    );

    if (!securityCheck.isValid) {
      print('Suspicious map interaction detected: ${securityCheck.reason}');
      return;
    }

    // ดำเนินการปกติ
    await handleMapTap(position);
  }

  void _onCameraMove(CameraPosition position) async {
    // ตรวจสอบการเลื่อนแผนที่
    final securityCheck = await _smartSecurity.validateAction(
      'camera_move', 
      context,
      additionalData: {
        'zoom': position.zoom,
        'bearing': position.bearing
      }
    );

    if (!securityCheck.isValid && securityCheck.shouldBlock) {
      // หยุดการเลื่อนถ้าสงสัยว่าเป็น Bot
      return;
    }

    // ดำเนินการปกติ
    handleCameraMove(position);
  }
}
```

### 3. สำหรับ FAQ Screen (LOW RISK)
```dart
// ในไฟล์ faq_screen.dart
class FAQScreen extends StatefulWidget {
  @override
  _FAQScreenState createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  final _smartSecurity = SmartSecurityService();

  @override
  void initState() {
    super.initState();
    _smartSecurity.initializeSecurity(SecurityLevel.low);
  }

  void _onFAQTap(int faqId) async {
    // ตรวจสอบแบบพื้นฐาน
    final securityCheck = await _smartSecurity.validateAction(
      'faq_view', 
      context,
      additionalData: {'faq_id': faqId}
    );

    // FAQ ไม่จำเป็นต้องบล็อก แค่ log ไว้
    if (!securityCheck.isValid) {
      print('Unusual FAQ access pattern: ${securityCheck.reason}');
    }

    // ดำเนินการปกติ
    showFAQDetail(faqId);
  }
}
```

## การติดตั้งใน Project ที่มีอยู่

### 1. เพิ่ม SmartSecurityService ใน existing screens:
```dart
// เพิ่มในทุก Screen ที่ต้องการ
final _smartSecurity = SmartSecurityService();

@override
void initState() {
  super.initState();
  // เลือก SecurityLevel ตามความเสี่ยง
  _smartSecurity.initializeSecurity(SecurityLevel.medium);
}
```

### 2. แทนที่ SecurityService เดิม:
```dart
// จาก
await SecurityService.validateSpeedCameraAction(context);

// เป็น  
await _smartSecurity.validateAction('speed_camera_check', context);
```

### 3. เพิ่ม Human Verification สำหรับ High Risk:
```dart
if (securityLevel == SecurityLevel.high && !securityCheck.isValid) {
  await _smartSecurity.showHumanVerificationChallenge(context);
}
```

## ประโยชน์ของ Smart Protection

1. **ประหยัดทรัพยากร**: ใช้การป้องกันตามความจำเป็น
2. **UX ดีขึ้น**: ไม่รบกวนผู้ใช้งานปกติ  
3. **ความปลอดภัยสูง**: ป้องกันเฉพาะจุดสำคัญ
4. **ง่ายต่อการดูแล**: จัดการรวมศูนย์
5. **ปรับแต่งได้**: เปลี่ยน Risk Level ได้ตามต้องการ

## สรุป
Smart Protection System ช่วยให้แอปมีความปลอดภัยที่เหมาะสมกับแต่ละหน้า โดยไม่ส่งผลกระทบต่อประสบการณ์ผู้ใช้
