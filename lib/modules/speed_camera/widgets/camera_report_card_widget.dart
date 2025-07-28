import 'package:flutter/material.dart';
import '../models/camera_report_model.dart';
import 'package:intl/intl.dart';

class CameraReportCardWidget extends StatelessWidget {
  final CameraReport report;
  final bool hasVoted;
  final Function(VoteType) onVoteSubmitted;

  const CameraReportCardWidget({
    super.key,
    required this.report,
    required this.hasVoted,
    required this.onVoteSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with type and time
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getTypeColor(report.type).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _getTypeDisplayName(report.type),
                    style: TextStyle(
                      fontFamily: 'Kanit',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _getTypeColor(report.type),
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDateTime(report.reportedAt),
                  style: TextStyle(
                    fontFamily: 'Kanit',
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Road name and location
            Text(
              report.roadName,
              style: const TextStyle(
                fontFamily: 'Kanit',
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'ละติจูด: ${report.latitude.toStringAsFixed(6)}, '
              'ลองจิจูด: ${report.longitude.toStringAsFixed(6)}',
              style: TextStyle(
                fontFamily: 'Kanit',
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),

            // Speed limit (if applicable)
            if (report.type == CameraReportType.newCamera ||
                report.type == CameraReportType.speedChanged) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.speed,
                    size: 16,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'จำกัดความเร็ว: ${report.speedLimit} km/h',
                    style: const TextStyle(
                      fontFamily: 'Kanit',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],

            // Description (if available)
            if (report.description != null &&
                report.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  report.description!,
                  style: const TextStyle(
                    fontFamily: 'Kanit',
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Voting stats
            Row(
              children: [
                Icon(
                  Icons.thumb_up,
                  size: 16,
                  color: Colors.green,
                ),
                const SizedBox(width: 4),
                Text(
                  '${report.upvotes}',
                  style: const TextStyle(
                    fontFamily: 'Kanit',
                    fontWeight: FontWeight.w500,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.thumb_down,
                  size: 16,
                  color: Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  '${report.downvotes}',
                  style: const TextStyle(
                    fontFamily: 'Kanit',
                    fontWeight: FontWeight.w500,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(width: 16),
                // Confidence indicator
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getConfidenceColor(report.confidenceScore)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'ความมั่นใจ: ${(report.confidenceScore * 100).toInt()}%',
                    style: TextStyle(
                      fontFamily: 'Kanit',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: _getConfidenceColor(report.confidenceScore),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Voting buttons
            if (!hasVoted && report.status == CameraStatus.pending) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => onVoteSubmitted(VoteType.upvote),
                      icon: const Icon(Icons.thumb_up, size: 18),
                      label: const Text(
                        'มีจริง',
                        style: TextStyle(fontFamily: 'Kanit'),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => onVoteSubmitted(VoteType.downvote),
                      icon: const Icon(Icons.thumb_down, size: 18),
                      label: const Text(
                        'ไม่มี',
                        style: TextStyle(fontFamily: 'Kanit'),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (hasVoted) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.blue,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'คุณได้โหวตแล้ว',
                      style: TextStyle(
                        fontFamily: 'Kanit',
                        fontWeight: FontWeight.w500,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (report.status != CameraStatus.pending) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getStatusColor(report.status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getStatusIcon(report.status),
                      color: _getStatusColor(report.status),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getStatusDisplayName(report.status),
                      style: TextStyle(
                        fontFamily: 'Kanit',
                        fontWeight: FontWeight.w500,
                        color: _getStatusColor(report.status),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getTypeDisplayName(CameraReportType type) {
    switch (type) {
      case CameraReportType.newCamera:
        return '📷 กล้องใหม่';
      case CameraReportType.removedCamera:
        return '❌ กล้องถูกถอด';
      case CameraReportType.movedCamera:
        return '📍 กล้องย้ายที่';
      case CameraReportType.speedChanged:
        return '⚡ เปลี่ยนความเร็ว';
      case CameraReportType.verification:
        return '✅ ยืนยันกล้อง';
    }
  }

  Color _getTypeColor(CameraReportType type) {
    switch (type) {
      case CameraReportType.newCamera:
        return Colors.green;
      case CameraReportType.removedCamera:
        return Colors.red;
      case CameraReportType.movedCamera:
        return Colors.orange;
      case CameraReportType.speedChanged:
        return Colors.purple;
      case CameraReportType.verification:
        return Colors.blue;
    }
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
  }

  Color _getStatusColor(CameraStatus status) {
    switch (status) {
      case CameraStatus.pending:
        return Colors.orange;
      case CameraStatus.verified:
        return Colors.green;
      case CameraStatus.rejected:
        return Colors.red;
      case CameraStatus.duplicate:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(CameraStatus status) {
    switch (status) {
      case CameraStatus.pending:
        return Icons.schedule;
      case CameraStatus.verified:
        return Icons.check_circle;
      case CameraStatus.rejected:
        return Icons.cancel;
      case CameraStatus.duplicate:
        return Icons.content_copy;
    }
  }

  String _getStatusDisplayName(CameraStatus status) {
    switch (status) {
      case CameraStatus.pending:
        return 'รอการตรวจสอบ';
      case CameraStatus.verified:
        return 'ยืนยันแล้ว';
      case CameraStatus.rejected:
        return 'ถูกปฏิเสธ';
      case CameraStatus.duplicate:
        return 'ข้อมูลซ้ำ';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'เมื่อสักครู่';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} นาทีที่แล้ว';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} ชั่วโมงที่แล้ว';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} วันที่แล้ว';
    } else {
      return DateFormat('dd/MM/yyyy').format(dateTime);
    }
  }
}
