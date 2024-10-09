import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CustomTileProvider implements TileProvider {
  final String baseUrl;
  final int minZoom;
  final int maxZoom;

  CustomTileProvider({
    required this.baseUrl,
    this.minZoom = 2,
    this.maxZoom = 18,
  });

  Future<void> clearCaches() async {
    // Caching functionality removed
    print("Caching functionality removed.");
  }

  String getBaseUrlForZoom(int zoom) {
    // Map different base URLs for different zoom levels
    if (zoom == 0 || zoom == 1) {
      return 'https://earthengine.googleapis.com/v1/projects/project-green-f4d78/maps/795fb64400fca37af694979bee2dcc4e-872811c818c954026d5557ffce7a3376/tiles';
    } else if (zoom == 2 || zoom == 3) {
      return 'https://earthengine.googleapis.com/v1/projects/project-green-f4d78/maps/242bd0c1c0c0b58f1371e04ec2a2ae70-87d1fea1f36bed006098206927add34b/tiles';
    } else if (zoom == 4 || zoom == 5) {
      return 'https://earthengine.googleapis.com/v1/projects/project-green-f4d78/maps/7d855038521dac742cfabcf477236f68-b2b7d2276c26e59c88efcbc338fe0bae/tiles';
    }
    // Default to the provided baseUrl for other zoom levels
    return baseUrl;
  }

  @override
  Future<Tile> getTile(int x, int y, int? zoom) async {
    if (zoom == null || zoom < minZoom || zoom > maxZoom) {
      return Tile(256, 256, Uint8List(0));
    }

    // Get the appropriate base URL for the current zoom level
    final tileUrl = '${getBaseUrlForZoom(zoom)}/$zoom/$x/$y';
    print("Fetching tile from network: $tileUrl");

    try {
      final ByteData data = await NetworkAssetBundle(Uri.parse(tileUrl)).load(tileUrl);
      final Uint8List tileData = data.buffer.asUint8List();

      return Tile(256, 256, tileData);
    } catch (e) {
      print("Error fetching tile: $e");
      return Tile(256, 256, Uint8List(0));
    }
  }
}

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  String _selectedLayer = 'earthquake';
  late CustomTileProvider _stormTileProvider;
  late CustomTileProvider _earthquakeTileProvider;
  late CustomTileProvider _floodTileProvider;
  late GoogleMapController _mapController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeTileProviders();
  }

  Future<void> _initializeTileProviders() async {
    _stormTileProvider = CustomTileProvider(baseUrl: 'https://tileserver/storm');
    _earthquakeTileProvider = CustomTileProvider(baseUrl: 'https://earthengine.googleapis.com/v1/projects/project-green-f4d78/maps/1ba088c3935534e0a69493984c6ffcdb-5513c78cc6ebc7fc38d85afbf1a1490d/tiles');
    _floodTileProvider = CustomTileProvider(baseUrl: 'https://tileserver/flood');

    setState(() {
      _isInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Hazard Risk Impact'),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _selectedLayer = 'storm';
                  });
                },
                child: Text('Storm'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _selectedLayer = 'earthquake';
                  });
                },
                child: Text('Earthquake'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _selectedLayer = 'flood';
                  });
                },
                child: Text('Flood'),
              ),
            ],
          ),
          Expanded(
            child: GoogleMap(
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
              },
              initialCameraPosition: CameraPosition(
                target: LatLng(40.240471670725135, -98.61664688427093),
                zoom: 0,
              ),
              tileOverlays: {
                if (_selectedLayer == 'storm')
                  TileOverlay(
                    tileOverlayId: TileOverlayId('storm_tiles'),
                    tileProvider: _stormTileProvider,
                  ),
                if (_selectedLayer == 'earthquake')
                  TileOverlay(
                    tileOverlayId: TileOverlayId('earthquake_tiles'),
                    tileProvider: _earthquakeTileProvider,
                  ),
                if (_selectedLayer == 'flood')
                  TileOverlay(
                    tileOverlayId: TileOverlayId('flood_tiles'),
                    tileProvider: _floodTileProvider,
                  ),
              },
            ),
          ),
        ],
      ),
    );
  }
}
