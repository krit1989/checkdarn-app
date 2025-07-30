import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'auth_service.dart';

/// Debug helper สำหรับ Authentication issues
class AuthDebugHelper {
  static void debugDependencies() {
    print('🔍 === DEBUG DEPENDENCIES ===');
    print('Firebase Auth version: Check pubspec.yaml');
    print('Google Sign In version: Check pubspec.yaml');
    print('=================================');
  }

  static Future<void> testGoogleSignIn() async {
    try {
      print('🧪 Testing Google Sign-In independently...');

      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut(); // Clear cache

      final GoogleSignInAccount? account = await googleSignIn.signIn();
      if (account != null) {
        print('✅ Google Sign-In successful: ${account.email}');

        final GoogleSignInAuthentication auth = await account.authentication;
        print('✅ Got authentication tokens');
        print('Access Token: ${auth.accessToken != null ? 'YES' : 'NO'}');
        print('ID Token: ${auth.idToken != null ? 'YES' : 'NO'}');

        await googleSignIn.signOut();
        print('✅ Google Sign-Out successful');
      } else {
        print('❌ Google Sign-In cancelled');
      }
    } catch (e) {
      print('❌ Google Sign-In test failed: $e');
    }
  }

  static Future<void> testFirebaseAuth() async {
    try {
      print('🧪 Testing Firebase Auth independently...');

      final FirebaseAuth auth = FirebaseAuth.instance;
      final User? currentUser = auth.currentUser;

      print('Current User: ${currentUser?.uid ?? 'None'}');
      print('Auth State: ${currentUser != null ? 'LOGGED_IN' : 'LOGGED_OUT'}');

      // Test auth state stream
      auth.authStateChanges().listen((User? user) {
        print('Auth State Change: ${user?.uid ?? 'null'}');
      });
    } catch (e) {
      print('❌ Firebase Auth test failed: $e');
    }
  }

  static Widget buildDebugInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🔧 Auth Debug Info',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildInfoRow(
              'Auth Service Initialized', AuthService.isLoggedIn.toString()),
          _buildInfoRow('Current User', AuthService.currentUser?.uid ?? 'None'),
          _buildInfoRow('User Email', AuthService.currentUser?.email ?? 'None'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => testGoogleSignIn(),
            child: const Text('Test Google Sign-In'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => testFirebaseAuth(),
            child: const Text('Test Firebase Auth'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => AuthService.debugAuthStatus(),
            child: const Text('Debug Auth Status'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => debugDependencies(),
            child: const Text('Debug Dependencies'),
          ),
        ],
      ),
    );
  }

  static Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
