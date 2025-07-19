import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async';
import 'dart:math' as math;
import '../models/event_model.dart';
import '../services/geocoding_service.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';
import 'location_picker_screen.dart';
import 'list_screen.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  Event                        child: Text(
                          '📍 ตำแหน่งปัจจุบัน (แตะเพื่อเปลี่ยน)',
                          style: TextStyle(
                            fontSize: 12,
                            color: const Color(0xFF4673E5),
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Kanit',
                          ),
                        ),? selectedCategory;
  final TextEditingController _detailController = TextEditingController();
  File? selectedImage;
  LatLng? selectedLocation;
  LocationInfo? selectedLocationInfo;
  final ImagePicker _picker = ImagePicker();
  bool isSubmitting = false;
  bool isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
  }

  Future<void> _loadCurrentLocation() async {
    setState(() {
      isLoadingLocation = true;
    });

    try {
      final currentLocation = await _getCurrentLocation();
      if (currentLocation != null) {
        final locationInfo =
            await GeocodingService.getLocationInfo(currentLocation);

        if (mounted) {
          setState(() {
            selectedLocation = currentLocation;
            selectedLocationInfo = locationInfo;
            isLoadingLocation = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            isLoadingLocation = false;
          });
        }
      }
    } catch (e) {
      print('Error loading current location: $e');
      if (mounted) {
        setState(() {
          isLoadingLocation = false;
        });
      }
    }
  }

  String? _validateRequiredFields() {
    if (selectedCategory == null) {
      return 'ประเภทเหตุการณ์';
    }
    if (_detailController.text.trim().isEmpty) {
      return 'รายละเอียดเหตุการณ์';
    }
    return null;
  }

  // Image Compression with Advanced Optimization
  Future<File?> _compressUntilUnderSize(File originalFile,
      {int maxSizeKB = 80}) async {
    try {
      File? compressedFile = originalFile;
      int currentQuality = 50;
      int step = 30;

      int originalSizeKB = await originalFile.length() ~/ 1024;
      print('Advanced Compression - Original size: $originalSizeKB KB');

      if (originalSizeKB <= maxSizeKB) {
        final tempDir = await getTemporaryDirectory();
        final targetPath =
            '${tempDir.path}/converted_${DateTime.now().millisecondsSinceEpoch}.webp';

        final result = await FlutterImageCompress.compressAndGetFile(
          originalFile.path,
          targetPath,
          quality: 60,
          format: CompressFormat.webp,
          minWidth: 480,
          minHeight: 320,
        );

        return result != null ? File(result.path) : originalFile;
      }

      while (currentQuality > 10) {
        final tempDir = await getTemporaryDirectory();
        final targetPath =
            '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.webp';

        final result = await FlutterImageCompress.compressAndGetFile(
          compressedFile!.path,
          targetPath,
          quality: currentQuality,
          minWidth: 480,
          minHeight: 320,
          format: CompressFormat.webp,
        );

        if (result == null) break;

        compressedFile = File(result.path);
        final newSizeKB = await compressedFile.length() ~/ 1024;
        print('Compression: Quality $currentQuality% → Size $newSizeKB KB');

        if (newSizeKB <= maxSizeKB) {
          try {
            await originalFile.delete();
          } catch (e) {
            print('Warning: Could not delete original file: $e');
          }
          return compressedFile;
        }

        currentQuality -= step;
      }

      if (await compressedFile!.length() ~/ 1024 > maxSizeKB) {
        print('Ultra compression mode');
        compressedFile =
            await _compressWithLowerResolution(compressedFile, maxSizeKB);
      }

      try {
        await originalFile.delete();
      } catch (e) {
        print('Warning: Could not delete original file: $e');
      }

      return compressedFile;
    } catch (e) {
      print('❌ Error in compression: $e');
      return null;
    }
  }

  Future<File> _compressWithLowerResolution(File file, int maxSizeKB) async {
    final tempDir = await getTemporaryDirectory();
    final targetPath =
        '${tempDir.path}/ultra_low_${DateTime.now().millisecondsSinceEpoch}.webp';

    final result = await FlutterImageCompress.compressAndGetFile(
      file.path,
      targetPath,
      quality: 20,
      minWidth: 320,
      minHeight: 240,
      format: CompressFormat.webp,
    );

    return result != null ? File(result.path) : file;
  }

  Future<LatLng?> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerScreen(
          initialLocation: selectedLocation,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        selectedLocation = result['location'] as LatLng?;
        selectedLocationInfo = result['locationInfo'] as LocationInfo?;
      });
    }
  }

  Future<void> _showImageSourceDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('เลือกแหล่งรูปภาพ'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('แกลเลอรี่'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromSource(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('กล้อง'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromSource(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImageFromSource(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);

      if (pickedFile != null) {
        final File originalFile = File(pickedFile.path);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('WebP Compression...'),
                ],
              ),
              duration: Duration(seconds: 10),
            ),
          );
        }

        // WebP Compression - เล็กกว่า JPEG 30%!
        final File? compressedFile =
            await _compressUntilUnderSize(originalFile, maxSizeKB: 60);

        if (compressedFile != null && mounted) {
          setState(() {
            selectedImage = compressedFile;
          });

          ScaffoldMessenger.of(context).hideCurrentSnackBar();

          final fileSizeKB = await compressedFile.length() ~/ 1024;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('รูปภาพ WebP สำเร็จ! (ขนาด: $fileSizeKB KB)'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ไม่สามารถประมวลผลรูปภาพได้'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('⚠️ Error in _pickImageFromSource: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการเลือกรูปภาพ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getDisplayAddress(LocationInfo locationInfo) {
    if (locationInfo.road != null && locationInfo.road!.isNotEmpty) {
      return locationInfo.fullAddress;
    }
    return locationInfo.shortAddress;
  }

  bool _hasAdditionalInfo(LocationInfo locationInfo) {
    return locationInfo.postcode != null && locationInfo.postcode!.isNotEmpty;
  }

  String _getAdditionalInfo(LocationInfo locationInfo) {
    List<String> additionalParts = [];

    if (locationInfo.postcode != null && locationInfo.postcode!.isNotEmpty) {
      additionalParts.add('รหัสไปรษณีย์: ${locationInfo.postcode}');
    }

    return additionalParts.join(' • ');
  }

  Future<void> _submitReport() async {
    if (isSubmitting) return;

    final isLoggedIn = await AuthService.ensureUserLoggedIn(context);
    if (!isLoggedIn) {
      return;
    }

    String? missingField = _validateRequiredFields();
    if (missingField != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('กรุณากรอกข้อมูล: $missingField'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      print('Starting optimized report submission...');

      await AuthService.debugAuthStatus();

      final currentUser = AuthService.currentUser;
      if (currentUser == null) {
        throw Exception('ไม่พบข้อมูลผู้ใช้ กรุณาล็อกอินใหม่');
      }

      final userId = currentUser.uid;
      print('👤 User ID: $userId');

      final canPost = await FirebaseService.canUserPostToday(userId).timeout(
        const Duration(seconds: 8), // ลด timeout
        onTimeout: () => throw TimeoutException(
            'ตรวจสอบสิทธิ์เกินเวลา', const Duration(seconds: 8)),
      );

      if (!canPost) {
        throw Exception(
            'เกินขีดจำกัด: โพสต์ได้สูงสุด 10 ครั้งต่อวัน กรุณารอ 24 ชั่วโมง');
      }

      LatLng? finalLocation = selectedLocation;
      LocationInfo? finalLocationInfo = selectedLocationInfo;

      if (finalLocation == null) {
        print('📍 กำลังขอตำแหน่งปัจจุบัน...');
        final currentLocation = await _getCurrentLocation();
        if (currentLocation != null) {
          finalLocation = currentLocation;
          finalLocationInfo =
              await GeocodingService.getLocationInfo(currentLocation);
          print('✅ ได้ตำแหน่ง: $finalLocation');
        } else {
          throw Exception('ไม่สามารถระบุตำแหน่งได้ กรุณาเลือกตำแหน่งด้วยตนเอง');
        }
      }

      print('Sending data to Firebase with optimized mode...');
      if (selectedImage != null) {
        final fileSizeKB = await selectedImage!.length() ~/ 1024;
        print('📷 Image size: $fileSizeKB KB');
      } else {
        print('📷 No image');
      }

      final reportId = await FirebaseService.submitReport(
        category: selectedCategory!,
        description: _detailController.text.trim(),
        location: finalLocation,
        district: finalLocationInfo?.district ?? 'ไม่ระบุ',
        province: finalLocationInfo?.province ?? 'ไม่ระบุ',
        imageFile: selectedImage,
        userId: userId,
      ).timeout(
        const Duration(seconds: 30), // ลด timeout สำหรับโหมดเร็ว
        onTimeout: () => throw TimeoutException(
            'การส่งรายงานเกินเวลา กรุณาตรวจสอบการเชื่อมต่ออินเทอร์เน็ต',
            const Duration(seconds: 30)),
      );

      print('✅ Submission successful: $reportId');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('สำเร็จ'),
            backgroundColor: Colors.green,
            duration: Duration(milliseconds: 800), // แสดงแป๊บเดียว
          ),
        );

        // Navigate ทันที
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const ListScreen(),
          ),
        );
      }
    } on TimeoutException catch (e) {
      print('⏰ Timeout Error: ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'ส่งรายงานไม่สำเร็จ: เกินเวลารอคอย กรุณาตรวจสอบการเชื่อมต่ออินเทอร์เน็ต'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      print('❌ Error in _submitReport: $e');
      if (mounted) {
        String errorMessage = 'เกิดข้อผิดพลาดในการส่งรายงาน';

        if (e.toString().contains('network') ||
            e.toString().contains('channel-error')) {
          errorMessage = 'ปัญหาการเชื่อมต่อเครือข่าย กรุณาตรวจสอบ WiFi/4G';
        } else if (e.toString().contains('permission')) {
          errorMessage = 'ไม่มีสิทธิ์ในการอัพโหลด กรุณาติดต่อผู้ดูแลระบบ';
        } else if (e.toString().contains('storage') ||
            e.toString().contains('Unable to establish connection')) {
          errorMessage = 'ปัญหาการอัพโหลดไฟล์ กรุณาลองส่งโดยไม่มีรูปภาพ';
        } else if (e.toString().contains('exceeded')) {
          errorMessage = 'ไฟล์รูปใหญ่เกินไป กรุณาลองถ่ายรูปใหม่';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('$errorMessage\n\nหากปัญหายังคงอยู่ ลองส่งโดยไม่มีรูปภาพ'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 8),
            action: SnackBarAction(
              label: 'ลองใหม่',
              textColor: Colors.white,
              onPressed: () {
                setState(() {
                  selectedImage = null;
                });
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text(
          'รายงานเหตุการณ์',
          style: TextStyle(
            fontWeight: FontWeight.w400,
            color: Colors.white,
            fontFamily: 'Kanit',
          ),
        ),
        centerTitle: true, // ให้ข้อความอยู่กลาง
        backgroundColor: const Color(0xFFFF9800),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom:
                math.max(MediaQuery.of(context).viewInsets.bottom + 20, 120),
          ),
          children: [
            // Dropdown หมวดหมู่
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButton<EventCategory>(
                isExpanded: true,
                underline: const SizedBox(),
                hint: const Text(
                  'เลือกประเภทเหตุการณ์ *',
                  style: TextStyle(fontFamily: 'Kanit'),
                ),
                value: selectedCategory,
                icon: const Icon(Icons.keyboard_arrow_down),
                onChanged: (value) {
                  setState(() => selectedCategory = value);
                },
                items: EventCategory.values.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width - 80,
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor:
                                category.color.withValues(alpha: 0.2),
                            child: Text(category.emoji),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child:                            Text(
                              category.label,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Kanit',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),

            // กล่องข้อความ
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _detailController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'รายละเอียดเหตุการณ์ *',
                  hintStyle: TextStyle(fontFamily: 'Kanit'),
                  border: InputBorder.none,
                ),
                style: const TextStyle(fontFamily: 'Kanit'),
              ),
            ),

            const SizedBox(height: 16),

            // เพิ่มรูปภาพ
            OutlinedButton.icon(
              onPressed: _showImageSourceDialog,
              icon: const Icon(Icons.add),
              label: const Text(
                'เพิ่มรูปภาพ (ไม่บังคับ)',
                style: TextStyle(fontFamily: 'Kanit'),
              ),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),

            // แสดงรูปที่เลือกแล้ว
            if (selectedImage != null) ...[
              const SizedBox(height: 16),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        selectedImage!,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedImage = null;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // ตำแหน่งที่เลือก
            GestureDetector(
              onTap: _pickLocation,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: selectedLocation != null
                              ? const Color(0xFF4673E5)
                              : Colors.grey.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'ตำแหน่งเหตุการณ์',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                            fontFamily: 'Kanit',
                          ),
                        ),
                        const Spacer(),
                        if (isLoadingLocation)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF4673E5)),
                            ),
                          )
                        else
                          Icon(
                            Icons.map,
                            color: Colors.grey.shade600,
                            size: 20,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (isLoadingLocation) ...[
                      Row(
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF4673E5)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'กำลังค้นหาตำแหน่งปัจจุบัน...',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                              fontFamily: 'Kanit',
                            ),
                          ),
                        ],
                      ),
                    ] else if (selectedLocation != null &&
                        selectedLocationInfo != null) ...[
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width - 64,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getDisplayAddress(selectedLocationInfo!),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                                fontFamily: 'Kanit',
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              softWrap: true,
                            ),
                            if (_hasAdditionalInfo(selectedLocationInfo!)) ...[
                              const SizedBox(height: 4),
                              Text(
                                _getAdditionalInfo(selectedLocationInfo!),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                  fontStyle: FontStyle.italic,
                                  fontFamily: 'Kanit',
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                softWrap: true,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4673E5).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '� ตำแหน่งปัจจุบัน (แตะเพื่อเปลี่ยน)',
                          style: TextStyle(
                            fontSize: 12,
                            color: const Color(0xFF4673E5),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ] else ...[
                      Text(
                        'ไม่สามารถระบุตำแหน่งปัจจุบันได้',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.red.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'แตะเพื่อเลือกตำแหน่งในแผนที่',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 80),

            // ปุ่มส่ง
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (selectedCategory == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('กรุณาเลือกประเภทเหตุการณ์')),
                        );
                        return;
                      }

                      if (_detailController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('กรุณากรอกรายละเอียด')),
                        );
                        return;
                      }

                      await _submitReport();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4673E5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: isSubmitting
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'กำลังส่ง...',
                          style: TextStyle(
                            fontSize: 18, 
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Kanit',
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.send,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'ส่ง',
                          style: TextStyle(
                            fontSize: 18, 
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Kanit',
                          ),
                        ),
                      ],
                    ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
