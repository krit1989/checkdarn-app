import 'package:flutter/material.dar      // สร้าง test report ด้วยข้อมูล location ที่ถูกต้อง (กรุงเทพฯ)
      final testReport = {
        'title': 'ทดสอบระบบแจ้งเตือน [TEST]',
        'description': 'ทดสอบแจ้งเตือนระบบจากกรุงเทพฯ [TEST DATA]',
        'category': 'traffic', // เปลี่ยนเป็น traffic แทนแผ่นดินไหว
        'type': 'ปัญหาการจราจร',
        'timestamp': FieldValue.serverTimestamp(),

        // ใช้พิกัดกรุงเทพฯ ที่ถูกต้อง (อนุสาวรีย์ประชาธิปไตย)
        'lat': 13.7563, // Bangkok latitude (อนุสาวรีย์ประชาธิปไตย)
        'lng': 100.5018, // Bangkok longitude

        'location': 'กรุงเทพมหานคร',
        'district': 'กรุงเทพมหานคร', 
        'province': 'กรุงเทพมหานคร',kage:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(TestApp());
}

class TestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test Notification',
      home: TestNotificationScreen(),
    );
  }
}

class TestNotificationScreen extends StatefulWidget {
  @override
  _TestNotificationScreenState createState() => _TestNotificationScreenState();
}

class _TestNotificationScreenState extends State<TestNotificationScreen> {
  bool _isCreating = false;
  String _result = '';

  Future<void> _createTestReport() async {
    setState(() {
      _isCreating = true;
      _result = 'กำลังสร้าง test report...';
    });

    try {
      // สร้าง test report ด้วยข้อมูล location ที่ถูกต้อง (กรุงเทพฯ)
      final testReport = {
        'title': 'ทดสอบระบบแจ้งเตือน [TEST]',
        'description': 'ทดสอบแจ้งเตือนระบบจากกรุงเทพฯ [TEST DATA]',
        'category': 'traffic', // เปลี่ยนเป็น traffic แทนแผ่นดินไหว
        'type': 'ปัญหาการจราจร',
        'timestamp': FieldValue.serverTimestamp(),

        // ใช้พิกัดกรุงเทพฯ ที่ถูกต้อง (อนุสาวรีย์ประชาธิปไตย)
        'lat': 13.7563, // Bangkok latitude (อนุสาวรีย์ประชาธิปไตย)
        'lng': 100.5018, // Bangkok longitude

        'location': 'กรุงเทพมหานคร',
        'district': 'กรุงเทพมหานคร',
        'province': 'กรุงเทพมหานคร',
        'userId': 'test_user_123',
        'userName': 'Kritchapon Test',
        'displayName': 'Kritchapon Test',
        'reporterName': 'Kritchapon Prommali', // เพิ่มชื่อสำหรับการ mask
        'status': 'active',
        'imageUrl': '',
        'expireAt': Timestamp.fromDate(DateTime.now().add(Duration(days: 7))),
      };

      // บันทึกไปยัง Firestore
      final docRef = await FirebaseFirestore.instance
          .collection('reports')
          .add(testReport);

      setState(() {
        _result = '✅ สร้าง test report สำเร็จ!\n'
            'Document ID: ${docRef.id}\n'
            'Location: lat=${testReport['lat']}, lng=${testReport['lng']}\n'
            'ตรวจสอบ Cloud Functions logs เพื่อดูผลลัพธ์';
      });

      print('🎉 Test report created successfully!');
      print('📍 Location: ${testReport['lat']}, ${testReport['lng']}');
      print('📋 Document ID: ${docRef.id}');
    } catch (error) {
      setState(() {
        _result = '❌ เกิดข้อผิดพลาด: $error';
      });
      print('❌ Error creating test report: $error');
    }

    setState(() {
      _isCreating = false;
    });
  }

  Future<void> _checkRecentReports() async {
    setState(() {
      _result = 'กำลังตรวจสอบ reports ล่าสุด...';
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('reports')
          .orderBy('timestamp', descending: true)
          .limit(3)
          .get();

      String resultText =
          '📊 Reports ล่าสุด ${snapshot.docs.length} รายการ:\n\n';

      for (int i = 0; i < snapshot.docs.length; i++) {
        final doc = snapshot.docs[i];
        final data = doc.data();

        resultText += '${i + 1}. ${doc.id}\n';
        resultText += '   Title: ${data['title'] ?? 'ไม่มี'}\n';
        resultText += '   Category: ${data['category'] ?? 'ไม่มี'}\n';

        // ตรวจสอบข้อมูล location
        if (data['lat'] != null && data['lng'] != null) {
          resultText += '   ✅ Location: ${data['lat']}, ${data['lng']}\n';
        } else {
          resultText += '   ❌ ไม่มีข้อมูล lat/lng\n';
        }

        if (data['timestamp'] != null) {
          final timestamp = data['timestamp'] as Timestamp;
          resultText += '   Time: ${timestamp.toDate().toString()}\n';
        }

        resultText += '\n';
      }

      setState(() {
        _result = resultText;
      });
    } catch (error) {
      setState(() {
        _result = '❌ เกิดข้อผิดพลาด: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Test Notification System'),
        backgroundColor: Color(0xFFFDC621),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _isCreating ? null : _createTestReport,
              child: _isCreating
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('กำลังสร้าง...'),
                      ],
                    )
                  : Text('สร้าง Test Report'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4673E5),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _checkRecentReports,
              child: Text('ตรวจสอบ Reports ล่าสุด'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            SizedBox(height: 24),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _result.isEmpty ? 'กดปุ่มเพื่อทดสอบระบบ' : _result,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.all(12),
              margin: EdgeInsets.only(top: 16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Text(
                '💡 วิธีใช้:\n'
                '1. กด "สร้าง Test Report" เพื่อสร้าง report ทดสอบ\n'
                '2. ตรวจสอบ Cloud Functions logs ว่ามีการแจ้งเตือนหรือไม่\n'
                '3. กด "ตรวจสอบ Reports ล่าสุด" เพื่อดูข้อมูล',
                style: TextStyle(fontSize: 12, color: Colors.blue[800]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
