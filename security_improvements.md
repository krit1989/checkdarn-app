# Security & Performance Improvements

## 🛡️ Firebase Security Rules

### Enhanced Firestore Rules
```javascript
// firestore.rules - Enhanced Security
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Reports collection with rate limiting and validation
    match /reports/{reportId} {
      // Read: Allow authenticated users, limit to reasonable queries
      allow read: if request.auth != null 
        && resource.data.timestamp > timestamp.date(2024, 1, 1)
        && request.query.limit <= 100;
      
      // Write: Strict validation and rate limiting
      allow create: if request.auth != null 
        && isValidReport(request.resource.data)
        && rateLimitCheck(request.auth.uid, 'reports', 5, 3600); // 5 reports per hour
      
      allow update: if request.auth != null 
        && request.auth.uid == resource.data.userId
        && isValidReport(request.resource.data);
      
      allow delete: if request.auth != null 
        && (request.auth.uid == resource.data.userId 
            || isAdmin(request.auth.uid));
    }

    // Comments with anti-spam protection
    match /reports/{reportId}/comments/{commentId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null 
        && isValidComment(request.resource.data)
        && rateLimitCheck(request.auth.uid, 'comments', 10, 3600); // 10 comments per hour
    }

    // Rate limiting collection
    match /rate_limits/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }

  // Validation functions
  function isValidReport(data) {
    return data.keys().hasAll(['title', 'lat', 'lng', 'category', 'timestamp', 'userId'])
      && data.title is string && data.title.size() <= 200
      && data.lat is number && data.lat >= -90 && data.lat <= 90
      && data.lng is number && data.lng >= -180 && data.lng <= 180
      && data.category in ['checkpoint', 'accident', 'fire', 'floodRain', 'tsunami', 'earthquake']
      && data.userId == request.auth.uid
      && data.timestamp > timestamp.date(2024, 1, 1);
  }

  function isValidComment(data) {
    return data.keys().hasAll(['content', 'userId', 'timestamp'])
      && data.content is string && data.content.size() <= 500
      && data.userId == request.auth.uid;
  }

  function rateLimitCheck(userId, action, limit, windowSeconds) {
    // This would need to be implemented with Cloud Functions
    // for now, return true but should be enhanced
    return true;
  }

  function isAdmin(userId) {
    return userId in ['admin-uid-1', 'admin-uid-2']; // Replace with actual admin UIDs
  }
}
```

### Cloud Functions for Rate Limiting
```javascript
// functions/index.js - Rate Limiting
const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Rate limiting middleware
exports.rateLimitMiddleware = functions.firestore
  .document('reports/{reportId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const userId = data.userId;
    const now = Date.now();
    const oneHour = 60 * 60 * 1000;

    // Check rate limit
    const rateLimitRef = admin.firestore().collection('rate_limits').doc(userId);
    const rateLimitDoc = await rateLimitRef.get();

    if (rateLimitDoc.exists) {
      const rateLimitData = rateLimitDoc.data();
      const recentReports = rateLimitData.reports || [];
      
      // Remove old entries
      const recentReportsFiltered = recentReports.filter(timestamp => 
        now - timestamp < oneHour
      );

      // Check if user exceeded limit
      if (recentReportsFiltered.length >= 5) { // 5 reports per hour
        // Delete the report and log abuse
        await snap.ref.delete();
        console.log(`Rate limit exceeded for user: ${userId}`);
        
        // Optionally ban user temporarily
        await admin.auth().setCustomUserClaims(userId, { 
          banned: true, 
          banUntil: now + oneHour 
        });
        
        return;
      }

      // Update rate limit
      recentReportsFiltered.push(now);
      await rateLimitRef.update({ reports: recentReportsFiltered });
    } else {
      // First report for user
      await rateLimitRef.set({ reports: [now] });
    }
  });
```

## 🔒 Client-Side Security

### Enhanced Authentication & Validation
```dart
// lib/services/security_service.dart
class SecurityService {
  static const int MAX_REQUESTS_PER_MINUTE = 10;
  static const int MAX_REPORTS_PER_HOUR = 5;
  
  static final Map<String, List<int>> _requestTimes = {};
  static final Map<String, List<int>> _reportTimes = {};

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
      debugPrint('🚨 Rate limit exceeded for $action');
      return false;
    }
    
    // Add current request
    _requestTimes[key]!.add(now);
    return true;
  }

  /// Validate report data before sending
  static bool validateReportData(Map<String, dynamic> data) {
    // Check required fields
    if (!data.containsKey('title') || !data.containsKey('lat') || !data.containsKey('lng')) {
      return false;
    }

    // Validate coordinates (Thailand bounds roughly)
    final lat = data['lat'] as double?;
    final lng = data['lng'] as double?;
    if (lat == null || lng == null || 
        lat < 5.0 || lat > 21.0 || 
        lng < 97.0 || lng > 106.0) {
      return false;
    }

    // Validate text length
    final title = data['title'] as String?;
    if (title == null || title.length > 200 || title.trim().isEmpty) {
      return false;
    }

    return true;
  }

  /// Sanitize user input
  static String sanitizeInput(String input) {
    // Remove potentially dangerous characters
    return input
        .replaceAll(RegExp(r'[<>"\'/\\]'), '')
        .trim()
        .substring(0, math.min(input.length, 500));
  }

  /// Check for spam patterns
  static bool isSpam(String content) {
    // Simple spam detection
    final spamPatterns = [
      RegExp(r'(http|https):\/\/[^\s]+', caseSensitive: false),
      RegExp(r'(.)\1{10,}'), // Repeated characters
      RegExp(r'[A-Z]{20,}'), // Too many caps
    ];

    return spamPatterns.any((pattern) => pattern.hasMatch(content));
  }
}
```

## 📊 Performance Monitoring & Alerts

### Performance Monitoring Service
```dart
// lib/services/performance_service.dart
class PerformanceService {
  static const int ALERT_THRESHOLD_MS = 5000;
  static const int MEMORY_ALERT_MB = 200;
  
  static final Map<String, List<int>> _performanceMetrics = {};

  static void trackOperation(String operation, int durationMs) {
    _performanceMetrics[operation] = _performanceMetrics[operation] ?? [];
    _performanceMetrics[operation]!.add(durationMs);

    // Alert if too slow
    if (durationMs > ALERT_THRESHOLD_MS) {
      _sendPerformanceAlert(operation, durationMs);
    }

    // Keep only last 100 measurements
    if (_performanceMetrics[operation]!.length > 100) {
      _performanceMetrics[operation]!.removeAt(0);
    }
  }

  static void _sendPerformanceAlert(String operation, int duration) {
    // Send to monitoring service (Firebase Analytics, Crashlytics, etc.)
    FirebaseAnalytics.instance.logEvent(
      name: 'performance_alert',
      parameters: {
        'operation': operation,
        'duration_ms': duration,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  static Map<String, double> getAverageMetrics() {
    final averages = <String, double>{};
    
    _performanceMetrics.forEach((operation, durations) {
      if (durations.isNotEmpty) {
        averages[operation] = durations.reduce((a, b) => a + b) / durations.length;
      }
    });

    return averages;
  }
}
```

## 🔧 Enhanced Caching Strategy

### Multi-level Caching
```dart
// lib/services/cache_service.dart
class CacheService {
  static const int MAX_CACHE_SIZE = 1000;
  static const Duration CACHE_TTL = Duration(minutes: 5);
  
  static final Map<String, CacheEntry> _cache = {};
  static Timer? _cleanupTimer;

  static void initialize() {
    _cleanupTimer = Timer.periodic(Duration(minutes: 1), (_) => _cleanup());
  }

  static T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;
    
    // Check TTL
    if (DateTime.now().difference(entry.timestamp) > CACHE_TTL) {
      _cache.remove(key);
      return null;
    }
    
    return entry.value as T?;
  }

  static void set(String key, dynamic value) {
    // Prevent cache overflow
    if (_cache.length >= MAX_CACHE_SIZE) {
      _evictOldest();
    }
    
    _cache[key] = CacheEntry(value, DateTime.now());
  }

  static void _cleanup() {
    final now = DateTime.now();
    _cache.removeWhere((key, entry) => 
      now.difference(entry.timestamp) > CACHE_TTL
    );
  }

  static void _evictOldest() {
    if (_cache.isEmpty) return;
    
    String? oldestKey;
    DateTime? oldestTime;
    
    _cache.forEach((key, entry) {
      if (oldestTime == null || entry.timestamp.isBefore(oldestTime!)) {
        oldestKey = key;
        oldestTime = entry.timestamp;
      }
    });
    
    if (oldestKey != null) {
      _cache.remove(oldestKey);
    }
  }
}

class CacheEntry {
  final dynamic value;
  final DateTime timestamp;
  
  CacheEntry(this.value, this.timestamp);
}
```
