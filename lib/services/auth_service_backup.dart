import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../screens/login_screen.dart';

// Mock UserCredential class สำหรับจัดการ type casting error
class MockUserCredential implements UserCredential {
  @override
  final User? user;

  MockUserCredential(this.user);

  @override
  AdditionalUserInfo? get additionalUserInfo => null;

  @override
  AuthCredential? get credential => null;
}

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Local cache สำหรับสถานะล็อกอิน
  static bool _isUserLoggedIn = false;

  // ตรวจสอบว่าผู้ใช้ล็อกอินอยู่หรือไม่ (ใช้ local cache)
  static bool get isLoggedIn => _isUserLoggedIn;

  // ข้อมูลผู้ใช้ปัจจุบัน (เรียกเฉพาะเมื่อจำเป็น)
  static User? get currentUser {
    try {
      return _auth.currentUser;
    } catch (e) {
      print('⚠️ Error getting current user: $e');
      return null;
    }
  }

  // สร้างชื่อแบบ masked สำหรับแสดงผล (เช่น kritchapon *****)
  static String getMaskedDisplayName() {
    final user = currentUser;
    if (user == null) return 'ผู้ใช้ไม่ระบุชื่อ';

    final displayName = user.displayName;
    if (displayName == null || displayName.isEmpty) {
      // ใช้ email แทนถ้าไม่มี displayName
      final email = user.email;
      if (email != null && email.isNotEmpty) {
        final username = email.split('@').first;
        return maskName(username);
      }
      return 'ผู้ใช้ไม่ระบุชื่อ';
    }

    return maskName(displayName);
  }

  // ฟังก์ชันสำหรับ mask ชื่อ (เช่น kritchapon prommali -> kritchapon *****)
  static String maskName(String name) {
    final parts = name.trim().split(' ');

    if (parts.isEmpty) return 'ผู้ใช้ไม่ระบุชื่อ';

    if (parts.length == 1) {
      // ถ้ามีคำเดียว เช่น "kritchapon" -> "krit*****"
      final firstPart = parts[0];
      if (firstPart.length <= 4) {
        return firstPart; // ถ้าสั้นเกินไป ไม่ mask
      }
      return '${firstPart.substring(0, 4)}${'*' * (firstPart.length - 4)}';
    } else {
      // ถ้ามีหลายคำ เช่น "kritchapon prommali" -> "kritchapon *******"
      final firstName = parts[0];
      final lastNameLength = parts.sublist(1).join(' ').length;
      return '$firstName ${'*' * lastNameLength}';
    }
  }

  // เริ่มต้นการตรวจสอบสถานะล็อกอิน
  static Future<void> initialize() async {
    try {
      // ตั้ง auth state listener ก่อนเพื่อจับ state ได้ทันที
      _auth.authStateChanges().listen((User? user) {
        final wasLoggedIn = _isUserLoggedIn;
        _isUserLoggedIn = user != null;
        
        if (wasLoggedIn != _isUserLoggedIn) {
          print('� Auth state changed: $_isUserLoggedIn');
          if (user != null) {
            print('👤 User logged in: ${user.uid}');
          } else {
            print('� User logged out');
          }
        }
      });
      
      // รอให้ Firebase Auth ประมวลผล auth state ก่อน
      await Future.delayed(const Duration(milliseconds: 100));
      
      final currentUser = _auth.currentUser;
      _isUserLoggedIn = currentUser != null;
      
      print('� AuthService initialized: $_isUserLoggedIn');
      if (currentUser != null) {
        print('👤 Current user: ${currentUser.uid}');
        print('� Email: ${currentUser.email}');
      }
      
    } catch (e) {
      print('⚠️ Error initializing AuthService: $e');
      _isUserLoggedIn = false;
    }
  }

  // ล็อกอินด้วย Google พร้อม Context สำหรับการจัดการ UI
  static Future<UserCredential?> signInWithGoogle(
      {BuildContext? context}) async {
    try {
      print('🚀 1. เริ่มกระบวนการล็อกอิน Google Sign-In...');

      // 1. ล้าง session เก่า
      print('🔹 2. ล้าง session เก่า...');
      await _googleSignIn.signOut();
      await _auth.signOut();
      _isUserLoggedIn = false;

      // 2. เริ่มกระบวนการล็อกอิน
      print('🔹 3. เปิดหน้าจอเลือก Gmail...');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print('❌ ผู้ใช้ยกเลิกการล็อกอิน');
        return null;
      }

      print('🔹 4. เลือกบัญชี Google สำเร็จ: ${googleUser.email}');
      print('🔹 Google User: ${googleUser.email}');
      print('🔹 Google User ID: ${googleUser.id}');
      print('🔹 Google User Display Name: ${googleUser.displayName}');

      // 3. รับ Credentials
      print('🔹 5. รับ authentication credentials...');
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw Exception('ไม่สามารถรับ authentication tokens ได้');
      }

      print('🔹 Google Auth Access Token: ${googleAuth.accessToken}');
      print('🔹 Google Auth ID Token: ${googleAuth.idToken}');
      print(
          '🔹 6. Access Token: ${googleAuth.accessToken?.substring(0, 20)}...');
      print('🔹 7. ID Token: ${googleAuth.idToken?.substring(0, 20)}...');

      // 4. สร้าง Firebase Credential
      print('🔹 8. สร้าง Firebase credential...');
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 5. ล็อกอิน Firebase
      print('🔹 9. ล็อกอินเข้า Firebase...');
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      if (userCredential.user == null) {
        throw Exception('ล็อกอิน Firebase สำเร็จแต่ไม่พบข้อมูลผู้ใช้');
      }

      print('🔹 10. ล็อกอิน Firebase สำเร็จ!');
      print('👤 User ID: ${userCredential.user!.uid}');
      print('📧 Email: ${userCredential.user!.email}');
      print('👤 Display Name: ${userCredential.user!.displayName}');

      // 6. บันทึกข้อมูลผู้ใช้
      print('🔹 11. บันทึกข้อมูลผู้ใช้ไปยัง Firestore...');
      await _saveUserToFirestore(userCredential.user!);

      // 7. อัปเดต local state
      _isUserLoggedIn = true;
      print('✅ ล็อกอินสำเร็จ!');

      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth Error: ${e.code} - ${e.message}');

      // ล้าง state
      _isUserLoggedIn = false;

      throw Exception(_getFriendlyError(e.code));
    } catch (e) {
      print('❌ Google Sign-In Error: $e');
      print('📱 Error Type: ${e.runtimeType}');

      // ตรวจสอบว่า Firebase Auth สำเร็จหรือไม่ ก่อนที่จะ error
      print('🔍 Checking if Firebase Auth actually succeeded...');
      await Future.delayed(
          const Duration(milliseconds: 500)); // รอ Firebase update

      final currentFirebaseUser = _auth.currentUser;
      if (currentFirebaseUser != null) {
        print(
            '🎉 Firebase Auth actually succeeded! User: ${currentFirebaseUser.uid}');
        _isUserLoggedIn = true;

        // สร้าง UserCredential จาก current user
        print('🔹 Creating UserCredential from Firebase current user...');
        await _saveUserToFirestore(currentFirebaseUser);

        print('✅ Recovered from Google Sign-In error - Login successful!');
        return MockUserCredential(currentFirebaseUser);
      }

      // ลองออกจากระบบและล้าง cache
      try {
        await _googleSignIn.signOut();
        await _auth.signOut();
        _isUserLoggedIn = false;
      } catch (cleanupError) {
        print('⚠️ Cleanup error: $cleanupError');
      }

      // จัดการข้อผิดพลาดเฉพาะ
      String errorMessage = 'ล็อกอินไม่สำเร็จ';

      // ตรวจสอบ type casting error ที่เกิดจาก Google Sign-In plugin
      if (e.toString().contains('PigeonUserDetails') ||
          e.toString().contains('List<Object?>') ||
          e.toString().contains('type cast')) {
        errorMessage =
            'เกิดข้อผิดพลาดภายใน Google Sign-In\nแต่การล็อกอินอาจสำเร็จแล้ว - กรุณาตรวจสอบสถานะ';
        print(
            '🔧 Type casting error detected - but login might have succeeded');
      } else if (e.toString().contains('sign_in_failed')) {
        errorMessage =
            'การตั้งค่า Google Sign-In ไม่ถูกต้อง\nกรุณาติดต่อผู้พัฒนาระบบ';
      } else if (e.toString().contains('network')) {
        errorMessage =
            'ปัญหาการเชื่อมต่ออินเทอร์เน็ต\nกรุณาตรวจสอบการเชื่อมต่อ';
      } else if (e.toString().contains('canceled') ||
          e.toString().contains('cancelled')) {
        errorMessage = 'ผู้ใช้ยกเลิกการล็อกอิน';
      } else if (e.toString().contains('10:')) {
        errorMessage =
            'Google Services ไม่พร้อมใช้งาน\nกรุณาอัปเดต Google Play Services';
      }

      throw Exception(errorMessage);
    }
  }

  // แปลง Firebase error code เป็นข้อความอ่านง่าย
  static String _getFriendlyError(String code) {
    switch (code) {
      case 'account-exists-with-different-credential':
        return 'บัญชีนี้ถูกใช้ด้วยวิธีล็อกอินอื่น';
      case 'network-request-failed':
        return 'เชื่อมต่ออินเทอร์เน็ตล้มเหลว กรุณาตรวจสอบการเชื่อมต่อ';
      case 'user-disabled':
        return 'บัญชีนี้ถูกระงับการใช้งาน';
      case 'user-not-found':
        return 'ไม่พบบัญชีผู้ใช้';
      case 'wrong-password':
        return 'รหัสผ่านไม่ถูกต้อง';
      case 'invalid-credential':
        return 'ข้อมูลการเข้าสู่ระบบไม่ถูกต้อง';
      case 'operation-not-allowed':
        return 'การล็อกอินด้วย Google ยังไม่ได้เปิดใช้งาน';
      case 'too-many-requests':
        return 'มีการพยายามล็อกอินมากเกินไป กรุณารอสักครู่';
      default:
        return 'ล็อกอินไม่สำเร็จ: $code';
    }
  }

  // บันทึกข้อมูลผู้ใช้ไปยัง Firestore
  static Future<void> _saveUserToFirestore(User user) async {
    try {
      print('🔹 Saving user to Firestore: ${user.uid}');
      final userDoc = _firestore.collection('users').doc(user.uid);

      // ตรวจสอบว่าเคยมีข้อมูลแล้วหรือไม่
      final docSnapshot = await userDoc.get();

      final userData = {
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'lastLoginAt': FieldValue.serverTimestamp(),
        'provider': 'google',
      };

      if (docSnapshot.exists) {
        // อัปเดตข้อมูลล่าสุด
        await userDoc.update({
          'lastLoginAt': FieldValue.serverTimestamp(),
          'email': user.email,
          'displayName': user.displayName,
          'photoURL': user.photoURL,
        });
        print('✅ อัปเดตข้อมูลผู้ใช้: ${user.uid}');
      } else {
        // สร้างข้อมูลผู้ใช้ใหม่
        userData['createdAt'] = FieldValue.serverTimestamp();
        userData['postCount'] = 0;
        userData['commentCount'] = 0;

        await userDoc.set(userData);
        print('✅ สร้างข้อมูลผู้ใช้ใหม่: ${user.uid}');
      }
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        print('❌ Firestore Permission Denied: ${e.message}');
        print('🔧 กรุณาตรวจสอบ Firestore Security Rules');
        print('🔧 ตรวจสอบว่าผู้ใช้ล็อกอินแล้วหรือไม่');
      } else {
        print('❌ Firestore Error: ${e.code} - ${e.message}');
      }
    } catch (e) {
      print('⚠️ ไม่สามารถบันทึกข้อมูลผู้ใช้: $e');
      print('📱 Error Type: ${e.runtimeType}');
    }
  }

  // ออกจากระบบ
  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      _isUserLoggedIn = false; // อัปเดต local state
      print('✅ ออกจากระบบสำเร็จ');
    } catch (e) {
      print('❌ ออกจากระบบล้มเหลว: $e');
      throw Exception('ออกจากระบบไม่สำเร็จ');
    }
  }

  // แสดงหน้าเข้าสู่ระบบแบบเต็มจอ
  static Future<bool> showLoginDialog(BuildContext context) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
        fullscreenDialog: true,
      ),
    );

    return result ?? false;
  }

  // ตรวจสอบว่าผู้ใช้ล็อกอินแล้วหรือไม่ ถ้าไม่ให้แสดงหน้าต่างล็อกอิน
  static Future<bool> ensureUserLoggedIn(BuildContext context) async {
    if (isLoggedIn) {
      return true;
    }

    return await showLoginDialog(context);
  }

  // ฟังก์ชัน Debug สำหรับตรวจสอบสถานะ Authentication
  static Future<void> debugAuthStatus() async {
    print('🔍 === DEBUG AUTH STATUS ===');
    print('🔐 Is Logged In: $isLoggedIn');

    if (currentUser != null) {
      print('👤 User ID: ${currentUser!.uid}');
      print('📧 Email: ${currentUser!.email}');
      print('👤 Display Name: ${currentUser!.displayName}');
      print('📷 Photo URL: ${currentUser!.photoURL}');
      print(
          '🔐 Provider Data: ${currentUser!.providerData.map((p) => p.providerId).join(', ')}');
      print('✅ Email Verified: ${currentUser!.emailVerified}');
      print('📅 Creation Time: ${currentUser!.metadata.creationTime}');
      print('📅 Last Sign In: ${currentUser!.metadata.lastSignInTime}');

      try {
        final token = await currentUser!.getIdToken();
        print('🎫 Firebase Token Available: ${token != null ? 'YES' : 'NO'}');
        if (token != null && token.length > 20) {
          print('🎫 Token Preview: ${token.substring(0, 20)}...');
        }
      } catch (e) {
        print('❌ Token Error: $e');
      }
    } else {
      print('❌ No user logged in');
    }
    print('🔍 === END DEBUG ===');
  }

  // ฟังก์ชันทดสอบการล็อกอินแบบง่าย
  static Future<void> testSimpleLogin() async {
    try {
      print('🧪 เริ่มทดสอบการล็อกอินแบบง่าย...');

      // ลองหลายครั้งเพื่อหลีกเลี่ยง type casting error
      UserCredential? result;
      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          print('🔄 ความพยายามครั้งที่ $attempt...');
          result = await signInWithGoogle();
          break; // สำเร็จแล้วออกจาก loop
        } catch (e) {
          print(
              '❌ ความพยายามครั้งที่ $attempt ล้มเหลว: ${e.toString().substring(0, 100)}...');
          if (attempt < 3) {
            await Future.delayed(const Duration(seconds: 2)); // รอ 2 วินาที
          }
        }
      }

      if (result != null) {
        print('✅ ทดสอบล็อกอินสำเร็จ: ${result.user?.uid}');
        print('👤 ชื่อ: ${result.user?.displayName}');
        print('📧 อีเมล: ${result.user?.email}');
      } else {
        print('❌ ทดสอบล็อกอินล้มเหลวหลังจาก 3 ครั้ง');
      }
    } catch (e) {
      print('❌ ทดสอบล็อกอินล้มเหลว: $e');
    }
  }
}
