// Manual cleanup script for verified reports
// Run: dart cleanup_verified_reports.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  print('🧹 === VERIFIED REPORTS CLEANUP SCRIPT ===');

  try {
    // Initialize Firebase
    await Firebase.initializeApp();
    print('✅ Firebase initialized');

    final firestore = FirebaseFirestore.instance;

    // 1. ค้นหาทุกรายงานที่มี status verified
    print('\n📋 Step 1: Finding all verified reports...');
    final verifiedReportsQuery = await firestore
        .collection('camera_reports')
        .where('status', isEqualTo: 'verified')
        .get();

    print('Found ${verifiedReportsQuery.docs.length} verified reports');

    if (verifiedReportsQuery.docs.isEmpty) {
      print('✅ No verified reports found - database is already clean!');
      return;
    }

    // 2. แสดงรายการ verified reports
    print('\n📋 Step 2: Listing verified reports to be deleted:');
    for (int i = 0; i < verifiedReportsQuery.docs.length; i++) {
      final doc = verifiedReportsQuery.docs[i];
      final data = doc.data() as Map<String, dynamic>?;

      if (data != null) {
        final roadName = data['roadName'] ?? 'Unknown Road';
        final type = data['type'] ?? 'unknown';
        final verifiedAt =
            data['verifiedAt'] ?? data['processedAt'] ?? 'unknown';

        print('   ${i + 1}. ${doc.id}');
        print('      Road: $roadName');
        print('      Type: $type');
        print('      Verified/Processed: $verifiedAt');
        print('');
      }
    }

    // 3. ขอยืนยันจากผู้ใช้
    print(
        '\n⚠️  WARNING: This will permanently delete ${verifiedReportsQuery.docs.length} verified reports!');
    print('Do you want to continue? (type "yes" to confirm): ');

    final input = stdin.readLineSync();
    if (input?.toLowerCase() != 'yes') {
      print('❌ Operation cancelled by user');
      return;
    }

    // 4. ลบข้อมูล
    print('\n📋 Step 3: Deleting verified reports...');
    final batch = firestore.batch();

    for (final doc in verifiedReportsQuery.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
    print(
        '✅ Successfully deleted ${verifiedReportsQuery.docs.length} verified reports');

    // 5. บันทึก log
    print('\n📋 Step 4: Creating cleanup log...');
    await firestore.collection('verified_reports_cleanup_log').add({
      'cleanupTimestamp': FieldValue.serverTimestamp(),
      'verifiedReportsFound': verifiedReportsQuery.docs.length,
      'reportsDeleted': verifiedReportsQuery.docs.length,
      'cleanupMethod': 'manual_script',
      'success': true,
    });

    print('✅ Cleanup log created successfully');
    print('\n🎉 === CLEANUP COMPLETE ===');
    print('Database is now clean of verified reports!');
  } catch (e) {
    print('❌ Error during cleanup: $e');
    exit(1);
  }
}
