import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../models/speed_camera_model.dart';
import '../services/speed_camera_service.dart';
import '../widgets/speed_camera_marker.dart';

class CameraSelectionMapWidget extends StatefulWidget {
  final LatLng? initialCenter;
  final SpeedCamera? selectedCamera;
  final Function(SpeedCamera camera) onCameraSelected;

  const CameraSelectionMapWidget({
    super.key,
    this.initialCenter,
    this.selectedCamera,
    required this.onCameraSelected,
  });

  @override
  State<CameraSelectionMapWidget> createState() =>
      _CameraSelectionMapWidgetState();
}

class _CameraSelectionMapWidgetState extends State<CameraSelectionMapWidget> {
  late MapController _mapController;
  List<SpeedCamera> _cameras = [];
  bool _isLoading = true;
  LatLng _center = const LatLng(13.7563, 100.5018); // Default Bangkok
  SpeedCamera? _selectedCamera;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _selectedCamera = widget.selectedCamera;

    if (widget.initialCenter != null) {
      _center = widget.initialCenter!;
    }

    _loadCameras();

    // โหลดข้อมูลตำแหน่งปัจจุบัน
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getCurrentLocation();
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      // แสดง loading
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'กำลังหาตำแหน่งปัจจุบัน...',
            style: TextStyle(fontFamily: 'NotoSansThai'),
          ),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );

      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final newPermission = await Geolocator.requestPermission();
        if (newPermission == LocationPermission.denied ||
            newPermission == LocationPermission.deniedForever) {
          throw Exception('ไม่อนุญาตให้เข้าถึงตำแหน่ง');
        }
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      setState(() {
        _center = LatLng(position.latitude, position.longitude);
      });

      if (mounted) {
        // เด้งมาที่ตำแหน่งตัวเองทันที
        _mapController.move(_center, 14.0); // ลดลงจาก 16.0
      }
    } catch (e) {
      print('Error getting location: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ไม่สามารถหาตำแหน่งได้: ${e.toString()}',
              style: const TextStyle(fontFamily: 'NotoSansThai'),
            ),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
            margin: const EdgeInsets.only(bottom: 200, left: 16, right: 16),
          ),
        );
      }
    }
  }

  Future<void> _loadCameras() async {
    try {
      final cameras = await SpeedCameraService.getSpeedCameras();
      setState(() {
        _cameras = cameras;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading cameras: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onCameraTap(SpeedCamera camera) {
    setState(() {
      _selectedCamera = camera;
    });

    // ซูมและเลื่อนแผนที่ให้กล้องอยู่กลางจอ
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(
      camera.location,
      currentZoom.clamp(14.0, 16.0), // จำกัดระดับซูม
    );

    // เรียก callback ทันที
    widget.onCameraSelected(camera);
  }

  // ไปยังตำแหน่งปัจจุบันของผู้ใช้
  void _goToMyLocation() {
    _mapController.move(_center, 15.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'เลือกกล้องจากแผนที่',
          style: TextStyle(fontFamily: 'NotoSansThai'),
        ),
        backgroundColor: const Color(0xFF1158F2),
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          // แสดงจำนวนกล้องที่โหลดได้
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_cameras.length} กล้อง',
                    style: const TextStyle(
                      fontFamily: 'NotoSansThai',
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

          // ปุ่มยืนยันใน AppBar
          if (_selectedCamera != null)
            TextButton.icon(
              onPressed: () => Navigator.pop(context, _selectedCamera),
              icon: const Icon(Icons.check, color: Colors.white, size: 18),
              label: const Text(
                'ยืนยัน',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'NotoSansThai',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // การ์ดแสดงข้อมูลกล้องที่เลือก (ด้านบน)
          if (_selectedCamera != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                border: Border(
                  bottom: BorderSide(color: Colors.green.shade200),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.camera_alt, color: Colors.green.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'กล้องที่เลือก',
                        style: TextStyle(
                          fontFamily: 'NotoSansThai',
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedCamera!.roadName,
                    style: const TextStyle(
                      fontFamily: 'NotoSansThai',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ID: ${_selectedCamera!.id}',
                    style: TextStyle(
                      fontFamily: 'NotoSansThai',
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    'ความเร็ว: ${_selectedCamera!.speedLimit} km/h • ${_selectedCamera!.type.displayName}',
                    style: TextStyle(
                      fontFamily: 'NotoSansThai',
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

          // แผนที่
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : Stack(
                    children: [
                      // แผนที่หลัก
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _center,
                          initialZoom:
                              10.0, // ลดลงจาก 14.0 เพื่อให้เห็นพื้นที่มากขึ้น
                          minZoom: 5.0, // ลดลงจาก 8.0 เพื่อให้ซูมออกได้มากขึ้น
                          maxZoom: 18.0,
                          interactionOptions: const InteractionOptions(
                            flags: InteractiveFlag.all &
                                ~InteractiveFlag.rotate, // ล็อคการหมุน
                          ),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.speedcamera.checkdarn',
                          ),

                          // รัศมีบางๆ รอบตำแหน่งผู้ใช้
                          CircleLayer(
                            circles: [
                              CircleMarker(
                                point: _center,
                                radius: 50, // 50 เมตร
                                useRadiusInMeter: true,
                                color: const Color(0xFF1158F2)
                                    .withValues(alpha: 0.1),
                                borderColor: const Color(0xFF1158F2)
                                    .withValues(alpha: 0.3),
                                borderStrokeWidth: 1,
                              ),
                            ],
                          ),

                          // กล้องทั้งหมด
                          MarkerLayer(
                            markers: _cameras.map((camera) {
                              final isSelected =
                                  _selectedCamera?.id == camera.id;

                              return Marker(
                                point: camera.location,
                                width:
                                    60, // เพิ่มขนาดเพื่อให้มีพื้นที่สำหรับวงกลม
                                height: 60,
                                child: GestureDetector(
                                  onTap: () => _onCameraTap(camera),
                                  child: Stack(
                                    alignment:
                                        Alignment.center, // จัดกลางทุกอย่าง
                                    children: [
                                      // วงกลมเขียว (เลือก)
                                      if (isSelected)
                                        Positioned(
                                          left: 4, // ขยับไปทางซ้ายเล็กน้อย
                                          top: 4,
                                          child: Container(
                                            width: 50,
                                            height: 50,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.green,
                                                width: 3,
                                              ),
                                            ),
                                          ),
                                        ),
                                      // ตัวกล้อง (ซ้อนทับบนวงกลมเขียว)
                                      Transform.scale(
                                        scale: isSelected
                                            ? 1.0
                                            : 1.0, // ไม่ต้องขยาย
                                        child:
                                            SpeedCameraMarker(camera: camera),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),

                          // แสดงตำแหน่งผู้ใช้ (วงกลมสีน้ำเงินแบบ AppBar มีขอบขาว)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _center,
                                width: 24,
                                height: 24,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1158F2),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // ปุ่มค้นหาตำแหน่งตัวเอง - วางไว้ด้านล่างทางขวา
                      Positioned(
                        bottom: MediaQuery.of(context).size.height * 0.2,
                        right: 16,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: FloatingActionButton(
                            mini: true,
                            backgroundColor: Colors.white,
                            elevation: 0,
                            onPressed: _goToMyLocation,
                            child: const Icon(
                              Icons.my_location,
                              color: Color(0xFF1158F2),
                            ),
                          ),
                        ),
                      ),

                      // ปุ่มยืนยันการเลือก - วางไว้ด้านล่างตรงกลาง (แบบลอย)
                      if (_selectedCamera != null)
                        Positioned(
                          bottom: 20,
                          left: 20,
                          right: 20,
                          child: SafeArea(
                            child: FloatingActionButton.extended(
                              onPressed: () =>
                                  Navigator.pop(context, _selectedCamera),
                              backgroundColor: const Color(0xFF1158F2),
                              foregroundColor: Colors.white,
                              icon: const Icon(Icons.check_circle),
                              label: const Text(
                                'ยืนยันการเลือก',
                                style: TextStyle(
                                  fontFamily: 'NotoSansThai',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
