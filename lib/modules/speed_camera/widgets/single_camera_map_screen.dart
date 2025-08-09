import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../generated/gen_l10n/app_localizations.dart';
import '../models/speed_camera_model.dart';
import '../services/speed_camera_service.dart';
import '../widgets/speed_camera_marker.dart';

class SingleCameraMapScreen extends StatefulWidget {
  final String cameraId;
  final String title;
  final LatLng? fallbackLocation; // ตำแหน่งสำรอง หากไม่พบกล้อง

  const SingleCameraMapScreen({
    super.key,
    required this.cameraId,
    required this.title,
    this.fallbackLocation,
  });

  @override
  State<SingleCameraMapScreen> createState() => _SingleCameraMapScreenState();
}

class _SingleCameraMapScreenState extends State<SingleCameraMapScreen> {
  late MapController _mapController;
  SpeedCamera? _camera;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _loadCamera();
  }

  Future<void> _loadCamera() async {
    try {
      print('🔍 Loading camera with ID: ${widget.cameraId}');

      // โหลดกล้องจาก ID
      final camera = await SpeedCameraService.getCameraById(widget.cameraId);

      if (camera != null) {
        setState(() {
          _camera = camera;
          _isLoading = false;
        });

        // ย้ายแผนที่ไปยังตำแหน่งกล้อง
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _mapController.move(camera.location, 16.0); // ซูมใกล้
          }
        });

        print('✅ Camera loaded: ${camera.roadName}');
      } else {
        // ไม่พบกล้อง แสดง fallback location
        setState(() {
          _isLoading = false;
          _errorMessage = AppLocalizations.of(context).cameraNotFoundInSystem;
        });

        if (widget.fallbackLocation != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _mapController.move(widget.fallbackLocation!, 14.0);
            }
          });
        }

        print('❌ Camera not found with ID: ${widget.cameraId}');
      }
    } catch (e) {
      print('❌ Error loading camera: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = '${AppLocalizations.of(context).errorLoadingData}: $e';
      });

      // แสดง fallback location หากมี
      if (widget.fallbackLocation != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _mapController.move(widget.fallbackLocation!, 14.0);
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontFamily: 'NotoSansThai'),
        ),
        backgroundColor: const Color(0xFF1158F2),
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context).loadingCameraData,
                    style: const TextStyle(fontFamily: 'NotoSansThai'),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                // แผนที่หลัก
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: widget.fallbackLocation ??
                        const LatLng(13.7563, 100.5018), // Default Bangkok
                    initialZoom: 14.0,
                    minZoom: 8.0,
                    maxZoom: 18.0,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.speedcamera.checkdarn',
                    ),

                    // แสดงกล้อง หากพบ
                    if (_camera != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _camera!.location,
                            width: 60,
                            height: 60,
                            child: SpeedCameraMarker(camera: _camera!),
                          ),
                        ],
                      ),

                    // แสดง marker fallback หากไม่พบกล้อง
                    if (_camera == null && widget.fallbackLocation != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: widget.fallbackLocation!,
                            width: 40,
                            height: 40,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.red.shade600,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),

                // ข้อความแสดงข้อผิดพลาด (หากมี)
                if (_errorMessage != null)
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning, color: Colors.red.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                fontFamily: 'NotoSansThai',
                                color: Colors.red.shade700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // ข้อมูลกล้อง (หากพบ)
                if (_camera != null)
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: SafeArea(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.camera_alt,
                                  color: const Color(0xFF1158F2),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _camera!.roadName,
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
                            Row(
                              children: [
                                Icon(
                                  Icons.speed,
                                  color: Colors.orange,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  AppLocalizations.of(context)
                                      .speedLimitDisplay(_camera!.speedLimit),
                                  style: const TextStyle(
                                    fontFamily: 'NotoSansThai',
                                    fontSize: 14,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    _camera!.type.displayName,
                                    style: TextStyle(
                                      fontFamily: 'NotoSansThai',
                                      fontSize: 12,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
