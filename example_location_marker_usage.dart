// ตัวอย่างการใช้งาน LocationMarker แบบ Petal Maps/Google Maps
import 'package:flutter/material.dart';
import 'widgets/location_marker.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Location Marker Demo',
      home: LocationMarkerDemo(),
    );
  }
}

class LocationMarkerDemo extends StatefulWidget {
  @override
  _LocationMarkerDemoState createState() => _LocationMarkerDemoState();
}

class _LocationMarkerDemoState extends State<LocationMarkerDemo>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  double _currentRotation = 0;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 4),
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
        title: Text('Location Marker Examples'),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // 1. หมุดปกติไม่มีทิศทาง
            Column(
              children: [
                Text('หมุดตำแหน่งปกติ', style: TextStyle(fontSize: 16)),
                SizedBox(height: 10),
                Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey[100],
                  child: Center(
                    child: LocationMarker(
                      scale: 1.0,
                      showDirectionPointer: false,
                    ),
                  ),
                ),
              ],
            ),

            // 2. หมุดมีทิศทางคงที่
            Column(
              children: [
                Text('หมุดมีทิศทาง (45°)', style: TextStyle(fontSize: 16)),
                SizedBox(height: 10),
                Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey[100],
                  child: Center(
                    child: LocationMarker(
                      scale: 1.0,
                      rotation: 45,
                      showDirectionPointer: true,
                    ),
                  ),
                ),
              ],
            ),

            // 3. หมุดหมุนแบบ animated
            Column(
              children: [
                Text('หมุดหมุนตามทิศทาง', style: TextStyle(fontSize: 16)),
                SizedBox(height: 10),
                Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey[100],
                  child: Center(
                    child: LocationMarker(
                      scale: 1.2,
                      rotation: _currentRotation,
                      showDirectionPointer: true,
                    ),
                  ),
                ),
              ],
            ),

            // 4. หมุดขนาดใหญ่
            Column(
              children: [
                Text('หมุดขนาดใหญ่', style: TextStyle(fontSize: 16)),
                SizedBox(height: 10),
                Container(
                  width: 120,
                  height: 120,
                  color: Colors.grey[100],
                  child: Center(
                    child: LocationMarker(
                      scale: 2.0,
                      rotation: 90,
                      showDirectionPointer: true,
                    ),
                  ),
                ),
              ],
            ),

            // 5. หมุดแบบเก่า (สำหรับเปรียบเทียบ)
            Column(
              children: [
                Text('หมุดแบบเก่า', style: TextStyle(fontSize: 16)),
                SizedBox(height: 10),
                Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey[100],
                  child: Center(
                    child: LegacyLocationMarker(scale: 1.6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/* 
การใช้งานใน map_screen.dart:

// แทนที่
child: const LocationMarker(scale: 1.68),

// ด้วย
child: LocationMarker(
  scale: 1.2,
  rotation: deviceHeading, // ได้จาก compass sensor
  showDirectionPointer: true,
),

หรือถ้าไม่ต้องการทิศทาง:
child: LocationMarker(
  scale: 1.0,
  showDirectionPointer: false,
),
*/
