import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // ทดสอบการเชื่อมต่อ Firestore
  print('🔥 Testing Firestore connection...');

  try {
    final firestore = FirebaseFirestore.instance;

    // ทดสอบการอ่านข้อมูล
    print('📖 Testing read operation...');
    final testRead = await firestore
        .collection('reports')
        .limit(1)
        .get()
        .timeout(Duration(seconds: 10));
    print('✅ Read test passed: ${testRead.docs.length} documents');

    // ทดสอบการเขียนข้อมูล
    print('📝 Testing write operation...');
    final testDoc = await firestore.collection('test_reports').add({
      'test': true,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'active',
    }).timeout(Duration(seconds: 10));
    print('✅ Write test passed: ${testDoc.id}');

    // ลบ test document
    await testDoc.delete();
    print('✅ Delete test passed');

    print('🎉 All Firestore tests passed!');
  } catch (e) {
    print('❌ Firestore test failed: $e');
    print('❌ Error type: ${e.runtimeType}');
  }
}
