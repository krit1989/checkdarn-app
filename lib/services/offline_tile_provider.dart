import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';

class OfflineTileProvider extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    // สร้าง path สำหรับ tile
    final tilePath =
        'assets/map_tiles/${coordinates.z}/${coordinates.x}/${coordinates.y}.png';

    // ลองโหลด asset ถ้าไม่มีให้ใช้ placeholder
    return AssetImage(tilePath);
  }
}

// Helper function เพื่อตรวจสอบว่ามี asset หรือไม่
Future<bool> assetExists(String path) async {
  try {
    await rootBundle.load(path);
    return true;
  } catch (e) {
    return false;
  }
}

// สร้าง placeholder tile widget
class PlaceholderTile extends StatelessWidget {
  final int x;
  final int y;
  final int z;

  const PlaceholderTile({
    super.key,
    required this.x,
    required this.y,
    required this.z,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 256,
      height: 256,
      color: const Color(0xFFF0F8FF),
      child: CustomPaint(
        painter: GridPainter(),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.map_outlined,
                color: Color(0xFFBDBDBD),
                size: 32,
              ),
              const SizedBox(height: 4),
              Text(
                '$z/$x/$y',
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFFBDBDBD),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 1;

    // วาดเส้นตาราง
    for (int i = 0; i <= 8; i++) {
      final x = size.width * i / 8;
      final y = size.height * i / 8;

      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
