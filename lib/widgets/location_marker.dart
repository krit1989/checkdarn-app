import 'package:flutter/material.dart';
import 'dart:ui' as ui;

// คลาสสำหรับวาดขาหมุด
class PinPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF5252) // สีแดง
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    final path = ui.Path();

    // วาดขาหมุดที่มีความมนด้านล่าง
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final radius = size.width * 0.9; // ความโค้ง 30% ของความกว้าง
    path.addRRect(RRect.fromRectAndCorners(
      rect,
      bottomLeft: Radius.circular(radius),
      bottomRight: Radius.circular(radius),
    ));
    path.close();

    // วาดเงาก่อน
    canvas.drawPath(path.shift(const Offset(0, 1)), shadowPaint);

    // วาดสี่เหลี่ยมหลัก
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Widget หมุดตำแหน่ง
class LocationMarker extends StatelessWidget {
  final double scale;

  const LocationMarker({
    super.key,
    this.scale = 1.6, // ขยาย 60% (1.6 เท่า) เป็นค่าเริ่มต้น
  });

  @override
  Widget build(BuildContext context) {
    // ขนาดพื้นฐาน
    const double baseWidth = 23;
    const double baseHeight = 30;
    const double baseCircleSize = 17.5;
    const double baseBorderWidth = 1.5;
    const double baseIconSize = 9;
    const double basePinWidth = 2.4;
    const double basePinHeight = 13;

    // คำนวณขนาดตามสเกล
    final double width = baseWidth * scale;
    final double height = baseHeight * scale;
    final double circleSize = baseCircleSize * scale;
    final double borderWidth = baseBorderWidth * scale;
    final double iconSize = baseIconSize * scale;
    final double pinWidth = basePinWidth * scale;
    final double pinHeight = basePinHeight * scale;

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ขาหมุด (ส่วนล่าง) - รูปสี่เหลี่ยมผืนผ้า
          Positioned(
            bottom: 0,
            child: CustomPaint(
              size: Size(pinWidth, pinHeight),
              painter: PinPainter(),
            ),
          ),
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
