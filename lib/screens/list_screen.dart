import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/foundation.dart'; // สำหรับ kDebugMode
import 'package:geolocator/geolocator.dart';
import '../widgets/comment_bottom_sheet.dart';
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

  // ตัวแปรสำหรับ location filtering
  Position? _currentPosition;
  String? _currentProvince;
  bool _isLoadingLocation = false;
  static const double _searchRadiusKm = 30.0; // รัศมี 30km

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  // ฟังก์ชันหาตำแหน่งปัจจุบันและจังหวัด
  Future<void> _getCurrentLocation() async {
    try {
      setState(() => _isLoadingLocation = true);

      final position = await LocationService.getCurrentLocation();
      if (position != null) {
        setState(() => _currentPosition = position);

        // ดึงข้อมูลจังหวัด
        final locationInfo = await GeocodingService.getLocationInfo(
            LatLng(position.latitude, position.longitude));
        setState(() => _currentProvince = locationInfo?.province);

        print(
            'Debug: Current location - ${position.latitude}, ${position.longitude}');
        print('Debug: Current province - $_currentProvince');
      }
    } catch (e) {
      print('Error getting location: $e');
    } finally {
      setState(() => _isLoadingLocation = false);
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
      backgroundColor: Colors.transparent,
      builder: (context) => CommentBottomSheet(
        reportId: reportId,
        reportType: category, // ใช้ category แทน
      ),
    );
  }

  // ฟังก์ชันดึง emoji สำหรับ category
  String _getCategoryEmoji(String category) {
    try {
      final eventCategory = EventCategoryExtension.fromString(category);
      return eventCategory.emoji;
    } catch (e) {
      return '📋'; // fallback
    }
  }

  // ฟังก์ชันดึงชื่อหมวดหมู่ภาษาไทย
  String _getCategoryName(String category) {
    try {
      final eventCategory = EventCategoryExtension.fromString(category);
      return eventCategory.label;
    } catch (e) {
      return 'อื่นๆ'; // fallback
    }
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
          title: const Text('📊 สถิติโพสต์'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('📄 โพสต์ทั้งหมด: ${stats['total']} รายการ'),
              const SizedBox(height: 8),
              Text('✨ โพสต์สดใหม่ (48 ชม.): ${stats['fresh']} รายการ'),
              const SizedBox(height: 8),
              Text('🗑️ โพสต์เก่า: ${stats['old']} รายการ'),
              const SizedBox(height: 16),
              const Text(
                '💡 โพสต์จะถูกลบอัตโนมัติหลัง 48 ชั่วโมง\nเพื่อรักษาความสดใหม่ของข้อมูล',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ปิด'),
            ),
            if (stats['old']! > 0)
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  _performManualCleanup();
                },
                child: const Text('🧹 ลบโพสต์เก่าตอนนี้'),
              ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    }
  }

  // ฟังก์ชันลบโพสต์เก่าด้วยตนเอง
  Future<void> _performManualCleanup() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🧹 กำลังลบโพสต์เก่า...')),
      );

      final freshCount = await CleanupService.manualCleanup();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ ลบเสร็จแล้ว! เหลือโพสต์สดใหม่ $freshCount รายการ'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการลบ: $e')),
      );
    }
  }

  // Widget สำหรับหมุดตำแหน่งที่เลือก
  Widget _buildLocationMarker() {
    return SizedBox(
      width: 34.5, // เพิ่มจาก 23 เป็น 34.5 (1.5 เท่า)
      height: 45, // เพิ่มจาก 30 เป็น 45 (1.5 เท่า)
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ขาหมุดสีแดง (ส่วนล่าง) - ลดความกว้าง 60%
          Positioned(
            bottom: 0,
            child: Container(
              width: 3.6, // เพิ่มจาก 2.4 เป็น 3.6 (1.5 เท่า)
              height: 19.5, // เพิ่มจาก 13 เป็น 19.5 (1.5 เท่า)
              decoration: BoxDecoration(
                color: const Color(0xFFFF5252), // สีแดง
                borderRadius: BorderRadius.circular(1.8), // เพิ่มจาก 1.2
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
          // วงกลมสีฟ้า (ส่วนบน) - เพิ่มขนาด 1.5 เท่า
          Positioned(
            top: 0,
            child: Container(
              width: 26.25, // เพิ่มจาก 17.5 เป็น 26.25 (1.5 เท่า)
              height: 26.25, // เพิ่มจาก 17.5 เป็น 26.25 (1.5 เท่า)
              decoration: BoxDecoration(
                color: const Color(0xFF4673E5), // สีฟ้า
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2.25, // เพิ่มจาก 1.5 เป็น 2.25 (1.5 เท่า)
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 1.5),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.location_on,
                  color: Colors.white,
                  size: 13.5, // เพิ่มจาก 9 เป็น 13.5 (1.5 เท่า)
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ฟังก์ชันแสดงแผนที่เต็มจอ
  void _showMapDialog(double latitude, double longitude, String? locationName) {
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
                        width: 34.5,
                        height: 45,
                        point: LatLng(latitude, longitude),
                        child: _buildLocationMarker(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'รายการแจ้งเหตุ',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black,
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
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('reports')
            .where('timestamp',
                isGreaterThan: Timestamp.fromDate(DateTime.now().subtract(
                    const Duration(hours: 48)))) // แสดงเฉพาะโพสต์ใน 48 ชั่วโมง
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'เกิดข้อผิดพลาด: ${snapshot.error}',
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFFFF9800)),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'กำลังโหลดข้อมูล...',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
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
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'เริ่มต้นด้วยการแจ้งเหตุครั้งแรกของคุณ',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: const Color(0xFFFF9800),
            onRefresh: () async {
              // แทนการใช้ setState ที่ไม่จำเป็น
              // เราจะให้ StreamBuilder refresh เอง
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final doc = snapshot.data!.docs[index];
                final data = doc.data() as Map<String, dynamic>;
                final reportId = doc.id;

                // กรองด้วยระยะทาง 30km + จังหวัดเดียวกัน
                if (!_isWithinRange(data)) {
                  return const SizedBox
                      .shrink(); // ซ่อนโพสต์ที่ไม่อยู่ในเงื่อนไข
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

                // Debug: แสดงข้อมูล imageUrl ใน console
                if (imageUrl != null && imageUrl.isNotEmpty) {
                  print('Debug ListScreen - imageUrl found: $imageUrl');
                } else {
                  print('Debug ListScreen - No imageUrl for report: $reportId');
                }
                print(
                    'Debug ListScreen - All data keys: ${data.keys.toList()}');

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
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
                        padding:
                            const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // แถวที่ 1: emoji + หัวข้อเหตุการณ์
                            Row(
                              children: [
                                Text(
                                  _getCategoryEmoji(category),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontFamily: 'Kanit',
                                    fontWeight: FontWeight.w500, // Medium
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _getCategoryName(category),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500, // Medium
                                      color: Colors.black87,
                                      fontFamily: 'Kanit',
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),

                            // แถวที่ 2: รายละเอียด (ถ้ามี)
                            if (data['description'] != null &&
                                data['description'].toString().isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF9800)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
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
                                    fontFamily: 'Sarabun',
                                    fontWeight: FontWeight.w200,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],

                            // แถวที่ 3: ตำแหน่ง/สถานที่ + ระยะทาง
                            if (data['location'] != null &&
                                data['location'].toString().isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Text(
                                    '📍',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontFamily: 'Kanit',
                                      fontWeight: FontWeight.w400, // Regular
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      '${data['location']}${_getDistanceText(data)}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w400, // Regular
                                        fontFamily: 'Kanit',
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],

                            // แถวที่ 4: ปุ่มดูแผนที่
                            const SizedBox(height: 6),
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
                                      );
                                    },
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text(
                                          '🗺️',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontFamily: 'Kanit',
                                            fontWeight:
                                                FontWeight.w400, // Regular
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'ดูแผนที่',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.blue[800],
                                            fontWeight:
                                                FontWeight.w400, // Regular
                                            fontFamily: 'Kanit',
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
                                        data['location'] ?? 'ไม่ระบุสถานที่',
                                      );
                                    },
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text(
                                          '🗺️',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontFamily: 'Kanit',
                                            fontWeight:
                                                FontWeight.w400, // Regular
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'ดูแผนที่',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.blue[800],
                                            fontWeight:
                                                FontWeight.w400, // Regular
                                            fontFamily: 'Kanit',
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
                              const SizedBox(height: 10),
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
                                              loadingBuilder: (context, child,
                                                  loadingProgress) {
                                                if (loadingProgress == null) {
                                                  return child;
                                                }
                                                return const Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                    color: Colors.white,
                                                  ),
                                                );
                                              },
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                print(
                                                    'Error loading image: $error');
                                                print('Image URL: $imageUrl');
                                                return const Center(
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(Icons.broken_image,
                                                          size: 48,
                                                          color: Colors.white),
                                                      SizedBox(height: 8),
                                                      Text(
                                                          'ไม่สามารถโหลดรูปภาพได้',
                                                          style: TextStyle(
                                                              color: Colors
                                                                  .white)),
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
                                              icon: const Icon(Icons.close,
                                                  color: Colors.white,
                                                  size: 30),
                                              onPressed: () =>
                                                  Navigator.of(context).pop(),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                                child: IntrinsicWidth(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.grey[300]!,
                                        width: 1,
                                      ),
                                    ),
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      child: Row(
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
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],

                            // แถวที่ 6: เวลา
                            if (timestamp != null) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Text(
                                    '🕐',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontFamily: 'Kanit',
                                      fontWeight: FontWeight.w400, // Regular
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${DateTimeFormatters.formatDate(timestamp)} · ${DateTimeFormatters.formatTimestamp(timestamp)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontFamily: 'Kanit',
                                      fontWeight: FontWeight.w400, // Regular
                                    ),
                                  ),
                                ],
                              ),
                            ],

                            // แถวที่ 7: ชื่อคนโพส
                            const SizedBox(height: 6),
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
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                    fontFamily: 'Kanit',
                                    fontWeight: FontWeight.w400, // Regular
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
                          return InkWell(
                            onTap: () =>
                                _showCommentSheet(reportId, title, category),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
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
                                      fontFamily: 'Sarabun',
                                    ),
                                  ),
                                  if (commentCount > 0) ...[
                                    const SizedBox(width: 0),
                                    Text(
                                      ' ($commentCount)',
                                      style: const TextStyle(
                                        color: Color(0xFFFF9800),
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(width: 16), // เพิ่ม margin ขวา
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
