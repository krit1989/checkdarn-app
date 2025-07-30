import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'modules/speed_camera/services/camera_report_service.dart';

class TestCreateSampleDataApp extends StatelessWidget {
  const TestCreateSampleDataApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Create Sample Data',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Kanit',
      ),
      home: const TestCreateSampleDataScreen(),
    );
  }
}

class TestCreateSampleDataScreen extends StatefulWidget {
  const TestCreateSampleDataScreen({super.key});

  @override
  State<TestCreateSampleDataScreen> createState() =>
      _TestCreateSampleDataScreenState();
}

class _TestCreateSampleDataScreenState
    extends State<TestCreateSampleDataScreen> {
  bool _isLoading = false;
  String _status = 'พร้อมสร้างข้อมูลทดสอบ';

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      await AuthService.initialize();
      setState(() {
        _status = 'เตรียมพร้อมแล้ว - กรุณาล็อกอินก่อนสร้างข้อมูล';
      });
    } catch (e) {
      setState(() {
        _status = 'เกิดข้อผิดพลาด: $e';
      });
    }
  }

  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
      _status = 'กำลังล็อกอิน...';
    });

    try {
      final result = await AuthService.signInWithGoogle(context: context);
      if (result != null) {
        setState(() {
          _status = 'ล็อกอินสำเร็จ! ตอนนี้สามารถสร้างข้อมูลทดสอบได้';
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

  Future<void> _createSampleData() async {
    if (!AuthService.isLoggedIn) {
      setState(() {
        _status = 'กรุณาล็อกอินก่อนสร้างข้อมูล';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _status = 'กำลังสร้างข้อมูลทดสอบ...';
    });

    try {
      await CameraReportService.createSampleReports();
      setState(() {
        _status =
            'สร้างข้อมูลทดสอบสำเร็จ! ตอนนี้สามารถเห็นรายการรอตรวจสอบได้แล้ว';
      });
    } catch (e) {
      setState(() {
        _status = 'เกิดข้อผิดพลาดในการสร้างข้อมูล: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _debugReports() async {
    setState(() {
      _isLoading = true;
      _status = 'กำลังตรวจสอบข้อมูลในฐานข้อมูล...';
    });

    try {
      await CameraReportService.debugAllReports();
      setState(() {
        _status = 'ตรวจสอบข้อมูลเสร็จสิ้น - ดูผลลัพธ์ใน Debug Console';
      });
    } catch (e) {
      setState(() {
        _status = 'เกิดข้อผิดพลาดในการตรวจสอบข้อมูล: $e';
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
        title: const Text('สร้างข้อมูลทดสอบ'),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'สถานะ:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(_status),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (!AuthService.isLoggedIn) ...[
              ElevatedButton(
                onPressed: _isLoading ? null : _signIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('ล็อกอินด้วย Google'),
              ),
            ] else ...[
              Text(
                'ล็อกอินแล้วในชื่อ: ${AuthService.getMaskedDisplayName()}',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _createSampleData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('สร้างข้อมูลทดสอบ'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _isLoading ? null : _debugReports,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('ตรวจสอบข้อมูลในฐานข้อมูล'),
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
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('ล็อกเอาต์'),
              ),
            ],
            const SizedBox(height: 40),
            const Card(
              color: Colors.blue,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📋 วิธีใช้:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '1. ล็อกอินด้วย Google\n'
                      '2. สร้างข้อมูลทดสอบ\n'
                      '3. กลับไปแอปหลักและเข้าหน้า "รายงาน"\n'
                      '4. ดู Tab "โหวต" จะเห็นรายการรอตรวจสอบ\n'
                      '5. ใช้อีเมล์อื่นล็อกอินเพื่อโหวต',
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

  runApp(const TestCreateSampleDataApp());
}
