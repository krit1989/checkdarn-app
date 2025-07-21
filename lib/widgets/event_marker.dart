import 'package:flutter/material.dart';
import '../models/event_model.dart';

class EventMarker extends StatelessWidget {
  final EventCategory category;
  final double scale;
  final VoidCallback? onTap;

  const EventMarker({
    super.key,
    required this.category,
    this.scale = 1.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // คำนวณขนาดตาม scale
    const double baseWidth = 23.0;
    const double baseHeight = 30.0;
    final double width = baseWidth * scale;
    final double height = baseHeight * scale;

    final double circleSize = 17.5 * scale;
    final double pinWidth = 2.4 * scale;
    final double pinHeight = 13.0 * scale;
    final double borderWidth = 1.5 * scale;
    final double fontSize = 10.4 * scale;
    final double borderRadius = 1.2 * scale;

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ขาหมุดสีเข้มตาม category (ส่วนล่าง)
          Positioned(
            bottom: 0,
            child: Container(
              width: pinWidth,
              height: pinHeight,
              decoration: BoxDecoration(
                color: category.color.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(borderRadius),
              ),
            ),
          ),
          // วงกลมตาม category (ส่วนบน)
          Positioned(
            top: 0,
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                width: circleSize,
                height: circleSize,
                decoration: BoxDecoration(
                  color: category.color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: borderWidth,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    category.emoji,
                    style: TextStyle(
                      fontSize: fontSize,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
