import 'dart:io';
import 'dart:typed_data';
import 'dart:math';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'dart:convert';

class MapCacheManager {
  static const int maxCacheSize = 100 * 1024 * 1024; // 100MB cache limit
  static const int tileCacheExpiry =
      7 * 24 * 60 * 60 * 1000; // 7 days in milliseconds

  static Directory? _cacheDir;
  static Map<String, DateTime> _tileAccessTime = {};

  // Initialize cache directory
  static Future<void> initialize() async {
    final appDir = await getApplicationDocumentsDirectory();
    _cacheDir = Directory('${appDir.path}/map_cache');

    if (!await _cacheDir!.exists()) {
      await _cacheDir!.create(recursive: true);
    }

    // Load tile access times
    await _loadAccessTimes();

    // Clean old cache on startup
    await _cleanOldCache();
  }

  // Generate cache key for tile
  static String _getTileKey(int z, int x, int y) {
    final key = '$z-$x-$y';
    return md5.convert(utf8.encode(key)).toString();
  }

  // Get tile file path
  static String _getTilePath(String key) {
    return '${_cacheDir!.path}/$key.png';
  }

  // Check if tile exists and is not expired
  static Future<bool> hasCachedTile(int z, int x, int y) async {
    if (_cacheDir == null) await initialize();

    final key = _getTileKey(z, x, y);
    final file = File(_getTilePath(key));

    if (!await file.exists()) return false;

    // Check expiry
    final stat = await file.stat();
    final age = DateTime.now().millisecondsSinceEpoch -
        stat.modified.millisecondsSinceEpoch;

    if (age > tileCacheExpiry) {
      await file.delete();
      _tileAccessTime.remove(key);
      return false;
    }

    return true;
  }

  // Get cached tile
  static Future<Uint8List?> getCachedTile(int z, int x, int y) async {
    if (_cacheDir == null) await initialize();

    final key = _getTileKey(z, x, y);
    final file = File(_getTilePath(key));

    if (await hasCachedTile(z, x, y)) {
      // Update access time
      _tileAccessTime[key] = DateTime.now();
      await _saveAccessTimes();

      return await file.readAsBytes();
    }

    return null;
  }

  // Cache tile data
  static Future<void> cacheTile(int z, int x, int y, Uint8List data) async {
    if (_cacheDir == null) await initialize();

    final key = _getTileKey(z, x, y);
    final file = File(_getTilePath(key));

    try {
      await file.writeAsBytes(data);
      _tileAccessTime[key] = DateTime.now();
      await _saveAccessTimes();

      // Check cache size and clean if needed
      await _manageCacheSize();
    } catch (e) {
      print('Error caching tile: $e');
    }
  }

  // Download and cache tile
  static Future<Uint8List?> downloadAndCacheTile(int z, int x, int y) async {
    try {
      final url = 'https://tile.openstreetmap.org/$z/$x/$y.png';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'CheckDarn Speed Camera App/1.0',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = response.bodyBytes;
        await cacheTile(z, x, y, data);
        return data;
      }
    } catch (e) {
      print('Error downloading tile: $e');
    }

    return null;
  }

  // Preload tiles around position
  static Future<void> preloadTilesAround(double lat, double lng, int zoom,
      {int radius = 2}) async {
    final centerX = _lon2tile(lng, zoom);
    final centerY = _lat2tile(lat, zoom);

    final futures = <Future>[];

    for (int x = centerX - radius; x <= centerX + radius; x++) {
      for (int y = centerY - radius; y <= centerY + radius; y++) {
        if (x >= 0 && y >= 0) {
          futures.add(_preloadSingleTile(zoom, x, y));
        }
      }
    }

    // Load tiles in parallel but limit concurrent downloads
    for (int i = 0; i < futures.length; i += 3) {
      final batch = futures.skip(i).take(3);
      await Future.wait(batch);

      // Small delay between batches to avoid overwhelming the server
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  static Future<void> _preloadSingleTile(int z, int x, int y) async {
    if (!await hasCachedTile(z, x, y)) {
      await downloadAndCacheTile(z, x, y);
    }
  }

  // Convert coordinates to tile numbers
  static int _lon2tile(double lon, int zoom) {
    return ((lon + 180.0) / 360.0 * (1 << zoom)).floor();
  }

  static int _lat2tile(double lat, int zoom) {
    final latRad = lat * pi / 180.0;
    return ((1.0 - log(tan(latRad) + (1 / cos(latRad))) / pi) /
            2.0 *
            (1 << zoom))
        .floor();
  }

  // Clean old and least recently used cache
  static Future<void> _cleanOldCache() async {
    if (_cacheDir == null) return;

    try {
      final files = await _cacheDir!.list().toList();
      final now = DateTime.now();

      for (final file in files) {
        if (file is File && file.path.endsWith('.png')) {
          final stat = await file.stat();
          final age =
              now.millisecondsSinceEpoch - stat.modified.millisecondsSinceEpoch;

          if (age > tileCacheExpiry) {
            await file.delete();
            final key = file.path.split('/').last.replaceAll('.png', '');
            _tileAccessTime.remove(key);
          }
        }
      }
    } catch (e) {
      print('Error cleaning cache: $e');
    }
  }

  // Manage cache size - remove least recently used tiles
  static Future<void> _manageCacheSize() async {
    if (_cacheDir == null) return;

    try {
      final files = await _cacheDir!.list().toList();
      int totalSize = 0;

      for (final file in files) {
        if (file is File) {
          final stat = await file.stat();
          totalSize += stat.size;
        }
      }

      if (totalSize > maxCacheSize) {
        // Sort files by access time (least recently used first)
        final fileStats = <Map<String, dynamic>>[];

        for (final file in files) {
          if (file is File && file.path.endsWith('.png')) {
            final key = file.path.split('/').last.replaceAll('.png', '');
            final accessTime =
                _tileAccessTime[key] ?? DateTime.fromMillisecondsSinceEpoch(0);
            final stat = await file.stat();

            fileStats.add({
              'file': file,
              'accessTime': accessTime,
              'size': stat.size,
            });
          }
        }

        // Sort by access time
        fileStats.sort((a, b) => a['accessTime'].compareTo(b['accessTime']));

        // Remove files until cache size is under limit
        for (final fileStat in fileStats) {
          if (totalSize <= maxCacheSize * 0.8) break; // Keep 80% of max size

          final file = fileStat['file'] as File;
          final size = fileStat['size'] as int;

          await file.delete();
          totalSize -= size;

          final key = file.path.split('/').last.replaceAll('.png', '');
          _tileAccessTime.remove(key);
        }
      }
    } catch (e) {
      print('Error managing cache size: $e');
    }
  }

  // Save access times to persistent storage
  static Future<void> _saveAccessTimes() async {
    if (_cacheDir == null) return;

    try {
      final file = File('${_cacheDir!.path}/access_times.json');
      final data = <String, String>{};

      _tileAccessTime.forEach((key, time) {
        data[key] = time.millisecondsSinceEpoch.toString();
      });

      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      print('Error saving access times: $e');
    }
  }

  // Load access times from persistent storage
  static Future<void> _loadAccessTimes() async {
    if (_cacheDir == null) return;

    try {
      final file = File('${_cacheDir!.path}/access_times.json');

      if (await file.exists()) {
        final content = await file.readAsString();
        final data = jsonDecode(content) as Map<String, dynamic>;

        _tileAccessTime.clear();
        data.forEach((key, value) {
          _tileAccessTime[key] =
              DateTime.fromMillisecondsSinceEpoch(int.parse(value.toString()));
        });
      }
    } catch (e) {
      print('Error loading access times: $e');
    }
  }

  // Get cache statistics
  static Future<Map<String, dynamic>> getCacheStats() async {
    if (_cacheDir == null) await initialize();

    try {
      final files = await _cacheDir!
          .list()
          .where((f) => f.path.endsWith('.png'))
          .toList();
      int totalSize = 0;
      int tileCount = files.length;

      for (final file in files) {
        if (file is File) {
          final stat = await file.stat();
          totalSize += stat.size;
        }
      }

      return {
        'tileCount': tileCount,
        'totalSize': totalSize,
        'totalSizeMB': (totalSize / (1024 * 1024)).toStringAsFixed(1),
        'maxSizeMB': (maxCacheSize / (1024 * 1024)).toStringAsFixed(0),
        'usagePercent': ((totalSize / maxCacheSize) * 100).toStringAsFixed(1),
      };
    } catch (e) {
      return {
        'tileCount': 0,
        'totalSize': 0,
        'totalSizeMB': '0.0',
        'maxSizeMB': '100',
        'usagePercent': '0.0',
        'error': e.toString(),
      };
    }
  }

  // Clear all cache
  static Future<void> clearCache() async {
    if (_cacheDir == null) await initialize();

    try {
      if (await _cacheDir!.exists()) {
        await _cacheDir!.delete(recursive: true);
        await _cacheDir!.create(recursive: true);
        _tileAccessTime.clear();
      }
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }
}
