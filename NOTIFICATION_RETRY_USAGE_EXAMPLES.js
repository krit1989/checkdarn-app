/**
 * 🔔 **ตัวอย่างการใช้งาน Notification Retry System**
 * 
 * ไฟล์นี้แสดงวิธีการใช้งานระบบ Retry ที่เราสร้างขึ้น
 * ทั้งใน Frontend (Flutter) และ Backend (Cloud Functions)
 */

// ===== FRONTEND (Flutter) Usage =====

/*
// 1. การเริ่มต้นใช้งาน (ใน main.dart)
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // เริ่มต้นระบบ Notification พร้อม Retry
  await NotificationService.initialize();
  
  runApp(MyApp());
}

// 2. การตรวจสอบสถานะ Retry System
void checkRetryStatus() {
  final status = NotificationService.retryStatus;
  print('Retry Status: $status');
  
  // ตัวอย่างผลลัพธ์:
  // {
  //   'isRefreshing': false,
  //   'retryAttempts': 0,
  //   'maxRetryAttempts': 3,
  //   'queueSize': 0,
  //   'hasActiveTimer': false
  // }
}

// 3. การบังคับ Refresh Token (สำหรับ Debug)
Future<void> debugForceRefresh() async {
  await NotificationService.forceTokenRefresh();
  print('Force refresh completed');
}

// 4. การประมวลผล Retry Queue ด้วยตนเอง
Future<void> debugProcessQueue() async {
  await NotificationService.forceProcessRetryQueue();
  print('Manual queue processing completed');
}

// 5. การล้าง Retry Queue
void debugClearQueue() {
  NotificationService.clearRetryQueue();
  print('Retry queue cleared');
}

// 6. การจัดการเมื่อ Login/Logout
class AuthenticationManager {
  static Future<void> signIn() async {
    // ... การ login ...
    
    // อัปเดต Token หลังจาก Login
    await NotificationService.updateTokenOnLogin();
  }
  
  static Future<void> signOut() async {
    // ลบ Token ก่อน Logout
    await NotificationService.removeTokenOnLogout();
    
    // ... การ logout ...
  }
}

// 7. การฟัง Notification Events
class NotificationListener extends StatefulWidget {
  @override
  _NotificationListenerState createState() => _NotificationListenerState();
}

class _NotificationListenerState extends State<NotificationListener> {
  late StreamSubscription<RemoteMessage> _messageSubscription;

  @override
  void initState() {
    super.initState();
    
    // ฟัง Notification ที่เข้ามา
    _messageSubscription = NotificationService.onMessageReceived.listen(
      (RemoteMessage message) {
        print('Received notification: ${message.notification?.title}');
        // จัดการ notification ตามต้องการ
      },
    );
  }

  @override
  void dispose() {
    _messageSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // UI ของคุณ
    );
  }
}
*/

// ===== BACKEND (Cloud Functions) Usage =====

/*
const { sendNotificationWithRetry } = require('./notification_retry');

// 1. ตัวอย่างการส่ง Notification เมื่อมีโพสต์ใหม่
exports.sendNewPostNotification = functions.firestore
  .document('reports/{reportId}')
  .onCreate(async (snapshot, context) => {
    try {
      const reportData = snapshot.data();
      const reporterId = reportData.userId;

      // ดึง FCM Tokens ของผู้ใช้ที่ต้องการแจ้งเตือน
      const tokensSnapshot = await admin.firestore()
        .collection('user_tokens')
        .where('userId', '!=', reporterId) // ไม่แจ้งเตือนคนโพส
        .where('isActive', '==', true)
        .get();

      const tokens = tokensSnapshot.docs.map(doc => doc.data().fcmToken);

      if (tokens.length === 0) {
        console.log('No tokens to send notification to');
        return;
      }

      // ส่ง Notification พร้อม Retry Logic
      const result = await sendNotificationWithRetry(
        {
          notification: {
            title: 'มีโพสต์ใหม่!',
            body: reportData.description.substring(0, 100)
          },
          data: {
            type: 'new_post',
            reportId: context.params.reportId,
            category: reportData.category
          }
        },
        tokens,
        'new_post'
      );

      console.log('Notification result:', result);

    } catch (error) {
      console.error('Error sending new post notification:', error);
    }
  });

// 2. ตัวอย่างการส่ง Notification เมื่อมีคอมเมนต์ใหม่
exports.sendNewCommentNotification = functions.firestore
  .document('reports/{reportId}/comments/{commentId}')
  .onCreate(async (snapshot, context) => {
    try {
      const commentData = snapshot.data();
      const reportId = context.params.reportId;

      // ดึงข้อมูลโพสต์เดิม
      const reportDoc = await admin.firestore()
        .collection('reports')
        .doc(reportId)
        .get();

      if (!reportDoc.exists) return;

      const reportData = reportDoc.data();
      const postOwnerId = reportData.userId;
      const commenterId = commentData.userId;

      // ไม่แจ้งเตือนถ้าคนคอมเมนต์เป็นเจ้าของโพสต์
      if (postOwnerId === commenterId) return;

      // ดึง FCM Token ของเจ้าของโพสต์
      const tokenDoc = await admin.firestore()
        .collection('user_tokens')
        .where('userId', '==', postOwnerId)
        .where('isActive', '==', true)
        .limit(1)
        .get();

      if (tokenDoc.empty) {
        console.log('No active token for post owner');
        return;
      }

      const token = tokenDoc.docs[0].data().fcmToken;

      // ส่ง Notification พร้อม Retry Logic
      const result = await sendNotificationWithRetry(
        {
          notification: {
            title: 'มีความคิดเห็นใหม่!',
            body: `${commentData.displayName || 'ผู้ใช้'}: ${commentData.comment.substring(0, 50)}...`
          },
          data: {
            type: 'new_comment',
            reportId: reportId,
            commentId: context.params.commentId
          }
        },
        [token],
        'new_comment'
      );

      console.log('Comment notification result:', result);

    } catch (error) {
      console.error('Error sending comment notification:', error);
    }
  });

// 3. ตัวอย่างการส่ง Notification แบบ Batch
exports.sendBulkNotification = functions.https.onCall(async (data, context) => {
  try {
    // ตรวจสอบสิทธิ์
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const { title, body, targetUserIds, notificationType } = data;

    // ดึง Tokens ของผู้ใช้เป้าหมาย
    const tokensSnapshot = await admin.firestore()
      .collection('user_tokens')
      .where('userId', 'in', targetUserIds)
      .where('isActive', '==', true)
      .get();

    const tokens = tokensSnapshot.docs.map(doc => doc.data().fcmToken);

    if (tokens.length === 0) {
      return { success: false, message: 'No active tokens found' };
    }

    // ส่ง Notification พร้อม Retry Logic
    const result = await sendNotificationWithRetry(
      {
        notification: { title, body },
        data: {
          type: notificationType || 'general',
          timestamp: Date.now().toString()
        }
      },
      tokens,
      'bulk_notification'
    );

    return {
      success: true,
      result: result,
      tokensProcessed: tokens.length
    };

  } catch (error) {
    console.error('Error sending bulk notification:', error);
    throw new functions.https.HttpsError('internal', 'Failed to send notification');
  }
});
*/

// ===== การตั้งค่า Firestore Security Rules =====

/*
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // กฎสำหรับ User Tokens
    match /user_tokens/{tokenId} {
      allow read, write: if request.auth != null && 
        request.auth.uid == resource.data.userId;
      allow create: if request.auth != null && 
        request.auth.uid == request.resource.data.userId;
    }
    
    // กฎสำหรับ Notification Retry Queue (เฉพาะ Cloud Functions)
    match /notification_retry_queue/{entryId} {
      allow read, write: if false; // เฉพาะ Cloud Functions เท่านั้น
    }
    
    // กฎสำหรับ Reports และ Comments
    match /reports/{reportId} {
      allow read: if true; // อ่านได้ทุกคน
      allow write: if request.auth != null;
      
      match /comments/{commentId} {
        allow read: if true;
        allow write: if request.auth != null;
      }
    }
  }
}
*/

// ===== การติดตั้งและ Deploy =====

/*
1. ติดตั้ง Dependencies:
   npm install firebase-functions firebase-admin

2. เพิ่มไฟล์ notification_retry.js ในโฟลเดอร์ functions/

3. นำเข้าในไฟล์ functions/index.js:
   const notificationRetry = require('./notification_retry');

4. Deploy Cloud Functions:
   firebase deploy --only functions

5. ตั้งค่า Firestore Security Rules:
   firebase deploy --only firestore:rules

6. ติดตั้ง Flutter Package (ถ้ายังไม่มี):
   flutter pub add firebase_messaging shared_preferences

7. เพิ่ม Permission ใน AndroidManifest.xml:
   <uses-permission android:name="android.permission.WAKE_LOCK" />
   <uses-permission android:name="android.permission.VIBRATE" />
*/

// ===== การทดสอบระบบ =====

/*
1. ทดสอบ Token Refresh:
   - ปิด/เปิดแอพหลายครั้ง
   - ตรวจสอบ Log ว่ามีการ refresh token

2. ทดสอบ Retry System:
   - ส่ง notification ขณะที่ไม่มีอินเทอร์เน็ต
   - ตรวจสอบว่าข้อความถูกเพิ่มเข้า retry queue

3. ทดสอบ Invalid Token Cleanup:
   - ลบแอพและติดตั้งใหม่
   - ตรวจสอบว่า invalid token ถูกลบออกจากฐานข้อมูล

4. ตรวจสอบ Cloud Functions Logs:
   firebase functions:log --only processRetryQueue,cleanupRetryQueue
*/

module.exports = {
  // ตัวอย่างการใช้งานทั้งหมดอยู่ใน comment ด้านบน
};
