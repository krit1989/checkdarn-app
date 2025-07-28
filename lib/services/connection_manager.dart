import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectionManager {
  static final Connectivity _connectivity = Connectivity();
  static ConnectionStatus _currentStatus = ConnectionStatus.unknown;
  static DateTime _lastCheck = DateTime.now();
  static const Duration _checkInterval = Duration(seconds: 5);

  // Connection status enum
  static ConnectionStatus get currentStatus => _currentStatus;

  // Initialize connection monitoring
  static Future<void> initialize() async {
    await _updateConnectionStatus();

    // Listen to connectivity changes
    _connectivity.onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      if (results.isNotEmpty) {
        _updateConnectionStatusFromResult(results.first);
      }
    });
  }

  // Check current connection status
  static Future<ConnectionStatus> checkConnection() async {
    final now = DateTime.now();

    // Don't check too frequently to save battery
    if (now.difference(_lastCheck) < _checkInterval &&
        _currentStatus != ConnectionStatus.unknown) {
      return _currentStatus;
    }

    _lastCheck = now;
    await _updateConnectionStatus();
    return _currentStatus;
  }

  // Update connection status
  static Future<void> _updateConnectionStatus() async {
    try {
      final connectivityResults = await _connectivity.checkConnectivity();
      if (connectivityResults.isNotEmpty) {
        _updateConnectionStatusFromResult(connectivityResults.first);
      }

      // If we have network connectivity, test actual internet access
      if (_currentStatus != ConnectionStatus.offline) {
        final hasInternet = await _testInternetConnection();
        if (!hasInternet) {
          _currentStatus = ConnectionStatus.poor;
        }
      }
    } catch (e) {
      print('Error checking connection: $e');
      _currentStatus = ConnectionStatus.poor;
    }
  }

  // Update status from connectivity result
  static void _updateConnectionStatusFromResult(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.wifi:
        _currentStatus = ConnectionStatus.good;
        break;
      case ConnectivityResult.mobile:
        _currentStatus = ConnectionStatus.mobile;
        break;
      case ConnectivityResult.ethernet:
        _currentStatus = ConnectionStatus.good;
        break;
      case ConnectivityResult.none:
        _currentStatus = ConnectionStatus.offline;
        break;
      default:
        _currentStatus = ConnectionStatus.poor;
    }
  }

  // Test actual internet connection by trying to reach a reliable server
  static Future<bool> _testInternetConnection() async {
    try {
      final response = await HttpClient()
          .getUrl(Uri.parse('https://www.google.com'))
          .timeout(const Duration(seconds: 5));

      final httpResponse =
          await response.close().timeout(const Duration(seconds: 5));
      return httpResponse.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Test map tile download speed
  static Future<TileLoadSpeed> testTileLoadSpeed() async {
    if (_currentStatus == ConnectionStatus.offline) {
      return TileLoadSpeed.offline;
    }

    try {
      final stopwatch = Stopwatch()..start();

      // Test with a small tile download
      final response = await HttpClient()
          .getUrl(Uri.parse('https://tile.openstreetmap.org/1/0/0.png'))
          .timeout(const Duration(seconds: 10));

      final httpResponse =
          await response.close().timeout(const Duration(seconds: 10));
      stopwatch.stop();

      if (httpResponse.statusCode == 200) {
        final milliseconds = stopwatch.elapsedMilliseconds;

        if (milliseconds < 1000) {
          return TileLoadSpeed.fast;
        } else if (milliseconds < 3000) {
          return TileLoadSpeed.medium;
        } else {
          return TileLoadSpeed.slow;
        }
      }
    } catch (e) {
      print('Error testing tile load speed: $e');
    }

    return TileLoadSpeed.slow;
  }

  // Get connection quality description
  static String getConnectionDescription() {
    switch (_currentStatus) {
      case ConnectionStatus.good:
        return 'เชื่อมต่ออินเทอร์เน็ตดี (WiFi/Ethernet)';
      case ConnectionStatus.mobile:
        return 'เชื่อมต่อผ่านมือถือ';
      case ConnectionStatus.poor:
        return 'สัญญาณอินเทอร์เน็ตอ่อน';
      case ConnectionStatus.offline:
        return 'ไม่มีการเชื่อมต่ออินเทอร์เน็ต';
      case ConnectionStatus.unknown:
        return 'ตรวจสอบการเชื่อมต่อ...';
    }
  }

  // Check if we should use online maps
  static bool shouldUseOnlineMaps() {
    return _currentStatus == ConnectionStatus.good ||
        _currentStatus == ConnectionStatus.mobile;
  }

  // Check if we should preload tiles
  static bool shouldPreloadTiles() {
    return _currentStatus == ConnectionStatus.good;
  }

  // Check if connection is good enough for downloads
  static bool isConnectionGoodForDownloads() {
    return _currentStatus == ConnectionStatus.good;
  }
}

// Connection status enum
enum ConnectionStatus {
  good, // WiFi, Ethernet - fast and reliable
  mobile, // Mobile data - potentially limited or slower
  poor, // Connected but slow/unreliable
  offline, // No connection
  unknown, // Status not determined yet
}

// Tile loading speed enum
enum TileLoadSpeed {
  fast, // < 1 second
  medium, // 1-3 seconds
  slow, // > 3 seconds
  offline, // No connection
}
