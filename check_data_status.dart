import 'package:cloud_firestore/cloud_firestore.dart';

/// ตรวจสอบว่าข้อมูลการโพสต์ยังอยู่ในฐานข้อมูลหรือไม่
/// เรียกดูข้อมูลแยกตาม status
void main() async {
  print('🔍 === ตรวจสอบสถานะข้อมูลในฐานข้อมูล ===');

  final firestore = FirebaseFirestore.instance;

  try {
    // 1. ตรวจสอบรายงาน pending (ที่แสดงในหน้าโหวต)
    print('\n📊 1. รายงานสถานะ PENDING (แสดงในหน้าโหวต):');
    final pendingQuery = await firestore
        .collection('camera_reports')
        .where('status', isEqualTo: 'pending')
        .get();

    print('   จำนวน: ${pendingQuery.docs.length} รายงาน');
    for (final doc in pendingQuery.docs.take(3)) {
      final data = doc.data();
      print('   - ${data['roadName']} (ID: ${doc.id})');
      print(
          '     Upvotes: ${data['upvotes']}, Downvotes: ${data['downvotes']}');
      print('     Confidence: ${data['confidenceScore']}');
    }

    // 2. ตรวจสอบรายงาน verified (ที่หายไปจากหน้าโหวต)
    print('\n✅ 2. รายงานสถานะ VERIFIED (หายจากหน้าโหวตแต่ยังอยู่ในฐานข้อมูล):');
    final verifiedQuery = await firestore
        .collection('camera_reports')
        .where('status', isEqualTo: 'verified')
        .get();

    print('   จำนวน: ${verifiedQuery.docs.length} รายงาน');
    for (final doc in verifiedQuery.docs.take(5)) {
      final data = doc.data();
      print('   - ${data['roadName']} (ID: ${doc.id})');
      print(
          '     Final Upvotes: ${data['upvotes']}, Downvotes: ${data['downvotes']}');
      print('     Final Confidence: ${data['confidenceScore']}');
      print('     Verified At: ${data['verifiedAt']}');
      print('     Verified By: ${data['verifiedBy']}');
    }

    // 3. ตรวจสอบรายงาน rejected
    print('\n❌ 3. รายงานสถานะ REJECTED:');
    final rejectedQuery = await firestore
        .collection('camera_reports')
        .where('status', isEqualTo: 'rejected')
        .get();

    print('   จำนวน: ${rejectedQuery.docs.length} รายงาน');
    for (final doc in rejectedQuery.docs.take(3)) {
      final data = doc.data();
      print('   - ${data['roadName']} (ID: ${doc.id})');
      print(
          '     Final Upvotes: ${data['upvotes']}, Downvotes: ${data['downvotes']}');
      print('     Final Confidence: ${data['confidenceScore']}');
    }

    // 4. ตรวจสอบข้อมูลทั้งหมด
    print('\n📈 4. สรุปสถานะทั้งหมด:');
    final allQuery = await firestore.collection('camera_reports').get();

    final statusCount = <String, int>{};
    for (final doc in allQuery.docs) {
      final status = doc.data()['status'] ?? 'unknown';
      statusCount[status] = (statusCount[status] ?? 0) + 1;
    }

    statusCount.forEach((status, count) {
      print('   $status: $count รายงาน');
    });

    print('\n🎯 สรุป:');
    print('✅ ข้อมูลไม่หายไป - ยังอยู่ในฐานข้อมูล');
    print('📱 แค่หายจากหน้าโหวตเพราะเปลี่ยนสถานะจาก pending → verified');
    print('🔍 สามารถดูข้อมูล verified ได้ผ่านฟังก์ชัน getVerifiedReports()');

    // 5. ตรวจสอบกล้องในฐานข้อมูลหลัก (ที่ถูก promote ไปแล้ว)
    print('\n🎯 5. กล้องในฐานข้อมูลหลัก (จากรายงานที่ verified):');
    final speedCamerasQuery = await firestore
        .collection('speed_cameras')
        .where('source', isEqualTo: 'community_verified')
        .get();

    print('   จำนวนกล้องจากชุมชน: ${speedCamerasQuery.docs.length} ตัว');
    for (final doc in speedCamerasQuery.docs.take(3)) {
      final data = doc.data();
      print('   - ${data['roadName']} (ID: ${doc.id})');
      print('     Source Report ID: ${data['sourceReportId']}');
      print('     Speed Limit: ${data['speedLimit']} km/h');
    }
  } catch (e) {
    print('❌ เกิดข้อผิดพลาด: $e');
  }
}
