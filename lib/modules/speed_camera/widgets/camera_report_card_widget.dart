import 'package:flutter/material.dart';
import '../models/camera_report_model.dart';
import '../services/camera_report_service.dart';
import '../../../services/auth_service.dart';
import '../../../widgets/location_picker_screen.dart';
import 'single_camera_map_screen.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;
import '../../../generated/gen_l10n/app_localizations.dart';

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

  // ฟังก์ชันสร้างชื่อแบบ masked สำหรับการแสดงผล
  String _getMaskedPosterName(BuildContext context) {
    final currentUser = AuthService.currentUser;

    // ถ้าเป็นผู้ใช้ปัจจุบัน
    if (currentUser != null && currentUser.uid == report.reportedBy) {
      return AppLocalizations.of(context).myReport;
    }

    // สำหรับคนอื่น ไม่แสดงชื่อเลย เพื่อความเป็นส่วนตัว
    return AppLocalizations.of(context).communityMember;
  }

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
                    _getTypeDisplayName(report.type, context),
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
                    tooltip: AppLocalizations.of(context).deleteReport,
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 4),
                ],

                Text(
                  _formatDateTime(report.reportedAt, context),
                  style: TextStyle(
                    fontFamily: 'NotoSansThai',
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Road name
            Text(
              report.roadName,
              style: const TextStyle(
                fontFamily: 'NotoSansThai',
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),

            // Description (if available) - รายละเอียดที่ตั้งและจุดสังเกต
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
                    AppLocalizations.of(context)
                        .speedLimitDisplay(report.speedLimit),
                    style: const TextStyle(
                      fontFamily: 'NotoSansThai',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],

            // View map button - แบบง่าย เฉพาะข้อความ
            const SizedBox(height: 8),
            InkWell(
              onTap: () {
                // เช็คว่าเป็นรายงานที่เกี่ยวข้องกับกล้องที่มีอยู่หรือไม่
                if ((report.type == CameraReportType.removedCamera ||
                        report.type == CameraReportType.speedChanged) &&
                    report.selectedCameraId != null) {
                  // แสดงแผนที่กล้องตัวเดียว
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SingleCameraMapScreen(
                        cameraId: report.selectedCameraId!,
                        title: AppLocalizations.of(context).viewMapButton,
                        fallbackLocation:
                            LatLng(report.latitude, report.longitude),
                      ),
                    ),
                  );
                } else {
                  // แสดงแผนที่แบบธรรมดา (สำหรับรายงานกล้องใหม่)
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LocationPickerScreen(
                        initialLocation:
                            LatLng(report.latitude, report.longitude),
                        title: AppLocalizations.of(context)
                            .viewLocationTitle(report.roadName),
                      ),
                    ),
                  );
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Row(
                  children: [
                    const Text(
                      '🗺️',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      // แสดงข้อความที่เหมาะสมกับประเภทรายงาน
                      (report.type == CameraReportType.removedCamera ||
                                  report.type ==
                                      CameraReportType.speedChanged) &&
                              report.selectedCameraId != null
                          ? AppLocalizations.of(context).viewCameraOnMap
                          : AppLocalizations.of(context).viewMapButton,
                      style: const TextStyle(
                        fontFamily: 'NotoSansThai',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1158F2),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: const Color(0xFF1158F2),
                      size: 14,
                    ),
                  ],
                ),
              ),
            ),

            // Poster information
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  '👤',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 4),
                Text(
                  _getMaskedPosterName(context),
                  style: TextStyle(
                    fontFamily: 'NotoSansThai',
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Voting stats with new race-to-3 system
            Row(
              children: [
                // Upvotes
                Icon(
                  Icons.thumb_up,
                  size: 16,
                  color: report.hasUpvoteWin
                      ? Colors.green.shade700
                      : Colors.green,
                ),
                const SizedBox(width: 4),
                Text(
                  '${report.upvotes}',
                  style: TextStyle(
                    fontFamily: 'NotoSansThai',
                    fontWeight:
                        report.hasUpvoteWin ? FontWeight.bold : FontWeight.w500,
                    color: report.hasUpvoteWin
                        ? Colors.green.shade700
                        : Colors.green,
                  ),
                ),
                if (report.hasUpvoteWin) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      AppLocalizations.of(context).win,
                      style: TextStyle(
                        fontFamily: 'NotoSansThai',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 16),

                // Downvotes
                Icon(
                  Icons.thumb_down,
                  size: 16,
                  color:
                      report.hasDownvoteWin ? Colors.red.shade700 : Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  '${report.downvotes}',
                  style: TextStyle(
                    fontFamily: 'NotoSansThai',
                    fontWeight: report.hasDownvoteWin
                        ? FontWeight.bold
                        : FontWeight.w500,
                    color: report.hasDownvoteWin
                        ? Colors.red.shade700
                        : Colors.red,
                  ),
                ),
                if (report.hasDownvoteWin) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      AppLocalizations.of(context).win,
                      style: TextStyle(
                        fontFamily: 'NotoSansThai',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                ],

                const Spacer(),

                // Status indicator for new system
                if (report.hasTieAt3) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      AppLocalizations.of(context).tied,
                      style: TextStyle(
                        fontFamily: 'NotoSansThai',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.amber.shade700,
                      ),
                    ),
                  ),
                ] else if (report.needsMoreVotes) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      AppLocalizations.of(context).needsMoreVotes(
                          3 - math.max(report.upvotes, report.downvotes)),
                      style: TextStyle(
                        fontFamily: 'NotoSansThai',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 16),

            // Voting buttons
            if (!hasVoted &&
                !_isReportOwner() &&
                report.status == CameraStatus.pending) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => onVoteSubmitted(VoteType.upvote),
                      icon: const Icon(Icons.thumb_up, size: 18),
                      label: Text(
                        _getUpvoteButtonText(context),
                        style: const TextStyle(fontFamily: 'NotoSansThai'),
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
                      label: Text(
                        _getDownvoteButtonText(context),
                        style: const TextStyle(fontFamily: 'NotoSansThai'),
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
            ] else if (_isReportOwner() &&
                report.status == CameraStatus.pending) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.person,
                      color: Colors.amber.shade700,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context).yourReportPending,
                      style: const TextStyle(
                        fontFamily: 'NotoSansThai',
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
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
                    Text(
                      AppLocalizations.of(context).alreadyVotedStatus,
                      style: const TextStyle(
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
                      _getStatusDisplayName(report.status, context),
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

  // ตรวจสอบว่าเป็นเจ้าของรายงานหรือไม่
  bool _isReportOwner() {
    final currentUser = AuthService.currentUser;
    return currentUser != null && currentUser.uid == report.reportedBy;
  }

  // เลือกข้อความปุ่มโหวตที่เหมาะสมกับประเภทการรายงาน
  String _getUpvoteButtonText(BuildContext context) {
    switch (report.type) {
      case CameraReportType.newCamera:
        return AppLocalizations.of(context).exists;
      case CameraReportType.removedCamera:
      case CameraReportType.speedChanged:
        return AppLocalizations.of(context).trueVote;
    }
  }

  String _getDownvoteButtonText(BuildContext context) {
    switch (report.type) {
      case CameraReportType.newCamera:
        return AppLocalizations.of(context).doesNotExist;
      case CameraReportType.removedCamera:
      case CameraReportType.speedChanged:
        return AppLocalizations.of(context).falseVote;
    }
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
          title: Text(
            AppLocalizations.of(context).confirmDeletion,
            style: const TextStyle(
                fontFamily: 'NotoSansThai', fontWeight: FontWeight.w600),
          ),
          content: Text(
            AppLocalizations.of(context).deleteConfirmMessage,
            style: const TextStyle(fontFamily: 'NotoSansThai'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                AppLocalizations.of(context).cancel,
                style: const TextStyle(fontFamily: 'NotoSansThai'),
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
              child: Text(
                AppLocalizations.of(context).delete,
                style: const TextStyle(fontFamily: 'NotoSansThai'),
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
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context).deletingReport,
                style: const TextStyle(fontFamily: 'NotoSansThai'),
              ),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 10), // ให้เวลาพอสำหรับการลบ
        ),
      );

      // ลบรายงาน
      await CameraReportService.deleteReport(report.id);

      // ซ่อน snackbar ที่แสดงอยู่
      scaffoldMessenger.hideCurrentSnackBar();

      // แสดงข้อความสำเร็จ
      if (context.mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).reportDeletedSuccess,
              style: const TextStyle(fontFamily: 'NotoSansThai'),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
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

      String errorMessage =
          AppLocalizations.of(context).errorOccurred(e.toString());
      if (e.toString().contains('TimeoutException')) {
        errorMessage = AppLocalizations.of(context).deleteTimeoutError;
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

  String _getTypeDisplayName(CameraReportType type, BuildContext context) {
    switch (type) {
      case CameraReportType.newCamera:
        return AppLocalizations.of(context).newCameraType;
      case CameraReportType.removedCamera:
        return AppLocalizations.of(context).removedCameraType;
      case CameraReportType.speedChanged:
        return AppLocalizations.of(context).speedChangedType;
    }
  }

  Color _getTypeColor(CameraReportType type) {
    switch (type) {
      case CameraReportType.newCamera:
        return Colors.green;
      case CameraReportType.removedCamera:
        return Colors.red;
      case CameraReportType.speedChanged:
        return Colors.purple;
    }
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

  String _getStatusDisplayName(CameraStatus status, BuildContext context) {
    switch (status) {
      case CameraStatus.pending:
        return AppLocalizations.of(context).pendingReview;
      case CameraStatus.verified:
        return AppLocalizations.of(context).verified;
      case CameraStatus.rejected:
        return AppLocalizations.of(context).rejected;
      case CameraStatus.duplicate:
        return AppLocalizations.of(context).duplicate;
    }
  }

  String _formatDateTime(DateTime dateTime, BuildContext context) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return AppLocalizations.of(context).justNow;
    } else if (difference.inHours < 1) {
      return AppLocalizations.of(context).minutesAgo(difference.inMinutes);
    } else if (difference.inDays < 1) {
      return AppLocalizations.of(context).hoursAgo(difference.inHours);
    } else if (difference.inDays < 7) {
      return AppLocalizations.of(context).daysAgo(difference.inDays);
    } else {
      return DateFormat('dd/MM/yyyy').format(dateTime);
    }
  }
}
