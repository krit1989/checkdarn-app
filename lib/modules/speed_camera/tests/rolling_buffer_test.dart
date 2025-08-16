import 'package:flutter_test/flutter_test.dart';
import '../utils/rolling_buffer.dart';

void main() {
  group('RollingBuffer Tests', () {
    test('should create empty buffer with correct capacity', () {
      final buffer = RollingBuffer<int>(5);

      expect(buffer.length, 0);
      expect(buffer.capacity, 5);
      expect(buffer.isEmpty, true);
      expect(buffer.isNotEmpty, false);
      expect(buffer.isFull, false);
    });

    test('should add items without overflow', () {
      final buffer = RollingBuffer<int>(3);

      buffer.push(1);
      buffer.push(2);
      buffer.push(3);

      expect(buffer.length, 3);
      expect(buffer.toList(), [1, 2, 3]);
      expect(buffer.isFull, true);
      expect(buffer.firstOrNull, 1);
      expect(buffer.lastOrNull, 3);
    });

    test('should auto-remove oldest when capacity exceeded', () {
      final buffer = RollingBuffer<int>(3);

      // เติมให้เต็ม
      buffer.push(1);
      buffer.push(2);
      buffer.push(3);
      expect(buffer.toList(), [1, 2, 3]);

      // overflow → ลบ 1 ออก, เพิ่ม 4
      buffer.push(4);
      expect(buffer.toList(), [2, 3, 4]);
      expect(buffer.length, 3);

      // overflow อีกครั้ง → ลบ 2 ออก, เพิ่ม 5
      buffer.push(5);
      expect(buffer.toList(), [3, 4, 5]);
      expect(buffer.length, 3);
    });

    test('should return correct last N items', () {
      final buffer = RollingBuffer<int>(5);

      buffer.push(10);
      buffer.push(20);
      buffer.push(30);
      buffer.push(40);
      buffer.push(50);

      // ขอ 2 ตัวสุดท้าย
      expect(buffer.last(2).toList(), [40, 50]);

      // ขอ 3 ตัวสุดท้าย
      expect(buffer.last(3).toList(), [30, 40, 50]);

      // ขอมากกว่าที่มี → ได้ทั้งหมด
      expect(buffer.last(10).toList(), [10, 20, 30, 40, 50]);

      // ขอ 0 → ได้ว่าง
      expect(buffer.last(0).toList(), []);

      // ขอติดลบ → ได้ว่าง
      expect(buffer.last(-1).toList(), []);
    });

    test('should handle indexing correctly', () {
      final buffer = RollingBuffer<String>(3);

      buffer.push('A');
      buffer.push('B');
      buffer.push('C');

      expect(buffer[0], 'A'); // เก่าสุด
      expect(buffer[1], 'B');
      expect(buffer[2], 'C'); // ใหม่สุด
    });

    test('should handle clear operation', () {
      final buffer = RollingBuffer<int>(3);

      buffer.push(1);
      buffer.push(2);
      buffer.push(3);
      expect(buffer.length, 3);

      buffer.clear();
      expect(buffer.length, 0);
      expect(buffer.isEmpty, true);
      expect(buffer.firstOrNull, null);
      expect(buffer.lastOrNull, null);
    });

    test('should handle forEach iteration', () {
      final buffer = RollingBuffer<int>(3);
      buffer.push(10);
      buffer.push(20);
      buffer.push(30);

      final collected = <int>[];
      buffer.forEach(collected.add);

      expect(collected, [10, 20, 30]);
    });

    test('should work with different data types', () {
      final stringBuffer = RollingBuffer<String>(2);
      final doubleBuffer = RollingBuffer<double>(2);

      stringBuffer.push('hello');
      stringBuffer.push('world');
      stringBuffer.push('test'); // 'hello' ถูกลบ

      expect(stringBuffer.toList(), ['world', 'test']);

      doubleBuffer.push(1.5);
      doubleBuffer.push(2.5);
      doubleBuffer.push(3.5); // 1.5 ถูกลบ

      expect(doubleBuffer.toList(), [2.5, 3.5]);
    });
  });

  group('PositionHistory Tests', () {
    test('should create with default capacity', () {
      final history = PositionHistory<int>();

      expect(history.capacity, 60);
      expect(history.isEmpty, true);
    });

    test('should create with custom capacity', () {
      final history = PositionHistory<int>(capacity: 100);

      expect(history.capacity, 100);
    });

    test('should return recent positions correctly', () {
      final history = PositionHistory<int>();

      // เพิ่มข้อมูล 5 ตำแหน่ง
      for (int i = 1; i <= 5; i++) {
        history.push(i);
      }

      // ขอ 3 ตัวล่าสุด (default)
      expect(history.getRecentPositions(), [3, 4, 5]);

      // ขอ 2 ตัวล่าสุด
      expect(history.getRecentPositions(2), [4, 5]);

      // ขอมากกว่าที่มี
      expect(history.getRecentPositions(10), [1, 2, 3, 4, 5]);
    });

    test('should handle insufficient data', () {
      final history = PositionHistory<int>();

      // ยังไม่มีข้อมูล
      expect(history.hasEnoughData(), false);
      expect(history.getRecentPositions(), []);

      // มี 2 ตำแหน่ง (น้อยกว่า 3)
      history.push(1);
      history.push(2);
      expect(history.hasEnoughData(), false);
      expect(history.getRecentPositions(), [1, 2]);

      // มี 3 ตำแหน่งแล้ว
      history.push(3);
      expect(history.hasEnoughData(), true);
      expect(history.getRecentPositions(), [1, 2, 3]);
    });
  });

  group('SpeedHistory Tests', () {
    test('should create with default capacity', () {
      final history = SpeedHistory<double>();

      expect(history.capacity, 120);
      expect(history.isEmpty, true);
    });

    test('should create with custom capacity', () {
      final history = SpeedHistory<double>(capacity: 200);

      expect(history.capacity, 200);
    });

    test('should return recent speeds correctly', () {
      final history = SpeedHistory<double>();

      // เพิ่มข้อมูล 15 ความเร็ว
      for (int i = 1; i <= 15; i++) {
        history.push(i.toDouble());
      }

      // ขอ 10 ตัวล่าสุด (default)
      expect(history.getRecentSpeeds(), [6, 7, 8, 9, 10, 11, 12, 13, 14, 15]);

      // ขอ 5 ตัวล่าสุด
      expect(history.getRecentSpeeds(5), [11, 12, 13, 14, 15]);

      // ขอมากกว่าที่มี
      final allSpeeds = List.generate(15, (i) => (i + 1).toDouble());
      expect(history.getRecentSpeeds(20), allSpeeds);
    });

    test('should handle analysis data requirements', () {
      final history = SpeedHistory<double>();

      // ยังไม่มีข้อมูล
      expect(history.hasEnoughDataForAnalysis(), false);

      // มี 3 ความเร็ว (น้อยกว่า 5)
      history.push(10.0);
      history.push(20.0);
      history.push(30.0);
      expect(history.hasEnoughDataForAnalysis(), false);

      // มี 5 ความเร็วแล้ว
      history.push(40.0);
      history.push(50.0);
      expect(history.hasEnoughDataForAnalysis(), true);

      // ตรวจสอบกับเงื่อนไขที่กำหนดเอง
      expect(history.hasEnoughDataForAnalysis(3), true);
      expect(history.hasEnoughDataForAnalysis(10), false);
    });
  });

  group('Performance & Memory Tests', () {
    test('should maintain constant time operations', () {
      final buffer = RollingBuffer<int>(1000);

      // เติมให้เต็ม
      for (int i = 0; i < 1000; i++) {
        buffer.push(i);
      }
      expect(buffer.isFull, true);

      // ทดสอบ overflow performance
      final stopwatch = Stopwatch()..start();

      for (int i = 1000; i < 2000; i++) {
        buffer.push(i); // ควรเป็น O(1) ทุกครั้ง
      }

      stopwatch.stop();

      // ตรวจสอบว่ายังคงมี 1000 รายการ
      expect(buffer.length, 1000);

      // ตรวจสอบว่าข้อมูลถูกต้อง (1000-1999)
      expect(buffer.firstOrNull, 1000);
      expect(buffer.lastOrNull, 1999);

      // ตรวจสอบ performance (ควรเร็วมาก)
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });

    test('should not grow beyond capacity', () {
      final buffer = RollingBuffer<String>(5);

      // เพิ่มข้อมูลมากกว่าความจุ
      for (int i = 0; i < 100; i++) {
        buffer.push('item_$i');
      }

      // ตรวจสอบว่าไม่เกินความจุ
      expect(buffer.length, 5);
      expect(buffer.capacity, 5);

      // ตรวจสอบว่าเก็บ 5 รายการสุดท้าย
      expect(buffer.toList(),
          ['item_95', 'item_96', 'item_97', 'item_98', 'item_99']);
    });
  });
}
