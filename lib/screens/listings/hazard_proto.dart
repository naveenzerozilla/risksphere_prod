import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:RiskSphare/design_system/primitives/custom_typography.dart';

class CustomTileProviderGEM implements TileProvider {
  final String baseUrl;
  final int minZoom;
  final int maxZoom;

  CustomTileProviderGEM({
    required this.baseUrl,
    this.minZoom = 2,
    this.maxZoom = 18,
  });

  @override
  Future<Tile> getTile(int x, int y, int? zoom) async {
    if (zoom == null || zoom < minZoom || zoom > maxZoom) {
      return Tile(256, 256, Uint8List(0));
    }

    final tileUrl = '$baseUrl/$zoom/$x/$y';
    print("Fetching tile for GEM: $tileUrl");

    try {
      final ByteData data = await NetworkAssetBundle(Uri.parse(tileUrl)).load(tileUrl);
      final Uint8List tileData = data.buffer.asUint8List();

      return Tile(256, 256, tileData);
    } catch (e) {
      print("Error fetching tile for GEM: $e");
      return Tile(256, 256, Uint8List(0));
    }
  }
}

class CustomTileProviderUSGSNRI implements TileProvider {
  final String baseUrl;
  final int minZoom;
  final int maxZoom;

  CustomTileProviderUSGSNRI({
    required this.baseUrl,
    this.minZoom = 2,
    this.maxZoom = 18,
  });

  @override
  Future<Tile> getTile(int x, int y, int? zoom) async {
    if (zoom == null || zoom < minZoom || zoom > maxZoom) {
      return Tile(256, 256, Uint8List(0));
    }

    final tileUrl = '$baseUrl/$zoom/$x/$y';
    print("Fetching tile for USGSNRI: $tileUrl");

    try {
      final ByteData data = await NetworkAssetBundle(Uri.parse(tileUrl)).load(tileUrl);
      final Uint8List tileData = data.buffer.asUint8List();

      return Tile(256, 256, tileData);
    } catch (e) {
      print("Error fetching tile for USGSNRI: $e");
      return Tile(256, 256, Uint8List(0));
    }
  }
}


class CustomTileProvider2 implements TileProvider {
  final String baseUrl;
  final int minZoom;
  final int maxZoom;

  CustomTileProvider2({
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
      return 'https://earthengine.googleapis.com/v1/projects/earthengine-legacy/maps/fd02f0f78244ab1a3bd9557f34995273-6eaad99ab488fc1887dc2e90bc904d2b/tiles';
    } else if (zoom == 2 || zoom == 3) {
      return 'https://earthengine.googleapis.com/v1/projects/earthengine-legacy/maps/8256eba945091a035ec25de3817eb65d-e3fbdb67e4a3bb352659bdedd447679e/tiles';
    } else if (zoom == 4 || zoom == 5) {
      return 'https://earthengine.googleapis.com/v1/projects/earthengine-legacy/maps/b9f3e7fee5a95028909a301795d4675e-86e6bf8fe2eb5deda016d99a4f0e8393/tiles';
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
      return 'https://earthengine.googleapis.com/v1/projects/project-green-f4d78/maps/6739e0e121b28173827c6ef2d35bd576-2ddd2eef8896d54a43d7790650e3f528/tiles';
    } else if (zoom == 2 || zoom == 3) {
      return 'https://earthengine.googleapis.com/v1/projects/project-green-f4d78/maps/6739e0e121b28173827c6ef2d35bd576-ee10811f31987ee93d20ea455c3a1ba3/tiles';
    } else if (zoom == 4 || zoom == 5) {
      return 'https://earthengine.googleapis.com/v1/projects/project-green-f4d78/maps/6739e0e121b28173827c6ef2d35bd576-bf6ba5eca5da355493707f3de90ffc4f/tiles';
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
  late CustomTileProvider2 _stormTileProvider;
  late CustomTileProvider _earthquakeTileProvider;
  late CustomTileProviderUSGSNRI _usgsnriTileProvider;
  late CustomTileProviderGEM _gemTileProvider;

  late CustomTileProvider _floodTileProvider;
  late GoogleMapController _mapController;
  bool _isInitialized = false;

  final Set<Marker> _markers = {};
  Set<Polygon> _polygons = {};

  // Toggle states
  bool _showGeoJson = false;
  bool _showCustomTileProvider1 = false;
  bool _showCustomTileProvider2 = false;
  bool _showLocationPins = false;
  bool _showUSGSNRI = false;
  bool _showGEM = false;

  final String _mapStyle = '''
     [
    {
      "elementType": "geometry",
      "stylers": [
        { "color": "#f5f5f5" }
      ]
    },
    {
      "elementType": "labels.icon",
      "stylers": [
        { "visibility": "off" }
      ]
    },
    {
      "elementType": "labels.text.fill",
      "stylers": [
        { "color": "#616161" }
      ]
    },
    {
      "elementType": "labels.text.stroke",
      "stylers": [
        { "color": "#f5f5f5" }
      ]
    },
    {
      "featureType": "administrative",
      "elementType": "geometry.stroke",
      "stylers": [
        { "visibility": "on" },
        { "color": "#a0a0a0" }, 
        { "weight": 1 }
      ]
    },
    {
      "featureType": "administrative.province",
      "elementType": "geometry.stroke",
      "stylers": [
        { "visibility": "on" },
        { "color": "#808080" }, 
        { "weight": 1.5 }
      ]
    },
    {
      "featureType": "administrative.land_parcel",
      "elementType": "labels.text.fill",
      "stylers": [
        { "color": "#bdbdbd" }
      ]
    },
    {
      "featureType": "poi",
      "elementType": "geometry",
      "stylers": [
        { "color": "#eeeeee" }
      ]
    },
    {
      "featureType": "poi",
      "elementType": "labels.text.fill",
      "stylers": [
        { "color": "#757575" }
      ]
    },
    {
      "featureType": "road",
      "elementType": "geometry",
      "stylers": [
        { "color": "#ffffff" }
      ]
    },
    {
      "featureType": "road.arterial",
      "elementType": "labels.text.fill",
      "stylers": [
        { "color": "#757575" }
      ]
    },
    {
      "featureType": "road.highway",
      "elementType": "geometry",
      "stylers": [
        { "color": "#dadada" }
      ]
    },
    {
      "featureType": "road.highway",
      "elementType": "labels.text.fill",
      "stylers": [
        { "color": "#616161" }
      ]
    },
    {
      "featureType": "road.local",
      "elementType": "labels.text.fill",
      "stylers": [
        { "color": "#9e9e9e" }
      ]
    },
    {
      "featureType": "transit.line",
      "elementType": "geometry",
      "stylers": [
        { "color": "#e5e5e5" }
      ]
    },
    {
      "featureType": "transit.station",
      "elementType": "geometry",
      "stylers": [
        { "color": "#eeeeee" }
      ]
    },
    {
      "featureType": "water",
      "elementType": "geometry",
      "stylers": [
        { "color": "#c9c9c9" }
      ]
    },
    {
      "featureType": "water",
      "elementType": "labels.text.fill",
      "stylers": [
        { "color": "#9e9e9e" }
      ]
    }
  ]
  
    ''';

  @override
  void initState() {
    super.initState();
    _initializeTileProviders();
    _loadGeoJson();
  }

  Future<void> _initializeTileProviders() async {
    _stormTileProvider = CustomTileProvider2(baseUrl: 'https://tileserver/storm');
    _earthquakeTileProvider = CustomTileProvider(baseUrl: 'https://tileserver/earthquake');
   // _floodTileProvider = CustomTileProvider(baseUrl: 'https://tileserver/flood');
    _usgsnriTileProvider = CustomTileProviderUSGSNRI(
      baseUrl: 'https://earthengine.googleapis.com/v1/projects/project-green-f4d78/maps/b1d1d590b181c3893b359b46222d8442-c94c714877340fd40ea6284ff40129ad/tiles',
    );
    _gemTileProvider = CustomTileProviderGEM(
      baseUrl: 'https://earthengine.googleapis.com/v1/projects/project-green-f4d78/maps/8f65477fb915b8b9b2fe15455d0775bf-d17e6d854f115531751aad4adbb644ae/tiles',
    );

    setState(() {
      _isInitialized = true;
    });
  }

  void _loadGeoJson() async {
    try {
      // Load the GeoJSON file from assets
      final String geoJsonData =
      await rootBundle.loadString('assets/proto/MMflood_geojson.geojson');
      final Map<String, dynamic> geoJson = json.decode(geoJsonData);

      final List<Polygon> newPolygons = [];

      // Loop through each feature in the GeoJSON
      for (var feature in geoJson['features']) {
        final geometry = feature['geometry'];
        final properties = feature['properties'] ?? {};

        if (geometry == null || geometry['type'] == null) {
          print("Invalid GeoJSON: Missing geometry type");
          continue;
        }

        final String geometryType = geometry['type'];
        if (geometryType == 'Polygon') {
          final List<dynamic> coordinates = geometry['coordinates'];
          if (coordinates.isNotEmpty) {
            final List<LatLng> polygonCoords = coordinates[0]
                .map<LatLng>((coord) => LatLng(coord[1] as double, coord[0] as double))
                .toList();

            final polygon = Polygon(
              polygonId: PolygonId(properties['id'] ?? 'polygon_${newPolygons.length}'),
              points: polygonCoords,
              strokeWidth: 2,
              fillColor: Colors.blue.withOpacity(0.5),
              strokeColor: Colors.blue,
            );

            newPolygons.add(polygon);
          }
        } else if (geometryType == 'MultiPolygon') {
          final List<dynamic> multiCoordinates = geometry['coordinates'];
          for (var polygonCoordsList in multiCoordinates) {
            if (polygonCoordsList.isNotEmpty) {
              final List<LatLng> polygonCoords = polygonCoordsList[0]
                  .map<LatLng>((coord) => LatLng(coord[1] as double, coord[0] as double))
                  .toList();

              final polygon = Polygon(
                polygonId: PolygonId(properties['id'] ?? 'polygon_${newPolygons.length}'),
                points: polygonCoords,
                strokeWidth: 2,
                fillColor: Colors.blue.withOpacity(0.5),
                strokeColor: Colors.blue,
              );

              newPolygons.add(polygon);
            }
          }
        } else {
          print("Unsupported geometry type: $geometryType");
        }
      }

      // Update state with the new polygons
      setState(() {
        _polygons = newPolygons.toSet();
      });
    } catch (e) {
      print("Error loading GeoJSON: $e");
    }
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
          Expanded(
            child: GoogleMap(
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
              },
              style: _mapStyle,
              markers: _showLocationPins ? _markers : {},
              polygons: _showGeoJson ? _polygons : {},
              initialCameraPosition: CameraPosition(
                target: LatLng(40.240471670725135, -98.61664688427093),
                zoom: 0,
              ),
              tileOverlays: {
                if (_showCustomTileProvider1)
                  TileOverlay(
                    tileOverlayId: TileOverlayId('storm_tiles'),
                    tileProvider: _stormTileProvider,
                  ),
                if (_showCustomTileProvider2)
                  TileOverlay(
                    tileOverlayId: TileOverlayId('earthquake_tiles'),
                    tileProvider: _earthquakeTileProvider,
                  ),
                if (_showUSGSNRI)
                  TileOverlay(
                    tileOverlayId: TileOverlayId('usgsnri_tiles'),
                    tileProvider: _usgsnriTileProvider,
                  ),
                if (_showGEM)
                  TileOverlay(
                    tileOverlayId: TileOverlayId('gem_tiles'),
                    tileProvider: _gemTileProvider,
                  ),
              },
            ),
          ),
          Column(
            children: [
              SwitchListTile(
                title: Text('Show GEM (Earthquake)', style: CustomTypography(context).Body1,),
                value: _showGEM,
                onChanged: (value) {
                  setState(() {
                    _showGEM = value;
                  });
                },
              ),
              SwitchListTile(
                title: Text('Show USG Avalanche', style: CustomTypography(context).Body1),
                value: _showUSGSNRI,
                onChanged: (value) {
                  setState(() {
                    _showUSGSNRI = value;
                  });
                },
              ),
              SwitchListTile(
                title: Text('Show MM Flood GeoJSON', style: CustomTypography(context).Body1),
                value: _showGeoJson,
                onChanged: (value) {
                  setState(() {
                    _showGeoJson = value;
                  });
                },
              ),
              SwitchListTile(
                title: Text('Show Heatmap', style: CustomTypography(context).Body1),
                value: _showCustomTileProvider1,
                onChanged: (value) {
                  setState(() {
                    _showCustomTileProvider1 = value;
                  });
                },
              ),
              SwitchListTile(
                title: Text('Show JRC OD', style: CustomTypography(context).Body1),
                value: _showCustomTileProvider2,
                onChanged: (value) {
                  setState(() {
                    _showCustomTileProvider2 = value;
                  });
                },
              ),
              SwitchListTile(
                title: Text('Show Location Pins', style: CustomTypography(context).Body1),
                value: _showLocationPins,
                onChanged: (value) {
                  setState(() {
                    _showLocationPins = value;
                    if (_showLocationPins) {
                      _addRandomMarkers(); // Add markers when enabled
                    } else {
                      _clearMarkers(); // Clear markers when disabled
                    }
                  });
                },
              ),

            ],
          ),
        ],
      ),
    );
  }

  void _addRandomMarkers() {
    final random = Random();
    final List<Marker> newMarkers = List.generate(20, (index) {
      final lat = 40.0 + random.nextDouble() * 20.0 - 10.0;
      final lng = -100.0 + random.nextDouble() * 20.0 - 10.0;
      return Marker(
        markerId: MarkerId('marker_$index'),
        position: LatLng(lat, lng),
        infoWindow: InfoWindow(title: 'Marker $index'),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueRed,
        ),
      );
    });

    setState(() {
      _markers.addAll(newMarkers);
    });
  }

  void _clearMarkers() {
    setState(() {
      _markers.clear();
    });
  }

}

