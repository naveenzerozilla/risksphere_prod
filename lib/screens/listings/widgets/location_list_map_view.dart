import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:RiskSphere/design_system/primitives/custom_typography.dart';
import 'package:RiskSphere/providers/user_profile_provider.dart';
import 'package:provider/provider.dart';
import '../../../constants/configuration.dart';
import '../../../design_system/primitives/app_colors.dart';
import '../../../models/hazard_data.dart';
import '../../../models/my_location_list_model.dart';
import 'package:RiskSphere/providers/my_location_list_provider.dart';
import '../../../providers/custom_tile_providers.dart';
import '../../../providers/custom_tile_providers_main_hazards.dart';
import '../../../service/api_service.dart';
import '../../../service/language_service.dart';
import '../../../service/shared_preference_service.dart';
import '../../../utils/api_constants.dart';
import '../../../utils/common_headers.dart';
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
  bool _isLoading = false;
  TabController? _tabController;
  String? datasetID = "1";

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
  bool _locationsLoaded = false;
  bool _firstAttachDone = false;

  List<MyLocation> _allDatasetLocations = []; // full unfiltered list
  List<MyLocation> _filteredLocations = []; // filtered by subAccountId
  String? _activeSubAccountFilter; // null = show ALL

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 2, vsync: this);
    _tabController!.addListener(() {
      setState(() => _selectedTabIndex = _tabController!.index);
    });
    clusterManager = cluster_manager.ClusterManager<MyLocation>(
      _filteredLocations,
      _updateMarkers,
      markerBuilder: _markerBuilder,
      levels: const [
        1,
        4,
        7,
        10,
        13,
        16,
        18,
      ],
      stopClusteringZoom: 18,
      extraPercent: 0.2,
    );
    // clusterManager = cluster_manager.ClusterManager<MyLocation>(
    //   [],
    //   _updateMarkers,
    //   markerBuilder: _markerBuilder,
    //   levels: [
    //     1,
    //     5,
    //     10,
    //     15,
    //     20,
    //   ],
    //   stopClusteringZoom: 16,
    // );

    _initializeClusterManager();
    _fetchMainHazardLayers();

    // Load dataset ID first, then download the dataset.
    _initialize();
  }

  Future<void> _initialize() async {
    await getdata();

    debugPrint("Dataset ID Loaded: $datasetID");

    if (datasetID != null && datasetID!.isNotEmpty && datasetID != "1" && datasetID != "null") {
      await loadDatasetLocations();
    } else {
      debugPrint("Invalid Dataset ID: $datasetID");
    }
  }

  Future<void> getdata() async {
    if (!mounted) return;

    String? datasetIdd = await SharedPreferenceService.getDefaultDatasetID();
    setState(() {
      datasetID = (datasetIdd != null && datasetIdd != "null") ? datasetIdd : null;
    });
    print("DatasetId => $datasetID");
  }

  void _applySubAccountFilter() {
    if (_activeSubAccountFilter == null || _activeSubAccountFilter!.isEmpty) {
      _filteredLocations = List.from(_allDatasetLocations);
    } else {
      _filteredLocations = _allDatasetLocations
          .where((loc) =>
              loc.finalAddress?.subAccountId == _activeSubAccountFilter)
          .toList();
    }
    if (_mapReady) {
      clusterManager.setItems(_filteredLocations);

      if (_filteredLocations.isNotEmpty && !_firstAttachDone) {
        _moveCameraToLatLng(_filteredLocations.first.location);
        _firstAttachDone = true;
      }
    }

    debugPrint(
        " Filter '$_activeSubAccountFilter' → ${_filteredLocations.length} locations");
  }

  Future<String?> getGoogleAccessToken() async {
    try {
      var headers = await CommonHeaders.createHeaders();

      log(headers.toString());

      final uri = Uri.parse(AppConstant.GET_GOOGLE_TOKEN);

      final response = await http.get(
        uri,
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final token = data['token']?.toString();

        debugPrint("Google Token: $token");

        return token;
      } else {
        debugPrint("Token API failed: ${response.statusCode} ${response.body}");
        return null;
      }
    } on BackendException catch (e, stackTrace) {
      debugPrint(stackTrace.toString());
      debugPrint(e.message);
      return null;
    } catch (e, stackTrace) {
      debugPrint(stackTrace.toString());
      debugPrint("getGoogleAccessToken error: $e");
      return null;
    }
  }

  Future<void> loadDatasetLocations() async {
    final projectId = Configuration.projectId;

    final googleAccessToken = await getGoogleAccessToken();

    if (googleAccessToken == null || googleAccessToken.isEmpty) {
      debugPrint(" Failed to get Google access token.");
      return;
    }

    try {
      final downloadResponse = await http.get(
        Uri.parse(
          "https://mapsplatformdatasets.googleapis.com/download/v1/projects/$projectId/datasets/$datasetID:download?alt=media",
        ),
        headers: {
          "Authorization": "Bearer $googleAccessToken",
          "X-Goog-User-Project": projectId,
        },
      );

      if (downloadResponse.statusCode != 200) {
        debugPrint(
            " Download failed ${downloadResponse.statusCode}: ${downloadResponse.body}");

        if (mounted) {
          setState(() => _locationsLoaded = true);
        }
        return;
      }

      final geoJson = jsonDecode(downloadResponse.body);

      final features = geoJson['features'] as List? ?? [];

      debugPrint(" Features in dataset: ${features.length}");

      final List<MyLocation> allLocations = [];

      final String selectedSubAccountId = widget.subAccountId;

      for (final feature in features) {
        final geometry = feature['geometry'];
        final props = feature['properties'] as Map<String, dynamic>? ?? {};

        if (geometry?['type'] != 'Point') continue;

        final coords = geometry['coordinates'] as List;

        final lng = (coords[0] as num).toDouble();
        final lat = (coords[1] as num).toDouble();

        if (lat == 0.0 || lng == 0.0) {
          debugPrint("️ Skipping invalid location");
          continue;
        }

        final locationId = props['location_id']?.toString() ?? '';
        final address = props['address']?.toString() ?? '';
        final city = props['city']?.toString() ?? '';
        final overallScore = props['overall_score'] ?? 0;
        final subAccountId = props['sub_account_id']?.toString() ?? '';

        debugPrint(
            "Dataset SubAccount: $subAccountId | Selected: $selectedSubAccountId");

        // Filter based on selected Sub Account Id
        if (selectedSubAccountId.isNotEmpty &&
            subAccountId != selectedSubAccountId) {
          continue;
        }

        allLocations.add(
          MyLocation(
            id: locationId,
            latitude: lat,
            longitude: lng,
            location: LatLng(lat, lng),
            finalAddress: FinalAddress(
              address: "$address, $city",
              score: (overallScore as num).toInt(),
              subAccountId: subAccountId,
              latitude: lat,
              longitude: lng,
            ),
          ),
        );
      }

      if (!mounted) return;

      setState(() {
        _allDatasetLocations = allLocations;
        _activeSubAccountFilter = selectedSubAccountId;
        _filteredLocations = List.from(allLocations);
        _locationsLoaded = true;
      });

      await Future.delayed(const Duration(milliseconds: 300));

      if (_mapReady && _filteredLocations.isNotEmpty) {
        clusterManager.setItems(_filteredLocations);

        if (!_firstAttachDone) {
          await _zoomToAllLocations();

          setState(() {
            _firstAttachDone = true;
          });
        }
      }

      debugPrint(" Final Marker Count: ${_filteredLocations.length}");
    } catch (e, stackTrace) {
      debugPrint(" loadDatasetLocations error: $e");
      debugPrint(stackTrace.toString());

      if (mounted) {
        setState(() => _locationsLoaded = true);
      }
    }
  }

  void _moveCameraToLatLng(LatLng target) {
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: target,
          zoom: 18,
        ),
      ),
    );
  }

  Future<void> _zoomToAllLocations() async {
    if (_filteredLocations.isEmpty) return;

    double minLat = _filteredLocations.first.location.latitude;
    double maxLat = _filteredLocations.first.location.latitude;
    double minLng = _filteredLocations.first.location.longitude;
    double maxLng = _filteredLocations.first.location.longitude;

    for (final loc in _filteredLocations) {
      minLat = minLat < loc.location.latitude ? minLat : loc.location.latitude;

      maxLat = maxLat > loc.location.latitude ? maxLat : loc.location.latitude;

      minLng =
          minLng < loc.location.longitude ? minLng : loc.location.longitude;

      maxLng =
          maxLng > loc.location.longitude ? maxLng : loc.location.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    mapController.animateCamera(
      CameraUpdate.newLatLngBounds(
        bounds,
        112,
      ),
    );
  }

  void _initializeClusterManager() {
    final allLocations =
        Provider.of<MyLocationListProvider>(context, listen: false)
            .fullLocationList;
    clusterManager = cluster_manager.ClusterManager<MyLocation>(
      _filteredLocations,
      _updateMarkers,
      markerBuilder: _markerBuilder,
      levels: const [
        1,
        4,
        7,
        10,
        13,
        16,
        18,
      ],
      stopClusteringZoom: 18,
      extraPercent: 0.2,
    );
  }

  Future<Marker> _markerBuilder(
      cluster_manager.Cluster<MyLocation> cluster) async {
    if (cluster.isMultiple) {
      debugPrint(
        " Building marker. Cluster=${cluster.isMultiple} Count=${cluster.count}",
      );
      return Marker(
        markerId: MarkerId(cluster.getId()),
        position: cluster.location,
        icon: await _getClusterBitmap(125, text: cluster.count.toString()),
      );
    }

    final location = cluster.items.first;
    final isCurrent = _filteredLocations.isNotEmpty &&
        _currentLocationIndex < _filteredLocations.length &&
        location.id == _filteredLocations[_currentLocationIndex].id;
    final score = location.finalAddress?.score ?? 0;

    double hue;

    switch (score) {
      case 1:
        hue = BitmapDescriptor.hueRed;
        break;
      case 2:
        hue = BitmapDescriptor.hueOrange;
        break;
      case 3:
        hue = BitmapDescriptor.hueYellow;
        break;
      case 4:
        hue = BitmapDescriptor.hueGreen;
        break;
      case 5:
        hue = BitmapDescriptor.hueAzure;
        break;
      default:
        hue = BitmapDescriptor.hueBlue;
    }

    return Marker(
      markerId: MarkerId(location.id ?? ''),
      position: location.location,
      icon: BitmapDescriptor.defaultMarkerWithHue(
        isCurrent ? BitmapDescriptor.hueRed : hue,
      ),
      onTap: () async {
        setState(() {
          _focusedLocation = location.location;
          is3DView = false;
        });

        await mapController.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: location.location,
              zoom: 20.5,
              tilt: 0,
              bearing: 0,
            ),
          ),
        );

        await _showLocationPopup(
          context,
          location.id!,
        );
      },
    );
  }

  Future<void> _showLocationPopup(
    BuildContext context,
    String locationId,
  ) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final response = await getLocationDetails(locationId);

      // Close loader FIRST
      Navigator.of(context).pop();

      if (response != null) {
        showLocationDetailsPopup(
          context,
          response["result"],
        );
      }
    } catch (e) {
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<Map<String, dynamic>?> getLocationDetails(
    String locationId,
  ) async {
    try {
      var headers = await CommonHeaders.createHeaders();

      log(headers.toString());

      final uri = Uri.parse(
        "${AppConstant.GET_LOCATION_DETAILS}?location_id=$locationId",
      );

      final response = await http.get(
        uri,
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        debugPrint("Location Details => $data");

        return data;
      } else {
        debugPrint(
          "Location API failed: ${response.statusCode} ${response.body}",
        );
        return null;
      }
    } on BackendException catch (e, stackTrace) {
      debugPrint(stackTrace.toString());
      debugPrint(e.message);
      return null;
    } catch (e, stackTrace) {
      debugPrint(stackTrace.toString());
      debugPrint("getLocationDetails error: $e");
      return null;
    }
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
    debugPrint(" Markers Received: ${markers.length}");

    for (final marker in markers) {
      debugPrint(
        " Marker: ${marker.markerId.value}",
      );
    }

    if (!mounted) return;

    setState(() {
      _markers = markers;
    });
  }

  Color _getColorFromScore(int score) {
    switch (score) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.deepOrange;
      case 3:
        return Colors.yellow;
      case 4:
        return Colors.lightGreen;
      case 5:
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  final String _mapStyle = '''[
    {"elementType":"geometry","stylers":[{"color":"#f5f5f5"}]},
    {"elementType":"labels.icon","stylers":[{"visibility":"off"}]},
    {"elementType":"labels.text.fill","stylers":[{"color":"#616161"}]},
    {"elementType":"labels.text.stroke","stylers":[{"color":"#f5f5f5"}]},
    {"featureType":"administrative","elementType":"geometry.stroke","stylers":[{"visibility":"on"},{"color":"#a0a0a0"},{"weight":1}]},
    {"featureType":"water","elementType":"geometry","stylers":[{"color":"#c9c9c9"}]},
    {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#9e9e9e"}]}
  ]''';

  bool is3DView = false;
  LatLng? _focusedLocation;
  LatLng _currentCenter = LatLng(20.5937, 78.9629);

  _fetchMainHazardLayers() async {
    setState(() => isLoadingMainHazards = true);
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
          if (selectedHazardId != null) _changeHazardLayer(selectedHazardId!);
          _changeVendor("");
        });
      }
    } catch (e) {
      debugPrint("Error fetching main hazard layers: $e");
    } finally {
      if (mounted) setState(() => isLoadingMainHazards = false);
    }
  }

  void _changeHazardLayer(String hazardId) {
    setState(() {
      if (_isHeatmapOn) {
        _selectedHazard = hazardId;
      } else {
        selectedHazardId = hazardId;
        final hazard = mainHazards.firstWhere((h) => h.id == hazardId);
        selectedVendor =
            hazard.vendors.isNotEmpty ? hazard.vendors.first.name : null;
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
    setState(() => _isLoading = true);
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
              widget.sovId);
        }
        Map<String, dynamic>? data = provider.hazardData;
        if (data == null || data.containsKey('message')) return;
        final hazards = data['heatmap'];
        if (hazards == null) return;
        if (hazards.isNotEmpty) {
          _reducers = hazards.entries.first.value.keys.toList();
          _selectedReducer =
              _reducers.contains("mean") ? "mean" : _reducers.first;
        }
        hazards.forEach((hazard, urls) {
          Map<String, Map<int, String>> intensityMap = {};
          urls.forEach((intensity, zoomUrls) {
            Map<int, String> zoomLevelUrls = {};
            zoomUrls
                .forEach((zoom, url) => zoomLevelUrls[int.parse(zoom)] = url);
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
      debugPrint("Error in _fetchHazardLayers: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toggleHeatmap() async {
    setState(() {
      _isHeatmapOn = !_isHeatmapOn;
      _isLoading = true;
      if (!_isHeatmapOn && _showPins) _togglePinVisibility();
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
          debugPrint("Error toggling heatmap: $e");
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      }
    }
  }

  void _onReducerChanged(String? newReducer) {
    setState(() {
      _selectedReducer = newReducer;
      if (_selectedHazard != null && newReducer != null) {
        _tileProviders[_selectedHazard]?.updateReducer(newReducer);
        _selectedHazard = "";
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

  Future<void> _zoomToLocation(int index) async {
    if (_filteredLocations.isEmpty) return;
    if (index < 0 || index >= _filteredLocations.length) return;

    setState(() {
      _isAnimating = true;
      _currentLocationIndex = index;
    });

    final location = _filteredLocations[index];

    await mapController.animateCamera(
      CameraUpdate.newCameraPosition(CameraPosition(
        target: location.location,
        zoom: 20.5, // or 20
        tilt: 0,
        bearing: 0,
      )),
    );

    // Don't recreate cluster items.
    clusterManager.updateMap();

    setState(() {
      _isAnimating = false;
    });
  }

  void _togglePinVisibility() {
    setState(() => _showPins = !_showPins);
    clusterManager.setItems(
      _filteredLocations
          .where(
              (loc) => _showPins || loc.finalAddress?.score == _selectedScore)
          .toList(),
    );
  }

  void _filterPins() {
    List<MyLocation> filteredLocations;

    if (_selectedScore == null) {
      filteredLocations = List.from(_filteredLocations);
    } else {
      filteredLocations = _filteredLocations.where((location) {
        return location.finalAddress?.score == _selectedScore;
      }).toList();
    }

    clusterManager.setItems(filteredLocations);
    clusterManager.updateMap();
  }

  Future<void> _toggle2D3DView() async {
    final LatLng target = _focusedLocation ?? _currentCenter;
    final zoom = await mapController.getZoomLevel();
    await mapController.animateCamera(
      CameraUpdate.newCameraPosition(CameraPosition(
        target: target,
        zoom: zoom,
        tilt: is3DView ? 0 : 60,
        bearing: is3DView ? 0 : 45,
      )),
    );
    setState(() => is3DView = !is3DView);
  }


  @override
  Widget build(BuildContext context) {
    var typography = CustomTypography(context);

    if (!_locationsLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    final currentLocation = (_filteredLocations.isNotEmpty &&
            _currentLocationIndex >= 0 &&
            _currentLocationIndex < _filteredLocations.length)
        ? _filteredLocations[_currentLocationIndex]
        : null;

    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
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
              Tab(text: LanguageService.getTranslated(context, "geocoding")),
              Tab(text: LanguageService.getTranslated(context, "hazard_score")),
            ],
          ),
        ),

        // if (_filteredLocations.isNotEmpty)
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  GoogleMap(
                    cloudMapId: Platform.isAndroid
                        ? "df78fbd8e414bf264398784a"
                        : "df78fbd8e414bf269a617fe7",
                    initialCameraPosition: const CameraPosition(
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
                      _mapReady = true;
                      clusterManager.setMapId(controller.mapId);
                      clusterManager.setItems(_filteredLocations);
                      clusterManager.updateMap();
                      Future.delayed(const Duration(seconds: 1), () {
                        debugPrint(" Locations: ${_filteredLocations.length}");
                        if (!mounted) return;
                        if (_locationsLoaded && _filteredLocations.isNotEmpty) {
                          clusterManager.setItems(_filteredLocations);
                          if (!_firstAttachDone) {
                            _moveCameraToLatLng(
                                _filteredLocations.first.location);
                            setState(() => _firstAttachDone = true);
                          }
                        }
                      });
                    },

                    tileOverlays: _selectedTabIndex == 0
                        ? {}
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
                    onCameraMove: (position) {
                      _currentCenter = position.target;
                      clusterManager.onCameraMove(position);
                    },

                    onCameraIdle: () {
                      clusterManager.updateMap();
                    },
                    // onCameraIdle: clusterManager.updateMap,
                  ),

                  // 2D/3D toggle
                  Positioned(
                    bottom: 70,
                    right: 8,
                    child: InkWell(
                      onTap: _toggle2D3DView,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 6,
                                offset: const Offset(0, 3))
                          ],
                        ),
                        child: Text(
                          is3DView ? "3D" : "2D",
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black),
                        ),
                      ),
                    ),
                  ),

                  // Layer / hazard controls
                  _selectedTabIndex == 1
                      ? _buildHazardControls()
                      : Positioned(
                          bottom: 20,
                          left: 10,
                          child: Container(
                            margin: const EdgeInsets.all(12),
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
                                    offset: const Offset(0, 5))
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
                                      List<MapType> mapTypes = [
                                        MapType.normal,
                                        MapType.satellite,
                                        MapType.terrain,
                                        MapType.hybrid
                                      ];
                                      int currentIndex =
                                          mapTypes.indexOf(_currentMapType);
                                      _currentMapType = mapTypes[
                                          (currentIndex + 1) % mapTypes.length];
                                    });
                                  },
                                  child: Icon(Icons.layers,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface),
                                  tooltip: 'Change Map Type',
                                ),
                                const SizedBox(width: 8),
                              ],
                            ),
                          ),
                        ),

                  // Heatmap toggle (tab 1)
                  Positioned(
                    top: 16,
                    right: 10,
                    child: _selectedTabIndex == 1
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness ==
                                      Brightness.light
                                  ? AppColors.paperElavation25Light
                                  : AppColors.paperElavation25,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: MenuAnchor(
                              builder: (context, controller, child) {
                                return InkWell(
                                  onTap: () async {
                                    setState(() => _isLoading = true);
                                    Future.delayed(const Duration(seconds: 5),
                                        () {
                                      if (mounted)
                                        setState(() => _isLoading = false);
                                    });
                                  },
                                  child: Container(
                                    height: 31,
                                    width: 34,
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: _isHeatmapOn
                                          ? Colors.grey.withOpacity(0.8)
                                          : Theme.of(context)
                                              .colorScheme
                                              .surface,
                                    ),
                                    child: _isLoading
                                        ? const Center(
                                            child: SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(Colors.orange),
                                              ),
                                            ),
                                          )
                                        : SvgPicture.asset(
                                            'assets/images/heatmap_icon.svg',
                                            color: _isHeatmapOn
                                                ? Colors.white
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .onSurface,
                                          ),
                                  ),
                                );
                              },
                              menuChildren: !_isLoading &&
                                      !Provider.of<MyLocationListProvider>(
                                              context,
                                              listen: false)
                                          .isHeatMapGeneratingLive
                                  ? [
                                      MenuItemButton(
                                        child: Text("Update Heatmap",
                                            style: typography.InputLabel),
                                        onPressed: () async =>
                                            await _fetchHazardLayers(
                                                regenerate: true),
                                      ),
                                      const Divider(height: 1, thickness: 1),
                                      if (_isHeatmapOn)
                                        MenuItemButton(
                                          child: Text("Switch off Heatmap",
                                              style: typography.InputLabel),
                                          onPressed: _toggleHeatmap,
                                        ),
                                      if (_isHeatmapOn)
                                        const Divider(height: 1, thickness: 1),
                                      ..._reducers.map((reducer) {
                                        return MenuItemButton(
                                          child: Text(reducer,
                                              style: typography.InputLabel),
                                          onPressed: () {
                                            if (!_isHeatmapOn) _toggleHeatmap();
                                            _onReducerChanged(reducer);
                                          },
                                        );
                                      }).toList(),
                                    ]
                                  : [],
                            ),
                          )
                        : const SizedBox(),
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 8),

        if (currentLocation != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "(${_currentLocationIndex + 1}/${_filteredLocations.length})",
                  style: typography.Subtitle2.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.white30,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currentLocation.finalAddress?.address ?? "Unknown location",
                  maxLines: 2,
                  style: typography.Subtitle2.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        color: _currentLocationIndex > 0
                            ? AppColors.primaryMain
                            : Colors.grey,
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
                          await _zoomToLocation(_currentLocationIndex - 1);
                          setState(() => _isAnimating = false);
                        }
                      : null,
                  child: _isAnimating && _currentLocationIndex > 0
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          LanguageService.getTranslated(context, "previous"),
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
                      side: const BorderSide(color: AppColors.primaryMain),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 22),
                    backgroundColor:
                        _currentLocationIndex < _filteredLocations.length - 1
                            ? AppColors.primaryMain
                            : Colors.grey[300],
                  ),
                  onPressed:
                      _currentLocationIndex < _filteredLocations.length - 1 &&
                              !_isAnimating
                          ? () async {
                              setState(() => _isAnimating = true);
                              await _zoomToLocation(_currentLocationIndex + 1);
                              setState(() => _isAnimating = false);
                            }
                          : null,
                  child: _isAnimating &&
                          _currentLocationIndex < _filteredLocations.length - 1
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          LanguageService.getTranslated(context, "next"),
                          style: typography.ButtonLarge.copyWith(
                            color: _currentLocationIndex <
                                    _filteredLocations.length - 1
                                ? AppColors.black
                                : Colors.grey,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildHazardControls() {
    var typography = CustomTypography(context);

    if (isLoadingMainHazards) {
      return Positioned(
        bottom: 2,
        left: 11,
        child: Container(
          width: 45,
          height: 45,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.light
                ? AppColors.paperElavation25Light
                : AppColors.paperElavation25,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (!_isHeatmapOn || _isLoading) {
      return Positioned(
        bottom: 16,
        left: 16,
        child: Container(
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
                    setState(() => _isHeatmapMenuOpen = false);
                  } else {
                    controller.open();
                    setState(() => _isHeatmapMenuOpen = true);
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
                constraints: const BoxConstraints(maxHeight: 200),
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
                              _changeHazardLayer(hazard.id);
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

    return Positioned(
      bottom: 16,
      left: 16,
      child: Container(
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
              constraints: const BoxConstraints(maxHeight: 200),
              child: SingleChildScrollView(
                child: Column(
                  children: _tileProviders.keys.map((hazard) {
                    return MenuItemButton(
                      child: Text(hazard, style: typography.InputLabel),
                      onPressed: () => setState(() => _selectedHazard = hazard),
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

  void showLocationDetailsPopup(
    BuildContext context,
    Map<String, dynamic> location,
  ) {
    final finalAddress =
        location["final_address"] as Map<String, dynamic>? ?? {};

    final hazard = location["hazard"] as Map<String, dynamic>? ?? {};

    final overallHazard = hazard["Overall"] as Map<String, dynamic>? ?? {};

    final List<String> occupancy = (finalAddress["place_types"] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        ["--"];

    final List<String> geocodedAt = [
      finalAddress["location_type"]?.toString() ?? "--"
    ];

    final String? sovIdValue = (() {
      final sovId = finalAddress["sov_id"];

      if (sovId is List && sovId.isNotEmpty) {
        return sovId.first.toString();
      }

      if (sovId != null) {
        return sovId.toString();
      }

      return null;
    })();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return LocationDetailsPopup(
          lat: finalAddress["latitude"]?.toString(),
          long: finalAddress["longitude"]?.toString(),
          imageUrl: finalAddress["image_url"]?.toString(),
          address: finalAddress["address"]?.toString() ?? "Unknown Address",
          locationId: finalAddress["location_id"]?.toString() ?? "Unknown ID",
          geocodingScore: finalAddress["score"] ?? 0,
          riskScore: overallHazard["rating"] ?? 0,
          dataCompleteness: location["dataCompleteness"] ?? 1,
          hazards: _parseHazards(hazard),
          geocodedAt: geocodedAt,
          occupancy: occupancy,
          campus: finalAddress["campus_id"]?.toString(),
          accountId: finalAddress["account_id"]?.toString(),
          accountName: finalAddress["account_name"]?.toString(),
          subAccountId: finalAddress["sub_account_id"]?.toString(),
          subAccountName: finalAddress["sub_account_name"]?.toString(),
          sovId: sovIdValue,
          sovName: finalAddress["sov_name"]?.toString(),
          rented: finalAddress["rented"] ?? false,
        );
      },
    );
  }

  Map<String, HazardDetails> _parseHazards(
    Map<String, dynamic> hazardJson,
  ) {
    final Map<String, HazardDetails> hazards = {};

    hazardJson.forEach((key, value) {
      if (value != null && value is Map<String, dynamic>) {
        hazards[key] = HazardDetails.fromJson(value);
      }
    });

    debugPrint("Hazards Count : ${hazards.length}");
    debugPrint("Hazards : ${hazards.keys.toList()}");

    return hazards;
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }
}

int scoreToStar(int? score) {
  if (score == null) return 1;

  if (score >= 80) return 5;
  if (score >= 60) return 4;
  if (score >= 40) return 3;
  if (score >= 20) return 2;

  return 1;
}
