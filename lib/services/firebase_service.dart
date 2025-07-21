import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;
import 'dart:io';
import 'dart:async';
import '../models/event_model.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static const String _collection = 'reports';
  static const int _maxPostsPerDay = 10; // จำกัด 10 โพสต์ต่อคนต่อวัน

  // 🚀 Cache สำหรับ Smart Prefetch
  static List<QueryDocumentSnapshot>? _cachedReports;
  static DateTime? _lastCacheTime;
  static const Duration _cacheValidDuration = Duration(minutes: 5);

  /// 🚀 Smart Prefetch System - โหลดข้อมูลล่วงหน้าแบบฉลาด
  static Future<void> prefetchRecentReports() async {
    try {
      print('🚀 Starting smart prefetch...');

      // ดึงข้อมูลล่วงหน้าและเก็บใน cache
      final snapshot = await _firestore
          .collection(_collection)
          .where('status', isEqualTo: 'active')
          .orderBy('timestamp', descending: true)
          .limit(15) // โหลดข้อมูลล่วงหน้า 15 รายการ
          .get(const GetOptions(source: Source.server)) // บังคับจากเซิร์ฟเวอร์
          .timeout(const Duration(seconds: 10));

      _cachedReports = snapshot.docs;
      _lastCacheTime = DateTime.now();

      print('✅ Prefetch completed: ${snapshot.docs.length} reports cached');
    } catch (e) {
      print('⚠️ Prefetch failed (non-critical): $e');
    }
  }

  /// 🚀 ตรวจสอบว่ามี cache ที่ใช้ได้หรือไม่
  static bool _isCacheValid() {
    if (_cachedReports == null || _lastCacheTime == null) return false;
    return DateTime.now().difference(_lastCacheTime!) < _cacheValidDuration;
  }

  /// อัพโหลดรูปภาพไป Firebase Storage พร้อม retry mechanism
  static Future<String?> uploadImage(File imageFile, String reportId) async {
    return _uploadImageWithRetry(imageFile, reportId, maxRetries: 2);
  }

  /// อัพโหลดรูปภาพพร้อม retry mechanism
  static Future<String?> _uploadImageWithRetry(
    File imageFile,
    String reportId, {
    int maxRetries = 2,
    int currentAttempt = 1,
  }) async {
    try {
      print(
          '📤 Starting image upload (attempt $currentAttempt/$maxRetries)...');

      // ตรวจสอบว่าไฟล์มีอยู่จริง
      if (!await imageFile.exists()) {
        print('❌ Image file does not exist: ${imageFile.path}');
        return null;
      }

      // ตรวจสอบขนาดไฟล์
      final fileSize = await imageFile.length();
      print('📁 File size: ${fileSize ~/ 1024} KB');

      if (fileSize > 5 * 1024 * 1024) {
        // 5MB limit
        print('❌ File too large: ${fileSize ~/ 1024} KB (max 5MB)');
        return null;
      }

      // สร้าง path สำหรับเก็บรูปภาพ
      final String fileName =
          'report_${reportId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference ref =
          _storage.ref().child('report_images').child(fileName);

      print('🌐 Uploading to: report_images/$fileName');

      // สร้าง metadata ที่ชัดเจนเพื่อป้องกัน NullPointerException
      final SettableMetadata metadata = SettableMetadata(
        contentType: 'image/jpeg',
        cacheControl: 'max-age=86400', // 1 day cache
        customMetadata: {
          'reportId': reportId,
          'uploadTime': DateTime.now().toIso8601String(),
        },
      );

      // อัพโหลดรูปภาพพร้อม metadata ที่ครบถ้วน
      final UploadTask uploadTask = ref.putFile(imageFile, metadata);

      // ติดตาม progress (แต่ไม่บล็อก)
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress =
            (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        print('📈 Upload progress: ${progress.toInt()}%');
      }, onError: (error) {
        print('⚠️ Upload progress error: $error');
      });

      // เพิ่มเวลา timeout และจัดการข้อผิดพลาดให้ดีขึ้น
      final TaskSnapshot snapshot = await uploadTask.timeout(
        const Duration(seconds: 30), // ลดเวลาลงเพื่อล้ม fast fail
        onTimeout: () => throw TimeoutException(
            'Image upload timeout - network may be slow',
            const Duration(seconds: 30)),
      );

      // ดึง download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      print('✅ Image uploaded successfully: $downloadUrl');

      return downloadUrl;
    } on TimeoutException catch (e) {
      print('⏰ Image upload timeout: ${e.message}');

      // ลอง retry หากยังไม่เกิน maxRetries
      if (currentAttempt < maxRetries) {
        print('🔄 Retrying upload... ($currentAttempt/$maxRetries)');
        await Future.delayed(
            const Duration(seconds: 2)); // รอ 2 วินาทีก่อน retry
        return _uploadImageWithRetry(
          imageFile,
          reportId,
          maxRetries: maxRetries,
          currentAttempt: currentAttempt + 1,
        );
      }
      return null;
    } on FirebaseException catch (e) {
      print('🔥 Firebase error: ${e.code} - ${e.message}');
      // ตรวจสอบข้อผิดพลาดเฉพาะ
      if (e.code == 'storage/unauthorized') {
        print('🔒 Storage permission denied - check Firebase rules');
      } else if (e.code == 'storage/canceled') {
        print('🚫 Upload was canceled');
      } else if (e.code == 'storage/unknown') {
        print('❓ Unknown storage error - likely network issue');

        // ลอง retry สำหรับ network issues
        if (currentAttempt < maxRetries) {
          print(
              '🔄 Retrying upload after network error... ($currentAttempt/$maxRetries)');
          await Future.delayed(const Duration(seconds: 3));
          return _uploadImageWithRetry(
            imageFile,
            reportId,
            maxRetries: maxRetries,
            currentAttempt: currentAttempt + 1,
          );
        }
      } else if (e.code == 'storage/retry-limit-exceeded') {
        print('🔄 Upload retry limit exceeded');
      }
      return null;
    } catch (e) {
      print('❌ Error uploading image: $e');

      // จัดการข้อผิดพลาดเฉพาะ
      if (e.toString().contains('channel-error')) {
        print('📡 Channel connection error - network or Firebase issue');
        print('💡 Try again or submit without image');

        // ลอง retry สำหรับ channel errors (Xiaomi issue)
        if (currentAttempt < maxRetries) {
          print(
              '🔄 Retrying upload after channel error... ($currentAttempt/$maxRetries)');
          await Future.delayed(const Duration(seconds: 2));
          return _uploadImageWithRetry(
            imageFile,
            reportId,
            maxRetries: maxRetries,
            currentAttempt: currentAttempt + 1,
          );
        }
      } else if (e.toString().contains('Unable to establish connection')) {
        print('🌐 Network connection problem');
        print('💡 Check your internet connection');
      } else if (e.toString().contains('NullPointerException')) {
        print('🐛 Firebase Storage metadata error');
        print('💡 This is a known issue with some Android versions');
      } else if (e.toString().contains('storage')) {
        print('💡 This might be a Firebase Storage configuration issue');
      } else if (e.toString().contains('permission')) {
        print('💡 Check Firebase Storage security rules');
      }
      return null;
    }
  }

  /// ตรวจสอบว่าผู้ใช้โพสต์เกินขาดวันนี้แล้วหรือยัง
  static Future<bool> canUserPostToday(String userId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      print('🔍 Checking daily limit for user: $userId');
      print(
          '📅 Date range: ${startOfDay.toIso8601String()} to ${endOfDay.toIso8601String()}');

      final todayPosts = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
          .where('status', isEqualTo: 'active')
          .get();

      final postCount = todayPosts.docs.length;
      print(
          '📊 User $userId has posted $postCount times today (limit: $_maxPostsPerDay)');

      return postCount < _maxPostsPerDay;
    } catch (e) {
      print('❌ Error checking daily post limit: $e');

      // ตรวจสอบ error เรื่อง index อย่างละเอียด
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('failed-precondition') ||
          errorMessage.contains('requires an index') ||
          errorMessage.contains('index') ||
          errorMessage.contains('composite')) {
        print('🔧 Firebase Index missing - This is expected for new projects');
        print(
            '📋 To fix this permanently, create a composite index with fields:');
        print('   - userId (Ascending)');
        print('   - timestamp (Ascending)');
        print('   - status (Ascending)');
        print(
            '💡 App will continue working - bypassing daily limit check temporarily');
        return true; // อนุญาตให้โพสต์ได้เมื่อ index ยังไม่พร้อม
      }

      // Log error อื่นๆ เพื่อ debug
      print('⚠️  Unknown error type - allowing post to continue: $e');
      return true; // ถ้าเกิดข้อผิดพลาดอื่น ให้อนุญาตโพสต์ได้
    }
  }

  /// เพิ่มรายงานเหตุการณ์ใหม่ (รวม TTL และการจำกัดโพสต์)
  static Future<String> submitReport({
    required EventCategory category,
    required String description,
    required LatLng location,
    required String district,
    required String province,
    String? imageUrl,
    File? imageFile,
    String? userId,
    String? userName,
  }) async {
    try {
      final effectiveUserId = userId ?? 'anonymous';
      print('🚀 Starting report submission for user: $effectiveUserId');

      // ตรวจสอบจำนวนโพสต์ต่อวัน
      final canPost = await canUserPostToday(effectiveUserId);
      if (!canPost) {
        throw Exception(
            'เกินขีดจำกัด: โพสต์ได้สูงสุด $_maxPostsPerDay ครั้งต่อวัน');
      }

      // สร้าง document อันหนึ่งก่อนเพื่อได้ ID
      final docRef = _firestore.collection(_collection).doc();
      final reportId = docRef.id;
      print('📄 Created document ID: $reportId');

      String? finalImageUrl = imageUrl;

      // อัพโหลดรูปภาพถ้ามี (พร้อม timeout)
      if (imageFile != null) {
        print('📷 Uploading image...');
        try {
          finalImageUrl = await uploadImage(imageFile, reportId).timeout(
            const Duration(seconds: 45), // timeout สำหรับการอัพโหลดรูป
            onTimeout: () {
              print('⏰ Image upload timeout - continuing without image');
              return null;
            },
          );

          if (finalImageUrl != null) {
            print('✅ Image uploaded successfully');
          } else {
            print('⚠️ Image upload failed - saving report without image');
          }
        } catch (e) {
          print('❌ Image upload error: $e - continuing without image');
          finalImageUrl = null;
        }
      }

      final now = DateTime.now();
      final expireAt = now.add(const Duration(days: 7)); // หมดอายุใน 7 วัน

      print('💾 Saving report with TURBO Transaction mode...');

      // 🚀 ใช้ Transaction แทน Batch สำหรับความเร็วสูงสุด
      await _firestore.runTransaction((transaction) async {
        // บันทึกข้อมูลรายงานหลัก
        transaction.set(docRef, {
          'title': _generateTitle(category, description),
          'description': description,
          'category': _getCategoryKey(category),
          'type': _getCategoryName(category),
          'timestamp': FieldValue.serverTimestamp(), // เวลาจากเซิร์ฟเวอร์
          'lat': location.latitude,
          'lng': location.longitude,
          'location': _formatLocationString(district, province),
          'district': district,
          'province': province,
          'imageUrl': finalImageUrl ?? '',
          'userId': effectiveUserId,
          'userName': userName ?? 'ไม่ระบุชื่อ',
          'displayName': userName ?? 'ไม่ระบุชื่อ',
          'status': 'active',
          'expireAt': Timestamp.fromDate(expireAt),
        });

        // อัปเดต user stats พร้อมกัน
        final userStatsRef =
            _firestore.collection('user_stats').doc(effectiveUserId);
        transaction.set(
            userStatsRef,
            {
              'lastReportAt': FieldValue.serverTimestamp(),
              'totalReports': FieldValue.increment(1),
              'lastReportLocation': '$district, $province',
            },
            SetOptions(merge: true));

        print('🚀 Transaction completed - ultra fast atomic operation!');
      }).timeout(
        const Duration(seconds: 12), // ลด timeout สำหรับ transaction
        onTimeout: () => throw TimeoutException(
            'Transaction timeout - ultra fast mode',
            const Duration(seconds: 12)),
      );

      print('✅ Report submitted successfully with ID: ${docRef.id}');
      print('⏰ Report will auto-delete after: $expireAt');
      if (finalImageUrl != null) {
        print('🖼️ Image URL: $finalImageUrl');
      }
      return docRef.id;
    } on TimeoutException catch (e) {
      print('⏰ Timeout during report submission: ${e.message}');
      throw Exception('การส่งรายงานเกินเวลา กรุณาลองใหม่อีกครั้ง');
    } catch (e) {
      print('❌ Error submitting report: $e');

      // แยกประเภท error เพื่อแสดงข้อความที่เหมาะสม
      if (e.toString().contains('network')) {
        throw Exception('ปัญหาเชื่อมต่ออินเทอร์เน็ต กรุณาตรวจสอบการเชื่อมต่อ');
      } else if (e.toString().contains('permission')) {
        throw Exception('ไม่มีสิทธิ์ในการส่งรายงาน กรุณาลองล็อกอินใหม่');
      } else if (e.toString().contains('storage')) {
        throw Exception('ปัญหาการอัพโหลดไฟล์ กรุณาลองเลือกรูปภาพใหม่');
      }

      rethrow;
    }
  }

  /// ดึงรายงานทั้งหมด (สำหรับแผนที่)
  static Stream<QuerySnapshot> getReportsStream() {
    print('Debug: Getting reports stream from collection: $_collection');
    return _firestore
        .collection(_collection)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// ดึงรายงานในรัศมีที่กำหนด
  static Stream<QuerySnapshot> getReportsInRadius({
    required LatLng center,
    required double radiusKm,
  }) {
    final latRange = radiusKm / 111.0; // 1 องศา ≈ 111 กม.

    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: 'active')
        .where('lat', isGreaterThanOrEqualTo: center.latitude - latRange)
        .where('lat', isLessThanOrEqualTo: center.latitude + latRange)
        .orderBy('timestamp', descending: true)
        .orderBy('lat')
        .snapshots();
  }

  /// ดึงรายงานล่าสุด (สำหรับ ListScreen) พร้อม cache optimization
  static Stream<QuerySnapshot> getRecentReports({int limit = 20}) {
    // ลดจาก 50 เป็น 20
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: 'active')
        .orderBy('timestamp', descending: true)
        .limit(limit) // จำกัดจำนวนเพื่อลดการใช้ bandwidth
        .snapshots();
  }

  /// ลบรายงาน (เปลี่ยนสถานะเป็น inactive)
  static Future<void> deleteReport(String reportId) async {
    try {
      await _firestore.collection(_collection).doc(reportId).update({
        'status': 'inactive',
        'deletedAt': FieldValue.serverTimestamp(),
      });
      print('Report marked as inactive: $reportId');
    } catch (e) {
      print('Error deleting report: $e');
      rethrow;
    }
  }

  /// อัปเดตสถานะรายงาน
  static Future<void> updateReportStatus(String reportId, String status) async {
    try {
      await _firestore.collection(_collection).doc(reportId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('Report status updated: $reportId -> $status');
    } catch (e) {
      print('Error updating report status: $e');
      rethrow;
    }
  }

  /// อัปเดตเอกสารเก่าให้มี TTL field (รันครั้งเดียวเพื่อ migrate ข้อมูล)
  static Future<void> migrateExistingReportsToTTL() async {
    try {
      print('Debug: Starting migration of existing reports to TTL...');

      // ค้นหาเอกสารที่ยังไม่มี expireAt field
      final QuerySnapshot existingReports = await _firestore
          .collection(_collection)
          .where('status', isEqualTo: 'active')
          .get();

      print('Debug: Found ${existingReports.docs.length} reports to migrate');

      if (existingReports.docs.isEmpty) {
        print('Debug: No reports to migrate');
        return;
      }

      WriteBatch batch = _firestore.batch();
      int batchCount = 0;
      int migratedCount = 0;

      for (var doc in existingReports.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // ตรวจสอบว่ามี expireAt field หรือยัง
        if (!data.containsKey('expireAt') || data['expireAt'] == null) {
          final Timestamp? timestamp = data['timestamp'] as Timestamp?;

          if (timestamp != null) {
            // คำนวณ expireAt จาก timestamp + 7 วัน
            final expireAt = timestamp.toDate().add(const Duration(days: 7));

            batch.update(doc.reference, {
              'expireAt': Timestamp.fromDate(expireAt),
            });

            batchCount++;
            migratedCount++;

            // Firestore batch มีข้อจำกัด 500 operations
            if (batchCount >= 500) {
              await batch.commit();
              print('Debug: Committed batch of $batchCount operations');
              batch = _firestore.batch();
              batchCount = 0;
            }
          }
        }
      }

      // Commit batch สุดท้าย
      if (batchCount > 0) {
        await batch.commit();
        print('Debug: Committed final batch of $batchCount operations');
      }

      print('Successfully migrated $migratedCount reports to TTL');
    } catch (e) {
      print('Error migrating reports to TTL: $e');
      rethrow;
    }
  }

  /// เรียกใช้ initialization และ migration เมื่อเปิดแอป
  static Future<void> initializeAndMigrate() async {
    try {
      print('Debug: Initializing Firebase service with TTL migration...');
      await migrateExistingReportsToTTL();
      print('Debug: TTL initialization and migration completed successfully');
    } catch (e) {
      print('Error during initialization: $e');
      // ไม่ rethrow เพราะไม่ควรให้การ migration ไปกระทบการใช้งานแอป
    }
  }

  /// แปลง EventCategory เป็นชื่อ
  static String _getCategoryName(EventCategory category) {
    switch (category) {
      case EventCategory.floodRain:
        return 'ฝนตก';
      case EventCategory.accident:
        return 'อุบัติเหตุ';
      case EventCategory.fire:
        return 'ไฟไหม้';
      case EventCategory.earthquake:
        return 'แผ่นดินไหว';
      case EventCategory.tsunami:
        return 'สึนามิ';
      case EventCategory.checkpoint:
        return 'ด่านตรวจ';
      case EventCategory.animalLost:
        return 'สัตว์หาย';
      case EventCategory.question:
        return 'คำถาม';
    }
  }

  /// แปลง EventCategory เป็น key สำหรับเก็บใน database
  static String _getCategoryKey(EventCategory category) {
    switch (category) {
      case EventCategory.floodRain:
        return 'floodRain';
      case EventCategory.accident:
        return 'accident';
      case EventCategory.fire:
        return 'fire';
      case EventCategory.earthquake:
        return 'earthquake';
      case EventCategory.tsunami:
        return 'tsunami';
      case EventCategory.checkpoint:
        return 'checkpoint';
      case EventCategory.animalLost:
        return 'animalLost';
      case EventCategory.question:
        return 'question';
    }
  }

  /// สร้าง title อัตโนมัติจาก category และ description
  static String _generateTitle(EventCategory category, String description) {
    final categoryName = _getCategoryName(category);

    // ตัดคำแรกของ description มาใช้เป็น title
    final words = description.trim().split(' ');
    if (words.length <= 3) {
      return '$categoryName: $description';
    }

    final shortDesc = words.take(3).join(' ');
    return '$categoryName: $shortDesc...';
  }

  /// รวม district และ province เป็น location string
  static String _formatLocationString(String district, String province) {
    if (district.isEmpty && province.isEmpty) {
      return 'ไม่ระบุตำแหน่ง';
    } else if (district.isEmpty) {
      return province;
    } else if (province.isEmpty) {
      return district;
    } else {
      return '$district, $province';
    }
  }

  /// แปลงชื่อเป็น EventCategory
  static EventCategory getCategoryFromName(String name) {
    switch (name.toLowerCase()) {
      // ภาษาไทย
      case 'ฝนตก':
      case 'น้ำท่วม':
        return EventCategory.floodRain;
      case 'อุบัติเหตุ':
      case 'รถชน':
        return EventCategory.accident;
      case 'ไฟไหม้':
      case 'ไฟ':
        return EventCategory.fire;
      case 'แผ่นดินไหว':
        return EventCategory.earthquake;
      case 'สึนามิ':
        return EventCategory.tsunami;
      case 'ด่านตรวจ':
      case 'ด่าน':
        return EventCategory.checkpoint;
      case 'สัตว์หาย':
        return EventCategory.animalLost;
      case 'คำถาม':
      case 'คำถามทั่วไป':
        return EventCategory.question;

      // Enum strings
      case 'checkpoint':
        return EventCategory.checkpoint;
      case 'accident':
        return EventCategory.accident;
      case 'fire':
        return EventCategory.fire;
      case 'floodrain':
      case 'flood':
      case 'rain':
        return EventCategory.floodRain;
      case 'tsunami':
        return EventCategory.tsunami;
      case 'earthquake':
        return EventCategory.earthquake;
      case 'animallost':
      case 'animal':
        return EventCategory.animalLost;
      case 'question':
        return EventCategory.question;

      // Legacy support
      case 'incident':
      case 'other':
        return EventCategory.accident;
      case 'type':
        return EventCategory.checkpoint;

      default:
        print('Debug: Unknown category name: $name, defaulting to checkpoint');
        return EventCategory.checkpoint; // เปลี่ยนจาก accident เป็น checkpoint
    }
  }

  /// คำนวณระยะทางระหว่างสองจุด (Haversine formula)
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double radiusEarth = 6371; // รัศมีโลกในหน่วยกิโลเมตร

    final double dLat = _degToRad(lat2 - lat1);
    final double dLon = _degToRad(lon2 - lon1);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final double c = 2 * math.asin(math.sqrt(a));
    return radiusEarth * c;
  }

  static double _degToRad(double deg) {
    return deg * (math.pi / 180);
  }

  /// ฟอร์แมทเวลา
  static String formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'ไม่ทราบเวลา';

    final dateTime = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} วันที่แล้ว';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ชั่วโมงที่แล้ว';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} นาทีที่แล้ว';
    } else {
      return 'เมื่อสักครู่';
    }
  }
}
