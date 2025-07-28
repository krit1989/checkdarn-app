import 'package:flutter/foundation.dart';
import 'dart:async';

/// Performance monitoring service for tracking app performance
class PerformanceService {
  static const int ALERT_THRESHOLD_MS = 5000;
  static const int MEMORY_ALERT_MB = 200;
  static const int MAX_METRICS_HISTORY = 100;

  static final Map<String, List<int>> _performanceMetrics = {};
  static final Map<String, int> _alertCounts = {};
  static Timer? _cleanupTimer;

  /// Initialize performance monitoring
  static void initialize() {
    _cleanupTimer =
        Timer.periodic(const Duration(minutes: 5), (_) => _cleanup());

    if (kDebugMode) {
      debugPrint('🚀 Performance monitoring initialized');
    }
  }

  /// Track operation performance
  static void trackOperation(String operation, int durationMs) {
    _performanceMetrics[operation] = _performanceMetrics[operation] ?? [];
    _performanceMetrics[operation]!.add(durationMs);

    // Alert if too slow
    if (durationMs > ALERT_THRESHOLD_MS) {
      _sendPerformanceAlert(operation, durationMs);
    }

    // Keep only recent measurements
    if (_performanceMetrics[operation]!.length > MAX_METRICS_HISTORY) {
      _performanceMetrics[operation]!.removeAt(0);
    }

    if (kDebugMode && durationMs > 1000) {
      debugPrint('⚡ Performance: $operation took ${durationMs}ms');
    }
  }

  /// Track operation with automatic timing
  static Future<T> trackAsyncOperation<T>(
      String operation, Future<T> Function() task) async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = await task();
      stopwatch.stop();
      trackOperation(operation, stopwatch.elapsedMilliseconds);
      return result;
    } catch (e) {
      stopwatch.stop();
      trackOperation('${operation}_error', stopwatch.elapsedMilliseconds);
      _logError(operation, e);
      rethrow;
    }
  }

  /// Track synchronous operation
  static T trackSyncOperation<T>(String operation, T Function() task) {
    final stopwatch = Stopwatch()..start();
    try {
      final result = task();
      stopwatch.stop();
      trackOperation(operation, stopwatch.elapsedMilliseconds);
      return result;
    } catch (e) {
      stopwatch.stop();
      trackOperation('${operation}_error', stopwatch.elapsedMilliseconds);
      _logError(operation, e);
      rethrow;
    }
  }

  /// Send performance alert
  static void _sendPerformanceAlert(String operation, int duration) {
    _alertCounts[operation] = (_alertCounts[operation] ?? 0) + 1;

    if (kDebugMode) {
      debugPrint(
          '🚨 Performance Alert: $operation took ${duration}ms (alert #${_alertCounts[operation]})');
    }

    // Log to console for now (can be extended to external monitoring)
    _logPerformanceEvent('slow_operation', {
      'operation': operation,
      'duration_ms': duration,
      'alert_count': _alertCounts[operation],
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Log error
  static void _logError(String operation, dynamic error) {
    if (kDebugMode) {
      debugPrint('💥 Error in $operation: $error');
    }

    _logPerformanceEvent('operation_error', {
      'operation': operation,
      'error': error.toString(),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Log performance event
  static void _logPerformanceEvent(String event, Map<String, dynamic> data) {
    if (kDebugMode) {
      debugPrint('📊 Performance Event: $event - $data');
    }
    // This would send to external monitoring service in production
  }

  /// Get average metrics for all operations
  static Map<String, double> getAverageMetrics() {
    final averages = <String, double>{};

    _performanceMetrics.forEach((operation, durations) {
      if (durations.isNotEmpty) {
        averages[operation] =
            durations.reduce((a, b) => a + b) / durations.length;
      }
    });

    return averages;
  }

  /// Get performance summary
  static Map<String, dynamic> getPerformanceSummary() {
    final summary = <String, dynamic>{};

    _performanceMetrics.forEach((operation, durations) {
      if (durations.isNotEmpty) {
        durations.sort();
        summary[operation] = {
          'count': durations.length,
          'average_ms': durations.reduce((a, b) => a + b) / durations.length,
          'median_ms': durations[durations.length ~/ 2],
          'min_ms': durations.first,
          'max_ms': durations.last,
          'alerts': _alertCounts[operation] ?? 0,
        };
      }
    });

    return summary;
  }

  /// Check if operation is performing poorly
  static bool isOperationSlow(String operation) {
    final durations = _performanceMetrics[operation];
    if (durations == null || durations.isEmpty) return false;

    final average = durations.reduce((a, b) => a + b) / durations.length;
    return average > ALERT_THRESHOLD_MS;
  }

  /// Get slow operations
  static List<String> getSlowOperations() {
    return _performanceMetrics.keys.where((op) => isOperationSlow(op)).toList();
  }

  /// Clean up old data
  static void _cleanup() {
    // Reset alert counts periodically
    if (DateTime.now().minute == 0) {
      // Reset every hour
      _alertCounts.clear();
    }

    // Keep only recent metrics
    _performanceMetrics.forEach((operation, durations) {
      if (durations.length > MAX_METRICS_HISTORY) {
        durations.removeRange(0, durations.length - MAX_METRICS_HISTORY);
      }
    });

    if (kDebugMode) {
      debugPrint('🧹 Performance metrics cleaned up');
    }
  }

  /// Get memory usage estimate
  static double getEstimatedMemoryUsage() {
    // Simple estimation based on tracked data
    int totalEntries = 0;
    _performanceMetrics.forEach((_, durations) {
      totalEntries += durations.length;
    });

    // Rough estimate: each entry ~8 bytes + overhead
    return (totalEntries * 8 + _performanceMetrics.length * 100) /
        (1024 * 1024); // MB
  }

  /// Dispose performance monitoring
  static void dispose() {
    _cleanupTimer?.cancel();
    _performanceMetrics.clear();
    _alertCounts.clear();

    if (kDebugMode) {
      debugPrint('🚀 Performance monitoring disposed');
    }
  }

  /// Log app startup time
  static void logAppStartup(int startupTimeMs) {
    trackOperation('app_startup', startupTimeMs);

    if (startupTimeMs > 3000) {
      if (kDebugMode) {
        debugPrint('🐌 Slow app startup: ${startupTimeMs}ms');
      }
    }
  }

  /// Log Firebase operation
  static void logFirebaseOperation(
      String operation, int durationMs, int recordCount) {
    trackOperation('firebase_$operation', durationMs);

    if (kDebugMode) {
      debugPrint(
          '🔥 Firebase $operation: ${durationMs}ms for $recordCount records');
    }
  }

  /// Log UI rendering performance
  static void logUIRender(String screen, int renderTimeMs) {
    trackOperation('ui_render_$screen', renderTimeMs);

    if (renderTimeMs > 16) {
      // 60 FPS = 16ms per frame
      if (kDebugMode) {
        debugPrint('🎨 Slow UI render for $screen: ${renderTimeMs}ms');
      }
    }
  }
}
