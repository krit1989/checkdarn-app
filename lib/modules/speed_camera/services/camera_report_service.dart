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

    // Update user stats
    await _updateUserStats(user.uid, 'reports_submitted');

    return reportId;
  }

  /// Submit a vote for a camera report
  static Future<void> submitVote({
    required String reportId,
    required VoteType voteType,
    String? comment,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Check if user has already voted
    final existingVote = await _firestore
        .collection(_votesCollection)
        .where('reportId', isEqualTo: reportId)
        .where('userId', isEqualTo: user.uid)
        .get();

    if (existingVote.docs.isNotEmpty) {
      throw Exception('คุณได้โหวตรายงานนี้แล้ว');
    }

    final voteId = _firestore.collection(_votesCollection).doc().id;
    final vote = CameraVote(
      id: voteId,
      reportId: reportId,
      userId: user.uid,
      voteType: voteType,
      votedAt: DateTime.now(),
      comment: comment,
    );

    // Submit vote and update report stats in transaction
    await _firestore.runTransaction((transaction) async {
      final reportRef = _firestore.collection(_reportsCollection).doc(reportId);
      final reportDoc = await transaction.get(reportRef);

      if (!reportDoc.exists) {
        throw Exception('Report not found');
      }

      final report = CameraReport.fromJson(reportDoc.data()!);

      // Update vote counts
      final newUpvotes =
          voteType == VoteType.upvote ? report.upvotes + 1 : report.upvotes;
      final newDownvotes = voteType == VoteType.downvote
          ? report.downvotes + 1
          : report.downvotes;
      final newTotalVotes = newUpvotes + newDownvotes;
      final newConfidenceScore =
          newTotalVotes > 0 ? newUpvotes / newTotalVotes : 0.0;

      // Auto-verify if confidence is high enough
      CameraStatus newStatus = report.status;
      DateTime? verifiedAt;
      String? verifiedBy;

      if (newTotalVotes >= 5) {
        if (newConfidenceScore >= 0.8) {
          newStatus = CameraStatus.verified;
          verifiedAt = DateTime.now();
          verifiedBy = 'auto_system';
        } else if (newConfidenceScore <= 0.2) {
          newStatus = CameraStatus.rejected;
          verifiedAt = DateTime.now();
          verifiedBy = 'auto_system';
        }
      }

      // Update report
      transaction.update(reportRef, {
        'upvotes': newUpvotes,
        'downvotes': newDownvotes,
        'confidenceScore': newConfidenceScore,
        'status': newStatus.toString().split('.').last,
        if (verifiedAt != null) 'verifiedAt': verifiedAt.toIso8601String(),
        if (verifiedBy != null) 'verifiedBy': verifiedBy,
      });

      // Add vote
      final voteRef = _firestore.collection(_votesCollection).doc(voteId);
      transaction.set(voteRef, vote.toJson());
    });

    // Update user stats
    await _updateUserStats(user.uid, 'votes_submitted');

    // If auto-verified, potentially add to main speed camera database
    if (await _isReportAutoVerified(reportId)) {
      await _promoteToMainDatabase(reportId);
    }
  }

  /// Get pending reports that need votes
  static Future<List<CameraReport>> getPendingReports({
    double? userLat,
    double? userLng,
    double radiusKm = 10.0,
    int limit = 20,
  }) async {
    Query query = _firestore
        .collection(_reportsCollection)
        .where('status', isEqualTo: 'pending')
        .orderBy('reportedAt', descending: true)
        .limit(limit);

    final snapshot = await query.get();
    final reports = snapshot.docs
        .map((doc) => CameraReport.fromJson(doc.data() as Map<String, dynamic>))
        .toList();

    // Filter by distance if user location provided
    if (userLat != null && userLng != null) {
      reports.removeWhere((report) {
        final distance = _calculateDistance(
            userLat, userLng, report.latitude, report.longitude);
        return distance > radiusKm;
      });
    }

    return reports;
  }

  /// Get user's voting history
  static Future<List<String>> getUserVotedReports() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final snapshot = await _firestore
        .collection(_votesCollection)
        .where('userId', isEqualTo: user.uid)
        .get();

    return snapshot.docs.map((doc) => doc['reportId'] as String).toList();
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
  static Future<List<CameraReport>> getReportsByStatus(
      CameraStatus status) async {
    final snapshot = await _firestore
        .collection(_reportsCollection)
        .where('status', isEqualTo: status.toString().split('.').last)
        .orderBy('reportedAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => CameraReport.fromJson(doc.data()))
        .toList();
  }

  /// Delete a report (admin function)
  static Future<void> deleteReport(String reportId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Check if user is admin or the original reporter
    final reportDoc =
        await _firestore.collection(_reportsCollection).doc(reportId).get();
    if (!reportDoc.exists) throw Exception('Report not found');

    final report = CameraReport.fromJson(reportDoc.data()!);

    // Allow deletion if user is the original reporter and report is still pending
    if (report.reportedBy == user.uid &&
        report.status == CameraStatus.pending) {
      await _firestore.collection(_reportsCollection).doc(reportId).delete();

      // Also delete associated votes
      final votes = await _firestore
          .collection(_votesCollection)
          .where('reportId', isEqualTo: reportId)
          .get();

      for (final vote in votes.docs) {
        await vote.reference.delete();
      }
    } else {
      throw Exception('ไม่สามารถลบรายงานนี้ได้');
    }
  }
}

// Remove the local LatLng class since we're using latlong2
