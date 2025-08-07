import 'dart:async';
import 'dart:isolate';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// EventCategory enum สำหรับ background service
enum BackgroundEventCategory {
  traffic,
  accident,
  roadwork,
  police,
  weather,
  other,
}

/// Helper function สำหรับแปลง string เป็น BackgroundEventCategory
BackgroundEventCategory getBackgroundCategoryFromName(String categoryName) {
  switch (categoryName.toLowerCase()) {
    case 'traffic':
    case 'รถติด':
      return BackgroundEventCategory.traffic;
    case 'accident':
    case 'อุบัติเหตุ':
      return BackgroundEventCategory.accident;
    case 'roadwork':
    case 'ซ่อมถนน':
      return BackgroundEventCategory.roadwork;
    case 'police':
    case 'ตำรวจ':
      return BackgroundEventCategory.police;
    case 'weather':
    case 'อากาศ':
      return BackgroundEventCategory.weather;
    default:
      return BackgroundEventCategory.other;
  }
}

/// Service สำหรับการ fetch ข้อมูลในพื้นหลังโดยใช้ Isolates
/// เพื่อไม่ให้กระทบต่อ UI performance
class BackgroundFetchService {
  static BackgroundFetchService? _instance;
  static BackgroundFetchService get instance =>
      _instance ??= BackgroundFetchService._();

  BackgroundFetchService._();

  Isolate? _backgroundIsolate;
  ReceivePort? _receivePort;
  SendPort? _sendPort;
  bool _isInitialized = false;

  // StreamController สำหรับส่งข้อมูลที่ได้จาก background fetch
  final StreamController<List<BackgroundDocumentData>> _dataStreamController =
      StreamController<List<BackgroundDocumentData>>.broadcast();

  Stream<List<BackgroundDocumentData>> get dataStream =>
      _dataStreamController.stream;

  /// เริ่ม background fetch service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _receivePort = ReceivePort();

      // รับข้อมูลจาก isolate
      _receivePort!.listen((message) {
        if (message is SendPort) {
          _sendPort = message;
          if (kDebugMode) {
            debugPrint('BackgroundFetch: Isolate initialized successfully');
          }
        } else if (message is Map<String, dynamic>) {
          _handleBackgroundData(message);
        } else if (message is String) {
          if (kDebugMode) {
            debugPrint('BackgroundFetch: $message');
          }
        }
      });

      // สร้าง isolate
      _backgroundIsolate = await Isolate.spawn(
        _backgroundFetchWorker,
        _receivePort!.sendPort,
        debugName: 'BackgroundFetchWorker',
      );

      _isInitialized = true;

      if (kDebugMode) {
        debugPrint('BackgroundFetch: Service initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('BackgroundFetch: Failed to initialize - $e');
      }
    }
  }

  /// เริ่มการ fetch ข้อมูลในพื้นหลัง
  Future<void> startFetching({
    required double lat,
    required double lng,
    required double searchRadius,
    required List<BackgroundEventCategory> categories,
    Duration interval = const Duration(minutes: 5),
  }) async {
    if (!_isInitialized || _sendPort == null) {
      await initialize();

      // รอให้ isolate พร้อม
      int retries = 0;
      while (_sendPort == null && retries < 10) {
        await Future.delayed(const Duration(milliseconds: 100));
        retries++;
      }

      if (_sendPort == null) {
        if (kDebugMode) {
          debugPrint('BackgroundFetch: Failed to get SendPort');
        }
        return;
      }
    }

    final fetchConfig = {
      'action': 'start_fetching',
      'lat': lat,
      'lng': lng,
      'searchRadius': searchRadius,
      'categories': categories.map((c) => c.toString()).toList(),
      'intervalMinutes': interval.inMinutes,
    };

    _sendPort!.send(fetchConfig);

    if (kDebugMode) {
      debugPrint('BackgroundFetch: Started fetching with config: $fetchConfig');
    }
  }

  /// หยุดการ fetch ข้อมูลในพื้นหลัง
  void stopFetching() {
    if (_sendPort != null) {
      _sendPort!.send({'action': 'stop_fetching'});
      if (kDebugMode) {
        debugPrint('BackgroundFetch: Stopped fetching');
      }
    }
  }

  /// จัดการข้อมูลที่ได้จาก background fetch
  void _handleBackgroundData(Map<String, dynamic> data) {
    try {
      if (data['type'] == 'fetch_result') {
        final docsData = data['docs'] as List<dynamic>;
        final docs = docsData.map((docData) {
          return BackgroundDocumentData(
            id: docData['id'] as String,
            data: Map<String, dynamic>.from(docData['data'] as Map),
          );
        }).toList();

        _dataStreamController.add(docs);

        if (kDebugMode) {
          debugPrint('BackgroundFetch: Received ${docs.length} documents');
        }
      } else if (data['type'] == 'error') {
        if (kDebugMode) {
          debugPrint('BackgroundFetch: Error - ${data['message']}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('BackgroundFetch: Error handling data - $e');
      }
    }
  }

  /// ปิด service และ isolate
  void dispose() {
    _sendPort?.send({'action': 'stop'});
    _backgroundIsolate?.kill(priority: Isolate.immediate);
    _receivePort?.close();
    _dataStreamController.close();
    _isInitialized = false;

    if (kDebugMode) {
      debugPrint('BackgroundFetch: Service disposed');
    }
  }

  /// Background worker function ที่รันใน isolate
  static void _backgroundFetchWorker(SendPort mainSendPort) async {
    final receivePort = ReceivePort();
    mainSendPort.send(receivePort.sendPort);

    Timer? fetchTimer;
    Map<String, dynamic>? currentConfig;

    receivePort.listen((message) async {
      if (message is Map<String, dynamic>) {
        final action = message['action'] as String;

        switch (action) {
          case 'start_fetching':
            currentConfig = message;
            fetchTimer?.cancel();

            // เริ่ม fetch ทันที
            await _performFetch(mainSendPort, currentConfig!);

            // ตั้ง timer สำหรับ fetch ครั้งต่อไป
            final intervalMinutes = message['intervalMinutes'] as int;
            fetchTimer = Timer.periodic(
              Duration(minutes: intervalMinutes),
              (_) => _performFetch(mainSendPort, currentConfig!),
            );

            mainSendPort.send('Background fetching started');
            break;

          case 'stop_fetching':
            fetchTimer?.cancel();
            fetchTimer = null;
            mainSendPort.send('Background fetching stopped');
            break;

          case 'stop':
            fetchTimer?.cancel();
            receivePort.close();
            return;
        }
      }
    });
  }

  /// ทำการ fetch ข้อมูลจาก Firestore
  static Future<void> _performFetch(
    SendPort mainSendPort,
    Map<String, dynamic> config,
  ) async {
    try {
      final lat = config['lat'] as double;
      final lng = config['lng'] as double;
      final searchRadius = config['searchRadius'] as double;
      final categoryStrings = config['categories'] as List<String>;

      // แปลง string กลับเป็น BackgroundEventCategory
      final categories = categoryStrings
          .map((cat) => BackgroundEventCategory.values.firstWhere(
                (e) => e.toString() == cat,
                orElse: () => BackgroundEventCategory.other,
              ))
          .toList();

      // คำนวณ bounding box
      const double kmPerLatDegree = 111.0;
      final double kmPerLngDegree = 111.0 * cos(lat * pi / 180.0);

      final double latOffset = searchRadius / kmPerLatDegree;
      final double lngOffset = searchRadius / kmPerLngDegree;

      final double minLat = lat - latOffset;
      final double maxLat = lat + latOffset;
      final double minLng = lng - lngOffset;
      final double maxLng = lng + lngOffset;

      // สร้าง query
      Query query = FirebaseFirestore.instance
          .collection('reports')
          .where('lat', isGreaterThanOrEqualTo: minLat)
          .where('lat', isLessThanOrEqualTo: maxLat);

      // เพิ่มเงื่อนไข status
      query = query.where('status', isEqualTo: 'approved');

      // เพิ่มเงื่อนไข timestamp (ล่าสุด 24 ชั่วโมง)
      final now = DateTime.now();
      final cutoffTime = now.subtract(const Duration(hours: 24));
      query = query.where('timestamp',
          isGreaterThan: Timestamp.fromDate(cutoffTime));

      // เรียงตาม timestamp
      query = query.orderBy('timestamp', descending: true);

      // จำกัดผลลัพธ์
      query = query.limit(1000);

      final querySnapshot = await query.get();

      // กรองข้อมูลเพิ่มเติม
      final filteredDocs = querySnapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;

        // ตรวจสอบ longitude
        final docLng = (data['lng'] ?? 0.0) as double;
        if (docLng < minLng || docLng > maxLng) return false;

        // ตรวจสอบ category
        final category =
            data['category'] as String? ?? data['type'] as String? ?? '';
        final backgroundCategory = getBackgroundCategoryFromName(category);
        if (!categories.contains(backgroundCategory)) return false;

        return true;
      }).toList();

      // ส่งข้อมูลกลับ
      final docsData = filteredDocs
          .map((doc) => {
                'id': doc.id,
                'data': doc.data() as Map<String, dynamic>,
              })
          .toList();

      mainSendPort.send({
        'type': 'fetch_result',
        'docs': docsData,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      mainSendPort.send({
        'type': 'error',
        'message': e.toString(),
      });
    }
  }
}

/// Simple data class สำหรับเก็บข้อมูล document
class BackgroundDocumentData {
  final String id;
  final Map<String, dynamic> data;

  BackgroundDocumentData({required this.id, required this.data});
}
