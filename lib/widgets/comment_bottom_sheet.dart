import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/comment_service.dart';
import '../services/auth_service.dart';
import '../generated/gen_l10n/app_localizations.dart';

class CommentBottomSheet extends StatefulWidget {
  final String reportId;
  final String reportType;

  const CommentBottomSheet({
    super.key,
    required this.reportId,
    required this.reportType,
  });

  @override
  State<CommentBottomSheet> createState() => _CommentBottomSheetState();
}

class _CommentBottomSheetState extends State<CommentBottomSheet> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isUserLoggedIn = false; // Local state สำหรับสถานะล็อกอิน

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  // ตรวจสอบสถานะล็อกอินครั้งเดียวตอน init
  void _checkLoginStatus() {
    _isUserLoggedIn = AuthService.isLoggedIn;
  }

  // ดึงชื่อผู้ใช้แบบ masked
  String _getMaskedUserName(String userId, Map<String, dynamic> data) {
    // ถ้ามี displayName ใน Firestore ให้ใช้ชื่อนั้น
    if (data['displayName'] != null &&
        data['displayName'].toString().isNotEmpty) {
      final displayName = data['displayName'].toString();
      return AuthService.maskName(displayName);
    }

    // ถ้าเป็นผู้ใช้ปัจจุบัน ใช้ displayName จาก Google Sign-In
    if (AuthService.currentUser?.uid == userId) {
      return AuthService.getMaskedDisplayName();
    }

    // ถ้าเป็นผู้ใช้คนอื่น แสดง userId แบบ masked
    if (userId.length <= 8) return userId;
    return '${userId.substring(0, 4)}${'*' * (userId.length - 4)}';
  }

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _reportComment(String commentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = MediaQuery.of(context).size.width;
          final dialogWidth = screenWidth * 0.85; // 85% ของหน้าจอ

          return AlertDialog(
            contentPadding: const EdgeInsets.all(20),
            insetPadding: EdgeInsets.symmetric(
              horizontal: (screenWidth - dialogWidth) / 2,
              vertical: 24,
            ),
            title: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: dialogWidth),
              child: Text(
                AppLocalizations.of(context).reportComment,
                style:
                    const TextStyle(fontSize: 18, fontFamily: 'NotoSansThai'),
              ),
            ),
            content: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: dialogWidth),
              child: Text(
                AppLocalizations.of(context).reportCommentConfirm,
                style:
                    const TextStyle(fontSize: 14, fontFamily: 'NotoSansThai'),
              ),
            ),
            actions: [
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('ยกเลิก',
                        style: TextStyle(fontFamily: 'NotoSansThai')),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('รายงาน',
                        style: TextStyle(
                            color: Colors.red, fontFamily: 'NotoSansThai')),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    if (confirmed == true) {
      try {
        await CommentService.reportComment(
          reportId: widget.reportId,
          commentId: commentId,
          reporterId: 'anonymous',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).reportCommentSuccess,
                  style: const TextStyle(fontFamily: 'NotoSansThai')),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('เกิดข้อผิดพลาด: $e',
                    style: TextStyle(fontFamily: 'NotoSansThai'))),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.3,
      maxChildSize: 0.95,
      snap: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar สำหรับดึง
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 8, bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.chat_bubble_outline, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context).commentsTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'NotoSansThai',
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            // Comments List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: CommentService.getCommentsStream(widget.reportId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.chat_bubble_outline,
                              size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            AppLocalizations.of(context).noCommentsYet,
                            style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                                fontFamily: 'NotoSansThai'),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppLocalizations.of(context).beFirstToComment,
                            style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                                fontFamily: 'NotoSansThai'),
                          ),
                        ],
                      ),
                    );
                  }

                  final comments = snapshot.data!.docs;
                  return ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final comment = comments[index];
                      final data = comment.data() as Map<String, dynamic>;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Comment text
                            Text(
                              data['comment'] ?? 'ไม่มีข้อความ',
                              style: const TextStyle(
                                  fontSize: 15, fontFamily: 'NotoSansThai'),
                            ),
                            const SizedBox(height: 8),

                            // Footer: User and time
                            Row(
                              children: [
                                Icon(Icons.person_outline,
                                    size: 16, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    data['userId'] == 'anonymous'
                                        ? 'ผู้ใช้ไม่ระบุชื่อ'
                                        : _getMaskedUserName(
                                            data['userId'], data),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'NotoSansThai',
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Text(' • ',
                                    style: TextStyle(
                                        color: Colors.grey,
                                        fontFamily: 'NotoSansThai')),
                                Flexible(
                                  child: Text(
                                    CommentService.formatCommentTime(
                                        data['timestamp']),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                      fontFamily: 'NotoSansThai',
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Report button
                                GestureDetector(
                                  onTap: () => _reportComment(comment.id),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.flag_outlined,
                                            size: 14,
                                            color: Colors.red.shade400),
                                        const SizedBox(width: 4),
                                        Text(
                                          'รายงาน',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.red.shade400,
                                              fontFamily: 'NotoSansThai'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Add Comment Button - ติดด้านล่าง
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: SafeArea(
                top: false,
                child: GestureDetector(
                  onTap: () => _showCommentInput(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.person_outline,
                            size: 20, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context).addCommentHint,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey.shade600,
                              fontFamily: 'NotoSansThai',
                            ),
                          ),
                        ),
                        Icon(Icons.send_outlined,
                            size: 20, color: Colors.grey.shade600),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // แสดง Comment Input แยกเป็น Modal ใหม่
  void _showCommentInput(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentInputModal(
        reportId: widget.reportId,
        isUserLoggedIn: _isUserLoggedIn,
        onLoginSuccess: () {
          setState(() {
            _isUserLoggedIn = true;
          });
        },
      ),
    );
  }
}

// Comment Input Modal แยกต่างหาก
class CommentInputModal extends StatefulWidget {
  final String reportId;
  final bool isUserLoggedIn;
  final VoidCallback onLoginSuccess;

  const CommentInputModal({
    super.key,
    required this.reportId,
    required this.isUserLoggedIn,
    required this.onLoginSuccess,
  });

  @override
  State<CommentInputModal> createState() => _CommentInputModalState();
}

class _CommentInputModalState extends State<CommentInputModal> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSubmitting = false;
  bool _localIsLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _localIsLoggedIn = widget.isUserLoggedIn;
    // Auto focus เมื่อเปิด modal
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;

    final comment = _commentController.text.trim();
    if (comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context).pleaseEnterComment,
                style: const TextStyle(fontFamily: 'NotoSansThai'))),
      );
      return;
    }

    // ตรวจสอบการล็อกอิน
    if (!_localIsLoggedIn) {
      final success = await AuthService.showLoginDialog(context);
      if (success && mounted) {
        setState(() {
          _localIsLoggedIn = true;
        });
        widget.onLoginSuccess();
      } else {
        return;
      }
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // ใช้ User ID และ displayName จาก Google Sign-In
      final userId = AuthService.currentUser?.uid ?? 'anonymous';
      final displayName = AuthService.currentUser?.displayName;

      await CommentService.addComment(
        reportId: widget.reportId,
        comment: comment,
        userId: userId,
        displayName: displayName,
      );

      if (mounted) {
        Navigator.pop(context); // ปิด modal หลังส่งสำเร็จ
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).commentSentSuccess,
                style: const TextStyle(fontFamily: 'NotoSansThai')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e',
                style: TextStyle(fontFamily: 'NotoSansThai')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.only(bottom: keyboardHeight),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Input field - ใช้สไตล์เดียวกับ fake input
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius:
                      BorderRadius.circular(12), // ลดความโค้งจาก 20 เป็น 12
                ),
                child: Row(
                  children: [
                    Icon(Icons.person_outline,
                        size: 20, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        focusNode: _focusNode,
                        maxLength: CommentService.maxCommentLength,
                        maxLines: 1, // จำกัดให้เป็นบรรทัดเดียวเหมือนก่อนพิมพ์
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _handleSubmit(),
                        decoration: InputDecoration(
                          hintText:
                              AppLocalizations.of(context).typeCommentHint,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          counterText: '', // ซ่อน counter default
                          isDense: true, // ลดความสูงภายใน
                          hintStyle:
                              const TextStyle(fontFamily: 'NotoSansThai'),
                        ),
                        style: const TextStyle(
                            fontSize: 15, fontFamily: 'NotoSansThai'),
                      ),
                    ),
                    GestureDetector(
                      onTap: _isSubmitting ? null : _handleSubmit,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.grey,
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(
                              Icons.send_outlined,
                              size: 20,
                              color: Colors.grey.shade600,
                            ),
                    ),
                  ],
                ),
              ),

              // Character counter - ซ่อนเพื่อให้ความสูงเท่า fake input
              // if (_localIsLoggedIn)
              //   Align(
              //     alignment: Alignment.centerRight,
              //     child: Text(
              //       '${_commentController.text.length}/${CommentService.maxCommentLength}',
              //       style: TextStyle(
              //         fontSize: 11,
              //         color: _commentController.text.length >
              //                 CommentService.maxCommentLength * 0.9
              //             ? Colors.red
              //             : Colors.grey,
              //       ),
              //     ),
              //   ),
            ],
          ),
        ),
      ),
    );
  }
}
