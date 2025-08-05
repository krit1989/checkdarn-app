import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  print('🔧 === DEBUG SPECIFIC REPORT ===');

  try {
    // Initialize Firebase (ใช้ project default)
    await Firebase.initializeApp();
    final firestore = FirebaseFirestore.instance;

    final reportId =
        'vEWIsFetfmb0ziTVW3aj'; // Report ID ที่คุณส่งมา (อาจจะต่างกัน)
    final cameraId = 'Ubyl4OWUitFBvZpvZDSg'; // Camera ID ที่ควรจะเป็น

    print('🔍 Checking report: $reportId');
    print('🔍 Expected camera ID: $cameraId');

    // 1. ตรวจสอบรายงานใน camera_reports
    print('\n📋 === CHECKING CAMERA REPORT ===');
    final reportDoc =
        await firestore.collection('camera_reports').doc(reportId).get();

    if (reportDoc.exists) {
      final reportData = reportDoc.data()!;
      print('✅ Report found:');
      print('   Status: ${reportData['status']}');
      print('   Type: ${reportData['type']}');
      print('   Selected Camera ID: ${reportData['selectedCameraId']}');
      print('   Upvotes: ${reportData['upvotes']}');
      print('   Verified At: ${reportData['verifiedAt']}');
      print('   Verified By: ${reportData['verifiedBy']}');
      print('   Road Name: ${reportData['roadName']}');
      print('   Speed Limit: ${reportData['speedLimit']}');
      print('   Latitude: ${reportData['latitude']}');
      print('   Longitude: ${reportData['longitude']}');
    } else {
      print('❌ Report not found!');
      return;
    }

    // 2. ตรวจสอบว่ามีกล้องใน speed_cameras หรือไม่
    print('\n🎥 === CHECKING SPEED CAMERAS ===');
    final cameraDoc =
        await firestore.collection('speed_cameras').doc(cameraId).get();

    if (cameraDoc.exists) {
      final cameraData = cameraDoc.data()!;
      print('✅ Camera found in speed_cameras:');
      print('   ID: ${cameraData['id']}');
      print('   Road Name: ${cameraData['roadName']}');
      print('   Speed Limit: ${cameraData['speedLimit']}');
      print('   Is Active: ${cameraData['isActive']}');
      print('   Latitude: ${cameraData['latitude']}');
      print('   Longitude: ${cameraData['longitude']}');
      print('   Description: ${cameraData['description']}');
    } else {
      print('❌ Camera NOT found in speed_cameras!');
      print('🚨 This is the problem - camera should exist but doesn\'t');
    }

    // 3. ตรวจสอบ promotion success logs
    print('\n🎉 === CHECKING PROMOTION SUCCESS LOGS ===');
    final successQuery = await firestore
        .collection('camera_promotion_success')
        .where('reportId', isEqualTo: reportId)
        .get();

    if (successQuery.docs.isNotEmpty) {
      print('✅ Found ${successQuery.docs.length} promotion success logs:');
      for (final doc in successQuery.docs) {
        final data = doc.data();
        print('   Timestamp: ${data['timestamp']}');
        print('   Camera ID: ${data['cameraId']}');
        print('   Road Name: ${data['roadName']}');
        print('   Promoted By: ${data['promotedBy']}');
      }
    } else {
      print('❌ No promotion success logs found');
    }

    // 4. ตรวจสอบ promotion error logs
    print('\n❌ === CHECKING PROMOTION ERROR LOGS ===');
    final errorQuery = await firestore
        .collection('camera_promotion_errors')
        .where('reportId', isEqualTo: reportId)
        .get();

    if (errorQuery.docs.isNotEmpty) {
      print('⚠️ Found ${errorQuery.docs.length} promotion error logs:');
      for (final doc in errorQuery.docs) {
        final data = doc.data();
        print('   Timestamp: ${data['timestamp']}');
        print('   Error: ${data['error']}');
        print('   Stage: ${data['stage']}');
      }
    } else {
      print('✅ No promotion error logs found');
    }

    // 5. ตรวจสอบกล้องทั้งหมดในระบบ
    print('\n🎥 === ALL CAMERAS IN SYSTEM ===');
    final allCamerasQuery = await firestore
        .collection('speed_cameras')
        .where('isActive', isEqualTo: true)
        .get();

    print('📊 Total active cameras: ${allCamerasQuery.docs.length}');
    for (final doc in allCamerasQuery.docs.take(10)) {
      // แสดงแค่ 10 ตัวแรก
      final data = doc.data();
      print(
          '   ${data['id']}: ${data['roadName']} (${data['speedLimit']} km/h)');
    }

    if (allCamerasQuery.docs.length > 10) {
      print('   ... and ${allCamerasQuery.docs.length - 10} more cameras');
    }

    // สรุปผล
    print('\n📝 === SUMMARY ===');
    print('Report exists: ${reportDoc.exists}');
    print('Camera exists: ${cameraDoc.exists}');
    print('Success logs: ${successQuery.docs.length}');
    print('Error logs: ${errorQuery.docs.length}');

    if (reportDoc.exists && !cameraDoc.exists) {
      print(
          '🚨 PROBLEM IDENTIFIED: Report is verified but camera was not created!');
      print('🔧 RECOMMENDED ACTION: Use debug promotion tool in the app');
    }
  } catch (e) {
    print('❌ Error: $e');
  }

  print('🔧 === DEBUG COMPLETE ===');
  exit(0);
}
