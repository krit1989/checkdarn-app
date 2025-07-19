import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginTestScreen extends StatefulWidget {
  const LoginTestScreen({super.key});

  @override
  State<LoginTestScreen> createState() => _LoginTestScreenState();
}

class _LoginTestScreenState extends State<LoginTestScreen> {
  bool _isLoading = false;
  String _status = 'พร้อมทดสอบ';

  @override
  void initState() {
    super.initState();
    _checkCurrentStatus();
  }

  Future<void> _checkCurrentStatus() async {
    await AuthService.initialize();
    await AuthService.debugAuthStatus();
    setState(() {
      _status = AuthService.isLoggedIn ? 'ล็อกอินแล้ว' : 'ยังไม่ล็อกอิน';
    });
  }

  Future<void> _testLogin() async {
    setState(() {
      _isLoading = true;
      _status = 'กำลังทดสอบล็อกอิน...';
    });

    try {
      print('🧪 เริ่มทดสอบการล็อกอิน...');
      final result = await AuthService.signInWithGoogle();

      if (result != null) {
        setState(() {
          _status = 'ล็อกอินสำเร็จ: ${result.user?.email}';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ล็อกอินสำเร็จ: ${result.user?.displayName}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _status = 'ผู้ใช้ยกเลิกการล็อกอิน';
        });
      }
    } catch (e) {
      print('❌ ทดสอบล็อกอินล้มเหลว: $e');
      setState(() {
        _status = 'ล็อกอินล้มเหลว: $e';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ล็อกอินล้มเหลว: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
        _status = 'ออกจากระบบแล้ว';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ออกจากระบบสำเร็จ'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ออกจากระบบล้มเหลว: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ทดสอบการล็อกอิน'),
        backgroundColor: const Color(0xFF1B2D3F),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'สถานะการล็อกอิน',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                _status,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(height: 24),
            if (AuthService.currentUser != null) ...[
              const Text(
                'ข้อมูลผู้ใช้',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('UID: ${AuthService.currentUser!.uid}'),
                    Text('Email: ${AuthService.currentUser!.email}'),
                    Text(
                        'Display Name: ${AuthService.currentUser!.displayName}'),
                    Text('Photo URL: ${AuthService.currentUser!.photoURL}'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            const Text(
              'การทดสอบ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _testLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4285F4),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
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
                          SizedBox(width: 8),
                          Text('กำลังทดสอบ...'),
                        ],
                      )
                    : const Text('ทดสอบการล็อกอิน'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _checkCurrentStatus,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('ตรวจสอบสถานะ'),
              ),
            ),
            const SizedBox(height: 12),
            if (AuthService.currentUser != null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _testSignOut,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('ออกจากระบบ'),
                ),
              ),
            const SizedBox(height: 32),
            const Text(
              'หมายเหตุ:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '• ดู Console/Log เพื่อรายละเอียดการ debug\n'
              '• ตรวจสอบ Google Services และ Firebase Console\n'
              '• ตรวจสอบ SHA-1 fingerprint ใน Firebase\n'
              '• ทดสอบบนอุปกรณ์จริง ไม่ใช่ Emulator',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
