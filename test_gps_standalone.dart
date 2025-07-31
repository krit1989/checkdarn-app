import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

void main() {
  runApp(GPSTestApp());
}

class GPSTestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GPS Test',
      home: GPSTestScreen(),
    );
  }
}

class GPSTestScreen extends StatefulWidget {
  @override
  _GPSTestScreenState createState() => _GPSTestScreenState();
}

class _GPSTestScreenState extends State<GPSTestScreen> {
  String statusMessage = 'Initializing...';
  bool isLoading = false;
  Position? currentPosition;

  @override
  void initState() {
    super.initState();
    _testGPS();
  }

  Future<void> _testGPS() async {
    setState(() {
      isLoading = true;
      statusMessage = 'Testing GPS...';
    });

    try {
      // ตรวจสอบ Location Services
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (kDebugMode) {
        debugPrint(
            '📡 Location Services: ${serviceEnabled ? "✅ ENABLED" : "❌ DISABLED"}');
      }

      if (!serviceEnabled) {
        setState(() {
          statusMessage =
              '❌ Location services are DISABLED\n\nPlease enable in device settings:\nSettings > Privacy & Security > Location Services';
          isLoading = false;
        });
        return;
      }

      // ตรวจสอบ Permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (kDebugMode) {
        debugPrint('🔐 Location Permission: $permission');
      }

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            statusMessage = '❌ Location permission DENIED by user';
            isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          statusMessage =
              '❌ Location permission PERMANENTLY DENIED\n\nPlease enable in app settings';
          isLoading = false;
        });
        return;
      }

      setState(() {
        statusMessage = '✅ Permissions OK\n🔍 Getting GPS position...';
      });

      // หาตำแหน่งปัจจุบัน
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      setState(() {
        currentPosition = position;
        statusMessage = '✅ GPS SUCCESS!\n\n'
            'Latitude: ${position.latitude}\n'
            'Longitude: ${position.longitude}\n'
            'Accuracy: ${position.accuracy}m\n'
            'Speed: ${position.speed}m/s';
        isLoading = false;
      });

      if (kDebugMode) {
        debugPrint(
            '✅ GPS SUCCESS: ${position.latitude}, ${position.longitude}');
      }
    } catch (e) {
      setState(() {
        statusMessage = '❌ GPS ERROR: $e';
        isLoading = false;
      });

      if (kDebugMode) {
        debugPrint('❌ GPS ERROR: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('GPS Test'),
        backgroundColor: Color(0xFF4673E5),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isLoading)
              Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4673E5)),
                ),
              ),
            SizedBox(height: 20),
            Text(
              statusMessage,
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'Sarabun',
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _testGPS,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF4673E5),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: Text('🔄 Test Again'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
