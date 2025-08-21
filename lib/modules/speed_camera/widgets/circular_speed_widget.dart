import 'package:flutter/material.dart';
import 'dart:math' as math;

class CircularSpeedWidget extends StatefulWidget {
  final double currentSpeed;
  final double? speedLimit;
  final bool isMoving;

  const CircularSpeedWidget({
    super.key,
    required this.currentSpeed,
    this.speedLimit,
    this.isMoving = false,
  });

  @override
  State<CircularSpeedWidget> createState() => _CircularSpeedWidgetState();
}

class _CircularSpeedWidgetState extends State<CircularSpeedWidget>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  double _currentProgress = 0.0;
  static const double MAX_SPEED = 200.0; // ความเร็วสูงสุด 200 km/h

  @override
  void initState() {
    super.initState();

    // Animation controller สำหรับ progress แบบ smooth
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 100), // ลดเวลาให้ตอบสนองเร็วขึ้น
      vsync: this,
    );

    // อัปเดต progress ครั้งแรก
    _updateProgress();
  }

  @override
  void didUpdateWidget(CircularSpeedWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // อัปเดต progress เมื่อความเร็วเปลี่ยน - ลดการตรวจสอบให้ละเอียดขึ้น
    if ((widget.currentSpeed - oldWidget.currentSpeed).abs() > 0.01) {
      _updateProgress();
    }
  }

  void _updateProgress() {
    // คำนวณ progress จาก 0 ถึง 1 โดยใช้ 200 km/h เป็นสูงสุด
    final targetProgress = (widget.currentSpeed / MAX_SPEED).clamp(0.0, 1.0);

    // คำนวณระยะห่างระหว่างค่าเก่าและใหม่
    final delta = (targetProgress - _currentProgress).abs();

    // Duration แปรผันตาม delta - ลด min ลงเหลือ 20ms เพื่อ "เกาะสปีดจริง" มากขึ้น
    final animationDurationMs =
        (40 + 350 * delta).clamp(20, 120).toInt(); // 20–120ms

    // ใช้ animateTo แทน reset+forward เพื่อความนุ่มนวล
    _progressController.animateTo(
      targetProgress,
      duration: Duration(milliseconds: animationDurationMs),
      curve: Curves.linear,
    );

    // Debug logging แบบ throttled (ไม่ log ทุกครั้ง)
    if (delta > 0.01) {
      print('=== SPEED WIDGET UPDATE ===');
      print('Speed: ${widget.currentSpeed.toStringAsFixed(1)} km/h');
      print('Delta: ${(delta * 100).toStringAsFixed(1)}%');
      print('Duration: ${animationDurationMs}ms');
    }

    _currentProgress = targetProgress;
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  Color _getSpeedColor() {
    double ratio = widget.currentSpeed / (widget.speedLimit ?? 120);
    if (ratio > 1.2) return Colors.red.shade600;
    if (ratio > 1.0) return Colors.orange.shade600;
    return const Color(0xFF1158F2);
  }

  String _getFormattedSpeed() {
    // แสดงเป็นจำนวนเต็มทุกครั้งเพื่อให้ดูเรียบง่ายและเป็นธรรมชาติ
    return widget.currentSpeed.toInt().toString();
  }

  @override
  Widget build(BuildContext context) {
    final speedColor = _getSpeedColor();

    return AnimatedBuilder(
      animation: _progressController,
      builder: (context, child) {
        // ใช้ progress ที่คำนวณจากความเร็วแบบ real-time
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // วงแหวนพื้นหลัง
                  RepaintBoundary(
                    child: CustomPaint(
                      size: const Size(120, 120),
                      painter: SpeedRingPainter(
                        progress: 1.0,
                        color: Colors.grey.withValues(alpha: 0.2),
                        strokeWidth: 8,
                      ),
                    ),
                  ),

                  // วงแหวนความเร็ว (Progress Bar - ไม่หมุน)
                  RepaintBoundary(
                    child: CustomPaint(
                      size: const Size(120, 120),
                      painter: SpeedRingPainter(
                        progress: _currentProgress,
                        color: speedColor,
                        strokeWidth: 8,
                        hasGlow: widget.isMoving,
                      ),
                    ),
                  ),

                  // ตัวเลขความเร็วกลางจอ ทรงกลมพอดีกับวงใน
                  Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0088FE),
                        shape: BoxShape.circle,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // ความเร็วปัจจุบัน - แสดงทศนิยมเมื่อความเร็วต่ำ
                          Text(
                            _getFormattedSpeed(),
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'NotoSansThai',
                              height: 1.0, // ลด line height
                            ),
                          ),
                          // หน่วย - ไม่มี spacing และลด line height
                          const Text(
                            'km/h',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                              fontFamily: 'NotoSansThai',
                              height: 1.0, // ลด line height
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class SpeedRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;
  final bool hasGlow;

  SpeedRingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
    this.hasGlow = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // ตรวจสอบ Hardware Acceleration
    final isHardwareAccelerated =
        canvas.runtimeType.toString().contains('Skia');
    if (!isHardwareAccelerated) {
      debugPrint(
          '⚠️ Warning: Canvas is not hardware accelerated - may affect performance');
    }

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // วาดเส้นโครงร่าง
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // เพิ่ม glow effect หากกำลังเคลื่อนที่
    if (hasGlow) {
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.5)
        ..strokeWidth = strokeWidth * 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 3);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2, // เริ่มจากด้านบน
        2 * math.pi * progress, // วาดตามความเร็ว
        false,
        glowPaint,
      );
    }

    // วาดวงแหวนหลัก
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // เริ่มจากด้านบน
      2 * math.pi * progress, // วาดตามความเร็ว
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant SpeedRingPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.strokeWidth != strokeWidth ||
      old.hasGlow != hasGlow;
}
