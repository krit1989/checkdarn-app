import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'modules/speed_camera/services/camera_report_service.dart';
import 'modules/speed_camera/models/camera_report_model.dart';

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
      // Create a simple test report
      if (AuthService.isLoggedIn) {
        print('สร้างรายงานทดสอบ...');
        await CameraReportService.submitReport(
          latitude: 13.7563,
          longitude: 100.5018,
          roadName: 'ถนนทดสอบ',
          speedLimit: 80,
          type: CameraReportType.newCamera,
          description: 'รายงานทดสอบระบบ',
        );
        setState(() {
          _status = 'สร้างรายงานทดสอบสำเร็จ!';
        });
      } else {
        setState(() {
          _status = 'กรุณาล็อกอินก่อนเพื่อสร้างข้อมูลทดสอบ';
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

  Future<void> _debugPendingReports() async {
    setState(() {
      _isLoading = true;
      _status = 'กำลังตรวจสอบโพสต์รอโหวต...';
    });

    try {
      print('🔍 === DEBUGGING PENDING REPORTS STEP BY STEP ===');

      // Step 1: Check login status
      if (!AuthService.isLoggedIn) {
        setState(() {
          _status = 'กรุณาล็อกอินก่อนเพื่อดูรายงานรอโหวต';
        });
        return;
      }

      print('✅ User is logged in: ${AuthService.currentUser?.email}');

      // Step 2: Get pending reports with full debug
      final pendingReports =
          await CameraReportService.getPendingReports(forceRefresh: true);

      // Step 3: Get user voted reports
      final userVotedReports = await CameraReportService.getUserVotedReports();

      // Step 4: Analyze results
      print('📊 ANALYSIS RESULTS:');
      print('   Total pending reports: ${pendingReports.length}');
      print('   User voted reports: ${userVotedReports.length}');

      if (pendingReports.isEmpty) {
        print('❌ NO PENDING REPORTS FOUND!');
        print('   Possible causes:');
        print('   1. No reports in database');
        print('   2. All reports have non-pending status');
        print('   3. Location filter too restrictive');
        print('   4. Database connection issue');
      } else {
        print('✅ PENDING REPORTS FOUND:');
        for (int i = 0; i < pendingReports.length; i++) {
          final report = pendingReports[i];
          final hasVoted = userVotedReports.contains(report.id);
          print('   ${i + 1}. ${report.roadName}');
          print('      ID: ${report.id}');
          print('      Status: ${report.status}');
          print('      Upvotes: ${report.upvotes}');
          print('      Downvotes: ${report.downvotes}');
          print('      User voted: $hasVoted');
          print('      Reported at: ${report.reportedAt}');
          print('      ---');
        }
      }

      setState(() {
        _status = 'ตรวจสอบเสร็จสิ้น!\n'
            'รายงานรอโหวต: ${pendingReports.length} รายการ\n'
            'รายงานที่โหวตแล้ว: ${userVotedReports.length} รายการ\n'
            'ดูรายละเอียดใน Debug Console';
      });
    } catch (e) {
      print('❌ Error in debug pending reports: $e');
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
      // Test basic functionality
      print('🔍 Testing CameraReportService basic functions...');

      if (AuthService.isLoggedIn) {
        final pendingReports = await CameraReportService.getPendingReports();
        final userStats = await CameraReportService.getUserStats();

        setState(() {
          _status = 'พบรายการรอตรวจสอบ: ${pendingReports.length} รายการ\n'
              'สถิติผู้ใช้: ${userStats.length} รายการ\n'
              'ดู Debug Console สำหรับรายละเอียด\n'
              'Email: ${AuthService.currentUser?.email}';
        });
      } else {
        setState(() {
          _status =
              'ตรวจสอบข้อมูลเสร็จสิ้น\nกรุณาล็อกอินเพื่อดูข้อมูลเพิ่มเติม';
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
              onPressed: _isLoading ? null : _debugPendingReports,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('ดีบักโพสต์รอโหวต'),
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
