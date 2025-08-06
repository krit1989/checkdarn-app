class CameraReport {
  final String id;
  final double latitude;
  final double longitude;
  final String roadName;
  final int speedLimit;
  final String reportedBy; // User ID
  final DateTime reportedAt;
  final CameraReportType type;
  final String? description;
  final String? imageUrl;
  final List<String> tags; // ['new', 'moved', 'removed', 'speed_changed']
  final String? selectedCameraId; // ID ของกล้องที่เลือกจากแผนที่

  // Verification data
  final int upvotes;
  final int downvotes;
  final double confidenceScore; // 0.0 - 1.0
  final CameraStatus status;
  final DateTime? verifiedAt;
  final String? verifiedBy; // Admin/Moderator ID

  const CameraReport({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.roadName,
    required this.speedLimit,
    required this.reportedBy,
    required this.reportedAt,
    required this.type,
    this.description,
    this.imageUrl,
    this.tags = const [],
    this.selectedCameraId, // เพิ่ม
    this.upvotes = 0,
    this.downvotes = 0,
    this.confidenceScore = 0.0,
    this.status = CameraStatus.pending,
    this.verifiedAt,
    this.verifiedBy,
  });

  factory CameraReport.fromJson(Map<String, dynamic> json) {
    return CameraReport(
      id: json['id'],
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      roadName: json['roadName'] ?? '',
      speedLimit: json['speedLimit'] ?? 90,
      reportedBy: json['reportedBy'],
      reportedAt: DateTime.parse(json['reportedAt']),
      type: CameraReportType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => CameraReportType.newCamera,
      ),
      description: json['description'],
      imageUrl: json['imageUrl'],
      tags: List<String>.from(json['tags'] ?? []),
      selectedCameraId: json['selectedCameraId'], // เพิ่ม
      upvotes: json['upvotes'] ?? 0,
      downvotes: json['downvotes'] ?? 0,
      confidenceScore: (json['confidenceScore'] ?? 0.0).toDouble(),
      status: CameraStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => CameraStatus.pending,
      ),
      verifiedAt: json['verifiedAt'] != null
          ? DateTime.parse(json['verifiedAt'])
          : null,
      verifiedBy: json['verifiedBy'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'roadName': roadName,
      'speedLimit': speedLimit,
      'reportedBy': reportedBy,
      'reportedAt': reportedAt.toIso8601String(),
      'type': type.toString().split('.').last,
      'description': description,
      'imageUrl': imageUrl,
      'tags': tags,
      'selectedCameraId': selectedCameraId, // เพิ่ม
      'upvotes': upvotes,
      'downvotes': downvotes,
      'confidenceScore': confidenceScore,
      'status': status.toString().split('.').last,
      'verifiedAt': verifiedAt?.toIso8601String(),
      'verifiedBy': verifiedBy,
    };
  }

  // Helper methods
  bool get isVerified => status == CameraStatus.verified;
  bool get isPending => status == CameraStatus.pending;
  bool get isRejected => status == CameraStatus.rejected;

  int get totalVotes => upvotes + downvotes;
  double get approvalRatio => totalVotes > 0 ? upvotes / totalVotes : 0.0;

  // 🆕 NEW VOTING SYSTEM: Race-to-3 logic
  bool get hasUpvoteWin => upvotes >= 3 && upvotes > downvotes;
  bool get hasDownvoteWin => downvotes >= 3 && downvotes > upvotes;
  bool get hasTieAt3 => upvotes == 3 && downvotes == 3;
  bool get isDecisive => hasUpvoteWin || hasDownvoteWin || hasTieAt3;

  bool get isHighConfidence =>
      confidenceScore >= 0.5 && isDecisive; // Updated for new system
  bool get needsMoreVotes => !isDecisive; // Changed from < 3 to !isDecisive

  // เพิ่มเมธอดตรวจสอบว่ากล้องนี้มี ID หรือยัง
  bool get hasCameraId =>
      selectedCameraId != null && selectedCameraId!.isNotEmpty;

  // เพิ่มเมธอดตรวจสอบว่ากล้องนี้พร้อมแสดงในแผนที่หรือไม่
  bool get shouldShowInMap {
    return (type == CameraReportType.newCamera && hasCameraId) ||
        (type == CameraReportType.speedChanged && hasCameraId);
  }

  // เพิ่มเมธอดตรวจสอบว่าต้องการอัปเดตความเร็วหรือไม่
  bool get needsSpeedUpdate =>
      type == CameraReportType.speedChanged &&
      isVerified &&
      selectedCameraId != null;
}

enum CameraReportType {
  newCamera, // รายงานกล้องใหม่
  removedCamera, // รายงานกล้องที่ถูกถอด
  speedChanged, // รายงานการเปลี่ยนจำกัดความเร็ว
}

enum CameraStatus {
  pending, // รอการตรวจสอบ
  verified, // ยืนยันแล้ว
  rejected, // ปฏิเสธ
  duplicate, // ข้อมูลซ้ำ
}

class CameraVote {
  final String id;
  final String reportId;
  final String userId;
  final VoteType voteType;
  final DateTime votedAt;
  final String? comment;

  const CameraVote({
    required this.id,
    required this.reportId,
    required this.userId,
    required this.voteType,
    required this.votedAt,
    this.comment,
  });

  factory CameraVote.fromJson(Map<String, dynamic> json) {
    return CameraVote(
      id: json['id'],
      reportId: json['reportId'],
      userId: json['userId'],
      voteType: VoteType.values.firstWhere(
        (e) => e.toString().split('.').last == json['voteType'],
      ),
      votedAt: DateTime.parse(json['votedAt']),
      comment: json['comment'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reportId': reportId,
      'userId': userId,
      'voteType': voteType.toString().split('.').last,
      'votedAt': votedAt.toIso8601String(),
      'comment': comment,
    };
  }
}

enum VoteType {
  upvote, // โหวตเห็นด้วย (มีจริง)
  downvote, // โหวตไม่เห็นด้วย (ไม่มี/ผิด)
}
