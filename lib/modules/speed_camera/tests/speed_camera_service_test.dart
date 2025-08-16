import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import '../services/speed_camera_service.dart';
import '../models/speed_camera_model.dart';

void main() {
  group('SpeedCameraService Tests', () {
    // Sample test data
    late List<SpeedCamera> testCameras;
    late LatLng currentLocation;

    setUp(() {
      currentLocation = LatLng(13.7563, 100.5018); // Bangkok center

      testCameras = [
        SpeedCamera(
          id: 'test1',
          location: LatLng(13.7563, 100.5018), // Same as current location (0m)
          speedLimit: 80,
          type: CameraType.fixed,
          roadName: 'Test Road 1',
          description: 'Test Camera 1',
        ),
        SpeedCamera(
          id: 'test2',
          location: LatLng(13.7573, 100.5028), // ~1.2km away
          speedLimit: 60,
          type: CameraType.mobile,
          roadName: 'Test Road 2',
          description: 'Test Camera 2',
        ),
        SpeedCamera(
          id: 'test3',
          location: LatLng(13.7663, 100.5118), // ~12km away
          speedLimit: 100,
          type: CameraType.fixed,
          roadName: 'Highway 1',
          description: 'Highway Camera',
        ),
        SpeedCamera(
          id: 'test4',
          location: LatLng(13.7463, 100.4918), // ~12km away opposite direction
          speedLimit: 50,
          type: CameraType.mobile,
          roadName: 'Local Street',
          description: 'Local Camera',
        ),
      ];
    });

    test('findNearestCamera should return closest camera within range', () {
      final nearest = SpeedCameraService.findNearestCamera(
        currentLocation,
        testCameras,
        maxDistance: 5000, // 5km
      );

      expect(nearest, isNotNull);
      expect(nearest!.id, equals('test1')); // Should be the closest one
    });

    test('findNearestCamera should return null when no cameras in range', () {
      final nearest = SpeedCameraService.findNearestCamera(
        LatLng(14.0000, 101.0000), // Far away location
        testCameras,
        maxDistance: 1000, // 1km - too small for distant location
      );

      expect(nearest, isNull);
    });

    test('getCamerasInRange should return cameras within specified range', () {
      final camerasInRange = SpeedCameraService.getCamerasInRange(
        currentLocation,
        testCameras,
        range: 5000, // 5km - should include all test cameras
      );

      // All cameras should be within 5km based on our coordinates
      expect(camerasInRange.length, equals(4));
      expect(camerasInRange.any((c) => c.id == 'test1'), isTrue);
      expect(camerasInRange.any((c) => c.id == 'test2'), isTrue);
      expect(camerasInRange.any((c) => c.id == 'test3'), isTrue);
      expect(camerasInRange.any((c) => c.id == 'test4'), isTrue);
    });

    test('filterCamerasByType should return cameras of specified type', () {
      final fixedCameras = SpeedCameraService.filterCamerasByType(
        testCameras,
        CameraType.fixed,
      );

      expect(fixedCameras.length, equals(2)); // test1 and test3
      expect(fixedCameras.every((c) => c.type == CameraType.fixed), isTrue);

      final mobileCameras = SpeedCameraService.filterCamerasByType(
        testCameras,
        CameraType.mobile,
      );

      expect(mobileCameras.length, equals(2)); // test2 and test4
      expect(mobileCameras.every((c) => c.type == CameraType.mobile), isTrue);
    });

    test('filterCamerasBySpeedLimit should filter by speed range', () {
      // Test minimum speed filter
      final highSpeedCameras = SpeedCameraService.filterCamerasBySpeedLimit(
        testCameras,
        minSpeed: 80,
      );

      expect(highSpeedCameras.length, equals(2)); // test1 (80) and test3 (100)

      // Test maximum speed filter
      final lowSpeedCameras = SpeedCameraService.filterCamerasBySpeedLimit(
        testCameras,
        maxSpeed: 60,
      );

      expect(lowSpeedCameras.length, equals(2)); // test2 (60) and test4 (50)

      // Test range filter
      final mediumSpeedCameras = SpeedCameraService.filterCamerasBySpeedLimit(
        testCameras,
        minSpeed: 60,
        maxSpeed: 80,
      );

      expect(mediumSpeedCameras.length, equals(2)); // test1 (80) and test2 (60)
    });

    test('sortCamerasByDistance should sort cameras by distance from location',
        () {
      final sortedCameras = SpeedCameraService.sortCamerasByDistance(
        currentLocation,
        testCameras,
      );

      expect(sortedCameras.length, equals(4));
      expect(sortedCameras[0].id, equals('test1')); // Closest
      expect(sortedCameras[1].id, equals('test2')); // Second closest
      // test3 and test4 are approximately same distance, so order may vary
    });

    test('searchCamerasByRoadName should find cameras by road name', () {
      final foundCameras = SpeedCameraService.searchCamerasByRoadName(
        testCameras,
        'test road',
      );

      expect(foundCameras.length, equals(2)); // test1 and test2
      expect(foundCameras.any((c) => c.id == 'test1'), isTrue);
      expect(foundCameras.any((c) => c.id == 'test2'), isTrue);
    });

    test('searchCamerasByRoadName should find cameras by description', () {
      final foundCameras = SpeedCameraService.searchCamerasByRoadName(
        testCameras,
        'highway',
      );

      expect(foundCameras.length, equals(1)); // test3 only
      expect(foundCameras[0].id, equals('test3'));
    });

    test('searchCamerasByRoadName should be case insensitive', () {
      final foundCameras = SpeedCameraService.searchCamerasByRoadName(
        testCameras,
        'HIGHWAY',
      );

      expect(foundCameras.length, equals(1));
      expect(foundCameras[0].id, equals('test3'));
    });

    test('getCameraStatistics should return correct statistics', () {
      final stats = SpeedCameraService.getCameraStatistics(testCameras);

      expect(stats['total'], equals(4));

      final typeCount = stats['typeCount'] as Map<CameraType, int>;
      expect(typeCount[CameraType.fixed], equals(2));
      expect(typeCount[CameraType.mobile], equals(2));

      final speedRanges = stats['speedRanges'] as Map<String, int>;
      expect(speedRanges['low'], equals(2)); // 50, 60
      expect(speedRanges['medium'], equals(1)); // 80
      expect(speedRanges['high'], equals(1)); // 100
    });

    test('getCamerasInRange should handle empty camera list', () {
      final camerasInRange = SpeedCameraService.getCamerasInRange(
        currentLocation,
        [],
        range: 2000,
      );

      expect(camerasInRange, isEmpty);
    });
  });
}
