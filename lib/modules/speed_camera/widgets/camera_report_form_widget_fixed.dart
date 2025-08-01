import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../../services/auth_service.dart';
import '../../../widgets/location_picker_screen.dart';
import '../services/camera_report_service.dart';
import '../models/camera_report_model.dart';

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
                  value: _selectedType,
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
                    });
                  },
                ),

                const SizedBox(height: 16),

                // Location selection
                const Text(
                  'ตำแหน่ง',
                  style: TextStyle(
                    fontFamily: 'NotoSansThai',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final result = await Navigator.push<Map<String, dynamic>>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LocationPickerScreen(
                          initialLocation: _selectedLocation,
                          title: 'เลือกตำแหน่งกล้อง',
                        ),
                      ),
                    );

                    if (result != null) {
                      setState(() {
                        _selectedLocation = result['location'] as LatLng;
                        final roadName = result['roadName'] as String?;
                        if (roadName != null && roadName.isNotEmpty) {
                          _roadNameController.text = roadName;
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
                          Icons.location_on,
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

                const SizedBox(height: 16),

                // Road name
                TextFormField(
                  controller: _roadNameController,
                  decoration: const InputDecoration(
                    labelText: 'ชื่อถนน',
                    labelStyle: TextStyle(fontFamily: 'NotoSansThai'),
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'กรุณากรอกชื่อถนน';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Speed limit (only for new camera and speed changed)
                if (_selectedType == CameraReportType.newCamera ||
                    _selectedType == CameraReportType.speedChanged) ...[
                  const Text(
                    'จำกัดความเร็ว (km/h)',
                    style: TextStyle(
                      fontFamily: 'NotoSansThai',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: _selectedSpeedLimit,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                    onChanged: (value) {
                      setState(() {
                        _selectedSpeedLimit = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'รายละเอียดเพิ่มเติม (ไม่บังคับ)',
                    labelStyle: TextStyle(fontFamily: 'NotoSansThai'),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(12),
                  ),
                  maxLines: 3,
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
    );
  }

  String _getReportTypeDisplayName(CameraReportType type) {
    switch (type) {
      case CameraReportType.newCamera:
        return '📷 รายงานกล้องใหม่';
      case CameraReportType.removedCamera:
        return '❌ รายงานกล้องที่ถูกถอด';
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
        return 'รายงานกล้องถูกถอด';
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

    // ตรวจสอบว่าเลือกตำแหน่งแล้วหรือยัง
    if (_selectedLocation == null) {
      setState(() => _isSubmitting = true);
      Future.delayed(const Duration(milliseconds: 500), () {
        setState(() => _isSubmitting = false);
      });
      return;
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
