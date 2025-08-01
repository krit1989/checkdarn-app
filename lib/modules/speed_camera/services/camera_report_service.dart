import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart';
import '../models/camera_report_model.dart';
import '../models/speed_camera_model.dart';
import 'dart:math' as math;

class CameraReportService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collections
  static const String _reportsCollection = 'camera_reports';
  static const String _votesCollection = 'camera_votes';
  static const String _userStatsCollection = 'user_report_stats';

  /// Submit a new camera report
  static Future<String> submitReport({
    required double latitude,
    required double longitude,
    required String roadName,
    required int speedLimit,
    required CameraReportType type,
    String? description,
    String? imageUrl,
    List<String> tags = const [],
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Check for duplicate reports within 50m
    final nearbyReports = await _findNearbyReports(latitude, longitude, 50);
    if (nearbyReports.isNotEmpty) {
      throw Exception('มีการรายงานในบริเวณนี้แล้ว โปรดตรวจสอบอีกครั้ง');
    }

    final reportId = _firestore.collection(_reportsCollection).doc().id;
    final report = CameraReport(
      id: reportId,
      latitude: latitude,
      longitude: longitude,
      roadName: roadName,
      speedLimit: speedLimit,
      reportedBy: user.uid,
      reportedAt: DateTime.now(),
      type: type,
      description: description,
      imageUrl: imageUrl,
      tags: tags,
    );

    await _firestore
        .collection(_reportsCollection)
        .doc(reportId)
        .set(report.toJson());

    print('✅ New camera report created: ${report.roadName} (ID: $reportId)');

    // Update user stats
    await _updateUserStats(user.uid, 'reports_submitted');

    return reportId;
  }

  /// Submit a vote for a camera report
  static Future<void> submitVote({
    required String reportId,
    required VoteType voteType,
    String? comment,
    int maxRetries = 2, // เพิ่ม retry mechanism
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('กรุณาล็อกอินก่อน');

    // Debug user info
    print('🔍 DEBUG - User info:');
    print('   User ID: ${user.uid}');
    print('   Email: ${user.email}');
    print('   Is Anonymous: ${user.isAnonymous}');
    print('   Display Name: ${user.displayName}');
    print('   Auth Token: ${user.refreshToken != null ? "Available" : "None"}');

    Exception? lastError;

    // พยายามโหวตสูงสุด maxRetries + 1 ครั้ง
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        if (attempt > 0) {
          print('🔄 Vote retry attempt $attempt of $maxRetries');
          // รอเล็กน้อยก่อน retry
          await Future.delayed(Duration(milliseconds: 1000 * attempt));

          // ตรวจสอบ auth token ใหม่ก่อน retry
          await user.getIdToken(true); // Force refresh token
          print('🔐 Auth token refreshed for retry');
        }

        print(
            '🗳️ Starting vote submission for user: ${user.uid} (attempt ${attempt + 1})');

        // Check if user has already voted (FORCE SERVER CHECK - ไม่ใช้ cache)
        print('🔍 Checking if user has already voted (from server)...');
        final existingVote = await _firestore
            .collection(_votesCollection)
            .where('reportId', isEqualTo: reportId)
            .where('userId', isEqualTo: user.uid)
            .get(const GetOptions(source: Source.server)) // FORCE SERVER
            .timeout(const Duration(seconds: 15));

        if (existingVote.docs.isNotEmpty) {
          print(
              '❌ User has already voted - vote ID: ${existingVote.docs.first.id}');
          throw Exception('คุณได้โหวตรายงานนี้แล้ว');
        }

        print('✅ Vote check passed - user has not voted yet');

        // Check if report exists first (FORCE SERVER CHECK)
        print('🔍 Checking if report exists (from server)...');
        final reportDoc = await _firestore
            .collection(_reportsCollection)
            .doc(reportId)
            .get(const GetOptions(source: Source.server)) // FORCE SERVER
            .timeout(const Duration(seconds: 15));

        if (!reportDoc.exists) {
          throw Exception('ไม่พบรายงานนี้ อาจถูกลบไปแล้ว');
        }

        final report = CameraReport.fromJson(reportDoc.data()!);

        // ตรวจสอบสถานะรายงาน
        if (report.status != CameraStatus.pending) {
          throw Exception('ไม่สามารถโหวตรายงานที่ไม่ใช่สถานะ pending ได้');
        }

        print('✅ Report exists and is pending - proceeding with vote');
        print(
            '📊 Report details: ${report.roadName}, Status: ${report.status}');

        final voteId = _firestore.collection(_votesCollection).doc().id;
        final vote = CameraVote(
          id: voteId,
          reportId: reportId,
          userId: user.uid,
          voteType: voteType,
          votedAt: DateTime.now(),
          comment: comment,
        );

        // ขั้นตอนที่ 1: สร้าง vote ก่อน (with timeout)
        print('📝 Creating vote document...');
        await _firestore
            .collection(_votesCollection)
            .doc(voteId)
            .set(vote.toJson())
            .timeout(const Duration(seconds: 15));
        print('✅ Vote document created successfully');

        // ขั้นตอนที่ 2: อัปเดต report counts แยกต่างหาก
        print('📊 Updating report vote counts...');
        await _updateReportVoteCounts(reportId, voteType);
        print('✅ Report vote counts updated successfully');

        // Update user stats (with timeout)
        print('📈 Updating user stats...');
        await _updateUserStats(user.uid, 'votes_submitted')
            .timeout(const Duration(seconds: 15));
        print('✅ User stats updated successfully');

        // If auto-verified, potentially add to main speed camera database
        if (await _isReportAutoVerified(reportId)) {
          print('🎯 Report auto-verified - promoting to main database');
          await _promoteToMainDatabase(reportId);
        }

        print('🎉 Vote submission completed successfully');
        return; // สำเร็จแล้ว ออกจาก loop
      } catch (e) {
        lastError = Exception(e.toString());
        print('❌ Vote attempt ${attempt + 1} failed: $e');
        print('🔍 Error type: ${e.runtimeType}');

        // แสดงรายละเอียด error เพิ่มเติม
        if (e.toString().contains('permission-denied')) {
          print('🚫 Permission denied details:');
          print('   Current user: ${user.uid}');
          print('   User email: ${user.email ?? "No email"}');
          print('   Is authenticated: ${user.uid.isNotEmpty}');
          print('   Report ID: $reportId');
        }

        // ถ้าเป็น error ที่ไม่ควร retry ให้หยุดทันที
        if (e.toString().contains('คุณได้โหวตรายงานนี้แล้ว') ||
            e.toString().contains('ไม่พบรายงานนี้') ||
            e.toString().contains('ไม่ใช่สถานะ pending')) {
          print('💡 Non-retryable error - stopping retries');
          break;
        }

        // ถ้ายังมี attempt เหลือและเป็น error ที่ retry ได้
        if (attempt < maxRetries) {
          print('🔄 Will retry in ${1000 * (attempt + 1)}ms...');
          continue;
        }
      }
    }

    // ถ้าถึงจุดนี้แปลว่าล้มเหลวทั้งหมด
    print('💥 All vote attempts failed');
    print('🔍 Last error: ${lastError?.toString()}');

    // ให้ข้อมูล error ที่ชัดเจนขึ้น
    if (lastError != null) {
      final errorMsg = lastError.toString();
      if (errorMsg.contains('permission-denied')) {
        // ข้อมูล debug เพิ่มเติมสำหรับ permission error
        print('🚫 Permission denied - Debug info:');
        print('   User authenticated: ${user.uid.isNotEmpty}');
        print('   User email: ${user.email}');
        print('   Report ID: $reportId');

        throw Exception(
            'ไม่มีสิทธิ์ในการโหวต - กรุณาลองออกจากระบบแล้วล็อกอินใหม่');
      } else if (errorMsg.contains('not-found')) {
        throw Exception('ไม่พบรายงานนี้ อาจถูกลบไปแล้ว');
      } else if (errorMsg.contains('network') ||
          errorMsg.contains('timeout') ||
          errorMsg.contains('TimeoutException')) {
        throw Exception('ปัญหาการเชื่อมต่อ กรุณาตรวจสอบอินเทอร์เน็ตและลองใหม่');
      } else if (errorMsg.contains('คุณได้โหวตรายงานนี้แล้ว')) {
        throw Exception('คุณได้โหวตรายงานนี้แล้ว');
      } else {
        throw Exception(
            'ไม่สามารถโหวตได้ กรุณาลองใหม่อีกครั้ง\nรายละเอียด: ${errorMsg.length > 100 ? errorMsg.substring(0, 100) + "..." : errorMsg}');
      }
    } else {
      throw Exception('ไม่สามารถโหวตได้ กรุณาลองใหม่อีกครั้ง');
    }
  }

  /// Update report vote counts separately (ไม่ใช้ transaction)
  static Future<void> _updateReportVoteCounts(
      String reportId, VoteType voteType) async {
    try {
      print('📊 Getting report document for vote count update...');
      final reportRef = _firestore.collection(_reportsCollection).doc(reportId);
      final reportDoc = await reportRef
          .get(const GetOptions(source: Source.server)); // Force server read

      if (!reportDoc.exists) {
        throw Exception('Report not found');
      }

      final report = CameraReport.fromJson(reportDoc.data()!);
      print(
          '📄 Current report - Upvotes: ${report.upvotes}, Downvotes: ${report.downvotes}');

      // Update vote counts
      final newUpvotes =
          voteType == VoteType.upvote ? report.upvotes + 1 : report.upvotes;
      final newDownvotes = voteType == VoteType.downvote
          ? report.downvotes + 1
          : report.downvotes;
      final newTotalVotes = newUpvotes + newDownvotes;
      final newConfidenceScore =
          newTotalVotes > 0 ? newUpvotes / newTotalVotes : 0.0;

      print(
          '📊 New counts - Upvotes: $newUpvotes, Downvotes: $newDownvotes, Confidence: ${(newConfidenceScore * 100).toStringAsFixed(1)}%');

      // Auto-verify if confidence is high enough
      CameraStatus newStatus = report.status;
      DateTime? verifiedAt;
      String? verifiedBy;

      if (newTotalVotes >= 5) {
        if (newConfidenceScore >= 0.8) {
          newStatus = CameraStatus.verified;
          verifiedAt = DateTime.now();
          verifiedBy = 'auto_system';
          print(
              '✅ Auto-verifying report due to high confidence (${(newConfidenceScore * 100).toStringAsFixed(1)}%)');
        } else if (newConfidenceScore <= 0.2) {
          newStatus = CameraStatus.rejected;
          verifiedAt = DateTime.now();
          verifiedBy = 'auto_system';
          print(
              '❌ Auto-rejecting report due to low confidence (${(newConfidenceScore * 100).toStringAsFixed(1)}%)');
        }
      }

      // Update report ด้วย merge: true เพื่อป้องกันการเขียนทับ
      final updateData = {
        'upvotes': newUpvotes,
        'downvotes': newDownvotes,
        'confidenceScore': newConfidenceScore,
        'status': newStatus.toString().split('.').last,
        if (verifiedAt != null) 'verifiedAt': verifiedAt.toIso8601String(),
        if (verifiedBy != null) 'verifiedBy': verifiedBy,
      };

      print('🔄 Updating report with new vote counts...');
      await reportRef.update(updateData);
      print('✅ Report vote counts updated successfully');
    } catch (e) {
      print('❌ Error updating report vote counts: $e');

      // ให้ข้อมูล error ที่ชัดเจนขึ้น
      if (e.toString().contains('permission-denied')) {
        throw Exception('ไม่มีสิทธิ์ในการอัปเดตคะแนนโหวต');
      } else if (e.toString().contains('not-found')) {
        throw Exception('ไม่พบรายงานที่ต้องการอัปเดต');
      } else {
        throw Exception('ไม่สามารถอัปเดตคะแนนโหวตได้: ${e.toString()}');
      }
    }
  }

  /// Get pending reports that need votes (ALWAYS FORCE REFRESH)
  static Future<List<CameraReport>> getPendingReports({
    double? userLat,
    double? userLng,
    double radiusKm = 10.0,
    int limit = 20,
    bool forceRefresh = true, // เปลี่ยนเป็น true เป็นค่าเริ่มต้น
  }) async {
    print('🔍 getPendingReports called with:');
    print('   userLat: $userLat, userLng: $userLng');
    print('   radiusKm: $radiusKm, limit: $limit');
    print('   forceRefresh: $forceRefresh');

    Query query = _firestore
        .collection(_reportsCollection)
        .where('status', isEqualTo: 'pending')
        .orderBy('reportedAt', descending: true)
        .limit(limit);

    // ALWAYS FORCE REFRESH เพื่อให้เห็นโพสต์ใหม่ทันที
    final snapshot = await query.get(const GetOptions(source: Source.server));

    print('📊 Firestore query result: ${snapshot.docs.length} documents');

    final reports = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      print(
          '   Document ID: ${doc.id}, Status: ${data['status']}, Road: ${data['roadName']}');
      return CameraReport.fromJson(data);
    }).toList();

    print('📋 Converted to ${reports.length} CameraReport objects');

    // Filter by distance if user location provided
    if (userLat != null && userLng != null) {
      final originalCount = reports.length;
      print(
          '📍 Applying distance filter with user location: ($userLat, $userLng)');

      // Debug: Check distances for all reports
      for (int i = 0; i < reports.length; i++) {
        final report = reports[i];
        final distance = _calculateDistance(
            userLat, userLng, report.latitude, report.longitude);
        print(
            '   Report ${i + 1}: ${report.roadName} - Distance: ${distance.toStringAsFixed(2)}km');
      }

      reports.removeWhere((report) {
        final distance = _calculateDistance(
            userLat, userLng, report.latitude, report.longitude);
        final tooFar = distance > radiusKm;
        if (tooFar) {
          print(
              '   ❌ Filtering out ${report.roadName} - ${distance.toStringAsFixed(2)}km > ${radiusKm}km');
        }
        return tooFar;
      });
      print(
          '📍 Distance filter: ${originalCount} -> ${reports.length} reports (within ${radiusKm}km)');
    } else {
      print('📍 No user location provided - skipping distance filter');
    }

    print('✅ Final result: ${reports.length} pending reports');
    return reports;
  }

  /// Get user's voting history (FORCE FROM SERVER)
  static Future<List<String>> getUserVotedReports() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    // FORCE SERVER READ - ไม่ใช้ cache เพื่อป้องกันปัญหาข้อมูลเก่า
    final snapshot = await _firestore
        .collection(_votesCollection)
        .where('userId', isEqualTo: user.uid)
        .get(const GetOptions(source: Source.server));

    final votedReports =
        snapshot.docs.map((doc) => doc['reportId'] as String).toList();
    print(
        '📊 User voted reports (from server): ${votedReports.length} reports');

    return votedReports;
  }

  /// Get user's report statistics
  static Future<Map<String, int>> getUserStats() async {
    final user = _auth.currentUser;
    if (user == null) return {};

    final doc =
        await _firestore.collection(_userStatsCollection).doc(user.uid).get();

    if (!doc.exists) return {};

    return Map<String, int>.from(doc.data() ?? {});
  }

  /// Find nearby reports within specified radius (meters)
  static Future<List<CameraReport>> _findNearbyReports(
      double lat, double lng, double radiusMeters) async {
    // Simple geohash-like approach for nearby search
    // In production, consider using GeoFlutterFire for better geo queries

    final latRange = radiusMeters / 111000; // rough conversion

    final snapshot = await _firestore
        .collection(_reportsCollection)
        .where('latitude', isGreaterThan: lat - latRange)
        .where('latitude', isLessThan: lat + latRange)
        .get();

    final reports = snapshot.docs
        .map((doc) => CameraReport.fromJson(doc.data()))
        .where((report) {
      final distance =
          _calculateDistance(lat, lng, report.latitude, report.longitude);
      return distance * 1000 <= radiusMeters; // Convert km to meters
    }).toList();

    return reports;
  }

  /// Calculate distance between two points (in kilometers)
  static double _calculateDistance(
      double lat1, double lng1, double lat2, double lng2) {
    const earthRadius = 6371; // Earth's radius in kilometers

    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLng = (lng2 - lng1) * math.pi / 180;

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  /// Update user statistics
  static Future<void> _updateUserStats(String userId, String statKey) async {
    final docRef = _firestore.collection(_userStatsCollection).doc(userId);

    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(docRef);

      final currentStats =
          doc.exists ? Map<String, int>.from(doc.data()!) : <String, int>{};
      currentStats[statKey] = (currentStats[statKey] ?? 0) + 1;
      currentStats['total_contributions'] =
          (currentStats['total_contributions'] ?? 0) + 1;
      currentStats['last_activity'] = DateTime.now().millisecondsSinceEpoch;

      transaction.set(docRef, currentStats, SetOptions(merge: true));
    });
  }

  /// Check if report is auto-verified
  static Future<bool> _isReportAutoVerified(String reportId) async {
    final doc =
        await _firestore.collection(_reportsCollection).doc(reportId).get();
    if (!doc.exists) return false;

    final report = CameraReport.fromJson(doc.data()!);
    return report.status == CameraStatus.verified &&
        report.verifiedBy == 'auto_system';
  }

  /// Promote verified report to main speed camera database
  static Future<void> _promoteToMainDatabase(String reportId) async {
    final doc =
        await _firestore.collection(_reportsCollection).doc(reportId).get();
    if (!doc.exists) return;

    final report = CameraReport.fromJson(doc.data()!);

    if (report.status == CameraStatus.verified &&
        report.type == CameraReportType.newCamera) {
      // Create new speed camera entry
      final speedCamera = SpeedCamera(
        id: _firestore.collection('speed_cameras').doc().id,
        location:
            LatLng(report.latitude, report.longitude), // Use latlong2 LatLng
        speedLimit: report.speedLimit,
        roadName: report.roadName,
        type: CameraType.fixed, // Default to fixed
        isActive: true,
        description:
            'Community verified camera (${report.confidenceScore.toStringAsFixed(2)} confidence)',
      );

      await _firestore
          .collection('speed_cameras')
          .doc(speedCamera.id)
          .set(speedCamera.toJson());

      print(
          'Promoted report $reportId to main database as camera ${speedCamera.id}');
    }
  }

  /// Get reports by status
  static Future<List<CameraReport>> getReportsByStatus(CameraStatus status,
      {bool forceRefresh = false}) async {
    final query = _firestore
        .collection(_reportsCollection)
        .where('status', isEqualTo: status.toString().split('.').last)
        .orderBy('reportedAt', descending: true);

    // Force refresh จาก server ถ้าต้องการ
    final snapshot = forceRefresh
        ? await query.get(const GetOptions(source: Source.server))
        : await query.get();

    return snapshot.docs
        .map((doc) => CameraReport.fromJson(doc.data()))
        .toList();
  }

  /// Get user's own reports (เฉพาะรายงานของผู้ใช้ปัจจุบัน)
  static Future<List<CameraReport>> getUserReports(
      {bool forceRefresh = false}) async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final query = _firestore
        .collection(_reportsCollection)
        .where('reportedBy', isEqualTo: user.uid)
        .orderBy('reportedAt', descending: true);

    // Force refresh จาก server ถ้าต้องการ
    final snapshot = forceRefresh
        ? await query.get(const GetOptions(source: Source.server))
        : await query.get();

    return snapshot.docs
        .map((doc) => CameraReport.fromJson(doc.data()))
        .toList();
  }

  /// Delete a report (admin function)
  static Future<void> deleteReport(String reportId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      // ตรวจสอบสิทธิ์ก่อน (ไม่ timeout เพื่อความเร็ว)
      final reportDoc =
          await _firestore.collection(_reportsCollection).doc(reportId).get();

      if (!reportDoc.exists) throw Exception('ไม่พบรายงานนี้');

      final report = CameraReport.fromJson(reportDoc.data()!);

      // ตรวจสอบว่าเป็นเจ้าของและสถานะ pending
      if (report.reportedBy != user.uid) {
        throw Exception('คุณไม่ใช่เจ้าของรายงานนี้');
      }
      if (report.status != CameraStatus.pending) {
        throw Exception('ไม่สามารถลบรายงานที่ไม่ใช่สถานะ pending ได้');
      }

      // ลบรายงานหลักเลย (ไม่ timeout)
      await _firestore.collection(_reportsCollection).doc(reportId).delete();

      // ลบ votes ในพื้นหลัง (ไม่รอ)
      _deleteVotesInBackground(reportId);
    } catch (e) {
      throw Exception('ไม่สามารถลบรายงานได้: $e');
    }
  }

  /// ลบ votes ในพื้นหลัง
  static void _deleteVotesInBackground(String reportId) async {
    try {
      final votes = await _firestore
          .collection(_votesCollection)
          .where('reportId', isEqualTo: reportId)
          .get();

      for (final vote in votes.docs) {
        vote.reference.delete().catchError((e) {
          print('Warning: Could not delete vote ${vote.id}: $e');
        });
      }
    } catch (e) {
      print('Warning: Could not delete associated votes: $e');
    }
  }
}

// Remove the local LatLng class since we're using latlong2
