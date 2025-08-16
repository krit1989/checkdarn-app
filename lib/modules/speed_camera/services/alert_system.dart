import 'dart:async';
import 'package:flutter/material.dart';
import '../../../generated/gen_l10n/app_localizations.dart';
import '../../../services/sound_manager.dart';

/// 🔔 **Alert System**
/// ระบบแจ้งเตือนที่แยกออกมาจาก SpeedCameraScreen
/// เพื่อให้โค้ดสะอาดและง่ายต่อการบำรุงรักษา
class AlertSystem {
  final SoundManager _soundManager;

  // Badge state
  String _badgeText = 'Speed Camera';
  Color _badgeColor = const Color(0xFFFFC107);
  Timer? _badgeResetTimer;

  // Callbacks สำหรับการอัปเดต UI
  final VoidCallback? onBadgeUpdate;

  AlertSystem(this._soundManager, {this.onBadgeUpdate});

  // Getters สำหรับ UI
  String get badgeText => _badgeText;
  Color get badgeColor => _badgeColor;

  /// แสดงการแจ้งเตือนทั่วไป
  void showAlert(String message, Color color, int durationMs) {
    _badgeResetTimer?.cancel();

    _badgeText = message;
    _badgeColor = color;

    // แจ้งให้ UI อัปเดท
    onBadgeUpdate?.call();

    // ตั้งเวลากลับเป็นค่าเริ่มต้น
    _badgeResetTimer = Timer(Duration(milliseconds: durationMs), () {
      _badgeText = 'Speed Camera';
      _badgeColor = const Color(0xFFFFC107);
      onBadgeUpdate?.call();
    });
  }

  /// แจ้งเตือนความเร็วเกิน
  void showSpeedAlert(
      double currentSpeed, int speedLimit, AppLocalizations localizations) {
    final excessSpeed = (currentSpeed - speedLimit).toInt();
    final message = localizations.badgeExceedingSpeed(excessSpeed);

    _soundManager.playSpeedAlert(
      message: 'เร็วเกิน $excessSpeed กิโลเมตรต่อชั่วโมง',
      currentSpeed: currentSpeed.toInt(),
      speedLimit: speedLimit,
    );

    showAlert(message, Colors.orange, 5000);
  }

  /// แจ้งเตือนใกล้กล้อง
  void showProximityAlert(double distance, AppLocalizations localizations) {
    final distanceInt = distance.toInt();
    final message = localizations.badgeCameraAhead(distanceInt);

    _soundManager.playProximityAlert(
      message: 'กล้องจับความเร็วข้างหน้า $distanceInt เมตร',
      distance: distance,
    );

    showAlert(message, Colors.orange, 4000);
  }

  /// แจ้งเตือนใกล้กล้องมาก - ให้ลดความเร็ว
  void showCloseProximityAlert(
      bool isOverSpeed, AppLocalizations localizations) {
    if (isOverSpeed) {
      _soundManager.playProximityAlert(
        message: 'อยู่ใกล้กล้องจับความเร็ว โปรดลดความเร็ว',
        distance: 50.0,
      );
      showAlert(localizations.badgeNearCameraReduceSpeed, Colors.orange, 5000);
    } else {
      _soundManager.playProximityAlert(
        message: 'อยู่ใกล้กล้องจับความเร็ว ความเร็วเหมาะสม',
        distance: 50.0,
      );
      showAlert(localizations.badgeNearCameraGoodSpeed, Colors.green, 4000);
    }
  }

  /// แจ้งเตือนการตรวจจับด้วย radar
  void showRadarDetection(int distance, AppLocalizations localizations) {
    showAlert(
      localizations.badgeRadarDetection(distance),
      const Color(0xFF1158F2),
      2000,
    );
  }

  /// แจ้งเตือนการทำนายล่วงหน้า
  void showPredictiveAlert(AppLocalizations localizations) {
    showAlert(
      localizations.badgePredictedCameraAhead,
      const Color(0xFF1158F2),
      6000,
    );
  }

  /// แจ้งเตือนการอัปเดทข้อมูล
  void showDataUpdateAlert(String message, {bool isSuccess = true}) {
    final color = isSuccess ? Colors.green : Colors.orange;
    showAlert(message, color, 3000);
  }

  /// แจ้งเตือนเบาๆ สำหรับการอัปเดทในพื้นหลัง
  void showSubtleUpdateNotification() {
    showAlert(
      '📡 ข้อมูลอัพเดทแล้ว',
      Colors.blue.withOpacity(0.8),
      2000,
    );
  }

  /// แจ้งเตือนความผิดปกติด้านความปลอดภัย
  void showSecurityAlert(String message, {bool isCritical = false}) {
    final color = isCritical ? Colors.red : Colors.orange;
    final duration = isCritical ? 10000 : 5000;
    showAlert(message, color, duration);
  }

  /// รีเซ็ตระบบแจ้งเตือน
  void reset() {
    _badgeResetTimer?.cancel();
    _badgeText = 'Speed Camera';
    _badgeColor = const Color(0xFFFFC107);
    onBadgeUpdate?.call();
  }

  /// ทำความสะอาดทรัพยากร
  void dispose() {
    _badgeResetTimer?.cancel();
    _badgeResetTimer = null;
  }
}
