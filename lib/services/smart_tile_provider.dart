import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/painting.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'map_cache_manager.dart';
import 'connection_manager.dart';

class SmartTileProvider extends TileProvider {
  final String urlTemplate;
  final Map<String, String> additionalOptions;
  bool _isPreloading = false;

  SmartTileProvider({
    required this.urlTemplate,
    this.additionalOptions = const {},
  });

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return SmartTileImageProvider(
      coordinates: coordinates,
      options: options,
      urlTemplate: urlTemplate,
      additionalOptions: additionalOptions,
    );
  }

  // Preload tiles around current position
  Future<void> preloadTilesAround(LatLng position, int zoom,
      {int radius = 2}) async {
    if (_isPreloading) return; // Prevent multiple preload operations

    _isPreloading = true;

    try {
      await ConnectionManager.checkConnection();

      // Only preload on good connections
      if (ConnectionManager.shouldPreloadTiles()) {
        await MapCacheManager.preloadTilesAround(
            position.latitude, position.longitude, zoom,
            radius: radius);
      }
    } catch (e) {
      print('Error preloading tiles: $e');
    } finally {
      _isPreloading = false;
    }
  }
}

class SmartTileImageProvider extends ImageProvider<SmartTileImageProvider> {
  final TileCoordinates coordinates;
  final TileLayer options;
  final String urlTemplate;
  final Map<String, String> additionalOptions;

  const SmartTileImageProvider({
    required this.coordinates,
    required this.options,
    required this.urlTemplate,
    required this.additionalOptions,
  });

  @override
  Future<SmartTileImageProvider> obtainKey(ImageConfiguration configuration) {
    return Future.value(this);
  }

  @override
  ImageStreamCompleter loadBuffer(
      SmartTileImageProvider key, DecoderBufferCallback decode) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode),
      scale: 1.0,
    );
  }

  Future<ui.Codec> _loadAsync(
      SmartTileImageProvider key, DecoderBufferCallback decode) async {
    try {
      final tileData = await _getTileData();

      if (tileData != null) {
        final buffer = await ui.ImmutableBuffer.fromUint8List(tileData);
        return await decode(buffer);
      } else {
        // Return placeholder/error tile
        return await _createErrorTile(decode);
      }
    } catch (e) {
      print('Error loading tile: $e');
      return await _createErrorTile(decode);
    }
  }

  Future<Uint8List?> _getTileData() async {
    final z = coordinates.z.round();
    final x = coordinates.x.round();
    final y = coordinates.y.round();

    // Step 1: Try to get from cache first (fastest)
    final cachedTile = await MapCacheManager.getCachedTile(z, x, y);
    if (cachedTile != null) {
      return cachedTile;
    }

    // Step 2: Check connection status
    await ConnectionManager.checkConnection();

    // Step 3: If online, try to download
    if (ConnectionManager.shouldUseOnlineMaps()) {
      final downloadedTile =
          await MapCacheManager.downloadAndCacheTile(z, x, y);
      if (downloadedTile != null) {
        return downloadedTile;
      }
    }

    // Step 4: No tile available - will show placeholder
    return null;
  }

  Future<ui.Codec> _createErrorTile(DecoderBufferCallback decode) async {
    // Create a simple 256x256 gray placeholder tile
    final Uint8List placeholderData = _createPlaceholderTileData();
    final buffer = await ui.ImmutableBuffer.fromUint8List(placeholderData);
    return await decode(buffer);
  }

  Uint8List _createPlaceholderTileData() {
    // Simple PNG header for a 256x256 gray tile
    // This is a minimal PNG that represents a gray square
    return Uint8List.fromList([
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
      0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, // IHDR chunk
      0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x00, // 256x256
      0x08, 0x02, 0x00, 0x00, 0x00, 0x30, 0x7D, 0x77, // RGB, no compression
      0x75, 0x00, 0x00, 0x00, 0x19, 0x74, 0x45, 0x58, // texture data
      0x74, 0x53, 0x6F, 0x66, 0x74, 0x77, 0x61, 0x72, // software
      0x65, 0x00, 0x41, 0x64, 0x6F, 0x62, 0x65, 0x20,
      0x49, 0x6D, 0x61, 0x67, 0x65, 0x52, 0x65, 0x61,
      0x64, 0x79, 0x71, 0xC9, 0x65, 0x3C, 0x00, 0x00,
      0x00, 0x0C, 0x49, 0x44, 0x41, 0x54, 0x78, 0xDA, // IDAT chunk start
      0x62, 0x60, 0x60, 0x60, 0x00, 0x00, 0x00, 0x04, // minimal gray data
      0x00, 0x01, 0x27, 0x10, 0xDA, 0x0F, 0x00, 0x00,
      0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, // IEND
      0x60, 0x82
    ]);
  }

  @override
  bool operator ==(Object other) {
    return other is SmartTileImageProvider &&
        coordinates.x == other.coordinates.x &&
        coordinates.y == other.coordinates.y &&
        coordinates.z == other.coordinates.z &&
        urlTemplate == other.urlTemplate;
  }

  @override
  int get hashCode => Object.hash(
        coordinates.x,
        coordinates.y,
        coordinates.z,
        urlTemplate,
      );
}
