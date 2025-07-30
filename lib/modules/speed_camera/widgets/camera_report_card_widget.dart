import 'package:flutter/material.dart';
import '../models/camera_report_model.dart';
import '../services/camera_report_service.dart';
import '../../../services/auth_service.dart';
import 'package:intl/intl.dart';

class CameraReportCardWidget extends StatelessWidget {
  final CameraReport report;
  final bool hasVoted;
  final Function(VoteType) onVoteSubmitted;
  final VoidCallback? onReportDeleted;

  const CameraReportCardWidget({
    super.key,
    required this.report,
    required this.hasVoted,
    required this.onVoteSubmitted,
    this.onReportDeleted,
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
                      fontFamily: 'NotoSansThai',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _getTypeColor(report.type),
                    ),
                  ),
                ),
                const Spacer(),

                // Delete button for owner
                if (_canDeleteReport()) ...[
                  IconButton(
                    onPressed: () => _showDeleteDialog(context),
                    icon: const Icon(Icons.delete_outline),
                    iconSize: 20,
                    color: Colors.red.shade400,
                    tooltip: 'ลบรายงาน',
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 4),
                ],

                Text(
                  _formatDateTime(report.reportedAt),
                  style: TextStyle(
                    fontFamily: 'NotoSansThai',
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
                fontFamily: 'NotoSansThai',
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'ละติจูด: ${report.latitude.toStringAsFixed(6)}, '
              'ลองจิจูด: ${report.longitude.toStringAsFixed(6)}',
              style: TextStyle(
                fontFamily: 'NotoSansThai',
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
                      fontFamily: 'NotoSansThai',
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
                    fontFamily: 'NotoSansThai',
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
                    fontFamily: 'NotoSansThai',
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
                    fontFamily: 'NotoSansThai',
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
                      fontFamily: 'NotoSansThai',
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
                        style: TextStyle(fontFamily: 'NotoSansThai'),
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
                        style: TextStyle(fontFamily: 'NotoSansThai'),
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
                        fontFamily: 'NotoSansThai',
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
                        fontFamily: 'NotoSansThai',
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

  // ตรวจสอบว่าสามารถลบรายงานได้หรือไม่
  bool _canDeleteReport() {
    final currentUser = AuthService.currentUser;
    return currentUser != null &&
        currentUser.uid == report.reportedBy &&
        report.status == CameraStatus.pending;
  }

  // แสดง dialog ยืนยันการลบ
  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            'ยืนยันการลบ',
            style: TextStyle(fontFamily: 'NotoSansThai', fontWeight: FontWeight.w600),
          ),
          content: const Text(
            'คุณต้องการลบรายงานนี้ใช่หรือไม่?\n\nเมื่อลบแล้วจะไม่สามารถกู้คืนได้',
            style: TextStyle(fontFamily: 'NotoSansThai'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'ยกเลิก',
                style: TextStyle(fontFamily: 'NotoSansThai'),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteReport(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'ลบ',
                style: TextStyle(fontFamily: 'NotoSansThai'),
              ),
            ),
          ],
        );
      },
    );
  }

  // ลบรายงาน
  Future<void> _deleteReport(BuildContext context) async {
    // เก็บ reference ของ ScaffoldMessenger ไว้ก่อนเพื่อป้องกัน error
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      // แสดงข้อความแจ้งเตือนแทน loading dialog
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text(
                'กำลังลบรายงาน...',
                style: TextStyle(fontFamily: 'NotoSansThai'),
              ),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 10), // ให้เวลาพอสำหรับการลบ
        ),
      );

      // ลบรายงาน
      await CameraReportService.deleteReport(report.id);

      // ซ่อน snackbar ที่แสดงอยู่
      scaffoldMessenger.hideCurrentSnackBar();

      // แสดงข้อความสำเร็จ
      if (context.mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text(
              'ลบรายงานเรียบร้อยแล้ว 🎉 กำลังอัปเดตหน้าจอ...',
              style: TextStyle(fontFamily: 'NotoSansThai'),
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );

        // เรียก callback ทันทีพร้อม report ID เพื่อลบออกจาก UI
        onReportDeleted?.call();

        // เรียก callback หลายครั้งเพื่อให้แน่ใจ
        Future.delayed(const Duration(milliseconds: 100), () {
          if (context.mounted) {
            onReportDeleted?.call();
          }
        });

        Future.delayed(const Duration(milliseconds: 300), () {
          if (context.mounted) {
            onReportDeleted?.call();
          }
        });
      }
    } catch (e) {
      // ซ่อน loading snackbar
      scaffoldMessenger.hideCurrentSnackBar();

      String errorMessage = 'เกิดข้อผิดพลาด: $e';
      if (e.toString().contains('TimeoutException')) {
        errorMessage = 'การลบใช้เวลานานเกินไป กรุณาลองใหม่';
      }

      // แสดงข้อความผิดพลาด
      if (context.mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              errorMessage,
              style: const TextStyle(fontFamily: 'NotoSansThai'),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
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
