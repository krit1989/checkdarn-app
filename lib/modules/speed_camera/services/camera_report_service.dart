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
    print('📊 Report details:');
    print('   Status: ${report.status}');
    print('   Type: ${report.type}');
    print('   Latitude: ${report.latitude}');
    print('   Longitude: ${report.longitude}');
    print('   Reported by: ${report.reportedBy}');
    print('   Reported at: ${report.reportedAt}');

    // Verify the document was saved correctly
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      final savedDoc = await _firestore
          .collection(_reportsCollection)
          .doc(reportId)
          .get(const GetOptions(source: Source.server));

      if (savedDoc.exists) {
        final savedData = savedDoc.data()!;
        print('✅ Verification: Document saved successfully');
        print('   Saved status: ${savedData['status']}');
        print('   Saved type: ${savedData['type']}');
        print('   Document exists: true');
      } else {
        print('❌ Warning: Document not found after save');
      }
    } catch (e) {
      print('⚠️ Could not verify document save: $e');
    }

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
        print('🔍 Checking if report was auto-verified...');
        final isAutoVerified = await _isReportAutoVerified(reportId);
        print('📊 Auto-verification result: $isAutoVerified');

        if (isAutoVerified) {
          print('🎯 Report auto-verified - promoting to main database');
          try {
            await _promoteToMainDatabase(reportId);
            print('✅ Promotion completed successfully');
          } catch (e) {
            print('❌ Error during promotion: $e');
            // Log the error but don't fail the vote
          }
        } else {
          print('⏳ Report not yet auto-verified - skipping promotion');
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

      print('🎯 Auto-verification check:');
      print('   Total votes: $newTotalVotes (need >= 3 for auto-verify)');
      print('   Confidence: ${(newConfidenceScore * 100).toStringAsFixed(1)}%');
      print('   Current status: ${report.status}');
      print('   Report type: ${report.type}');

      // ลดเงื่อนไขจาก 5 votes เป็น 3 votes เพื่อให้ verify เร็วขึ้น
      if (newTotalVotes >= 3) {
        if (newConfidenceScore >= 0.8) {
          newStatus = CameraStatus.verified;
          verifiedAt = DateTime.now();
          verifiedBy = 'auto_system';
          print(
              '✅ Auto-verifying report due to high confidence (${(newConfidenceScore * 100).toStringAsFixed(1)}%) with $newTotalVotes votes');
        } else if (newConfidenceScore <= 0.2) {
          newStatus = CameraStatus.rejected;
          verifiedAt = DateTime.now();
          verifiedBy = 'auto_system';
          print(
              '❌ Auto-rejecting report due to low confidence (${(newConfidenceScore * 100).toStringAsFixed(1)}%) with $newTotalVotes votes');
        } else {
          print(
              '⏳ Report still pending - confidence ${(newConfidenceScore * 100).toStringAsFixed(1)}% (need >= 80% or <= 20%)');
        }
      } else {
        print('⏳ Not enough votes yet for auto-verification');
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
      print('📊 Update data: $updateData');
      await reportRef.update(updateData);
      print('✅ Report vote counts updated successfully');

      // ตรวจสอบว่าอัปเดตสำเร็จหรือไม่
      final updatedDoc =
          await reportRef.get(const GetOptions(source: Source.server));
      if (updatedDoc.exists) {
        final updatedData = updatedDoc.data() as Map<String, dynamic>;
        print('✅ Verification - Updated report data: {');
        print('   status: ${updatedData['status']}');
        print('   upvotes: ${updatedData['upvotes']}');
        print('   downvotes: ${updatedData['downvotes']}');
        print('   confidenceScore: ${updatedData['confidenceScore']}');
        print('   verifiedAt: ${updatedData['verifiedAt']}');
        print('   verifiedBy: ${updatedData['verifiedBy']}');
        print('}');
      } else {
        print('❌ Warning: Could not verify report update');
      }
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
    double radiusKm =
        1000.0, // เพิ่มจาก 50 เป็น 1000 km (ครอบคลุมทั้งประเทศไทย)
    int limit = 50, // เพิ่มจาก 20 เป็น 50 โพสต์
    bool forceRefresh = true, // เปลี่ยนเป็น true เป็นค่าเริ่มต้น
    bool showAllNationwide = false, // ตัวเลือกใหม่: แสดงทั้งประเทศ
  }) async {
    print('🔍 === GET PENDING REPORTS START ===');
    print('🔍 getPendingReports called with:');
    print('   userLat: $userLat, userLng: $userLng');
    print('   radiusKm: $radiusKm, limit: $limit');
    print('   forceRefresh: $forceRefresh');
    print('   showAllNationwide: $showAllNationwide');

    try {
      Query query = _firestore
          .collection(_reportsCollection)
          .where('status', isEqualTo: 'pending')
          .orderBy('reportedAt', descending: true)
          .limit(limit);

      print('🔍 Executing Firestore query...');

      // ALWAYS FORCE REFRESH เพื่อให้เห็นโพสต์ใหม่ทันที
      final snapshot = await query.get(const GetOptions(source: Source.server));

      print('📊 Firestore query result: ${snapshot.docs.length} documents');

      if (snapshot.docs.isEmpty) {
        print('⚠️ No pending reports found in Firestore');
        print('🔍 Checking if there are any reports at all...');

        // ตรวจสอบว่ามีรายงานอื่นๆ หรือไม่
        final allReportsQuery = _firestore
            .collection(_reportsCollection)
            .orderBy('reportedAt', descending: true)
            .limit(5);

        final allReportsSnapshot =
            await allReportsQuery.get(const GetOptions(source: Source.server));
        print(
            '📊 Total reports in database: ${allReportsSnapshot.docs.length}');

        for (final doc in allReportsSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>?;
          if (data != null) {
            print(
                '   Report: ${data['roadName']} - Status: ${data['status']} - Type: ${data['type']}');
          }
        }
      }

      final reports = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) {
          print('   ❌ Document ${doc.id} has null data');
          throw Exception('Document data is null');
        }

        print('📄 Processing document:');
        print('   Document ID: ${doc.id}');
        print('   Status: ${data['status']}');
        print('   Type: ${data['type']}');
        print('   Road: ${data['roadName']}');
        print('   Reported at: ${data['reportedAt']}');
        print('   Reported by: ${data['reportedBy']}');

        try {
          final report = CameraReport.fromJson(data);
          print('   ✅ Successfully converted to CameraReport');
          return report;
        } catch (e) {
          print('   ❌ Error converting to CameraReport: $e');
          print('   ❌ Raw data: $data');
          rethrow;
        }
      }).toList();

      print('📋 Converted to ${reports.length} CameraReport objects');

      // Filter by distance if user location provided
      if (userLat != null && userLng != null && !showAllNationwide) {
        final originalCount = reports.length;
        print(
            '📍 Applying distance filter with user location: ($userLat, $userLng)');
        print('📍 Radius limit: ${radiusKm}km');

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
      } else if (showAllNationwide) {
        print('🌏 Showing all reports nationwide - no distance filter applied');
      } else {
        print('📍 No user location provided - skipping distance filter');
      }

      print('✅ Final result: ${reports.length} pending reports');
      print('🔍 === GET PENDING REPORTS END ===');

      return reports;
    } catch (e) {
      print('❌ Error in getPendingReports: $e');
      print('❌ Error type: ${e.runtimeType}');
      print('❌ Stack trace: ${StackTrace.current}');
      rethrow;
    }
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
    print('🔍 Checking auto-verification status for report: $reportId');

    try {
      final doc = await _firestore
          .collection(_reportsCollection)
          .doc(reportId)
          .get(const GetOptions(source: Source.server)); // Force server read

      if (!doc.exists) {
        print('❌ Report $reportId not found for auto-verification check');
        return false;
      }

      final report = CameraReport.fromJson(doc.data()!);
      final isAutoVerified = report.status == CameraStatus.verified &&
          report.verifiedBy == 'auto_system';

      print('📊 Auto-verification check result:');
      print('   Report ID: $reportId');
      print('   Status: ${report.status}');
      print('   Verified by: ${report.verifiedBy}');
      print('   Is auto-verified: $isAutoVerified');
      print('   Report type: ${report.type}');
      print('   Confidence: ${report.confidenceScore}');

      return isAutoVerified;
    } catch (e) {
      print('❌ Error checking auto-verification for $reportId: $e');
      return false;
    }
  }

  /// Promote verified report to main speed camera database
  static Future<void> _promoteToMainDatabase(String reportId) async {
    try {
      print('🚀 === PROMOTION PROCESS START ===');
      print('🚀 Attempting to promote report $reportId to main database');

      final doc = await _firestore
          .collection(_reportsCollection)
          .doc(reportId)
          .get(const GetOptions(source: Source.server)); // Force server read

      if (!doc.exists) {
        print('❌ Report $reportId not found - cannot promote');
        return;
      }

      final report = CameraReport.fromJson(doc.data()!);
      print('📊 Report details for promotion:');
      print('   Report ID: $reportId');
      print('   Status: ${report.status}');
      print('   Type: ${report.type}');
      print('   Verified by: ${report.verifiedBy}');
      print('   Road: ${report.roadName}');
      print('   Location: (${report.latitude}, ${report.longitude})');
      print('   Confidence: ${report.confidenceScore}');
      print('   Speed Limit: ${report.speedLimit}');

      // ตรวจสอบเงื่อนไขการเลื่อนขั้น
      if (report.status != CameraStatus.verified) {
        print('❌ Report status is not verified: ${report.status}');
        return;
      }

      if (report.type != CameraReportType.newCamera) {
        print('❌ Report type is not newCamera: ${report.type}');
        return;
      }

      print('✅ Report meets basic promotion criteria');

      // ตรวจสอบว่ามีกล้องซ้ำในรัศมี 100 เมตรหรือไม่
      print('🔍 Checking for duplicate cameras within 100m...');
      final nearbyCameras = await getAllSpeedCameras();
      print('📊 Found ${nearbyCameras.length} existing cameras to check');

      bool hasDuplicate = false;
      String? duplicateInfo;

      for (final camera in nearbyCameras) {
        final distance = _calculateDistance(
          report.latitude,
          report.longitude,
          camera.location.latitude,
          camera.location.longitude,
        );
        final distanceInMeters = distance * 1000;

        print(
            '   Camera: ${camera.roadName} - Distance: ${distanceInMeters.toStringAsFixed(2)}m');

        if (distanceInMeters <= 100) {
          hasDuplicate = true;
          duplicateInfo =
              '${camera.roadName} (${camera.id}) at ${distanceInMeters.toStringAsFixed(2)}m';
          print('⚠️ Duplicate camera found within 100m:');
          print(
              '   Existing: ${camera.roadName} at (${camera.location.latitude}, ${camera.location.longitude})');
          print('   Distance: ${distanceInMeters.toStringAsFixed(2)}m');
          print('   Duplicate camera ID: ${camera.id}');
          break;
        }
      }

      if (hasDuplicate) {
        print('⚠️ Duplicate camera found within 100m - skipping promotion');
        print('⚠️ Duplicate info: $duplicateInfo');
        return;
      }

      print('✅ No duplicate cameras found - proceeding with promotion');

      // Create new speed camera entry
      final cameraId = _firestore.collection('speed_cameras').doc().id;
      print('🏗️ Creating new camera with ID: $cameraId');

      final speedCamera = SpeedCamera(
        id: cameraId,
        location:
            LatLng(report.latitude, report.longitude), // Use latlong2 LatLng
        speedLimit: report.speedLimit,
        roadName: report.roadName,
        type: CameraType.fixed, // Default to fixed
        isActive: true,
        description:
            'Community verified camera (${report.confidenceScore.toStringAsFixed(2)} confidence)',
      );

      final cameraData = speedCamera.toJson();
      print('📝 Camera data to save:');
      print('   ID: ${speedCamera.id}');
      print('   Road: ${speedCamera.roadName}');
      print(
          '   Location: (${speedCamera.location.latitude}, ${speedCamera.location.longitude})');
      print('   Speed Limit: ${speedCamera.speedLimit}');
      print('   Type: ${speedCamera.type}');
      print('   Is Active: ${speedCamera.isActive}');
      print('   Description: ${speedCamera.description}');

      // บันทึกกล้องใหม่
      print('💾 Saving camera to Firebase...');
      await _firestore
          .collection('speed_cameras')
          .doc(speedCamera.id)
          .set(cameraData);

      print(
          '🎉 Successfully promoted report $reportId to main database as camera $cameraId');
      print(
          '📍 Camera location: ${report.roadName} (${report.latitude}, ${report.longitude})');

      // ตรวจสอบว่าบันทึกสำเร็จหรือไม่ด้วย server read
      print('🔍 Verifying camera was saved successfully...');
      final savedCamera = await _firestore
          .collection('speed_cameras')
          .doc(cameraId)
          .get(const GetOptions(source: Source.server));

      if (savedCamera.exists) {
        print('✅ Camera successfully saved to Firebase');
        final savedData = savedCamera.data() as Map<String, dynamic>;
        print('📊 Saved camera verification:');
        print('   ID: ${savedData['id']}');
        print('   Road: ${savedData['roadName']}');
        print('   Speed Limit: ${savedData['speedLimit']}');
        print('   Is Active: ${savedData['isActive']}');
        print('   Location Object: ${savedData['location']}');
        print('   Latitude: ${savedData['latitude']}');
        print('   Longitude: ${savedData['longitude']}');

        // Force refresh speed camera service
        print('🔄 Requesting speed camera service refresh...');
        try {
          // Call speed camera service to refresh data
          final refreshedCameras = await getAllSpeedCameras(forceRefresh: true);
          print(
              '✅ Speed camera refresh completed - found ${refreshedCameras.length} cameras');
        } catch (e) {
          print('⚠️ Could not refresh speed camera service: $e');
        }
      } else {
        print(
            '❌ Failed to save camera to Firebase - camera not found after save');
      }
      print('🚀 === PROMOTION PROCESS COMPLETE ===');
    } catch (e) {
      print('❌ Error promoting report $reportId to main database: $e');
      print('🔍 Error stack trace: ${e.toString()}');
      print('🔍 Error type: ${e.runtimeType}');

      if (e.toString().contains('permission-denied')) {
        print('🚫 Permission denied - check Firestore security rules');
      } else if (e.toString().contains('not-found')) {
        print(
            '🔍 Document not found - check collection names and document IDs');
      }

      // Re-throw the error for debugging but don't fail the entire vote process
      throw Exception('Promotion failed: ${e.toString()}');
    }
  }

  /// Get all speed cameras from main database (เพื่อตรวจสอบว่ากล้องถูกเพิ่มแล้วหรือยัง)
  static Future<List<SpeedCamera>> getAllSpeedCameras({
    double? userLat,
    double? userLng,
    double radiusKm =
        1000.0, // เพิ่มจาก 50 เป็น 1000 km (ครอบคลุมทั้งประเทศไทย)
    bool forceRefresh = true,
    bool showAllNationwide = false, // ตัวเลือกใหม่: แสดงทั้งประเทศ
  }) async {
    print('🔍 getAllSpeedCameras called with radius: ${radiusKm}km');
    print('🌏 Show all nationwide: $showAllNationwide');

    // ใช้ query ที่เรียบง่าย เพื่อไม่ต้องสร้าง compound index
    Query query = _firestore
        .collection('speed_cameras')
        .where('isActive', isEqualTo: true);

    final snapshot = await query
        .get(forceRefresh ? const GetOptions(source: Source.server) : null);

    print('📊 Speed cameras query result: ${snapshot.docs.length} cameras');

    final cameras = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      print('   Camera: ${data['roadName']} - ${data['description']}');
      return SpeedCamera.fromJson(data);
    }).toList();

    // จัดเรียงตาม roadName ใน Dart แทนการใช้ orderBy ใน Firestore
    cameras.sort((a, b) => a.roadName.compareTo(b.roadName));

    // Filter by distance if user location provided
    if (userLat != null && userLng != null && !showAllNationwide) {
      final originalCount = cameras.length;
      cameras.removeWhere((camera) {
        final distance = _calculateDistance(userLat, userLng,
            camera.location.latitude, camera.location.longitude);
        return distance > radiusKm;
      });
      print(
          '📍 Distance filter: ${originalCount} -> ${cameras.length} cameras (within ${radiusKm}km)');
    } else if (showAllNationwide) {
      print('🌏 Showing all cameras nationwide - no distance filter applied');
    }

    return cameras;
  }

  /// Get verified reports (เพื่อดูว่าโหวตแล้วเปลี่ยนสถานะหรือยัง)
  static Future<List<CameraReport>> getVerifiedReports({
    double? userLat,
    double? userLng,
    double radiusKm =
        1000.0, // เพิ่มจาก 50 เป็น 1000 km (ครอบคลุมทั้งประเทศไทย)
    int limit = 50, // เพิ่มจาก 20 เป็น 50 โพสต์
    bool forceRefresh = true,
    bool showAllNationwide = false, // ตัวเลือกใหม่: แสดงทั้งประเทศ
  }) async {
    print('🔍 getVerifiedReports called with radius: ${radiusKm}km');
    print('🌏 Show all nationwide: $showAllNationwide');

    Query query = _firestore
        .collection(_reportsCollection)
        .where('status', isEqualTo: 'verified')
        .orderBy('verifiedAt', descending: true)
        .limit(limit);

    final snapshot = await query
        .get(forceRefresh ? const GetOptions(source: Source.server) : null);

    print(
        '📊 Verified reports query result: ${snapshot.docs.length} documents');

    final reports = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      print('   Verified Report: ${data['roadName']} - ${data['verifiedAt']}');
      return CameraReport.fromJson(data);
    }).toList();

    // Filter by distance if user location provided
    if (userLat != null && userLng != null && !showAllNationwide) {
      final originalCount = reports.length;
      reports.removeWhere((report) {
        final distance = _calculateDistance(
            userLat, userLng, report.latitude, report.longitude);
        return distance > radiusKm;
      });
      print(
          '📍 Distance filter: ${originalCount} -> ${reports.length} verified reports (within ${radiusKm}km)');
    } else if (showAllNationwide) {
      print(
          '🌏 Showing all verified reports nationwide - no distance filter applied');
    }

    return reports;
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

  /// ฟังก์ชันทดสอบสำหรับ Debug Auto-Verification และ Promotion
  static Future<void> debugAutoVerificationProcess() async {
    print('🧪 === DEBUG AUTO-VERIFICATION PROCESS ===');

    try {
      // 1. ตรวจสอบรายงานที่ verified แล้ว
      print('🔍 Step 1: Checking verified reports...');
      final verifiedReports = await getReportsByStatus(CameraStatus.verified);
      print('📊 Found ${verifiedReports.length} verified reports');

      for (final report in verifiedReports) {
        print('   Verified Report: ${report.roadName} (${report.id})');
        print('     Status: ${report.status}');
        print('     Type: ${report.type}');
        print('     Verified by: ${report.verifiedBy}');
        print('     Confidence: ${report.confidenceScore}');
      }

      // 2. ตรวจสอบกล้องในฐานข้อมูลหลัก
      print('🔍 Step 2: Checking main speed camera database...');
      final allCameras = await getAllSpeedCameras();
      print('📊 Found ${allCameras.length} cameras in main database');

      final communityCameras = allCameras
          .where((camera) =>
              camera.description?.contains('Community verified') == true)
          .toList();
      print('🏘️ Community cameras: ${communityCameras.length}');

      for (final camera in communityCameras) {
        print('   Community Camera: ${camera.roadName} (${camera.id})');
        print(
            '     Location: (${camera.location.latitude}, ${camera.location.longitude})');
        print('     Description: ${camera.description}');
      }

      // 3. ตรวจสอบว่ามี verified report ที่ยังไม่ได้เลื่อนขั้นหรือไม่
      print('🔍 Step 3: Checking for verified reports that need promotion...');
      final newCameraReports = verifiedReports
          .where((report) =>
              report.type == CameraReportType.newCamera &&
              report.verifiedBy == 'auto_system')
          .toList();

      print('📊 Found ${newCameraReports.length} verified new camera reports');

      for (final report in newCameraReports) {
        print('   Report to promote: ${report.roadName} (${report.id})');

        // ตรวจสอบว่ามีกล้องในตำแหน่งนี้แล้วหรือยัง
        final nearbyCamera = communityCameras.where((camera) {
          final distance = _calculateDistance(report.latitude, report.longitude,
              camera.location.latitude, camera.location.longitude);
          return distance <= 0.1; // 100 meters
        }).toList();

        if (nearbyCamera.isEmpty) {
          print(
              '     ⚠️  This report should be promoted but camera not found!');
          print('     🔧 Attempting manual promotion...');
          try {
            await _promoteToMainDatabase(report.id);
          } catch (e) {
            print('     ❌ Manual promotion failed: $e');
          }
        } else {
          print('     ✅ Camera already exists: ${nearbyCamera.first.id}');
        }
      }

      print('🧪 === DEBUG PROCESS COMPLETE ===');
    } catch (e) {
      print('❌ Debug process failed: $e');
    }
  }

  /// ฟังก์ชันทดสอบการสร้างรายงานและโหวตอัตโนมัติ
  static Future<void> createTestReportAndVotes({
    required double latitude,
    required double longitude,
    required String roadName,
    int speedLimit = 90,
    int numberOfUpvotes = 3,
    int numberOfDownvotes = 0,
  }) async {
    print('🧪 === CREATING TEST REPORT AND VOTES ===');

    try {
      // สร้างรายงานทดสอบ
      print('📝 Creating test report...');
      final reportId = await submitReport(
        latitude: latitude,
        longitude: longitude,
        roadName: roadName,
        speedLimit: speedLimit,
        type: CameraReportType.newCamera,
        description: 'TEST REPORT - Auto-generated for debugging',
      );

      print('✅ Test report created: $reportId');
      print('   Location: ($latitude, $longitude)');
      print('   Road: $roadName');

      // รอสักครู่ให้ข้อมูลซิงค์
      await Future.delayed(const Duration(seconds: 2));

      // สร้างโหวตทดสอบ
      print('🗳️  Creating test votes...');

      // Upvotes
      for (int i = 0; i < numberOfUpvotes; i++) {
        try {
          await submitVote(
            reportId: reportId,
            voteType: VoteType.upvote,
          );
          print('   ✅ Upvote ${i + 1}/$numberOfUpvotes');
          await Future.delayed(const Duration(seconds: 1));
        } catch (e) {
          print('   ❌ Upvote ${i + 1} failed: $e');
        }
      }

      // Downvotes
      for (int i = 0; i < numberOfDownvotes; i++) {
        try {
          await submitVote(
            reportId: reportId,
            voteType: VoteType.downvote,
          );
          print('   ✅ Downvote ${i + 1}/$numberOfDownvotes');
          await Future.delayed(const Duration(seconds: 1));
        } catch (e) {
          print('   ❌ Downvote ${i + 1} failed: $e');
        }
      }

      // ตรวจสอบผล
      await Future.delayed(const Duration(seconds: 3));
      print('🔍 Checking final result...');

      final reportDoc =
          await _firestore.collection(_reportsCollection).doc(reportId).get();
      if (reportDoc.exists) {
        final updatedReport = CameraReport.fromJson(reportDoc.data()!);
        print('📊 Final report status:');
        print('   Status: ${updatedReport.status}');
        print('   Upvotes: ${updatedReport.upvotes}');
        print('   Downvotes: ${updatedReport.downvotes}');
        print('   Confidence: ${updatedReport.confidenceScore}');
        print('   Verified by: ${updatedReport.verifiedBy}');
      }

      print('🧪 === TEST COMPLETE ===');
    } catch (e) {
      print('❌ Test failed: $e');
    }
  }
}

// Remove the local LatLng class since we're using latlong2
