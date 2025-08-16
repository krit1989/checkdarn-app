import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ฟังก์ชันเช็คข้อมูลใน Firebase ใน Flutter environment
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Debug Firebase Data',
      home: DebugScreen(),
    );
  }
}

class DebugScreen extends StatefulWidget {
  @override
  _DebugScreenState createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  String _result = '';
  bool _isLoading = false;

  Future<void> _checkFirebaseData() async {
    setState(() {
      _isLoading = true;
      _result = 'กำลังตรวจสอบข้อมูล...';
    });

    try {
      final firestore = FirebaseFirestore.instance;

      // เช็ค reports ล่าสุด 10 อัน
      print('📊 กำลังดึงข้อมูล reports ล่าสุด...');
      final snapshot = await firestore
          .collection('reports')
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      String resultText =
          '📊 Reports ล่าสุด ${snapshot.docs.length} รายการ:\n\n';

      for (int i = 0; i < snapshot.docs.length; i++) {
        final doc = snapshot.docs[i];
        final data = doc.data();

        resultText += '${i + 1}. ${doc.id}\n';
        resultText += '   Title: ${data['title'] ?? 'ไม่มี'}\n';
        resultText += '   Description: ${data['description'] ?? 'ไม่มี'}\n';
        resultText += '   Location: ${data['location'] ?? 'ไม่มี'}\n';
        resultText += '   District: ${data['district'] ?? 'ไม่มี'}\n';
        resultText += '   Province: ${data['province'] ?? 'ไม่มี'}\n';
        resultText += '   Coordinates: (${data['lat']}, ${data['lng']})\n';

        if (data['timestamp'] != null) {
          final timestamp = data['timestamp'] as Timestamp;
          resultText += '   Time: ${timestamp.toDate().toString()}\n';
        }

        // เช็คว่าเป็นข้อมูล test หรือไม่
        if (data['userId'] == 'test_user_123' ||
            data['description']?.toString().contains('พานทอง') == true ||
            (data['lat'] == 13.0827 && data['lng'] == 101.0028)) {
          resultText += '   🚨 นี่คือข้อมูล TEST ที่ต้องลบ!\n';
        }

        resultText += '\n';
      }

      // เช็คข้อมูลเฉพาะที่มีปัญหา
      print('🔍 กำลังค้นหาข้อมูล test ที่มีปัญหา...');

      // ค้นหาข้อมูลที่มี พิกัด test เดิม
      final testCoordQuery = await firestore
          .collection('reports')
          .where('lat', isEqualTo: 13.0827)
          .get();

      if (testCoordQuery.docs.isNotEmpty) {
        resultText +=
            '\n🚨 พบข้อมูล test ที่มีพิกัดผิด ${testCoordQuery.docs.length} รายการ:\n';
        for (final doc in testCoordQuery.docs) {
          final data = doc.data();
          if (data['lng'] == 101.0028) {
            resultText += '- ${doc.id}: ${data['location']}\n';
          }
        }
      }

      // ค้นหาข้อมูลที่มี userId test
      final testUserQuery = await firestore
          .collection('reports')
          .where('userId', isEqualTo: 'test_user_123')
          .get();

      if (testUserQuery.docs.isNotEmpty) {
        resultText +=
            '\n🚨 พบข้อมูล test user ${testUserQuery.docs.length} รายการ:\n';
        for (final doc in testUserQuery.docs) {
          final data = doc.data();
          resultText += '- ${doc.id}: ${data['location']}\n';
        }
      }

      setState(() {
        _result = resultText;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _result = '❌ เกิดข้อผิดพลาด: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Debug Firebase Data'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _isLoading ? null : _checkFirebaseData,
              child: _isLoading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('กำลังตรวจสอบ...'),
                      ],
                    )
                  : Text('ตรวจสอบข้อมูล Firebase'),
            ),
            SizedBox(height: 16),
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
                    _result.isEmpty ? 'กดปุ่มเพื่อตรวจสอบข้อมูล' : _result,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
