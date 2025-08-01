import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/speed_camera_model.dart';

class SpeedCameraMarker extends StatelessWidget {
  final SpeedCamera camera;
  final VoidCallback? onTap;
  final bool isSelected;

  const SpeedCameraMarker({
    Key? key,
    required this.camera,
    this.onTap,
    this.isSelected = false,
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
        width: 60,
        height: 60,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // วงกลมใหญ่ (พื้นหลังสี) - สีเดียวตามความเร็ว
            Positioned(
              left: 10,
              top: 10,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color:
                      isSelected ? const Color(0xFF1158F2) : _getCameraColor(),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/icons/speed_camera_screen/speed camera2.svg',
                    width: 20,
                    height: 20,
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                    placeholderBuilder: (context) => const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),

            // วงกลมเล็ก (แสดงความเร็ว) - ขยับไปทางขวาล่าง พร้อมขอบสีแดง
            Positioned(
              left:
                  38, // 10 (left ของวงกลมใหญ่) + 40 (ความกว้างวงกลมใหญ่) - 10 (ครึ่งหนึ่งของวงกลมเล็ก)
              top:
                  30, // 10 (top ของวงกลมใหญ่) + 40 (ความสูงวงกลมใหญ่) - 10 (ครึ่งหนึ่งของวงกลมเล็ก)
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
