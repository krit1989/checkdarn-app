import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../generated/gen_l10n/app_localizations.dart';

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
      duration: const Duration(milliseconds: 200), // ตอบสนองเร็วขึ้น
      vsync: this,
    );

    // อัปเดต progress ครั้งแรก
    _updateProgress();
  }

  @override
  void didUpdateWidget(CircularSpeedWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // อัปเดต progress เมื่อความเร็วเปลี่ยน
    if (widget.currentSpeed != oldWidget.currentSpeed) {
      _updateProgress();
    }
  }

  void _updateProgress() {
    // คำนวณ progress จาก 0 ถึง 1 โดยใช้ 200 km/h เป็นสูงสุด
    final targetProgress = (widget.currentSpeed / MAX_SPEED).clamp(0.0, 1.0);

    // ปรับ Animation Duration ตามความเร็ว - เร็วขึ้นเมื่อความเร็วสูง
    int animationDuration;
    if (widget.currentSpeed > 100) {
      animationDuration = 100; // ความเร็วสูงมาก = animation เร็ว (100ms)
    } else if (widget.currentSpeed > 60) {
      animationDuration = 150; // ความเร็วสูง = animation ปานกลาง (150ms)
    } else if (widget.currentSpeed > 30) {
      animationDuration = 200; // ความเร็วปานกลาง = animation ปกติ (200ms)
    } else {
      animationDuration =
          250; // ความเร็วต่ำ = animation ช้า เพื่อความนุ่มนวล (250ms)
    }

    // Debug logging สำหรับตรวจสอบการ Sync
    print('=== CIRCULAR SPEED WIDGET SYNC ===');
    print('Speed: ${widget.currentSpeed.toStringAsFixed(2)} km/h');
    print('Display: ${_getFormattedSpeed()}');
    print('Progress: ${(targetProgress * 100).toStringAsFixed(1)}%');
    print('Animation Duration: ${animationDuration}ms');
    print('Color: ${_getSpeedColor()}');

    // อัปเดต duration ของ _progressController
    _progressController.duration = Duration(milliseconds: animationDuration);

    _progressController.reset();
    _progressController.forward();

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
                  CustomPaint(
                    size: const Size(120, 120),
                    painter: SpeedRingPainter(
                      progress: 1.0,
                      color: Colors.grey.withValues(alpha: 0.2),
                      strokeWidth: 8,
                    ),
                  ),

                  // วงแหวนความเร็ว (Progress Bar - ไม่หมุน)
                  CustomPaint(
                    size: const Size(120, 120),
                    painter: SpeedRingPainter(
                      progress: _currentProgress,
                      color: speedColor,
                      strokeWidth: 8,
                      hasGlow: widget.isMoving,
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

            // จำกัดความเร็ว (หากมี) - ย้ายออกมาด้านล่างวงกลม
            if (widget.speedLimit != null) ...[
              const SizedBox(height: 8), // เพิ่มระยะห่าง
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius:
                      BorderRadius.circular(6), // ลดความโค้งจาก 12 เป็น 6
                  border: Border.all(color: Colors.orange, width: 1),
                ),
                child: Text(
                  '${AppLocalizations.of(context).speedLimitText} ${widget.speedLimit!.toInt()}',
                  style: const TextStyle(
                    fontSize: 14, // เพิ่มขนาดจาก 10 เป็น 14
                    color: Colors.orange,
                    fontFamily: 'NotoSansThai',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate != this;
  }
}
