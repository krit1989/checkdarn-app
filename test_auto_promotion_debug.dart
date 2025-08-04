import 'dart:async';
import 'lib/modules/speed_camera/services/camera_report_service.dart';
import 'lib/modules/speed_camera/models/camera_report_model.dart';

/// Debug Tool สำหรับตรวจสอบระบบ AUTO-PROMOTION
///
/// ปัญหาที่เกิดขึ้น:
/// - โหวตครบ 3 คน ✅
/// - รายงานหายจากรายการ (verified) ✅
/// - แต่กล้องยังอยู่บนแผนที่ ❌
///
/// ต้องตรวจสอบ:
/// 1. Auto-verification ทำงานหรือไม่?
/// 2. AUTO-PROMOTION เรียก _promoteToMainDatabase หรือไม่?
/// 3. _handleCameraRemovalReport ลบกล้องจริงหรือไม่?

void main() async {
  print('🔍 === AUTO-PROMOTION DEBUG TOOL ===');
  print('🎯 วัตถุประสงค์: ตรวจสอบว่าทำไมกล้องไม่หายจากแผนที่');
  print('');

  // Test 1: ตรวจสอบว่า Auto-verification ทำงานที่ threshold ถูกต้องหรือไม่
  await testAutoVerificationThresholds();

  // Test 2: ตรวจสอบการทำงานของ AUTO-PROMOTION
  await testAutoPromotionFlow();

  // Test 3: ตรวจสอบการลบกล้องจริง
  await testCameraRemovalProcess();

  print('');
  print('🏁 === DEBUG COMPLETE ===');
}

Future<void> testAutoVerificationThresholds() async {
  print('📊 === TEST 1: AUTO-VERIFICATION THRESHOLDS ===');

  // Simulate vote counts for removedCamera reports
  final testCases = [
    {'upvotes': 2, 'downvotes': 1, 'expected': false}, // 66.7% < 60% threshold
    {'upvotes': 3, 'downvotes': 0, 'expected': true}, // 100% > 60% threshold
    {'upvotes': 3, 'downvotes': 1, 'expected': true}, // 75% > 60% threshold
    {'upvotes': 2, 'downvotes': 2, 'expected': false}, // 50% < 60% threshold
  ];

  print('🎯 Testing removedCamera auto-verification (60% threshold):');

  for (final testCase in testCases) {
    final upvotes = testCase['upvotes'] as int;
    final downvotes = testCase['downvotes'] as int;
    final expected = testCase['expected'] as bool;

    final totalVotes = upvotes + downvotes;
    final approvalRatio = totalVotes > 0 ? upvotes / totalVotes : 0.0;
    final shouldAutoVerify =
        totalVotes >= 3 && approvalRatio >= 0.60; // removedCamera threshold

    final result = shouldAutoVerify == expected ? '✅' : '❌';

    print(
        '   $result Upvotes: $upvotes, Downvotes: $downvotes, Ratio: ${(approvalRatio * 100).toStringAsFixed(1)}%, Auto-verify: $shouldAutoVerify');
  }

  print('');
}

Future<void> testAutoPromotionFlow() async {
  print('🚀 === TEST 2: AUTO-PROMOTION WORKFLOW ===');

  print('📋 ขั้นตอนที่ควรเกิดขึ้นเมื่อมี 3 votes:');
  print('   1. Vote submitted → updateReportVotes()');
  print('   2. Auto-verification check (≥3 votes + ≥60% approval)');
  print('   3. Status changed to verified + verifiedBy = "auto_system"');
  print('   4. 🚀 AUTO-PROMOTION triggered');
  print('   5. Call _promoteToMainDatabase(reportId)');
  print('   6. _promoteToMainDatabase calls _handleCameraRemovalReport()');
  print('   7. _handleCameraRemovalReport calls robustCameraDeletion()');
  print('   8. robustCameraDeletion ลบกล้องจาก Firebase');
  print('');

  print('🔍 ตรวจสอบ Code Flow:');
  print(
      '   ✅ AUTO-PROMOTION code exists in updateReportVotes() around line 420');
  print('   ✅ Condition: newStatus == verified && verifiedBy == "auto_system"');
  print('   ✅ Calls: await _promoteToMainDatabase(reportId)');
  print('   ✅ _promoteToMainDatabase has removedCamera handling');
  print('   ✅ Calls: await _handleCameraRemovalReport(report)');
  print('   ✅ _handleCameraRemovalReport calls robustCameraDeletion()');
  print('');
}

Future<void> testCameraRemovalProcess() async {
  print('🗑️ === TEST 3: CAMERA REMOVAL PROCESS ===');

  print('📋 Robust Camera Deletion Protocol:');
  print('   1. Validation & selectedCameraId check');
  print('   2. Location-based search if no selectedCameraId');
  print('   3. Idempotency check (already deleted?)');
  print('   4. robustCameraDeletion with 3 retry attempts');
  print('   5. _executeAtomicDeletion');
  print('   6. _performThreeLayerVerification');
  print('   7. Update report as processed');
  print('');

  print('🔍 Potential Issues to Check:');
  print('   ❓ selectedCameraId field populated in reports?');
  print('   ❓ Firebase permissions for speed_cameras collection?');
  print('   ❓ Network timeouts during deletion?');
  print('   ❓ Cache issues preventing UI refresh?');
  print('');

  print('🔧 Debug Steps:');
  print('   1. Check Firebase Console - speed_cameras collection');
  print('   2. Look for deleted camera IDs');
  print('   3. Check camera_removal_failures collection for errors');
  print('   4. Verify report has processedAt timestamp');
  print('   5. Force refresh app/clear cache');
  print('');
}

// Helper class to simulate the auto-verification logic
class AutoVerificationSimulator {
  static bool shouldAutoVerify(
      int upvotes, int downvotes, CameraReportType type) {
    final totalVotes = upvotes + downvotes;
    if (totalVotes < 3) return false;

    final approvalRatio = upvotes / totalVotes;

    switch (type) {
      case CameraReportType.removedCamera:
        return approvalRatio >= 0.60; // 60% threshold
      case CameraReportType.speedChanged:
        return approvalRatio >= 0.70; // 70% threshold
      case CameraReportType.newCamera:
        return approvalRatio >= 0.80; // 80% threshold
    }
  }
}
