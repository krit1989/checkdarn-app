import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/event_model.dart';

class EventMarkerPainter extends CustomPainter {
  final double rotation; // มุมหมุน (0-360 องศา)
  final bool showDirectionPointer; // แสดงสามเหลี่ยมหรือไม่
  final Color markerColor; // สีของหมุด
  final String? emoji; // emoji ที่จะแสดง (สำหรับหมุดโพส)
  final bool isPost; // เป็นหมุดโพสหรือไม่

  const EventMarkerPainter({
    this.rotation = 0.0,
    this.showDirectionPointer = true,
    this.markerColor = const Color(0xFF0C59F7),
    this.emoji,
    this.isPost = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 6; // รัศมีของวงกลมกลาง

    // 1. วาดสามเหลี่ยม (ขาหมุดสำหรับโพส หรือ ลูกศรทิศทางสำหรับตำแหน่งตัวเอง)
    if (showDirectionPointer || isPost) {
      canvas.save();
      canvas.translate(center.dx, center.dy);

      if (isPost) {
        // สำหรับหมุดโพส: สามเหลี่ยมชี้ลงเป็นขาหมุด (หมุน 0 องศา = ชี้ลง)
        // ไม่ต้องหมุนเพิ่ม เพราะ moveTo ด้านล่างคือจุดแหลม

        // เพิ่มเงาสำหรับปลายหมุด (จุดแหลม)
        final shadowPaint = Paint()
          ..color = Colors.black.withValues(alpha: 0.2) // เงาอ่อนๆ
          ..maskFilter =
              const MaskFilter.blur(BlurStyle.normal, 3.0); // เบลอเงา

        final shadowPath = Path();
        // เงาเล็กๆ ที่ปลายหมุด - เลื่อนลงและขวาเล็กน้อย
        shadowPath.moveTo(2, radius * 2.8 + 2); // จุดแหลมชี้ลง + offset
        shadowPath.lineTo(
            -radius * 0.6 + 2, radius * 1.3 + 2); // จุดซ้าย + offset
        shadowPath.lineTo(
            radius * 0.6 + 2, radius * 1.3 + 2); // จุดขวา + offset
        shadowPath.close();

        // วาดเงาก่อน
        canvas.drawPath(shadowPath, shadowPaint);
      } else {
        // สำหรับหมุดตำแหน่งตัวเอง: ลูกศรชี้ทิศทาง (หมุนตาม rotation)
        canvas.rotate(rotation * math.pi / 180);
      }

      final trianglePaint = Paint()
        ..color = markerColor
        ..style = PaintingStyle.fill;

      final trianglePath = Path();
      if (isPost) {
        // ขาหมุดโพส: สามเหลี่ยมชี้ลงแคบยาว
        trianglePath.moveTo(0, radius * 2.8); // จุดแหลมชี้ลง
        trianglePath.lineTo(-radius * 0.6, radius * 1.3); // จุดซ้าย
        trianglePath.lineTo(radius * 0.6, radius * 1.3); // จุดขวา
      } else {
        // ลูกศรทิศทาง: สามเหลี่ยมกว้างชี้ลง
        trianglePath.moveTo(0, radius * 3.3); // จุดแหลมชี้ลง (ค่าบวก)
        trianglePath.lineTo(-radius * 0.88, radius * 1.2); // จุดซ้าย
        trianglePath.lineTo(radius * 0.88, radius * 1.2); // จุดขวา
      }
      trianglePath.close();

      canvas.drawPath(trianglePath, trianglePaint);
      canvas.restore();
    }

    // 2. วาดวงกลมสีขาว (วงนอก)
    final outerWhitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
        center, radius * 1.4, outerWhitePaint); // ลดจาก 1.575 เป็น 1.4

    // 3. วาดวงกลมสีตามหมวดหมู่ตรงกลาง
    final colorPaint = Paint()
      ..color = markerColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 1.2, colorPaint);

    // 4. วาดขอบสีขาวรอบวงกลม
    final whiteBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, radius * 1.2 + 1, whiteBorderPaint);

    // 5. วาด emoji ตรงกลาง (สำหรับหมุดโพส)
    if (emoji != null && isPost) {
      try {
        final textPainter = TextPainter(
          text: TextSpan(
            text: emoji!,
            style: TextStyle(
              fontSize: radius * 1.4, // เพิ่มขนาดให้ใหญ่ขึ้น
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();

        final emojiOffset = Offset(
          center.dx - (textPainter.width / 2),
          center.dy - (textPainter.height / 2),
        );

        textPainter.paint(canvas, emojiOffset);
      } catch (e) {
        // หากไม่สามารถวาด emoji ได้ ให้วาดจุดสีขาวแทน
        final fallbackPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
        canvas.drawCircle(center, radius * 0.3, fallbackPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant EventMarkerPainter oldDelegate) {
    return oldDelegate.rotation != rotation ||
        oldDelegate.showDirectionPointer != showDirectionPointer ||
        oldDelegate.markerColor != markerColor ||
        oldDelegate.emoji != emoji ||
        oldDelegate.isPost != isPost;
  }
}

// Widget หมุดเหตุการณ์รูปแบบใหม่
class EventMarker extends StatelessWidget {
  final double scale;
  final double rotation; // มุมหมุนตามทิศทาง (0-360 องศา)
  final bool showDirectionPointer; // แสดงสามเหลี่ยมชี้ทิศทางหรือไม่
  final Color markerColor; // สีของหมุด
  final String? emoji; // emoji ที่จะแสดง (สำหรับหมุดโพส)
  final bool isPost; // เป็นหมุดโพสหรือไม่
  final EventCategory? category; // หมวดหมู่เหตุการณ์
  final VoidCallback? onTap; // ฟังก์ชันเมื่อกดหมุด

  const EventMarker({
    super.key,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.showDirectionPointer = true,
    this.markerColor = const Color(0xFF0C59F7),
    this.emoji,
    this.isPost = false,
    this.category,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // ขนาดพื้นฐาน (ปรับเป็น 55)
    const double baseSize = 55.0;
    final double size = baseSize * scale;

    // ใช้สีและ emoji จาก category ถ้ามี
    final Color finalColor = category?.color ?? markerColor;
    final String? finalEmoji = category?.emoji ?? emoji;

    Widget marker = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: EventMarkerPainter(
          rotation: rotation,
          showDirectionPointer: showDirectionPointer,
          markerColor: finalColor,
          emoji: finalEmoji,
          isPost: isPost,
        ),
      ),
    );

    // เพิ่ม GestureDetector ถ้ามี onTap
    if (onTap != null) {
      marker = GestureDetector(
        onTap: onTap,
        child: marker,
      );
    }

    return marker;
  }
}
