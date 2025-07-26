import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/speed_camera_model.dart';

class SpeedCameraMarker extends StatelessWidget {
  final SpeedCamera camera;
  final bool isNearby;

  const SpeedCameraMarker({
    super.key,
    required this.camera,
    this.isNearby = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showCameraDetails(context),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle with animation for nearby cameras
          if (isNearby)
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.withValues(alpha: 0.2),
                border: Border.all(
                  color: Colors.red,
                  width: 2,
                ),
              ),
            ),

          // Main camera icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getCameraColor(),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: SvgPicture.asset(
                'assets/icons/speed_camera_screen/speed_camera.svg',
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),

          // Speed limit badge
          Positioned(
            bottom: -2,
            right: -2,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: _getSpeedLimitColor(),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1),
              ),
              child: Center(
                child: Text(
                  '${camera.speedLimit}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Kanit',
                  ),
                ),
              ),
            ),
          ),

          // Warning pulse animation for very close cameras
          if (isNearby)
            Positioned.fill(
              child: _buildPulseAnimation(),
            ),
        ],
      ),
    );
  }

  Color _getCameraColor() {
    if (!camera.isActive) return Colors.grey;

    switch (camera.type) {
      case CameraType.fixed:
        return Colors.blue;
      case CameraType.mobile:
        return Colors.orange;
      case CameraType.average:
        return Colors.purple;
      case CameraType.redLight:
        return Colors.red;
    }
  }

  Color _getSpeedLimitColor() {
    if (camera.speedLimit <= 60) return Colors.red;
    if (camera.speedLimit <= 90) return Colors.orange;
    return Colors.green;
  }

  Widget _buildPulseAnimation() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(seconds: 1),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.red.withValues(alpha: 1.0 - value),
              width: 3 * value,
            ),
          ),
        );
      },
      onEnd: () {
        // Restart animation if still nearby
        if (isNearby) {
          // Will rebuild and restart
        }
      },
    );
  }

  void _showCameraDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Camera type icon and name
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _getCameraColor(),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      camera.type.emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        camera.type.displayName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Kanit',
                        ),
                      ),
                      Text(
                        camera.roadName,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontFamily: 'Kanit',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Speed limit
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getSpeedLimitColor().withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getSpeedLimitColor().withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.speed,
                    color: _getSpeedLimitColor(),
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ขีดจำกัดความเร็ว',
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Kanit',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${camera.speedLimit} กม./ชม.',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _getSpeedLimitColor(),
                          fontFamily: 'Kanit',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Description if available
            if (camera.description != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        camera.description!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                          fontFamily: 'Kanit',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Status
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: camera.isActive ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  camera.isActive ? 'ทำงานปกติ' : 'ไม่ทำงาน',
                  style: TextStyle(
                    fontSize: 14,
                    color: camera.isActive ? Colors.green : Colors.red,
                    fontFamily: 'Kanit',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
