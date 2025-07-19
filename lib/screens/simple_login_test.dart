import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class SimpleLoginTest extends StatefulWidget {
  const SimpleLoginTest({super.key});

  @override
  State<SimpleLoginTest> createState() => _SimpleLoginTestState();
}

class _SimpleLoginTestState extends State<SimpleLoginTest> {
  String _status = 'พร้อมทดสอบ';
  bool _isLoading = false;

  Future<void> _testSimpleLogin() async {
    setState(() {
      _isLoading = true;
      _status = 'กำลังทดสอบ...';
    });

    try {
      print('🧪 === เริ่มทดสอบการล็อกอิน ===');

      // ทดสอบ 1: ตรวจสอบสถานะเริ่มต้น
      await AuthService.initialize();
      setState(() {
        _status =
            'เริ่มต้น AuthService แล้ว\nสถานะล็อกอิน: ${AuthService.isLoggedIn}';
      });

      await Future.delayed(const Duration(seconds: 2));

      // ทดสอบ 2: debug auth status
      await AuthService.debugAuthStatus();
      setState(() {
        _status = 'ตรวจสอบสถานะ Auth แล้ว\nดูรายละเอียดใน Console';
      });

      await Future.delayed(const Duration(seconds: 2));

      // ทดสอบ 3: ลองล็อกอิน
      setState(() {
        _status = 'กำลังพยายามล็อกอิน Google...';
      });

      final result = await AuthService.signInWithGoogle(context: context);

      if (result != null) {
        setState(() {
          _status =
              '✅ ล็อกอินสำเร็จ!\nUser: ${result.user?.displayName}\nEmail: ${result.user?.email}';
        });
      } else {
        setState(() {
          _status = '❌ ผู้ใช้ยกเลิกการล็อกอิน';
        });
      }
    } catch (e) {
      setState(() {
        _status = '❌ เกิดข้อผิดพลาด:\n$e';
      });
      print('❌ Test login error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testSignOut() async {
    try {
      await AuthService.signOut();
      setState(() {
        _status = '✅ ออกจากระบบสำเร็จ';
      });
    } catch (e) {
      setState(() {
        _status = '❌ ออกจากระบบล้มเหลว: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ทดสอบการล็อกอิน'),
        backgroundColor: const Color(0xFF4285F4),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'ทดสอบระบบล็อกอิน Google',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10),
                color: Colors.grey.shade50,
              ),
              child: Column(
                children: [
                  const Text(
                    'สถานะ:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _status,
                    style: const TextStyle(fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isLoading ? null : _testSimpleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4285F4),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isLoading
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 10),
                        Text('กำลังทดสอบ...'),
                      ],
                    )
                  : const Text(
                      'ทดสอบล็อกอิน Google',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
            const SizedBox(height: 15),
            OutlinedButton(
              onPressed: _isLoading ? null : _testSignOut,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF4285F4)),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'ออกจากระบบ',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF4285F4),
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Divider(),
            const Text(
              'หมายเหตุ:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '• Google Sign-In อาจไม่ทำงานใน Android Emulator\n'
              '• ลองใช้อุปกรณ์จริงเพื่อผลลัพธ์ที่แม่นยำ\n'
              '• ตรวจสอบ Console สำหรับรายละเอียดเพิ่มเติม',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
