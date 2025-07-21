import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math';
import '../models/event_model.dart';
import '../widgets/event_marker.dart';

/// คลาสสำหรับจัดกลุ่ม Marker
class MarkerCluster {
  final List<ClusterMarker> markers;
  final LatLng center;
  final double zoom;

  MarkerCluster({
    required this.markers,
    required this.center,
    required this.zoom,
  });
}

/// Marker แต่ละตัวที่จะถูกจัดกลุ่ม
class ClusterMarker {
  final LatLng point;
  final EventCategory category;
  final Map<String, dynamic> data;
  final String docId;

  ClusterMarker({
    required this.point,
    required this.category,
    required this.data,
    required this.docId,
  });
}

/// Widget สำหรับแสดง Cluster
class ClusterWidget extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  final double size;

  const ClusterWidget({
    super.key,
    required this.count,
    required this.onTap,
    this.size = 40.0,
  });

  @override
  Widget build(BuildContext context) {
    // เปลี่ยนสีตามจำนวน marker
    Color backgroundColor;
    if (count < 10) {
      backgroundColor = const Color(0xFF4CAF50); // เขียว
    } else if (count < 50) {
      backgroundColor = const Color(0xFFFF9800); // ส้ม
    } else {
      backgroundColor = const Color(0xFFF44336); // แดง
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            count > 99 ? '99+' : count.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

/// คลาสสำหรับจัดการ Marker Clustering
class MarkerClusteringService {
  static const double clusterRadius = 80.0; // รัศมีการจัดกลุ่มในพิกเซล
  static const int minZoomCluster = 10; // zoom ขั้นต่ำที่จะแสดง cluster

  /// จัดกลุ่ม markers ตามระยะทางและ zoom level
  static List<Marker> clusterMarkers({
    required List<ClusterMarker> markers,
    required double currentZoom,
    required Function(LatLng) onClusterTap,
    required Function(ClusterMarker) onMarkerTap,
  }) {
    // ถ้า zoom มากเกินไป ไม่ต้องจัดกลุ่ม
    if (currentZoom > minZoomCluster || markers.length <= 1) {
      return markers
          .map((marker) => Marker(
                point: marker.point,
                width: 55 * 1.16, // ใช้ขนาดใหม่เหมือน map_screen.dart
                height: 55 * 1.16,
                child: EventMarker(
                  scale: 1.16,
                  category: marker.category,
                  isPost: true,
                  onTap: () => onMarkerTap(marker),
                ),
              ))
          .toList();
    }

    final clusters = <MarkerCluster>[];
    final processedMarkers = <ClusterMarker>[];

    for (var marker in markers) {
      if (processedMarkers.contains(marker)) continue;

      // หา markers ที่อยู่ใกล้กัน
      final nearbyMarkers = <ClusterMarker>[marker];
      processedMarkers.add(marker);

      for (var otherMarker in markers) {
        if (processedMarkers.contains(otherMarker)) continue;

        final distance = _calculatePixelDistance(
          marker.point,
          otherMarker.point,
          currentZoom,
        );

        if (distance <= clusterRadius) {
          nearbyMarkers.add(otherMarker);
          processedMarkers.add(otherMarker);
        }
      }

      // สร้าง cluster หรือ marker เดี่ยว
      if (nearbyMarkers.length > 1) {
        final center = _calculateCenter(nearbyMarkers);
        clusters.add(MarkerCluster(
          markers: nearbyMarkers,
          center: center,
          zoom: currentZoom,
        ));
      }
    }

    // สร้าง Flutter Markers
    final result = <Marker>[];

    // เพิ่ม cluster markers
    for (var cluster in clusters) {
      final size = _getClusterSize(cluster.markers.length);
      result.add(Marker(
        point: cluster.center,
        width: size,
        height: size,
        child: ClusterWidget(
          count: cluster.markers.length,
          size: size,
          onTap: () => onClusterTap(cluster.center),
        ),
      ));
    }

    // เพิ่ม markers ที่ไม่ได้จัดกลุ่ม
    final clusteredPoints = clusters
        .expand((cluster) => cluster.markers.map((m) => m.point))
        .toSet();

    for (var marker in markers) {
      if (!clusteredPoints.contains(marker.point)) {
        result.add(Marker(
          point: marker.point,
          width: 55 * 1.16,
          height: 55 * 1.16,
          child: EventMarker(
            scale: 1.16,
            category: marker.category,
            isPost: true,
            onTap: () => onMarkerTap(marker),
          ),
        ));
      }
    }

    return result;
  }

  /// คำนวณระยะทางในพิกเซลระหว่าง 2 จุด
  static double _calculatePixelDistance(
    LatLng point1,
    LatLng point2,
    double zoom,
  ) {
    const double mercatorRange = 256;

    // แปลงเป็น Mercator coordinates
    final lat1Rad = point1.latitudeInRad;
    final lat2Rad = point2.latitudeInRad;

    final x1 = mercatorRange * (point1.longitude + 180) / 360;
    final x2 = mercatorRange * (point2.longitude + 180) / 360;

    final y1 = mercatorRange *
        (180 - (180 / pi * log(tan(pi / 4 + lat1Rad / 2)))) /
        360;
    final y2 = mercatorRange *
        (180 - (180 / pi * log(tan(pi / 4 + lat2Rad / 2)))) /
        360;

    final pixelDistance =
        sqrt(pow(x2 - x1, 2) + pow(y2 - y1, 2)) * pow(2, zoom);

    return pixelDistance;
  }

  /// คำนวณจุดศูนย์กลางของ cluster
  static LatLng _calculateCenter(List<ClusterMarker> markers) {
    if (markers.isEmpty) return const LatLng(0, 0);
    if (markers.length == 1) return markers.first.point;

    double totalLat = 0;
    double totalLng = 0;

    for (var marker in markers) {
      totalLat += marker.point.latitude;
      totalLng += marker.point.longitude;
    }

    return LatLng(
      totalLat / markers.length,
      totalLng / markers.length,
    );
  }

  /// กำหนดขนาด cluster ตามจำนวน markers
  static double _getClusterSize(int count) {
    if (count < 10) return 35.0;
    if (count < 50) return 45.0;
    if (count < 100) return 55.0;
    return 65.0;
  }
}
