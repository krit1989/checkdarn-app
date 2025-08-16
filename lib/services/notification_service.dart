import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';
import 'smart_location_service.dart';

/// 🔔 **Notification Service**
/// ระบบแจ้งเตือน Push Notification ด้วย Firebase Cloud Messaging (FCM)
///
/// **ฟีเจอร์หลัก:**
/// - รับ FCM Token และส่งไปเก็บใน Firestore
/// - รับการแจ้งเตือนเมื่อแอพเปิดอยู่ (Foreground)
/// - รับการแจ้งเตือนเมื่อแอพปิดอยู่ (Background/Terminated)
/// - จัดการการแสดงผลการแจ้งเตือนภายในแอพ
/// - ระบบ Retry สำหรับ Token หมดอายุ
/// - Queue System สำหรับข้อความที่ส่งไม่สำเร็จ
///
/// **กฎการแจ้งเตือน:**
/// 1. เวลาที่มีโพสใหม่ ห้ามเตือนคนโพส
/// 2. เวลาที่มีคนคอมเม้น ให้เด้งแจ้งเตือนคนโพส
///
/// **ระบบ Retry:**
/// - พยายามรีเฟรช Token สูงสุด 3 ครั้ง
/// - ช่วงเวลาการ Retry: 1, 5, 15 นาที
/// - Queue System สำหรับข้อความที่ค้างอยู่
class NotificationService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Global key สำหรับเข้าถึง ScaffoldMessenger ได้จากทุกที่
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  // Stream Controller สำหรับส่งข้อมูล notification ไปยัง UI
  static final StreamController<RemoteMessage> _messageStreamController =
      StreamController<RemoteMessage>.broadcast();

  /// Stream สำหรับฟัง notification ที่เข้ามาใหม่
  static Stream<RemoteMessage> get onMessageReceived =>
      _messageStreamController.stream;

  // ตัวแปรเก็บสถานะ
  static bool _isInitialized = false;
  static String? _cachedToken;

  // 🔄 **Retry System สำหรับ Token หมดอายุ**
  static final List<Map<String, dynamic>> _retryQueue = [];
  static bool _isRefreshing = false;
  static int _retryAttempts = 0;
  static const int _maxRetryAttempts = 3;
  static const List<int> _retryDelayMinutes = [1, 5, 15]; // นาที
  static Timer? _retryTimer;

  /// 🚀 **เริ่มต้นระบบ Notification**
  /// เรียกใช้ครั้งเดียวตอน app เริ่มต้น
  static Future<void> initialize() async {
    if (_isInitialized) {
      print('🔔 NotificationService: Already initialized');
      return;
    }

    try {
      print('🔔 NotificationService: Starting initialization...');

      // ขอสิทธิ์การแจ้งเตือน
      await _requestPermission();

      // ✅ **ตั้งค่าให้แสดง notification ใน foreground**
      await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true, // แสดง alert
        badge: true, // แสดง badge
        sound: true, // เล่นเสียง
      );

      // ตั้งค่า foreground message handler
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // ตั้งค่า background message handler
      FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

      // ตั้งค่า notification tap handler (เมื่อผู้ใช้แตะการแจ้งเตือน)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // ตรวจสอบว่ามี notification ที่เปิดแอพไหม (จาก terminated state)
      final RemoteMessage? initialMessage =
          await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      // ดึงและบันทึก FCM token
      await _getFCMToken();

      // ตั้งค่าการตรวจสอบ token อัตโนมัติ
      await _checkAndRefreshToken();

      // ฟัง token refresh
      _firebaseMessaging.onTokenRefresh.listen(_handleTokenRefresh);

      _isInitialized = true;
      print('✅ NotificationService: Initialization completed');
    } catch (e, stackTrace) {
      print('❌ NotificationService: Initialization failed: $e');
      print('Stack trace: $stackTrace');
    }
  }

  /// 📜 **ขอสิทธิ์การแจ้งเตือน**
  static Future<void> _requestPermission() async {
    try {
      print('🔔 NotificationService: Requesting notification permission...');

      final NotificationSettings settings =
          await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      print(
          '🔔 NotificationService: Permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ NotificationService: Notification permission granted');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        print(
            '⚠️ NotificationService: Notification permission granted provisionally');
      } else {
        print('❌ NotificationService: Notification permission denied');
      }
    } catch (e) {
      print('❌ NotificationService: Error requesting permission: $e');
    }
  }

  /// 🔑 **ดึง FCM Token และบันทึกลงฐานข้อมูล**
  static Future<String?> _getFCMToken() async {
    try {
      print('🔔 NotificationService: Getting FCM token...');

      final String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        print(
            '✅ NotificationService: FCM token received: ${token.substring(0, 20)}...');
        _cachedToken = token;

        // บันทึก token ลง Firestore (ถ้าผู้ใช้ล็อกอินแล้ว)
        await _saveTokenToFirestore(token);

        // บันทึก token ลง SharedPreferences สำหรับใช้ภายหลัง
        await _saveTokenLocally(token);

        return token;
      } else {
        print('❌ NotificationService: Failed to get FCM token');
        return null;
      }
    } catch (e) {
      print('❌ NotificationService: Error getting FCM token: $e');
      return null;
    }
  }

  /// 💾 **บันทึก Token ลง Firestore พร้อมข้อมูลตำแหน่ง**
  static Future<void> _saveTokenToFirestore(String token) async {
    try {
      final String? userId = AuthService.currentUser?.uid;

      if (userId == null) {
        print(
            '⚠️ NotificationService: User not logged in, saving token locally only');
        return;
      }

      print(
          '🔔 NotificationService: Saving token to Firestore for user: $userId');

      // บันทึกใน collection 'users' -> document userId -> field 'fcmToken' (เก่า)
      await _firestore.collection('users').doc(userId).set({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
        'platform': Platform.isIOS ? 'ios' : 'android',
      }, SetOptions(merge: true));

      // 🌍 อัปเดตตำแหน่งและดึงข้อมูลตำแหน่งปัจจุบันสำหรับ Smart Geographic Targeting
      await SmartLocationService.updateUserLocation(forceUpdate: true);
      Map<String, dynamic> locationData =
          await SmartLocationService.getCurrentLocationData();

      // ✅ บันทึกใน collection 'user_tokens' สำหรับ Cloud Functions (ใหม่) + ตำแหน่ง
      await _firestore.collection('user_tokens').doc(userId).set({
        'userId': userId, // ⚠️ สำคัญ! ต้องเซ็ต userId field
        'tokens': [token], // เก็บเป็น array เพื่อรองรับหลาย device
        'lastUpdated': FieldValue.serverTimestamp(),
        'platform': Platform.isIOS ? 'ios' : 'android',
        'isActive': true,
        // 🌍 Smart Location Data สำหรับ Geographic Targeting
        'lastKnownLat': locationData['lat'],
        'lastKnownLng': locationData['lng'],
        'lastKnownProvince': locationData['province'],
        'lastKnownDistrict': locationData['district'],
        'lastKnownSubDistrict': locationData['subDistrict'],
        'lastLocationUpdate': FieldValue.serverTimestamp(),
        'locationAccuracy': locationData['accuracy'],
      }, SetOptions(merge: true));

      print(
          '✅ NotificationService: Token and location saved to both collections successfully');
      print(
          '🌍 Location data: ${locationData['province']}, ${locationData['district']}');
    } catch (e) {
      print('❌ NotificationService: Error saving token to Firestore: $e');
    }
  }

  /// 📱 **บันทึก Token ลง SharedPreferences**
  static Future<void> _saveTokenLocally(String token) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);
      print('✅ NotificationService: Token saved locally');
    } catch (e) {
      print('❌ NotificationService: Error saving token locally: $e');
    }
  }

  /// 🔄 **จัดการเมื่อ Token เปลี่ยน (ใหม่)**
  static Future<void> _handleTokenRefresh(String newToken) async {
    try {
      print(
          '🔔 NotificationService: Token refreshed: ${newToken.substring(0, 20)}...');
      _cachedToken = newToken;

      await _saveTokenToFirestore(newToken);
      await _saveTokenLocally(newToken);

      // ประมวลผลข้อความที่ค้างใน retry queue
      await _processRetryQueue();

      // รีเซ็ต retry attempts
      _retryAttempts = 0;
      _isRefreshing = false;
    } catch (e) {
      print('❌ NotificationService: Error handling token refresh: $e');
    }
  }

  /// 🔍 **ตรวจสอบและรีเฟรช Token**
  static Future<void> _checkAndRefreshToken() async {
    try {
      print('🔔 NotificationService: Checking token validity...');

      final String? currentToken = await _firebaseMessaging.getToken();
      if (currentToken == null) {
        print(
            '⚠️ NotificationService: No token available, starting retry process');
        await _retryTokenRefresh();
      } else {
        print('✅ NotificationService: Token is valid');
        _cachedToken = currentToken;
        await _saveTokenToFirestore(currentToken);
      }
    } catch (e) {
      print('❌ NotificationService: Error checking token: $e');
      await _retryTokenRefresh();
    }
  }

  /// 🔄 **พยายามรีเฟรช Token อีกครั้ง**
  static Future<void> _retryTokenRefresh() async {
    if (_isRefreshing) {
      print('🔔 NotificationService: Token refresh already in progress');
      return;
    }

    if (_retryAttempts >= _maxRetryAttempts) {
      print('❌ NotificationService: Max retry attempts reached');
      return;
    }

    _isRefreshing = true;
    _retryAttempts++;

    try {
      print(
          '🔔 NotificationService: Retry attempt $_retryAttempts/$_maxRetryAttempts');

      // รอตามระยะเวลาที่กำหนด
      final delayMinutes = _retryDelayMinutes[_retryAttempts - 1];
      print(
          '🔔 NotificationService: Waiting $delayMinutes minutes before retry...');

      _retryTimer?.cancel();
      _retryTimer = Timer(Duration(minutes: delayMinutes), () async {
        try {
          // ลบ token เก่าและขอใหม่
          await _firebaseMessaging.deleteToken();
          await Future.delayed(const Duration(seconds: 2));

          final String? newToken = await _firebaseMessaging.getToken();
          if (newToken != null) {
            print('✅ NotificationService: Successfully got new token on retry');
            _cachedToken = newToken;
            await _saveTokenToFirestore(newToken);
            await _saveTokenLocally(newToken);

            // ประมวลผลข้อความที่ค้างอยู่
            await _processRetryQueue();

            // รีเซ็ต retry attempts
            _retryAttempts = 0;
            _isRefreshing = false;
          } else {
            print('❌ NotificationService: Failed to get token on retry');
            // พยายามอีกครั้งถ้ายังไม่ครบจำนวน
            if (_retryAttempts < _maxRetryAttempts) {
              _isRefreshing = false;
              await _retryTokenRefresh();
            }
          }
        } catch (e) {
          print('❌ NotificationService: Error in retry process: $e');
          _isRefreshing = false;

          // พยายามอีกครั้งถ้ายังไม่ครบจำนวน
          if (_retryAttempts < _maxRetryAttempts) {
            await _retryTokenRefresh();
          }
        }
      });
    } catch (e) {
      print('❌ NotificationService: Error setting up retry: $e');
      _isRefreshing = false;
    }
  }

  /// 📤 **ประมวลผล Retry Queue**
  static Future<void> _processRetryQueue() async {
    try {
      if (_retryQueue.isEmpty) {
        print('🔔 NotificationService: Retry queue is empty');
        return;
      }

      print(
          '🔔 NotificationService: Processing ${_retryQueue.length} items in retry queue');

      final List<Map<String, dynamic>> queueCopy = List.from(_retryQueue);
      _retryQueue.clear();

      for (final item in queueCopy) {
        try {
          await _sendQueuedNotification(item);
        } catch (e) {
          print('❌ NotificationService: Error processing queued item: $e');
          // เพิ่มกลับเข้าคิวถ้าส่งไม่สำเร็จ
          _retryQueue.add(item);
        }
      }

      print('✅ NotificationService: Retry queue processed');
    } catch (e) {
      print('❌ NotificationService: Error processing retry queue: $e');
    }
  }

  /// 📨 **ส่งข้อความที่ค้างใน Queue**
  static Future<void> _sendQueuedNotification(Map<String, dynamic> item) async {
    try {
      // ตรวจสอบประเภทของข้อความ
      final String type = item['type'] ?? 'unknown';
      final Map<String, dynamic> data = item['data'] ?? {};

      print('🔔 NotificationService: Sending queued notification: $type');

      // TODO: เพิ่มการส่ง notification จริงตามประเภท
      // ปัจจุบันแค่ log ไว้ก่อน
      print('📤 NotificationService: Would send notification with data: $data');
    } catch (e) {
      print('❌ NotificationService: Error sending queued notification: $e');
      rethrow;
    }
  }

  /// 📥 **เพิ่มข้อความเข้า Retry Queue**
  static void _addToRetryQueue(String type, Map<String, dynamic> data) {
    try {
      final item = {
        'type': type,
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      _retryQueue.add(item);
      print(
          '📥 NotificationService: Added to retry queue: $type (Queue size: ${_retryQueue.length})');
    } catch (e) {
      print('❌ NotificationService: Error adding to retry queue: $e');
    }
  }

  /// 📞 **จัดการข้อความเมื่อแอพเปิดอยู่ (Foreground)**
  static void _handleForegroundMessage(RemoteMessage message) {
    try {
      print('🔔 NotificationService: Foreground message received');
      print('Title: ${message.notification?.title}');
      print('Body: ${message.notification?.body}');
      print('Data: ${message.data}');

      // ส่งข้อมูลไปยัง Stream เพื่อให้ UI รับรู้ (แต่ไม่แสดง in-app notification)
      _messageStreamController.add(message);

      // ไม่แสดง SnackBar หรือ in-app notification เมื่ออยู่ในแอพ
      // ให้แสดงแค่ notification ปกติจากระบบเท่านั้น
      print(
          '✅ NotificationService: Foreground message processed (no in-app display)');
    } catch (e) {
      print('❌ NotificationService: Error handling foreground message: $e');

      // เพิ่มเข้า retry queue หากเกิดข้อผิดพลาด
      _addToRetryQueue('foreground_message', {
        'notification': {
          'title': message.notification?.title,
          'body': message.notification?.body,
        },
        'data': message.data,
      });
    }
  }

  /// ️ **จัดการเมื่อผู้ใช้แตะ Notification**
  static void _handleNotificationTap(RemoteMessage message) {
    try {
      print('🔔 NotificationService: Notification tapped');
      print('Data: ${message.data}');

      _handleNotificationAction(message);
    } catch (e) {
      print('❌ NotificationService: Error handling notification tap: $e');
    }
  }

  /// ⚡ **จัดการ Action ของ Notification**
  /// ⚠️ **หมายเหตุ:** ฟังก์ชันนี้จะทำงานเฉพาะเมื่อผู้ใช้แตะ notification เท่านั้น
  /// ไม่ใช่เมื่อ notification มาถึงขณะที่กำลังใช้แอพ
  static void _handleNotificationAction(RemoteMessage message) {
    try {
      final Map<String, dynamic> data = message.data;
      final String? type = data['type'];
      final String? reportId = data['reportId'];
      final String? action = data['action'];

      print(
          '🔔 NotificationService: User tapped notification - Type: $type, Action: $action, ReportId: $reportId');

      final BuildContext? context = navigatorKey.currentContext;
      if (context == null) {
        print('⚠️ NotificationService: No context available for navigation');
        return;
      }

      // ✅ เฉพาะเมื่อผู้ใช้แตะ notification ให้นำทางไปหน้า List Screen
      // แต่ไม่เปิด Comment อัตโนมัติเพื่อไม่รบกวนการใช้งาน
      switch (action) {
        case 'open_comment':
          // นำทางไปยังหน้า List Screen แบบปกติ (ไม่เปิด Comment อัตโนมัติ)
          _navigateToListScreen(context);
          break;

        case 'open_post':
          // นำทางไปยังหน้า List Screen
          _navigateToListScreen(context);
          break;

        default:
          // Legacy support - ใช้ type แทน action
          switch (type) {
            case 'new_comment':
              // นำทางไปยังหน้า List Screen แบบปกติ (ไม่เปิด Comment อัตโนมัติ)
              _navigateToListScreen(context);
              break;
            case 'new_post':
              _navigateToListScreen(context);
              break;
            default:
              print(
                  '⚠️ NotificationService: Unknown notification type/action: $type/$action');
              _navigateToListScreen(context);
          }
      }
    } catch (e) {
      print('❌ NotificationService: Error handling notification action: $e');
    }
  }

  /// 📄 **นำทางไปยัง List Screen**
  static void _navigateToListScreen(BuildContext context) {
    try {
      print('🔔 NotificationService: Attempting to navigate to List Screen');

      // ตรวจสอบว่าอยู่ที่หน้า List Screen อยู่แล้วหรือไม่
      final String currentRoute = ModalRoute.of(context)?.settings.name ?? '';
      print('🔔 Current route: $currentRoute');

      if (currentRoute.contains('list') || currentRoute == '/list') {
        print('🔔 NotificationService: Already on List Screen');
        return;
      }

      // ✅ ใช้ pushNamedAndRemoveUntil เพื่อให้แน่ใจว่าไปถึง List Screen
      // และไม่มี route อื่นแทรกขวาง
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/list',
        (Route<dynamic> route) => route.settings.name == '/' || route.isFirst,
      );

      print('✅ NotificationService: Navigation to List Screen requested');
    } catch (e) {
      print('❌ NotificationService: Error navigating to List Screen: $e');
      // ถ้าเกิดข้อผิดพลาด ลองใช้วิธีง่ายๆ
      try {
        Navigator.of(context).pushNamed('/list');
        print('✅ NotificationService: Fallback navigation to List Screen');
      } catch (fallbackError) {
        print(
            '❌ NotificationService: Fallback navigation also failed: $fallbackError');
      }
    }
  }

  ///  **อัพเดท Token เมื่อผู้ใช้เข้าสู่ระบบ**
  static Future<void> updateTokenOnLogin() async {
    try {
      print('🔔 NotificationService: Updating token on login...');

      // ตรวจสอบ token ปัจจุบันก่อน
      await _checkAndRefreshToken();

      final String? token = _cachedToken ?? await _getFCMToken();
      if (token != null) {
        await _saveTokenToFirestore(token);

        // ประมวลผลข้อความที่ค้างอยู่หลังจาก login
        await _processRetryQueue();
      } else {
        print(
            '⚠️ NotificationService: No token available, starting retry process');
        await _retryTokenRefresh();
      }
    } catch (e) {
      print('❌ NotificationService: Error updating token on login: $e');

      // หากเกิดข้อผิดพลาด ให้พยายาม retry
      await _retryTokenRefresh();
    }
  }

  /// 🗑️ **ลบ Token เมื่อผู้ใช้ออกจากระบบ**
  static Future<void> removeTokenOnLogout() async {
    try {
      print('🔔 NotificationService: Removing token on logout...');

      final String? userId = AuthService.currentUser?.uid;
      if (userId != null) {
        await _firestore.collection('users').doc(userId).update({
          'fcmToken': FieldValue.delete(),
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
      }

      // ลบ token ในเครื่องด้วย
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('fcm_token');

      _cachedToken = null;
      print('✅ NotificationService: Token removed successfully');
    } catch (e) {
      print('❌ NotificationService: Error removing token on logout: $e');
    }
  }

  /// 📊 **ดึง Token ปัจจุบัน**
  static String? get currentToken => _cachedToken;

  /// 📊 **ตรวจสอบสถานะ Retry System**
  static Map<String, dynamic> get retryStatus => {
        'isRefreshing': _isRefreshing,
        'retryAttempts': _retryAttempts,
        'maxRetryAttempts': _maxRetryAttempts,
        'queueSize': _retryQueue.length,
        'hasActiveTimer': _retryTimer?.isActive ?? false,
      };

  /// 🔄 **บังคับรีเฟรช Token (สำหรับ Debug)**
  static Future<void> forceTokenRefresh() async {
    try {
      print('🔔 NotificationService: Force refreshing token...');

      // รีเซ็ต retry attempts
      _retryAttempts = 0;
      _isRefreshing = false;

      await _retryTokenRefresh();
    } catch (e) {
      print('❌ NotificationService: Error force refreshing token: $e');
    }
  }

  /// 📤 **บังคับประมวลผล Retry Queue (สำหรับ Debug)**
  static Future<void> forceProcessRetryQueue() async {
    try {
      print('🔔 NotificationService: Force processing retry queue...');
      await _processRetryQueue();
    } catch (e) {
      print('❌ NotificationService: Error force processing retry queue: $e');
    }
  }

  /// 🧹 **ล้าง Retry Queue**
  static void clearRetryQueue() {
    try {
      final int oldSize = _retryQueue.length;
      _retryQueue.clear();
      print('🔔 NotificationService: Cleared retry queue (was $oldSize items)');
    } catch (e) {
      print('❌ NotificationService: Error clearing retry queue: $e');
    }
  }

  /// 🚫 **ปิดการแจ้งเตือน**
  /// เรียกใช้เมื่อผู้ใช้ปิดการแจ้งเตือน
  static Future<void> disableNotifications() async {
    try {
      print('🔔 NotificationService: Disabling notifications...');

      final String? userId = AuthService.currentUser?.uid;
      if (userId != null) {
        // อัปเดตสถานะในฐานข้อมูล
        await _firestore
            .collection('user_tokens')
            .where('userId', isEqualTo: userId)
            .get()
            .then((snapshot) async {
          for (var doc in snapshot.docs) {
            await doc.reference.update({
              'isActive': false,
              'lastUpdated': FieldValue.serverTimestamp(),
            });
          }
        });
      }

      // ลบ FCM token
      await _firebaseMessaging.deleteToken();

      // ลบ token ในเครื่องด้วย
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('fcm_token');

      _cachedToken = null;
      print('✅ NotificationService: Notifications disabled successfully');
    } catch (e) {
      print('❌ NotificationService: Error disabling notifications: $e');
    }
  }

  /// 🔔 **เรียกใช้การส่งแจ้งเตือนเมื่อมีโพสใหม่**
  /// ฟังก์ชันนี้จะถูกเรียกหลังจากโพสใหม่สำเร็จ
  static Future<void> triggerNewPostNotification(String reportId) async {
    try {
      print(
          '🔔 NotificationService: Triggering new post notification for report: $reportId');

      // ตรวจสอบว่า service ถูกเริ่มต้นแล้วหรือไม่
      if (!_isInitialized) {
        print('⚠️ NotificationService: Not initialized, initializing now...');
        await initialize();
      }

      // ตรวจสอบว่ามี FCM token หรือไม่
      if (_cachedToken == null) {
        print(
            '⚠️ NotificationService: No FCM token available, getting new token...');
        await _getFCMToken();
      }

      // ไม่จำเป็นต้องทำอะไรเพิ่มเติมที่ frontend
      // เพราะ Cloud Functions จะจัดการส่งแจ้งเตือนอัตโนมัติเมื่อมี document ใหม่ใน reports collection
      print(
          '✅ NotificationService: New post notification triggered successfully');
      print(
          '📝 Note: Cloud Functions will handle the actual notification sending');
    } catch (e) {
      print(
          '❌ NotificationService: Error triggering new post notification: $e');
      // ไม่ throw error เพื่อไม่ให้กระทบกับการโพส
    }
  }

  /// 🧹 **ปิดระบบ Notification**
  static void dispose() {
    try {
      // ปิด Stream Controller
      _messageStreamController.close();

      // ยกเลิก Timer ที่ยังทำงานอยู่
      _retryTimer?.cancel();
      _retryTimer = null;

      // ล้าง retry queue
      _retryQueue.clear();

      // รีเซ็ตตัวแปร
      _isInitialized = false;
      _isRefreshing = false;
      _retryAttempts = 0;
      _cachedToken = null;

      print('🔔 NotificationService: Disposed with cleanup');
    } catch (e) {
      print('❌ NotificationService: Error disposing: $e');
    }
  }
}

/// 🌐 **Background Message Handler**
/// จัดการข้อความเมื่อแอพปิดอยู่หรือทำงานในพื้นหลัง
///
/// **หมายเหตุ:** ฟังก์ชันนี้ต้องเป็น top-level function (ไม่อยู่ใน class)
/// และต้องมี annotation @pragma('vm:entry-point')
@pragma('vm:entry-point')
Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  try {
    print('🔔 NotificationService: Background message received');
    print('Title: ${message.notification?.title}');
    print('Body: ${message.notification?.body}');
    print('Data: ${message.data}');

    // TODO: เพิ่มการประมวลผลข้อมูลเพิ่มเติมถ้าจำเป็น
    // เช่น บันทึกข้อมูลลงฐานข้อมูลท้องถิ่น
  } catch (e) {
    print('❌ NotificationService: Error handling background message: $e');
  }
}
