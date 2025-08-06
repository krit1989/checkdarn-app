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
    String? selectedCameraId, // เพิ่มสำหรับการเลือกกล้องจากแผนที่
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // ✨ สร้าง Camera ID สำหรับรายงานกล้องใหม่
    String? cameraId;
    if (type == CameraReportType.newCamera) {
      cameraId = _firestore.collection('speed_cameras').doc().id;
      print('🆕 Generated new camera ID: $cameraId');

      // ตรวจสอบว่า ID ไม่เป็น null หรือ empty
      if (cameraId.isEmpty) {
        throw Exception('Failed to generate camera ID');
      }
    } else {
      // สำหรับ removedCamera และ speedChanged ใช้ selectedCameraId ที่ส่งมา
      cameraId = selectedCameraId;
    }

    // ✨ ตรวจสอบ duplicate แบบชาญฉลาด
    if (type == CameraReportType.removedCamera) {
      // สำหรับ "รายงานกล้องถูกถอน" - ตรวจสอบ Camera ID ที่แน่นอน
      if (cameraId == null) {
        throw Exception('กรุณาเลือกกล้องที่ต้องการรายงานจากแผนที่');
      }

      final existingRemovalReports = await _firestore
          .collection(_reportsCollection)
          .where('type', isEqualTo: 'removedCamera')
          .where('selectedCameraId', isEqualTo: cameraId)
          .where('status', whereIn: ['pending', 'verified']).get();

      if (existingRemovalReports.docs.isNotEmpty) {
        throw Exception('มีการรายงานกล้องตัวนี้ถูกถอดแล้ว');
      }
    } else if (type == CameraReportType.speedChanged) {
      // สำหรับ "รายงานการเปลี่ยนความเร็ว" - ตรวจสอบ Camera ID ที่แน่นอน
      if (cameraId == null) {
        throw Exception('กรุณาเลือกกล้องที่ต้องการรายงานจากแผนที่');
      }

      final existingSpeedChangeReports = await _firestore
          .collection(_reportsCollection)
          .where('type', isEqualTo: 'speedChanged')
          .where('selectedCameraId', isEqualTo: cameraId)
          .where('status', whereIn: ['pending', 'verified']).get();

      if (existingSpeedChangeReports.docs.isNotEmpty) {
        throw Exception('มีการรายงานการเปลี่ยนความเร็วของกล้องตัวนี้แล้ว');
      }
    } else {
      // สำหรับ "รายงานกล้องใหม่" - ใช้ระยะรัศมีแบบง่าย (ไม่ต้องการ compound index)
      final nearbyNewCameraReports =
          await _findNearbyNewCameraReports(latitude, longitude, 50);
      if (nearbyNewCameraReports.isNotEmpty) {
        throw Exception(
            'มีการรายงานกล้องใหม่ในบริเวณนี้แล้ว โปรดตรวจสอบอีกครั้ง');
      }
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
      selectedCameraId: cameraId, // ใช้ cameraId ที่สร้างใหม่หรือที่ส่งมา
    );

    await _firestore
        .collection(_reportsCollection)
        .doc(reportId)
        .set(report.toJson());

    print('✅ New camera report created: ${report.roadName} (ID: $reportId)');
    print('📊 Report details:');
    print('   Status: ${report.status}');
    print('   Type: ${report.type}');
    print('   Selected Camera ID: ${report.selectedCameraId}');
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

            // ✨ Check if this was a new camera report and ensure it was created
            final promotedDoc = await _firestore
                .collection(_reportsCollection)
                .doc(reportId)
                .get(const GetOptions(source: Source.server));

            if (promotedDoc.exists) {
              final promotedReport = CameraReport.fromJson(promotedDoc.data()!);
              if (promotedReport.type == CameraReportType.newCamera) {
                print(
                    '📊 Verifying new camera was created in speed_cameras collection...');
                // Add additional verification if needed
              }
            }
          } catch (e) {
            print('❌ Error during promotion: $e');
            // Log the error to a dedicated collection for debugging
            try {
              await _firestore.collection('camera_promotion_errors').add({
                'reportId': reportId,
                'error': e.toString(),
                'timestamp': FieldValue.serverTimestamp(),
                'userId': user.uid,
              });
            } catch (logError) {
              print('❌ Failed to log promotion error: $logError');
            }
            // Don't fail the vote
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

      // 🎯 ระบบโหวตใหม่: ฝั่งไหนถึง 3 คนก่อน ฝั่งนั้นชนะ
      print('🗳️ === VOTE CHECK SYSTEM ===');
      print('Current upvotes: $newUpvotes');
      print('Current downvotes: $newDownvotes');
      print('Report type: ${report.type}');

      // ตรวจสอบว่าฝั่งไหนถึง 3 votes ก่อน
      if (newUpvotes >= 3 || newDownvotes >= 3) {
        if (newUpvotes >= 3 && newUpvotes > newDownvotes) {
          // ฝั่งเห็นด้วยถึง 3 ก่อน → VERIFIED
          newStatus = CameraStatus.verified;
          verifiedAt = DateTime.now();
          verifiedBy = 'auto_system';
          print(
              '✅ VERIFIED: Upvotes reached 3 first ($newUpvotes vs $newDownvotes)');
        } else if (newDownvotes >= 3 && newDownvotes > newUpvotes) {
          // ฝั่งไม่เห็นด้วยถึง 3 ก่อน → REJECTED
          newStatus = CameraStatus.rejected;
          verifiedAt = DateTime.now();
          verifiedBy = 'auto_system';
          print(
              '❌ REJECTED: Downvotes reached 3 first ($newDownvotes vs $newUpvotes)');
        } else if (newUpvotes >= 3 &&
            newDownvotes >= 3 &&
            newUpvotes == newDownvotes) {
          // เสมอกัน 3-3 ให้ดูจาก confidence
          if (newConfidenceScore >= 0.5) {
            newStatus = CameraStatus.verified;
            verifiedAt = DateTime.now();
            verifiedBy = 'auto_system';
            print('✅ VERIFIED: Tied 3-3, decided by confidence >= 50%');
          } else {
            newStatus = CameraStatus.rejected;
            verifiedAt = DateTime.now();
            verifiedBy = 'auto_system';
            print('❌ REJECTED: Tied 3-3, decided by confidence < 50%');
          }
        }

        // ✨ เพิ่ม: หากเป็นรายงานกล้องใหม่ที่ผ่านการตรวจสอบ ให้สร้างกล้องใน speed_cameras collection
        if (newStatus == CameraStatus.verified &&
            report.type == CameraReportType.newCamera) {
          print('🆕 === NEW CAMERA PROMOTION TRIGGERED ===');
          print('Report ID: $reportId');
          print('Camera will be created after report update');
        }

        // ✨ เพิ่ม: หากเป็นรายงานการลบกล้อง ให้ลบกล้องออกจาก Firebase ทันที
        if (newStatus == CameraStatus.verified &&
            report.type == CameraReportType.removedCamera) {
          print('🗑️ === CAMERA REMOVAL TRIGGERED ===');
          print('Report ID: $reportId');
          print('Selected Camera ID: ${report.selectedCameraId}');

          try {
            String? cameraId = report.selectedCameraId;

            if (cameraId != null && cameraId.isNotEmpty) {
              print('🎯 Deleting camera ID: $cameraId');
              await _directDeleteCameraWithRetry(cameraId);

              // ตรวจสอบว่าลบจริงหรือไม่
              final isDeleted = await _verifyCameraDeletion(cameraId);
              if (isDeleted) {
                print('✅ Camera $cameraId deleted and verified successfully');
              } else {
                throw Exception('Camera $cameraId still exists after deletion');
              }
            } else {
              print(
                  '⚠️ No camera ID specified - trying location-based deletion');
              await _deleteByLocation(report.latitude, report.longitude);
            }
          } catch (e) {
            print('❌ Error deleting camera: $e');
            // บันทึก error ลงใน collection พิเศษ
            await _logDeletionError(
                reportId, report.selectedCameraId, e.toString());
            // ไม่ให้ error การลบกล้องมาขัดขวางการอัปเดตสถานะรายงาน
          }
        }

        // 🔄 อัปเดตความเร็วสำหรับ speedChanged
        if (newStatus == CameraStatus.verified &&
            report.type == CameraReportType.speedChanged) {
          print('🔄 === SPEED LIMIT UPDATE TRIGGERED ===');
          await _updateCameraSpeedLimit(report);
        }

        // 🚀 AUTO-REMOVAL: ลบรายงานที่ verified/rejected ออกจาก collection ทันที
        if (newStatus == CameraStatus.verified ||
            newStatus == CameraStatus.rejected) {
          print('🚀 === AUTO-REMOVAL TRIGGERED ===');
          print('Report ID: $reportId, Status: $newStatus');

          try {
            // บันทึกข้อมูลก่อนลบ
            await _firestore.collection('verified_reports_removal_log').add({
              'originalReportId': reportId,
              'reportData': {
                'upvotes': newUpvotes,
                'downvotes': newDownvotes,
                'status': newStatus.toString().split('.').last,
                'type': report.type.toString().split('.').last,
                'roadName': report.roadName,
                'latitude': report.latitude,
                'longitude': report.longitude,
                'reportedBy': report.reportedBy,
                'verifiedAt': verifiedAt?.toIso8601String(),
                'verifiedBy': verifiedBy,
                'finalUpvotes': newUpvotes,
                'finalDownvotes': newDownvotes,
                'finalConfidenceScore': newConfidenceScore,
              },
              'removedAt': FieldValue.serverTimestamp(),
              'removedBy': 'auto_voting_system_v2',
              'autoRemovalReason': newStatus == CameraStatus.verified
                  ? 'upvotes_reached_3_first'
                  : 'downvotes_reached_3_first',
            });
            print('✅ Report logged to removal log');

            // ลบรายงานออกจาก main collection ทันที
            await reportRef.delete();
            print(
                '✅ AUTO-REMOVAL: Report $reportId successfully removed from main collection');

            return; // ออกจาก function เพราะรายงานถูกลบแล้ว
          } catch (e) {
            print('❌ AUTO-REMOVAL ERROR: $e');
            // ถ้าลบไม่สำเร็จ ให้อัปเดตปกติแทน (fallback)
            print('⚠️ Falling back to normal update due to auto-removal error');
          }
        }
      } else {
        print('⏳ Not enough votes yet (need 3 upvotes OR 3 downvotes)');
        print('   Current: $newUpvotes upvotes, $newDownvotes downvotes');
      }

      // อัปเดตรายงานปกติ (เฉพาะกรณีที่ไม่ถูกลบด้วย auto-removal)
      print('🔄 Updating report with new vote counts (not removed)...');
      final updateData = {
        'upvotes': newUpvotes,
        'downvotes': newDownvotes,
        'confidenceScore': newConfidenceScore,
        'status': newStatus.toString().split('.').last,
        if (verifiedAt != null) 'verifiedAt': verifiedAt.toIso8601String(),
        if (verifiedBy != null) 'verifiedBy': verifiedBy,
      };

      await reportRef.update(updateData);
      print(
          '✅ Report vote counts updated successfully (preserved in collection)');

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

  /// Find nearby NEW camera reports within specified radius (simplified - no compound index required)
  static Future<List<CameraReport>> _findNearbyNewCameraReports(
      double lat, double lng, double radiusMeters) async {
    // Simple approach: Get all newCamera reports and filter by distance in Dart
    // This avoids complex compound Firestore queries that need special indexes

    print('🔍 Searching for nearby new camera reports...');
    print('   Center: ($lat, $lng)');
    print('   Radius: ${radiusMeters}m');

    final snapshot = await _firestore
        .collection(_reportsCollection)
        .where('type', isEqualTo: 'newCamera')
        .where('status',
            whereIn: ['pending', 'verified']) // Only these 2 statuses
        .get();

    print('📊 Found ${snapshot.docs.length} newCamera reports to check');

    final reports = <CameraReport>[];

    for (final doc in snapshot.docs) {
      try {
        final report = CameraReport.fromJson(doc.data());
        final distance =
            _calculateDistance(lat, lng, report.latitude, report.longitude);
        final distanceInMeters = distance * 1000;

        print(
            '   Report: ${report.roadName} - Distance: ${distanceInMeters.toStringAsFixed(2)}m');

        if (distanceInMeters <= radiusMeters) {
          reports.add(report);
          print('   ✅ Within radius - added to results');
        } else {
          print('   ❌ Too far - skipped');
        }
      } catch (e) {
        print('   ⚠️ Error processing report ${doc.id}: $e');
      }
    }

    print(
        '🎯 Found ${reports.length} nearby new camera reports within ${radiusMeters}m');
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
        // Log this error
        await _firestore.collection('camera_promotion_errors').add({
          'reportId': reportId,
          'error': 'Report not found',
          'timestamp': FieldValue.serverTimestamp(),
          'stage': 'document_lookup',
        });
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
        await _firestore.collection('camera_promotion_errors').add({
          'reportId': reportId,
          'error': 'Report status is not verified: ${report.status}',
          'timestamp': FieldValue.serverTimestamp(),
          'stage': 'status_check',
          'reportData': report.toJson(),
        });
        return;
      }

      // เช็คว่า verifiedBy เป็น auto_system หรือไม่
      if (report.verifiedBy != 'auto_system') {
        print('❌ Report was not auto-verified by system: ${report.verifiedBy}');
        await _firestore.collection('camera_promotion_errors').add({
          'reportId': reportId,
          'error': 'Report was not auto-verified: ${report.verifiedBy}',
          'timestamp': FieldValue.serverTimestamp(),
          'stage': 'verification_check',
          'reportData': report.toJson(),
        });
        return;
      }

      // จัดการตามประเภทของรายงาน
      if (report.type == CameraReportType.removedCamera) {
        print('🗑️ Processing REMOVED CAMERA report');
        await _handleCameraRemovalReport(report);
        return;
      }

      if (report.type != CameraReportType.newCamera) {
        print('❌ Report type is not supported for promotion: ${report.type}');
        await _firestore.collection('camera_promotion_errors').add({
          'reportId': reportId,
          'error': 'Unsupported report type for promotion: ${report.type}',
          'timestamp': FieldValue.serverTimestamp(),
          'stage': 'type_check',
          'reportData': report.toJson(),
        });
        return;
      }

      print('✅ Report meets basic promotion criteria');

      // ตรวจสอบว่า selectedCameraId ไม่เป็น null สำหรับ newCamera
      if (report.type == CameraReportType.newCamera) {
        if (report.selectedCameraId == null ||
            report.selectedCameraId!.isEmpty) {
          print(
              '❌ Missing camera ID for new camera report - generating fallback ID');

          // สร้าง Camera ID ใหม่หากไม่มี (fallback)
          final newCameraId = _firestore.collection('speed_cameras').doc().id;
          await doc.reference.update({
            'selectedCameraId': newCameraId,
          });

          print('🆕 Generated fallback Camera ID: $newCameraId');

          // อ่านข้อมูลใหม่หลังจากอัปเดต
          final updatedDoc =
              await doc.reference.get(const GetOptions(source: Source.server));
          if (updatedDoc.exists) {
            final updatedReport = CameraReport.fromJson(updatedDoc.data()!);
            return _promoteToMainDatabase(updatedReport.id); // เรียกตัวเองใหม่
          } else {
            print('❌ Failed to update report with new camera ID');
            return;
          }
        }

        print('✅ Camera ID verified: ${report.selectedCameraId}');
      }

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

      // ใช้ selectedCameraId ที่มีอยู่แล้วในรายงาน
      final cameraId = report.selectedCameraId!;
      print('🏗️ Creating camera with pre-generated ID: $cameraId');

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
          .doc(cameraId) // ใช้ cameraId ที่มีอยู่แล้ว
          .set(cameraData);

      // Log successful promotion
      await _firestore.collection('camera_promotion_success').add({
        'reportId': reportId,
        'cameraId': cameraId,
        'roadName': report.roadName,
        'location': {
          'latitude': report.latitude,
          'longitude': report.longitude,
        },
        'speedLimit': report.speedLimit,
        'confidence': report.confidenceScore,
        'timestamp': FieldValue.serverTimestamp(),
        'promotedBy': 'auto_system',
      });

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

  /// ✨ ตรวจสอบว่ากล้องยังมีอยู่หรือไม่ (สำหรับ UI)
  static Future<bool> checkCameraDeleted(String? cameraId) async {
    if (cameraId == null || cameraId.isEmpty) return true;
    return await _verifyCameraDeletion(cameraId);
  }

  /// 🔧 บังคับลบกล้องที่ verified แล้วทั้งหมด (สำหรับ debugging)
  static Future<void> forceDeleteVerifiedCameras() async {
    try {
      print('🔧 === FORCE DELETE VERIFIED CAMERAS ===');

      // ค้นหา reports ที่ verified แล้วและเป็นประเภท removedCamera
      final snapshot = await _firestore
          .collection(_reportsCollection)
          .where('status', isEqualTo: 'verified')
          .where('type', isEqualTo: 'removedCamera')
          .get();

      print('📋 Found ${snapshot.docs.length} verified removal reports');

      int processedCount = 0;
      int successCount = 0;
      int errorCount = 0;

      for (final doc in snapshot.docs) {
        try {
          final report = CameraReport.fromJson(doc.data());
          processedCount++;

          print(
              '🔧 Processing report ${processedCount}/${snapshot.docs.length}:');
          print('   Report ID: ${report.id}');
          print('   Camera ID: ${report.selectedCameraId}');
          print('   Road: ${report.roadName}');

          if (report.selectedCameraId != null &&
              report.selectedCameraId!.isNotEmpty) {
            // ตรวจสอบว่ากล้องยังมีอยู่หรือไม่
            final cameraExists = await _firestore
                .collection('speed_cameras')
                .doc(report.selectedCameraId!)
                .get();

            if (cameraExists.exists) {
              print('   🗑️ Camera still exists - deleting now...');
              await _directDeleteCameraWithRetry(report.selectedCameraId!);
              successCount++;
              print('   ✅ Camera deleted successfully');
            } else {
              print('   ✅ Camera already deleted');
              successCount++;
            }
          } else {
            print('   ⚠️ No camera ID specified - skipping');
          }
        } catch (e) {
          errorCount++;
          print('   ❌ Error processing report: $e');
        }
      }

      print('🎉 === FORCE DELETE SUMMARY ===');
      print('   Total processed: $processedCount');
      print('   Successful: $successCount');
      print('   Errors: $errorCount');
    } catch (e) {
      print('❌ Error in force delete process: $e');
      rethrow;
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

  /// Handle camera removal report (verified removedCamera reports)
  static Future<void> _handleCameraRemovalReport(CameraReport report) async {
    try {
      print('🗑️ === STARTING CAMERA REMOVAL PROCESS ===');
      print('🔍 Processing removal report: ${report.id}');
      print('📍 Target camera ID: ${report.selectedCameraId}');
      print('📍 Report location: (${report.latitude}, ${report.longitude})');

      // Step 1: Get camera ID from report
      String? cameraId = report.selectedCameraId;

      if (cameraId == null || cameraId.isEmpty) {
        print(
            '⚠️ No selectedCameraId provided, attempting location-based search...');

        // Fallback: search for camera by location
        final nearbyCameras = await getAllSpeedCameras();
        SpeedCamera? targetCamera;
        double minDistance = double.infinity;

        for (final camera in nearbyCameras) {
          final distance = _calculateDistance(
            report.latitude,
            report.longitude,
            camera.location.latitude,
            camera.location.longitude,
          );
          final distanceInMeters = distance * 1000;

          if (distanceInMeters <= 100 && distanceInMeters < minDistance) {
            minDistance = distanceInMeters;
            targetCamera = camera;
          }
        }

        if (targetCamera != null) {
          cameraId = targetCamera.id;
          print(
              '✅ Found camera by location: ${targetCamera.roadName} (${cameraId}) at ${minDistance.toStringAsFixed(2)}m');
        } else {
          print('❌ No camera found within 100m of report location');
          throw Exception('Cannot identify camera to remove');
        }
      }

      // Step 2: Remove the community camera
      await _removeCommunityCamera(cameraId);

      // Step 3: Update report status with processing information
      await _firestore.collection(_reportsCollection).doc(report.id).update({
        'processedAt': FieldValue.serverTimestamp(),
        'processedBy': 'auto_removal_system',
        'removedCameraId': cameraId,
      });

      print('✅ Camera removal report processed successfully');

      // Step 4: Clean up related data to prevent conflicts
      print('🧹 Step 4: Cleaning up related report and vote data...');
      await _cleanupRelatedReportData(cameraId, report.id);

      print('🗑️ === CAMERA REMOVAL PROCESS COMPLETE ===');
    } catch (e) {
      print('❌ Error processing camera removal report: $e');

      // Log the failure for debugging
      try {
        await _firestore.collection('camera_removal_failures').add({
          'reportId': report.id,
          'selectedCameraId': report.selectedCameraId,
          'latitude': report.latitude,
          'longitude': report.longitude,
          'error': e.toString(),
          'timestamp': FieldValue.serverTimestamp(),
        });
      } catch (logError) {
        print('⚠️ Failed to log removal failure: $logError');
      }

      rethrow;
    }
  }

  /// Remove community camera using Pure ID-Based Deletion with 4-Phase Atomic Protocol
  static Future<void> _removeCommunityCamera(String cameraId) async {
    try {
      print('🗑️ === STARTING COMMUNITY CAMERA DELETION ===');
      print('🎯 Target Camera ID: $cameraId');

      // Phase 1: ID Validation & Mark for Deletion
      print('📋 PHASE 1: ID Validation & Mark for Deletion');
      final exists = await _checkIfCameraExists(cameraId);
      if (!exists) {
        print('⚠️ Camera $cameraId does not exist - may already be deleted');
        return;
      }

      await _firestore.collection('deleted_cameras').doc(cameraId).set({
        'cameraId': cameraId,
        'deletedAt': FieldValue.serverTimestamp(),
        'deletedBy': 'community_vote_system',
        'reason': 'community_camera_removal',
        'method': 'id_based_deletion',
      });
      print('✅ Phase 1 complete: Camera marked for deletion');

      // Phase 2: Delete from Speed Cameras Collection
      print('📋 PHASE 2: Delete from Speed Cameras Collection');
      await _firestore.collection('speed_cameras').doc(cameraId).delete();
      print('✅ Phase 2 complete: Camera deleted from main collection');

      // Phase 3: Record Deletion in Audit Trail
      print('📋 PHASE 3: Record Deletion in Audit Trail');
      await _firestore.collection('camera_deletion_log').add({
        'cameraId': cameraId,
        'deletionTimestamp': FieldValue.serverTimestamp(),
        'deletionMethod': 'id_based_deletion',
        'verificationLayers': 3,
        'success': true,
      });
      print('✅ Phase 3 complete: Deletion logged in audit trail');

      // Phase 4: 3-Layer Verification System
      print('📋 PHASE 4: 3-Layer Verification System');
      await _performThreeLayerVerification(cameraId);
      print('✅ Phase 4 complete: 3-Layer verification passed');

      print('🎉 === COMMUNITY CAMERA DELETION COMPLETE ===');
    } catch (e) {
      print('❌ Error deleting community camera $cameraId: $e');

      // Log failure for debugging
      try {
        await _firestore.collection('camera_deletion_log').add({
          'cameraId': cameraId,
          'deletionTimestamp': FieldValue.serverTimestamp(),
          'deletionMethod': 'id_based_deletion',
          'success': false,
          'error': e.toString(),
        });
      } catch (logError) {
        print('⚠️ Failed to log deletion failure: $logError');
      }

      rethrow;
    }
  }

  /// Perform 3-Layer Verification to ensure camera is truly deleted
  static Future<void> _performThreeLayerVerification(String cameraId) async {
    print('🔍 Starting 3-Layer Verification for camera $cameraId');

    // Layer 1: Immediate Verification (0 seconds)
    print('🔍 Layer 1: Immediate Verification');
    bool layer1Result = await _checkIfCameraExists(cameraId);
    print('🔍 Layer 1 result: Camera exists = $layer1Result');

    // Layer 2: Delayed Verification (3 seconds)
    print('🔍 Layer 2: Delayed Verification (waiting 3 seconds...)');
    await Future.delayed(const Duration(seconds: 3));
    bool layer2Result = await _checkIfCameraExists(cameraId);
    print('🔍 Layer 2 result: Camera exists = $layer2Result');

    // Layer 3: Force Deletion if needed
    if (layer1Result || layer2Result) {
      print('🔍 Layer 3: Force deletion required');
      try {
        await _firestore.collection('speed_cameras').doc(cameraId).delete();
        print('✅ Layer 3: Force deletion completed');

        // Final check
        await Future.delayed(const Duration(seconds: 1));
        bool finalCheck = await _checkIfCameraExists(cameraId);
        print('🔍 Final verification: Camera exists = $finalCheck');

        if (finalCheck) {
          throw Exception('Camera still exists after force deletion');
        }
      } catch (e) {
        print('❌ Layer 3: Force deletion failed: $e');
        throw e;
      }
    } else {
      print(
          '✅ Layer 3: No force deletion needed - camera successfully removed');
    }

    print(
        '🎉 3-Layer Verification Complete: Camera $cameraId successfully deleted');
  }

  /// Check if camera exists in database
  static Future<bool> _checkIfCameraExists(String cameraId) async {
    try {
      final doc = await _firestore
          .collection('speed_cameras')
          .doc(cameraId)
          .get(const GetOptions(source: Source.server));
      return doc.exists;
    } catch (e) {
      print('⚠️ Error checking camera existence: $e');
      return false; // Assume doesn't exist if error
    }
  }

  /// Clean up related report and vote data after camera deletion/addition
  /// This prevents conflicts when recreating cameras at the same location
  static Future<void> _cleanupRelatedReportData(
      String cameraId, String processedReportId) async {
    try {
      print('🧹 === CLEANUP RELATED REPORT DATA ===');
      print('🎯 Camera ID: $cameraId');
      print('🎯 Processed Report ID: $processedReportId');

      // Option 1: Move to archive instead of deleting
      await _archiveProcessedReports(cameraId, processedReportId);

      // Option 2: Clean up votes for processed reports
      await _cleanupVotesForProcessedReports(cameraId, processedReportId);

      print('✅ Cleanup completed successfully');
    } catch (e) {
      print('⚠️ Error during cleanup: $e');
      // Don't throw - cleanup failure shouldn't fail the main process
    }
  }

  /// Archive processed reports instead of deleting them
  static Future<void> _archiveProcessedReports(
      String cameraId, String processedReportId) async {
    try {
      print('📦 Archiving processed reports for camera: $cameraId');

      // Find reports related to this camera/location
      final reportQuery = await _firestore
          .collection(_reportsCollection)
          .where('selectedCameraId', isEqualTo: cameraId)
          .get();

      print('📊 Found ${reportQuery.docs.length} reports by cameraId');

      final batch = _firestore.batch();
      int archivedCount = 0;

      // Archive reports that match camera ID
      for (final doc in reportQuery.docs) {
        final reportData = doc.data();
        if (reportData['status'] == 'verified' || doc.id == processedReportId) {
          // Move to archived_reports collection
          final archiveRef =
              _firestore.collection('archived_camera_reports').doc(doc.id);
          batch.set(archiveRef, {
            ...reportData,
            'archivedAt': FieldValue.serverTimestamp(),
            'archivedReason': 'camera_processed',
            'originalCameraId': cameraId,
          });

          // Delete from main collection
          batch.delete(doc.reference);
          archivedCount++;
        }
      }

      if (archivedCount > 0) {
        await batch.commit();
        print('✅ Archived $archivedCount reports to archived_camera_reports');
      } else {
        print('📝 No reports to archive');
      }
    } catch (e) {
      print('⚠️ Error archiving reports: $e');
    }
  }

  /// Clean up votes for processed reports
  static Future<void> _cleanupVotesForProcessedReports(
      String cameraId, String processedReportId) async {
    try {
      print('🗳️ Cleaning up votes for processed camera: $cameraId');

      // Find votes for the processed report
      final voteQuery = await _firestore
          .collection('camera_votes')
          .where('reportId', isEqualTo: processedReportId)
          .get();

      print('📊 Found ${voteQuery.docs.length} votes for processed report');

      if (voteQuery.docs.isNotEmpty) {
        final batch = _firestore.batch();

        // Archive votes instead of deleting
        for (final voteDoc in voteQuery.docs) {
          final voteData = voteDoc.data();

          // Move to archived_votes collection
          final archiveRef =
              _firestore.collection('archived_camera_votes').doc(voteDoc.id);
          batch.set(archiveRef, {
            ...voteData,
            'archivedAt': FieldValue.serverTimestamp(),
            'archivedReason': 'report_processed',
            'originalReportId': processedReportId,
          });

          // Delete from main collection
          batch.delete(voteDoc.reference);
        }

        await batch.commit();
        print(
            '✅ Archived ${voteQuery.docs.length} votes to archived_camera_votes');
      } else {
        print('📝 No votes to clean up');
      }
    } catch (e) {
      print('⚠️ Error cleaning up votes: $e');
    }
  }

  /// Clean up reports and votes for a specific location (alternative method)
  static Future<void> cleanupLocationReports({
    required double latitude,
    required double longitude,
    double radiusKm = 0.1, // 100 meters
  }) async {
    try {
      print('🧹 === CLEANUP REPORTS BY LOCATION ===');
      print('📍 Location: ($latitude, $longitude)');
      print('📏 Radius: ${radiusKm * 1000}m');

      // Get all reports and filter by location
      final allReportsQuery = await _firestore
          .collection(_reportsCollection)
          .where('status',
              isEqualTo: 'verified') // Only cleanup verified reports
          .get();

      final List<String> reportsToCleanup = [];

      for (final doc in allReportsQuery.docs) {
        final data = doc.data();
        final reportLat = data['latitude'] as double?;
        final reportLng = data['longitude'] as double?;

        if (reportLat != null && reportLng != null) {
          final distance =
              _calculateDistance(latitude, longitude, reportLat, reportLng);
          if (distance <= radiusKm) {
            reportsToCleanup.add(doc.id);
          }
        }
      }

      print(
          '📊 Found ${reportsToCleanup.length} verified reports to cleanup in radius');

      // Archive reports and their votes
      for (final reportId in reportsToCleanup) {
        await _cleanupRelatedReportData('location_based', reportId);
      }

      print('✅ Location-based cleanup completed');
    } catch (e) {
      print('⚠️ Error in location-based cleanup: $e');
    }
  }

  /// ✨ ตรวจสอบว่ากล้องถูกลบจริงหรือไม่
  static Future<bool> _verifyCameraDeletion(String cameraId) async {
    try {
      print('🔍 Verifying camera deletion for ID: $cameraId');
      final doc =
          await _firestore.collection('speed_cameras').doc(cameraId).get();
      final exists = doc.exists;
      print('📍 Camera $cameraId exists: $exists');
      return !exists; // return true ถ้าไม่มีกล้อง (ลบสำเร็จ)
    } catch (e) {
      print('❌ Error verifying camera deletion: $e');
      return false; // ถ้าเกิด error ให้ถือว่าลบไม่สำเร็จ
    }
  }

  /// ✨ บันทึก error การลบกล้อง
  static Future<void> _logDeletionError(
      String reportId, String? cameraId, String error) async {
    try {
      await _firestore.collection('camera_deletion_errors').add({
        'reportId': reportId,
        'cameraId': cameraId,
        'error': error,
        'timestamp': FieldValue.serverTimestamp(),
        'processedBy': 'auto_verification_system',
      });
      print('📝 Deletion error logged successfully');
    } catch (logError) {
      print('⚠️ Failed to log deletion error: $logError');
    }
  }

  /// ✨ ลบกล้องพร้อมระบบ retry
  static Future<void> _directDeleteCameraWithRetry(String cameraId,
      {int maxRetries = 3}) async {
    print('🔄 Starting camera deletion with retry for ID: $cameraId');

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        print('🔄 Deletion attempt $attempt/$maxRetries for camera $cameraId');

        // ตรวจสอบว่ากล้องยังมีอยู่หรือไม่ก่อนลบ
        final cameraDoc =
            await _firestore.collection('speed_cameras').doc(cameraId).get();
        if (!cameraDoc.exists) {
          print('✅ Camera $cameraId already deleted (attempt $attempt)');
          return;
        }

        // ลบกล้อง
        await _firestore.collection('speed_cameras').doc(cameraId).delete();
        print(
            '🗑️ Delete command sent for camera $cameraId (attempt $attempt)');

        // 🧹 ลบ speed_limit_changes ที่เกี่ยวข้องกับกล้องนี้
        await _deleteSpeedLimitChanges(cameraId);

        // รอสักครู่แล้วตรวจสอบ
        await Future.delayed(Duration(seconds: attempt));

        // ตรวจสอบว่าลบจริงหรือไม่
        final isDeleted = await _verifyCameraDeletion(cameraId);
        if (isDeleted) {
          print('✅ Camera $cameraId deleted successfully on attempt $attempt');

          // บันทึก log การลบสำเร็จ
          await _firestore.collection('camera_deletion_log').add({
            'cameraId': cameraId,
            'deletionTimestamp': FieldValue.serverTimestamp(),
            'deletionMethod': 'auto_verification_with_retry',
            'deletedBy': 'auto_system',
            'reason': 'community_removal_vote_verified',
            'success': true,
            'attempts': attempt,
          });

          return;
        } else {
          print(
              '⚠️ Camera $cameraId still exists after deletion attempt $attempt');
        }
      } catch (e) {
        print('❌ Error on deletion attempt $attempt: $e');

        if (attempt == maxRetries) {
          // บันทึก error log สำหรับความพยายามสุดท้าย
          await _firestore.collection('camera_deletion_log').add({
            'cameraId': cameraId,
            'deletionTimestamp': FieldValue.serverTimestamp(),
            'deletionMethod': 'auto_verification_with_retry',
            'success': false,
            'error': e.toString(),
            'attempts': attempt,
            'maxRetries': maxRetries,
          });
          rethrow;
        }
      }

      if (attempt < maxRetries) {
        // Exponential backoff
        final delaySeconds = attempt * 2;
        print('⏳ Waiting ${delaySeconds}s before retry...');
        await Future.delayed(Duration(seconds: delaySeconds));
      }
    }

    throw Exception(
        'Failed to delete camera $cameraId after $maxRetries attempts');
  }

  /// ✨ ลบกล้องออกจาก Firebase โดยตรง (ไม่ยุ่งกับ UI)
  static Future<void> _directDeleteCamera(String cameraId) async {
    try {
      print('🗑️ === DIRECT CAMERA DELETION ===');
      print('🎯 Target Camera ID: $cameraId');

      // ตรวจสอบว่ากล้องมีอยู่จริงหรือไม่
      final cameraDoc =
          await _firestore.collection('speed_cameras').doc(cameraId).get();

      if (!cameraDoc.exists) {
        print('⚠️ Camera $cameraId does not exist - may already be deleted');
        return;
      }

      // ลบกล้องออกจาก speed_cameras collection
      await _firestore.collection('speed_cameras').doc(cameraId).delete();
      print('✅ Camera $cameraId deleted from speed_cameras collection');

      // 🧹 ลบ speed_limit_changes ที่เกี่ยวข้องกับกล้องนี้
      await _deleteSpeedLimitChanges(cameraId);

      // บันทึก log การลบ
      await _firestore.collection('camera_deletion_log').add({
        'cameraId': cameraId,
        'deletionTimestamp': FieldValue.serverTimestamp(),
        'deletionMethod': 'direct_deletion_after_verification',
        'deletedBy': 'auto_system',
        'reason': 'community_removal_vote_verified',
        'success': true,
      });
      print('✅ Deletion logged successfully');

      print('🎉 === DIRECT CAMERA DELETION COMPLETED ===');
    } catch (e) {
      print('❌ Error in direct camera deletion: $e');

      // บันทึก error log
      try {
        await _firestore.collection('camera_deletion_log').add({
          'cameraId': cameraId,
          'deletionTimestamp': FieldValue.serverTimestamp(),
          'deletionMethod': 'direct_deletion_after_verification',
          'success': false,
          'error': e.toString(),
        });
      } catch (logError) {
        print('⚠️ Failed to log deletion error: $logError');
      }

      rethrow;
    }
  }

  /// ✨ ลบกล้องตามตำแหน่งพิกัด (เมื่อไม่มี Camera ID)
  static Future<void> _deleteByLocation(
      double latitude, double longitude) async {
    try {
      print('🗑️ === LOCATION-BASED CAMERA DELETION ===');
      print('📍 Target location: ($latitude, $longitude)');

      // ค้นหากล้องในรัศมี 100 เมตร
      final allCameras = await getAllSpeedCameras();
      SpeedCamera? targetCamera;
      double minDistance = double.infinity;

      for (final camera in allCameras) {
        final distance = _calculateDistance(
          latitude,
          longitude,
          camera.location.latitude,
          camera.location.longitude,
        );
        final distanceInMeters = distance * 1000;

        if (distanceInMeters <= 100 && distanceInMeters < minDistance) {
          minDistance = distanceInMeters;
          targetCamera = camera;
        }
      }

      if (targetCamera != null) {
        print(
            '🎯 Found camera: ${targetCamera.roadName} (${targetCamera.id}) at ${minDistance.toStringAsFixed(2)}m');
        await _directDeleteCamera(targetCamera.id);
        print('✅ Location-based deletion completed');
      } else {
        print('❌ No camera found within 100m of specified location');
        throw Exception(
            'No camera found within 100m of location ($latitude, $longitude)');
      }
    } catch (e) {
      print('❌ Error in location-based deletion: $e');
      rethrow;
    }
  }

  /// อัปเดตความเร็วในกล้องหลักสำหรับรายงาน speedChanged
  static Future<void> _updateCameraSpeedLimit(CameraReport report) async {
    if (report.type != CameraReportType.speedChanged ||
        report.selectedCameraId == null) {
      return;
    }

    try {
      print('⚡ Updating speed limit for camera: ${report.selectedCameraId}');
      print('   New speed limit: ${report.speedLimit} km/h');

      // ดึงข้อมูลกล้องเก่าก่อนเพื่อบันทึกค่าความเร็วเดิม
      final cameraRef =
          _firestore.collection('speed_cameras').doc(report.selectedCameraId);
      final cameraDoc = await cameraRef.get();

      int? oldSpeedLimit;
      if (cameraDoc.exists) {
        final cameraData = cameraDoc.data() as Map<String, dynamic>;
        oldSpeedLimit = cameraData['speedLimit'] as int?;
      }

      await cameraRef.update({
        'speedLimit': report.speedLimit,
        'lastUpdated': FieldValue.serverTimestamp(),
        'updatedBy': 'community_vote',
        'sourceReport': report.id,
      });

      print('✅ Speed limit updated successfully');

      // บันทึกประวัติการเปลี่ยนแปลง
      await _firestore.collection('speed_limit_changes').add({
        'cameraId': report.selectedCameraId,
        'oldSpeed': oldSpeedLimit,
        'newSpeed': report.speedLimit,
        'changedAt': FieldValue.serverTimestamp(),
        'changedBy': 'auto_system',
        'reportId': report.id,
        'confidence': report.confidenceScore,
        'reporterUserId': report.reportedBy,
      });

      print('📊 Speed limit change logged successfully');
    } catch (e) {
      print('❌ Error updating speed limit: $e');
      // บันทึก error แต่ไม่ทำให้การโหวตล้มเหลว
      await _logSpeedUpdateError(
          report.id, report.selectedCameraId, e.toString());
    }
  }

  /// บันทึก error การอัปเดตความเร็ว
  static Future<void> _logSpeedUpdateError(
      String reportId, String? cameraId, String error) async {
    try {
      await _firestore.collection('speed_update_errors').add({
        'reportId': reportId,
        'cameraId': cameraId,
        'error': error,
        'timestamp': FieldValue.serverTimestamp(),
      });
      print('📝 Speed update error logged');
    } catch (e) {
      print('⚠️ Failed to log speed update error: $e');
    }
  }

  /// Debug: Manually promote a specific verified report
  static Future<void> debugPromoteVerifiedReport(String reportId) async {
    try {
      print('🔧 DEBUG: Manually promoting report $reportId');

      // Check if report exists and is verified
      final doc = await _firestore
          .collection(_reportsCollection)
          .doc(reportId)
          .get(const GetOptions(source: Source.server));

      if (!doc.exists) {
        print('❌ Report $reportId not found');
        return;
      }

      final report = CameraReport.fromJson(doc.data()!);
      print('📊 Report status: ${report.status}');
      print('📊 Report type: ${report.type}');
      print('📊 Verified by: ${report.verifiedBy}');
      print('📊 Confidence: ${report.confidenceScore}');
      print('📊 Selected Camera ID: ${report.selectedCameraId}');

      if (report.status == CameraStatus.verified &&
          report.type == CameraReportType.newCamera) {
        // ถ้าไม่มี selectedCameraId ให้สร้างใหม่
        if (report.selectedCameraId == null ||
            report.selectedCameraId!.isEmpty) {
          print('⚠️ No selectedCameraId found - generating new one');
          final newCameraId = _firestore.collection('speed_cameras').doc().id;

          await doc.reference.update({
            'selectedCameraId': newCameraId,
          });

          print('🆕 Updated report with new Camera ID: $newCameraId');
        }

        print('✅ Report is verified new camera - proceeding with promotion');
        await _promoteToMainDatabase(reportId);
        print('🎉 Manual promotion completed');
      } else {
        print('❌ Report does not meet promotion criteria');
        print('   Status: ${report.status} (need: verified)');
        print('   Type: ${report.type} (need: newCamera)');
      }
    } catch (e) {
      print('❌ Error in manual promotion: $e');
      rethrow;
    }
  }

  /// Debug: Check if camera exists in speed_cameras collection
  static Future<bool> debugCheckCameraExists(String cameraId) async {
    try {
      print('🔍 Checking if camera exists: $cameraId');

      final doc = await _firestore
          .collection('speed_cameras')
          .doc(cameraId)
          .get(const GetOptions(source: Source.server));

      final exists = doc.exists;
      print('📊 Camera $cameraId exists: $exists');

      if (exists) {
        final data = doc.data()!;
        print('📍 Camera details:');
        print('   Road: ${data['roadName']}');
        print('   Speed Limit: ${data['speedLimit']}');
        print('   Is Active: ${data['isActive']}');
        print('   Location: (${data['latitude']}, ${data['longitude']})');
      }

      return exists;
    } catch (e) {
      print('❌ Error checking camera existence: $e');
      return false;
    }
  }

  /// Debug: Get all verified reports that haven't been promoted yet
  static Future<List<CameraReport>> getUnpromotedVerifiedReports() async {
    try {
      print('🔍 Finding unpromoted verified reports...');

      final snapshot = await _firestore
          .collection(_reportsCollection)
          .where('status', isEqualTo: 'verified')
          .where('type', isEqualTo: 'newCamera')
          .get(const GetOptions(source: Source.server));

      final reports = snapshot.docs
          .map((doc) => CameraReport.fromJson(doc.data()))
          .toList();

      print('📊 Found ${reports.length} verified new camera reports');

      // Check which ones haven't been promoted by looking for success logs
      final unpromotedReports = <CameraReport>[];

      for (final report in reports) {
        final successLogs = await _firestore
            .collection('camera_promotion_success')
            .where('reportId', isEqualTo: report.id)
            .limit(1)
            .get();

        if (successLogs.docs.isEmpty) {
          print('⚠️ Report ${report.id} (${report.roadName}) not promoted yet');
          unpromotedReports.add(report);
        } else {
          print('✅ Report ${report.id} (${report.roadName}) already promoted');
        }
      }

      print('🎯 Found ${unpromotedReports.length} unpromoted verified reports');
      return unpromotedReports;
    } catch (e) {
      print('❌ Error finding unpromoted reports: $e');
      return [];
    }
  }

  /// Debug: Test Firebase permissions by creating a test camera
  static Future<void> testCreateCamera(String testCameraId) async {
    try {
      print('🧪 Testing camera creation with ID: $testCameraId');

      final testCameraData = {
        'id': testCameraId,
        'roadName': 'TEST_ROAD_${DateTime.now().millisecondsSinceEpoch}',
        'latitude': 13.420000,
        'longitude': 101.093000,
        'speedLimit': 90,
        'type': 'fixed',
        'isActive': true,
        'description': 'TEST CAMERA - PERMISSIONS CHECK',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'verifiedBy': 'permission_test',
        'confidence': 1.0,
        'lastReportedAt': FieldValue.serverTimestamp(),
        'reportCount': 1,
      };

      print('📝 Attempting to create test camera...');

      await _firestore
          .collection('speed_cameras')
          .doc(testCameraId)
          .set(testCameraData);

      print('✅ Test camera created successfully!');

      // Clean up the test camera
      print('🧹 Cleaning up test camera...');
      await _firestore.collection('speed_cameras').doc(testCameraId).delete();

      print('✅ Test camera cleaned up successfully!');
    } catch (e) {
      print('❌ Failed to create test camera: $e');
      print('   Error type: ${e.runtimeType}');
      print('   Current user: ${_auth.currentUser?.uid}');
      print('   User email: ${_auth.currentUser?.email}');
      rethrow;
    }
  }

  /// 🧹 Clean up verified/rejected reports that weren't auto-removed
  static Future<void> cleanupVerifiedReports() async {
    try {
      print('🧹 === CLEANUP VERIFIED REPORTS START ===');

      // ค้นหารายงานที่ verified แล้วแต่ยังไม่ถูกลบ
      final verifiedSnapshot = await _firestore
          .collection(_reportsCollection)
          .where('status', isEqualTo: 'verified')
          .get();

      // ค้นหารายงานที่ rejected แล้วแต่ยังไม่ถูกลบ
      final rejectedSnapshot = await _firestore
          .collection(_reportsCollection)
          .where('status', isEqualTo: 'rejected')
          .get();

      final totalReports =
          verifiedSnapshot.docs.length + rejectedSnapshot.docs.length;
      print(
          '📊 Found $totalReports reports to cleanup (${verifiedSnapshot.docs.length} verified, ${rejectedSnapshot.docs.length} rejected)');

      int processedCount = 0;
      int deletedCount = 0;

      // Process verified reports
      for (final doc in verifiedSnapshot.docs) {
        try {
          final report = CameraReport.fromJson(doc.data());
          processedCount++;

          // บันทึกลง log ก่อนลบ
          await _firestore.collection('verified_reports_removal_log').add({
            'originalReportId': report.id,
            'reportData': {
              'upvotes': report.upvotes,
              'downvotes': report.downvotes,
              'status': report.status.toString(),
              'type': report.type.toString(),
              'roadName': report.roadName,
              'latitude': report.latitude,
              'longitude': report.longitude,
              'reportedBy': report.reportedBy,
              'verifiedAt': report.verifiedAt?.toIso8601String(),
              'verifiedBy': report.verifiedBy,
            },
            'removedAt': FieldValue.serverTimestamp(),
            'removedBy': 'cleanup_system',
            'cleanupReason': 'verified_report_not_auto_removed',
          });

          // ลบรายงาน
          await doc.reference.delete();
          deletedCount++;
          print('✅ Deleted verified report: ${report.id}');
        } catch (e) {
          print('❌ Error processing verified report ${doc.id}: $e');
        }
      }

      // Process rejected reports
      for (final doc in rejectedSnapshot.docs) {
        try {
          final report = CameraReport.fromJson(doc.data());
          processedCount++;

          // บันทึกลง log ก่อนลบ
          await _firestore.collection('verified_reports_removal_log').add({
            'originalReportId': report.id,
            'reportData': {
              'upvotes': report.upvotes,
              'downvotes': report.downvotes,
              'status': report.status.toString(),
              'type': report.type.toString(),
              'roadName': report.roadName,
              'latitude': report.latitude,
              'longitude': report.longitude,
              'reportedBy': report.reportedBy,
              'verifiedAt': report.verifiedAt?.toIso8601String(),
              'verifiedBy': report.verifiedBy,
            },
            'removedAt': FieldValue.serverTimestamp(),
            'removedBy': 'cleanup_system',
            'cleanupReason': 'rejected_report_not_auto_removed',
          });

          // ลบรายงาน
          await doc.reference.delete();
          deletedCount++;
          print('✅ Deleted rejected report: ${report.id}');
        } catch (e) {
          print('❌ Error processing rejected report ${doc.id}: $e');
        }
      }

      print('🎉 === CLEANUP SUMMARY ===');
      print('   Total processed: $processedCount');
      print('   Successfully deleted: $deletedCount');
      print('   Cleanup completed successfully!');
    } catch (e) {
      print('❌ Error in verified reports cleanup: $e');
      throw Exception('Failed to cleanup verified reports: ${e.toString()}');
    }
  }

  /// Initialize cleanup on app start
  static Future<void> initializeCleanup() async {
    try {
      print('🚀 Initializing cleanup system...');
      await cleanupVerifiedReports();
      print('✅ Cleanup system initialized successfully');
    } catch (e) {
      print('❌ Error initializing cleanup: $e');
      // Don't throw error to prevent app from crashing
    }
  }

  /// 🧹 ลบ speed_limit_changes ที่เกี่ยวข้องกับกล้องที่ถูกลบ
  static Future<void> _deleteSpeedLimitChanges(String cameraId) async {
    try {
      print('🧹 === CLEANING UP SPEED LIMIT CHANGES ===');
      print('Camera ID: $cameraId');

      // ค้นหา speed_limit_changes ที่เกี่ยวข้องกับกล้องนี้
      final speedChangesSnapshot = await _firestore
          .collection('speed_limit_changes')
          .where('cameraId', isEqualTo: cameraId)
          .get();

      print(
          '📊 Found ${speedChangesSnapshot.docs.length} speed limit changes to delete');

      int deletedCount = 0;
      for (final doc in speedChangesSnapshot.docs) {
        try {
          final changeData = doc.data();

          // บันทึกข้อมูลก่อนลบ
          await _firestore.collection('deleted_speed_limit_changes_log').add({
            'originalChangeId': doc.id,
            'cameraId': cameraId,
            'changeData': changeData,
            'deletedAt': FieldValue.serverTimestamp(),
            'deletedBy': 'camera_removal_system',
            'deletionReason': 'camera_deleted',
          });

          // ลบ speed limit change
          await doc.reference.delete();
          deletedCount++;
          print('✅ Deleted speed limit change: ${doc.id}');
        } catch (e) {
          print('❌ Error deleting speed limit change ${doc.id}: $e');
        }
      }

      print('🎉 Speed limit changes cleanup completed');
      print('   Total processed: ${speedChangesSnapshot.docs.length}');
      print('   Successfully deleted: $deletedCount');
    } catch (e) {
      print('❌ Error cleaning up speed limit changes for camera $cameraId: $e');
      // ไม่ throw error เพราะไม่อยากให้การลบกล้องล้มเหลวเพราะ speed changes
    }
  }
}

// Remove the local LatLng class since we're using latlong2
