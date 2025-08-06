#!/usr/bin/env dart

/// 🧪 Test Camera Deletion System
/// ไฟล์สำหรับทดสอบระบบการลบกล้องที่ถูกถอนหลังจากโหวตครบ

import 'package:firebase_core/firebase_core.dart';
import 'lib/modules/speed_camera/services/camera_report_service.dart';

Future<void> main() async {
  print('🧪 === CAMERA DELETION SYSTEM TEST ===');

  try {
    // Initialize Firebase
    await Firebase.initializeApp();
    print('✅ Firebase initialized');

    // Test 1: Check for pending deletions
    print('\n📋 TEST 1: Checking for pending deletions...');
    final pendingDeletions = await CameraReportService.checkPendingDeletions();

    if (pendingDeletions.isEmpty) {
      print('✅ No pending deletions found - system is clean');
    } else {
      print(
          '⚠️ Found ${pendingDeletions.length} cameras that should be deleted:');
      for (final pending in pendingDeletions) {
        print('   - ${pending['roadName']} (${pending['cameraId']})');
        print('     Report ID: ${pending['reportId']}');
        print('     Confidence: ${pending['confidenceScore']}');
        print('     Verified by: ${pending['verifiedBy']}');
        print('     Marked for deletion: ${pending['isMarkedForDeletion']}');
      }

      // Test 2: Fix pending deletions
      print('\n🔧 TEST 2: Fixing pending deletions...');
      await CameraReportService.fixPendingDeletions();

      // Test 3: Verify fixes
      print('\n🔍 TEST 3: Verifying fixes...');
      final remainingPending =
          await CameraReportService.checkPendingDeletions();

      if (remainingPending.isEmpty) {
        print('✅ All pending deletions fixed successfully');
      } else {
        print(
            '⚠️ ${remainingPending.length} deletions still pending after fix');
        for (final remaining in remainingPending) {
          print('   - ${remaining['roadName']} (${remaining['cameraId']})');
        }
      }
    }

    // Test 4: Force delete any remaining verified cameras
    print('\n💪 TEST 4: Force delete verified removal reports...');
    await CameraReportService.forceDeleteVerifiedCameras();

    // Test 5: Final verification
    print('\n🔍 TEST 5: Final system verification...');
    final finalCheck = await CameraReportService.checkPendingDeletions();

    if (finalCheck.isEmpty) {
      print('🎉 System verification PASSED - all cameras properly deleted');
    } else {
      print(
          '❌ System verification FAILED - ${finalCheck.length} cameras still pending');
    }

    // Test 6: Debug auto-verification process
    print('\n🐛 TEST 6: Debug auto-verification process...');
    await CameraReportService.debugAutoVerificationProcess();

    print('\n🎯 === TEST COMPLETE ===');
    print('Camera deletion system test finished successfully');
  } catch (e) {
    print('❌ Test failed: $e');
    print('Stack trace: $e');
  }
}

/// ฟังก์ชันสำหรับรันเฉพาะการตรวจสอบ
Future<void> checkOnly() async {
  print('🔍 === CHECKING CAMERA DELETION STATUS ===');

  try {
    await Firebase.initializeApp();

    final pendingDeletions = await CameraReportService.checkPendingDeletions();

    if (pendingDeletions.isEmpty) {
      print('✅ System is clean - no pending deletions');
    } else {
      print('⚠️ Found ${pendingDeletions.length} pending deletions:');
      for (int i = 0; i < pendingDeletions.length; i++) {
        final pending = pendingDeletions[i];
        print('${i + 1}. ${pending['roadName']} (${pending['cameraId']})');
        print('   Report: ${pending['reportId']}');
        print('   Confidence: ${pending['confidenceScore']}%');
        print('   Verified: ${pending['verifiedAt']}');
        print('   Marked for deletion: ${pending['isMarkedForDeletion']}');
        print('');
      }
    }
  } catch (e) {
    print('❌ Check failed: $e');
  }
}

/// ฟังก์ชันสำหรับแก้ไขเฉพาะ
Future<void> fixOnly() async {
  print('🔧 === FIXING PENDING DELETIONS ONLY ===');

  try {
    await Firebase.initializeApp();
    await CameraReportService.fixPendingDeletions();
    print('✅ Fix process completed');
  } catch (e) {
    print('❌ Fix failed: $e');
  }
}

/// ฟังก์ชันสำหรับบังคับลบทั้งหมด
Future<void> forceDeleteAll() async {
  print('💥 === FORCE DELETE ALL VERIFIED CAMERAS ===');

  try {
    await Firebase.initializeApp();
    await CameraReportService.forceDeleteVerifiedCameras();
    print('✅ Force delete completed');
  } catch (e) {
    print('❌ Force delete failed: $e');
  }
}
