import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/geocoding_service.dart';

class LocationPickerScreen extends StatefulWidget {
  final LatLng? initialLocation;
  final String title;
  final bool
      autoLocateToCurrentPosition; // เพิ่ม parameter สำหรับเด้งไปหาตำแหน่งปัจจุบัน

  const LocationPickerScreen({
    super.key,
    this.initialLocation,
    this.title = 'เลือกตำแหน่ง',
    this.autoLocateToCurrentPosition = false, // ค่าเริ่มต้นเป็น false
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  late MapController _mapController;
  LatLng _selectedLocation = const LatLng(13.7563, 100.5018); // Default Bangkok
  bool _isLoadingCurrentLocation = false;
  double _currentZoom = 16.0;
  LocationInfo? _selectedLocationInfo; // เพิ่มตัวแปรสำหรับเก็บข้อมูลตำแหน่ง

  // Controllers for manual coordinate input
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();
  final TextEditingController _roadNameController = TextEditingController();
  bool _showCoordinateInput = false;
  bool _isLoadingRoadName = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    // Set initial location if provided
    if (widget.initialLocation != null) {
      _selectedLocation = widget.initialLocation!;
    }

    // Update text controllers
    _updateCoordinateControllers();

    // Move to initial location after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.autoLocateToCurrentPosition) {
        // เด้งไปหาตำแหน่งปัจจุบันเลย
        _getCurrentLocation();
      } else {
        // ใช้ตำแหน่งเริ่มต้นตามปกติ
        _moveToLocation(_selectedLocation);
      }
    });
  }

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    _roadNameController.dispose();
    super.dispose();
  }

  void _updateCoordinateControllers() {
    _latController.text = _selectedLocation.latitude.toStringAsFixed(6);
    _lngController.text = _selectedLocation.longitude.toStringAsFixed(6);
  }

  // Get road name from coordinates using reverse geocoding
  Future<void> _getRoadNameFromCoordinates(LatLng location) async {
    setState(() {
      _isLoadingRoadName = true;
    });

    try {
      // ใช้ GeocodingService เพื่อดึงข้อมูลที่อยู่แบบเต็ม
      final locationInfo = await GeocodingService.getLocationInfo(location);

      setState(() {
        _selectedLocationInfo = locationInfo;
        // ตั้งค่าชื่อถนนใน text field
        if (locationInfo?.road != null && locationInfo!.road!.isNotEmpty) {
          _roadNameController.text = locationInfo.road!;
        } else {
          _roadNameController.text = '';
        }
      });
    } catch (e) {
      print('Error getting road name: $e');

      // Fallback: ใช้ geocoding แบบธรรมดา
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          location.latitude,
          location.longitude,
        );

        if (placemarks.isNotEmpty) {
          final placemark = placemarks.first;
          String roadName = '';

          // Try to get road name in order of preference
          if (placemark.street != null && placemark.street!.isNotEmpty) {
            roadName = placemark.street!;
          } else if (placemark.thoroughfare != null &&
              placemark.thoroughfare!.isNotEmpty) {
            roadName = placemark.thoroughfare!;
          } else if (placemark.subThoroughfare != null &&
              placemark.subThoroughfare!.isNotEmpty) {
            roadName = placemark.subThoroughfare!;
          } else if (placemark.locality != null &&
              placemark.locality!.isNotEmpty) {
            roadName = placemark.locality!;
          }

          // Update road name if found
          if (roadName.isNotEmpty) {
            _roadNameController.text = roadName;
          }

          // สร้าง LocationInfo พื้นฐาน จาก fallback geocoding
          setState(() {
            _selectedLocationInfo = LocationInfo(
              road: roadName.isNotEmpty ? roadName : null,
              district: placemark.subAdministrativeArea ?? '',
              province: placemark.administrativeArea ?? '',
              country: placemark.country ?? '',
            );
          });
        }
      } catch (fallbackError) {
        print('Fallback geocoding also failed: $fallbackError');
        // ไม่แสดง error ให้ผู้ใช้, ปล่อยให้กรอกเอง
      }
    } finally {
      setState(() {
        _isLoadingRoadName = false;
      });
    }
  }

  void _moveToLocation(LatLng location) {
    try {
      _mapController.move(location, _currentZoom);
    } catch (e) {
      print('Error moving to location: $e');
    }
  }

  void _getCurrentLocation() async {
    setState(() {
      _isLoadingCurrentLocation = true;
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError('ไม่ได้รับอนุญาตให้เข้าถึงตำแหน่ง');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showError('กรุณาเปิดอนุญาตตำแหน่งในการตั้งค่า');
        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final newLocation = LatLng(position.latitude, position.longitude);
      setState(() {
        _selectedLocation = newLocation;
        _isLoadingCurrentLocation = false;
      });

      _updateCoordinateControllers();
      _moveToLocation(newLocation);
      _getRoadNameFromCoordinates(
          newLocation); // Get road name for current location
    } catch (e) {
      print('Error getting location: $e');
      setState(() {
        _isLoadingCurrentLocation = false;
      });
      _showError('ไม่สามารถระบุตำแหน่งปัจจุบันได้');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(message, style: const TextStyle(fontFamily: 'NotoSansThai')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      _selectedLocation = point;
    });
    _updateCoordinateControllers();
    _getRoadNameFromCoordinates(point); // Get road name automatically
  }

  void _onCoordinateChanged() {
    try {
      final lat = double.parse(_latController.text);
      final lng = double.parse(_lngController.text);

      // Validate coordinate ranges
      if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
        _showError(
            'พิกัดไม่ถูกต้อง: Latitude (-90 ถึง 90), Longitude (-180 ถึง 180)');
        return;
      }

      final newLocation = LatLng(lat, lng);
      setState(() {
        _selectedLocation = newLocation;
      });
      _moveToLocation(newLocation);
      _getRoadNameFromCoordinates(
          newLocation); // Get road name when coordinates change
    } catch (e) {
      _showError('รูปแบบพิกัดไม่ถูกต้อง');
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
        backgroundColor:
            const Color(0xFFFFC107), // เปลี่ยนเป็นสีเหลืองแบบหน้าอื่นๆ
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // Coordinate input panel (collapsible)
          if (_showCoordinateInput)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ป้อนพิกัดโดยตรง',
                    style: TextStyle(
                      fontFamily: 'NotoSansThai',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _latController,
                          decoration: const InputDecoration(
                            labelText: 'Latitude',
                            hintText: '13.756300',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          style: const TextStyle(fontFamily: 'NotoSansThai'),
                          onChanged: (_) => _onCoordinateChanged(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _lngController,
                          decoration: const InputDecoration(
                            labelText: 'Longitude',
                            hintText: '100.501800',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          style: const TextStyle(fontFamily: 'NotoSansThai'),
                          onChanged: (_) => _onCoordinateChanged(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'หรือแตะบนแผนที่เพื่อเลือกตำแหน่ง',
                    style: TextStyle(
                      fontFamily: 'NotoSansThai',
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Road name field
                  TextField(
                    controller: _roadNameController,
                    decoration: InputDecoration(
                      labelText: 'ชื่อถนน',
                      hintText: 'ชื่อถนนจะแสดงอัตโนมัติ หรือพิมพ์เอง',
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      suffixIcon: _isLoadingRoadName
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : null,
                    ),
                    style: const TextStyle(fontFamily: 'NotoSansThai'),
                  ),
                ],
              ),
            ),

          // Map container
          Expanded(
            child: Stack(
              children: [
                // Flutter Map
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _selectedLocation,
                    initialZoom: _currentZoom,
                    onTap: _onMapTap,
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
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.checkdarn.app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _selectedLocation,
                          child: const Icon(
                            Icons.location_pin,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Info overlay showing current coordinates
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ตำแหน่งที่เลือก:',
                              style: TextStyle(
                                fontFamily: 'NotoSansThai',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Lat: ${_selectedLocation.latitude.toStringAsFixed(6)}',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              'Lng: ${_selectedLocation.longitude.toStringAsFixed(6)}',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        // Edit coordinate button in top-right corner of card
                        Positioned(
                          top: -8,
                          right: -8,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _showCoordinateInput = !_showCoordinateInput;
                                });
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                child: _showCoordinateInput
                                    ? const Icon(Icons.map,
                                        size: 16, color: Colors.black)
                                    : SvgPicture.asset(
                                        'assets/icons/location_picker_screen/edit_location.svg',
                                        width: 16,
                                        height: 16,
                                        colorFilter: const ColorFilter.mode(
                                            Colors.black, BlendMode.srcIn),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // GPS button (moved to bottom)
                Positioned(
                  bottom: 100 +
                      (MediaQuery.of(context).viewPadding.bottom > 0
                          ? MediaQuery.of(context).viewPadding.bottom
                          : 0), // ขยับขึ้นตาม navigation bar
                  right: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isLoadingCurrentLocation
                            ? null
                            : _getCurrentLocation,
                        borderRadius: BorderRadius.circular(
                            22), // ครึ่งหนึ่งของ size (44/2)
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                          child: _isLoadingCurrentLocation
                              ? const Center(
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF1158F2),
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.my_location,
                                  color: Color(0xFF1158F2),
                                  size: 20,
                                ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Bottom action buttons positioned directly on map
                Positioned(
                  bottom: 16 +
                      (MediaQuery.of(context).viewPadding.bottom > 0
                          ? MediaQuery.of(context).viewPadding.bottom
                          : 0), // ขยับขึ้นตาม navigation bar
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
                          onPressed: () => Navigator.pop(context, {
                            'location': _selectedLocation,
                            'locationInfo': _selectedLocationInfo,
                          }),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFC107),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 2,
                          ),
                          child: const Text(
                            'ยืนยันตำแหน่ง',
                            style: TextStyle(
                              fontFamily: 'NotoSansThai',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
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
