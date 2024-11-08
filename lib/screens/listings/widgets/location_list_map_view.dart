import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:green/design_system/primitives/custom_typography.dart';
import 'package:provider/provider.dart';
import '../../../design_system/primitives/app_colors.dart';
import '../../../models/my_location_list_model.dart';
import 'package:green/providers/my_location_list_provider.dart';

import '../../../providers/custom_tile_providers.dart';
import 'location_details_popup.dart';
import 'package:google_maps_cluster_manager_2/google_maps_cluster_manager_2.dart' as cluster_manager;

class LocationListMapView extends StatefulWidget {
  final String accountId;
  final String subAccountId;
  final String? sovId;

  LocationListMapView(
      {required this.accountId, required this.subAccountId, this.sovId = ""});

  @override
  _LocationListMapViewState createState() => _LocationListMapViewState();
}

class _LocationListMapViewState extends State<LocationListMapView>
    with SingleTickerProviderStateMixin {
  late GoogleMapController mapController;
  late cluster_manager.ClusterManager<MyLocation> clusterManager;
  Set<Marker> _markers = {};
  Set<ClusterManager> _clusterManagers = {};
  bool _showPins = true;
  int? _selectedScore; // null means all scores are shown
  Map<String, CustomTileProvider> _tileProviders = {};
  bool _isInitialized = false;
  String? _selectedHazard;
  bool _isHeatmapOn = false;
  List<String> _reducers = [];
  String? _selectedReducer;
  int _selectedTabIndex = 0;


  @override
  void initState() {
    super.initState();
    //_loadMarkers();
    _tabController = TabController(length: 4, vsync: this);
    _tabController!.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController!.index;
      });
    });
    _initializeClusterManager();
    _fetchHazardLayers();
  }

  void _initializeClusterManager() {
    final allLocations =
        Provider.of<MyLocationListProvider>(context, listen: false).fullLocationList;

    clusterManager = cluster_manager.ClusterManager<MyLocation>(
      allLocations,
      _updateMarkers,
      markerBuilder: _markerBuilder,
      levels: [1, 4.25, 6.75], // Optional zoom levels
      extraPercent: 0.2, // Optional padding to prevent clusters from popping in/out
      stopClusteringZoom: 5.0,
    );
  }

  Future<Marker> _markerBuilder(cluster_manager.Cluster<MyLocation> cluster) async {
    if (cluster.isMultiple) {
      Color clusterColor = _determineClusterColor(cluster.items.toList());
      return Marker(
        markerId: MarkerId(cluster.getId()),
        position: cluster.location,
        icon: await _getClusterBitmap(125, text: cluster.count.toString(), color: clusterColor),
        onTap: () {
          print(cluster.items); // You can access clustered items here
        },
      );
    } else {
      MyLocation location = cluster.items.first;
      final score = location.finalAddress?.score;

      // Adjust marker color based on score using _getMarkerHue
      return Marker(
        markerId: MarkerId(location.id ?? ''),
        position: location.location,
        icon: BitmapDescriptor.defaultMarkerWithHue(_getMarkerHue(score ?? 0)),
        visible: _showPins && (_selectedScore == null || _selectedScore == score),
        onTap: () {
          showLocationDetailsPopup(context, location);
        },
      );
    }
  }

  Color _determineClusterColor(List<MyLocation> items) {
    // Count occurrences of each color based on score
    Map<int, int> colorCounts = {};

    for (var item in items) {
      int score = item.finalAddress?.score ?? 0;
      colorCounts[score] = (colorCounts[score] ?? 0) + 1;
    }

    // Find the most common color
    int dominantScore = colorCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    return _getColorFromScore(dominantScore);
  }
  Color _getColorFromScore(int score) {
    switch (score) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.yellow;
      case 4:
        return Colors.green;
      case 5:
        return Colors.blue;
      default:
        return Colors.grey; // Default color
    }
  }



  Future<BitmapDescriptor> _getClusterBitmap(int size, {String? text, Color color = Colors.red}) async {
    final PictureRecorder pictureRecorder = PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..color = color; // Use passed color here

    canvas.drawCircle(Offset(size / 2, size / 2), size / 2.0, paint);

    if (text != null) {
      TextPainter painter = TextPainter(textDirection: TextDirection.ltr);
      painter.text = TextSpan(
        text: text,
        style: TextStyle(fontSize: size / 3, color: Colors.white),
      );
      painter.layout();
      painter.paint(
        canvas,
        Offset(size / 2 - painter.width / 2, size / 2 - painter.height / 2),
      );
    }
    final img = await pictureRecorder.endRecording().toImage(size, size);
    final data = await img.toByteData(format: ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }


  void _updateMarkers(Set<Marker> markers) {
    setState(() {
      _markers = markers;
    });
  }
  Future<void> _fetchHazardLayers() async {
    try {
      var provider =
          Provider.of<MyLocationListProvider>(context, listen: false);


      if (_selectedTabIndex == 0 && provider.geocodingData == null) {
        // Only fetch if data is null
        await provider.generateHeatMapForLocationsGeocoding(
            context, widget.accountId, widget.subAccountId, true, false, widget.sovId);

        Map<String, dynamic>? data = provider.geocodingData; // Assuming response is JSON
        print("Fetched data: $data"); // Debugging output to check structure
        final geocoding = data?['GeocodeScore'];
        if (geocoding == null) {
          print("Error: 'GeocodeScore' data is missing in the response.");
          return; // Exit if 'GeocodeScore' data is missing
        }

        // Extract reducers dynamically
        if (geocoding.isNotEmpty) {
          _reducers = geocoding.entries.first.value.keys.toList();
          _selectedReducer =
          _reducers.contains("mean") ? "mean" : _reducers.first;
        }

        /*{
    "GeocodeScore": {
        "count": {
            "0": "
https://earthengine.googleapis.com/v1/projects/earthengine-legacy/maps/568c588b0f03c2d97be3fed51b849875-940168d07b64447fdd7d11eab8fc21af/tiles"
,
            "1": "
https://earthengine.googleapis.com/v1/projects/earthengine-legacy/maps/568c588b0f03c2d97be3fed51b849875-ef3cf21bcb608bea3bdd8dd62c6f5672/tiles"
,
            "2": "
https://earthengine.googleapis.com/v1/projects/earthengine-legacy/maps/ffd33362fb509773770650a3df72cc6e-39612cfbc6300890bfb2f5951fa7abad/tiles"
,
            "3": "
https://earthengine.googleapis.com/v1/projects/earthengine-legacy/maps/ffd33362fb509773770650a3df72cc6e-0a888bae49fb826a8153a39067a1a7a5/tiles"
,
            "4": "
https://earthengine.googleapis.com/v1/projects/earthengine-legacy/maps/8d9d26bd31d58e91ad0bec2541890851-0065f78d0226f0a873f929d873e9fb09/tiles"
,
            "5": "
https://earthengine.googleapis.com/v1/projects/earthengine-legacy/maps/8d9d26bd31d58e91ad0bec2541890851-f92a63c04cc6ac6853c2ffccfe153427/tiles"
        },
        "mean": {
            "0": "
https://earthengine.googleapis.com/v1/projects/earthengine-legacy/maps/058cf18215aa2895d2fde8eadfb3fb2e-c649f2e284d0ce37f7dd029635763050/tiles"
,
            "1": "
https://earthengine.googleapis.com/v1/projects/earthengine-legacy/maps/058cf18215aa2895d2fde8eadfb3fb2e-c16ae2c5588b2eba6eae8937010ef0a0/tiles"
,
            "2": "
https://earthengine.googleapis.com/v1/projects/earthengine-legacy/maps/876e3eeb85897a2a11e85f49d06d73a2-78dd6a787eea5794ac479fdfd1476db8/tiles"
,
            "3": "
https://earthengine.googleapis.com/v1/projects/earthengine-legacy/maps/876e3eeb85897a2a11e85f49d06d73a2-81a6abbae614dd6c5384aa3bad6c2197/tiles"
,
            "4": "
https://earthengine.googleapis.com/v1/projects/earthengine-legacy/maps/0467cceae28cd583d7adfeeed338b759-e2df24716187e2c07164f13c84021048/tiles"
,
            "5": "
https://earthengine.googleapis.com/v1/projects/earthengine-legacy/maps/0467cceae28cd583d7adfeeed338b759-95ec575aa0e87688a8a3e702e6410cea/tiles"
        },
        "max": {
            "0": "
https://earthengine.googleapis.com/v1/projects/earthengine-legacy/maps/8a7e426bd6e636cc1498156069e5115a-cbc658adee9654774939aaa058b57254/tiles"
,
            "1": "
https://earthengine.googleapis.com/v1/projects/earthengine-legacy/maps/8a7e426bd6e636cc1498156069e5115a-42d37c2c538c5784ef91df6e18f0a997/tiles"
,
            "2": "
https://earthengine.googleapis.com/v1/projects/earthengine-legacy/maps/b0dcc9c07cfd6b1b3919760e242f0e25-9e738c8c48bdb17b24c1985b91911952/tiles"
,
            "3": "
https://earthengine.googleapis.com/v1/projects/earthengine-legacy/maps/b0dcc9c07cfd6b1b3919760e242f0e25-2bead94db1eb1c60c9644446d2af59b6/tiles"
,
            "4": "
https://earthengine.googleapis.com/v1/projects/earthengine-legacy/maps/ea95deed63a7969e44b5ef546ba8ebdc-5ffe3079cee284bbab85e583e508af58/tiles"
,
            "5": "
https://earthengine.googleapis.com/v1/projects/earthengine-legacy/maps/ea95deed63a7969e44b5ef546ba8ebdc-445d97a7e514657e7c6549082f53f0a4/tiles"
        },
        "min": {
            "0": "
https://earthengine.googleapis.com/v1/projects/earthengine-legacy/maps/9167341690c1098f2b897252af92bb65-f709589fbb776f2ee497e228716e673e/tiles"
,
            "1": "
https://earthengine.googleapis.com/v1/projects/earthengine-legacy/maps/9167341690c1098f2b897252af92bb65-4a9d0907e8e72c546fa2408d078ec6a9/tiles"
,
            "2": "
https://earthengine.googleapis.com/v1/projects/earthengine-legacy/maps/f262e67538fc1a206c8f7a0e91bd620f-53f7241c21790dfdb05c90b9e8979424/tiles"
,
            "3": "
https://earthengine.googleapis.com/v1/projects/earthengine-legacy/maps/f262e67538fc1a206c8f7a0e91bd620f-f0e46bf37129d0e8a07bb4ec6e876d00/tiles"
,
            "4": "
https://earthengine.googleapis.com/v1/projects/earthengine-legacy/maps/9e63627d751ab055d8638c17f0c29d8e-f2eaddfd5022c4f822ba2661fb283909/tiles"
,
            "5": "
https://earthengine.googleapis.com/v1/projects/earthengine-legacy/maps/9e63627d751ab055d8638c17f0c29d8e-5b935fa6a3154d5b2d72deecb9fc585c/tiles"
        }
    }
}*/

        // Extract reducers for geocoding
        if (geocoding.isNotEmpty) {
          _reducers = geocoding.entries.first.value.keys.toList();
          _selectedReducer = _reducers.contains("mean") ? "mean" : _reducers.first;
        }

        Map<String, Map<int, String>> geocodingTiles = {};
        geocoding.forEach((reducer, zoomUrls) {
          Map<int, String> tiles = {};
          zoomUrls.forEach((zoom, url) {
            tiles[int.parse(zoom)] = url;
          });
          geocodingTiles[reducer] = tiles;
        });

        _tileProviders["Geocoding"] = CustomTileProvider(
          tileUrls: {"Geocoding": geocodingTiles},
          hazardType: "Geocoding",
          currentReducer: _selectedReducer ?? "mean",
        );

        setState(() {
          _isInitialized = true;
          _selectedHazard = "Geocoding";
        });


      } else if (_selectedTabIndex == 1 && provider.hazardData == null) {
        // Only fetch if data is null
        await provider.generateHeatMapForLocationsGeocoding(
            context, widget.accountId, widget.subAccountId, false, false, widget.sovId);
        Map<String, dynamic>? data = provider.hazardData; // Assuming response is JSON
        print("Fetched data: $data"); // Debugging output to check structure

        // Access the 'heatmap' key and check if it's null
        final hazards = data?['heatmap'];
        if (hazards == null) {
          print("Error: 'heatmap' data is missing in the response.");
          return; // Exit if 'heatmap' data is missing
        }

        // Extract reducers dynamically
        if (hazards.isNotEmpty) {
          _reducers = hazards.entries.first.value.keys.toList();
          _selectedReducer =
          _reducers.contains("mean") ? "mean" : _reducers.first;
        }

        hazards.forEach((hazard, urls) {
          Map<String, Map<int, String>> intensityMap = {};

          urls.forEach((intensity, zoomUrls) {
            Map<int, String> zoomLevelUrls = {};
            zoomUrls.forEach((zoom, url) {
              zoomLevelUrls[int.parse(zoom)] = url;
            });
            intensityMap[intensity] = zoomLevelUrls;
          });

          // Pass the selected reducer as the initial reducer for each CustomTileProvider
          _tileProviders[hazard] = CustomTileProvider(
            tileUrls: {hazard: intensityMap},
            hazardType: hazard,
            currentReducer: _selectedReducer ??
                "mean", // Default to "mean" if _selectedReducer is null
          );
        });

        setState(() {
          _isInitialized = true;
          _selectedHazard = _tileProviders.keys.first; // Set default hazard
        });

        // Debugging outputs to verify hazards and tile providers
        print("Selected hazard: $_selectedHazard");
        print("Available tile providers: ${_tileProviders.keys}");
      } else {
        print("Data already fetched for the selected tab.");
      }


    } catch (e) {
      print("Error in _fetchHazardLayers: $e");
    }
  }

  void _toggleHeatmap() {
    setState(() {
      _isHeatmapOn = !_isHeatmapOn;
      if (!_isHeatmapOn) {
        // Clear tile overlays by setting _selectedHazard to null
        _selectedHazard = null;
      } else {
        // If heatmap is turned back on and data is initialized, restore the selected hazard and reducer
        if (_isInitialized) {
          _selectedHazard = _selectedHazard ?? _tileProviders.keys.first;
          _tileProviders[_selectedHazard]
              ?.updateReducer(_selectedReducer ?? "mean");
        } else {
          // Fetch hazard layers if they are not initialized yet
          _fetchHazardLayers();
        }
      }
    });
  }

  void _onReducerChanged(String? newReducer) {
    setState(() {
      _selectedReducer = newReducer;
      if (_selectedHazard != null && newReducer != null) {
        // Update the tile provider with the selected reducer
        _tileProviders[_selectedHazard]?.updateReducer(newReducer);

        // Temporarily clear tile overlays to trigger refresh
        _selectedHazard = "";
      }
    });

    // Reapply the selected hazard with a delay to ensure the refresh
    Future.delayed(Duration(milliseconds: 50), () {
      setState(() {
        _selectedHazard = _tileProviders.keys.firstWhere(
            (key) => key.isNotEmpty && key == _selectedHazard,
            orElse: () => _tileProviders.keys.first);
      });
    });
  }

  void _changeHazardLayer(String hazard) {
    setState(() => _selectedHazard = hazard);
  }

  Future<void> _loadMarkers() async {
    Set<Marker> markers = {};
    final allLocations =
        Provider.of<MyLocationListProvider>(context, listen: false)
            .fullLocationList;


    for (var location in allLocations) {
      final score = location.finalAddress?.score;
      final marker = Marker(
        markerId: MarkerId(location.id ?? ''),
        position: LatLng(location.finalAddress?.latitude ?? 0,
            location.finalAddress?.longitude ?? 0),
        icon: BitmapDescriptor.defaultMarkerWithHue(_getMarkerHue(score ?? 0)),
        visible:
            _showPins && (_selectedScore == null || _selectedScore == score),
        onTap: () {
          showLocationDetailsPopup(context, location);
        },
      );
      markers.add(marker);
    }


    setState(() {
      _markers = markers;
    });
  }



  double _getMarkerHue(int score) {
    switch (score) {
      case 1:
        return BitmapDescriptor.hueRed;
      case 2:
        return BitmapDescriptor.hueOrange;
      case 3:
        return BitmapDescriptor.hueYellow;
      case 4:
        return BitmapDescriptor.hueGreen;
      case 5:
        return BitmapDescriptor.hueBlue;
      default:
        return BitmapDescriptor.hueCyan;
    }
  }

  void _handleClusterTap(dynamic cluster) async {
    // Await the zoom level and add 2
    double currentZoom = await mapController.getZoomLevel();
    mapController.animateCamera(
      CameraUpdate.newLatLngZoom(
        cluster.position,
        currentZoom + 2,
      ),
    );
  }


  void _togglePinVisibility() {
    setState(() {
      _showPins = !_showPins;
    });

    // Refresh items in the cluster manager to apply visibility filter
    clusterManager.setItems(
      Provider.of<MyLocationListProvider>(context, listen: false)
          .fullLocationList
          .where((location) =>
      _showPins || location.finalAddress?.score == _selectedScore)
          .toList(),
    );
  }


  void _toggleScoreFilter(int score) {
    setState(() {
      if (_selectedScore == score) {
        _selectedScore = null; // Show all scores if tapped on selected score again
      } else {
        _selectedScore = score;
      }
    });

    // Filter locations based on selected score and update ClusterManager
    clusterManager.setItems(
      Provider.of<MyLocationListProvider>(context, listen: false)
          .fullLocationList
          .where((location) =>
      _selectedScore == null || location.finalAddress?.score == _selectedScore)
          .toList(),
    );
  }


  ScrollController _scrollController = ScrollController();
  TabController? _tabController;

  void _scrollLeft() {
    _scrollController.animateTo(
      _scrollController.offset - 100, // Scroll left by 100 pixels
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _scrollRight() {
    _scrollController.animateTo(
      _scrollController.offset + 100, // Scroll right by 100 pixels
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    var typography = CustomTypography(context);
    return Column(
      children: [
        // Container for the TabBar with arrows
        Container(
          margin: EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
          ),
          height: 50,
          child: Row(
            children: <Widget>[
              // Left arrow button
              IconButton(
                icon: Icon(Icons.arrow_left, color: Colors.grey),
                onPressed: _scrollLeft,
              ),
              // Scrollable TabBar
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  child: TabBar(
                    controller: _tabController,
                    tabAlignment: TabAlignment.start,
                    labelStyle: typography.Subtitle2,
                    isScrollable: true,
                    indicatorColor: Colors.lightBlueAccent,
                    labelColor: Colors.lightBlueAccent,
                    unselectedLabelColor: Colors.grey,
                    tabs: [
                      Tab(
                        text: 'Geocoding',
                      ),
                      Tab(text: 'Risk Score'),
                      Tab(text: 'Occupancy'),
                      Tab(text: 'Construction'),
                    ],
                  ),
                ),
              ),
              // Right arrow button
              IconButton(
                icon: Icon(Icons.arrow_right, color: Colors.grey),
                onPressed: _scrollRight,
              ),
            ],
          ),
        ),
        // Container with curved borders for the map view
        Expanded(
          child: Container(
            margin: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                      target: LatLng(37.0902, -95.7129), zoom: 0),
                  markers: _markers,
                  minMaxZoomPreference: _isHeatmapOn
                      ? MinMaxZoomPreference(0, 5)
                      : MinMaxZoomPreference.unbounded,
                  onMapCreated: (GoogleMapController controller) {
                    mapController = controller;
                    clusterManager.setMapId(controller.mapId); // Set map ID for ClusterManager
                  },
                  tileOverlays: _selectedHazard != null &&
                          _tileProviders.containsKey(_selectedHazard)
                      ? {
                          TileOverlay(
                              tileOverlayId: TileOverlayId(_selectedHazard!),
                              tileProvider: _tileProviders[_selectedHazard!]!)
                        }
                      : {},
                  onCameraMove: clusterManager.onCameraMove, // Update clusters on camera move
                  onCameraIdle: clusterManager.updateMap, // Update clusters when camera stops
                ),
                // Positioned widget for the hazard filter at the bottom-left
                _selectedTabIndex == 1?Positioned(
                  bottom: 16,
                  left: 16,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.light
                          ? AppColors.paperElavation25Light
                          : AppColors.paperElavation25,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        selectedItemBuilder: (context) {
                          return _tileProviders.keys.map((hazard) {
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: 80), // Set the maximum width here
                                child: Text(
                                  hazard,
                                  style: typography.InputLabel,
                                  overflow: TextOverflow.ellipsis, // Add ellipsis for long text
                                ),
                              ),
                            );
                          }).toList();
                        },

                        menuMaxHeight: 200,
                        menuWidth: 400,
                        borderRadius: BorderRadius.circular(16),
                        value: _selectedHazard,
                        items: _tileProviders.keys.map((hazard) {
                          return DropdownMenuItem<String>(
                            value: hazard,
                            child: Text(hazard, style: typography.InputLabel),
                          );
                        }).toList(),
                        onChanged: (hazard) => _changeHazardLayer(hazard!),
                        isDense: true,
                        icon: SizedBox.shrink(), // Remove the dropdown icon
                        dropdownColor: Theme.of(context).colorScheme.surface,
                      ),
                    ),
                  ),
                ):SizedBox(),
                // Positioned widget for the heatmap toggle and reducer selection
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.light
                          ? AppColors.paperElavation25Light
                          : AppColors.paperElavation25,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Locations',
                              style: typography.InputLabel.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            SizedBox(width: 8),
                            Container(
                              height: 24,
                              width: 48,
                              child: Switch(
                                value: _showPins,
                                onChanged: (value) => _togglePinVisibility(),
                                activeColor:
                                    Theme.of(context).colorScheme.primary,
                                activeTrackColor: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.5),
                                inactiveThumbColor:
                                    Theme.of(context).colorScheme.surface,
                                inactiveTrackColor: Theme.of(context)
                                    .colorScheme
                                    .surface
                                    .withOpacity(0.5),
                              ),
                            ),
                            SizedBox(width: 8),
                            InkWell(
                              onTap: _toggleHeatmap,
                              child: Container(
                                height: 34,
                                width: 34,
                                padding: EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  shape: BoxShape.rectangle,
                                  color: _isHeatmapOn
                                      ? Colors.orange.withOpacity(0.8)
                                      : Theme.of(context).colorScheme.surface,
                                ),
                                child: SvgPicture.asset(
                                  'assets/images/heatmap_icon.svg',
                                  color: _isHeatmapOn
                                      ? Colors.white
                                      : Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Display the dropdown if heatmap is on and data is initialized
                        if (_isHeatmapOn && _isInitialized)
                          Container(
                            margin: EdgeInsets.only(top: 8),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedReducer,
                                items: _reducers.map((reducer) {
                                  return DropdownMenuItem<String>(
                                    value: reducer,
                                    child: Text(reducer),
                                  );
                                }).toList(),
                                onChanged: _onReducerChanged,
                                isDense: true,
                                icon: SizedBox.shrink(),
                                // Remove the dropdown icon
                                style: typography.Subtitle2.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface),
                                dropdownColor:
                                    Theme.of(context).colorScheme.surface,
                                selectedItemBuilder: (context) {
                                  return _reducers.map((reducer) {
                                    return Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(reducer,
                                          style: TextStyle(fontSize: 16)),
                                    );
                                  }).toList();
                                },
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Score filter tray below the map with rounded corners
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildScoreIndicator(1, Colors.red),
              SizedBox(width: 8),
              _buildScoreIndicator(2, Colors.orange),
              SizedBox(width: 8),
              _buildScoreIndicator(3, Colors.yellow),
              SizedBox(width: 8),
              _buildScoreIndicator(4, Colors.green),
              SizedBox(width: 8),
              _buildScoreIndicator(5, Colors.blue),
            ],
          ),
        ),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildScoreIndicator(int score, Color color) {
    return GestureDetector(
      onTap: () => _toggleScoreFilter(score),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(4),
            // Add padding to create the white border effect
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _selectedScore == score
                  ? Colors.white
                  : Colors.transparent, // White highlight when selected
            ),
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
              ),
            ),
          ),
          SizedBox(width: 8),
          Text(
            '$score',
            style: CustomTypography(context).InputLabel.copyWith(
                  color: Colors.white,
                ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    switch (score) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.yellow;
      case 4:
        return Colors.green;
      case 5:
        return Colors.blue;
      default:
        return Colors.black;
    }
  }

  // Call this function to show the popup on tap
  void showLocationDetailsPopup(BuildContext context, MyLocation location) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return LocationDetailsPopup(
          address: location.finalAddress?.address ?? 'Unknown Address',
          locationId: location.id ?? 'Unknown ID',
          geocodingScore: location.finalAddress?.score ?? 0,
          riskScore: 0,
          //location.riskScore ?? 0,
          hazards: location.hazard ?? {},
        );
      },
    );
  }
}
