import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../models/speed_camera_model.dart';
import 'speed_camera_marker.dart';

class CameraSelectionMapScreen extends StatefulWidget {
  final List<SpeedCamera> existingCameras;
  final SpeedCamera? selectedCamera;
  final String title;

  const CameraSelectionMapScreen({
    super.key,
    required this.existingCameras,
    this.selectedCamera,
    this.title = 'เลือกกล้อง',
  });

  @override
  State<CameraSelectionMapScreen> createState() =>
      _CameraSelectionMapScreenState();
}

class _CameraSelectionMapScreenState extends State<CameraSelectionMapScreen> {
  late MapController _mapController;
  SpeedCamera? _selectedCamera;
  double _currentZoom = 12.0;
  LatLng? _currentLocation;

  // Default center - Bangkok
  LatLng _mapCenter = const LatLng(13.7563, 100.5018);

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _selectedCamera = widget.selectedCamera;
    _getCurrentLocation();

    // Set initial map center
    if (widget.selectedCamera != null) {
      _mapCenter = widget.selectedCamera!.location;
      _currentZoom = 16.0;
    } else if (widget.existingCameras.isNotEmpty) {
      // Center map to show all cameras
      _calculateMapBounds();
    }

    // Move to initial location after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.move(_mapCenter, _currentZoom);
    });
  }

  void _getCurrentLocation() async {
    try {
      // ตรวจสอบสิทธิ์การเข้าถึงตำแหน่ง
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permissions are denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('Location permissions are permanently denied');
        return;
      }

      // รับตำแหน่งปัจจุบัน
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _currentLocation = LatLng(position.latitude, position.longitude);
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error getting location: $e');
      // ไม่ใช้ตำแหน่งเริ่มต้น ให้เป็น null แทน
      _currentLocation = null;
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _calculateMapBounds() {
    if (widget.existingCameras.isEmpty) return;

    double minLat = widget.existingCameras.first.location.latitude;
    double maxLat = widget.existingCameras.first.location.latitude;
    double minLng = widget.existingCameras.first.location.longitude;
    double maxLng = widget.existingCameras.first.location.longitude;

    for (final camera in widget.existingCameras) {
      minLat =
          minLat < camera.location.latitude ? minLat : camera.location.latitude;
      maxLat =
          maxLat > camera.location.latitude ? maxLat : camera.location.latitude;
      minLng = minLng < camera.location.longitude
          ? minLng
          : camera.location.longitude;
      maxLng = maxLng > camera.location.longitude
          ? maxLng
          : camera.location.longitude;
    }

    _mapCenter = LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);

    // Calculate appropriate zoom level
    final latDiff = maxLat - minLat;
    final lngDiff = maxLng - minLng;
    final maxDiff = latDiff > lngDiff ? latDiff : lngDiff;

    if (maxDiff > 0.1) {
      _currentZoom = 10.0;
    } else if (maxDiff > 0.05) {
      _currentZoom = 12.0;
    } else if (maxDiff > 0.01) {
      _currentZoom = 14.0;
    } else {
      _currentZoom = 16.0;
    }
  }

  void _onCameraSelected(SpeedCamera camera) {
    setState(() {
      _selectedCamera = camera;
    });

    // Move map to selected camera
    _mapController.move(camera.location, 16.0);
  }

  void _goToCurrentLocation() async {
    if (_currentLocation != null) {
      _mapController.move(_currentLocation!, 16.0);
    } else {
      // ลองรับตำแหน่งใหม่อีกครั้ง
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        _currentLocation = LatLng(position.latitude, position.longitude);
        if (mounted) {
          setState(() {});
          _mapController.move(_currentLocation!, 16.0);
        }
      } catch (e) {
        // Show snackbar if location not available
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'ไม่สามารถหาตำแหน่งปัจจุบันได้ กรุณาเปิด GPS',
                style: TextStyle(fontFamily: 'NotoSansThai'),
              ),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(
            fontFamily: 'NotoSansThai',
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        backgroundColor: const Color(0xFFFFC107),
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          if (_selectedCamera != null)
            TextButton(
              onPressed: () => Navigator.pop(context, _selectedCamera),
              child: const Text(
                'เลือก',
                style: TextStyle(
                  fontFamily: 'NotoSansThai',
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _mapCenter,
              initialZoom: _currentZoom,
              onMapEvent: (MapEvent event) {
                if (event is MapEventMove) {
                  setState(() {
                    _currentZoom = event.camera.zoom;
                  });
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.checkdarn.app',
              ),
              MarkerLayer(
                markers: [
                  // Camera markers
                  ...widget.existingCameras.map((camera) {
                    final isSelected = _selectedCamera?.id == camera.id;
                    return Marker(
                      point: camera.location,
                      child: SpeedCameraMarker(
                        camera: camera,
                        isSelected: isSelected,
                        onTap: () => _onCameraSelected(camera),
                      ),
                    );
                  }),

                  // Current location marker
                  if (_currentLocation != null)
                    Marker(
                      point: _currentLocation!,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1158F2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1158F2).withOpacity(0.3),
                              blurRadius: 10,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Find my location button
          Positioned(
            bottom: 160 + MediaQuery.of(context).viewPadding.bottom,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1158F2),
              elevation: 4,
              onPressed: _goToCurrentLocation,
              child: const Icon(Icons.my_location),
            ),
          ),

          // Camera info overlay - ย้ายมาไว้ด้านบน
          if (_selectedCamera != null)
            Positioned(
              top: 10,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        SvgPicture.asset(
                          'assets/icons/speed_camera_screen/speed camera2.svg',
                          width: 24,
                          height: 24,
                          colorFilter: const ColorFilter.mode(
                            Color(0xFF1158F2),
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedCamera!.roadName,
                            style: const TextStyle(
                              fontFamily: 'NotoSansThai',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'จำกัดความเร็ว: ${_selectedCamera!.speedLimit} km/h',
                      style: const TextStyle(
                        fontFamily: 'NotoSansThai',
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Confirm button
          Positioned(
            bottom: 16 + MediaQuery.of(context).viewPadding.bottom,
            left: 16,
            right: 16,
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC107),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 2,
                    ),
                    child: const Text(
                      'ยกเลิก',
                      style: TextStyle(
                        fontFamily: 'NotoSansThai',
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selectedCamera != null
                        ? () => Navigator.pop(context, _selectedCamera)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedCamera != null
                          ? const Color(0xFF1158F2)
                          : Colors.grey.shade400,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 2,
                    ),
                    child: const Text(
                      'ยืนยันการเลือก',
                      style: TextStyle(
                        fontFamily: 'NotoSansThai',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Instructions overlay - ปรับตำแหน่งให้ไม่ทับกับการ์ดข้อมูล
          if (_selectedCamera == null)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'แตะที่ไอคอนกล้องบนแผนที่เพื่อเลือก',
                  style: TextStyle(
                    fontFamily: 'NotoSansThai',
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
