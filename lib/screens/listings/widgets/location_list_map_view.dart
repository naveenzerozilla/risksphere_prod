import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:RiskSphere/design_system/primitives/custom_typography.dart';
import 'package:RiskSphere/providers/user_profile_provider.dart';
import 'package:provider/provider.dart';
import '../../../design_system/primitives/app_colors.dart';
import '../../../models/hazard_data.dart';
import '../../../models/my_location_list_model.dart';
import 'package:RiskSphere/providers/my_location_list_provider.dart';
import '../../../providers/custom_tile_providers.dart';
import '../../../providers/custom_tile_providers_main_hazards.dart';
import '../../../service/language_service.dart';
import 'location_details_popup.dart';
import 'package:google_maps_cluster_manager_2/google_maps_cluster_manager_2.dart'
    as cluster_manager;

class LocationListMapView extends StatefulWidget {
  final String accountId;
  final String subAccountId;
  final String? sovId;

  LocationListMapView({
    required this.accountId,
    required this.subAccountId,
    this.sovId,
  });

  @override
  _LocationListMapViewState createState() => _LocationListMapViewState();
}

class _LocationListMapViewState extends State<LocationListMapView>
    with SingleTickerProviderStateMixin {
  late GoogleMapController mapController;
  late cluster_manager.ClusterManager<MyLocation> clusterManager;
  Set<Marker> _markers = {};
  bool _showPins = true;
  int? _selectedScore;
  Map<String, CustomTileProvider> _tileProviders = {};
  bool _isInitialized = false;
  String? _selectedHazard;
  bool _isHeatmapOn = false;
  List<String> _reducers = [];
  String? _selectedReducer;
  int _selectedTabIndex = 0;
  bool _isLoading = false; // used as overlay loader for async work
  TabController? _tabController;

  // Hazard state
  List<HazardData> mainHazards = [];
  String? selectedHazardId;
  String? selectedVendor = "";
  bool isLoadingMainHazards = false;
  MapType _currentMapType = MapType.satellite;
  MapType _currentMapType1 = MapType.normal;
  CustomTileProviderMainHazards? _mainHazardTileProvider;
  bool _isHeatmapMenuOpen = false;

  // navigation state
  int _currentLocationIndex = 0;
  bool _isAnimating = false;
  bool _mapReady = false;
  bool _locationsLoaded = false; // initial first-page loaded flag
  bool _firstAttachDone = false; // attach camera once after first data load

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController!.addListener(() {
      setState(() => _selectedTabIndex = _tabController!.index);
    });

    // initialize cluster manager with empty list - will set items later
    clusterManager = cluster_manager.ClusterManager<MyLocation>(
      [],
      _updateMarkers,
      markerBuilder: _markerBuilder,
      levels: [1, 4.25, 6.75],
      extraPercent: 0.2,
      stopClusteringZoom: 5.0,
    );
    _initializeClusterManager();
    _fetchMainHazardLayers();
    // call after build to fetch first page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLocationsFirstTime();
    });
  }

  void _initializeClusterManager() {
    final allLocations =
        Provider.of<MyLocationListProvider>(context, listen: false)
            .fullLocationList;

    clusterManager = cluster_manager.ClusterManager<MyLocation>(
      allLocations,
      _updateMarkers,
      markerBuilder: _markerBuilder,
      levels: [1, 4.25, 6.75],
      // Optional zoom levels
      extraPercent: 0.2,
      // Optional padding to prevent clusters from popping in/out
      stopClusteringZoom: 5.0,
    );
  }

  // ------------ INITIAL DATA LOAD ------------
  Future<void> _loadLocationsFirstTime() async {
    final provider =
        Provider.of<MyLocationListProvider>(context, listen: false);

    // show loader for initial load
    setState(() {
      _isLoading = true;
    });

    try {
      // load page 1 with pageSize 10 (matches your API)
      await provider.fetchLocationListMapSov(
        context,
        "",
        1,
        10000,
        widget.accountId,
        widget.subAccountId,
        "",
        "",
        widget.sovId,
      );

      // mark loaded
      _locationsLoaded = true;

      // attach items to cluster manager if map is ready
      _tryAttachMarkers();
    } catch (e, st) {
      print("Error loading first page of locations: $e\n$st");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Ensure cluster items attached and animate camera to first location once
  void _tryAttachMarkers() {
    if (!_mapReady || !_locationsLoaded) return;

    final provider =
        Provider.of<MyLocationListProvider>(context, listen: false);

    clusterManager.setItems(provider.fullLocationList);

    if (!_firstAttachDone && provider.fullLocationList.isNotEmpty) {
      _moveCameraTo(0); // show first pin
      _firstAttachDone = true;
    }
  }

  void _moveCameraTo(int index) {
    final provider =
        Provider.of<MyLocationListProvider>(context, listen: false);

    if (provider.fullLocationList.isEmpty) return;
    if (index < 0 || index >= provider.fullLocationList.length) return;

    final target = provider.fullLocationList[index].location;

    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: 15),
      ),
    );
  }

  // ------------ MARKER / CLUSTER HELPERS ------------
  Future<Marker> _markerBuilder(
      cluster_manager.Cluster<MyLocation> cluster) async {
    if (cluster.isMultiple) {
      return Marker(
        markerId: MarkerId(cluster.getId()),
        position: cluster.location,
        icon: await _getClusterBitmap(
          125,
          text: cluster.count.toString(),
        ),
      );
    }

    MyLocation location = cluster.items.first;

    bool isCurrent = location.id ==
        Provider.of<MyLocationListProvider>(context, listen: false)
            .fullLocationList[_currentLocationIndex]
            .id;

    return Marker(
      markerId: MarkerId(location.id ?? ''),
      position: location.location,
      icon: BitmapDescriptor.defaultMarkerWithHue(
        isCurrent ? BitmapDescriptor.hueRed : BitmapDescriptor.hueBlue,
      ),
      onTap: () async {
        print("Marker tapped!");

        setState(() {
          _focusedLocation = location.location; // ⭐ SET FOCUSED LOCATION HERE
          is3DView = false; // Reset back to 2D
        });

        await mapController.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: location.location,
              zoom: 17,
              tilt: 0,
              bearing: 0,
            ),
          ),
        );

        showLocationDetailsPopup(context, location);
      },

      // onTap: () {
      //   showLocationDetailsPopup(context, location);
      // },
    );
  }

  // Future<Marker> _markerBuilder(
  //     cluster_manager.Cluster<MyLocation> cluster) async {
  //   if (cluster.isMultiple) {
  //     Color clusterColor = _determineClusterColor(cluster.items.toList());
  //     return Marker(
  //       markerId: MarkerId(cluster.getId()),
  //       position: cluster.location,
  //       icon: await _getClusterBitmap(125,
  //           text: cluster.count.toString(), color: clusterColor),
  //       onTap: () {
  //         // optionally handle cluster tap
  //       },
  //     );
  //   } else {
  //     MyLocation location = cluster.items.first;
  //     final score = location.finalAddress?.score;
  //
  //     // ⭐ CURRENT LOCATION MARKER (RED)
  //     bool isCurrent = location.id ==
  //         Provider.of<MyLocationListProvider>(context, listen: false)
  //             .fullLocationList[_currentLocationIndex]
  //             .id;
  //
  //     return Marker(
  //       markerId: MarkerId(location.id ?? ''),
  //       position: location.location,
  //
  //       // ⭐ If current → RED, else use score color
  //       icon: BitmapDescriptor.defaultMarkerWithHue(
  //         isCurrent ? BitmapDescriptor.hueRed : BitmapDescriptor.hueBlue, //_getMarkerHue(score ?? 0),
  //       ),
  //
  //       visible:
  //           _showPins && (_selectedScore == null || _selectedScore == score),
  //
  //       onTap: () {
  //         showLocationDetailsPopup(context, location);
  //       },
  //     );
  //   }
  // }

  Color _determineClusterColor(List<MyLocation> items) {
    Map<int, int> colorCounts = {};
    for (var item in items) {
      int score = item.finalAddress?.score ?? 0;
      colorCounts[score] = (colorCounts[score] ?? 0) + 1;
    }
    if (colorCounts.isEmpty) return Colors.blue;
    int dominantScore =
        colorCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    return _getColorFromScore(dominantScore);
  }

  Color _getColorFromScore(int score) {
    // You had blue for all — keep original
    return Colors.blue;
  }

  Future<BitmapDescriptor> _getClusterBitmap(int size,
      {String? text, Color color = Colors.red}) async {
    final PictureRecorder pictureRecorder = PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..color = color;
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
    if (!mounted) return;
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

  void _handleClusterTap(dynamic cluster) async {
    double currentZoom = await mapController.getZoomLevel();
    mapController.animateCamera(
      CameraUpdate.newLatLngZoom(
        cluster.position,
        currentZoom + 2,
      ),
    );
  }

  bool is3DView = false;
  LatLng? _focusedLocation;
  LatLng _currentCenter = LatLng(20.5937, 78.9629);

  // ------------ HAZARD LAYER / TILE PROVIDER (kept mostly unchanged) ------------
  _fetchMainHazardLayers() async {
    setState(() {
      isLoadingMainHazards = true;
    });
    try {
      var provider =
          Provider.of<MyLocationListProvider>(context, listen: false);
      await provider.fetchMainTileProviders(context);
      if (provider.mainHazardData != null) {
        final hazardsData = provider.mainHazardData?['result'] as List;
        setState(() {
          mainHazards = hazardsData.map((h) => HazardData.fromJson(h)).toList();
          selectedVendor = "";
          selectedHazardId =
              mainHazards.isNotEmpty ? mainHazards.first.id : null;
          if (selectedHazardId != null) {
            _changeHazardLayer(selectedHazardId!);
          }
          _changeVendor("");
        });
      }
    } catch (e, stackTrace) {
      print("Error while fetching main hazard layers: $e");
      print(stackTrace);
    } finally {
      if (mounted)
        setState(() {
          isLoadingMainHazards = false;
        });
    }
  }

  void _changeHazardLayer(String hazardId) {
    setState(() {
      if (_isHeatmapOn) {
        _selectedHazard = hazardId;
      } else {
        selectedHazardId = hazardId;
        final hazard = mainHazards.firstWhere((h) => h.id == hazardId);
        if (hazard.vendors.isNotEmpty) {
          selectedVendor = hazard.vendors.first.name;
        } else {
          selectedVendor = null;
        }
      }
    });
  }

  void _changeVendor(String? vendorName) {
    if (!_isHeatmapOn) {
      setState(() {
        selectedVendor = vendorName;
        _mainHazardTileProvider = CustomTileProviderMainHazards(
          tileUrls: mainHazards,
          hazardType: selectedHazardId!,
          vendor: vendorName ?? "USGS",
        );
      });
    }
  }

  Future<void> _fetchHazardLayers({bool regenerate = false}) async {
    setState(() {
      _isLoading = true;
    });

    try {
      var provider =
          Provider.of<MyLocationListProvider>(context, listen: false);

      if (_selectedTabIndex == 1) {
        if (regenerate ||
            provider.hazardData == null ||
            provider.hazardData?['heatmap'] == null) {
          var userProfileProvider =
              Provider.of<UserProfileProvider>(context, listen: false);
          var trialStatus = userProfileProvider.trialInfo['status'] ?? '';
          if (trialStatus.isNotEmpty) return;
          await provider.generateHeatMapForLocationsGeocoding(
            context,
            widget.accountId,
            widget.subAccountId,
            false,
            regenerate,
            widget.sovId,
          );
        }

        Map<String, dynamic>? data = provider.hazardData;
        if (data == null || data.containsKey('message')) {
          print(
              "Re-fetching due to incomplete hazard data: ${data?['message']}");
          return;
        }

        final hazards = data['heatmap'];
        if (hazards == null) {
          print("Error: 'heatmap' data is missing in the response.");
          return;
        }

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

          _tileProviders[hazard] = CustomTileProvider(
            tileUrls: {hazard: intensityMap},
            hazardType: hazard,
            currentReducer: _selectedReducer ?? "mean",
          );
        });

        setState(() {
          _isInitialized = true;
          _selectedHazard = _tileProviders.keys.first;
        });
      }
    } catch (e) {
      print("Error in _fetchHazardLayers: $e");
    } finally {
      if (mounted)
        setState(() {
          _isLoading = false;
        });
    }
  }

  void _toggleHeatmap() async {
    setState(() {
      _isHeatmapOn = !_isHeatmapOn;
      _isLoading = true;
      if (!_isHeatmapOn) {
        if (_showPins) _togglePinVisibility();
      }
    });

    if (!_isHeatmapOn) {
      setState(() {
        _selectedHazard = null;
        _isLoading = false;
      });
    } else {
      if (_isInitialized) {
        setState(() {
          _selectedHazard = _selectedHazard ?? _tileProviders.keys.first;
          _tileProviders[_selectedHazard]
              ?.updateReducer(_selectedReducer ?? "mean");
          _isLoading = false;
        });
      } else {
        try {
          await _fetchHazardLayers();
        } catch (e) {
          print("Error while fetching hazard layers: $e");
        } finally {
          if (mounted)
            setState(() {
              _isLoading = false;
            });
        }
      }
    }
  }

  void _onReducerChanged(String? newReducer) {
    setState(() {
      _selectedReducer = newReducer;
      if (_selectedHazard != null && newReducer != null) {
        _tileProviders[_selectedHazard]?.updateReducer(newReducer);
        _selectedHazard = ""; // clear temporarily
      }
    });

    Future.delayed(Duration(milliseconds: 100), () {
      if (!mounted) return;
      setState(() {
        _selectedHazard = _tileProviders.keys.firstWhere(
            (key) => key.isNotEmpty && key == _selectedHazard,
            orElse: () => _tileProviders.keys.first);
      });
    });
  }

  // Map style (kept your style)
  // final String _mapStyle = '''[ ... your long style json ... ]''';

  // ------------ NAVIGATION + PAGINATION ------------
  // This is central: when we request zoom to index, if it's the last item of current data
  // and more pages are available, load next page then proceed.
  Future<void> _zoomToLocation(int index) async {
    final provider =
        Provider.of<MyLocationListProvider>(context, listen: false);

    if (provider.fullLocationList.isEmpty) return;

    setState(() => _isAnimating = true);

    try {
      _moveCameraTo(index);

      setState(() => _currentLocationIndex = index);

      // ⭐ IMPORTANT: rebuild cluster markers to update RED PIN
      clusterManager.setItems(provider.fullLocationList);
    } catch (e) {
      print("Zoom error: $e");
    }

    setState(() => _isAnimating = false);
  }

  void _togglePinVisibility() {
    setState(() {
      _showPins = !_showPins;
    });

    final provider =
        Provider.of<MyLocationListProvider>(context, listen: false);
    clusterManager.setItems(
      provider.fullLocationList
          .where((location) =>
              _showPins || location.finalAddress?.score == _selectedScore)
          .toList(),
    );
  }

  void _toggleScoreFilter(int score) {
    setState(() {
      if (_selectedScore == score) {
        _selectedScore = null;
      } else {
        _selectedScore = score;
      }
    });

    final provider =
        Provider.of<MyLocationListProvider>(context, listen: false);
    clusterManager.setItems(
      provider.fullLocationList
          .where((location) =>
              _selectedScore == null ||
              location.finalAddress?.score == _selectedScore)
          .toList(),
    );
  }

  Future<void> _toggle2D3DView() async {
    // Use focused location when marker selected, else map center
    final LatLng target = _focusedLocation ?? _currentCenter;

    final zoom = await mapController.getZoomLevel();

    await mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: target,
          zoom: zoom,
          tilt: is3DView ? 0 : 60,
          bearing: is3DView ? 0 : 45,
        ),
      ),
    );

    setState(() => is3DView = !is3DView);
  }

  // ------------ BUILD ------------
  @override
  Widget build(BuildContext context) {
    var typography = CustomTypography(context);

    return Consumer<MyLocationListProvider>(
      builder: (context, myLocationProvider, child) {
        MyLocation? currentLocation;

        if (myLocationProvider.fullLocationList.isNotEmpty &&
            _currentLocationIndex >= 0 &&
            _currentLocationIndex <
                myLocationProvider.fullLocationList.length) {
          currentLocation =
              myLocationProvider.fullLocationList[_currentLocationIndex];
        }
        // Attach markers when provider list changes (and map ready)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_mapReady && myLocationProvider.fullLocationList.isNotEmpty) {
            clusterManager.setItems(myLocationProvider.fullLocationList);
            if (!_firstAttachDone) {
              final first = myLocationProvider.fullLocationList.first.location;
              try {
                mapController.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(target: first, zoom: 14),
                  ),
                );
              } catch (_) {}
              _firstAttachDone = true;
            }
          }
        });

        // WidgetsBinding.instance.addPostFrameCallback((_) {
        //   if (_mapReady && myLocationProvider.fullLocationList.isNotEmpty) {
        //     clusterManager.setItems(myLocationProvider.fullLocationList);
        //     if (!_firstAttachDone) {
        //       // animate to first item on first load
        //       if (myLocationProvider.fullLocationList.isNotEmpty) {
        //         final first =
        //             myLocationProvider.fullLocationList.first.location;
        //         try {
        //           mapController.animateCamera(
        //             CameraUpdate.newCameraPosition(
        //               CameraPosition(target: first, zoom: 14),
        //             ),
        //           );
        //         } catch (_) {}
        //         _firstAttachDone = true;
        //       }
        //     }
        //   }
        // });

        // If initial data not loaded yet -> full screen loader
        if (!_locationsLoaded) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }

        final providerListLength = myLocationProvider.totalRecords.toString();

        return Column(
          children: [
            SizedBox(height: 8),

            // Geocoding + Hazard Score tabs in a single row
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
              ),
              height: 50,
              child: TabBar(
                controller: _tabController,
                isScrollable: false,
                tabAlignment: TabAlignment.fill,
                dividerColor: Colors.transparent,
                labelStyle: typography.Subtitle2,
                indicatorColor: Colors.lightBlueAccent,
                labelColor: Colors.lightBlueAccent,
                unselectedLabelColor: Colors.grey,
                tabs: [
                  Tab(
                    text: LanguageService.getTranslated(context, "geocoding"),
                  ),
                  Tab(
                    text: LanguageService.getTranslated(
                        context, "hazard_score"),
                  ),
                ],
              ),
            ),

            // MAP CONTAINER
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
                        target: LatLng(20.5937, 78.9629),
                        zoom: 9,
                      ),
                      zoomControlsEnabled: false,
                      myLocationEnabled: true,
                      markers: (!_isHeatmapOn && _showPins) ? _markers : {},
                      mapType: _selectedTabIndex == 0
                          ? _currentMapType
                          : _currentMapType1,
                      onMapCreated: (GoogleMapController controller) {
                        mapController = controller;
                        _mapReady = true; // ⭐ REQUIRED FIX
                        clusterManager.setMapId(controller.mapId);
                        mapController.setMapStyle(_mapStyle);

                        _tryAttachMarkers(); // ⭐ Attach markers once map is ready
                      },
                      tileOverlays: _selectedTabIndex == 0
                          ? {} // No tile overlay when selectedTabIndex is 0
                          : (_selectedHazard != null &&
                                  _tileProviders.containsKey(_selectedHazard) &&
                                  _mainHazardTileProvider != null &&
                                  selectedHazardId != null &&
                                  selectedVendor != null)
                              ? {
                                  TileOverlay(
                                    tileOverlayId:
                                        TileOverlayId(selectedHazardId!),
                                    tileProvider: _mainHazardTileProvider!,
                                  ),
                                  TileOverlay(
                                    tileOverlayId:
                                        TileOverlayId(_selectedHazard!),
                                    tileProvider:
                                        _tileProviders[_selectedHazard!]!,
                                  ),
                                }
                              : (_mainHazardTileProvider != null &&
                                      selectedHazardId != null &&
                                      selectedVendor != null)
                                  ? {
                                      TileOverlay(
                                        tileOverlayId:
                                            TileOverlayId(selectedHazardId!),
                                        tileProvider: _mainHazardTileProvider!,
                                      ),
                                    }
                                  : {},
                      // onCameraMove: clusterManager.onCameraMove,
                      onCameraMove: (position) {
                        _currentCenter = position
                            .target; // ⭐ KEEP TRACK OF CURRENT MAP LOCATION
                        clusterManager.onCameraMove(position);
                      },
                      // Update clusters on camera move
                      onCameraIdle: clusterManager
                          .updateMap, // Update clusters when camera stops
                    ),
                    Positioned(
                      bottom: 70,
                      right: 8,
                      child: InkWell(
                        onTap: _toggle2D3DView,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 6,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Text(
                          is3DView ? "3D " : "2D "
,
        style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      )

                    ),
                    _selectedTabIndex == 1
                        ? _buildHazardControls()
                        : Positioned(
                            bottom: 20,
                            left: 10,
                            child: Container(
                              margin: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color:
                                    Theme.of(context).colorScheme.brightness ==
                                            Brightness.light
                                        ? AppColors.paperElevation2Light
                                        : AppColors.paperElevation2,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  FloatingActionButton.small(
                                    elevation: 0,
                                    backgroundColor: Theme.of(context)
                                                .colorScheme
                                                .brightness ==
                                            Brightness.light
                                        ? AppColors.paperElevation2Light
                                        : AppColors.paperElevation2,
                                    onPressed: () {
                                      setState(() {
                                        // List of map types to cycle through
                                        List<MapType> mapTypes = [
                                          MapType.normal,
                                          MapType.satellite,
                                          MapType.terrain,
                                          MapType.hybrid
                                        ];

                                        // Get the next index in the list
                                        int currentIndex =
                                            mapTypes.indexOf(_currentMapType);
                                        int nextIndex = (currentIndex + 1) %
                                            mapTypes.length;

                                        // Update the map type
                                        _currentMapType = mapTypes[nextIndex];
                                      });
                                    },

                                    // onPressed: () {
                                    //   setState(() {
                                    //     _currentMapType =
                                    //     _currentMapType == MapType.normal
                                    //         ? MapType.satellite
                                    //         : MapType.terrain
                                    //   });
                                    // },
                                    child: Icon(Icons.layers,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface),
                                    tooltip: 'Change Map Type',
                                  ),
                                  SizedBox(width: 8),
                                ],
                              ),
                            ),
                          ),
                    // Positioned widget for the heatmap toggle and reducer selection
                    Positioned(
                        top: 16,
                        right: 10,
                        child: _selectedTabIndex == 1
                            ? Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).brightness ==
                                          Brightness.light
                                      ? AppColors.paperElavation25Light
                                      : AppColors.paperElavation25,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      children: [
                                        _selectedTabIndex == 1
                                            ? Container(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 0, vertical: 0),
                                                // decoration: BoxDecoration(
                                                //   color: Theme.of(context).brightness ==
                                                //           Brightness.light
                                                //       ? AppColors.paperElavation25Light
                                                //       : AppColors.paperElavation25,
                                                //   borderRadius: BorderRadius.circular(16),
                                                // ),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        // Container(
                                                        //   height: 24,
                                                        //   width: 48,
                                                        //   child: Switch(
                                                        //     value: _showPins,
                                                        //     // onChanged: (value) {
                                                        //     onChanged: _isHeatmapMenuOpen
                                                        //         ? null
                                                        //         : (value) {
                                                        //             print(value);
                                                        //             // if (_isHeatmapOn) {
                                                        //             print("object");
                                                        //             _togglePinVisibility();
                                                        //             // }
                                                        //           },
                                                        //     activeColor: Theme.of(context)
                                                        //         .colorScheme
                                                        //         .primary,
                                                        //     activeTrackColor: Theme.of(context)
                                                        //         .colorScheme
                                                        //         .primary
                                                        //         .withOpacity(0.5),
                                                        //     inactiveThumbColor: Theme.of(context)
                                                        //         .colorScheme
                                                        //         .surface,
                                                        //     inactiveTrackColor: Theme.of(context)
                                                        //         .colorScheme
                                                        //         .surface
                                                        //         .withOpacity(0.5),
                                                        //   ),
                                                        // ),

                                                        _selectedTabIndex == 1
                                                            ? MenuAnchor(
                                                                builder: (context,
                                                                    controller,
                                                                    child) {
                                                                  return InkWell(
                                                                    onTap:
                                                                        () async {
                                                                      // var userProfileProvider =
                                                                      // Provider.of<UserProfileProvider>(context, listen: false);
                                                                      // final trialStatus = userProfileProvider.trialInfo['status'] ?? '';
                                                                      // final trialSubdestinations =
                                                                      //     userProfileProvider.trialInfo['subDestinations'] ?? 0;

                                                                      // if (trialStatus != '') {
                                                                      //   showDialog(
                                                                      //     context: context,
                                                                      //     barrierColor: Theme.of(context).colorScheme.surfaceContainerLowest,
                                                                      //     builder: (BuildContext context) {
                                                                      //       return Column(
                                                                      //         mainAxisAlignment: MainAxisAlignment.center,
                                                                      //         children: [
                                                                      //           Row(
                                                                      //             mainAxisAlignment: MainAxisAlignment.end,
                                                                      //             children: [
                                                                      //               IconButton(
                                                                      //                 icon: const Icon(Icons.close),
                                                                      //                 onPressed: () {
                                                                      //                   Navigator.of(context).pop();
                                                                      //                 },
                                                                      //               ),
                                                                      //             ],
                                                                      //           ),
                                                                      //           MessageCard(
                                                                      //             isUpgrade: true,
                                                                      //             messageTextSpans: [
                                                                      //               TextSpan(
                                                                      //                 text: 'Upgrade your account to generate heat map!',
                                                                      //                 style: CustomTypography(context).Body1,
                                                                      //               ),
                                                                      //             ],
                                                                      //           ),
                                                                      //         ],
                                                                      //       );
                                                                      //     },
                                                                      //   );
                                                                      //   return;
                                                                      // }
                                                                      //
                                                                      // if (_isLoading ||
                                                                      //     Provider.of<MyLocationListProvider>(context, listen: false)
                                                                      //         .isHeatMapGeneratingLive) {
                                                                      //   // Prevent double-tap or when generation is already in progress
                                                                      //   return;
                                                                      // }

                                                                      // 🟡 Start loader
                                                                      setState(
                                                                          () {
                                                                        _isLoading =
                                                                            true;
                                                                      });

                                                                      // 🕒 Stop loader automatically after 10 seconds
                                                                      Future.delayed(
                                                                          const Duration(
                                                                              seconds: 5),
                                                                          () {
                                                                        if (mounted) {
                                                                          setState(
                                                                              () {
                                                                            _isLoading =
                                                                                false;
                                                                          });
                                                                        }
                                                                      });

                                                                      // 🔥 Continue your existing logic
                                                                      // if (_reducers.isEmpty) {
                                                                      //   _toggleHeatmap();
                                                                      // } else {
                                                                      //   if (controller.isOpen) {
                                                                      //     controller.close();
                                                                      //   } else {
                                                                      //     controller.open();
                                                                      //   }
                                                                      // }
                                                                    },
                                                                    child:
                                                                        Container(
                                                                      height:
                                                                          31,
                                                                      width: 34,
                                                                      padding:
                                                                          const EdgeInsets
                                                                              .all(
                                                                              2),
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        borderRadius:
                                                                            BorderRadius.circular(8),
                                                                        shape: BoxShape
                                                                            .rectangle,
                                                                        color: _isHeatmapOn
                                                                            ? Colors.grey.withOpacity(0.8)
                                                                            : Theme.of(context).colorScheme.surface,
                                                                      ),
                                                                      child: _isLoading
                                                                          ? const Center(
                                                                              child: SizedBox(
                                                                                height: 20,
                                                                                width: 20,
                                                                                child: CircularProgressIndicator(
                                                                                  strokeWidth: 2,
                                                                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                                                                                ),
                                                                              ),
                                                                            )
                                                                          : SvgPicture.asset(
                                                                              'assets/images/heatmap_icon.svg',
                                                                              color: _isHeatmapOn ? Colors.white : Theme.of(context).colorScheme.onSurface,
                                                                            ),
                                                                    ),
                                                                  );
                                                                },
                                                                menuChildren:
                                                                    !_isLoading &&
                                                                            !Provider.of<MyLocationListProvider>(context, listen: false).isHeatMapGeneratingLive
                                                                        ? [
                                                                            // Update Heatmap Button
                                                                            MenuItemButton(
                                                                              child: Text(
                                                                                "Update Heatmap",
                                                                                style: typography.InputLabel,
                                                                              ),
                                                                              onPressed: () async {
                                                                                print("Updating heatmap...");
                                                                                await _fetchHazardLayers(regenerate: true);
                                                                              },
                                                                            ),
                                                                            Divider(
                                                                                height: 1,
                                                                                thickness: 1),
                                                                            // "Switch off Heatmap" option when heatmap is on
                                                                            if (_isHeatmapOn)
                                                                              MenuItemButton(
                                                                                child: Text("Switch off Heatmap", style: typography.InputLabel),
                                                                                onPressed: () {
                                                                                  _toggleHeatmap(); // Turn off the heatmap
                                                                                },
                                                                              ),
                                                                            if (_isHeatmapOn)
                                                                              Divider(height: 1, thickness: 1),
                                                                            // List of reducers
                                                                            ..._reducers.map((reducer) {
                                                                              return MenuItemButton(
                                                                                child: Text(reducer, style: typography.InputLabel),
                                                                                onPressed: () {
                                                                                  if (!_isHeatmapOn) {
                                                                                    // Automatically turn on the heatmap if it's off
                                                                                    _toggleHeatmap();
                                                                                  }
                                                                                  _onReducerChanged(reducer); // Set the selected reducer
                                                                                },
                                                                              );
                                                                            }).toList(),
                                                                          ]
                                                                        : [],
                                                              )
                                                            : SizedBox(),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              )
                                            : Container(),
                                      ],
                                    ),
                                  ],
                                ),
                              )
                            : Container()),
                  ],
                ),
              ),
            ),
            // SizedBox(height: 8),

            if (currentLocation != null)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      "(${_currentLocationIndex + 1}/$providerListLength)",
                      textAlign: TextAlign.center,
                      style: typography.Subtitle2.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.white30,
                      ),
                    ),
                    SizedBox(height: 4),
                    Container(
                      alignment: Alignment.topLeft,
                      // width: MediaQuery.of(context).size.width/1.3,
                      child: Text(
                        currentLocation!.finalAddress?.address ??
                            "Unknown location",
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        style: typography.Subtitle2.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    SizedBox(height: 6),
                  ],
                ),
              )
            else
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text(
                  "",
                  textAlign: TextAlign.center,
                  style: typography.Subtitle2,
                ),
              ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                              color: _currentLocationIndex > 0
                                  ? AppColors.primaryMain
                                  : Colors.grey,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          backgroundColor: _currentLocationIndex > 0
                              ? Colors.black
                              : Colors.grey[300],
                        ),
                        onPressed: _currentLocationIndex > 0 && !_isAnimating
                            ? () async {
                                setState(() => _isAnimating = true);
                                await _zoomToLocation(
                                    _currentLocationIndex - 1);
                                setState(() => _isAnimating = false);
                              }
                            : null,
                        child: _isAnimating && _currentLocationIndex > 0
                            ?  SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : Text(LanguageService.getTranslated(
                              context,
                              "previous"),
                                style: typography.ButtonLarge.copyWith(
                                  color: _currentLocationIndex > 0
                                      ? AppColors.primaryMain
                                      : Colors.grey,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            side: const BorderSide(
                              color: AppColors.primaryMain,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 22),
                          backgroundColor: _currentLocationIndex <
                                  myLocationProvider.fullLocationList.length - 1
                              ? AppColors.primaryMain
                              : Colors.grey[300],
                        ),
                        onPressed: _currentLocationIndex <
                                    myLocationProvider.fullLocationList.length -
                                        1 &&
                                !_isAnimating
                            ? () async {
                                setState(() => _isAnimating = true);
                                await _zoomToLocation(
                                    _currentLocationIndex + 1);
                                setState(() => _isAnimating = false);
                              }
                            : null,
                        child: _isAnimating &&
                                _currentLocationIndex <
                                    myLocationProvider.fullLocationList.length -
                                        1
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : Text(
                          LanguageService.getTranslated(
                              context,
                              "next"),
                                style: typography.ButtonLarge.copyWith(
                                  color: _currentLocationIndex <
                                          myLocationProvider
                                                  .fullLocationList.length -
                                              1
                                      ? AppColors.black
                                      : Colors.grey,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                ),
              ],
            ),

            SizedBox(height: 16),
          ],
        );
      },
    );
  }

  // small helpers for widget pieces to reduce build bloat
  Widget _buildLayerButton() {
    return Positioned(
      bottom: 20,
      left: 3,
      child: Container(
        margin: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.brightness == Brightness.light
              ? AppColors.paperElevation2Light
              : AppColors.paperElevation2,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            FloatingActionButton.small(
              elevation: 0,
              backgroundColor:
                  Theme.of(context).colorScheme.brightness == Brightness.light
                      ? AppColors.paperElevation2Light
                      : AppColors.paperElevation2,
              onPressed: () {
                setState(() {
                  List<MapType> mapTypes = [
                    MapType.normal,
                    MapType.satellite,
                    MapType.terrain
                  ];
                  int currentIndex = mapTypes.indexOf(_currentMapType);
                  int nextIndex = (currentIndex + 1) % mapTypes.length;
                  _currentMapType = mapTypes[nextIndex];
                });
              },
              child: Icon(Icons.layers,
                  color: Theme.of(context).colorScheme.onSurface),
              tooltip: 'Change Map Type',
            ),
            SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildHeatmapControl(CustomTypography typography) {
    return Container(
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
              MenuAnchor(
                builder: (context, controller, child) {
                  return InkWell(
                    onTap: () async {
                      setState(() {
                        _isLoading = true;
                      });
                      Future.delayed(const Duration(seconds: 5), () {
                        if (mounted) {
                          setState(() {
                            _isLoading = false;
                          });
                        }
                      });
                    },
                    child: Container(
                      height: 34,
                      width: 34,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        shape: BoxShape.rectangle,
                        color: _isHeatmapOn
                            ? Colors.grey.withOpacity(0.8)
                            : Theme.of(context).colorScheme.surface,
                      ),
                      child: _isLoading
                          ? const Center(
                              child: SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.orange),
                                ),
                              ),
                            )
                          : SvgPicture.asset(
                              'assets/images/heatmap_icon.svg',
                              color: _isHeatmapOn
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                    ),
                  );
                },
                menuChildren: !_isLoading &&
                        !Provider.of<MyLocationListProvider>(context,
                                listen: false)
                            .isHeatMapGeneratingLive
                    ? [
                        MenuItemButton(
                          child: Text("Update Heatmap",
                              style: typography.InputLabel),
                          onPressed: () async {
                            await _fetchHazardLayers(regenerate: true);
                          },
                        ),
                        Divider(height: 1, thickness: 1),
                        if (_isHeatmapOn)
                          MenuItemButton(
                            child: Text("Switch off Heatmap",
                                style: typography.InputLabel),
                            onPressed: _toggleHeatmap,
                          ),
                        if (_isHeatmapOn) Divider(height: 1, thickness: 1),
                        ..._reducers.map((reducer) {
                          return MenuItemButton(
                            child: Text(reducer, style: typography.InputLabel),
                            onPressed: () {
                              if (!_isHeatmapOn) _toggleHeatmap();
                              _onReducerChanged(reducer);
                            },
                          );
                        }).toList(),
                      ]
                    : [],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Build hazard controls (kept from original)
  Widget _buildHazardControls() {
    var typography = CustomTypography(context);

    // Show loading spinner if the main hazards are loading
    if (isLoadingMainHazards) {
      return Positioned(
        bottom: 2,
        left: 11,
        child: Container(
          width: 45,
          height: 45,
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.light
                ? AppColors.paperElavation25Light
                : AppColors.paperElavation25,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    // If heatmap is off, use the existing menu with mainHazards and vendors
    if (!_isHeatmapOn || _isLoading) {
      // if (!(_selectedTabIndex ==0  || _selectedTabIndex == 1) || mainHazards.isEmpty) {
      // if (!(_selectedTabIndex == 2 || _selectedTabIndex == 1) ||
      //     mainHazards.isEmpty) {
      //   return SizedBox();
      // }

      return Positioned(
        bottom: 16,
        left: 16,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.light
                ? AppColors.paperElavation25Light
                : AppColors.paperElavation25,
            borderRadius: BorderRadius.circular(16),
          ),
          child: MenuAnchor(
            builder: (context, controller, child) {
              return IconButton(
                onPressed: () {
                  if (controller.isOpen) {
                    controller.close();
                    setState(() {
                      _isHeatmapMenuOpen = false;
                    });
                  } else {
                    controller.open();
                    setState(() {
                      _isHeatmapMenuOpen = true;
                    });
                  }
                  // if (controller.isOpen) {
                  //   controller.close();
                  // } else {
                  //   controller.open();
                  // }
                },
                icon: SvgPicture.asset(
                  'assets/images/hazardLayerIcon.svg',
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              );
            },
            menuChildren: [
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: 200),
                // Limit height of the menu
                child: SingleChildScrollView(
                  child: Column(
                    children: mainHazards.map((hazard) {
                      return SubmenuButton(
                        child: Text(hazard.name, style: typography.InputLabel),
                        menuChildren: hazard.vendors.map((vendor) {
                          return MenuItemButton(
                            child:
                                Text(vendor.name, style: typography.InputLabel),
                            onPressed: () {
                              // Change hazard and vendor selection
                              _changeHazardLayer(hazard.id!);
                              _changeVendor(vendor.name);
                            },
                          );
                        }).toList(),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // If heatmap is on and not loading, generate the menu using tileProviders
    return Positioned(
      bottom: 16,
      left: 16,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.light
              ? AppColors.paperElavation25Light
              : AppColors.paperElavation25,
          borderRadius: BorderRadius.circular(16),
        ),
        child: MenuAnchor(
          builder: (context, controller, child) {
            return IconButton(
              onPressed: () {
                if (controller.isOpen) {
                  controller.close();
                } else {
                  controller.open();
                }
              },
              icon: SvgPicture.asset(
                'assets/images/hazardLayerIcon.svg',
                color: Theme.of(context).colorScheme.onSurface,
              ),
            );
          },
          menuChildren: [
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 200),
              // Limit height of the menu
              child: SingleChildScrollView(
                child: Column(
                  children: _tileProviders.keys.map((hazard) {
                    return MenuItemButton(
                      child: Text(hazard, style: typography.InputLabel),
                      onPressed: () {
                        // Update the selected hazard
                        setState(() {
                          _selectedHazard = hazard;
                          print("Selected Hazard changed to: $_selectedHazard");
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Show popup
  void showLocationDetailsPopup(BuildContext context, MyLocation location) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final sovIdValue = (location.finalAddress?.sovId is List &&
                location.finalAddress!.sovId!.isNotEmpty)
            ? location.finalAddress!.sovId![0].toString()
            : null;
        return LocationDetailsPopup(
          address: location.finalAddress?.address ?? 'Unknown Address',
          locationId: location.id ?? 'Unknown ID',
          geocodingScore: location.finalAddress?.score ?? 0,
          riskScore: location.hazard?['Overall']?.rating ?? 0,
          dataCompleteness: location.dataCompleteness?.toString() ?? '1',
          hazards: location.hazard ?? {},
          geocodedAt: [location.finalAddress?.locationType ?? ""],
          occupancy: location.finalAddress?.placeTypes ?? ["--"],
          campus: location.finalAddress?.campusId,
          accountId: location.finalAddress?.accountId,
          accountName: location.finalAddress?.accountName,
          subAccountId: location.finalAddress?.subAccountId,
          subAccountName: location.finalAddress?.subAccountName,
          sovId: sovIdValue,
          sovName: location.finalAddress?.sovName,
          rented: location.finalAddress?.rented ?? false,
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }
}

int scoreToStar(int? score) {
  if (score == null) return 0;
  if (score >= 80) return 5;
  if (score >= 60) return 4;
  if (score >= 40) return 3;
  if (score >= 20) return 2;
  return 0;
}
