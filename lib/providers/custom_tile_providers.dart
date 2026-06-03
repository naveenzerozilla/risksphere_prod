import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class CustomTileProvider implements TileProvider {
  final Map<String, Map<String, Map<int, String>>> tileUrls;
  final String hazardType;
  final int minZoom;
  final int maxZoom;
  String currentReducer;

  CustomTileProvider({
    required this.tileUrls,
    required this.hazardType,
    this.minZoom = 0,
    this.maxZoom = 22,
    this.currentReducer = "mean",
  });

  void updateReducer(String reducer) {
    currentReducer = reducer;
    // Trigger tile overlay refresh if needed
  }

  String getTileUrl(int zoom) {
    // Get tile URL based on hazard type, intensity, and zoom level
    return tileUrls[hazardType]?[currentReducer]?[zoom] ?? '';
  }

  @override
  Future<Tile> getTile(int x, int y, int? zoom) async {
    print("getTile called with x: $x, y: $y, zoom: $zoom");

    if (zoom == null || zoom < minZoom || zoom > maxZoom) {
      print("Zoom level $zoom is out of range.");
      return Tile(256, 256, Uint8List(0)); // Empty tile for invalid zoom levels
    }

    final tileUrl = '${getTileUrl(zoom)}/$zoom/$x/$y';
    print("Fetching tile from network: $tileUrl");

    try {
      final ByteData data =
          await NetworkAssetBundle(Uri.parse(tileUrl)).load(tileUrl);
      final Uint8List tileData = data.buffer.asUint8List();
      return Tile(256, 256, tileData);
    } catch (e) {
      print("Error fetching tile: $e");
      return Tile(256, 256, Uint8List(0)); // Return an empty tile on error
    }
  }
}
class CustomTileProvider1 implements TileProvider {
  final String baseUrl;

  static final Map<String, Tile> _tileCache = {};
  static final Set<String> _loadingTiles = {};

  static int _lastRequestedZoom = -1;
  static final Set<String> _processedCoordinates = {};

  static int _activeRequests = 0;
  static const int _maxConcurrent = 8;

  static final Map<String, DateTime> _recentlyRequested = {};
  static const Duration _deduplicateWindow = Duration(milliseconds: 500);

  CustomTileProvider1({required this.baseUrl});

  String getCleanBaseUrl() {
    return baseUrl.replaceAll(RegExp(r'/\d+/\d+/\d+$'), '');
  }

  @override
  Future<Tile> getTile(int x, int y, int? zoom) async {
    if (zoom == null) return _emptyTile();

    final cleanUrl = getCleanBaseUrl();
    final url = "$cleanUrl/$zoom/$x/$y";
    final coordinateKey = "$zoom-$x-$y";

    if (_tileCache.containsKey(url)) {
      return _tileCache[url]!;
    }

    if (_isDuplicateRequest(coordinateKey)) {
      // Return fallback while the original request completes
      return _getFallbackTile(x, y, zoom) ?? _emptyTile();
    }

    if (_shouldSkipTileLoad(zoom, coordinateKey)) {
      final fallback = _getFallbackTile(x, y, zoom);
      if (fallback != null) {
        return fallback;
      }
    }

    if (_loadingTiles.contains(url)) {
      return _getFallbackTile(x, y, zoom) ?? _emptyTile();
    }

    if (_activeRequests >= _maxConcurrent) {
      return _getFallbackTile(x, y, zoom) ?? _emptyTile();
    }

    _loadingTiles.add(url);
    _recentlyRequested[coordinateKey] = DateTime.now();
    _activeRequests++;

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'FlutterApp',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => http.Response('Timeout', 408),
      );

      if (response.statusCode == 200 &&
          response.bodyBytes.isNotEmpty &&
          _isImage(response.bodyBytes)) {

        final tile = Tile(256, 256, response.bodyBytes);
        _tileCache[url] = tile;
        _processedCoordinates.add(coordinateKey);

        return tile;
      } else if (response.statusCode == 408 || response.statusCode == 504) {
        // Timeout or gateway error - return fallback
        return _getFallbackTile(x, y, zoom) ?? _emptyTile();
      }
    } catch (e) {
      print(" Tile Error [$zoom/$x/$y]: $e");
      // Don't log every error, just return fallback
    } finally {
      _loadingTiles.remove(url);
      _activeRequests--;
    }

    return _getFallbackTile(x, y, zoom) ?? _emptyTile();
  }

  bool _isDuplicateRequest(String coordinateKey) {
    if (_recentlyRequested.containsKey(coordinateKey)) {
      final lastTime = _recentlyRequested[coordinateKey];
      if (lastTime != null) {
        final timeDiff = DateTime.now().difference(lastTime);
        if (timeDiff.inMilliseconds < _deduplicateWindow.inMilliseconds) {
          return true; // This is a duplicate request
        }
      }
    }
    return false;
  }
  bool _shouldSkipTileLoad(int currentZoom, String coordinateKey) {
    // If we already processed this coordinate at this zoom level, skip reload
    if (_processedCoordinates.contains(coordinateKey)) {
      return true;
    }

    // If zooming in/out but the tile is already cached, don't reload
    if (_lastRequestedZoom != -1 &&
        (currentZoom - _lastRequestedZoom).abs() <= 1) {
      // Zoom level change is minimal, try to use cached version
      return _tileCache.containsKey(coordinateKey);
    }

    _lastRequestedZoom = currentZoom;
    return false;
  }

  Tile? _getFallbackTile(int x, int y, int zoom) {
    if (zoom <= 0) return null;

    // Try parent tiles (zoom out) instead of blank tiles
    for (int z = zoom - 1; z >= zoom - 2; z--) {
      if (z < 0) break;

      final parentX = x ~/ (1 << (zoom - z));
      final parentY = y ~/ (1 << (zoom - z));
      final fallbackUrl = "${getCleanBaseUrl()}/$z/$parentX/$parentY";

      if (_tileCache.containsKey(fallbackUrl)) {
        return _tileCache[fallbackUrl];
      }
    }

    return null;
  }

  Tile _emptyTile() {
    return Tile(256, 256, Uint8List(0));
  }

  bool _isImage(Uint8List bytes) {
    if (bytes.length < 4) return false;

    // PNG signature
    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) return true;

    // JPEG signature
    if (bytes[0] == 0xFF && bytes[1] == 0xD8) return true;

    // WebP signature
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) return true;

    return false;
  }

  /// 🔹 CLEAR CACHE (call when navigating away)
  static void clearCache() {
    _tileCache.clear();
    _loadingTiles.clear();
    _recentlyRequested.clear();
    _processedCoordinates.clear();
    _lastRequestedZoom = -1;
    _activeRequests = 0;
    print("Tile cache cleared");
  }

  ///  PARTIAL CACHE CLEAR (for memory optimization)
  static void clearOldCache({int maxItems = 500}) {
    if (_tileCache.length > maxItems) {
      final keysToRemove = _tileCache.keys.toList().sublist(0, _tileCache.length - maxItems);
      for (var key in keysToRemove) {
        _tileCache.remove(key);
      }
      print("🗑 Cleared old tiles, cache size: ${_tileCache.length}");
    }
  }

  ///  GET CACHE STATS (for debugging)
  static Map<String, dynamic> getCacheStats() {
    return {
      'cachedTiles': _tileCache.length,
      'loadingTiles': _loadingTiles.length,
      'activeRequests': _activeRequests,
      'recentRequests': _recentlyRequested.length,
    };
  }
}


