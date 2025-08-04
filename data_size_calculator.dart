/// คำนวณขนาดข้อมูลสำหรับ Camera Report System
/// สำหรับ 3,000 รายงานกล้องจับความเร็ว

void main() {
  print('📊 === คำนวณขนาดข้อมูล Camera Report System ===');
  print('🎯 เป้าหมาย: 3,000 รายงานกล้องจับความเร็ว\n');

  // === 1. ขนาดข้อมูลต่อรายงาน 1 รายการ ===

  // ฟิลด์หลักของ CameraReport
  final singleReportSize = calculateSingleReportSize();
  print('📄 ขนาดข้อมูลต่อรายงาน 1 รายการ:');
  print('   ${singleReportSize.toStringAsFixed(2)} KB\n');

  // === 2. ข้อมูลโหวต (votes) ===

  // สมมติเฉลี่ย 5 โหวตต่อรายงาน
  final averageVotesPerReport = 5;
  final singleVoteSize = calculateSingleVoteSize();
  final totalVotesSize = 3000 * averageVotesPerReport * singleVoteSize;

  print('🗳️ ขนาดข้อมูลโหวต:');
  print('   โหวตต่อรายงาน: $averageVotesPerReport โหวต');
  print('   ขนาดต่อโหวต: ${singleVoteSize.toStringAsFixed(2)} KB');
  print(
      '   รวมโหวตทั้งหมด: ${(totalVotesSize / 1024).toStringAsFixed(2)} MB\n');

  // === 3. สถิติผู้ใช้ ===

  // สมมติ 500 ผู้ใช้ที่มีส่วนร่วม
  final numberOfUsers = 500;
  final userStatsSize = calculateUserStatsSize();
  final totalUserStatsSize = numberOfUsers * userStatsSize;

  print('📊 ขนาดข้อมูลสถิติผู้ใช้:');
  print('   จำนวนผู้ใช้: $numberOfUsers คน');
  print('   ขนาดต่อผู้ใช้: ${userStatsSize.toStringAsFixed(2)} KB');
  print(
      '   รวมสถิติทั้งหมด: ${(totalUserStatsSize / 1024).toStringAsFixed(2)} MB\n');

  // === 4. ข้อมูลกล้องในฐานข้อมูลหลัก ===

  // สมมติ 70% ของรายงานจะผ่านการยืนยัน = 2,100 กล้อง
  final verifiedCameras = (3000 * 0.7).round();
  final speedCameraSize = calculateSpeedCameraSize();
  final totalSpeedCamerasSize = verifiedCameras * speedCameraSize;

  print('🎯 ขนาดข้อมูลกล้องในฐานข้อมูลหลัก:');
  print('   กล้องที่ยืนยันแล้ว: $verifiedCameras ตัว');
  print('   ขนาดต่อกล้อง: ${speedCameraSize.toStringAsFixed(2)} KB');
  print(
      '   รวมกล้องทั้งหมด: ${(totalSpeedCamerasSize / 1024).toStringAsFixed(2)} MB\n');

  // === 5. สรุปรวม ===

  final totalReportsSize = 3000 * singleReportSize;
  final grandTotal = totalReportsSize +
      totalVotesSize +
      totalUserStatsSize +
      totalSpeedCamerasSize;

  print('📋 === สรุปขนาดข้อมูลทั้งหมด ===');
  print(
      '📄 รายงาน (3,000 รายการ): ${(totalReportsSize / 1024).toStringAsFixed(2)} MB');
  print(
      '🗳️ โหวต (15,000 โหวต): ${(totalVotesSize / 1024).toStringAsFixed(2)} MB');
  print(
      '👥 สถิติผู้ใช้ (500 คน): ${(totalUserStatsSize / 1024).toStringAsFixed(2)} MB');
  print(
      '🎯 กล้องหลัก (2,100 ตัว): ${(totalSpeedCamerasSize / 1024).toStringAsFixed(2)} MB');
  print('─' * 50);
  print('💾 รวมทั้งหมด: ${(grandTotal / (1024 * 1024)).toStringAsFixed(2)} MB');

  if (grandTotal > 1024 * 1024) {
    print(
        '💾 หรือ: ${(grandTotal / (1024 * 1024 * 1024)).toStringAsFixed(3)} GB\n');
  } else {
    print('');
  }

  // === 6. การเปรียบเทียบ ===

  print('📱 === เปรียบเทียบขนาด ===');
  final photoSize = 2.5; // MB per photo
  final songSize = 4.0; // MB per song
  final videoSize = 50.0; // MB per short video

  final totalMB = grandTotal / (1024 * 1024);
  print('📸 เท่ากับรูปถ่าย: ${(totalMB / photoSize).toStringAsFixed(1)} รูป');
  print('🎵 เท่ากับเพลง: ${(totalMB / songSize).toStringAsFixed(1)} เพลง');
  print(
      '🎬 เท่ากับวิดีโอสั้น: ${(totalMB / videoSize).toStringAsFixed(1)} คลิป\n');

  // === 7. ค่าใช้จ่าย Firebase ===

  print('💰 === ประมาณการค่าใช้จ่าย Firebase ===');
  final firestoreReadCostPer1000 = 0.06; // USD per 1000 reads
  final firestoreWriteCostPer1000 = 0.18; // USD per 1000 writes
  final storageCostPerGB = 0.026; // USD per GB per month

  // สมมติการใช้งานต่อเดือน
  final monthlyReads = 50000; // reads per month
  final monthlyWrites = 10000; // writes per month
  final storageGB = totalMB / 1024;

  final readCost = (monthlyReads / 1000) * firestoreReadCostPer1000;
  final writeCost = (monthlyWrites / 1000) * firestoreWriteCostPer1000;
  final storageCost = storageGB * storageCostPerGB;
  final totalMonthlyCost = readCost + writeCost + storageCost;

  print('📖 การอ่านข้อมูล: \$${readCost.toStringAsFixed(3)}/เดือน');
  print('✍️ การเขียนข้อมูล: \$${writeCost.toStringAsFixed(3)}/เดือน');
  print('💾 พื้นที่จัดเก็บ: \$${storageCost.toStringAsFixed(3)}/เดือน');
  print('─' * 30);
  print('💵 รวมต่อเดือน: \$${totalMonthlyCost.toStringAsFixed(2)}');
  print('💵 รวมต่อปี: \$${(totalMonthlyCost * 12).toStringAsFixed(2)}\n');

  // === 8. ข้อเสนอแนะ ===

  print('💡 === ข้อเสนอแนะการเพิ่มประสิทธิภาพ ===');
  print('🗜️ บีบอัดข้อมูล: ลดขนาดลง 30-50%');
  print('🧹 ทำความสะอาด: ลบข้อมูลเก่าอัตโนมัติ');
  print('📦 Index เฉพาะที่จำเป็น: ลดต้นทุน query');
  print('⚡ Cache ข้อมูลยอดนิยม: ลดการอ่านจาก server');
  print('🔄 Batch operations: ลดจำนวน writes');
}

/// คำนวณขนาดข้อมูลต่อรายงาน 1 รายการ (KB)
double calculateSingleReportSize() {
  // ตามโครงสร้าง CameraReport
  var size = 0.0;

  size += 36; // id (UUID string)
  size += 8; // latitude (double)
  size += 8; // longitude (double)
  size += 50; // roadName (average Thai road name)
  size += 4; // speedLimit (int)
  size += 28; // reportedBy (user ID)
  size += 24; // reportedAt (ISO 8601 string)
  size += 20; // type (enum string)
  size += 100; // description (optional, average)
  size += 150; // imageUrl (optional, average URL)
  size += 50; // tags (array of strings)
  size += 4; // upvotes (int)
  size += 4; // downvotes (int)
  size += 8; // confidenceScore (double)
  size += 15; // status (enum string)
  size += 24; // verifiedAt (optional ISO string)
  size += 28; // verifiedBy (optional user ID)

  // Firebase overhead (indexes, metadata)
  size += 50;

  return size / 1024; // Convert to KB
}

/// คำนวณขนาดข้อมูลต่อโหวต 1 รายการ (KB)
double calculateSingleVoteSize() {
  var size = 0.0;

  size += 36; // id (UUID)
  size += 36; // reportId
  size += 28; // userId
  size += 10; // voteType (upvote/downvote)
  size += 24; // votedAt (ISO string)
  size += 100; // comment (optional)

  // Firebase overhead
  size += 30;

  return size / 1024; // Convert to KB
}

/// คำนวณขนาดข้อมูลสถิติต่อผู้ใช้ 1 คน (KB)
double calculateUserStatsSize() {
  var size = 0.0;

  size += 28; // userId
  size += 4; // reports_submitted
  size += 4; // votes_submitted
  size += 4; // total_contributions
  size += 8; // last_activity (timestamp)

  // Firebase overhead
  size += 20;

  return size / 1024; // Convert to KB
}

/// คำนวณขนาดข้อมูลต่อกล้องในฐานข้อมูลหลัก 1 ตัว (KB)
double calculateSpeedCameraSize() {
  var size = 0.0;

  size += 36; // id
  size += 8; // latitude
  size += 8; // longitude
  size += 4; // speedLimit
  size += 50; // roadName
  size += 15; // type
  size += 5; // isActive (boolean)
  size += 100; // description
  size += 20; // source
  size += 36; // sourceReportId
  size += 24; // createdAt
  size += 24; // updatedAt

  // Firebase overhead
  size += 40;

  return size / 1024; // Convert to KB
}
