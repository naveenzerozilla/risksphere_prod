import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:RiskSphere/design_system/primitives/custom_typography.dart';
import 'package:RiskSphere/providers/user_profile_provider.dart';
import 'package:provider/provider.dart';
import '../../../constants/enums.dart';
import '../../../design_system/components/custom_button.dart';
import '../../../design_system/primitives/app_colors.dart';
import '../../../models/hazard_data.dart';
import '../../../models/my_location_list_model.dart';
import 'package:RiskSphere/providers/my_location_list_provider.dart';

import '../../../providers/custom_tile_providers.dart';
import '../../../providers/custom_tile_providers_main_hazards.dart';
import '../location_profile.dart';
import 'location_details_popup.dart';
import 'package:google_maps_cluster_manager_2/google_maps_cluster_manager_2.dart'
    as cluster_manager;

import 'message_card.dart';

class LocationListMapView extends StatefulWidget {
  final String accountId;
  final String subAccountId;
  // final String accountName;
  // final String subAccountName;
  // final String sovName;

  final String? sovId;

  LocationListMapView(
      {required this.accountId, required this.subAccountId,
        // ,required this.accountName,required this.subAccountName,required this.sovName,
        this.sovId = ""});

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
  bool _isLoading = false; // Tracks if the API or tile loading is in progress
  ScrollController _scrollController = ScrollController();
  TabController? _tabController;

  // New state variables for hazards and Lvendors
  List<HazardData> mainHazards = [];
  String? selectedHazardId;
  String? selectedVendor = "";
  bool isLoadingMainHazards = false;
  MapType _currentMapType = MapType.satellite;
  MapType _currentMapType1 = MapType.normal;
  CustomTileProviderMainHazards? _mainHazardTileProvider;
  bool _isHeatmapMenuOpen = false;

  @override
  void initState() {
    //_loadMarkers();
    _tabController = TabController(length: 2, vsync: this);
    _tabController!.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController!.index;
      });
    });
    _initializeClusterManager();
    _fetchMainHazardLayers();
    //_fetchHazardLayers();
  }

  _fetchMainHazardLayers() async {
    setState(() {
      isLoadingMainHazards = true;
    });
    try {
      var provider =
          Provider.of<MyLocationListProvider>(context, listen: false);
      await provider.fetchMainTileProviders(context);
      print("Main hazard data: ${provider.mainHazardData}");
      if (provider.mainHazardData != null) {
        final hazardsData = provider.mainHazardData?['result'] as List;
        setState(() {
          mainHazards = hazardsData.map((h) => HazardData.fromJson(h)).toList();
          print("mainHazards: $mainHazards");
          // if (mainHazards.isNotEmpty) {
          //   selectedHazardId = mainHazards.first.id;
          //   if (mainHazards.first.vendors.isNotEmpty) {
          selectedVendor = "";
          _changeHazardLayer(selectedHazardId!);
          _changeVendor("");
          //   }
          // }
        });
      }
    } catch (e, stackTrace) {
      print("Error while fetching main hazard layers: $e");
      print(stackTrace);
    } finally {
      setState(() {
        isLoadingMainHazards = false;
      });
    }
  }

  // Modified function to handle hazard selection
  void _changeHazardLayer(String hazardId) {
    setState(() {
      // if heatmap is on, let the current hazard be the main hazard and we will change the heatmap wrt hazard selected from the tile provider
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

  // New function to handle vendor selection
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

  Future<Marker> _markerBuilder(
      cluster_manager.Cluster<MyLocation> cluster) async {
    if (cluster.isMultiple) {
      Color clusterColor = _determineClusterColor(cluster.items.toList());
      return Marker(
        markerId: MarkerId(cluster.getId()),
        position: cluster.location,
        icon: await _getClusterBitmap(125,
            text: cluster.count.toString(), color: clusterColor),
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
        visible:
            _showPins && (_selectedScore == null || _selectedScore == score),
        onTap: () {
          // Navigator.push(
          //     context,
          //     MaterialPageRoute(
          //         builder: (context) => LocationProfile(
          //           accountId: widget.accountId!,
          //           accountName: widget.accountName!,
          //           subAccountId: widget.subAccountId!,
          //           subAccountName: widget.subAccountName!,
          //           sovId: widget.sovId ?? "",
          //           sovName: widget.sovName ?? "",
          //           searchQuery: widget.locationQuery ?? "",
          //           page: (widget.index + 1).toString(),
          //           totalPages: Provider.of<MyLocationListProvider>(context,
          //               listen: false)
          //               .locationHits
          //               .toString(),
          //           hazardProcess: widget.hazardProcess,
          //           onConfirmCallback: widget.getData,
          //           onNavigateBack: widget.onNavigateBack,
          //           tab: 1,
          //         ),
          //     ),
          // );
          // showLocationDetailsPopup(context, location);
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
    int dominantScore =
        colorCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    return _getColorFromScore(dominantScore);
  }

  Color _getColorFromScore(int score) {
    switch (score) {
      case 1:
        return Colors.blue;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.blue;
      case 4:
        return Colors.blue;
      case 5:
        return Colors.blue;
      default:
        return Colors.blue; // Default color
    }
  }

  Future<BitmapDescriptor> _getClusterBitmap(int size,
      {String? text, Color color = Colors.red}) async {
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

  Future<void> _fetchHazardLayers({bool regenerate = false}) async {
    setState(() {
      _isLoading = true; // Start loading
    });

    try {
      var provider =
          Provider.of<MyLocationListProvider>(context, listen: false);

      if (_selectedTabIndex == 1) {
        // Fetch hazard data unconditionally if regenerate is true
        if (regenerate ||
            provider.hazardData == null ||
            provider.hazardData?['heatmap'] == null) {
          print("Fetching hazard data from API...");
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
        } else {
          print("Using cached hazard data.");
        }

        // Process hazard data
        Map<String, dynamic>? data = provider.hazardData;
        if (data == null || data.containsKey('message')) {
          print(
              "Re-fetching due to incomplete hazard data: ${data?['message']}");
          return; // Exit early if the data is incomplete
        }

        final hazards = data['heatmap'];
        if (hazards == null) {
          print("Error: 'heatmap' data is missing in the response.");
          return;
        }

        // Extract reducers
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

        // Debugging outputs
        print("Selected hazard: $_selectedHazard");
        print("Available tile providers: ${_tileProviders.keys}");
      }
    } catch (e) {
      print("Error in _fetchHazardLayers: $e");
    } finally {
      setState(() {
        _isLoading = false; // Stop loading
      });
    }
  }

  void _initializeGeocodingTileProvider(Map<String, dynamic>? data) {
    if (data == null || data.containsKey('message')) return;

    final geocoding = data['GeocodeScore'];
    if (geocoding == null) return;

    _reducers = geocoding.entries.first.value.keys.toList();
    _selectedReducer = _reducers.contains("mean") ? "mean" : _reducers.first;

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
  }

  void _initializeHazardTileProvider(Map<String, dynamic>? data) {
    if (data == null || data.containsKey('message')) return;

    final hazards = data['heatmap'];
    if (hazards == null) return;

    _reducers = hazards.entries.first.value.keys.toList();
    _selectedReducer = _reducers.contains("mean") ? "mean" : _reducers.first;

    setState(() {
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
      _isInitialized = true;
      _selectedHazard = _tileProviders.keys.first;
    });
  }

  void _toggleHeatmap() async {
    setState(() {
      // switch off pins if heatmap is on

      _isHeatmapOn = !_isHeatmapOn;
      _isLoading = true;
      if (!_isHeatmapOn) {
        if (_showPins) {
          print("test");
          _togglePinVisibility();
        }
      } else {
        print("hazard is off");
      }
      // Start loading
    });
    if (!_isHeatmapOn) {
      // Clear tile overlays by setting _selectedHazard to null
      setState(() {
        _selectedHazard = null;
        _isLoading = false; // Stop loading when clearing
      });
    } else {
      if (_isInitialized) {
        // Restore the selected hazard and reducer
        setState(() {
          _selectedHazard = _selectedHazard ?? _tileProviders.keys.first;
          _tileProviders[_selectedHazard]
              ?.updateReducer(_selectedReducer ?? "mean");
          _isLoading = false; // Stop loading
        });
      } else {
        // Fetch hazard layers if not initialized yet
        try {
          await _fetchHazardLayers();
        } catch (e) {
          print("Error while fetching hazard layers: $e");
        } finally {
          setState(() {
            _isLoading = false; // Stop loading
          });
        }
      }
    }
  }

  void _onReducerChanged(String? newReducer) {
    print('Tile Providers: $_tileProviders');
    print("Reducer change initiated. New reducer: $newReducer");

    setState(() {
      _selectedReducer = newReducer;
      print("Updated _selectedReducer: $_selectedReducer");

      if (_selectedHazard != null && newReducer != null) {
        print("Valid hazard and reducer found. Updating tile provider.");

        // Update the tile provider with the selected reducer
        _tileProviders[_selectedHazard]?.updateReducer(newReducer);
        print(
            "Tile provider for hazard $_selectedHazard updated with reducer $newReducer");

        // Temporarily clear tile overlays to trigger refresh
        print("Clearing _selectedHazard temporarily to refresh tile overlays.");
        _selectedHazard = "";
      } else {
        print(
            "Either _selectedHazard or newReducer is null. Skipping tile provider update.");
      }
    });

    // Reapply the selected hazard with a delay to ensure the refresh
    Future.delayed(Duration(milliseconds: 100), () {
      setState(() {
        _selectedHazard = _tileProviders.keys.firstWhere(
            (key) => key.isNotEmpty && key == _selectedHazard,
            orElse: () => _tileProviders.keys.first);
        print("Reapplied _selectedHazard: $_selectedHazard");
      });
    });
  }

  /* void _changeHazardLayer(String hazard) {
      setState(() => _selectedHazard = hazard);
    }
*/

  // Modified build method for the hazard and vendor dropdowns
  Widget _buildHazardControls() {
    var typography = CustomTypography(context);

    // Show loading spinner if the main hazards are loading
    if (isLoadingMainHazards) {
      return Positioned(
        bottom: 16,
        left: 16,
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
      if (!(_selectedTabIndex == 2 || _selectedTabIndex == 1) ||
          mainHazards.isEmpty) {
        return SizedBox();
      }

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
        _selectedScore =
            null; // Show all scores if tapped on selected score again
      } else {
        _selectedScore = score;
      }
    });

    // Filter locations based on selected score and update ClusterManager
    clusterManager.setItems(
      Provider.of<MyLocationListProvider>(context, listen: false)
          .fullLocationList
          .where((location) =>
              _selectedScore == null ||
              location.finalAddress?.score == _selectedScore)
          .toList(),
    );
  }

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
  Widget build(BuildContext context) {
    var typography = CustomTypography(context);
    return Consumer<MyLocationListProvider>(
        builder: (context, myLocationProvider, child) {
      return Column(
        children: [
          // Heatmap Generation Button
          /*_tileProviders.isEmpty && */
          /*!myLocationProvider.isHeatMapGeneratingLive
                  ?
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child:
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _isLoading?Center(child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.1,
                          child: CircularProgressIndicator()),
                    )):
                    CustomButton(
                      type: ButtonType.elevated,
                      onPressed: _isLoading? null: () async {
                        print("Generating heatmap");
                        await _fetchHazardLayers(
                          regenerate: true,
                        ); // Call to generate the heatmap
                       */ /* setState(() {
                          _isHeatmapOn = true; // Enable the heatmap view
                        });*/ /*
                      }, child: Text('Update Heatmap', style: typography.ButtonLarge.copyWith(color: Colors.black,),),
                    ),
                  ],
                ),
              ): SizedBox(),*/
          SizedBox(height: 8),
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
                        // Tab(text: 'Occupancy'),
                        // Tab(text: 'Construction'),
                      ],
                    ),
                  ),
                ),
                // Right arrow button
                // IconButton(
                //   icon: Icon(Icons.arrow_right, color: Colors.grey),
                //   onPressed: _scrollRight,
                // ),
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
                      target: LatLng(38.7946, 106.5348),
                      zoom: -100.0,
                    ),
                    zoomControlsEnabled: false,
                    myLocationEnabled: true,
                    markers: (!_isHeatmapOn && _showPins) ? _markers : {},
                    mapType: _selectedTabIndex == 0
                        ? _currentMapType
                        : _currentMapType1,
                    onMapCreated: (GoogleMapController controller) {
                      mapController = controller;
                      clusterManager.setMapId(
                          controller.mapId); // Set map ID for ClusterManager
                      mapController.setMapStyle(_mapStyle);
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
                    onCameraMove: clusterManager.onCameraMove,
                    // Update clusters on camera move
                    onCameraIdle: clusterManager
                        .updateMap, // Update clusters when camera stops
                  ),

                  _selectedTabIndex == 1
                      ? _buildHazardControls()
                      : Positioned(
                          bottom: 20,
                          left: 16,
                          child: Container(
                            margin: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.brightness ==
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
                                        MapType.terrain
                                      ];

                                      // Get the next index in the list
                                      int currentIndex =
                                          mapTypes.indexOf(_currentMapType);
                                      int nextIndex =
                                          (currentIndex + 1) % mapTypes.length;

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
                      right: 16,
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
                                      Text(
                                        'Locations',
                                        style: typography.InputLabel.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Container(
                                        height: 24,
                                        width: 48,
                                        child: Switch(
                                          value: _showPins,
                                          // onChanged: (value) {
                                          onChanged: _isHeatmapMenuOpen
                                              ? null
                                              : (value) {
                                                  print(value);
                                                  // if (_isHeatmapOn) {
                                                  print("object");
                                                  _togglePinVisibility();
                                                  // }
                                                },
                                          activeColor: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          activeTrackColor: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withOpacity(0.5),
                                          inactiveThumbColor: Theme.of(context)
                                              .colorScheme
                                              .surface,
                                          inactiveTrackColor: Theme.of(context)
                                              .colorScheme
                                              .surface
                                              .withOpacity(0.5),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      _selectedTabIndex == 1
                                          ? MenuAnchor(
                                              builder:
                                                  (context, controller, child) {
                                                return InkWell(
                                                  onTap: () {
                                                    var userProfileProvider =
                                                        Provider.of<
                                                                UserProfileProvider>(
                                                            context,
                                                            listen: false);
                                                    final trialStatus =
                                                        userProfileProvider
                                                                    .trialInfo[
                                                                'status'] ??
                                                            '';
                                                    final trialSubdestinations =
                                                        userProfileProvider
                                                                    .trialInfo[
                                                                'subDestinations'] ??
                                                            0;
                                                    if (trialStatus != '') {
                                                      showDialog(
                                                        context: context,
                                                        barrierColor: Theme.of(
                                                                context)
                                                            .colorScheme
                                                            .surfaceContainerLowest,
                                                        builder: (BuildContext
                                                            context) {
                                                          return Column(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            children: [
                                                              Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .end,
                                                                children: [
                                                                  IconButton(
                                                                    icon: Icon(Icons
                                                                        .close),
                                                                    onPressed:
                                                                        () {
                                                                      Navigator.of(
                                                                              context)
                                                                          .pop();
                                                                    },
                                                                  ),
                                                                ],
                                                              ),
                                                              MessageCard(
                                                                isUpgrade: true,
                                                                messageTextSpans: [
                                                                  TextSpan(
                                                                    text:
                                                                        'Upgrade your account to generate heat map!',
                                                                    style: CustomTypography(
                                                                            context)
                                                                        .Body1,
                                                                  ),
                                                                ],
                                                              ),
                                                            ],
                                                          );
                                                        },
                                                      );
                                                      return;
                                                    }
                                                    if (_isLoading ||
                                                        Provider.of<MyLocationListProvider>(
                                                                context,
                                                                listen: false)
                                                            .isHeatMapGeneratingLive) {
                                                      // Prevent opening the menu if loading or heatmap is being generated
                                                      return;
                                                    }
                                                    if (_reducers.isEmpty) {
                                                      // Old implementation: Toggle heatmap directly if no reducers
                                                      _toggleHeatmap();
                                                    } else {
                                                      // Show the menu if reducers are available
                                                      if (controller.isOpen) {
                                                        controller.close();
                                                      } else {
                                                        controller.open();
                                                      }
                                                    }
                                                  },
                                                  child: Container(
                                                    height: 34,
                                                    width: 34,
                                                    padding: EdgeInsets.all(4),
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                      shape: BoxShape.rectangle,
                                                      color: _isHeatmapOn
                                                          ? Colors.orange
                                                              .withOpacity(0.8)
                                                          : Theme.of(context)
                                                              .colorScheme
                                                              .surface,
                                                    ),
                                                    child: _isLoading ||
                                                            Provider.of<MyLocationListProvider>(
                                                                    context,
                                                                    listen:
                                                                        false)
                                                                .isHeatMapGeneratingLive
                                                        ? Center(
                                                            child: SizedBox(
                                                              height: 20,
                                                              width: 20,
                                                              child:
                                                                  CircularProgressIndicator(
                                                                strokeWidth: 2,
                                                                valueColor:
                                                                    AlwaysStoppedAnimation<
                                                                        Color>(
                                                                  Theme.of(
                                                                          context)
                                                                      .colorScheme
                                                                      .primary,
                                                                ),
                                                              ),
                                                            ),
                                                          )
                                                        : SvgPicture.asset(
                                                            'assets/images/heatmap_icon.svg',
                                                            color: _isHeatmapOn
                                                                ? Colors.white
                                                                : Theme.of(
                                                                        context)
                                                                    .colorScheme
                                                                    .onSurface,
                                                          ),
                                                  ),
                                                );
                                              },
                                              menuChildren: !_isLoading &&
                                                      !Provider.of<
                                                                  MyLocationListProvider>(
                                                              context,
                                                              listen: false)
                                                          .isHeatMapGeneratingLive
                                                  ? [
                                                      // Update Heatmap Button
                                                      MenuItemButton(
                                                        child: Text(
                                                          "Update Heatmap",
                                                          style: typography
                                                              .InputLabel,
                                                        ),
                                                        onPressed: () async {
                                                          print(
                                                              "Updating heatmap...");
                                                          await _fetchHazardLayers(
                                                              regenerate: true);
                                                        },
                                                      ),
                                                      Divider(
                                                          height: 1,
                                                          thickness: 1),
                                                      // "Switch off Heatmap" option when heatmap is on
                                                      if (_isHeatmapOn)
                                                        MenuItemButton(
                                                          child: Text(
                                                              "Switch off Heatmap",
                                                              style: typography
                                                                  .InputLabel),
                                                          onPressed: () {
                                                            _toggleHeatmap(); // Turn off the heatmap
                                                          },
                                                        ),
                                                      if (_isHeatmapOn)
                                                        Divider(
                                                            height: 1,
                                                            thickness: 1),
                                                      // List of reducers
                                                      ..._reducers
                                                          .map((reducer) {
                                                        return MenuItemButton(
                                                          child: Text(reducer,
                                                              style: typography
                                                                  .InputLabel),
                                                          onPressed: () {
                                                            if (!_isHeatmapOn) {
                                                              // Automatically turn on the heatmap if it's off
                                                              _toggleHeatmap();
                                                            }
                                                            _onReducerChanged(
                                                                reducer); // Set the selected reducer
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
                          : Container()),
                ],
              ),
            ),
          ),
          // Score filter tray below the map with rounded corners
          if (_selectedTabIndex == 0) ...[
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
          ],
          SizedBox(height: 16),
        ],
      );
    });
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
          riskScore: location.hazard?['Overall']?.rating ?? 0,
          dataCompleteness: scoreToStar( location.dataCompleteness),
          //location.riskScore ?? 0,
          hazards: location.hazard ?? {},
          geocodedAt: [location.finalAddress?.locationType ?? ""],
          occupancy: location.finalAddress?.placeTypes ?? ["--"],
          campus: location.finalAddress?.campusId,
          accountId: location.finalAddress?.accountId,
          accountName: location.finalAddress?.accountName,
          subAccountId: location.finalAddress?.subAccountId,
          subAccountName: location.finalAddress?.subAccountName,
          sovId: location.finalAddress?.sovId,
          sovName: location.finalAddress?.sovName,
          rented: location.finalAddress?.rented ?? false,
        );
      },
    );
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