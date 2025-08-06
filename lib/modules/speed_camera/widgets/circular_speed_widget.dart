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
  late AnimationController _rotationController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    // Animation controller สำหรับการหมุนของวงแหวนเมื่อเคลื่อนที่
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // Animation controller สำหรับ pulse effect
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // เริ่ม animation หากกำลังเคลื่อนที่
    if (widget.isMoving) {
      _rotationController.repeat();
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(CircularSpeedWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // อัปเดต animation เมื่อสถานะการเคลื่อนที่เปลี่ยน
    if (widget.isMoving != oldWidget.isMoving) {
      if (widget.isMoving) {
        _rotationController.repeat();
        _pulseController.repeat(reverse: true);
      } else {
        _rotationController.stop();
        _pulseController.stop();
      }
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Color _getSpeedColor() {
    if (widget.speedLimit == null) return const Color(0xFF1158F2);

    final ratio = widget.currentSpeed / widget.speedLimit!;
    if (ratio > 1.2) return Colors.red.shade600;
    if (ratio > 1.0) return Colors.orange.shade600;
    return const Color(0xFF1158F2);
  }

  double _getSpeedProgress() {
    if (widget.speedLimit == null) return widget.currentSpeed / 100.0;
    return (widget.currentSpeed / widget.speedLimit!).clamp(0.0, 1.5);
  }

  @override
  Widget build(BuildContext context) {
    final speedColor = _getSpeedColor();
    final progress = _getSpeedProgress();

    return AnimatedBuilder(
      animation: Listenable.merge([_rotationController, _pulseController]),
      builder: (context, child) {
        return Container(
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

              // วงแหวนความเร็ว (หมุนเมื่อเคลื่อนที่)
              Transform.rotate(
                angle: widget.isMoving
                    ? _rotationController.value * 2 * math.pi
                    : 0,
                child: CustomPaint(
                  size: const Size(120, 120),
                  painter: SpeedRingPainter(
                    progress: progress,
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
                      // ความเร็วปัจจุบัน
                      Text(
                        '${widget.currentSpeed.toInt()}',
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

              // จำกัดความเร็ว (หากมี)
              if (widget.speedLimit != null)
                Positioned(
                  bottom: 15,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Text(
                      'จำกัด ${widget.speedLimit!.toInt()}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.orange,
                        fontFamily: 'NotoSansThai',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
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
