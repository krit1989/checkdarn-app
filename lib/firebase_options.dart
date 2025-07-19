import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCvwYxr13mQzlk9iFwVF-ixltNNLrmDt1k',
    appId: '1:1051005565361:web:babb8fcfb33f6b0957e590',
    messagingSenderId: '1051005565361',
    projectId: 'checkdarn-app',
    authDomain: 'checkdarn-app.firebaseapp.com',
    storageBucket: 'checkdarn-app.firebasestorage.app',
    measurementId: 'G-J1SR8P4WQC',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCmfosvws-kxETQL7QnslQ1ik0hQ_w5UeM',
    appId: '1:1051005565361:android:03878a41f334bff357e590',
    messagingSenderId: '1051005565361',
    projectId: 'checkdarn-app',
    storageBucket: 'checkdarn-app.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAXvkGJEs31ucJtLUcG4gfn7wK2htXOsGc',
    appId: '1:1051005565361:ios:867711c591c9f42457e590',
    messagingSenderId: '1051005565361',
    projectId: 'checkdarn-app',
    storageBucket: 'checkdarn-app.firebasestorage.app',
    iosBundleId: 'com.example.checkDarn',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBmjWx-Demo-Key-For-Testing',
    appId: '1:123456789:ios:demo-app-id',
    messagingSenderId: '123456789',
    projectId: 'checkdarn-demo',
    iosClientId: 'demo-ios-client-id.apps.googleusercontent.com',
    iosBundleId: 'com.example.checkDarn',
  );
}