import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import '../models/event_model.dart';

class SimpleOfflineMap extends StatelessWidget {
  final LatLng center;
  final double searchRadius;
  final double zoom;
  final List<Map<String, dynamic>>? mockEvents;
  final List<dynamic>? selectedCategories;
  final MapController? mapController;

  const SimpleOfflineMap({
    super.key,
    required this.center,
    required this.searchRadius,
    this.zoom = 15.0,
    this.mockEvents,
    this.selectedCategories,
    this.mapController,
  });
  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: zoom,
        minZoom: 5.0,
        maxZoom: 18.0,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all, // อนุญาตการโต้ตอบทั้งหมด
        ),
      ),
      children: [
        // ใช้ TileLayer แบบ offline
        TileLayer(
          urlTemplate:
              "https://tile.openstreetmap.org/{z}/{x}/{y}.png", // placeholder URL
          tileBuilder: (context, widget, tile) {
            // สร้างแผนที่สีพื้นหลังสวยๆ เมื่อไม่มีไฟล์แผนที่
            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFE8F4FD), // ฟ้าอ่อน
                    Color(0xFFD1E7DD), // เขียวอ่อน
                  ],
                ),
              ),
              child: CustomPaint(
                painter: TilePainter(tile: tile),
                size: const Size(256, 256),
              ),
            );
          },
        ),

        // วงกลมรัศมีการค้นหา (บางและอ่อนลง)
        CircleLayer(
          circles: [
            CircleMarker(
              point: center,
              radius: searchRadius * 1000,
              useRadiusInMeter: true,
              color: const Color(0xFF4673E5).withValues(alpha: 0.1), // อ่อนลง
              borderColor: const Color(0xFF4673E5).withValues(alpha: 0.4), // อ่อนลง
              borderStrokeWidth: 1, // บางลง
            ),
          ],
        ),

        // หมุดตำแหน่งปัจจุบัน
        MarkerLayer(
          markers: [
            Marker(
              point: center,
              width: 40,
              height: 40,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFF4444),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
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
          ],
        ),

        // หมุดเหตุการณ์
        MarkerLayer(
          markers: _buildEventMarkers(),
        ),
      ],
    );
  }

  List<Marker> _buildEventMarkers() {
    if (mockEvents == null || selectedCategories == null) return [];

    return mockEvents!
        .where((event) => selectedCategories!.contains(event['category']))
        .map((event) {
      final category = event['category'] as EventCategory;

      return Marker(
        point: event['latlng'],
        width: 32,
        height: 32,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: category.color,
            border: Border.all(color: Colors.white, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Center(
            child: Text(
              category.emoji,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
      );
    }).toList();
  }
}

// CustomPainter สำหรับวาดแผนที่ในแต่ละ tile
class TilePainter extends CustomPainter {
  final TileImage tile;

  TilePainter({required this.tile});

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

    final gridSize = size.width / 8;
    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // วาดถนนง่ายๆ
    paint.color = Colors.white.withValues(alpha: 0.6);
    paint.strokeWidth = 2;

    // ถนนแนวนอน
    canvas.drawLine(
      Offset(0, size.height * 0.3),
      Offset(size.width, size.height * 0.3),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.7),
      Offset(size.width, size.height * 0.7),
      paint,
    );

    // ถนนแนวตั้ง
    canvas.drawLine(
      Offset(size.width * 0.3, 0),
      Offset(size.width * 0.3, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.7, 0),
      Offset(size.width * 0.7, size.height),
      paint,
    );

    // วาดพื้นที่สีเขียว (สวนสาธารณะ)
    paint.color = const Color(0xFF81C784).withValues(alpha: 0.3);
    paint.style = PaintingStyle.fill;

    final park = Rect.fromLTWH(
      size.width * 0.1,
      size.height * 0.1,
      size.width * 0.3,
      size.height * 0.3,
    );
    canvas.drawOval(park, paint);

    // วาดข้อมูล tile (สำหรับ debug)
    if (tile.coordinates.z <= 10) {
      // แสดงเฉพาะ zoom level ต่ำ
      final textPainter = TextPainter(
        text: TextSpan(
          text:
              '${tile.coordinates.x},${tile.coordinates.y}\nZ:${tile.coordinates.z}',
          style: TextStyle(
            color: Colors.black.withValues(alpha: 0.3),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          size.width / 2 - textPainter.width / 2,
          size.height / 2 - textPainter.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
