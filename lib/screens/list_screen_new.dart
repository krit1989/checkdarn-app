import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../widgets/comment_bottom_sheet.dart';
import '../utils/formatters.dart';
import '../models/event_model.dart';
import '../services/cleanup_service.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({super.key});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true, // ให้ข้อความอยู่กลาง
        backgroundColor: const Color(0xFFFF9800),
        elevation: 0,
        actions: [
          // ปุ่มดูสถิติและลบโพสต์เก่า
          IconButton(
            onPressed: _showCleanupStats,
            icon: const Icon(
              Icons.info_outline,
              color: Colors.white,
            ),
            tooltip: 'ดูสถิติโพสต์',
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
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // แถวที่ 1: emoji + หัวข้อเหตุการณ์ + badge
                            Row(
                              children: [
                                Text(
                                  _getCategoryEmoji(category),
                                  style: const TextStyle(fontSize: 20),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _getCategoryName(category),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF9800)
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFFFF9800)
                                          .withValues(alpha: 0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    _getCategoryName(category),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFF57C00),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // แถวที่ 2: รายละเอียด (ถ้ามี)
                            if (data['description'] != null &&
                                data['description'].toString().isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: const Text(
                                      '💬',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      '${data['description']}',
                                      style: TextStyle(
                                        fontSize: 20,
                                        color: Colors.grey[700],
                                        height: 1.3,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],

                            // แถวที่ 3: ตำแหน่ง/สถานที่
                            if (data['location'] != null &&
                                data['location'].toString().isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Text(
                                    '📍',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      '${data['location']}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],

                            // แถวที่ 4: ปุ่มดูแผนที่
                            const SizedBox(height: 8),
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
                                          style: TextStyle(fontSize: 14),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'ดูแผนที่',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.blue[800],
                                            fontWeight: FontWeight.w500,
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
                                          style: TextStyle(fontSize: 14),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'ดูแผนที่',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.blue[800],
                                            fontWeight: FontWeight.w500,
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
                              const SizedBox(height: 12),
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
                                                if (loadingProgress == null)
                                                  return child;
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
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        '📷',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'คลิกดูรูปภาพ',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        '🔍',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],

                            // แถวที่ 6: เวลา
                            if (timestamp != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Text(
                                    '🕐',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${DateTimeFormatters.formatDate(timestamp)} · ${DateTimeFormatters.formatTimestamp(timestamp)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
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
                          return SizedBox(
                            width: double.infinity,
                            child: TextButton(
                              onPressed: () =>
                                  _showCommentSheet(reportId, title, category),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.only(
                                    bottomLeft: Radius.circular(12),
                                    bottomRight: Radius.circular(12),
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.chat_bubble_outline,
                                    size: 13,
                                    color: Color(0xFFFF9800),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'แสดงความคิดเห็น',
                                    style: TextStyle(
                                      color: Color(0xFFFF9800),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (commentCount > 0) ...[
                                    const SizedBox(width: 4),
                                    Text(
                                      '($commentCount)',
                                      style: const TextStyle(
                                        color: Color(0xFFFF9800),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
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
