import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../../services/auth_service.dart';
import '../../../services/geocoding_service.dart';
import '../../../widgets/location_picker_screen.dart';
import '../services/camera_report_service.dart';
import '../services/speed_camera_service.dart';
import '../models/camera_report_model.dart';
import '../models/speed_camera_model.dart';
import 'camera_selection_map_screen.dart';

class CameraReportFormWidget extends StatefulWidget {
  final LatLng? initialLocation;
  final String? initialRoadName;
  final VoidCallback? onReportSubmitted;

  const CameraReportFormWidget({
    super.key,
    this.initialLocation,
    this.initialRoadName,
    this.onReportSubmitted,
  });

  @override
  State<CameraReportFormWidget> createState() => _CameraReportFormWidgetState();
}

class _CameraReportFormWidgetState extends State<CameraReportFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _roadNameController = TextEditingController();
  final _descriptionController = TextEditingController();

  CameraReportType _selectedType = CameraReportType.newCamera;
  int _selectedSpeedLimit = 90;
  bool _isSubmitting = false;
  LatLng? _selectedLocation;

  // สำหรับการเลือกกล้องที่มีอยู่ในระบบ
  List<SpeedCamera> _existingCameras = [];
  SpeedCamera? _selectedExistingCamera;
  bool _isLoadingCameras = false;

  final List<int> _speedLimits = [30, 50, 60, 80, 90, 100, 120];

  @override
  void initState() {
    super.initState();

    // Set initial values
    if (widget.initialLocation != null) {
      _selectedLocation = widget.initialLocation;
    }

    if (widget.initialRoadName != null) {
      _roadNameController.text = widget.initialRoadName!;
    }

    // โหลดกล้องที่มีอยู่ในระบบ
    _loadExistingCameras();
  }

  // โหลดกล้องที่มีอยู่ในระบบ
  Future<void> _loadExistingCameras() async {
    setState(() => _isLoadingCameras = true);

    try {
      final cameras = await SpeedCameraService.getSpeedCameras();
      if (mounted) {
        setState(() {
          _existingCameras = cameras;
          _isLoadingCameras = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingCameras = false);
        print('Error loading existing cameras: $e');
      }
    }
  }

  @override
  void dispose() {
    _roadNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false, // ไม่ใช้ SafeArea กับส่วนล่าง เพื่อให้เราจัดการเอง
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 16 +
                MediaQuery.of(context)
                    .padding
                    .bottom, // เพิ่ม padding สำหรับ navigator bar
          ),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'รายงานกล้องจับความเร็ว',
                    style: TextStyle(
                      fontFamily: 'NotoSansThai',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Report type selection
                  const Text(
                    'ประเภทการรายงาน',
                    style: TextStyle(
                      fontFamily: 'NotoSansThai',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<CameraReportType>(
                    initialValue: _selectedType,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    isExpanded: true,
                    items: CameraReportType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(
                          _getReportTypeDisplayName(type),
                          style: const TextStyle(
                              fontFamily: 'NotoSansThai', fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedType = value!;
                        // ถ้าเปลี่ยนจาก newCamera เป็น type อื่น ให้ clear location
                        if (_selectedType != CameraReportType.newCamera) {
                          _selectedLocation = null;
                          _selectedExistingCamera = null;
                        }
                        // ถ้าเปลี่ยนเป็น newCamera ให้ clear existing camera และชื่อถนน
                        if (_selectedType == CameraReportType.newCamera) {
                          _selectedExistingCamera = null;
                          _selectedLocation = null;
                          _roadNameController
                              .clear(); // Clear ชื่อถนนเพื่อให้เริ่มใหม่
                          _selectedSpeedLimit =
                              90; // Reset ความเร็วเป็นค่าเริ่มต้น
                        }
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  // Location/Camera selection based on type
                  if (_selectedType == CameraReportType.newCamera) ...[
                    // สำหรับกล้องใหม่ - เลือกตำแหน่งบนแผนที่
                    const Text(
                      'ตำแหน่งกล้องใหม่',
                      style: TextStyle(
                        fontFamily: 'NotoSansThai',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final result =
                            await Navigator.push<Map<String, dynamic>>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LocationPickerScreen(
                              initialLocation: _selectedLocation,
                              title: 'เลือกตำแหน่งกล้องใหม่',
                            ),
                          ),
                        );

                        if (result != null) {
                          setState(() {
                            _selectedLocation = result['location'] as LatLng;
                            // ดึงชื่อถนนจาก locationInfo
                            final locationInfo =
                                result['locationInfo'] as LocationInfo?;
                            if (locationInfo != null &&
                                locationInfo.road != null &&
                                locationInfo.road!.isNotEmpty) {
                              _roadNameController.text = locationInfo.road!;
                            }
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.add_location,
                              color: _selectedLocation != null
                                  ? const Color(0xFF1158F2)
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedLocation != null
                                        ? 'ตำแหน่งที่เลือก'
                                        : 'แตะเพื่อเลือกตำแหน่งบนแผนที่',
                                    style: TextStyle(
                                      fontFamily: 'NotoSansThai',
                                      fontSize: 14,
                                      color: _selectedLocation != null
                                          ? Colors.black87
                                          : Colors.grey.shade600,
                                      fontWeight: _selectedLocation != null
                                          ? FontWeight.w500
                                          : FontWeight.w400,
                                    ),
                                  ),
                                  if (_selectedLocation != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'ละติจูด: ${_selectedLocation!.latitude.toStringAsFixed(6)}',
                                      style: TextStyle(
                                        fontFamily: 'NotoSansThai',
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    Text(
                                      'ลองจิจูด: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                                      style: TextStyle(
                                        fontFamily: 'NotoSansThai',
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.grey.shade400,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // แสดง error ถ้าไม่เลือกตำแหน่ง
                    if (_selectedLocation == null && _isSubmitting)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'กรุณาเลือกตำแหน่งบนแผนที่',
                          style: TextStyle(
                            fontFamily: 'NotoSansThai',
                            fontSize: 12,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ),
                  ] else ...[
                    // สำหรับประเภทอื่น - เลือกกล้องที่มีอยู่ในระบบ
                    const Text(
                      'เลือกกล้องที่มีอยู่ในระบบ',
                      style: TextStyle(
                        fontFamily: 'NotoSansThai',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),

                    if (_isLoadingCameras) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'กำลังโหลดข้อมูลกล้อง...',
                              style: TextStyle(
                                fontFamily: 'NotoSansThai',
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else if (_existingCameras.isEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: Colors.grey.shade600),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'ไม่พบข้อมูลกล้องในระบบ',
                                style: TextStyle(
                                  fontFamily: 'NotoSansThai',
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // เลือกกล้องจากแผนที่แทน dropdown
                      InkWell(
                        onTap: () async {
                          final result = await Navigator.push<SpeedCamera>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CameraSelectionMapScreen(
                                existingCameras: _existingCameras,
                                selectedCamera: _selectedExistingCamera,
                                title: 'เลือกกล้องที่ต้องการรายงาน',
                              ),
                            ),
                          );

                          if (result != null) {
                            setState(() {
                              _selectedExistingCamera = result;
                              _selectedLocation = result.location;
                              _roadNameController.text = result.roadName;
                              _selectedSpeedLimit = result.speedLimit;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.map,
                                color: _selectedExistingCamera != null
                                    ? const Color(0xFF1158F2)
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedExistingCamera != null
                                          ? 'กล้องที่เลือก'
                                          : 'แตะเพื่อเลือกกล้องจากแผนที่',
                                      style: TextStyle(
                                        fontFamily: 'NotoSansThai',
                                        fontSize: 14,
                                        color: _selectedExistingCamera != null
                                            ? Colors.black87
                                            : Colors.grey.shade600,
                                        fontWeight:
                                            _selectedExistingCamera != null
                                                ? FontWeight.w500
                                                : FontWeight.w400,
                                      ),
                                    ),
                                    if (_selectedExistingCamera != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        _selectedExistingCamera!.roadName,
                                        style: const TextStyle(
                                          fontFamily: 'NotoSansThai',
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        '${_selectedExistingCamera!.speedLimit} km/h • ${_selectedExistingCamera!.location.latitude.toStringAsFixed(4)}, ${_selectedExistingCamera!.location.longitude.toStringAsFixed(4)}',
                                        style: TextStyle(
                                          fontFamily: 'NotoSansThai',
                                          fontSize: 11,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Colors.grey.shade400,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    // แสดง error ถ้าไม่เลือกกล้อง
                    if (_selectedExistingCamera == null &&
                        _isSubmitting &&
                        _existingCameras.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'กรุณาเลือกกล้องจากแผนที่',
                          style: TextStyle(
                            fontFamily: 'NotoSansThai',
                            fontSize: 12,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ),
                  ],

                  const SizedBox(height: 16),

                  // Road name
                  TextFormField(
                    controller: _roadNameController,
                    readOnly: _selectedType != CameraReportType.newCamera,
                    decoration: InputDecoration(
                      labelText: 'ชื่อถนน',
                      labelStyle: const TextStyle(fontFamily: 'NotoSansThai'),
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      filled: _selectedType != CameraReportType.newCamera,
                      fillColor: _selectedType != CameraReportType.newCamera
                          ? Colors.grey.shade100
                          : null,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'กรุณากรอกชื่อถนน';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Speed limit (for new camera, speed changed, and verification)
                  if (_selectedType == CameraReportType.newCamera ||
                      _selectedType == CameraReportType.speedChanged ||
                      _selectedType == CameraReportType.verification) ...[
                    Text(
                      _selectedType == CameraReportType.speedChanged
                          ? 'จำกัดความเร็วใหม่ (km/h)'
                          : _selectedType == CameraReportType.verification
                              ? 'จำกัดความเร็วปัจจุบัน (km/h)'
                              : 'จำกัดความเร็ว (km/h)',
                      style: const TextStyle(
                        fontFamily: 'NotoSansThai',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      initialValue: _selectedSpeedLimit,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        filled: _selectedType == CameraReportType.verification,
                        fillColor:
                            _selectedType == CameraReportType.verification
                                ? Colors.grey.shade100
                                : null,
                      ),
                      items: _speedLimits.map((speed) {
                        return DropdownMenuItem(
                          value: speed,
                          child: Text(
                            '$speed km/h',
                            style: const TextStyle(fontFamily: 'NotoSansThai'),
                          ),
                        );
                      }).toList(),
                      onChanged: _selectedType == CameraReportType.verification
                          ? null // ไม่ให้แก้ไขถ้าเป็น verification
                          : (value) {
                              setState(() {
                                _selectedSpeedLimit = value!;
                              });
                            },
                    ),

                    // แสดงข้อมูลเพิ่มเติมสำหรับ speedChanged
                    if (_selectedType == CameraReportType.speedChanged &&
                        _selectedExistingCamera != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: Colors.blue.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: Colors.blue.shade700, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'ความเร็วเดิม: ${_selectedExistingCamera!.speedLimit} km/h → ใหม่: $_selectedSpeedLimit km/h',
                                style: TextStyle(
                                  fontFamily: 'NotoSansThai',
                                  fontSize: 12,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
                  ],

                  // Description
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'รายละเอียดที่ตั้งและจุดสังเกต',
                      labelStyle: TextStyle(fontFamily: 'NotoSansThai'),
                      hintText:
                          'เช่น ใกล้ห้าแยกโรบินสัน, หน้าโรงเรียน, ตรงข้ามปั๊มน้ำมัน, บริเวณสะพาน',
                      hintStyle: TextStyle(
                        fontFamily: 'NotoSansThai',
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(12),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'กรุณาระบุรายละเอียดที่ตั้งและจุดสังเกต';
                      }
                      if (value.trim().length < 10) {
                        return 'กรุณาระบุรายละเอียดอย่างน้อย 10 ตัวอักษร';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitReport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1158F2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              _getSubmitButtonText(),
                              style: const TextStyle(
                                fontFamily: 'NotoSansThai',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getReportTypeDisplayName(CameraReportType type) {
    switch (type) {
      case CameraReportType.newCamera:
        return '📷 รายงานกล้องใหม่';
      case CameraReportType.removedCamera:
        return '❌ รายงานกล้องที่ถูกถอน';
      case CameraReportType.speedChanged:
        return '⚡ รายงานการเปลี่ยนจำกัดความเร็ว';
      case CameraReportType.verification:
        return '✅ ยืนยันกล้องที่มีอยู่';
    }
  }

  String _getSubmitButtonText() {
    switch (_selectedType) {
      case CameraReportType.newCamera:
        return 'รายงานกล้องใหม่';
      case CameraReportType.removedCamera:
        return 'รายงานกล้องที่ถูกถอน';
      case CameraReportType.speedChanged:
        return 'รายงานเปลี่ยนความเร็ว';
      case CameraReportType.verification:
        return 'ยืนยันกล้อง';
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // ตรวจสอบการล็อกอินก่อน
    if (!AuthService.isLoggedIn) {
      final success = await AuthService.showLoginDialog(context);
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('กรุณาล็อกอินก่อนรายงานกล้อง',
                style: TextStyle(fontFamily: 'NotoSansThai')),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    // ตรวจสอบว่าเลือกตำแหน่งหรือกล้องแล้วหรือยัง
    if (_selectedType == CameraReportType.newCamera) {
      // สำหรับกล้องใหม่ ต้องเลือกตำแหน่ง
      if (_selectedLocation == null) {
        setState(() => _isSubmitting = true);
        Future.delayed(const Duration(milliseconds: 500), () {
          setState(() => _isSubmitting = false);
        });
        return;
      }
    } else {
      // สำหรับประเภทอื่น ต้องเลือกกล้องที่มีอยู่
      if (_selectedExistingCamera == null) {
        setState(() => _isSubmitting = true);
        Future.delayed(const Duration(milliseconds: 500), () {
          setState(() => _isSubmitting = false);
        });
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      await CameraReportService.submitReport(
        latitude: _selectedLocation!.latitude,
        longitude: _selectedLocation!.longitude,
        roadName: _roadNameController.text.trim(),
        speedLimit: _selectedSpeedLimit,
        type: _selectedType,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );

      // Reset form
      _formKey.currentState!.reset();
      _roadNameController.clear();
      _descriptionController.clear();
      setState(() {
        _selectedLocation = null;
        _selectedExistingCamera = null;
        _selectedType = CameraReportType.newCamera;
        _selectedSpeedLimit = 90;
      });

      // Notify parent
      widget.onReportSubmitted?.call();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'เกิดข้อผิดพลาด: $e',
            style: const TextStyle(fontFamily: 'NotoSansThai'),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }
}
