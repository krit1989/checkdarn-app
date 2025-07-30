# 🔒 ระบบความปลอดภัยแอพ Speed Camera

## 🎯 วัตถุประสงค์

ระบบความปลอดภัยนี้ออกแบบมาเพื่อป้องกันการใช้งานแอพ Speed Camera ในทางที่ผิด โดยเฉพาะ:

1. **การหลีกเลี่ยงกฎหมาย** - ป้องกันการใช้แอพเพื่อหลบหลีกการจับความเร็ว
2. **การทำลายระบบ** - ป้องกันการส่งข้อมูลปลอมหรือใช้ทรัพยากรมากเกินไป
3. **การใช้งานผิดวัตถุประสงค์** - ตรวจจับพฤติกรรมที่ไม่ปกติ

## 🛡️ ระบบป้องกันหลัก

### 1. **Anti-Evasion System - ป้องกันการหลีกเลี่ยงกฎหมาย**

#### การตรวจจับการใช้งานผิดปกติ:
- **การใช้งานต่อเนื่องเกิน 12 ชั่วโมง** → อาจใช้เพื่อหลีกเลี่ยงการจับตลอดเวลา
- **แจ้งเตือนความเร็วสูงเกิน 20 ครั้ง/ชั่วโมง** → อาจใช้เพื่อขับเร็วอย่างต่อเนื่อง
- **ความเร็วเกิน 180 กม./ชม. บ่อยครั้ง** → ใช้งานในลักษณะอันตราย

#### มาตรการตอบโต้:
```dart
// เมื่อตรวจพบการใช้งานผิดปกติ
if (_suspiciousActivityCount >= _maxSuspiciousActivity) {
  _activateSecurityMode(); // จำกัดการทำงานของแอพ
}
```

### 2. **GPS Spoofing Detection - ตรวจจับการปลอมตำแหน่ง**

#### การตรวจสอบ GPS:
- **พิกัดนอกขอบเขตไทย** → GPS ผิดปกติหรือใช้ VPN/Spoof
- **การกระโดดตำแหน่งเกิน 2 กม.** ในเวลาสั้น → GPS spoofing
- **ความเร็วไม่สมเหตุสมผล** → ข้อมูลปลอมจาก GPS faker

```dart
// ตรวจสอบการกระโดดตำแหน่ง
if (distance > LOCATION_JUMP_THRESHOLD && timeDiff < 60) {
  result.addViolation('location_jump', 
      'Impossible location jump: ${distance.toInt()}m in ${timeDiff}s');
}
```

### 3. **Resource Protection - ป้องกันการใช้ทรัพยากรมากเกินไป**

#### การจำกัดการใช้งาน:
- **การโต้ตอบแผนที่: สูงสุด 100 ครั้ง/นาที**
- **เสียงแจ้งเตือน: สูงสุด 60 ครั้ง/นาที**
- **การเคลื่อนไหวแผนที่: สูงสุด 50 ครั้ง/นาที**

#### ประโยชน์:
- ป้องกัน DoS attacks
- ลดการใช้ battery และ CPU
- ป้องกันการใช้งานโดย bot

### 4. **Behavior Analysis - วิเคราะห์พฤติกรรมผู้ใช้**

#### การตรวจจับพฤติกรรมผิดปกติ:
```dart
// คำนวณ pattern score
int patternScore = 0;
if (_highSpeedAlertCount > 10) patternScore += 20;
if (_locationJumpCount > 3) patternScore += 30;
if (sessionDuration > 480) patternScore += 25; // > 8 ชั่วโมง
if (_mapInteractionCount > 50) patternScore += 15;
```

#### เกณฑ์การตัดสิน:
- **Score 0-30**: การใช้งานปกติ
- **Score 31-50**: ต้องสงสัย - จำกัดบางฟีเจอร์
- **Score 51+**: อันตราย - เปิด Security Mode

## ⚡ การทำงานของระบบ

### Security Mode Activation
เมื่อตรวจพบการใช้งานผิดปกติ:

1. **แจ้งเตือนผู้ใช้**:
   ```
   🔒 ระบบตรวจพบการใช้งานผิดปกติ
   ```

2. **จำกัดการทำงาน**:
   - หยุดเสียงแจ้งเตือน Progressive Beep
   - ยกเลิก Badge alerts
   - จำกัดการโต้ตอบแผนที่

3. **Cooldown Period**:
   - ระยะเวลา: 10 นาที
   - กลับสู่การทำงานปกติหลังจากนั้น

### การรีเซ็ตตัวนับ
```dart
// รีเซ็ตทุกชั่วโมง
_hourlyResetTimer = Timer.periodic(const Duration(hours: 1), (timer) {
  _resetHourlyCounters();
});

// รีเซ็ตทุกนาที
_resourceMonitorTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
  SpeedCameraSecurityService.resetMinuteCounters();
});
```

## 📊 Monitoring & Logging

### ข้อมูลที่ติดตาม:
- **Session Duration** - ระยะเวลาการใช้งาน
- **High Speed Events** - จำนวนครั้งที่ขับเร็ว
- **Location Jumps** - การกระโดดตำแหน่ง GPS
- **Resource Usage** - การใช้ทรัพยากรต่างๆ
- **Violation Score** - คะแนนการละเมิด

### Security Status API:
```dart
final status = SpeedCameraSecurityService.getSecurityStatus();
// Returns:
{
  'session_duration_hours': 2,
  'high_speed_alerts': 5,
  'location_jumps': 0,
  'map_interactions': 25,
  'beep_requests': 15,
  'violation_score': 10,
  'is_suspicious': false,
}
```

## 🚨 Security Violations

### ประเภทการละเมิด:

1. **invalid_coordinates** - พิกัดนอกขอบเขต
2. **suspicious_speed** - ความเร็วผิดปกติ
3. **location_jump** - การกระโดดตำแหน่ง
4. **gps_frequency** - ความถี่ GPS ผิดปกติ
5. **excessive_usage** - การใช้งานมากเกินไป
6. **excessive_speed_alerts** - แจ้งเตือนความเร็วบ่อยเกินไป
7. **excessive_location_jumps** - กระโดดตำแหน่งบ่อยเกินไป
8. **excessive_map_interaction** - โต้ตอบแผนที่มากเกินไป

### Severity Levels:
- **WARNING** - การใช้งานที่ต้องสงสัย
- **CRITICAL** - การใช้งานที่อันตราย

## 🎛️ การปรับแต่ง

### Constants ที่สามารถปรับได้:

```dart
// Anti-Evasion
static const int MAX_CONTINUOUS_HOURS = 12;
static const int MAX_HIGH_SPEED_ALERTS = 20;
static const double SUSPICIOUS_SPEED_THRESHOLD = 180.0;

// Resource Protection  
static const int MAX_MAP_INTERACTIONS = 100;
static const int MAX_BEEP_REQUESTS = 60;

// GPS Validation
static const double LOCATION_JUMP_THRESHOLD = 2000.0;
```

## 🔧 การ Debug

### Debug Logs:
```
🔒 Speed Camera Security Service initialized
🚨 High speed event: 185 km/h (Total: 15)
⚠️ Suspicious behavior pattern detected (Score: 35)
🔴 SECURITY MODE ACTIVATED
🟢 Security mode deactivated
```

### การตรวจสอบสถานะ:
```dart
if (kDebugMode) {
  final status = SpeedCameraSecurityService.getSecurityStatus();
  debugPrint('Security Status: $status');
}
```

## ⚖️ ข้อควรระวัง

### False Positives:
- **สัญญาณ GPS อ่อน** → อาจถูกตีความว่าเป็น GPS spoofing
- **การเดินทางในพื้นที่ชานเมือง** → อาจมีความเร็วสูงธรรมดา
- **การใช้งานสำหรับงาน** → เช่น ขับรถส่งของ อาจใช้งานนานต่อเนื่อง

### การจัดการ:
1. **Adjustment Period** - ให้เวลาปรับตัวก่อนเปิด Security Mode
2. **User Feedback** - เก็บข้อมูลพฤติกรรมผู้ใช้จริง
3. **Threshold Tuning** - ปรับค่าเกณฑ์ให้เหมาะสม

## 🎯 วัตถุประสงค์สุดท้าย

ระบบนี้มุ่งหวังให้:
1. **ผู้ใช้ที่ดี** ได้ใช้งานแอพอย่างปกติโดยไม่รับผลกระทบ
2. **ผู้ใช้ที่ไม่หวังดี** ไม่สามารถใช้แอพเพื่อหลีกเลี่ยงกฎหมายได้
3. **ระบบแอพ** ปลอดภัยจากการโจมตีและการใช้งานผิดวัตถุประสงค์

**หลักการสำคัญ**: "ป้องกันการใช้งานในทางที่ผิด โดยไม่กระทบผู้ใช้ที่ดี"
