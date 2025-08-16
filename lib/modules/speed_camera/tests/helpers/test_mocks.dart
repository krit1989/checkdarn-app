import 'dart:io';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:geolocator/geolocator.dart';

/// No-network HTTP overrides to prevent TileLayer from making network calls
class NoNetworkOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => NoHttpClient();
}

class NoHttpClient implements HttpClient {
  @override
  Future<void> close({bool force = false}) async {}

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    throw UnimplementedError('HTTP requests are disabled in tests');
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Fake GeolocatorPlatform that doesn't emit periodic position updates
class FakeGeolocator extends GeolocatorPlatform {
  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.whileInUse;

  @override
  Future<LocationPermission> requestPermission() async =>
      LocationPermission.whileInUse;

  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<Position> getCurrentPosition(
      {LocationSettings? locationSettings}) async {
    return Position(
      latitude: 13.7563,
      longitude: 100.5018,
      timestamp: DateTime.now(),
      accuracy: 5.0,
      altitude: 0.0,
      heading: 0.0,
      speed: 0.0,
      speedAccuracy: 0.1,
      altitudeAccuracy: 1.0,
      headingAccuracy: 1.0,
    );
  }

  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) {
    // Return empty stream to prevent periodic updates that cause pumpAndSettle to hang
    return const Stream.empty();
  }
}

/// Silent SoundManager for testing that tracks method calls without playing sounds
class SilentSoundManager {
  final List<String> calledMethods = [];
  final List<String> playedMessages = [];

  Future<void> initialize() async {
    calledMethods.add('initialize');
  }

  Future<void> playSpeedAlert({
    required String message,
    int? currentSpeed,
    int? speedLimit,
  }) async {
    calledMethods.add('playSpeedAlert');
    playedMessages.add(message);
  }

  Future<void> playProximityAlert({
    required String message,
    double? distance,
  }) async {
    calledMethods.add('playProximityAlert');
    playedMessages.add(message);
  }

  Future<void> playPredictiveAlert({
    required String message,
    String? roadName,
    int? speedLimit,
  }) async {
    calledMethods.add('playPredictiveAlert');
    playedMessages.add(message);
  }

  Future<void> playProgressiveBeep() async {
    calledMethods.add('playProgressiveBeep');
  }

  Future<void> dispose() async {
    calledMethods.add('dispose');
  }

  // Helper methods for testing
  void reset() {
    calledMethods.clear();
    playedMessages.clear();
  }

  bool wasMethodCalled(String method) {
    return calledMethods.contains(method);
  }

  bool wasMessagePlayed(String message) {
    return playedMessages.contains(message);
  }
}

/// Create a mock SoundManager instance for testing
SilentSoundManager createMockSoundManager() {
  return SilentSoundManager();
}

/// Setup test environment with mocked platform channels and no network
Future<void> setupTestEnvironment() async {
  // Prevent network calls
  HttpOverrides.global = NoNetworkOverrides();

  // Mock Geolocator platform
  GeolocatorPlatform.instance = FakeGeolocator();

  // Mock Firebase Core
  const firebaseCoreChannel = MethodChannel('plugins.flutter.io/firebase_core');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(firebaseCoreChannel, (MethodCall call) async {
    switch (call.method) {
      case 'Firebase#initializeCore':
        return [
          {
            'name': '[DEFAULT]',
            'options': {
              'apiKey': 'fake-api-key',
              'appId': 'fake-app-id',
              'projectId': 'fake-project-id',
            },
            'pluginConstants': {},
          }
        ];
      case 'Firebase#initializeApp':
        return {
          'name': '[DEFAULT]',
          'options': {
            'apiKey': 'fake-api-key',
            'appId': 'fake-app-id',
            'projectId': 'fake-project-id',
          },
          'pluginConstants': {},
        };
      default:
        return null;
    }
  });

  // Mock Firebase Auth
  const firebaseAuthChannel = MethodChannel('plugins.flutter.io/firebase_auth');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(firebaseAuthChannel, (MethodCall call) async {
    switch (call.method) {
      case 'Auth#registerIdTokenListener':
        return null;
      case 'Auth#registerAuthStateListener':
        return null;
      case 'Auth#currentUser':
        return null; // No user signed in
      default:
        return null;
    }
  });

  // Mock Cloud Firestore
  const firestoreChannel = MethodChannel('plugins.flutter.io/cloud_firestore');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(firestoreChannel, (MethodCall call) async {
    switch (call.method) {
      case 'Firestore#settings':
        return null;
      case 'Query#snapshots':
        return null;
      default:
        return null;
    }
  });

  // Mock wakelock_plus to prevent platform channel issues
  const wakelockChannel = MethodChannel('wakelock_plus');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(wakelockChannel, (MethodCall call) async {
    switch (call.method) {
      case 'toggle':
        return null;
      case 'enabled':
        return false;
      default:
        return null;
    }
  });

  // Mock any other method channels that might be used
  // Add more mocks here if needed for other plugins
}
