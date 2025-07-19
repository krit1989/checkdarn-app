import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  List<Map<String, dynamic>> debugInfo = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkFirebaseData();
  }

  Future<void> _checkFirebaseData() async {
    setState(() {
      isLoading = true;
      debugInfo.clear();
    });

    try {
      // 1. ตรวจสอบ Firestore Collection
      final reportsSnapshot = await _firestore
          .collection('reports')
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      debugInfo.add({
        'type': 'info',
        'title': '📊 Firestore Reports Collection',
        'content': 'พบ ${reportsSnapshot.docs.length} รายการ',
      });

      // 2. ตรวจสอบแต่ละรายงานที่มี imageUrl
      for (var doc in reportsSnapshot.docs) {
        final data = doc.data();
        final imageUrl = data['imageUrl'] as String?;

        if (imageUrl != null && imageUrl.isNotEmpty) {
          debugInfo.add({
            'type': 'success',
            'title': '✅ Report ID: ${doc.id}',
            'content':
                'มี imageUrl: ${imageUrl.substring(0, imageUrl.length > 50 ? 50 : imageUrl.length)}${imageUrl.length > 50 ? "..." : ""}',
          });

          // ตรวจสอบว่า URL สามารถเข้าถึงได้หรือไม่
          try {
            final ref = _storage.refFromURL(imageUrl);
            final metadata = await ref.getMetadata();
            debugInfo.add({
              'type': 'success',
              'title': '  🟢 Storage File Check',
              'content':
                  'ไฟล์มีอยู่จริง - ขนาด: ${(metadata.size! / 1024).toStringAsFixed(1)} KB',
            });
          } catch (e) {
            debugInfo.add({
              'type': 'error',
              'title': '  🔴 Storage File Error',
              'content': 'ไฟล์ไม่พบใน Storage: $e',
            });
          }
        } else {
          debugInfo.add({
            'type': 'warning',
            'title': '⚠️ Report ID: ${doc.id}',
            'content': 'ไม่มี imageUrl หรือ imageUrl ว่าง',
          });
        }
      }

      // 3. ตรวจสอบ Storage Rules
      debugInfo.add({
        'type': 'info',
        'title': '🔒 Storage Rules Check',
        'content':
            'กรุณาตรวจสอบ Firebase Console → Storage → Rules\nควรมี: allow read: if true; สำหรับการทดสอบ',
      });

      // 4. ตรวจสอบ Storage Bucket
      try {
        final ref = _storage.ref('reports/');
        final listResult = await ref.listAll();
        debugInfo.add({
          'type': 'success',
          'title': '📁 Storage /reports/ folder',
          'content': 'พบไฟล์ ${listResult.items.length} ไฟล์',
        });

        for (var item in listResult.items.take(5)) {
          final metadata = await item.getMetadata();
          final downloadUrl = await item.getDownloadURL();
          debugInfo.add({
            'type': 'info',
            'title': '  📄 ${item.name}',
            'content':
                'ขนาด: ${(metadata.size! / 1024).toStringAsFixed(1)} KB\nURL: ${downloadUrl.substring(0, 50)}...',
          });
        }
      } catch (e) {
        debugInfo.add({
          'type': 'error',
          'title': '🔴 Storage Access Error',
          'content': 'ไม่สามารถเข้าถึง Storage: $e',
        });
      }
    } catch (e) {
      debugInfo.add({
        'type': 'error',
        'title': '❌ Error',
        'content': 'เกิดข้อผิดพลาด: $e',
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'success':
        return Colors.green;
      case 'error':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔍 Firebase Debug'),
        backgroundColor: const Color(0xFFFF9800),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkFirebaseData,
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('กำลังตรวจสอบข้อมูล Firebase...'),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: debugInfo.length,
              itemBuilder: (context, index) {
                final info = debugInfo[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(
                      Icons.circle,
                      color: _getColorForType(info['type']),
                      size: 12,
                    ),
                    title: Text(
                      info['title'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getColorForType(info['type']),
                      ),
                    ),
                    subtitle: Text(info['content']),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // แสดง Storage Rules ที่แนะนำ
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('🔒 Firebase Storage Rules'),
              content: const SingleChildScrollView(
                child: Text('''สำหรับการทดสอบ ให้ใช้ Rules นี้:

rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if true;
    }
  }
}

สำหรับ Production ให้ใช้:

rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /reports/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}'''),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('ปิด'),
                ),
              ],
            ),
          );
        },
        backgroundColor: const Color(0xFFFF9800),
        child: const Icon(Icons.security),
      ),
    );
  }
}
