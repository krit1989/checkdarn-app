import 'package:firebase_core/firebase_core.dart';
import 'lib/modules/speed_camera/services/camera_report_service.dart';
import 'lib/modules/speed_camera/models/camera_report_model.dart';

void main() async {
  print('🧪 === DEBUG PROMOTION SCRIPT ===');

  try {
    // Initialize Firebase
    await Firebase.initializeApp();
    print('✅ Firebase initialized successfully');

    // Debug specific report ID
    final reportId = 'K5Y8k0o6KwGEjPHUMUHh';
    print('🎯 Debugging report: $reportId');

    // Check current status of the report
    print('🔍 Checking current report status...');
    final reports = await CameraReportService.getReportsByStatus(
        CameraStatus.verified,
        forceRefresh: true);

    final targetReport = reports.where((r) => r.id == reportId).firstOrNull;
    if (targetReport == null) {
      print('❌ Report $reportId not found in verified reports');
      return;
    }

    print('📊 Found report:');
    print('   ID: ${targetReport.id}');
    print('   Status: ${targetReport.status}');
    print('   Type: ${targetReport.type}');
    print('   Verified by: ${targetReport.verifiedBy}');
    print('   Total votes: ${targetReport.totalVotes}');
    print('   Upvotes: ${targetReport.upvotes}');
    print('   Confidence: ${targetReport.confidenceScore}');
    print('   Road: ${targetReport.roadName}');
    print('   Camera ID: ${targetReport.selectedCameraId}');

    // Check if camera already exists
    print('🔍 Checking if camera already exists...');
    final allCameras =
        await CameraReportService.getAllSpeedCameras(forceRefresh: true);
    final existingCamera = allCameras
        .where((c) =>
            c.id == targetReport.selectedCameraId ||
            (targetReport.selectedCameraId != null &&
                c.description?.contains(targetReport.selectedCameraId!) ==
                    true))
        .firstOrNull;

    if (existingCamera != null) {
      print('✅ Camera already exists:');
      print('   Camera ID: ${existingCamera.id}');
      print('   Road: ${existingCamera.roadName}');
      print('   Description: ${existingCamera.description}');
      print('   Is Active: ${existingCamera.isActive}');
      return;
    }

    print('❌ Camera does not exist - attempting manual promotion...');

    // Manually trigger promotion
    print('🚀 Triggering manual promotion...');
    await CameraReportService.debugPromoteReport(reportId);

    // Verify promotion worked
    print('🔍 Verifying promotion result...');
    await Future.delayed(Duration(seconds: 3));

    final updatedCameras =
        await CameraReportService.getAllSpeedCameras(forceRefresh: true);
    final newCamera = updatedCameras
        .where((c) =>
            c.id == targetReport.selectedCameraId ||
            (c.description?.contains('Community verified') == true &&
                c.roadName == targetReport.roadName))
        .firstOrNull;

    if (newCamera != null) {
      print('✅ SUCCESS! Camera was created:');
      print('   Camera ID: ${newCamera.id}');
      print('   Road: ${newCamera.roadName}');
      print('   Speed Limit: ${newCamera.speedLimit}');
      print(
          '   Location: (${newCamera.location.latitude}, ${newCamera.location.longitude})');
      print('   Description: ${newCamera.description}');
      print('   Is Active: ${newCamera.isActive}');
    } else {
      print('❌ FAILED! Camera was not created after promotion');
    }
  } catch (e) {
    print('❌ Debug script failed: $e');
    print('📍 Stack trace: ${StackTrace.current}');
  }

  print('🧪 === DEBUG SCRIPT COMPLETE ===');
}
