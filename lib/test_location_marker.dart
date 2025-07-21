import 'package:flutter/material.dart';
import '../widgets/location_marker.dart';

// ตัวอย่างการใช้งาน LocationMarker เพื่อทดสอบสามเหลี่ยม
class LocationMarkerTestPage extends StatefulWidget {
  const LocationMarkerTestPage({super.key});

  @override
  State<LocationMarkerTestPage> createState() => _LocationMarkerTestPageState();
}

class _LocationMarkerTestPageState extends State<LocationMarkerTestPage>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  double _currentRotation = 0;
  bool _showPointer = true;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    _rotationController.addListener(() {
      setState(() {
        _currentRotation = _rotationController.value * 360;
      });
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Location Marker'),
        backgroundColor: const Color(0xFF0C59F7),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // สลับเปิด/ปิดสามเหลี่ยม
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('แสดงสามเหลี่ยม: '),
                Switch(
                  value: _showPointer,
                  onChanged: (value) {
                    setState(() {
                      _showPointer = value;
                    });
                  },
                ),
              ],
            ),

            // หมุดตำแหน่งปกติ (ไม่มีทิศทาง)
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border.all(color: Colors.grey),
              ),
              child: const Center(
                child: LocationMarker(
                  scale: 1.5,
                  showDirectionPointer: false,
                ),
              ),
            ),

            // หมุดมีทิศทาง (คงที่)
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border.all(color: Colors.grey),
              ),
              child: Center(
                child: LocationMarker(
                  scale: 1.5,
                  rotation: 45,
                  showDirectionPointer: _showPointer,
                ),
              ),
            ),

            // หมุดหมุนตามทิศทาง (animation)
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border.all(color: Colors.grey),
              ),
              child: Center(
                child: LocationMarker(
                  scale: 1.5,
                  rotation: _currentRotation,
                  showDirectionPointer: _showPointer,
                ),
              ),
            ),

            // ข้อมูลการหมุน
            Text(
              'Rotation: ${_currentRotation.toStringAsFixed(1)}°',
              style: const TextStyle(fontSize: 16),
            ),

            // คำแนะนำ
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'หมุดบน: ไม่มีทิศทาง\n'
                'หมุดกลาง: ทิศทาง 45°\n'
                'หมุดล่าง: หมุนอัตโนมัติ\n\n'
                'ใช้ Switch เพื่อเปิด/ปิดสามเหลี่ยม',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
