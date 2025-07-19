import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/map_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CheckDarn - แผนที่เหตุการณ์',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Sarabun',
      ),
      home: const MapScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
