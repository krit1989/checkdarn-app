import 'package:flutter/material.dart';

// Widget ปุ่มค้นหาตำแหน่งปัจจุบัน
class LocationButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;
  final double size;
  final Color backgroundColor;
  final Color iconColor;
  final IconData icon;
  final String? tooltip;

  const LocationButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.size = 45,
    this.backgroundColor = Colors.white,
    this.iconColor = const Color(0xFF4673E5),
    this.icon = Icons.my_location,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final button = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? SizedBox(
                width: size * 0.5,
                height: size * 0.5,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                ),
              )
            : Icon(
                icon,
                color: iconColor,
                size: size * 0.5,
              ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip!,
        child: button,
      );
    }

    return button;
  }
}
