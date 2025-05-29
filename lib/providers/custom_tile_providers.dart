import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
      final ByteData data = await NetworkAssetBundle(Uri.parse(tileUrl)).load(tileUrl);
      final Uint8List tileData = data.buffer.asUint8List();
      return Tile(256, 256, tileData);
    } catch (e) {
      print("Error fetching tile: $e");
      return Tile(256, 256, Uint8List(0)); // Return an empty tile on error
    }
  }


}
