import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'modules/speed_camera/services/camera_report_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Firebase initialization error: $e');
  }

  runApp(const QuickTestApp());
}

class QuickTestApp extends StatelessWidget {
  const QuickTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quick Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Kanit',
      ),
      home: const QuickTestScreen(),
    );
  }
}

class QuickTestScreen extends StatefulWidget {
  const QuickTestScreen({super.key});

  @override
  State<QuickTestScreen> createState() => _QuickTestScreenState();
}

class _QuickTestScreenState extends State<QuickTestScreen> {
  String _status = 'กรุณาเลือกการทดสอบ';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      await AuthService.initialize();
      setState(() {
        _status = 'เริ่มต้นระบบสำเร็จ';
      });
    } catch (e) {
      setState(() {
        _status = 'เกิดข้อผิดพลาด: $e';
      });
    }
  }

  Future<void> _testLogin() async {
    setState(() {
      _isLoading = true;
      _status = 'กำลังทดสอบล็อกอิน...';
    });

    try {
      final result = await AuthService.signInWithGoogle(context: context);
      if (result != null) {
        setState(() {
          _status = 'ล็อกอินสำเร็จ! UID: ${result.user?.uid}';
        });
      } else {
        setState(() {
          _status = 'การล็อกอินถูกยกเลิก';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'เกิดข้อผิดพลาดในการล็อกอิน: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createData() async {
    if (!AuthService.isLoggedIn) {
      setState(() {
        _status = 'กรุณาล็อกอินก่อน';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _status = 'กำลังสร้างข้อมูลตัวอย่าง...';
    });

    try {
      await CameraReportService.createSampleReports();
      setState(() {
        _status = 'สร้างข้อมูลตัวอย่างสำเร็จ!';
      });
    } catch (e) {
      setState(() {
        _status = 'เกิดข้อผิดพลาด: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _debugData() async {
    setState(() {
      _isLoading = true;
      _status = 'กำลังตรวจสอบข้อมูล...';
    });

    try {
      await CameraReportService.debugAllReports();

      if (AuthService.isLoggedIn) {
        // Test multi-user functionality
        await CameraReportService.debugMultiUserTest();

        final pendingReports = await CameraReportService.getPendingReports();
        setState(() {
          _status = 'พบรายการรอตรวจสอบ: ${pendingReports.length} รายการ\n'
              'ดู Debug Console สำหรับรายละเอียด\n'
              'Email: ${AuthService.currentUser?.email}';
        });
      } else {
        setState(() {
          _status = 'ตรวจสอบข้อมูลเสร็จสิ้น\nดูผลลัพธ์ใน Debug Console';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'เกิดข้อผิดพลาด: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _status,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _testLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('ทดสอบล็อกอิน'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isLoading ? null : _createData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('สร้างข้อมูลตัวอย่าง'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isLoading ? null : _debugData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('ตรวจสอบข้อมูล'),
            ),
            const SizedBox(height: 20),
            if (AuthService.isLoggedIn) ...[
              Text(
                'ล็อกอินแล้ว: ${AuthService.getMaskedDisplayName()}',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Email: ${AuthService.currentUser?.email}',
                style: const TextStyle(
                  color: Colors.blue,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () async {
                  await AuthService.signOut(context: context);
                  setState(() {
                    _status = 'ล็อกเอาต์แล้ว - กรุณาล็อกอินใหม่';
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('ล็อกเอาต์'),
              ),
            ],
            const SizedBox(height: 20),
            const Card(
              color: Colors.blue,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📋 วิธีทดสอบ Multi-User:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '1. Account A: ล็อกอิน → สร้างข้อมูลตัวอย่าง\n'
                      '2. Account A: ตรวจสอบข้อมูล (จะเห็นตัวเลข reports)\n'
                      '3. Account A: ล็อกเอาต์\n'
                      '4. Account B: ล็อกอินด้วยอีเมล์อื่น\n'
                      '5. Account B: ตรวจสอบข้อมูล (ควรเห็นรายการให้โหวต)\n'
                      '6. ถ้าไม่เห็น = ปัญหา Firebase Rules',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
