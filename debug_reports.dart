import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  // Initialize Firebase (you'll need to run this in proper Flutter context)
  final firestore = FirebaseFirestore.instance;

  try {
    print('🔍 Checking all camera reports in database...');

    // Get all reports (not just pending)
    final allReports = await firestore
        .collection('camera_reports')
        .orderBy('reportedAt', descending: true)
        .limit(50)
        .get();

    print('📊 Total reports found: ${allReports.docs.length}');

    if (allReports.docs.isEmpty) {
      print('❌ No reports found in database!');
      return;
    }

    final statusCounts = <String, int>{};

    for (final doc in allReports.docs) {
      final data = doc.data();
      final status = data['status'] ?? 'unknown';
      final roadName = data['roadName'] ?? 'Unknown road';
      final reportedAt = data['reportedAt'] ?? 'Unknown time';

      statusCounts[status] = (statusCounts[status] ?? 0) + 1;

      print('📄 Report: ${doc.id}');
      print('   Road: $roadName');
      print('   Status: $status');
      print('   Reported: $reportedAt');
      print('   ---');
    }

    print('📈 Status summary:');
    statusCounts.forEach((status, count) {
      print('   $status: $count reports');
    });

    // Check specifically for pending reports
    final pendingReports = await firestore
        .collection('camera_reports')
        .where('status', isEqualTo: 'pending')
        .get();

    print('⏳ Pending reports specifically: ${pendingReports.docs.length}');
  } catch (e) {
    print('❌ Error checking reports: $e');
  }
}
