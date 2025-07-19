import 'package:flutter/material.dart';
import '../utils/constants.dart';

class MapPinIcon extends StatelessWidget {
  final String category;
  final bool isVerified;
  final double size;

  const MapPinIcon({
    super.key,
    required this.category,
    this.isVerified = false,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    final categoryIcon =
        EventCategory.categoryIcons[category] ?? Icons.help_outline;
    final categoryColor =
        EventCategory.categoryColors[category] ?? AppColors.primary;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: categoryColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Main category icon
          Center(
            child: Icon(categoryIcon, size: size * 0.5, color: Colors.white),
          ),

          // Verification badge
          if (isVerified)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: size * 0.3,
                height: size * 0.3,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check, size: size * 0.2, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

class CustomMapPin extends StatelessWidget {
  final String category;
  final bool isVerified;
  final int verificationCount;
  final VoidCallback? onTap;

  const CustomMapPin({
    super.key,
    required this.category,
    this.isVerified = false,
    this.verificationCount = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final categoryIcon =
        EventCategory.categoryIcons[category] ?? Icons.help_outline;
    final categoryColor =
        EventCategory.categoryColors[category] ?? AppColors.primary;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pin head
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: categoryColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Category icon
                Center(
                  child: Icon(categoryIcon, size: 20, color: Colors.white),
                ),

                // Verification badge
                if (isVerified)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 8,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Pin tail
          Container(width: 2, height: 8, color: categoryColor),

          // Verification count badge
          if (verificationCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                verificationCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class AnimatedMapPin extends StatefulWidget {
  final String category;
  final bool isVerified;
  final bool isSelected;
  final VoidCallback? onTap;

  const AnimatedMapPin({
    super.key,
    required this.category,
    this.isVerified = false,
    this.isSelected = false,
    this.onTap,
  });

  @override
  State<AnimatedMapPin> createState() => _AnimatedMapPinState();
}

class _AnimatedMapPinState extends State<AnimatedMapPin>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    if (widget.isSelected) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(AnimatedMapPin oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _animationController.repeat(reverse: true);
      } else {
        _animationController.stop();
        _animationController.reset();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isSelected ? _scaleAnimation.value : 1.0,
          child: Opacity(
            opacity: widget.isSelected ? _pulseAnimation.value : 1.0,
            child: CustomMapPin(
              category: widget.category,
              isVerified: widget.isVerified,
              onTap: widget.onTap,
            ),
          ),
        );
      },
    );
  }
}
