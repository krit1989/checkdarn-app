import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Enhanced Cache Service with TTL (Time To Live) Policy
///
/// Features:
/// - Automatic cache expiration
/// - Memory management with size limits
/// - LRU (Least Recently Used) eviction
/// - Persistent storage for important data
/// - Debug logging for cache performance
class EnhancedCacheService {
  // Cache configuration
  static const int MAX_CACHE_SIZE = 1000;
  static const Duration DEFAULT_TTL = Duration(minutes: 5);
  static const Duration REPORTS_TTL = Duration(minutes: 10);
  static const Duration USER_DATA_TTL = Duration(hours: 1);
  static const Duration MAP_TILES_TTL = Duration(hours: 24);

  // Internal cache storage
  static final Map<String, CacheEntry> _memoryCache = {};
  static Timer? _cleanupTimer;
  static SharedPreferences? _prefs;

  /// Initialize the cache service
  static Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _startCleanupTimer();
      await _loadPersistentCache();

      if (kDebugMode) {
        print('✅ Enhanced Cache Service initialized');
        print(
            '📊 Cache config: MAX_SIZE=$MAX_CACHE_SIZE, DEFAULT_TTL=${DEFAULT_TTL.inMinutes}min');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to initialize Enhanced Cache Service: $e');
      }
    }
  }

  /// Get value from cache with automatic TTL check
  static T? get<T>(String key) {
    final entry = _memoryCache[key];
    if (entry == null) {
      _tryLoadFromPersistent(key);
      return null;
    }

    // Check TTL expiration
    if (_isExpired(entry)) {
      _memoryCache.remove(key);
      _removeFromPersistent(key);

      if (kDebugMode) {
        print('🗑️ Cache expired and removed: $key');
      }
      return null;
    }

    // Update access time for LRU
    entry.lastAccessed = DateTime.now();

    if (kDebugMode) {
      print(
          '✅ Cache hit: $key (age: ${DateTime.now().difference(entry.createdAt).inMinutes}min)');
    }

    return entry.value as T?;
  }

  /// Set value in cache with custom TTL
  static Future<void> set(String key, dynamic value,
      {Duration? ttl, bool persistent = false}) async {
    // Prevent cache overflow
    if (_memoryCache.length >= MAX_CACHE_SIZE) {
      await _evictLRU();
    }

    final effectiveTTL = ttl ?? _getTTLForKey(key);
    final entry = CacheEntry(
      value: value,
      createdAt: DateTime.now(),
      lastAccessed: DateTime.now(),
      ttl: effectiveTTL,
      persistent: persistent,
    );

    _memoryCache[key] = entry;

    // Save to persistent storage if needed
    if (persistent) {
      await _saveToPersistent(key, entry);
    }

    if (kDebugMode) {
      print(
          '💾 Cache set: $key (TTL: ${effectiveTTL.inMinutes}min, persistent: $persistent)');
    }
  }

  /// Remove specific key from cache
  static Future<void> remove(String key) async {
    _memoryCache.remove(key);
    await _removeFromPersistent(key);

    if (kDebugMode) {
      print('🗑️ Cache removed: $key');
    }
  }

  /// Clear all cache (memory + persistent)
  static Future<void> clearAll() async {
    _memoryCache.clear();

    if (_prefs != null) {
      final keys =
          _prefs!.getKeys().where((key) => key.startsWith('cache_')).toList();
      for (final key in keys) {
        await _prefs!.remove(key);
      }
    }

    if (kDebugMode) {
      print('🧹 All cache cleared');
    }
  }

  /// Get cache statistics for monitoring
  static Map<String, dynamic> getStats() {
    int expiredCount = 0;
    int persistentCount = 0;
    int totalSize = 0;

    _memoryCache.forEach((key, entry) {
      if (_isExpired(entry)) {
        expiredCount++;
      }
      if (entry.persistent) {
        persistentCount++;
      }
      totalSize += _calculateEntrySize(entry);
    });

    return {
      'total_entries': _memoryCache.length,
      'expired_entries': expiredCount,
      'persistent_entries': persistentCount,
      'estimated_size_kb': (totalSize / 1024).round(),
      'cache_utilization':
          ((_memoryCache.length / MAX_CACHE_SIZE) * 100).round(),
      'cleanup_timer_active': _cleanupTimer?.isActive ?? false,
    };
  }

  /// Manual cleanup of expired entries
  static Future<void> cleanup() async {
    final expiredKeys = <String>[];

    _memoryCache.forEach((key, entry) {
      if (_isExpired(entry)) {
        expiredKeys.add(key);
      }
    });
    for (final key in expiredKeys) {
      _memoryCache.remove(key);
      await _removeFromPersistent(key);
    }

    if (kDebugMode && expiredKeys.isNotEmpty) {
      print(
          '🧹 Cleanup completed: removed ${expiredKeys.length} expired entries');
    }
  }

  /// Dispose cache service
  static void dispose() {
    _cleanupTimer?.cancel();
    _memoryCache.clear();

    if (kDebugMode) {
      print('🔒 Enhanced Cache Service disposed');
    }
  }

  // Private helper methods

  static bool _isExpired(CacheEntry entry) {
    return DateTime.now().difference(entry.createdAt) > entry.ttl;
  }

  static Duration _getTTLForKey(String key) {
    if (key.startsWith('reports_') || key.startsWith('camera_reports_')) {
      return REPORTS_TTL;
    } else if (key.startsWith('user_') || key.startsWith('auth_')) {
      return USER_DATA_TTL;
    } else if (key.startsWith('map_') || key.startsWith('tile_')) {
      return MAP_TILES_TTL;
    } else {
      return DEFAULT_TTL;
    }
  }

  static void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      cleanup();
    });
  }

  static Future<void> _evictLRU() async {
    if (_memoryCache.isEmpty) return;

    String? oldestKey;
    DateTime? oldestAccess;

    _memoryCache.forEach((key, entry) {
      if (oldestAccess == null || entry.lastAccessed.isBefore(oldestAccess!)) {
        oldestKey = key;
        oldestAccess = entry.lastAccessed;
      }
    });

    if (oldestKey != null) {
      await remove(oldestKey!);

      if (kDebugMode) {
        print('🔄 LRU evicted: $oldestKey');
      }
    }
  }

  static Future<void> _saveToPersistent(String key, CacheEntry entry) async {
    if (_prefs == null) return;

    try {
      final data = {
        'value': entry.value,
        'created_at': entry.createdAt.millisecondsSinceEpoch,
        'ttl_minutes': entry.ttl.inMinutes,
      };

      await _prefs!.setString('cache_$key', jsonEncode(data));
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to save persistent cache: $key - $e');
      }
    }
  }

  static Future<void> _loadPersistentCache() async {
    if (_prefs == null) return;

    try {
      final keys =
          _prefs!.getKeys().where((key) => key.startsWith('cache_')).toList();
      int loadedCount = 0;

      for (final prefKey in keys) {
        final cacheKey = prefKey.substring(6); // Remove 'cache_' prefix
        final dataStr = _prefs!.getString(prefKey);

        if (dataStr != null) {
          final data = jsonDecode(dataStr) as Map<String, dynamic>;
          final createdAt =
              DateTime.fromMillisecondsSinceEpoch(data['created_at']);
          final ttl = Duration(minutes: data['ttl_minutes']);

          // Check if still valid
          if (DateTime.now().difference(createdAt) < ttl) {
            final entry = CacheEntry(
              value: data['value'],
              createdAt: createdAt,
              lastAccessed: DateTime.now(),
              ttl: ttl,
              persistent: true,
            );

            _memoryCache[cacheKey] = entry;
            loadedCount++;
          } else {
            // Remove expired persistent cache
            await _prefs!.remove(prefKey);
          }
        }
      }

      if (kDebugMode && loadedCount > 0) {
        print('📚 Loaded $loadedCount persistent cache entries');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to load persistent cache: $e');
      }
    }
  }

  static void _tryLoadFromPersistent(String key) {
    // This would be implemented for real-time persistent loading
    // For now, we load all persistent cache at startup
  }

  static Future<void> _removeFromPersistent(String key) async {
    if (_prefs == null) return;

    try {
      await _prefs!.remove('cache_$key');
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to remove persistent cache: $key - $e');
      }
    }
  }

  static int _calculateEntrySize(CacheEntry entry) {
    try {
      return jsonEncode(entry.value).length;
    } catch (e) {
      return 100; // Default size estimate
    }
  }
}

/// Cache entry with TTL and access tracking
class CacheEntry {
  final dynamic value;
  final DateTime createdAt;
  DateTime lastAccessed;
  final Duration ttl;
  final bool persistent;

  CacheEntry({
    required this.value,
    required this.createdAt,
    required this.lastAccessed,
    required this.ttl,
    this.persistent = false,
  });

  bool get isExpired => DateTime.now().difference(createdAt) > ttl;

  int get ageInMinutes => DateTime.now().difference(createdAt).inMinutes;

  int get timeSinceAccessMinutes =>
      DateTime.now().difference(lastAccessed).inMinutes;
}
