# 🌐 Internet Connection & Topic Sync Guide

## 📱 **เมื่อไม่มีอินเทอร์เน็ต จะเกิดอะไร**

### **1. Topic Subscription ไม่อัพเดท:**
```dart
// ❌ ไม่สามารถ subscribe topics ใหม่
await TopicSubscriptionService.subscribeToLocationTopics();
// Result: Exception - No internet connection

// ✅ แต่ topics เก่าที่ subscribe ไว้แล้ว ยังใช้ได้
// เพราะ FCM เก็บ subscription ไว้ server-side
```

### **2. Location Update ล่าช้า:**
```dart
// ❌ ไม่สามารถดึง location data ใหม่
final locationData = await SmartLocationService.getCurrentLocationData();
// Result: ใช้ cached location แทน

// ⚠️ ถ้า cache หมดอายุ = ไม่ได้รับแจ้งเตือนพื้นที่ใหม่
```

### **3. Notification ยังรับได้:**
```dart
// ✅ FCM ทำงานแบบ offline-first
// Notification จะส่งมาเมื่อมีอินเทอร์เน็ตกลับมา
// Google มี notification queue บน server
```

---

## 🔄 **Auto Retry & Recovery System**

### **Built-in Retry Logic:**
```dart
class TopicSubscriptionService {
  static Future<void> _retryTopicSync() async {
    int attempts = 0;
    const maxAttempts = 3;
    
    while (attempts < maxAttempts) {
      try {
        await subscribeToLocationTopics();
        print('✅ Topic sync successful');
        return;
        
      } catch (e) {
        attempts++;
        print('⚠️ Topic sync failed, attempt $attempts/$maxAttempts');
        
        if (attempts < maxAttempts) {
          await Future.delayed(Duration(seconds: 30 * attempts));
        }
      }
    }
    
    print('❌ Topic sync failed after $maxAttempts attempts');
    // จะลองใหม่เมื่อมี internet กลับมา
  }
}
```

### **Internet Connection Listener:**
```dart
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkManager {
  static void startNetworkListener() {
    Connectivity().onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        print('🌐 Internet connection restored');
        
        // Auto sync topics เมื่อมี internet กลับมา
        TopicSubscriptionService.updateTopicsIfLocationChanged();
        
        // Sync pending notifications
        NotificationService.syncPendingNotifications();
      } else {
        print('📴 No internet connection');
      }
    });
  }
}
```

---

## 💾 **Offline Caching Strategy**

### **Location Data Cache:**
```dart
class SmartLocationService {
  static const Duration _cacheValidTime = Duration(hours: 6);
  
  static Future<Map<String, dynamic>> getCurrentLocationData() async {
    try {
      // 1. ลองดึงข้อมูลใหม่
      final fresh = await _getFreshLocationData();
      await _saveToCache(fresh);
      return fresh;
      
    } catch (e) {
      print('⚠️ Cannot get fresh location, using cache');
      
      // 2. ใช้ cache ถ้าไม่หมดอายุ
      final cached = await _getCachedLocationData();
      if (cached != null && !_isCacheExpired(cached)) {
        return cached;
      }
      
      // 3. ใช้ last known location
      return await _getLastKnownLocation();
    }
  }
}
```

### **Topic Cache:**
```dart
class TopicSubscriptionService {
  static Future<void> _saveCachedTopics(List<String> topics) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('cached_topics', topics);
    await prefs.setInt('cache_timestamp', DateTime.now().millisecondsSinceEpoch);
  }
  
  static Future<List<String>> _getCachedTopics() async {
    final prefs = await SharedPreferences.getInstance();
    final topics = prefs.getStringList('cached_topics') ?? [];
    final timestamp = prefs.getInt('cache_timestamp') ?? 0;
    
    // Cache valid สำหรับ 24 ชั่วโมง
    if (DateTime.now().millisecondsSinceEpoch - timestamp < 86400000) {
      return topics;
    }
    
    return [];
  }
}
```

---

## 🔔 **Notification Behavior During Offline**

### **FCM Offline Handling:**
```
1. 📤 Server ส่ง notification
2. 📴 Device offline
3. 💾 Google FCM servers เก็บ notification ไว้
4. ⏰ รอ device กลับมา online (สูงสุด 4 สัปดาห์)
5. 📱 ส่ง notification ทันทีเมื่อ online
```

### **Topic Subscription Durability:**
```dart
// ✅ Topic subscriptions คงอยู่แม้ไม่มี internet
// เพราะเก็บไว้ที่ Firebase servers

// เมื่อกลับมา online:
// - ได้รับ notifications ที่ค้างอยู่
// - Topic subscriptions ยังใช้งานได้
// - ไม่ต้อง re-subscribe
```

---

## 🛠️ **Best Practices**

### **1. Graceful Degradation:**
```dart
try {
  await TopicSubscriptionService.subscribeToLocationTopics();
} catch (e) {
  print('⚠️ Using offline mode with cached topics');
  // แอปยังใช้งานได้แต่อาจได้แจ้งเตือนช้า
}
```

### **2. User Feedback:**
```dart
class NetworkStatusWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ConnectivityResult>(
      stream: Connectivity().onConnectivityChanged,
      builder: (context, snapshot) {
        if (snapshot.data == ConnectivityResult.none) {
          return Container(
            color: Colors.orange,
            child: Text('📴 โหมดออฟไลน์ - แจ้งเตือนอาจช้า'),
          );
        }
        return SizedBox.shrink();
      },
    );
  }
}
```

### **3. Auto Recovery:**
```dart
class AppLifecycleManager extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // เมื่อเปิดแอปใหม่ ตรวจสอบ internet และ sync
      _checkAndSyncTopics();
    }
  }
  
  void _checkAndSyncTopics() async {
    final hasInternet = await _hasInternetConnection();
    if (hasInternet) {
      TopicSubscriptionService.updateTopicsIfLocationChanged();
    }
  }
}
```
