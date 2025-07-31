import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Secure Storage Service for sensitive data
///
/// Features:
/// - Encrypted storage for auth tokens and sensitive data
/// - Fallback to SharedPreferences for non-sensitive data
/// - Automatic token refresh management
/// - Session management with timeout
/// - Debug logging for security events
class SecureStorageService {
  // Secure storage instance with optimal configuration
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      sharedPreferencesName: 'checkdarn_secure_prefs',
      preferencesKeyPrefix: 'checkdarn_',
    ),
    iOptions: IOSOptions(
      groupId: 'group.com.checkdarn.app',
      accountName: 'CheckDarn',
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static SharedPreferences? _prefs;

  // Storage keys for different data types
  static const String _authTokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userCredentialsKey = 'user_credentials';
  static const String _sessionKey = 'session_data';
  static const String _lastLoginKey = 'last_login_time';
  static const String _deviceIdKey = 'device_id';
  static const String _biometricEnabledKey = 'biometric_enabled';

  /// Initialize secure storage service
  static Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();

      // Test secure storage availability
      await _testSecureStorage();

      if (kDebugMode) {
        print('✅ Secure Storage Service initialized');
        print(
            '🔒 Secure storage: ${await _isSecureStorageAvailable() ? 'Available' : 'Fallback mode'}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to initialize Secure Storage Service: $e');
      }
    }
  }

  /// Store auth token securely
  static Future<void> storeAuthToken(String token) async {
    try {
      await _secureStorage.write(key: _authTokenKey, value: token);
      await _storeSecurely(_lastLoginKey, DateTime.now().toIso8601String());

      if (kDebugMode) {
        print('🔒 Auth token stored securely');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to store auth token: $e');
      }
      rethrow;
    }
  }

  /// Retrieve auth token
  static Future<String?> getAuthToken() async {
    try {
      final token = await _secureStorage.read(key: _authTokenKey);

      if (token != null) {
        // Check if token is expired based on last login
        final lastLogin = await _getSecurely(_lastLoginKey);
        if (lastLogin != null && _isTokenExpired(lastLogin)) {
          await clearAuthToken();

          if (kDebugMode) {
            print('🕐 Auth token expired and cleared');
          }
          return null;
        }
      }

      return token;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to retrieve auth token: $e');
      }
      return null;
    }
  }

  /// Store refresh token
  static Future<void> storeRefreshToken(String refreshToken) async {
    try {
      await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);

      if (kDebugMode) {
        print('🔒 Refresh token stored securely');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to store refresh token: $e');
      }
      rethrow;
    }
  }

  /// Get refresh token
  static Future<String?> getRefreshToken() async {
    try {
      return await _secureStorage.read(key: _refreshTokenKey);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to retrieve refresh token: $e');
      }
      return null;
    }
  }

  /// Store user credentials for auto-login
  static Future<void> storeUserCredentials({
    required String userId,
    required String email,
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      final credentials = {
        'user_id': userId,
        'email': email,
        'display_name': displayName,
        'photo_url': photoUrl,
        'stored_at': DateTime.now().toIso8601String(),
      };

      await _secureStorage.write(
        key: _userCredentialsKey,
        value: jsonEncode(credentials),
      );

      if (kDebugMode) {
        print('🔒 User credentials stored securely');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to store user credentials: $e');
      }
      rethrow;
    }
  }

  /// Get stored user credentials
  static Future<Map<String, dynamic>?> getUserCredentials() async {
    try {
      final credentialsStr =
          await _secureStorage.read(key: _userCredentialsKey);

      if (credentialsStr != null) {
        final credentials = jsonDecode(credentialsStr) as Map<String, dynamic>;

        // Check if credentials are still valid (not older than 30 days)
        final storedAt = DateTime.parse(credentials['stored_at']);
        if (DateTime.now().difference(storedAt).inDays > 30) {
          await clearUserCredentials();

          if (kDebugMode) {
            print('🕐 User credentials expired and cleared');
          }
          return null;
        }

        return credentials;
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to retrieve user credentials: $e');
      }
      return null;
    }
  }

  /// Store session data
  static Future<void> storeSessionData(Map<String, dynamic> sessionData) async {
    try {
      await _storeSecurely(_sessionKey, jsonEncode(sessionData));

      if (kDebugMode) {
        print('🔒 Session data stored securely');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to store session data: $e');
      }
      rethrow;
    }
  }

  /// Get session data
  static Future<Map<String, dynamic>?> getSessionData() async {
    try {
      final sessionStr = await _getSecurely(_sessionKey);

      if (sessionStr != null) {
        return jsonDecode(sessionStr) as Map<String, dynamic>;
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to retrieve session data: $e');
      }
      return null;
    }
  }

  /// Store device ID for security tracking
  static Future<void> storeDeviceId(String deviceId) async {
    try {
      await _storeSecurely(_deviceIdKey, deviceId);

      if (kDebugMode) {
        print('🔒 Device ID stored securely');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to store device ID: $e');
      }
    }
  }

  /// Get device ID
  static Future<String?> getDeviceId() async {
    try {
      return await _getSecurely(_deviceIdKey);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to retrieve device ID: $e');
      }
      return null;
    }
  }

  /// Enable/disable biometric authentication
  static Future<void> setBiometricEnabled(bool enabled) async {
    try {
      await _storeSecurely(_biometricEnabledKey, enabled.toString());

      if (kDebugMode) {
        print('🔒 Biometric setting updated: $enabled');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to set biometric setting: $e');
      }
    }
  }

  /// Check if biometric authentication is enabled
  static Future<bool> isBiometricEnabled() async {
    try {
      final enabled = await _getSecurely(_biometricEnabledKey);
      return enabled == 'true';
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to check biometric setting: $e');
      }
      return false;
    }
  }

  /// Clear all auth-related data
  static Future<void> clearAuthData() async {
    try {
      await clearAuthToken();
      await clearRefreshToken();
      await clearUserCredentials();
      await clearSessionData();

      if (kDebugMode) {
        print('🧹 All auth data cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to clear auth data: $e');
      }
    }
  }

  /// Clear auth token
  static Future<void> clearAuthToken() async {
    try {
      await _secureStorage.delete(key: _authTokenKey);
      await _secureStorage.delete(key: _lastLoginKey);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to clear auth token: $e');
      }
    }
  }

  /// Clear refresh token
  static Future<void> clearRefreshToken() async {
    try {
      await _secureStorage.delete(key: _refreshTokenKey);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to clear refresh token: $e');
      }
    }
  }

  /// Clear user credentials
  static Future<void> clearUserCredentials() async {
    try {
      await _secureStorage.delete(key: _userCredentialsKey);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to clear user credentials: $e');
      }
    }
  }

  /// Clear session data
  static Future<void> clearSessionData() async {
    try {
      await _secureStorage.delete(key: _sessionKey);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to clear session data: $e');
      }
    }
  }

  /// Clear all secure storage
  static Future<void> clearAll() async {
    try {
      await _secureStorage.deleteAll();

      if (kDebugMode) {
        print('🧹 All secure storage cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to clear all secure storage: $e');
      }
    }
  }

  /// Check if user has valid session
  static Future<bool> hasValidSession() async {
    try {
      final token = await getAuthToken();
      final credentials = await getUserCredentials();

      return token != null && credentials != null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to check session validity: $e');
      }
      return false;
    }
  }

  /// Get storage statistics for debugging
  static Future<Map<String, dynamic>> getStorageStats() async {
    try {
      final stats = <String, dynamic>{
        'secure_storage_available': await _isSecureStorageAvailable(),
        'has_auth_token': await getAuthToken() != null,
        'has_refresh_token': await getRefreshToken() != null,
        'has_user_credentials': await getUserCredentials() != null,
        'has_session_data': await getSessionData() != null,
        'has_device_id': await getDeviceId() != null,
        'biometric_enabled': await isBiometricEnabled(),
        'has_valid_session': await hasValidSession(),
      };

      // Add last login info if available
      final lastLogin = await _getSecurely(_lastLoginKey);
      if (lastLogin != null) {
        final lastLoginTime = DateTime.parse(lastLogin);
        stats['last_login'] = lastLogin;
        stats['days_since_login'] =
            DateTime.now().difference(lastLoginTime).inDays;
      }

      return stats;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to get storage stats: $e');
      }
      return {'error': e.toString()};
    }
  }

  // Private helper methods

  static Future<void> _storeSecurely(String key, String value) async {
    try {
      await _secureStorage.write(key: key, value: value);
    } catch (e) {
      // Fallback to SharedPreferences for non-critical data
      if (_prefs != null) {
        await _prefs!.setString('fallback_$key', value);

        if (kDebugMode) {
          print('⚠️ Using SharedPreferences fallback for: $key');
        }
      } else {
        rethrow;
      }
    }
  }

  static Future<String?> _getSecurely(String key) async {
    try {
      return await _secureStorage.read(key: key);
    } catch (e) {
      // Try fallback from SharedPreferences
      if (_prefs != null) {
        final value = _prefs!.getString('fallback_$key');

        if (value != null && kDebugMode) {
          print('⚠️ Retrieved from SharedPreferences fallback: $key');
        }

        return value;
      }
      return null;
    }
  }

  static Future<bool> _isSecureStorageAvailable() async {
    try {
      await _secureStorage.write(key: 'test_key', value: 'test_value');
      final value = await _secureStorage.read(key: 'test_key');
      await _secureStorage.delete(key: 'test_key');

      return value == 'test_value';
    } catch (e) {
      return false;
    }
  }

  static Future<void> _testSecureStorage() async {
    try {
      const testKey = 'init_test';
      final testValue = 'test_value_${DateTime.now().millisecondsSinceEpoch}';

      await _secureStorage.write(key: testKey, value: testValue);
      final retrievedValue = await _secureStorage.read(key: testKey);
      await _secureStorage.delete(key: testKey);

      if (retrievedValue != testValue) {
        throw Exception('Secure storage test failed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Secure storage test failed, will use fallback: $e');
      }
    }
  }

  static bool _isTokenExpired(String lastLoginStr) {
    try {
      final lastLogin = DateTime.parse(lastLoginStr);
      const tokenValidityDuration = Duration(days: 7); // 7 days token validity

      return DateTime.now().difference(lastLogin) > tokenValidityDuration;
    } catch (e) {
      return true; // Assume expired if we can't parse the date
    }
  }
}
