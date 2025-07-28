import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/speed_camera_model.dart';

class SpeedCameraMarker extends StatelessWidget {
  final SpeedCamera camera;
  final VoidCallback? onTap;

  const SpeedCameraMarker({
    Key? key,
    required this.camera,
    this.onTap,
  }) : super(key: key);

  // สีสำหรับแยกตามความเร็ว
  Color _getCameraColor() {
    if (camera.speedLimit <= 60) {
      return const Color(0xFF4CAF50); // เขียว
    } else if (camera.speedLimit <= 90) {
      return const Color(0xFFFF9800); // ส้ม
    } else {
      return const Color(0xFFF44336); // แดง
    }
  }

  // ขนาดของวงกลมเล็กตามจำนวนหลัก
  double _getBadgeSize() {
    final speedText = camera.speedLimit.toString();
    if (speedText.length == 1) {
      return 18.0; // 1 หลัก
    } else if (speedText.length == 2) {
      return 20.0; // 2 หลัก
    } else {
      return 24.0; // 3 หลัก
    }
  }

  // ขนาดตัวอักษรตามจำนวนหลัก
  double _getFontSize() {
    final speedText = camera.speedLimit.toString();
    if (speedText.length == 1) {
      return 10.0; // 1 หลัก
    } else if (speedText.length == 2) {
      return 9.0; // 2 หลัก
    } else {
      return 8.0; // 3 หลัก
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 50,
        height: 50,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // วงกลมใหญ่ (พื้นหลังสี) - สีเดียวตามความเร็ว
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getCameraColor(),
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),

            // ไอคอนกล้องด้านหน้าพื้นสี - ตำแหน่งตรงกลางของวงกลม
            Positioned(
              left: 0,
              top: 0,
              width: 40,
              height: 40,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(
                      2), // เพิ่ม padding เพื่อให้เห็นชัดขึ้น
                  child: SvgPicture.asset(
                    'assets/icons/speed_camera_screen/speed camera2.svg',
                    width: 24, // เพิ่มขนาดจาก 22 เป็น 24
                    height: 24, // เพิ่มขนาดจาก 22 เป็น 24
                    colorFilter: const ColorFilter.mode(
                      Colors.white, // ไอคอนสีขาว
                      BlendMode.srcIn,
                    ),
                    // ถ้าโหลดไฟล์ SVG ไม่ได้ จะแสดงไอคอน fallback
                    placeholderBuilder: (context) => const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
            // วงกลมเล็ก (แสดงความเร็ว) - ขยับไปทางขวาล่าง พร้อมขอบสีแดง
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: _getBadgeSize(),
                height: _getBadgeSize(),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.red, width: 1.5), // เพิ่มขอบสีแดง
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '${camera.speedLimit}',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: _getFontSize(),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
