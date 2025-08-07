import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/foundation.dart'; // สำหรับ kDebugMode
import 'package:geolocator/geolocator.dart';
import 'package:popover/popover.dart';
import '../widgets/comment_bottom_sheet.dart';
import '../widgets/event_marker.dart'; // เพิ่ม import EventMarker
import '../utils/formatters.dart';
import '../models/event_model.dart';
import '../services/cleanup_service.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../services/geocoding_service.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({super.key});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cache สำหรับ EventCategory เพื่อประหยัดการแปลงซ้ำ
  final Map<String, EventCategory> _categoryCache = {};

  // ตัวแปรสำหรับ location filtering
  Position? _currentPosition;
  String? _currentProvince;
  bool _isLoadingLocation = false;
  static const double _searchRadiusKm = 30.0; // รัศมี 30km

  // 🎯 Filter variables
  EventCategory? _selectedCategory; // หมวดหมู่ที่เลือก (null = ทั้งหมด)
  bool _showMyPostsOnly = false; // แสดงเฉพาะโพสต์ของตัวเอง

  // 📖 Pagination variables
  static const int _pageSize = 20; // โหลดทีละ 20 รายการ
  DocumentSnapshot? _lastDocument;
  bool _hasMoreData = true;
  bool _isLoadingMore = false;
  final List<DocumentSnapshot> _allDocuments = [];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadMoreData(); // โหลดข้อมูลแรก
  }

  // ฟังก์ชันโหลดข้อมูลเพิ่มเติม (Pagination)
  // 🔍 Firebase Indexes ที่ใช้:
  // - timestamp (เวลา) - กรองโพสต์ใน 24 ชั่วโมงล่าสุด
  // - orderBy timestamp - เรียงจากใหม่ไปเก่า
  // 📝 Index ที่ต้องมีใน Firebase: timestamp (descending)
  Future<void> _loadMoreData() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() => _isLoadingMore = true);

    try {
      print('Debug: Starting to load data from Firestore...');

      // Query หลักสำหรับ List Screen: โพสต์ 24 ชั่วโมงล่าสุด
      final cutoffTime = DateTime.now().subtract(const Duration(hours: 24));
      print('Debug: Cutoff time: $cutoffTime');

      Query query = _firestore
          .collection('reports')
          .where('timestamp', isGreaterThan: Timestamp.fromDate(cutoffTime))
          .orderBy('timestamp', descending: true)
          .limit(_pageSize);

      // ถ้ามี lastDocument ให้เริ่มจากตรงนั้น
      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
        print('Debug: Continuing from last document: ${_lastDocument!.id}');
      }

      print('Debug: Executing Firestore query...');
      final snapshot = await query.get();
      print('Debug: Query completed. Found ${snapshot.docs.length} documents');

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
        _allDocuments.addAll(snapshot.docs);
        print(
            'Debug: Added ${snapshot.docs.length} documents. Total: ${_allDocuments.length}');

        // ถ้าได้ข้อมูลน้อยกว่า pageSize แสดงว่าหมดแล้ว
        if (snapshot.docs.length < _pageSize) {
          _hasMoreData = false;
          print('Debug: Reached end of data');
        }
      } else {
        _hasMoreData = false;
        print('Debug: No more documents found');
      }
    } catch (e, stackTrace) {
      print('Error loading more data: $e');
      print('Stack trace: $stackTrace');

      // แสดง error ให้ผู้ใช้เห็น
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ไม่สามารถโหลดข้อมูลได้: $e',
                style: TextStyle(fontFamily: 'NotoSansThai')),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'ลองใหม่',
              textColor: Colors.white,
              onPressed: () => _loadMoreData(),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      if (!mounted) return; // ตรวจสอบก่อน setState
      setState(() => _isLoadingLocation = true);

      final position = await LocationService.getCurrentLocation();
      if (position != null) {
        if (!mounted) return; // ตรวจสอบก่อน setState
        setState(() => _currentPosition = position);

        // ดึงข้อมูลจังหวัด
        final locationInfo = await GeocodingService.getLocationInfo(
            LatLng(position.latitude, position.longitude));
        if (!mounted) return; // ตรวจสอบก่อน setState
        setState(() => _currentProvince = locationInfo?.province);

        print(
            'Debug: Current location - ${position.latitude}, ${position.longitude}');
        print('Debug: Current province - $_currentProvince');
      }
    } catch (e) {
      print('Error getting location: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  // ฟังก์ชันตรวจสอบว่าโพสต์อยู่ในรัศมีและจังหวัดที่กำหนดหรือไม่
  bool _isWithinRange(Map<String, dynamic> data) {
    // ถ้าไม่มีตำแหน่งปัจจุบัน ให้แสดงทุกโพสต์
    if (_currentPosition == null) return true;

    // ตรวจสอบพิกัดของโพสต์
    final postLat = data['lat']?.toDouble() ?? data['latitude']?.toDouble();
    final postLng = data['lng']?.toDouble() ?? data['longitude']?.toDouble();

    if (postLat == null || postLng == null) {
      return true; // ถ้าไม่มีพิกัด ให้แสดง
    }

    // คำนวณระยะทาง
    final distanceInMeters = LocationService.calculateDistance(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      postLat,
      postLng,
    );

    final distanceInKm = distanceInMeters / 1000;

    // ตรวจสอบว่าอยู่ในรัศมี 30km หรือไม่
    if (distanceInKm <= _searchRadiusKm) return true;

    // ถ้าไม่อยู่ในรัศมี แต่อยู่ในจังหวัดเดียวกัน ก็ให้แสดง
    final postProvince = data['province'] as String?;
    if (_currentProvince != null && postProvince == _currentProvince) {
      return true;
    }

    return false;
  }

  // ฟังก์ชันแสดงระยะทาง
  String _getDistanceText(Map<String, dynamic> data) {
    if (_currentPosition == null) return '';

    final postLat = data['lat']?.toDouble() ?? data['latitude']?.toDouble();
    final postLng = data['lng']?.toDouble() ?? data['longitude']?.toDouble();

    if (postLat == null || postLng == null) return '';

    final distanceInMeters = LocationService.calculateDistance(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      postLat,
      postLng,
    );

    final distanceInKm = distanceInMeters / 1000;

    if (distanceInKm < 1.0) {
      return ' (${distanceInMeters.round()} ม.)';
    } else {
      return ' (${distanceInKm.toStringAsFixed(1)} กม.)';
    }
  }

  void _showCommentSheet(String reportId, String title, String category) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true, // ใช้ root navigator สำหรับประสิทธิภาพที่ดีกว่า
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54, // เพิ่มสีพื้นหลังเมื่อแสดงป๊อปอัพ
      isDismissible: true,
      enableDrag: true,
      useSafeArea: true,
      clipBehavior: Clip.antiAlias,
      builder: (context) => CommentBottomSheet(
        reportId: reportId,
        reportType: category, // ใช้ category แทน
      ),
    );
  }

  // ฟังก์ชันดึง EventCategory แบบ cache เพื่อประหยัดการแปลงซ้ำ
  EventCategory _getCachedCategory(String categoryString) {
    return _categoryCache.putIfAbsent(categoryString, () {
      try {
        return EventCategoryExtension.fromString(categoryString);
      } catch (e) {
        return EventCategory.checkpoint; // fallback
      }
    });
  }

  // ฟังก์ชันดึง emoji สำหรับ category (เก็บไว้เพื่อ backward compatibility)
  String _getCategoryEmoji(String category) {
    final eventCategory = _getCachedCategory(category);
    return eventCategory.emoji;
  }

  // ฟังก์ชันดึงชื่อหมวดหมู่ภาษาไทย (เก็บไว้เพื่อ backward compatibility)
  String _getCategoryName(String category) {
    final eventCategory = _getCachedCategory(category);
    return eventCategory.label;
  }

  // ดึงชื่อคนโพสแบบ masked
  String _getMaskedPosterName(Map<String, dynamic> data) {
    final userId = data['userId'] as String?;

    if (userId == null || userId.isEmpty) {
      return 'ผู้ใช้ไม่ระบุชื่อ';
    }

    // ถ้าเป็นผู้ใช้ปัจจุบัน ใช้ AuthService
    if (AuthService.currentUser?.uid == userId) {
      return AuthService.getMaskedDisplayName();
    }

    // ถ้ามี displayName ใน data ให้ใช้ชื่อนั้น
    if (data['displayName'] != null &&
        data['displayName'].toString().isNotEmpty) {
      return _maskDisplayName(data['displayName'].toString());
    }

    // ถ้าไม่มี displayName ให้ mask userId
    if (userId == 'anonymous') {
      return 'ผู้ใช้ไม่ระบุชื่อ';
    }

    // Mask userId
    if (userId.length <= 8) return userId;
    return '${userId.substring(0, 4)}${'*' * (userId.length - 4)}';
  }

  // ฟังก์ชัน mask ชื่อ (คล้ายกับใน AuthService)
  String _maskDisplayName(String name) {
    final parts = name.trim().split(' ');

    if (parts.isEmpty) return 'ผู้ใช้ไม่ระบุชื่อ';

    if (parts.length == 1) {
      // ถ้ามีคำเดียว เช่น "kritchapon" -> "krit*****"
      final firstPart = parts[0];
      if (firstPart.length <= 4) {
        return firstPart; // ถ้าสั้นเกินไป ไม่ mask
      }
      return '${firstPart.substring(0, 4)}${'*' * (firstPart.length - 4)}';
    } else {
      // ถ้ามีหลายคำ เช่น "kritchapon prommali" -> "kritchapon *******"
      final firstName = parts[0];
      final lastNameLength = parts.sublist(1).join(' ').length;
      return '$firstName ${'*' * lastNameLength}';
    }
  }

  // ฟังก์ชันแสดงสถิติและ cleanup
  Future<void> _showCleanupStats() async {
    try {
      final stats = await CleanupService.getPostStatistics();

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('📊 สถิติโพสต์',
              style: TextStyle(fontFamily: 'NotoSansThai')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('📄 โพสต์ทั้งหมด: ${stats['total']} รายการ',
                  style: TextStyle(fontFamily: 'NotoSansThai')),
              const SizedBox(height: 8),
              Text('✨ โพสต์สดใหม่ (24 ชม.): ${stats['fresh']} รายการ',
                  style: TextStyle(fontFamily: 'NotoSansThai')),
              const SizedBox(height: 8),
              Text('🗑️ โพสต์เก่า: ${stats['old']} รายการ',
                  style: TextStyle(fontFamily: 'NotoSansThai')),
              const SizedBox(height: 16),
              const Text(
                '💡 โพสต์จะถูกลบอัตโนมัติหลัง 24 ชั่วโมง\nเพื่อรักษาความสดใหม่ของข้อมูล',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontFamily: 'NotoSansThai'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ปิด',
                  style: TextStyle(fontFamily: 'NotoSansThai')),
            ),
            if (stats['old']! > 0)
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  _performManualCleanup();
                },
                child: const Text('🧹 ลบโพสต์เก่าตอนนี้',
                    style: TextStyle(fontFamily: 'NotoSansThai')),
              ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e',
                style: TextStyle(fontFamily: 'NotoSansThai'))),
      );
    }
  }

  // ฟังก์ชันลบโพสต์เก่าด้วยตนเอง
  Future<void> _performManualCleanup() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('🧹 กำลังลบโพสต์เก่า...',
                style: TextStyle(fontFamily: 'NotoSansThai'))),
      );

      final freshCount = await CleanupService.manualCleanup();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ ลบเสร็จแล้ว! เหลือโพสต์สดใหม่ $freshCount รายการ',
              style: TextStyle(fontFamily: 'NotoSansThai')),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('เกิดข้อผิดพลาดในการลบ: $e',
                style: TextStyle(fontFamily: 'NotoSansThai'))),
      );
    }
  }

  // ฟังก์ชันแสดงแผนที่เต็มจอ
  void _showMapDialog(double latitude, double longitude, String? locationName,
      String category) {
    // ใช้ cached category แทนการแปลงใหม่
    final eventCategory = _getCachedCategory(category);

    showDialog(
      context: context,
      barrierDismissible: true,
      useSafeArea: false,
      builder: (context) => Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // แสดงแผนที่จริงเต็มจอ
            SizedBox.expand(
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(latitude, longitude),
                  initialZoom: 16.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.check_darn',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        width: 55.0,
                        height: 55.0,
                        point: LatLng(latitude, longitude),
                        child: EventMarker(
                          category: eventCategory,
                          scale:
                              1.2, // ขยายให้ใหญ่ขึ้นเล็กน้อยเพื่อให้เห็นชัดในแผนที่
                          isPost:
                              true, // เพิ่มการกำหนดให้เป็นหมุดโพส เพื่อแสดง emoji
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // ปุ่มปิด
            Positioned(
              top: MediaQuery.of(context).padding.top + 20,
              right: 20,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
            // ข้อมูลตำแหน่ง
            if (locationName != null)
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 40,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    locationName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'NotoSansThai',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 🔄 รีเฟรชข้อมูลเมื่อเปลี่ยน Filter
  void _refreshWithNewFilter() {
    _allDocuments.clear();
    _lastDocument = null;
    _hasMoreData = true;
    _loadMoreData();
  }

  // 🎯 แสดง Filter Popover โดยให้ลูกศรฟิกกับไอคอน แต่เนื้อหาขยับเล็กน้อย
  void _showFilterPopover(BuildContext context) {
    showPopover(
      context: context,
      bodyBuilder: (context) => Transform.translate(
        offset: const Offset(
            -5, 0), // ขยับเฉพาะเนื้อหาไปทางซ้าย 20px (ลดลงจาก 50px)
        child: _buildFilterPopover(context),
      ),
      direction: PopoverDirection.bottom,
      backgroundColor: Colors.white, // เปลี่ยนกลับเป็นสีขาวเพื่อให้เห็นลูกศร
      radius: 12,
      shadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.15),
          blurRadius: 20,
          offset: const Offset(0, 8),
          spreadRadius: 2,
        ),
      ],
      arrowHeight: 8,
      arrowWidth: 16,
      width: 300, // เพิ่มความกว้างเป็น 300px
      height: null,
    );
  }

  // 🎯 สร้าง Filter Popover Widget
  Widget _buildFilterPopover(BuildContext context) {
    return Container(
      width: 300, // เพิ่มความกว้างเป็น 300px
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6, // 60% ของความสูงจอ
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ทั้งหมด
            _buildFilterOption(
              emoji: '📋',
              title: 'ทั้งหมด',
              isSelected: _selectedCategory == null && !_showMyPostsOnly,
              onTap: () {
                setState(() {
                  _selectedCategory = null;
                  _showMyPostsOnly = false;
                  _refreshWithNewFilter();
                });
                Navigator.of(context).pop();
              },
            ),

            // หมวดหมู่ต่างๆ
            ...EventCategory.values.map(
              (category) => _buildFilterOption(
                emoji: category.emoji,
                title: category.label,
                isSelected: _selectedCategory == category,
                onTap: () {
                  setState(() {
                    _selectedCategory = category;
                    _showMyPostsOnly = false;
                    _refreshWithNewFilter();
                  });
                  Navigator.of(context).pop();
                },
              ),
            ),

            // แบ่งคั่น
            const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),

            // โพสต์ของฉัน
            _buildFilterOption(
              emoji: '👤',
              title: 'โพสต์ของฉัน',
              isSelected: _showMyPostsOnly,
              onTap: () {
                setState(() {
                  _showMyPostsOnly = !_showMyPostsOnly;
                  _selectedCategory = null;
                  _refreshWithNewFilter();
                });
                Navigator.of(context).pop();
              },
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // 🎯 สร้าง Filter Option Widget
  Widget _buildFilterOption({
    required String emoji,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
            16, 12, 24, 12), // เพิ่ม padding ขวาเป็น 24px
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? Colors.black : Colors.grey[700],
                  fontFamily: 'NotoSansThai',
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDF0F7),
      appBar: AppBar(
        title: const Text(
          'ใกล้ฉัน',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black,
            fontFamily: 'NotoSansThai',
          ),
        ),
        centerTitle: true, // ให้ข้อความอยู่กลาง
        backgroundColor: const Color(0xFFFDC621),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.black,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // 🎯 Filter Popover ด้านขวา (ขยับไปซ้าย)
          Padding(
            padding: const EdgeInsets.only(right: 20), // ขยับปุ่มไปซ้าย 20px
            child: Builder(
              builder: (context) => IconButton(
                onPressed: () => _showFilterPopover(context),
                icon: Stack(
                  children: [
                    const Icon(
                      Icons.filter_list,
                      color: Colors.black,
                      size: 24,
                    ),
                    // แสดง badge เมื่อมี filter ทำงาน
                    if (_selectedCategory != null || _showMyPostsOnly)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // ปุ่มดูสถิติและลบโพสต์เก่า (แสดงเฉพาะในโหมด debug/dev)
          if (kDebugMode) // แสดงเฉพาะใน debug mode
            IconButton(
              onPressed: _showCleanupStats,
              icon: const Icon(
                Icons.info_outline,
                color: Colors.black,
              ),
              tooltip: 'ดูสถิติโพสต์ (Dev Only)',
            ),
          // แสดงสถานะการโหลดตำแหน่ง
          if (_isLoadingLocation)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Main Content (ลบ Filter Chips Section ออก)
          Expanded(
            child: RefreshIndicator(
              color: const Color(0xFFFF9800),
              onRefresh: () async {
                // รีเซ็ต pagination และโหลดใหม่
                _allDocuments.clear();
                _lastDocument = null;
                _hasMoreData = true;
                await _loadMoreData();
              },
              child: _allDocuments.isEmpty && !_isLoadingMore
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'ยังไม่มีรายการแจ้งเหตุ',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'NotoSansThai',
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'เริ่มต้นด้วยการแจ้งเหตุครั้งแรกของคุณ',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                              fontFamily: 'NotoSansThai',
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8.0),
                      itemCount: _allDocuments.length + (_hasMoreData ? 1 : 0),
                      itemBuilder: (context, index) {
                        // แสดง loading indicator ที่ด้านล่าง
                        if (index == _allDocuments.length) {
                          if (!_isLoadingMore && _hasMoreData) {
                            // Trigger load more เมื่อเลื่อนถึงด้านล่าง
                            Future.delayed(Duration.zero, _loadMoreData);
                          }
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFFFF9800)),
                              ),
                            ),
                          );
                        }

                        final doc = _allDocuments[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final reportId = doc.id;

                        // กรองด้วยระยะทาง 30km + จังหวัดเดียวกัน
                        if (!_isWithinRange(data)) {
                          return const SizedBox
                              .shrink(); // ซ่อนโพสต์ที่ไม่อยู่ในเงื่อนไข
                        }

                        // 🎯 Filter by category
                        if (_selectedCategory != null) {
                          final postCategory =
                              data['category'] ?? data['type'] ?? 'other';
                          final eventCategory =
                              _getCachedCategory(postCategory);
                          if (eventCategory != _selectedCategory) {
                            return const SizedBox.shrink();
                          }
                        }

                        // 🎯 Filter by "My Posts Only"
                        if (_showMyPostsOnly) {
                          final postUserId = data['userId'] as String?;
                          final currentUserId = AuthService.currentUser?.uid;
                          if (postUserId != currentUserId) {
                            return const SizedBox.shrink();
                          }
                        }

                        final title = data['title'] ??
                            data['description']
                                ?.toString()
                                .split(' ')
                                .take(3)
                                .join(' ') ??
                            'ไม่มีหัวข้อ';
                        final imageUrl = data['imageUrl'] as String?;
                        final timestamp = data['timestamp'] as Timestamp?;
                        final category = data['category'] ??
                            data['type'] ??
                            'other'; // fallback ถ้าไม่มี category

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          elevation: 2,
                          color: Colors.white, // เปลี่ยนพื้นหลังเป็นสีขาว
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Main content
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    16.0, 16.0, 16.0, 8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // แถวที่ 1: emoji + หัวข้อเหตุการณ์ + เวลาที่ผ่านมา
                                    Row(
                                      children: [
                                        Text(
                                          _getCategoryEmoji(category),
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontFamily: 'NotoSansThai',
                                            fontWeight:
                                                FontWeight.w500, // Medium
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _getCategoryName(category),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight:
                                                  FontWeight.w500, // Medium
                                              color: Colors.black87,
                                              fontFamily: 'NotoSansThai',
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        // เวลาที่ผ่านมา
                                        if (timestamp != null) ...[
                                          Text(
                                            DateTimeFormatters.formatTimestamp(
                                                timestamp),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.w400,
                                              fontFamily: 'NotoSansThai',
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),

                                    // แถวที่ 2: รายละเอียด (ถ้ามี)
                                    if (data['description'] != null &&
                                        data['description']
                                            .toString()
                                            .isNotEmpty) ...[
                                      const SizedBox(height: 5),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFF9800)
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color: const Color(0xFFFF9800)
                                                .withValues(alpha: 0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          '${data['description']}',
                                          style: const TextStyle(
                                            fontSize: 17,
                                            color: Colors.black,
                                            height: 1.3,
                                            fontFamily: 'NotoSansThai',
                                            fontWeight: FontWeight.w400,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],

                                    // แถวที่ 3: ตำแหน่ง/สถานที่ + ระยะทาง
                                    if (data['location'] != null &&
                                        data['location']
                                            .toString()
                                            .isNotEmpty) ...[
                                      const SizedBox(height: 5),
                                      Row(
                                        children: [
                                          const Text(
                                            '📍',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontFamily: 'NotoSansThai',
                                              fontWeight:
                                                  FontWeight.w400, // Regular
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              '${data['location']}${_getDistanceText(data)}',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.black,
                                                fontWeight:
                                                    FontWeight.w400, // Regular
                                                fontFamily: 'NotoSansThai',
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],

                                    // แถวที่ 4: ปุ่มดูแผนที่
                                    const SizedBox(height: 5),
                                    Row(
                                      children: [
                                        // ปุ่มดูแผนที่ด้านซ้าย (ลบการ์ดออก แค่แสดง emoji + text)
                                        if (data['lat'] != null &&
                                            data['lng'] != null) ...[
                                          GestureDetector(
                                            onTap: () {
                                              _showMapDialog(
                                                data['lat'].toDouble(),
                                                data['lng'].toDouble(),
                                                data['location']?.toString(),
                                                category, // เพิ่ม category parameter
                                              );
                                            },
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Text(
                                                  '🗺️',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontFamily: 'NotoSansThai',
                                                    fontWeight: FontWeight
                                                        .w400, // Regular
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'ดูแผนที่',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.blue[800],
                                                    fontWeight: FontWeight
                                                        .w400, // Regular
                                                    fontFamily: 'NotoSansThai',
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ] else if (data['latitude'] != null &&
                                            data['longitude'] != null) ...[
                                          GestureDetector(
                                            onTap: () {
                                              _showMapDialog(
                                                data['latitude'].toDouble(),
                                                data['longitude'].toDouble(),
                                                data['location'] ??
                                                    'ไม่ระบุสถานที่',
                                                category, // เพิ่ม category parameter
                                              );
                                            },
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Text(
                                                  '🗺️',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontFamily: 'NotoSansThai',
                                                    fontWeight: FontWeight
                                                        .w400, // Regular
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'ดูแผนที่',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.blue[800],
                                                    fontWeight: FontWeight
                                                        .w400, // Regular
                                                    fontFamily: 'NotoSansThai',
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),

                                    // แถวที่ 5: รูปภาพ (ถ้ามี)
                                    if (imageUrl != null &&
                                        imageUrl.isNotEmpty &&
                                        imageUrl.trim() != '') ...[
                                      const SizedBox(height: 5),
                                      GestureDetector(
                                        onTap: () {
                                          // แสดงรูปภาพแบบเต็มจอเมื่อคลิก
                                          showDialog(
                                            context: context,
                                            builder: (context) => Dialog(
                                              backgroundColor: Colors.black,
                                              child: Stack(
                                                children: [
                                                  Center(
                                                    child: Image.network(
                                                      imageUrl,
                                                      fit: BoxFit.contain,
                                                      loadingBuilder: (context,
                                                          child,
                                                          loadingProgress) {
                                                        if (loadingProgress ==
                                                            null) {
                                                          return child;
                                                        }
                                                        return const Center(
                                                          child:
                                                              CircularProgressIndicator(
                                                            color: Colors.white,
                                                          ),
                                                        );
                                                      },
                                                      errorBuilder: (context,
                                                          error, stackTrace) {
                                                        print(
                                                            'Error loading image: $error');
                                                        print(
                                                            'Image URL: $imageUrl');
                                                        return const Center(
                                                          child: Column(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            children: [
                                                              Icon(
                                                                  Icons
                                                                      .broken_image,
                                                                  size: 48,
                                                                  color: Colors
                                                                      .white),
                                                              SizedBox(
                                                                  height: 8),
                                                              Text(
                                                                  'ไม่สามารถโหลดรูปภาพได้',
                                                                  style: TextStyle(
                                                                      color: Colors
                                                                          .white,
                                                                      fontFamily:
                                                                          'NotoSansThai')),
                                                            ],
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                  Positioned(
                                                    top: 40,
                                                    right: 20,
                                                    child: IconButton(
                                                      icon: const Icon(
                                                          Icons.close,
                                                          color: Colors.white,
                                                          size: 30),
                                                      onPressed: () =>
                                                          Navigator.of(context)
                                                              .pop(),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              '📷',
                                              style: TextStyle(fontSize: 13),
                                            ),
                                            SizedBox(width: 6),
                                            Text(
                                              'คลิกดูรูปภาพ',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w400,
                                                color: Colors.black87,
                                                fontFamily: 'NotoSansThai',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],

                                    // แถวที่ 6: วันเดือนปี เวลาที่โพสต์
                                    if (timestamp != null) ...[
                                      const SizedBox(height: 5),
                                      Row(
                                        children: [
                                          const Text(
                                            '🗓️',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontFamily: 'NotoSansThai',
                                              fontWeight:
                                                  FontWeight.w400, // Regular
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            DateTimeFormatters.formatDate(
                                                timestamp),
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.black,
                                              fontFamily: 'NotoSansThai',
                                              fontWeight:
                                                  FontWeight.w400, // Regular
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],

                                    // แถวที่ 7: ชื่อคนโพส
                                    const SizedBox(height: 5),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.person_outline,
                                          size: 16,
                                          color: Colors.red,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _getMaskedPosterName(data),
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.black,
                                            fontFamily: 'NotoSansThai',
                                            fontWeight:
                                                FontWeight.w400, // Regular
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Comment button for all posts (moved to bottom)
                              const Divider(height: 1),
                              FutureBuilder<QuerySnapshot>(
                                future: FirebaseFirestore.instance
                                    .collection('reports')
                                    .doc(reportId)
                                    .collection('comments')
                                    .get(),
                                builder: (context, snapshot) {
                                  int commentCount = 0;
                                  if (snapshot.hasData) {
                                    commentCount = snapshot.data!.docs.length;
                                  }
                                  return Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 9),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        // ส่วนที่ไม่สามารถกดได้
                                        const Spacer(),
                                        // ส่วนที่กดได้ (เฉพาะไอคอนและข้อความ)
                                        InkWell(
                                          onTap: () => _showCommentSheet(
                                              reportId, title, category),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.chat_bubble_outline,
                                                  size: 16,
                                                  color: Color(0xFFFF9800),
                                                ),
                                                const SizedBox(width: 4),
                                                const Text(
                                                  'ความคิดเห็น',
                                                  style: TextStyle(
                                                    color: Color(0xFFFF9800),
                                                    fontWeight: FontWeight.w200,
                                                    fontSize: 14,
                                                    fontFamily: 'NotoSansThai',
                                                  ),
                                                ),
                                                if (commentCount > 0) ...[
                                                  const SizedBox(width: 0),
                                                  Text(
                                                    ' ($commentCount)',
                                                    style: const TextStyle(
                                                      color: Color(0xFFFF9800),
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(
                                            width: 16), // เพิ่ม margin ขวา
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
