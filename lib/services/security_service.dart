import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import 'auth_service.dart';

/// Security service for rate limiting, validation, and spam detection
class SecurityService {
  // Rate limiting constants
  static const int MAX_REQUESTS_PER_MINUTE = 10;
  static const int MAX_REPORTS_PER_HOUR = 5;
  static const int MAX_COMMENTS_PER_HOUR = 20;

  // Client-side tracking
  static final Map<String, List<int>> _requestTimes = {};
  static final Map<String, int> _suspiciousActivity = {};

  /// Client-side rate limiting
  static bool checkRateLimit(String action, int maxRequests, Duration window) {
    final userId = AuthService.currentUser?.uid ?? 'anonymous';
    final key = '${userId}_$action';
    final now = DateTime.now().millisecondsSinceEpoch;
    final windowMs = window.inMilliseconds;

    _requestTimes[key] = _requestTimes[key] ?? [];

    // Remove old requests
    _requestTimes[key]!.removeWhere((time) => now - time > windowMs);

    // Check if limit exceeded
    if (_requestTimes[key]!.length >= maxRequests) {
      if (kDebugMode) {
        debugPrint('🚨 Rate limit exceeded for $action by user $userId');
      }

      // Track suspicious activity
      _trackSuspiciousActivity(userId, 'rate_limit_exceeded');

      // Log to analytics (removed Firebase Analytics dependency)
      if (kDebugMode) {
        debugPrint(
            '🚨 Rate limit exceeded: $action, user: $userId, count: ${_requestTimes[key]!.length}');
      }

      return false;
    }

    // Add current request
    _requestTimes[key]!.add(now);
    return true;
  }

  /// Validate report data before sending
  static bool validateReportData(Map<String, dynamic> data) {
    try {
      // Check required fields
      if (!data.containsKey('title') ||
          !data.containsKey('lat') ||
          !data.containsKey('lng') ||
          !data.containsKey('category')) {
        _logSecurityEvent('invalid_report_missing_fields', data);
        return false;
      }

      // Validate coordinates (Thailand bounds roughly + buffer)
      final lat = data['lat'] as double?;
      final lng = data['lng'] as double?;
      if (lat == null || lng == null) {
        _logSecurityEvent('invalid_coordinates_null', data);
        return false;
      }

      // Thailand bounds with reasonable buffer
      if (lat < 4.0 || lat > 22.0 || lng < 96.0 || lng > 107.0) {
        _logSecurityEvent('coordinates_outside_thailand', {
          'lat': lat,
          'lng': lng,
        });
        return false;
      }

      // Validate text length and content
      final title = data['title'] as String?;
      if (title == null || title.length > 200 || title.trim().isEmpty) {
        _logSecurityEvent('invalid_title', {'title_length': title?.length});
        return false;
      }

      // Check for spam in title
      if (isSpam(title)) {
        _logSecurityEvent('spam_detected_title', {'title': title});
        return false;
      }

      // Validate description if present
      final description = data['description'] as String?;
      if (description != null) {
        if (description.length > 1000) {
          _logSecurityEvent('description_too_long',
              {'description_length': description.length});
          return false;
        }

        if (isSpam(description)) {
          _logSecurityEvent('spam_detected_description', {
            'description':
                description.substring(0, math.min(50, description.length))
          });
          return false;
        }
      }

      // Validate category
      final validCategories = [
        'checkpoint',
        'accident',
        'fire',
        'floodRain',
        'tsunami',
        'earthquake',
        'animalLost',
        'question'
      ];
      if (!validCategories.contains(data['category'])) {
        _logSecurityEvent('invalid_category', {'category': data['category']});
        return false;
      }

      return true;
    } catch (e) {
      _logSecurityEvent('validation_error', {'error': e.toString()});
      return false;
    }
  }

  /// Sanitize user input
  static String sanitizeInput(String input) {
    if (input.isEmpty) return input;

    // Remove potentially dangerous characters and scripts
    return input
        .replaceAll(RegExp(r'[<>"\\/]'), '') // Remove HTML/script chars
        .replaceAll(
            RegExp(r'javascript:', caseSensitive: false), '') // Remove JS
        .replaceAll(
            RegExp(r'data:', caseSensitive: false), '') // Remove data URLs
        .trim()
        .substring(0, math.min(input.length, 1000)); // Limit length
  }

  /// Check for spam patterns
  static bool isSpam(String content) {
    if (content.isEmpty) return false;

    // Spam detection patterns
    final spamPatterns = [
      // URLs
      RegExp(r'(http|https|ftp):\/\/[^\s]+', caseSensitive: false),
      RegExp(r'www\.[^\s]+', caseSensitive: false),

      // Repeated characters (more than 10 in a row)
      RegExp(r'(.)\1{10,}'),

      // Too many caps (more than 50% caps in words longer than 10 chars)
      RegExp(r'^[A-Z\s]{10,}$'),

      // Phone numbers (Thai format)
      RegExp(r'0[0-9]{1,2}[-.\s]?[0-9]{3,4}[-.\s]?[0-9]{4}'),

      // Email addresses
      RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'),

      // Common spam words (Thai/English)
      RegExp(r'(ลดราคา|เงินด่วน|โปรโมชั่น|ถูกที่สุด|ฟรี|free|money|loan|sale)',
          caseSensitive: false),
    ];

    // Check patterns
    for (final pattern in spamPatterns) {
      if (pattern.hasMatch(content)) {
        return true;
      }
    }

    // Check for excessive repeated words
    final words = content.toLowerCase().split(RegExp(r'\s+'));
    final wordCount = <String, int>{};
    for (final word in words) {
      if (word.length > 3) {
        wordCount[word] = (wordCount[word] ?? 0) + 1;
        if (wordCount[word]! > 5) {
          // Same word repeated more than 5 times
          return true;
        }
      }
    }

    return false;
  }

  /// Check if user is behaving suspiciously
  static bool isSuspiciousUser(String userId) {
    final suspiciousScore = _suspiciousActivity[userId] ?? 0;
    return suspiciousScore > 10; // Threshold for suspicious behavior
  }

  /// Track suspicious activity
  static void _trackSuspiciousActivity(String userId, String activity) {
    _suspiciousActivity[userId] = (_suspiciousActivity[userId] ?? 0) + 1;

    if (kDebugMode) {
      debugPrint(
          '🚨 Suspicious activity: $activity by user $userId (score: ${_suspiciousActivity[userId]})');
    }
  }

  /// Log security events
  static void _logSecurityEvent(String event, Map<String, dynamic> data) {
    if (kDebugMode) {
      debugPrint('🔒 Security event: $event - $data');
    }

    // Log to console for now (can be extended to external logging service)
    // FirebaseAnalytics would go here if available
  }

  /// Validate comment data
  static bool validateCommentData(Map<String, dynamic> data) {
    try {
      // Check required fields
      if (!data.containsKey('content') || !data.containsKey('reportId')) {
        _logSecurityEvent('invalid_comment_missing_fields', data);
        return false;
      }

      // Validate content
      final content = data['content'] as String?;
      if (content == null || content.trim().isEmpty || content.length > 500) {
        _logSecurityEvent('invalid_comment_content', {
          'content_length': content?.length,
        });
        return false;
      }

      // Check for spam
      if (isSpam(content)) {
        _logSecurityEvent('spam_detected_comment', {
          'content': content.substring(0, math.min(50, content.length)),
        });
        return false;
      }

      return true;
    } catch (e) {
      _logSecurityEvent('comment_validation_error', {'error': e.toString()});
      return false;
    }
  }

  /// Clear old tracking data
  static void cleanup() {
    final now = DateTime.now().millisecondsSinceEpoch;
    const oneHour = 60 * 60 * 1000;

    // Clean up request times older than 1 hour
    _requestTimes.forEach((key, times) {
      times.removeWhere((time) => now - time > oneHour);
    });

    // Remove empty entries
    _requestTimes.removeWhere((key, times) => times.isEmpty);

    // Reset suspicious activity scores periodically
    if (DateTime.now().hour == 0) {
      // Reset daily at midnight
      _suspiciousActivity.clear();
    }
  }

  /// Get current rate limit status for debugging
  static Map<String, dynamic> getRateLimitStatus() {
    final userId = AuthService.currentUser?.uid ?? 'anonymous';
    final now = DateTime.now().millisecondsSinceEpoch;
    const oneHour = 60 * 60 * 1000;

    final result = <String, dynamic>{};

    _requestTimes.forEach((key, times) {
      if (key.startsWith(userId)) {
        final recentTimes = times.where((time) => now - time < oneHour).length;
        result[key] = recentTimes;
      }
    });

    result['suspicious_score'] = _suspiciousActivity[userId] ?? 0;

    return result;
  }
}
