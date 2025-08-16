import 'dart:async';
import 'package:flutter/material.dart';
import '../../../services/sound_manager.dart';
import '../models/speed_camera_model.dart';
import '../services/alert_system.dart';

/// 📢 **Progressive Alert System**
/// ระบบแจ้งเตือนแบบค่อยเป็นค่อยไปตามระยะทาง
/// แยกออกมาเพื่อให้จัดการง่ายและทดสอบได้
class ProgressiveAlertSystem {
  final SoundManager _soundManager;
  final AlertSystem _alertSystem;

  // Progressive beep state
  final Set<String> _alertedCameras = {};
  Timer? _beepTimer;
  SpeedCamera? _currentCamera;
  double _lastBeepDistance = 0.0;
  bool _isActive = false;

  // Timer สำหรับล้างข้อมูลกล้องที่เตือนแล้ว
  Timer? _cleanupTimer;

  ProgressiveAlertSystem(this._soundManager, this._alertSystem) {
    _startCleanupTimer();
  }

  /// เริ่มระบบแจ้งเตือนแบบ Progressive
  void startAlert(SpeedCamera camera, double distance, double currentSpeed) {
    // ตรวจสอบว่าเตือนกล้องนี้แล้วหรือยัง
    if (_alertedCameras.contains(camera.id)) {
      print('=== PROGRESSIVE BEEP SKIPPED ===');
      print('Camera already alerted: ${camera.roadName}');
      print('Distance: ${distance.toInt()}m');
      return;
    }

    // ตรวจสอบว่าเป็นกล้องเดียวกันและระยะใกล้เคียงกันหรือไม่
    if (_currentCamera?.id == camera.id &&
        (distance - _lastBeepDistance).abs() < 5) {
      return; // ไม่ต้องเริ่มใหม่
    }

    // เพิ่มกล้องเข้าลิสต์ที่เตือนแล้ว
    _alertedCameras.add(camera.id);

    // หยุดการแจ้งเตือนเก่า
    _stopAlert();

    // เริ่มการแจ้งเตือนใหม่
    _currentCamera = camera;
    _lastBeepDistance = distance;
    _isActive = true;

    final beepInterval = _calculateBeepInterval(distance);
    if (beepInterval > 0 && currentSpeed > 5.0) {
      print('=== PROGRESSIVE BEEP START ===');
      print('Camera: ${camera.roadName}');
      print('Distance: ${distance.toInt()}m');
      print('Speed: ${currentSpeed.toInt()} km/h');
      print('Beep interval: ${beepInterval}ms');

      // เล่นเสียงทันที
      _playBeep();

      // ตั้ง Timer สำหรับเสียงต่อไป
      _beepTimer = Timer.periodic(
        Duration(milliseconds: beepInterval),
        (_) => _playBeep(),
      );

      // แสดงการแจ้งเตือนใน UI (ใช้ข้อความง่ายๆ ก่อน จนกว่าจะมี context)
      _alertSystem.showAlert(
        '🔴 กล้องข้างหน้า ${distance.toInt()}m',
        const Color(0xFF1158F2),
        beepInterval + 1000,
      );
    }
  }

  /// หยุดการแจ้งเตือน
  void stopAlert() {
    _stopAlert();
  }

  void _stopAlert() {
    if (_isActive) {
      print('=== PROGRESSIVE BEEP STOP ===');
      _beepTimer?.cancel();
      _beepTimer = null;
      _currentCamera = null;
      _lastBeepDistance = 0.0;
      _isActive = false;
    }
  }

  /// เล่นเสียงแจ้งเตือน
  void _playBeep() {
    if (_currentCamera == null || !_isActive) return;
    _soundManager.playProgressiveBeep();
  }

  /// คำนวณช่วงเวลาการแจ้งเตือนตามระยะทาง
  int _calculateBeepInterval(double distance) {
    if (distance <= 10) {
      return 500; // 0.5 วินาที (ติดๆ)
    } else if (distance <= 20) {
      return 1000; // 1 วินาที
    } else if (distance <= 30) {
      return 2000; // 2 วินาที
    } else if (distance <= 50) {
      return 3000; // 3 วินาที
    } else {
      return 0; // ไม่เล่นเสียง
    }
  }

  /// รีเซ็ตกล้องที่เตือนแล้วเมื่อห่างเกิน 100 เมตร
  void resetAlertedCamerasIfFar(List<SpeedCamera> nearbyCameras) {
    final removedCount = _alertedCameras.length;
    _alertedCameras.removeWhere((cameraId) {
      // หากล้องไม่อยู่ในรายการใกล้เคียง (100m) ให้ลบออก
      return !nearbyCameras.any((camera) => camera.id == cameraId);
    });

    if (removedCount != _alertedCameras.length) {
      print('=== CAMERA RESET BY DISTANCE ===');
      print(
          'Removed ${removedCount - _alertedCameras.length} cameras from alerted list');
      print('Remaining alerted cameras: ${_alertedCameras.length}');
    }
  }

  /// เริ่ม Timer สำหรับล้างข้อมูลทุก 5 นาที
  void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      final oldSize = _alertedCameras.length;
      _alertedCameras.clear();

      print('=== CAMERA CLEANUP ===');
      print('Cleared $oldSize alerted cameras');
      print('Progressive Beep system reset');
      print('=====================');
    });
  }

  /// ตรวจสอบสถานะระบบ
  bool get isActive => _isActive;
  SpeedCamera? get currentCamera => _currentCamera;
  int get alertedCamerasCount => _alertedCameras.length;

  /// รีเซ็ตระบบทั้งหมด
  void reset() {
    _stopAlert();
    _alertedCameras.clear();
  }

  /// ทำความสะอาดทรัพยากร
  void dispose() {
    _stopAlert();
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    _alertedCameras.clear();
  }
}
