import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
// import '../modules/speed_camera/screens/login_screen.dart';

// Mock UserCredential class สำหรับจัดการ type casting error
class MockUserCredential implements UserCredential {
  @override
  final User? user;

  @override
  final AdditionalUserInfo? additionalUserInfo;

  @override
  final AuthCredential? credential;

  MockUserCredential({
    required this.user,
    this.additionalUserInfo,
    this.credential,
  });
}

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Local cache สำหรับสถานะล็อกอิน
  static bool _isUserLoggedIn = false;
  static bool _isInitialized = false;

  // ตรวจสอบว่าผู้ใช้ล็อกอินอยู่หรือไม่ (ใช้ local cache)
  static bool get isLoggedIn {
    if (!_isInitialized) {
      print('WARNING: AuthService not initialized yet, forcing check...');
      final currentUser = _auth.currentUser;
      _isUserLoggedIn = currentUser != null;
      print('Force check result: $_isUserLoggedIn (user: ${currentUser?.uid})');
    }
    return _isUserLoggedIn;
  }

  // ข้อมูลผู้ใช้ปัจจุบัน (เรียกเฉพาะเมื่อจำเป็น)
  static User? get currentUser {
    try {
      return _auth.currentUser;
    } catch (e) {
      print('Error getting current user: $e');
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
      // ถ้ามีแค่ชื่อเดียว ให้แสดง 3 ตัวแรก + *****
      final firstName = parts[0];
      if (firstName.length <= 3) return firstName;
      return '${firstName.substring(0, 3)}*****';
    }

    // ถ้ามีหลายคำ ให้แสดงคำแรกเต็ม + mask คำที่เหลือ
    final firstName = parts[0];
    return '$firstName *****';
  }

  // เริ่มต้น AuthService และตั้งค่า auth state listener
  static Future<void> initialize() async {
    try {
      print('Starting AuthService initialization...');

      // Setup auth state listener to catch state changes immediately
      _auth.authStateChanges().listen((User? user) {
        final wasLoggedIn = _isUserLoggedIn;
        _isUserLoggedIn = user != null;

        print(
            'Auth state changed: ${user?.uid ?? 'null'} (isLoggedIn: $_isUserLoggedIn)');

        if (wasLoggedIn != _isUserLoggedIn) {
          print('Auth state transition: $wasLoggedIn -> $_isUserLoggedIn');
          if (user != null) {
            print('User logged in: ${user.uid}');
            print('Email: ${user.email}');
          } else {
            print('User logged out');
          }
        }
      });

      // Wait for Firebase Auth to initialize properly
      await Future.delayed(const Duration(milliseconds: 300));

      // Check current user and force sync state
      final currentUser = _auth.currentUser;
      _isUserLoggedIn = currentUser != null;
      _isInitialized = true;

      print('AuthService initialized: $_isUserLoggedIn (FIXED)');
      if (currentUser != null) {
        print('Current user: ${currentUser.uid}');
        print('Email: ${currentUser.email}');
        print('Firebase Auth state: USER_LOGGED_IN');
      } else {
        print('No current user found');
        print('Firebase Auth state: NO_USER');
      }

      // Force trigger auth state consistency check
      print('Force checking auth state consistency...');
      final authStateCheck = _auth.currentUser != null;
      if (authStateCheck != _isUserLoggedIn) {
        print(
            'INCONSISTENCY DETECTED: Firebase=${authStateCheck}, AuthService=${_isUserLoggedIn}');
        _isUserLoggedIn = authStateCheck;
        print(
            'Fixed inconsistency: AuthService now reports ${_isUserLoggedIn}');
      } else {
        print('Auth states are consistent: ${_isUserLoggedIn}');
      }
    } catch (e) {
      print('Error initializing AuthService: $e');
      _isUserLoggedIn = false;
      _isInitialized = true;
    }
  }

  // ล็อกอินด้วย Google พร้อม Context สำหรับการจัดการ UI
  static Future<UserCredential?> signInWithGoogle(
      {BuildContext? context}) async {
    try {
      print('Starting Google Sign-In process...');

      // ตรวจสอบการเชื่อมต่ออินเทอร์เน็ต
      try {
        await _googleSignIn.signInSilently();
      } catch (e) {
        print('Silent sign-in failed: $e');
      }

      print('2. Starting Google Sign-In dialog...');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print('User cancelled Google Sign-In');
        return null;
      }

      print('3. Google account selected: ${googleUser.email}');
      print('4. Getting authentication details...');

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw Exception('Failed to get Google authentication tokens');
      }

      print('5. Creating Firebase credential...');
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print('6. Signing in to Firebase...');
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        print('7. Firebase sign-in successful!');
        print('User ID: ${userCredential.user!.uid}');
        print('Email: ${userCredential.user!.email}');
        print('Display Name: ${userCredential.user!.displayName}');

        // Update local state immediately
        _isUserLoggedIn = true;

        // บันทึกข้อมูลผู้ใช้ใน Firestore
        await _saveUserData(userCredential.user!);

        // แสดง success message หากมี context
        if (context != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'ล็อกอินสำเร็จ! ยินดีต้อนรับ ${getMaskedDisplayName()}',
                style: const TextStyle(fontFamily: 'Kanit'),
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }

        print('8. Login process completed successfully');
        return userCredential;
      } else {
        throw Exception('Firebase authentication failed: no user returned');
      }
    } catch (e) {
      print('Google Sign-In error: $e');

      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'เกิดข้อผิดพลาดในการล็อกอิน: ${e.toString()}',
              style: const TextStyle(fontFamily: 'Kanit'),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }

      return null;
    }
  }

  // ล็อกเอาต์
  static Future<void> signOut({BuildContext? context}) async {
    try {
      print('Starting sign out process...');

      // ล็อกเอาต์จาก Google
      await _googleSignIn.signOut();
      print('Google Sign-In signed out');

      // ล็อกเอาต์จาก Firebase
      await _auth.signOut();
      print('Firebase signed out');

      // รีเซ็ต local cache
      _isUserLoggedIn = false;

      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'ล็อกเอาต์เรียบร้อยแล้ว',
              style: TextStyle(fontFamily: 'Kanit'),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }

      print('Sign out completed successfully');
    } catch (e) {
      print('Sign out error: $e');

      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'เกิดข้อผิดพลาดในการล็อกเอาต์: $e',
              style: const TextStyle(fontFamily: 'Kanit'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // บันทึกข้อมูลผู้ใช้ใน Firestore
  static Future<void> _saveUserData(User user) async {
    try {
      final userDoc = _firestore.collection('users').doc(user.uid);

      // ตรวจสอบว่าผู้ใช้มีข้อมูลอยู่แล้วหรือไม่
      final docSnapshot = await userDoc.get();

      Map<String, dynamic> userData = {
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'lastLoginAt': FieldValue.serverTimestamp(),
      };

      if (docSnapshot.exists) {
        // อัปเดตข้อมูลที่มีอยู่
        await userDoc.update({
          'email': user.email,
          'displayName': user.displayName,
          'photoURL': user.photoURL,
          'lastLoginAt': FieldValue.serverTimestamp(),
        });
        print('User data updated in Firestore');
      } else {
        // สร้างข้อมูลใหม่
        userData['createdAt'] = FieldValue.serverTimestamp();
        await userDoc.set(userData);
        print('New user data created in Firestore');
      }
    } catch (e) {
      print('Error saving user data: $e');
      // ไม่ throw error เพราะการบันทึกข้อมูลไม่สำคัญต่อการล็อกอิน
    }
  }

  // แสดงหน้าล็อกอิน
  static void showLoginScreen(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('กรุณาล็อกอินผ่านโปรไฟล์ในหน้าแผนที่',
            style: TextStyle(fontFamily: 'Kanit')),
        backgroundColor: Colors.orange,
      ),
    );
  }

  // ตรวจสอบ permission และแสดงล็อกอินหากจำเป็น
  static Future<bool> requireAuth(BuildContext context) async {
    if (isLoggedIn) {
      return true;
    }

    // แสดงหน้าล็อกอิน
    showLoginScreen(context);
    return false;
  }

  // ตรวจสอบสถานะการล็อกอิน (force check)
  static bool checkAuthStatus() {
    final currentUser = _auth.currentUser;
    _isUserLoggedIn = currentUser != null;
    print(
        'Force auth status check: $_isUserLoggedIn (user: ${currentUser?.uid})');
    return _isUserLoggedIn;
  }
}
