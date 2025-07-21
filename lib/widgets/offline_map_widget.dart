import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/event_model.dart';
import 'dart:ui' as ui;

class OfflineMapWidget extends StatefulWidget {
  final LatLng center;
  final double zoom;
  final double searchRadius;
  final List<Map<String, dynamic>>? mockEvents;
  final List<EventCategory>? selectedCategories;

  const OfflineMapWidget({
    super.key,
    required this.center,
    required this.zoom,
    required this.searchRadius,
    this.mockEvents,
    this.selectedCategories,
  });

  @override
  State<OfflineMapWidget> createState() => _OfflineMapWidgetState();
}

class _OfflineMapWidgetState extends State<OfflineMapWidget> {
  late TransformationController _controller;
  LatLng _currentCenter = const LatLng(13.7563, 100.5018);
  double _currentZoom = 15.0;

  @override
  void initState() {
    super.initState();
    _controller = TransformationController();
    _currentCenter = widget.center;
    _currentZoom = widget.zoom;
  }

  // ฟังก์ชันสำหรับอัปเดตตำแหน่งแผนที่
  void updateCenter(LatLng newCenter) {
    setState(() {
      _currentCenter = newCenter;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // แผนที่หลักแบบ InteractiveViewer สำหรับ pan/zoom
        InteractiveViewer(
          transformationController: _controller,
          minScale: 0.5,
          maxScale: 5.0,
          boundaryMargin: const EdgeInsets.all(200),
          onInteractionUpdate: (details) {
            // อัปเดตการแสดงผลเมื่อมีการ pan/zoom
            setState(() {});
          },
          child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: CustomPaint(
              painter: OfflineMapPainter(
                center: _currentCenter,
                zoom: _currentZoom,
                searchRadius: widget.searchRadius,
              ),
              size: Size.infinite,
            ),
          ),
        ),

        // Markers overlay - จะอยู่บนแผนที่เสมอ
        ..._buildMarkers(),
      ],
    );
  }

  List<Widget> _buildMarkers() {
    List<Widget> markers = [];
    final screenSize = MediaQuery.of(context).size;

    // หมุดตำแหน่งผู้ใช้ (ตรงกลางหน้าจอ)
    markers.add(
      Positioned(
        left: screenSize.width / 2 - 20,
        top: screenSize.height / 2 - 20,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF4673E5),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.4),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.person_pin_circle,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
    );

    // วงรัศมีการค้นหา
    final radiusPixels = widget.searchRadius * 3.0; // แปลงเป็น pixels
    markers.add(
      Positioned(
        left: screenSize.width / 2 - radiusPixels,
        top: screenSize.height / 2 - radiusPixels,
        child: Container(
          width: radiusPixels * 2,
          height: radiusPixels * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF4673E5)
                .withValues(alpha: 0.1), // เพิ่มสีพื้นหลังฟ้าจางๆ
            border: Border.all(
              color: const Color(0xFF4673E5).withValues(alpha: 0.4),
              width: 1,
            ),
          ),
        ),
      ),
    );

    // หมุดเหตุการณ์
    if (widget.mockEvents != null && widget.selectedCategories != null) {
      for (int i = 0; i < widget.mockEvents!.length; i++) {
        final event = widget.mockEvents![i];
        final category = event['category'] as EventCategory;

        if (widget.selectedCategories!.contains(category)) {
          // คำนวณตำแหน่งแบบสุ่มรอบๆ ศูนย์กลาง
          final offsetX = (i % 5 - 2) * 60.0;
          final offsetY = ((i ~/ 5) % 5 - 2) * 60.0;

          markers.add(
            Positioned(
              left: screenSize.width / 2 + offsetX - 15,
              top: screenSize.height / 2 + offsetY - 15,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: category.color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    category.emoji,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
            ),
          );
        }
      }
    }

    return markers;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// CustomPainter สำหรับวาดแผนที่ offline
class OfflineMapPainter extends CustomPainter {
  final LatLng center;
  final double zoom;
  final double searchRadius;

  OfflineMapPainter({
    required this.center,
    required this.zoom,
    required this.searchRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // วาดพื้นหลังไล่สี
    const gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFE8F4FD), // ฟ้าอ่อน
        Color(0xFFD1E7DD), // เขียวอ่อน
      ],
    );

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    paint.shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);

    // วาดเส้นตารางเบาๆ
    paint.shader = null;
    paint.color = Colors.white.withValues(alpha: 0.3);
    paint.strokeWidth = 0.5;
    paint.style = PaintingStyle.stroke;

    const gridSize = 50.0;
    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // วาดถนนหลัก
    paint.color = Colors.white.withValues(alpha: 0.8);
    paint.strokeWidth = 3;

    // ถนนแนวนอน
    for (int i = 1; i < 6; i++) {
      final y = size.height * i / 6;
      canvas.drawLine(
        Offset(size.width * 0.1, y),
        Offset(size.width * 0.9, y),
        paint,
      );
    }

    // ถนนแนวตั้ง
    for (int i = 1; i < 6; i++) {
      final x = size.width * i / 6;
      canvas.drawLine(
        Offset(x, size.height * 0.1),
        Offset(x, size.height * 0.9),
        paint,
      );
    }

    // วาดแม่น้ำ
    paint.color = const Color(0xFF42A5F5);
    paint.strokeWidth = 6;
    final riverPath = ui.Path();
    riverPath.moveTo(size.width * 0.15, size.height * 0.3);
    riverPath.quadraticBezierTo(
      size.width * 0.4,
      size.height * 0.7,
      size.width * 0.85,
      size.height * 0.5,
    );
    canvas.drawPath(riverPath, paint);

    // วาดพื้นที่สีเขียว (สวนสาธารณะ)
    paint.color = const Color(0xFF66BB6A).withValues(alpha: 0.4);
    paint.style = PaintingStyle.fill;

    // สวนที่ 1
    final park1 = Rect.fromLTWH(
      size.width * 0.15,
      size.height * 0.15,
      size.width * 0.25,
      size.height * 0.2,
    );
    canvas.drawOval(park1, paint);

    // สวนที่ 2
    final park2 = Rect.fromLTWH(
      size.width * 0.6,
      size.height * 0.6,
      size.width * 0.3,
      size.height * 0.25,
    );
    canvas.drawOval(park2, paint);

    // วาดอาคารสำคัญ
    paint.color = const Color(0xFF90A4AE);
    paint.style = PaintingStyle.fill;

    // อาคาร 1
    final building1 = Rect.fromLTWH(
      size.width * 0.3,
      size.height * 0.4,
      size.width * 0.08,
      size.height * 0.12,
    );
    canvas.drawRect(building1, paint);

    // อาคาร 2
    final building2 = Rect.fromLTWH(
      size.width * 0.7,
      size.height * 0.25,
      size.width * 0.06,
      size.height * 0.1,
    );
    canvas.drawRect(building2, paint);

    // วาดถนนย่อย
    paint.color = Colors.white.withValues(alpha: 0.5);
    paint.strokeWidth = 1.5;
    paint.style = PaintingStyle.stroke;

    // ถนนย่อยแนวนอน
    for (int i = 1; i < 12; i++) {
      if (i % 2 == 0) {
        // ทุกๆ 2 เส้น
        final y = size.height * i / 12;
        canvas.drawLine(
          Offset(size.width * 0.2, y),
          Offset(size.width * 0.8, y),
          paint,
        );
      }
    }

    // ถนนย่อยแนวตั้ง
    for (int i = 1; i < 12; i++) {
      if (i % 2 == 0) {
        // ทุกๆ 2 เส้น
        final x = size.width * i / 12;
        canvas.drawLine(
          Offset(x, size.height * 0.2),
          Offset(x, size.height * 0.8),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
