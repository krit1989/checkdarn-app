import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:async';
import '../models/event_model.dart';
import '../services/geocoding_service.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';
import '../services/smart_security_service.dart';
import '../services/notification_service.dart';
import '../widgets/location_picker_screen.dart';
import 'list_screen.dart';

class ReportScreen extends StatefulWidget {
  final LatLng? initialLocation;
  final LocationInfo? initialLocationInfo;

  const ReportScreen({
    super.key,
    this.initialLocation,
    this.initialLocationInfo,
  });

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  EventCategory? selectedCategory;
  final TextEditingController _detailController = TextEditingController();
  File? selectedImage;
  LatLng? selectedLocation;
  LocationInfo? selectedLocationInfo;
  final ImagePicker _picker = ImagePicker();
  bool isSubmitting = false;
  bool isLoadingLocation = false;
  bool hasUserSelectedLocation =
      false; // เพิ่ม flag เพื่อเช็คว่าผู้ใช้เลือกตำแหน่งแล้วหรือยัง

  @override
  void initState() {
    super.initState();
    _initializeSmartSecurity();

    // ใช้ข้อมูลเริ่มต้นที่ส่งมาจากการ Long Press บนแผนที่
    if (widget.initialLocation != null) {
      selectedLocation = widget.initialLocation;
      selectedLocationInfo = widget.initialLocationInfo;
      hasUserSelectedLocation = true; // ตั้งค่า flag เมื่อมีตำแหน่งเริ่มต้น
    }
    // ไม่โหลดตำแหน่งปัจจุบันอัตโนมัติ ให้ผู้ใช้เลือกเอง
  }

  Future<void> _initializeSmartSecurity() async {
    await SmartSecurityService.initialize();
    SmartSecurityService.setSecurityLevel(SecurityLevel.high);
  }

  Future<bool> _validateReportActionSimple({
    String? action,
    Map<String, dynamic>? context,
  }) async {
    try {
      final result = await SmartSecurityService.checkPageSecurity(
        'report_page',
        context: {
          'action': action ?? 'generic',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          ...(context ?? {}),
        },
      );
      return result.isAllowed;
    } catch (e) {
      print('Smart Security validation failed: $e');
      return false;
    }
  }

  String? _validateRequiredFields() {
    if (selectedCategory == null) {
      return 'ประเภทเหตุการณ์';
    }
    if (_detailController.text.trim().isEmpty) {
      return 'รายละเอียด';
    }
    if (!hasUserSelectedLocation || selectedLocation == null) {
      return 'ตำแหน่งเหตุการณ์';
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
    // ซ่อนคีย์บอร์ดก่อนไปหน้าเลือกพิกัด
    FocusScope.of(context).unfocus();

    // ถ้ายังไม่มีตำแหน่งที่เลือก ให้หาตำแหน่งปัจจุบันก่อน
    LatLng? initialLocation = selectedLocation;

    if (initialLocation == null) {
      setState(() {
        isLoadingLocation = true;
      });

      try {
        initialLocation = await _getCurrentLocation();
        if (initialLocation != null) {
          print('✅ Found current location for picker: $initialLocation');
        }
      } catch (e) {
        print('Error getting location for picker: $e');
      } finally {
        setState(() {
          isLoadingLocation = false;
        });
      }
    }

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerScreen(
          initialLocation:
              initialLocation, // ส่งตำแหน่งปัจจุบันหรือตำแหน่งที่เลือกไว้แล้ว
          autoLocateToCurrentPosition: true, // เด้งไปหาตำแหน่งปัจจุบันเลย
        ),
      ),
    );

    // ซ่อนคีย์บอร์ดอีกครั้งหลังจากกลับมาจากหน้าเลือกพิกัด
    if (mounted) {
      FocusScope.of(context).unfocus();
      // ใช้ postFrameCallback เพื่อให้แน่ใจว่าคีย์บอร์ดจะถูกซ่อนหลังจาก widget rebuild
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          FocusScope.of(context).unfocus();
        }
      });
    }

    if (result != null) {
      setState(() {
        selectedLocation = result['location'] as LatLng?;
        selectedLocationInfo = result['locationInfo'] as LocationInfo?;
        hasUserSelectedLocation =
            true; // ตั้งค่า flag เมื่อผู้ใช้เลือกตำแหน่งแล้ว
      });
    }
  }

  Future<void> _showImageSourceDialog() async {
    // ซ่อนคีย์บอร์ดก่อนแสดง dialog
    FocusScope.of(context).unfocus();

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'เลือกแหล่งรูปภาพ',
            style: TextStyle(fontFamily: 'NotoSansThai'),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text(
                  'แกลเลอรี่',
                  style: TextStyle(fontFamily: 'NotoSansThai'),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromSource(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text(
                  'กล้อง',
                  style: TextStyle(fontFamily: 'NotoSansThai'),
                ),
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
    // Smart Security validation for image upload
    if (!await _validateReportActionSimple(
      action: 'image_upload',
      context: {
        'source': source.toString(),
        'current_image_exists': selectedImage != null,
      },
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('การตรวจสอบความปลอดภัยล้มเหลว ไม่สามารถอัปโหลดรูปภาพได้'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

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
                  Text(
                    'WebP Compression...',
                    style: TextStyle(fontFamily: 'NotoSansThai'),
                  ),
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

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'อัพโหลดรูปภาพสำเร็จ!',
                style: const TextStyle(fontFamily: 'NotoSansThai'),
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'ไม่สามารถประมวลผลรูปภาพได้',
                style: TextStyle(fontFamily: 'NotoSansThai'),
              ),
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
            content: Text(
              'เกิดข้อผิดพลาดในการเลือกรูปภาพ: $e',
              style: const TextStyle(fontFamily: 'NotoSansThai'),
            ),
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

  Future<void> _submitReport() async {
    if (isSubmitting) return;

    // Smart Security validation - HIGH RISK operation
    if (!await _validateReportActionSimple(
      action: 'submit_report',
      context: {
        'report_category': selectedCategory?.name,
        'has_image': selectedImage != null,
        'has_location': selectedLocation != null,
        'detail_length': _detailController.text.length,
      },
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('การตรวจสอบความปลอดภัยล้มเหลว กรุณาลองใหม่อีกครั้ง'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final isLoggedIn = await AuthService.ensureUserLoggedIn(context);
    if (!isLoggedIn) {
      return;
    }

    String? missingField = _validateRequiredFields();
    if (missingField != null) {
      String errorMessage;
      if (missingField == 'ตำแหน่งเหตุการณ์') {
        errorMessage = 'กรุณาเลือกพิกัด: $missingField';
      } else {
        errorMessage = 'กรุณากรอกข้อมูล: $missingField';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorMessage,
            style: const TextStyle(fontFamily: 'NotoSansThai'),
          ),
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
        userName: currentUser.displayName ?? currentUser.email ?? 'ไม่ระบุชื่อ',
      ).timeout(
        const Duration(seconds: 30), // ลด timeout สำหรับโหมดเร็ว
        onTimeout: () => throw TimeoutException(
            'การส่งรายงานเกินเวลา กรุณาตรวจสอบการเชื่อมต่ออินเทอร์เน็ต',
            const Duration(seconds: 30)),
      );

      print('✅ Submission successful: $reportId');

      // 🔔 ทริกเกอร์การส่งแจ้งเตือนหลังโพสใหม่สำเร็จ
      try {
        print('🔔 Triggering notification for new post...');
        await NotificationService.triggerNewPostNotification(reportId);
        print('✅ Notification triggered successfully');
      } catch (notificationError) {
        print('⚠️ Notification error (non-critical): $notificationError');
        // ไม่ให้ error ของ notification ขัดขวางการโพส
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'สำเร็จ',
              style: TextStyle(fontFamily: 'NotoSansThai'),
            ),
            backgroundColor: Colors.green,
            duration: Duration(milliseconds: 800), // แสดงแป๊บเดียว
          ),
        );

        // เซ็ต flag ว่ามีโพสใหม่ เพื่อให้ MapScreen refresh cache
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('has_new_post', true);
        } catch (e) {
          print('Error setting new post flag: $e');
        }

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
              'ส่งรายงานไม่สำเร็จ: เกินเวลารอคอย กรุณาตรวจสอบการเชื่อมต่ออินเทอร์เน็ต',
              style: TextStyle(fontFamily: 'NotoSansThai'),
            ),
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
            content: Text(
              '$errorMessage\n\nหากปัญหายังคงอยู่ ลองส่งโดยไม่มีรูปภาพ',
              style: const TextStyle(fontFamily: 'NotoSansThai'),
            ),
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
    return GestureDetector(
      onTap: () {
        // ซ่อนคีย์บอร์ดเมื่อแตะบริเวณอื่น
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: const Text(
            'แจ้งอะไร?',
            style: TextStyle(
              fontFamily: 'NotoSansThai',
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          centerTitle: true, // ให้ข้อความอยู่กลาง
          backgroundColor:
              const Color(0xFFFFC107), // เปลี่ยนเป็นสีเหลืองแบบหน้าอื่นๆ
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.black,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        backgroundColor: const Color(0xFFEDF0F7),
        body: SafeArea(
          child: Column(
            children: [
              // เนื้อหาหลัก
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: 16,
                  ),
                  children: [
                    // Dropdown หมวดหมู่
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButton<EventCategory>(
                        isExpanded: true,
                        underline: const SizedBox(),
                        hint: const Text(
                          'เลือกประเภทเหตุการณ์ *',
                          style: TextStyle(
                            fontFamily: 'NotoSansThai',
                            color: Colors.black,
                          ),
                        ),
                        value: selectedCategory,
                        icon: const Icon(Icons.keyboard_arrow_down),
                        onChanged: (value) {
                          setState(() {
                            // ถ้าเปลี่ยนจาก animalLost ไปหมวดอื่น ให้ล้างรูปภาพ
                            if (selectedCategory == EventCategory.animalLost &&
                                value != EventCategory.animalLost) {
                              selectedImage = null;
                            }
                            selectedCategory = value;
                          });
                        },
                        items: EventCategory.values.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width - 80,
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: category
                                        .color, // ใช้สีเดียวกันกับ EventCategory model
                                    child: Text(category.emoji),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      category.label,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        fontFamily: 'NotoSansThai',
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
                        color: Colors.white.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _detailController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'รายละเอียด *',
                          hintStyle: TextStyle(
                            fontFamily: 'NotoSansThai',
                            color: Colors.black,
                          ),
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(
                          fontFamily: 'NotoSansThai',
                          color: Colors.black,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ตำแหน่งที่เลือก
                    GestureDetector(
                      onTap: _pickLocation,
                      child: Container(
                        height: 160, // กำหนดความสูงให้การ์ด
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withValues(alpha: 0.1),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: hasUserSelectedLocation &&
                                  selectedLocation != null
                              ? // แสดงแผนที่เต็มพื้นที่เมื่อเลือกตำแหน่งแล้ว
                              Stack(
                                  children: [
                                    // แผนที่เต็มพื้นที่
                                    FlutterMap(
                                      options: MapOptions(
                                        initialCenter: selectedLocation!,
                                        initialZoom: 16.0,
                                        interactionOptions:
                                            const InteractionOptions(
                                          flags: InteractiveFlag.none,
                                        ),
                                      ),
                                      children: [
                                        TileLayer(
                                          urlTemplate:
                                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                          userAgentPackageName:
                                              'com.example.check_darn',
                                        ),
                                        MarkerLayer(
                                          markers: [
                                            Marker(
                                              point: selectedLocation!,
                                              width: 50,
                                              height: 50,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withValues(
                                                              alpha: 0.3),
                                                      blurRadius: 4,
                                                    ),
                                                  ],
                                                ),
                                                child: const Icon(
                                                  Icons.location_on,
                                                  color: Color(0xFF4673E5),
                                                  size: 30,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    // ข้อมูลตำแหน่งด้านล่าง
                                    Positioned(
                                      bottom: 0,
                                      left: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              Colors.black
                                                  .withValues(alpha: 0.7),
                                            ],
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              selectedLocationInfo != null
                                                  ? _getDisplayAddress(
                                                      selectedLocationInfo!)
                                                  : 'กำลังโหลดข้อมูลที่อยู่...',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                                fontFamily: 'NotoSansThai',
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              'แตะเพื่อเปลี่ยนตำแหน่ง',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.white
                                                    .withValues(alpha: 0.8),
                                                fontFamily: 'NotoSansThai',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    // ไอคอน arrow ด้านขวาบน
                                    Positioned(
                                      top: 12,
                                      right: 12,
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.white
                                              .withValues(alpha: 0.9),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withValues(alpha: 0.2),
                                              blurRadius: 2,
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          Icons.arrow_forward_ios,
                                          color: Colors.grey.shade600,
                                          size: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : // แสดงการ์ดขาวสำหรับเลือกตำแหน่ง
                              Container(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (isLoadingLocation) ...[
                                        const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Color(0xFF4673E5)),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'กำลังค้นหาตำแหน่งปัจจุบัน...',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade600,
                                            fontStyle: FontStyle.italic,
                                            fontFamily: 'NotoSansThai',
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ] else ...[
                                        SvgPicture.asset(
                                          'assets/icons/report_screen/add_location.svg',
                                          width: 48,
                                          height: 48,
                                          colorFilter: const ColorFilter.mode(
                                            Color(0xFF4CAF50),
                                            BlendMode.srcIn,
                                          ),
                                          placeholderBuilder: (context) =>
                                              const Icon(
                                            Icons.add_location,
                                            size: 48,
                                            color: Color(0xFF4CAF50),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'คลิกเพื่อเลือกตำแหน่ง',
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: Colors.black,
                                            fontWeight: FontWeight.w500,
                                            fontFamily: 'NotoSansThai',
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'จะพาไปที่ตำแหน่งปัจจุบันของคุณ *',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade600,
                                            fontFamily: 'NotoSansThai',
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ข้อความอธิบายเกี่ยวกับการแนบรูปภาพ - แสดงเฉพาะเมื่อไม่ได้เลือก "สัตว์หาย"
                    if (selectedCategory != null &&
                        selectedCategory != EventCategory.animalLost) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.blue.shade600,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'สามารถแนบรูปภาพได้เฉพาะในหัวข้อ "สัตว์หาย" เท่านั้น\nเพื่อป้องกันเนื้อหาที่ไม่เหมาะสม',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade700,
                                  fontFamily: 'NotoSansThai',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // เพิ่มรูปภาพ - แสดงเฉพาะสำหรับหมวด "สัตว์หาย" เท่านั้น
                    if (selectedCategory == EventCategory.animalLost) ...[
                      DottedBorder(
                        borderType: BorderType.RRect,
                        radius: const Radius.circular(12),
                        dashPattern: const [8, 4],
                        color: Colors.grey.shade400,
                        strokeWidth: 1.0, // ลดจาก 1.5 เป็น 1.0
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: selectedImage != null
                              ? Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        selectedImage!,
                                        width: double.infinity,
                                        height: 340,
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
                                    Positioned(
                                      bottom: 8,
                                      left: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.black
                                              .withValues(alpha: 0.7),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: GestureDetector(
                                          onTap: _showImageSourceDialog,
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.edit,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                'เปลี่ยน',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontFamily: 'NotoSansThai',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : OutlinedButton.icon(
                                  onPressed: _showImageSourceDialog,
                                  icon: SvgPicture.asset(
                                    'assets/icons/report_screen/add_photo_alternate.svg',
                                    width: 48,
                                    height: 48,
                                    colorFilter: ColorFilter.mode(
                                      Colors.blue.shade600,
                                      BlendMode.srcIn,
                                    ),
                                    placeholderBuilder: (context) => Icon(
                                      Icons.add_photo_alternate,
                                      size: 48,
                                      color: Colors.blue.shade600,
                                    ),
                                  ),
                                  label: const Text(
                                    'เพิ่มรูปภาพ (ไม่บังคับ)',
                                    style: TextStyle(
                                      fontFamily: 'NotoSansThai',
                                      fontSize: 16,
                                      color: Colors.black,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 54, horizontal: 16),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    side: BorderSide.none,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // ปุ่มส่งชิดขอบล่าง
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
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
                                const SnackBar(
                                    content: Text('กรุณากรอกรายละเอียด')),
                              );
                              return;
                            }

                            await _submitReport();
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC107),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                          vertical: 12), // ลดจาก 16 เป็น 12
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
                                  color: Colors.black,
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'กำลังส่ง...',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'NotoSansThai',
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          )
                        : const Text(
                            'บันทึก',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'NotoSansThai',
                              color: Colors.black,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
