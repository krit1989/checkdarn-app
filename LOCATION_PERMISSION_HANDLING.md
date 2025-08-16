# 📍 Location Permission Management Guide

## 🔒 **เมื่อไม่มี Location Permission จะเกิดอะไร**

### **1. ไม่สามารถสร้าง Topics ตามพื้นที่:**
```dart
// ❌ จะได้ exception
final locationData = await SmartLocationService.getCurrentLocationData();
// Result: LocationServiceDisabledException

// ❌ Topic subscription ล้มเหลว
await TopicSubscriptionService.subscribeToLocationTopics();
// Result: ได้ topics ทั่วไป แทนที่จะเป็นตามพื้นที่
```

### **2. ได้รับแจ้งเตือนไม่ตรงพื้นที่:**
```dart
// ⚠️ ระบบจะ fallback เป็น general topics
final fallbackTopics = [
  'th_general_thailand',  // แจ้งเตือนทั้งประเทศ
  'th_region_central',    // แจ้งเตือนทั้งภาค
];

// ผลคือ: ได้แจ้งเตือนที่ไม่เกี่ยวข้อง เยอะเกินไป
```

### **3. ไม่สามารถโพสต์ได้:**
```dart
// ❌ การโพสต์ต้องมีพิกัด
await FirebaseService.submitReport(
  category: 'accident',
  description: 'อุบัติเหตุ',
  lat: null,  // ❌ จำเป็นต้องมี
  lng: null,  // ❌ จำเป็นต้องมี
);
// Result: ValidationException - Location required
```

---

## 🛡️ **Permission States & Handling**

### **Android Permission States:**
```dart
enum LocationPermissionStatus {
  denied,           // ยังไม่เคยขอ permission
  deniedForever,    // ปฏิเสธถาวร (ไปตั้งค่าใน Settings)
  whileInUse,       // อนุญาตเฉพาะเปิดแอป
  always,           // อนุญาตตลอดเวลา (ดีที่สุด)
}
```

### **iOS Permission States:**
```dart
enum CLAuthorizationStatus {
  notDetermined,    // ยังไม่เคยขอ
  restricted,       // ระบบห้าม
  denied,           // ปฏิเสธ
  authorizedWhenInUse,  // เฉพาะเปิดแอป
  authorizedAlways,     // ตลอดเวลา
}
```

---

## 🔧 **Smart Permission Handling**

### **Progressive Permission Request:**
```dart
class LocationPermissionManager {
  static Future<bool> requestLocationPermission() async {
    try {
      // 1. ตรวจสอบสถานะปัจจุบัน
      final status = await Permission.location.status;
      
      if (status.isGranted) {
        return true;
      }
      
      // 2. อธิบายเหตุผลก่อนขอ permission
      if (status.isDenied) {
        await _showPermissionRationale();
      }
      
      // 3. ขอ permission
      final result = await Permission.location.request();
      
      if (result.isGranted) {
        return true;
      }
      
      // 4. ถ้าปฏิเสธถาวร แนะนำไปตั้งค่า
      if (result.isPermanentlyDenied) {
        await _showSettingsDialog();
      }
      
      return false;
      
    } catch (e) {
      print('❌ Permission request failed: $e');
      return false;
    }
  }
  
  static Future<void> _showPermissionRationale() async {
    await showDialog(
      context: navigatorKey.currentContext!,
      builder: (context) => AlertDialog(
        title: Text('📍 ต้องการตำแหน่งของคุณ'),
        content: Text(
          'เพื่อ:\n'
          '• ส่งแจ้งเตือนเฉพาะพื้นที่ใกล้คุณ\n'
          '• ลดแจ้งเตือนที่ไม่เกี่ยวข้อง\n'
          '• โพสต์เหตุการณ์พร้อมตำแหน่ง'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('อนุญาต'),
          ),
        ],
      ),
    );
  }
  
  static Future<void> _showSettingsDialog() async {
    await showDialog(
      context: navigatorKey.currentContext!,
      builder: (context) => AlertDialog(
        title: Text('⚙️ เปิด Location Permission'),
        content: Text(
          'กรุณาเปิด Location Permission ใน Settings\n'
          'เพื่อใช้งานฟีเจอร์แจ้งเตือนตามพื้นที่'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: Text('เปิด Settings'),
          ),
        ],
      ),
    );
  }
}
```

---

## 🎯 **Fallback Strategies เมื่อไม่มี Location**

### **1. Manual Location Selection:**
```dart
class ManualLocationSelector extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('📍 เลือกจังหวัดของคุณ'),
        DropdownButton<String>(
          items: ThaiProvinces.all.map((province) => 
            DropdownMenuItem(
              value: province,
              child: Text(province),
            ),
          ).toList(),
          onChanged: (province) async {
            if (province != null) {
              await _subscribeToProvinceTopics(province);
            }
          },
        ),
      ],
    );
  }
  
  Future<void> _subscribeToProvinceTopics(String province) async {
    final topics = [
      'th_province_${_normalizeProvinceName(province)}',
      'th_region_${_getRegionFromProvince(province)}',
    ];
    
    for (final topic in topics) {
      await FirebaseMessaging.instance.subscribeToTopic(topic);
    }
    
    print('✅ Subscribed to $province topics manually');
  }
}
```

### **2. IP-based Location Detection:**
```dart
class IPLocationService {
  static Future<Map<String, dynamic>?> getLocationFromIP() async {
    try {
      // ใช้ IP Geolocation API (ฟรี)
      final response = await http.get(
        Uri.parse('https://api.ipgeolocation.io/ipgeo?apiKey=free'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        return {
          'province': _mapCityToProvince(data['city']),
          'lat': double.parse(data['latitude']),
          'lng': double.parse(data['longitude']),
          'source': 'ip_geolocation',
          'accuracy': 'city_level', // ความแม่นยำระดับเมือง
        };
      }
      
    } catch (e) {
      print('❌ IP location failed: $e');
    }
    
    return null;
  }
  
  static String? _mapCityToProvince(String city) {
    const cityToProvince = {
      'Bangkok': 'กรุงเทพมหานคร',
      'Chiang Mai': 'เชียงใหม่',
      'Phuket': 'ภูเก็ต',
      'Pattaya': 'ชลบุรี',
      // ... เพิ่มเมืองอื่นๆ
    };
    
    return cityToProvince[city];
  }
}
```

### **3. Saved Preferences:**
```dart
class LocationPreferences {
  static Future<void> saveUserLocation(String province) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_province', province);
    await prefs.setInt('location_saved_at', DateTime.now().millisecondsSinceEpoch);
  }
  
  static Future<String?> getSavedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final province = prefs.getString('user_province');
    final savedAt = prefs.getInt('location_saved_at') ?? 0;
    
    // ถือว่า preferences valid 30 วัน
    final isValid = DateTime.now().millisecondsSinceEpoch - savedAt < 2592000000;
    
    return isValid ? province : null;
  }
}
```

---

## 🔄 **Background Location Updates**

### **เมื่อมี Always Permission:**
```dart
class BackgroundLocationService {
  static Future<void> startBackgroundTracking() async {
    final permission = await Permission.locationAlways.status;
    
    if (!permission.isGranted) {
      print('⚠️ Always permission required for background tracking');
      return;
    }
    
    // ตั้งค่า background location updates
    await Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.low, // ประหยัดแบต
        distanceFilter: 5000, // อัพเดทเมื่อเคลื่อนที่ 5 กม.
      ),
    ).listen((position) async {
      print('📍 Background location update: ${position.latitude}, ${position.longitude}');
      
      // อัพเดท topics เมื่อเปลี่ยนพื้นที่
      await TopicSubscriptionService.updateTopicsIfLocationChanged();
    });
  }
}
```

---

## ⚠️ **User Experience Considerations**

### **1. Permission Timing:**
```dart
// ❌ ไม่ดี - ขอ permission ทันทีเมื่อเปิดแอป
void initState() {
  super.initState();
  LocationPermissionManager.requestLocationPermission(); // รบกวนผู้ใช้
}

// ✅ ดี - ขอเมื่อจำเป็น
void _onPostButtonPressed() async {
  final hasPermission = await LocationPermissionManager.requestLocationPermission();
  
  if (hasPermission) {
    _showPostDialog();
  } else {
    _showManualLocationDialog();
  }
}
```

### **2. Progressive Disclosure:**
```dart
class OnboardingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PageView(
      children: [
        _buildWelcomeScreen(),
        _buildLocationBenefitsScreen(), // อธิบายประโยชน์ก่อน
        _buildPermissionRequestScreen(), // ขอ permission ทีหลัง
      ],
    );
  }
}
```

### **3. Graceful Degradation:**
```dart
class NotificationSettings extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SwitchListTile(
          title: Text('🎯 แจ้งเตือนตามพื้นที่'),
          subtitle: Text('ต้องการ Location Permission'),
          value: _hasLocationPermission,
          onChanged: _onLocationToggled,
        ),
        
        if (!_hasLocationPermission)
          ListTile(
            title: Text('📍 เลือกจังหวัดด้วยตนเอง'),
            subtitle: Text('ใช้งานได้โดยไม่ต้องแชร์ตำแหน่ง'),
            onTap: _showManualLocationSelector,
          ),
      ],
    );
  }
}
```
