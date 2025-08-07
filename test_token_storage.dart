import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  await Firebase.initializeApp();

  // สร้างข้อมูลทดสอบในคอลเลคชั่น user_tokens
  await FirebaseFirestore.instance
      .collection('user_tokens')
      .doc('test_user_1')
      .set({
    'tokens': ['dummy_token_1', 'dummy_token_2'],
    'lastUpdated': Timestamp.now(),
  });

  await FirebaseFirestore.instance
      .collection('user_tokens')
      .doc('test_user_2')
      .set({
    'tokens': ['dummy_token_3', 'dummy_token_4'],
    'lastUpdated': Timestamp.now(),
  });

  print('✅ สร้างข้อมูลทดสอบใน user_tokens เสร็จแล้ว');

  // เช็คข้อมูลที่สร้าง
  final tokens =
      await FirebaseFirestore.instance.collection('user_tokens').get();
  print('📊 จำนวน user_tokens: ${tokens.docs.length}');

  for (var doc in tokens.docs) {
    print('User: ${doc.id}, Tokens: ${doc.data()['tokens']}');
  }
}
