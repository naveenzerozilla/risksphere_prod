import 'dart:collection';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import '../utils/global_imports.dart';


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
  late final String cleanBaseUrl;

  // static final LinkedHashMap<String, Tile> _tileCache =
  // LinkedHashMap<String, Tile>();

  // static final Map<String, Completer<Tile>> _pendingTiles = {};

  static int _activeRequests = 0;

  static int get _maxConcurrent => Platform.isIOS ? 20 : 24;

  static final Queue<_TileRequest> _waitingQueue = Queue<_TileRequest>();
  static final Map<String, Tile> _tileCache = {};
  static final Map<String, Completer<Tile>> _pendingTiles = {};

  // Reduce concurrency on iOS — too many parallel SSL handshakes kills performance
  // static int _activeRequests = 0;
  //
  // static int get _maxConcurrent => Platform.isIOS ? 6 : 24;
  //
  // // Queue for tiles waiting for a slot
  // static final List<_TileRequest> _waitingQueue = [];

  static final http.Client _httpClient = _buildHttpClient();


  static http.Client _buildHttpClient() {
    if (Platform.isIOS) {
      final ioClient = HttpClient()
        ..connectionTimeout = const Duration(seconds: 10)
        ..idleTimeout = const Duration(seconds: 30)
        ..maxConnectionsPerHost = 20;
      return IOClient(ioClient);
    }
    return http.Client();
  }

  CustomTileProvider1({required this.baseUrl}) {
    cleanBaseUrl = baseUrl.replaceAll(RegExp(r'/\d+/\d+/\d+$'), '');
  }

  String getCleanBaseUrl() {
    return baseUrl.replaceAll(RegExp(r'/\d+/\d+/\d+$'), '');
  }
  Duration get _requestTimeout => const Duration(seconds: 8);

  int get _maxRetries => 1;
  @override
  Future<Tile> getTile(int x, int y, int? zoom) async {
    if (zoom == null) return _emptyTile();

    final url = "$cleanBaseUrl/$zoom/$x/$y";

    final cachedTile = _tileCache[url];
    if (cachedTile != null) {
      return cachedTile;
    }

    final pending = _pendingTiles[url];
    if (pending != null) {
      return pending.future;
    }

    final completer = Completer<Tile>();
    _pendingTiles[url] = completer;

    if (_activeRequests < _maxConcurrent) {
      _executeFetch(url, x, y, zoom, completer);
    } else {
      _waitingQueue.addLast(
        _TileRequest(
          url: url,
          x: x,
          y: y,
          zoom: zoom,
          completer: completer,
        ),
      );
    }

    return completer.future;
  }

  void _executeFetch(
    String url,
    int x,
    int y,
    int zoom,
    Completer<Tile> completer,
  ) {
    _activeRequests++;

    _fetchWithRetry(url, x, y, zoom).then((tile) {
      if (!completer.isCompleted) completer.complete(tile);
    }).catchError((e) {
      debugPrint("Tile Fatal [$zoom/$x/$y] => $e");
      if (!completer.isCompleted) completer.complete(_emptyTile());
    }).whenComplete(() {
      _pendingTiles.remove(url);
      _activeRequests--;
      _processQueue(); // process next waiting tile
    });
  }

  void _processQueue() {
    debugPrint(
      "Queue=${_waitingQueue.length}, Active=$_activeRequests",
    );
    while (_waitingQueue.isNotEmpty && _activeRequests < _maxConcurrent) {
      final request = _waitingQueue.removeFirst();

      final cachedTile = _tileCache[request.url];
      if (cachedTile != null) {
        if (!request.completer.isCompleted) {
          request.completer.complete(cachedTile);
        }

        _pendingTiles.remove(request.url);
        continue;
      }

      if (request.completer.isCompleted) {
        _pendingTiles.remove(request.url);
        continue;
      }

      _executeFetch(
        request.url,
        request.x,
        request.y,
        request.zoom,
        request.completer,
      );
    }
  }

  Future<Tile> _fetchWithRetry(
    String url,
    int x,
    int y,
    int zoom,
  ) async {
    int attempt = 0;

    while (attempt < _maxRetries) {
      attempt++;

      try {
        final stopwatch = Stopwatch()..start();

        final response = await _httpClient.get(
          Uri.parse(url),
          headers: {
            'User-Agent': 'FlutterApp',
            'Accept': 'image/webp,image/png,image/*',
          },
        ).timeout(_requestTimeout);

        stopwatch.stop();
        debugPrint(
          "Tile [$zoom/$x/$y] "
              "${stopwatch.elapsedMilliseconds}ms "
              "Status=${response.statusCode} "
              "Size=${response.bodyBytes.length ~/ 1024}KB",
        );
        debugPrint(
          "Headers => ${response.headers['content-type']}",
        );
        if (response.statusCode == 200 &&
            response.bodyBytes.isNotEmpty) {
          final tile = Tile(
            256,
            256,
            response.bodyBytes,
          );

          _addToCache(url, tile);

          return tile;
        }
      } on TimeoutException {
        if (attempt < _maxRetries) {
          await Future.delayed(
            Duration(milliseconds: 300 * attempt),
          );
        }
      } catch (e) {
        debugPrint(
          "Tile error [$zoom/$x/$y] => $e",
        );

        if (attempt < _maxRetries) {
          await Future.delayed(
            Duration(milliseconds: 300 * attempt),
          );
        }
      }
    }

    return _emptyTile();
  }

  void _addToCache(String url, Tile tile) {
    _tileCache[url] = tile;

    if (_tileCache.length > 20000) {
      _tileCache.remove(_tileCache.keys.first);
    }
  }
  Tile _emptyTile() {
    return Tile(256, 256, Uint8List(0));
  }

  bool _isImage(Uint8List bytes) {
    if (bytes.length < 4) return false;

    // PNG
    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) return true;

    // JPEG
    if (bytes[0] == 0xFF && bytes[1] == 0xD8) return true;

    // WebP
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

  static void clearCache() {
    for (final completer in _pendingTiles.values) {
      if (!completer.isCompleted) {
        completer.complete(Tile(256, 256, Uint8List(0)));
      }
    }
    _waitingQueue.clear();
    _tileCache.clear();
    _pendingTiles.clear();
    _activeRequests = 0;
    debugPrint("Tile cache cleared");
  }

  static void clearOldCache({int maxItems = 3000}) {
    if (_tileCache.length > maxItems) {
      final keys = _tileCache.keys.toList();
      for (int i = 0; i < keys.length - maxItems; i++) {
        _tileCache.remove(keys[i]);
      }
    }
  }

  static Map<String, dynamic> getCacheStats() {
    return {
      'cachedTiles': _tileCache.length,
      'pendingTiles': _pendingTiles.length,
      'activeRequests': _activeRequests,
      'queuedTiles': _waitingQueue.length,
    };
  }
}

// Helper class to hold queued tile requests
class _TileRequest {
  final String url;
  final int x;
  final int y;
  final int zoom;
  final Completer<Tile> completer;

  _TileRequest({
    required this.url,
    required this.x,
    required this.y,
    required this.zoom,
    required this.completer,
  });
}
