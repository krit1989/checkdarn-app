import 'package:flutter_test/flutter_test.dart';
import '../utils/speed_camera_logic.dart';

void main() {
  group('SpeedCameraLogic.optimalAlertDistance', () {
    test('should clamp to minimum 200m and maximum 1000m', () {
      // ความเร็วต่ำมาก ควรได้ระยะขั้นต่ำ
      expect(SpeedCameraLogic.optimalAlertDistance(0), 200);
      expect(SpeedCameraLogic.optimalAlertDistance(15), 200);

      // ความเร็วอ้างอิง 100 km/h ควรได้ 800m
      expect(SpeedCameraLogic.optimalAlertDistance(100), 800);

      // ความเร็วสูงมาก ควรได้ระยะสูงสุด 1000m
      expect(SpeedCameraLogic.optimalAlertDistance(400), 1000);
    });

    test('should increase monotonically with speed', () {
      final d50 = SpeedCameraLogic.optimalAlertDistance(50);
      final d80 = SpeedCameraLogic.optimalAlertDistance(80);
      final d120 = SpeedCameraLogic.optimalAlertDistance(120);

      // ระยะควรเพิ่มขึ้นตามความเร็ว
      expect(d50 <= d80 && d80 <= d120, true,
          reason:
              'Alert distance should increase with speed: $d50 <= $d80 <= $d120');
    });

    test('should follow quadratic formula', () {
      // ทดสอบสูตร: (speed/100)² × 800
      final result60 = SpeedCameraLogic.optimalAlertDistance(60);
      final expected60 = (60 / 100) * (60 / 100) * 800; // = 288
      expect(result60, closeTo(expected60, 1));
    });
  });

  group('SpeedCameraLogic.isCameraAhead', () {
    test('should return true when camera is within ±45°', () {
      // กล้องอยู่ภายในมุม ±45°
      expect(SpeedCameraLogic.isCameraAhead(10, 40), true);
      expect(
          SpeedCameraLogic.isCameraAhead(10, 350), true); // 350° = -10° จาก 0°
    });

    test('should return false when camera is outside ±45°', () {
      // กล้องอยู่นอกมุม ±45°
      expect(SpeedCameraLogic.isCameraAhead(0, 90), false); // 90° difference
      expect(SpeedCameraLogic.isCameraAhead(180, 90), false); // 90° difference
      expect(SpeedCameraLogic.isCameraAhead(0, 270),
          false); // 90° difference (or -90°)
    });

    test('should handle edge cases correctly', () {
      // ขอบเขตที่ 45° พอดี
      expect(SpeedCameraLogic.isCameraAhead(0, 45), true); // exactly 45°
      expect(SpeedCameraLogic.isCameraAhead(0, 315), true); // exactly -45°

      // ขอบเขตที่เกิน 45°
      expect(SpeedCameraLogic.isCameraAhead(0, 46), false); // 46° (just over)
    });
  });

  group('SpeedCameraLogic.beepIntervalMs', () {
    test('should return correct intervals for different distances', () {
      expect(SpeedCameraLogic.beepIntervalMs(5), 500); // ≤10m
      expect(SpeedCameraLogic.beepIntervalMs(10), 500); // ≤10m
      expect(SpeedCameraLogic.beepIntervalMs(15), 1000); // ≤20m
      expect(SpeedCameraLogic.beepIntervalMs(20), 1000); // ≤20m
      expect(SpeedCameraLogic.beepIntervalMs(25), 2000); // ≤30m
      expect(SpeedCameraLogic.beepIntervalMs(30), 2000); // ≤30m
      expect(SpeedCameraLogic.beepIntervalMs(40), 3000); // ≤50m
      expect(SpeedCameraLogic.beepIntervalMs(50), 3000); // ≤50m
      expect(SpeedCameraLogic.beepIntervalMs(51), 0); // >50m = no beep
      expect(SpeedCameraLogic.beepIntervalMs(100), 0); // >50m = no beep
    });

    test('should increase intervals as distance increases', () {
      final far = SpeedCameraLogic.beepIntervalMs(45); // 3000ms
      final medium = SpeedCameraLogic.beepIntervalMs(25); // 2000ms
      final close = SpeedCameraLogic.beepIntervalMs(15); // 1000ms
      final veryClose = SpeedCameraLogic.beepIntervalMs(5); // 500ms

      // ระยะไกลขึ้น = ช่วงเวลาเสียงยาวขึ้น (เสียงช้าลง)
      expect(veryClose < close && close < medium && medium < far, true,
          reason:
              'Beep should be faster when closer: $veryClose < $close < $medium < $far');
    });
  });

  group('SpeedCameraLogic.smoothHeading', () {
    test('should smooth small heading changes', () {
      final result = SpeedCameraLogic.smoothHeading(0, 10, 50);
      expect(result, greaterThan(0));
      expect(result, lessThan(10));
    });

    test('should handle wrap-around from 350° to 10°', () {
      final result = SpeedCameraLogic.smoothHeading(350, 10, 50);
      expect(result, anyOf(greaterThan(350), lessThan(30)));
    });

    test('should be more responsive at higher speeds', () {
      final slowResult = SpeedCameraLogic.smoothHeading(0, 10, 20);
      final fastResult = SpeedCameraLogic.smoothHeading(0, 10, 80);

      // ความเร็วสูง = การตอบสนองสูง = ค่าใกล้เคียงกับ newHeading มากกว่า
      expect(fastResult, greaterThan(slowResult));
    });

    test('should normalize output to 0-360 range', () {
      final smallAngleResult = SpeedCameraLogic.smoothHeading(0, 350, 50);
      expect(smallAngleResult, greaterThanOrEqualTo(0));
      expect(smallAngleResult, lessThan(360));

      final largeAngleResult = SpeedCameraLogic.smoothHeading(350, 10, 50);
      expect(largeAngleResult, greaterThanOrEqualTo(0));
      expect(largeAngleResult, lessThan(360));
    });

    test('edge case: 차이가 180도를 넘나드는 경우', () {
      for (double speed in [10, 30, 50, 80, 100]) {
        final result = SpeedCameraLogic.smoothHeading(10, 200, speed);

        expect(result, greaterThanOrEqualTo(0));
        expect(result, lessThan(360));
      }
    });
  });
}
