# Speed Camera Module

This module contains all components related to speed camera functionality in the CheckDarn app.

## Structure

```
lib/modules/speed_camera/
├── models/                     # Data models
│   ├── speed_camera_model.dart # SpeedCamera entity
│   └── camera_report_model.dart # CameraReport entity
├── screens/                    # UI screens
│   ├── speed_camera_screen.dart # Main speed camera map view
│   └── camera_report_screen.dart # Camera reporting interface
├── services/                   # Business logic
│   ├── speed_camera_service.dart # Speed camera data management
│   └── camera_report_service.dart # Camera reporting logic
├── widgets/                    # Reusable UI components
│   ├── speed_camera_marker.dart # Map marker for cameras
│   ├── camera_report_form_widget.dart # Report form
│   └── camera_report_card_widget.dart # Report display card
└── speed_camera_module.dart    # Module exports
```

## Features

### Speed Camera Screen
- Real-time GPS tracking
- Speed limit warnings
- Camera proximity alerts
- Smooth map navigation
- Sound management
- Predictive alerts

### Camera Report System
- Community-driven camera reporting
- Voting system for verification
- Multiple report types (new, removed, speed limit changes)
- User statistics and contribution tracking

## Dependencies

### Shared Services (from main app)
- `AuthService` - User authentication
- `GeocodingService` - Location geocoding
- `SoundManager` - Audio alerts
- `SmartTileProvider` - Map tile management
- `ConnectionManager` - Network management
- `MapCacheManager` - Map caching

### External Packages
- `flutter_map` - Map display
- `geolocator` - GPS location
- `latlong2` - Coordinate calculations
- `cloud_firestore` - Database
- `firebase_auth` - Authentication

## Usage

### Import the module
```dart
import '../modules/speed_camera/speed_camera_module.dart';
```

### Navigate to Speed Camera Screen
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const SpeedCameraScreen(),
  ),
);
```

## Data Models

### SpeedCamera
- `id`: Unique identifier
- `location`: GPS coordinates
- `speedLimit`: Speed limit (km/h)
- `roadName`: Road name
- `type`: Camera type (fixed, mobile, etc.)
- `isActive`: Camera status
- `description`: Additional information

### CameraReport
- `id`: Report identifier
- `reportType`: Type of report
- `location`: GPS coordinates
- `roadName`: Road name
- `reportedBy`: User ID
- `timestamp`: Report time
- `votes`: Community votes
- `status`: Report status

## Architecture Notes

- Uses Firebase Firestore for data persistence
- Implements community voting system
- Real-time location tracking with optimized performance
- Modular design for easy maintenance and testing
- Shared services with main application for consistency
