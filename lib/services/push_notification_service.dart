import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart';
import 'auth_service.dart';

/// 🔔 **Push Notification Service - Business Logic**
/// ระบบจัดการ Push Notification ระดับ Business Logic
///
/// **หน้าที่หลัก:**
/// - จัดการการส่ง notification เมื่อมีเหตุการณ์ใหม่
/// - Handle notification clicks และ navigation
/// - จัดการ notification preferences
/// - Integration กับ UI components
class PushNotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ตัวแปรเก็บสถานะ
  static bool _isInitialized = false;
  static String? _pendingReportId; // เก็บ reportId ที่ต้องเปิดเมื่อ app พร้อม

  /// 🚀 **เริ่มต้นระบบ Push Notification Business Logic**
  static Future<void> initialize() async {
    if (_isInitialized) {
      print('🔔 PushNotificationService: Already initialized');
      return;
    }

    try {
      print('🔔 PushNotificationService: Starting initialization...');

      // ฟัง notification stream จาก NotificationService
      NotificationService.onMessageReceived.listen(_handleNotificationReceived);

      _isInitialized = true;
      print('✅ PushNotificationService: Initialization completed');
    } catch (e) {
      print('❌ PushNotificationService: Initialization failed: $e');
    }
  }

  /// 📱 **จัดการ Notification ที่เข้ามา**
  static void _handleNotificationReceived(dynamic message) {
    try {
      print('🔔 PushNotificationService: Notification received');

      // Extract data from message
      final Map<String, dynamic> data = message.data ?? {};
      final String? type = data['type'];
      final String? reportId = data['reportId'];

      print('🔔 Notification type: $type, reportId: $reportId');

      // Handle based on notification type
      switch (type) {
        case 'new_post':
          _handleNewPostNotification(reportId);
          break;

        case 'new_comment':
          _handleNewCommentNotification(reportId);
          break;

        default:
          print('⚠️ Unknown notification type: $type');
      }
    } catch (e) {
      print('❌ PushNotificationService: Error handling notification: $e');
    }
  }

  /// 📄 **จัดการ Notification สำหรับโพสใหม่**
  static void _handleNewPostNotification(String? reportId) {
    try {
      print('🔔 PushNotificationService: Handling new post notification');

      if (reportId != null) {
        // นำทางไปยัง List Screen
        _navigateToListScreen();
      }
    } catch (e) {
      print(
          '❌ PushNotificationService: Error handling new post notification: $e');
    }
  }

  /// 💬 **จัดการ Notification สำหรับคอมเม้นใหม่**
  static void _handleNewCommentNotification(String? reportId) {
    try {
      print('🔔 PushNotificationService: Handling new comment notification');

      if (reportId != null) {
        // เก็บ reportId เพื่อเปิด comment sheet ภายหลัง
        _pendingReportId = reportId;

        // นำทางไปยัง List Screen และเปิด comment
        _navigateToListScreenWithComment(reportId);
      }
    } catch (e) {
      print(
          '❌ PushNotificationService: Error handling new comment notification: $e');
    }
  }

  /// 📄 **นำทางไปยัง List Screen**
  static void _navigateToListScreen() {
    try {
      final BuildContext? context =
          NotificationService.navigatorKey.currentContext;
      if (context == null) {
        print(
            '⚠️ PushNotificationService: No context available for navigation');
        return;
      }

      // ตรวจสอบ route ปัจจุบัน
      final String? currentRoute = ModalRoute.of(context)?.settings.name;
      print('🔔 Current route: $currentRoute');

      // ถ้าไม่ได้อยู่ที่ List Screen ให้ไป
      if (currentRoute != '/list') {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/list',
          (route) => route.settings.name == '/',
        );
      }
    } catch (e) {
      print('❌ PushNotificationService: Error navigating to List Screen: $e');
    }
  }

  /// 💬 **นำทางไปยัง List Screen และเปิด Comment**
  static void _navigateToListScreenWithComment(String reportId) {
    try {
      final BuildContext? context =
          NotificationService.navigatorKey.currentContext;
      if (context == null) {
        print(
            '⚠️ PushNotificationService: No context available for navigation');
        return;
      }

      // ไปที่ List Screen ก่อน
      _navigateToListScreen();

      // รอให้หน้าโหลดเสร็จ แล้วเปิด comment sheet
      Future.delayed(const Duration(milliseconds: 1000), () {
        _openCommentSheet(context, reportId);
      });
    } catch (e) {
      print('❌ PushNotificationService: Error navigating to comment: $e');
    }
  }

  /// 💬 **เปิด Comment Sheet สำหรับ Report ID ที่กำหนด**
  static Future<void> _openCommentSheet(
      BuildContext context, String reportId) async {
    try {
      print(
          '🔔 PushNotificationService: Opening comment sheet for reportId: $reportId');

      // ดึงข้อมูลโพสต์เพื่อเอา title และ category
      final DocumentSnapshot reportDoc =
          await _firestore.collection('reports').doc(reportId).get();

      if (!reportDoc.exists) {
        print('❌ Report not found: $reportId');
        return;
      }

      final Map<String, dynamic> data =
          reportDoc.data() as Map<String, dynamic>;
      final String title = data['title'] ??
          data['description']?.toString().split(' ').take(3).join(' ') ??
          'ไม่มีหัวข้อ';
      final String category = data['category'] ?? data['type'] ?? 'other';

      // เปิด Comment Bottom Sheet (ต้องใช้ dynamic import)
      _showCommentBottomSheet(context, reportId, title, category);
    } catch (e) {
      print('❌ PushNotificationService: Error opening comment sheet: $e');
    }
  }

  /// 💬 **แสดง Comment Bottom Sheet**
  static void _showCommentBottomSheet(
      BuildContext context, String reportId, String title, String category) {
    try {
      // ใช้ showModalBottomSheet เหมือนใน list_screen.dart
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useRootNavigator: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black54,
        isDismissible: true,
        enableDrag: true,
        useSafeArea: true,
        clipBehavior: Clip.antiAlias,
        builder: (context) {
          // สร้าง Comment Bottom Sheet แบบ dynamic
          return _buildCommentBottomSheet(reportId, category);
        },
      );
    } catch (e) {
      print(
          '❌ PushNotificationService: Error showing comment bottom sheet: $e');
    }
  }

  /// 🏗️ **สร้าง Comment Bottom Sheet Widget**
  static Widget _buildCommentBottomSheet(String reportId, String category) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.chat_bubble_outline, color: Color(0xFFFF9800)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'ความคิดเห็น',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'NotoSansThai',
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(
                          NotificationService.navigatorKey.currentContext!)
                      .pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Icon(Icons.chat, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'กำลังโหลดความคิดเห็น...',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    fontFamily: 'NotoSansThai',
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Report ID: $reportId',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontFamily: 'NotoSansThai',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🔄 **Refresh Notifications**
  static Future<void> refreshNotifications() async {
    try {
      print('🔔 PushNotificationService: Refreshing notifications...');

      // Re-initialize if needed
      if (!_isInitialized) {
        await initialize();
      }
    } catch (e) {
      print('❌ PushNotificationService: Error refreshing notifications: $e');
    }
  }

  /// 📋 **ดึง Pending Report ID**
  static String? getPendingReportId() {
    final String? reportId = _pendingReportId;
    _pendingReportId = null; // Clear หลังใช้
    return reportId;
  }

  /// � **ส่งการแจ้งเตือนทดสอบ**
  static Future<void> sendTestNotification() async {
    try {
      print('🧪 PushNotificationService: Sending test notification...');

      // สร้างการแจ้งเตือนทดสอบภายในแอป
      final BuildContext? context =
          NotificationService.navigatorKey.currentContext;
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.notifications_active, color: Colors.white),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '🔔 การแจ้งเตือนทำงานปกติ!',
                    style: TextStyle(fontFamily: 'NotoSansThai'),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );
      }

      // สำหรับทดสอบแบบจริง สามารถเพิ่ม HTTP request ไปยัง Cloud Functions
      // เพื่อส่งการแจ้งเตือนจริงๆ กลับมาที่ตัวเอง

      print('✅ PushNotificationService: Test notification sent');
    } catch (e) {
      print('❌ PushNotificationService: Error sending test notification: $e');
      throw e;
    }
  }

  /// �🧹 **ทำความสะอาดระบบ**
  static void dispose() {
    try {
      _isInitialized = false;
      _pendingReportId = null;
      print('🔔 PushNotificationService: Disposed');
    } catch (e) {
      print('❌ PushNotificationService: Error disposing: $e');
    }
  }
}
