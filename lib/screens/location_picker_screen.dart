import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../services/geocoding_service.dart';
import '../widgets/location_marker.dart';
import '../widgets/location_button.dart';

class LocationPickerScreen extends StatefulWidget {
  final LatLng? initialLocation;

  const LocationPickerScreen({
    super.key,
    this.initialLocation,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  late MapController mapController;
  LatLng? selectedLocation;
  LocationInfo? selectedLocationInfo;
  bool isLoadingLocation = false;
  LatLng currentCenter =
      const LatLng(13.7563, 100.5018); // กรุงเทพเป็นค่าเริ่มต้น

  @override
  void initState() {
    super.initState();
    mapController = MapController();

    // ใช้ตำแหน่งที่ส่งมาหรือหาตำแหน่งปัจจุบัน
    if (widget.initialLocation != null) {
      selectedLocation = widget.initialLocation;
      currentCenter = widget.initialLocation!;
      _getLocationInfo(widget.initialLocation!);
    } else {
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() {
        isLoadingLocation = true;
      });

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final newPosition = LatLng(position.latitude, position.longitude);

      setState(() {
        currentCenter = newPosition;
        selectedLocation = newPosition;
      });

      mapController.move(newPosition, 15.0);
      await _getLocationInfo(newPosition);
    } finally {
      setState(() {
        isLoadingLocation = false;
      });
    }
  }

  // ฟังก์ชันดึงข้อมูลที่อยู่จากพิกัด
  Future<void> _getLocationInfo(LatLng position) async {
    try {
      setState(() {
        isLoadingLocation = true;
      });

      final locationInfo = await GeocodingService.getLocationInfo(position);
      setState(() {
        selectedLocationInfo = locationInfo;
      });
    } catch (e) {
      print('Error getting location info: $e');
    } finally {
      setState(() {
        isLoadingLocation = false;
      });
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      selectedLocation = point;
    });

    _getLocationInfo(point);
  }

  void _confirmLocation() {
    if (selectedLocation != null) {
      Navigator.pop(context, {
        'location': selectedLocation,
        'locationInfo': selectedLocationInfo,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'เลือกตำแหน่ง',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        backgroundColor: const Color(0xFFFDC621),
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          // แผนที่
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: currentCenter,
              initialZoom: 15.0,
              minZoom: 5.0,
              maxZoom: 18.0,
              onTap: _onMapTap,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.checkdarn',
              ),
              // หมุดตำแหน่งที่เลือก
              if (selectedLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: selectedLocation!,
                      width: 36.8, // เพิ่ม 60%: 23 * 1.6 = 36.8
                      height: 48, // เพิ่ม 60%: 30 * 1.6 = 48
                      child: const LocationMarker(scale: 1.6),
                    ),
                  ],
                ),
            ],
          ),

          // แถบข้อมูลที่อยู่
          if (selectedLocationInfo != null || isLoadingLocation)
            Positioned(
              top: 16,
              left: 18,
              right: 18,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'ตำแหน่งที่เลือก',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        if (isLoadingLocation) ...[
                          const SizedBox(width: 8),
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      selectedLocationInfo?.fullAddress ??
                          selectedLocationInfo?.shortAddress ??
                          'กำลังหาข้อมูลตำแหน่ง...',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),

          // ปุ่มค้นหาตำแหน่งปัจจุบัน
          Positioned(
            right: 16,
            bottom: 130,
            child: LocationButton(
              onPressed: _getCurrentLocation,
              isLoading: isLoadingLocation,
            ),
          ),

          // ปุ่มยืนยัน
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: ElevatedButton(
              onPressed: selectedLocation != null ? _confirmLocation : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9800),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 6,
              ),
              child: const Text(
                'ยืนยันตำแหน่ง',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
