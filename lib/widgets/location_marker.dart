import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/event_model.dart';

class LocationMarkerPainter extends CustomPainter {
  final double rotation; // มุมหมุน (0-360 องศา)
  final bool showDirectionPointer; // แสดงสามเหลี่ยมหรือไม่
  final Color markerColor; // สีของหมุด
  final String? emoji; // emoji ที่จะแสดง (สำหรับหมุดโพส)
  final bool isPost; // เป็นหมุดโพสหรือไม่

  const LocationMarkerPainter({
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
        trianglePath.lineTo(
            -radius * 0.63, radius * 1.3); // จุดซ้าย (เพิ่มจาก 0.6 เป็น 0.63)
        trianglePath.lineTo(
            radius * 0.63, radius * 1.3); // จุดขวา (เพิ่มจาก 0.6 เป็น 0.63)
      } else {
        // ลูกศรทิศทาง: สามเหลี่ยมกว้างชี้ลง
        trianglePath.moveTo(0, radius * 3.3); // จุดแหลมชี้ลง (ค่าบวก)
        trianglePath.lineTo(-radius * 0.924,
            radius * 1.2); // จุดซ้าย (เพิ่มจาก 0.88 เป็น 0.924)
        trianglePath.lineTo(
            radius * 0.924, radius * 1.2); // จุดขวา (เพิ่มจาก 0.88 เป็น 0.924)
      }
      trianglePath.close();

      canvas.drawPath(trianglePath, trianglePaint);
      canvas.restore();
    }

    // 2. วาดรัศมีสีฟ้า รอบหมุดตำแหน่งตัวเอง (เพื่อให้เห็นง่าย)
    if (!isPost) {
      final radiusPaint = Paint()
        ..color = const Color(0xFF4673E5).withValues(alpha: 0.3) // สีฟ้า 30%
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius * 5.0, radiusPaint); // รัศมี 5.0
    }

    // 3. วาดวงกลมสีขาว (วงนอก)
    final outerWhitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
        center, radius * 1.4, outerWhitePaint); // ลดจาก 1.575 เป็น 1.4

    // 4. วาดวงกลมสีตามหมวดหมู่ตรงกลาง
    final colorPaint = Paint()
      ..color = markerColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 1.2, colorPaint);

    // 5. วาดขอบสีขาวรอบวงกลม
    final whiteBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, radius * 1.2 + 1, whiteBorderPaint);

    // 6. วาด emoji ตรงกลาง (สำหรับหมุดโพส)
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
  bool shouldRepaint(covariant LocationMarkerPainter oldDelegate) {
    return oldDelegate.rotation != rotation ||
        oldDelegate.showDirectionPointer != showDirectionPointer ||
        oldDelegate.markerColor != markerColor ||
        oldDelegate.emoji != emoji ||
        oldDelegate.isPost != isPost;
  }
}

// Widget หมุดตำแหน่งแบบ Petal Maps
class LocationMarker extends StatelessWidget {
  final double scale;
  final double rotation; // มุมหมุนตามทิศทาง (0-360 องศา)
  final bool showDirectionPointer; // แสดงสามเหลี่ยมชี้ทิศทางหรือไม่
  final Color markerColor; // สีของหมุด
  final String? emoji; // emoji ที่จะแสดง (สำหรับหมุดโพส)
  final bool isPost; // เป็นหมุดโพสหรือไม่

  const LocationMarker({
    super.key,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.showDirectionPointer = true,
    this.markerColor = const Color(0xFF0C59F7),
    this.emoji,
    this.isPost = false,
  });

  @override
  Widget build(BuildContext context) {
    // ขนาดพื้นฐาน (ปรับเป็น 55)
    const double baseSize = 55.0;
    final double size = baseSize * scale;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: LocationMarkerPainter(
          rotation: rotation,
          showDirectionPointer: showDirectionPointer,
          markerColor: markerColor,
          emoji: emoji,
          isPost: isPost,
        ),
      ),
    );
  }
}

// Widget สำหรับหมุดโพสตามหมวดหมู่ - ใช้ดีไซน์เดียวกับหมุดตำแหน่งตัวเอง
class PostMarker extends StatelessWidget {
  final double scale;
  final EventCategory category; // เปลี่ยนจาก PostCategory เป็น EventCategory
  final bool isImportant;
  final VoidCallback? onTap;

  const PostMarker({
    super.key,
    this.scale = 1.0,
    required this.category,
    this.isImportant = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: LocationMarker(
        scale: isImportant ? scale * 1.2 : scale,
        isPost: true, // บอกว่าเป็นหมุดโพส
        showDirectionPointer: true, // แสดงขาหมุด
        markerColor: category.color, // ใช้สีจาก EventCategory
        emoji: category.emoji, // ใช้ emoji จาก EventCategory แทน icon
      ),
    );
  }
}

// Widget ที่ใช้ Sensor เพื่อหมุนตามทิศทาง
class RotatingLocationMarker extends StatefulWidget {
  final double scale;

  const RotatingLocationMarker({
    super.key,
    this.scale = 1.0,
  });

  @override
  State<RotatingLocationMarker> createState() => _RotatingLocationMarkerState();
}

class _RotatingLocationMarkerState extends State<RotatingLocationMarker> {
  double? _currentHeading; // ทิศทางปัจจุบัน (องศา)

  @override
  void initState() {
    super.initState();
    // เริ่มต้นการติดตามเซ็นเซอร์ (ตัวอย่างเท่านั้น)
    // ในโปรเจคจริงควรใช้ package เช่น `sensors_plus` หรือ `flutter_compass`
    _mockCompassUpdates();
  }

  // ฟังก์ชันจำลองการอัปเดตทิศทาง (สำหรับทดสอบ)
  void _mockCompassUpdates() {
    // ในแอปจริงควรใช้ Compass จากเซ็นเซอร์จริง
    int count = 0;
    const duration = Duration(milliseconds: 100);
    Future.doWhile(() {
      if (!mounted) return false;

      setState(() {
        _currentHeading = (count * 10) % 360.0;
      });
      count++;

      return Future.delayed(duration).then((_) => true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LocationMarker(
      scale: widget.scale,
      rotation: _currentHeading ?? 0.0, // ใช้ทิศทางจากเซ็นเซอร์
      showDirectionPointer: true,
    );
  }
}

// Widget เก่าสำหรับ backward compatibility
class LegacyLocationMarker extends StatelessWidget {
  final double scale;

  const LegacyLocationMarker({
    super.key,
    this.scale = 1.6,
  });

  @override
  Widget build(BuildContext context) {
    // ขนาดพื้นฐาน
    const double baseWidth = 23;
    const double baseHeight = 30;
    const double baseCircleSize = 17.5;
    const double baseBorderWidth = 1.5;
    const double baseIconSize = 9;

    // คำนวณขนาดตามสเกล
    final double width = baseWidth * scale;
    final double height = baseHeight * scale;
    final double circleSize = baseCircleSize * scale;
    final double borderWidth = baseBorderWidth * scale;
    final double iconSize = baseIconSize * scale;

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // วงกลมสีฟ้า (ส่วนบน)
          Positioned(
            top: 0,
            child: Container(
              width: circleSize,
              height: circleSize,
              decoration: BoxDecoration(
                color: const Color(0xFF4673E5), // สีฟ้า
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: borderWidth,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 1.5),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.location_on,
                  color: Colors.white,
                  size: iconSize,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
