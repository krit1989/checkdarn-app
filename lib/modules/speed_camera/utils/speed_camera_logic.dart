import 'dart:math' as math;

/// Logic utilities for Speed Camera functionality
class SpeedCameraLogic {
  /// Calculate optimal alert distance based on current speed
  /// Formula: (speed/100)² × 800, clamped between 200m and 1000m
  static int optimalAlertDistance(int speed) {
    if (speed <= 0) return 200;
    if (speed >= 400) return 1000;

    // Quadratic formula: (speed/100)² × 800
    final normalized = speed / 100.0;
    final distance = (normalized * normalized * 800).round();

    // Clamp between 200m and 1000m
    return math.max(200, math.min(1000, distance));
  }

  /// Check if camera is ahead based on bearing difference
  static bool isCameraAhead(double userBearing, double cameraBearing,
      {double tolerance = 45.0}) {
    // Calculate bearing difference
    double diff = (cameraBearing - userBearing).abs();
    if (diff > 180) {
      diff = 360 - diff;
    }

    // Camera is ahead if bearing difference is within tolerance
    return diff <= tolerance;
  }

  /// Calculate beep interval based on distance to camera
  static int beepIntervalMs(double distanceMeters) {
    if (distanceMeters <= 10) return 500; // Very close: beep every 500ms
    if (distanceMeters <= 20) return 1000; // Close: beep every 1s
    if (distanceMeters <= 30) return 2000; // Medium: beep every 2s
    if (distanceMeters <= 50) return 3000; // Far: beep every 3s
    return 0; // Too far: no beep
  }

  /// Smooth heading changes to prevent jittery compass behavior
  static double smoothHeading(
      double currentHeading, double newHeading, double speed) {
    // Higher speed = more smoothing to account for GPS jitter
    final smoothingFactor = math.min(0.9, speed / 100.0 * 0.8 + 0.1);

    // Handle circular nature of bearing (0° = 360°)
    double diff = newHeading - currentHeading;
    if (diff > 180) {
      diff -= 360;
    } else if (diff < -180) {
      diff += 360;
    }

    // Apply smoothing
    double smoothedHeading = currentHeading + (diff * (1 - smoothingFactor));

    // Normalize to 0-360 range
    if (smoothedHeading < 0) {
      smoothedHeading += 360;
    } else if (smoothedHeading >= 360) {
      smoothedHeading -= 360;
    }

    return smoothedHeading;
  }
}
