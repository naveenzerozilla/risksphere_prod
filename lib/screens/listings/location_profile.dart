import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:RiskSphere/models/hazard_data.dart';
import 'package:RiskSphere/providers/custom_tile_providers.dart';
import 'package:RiskSphere/providers/custom_tile_providers_main_hazards.dart';
import 'package:RiskSphere/screens/listings/account_list.dart';
import 'package:RiskSphere/screens/listings/sub_account_list.dart';
import 'package:RiskSphere/screens/listings/widgets/data_tab.dart';
import 'package:RiskSphere/screens/listings/widgets/hazard_page.dart';
import 'package:RiskSphere/screens/listings/widgets/location_card.dart'
    show GeocodingDialog;
import 'package:RiskSphere/screens/listings/widgets/vertical_bar_indicator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart' show DateFormat;
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:RiskSphere/constants/enums.dart';
import 'package:RiskSphere/design_system/components/rating_widget.dart';
import 'package:RiskSphere/design_system/primitives/app_colors.dart';
import 'package:RiskSphere/design_system/primitives/custom_typography.dart';
import 'package:RiskSphere/design_system/primitives/utilities/custom_spacing.dart';
import 'package:RiskSphere/providers/location_profile_provider.dart';
import 'package:RiskSphere/providers/place_api_provider.dart';
import 'package:RiskSphere/providers/user_profile_provider.dart';
import 'package:RiskSphere/screens/listings/add_location_screen.dart';
import 'package:RiskSphere/screens/listings/widgets/export_dialog.dart';
import 'package:RiskSphere/screens/listings/widgets/location_details_popup.dart';
import 'package:RiskSphere/screens/listings/widgets/message_card.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:google_maps_cluster_manager_2/google_maps_cluster_manager_2.dart'
    as cluster_manager;
import '../../design_system/components/custom_button.dart';
import '../../models/locationDocument.dart';
import '../../models/location_profile_model.dart';
import '../../models/my_location_list_model.dart';
import '../../providers/account_list_provider.dart';
import '../../providers/data_list_parameters.dart';
import '../../providers/my_location_list_provider.dart';
import '../../providers/sub_account_list_provider.dart';
import '../../providers/theme_provider.dart';
import '../../design_system/components/custom_appbar.dart';
import '../../design_system/components/custom_drawer.dart';
import '../../service/language_service.dart';
import '../../service/shared_preference_service.dart';

class LocationProfile extends StatefulWidget {
  LocationProfile({
    super.key,
    this.locationName,
    required this.accountId,
    required this.accountName,
    required this.subAccountId,
    required this.subAccountName,
    required this.sovId,
    required this.sovName,
    required this.page,
    required this.totalPages,
    required this.searchQuery,
    this.locationId,
    this.reset = false,
    this.hazardProcess,
    this.onConfirmCallback,
    this.onNavigateBack,
    this.tab,
  });

  final String? locationName;
  final String accountId;
  final String accountName;
  final String subAccountId;
  final String subAccountName;
  final String sovId;
  final String sovName;
  final String page;
  final String? totalPages;
  final String searchQuery;
  final String? locationId;
  final bool reset;
  final bool? hazardProcess;
  final VoidCallback? onConfirmCallback;
  final VoidCallback? onNavigateBack;
  final int? tab;

  @override
  State<LocationProfile> createState() => _LocationProfileState();
}

class _LocationProfileState extends State<LocationProfile>
    with SingleTickerProviderStateMixin {
  bool _isInitialized = false;
  late cluster_manager.ClusterManager<MyLocation> clusterManager;

  final ScreenshotController _geocodingScreenshotController =
      ScreenshotController();
  final ScreenshotController _riskScoreScreenshotController =
      ScreenshotController();
  final GlobalKey _mapKey = GlobalKey();
  bool isLoadingAddToCampus = false;
  bool isLoadingAddToMultiple = false;
  bool showViewMore = true;
  final TextEditingController _commentController = TextEditingController();
  bool is3DView = false;
  LatLng? _focusedLocation;
  late GoogleMapController mapController;
  LatLng _currentCenter = LatLng(20.5937, 78.9629);

  late int tabIndex = widget.tab ?? 0;
  bool isLoading = false;
  bool addCampusLoading = false;
  bool addCampusLoading1 = false;
  String? selectedLoadingType;
  bool _isExpanded = false;
  bool _showNotificationDot = true;
  List<HazardData> mainHazards = [];
  int? _selectedScore;
  Set<Marker> _markers = {};

  bool hasAnyPlan = false;
  List<Map<String, dynamic>> galleryMedia = [];
  bool isGalleryLoading = false;
  bool isGalleryLoaded = false;

  // Google Maps
  bool _mapIsReady = false;
  UniqueKey _googleMapKey = UniqueKey();
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};
  bool _isHeatmapOn = false;
  String? _selectedHazard;
  String? selectedHazardId;
  bool _isAddingMarker = false;
  bool _isLoading = false;
  String? selectedVendor;
  bool isLoadingMainHazards = false;
  CustomTileProviderMainHazards? _mainHazardTileProvider;
  Map<String, CustomTileProvider> _tileProviders = {};
  bool _showPins = true;
  PageController? _pageController;
  int selectedIndex = 0;
  bool isSelectionMode = false;
  Set<String> selectedIds = {};
  bool _isSending = false;

  TabController? _tabController;
  TextEditingController _nameController = TextEditingController();
  TextEditingController _addressController = TextEditingController();
  TextEditingController _campusIdController = TextEditingController();
  TextEditingController searchController = TextEditingController();
  ScrollController? _campusScrollController;
  List<File> _images = [];
  String autoCompleteSuggestionSessionToken = Uuid().v4();
  MapType _currentMapType = MapType.satellite;
  bool _isBottomSheetExpanded = false;
  bool bottomsheetopened = false;
  bool _isBottomSheetFullScreen = false;
  bool isSwitched = false;
  bool confirmload = false;

  MarkerId? _selectedMarker;
  late String _totalPages;

  late TextEditingController _searchController;

  ScrollController _scrollController = ScrollController();

  String _formatTimestamp(int? seconds) {
    if (seconds == null) return '';

    final dateTime = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);

    return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime).toLowerCase();
  }

  @override
  void initState() {
    if (!_isInitialized) {
      _fetchAllData();
      _searchController = TextEditingController();
      _tabController =
          TabController(length: 4, vsync: this, initialIndex: widget.tab ?? 0);
      super.initState();
      _totalPages = widget.totalPages!;
      _campusScrollController = ScrollController();
      _pageController =
          PageController(viewportFraction: 0.9, initialPage: selectedIndex);
      _isInitialized = true;
      _tabController!.addListener(() {
        setState(() {
          tabIndex = _tabController!.index;
        });
      });
      Provider.of<SubaccountParameterProvider>(context, listen: false)
          .setUpdatedScore(0);
    }
  }

  _fetchAllData() async {
    await Future.wait(<Future>[
      _getData(),
      _initializeClusterManager(),
      _fetchMainHazardLayers(),
    ]);
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

  int? totalPages;

  Future<void> _navigateRight() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    print('Navigating from page ${widget.page} of ${widget.totalPages}');

    final locationProvider =
        Provider.of<MyLocationListProvider>(context, listen: false);
    int currentPage = int.tryParse(widget.page) ?? 1;

    totalPages = widget.locationId!.isNotEmpty
        ? int.parse(locationProvider.totalPages.toString())
        : int.tryParse(widget.totalPages!) ==
                int.parse(locationProvider.totalPages.toString())
            ? int.tryParse(widget.totalPages!)
            : int.parse(locationProvider.totalPages.toString());
    setState(() {
      totalPages == _totalPages;
    });

    totalPages = (totalPages == 0)
        ? (int.tryParse(_totalPages.toString()) ?? 1)
        : totalPages;
    if (currentPage >= totalPages!) {
      print('Already on the last page.');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    int pageToNavigate = currentPage + 1;
    print('Navigating to page: $pageToNavigate');

    // Check if the page already exists in the navigation stack
    bool alreadyExists = false;
    Navigator.popUntil(context, (route) {
      if (route.settings.name == 'LocationProfile$pageToNavigate') {
        alreadyExists = true;
      }
      return true;
    });

    if (alreadyExists) {
      print('Page $pageToNavigate already exists. Not pushing a new one.');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // Navigate to the next page
    try {
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => LocationProfile(
            accountId: widget.accountId,
            subAccountId: widget.subAccountId,
            sovId: widget.sovId,
            accountName: widget.accountName,
            subAccountName: widget.subAccountName,
            sovName: widget.sovName,
            searchQuery: widget.searchQuery,
            locationId: '',
            page: pageToNavigate.toString(),
            totalPages: totalPages.toString(),
          ),
        ),
      );
    } catch (e) {
      print('Navigation error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _navigateLeft() async {
    int currentPage = int.tryParse(widget.page) ?? 1;

    // Prevent navigation beyond first page
    if (currentPage <= 1) {
      print('Already on the first page.');
      return;
    }

    int pageToNavigate = currentPage - 1;
    print('Navigating to page: $pageToNavigate');

    final locationProvider =
        Provider.of<MyLocationListProvider>(context, listen: false);
    int? totalPages = widget.locationId!.isNotEmpty
        ? int.parse(locationProvider.totalPages.toString())
        : int.tryParse(widget.totalPages!) ==
                int.parse(locationProvider.totalPages.toString())
            ? int.tryParse(widget.totalPages!)
            : int.parse(locationProvider.totalPages.toString());
    Navigator.of(context).replace(
      oldRoute: ModalRoute.of(context)!,
      newRoute: MaterialPageRoute(
        builder: (context) => LocationProfile(
          accountId: widget.accountId,
          subAccountId: widget.subAccountId,
          sovId: widget.sovId,
          accountName: widget.accountName,
          subAccountName: widget.subAccountName,
          sovName: widget.sovName,
          searchQuery: widget.searchQuery,
          locationId: '',
          page: pageToNavigate.toString(),
          totalPages: totalPages.toString(),
        ),
      ),
    );
  }

  Future<void> _initializeClusterManager() async {
    final allLocations =
        Provider.of<MyLocationListProvider>(context, listen: false)
            .fullLocationList;

    clusterManager = cluster_manager.ClusterManager<MyLocation>(
      allLocations,
      _updateMarkers,
      markerBuilder: _markerBuilder,
      levels: [1, 4.25, 6.75],
      extraPercent: 0.2,
      stopClusteringZoom: 5.0,
    );
  }

  Future<Marker> _markerBuilder(
      cluster_manager.Cluster<MyLocation> cluster) async {
    if (cluster.isMultiple) {
      Color clusterColor = _determineClusterColor(cluster.items.toList());
      return Marker(
        markerId: MarkerId(cluster.getId()),
        infoWindow: InfoWindow(
          title: 'Click here',
          onTap: () {
            print('Info window tapped');
          },
        ),
        position: cluster.location,
        icon: await _getClusterBitmap(125,
            text: cluster.count.toString(), color: clusterColor),
        onTap: () {
          print(cluster.items);
        },
      );
    } else {
      MyLocation location = cluster.items.first;
      final score = location.finalAddress?.score;

      return Marker(
        markerId: MarkerId(location.id ?? ''),
        infoWindow: InfoWindow(
          title: 'Click here',
          onTap: () {
            print('Info window tapped');
          },
        ),
        position: location.location,
        icon: BitmapDescriptor.defaultMarkerWithHue(_getMarkerHue(score ?? 0)),
        visible:
            _showPins && (_selectedScore == null || _selectedScore == score),
        onTap: () {
          showLocationDetailsPopup(context, location);
        },
      );
    }
  }

  Color _determineClusterColor(List<MyLocation> items) {
    Map<int, int> colorCounts = {};

    for (var item in items) {
      int score = item.finalAddress?.score ?? 0;
      colorCounts[score] = (colorCounts[score] ?? 0) + 1;
    }

    int dominantScore =
        colorCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    return _getColorFromScore(dominantScore);
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

  List<Color> scoreColors = [
    Colors.grey[300]!,
    Colors.red[900]!,
    Colors.red[300]!,
    Colors.yellow[300]!,
    Colors.green[300]!,
    Colors.green[600]!,
  ];

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
        return Colors.blue;
    }
  }

  Future<void> _getData() async {
    bool? hasAnyPlans = await SharedPreferenceService.getHasAnyPlan();
    await Provider.of<MyLocationListProvider>(context, listen: false)
        .fetchLocationListProfile(
      context,
      "",
      int.parse(widget.page),
      int.parse(widget.totalPages!),
      widget.accountId,
      widget.subAccountId,
      widget.sovId,
      widget.locationId,
    );
    _addSubdestinationMarkers();
    _add();
    setState(() {
      hasAnyPlan = hasAnyPlans ?? false;
    });
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
          if (mainHazards.isNotEmpty) {
            selectedHazardId = mainHazards.first.id;
            if (mainHazards.first.vendors.isNotEmpty) {
              selectedVendor = mainHazards.first.vendors.first.name;
              _changeHazardLayer("");
              _changeVendor(selectedVendor);
            }
          }
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

  void _add() {
    var controller =
        Provider.of<MyLocationListProvider>(context, listen: false);
    var markerIdVal =
        controller.locationProfile?.finalAddress?.locationId ?? '1';
    final MarkerId markerId = MarkerId(markerIdVal);

    print(
        'Latitude: ${controller.locationProfile?.finalAddress?.latitude}, Longitude: ${controller.locationProfile?.finalAddress?.longitude}');
    final Marker marker = Marker(
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      markerId: markerId,
      infoWindow: InfoWindow(
        title: '',
        onTap: () {
          print('Info window tapped');
        },
      ),
      position: LatLng(
          controller.locationProfile?.finalAddress?.latitude ?? 123.432432,
          controller.locationProfile?.finalAddress?.longitude ?? -111.889),
      onTap: () {
        _onMarkerTapped(markerId);
      },
      zIndex: 15,
    );

    setState(() {
      markers[markerId] = marker;
    });
    _controller.future.then((value) => value.animateCamera(
        CameraUpdate.newLatLng(LatLng(
            controller.locationProfile?.finalAddress?.latitude ?? 123.432432,
            controller.locationProfile?.finalAddress?.longitude ?? -111.889))));
    // if rating is 3 or 4
    if (controller.locationProfile?.finalAddress?.score == 3 ||
        controller.locationProfile?.finalAddress?.score == 4) {
      setState(() {
        _searchController.text =
            controller.locationProfile?.finalAddress?.address ?? "";
      });
    }
  }

  void _addSubdestinationMarkers() {
    try {
      var provider =
          Provider.of<MyLocationListProvider>(context, listen: false);
      Map<MarkerId, Marker> newMarkers = {}; // Temporary map to hold markers

      for (var subdestination
          in provider.locationProfile?.subdestinations ?? []) {
        try {
          var markerId = MarkerId(subdestination.id!);
          var isAdded = (subdestination.status ?? "").toLowerCase() == "added";

          var marker = Marker(
            infoWindow: InfoWindow(
              title: 'Click here',
              onTap: () {
                print('Info window tapped');
              },
            ),
            zIndex: isAdded ? 5 : 0,
            markerId: markerId,
            position: LatLng(subdestination.lat!, subdestination.lng!),
            icon: BitmapDescriptor.defaultMarkerWithHue(isAdded
                ? BitmapDescriptor.hueGreen
                : BitmapDescriptor.hueAzure),
            onTap: () {
              _onMarkerTapped(markerId);
            },
          );

          print("latlong ${subdestination.lat} ${subdestination.lng}");
          newMarkers[markerId] = marker; // Add marker to the temporary map
        } catch (e, stackTrace) {
          print("Error processing subdestination: $e\n$stackTrace");
        }
      }

      setState(() {
        markers =
            newMarkers; // Set all markers at once to avoid unnecessary rebuilds
      });

      _add();
    } catch (e, stackTrace) {
      print("Error in _addSubdestinationMarkers: $e\n$stackTrace");
    }
  }

  Future<void> _pickImage() async {
    final pickedFiles = await ImagePicker().pickMultiImage();
    setState(() {
      _images.addAll(pickedFiles.map((file) => File(file.path)));
    });
    for (var file in pickedFiles) {
      var provider =
          Provider.of<MyLocationListProvider>(context, listen: false);
      await provider.uploadImage(
          context,
          file.path,
          widget.accountId,
          widget.subAccountId,
          widget.sovId,
          provider.locationProfile?.finalAddress!.locationId ?? "");
    }
  }

  Future<void> _pickDocuments() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
    );

    if (result == null) return;

    bool exceeded = false;

    for (var file in result.files) {
      if (file.size > maxFileSize) {
        exceeded = true;
      }
    }

    setState(() {
      _selectedFiles = result.files;
      _isSizeExceeded = exceeded;
    });

    if (exceeded) {
      _showSizeExceededDialog();
    }
  }

  void _showSizeExceededDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text("Upload Documents"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.red),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Total File Size Limit Exceeded",
                    style: TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Maximum allowed size per file is 200MB.",
                    style: TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 10),
                  ..._selectedFiles
                      .where((f) => f.size > maxFileSize)
                      .map(
                        (f) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            "${f.name} (${(f.size / (1024 * 1024)).toStringAsFixed(2)} MB)",
                          ),
                        ),
                      )
                      .toList(),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  static const int maxFileSize = 200 * 1024 * 1024; // 200MB

  List<PlatformFile> _selectedFiles = [];
  bool _isSizeExceeded = false;

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
    _tabController!.dispose();
    _pageController!.dispose();
    _searchController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _campusIdController.dispose();
    _controller.future.then((value) => value.dispose());
    _campusScrollController!.dispose();
  } // Refresh method

  bool isLoadingPrevious = false;
  bool isLoadingNext = false;

  Future<void> _refreshData() async {
    final provider =
        Provider.of<MyLocationListProvider>(context, listen: false);
    setState(() => _isLoading = true);
    try {
      await _fetchAllData();
      widget.onConfirmCallback?.call();

      setState(() {
        _totalPages = provider.totalPages.toString(); // update state
      });
      print("TotalPage" + _totalPages.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    var typography = CustomTypography(context);
    _googleMapKey = UniqueKey();
    return SafeArea(
      child: Consumer<ThemeProvider>(builder: (context, themeProvider, child) {
        return Consumer<MyLocationListProvider>(
            builder: (context, locationProfileProvider, child) {
          return Scaffold(
            backgroundColor: themeProvider.getTheme.colorScheme.surface,
            appBar: CustomAppBar(
              isExpanded: _isExpanded,
              showNotificationDot: _showNotificationDot,
              onExpandPressed: (isExpanded) {
                setState(() {
                  _isExpanded = isExpanded;
                });
              },
              onSearchPressed: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
            ),
            drawer: CustomDrawer(),
            bottomNavigationBar: tabIndex == 2 || tabIndex == 3
                ? Container(
                    height: 0,
                  )
                : BottomAppBar(
                    color: Theme.of(context).primaryColor,
                    shape: const CircularNotchedRectangle(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Row(
                        children: [
                          Builder(builder: (context) {
                            final int currentPage =
                                int.tryParse(widget.page) ?? 1;
                            final int totalPages = widget.locationId!.isNotEmpty
                                ? (locationProfileProvider.resetTotalPage ?? 1)
                                : (int.tryParse(widget.totalPages ?? '1') ?? 1);
                            final bool canNavigatePrevious = currentPage > 1;
                            final bool canNavigateNext =
                                currentPage < totalPages;

                            return Expanded(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          side: BorderSide(
                                            color: canNavigatePrevious
                                                ? AppColors.primaryMain
                                                : Colors.grey,
                                            width: 1,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10),
                                        backgroundColor: canNavigatePrevious
                                            ? Colors.black
                                            : Colors.grey[300],
                                      ),
                                      onPressed: canNavigatePrevious &&
                                              !isLoadingPrevious
                                          ? () async {
                                              setState(() =>
                                                  isLoadingPrevious = true);
                                              await _navigateLeft(); // You should await your navigation function
                                              setState(() =>
                                                  isLoadingPrevious = false);
                                            }
                                          : null,
                                      child: isLoadingPrevious
                                          ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2),
                                            )
                                          : Text(
                                              LanguageService.getTranslated(
                                                  context, "prev_locations"),
                                              style: typography.ButtonLarge
                                                  .copyWith(
                                                color: canNavigatePrevious
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
                                          side: BorderSide(
                                            color: AppColors.primaryMain,
                                            width: 1,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10),
                                        backgroundColor: canNavigateNext
                                            ? AppColors.primaryMain
                                            : Colors.grey[300],
                                      ),
                                      onPressed: canNavigateNext &&
                                              !isLoadingNext
                                          ? () async {
                                              setState(
                                                  () => isLoadingNext = true);
                                              await _navigateRight(); // Await navigation
                                              setState(
                                                  () => isLoadingNext = false);
                                            }
                                          : null,
                                      child: isLoadingNext
                                          ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2),
                                            )
                                          : Text(
                                              LanguageService.getTranslated(
                                                  context, "next_locations"),
                                              style: typography.ButtonLarge
                                                  .copyWith(
                                                color: canNavigateNext
                                                    ? AppColors.black
                                                    : Colors.grey,
                                              ),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
            body: LayoutBuilder(builder: (context, constraints) {
              return Stack(
                children: [
                  RefreshIndicator(
                    onRefresh: _refreshData,
                    child: SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(minHeight: constraints.maxHeight),
                        child: IntrinsicHeight(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Left Column
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              InkWell(
                                                onTap: () {
                                                  if (!bottomsheetopened)
                                                    Navigator.pop(
                                                        context, false);
                                                },
                                                child: Container(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  height: 35,
                                                  width: 35,
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                  ),
                                                  child: Icon(
                                                      Icons.arrow_back_ios_new,
                                                      size: 18),
                                                ),
                                              ),
                                              // SizedBox(width: 8),
                                              Expanded(
                                                child: Container(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 5),
                                                  child: SingleChildScrollView(
                                                    scrollDirection:
                                                        Axis.horizontal,
                                                    // ✅ prevents overflow
                                                    child: Row(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .center,
                                                      children: [
                                                        // ---------- SOV FLOW ----------
                                                        if (widget.sovId
                                                                .isNotEmpty) ...[
                                                          InkWell(
                                                            onTap: () {
                                                              if (!bottomsheetopened) {
                                                                Navigator.pop(
                                                                    context);
                                                                Navigator.pop(
                                                                    context);
                                                              }
                                                            },
                                                            child: Text(
                                                              widget.sovName ??
                                                                  "",
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 14,
                                                                color: Colors
                                                                    .white60,
                                                              ),
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                          ),
                                                          const Text(
                                                            ' > ',
                                                            style: TextStyle(
                                                                fontSize: 12,
                                                                color: Colors
                                                                    .white70),
                                                          ),
                                                          InkWell(
                                                            onTap: () {
                                                              if (!bottomsheetopened) {
                                                                Navigator.pop(
                                                                    context);
                                                              }
                                                            },
                                                            child: Text(
                                                              widget.locationName ??
                                                                  "",
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 14,
                                                                color: Colors
                                                                    .white60,
                                                              ),
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                          ),
                                                          const Text(
                                                            ' > ',
                                                            style: TextStyle(
                                                                fontSize: 12,
                                                                color: Colors
                                                                    .white70),
                                                          ),
                                                          const Text(
                                                            'Location Profile',
                                                            style: TextStyle(
                                                                fontSize: 14,
                                                                color: Colors
                                                                    .white),
                                                          ),
                                                        ]

                                                        // ---------- ACCOUNT FLOW ----------
                                                        else ...[
                                                          InkWell(
                                                            onTap: () {
                                                              if (!bottomsheetopened) {
                                                                Navigator
                                                                    .pushAndRemoveUntil(
                                                                  context,
                                                                  MaterialPageRoute(
                                                                      builder:
                                                                          (_) =>
                                                                              AccountListScreen()),
                                                                  (route) =>
                                                                      false,
                                                                );
                                                              }
                                                            },
                                                            child: Text(
                                                              widget.accountName ??
                                                                  "",
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 12,
                                                                color: Colors
                                                                    .white70,
                                                              ),
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                          ),
                                                          const Text(
                                                            ' > ',
                                                            style: TextStyle(
                                                                fontSize: 12,
                                                                color: Colors
                                                                    .white70),
                                                          ),
                                                          InkWell(
                                                            onTap: () {
                                                              if (!bottomsheetopened) {
                                                                Navigator
                                                                    .pushAndRemoveUntil(
                                                                  context,
                                                                  MaterialPageRoute(
                                                                    builder: (_) =>
                                                                        SubAccountListScreen(
                                                                      accountId:
                                                                          widget.accountId ??
                                                                              "",
                                                                      accountName:
                                                                          widget.subAccountName ??
                                                                              "",
                                                                    ),
                                                                  ),
                                                                  (route) =>
                                                                      false,
                                                                );
                                                              }
                                                            },
                                                            child: Text(
                                                              widget.subAccountName ??
                                                                  "",
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 12,
                                                                color: Colors
                                                                    .white70,
                                                              ),
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                          ),
                                                          const Text(
                                                            ' > ',
                                                            style: TextStyle(
                                                                fontSize: 12,
                                                                color: Colors
                                                                    .white70),
                                                          ),
                                                          InkWell(
                                                            onTap: () {
                                                              if (!bottomsheetopened) {
                                                                Navigator.pop(
                                                                    context);
                                                              }
                                                            },
                                                            child: Text(
                                                              '${locationProfileProvider.locationProfile?.finalAddress?.locationName ?? ''}',
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 12,
                                                                color: Colors
                                                                    .white60,
                                                              ),
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                          ),
                                                          const Text(
                                                            ' > ',
                                                            style: TextStyle(
                                                                fontSize: 12,
                                                                color: Colors
                                                                    .white70),
                                                          ),
                                                          const Text(
                                                            'Location Profile',
                                                            style: TextStyle(
                                                                fontSize: 12,
                                                                color: Colors
                                                                    .white),
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      '${locationProfileProvider.locationProfile?.finalAddress?.locationName ?? ''} ${formatLocationText((int.tryParse(widget.page) ?? 1), (int.tryParse(widget.totalPages!) ?? 1))}',
                                                      style: typography.H6
                                                          .copyWith(
                                                              height: 1.0),
                                                      overflow: TextOverflow
                                                          .ellipsis, // Handle overflow
                                                    ),
                                                    SizedBox(
                                                        height:
                                                            CustomSpacing.two),
                                                    Text(
                                                      locationProfileProvider
                                                              .locationProfile
                                                              ?.finalAddress
                                                              ?.address ??
                                                          '',
                                                      maxLines: 2,
                                                      style: typography
                                                          .Subtitle2.copyWith(
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: AppColors
                                                            .primaryMain,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              IconButton(
                                                icon: Icon(
                                                  Icons.edit,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary,
                                                ),
                                                onPressed: () async {
                                                  final locationProfile =
                                                      locationProfileProvider
                                                          .locationProfile;

                                                  if (locationProfile == null)
                                                    return;

                                                  final score = locationProfile
                                                      .finalAddress?.score;
                                                  print(score);

                                                  /// 🔹 CASE 1: Score == 5 → Edit name only
                                                  if (score.toString() == "5") {
                                                    _editName(
                                                        locationProfileProvider);
                                                    return;
                                                  }

                                                  /// 🔹 CASE 2: Full edit
                                                  final value =
                                                      await Navigator.of(
                                                              context)
                                                          .push(
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                          AddLocationScreen(
                                                        accountId:
                                                            widget.accountId,
                                                        subAccountId:
                                                            widget.subAccountId,
                                                        sovId: widget.sovId,
                                                        accountName:
                                                            widget.accountName,
                                                        subAccountName: widget
                                                            .subAccountName,
                                                        sovName: widget.sovName,
                                                        locationId:
                                                            locationProfile.id,
                                                        // nullable-safe
                                                        locationName: locationProfile
                                                                .finalAddress
                                                                ?.locationName ??
                                                            "",
                                                        locationIdForRef:
                                                            locationProfile
                                                                    .finalAddress
                                                                    ?.locationIdForRef ??
                                                                "",
                                                        searchQuery: widget
                                                                .searchQuery ??
                                                            "",
                                                        page: widget.page,
                                                        totalPages: widget
                                                                    .locationId
                                                                    ?.isNotEmpty ==
                                                                true
                                                            ? ((locationProfileProvider
                                                                            .resetTotalPage ??
                                                                        1) -
                                                                    1)
                                                                .toString()
                                                            : widget.totalPages,
                                                      ),
                                                    ),
                                                  );

                                                  if (value != null) {
                                                    _refreshData();
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Right Column
                                    Column(
                                      children: [
                                        SizedBox(height: CustomSpacing.four),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: CustomSpacing.two,
                              ),
                              // Container(
                              //   padding: EdgeInsets.only(left: 16, right: 24),
                              //   child: Row(
                              //     children: [
                              //       Text(
                              //         LanguageService.getTranslated(
                              //             context, "listing_maps_ratings"),
                              //       ),
                              //       SizedBox(width: 3),
                              //       InkWell(
                              //           onTap: () {
                              //             bottomsheetopened != true
                              //                 ? showDialog(
                              //                     context: context,
                              //                     builder: (context) => GeocodingDialog(
                              //                         title: tabIndex == 0
                              //                             ? "Geocoding Score Info"
                              //                             : tabIndex == 1
                              //                                 ? "Hazard Score Info"
                              //                                 : "Data Completeness Info",
                              //                         status: true),
                              //                   )
                              //                 : null;
                              //           },
                              //           child: Icon(Icons.info,
                              //               color: Colors.lightBlueAccent))
                              //     ],
                              //   ),
                              // ),
                              Padding(
                                padding: EdgeInsets.only(left: 16, right: 24),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    tabIndex == 0 || tabIndex == 1
                                        ? Consumer2<MyLocationListProvider,
                                            SubaccountParameterProvider>(
                                            builder: (context,
                                                locationProfileProvider,
                                                provider,
                                                child) {
                                              dynamic rawScore;

                                              try {
                                                if (tabIndex == 0) {
                                                  rawScore =
                                                      locationProfileProvider
                                                              .locationProfile
                                                              ?.geocodingScore ??
                                                          1;
                                                } else if (tabIndex == 1) {
                                                  rawScore =
                                                      locationProfileProvider
                                                              .locationProfile
                                                              ?.overallScore ??
                                                          5;
                                                  // if (rawScore == 0)
                                                  //   rawScore = 5;
                                                } else {
                                                  rawScore =
                                                      locationProfileProvider
                                                              .locationProfile
                                                              ?.dataCompleteness ??
                                                          1;

                                                  if (provider.updatedScore !=
                                                      null) {
                                                    rawScore =
                                                        provider.updatedScore;
                                                  }
                                                }
                                              } catch (_) {
                                                rawScore == 0 ? 5 : 1;
                                              }
                                              final int rating = normalizeScore(
                                                  rawScore); // for color & bars
                                              final String ratingText =
                                                  formatScoreText(
                                                      rawScore); // for text

                                              return Row(
                                                children: [
                                                  VerticalBarIndicator(
                                                    score: (rawScore is num
                                                        ? (rawScore == 0
                                                            ? 5.0
                                                            : rawScore
                                                                .toDouble())
                                                        : (double.tryParse(rawScore
                                                                    .toString()) ==
                                                                0
                                                            ? 5.0
                                                            : double.tryParse(
                                                                    rawScore
                                                                        .toString()) ??
                                                                rating
                                                                    .toDouble())),
                                                  ),

                                                  const SizedBox(width: 8),
                                                  // Text(rawScore),

                                                  rating == 5 ||
                                                          int.parse(rawScore
                                                                  .toString()) ==
                                                              0
                                                      ? SvgPicture.asset(
                                                          'assets/images/certified_five.svg',
                                                          width: 24,
                                                          height: 24,
                                                        )
                                                      : Container(
                                                          width: 22,
                                                          height: 22,
                                                          decoration:
                                                              BoxDecoration(
                                                            color: scoreColors[
                                                                rating],
                                                            shape:
                                                                BoxShape.circle,
                                                          ),
                                                          alignment:
                                                              Alignment.center,
                                                          child: Text(
                                                            rating.toString(),
                                                            textAlign: TextAlign
                                                                .center,
                                                            style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 11,
                                                              color: ThemeData.estimateBrightnessForColor(
                                                                          scoreColors[
                                                                              rating]) ==
                                                                      Brightness
                                                                          .dark
                                                                  ? Colors.white
                                                                  : Colors
                                                                      .black,
                                                            ),
                                                          ),
                                                        ),
                                                ],
                                              );
                                            },
                                          )
                                        : Consumer2<MyLocationListProvider,
                                            SubaccountParameterProvider>(
                                            builder: (context, locationProvider,
                                                paramProvider, child) {
                                              double rawScore = 1;

                                              try {
                                                if (tabIndex == 0) {
                                                  rawScore = (locationProvider
                                                              .locationProfile
                                                              ?.geocodingScore ??
                                                          1)
                                                      .toDouble();
                                                } else if (tabIndex == 1) {
                                                  rawScore = (locationProvider
                                                              .locationProfile
                                                              ?.overallScore ??
                                                          1)
                                                      .toDouble();
                                                  if (rawScore == 0)
                                                    rawScore = 1;
                                                } else if (tabIndex == 2) {
                                                  final apiScore = (locationProvider
                                                              .locationProfile
                                                              ?.dataCompleteness ??
                                                          1)
                                                      .toDouble();

                                                  /// ⭐ Use updatedScore ONLY if available & greater
                                                  if (paramProvider
                                                              .updatedScore !=
                                                          null &&
                                                      paramProvider
                                                              .updatedScore! >
                                                          apiScore) {
                                                    rawScore = paramProvider
                                                        .updatedScore!
                                                        .toDouble();
                                                  } else {
                                                    rawScore = apiScore == 0
                                                        ? 1
                                                        : apiScore;
                                                  }
                                                }
                                              } catch (_) {
                                                rawScore = 1;
                                              }

                                              final int rating =
                                                  normalizeScore(rawScore);
                                              final int colorIndex =
                                                  scoreToColorIndex(rawScore);

                                              return RepaintBoundary(
                                                child: Row(
                                                  children: [
                                                    VerticalBarIndicator(
                                                        score: rawScore),
                                                    const SizedBox(width: 8),
                                                    rawScore == 5
                                                        ? SvgPicture.asset(
                                                            'assets/images/certified_five.svg',
                                                            width: 24,
                                                            height: 24,
                                                          )
                                                        : Container(
                                                            width: 22,
                                                            height: 22,
                                                            decoration:
                                                                BoxDecoration(
                                                              color: scoreColors[
                                                                  colorIndex],
                                                              shape: BoxShape
                                                                  .circle,
                                                            ),
                                                            alignment: Alignment
                                                                .center,
                                                            child: Text(
                                                              rawScore.toString() ==
                                                                      "1.0"
                                                                  ? '1'
                                                                  : rawScore.toString() ==
                                                                          "2.0"
                                                                      ? '2'
                                                                      : rawScore.toString() ==
                                                                              "3.0"
                                                                          ? '3'
                                                                          : rawScore.toString() == "4.0"
                                                                              ? '4'
                                                                              : rawScore.toString(),
                                                              style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 11,
                                                                color: ThemeData.estimateBrightnessForColor(scoreColors[
                                                                            colorIndex]) ==
                                                                        Brightness
                                                                            .dark
                                                                    ? Colors
                                                                        .white
                                                                    : Colors
                                                                        .black,
                                                              ),
                                                            ),
                                                          ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                    InkWell(
                                        onTap: () {
                                          bottomsheetopened != true
                                              ? showDialog(
                                                  context: context,
                                                  builder: (context) => GeocodingDialog(
                                                      title: tabIndex == 0
                                                          ? "Geocoding Score Info"
                                                          : tabIndex == 1
                                                              ? "Hazard Score Info"
                                                              : "Data Completeness Info",
                                                      status: true),
                                                )
                                              : null;
                                        },
                                        child: Icon(Icons.info,
                                            color: Colors.lightBlueAccent))
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: tabIndex == 0
                                    ? MediaQuery.of(context).size.height * 0.70
                                    : MediaQuery.of(context).size.height * 0.80,
                                child: DefaultTabController(
                                  length: _tabController!.length,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: TabBar(
                                          controller: _tabController,
                                          isScrollable: true,
                                          tabAlignment: TabAlignment.start,
                                          labelPadding: EdgeInsets.zero,
                                          indicatorPadding: EdgeInsets.zero,
                                          indicatorSize:
                                              TabBarIndicatorSize.label,
                                          onTap: (index) {
                                            if (bottomsheetopened || index >= 3)
                                              return;
                                            setState(() => tabIndex = index);
                                          },
                                          tabs: [
                                            Tab(
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 20),
                                                child: Text(
                                                  LanguageService.getTranslated(
                                                      context, "geocoding"),
                                                ),
                                              ),
                                            ),
                                            Tab(
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 20),
                                                child: Text(
                                                  LanguageService.getTranslated(
                                                      context, "hazard_score"),
                                                ),
                                              ),
                                            ),
                                            Tab(
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 20),
                                                child: Text(
                                                  LanguageService.getTranslated(
                                                      context,
                                                      "data_completeness"),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: RepaintBoundary(
                                          child: TabBarView(
                                            controller: _tabController,
                                            physics:
                                                NeverScrollableScrollPhysics(),
                                            children: [
                                              _geocodingScore(),
                                              Consumer<MyLocationListProvider>(
                                                builder: (context,
                                                    locationProfileProvider,
                                                    child) {
                                                  return SizedBox(
                                                    child:
                                                        locationProfileProvider
                                                                .isLoading
                                                            ? const Center(
                                                                child:
                                                                    RepaintBoundary(
                                                                  child:
                                                                      CircularProgressIndicator(),
                                                                ),
                                                              )
                                                            : RepaintBoundary(
                                                                child:
                                                                    SingleChildScrollView(
                                                                  child:
                                                                      HazardsSectionPage(
                                                                    hazards: locationProfileProvider
                                                                            .locationProfile
                                                                            ?.hazard ??
                                                                        {},
                                                                  ),
                                                                ),
                                                              ),
                                                  );
                                                },
                                              ),

                                              /// 🔹 3. Data Tab
                                              Consumer2<AccountListProvider,
                                                  SubAccountListProvider>(
                                                builder: (context,
                                                    accountListProvider,
                                                    subAccountListProvider,
                                                    _) {
                                                  if (accountListProvider
                                                          .isLoading ||
                                                      subAccountListProvider
                                                          .isLoading) {
                                                    return const Center(
                                                      child: RepaintBoundary(
                                                        child:
                                                            CircularProgressIndicator(),
                                                      ),
                                                    );
                                                  }

                                                  if (locationProfileProvider
                                                          .locationProfile ==
                                                      null) {
                                                    return const Center(
                                                      child: RepaintBoundary(
                                                        child:
                                                            CircularProgressIndicator(),
                                                      ),
                                                    );
                                                  }

                                                  return RepaintBoundary(
                                                    child: DataTab(
                                                      accountName:
                                                          locationProfileProvider
                                                                  .locationProfile
                                                                  ?.finalAddress
                                                                  ?.accountName ??
                                                              "",
                                                      accountId:
                                                          locationProfileProvider
                                                                  .locationProfile
                                                                  ?.finalAddress
                                                                  ?.accountId ??
                                                              "",
                                                      subaccountId:
                                                          locationProfileProvider
                                                                  .locationProfile
                                                                  ?.finalAddress
                                                                  ?.subAccountId
                                                                  ?.toString() ??
                                                              "",
                                                      locationId:
                                                          locationProfileProvider
                                                              .locationProfile
                                                              ?.finalAddress
                                                              ?.locationId
                                                              ?.toString(),
                                                      sovId: widget.sovId,
                                                      campusId:
                                                          locationProfileProvider
                                                                  .locationProfile
                                                                  ?.finalAddress
                                                                  ?.campusId
                                                                  ?.toString() ??
                                                              "",
                                                      campusStatus: (locationProfileProvider
                                                                  .locationProfile
                                                                  ?.finalAddress
                                                                  ?.placeTypes
                                                                  ?.contains(
                                                                      'premise') ==
                                                              true &&
                                                          (locationProfileProvider
                                                                  .locationProfile
                                                                  ?.subdestinations
                                                                  ?.isNotEmpty ??
                                                              false)),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              _isBottomSheetExpanded
                                  ? SizedBox(
                                      width: double.infinity,
                                      height: 300,
                                      child: Stack(
                                        children: [
                                          BackdropFilter(
                                            filter: ImageFilter.blur(
                                                sigmaX: 5, sigmaY: 5),
                                            child: Container(
                                              color:
                                                  Colors.black.withOpacity(0.2),
                                              width: double.infinity,
                                              height: double.infinity,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : Container(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (!_isBottomSheetFullScreen && tabIndex == 0)
                    Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: RepaintBoundary(
                          child: _buildBottomSheet(),
                        )),
                  if (_isBottomSheetFullScreen)
                    Positioned.fill(
                      child: _locationProfileBody(),
                    ),
                  if (_selectedMarker != null) _buildCustomInfoWindow(),
                  Positioned(
                    bottom: 70, // adjust above SpeedDial
                    right: 16,
                    child: GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          useSafeArea: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => _ChatbotBottomSheet(
                            locationId: locationProfileProvider
                                .locationProfile?.finalAddress?.locationId
                                .toString(),
                          ),
                        );
                      },
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Need Help?",
                              style: TextStyle(color: Colors.white),
                            ),
                            SizedBox(width: 8),
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: AppColors.primaryMain,
                              child: Icon(Icons.smart_toy,
                                  color: Colors.white, size: 18),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
          );
        });
      }),
    );
  }

  int scoreToColorIndex(dynamic value) {
    if (value == null) return 1;

    final double score = value is num
        ? value.toDouble()
        : double.tryParse(value.toString()) ?? 1.0;

    final int colorIndex = score.ceil();

    return colorIndex.clamp(1, 5);
  }

  int normalizeScore(dynamic value) {
    if (value == null) return 1;

    final double parsed = value is num
        ? value.toDouble()
        : double.tryParse(value.toString()) ?? 1;

    return parsed.ceil().clamp(1, 5);
  }

  String formatScoreText(dynamic value) {
    if (value == null) return '1';

    final double? parsed =
        value is num ? value.toDouble() : double.tryParse(value.toString());

    if (parsed == null) return '1';

    return parsed % 1 == 0
        ? parsed.toInt().toString()
        : parsed.toStringAsFixed(1);
  }

  Widget _buildCustomInfoWindow() {
    var typography = CustomTypography(context);
    var marker = markers[_selectedMarker];
    var isSubdestination =
        marker?.infoWindow.title?.contains("Subdestination") ?? false;
    var isAdded = marker?.infoWindow.snippet?.contains("Added") ?? false;
    String occupancy =
        marker?.infoWindow.snippet?.split("Occupancy: ").last ?? "";

    return Positioned(
      left: 50,
      right: 50,
      bottom: 100,
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              marker?.infoWindow.title ?? '',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(
              marker?.infoWindow.snippet ?? '',
              style: TextStyle(color: Colors.white),
            ),
            if (isSubdestination) ...[
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (isAdded)
                    ElevatedButton.icon(
                      onPressed: () => _removeFromSOV(_selectedMarker!.value),
                      icon: Icon(Icons.delete, color: Colors.red),
                      label:
                          Text('Remove', style: TextStyle(color: Colors.red)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black),
                    ),
                  ElevatedButton.icon(
                    onPressed: () {
                      var provider = Provider.of<MyLocationListProvider>(
                          context,
                          listen: false);
                      if (provider.locationProfile?.finalAddress?.campusId ==
                              null ||
                          provider.locationProfile?.finalAddress?.campusId ==
                              '') {
                        _showAddToSOVDialog(
                            marker?.markerId.value ?? "", occupancy);
                      } else {
                        _addToSOV(marker?.markerId.value ?? "",
                            occupancy: occupancy,
                            campusName: provider
                                    .locationProfile?.finalAddress?.campusId ??
                                "");
                      }
                    },
                    icon: Icon(Icons.add, color: Colors.blue),
                    label: Text('Add to SOV',
                        style: TextStyle(color: Colors.blue)),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.black),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<Uint8List> createCustomMarkerBitmap(GlobalKey widgetKey) async {
    RenderRepaintBoundary boundary =
        widgetKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    var image = await boundary.toImage();
    ByteData? byteData = await image.toByteData(format: ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Widget _buildBottomSheet() {
    var typography = CustomTypography(context);
    return WillPopScope(
      onWillPop: () async {
        // Prevent closing when back button is pressed or tap outside
        return false;
      },
      child: Consumer<MyLocationListProvider>(
          builder: (context, locationProfileProvider, child) {
        return AnimatedContainer(
          duration: Duration(milliseconds: 300),
          constraints: BoxConstraints(
            maxHeight: _isBottomSheetExpanded
                ? MediaQuery.of(context).size.height * 0.65
                : 60,
          ),
          // height: _isBottomSheetExpanded ? 600 : 100,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              SizedBox(height: 2),
              if (!_isBottomSheetExpanded && tabIndex == 0) ...[
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    SizedBox(height: 20),
                    ListTile(
                      title: Text(
                        LanguageService.getTranslated(context, "view_info"),
                        // '${widget.accountName}/${widget.subAccountName}-${widget.sovName}/${locationProfileProvider.locationProfile?.finalAddress?.locationIdForRef ?? ''}${formatLocationText((int.tryParse(widget.page) ?? 1) + 0, (int.tryParse(widget.totalPages!) ?? 1))}',
                        style: typography.Subtitle1.copyWith(
                            fontWeight: FontWeight.w800),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      trailing: IconButton(
                        icon: Icon(_isBottomSheetExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down),
                        onPressed: () {
                          setState(() {
                            _isBottomSheetExpanded = !_isBottomSheetExpanded;
                            bottomsheetopened == false
                                ? bottomsheetopened = true
                                : bottomsheetopened = false;
                          });
                          print(_isBottomSheetExpanded.toString());
                          print(bottomsheetopened.toString());
                        },
                      ),
                    ),
                    !_isBottomSheetExpanded
                        ? SizedBox()
                        : Positioned(
                            top: -25,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isBottomSheetExpanded =
                                        !_isBottomSheetExpanded;
                                  });
                                },
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color:
                                        Theme.of(context).colorScheme.surface,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                      width: 1,
                                    ),
                                  ),
                                  child: Icon(Icons.close),
                                ),
                              ),
                            ),
                          ),
                  ],
                ),
              ] else ...[
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.only(left: 13),
                          width: MediaQuery.of(context).size.width / 1.35,
                          child: Text(
                            '${locationProfileProvider.locationProfile?.finalAddress?.locationName ?? ''} ${formatLocationText((int.tryParse(widget.page) ?? 1), (int.tryParse(widget.totalPages!) ?? 1))}',
                            style: TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                        Container(
                          child: Consumer<UserProfileProvider>(
                              builder: (context, userProfileProvider, child) {
                            var trialStatus =
                                userProfileProvider.trialInfo['status'] ?? '';
                            return IconButton(
                              icon: Icon(Icons.download),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return ExportDialog(
                                      accountId: widget.accountId,
                                      subAccountId: widget.subAccountId,
                                      sovId: widget.sovId,
                                      locationId: [
                                        locationProfileProvider.locationProfile
                                                ?.finalAddress?.locationId ??
                                            ''
                                      ],
                                    );
                                  },
                                );
                              },
                            );
                          }),
                        ),
                        IconButton(
                          icon: Icon(_isBottomSheetExpanded
                              ? Icons.close
                              : Icons.keyboard_arrow_down),
                          onPressed: () {
                            setState(() {
                              _isBottomSheetExpanded = !_isBottomSheetExpanded;
                              bottomsheetopened == false
                                  ? bottomsheetopened = true
                                  : bottomsheetopened = false;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width / 1,
                      padding: EdgeInsets.only(left: 16),
                      child: Text(
                        locationProfileProvider
                                .locationProfile?.finalAddress?.address ??
                            'N/A',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: typography.Body1,
                      ),
                    )
                  ],
                ),
                SizedBox(height: 2),
                DefaultTabController(
                  length: 5, // Number of tabs
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TabBar(
                        isScrollable: true,
                        onTap: (index) {
                          if (!mounted) return;

                          final provider = Provider.of<MyLocationListProvider>(
                              context,
                              listen: false);

                          /// CAMPUS TAB
                          if (index == 0) {
                            setState(() => tabIndex = 0);
                            provider.fetchLocations();
                          }

                          if (index == 1) {
                            final locationId = provider
                                .locationProfile?.finalAddress?.locationId;
                            if (locationId != null && locationId.isNotEmpty) {
                              provider.fetchGalleryMedia(
                                context: context,
                                locationId: locationId,
                                forceRefresh:
                                    true, // forces reload every time tab is clicked
                              );
                            }
                          }

                          /// DOCUMENTS TAB
                          if (index == 4) {
                            final locationId =
                                provider.locationProfile?.locationId;

                            if (locationId != null && locationId.isNotEmpty) {
                              provider.fetchDocuments(
                                context: context,
                                locationId: locationId,
                              );
                            }
                          }
                        },
                        tabs: [
                          Tab(
                            text: LanguageService.getTranslated(
                                context, "campus"),
                          ),
                          Tab(
                            text: LanguageService.getTranslated(
                                context, "gallery"),
                          ),
                          Tab(
                            text: LanguageService.getTranslated(
                                context, "activity_log"),
                          ),
                          Tab(
                            text: LanguageService.getTranslated(
                                context, "comments"),
                          ),
                          Tab(text: "Documents"),
                        ],

                        labelPadding: EdgeInsets.only(left: 0, right: 30),

                        automaticIndicatorColorAdjustment: true,
                        // alignment: TabAlignment.start,
                      ),
                      Container(
                        constraints: BoxConstraints(
                          minHeight: 10,
                          maxHeight: Platform.isAndroid
                              ? MediaQuery.of(context).size.height * 0.48
                              : MediaQuery.of(context).size.height * 0.48,
                        ),
                        child: RepaintBoundary(
                          child: TabBarView(
                            physics: NeverScrollableScrollPhysics(),
                            children: [
                              _campusWidget(),
                              _mediaImageWidget(),
                              _activityLogWidget(),
                              _activityCommentsWidget(),
                              _mediaDocumentWidget(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ]
            ],
          ),
        );
      }),
    );
  }

  Widget _campusWidget() {
    var typography = CustomTypography(context);
    return Consumer<MyLocationListProvider>(
        builder: (context, locationProfileProvider, child) {
      return Builder(builder: (context) {
        List<Subdestination> filteredSubdestinations =
            (locationProfileProvider.locationProfile?.subdestinations ?? [])
                .where((sub) {
          final status = (sub.status ?? '').toLowerCase();
          return isSwitched ? status == 'added' : status != 'added';
        }).toList();
        List<Subdestination> allSubdestinations =
            locationProfileProvider.locationProfile?.subdestinations ?? [];

        int addedCount = allSubdestinations
            .where((sub) => (sub.status ?? '').toLowerCase() == 'added')
            .length;

        return Stack(
          children: [
            if (_isBottomSheetExpanded)
              Scrollbar(
                controller: _campusScrollController,
                thumbVisibility: true,
                child: ListView(
                  controller: _campusScrollController,
                  children: [
                    // Campus Id, if present editable
                    if (locationProfileProvider
                                .locationProfile?.finalAddress?.campusId !=
                            null &&
                        locationProfileProvider
                                .locationProfile?.finalAddress?.campusId! !=
                            '')
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Campus',
                                    style: typography.H6.copyWith(height: 1.2)),
                                SizedBox(height: 4),
                                Text(
                                    locationProfileProvider.locationProfile
                                            ?.finalAddress?.campusId ??
                                        '',
                                    style: typography.Body1),
                              ],
                            ),
                            IconButton(
                              icon: Icon(Icons.edit,
                                  color: AppColors.primaryMain),
                              onPressed: () =>
                                  _editCampusId(locationProfileProvider),
                            ),
                          ],
                        ),
                      ),
                    (locationProfileProvider.locationProfile?.subdestinations ??
                                [])
                            .isEmpty
                        ? Container()
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: EdgeInsets.only(left: 10),
                                child: Text(
                                  addedCount == 0
                                      ? 'Campus'
                                      : isSwitched
                                          ? 'Added Campus'
                                          : 'Not Added Campus',
                                  // 'Added Campus',
                                  style: typography.H6.copyWith(height: 1.2),
                                ),
                              ),
                              SizedBox(height: 10),
                              addedCount == 0
                                  ? Container()
                                  : Container(
                                      padding: EdgeInsets.only(right: 8),
                                      child: Switch(
                                        value: isSwitched,
                                        onChanged: (value) {
                                          if (!mounted) return;
                                          setState(() {
                                            isSwitched = value;
                                            isSelectionMode = false;
                                            selectedIds.clear();
                                            // status= value ? "added" : "not added";
                                          });
                                        },
                                        activeThumbColor: Colors.blue,
                                        inactiveThumbColor: Colors.grey,
                                        inactiveTrackColor: Colors.grey[300],
                                      ),
                                    ),
                            ],
                          ),
                    (locationProfileProvider.locationProfile?.subdestinations ??
                                [])
                            .isEmpty
                        ? Center(
                            child: Container(
                                alignment: Alignment.center,
                                height: MediaQuery.of(context).size.height / 2,
                                child: Text(
                                    LanguageService.getTranslated(
                                        context, "no_campus"),
                                    style: typography.Body1)))
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (isSelectionMode)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0, vertical: 8.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${selectedIds.length} selected',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium!
                                            .copyWith(
                                                fontWeight: FontWeight.bold),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          if (!mounted) return;
                                          setState(() {
                                            isSelectionMode = false;
                                            selectedIds.clear();
                                          });
                                        },
                                        child: Text('Clear Selection'),
                                      ),
                                    ],
                                  ),
                                ),
                              Container(
                                constraints: BoxConstraints(
                                  minHeight: 8,
                                  maxHeight: isSwitched
                                      ? MediaQuery.of(context).size.height / 3
                                      : MediaQuery.of(context).size.height / 7,
                                ),
                                child: RepaintBoundary(
                                  child: PageView.builder(
                                    key: const ValueKey('campus_page_view'),
                                    controller: _pageController,
                                    itemCount: filteredSubdestinations.length,
                                    itemBuilder: (context, index) {
                                      int totalItems =
                                          filteredSubdestinations.length;
                                      var subdestination =
                                          filteredSubdestinations[index];
                                      final id = subdestination.id ?? '';
                                      final status =
                                          (subdestination.status ?? '')
                                              .toLowerCase();
                                      final isSelected =
                                          selectedIds.contains(id);
                                      final canSelect = status != 'added';

                                      return GestureDetector(
                                        onTap: () {
                                          if (!canSelect) return;

                                          final currentPage =
                                              _pageController?.page?.round() ??
                                                  0;

                                          setState(() {
                                            isSelectionMode = true;

                                            if (isSelected) {
                                              selectedIds.remove(id);
                                            } else {
                                              selectedIds.add(id);
                                            }

                                            selectedIndex = index;

                                            if (selectedIds.isEmpty) {
                                              isSelectionMode = false;
                                            }
                                          });

                                          WidgetsBinding.instance
                                              .addPostFrameCallback((_) {
                                            if (_pageController?.hasClients ??
                                                false) {
                                              _pageController
                                                  ?.jumpToPage(index);
                                            }
                                          });
                                        },
                                        onLongPress: () {
                                          if (!canSelect) return;

                                          final currentPage =
                                              _pageController?.page?.round() ??
                                                  0;

                                          setState(() {
                                            isSelectionMode = true;

                                            if (isSelected) {
                                              selectedIds.remove(id);
                                            } else {
                                              selectedIds.add(id);
                                            }

                                            selectedIndex = index;

                                            if (selectedIds.isEmpty) {
                                              isSelectionMode = false;
                                            }
                                          });

                                          // Always jump to the selected index, even the first time
                                          WidgetsBinding.instance
                                              .addPostFrameCallback((_) {
                                            if (_pageController?.hasClients ??
                                                false) {
                                              _pageController
                                                  ?.jumpToPage(index);
                                            }
                                          });
                                        },
                                        onDoubleTap: () {
                                          setState(() {
                                            selectedIndex = index;
                                            if (_pageController?.page
                                                    ?.round() !=
                                                index) {
                                              _pageController
                                                  ?.jumpToPage(index);
                                            }
                                          });
                                        },
                                        child: Card(
                                          shape: RoundedRectangleBorder(
                                            side: BorderSide(
                                              color: isSelected && canSelect
                                                  ? Colors.blue
                                                  : Colors.transparent,
                                              width: 2,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          margin: EdgeInsets.symmetric(
                                              vertical: 10, horizontal: 16),
                                          child: Builder(
                                            builder: (context) {
                                              String occupancy =
                                                  (subdestination.rented ??
                                                          false)
                                                      ? 'Rented/Leased'
                                                      : 'Owned';

                                              return Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.stretch,
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  SizedBox(height: 3),
                                                  ListTile(
                                                    leading: canSelect
                                                        ? Checkbox(
                                                            value: isSelected,
                                                            onChanged: (bool?
                                                                checked) {
                                                              if (!canSelect)
                                                                return;

                                                              final currentPage =
                                                                  _pageController
                                                                          ?.page
                                                                          ?.round() ??
                                                                      0;

                                                              setState(() {
                                                                isSelectionMode =
                                                                    true;

                                                                if (isSelected) {
                                                                  selectedIds
                                                                      .remove(
                                                                          id);
                                                                } else {
                                                                  selectedIds
                                                                      .add(id);
                                                                }

                                                                selectedIndex =
                                                                    index;

                                                                if (selectedIds
                                                                    .isEmpty) {
                                                                  isSelectionMode =
                                                                      false;
                                                                }
                                                              });
                                                              WidgetsBinding
                                                                  .instance
                                                                  .addPostFrameCallback(
                                                                      (_) {
                                                                if (_pageController
                                                                        ?.hasClients ??
                                                                    false) {
                                                                  _pageController
                                                                      ?.jumpToPage(
                                                                          index);
                                                                }
                                                              });
                                                            },
                                                          )
                                                        : null,
                                                    title: Text(
                                                      '${index + 1}. ${subdestination.name ?? ''}',
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    subtitle: Text(
                                                      subdestination.address ??
                                                          '',
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  if (status == 'added') ...[
                                                    Padding(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 16.0),
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          Text("Occupancy Type",
                                                              style: typography
                                                                  .Body1),
                                                          Chip(
                                                            padding:
                                                                EdgeInsets.all(
                                                                    12),
                                                            label: Text(
                                                              subdestination
                                                                      .status ??
                                                                  "Not Added",
                                                              style: typography
                                                                  .Body1,
                                                            ),
                                                            backgroundColor:
                                                                Colors.green,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Row(
                                                      children: [
                                                        Radio<String>(
                                                          value: "Owned",
                                                          groupValue: occupancy,
                                                          onChanged: isLoading
                                                              ? null
                                                              : (value) async {
                                                                  if (value ==
                                                                          null ||
                                                                      !mounted)
                                                                    return;
                                                                  setState(() {
                                                                    occupancy =
                                                                        value;
                                                                    subdestination
                                                                            .rented =
                                                                        false;
                                                                    isLoading =
                                                                        true;
                                                                    selectedLoadingType =
                                                                        value;
                                                                  });

                                                                  var provider = Provider.of<
                                                                          MyLocationListProvider>(
                                                                      context,
                                                                      listen:
                                                                          false);
                                                                  bool result =
                                                                      await provider
                                                                          .changeOccupancy(
                                                                    context,
                                                                    subdestination
                                                                            .locationId ??
                                                                        "",
                                                                    false,
                                                                    provider
                                                                            .locationProfile
                                                                            ?.finalAddress
                                                                            ?.locationId ??
                                                                        "",
                                                                  );

                                                                  if (!mounted)
                                                                    return;
                                                                  setState(() {
                                                                    isLoading =
                                                                        false;
                                                                    selectedLoadingType =
                                                                        null;
                                                                  });

                                                                  if (!result) {
                                                                    _showErrorSnackBar();
                                                                    if (!mounted)
                                                                      return;
                                                                    setState(
                                                                        () {
                                                                      occupancy =
                                                                          "Rented/Leased";
                                                                      subdestination
                                                                              .rented =
                                                                          true;
                                                                    });
                                                                  }
                                                                },
                                                        ),
                                                        Text("Owned"),
                                                        if (isLoading &&
                                                            selectedLoadingType ==
                                                                "Owned")
                                                          SizedBox(
                                                            width: 16,
                                                            height: 16,
                                                            child:
                                                                CircularProgressIndicator(
                                                                    strokeWidth:
                                                                        2),
                                                          ),
                                                        Radio<String>(
                                                          value:
                                                              "Rented/Leased",
                                                          groupValue: occupancy,
                                                          onChanged: isLoading
                                                              ? null
                                                              : (value) async {
                                                                  if (value ==
                                                                          null ||
                                                                      !mounted)
                                                                    return;
                                                                  setState(() {
                                                                    occupancy =
                                                                        value;
                                                                    subdestination
                                                                            .rented =
                                                                        true;
                                                                    isLoading =
                                                                        true;
                                                                    selectedLoadingType =
                                                                        value;
                                                                  });

                                                                  var provider = Provider.of<
                                                                          MyLocationListProvider>(
                                                                      context,
                                                                      listen:
                                                                          false);
                                                                  bool result =
                                                                      await provider
                                                                          .changeOccupancy(
                                                                    context,
                                                                    subdestination
                                                                            .locationId ??
                                                                        "",
                                                                    true,
                                                                    provider
                                                                            .locationProfile
                                                                            ?.finalAddress
                                                                            ?.locationId ??
                                                                        "",
                                                                  );

                                                                  if (!mounted)
                                                                    return;
                                                                  setState(() {
                                                                    isLoading =
                                                                        false;
                                                                    selectedLoadingType =
                                                                        null;
                                                                  });

                                                                  if (!result) {
                                                                    _showErrorSnackBar();
                                                                    if (!mounted)
                                                                      return;
                                                                    setState(
                                                                        () {
                                                                      occupancy =
                                                                          "Owned";
                                                                      subdestination
                                                                              .rented =
                                                                          false;
                                                                    });
                                                                  }
                                                                },
                                                        ),
                                                        Text("Rented/Leased"),
                                                        if (isLoading &&
                                                            selectedLoadingType ==
                                                                "Rented/Leased")
                                                          SizedBox(
                                                            width: 16,
                                                            height: 16,
                                                            child:
                                                                CircularProgressIndicator(
                                                                    strokeWidth:
                                                                        2),
                                                          ),
                                                        Text(totalItems
                                                            .toString()),
                                                      ],
                                                    ),
                                                  ],
                                                  SizedBox(height: 8),
                                                ],
                                              );
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                    onPageChanged: (index) {
                                      if (!mounted) return;

                                      setState(() {
                                        selectedIndex = index;
                                      });

                                      if (index <
                                          filteredSubdestinations.length) {
                                        _focusOnSubdestination(
                                            filteredSubdestinations[index]);
                                      }
                                    },

                                    // onPageChanged: (index) {
                                    //   setState(() {
                                    //     selectedIndex = index;
                                    //   });
                                    //
                                    //   var subdestination = locationProfileProvider
                                    //       .subdestinations[index];
                                    //   _focusOnSubdestination(subdestination);
                                    // },
                                  ),
                                ),
                              ),

                              SizedBox(height: 150),
                              if (isSelectionMode && !isSwitched)
                                Align(
                                  alignment: Alignment.bottomCenter,
                                  child: SafeArea(
                                    top: false,
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0,
                                        vertical: 12.0,
                                      ),
                                      decoration: const BoxDecoration(
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black26,
                                            blurRadius: 8,
                                            offset: Offset(0, -2),
                                          ),
                                        ],
                                      ),
                                      child: CustomButton(
                                        type: ButtonType.elevated,
                                        onPressed: () async {
                                          Set<String> tempSelectedIds =
                                              Set.from(selectedIds);

                                          await showDialog(
                                            context: context,
                                            barrierDismissible: false,
                                            builder: (context) {
                                              bool confirmload = false;

                                              return StatefulBuilder(
                                                builder:
                                                    (context, setStateDialog) {
                                                  return AlertDialog(
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                    ),
                                                    title: const Text(
                                                        "Confirm Add to Campus"),
                                                    content: SizedBox(
                                                      width: double.maxFinite,
                                                      height:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .height /
                                                              3,
                                                      child: ListView.separated(
                                                        itemCount:
                                                            tempSelectedIds
                                                                .length,
                                                        separatorBuilder: (_,
                                                                __) =>
                                                            const SizedBox(
                                                                height: 12),
                                                        itemBuilder:
                                                            (context, index) {
                                                          final selectedId =
                                                              tempSelectedIds
                                                                      .toList()[
                                                                  index];
                                                          final item =
                                                              filteredSubdestinations
                                                                  .firstWhere(
                                                            (e) =>
                                                                e.id ==
                                                                selectedId,
                                                          );

                                                          return Row(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Checkbox(
                                                                value: tempSelectedIds
                                                                    .contains(
                                                                        selectedId),
                                                                onChanged:
                                                                    (bool?
                                                                        value) {
                                                                  setStateDialog(
                                                                      () {
                                                                    if (value ==
                                                                        true) {
                                                                      tempSelectedIds
                                                                          .add(
                                                                              selectedId);
                                                                    } else {
                                                                      tempSelectedIds
                                                                          .remove(
                                                                              selectedId);
                                                                    }
                                                                  });
                                                                },
                                                              ),
                                                              Expanded(
                                                                child: Column(
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .start,
                                                                  children: [
                                                                    Text(item
                                                                            .name ??
                                                                        "Unnamed Location"),
                                                                    if (item.address !=
                                                                        null)
                                                                      Text(
                                                                        item.address!,
                                                                        style:
                                                                            const TextStyle(
                                                                          fontSize:
                                                                              12,
                                                                          color:
                                                                              Colors.grey,
                                                                        ),
                                                                      ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ],
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.of(
                                                                    context)
                                                                .pop(),
                                                        child: const Text(
                                                            "Cancel"),
                                                      ),
                                                      ElevatedButton(
                                                        onPressed: confirmload
                                                            ? null
                                                            : () async {
                                                                setStateDialog(
                                                                    () {
                                                                  confirmload =
                                                                      true;
                                                                });

                                                                try {
                                                                  final provider =
                                                                      Provider.of<
                                                                          MyLocationListProvider>(
                                                                    context,
                                                                    listen:
                                                                        false,
                                                                  );

                                                                  final campusId = provider
                                                                          .locationProfile
                                                                          ?.finalAddress
                                                                          ?.campusId ??
                                                                      "";

                                                                  for (final id
                                                                      in tempSelectedIds) {
                                                                    final subdestination =
                                                                        filteredSubdestinations
                                                                            .firstWhere(
                                                                      (e) =>
                                                                          e.id ==
                                                                          id,
                                                                    );

                                                                    final occupancy = (subdestination.rented ??
                                                                            false)
                                                                        ? 'Rented/Leased'
                                                                        : 'Owned';

                                                                    await _addToSOV(
                                                                      subdestination
                                                                              .id ??
                                                                          "",
                                                                      occupancy:
                                                                          occupancy,
                                                                      campusName:
                                                                          campusId,
                                                                    );
                                                                  }

                                                                  if (!mounted)
                                                                    return;

                                                                  setState(() {
                                                                    selectedIds
                                                                        .clear();
                                                                    isSelectionMode =
                                                                        false;
                                                                    isLoadingAddToCampus =
                                                                        false;
                                                                  });

                                                                  await _fetchAllData();

                                                                  if (context
                                                                      .mounted) {
                                                                    widget
                                                                        .onConfirmCallback
                                                                        ?.call();
                                                                    _getData();
                                                                    _initializeClusterManager();
                                                                    await _refreshData();
                                                                    Navigator.of(
                                                                            context)
                                                                        .pop(
                                                                            true);
                                                                  }
                                                                } finally {
                                                                  if (context
                                                                      .mounted) {
                                                                    setStateDialog(
                                                                        () {
                                                                      confirmload =
                                                                          false;
                                                                    });
                                                                  }
                                                                }
                                                              },
                                                        child: confirmload
                                                            ? const SizedBox(
                                                                width: 20,
                                                                height: 20,
                                                                child:
                                                                    CircularProgressIndicator(
                                                                  strokeWidth:
                                                                      2,
                                                                  color: Colors
                                                                      .white,
                                                                ),
                                                              )
                                                            : const Text(
                                                                "Confirm"),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );
                                            },
                                          );
                                        },
                                        child: isLoadingAddToCampus
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                          Color>(Colors.white),
                                                ),
                                              )
                                            : const Text(
                                                'Confirm Add to Campus',
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 16,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                ),

                              //old
                              // if (isSelectionMode && !isSwitched)
                              //
                              //  SafeArea(
                              //       top: false,
                              //       child: Container(
                              //         width: double.infinity,
                              //         padding: const EdgeInsets.symmetric(
                              //             horizontal: 16.0, vertical: 12.0),
                              //         decoration: BoxDecoration(
                              //           // color: Colors.white,
                              //           boxShadow: [
                              //             BoxShadow(
                              //               color: Colors.black26,
                              //               blurRadius: 8,
                              //               offset: Offset(0, -2),
                              //             ),
                              //           ],
                              //         ),
                              //         child: CustomButton(
                              //           type: ButtonType.elevated,
                              //           onPressed: () async {
                              //             Set<String> tempSelectedIds =
                              //                 Set.from(selectedIds);
                              //             await showDialog(
                              //               context: context,
                              //               barrierDismissible: false,
                              //               builder: (context) {
                              //                 bool confirmload = false;
                              //
                              //                 return StatefulBuilder(
                              //                   builder:
                              //                       (context, setStateDialog) {
                              //                     return AlertDialog(
                              //                       shape:
                              //                           RoundedRectangleBorder(
                              //                         borderRadius:
                              //                             BorderRadius.circular(
                              //                                 10),
                              //                       ),
                              //                       title: Text(
                              //                           "Confirm Add to Campus"),
                              //                       content: SizedBox(
                              //                         width: double.maxFinite,
                              //                         height:
                              //                             MediaQuery.of(context)
                              //                                     .size
                              //                                     .height /
                              //                                 3,
                              //                         child: ListView.separated(
                              //                           itemCount:
                              //                               tempSelectedIds
                              //                                   .length,
                              //                           separatorBuilder:
                              //                               (_, __) => SizedBox(
                              //                                   height: 12),
                              //                           itemBuilder:
                              //                               (context, index) {
                              //                             final selectedId =
                              //                                 tempSelectedIds
                              //                                         .toList()[
                              //                                     index];
                              //                             final item =
                              //                                 filteredSubdestinations
                              //                                     .firstWhere(
                              //                               (element) =>
                              //                                   element.id ==
                              //                                   selectedId,
                              //                             );
                              //
                              //                             return Row(
                              //                               crossAxisAlignment:
                              //                                   CrossAxisAlignment
                              //                                       .start,
                              //                               children: [
                              //                                 Checkbox(
                              //                                   value: tempSelectedIds
                              //                                       .contains(
                              //                                           selectedId),
                              //                                   onChanged:
                              //                                       (bool?
                              //                                           value) {
                              //                                     setStateDialog(
                              //                                         () {
                              //                                       if (value ==
                              //                                           true) {
                              //                                         tempSelectedIds
                              //                                             .add(
                              //                                                 selectedId);
                              //                                       } else {
                              //                                         tempSelectedIds
                              //                                             .remove(
                              //                                                 selectedId);
                              //                                       }
                              //                                     });
                              //                                   },
                              //                                 ),
                              //                                 Expanded(
                              //                                   child: Column(
                              //                                     crossAxisAlignment:
                              //                                         CrossAxisAlignment
                              //                                             .start,
                              //                                     children: [
                              //                                       Text(item
                              //                                               .name ??
                              //                                           "Unnamed Location"),
                              //                                       if (item.address !=
                              //                                           null)
                              //                                         Text(
                              //                                           item.address!,
                              //                                           style: TextStyle(
                              //                                               fontSize:
                              //                                                   12,
                              //                                               color:
                              //                                                   Colors.grey),
                              //                                         ),
                              //                                     ],
                              //                                   ),
                              //                                 ),
                              //                               ],
                              //                             );
                              //                           },
                              //                         ),
                              //                       ),
                              //                       actions: [
                              //                         TextButton(
                              //                           onPressed: () =>
                              //                               Navigator.of(
                              //                                       context)
                              //                                   .pop(),
                              //                           child: Text("Cancel"),
                              //                         ),
                              //                         ElevatedButton(
                              //                           onPressed: confirmload
                              //                               ? null
                              //                               : () async {
                              //                                   setStateDialog(
                              //                                       () {
                              //                                     confirmload =
                              //                                         true;
                              //                                   });
                              //                                   try {
                              //                                     var provider = Provider.of<
                              //                                             MyLocationListProvider>(
                              //                                         context,
                              //                                         listen:
                              //                                             false);
                              //                                     final campusId = provider
                              //                                             .locationProfile
                              //                                             ?.finalAddress
                              //                                             ?.campusId ??
                              //                                         "";
                              //
                              //                                     for (String id
                              //                                         in tempSelectedIds) {
                              //                                       final subdestination =
                              //                                           filteredSubdestinations.firstWhere((item) =>
                              //                                               item.id ==
                              //                                               id);
                              //                                       String occupancy = (subdestination.rented ??
                              //                                               false)
                              //                                           ? 'Rented/Leased'
                              //                                           : 'Owned';
                              //
                              //                                       await _addToSOV(
                              //                                         subdestination
                              //                                                 .id ??
                              //                                             "",
                              //                                         occupancy:
                              //                                             occupancy,
                              //                                         campusName:
                              //                                             campusId,
                              //                                       );
                              //                                     }
                              //
                              //                                     setState(() {
                              //                                       selectedIds
                              //                                           .clear();
                              //                                       isLoadingAddToCampus =
                              //                                           false;
                              //                                       isSelectionMode =
                              //                                           false;
                              //                                     });
                              //                                     await _fetchAllData();
                              //
                              //                                     if (context
                              //                                         .mounted) {
                              //                                       widget
                              //                                           .onConfirmCallback
                              //                                           ?.call();
                              //                                       _getData();
                              //                                       _initializeClusterManager();
                              //                                       await _refreshData();
                              //                                       Navigator.of(
                              //                                               context)
                              //                                           .pop(
                              //                                               true);
                              //                                     }
                              //                                   } finally {
                              //                                     if (context
                              //                                         .mounted) {
                              //                                       setStateDialog(
                              //                                           () {
                              //                                         confirmload =
                              //                                             false;
                              //                                       });
                              //                                     }
                              //                                   }
                              //                                 },
                              //                           child: confirmload
                              //                               ? SizedBox(
                              //                                   width: 20,
                              //                                   height: 20,
                              //                                   child:
                              //                                       CircularProgressIndicator(
                              //                                     strokeWidth:
                              //                                         2,
                              //                                     color: Colors
                              //                                         .white,
                              //                                   ),
                              //                                 )
                              //                               : Text("Confirm"),
                              //                         ),
                              //                       ],
                              //                     );
                              //                   },
                              //                 );
                              //               },
                              //             );
                              //           },
                              //           child: isLoadingAddToCampus
                              //               ? SizedBox(
                              //                   width: 20,
                              //                   height: 20,
                              //                   child:
                              //                       CircularProgressIndicator(
                              //                     strokeWidth: 2,
                              //                     valueColor:
                              //                         AlwaysStoppedAnimation<
                              //                             Color>(Colors.white),
                              //                   ),
                              //                 )
                              //               : Text(
                              //                   'Confirm Add to Campus',
                              //                   style: TextStyle(
                              //                     color: Colors.black,
                              //                     fontWeight: FontWeight.w600,
                              //                     fontSize: 16,
                              //                   ),
                              //                 ),
                              //         ),
                              //       ),
                              //     ),
                            ],
                          ),
                  ],
                ),
              ),
          ],
        );
      });
    });
  }

  void _showErrorSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to change occupancy'),
      ),
    );
  }

  Widget _buildLocalImage(File image, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(
              image,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: _deleteIcon(
              onTap: () {
                setState(() {
                  _images.removeAt(index);
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _mediaImageWidget() {
    final typography = CustomTypography(context);

    return Consumer<MyLocationListProvider>(
      builder: (context, provider, _) {
        final profile = provider.locationProfile;
        final bool showGoogleImage = profile?.geocodingScore == 5;

        final int galleryCount = provider.galleryMedia.length;
        final int screenshotsCount = profile?.screenshots?.length ?? 0;

        // ✅ All three sources combined
        final int totalItemCount = _images.length +
            galleryCount +
            screenshotsCount +
            (showGoogleImage ? 1 : 0);

        return Stack(
          children: [
            if (_isBottomSheetExpanded)
              Scrollbar(
                thumbVisibility: true,
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 100),
                  children: [
                    const SizedBox(height: 10),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        LanguageService.getTranslated(context, "images"),
                        style: typography.H6.copyWith(height: 1.2),
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// LOADING
                    if (provider.isGalleryLoading || provider.isUploadingImage)
                      SizedBox(
                        height: MediaQuery.of(context).size.height / 3.5,
                        child: const Center(child: CircularProgressIndicator()),
                      )

                    /// IMAGES
                    else if (totalItemCount > 0)
                      Column(
                        children: [
                          Container(
                            height: MediaQuery.of(context).size.height / 3.5,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                            ),
                            child: PageView.builder(
                              itemCount: totalItemCount,
                              itemBuilder: (context, index) {
                                /// 1️⃣ LOCAL IMAGES (picked, not yet uploaded)
                                if (index < _images.length) {
                                  return _buildLocalImage(
                                      _images[index], index);
                                }

                                /// 2️⃣ GALLERY MEDIA FROM API
                                final galleryStartIndex = _images.length;
                                final galleryEndIndex =
                                    _images.length + galleryCount;

                                if (index >= galleryStartIndex &&
                                    index < galleryEndIndex) {
                                  final galleryIndex = index - _images.length;
                                  final item =
                                      provider.galleryMedia[galleryIndex];
                                  final String? imageUrl = item['url'] is List
                                      ? (item['url'] as List).isNotEmpty
                                          ? item['url'][0]?.toString()
                                          : null
                                      : item['url']?.toString();
                                  // final String? imageUrl =
                                  //     item['url'];
                                  final String name = item['name'] ?? '';
                                  final String isMedia =
                                      item['is_location_media'].toString();
                                  final String date = item['date'] ?? '';
                                  final String time = item['time'] ?? '';

                                  if (imageUrl == null || imageUrl.isEmpty) {
                                    return const Center(
                                      child: Icon(Icons.broken_image_outlined,
                                          size: 48),
                                    );
                                  }

                                  return _buildServerImage(
                                    isMedia,
                                    Screenshots(
                                      imageUrl: imageUrl,
                                      name: name,
                                      date: date,
                                      time: time,
                                    ),
                                    galleryIndex,
                                    provider,
                                  );
                                }

                                /// 3️⃣ SCREENSHOTS FROM PROFILE
                                final screenshotsStartIndex = galleryEndIndex;
                                final screenshotsEndIndex =
                                    galleryEndIndex + screenshotsCount;

                                if (index >= screenshotsStartIndex &&
                                    index < screenshotsEndIndex) {
                                  final screenshotIndex =
                                      index - screenshotsStartIndex;
                                  final screenshot =
                                      profile!.screenshots![screenshotIndex];

                                  // ✅ Handle missing imageUrl in screenshots too
                                  if (screenshot.imageUrl == null ||
                                      screenshot.imageUrl!.isEmpty) {
                                    return const Center(
                                      child: Icon(Icons.broken_image_outlined,
                                          size: 48),
                                    );
                                  }

                                  return _buildServerImage(
                                    '1',
                                    screenshot,
                                    screenshotIndex,
                                    provider,
                                  );
                                }

                                /// 4️⃣ GOOGLE STREET VIEW (only if geocodingScore == 5)
                                if (showGoogleImage) {
                                  return _buildGoogleImage(profile);
                                }

                                return const SizedBox();
                              },
                            ),
                          ),
                          const SizedBox(height: 50),
                        ],
                      )

                    /// EMPTY
                    else
                      SizedBox(
                        height: MediaQuery.of(context).size.height / 3,
                        child: Center(
                          child: Text(
                            LanguageService.getTranslated(context, "no_images"),
                            style: typography.Body1,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

            /// UPLOAD BUTTON
            if (_isBottomSheetExpanded)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 12),
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: CustomButton(
                      type: ButtonType.elevated,
                      onPressed: _pickImage,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.upload_sharp,
                              color: Colors.black, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            LanguageService.getTranslated(
                                context, "upload_relevant_images"),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void removeGalleryMedia(int index) {
    if (index >= 0 && index < galleryMedia.length) {
      galleryMedia.removeAt(index);
      // notifyListeners();
    }
  }

  Widget _buildServerImage(
    String isMedia,
    Screenshots screenshot,
    int screenshotIndex,
    MyLocationListProvider provider,
  ) {
    final String? url = screenshot.imageUrl;

    if (url == null || url.isEmpty) {
      return const Center(
        child: Icon(Icons.broken_image, size: 40),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.network(
                url,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(Icons.broken_image, size: 40),
                  );
                },
              ),
            ),
            // Text(isMedia.toString()),

            /// DELETE ICON
            Positioned(
                top: 10,
                right: 10,
                child: isMedia == "false"
                    ? const SizedBox() // Don't show delete icon for location media
                    : _deleteIcon(
                        onTap: () async {
                          final item = provider.galleryMedia[screenshotIndex];
                          final String? imageId = item['id'] as String?;
                          final locationId = provider
                              .locationProfile?.finalAddress?.locationId;

                          if (imageId == null || locationId == null) return;

                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Delete Image?'),
                              content:
                                  const Text('This action cannot be undone.'),
                              actions: [
                                TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancel')),
                                TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Delete')),
                              ],
                            ),
                          );

                          if (confirmed != true) return;

                          await provider.deleteGalleryImage(
                            context: context,
                            locationId: locationId,
                            imageId: imageId,
                            imageUrl: url,
                            // <-- pass image_url from galleryMedia item
                            index: screenshotIndex,
                          );
                          // await provider.deleteGalleryImage(
                          //   context: context,
                          //   locationId: locationId,
                          //   imageId: imageId,        // <-- passing imageId just like documentId
                          //   index: screenshotIndex,
                          // );
                        },
                      )),

            /// BOTTOM INFO OVERLAY
            Positioned(
              left: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    /// NAME
                    Text(
                      isMedia == "false"
                          ? screenshot.name?.isNotEmpty == true
                              ? "data parameter : " + screenshot.name!
                              : 'Unknown'
                          : screenshot.name?.isNotEmpty == true
                              ? screenshot.name!
                              : 'Unknown',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    if (isMedia == "false") ...[
                      const SizedBox(height: 4),

                      /// DATE + TIME
                      Text(
                        '${screenshot.date ?? ''} ${screenshot.time ?? ''}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleImage(MyLocation? profile) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            /// IMAGE
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl:
                    "https://maps.googleapis.com/maps/api/streetview?size=600x300&location=${profile?.finalAddress?.latitude ?? 0},${profile?.finalAddress?.longitude ?? 0}&key=AIzaSyBA8NoBrHa9JwGQT8Mk1s9lXqElfON_NGI",
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                errorWidget: (context, url, error) =>
                    const Center(child: Icon(Icons.location_on, size: 40)),
              ),
            ),

            /// GOOGLE TEXT OVERLAY (FIXED)
            Positioned(
              left: 8,
              right: 200,
              bottom: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: const [
                    Text(
                      '@',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Resource from Google',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _deleteIcon({required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.delete, color: Colors.red, size: 20),
      ),
    );
  }

  Widget _mediaDocumentWidget() {
    final typography = CustomTypography(context);

    return Consumer<MyLocationListProvider>(
      builder: (context, provider, _) {
        return RefreshIndicator(
          onRefresh: () async {
            await provider.fetchDocuments(
              context: context,
              locationId: provider.locationProfile!.locationId!,
              forceRefresh: true,
            );
          },
          child: Scrollbar(
            thumbVisibility: true,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 10),

                /// HEADER
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    "Documents",
                    style: typography.H6.copyWith(height: 1.2),
                  ),
                ),

                const SizedBox(height: 20),

                /// LOADING
                if (provider.isDocumentsLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()),
                  )

                /// EMPTY
                else if (provider.documents.isEmpty &&
                    !provider.isDocumentsLoading)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 60),
                      child: Text("No Documents", style: typography.Body1),
                    ),
                  )

                /// EXISTING DOCUMENT LIST
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: provider.documents.length,
                    itemBuilder: (context, index) {
                      final doc = provider.documents[index];

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              const Icon(Icons.description),
                              const SizedBox(width: 10),
                              // Text(doc.

                              /// DOCUMENT NAME
                              Expanded(
                                child: InkWell(
                                  onTap: doc.url!.isEmpty
                                      ? null
                                      : () => _previewDocument(doc.url!),
                                  child: Text(
                                    doc.name!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              if (doc.isLocationMedia!) ...[
                                provider.deletingDocumentId == doc.id
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () async {
                                          final locationId = provider
                                              .locationProfile!.locationId!;

                                          await provider.deleteDocument(
                                            context: context,
                                            locationId: locationId,
                                            documentId: doc.id!,
                                            imageUrl: doc.url!.isNotEmpty
                                                ? doc.url!
                                                : "",
                                          );
                                        },
                                      ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                /// SELECTED FILE PREVIEW
                if (_selectedFiles.isNotEmpty) ...[
                  // const SizedBox(height: 20),
                  // Padding(
                  //   padding: const EdgeInsets.symmetric(horizontal: 16),
                  //   child: Text(
                  //     "Selected Files",
                  //     style: typography.H6,
                  //   ),
                  // ),
                  // const SizedBox(height: 10),
                  ..._selectedFiles.map((file) {
                    final isTooLarge = file.size > maxFileSize;

                    return Card(
                      color: Colors.grey[900],
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      child: ListTile(
                        leading: const Icon(Icons.insert_drive_file,
                            color: Colors.white),
                        title: Text(
                          file.name,
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          "${(file.size / (1024 * 1024)).toStringAsFixed(2)} MB",
                          style: TextStyle(
                            color: isTooLarge ? Colors.red : Colors.white70,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _selectedFiles.remove(file);
                              _isSizeExceeded = _selectedFiles
                                  .any((f) => f.size > maxFileSize);
                            });
                          },
                        ),
                      ),
                    );
                  }).toList(),
                ],

                const SizedBox(height: 30),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Consumer<MyLocationListProvider>(
                    builder: (context, provider, _) {
                      return CustomButton(
                        type: ButtonType.elevated,
                        onPressed: (_isSizeExceeded ||
                                provider.isUploadingDocument)
                            ? null
                            : () async {
                                /// STEP 1: Pick files
                                await _pickDocuments();

                                if (_isSizeExceeded || _selectedFiles.isEmpty) {
                                  return;
                                }

                                final locationId =
                                    provider.locationProfile!.locationId!;

                                /// STEP 2: Upload each file
                                for (var file in _selectedFiles) {
                                  try {
                                    if (file.path != null) {
                                      await provider.uploadDocument(
                                        context: context,
                                        locationId: locationId,
                                        file: File(file.path!),
                                        fileName: file.name,
                                      );
                                    } else if (file.bytes != null) {
                                      await provider.uploadDocumentFromBytes(
                                        context: context,
                                        locationId: locationId,
                                        bytes: file.bytes!,
                                        fileName: file.name,
                                      );
                                    }
                                  } catch (e) {
                                    debugPrint("Upload error: $e");
                                  }
                                }

                                /// STEP 3: Clear selected files
                                setState(() {
                                  _selectedFiles.clear();
                                });

                                /// STEP 4: Refresh document list
                                await provider.fetchDocuments(
                                  context: context,
                                  locationId: locationId,
                                  forceRefresh: true,
                                );
                              },
                        child: provider.isUploadingDocument
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : Row(
                                children: const [
                                  Icon(Icons.upload_sharp, color: Colors.black),
                                  SizedBox(width: 20),
                                  Text(
                                    "Upload relevant document(s)",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _previewDocument(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not open document');
    }
  }

  void _showDocumentActions({
    required BuildContext context,
    required LocationDocument document,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.visibility),
                title: const Text('Preview'),
                onTap: () {
                  Navigator.pop(context);
                  _previewDocument(document.urls.first);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  Navigator.pop(context);

                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Delete document?'),
                      content: const Text('This action cannot be undone.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    final provider = Provider.of<MyLocationListProvider>(
                      context,
                      listen: false,
                    );

                    provider.deleteDocument(
                      context: context,
                      locationId: provider.locationProfile!.locationId!,
                      documentId: document.id,
                      imageUrl: document.urls.first,
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _activityLogWidget() {
    return Consumer<MyLocationListProvider>(
      builder: (context, provider, child) {
        final logs = provider.allAcitivityLogs.length;

        return _isBottomSheetExpanded
            ? Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: List.generate(provider.allAcitivityLogs.length,
                          (index) {
                        final log = provider.allAcitivityLogs[index];

                        final action = log.action ?? "";
                        final targetId = log.targetId?.toString() ?? "";
                        final time = log.at?.iSeconds ?? 0;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.grey[800],
                                child: const Text(
                                  "N",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      action,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                    // const SizedBox(height: 4),
                                    // Text(
                                    //   "Location • $targetId",
                                    //   maxLines: 2,
                                    //   overflow: TextOverflow.ellipsis,
                                    //   style: TextStyle(
                                    //     color: Colors.grey[400],
                                    //     fontSize: 13,
                                    //   ),
                                    // ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _formatTimestamp(time),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              )
            : const SizedBox();
      },
    );
  }

  Widget _activityCommentsWidget() {
    return Consumer<MyLocationListProvider>(
      builder: (context, locationProfileProvider, child) {
        return Stack(
          children: [
            if (_isBottomSheetExpanded)
              Padding(
                padding: const EdgeInsets.only(bottom: 60),
                // space for input box

                child: ScrollbarTheme(
                  data: ScrollbarThemeData(
                    thumbColor:
                        WidgetStateProperty.all(Colors.lightBlueAccent),
                    trackColor: WidgetStateProperty.all(Colors.black26),
                    thickness: WidgetStateProperty.all(3),
                    // move thickness here
                    radius: const Radius.circular(8),
                  ),
                  child: Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    thickness: 3,
                    radius: const Radius.circular(8),
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(12),
                      itemCount: locationProfileProvider
                          .locationProfile!.locationComments!.length,
                      itemBuilder: (context, index) {
                        final log = locationProfileProvider
                            .locationProfile!.locationComments![index];

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.grey[800],
                                    child: Text(
                                      log.user != null &&
                                              log.user!.name!.isNotEmpty
                                          ? log.user!.name![0].toUpperCase()
                                          : "?",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  /// Comment content
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          log.user?.name ?? "Unknown",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatTimestamp(
                                              log.updatedAt!.iSeconds),
                                          style: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              /// Message
                              Container(
                                padding:
                                    const EdgeInsets.only(top: 12, left: 5),
                                child: Text(
                                  log.comment ?? "",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

            /// Input Box
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                color: Colors.black,
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _commentController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: LanguageService.getTranslated(
                              context, "enter_message_here"),
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white24),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.blue),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          suffixIcon: Container(
                            margin: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.lightBlue,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              icon: _isSending
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.send, color: Colors.black),
                              onPressed: _isSending
                                  ? null
                                  : () async {
                                      final commentText =
                                          _commentController.text.trim();
                                      if (commentText.isNotEmpty) {
                                        setState(() {
                                          _isSending = true;
                                        });

                                        try {
                                          // 🔹 1. Call the provider API
                                          final response =
                                              await locationProfileProvider
                                                  .addCommentsLocation(
                                            context,
                                            locationProfileProvider
                                                .locationProfile!
                                                .finalAddress!
                                                .locationId
                                                .toString(),
                                            commentText,
                                          );

                                          // 🔹 2. If API returned success and comments
                                          if (response != null &&
                                              response['location_comments'] !=
                                                  null) {
                                            // ✅ Declare updatedComments locally here
                                            final updatedComments =
                                                (response['location_comments']
                                                        as List)
                                                    .map((c) => LocationComments
                                                        .fromJson(c))
                                                    .toList();

                                            // 🔹 3. Update provider data
                                            locationProfileProvider
                                                    .locationProfile!
                                                    .locationComments =
                                                updatedComments;

                                            // 🔹 4. Notify listeners to rebuild UI
                                            locationProfileProvider
                                                .notifyListeners();

                                            // 🔹 5. Clear text field
                                            _commentController.clear();
                                          }
                                        } catch (e) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    "Failed to send comment")),
                                          );
                                        } finally {
                                          setState(() {
                                            _isSending = false;
                                          });
                                        }
                                      }
                                    },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void showLocationDetailsPopup(BuildContext context, MyLocation location,
      [bool hideNavigation = false]) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return LocationDetailsPopup(
          // location.overallScore ?? 0,
          address: location.finalAddress?.address ?? 'Unknown Address',
          locationId: location.finalAddress?.locationId ?? 'Unknown ID',
          geocodingScore: location.finalAddress?.score ?? 0,
          riskScore: location.overallScore ?? 5,
          dataCompleteness: (location.dataCompleteness == null
              ? ''
              : (location.dataCompleteness! == 0
                  ? '1'
                  : location.dataCompleteness!.toString())),
          // scoreToStar(
          //     location.dataCompleteness == 0 ? 1 : location.dataCompleteness),
          hazards: location.hazard ?? {},
          geocodedAt: [location.finalAddress?.locationType ?? ""],
          occupancy: location.finalAddress?.placeTypes ?? ["--"],
          campus: location.finalAddress?.campusId,
          rented: location.finalAddress?.rented,
          accountId: widget.accountId,
          subAccountId: widget.subAccountId,
          sovId: widget.sovId,
          accountName: widget.accountName,
          subAccountName: widget.subAccountName,
          sovName: widget.sovName,
          hideNavigation: hideNavigation,
          hazardProcess: widget.hazardProcess,
        );
      },
    );
  }

  Widget _locationProfileBody() {
    var typography = CustomTypography(context);
    return Consumer<MyLocationListProvider>(
        builder: (context, locationProfileProvider, child) {
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            ListTile(
              title: Text(
                '${widget.accountName}/${widget.subAccountName}-${widget.sovName}/${locationProfileProvider.locationProfile?.finalAddress?.locationIdForRef ?? ''}${formatLocationText((int.tryParse(widget.page) ?? 1) + 0, (int.tryParse(widget.totalPages!) ?? 1))}',
                style: typography.H6.copyWith(height: 1.2),
              ),
              trailing: IconButton(
                icon: Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _isBottomSheetFullScreen = false;
                  });
                },
              ),
            ),
            Divider(),
            Expanded(
              child: ListView(
                children: [
                  ListTile(
                    title: Row(
                      children: [
                        Flexible(
                          child: Text(
                            locationProfileProvider.locationProfile
                                    ?.finalAddress?.locationName ??
                                '',
                            style: typography.H6.copyWith(height: 1.2),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.edit,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          onPressed: () async {
                            final locationProfile =
                                locationProfileProvider.locationProfile;

                            if (locationProfile == null) return;

                            final score = locationProfile.finalAddress?.score;
                            print(score);

                            if (score.toString() == "5") {
                              _editName(locationProfileProvider);
                              return;
                            }

                            final result = await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AddLocationScreen(
                                  accountId: widget.accountId,
                                  subAccountId: widget.subAccountId,
                                  sovId: widget.sovId,
                                  accountName: widget.accountName,
                                  subAccountName: widget.subAccountName,
                                  sovName: widget.sovName,
                                  locationId: locationProfile.id,
                                  locationName: locationProfile
                                          .finalAddress?.locationName ??
                                      "",
                                  locationIdForRef: locationProfile
                                          .finalAddress?.locationIdForRef ??
                                      "",
                                  searchQuery: widget.searchQuery ?? "",
                                  page: widget.page,
                                  totalPages: widget.totalPages,
                                ),
                              ),
                            );

                            if (result == true) {
                              _refreshData();
                            }

                            /// 🔹 Refresh profile after successful update
                            // if (value == true && mounted) {
                            //   await locationProfileProvider
                            //       .fetchIndividualLocationProfile(
                            //     context,
                            //     locationProfile.id!,
                            //   );
                            //   setState(() {});
                            // }
                          },
                        ),
                      ],
                    ),
                    trailing: Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: TooltipTheme(
                        data: TooltipThemeData(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          textStyle: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 14,
                          ),
                          padding: EdgeInsets.all(8),
                          verticalOffset: 20,
                          preferBelow: false,
                        ),
                        child: Tooltip(
                          showDuration: Duration(seconds: 5),
                          triggerMode: TooltipTriggerMode.tap,
                          preferBelow: true,
                          richMessage: TextSpan(
                            children: [
                              TextSpan(
                                text:
                                    'Geocode Type: ${locationProfileProvider.locationProfile?.finalAddress?.locationType ?? 'Unknown'}\n',
                                style: typography.Subtitle1,
                              ),
                              // Comma seperated
                              TextSpan(
                                text:
                                    'Property Type: ${locationProfileProvider.locationProfile?.finalAddress?.placeTypes?.join(', ') ?? 'Unknown'}\n',
                                style: typography.Subtitle1,
                              ),
                            ],
                            style: typography.Subtitle1,
                          ),
                          child: Icon(
                            Icons.info,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Text(
                    "" +
                        (locationProfileProvider
                                    .locationProfile?.finalAddress?.longitude ??
                                '')
                            .toString(),
                    style: typography.Body1,
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        /*RatingSlider(
                            progress: context
                                .read<LocationProfileProvider>()
                                .result
                                ?.score ??
                                0,
                            total: 5,
                            width: MediaQuery.of(context).size.width * 0.5,
                            progressColor: Colors.amber,
                            thumbColor: Colors.amberAccent,
                            textColor: Colors.white,
                          ),*/
                        RatingWidget(
                            score: context
                                    .read<MyLocationListProvider>()
                                    .locationProfile
                                    ?.finalAddress
                                    ?.score ??
                                0),
                        (locationProfileProvider
                                        .locationProfile?.finalAddress?.score ??
                                    0) ==
                                5
                            ? SvgPicture.asset('assets/images/certified.svg')
                            : SizedBox.shrink(),
                      ],
                    ),
                  ),
                  Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          LanguageService.getTranslated(context, "address"),
                          style: typography.H6.copyWith(height: 1.2),
                        ),
                        Row(
                          children: [
                            Consumer<UserProfileProvider>(
                                builder: (context, userProfileProvider, child) {
                              var trialStatus =
                                  userProfileProvider.trialInfo['status'] ?? '';
                              return IconButton(
                                icon: Icon(Icons.download),
                                onPressed: trialStatus.isNotEmpty
                                    ? null
                                    : () {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return ExportDialog(
                                              accountId: widget.accountId,
                                              subAccountId: widget.subAccountId,
                                              sovId: widget.sovId,
                                              locationId: [
                                                locationProfileProvider
                                                        .locationProfile
                                                        ?.finalAddress
                                                        ?.locationId ??
                                                    ''
                                              ],
                                            );
                                          },
                                        );
                                      },
                              );
                            }),
                            // edit location
                            (locationProfileProvider.locationProfile
                                            ?.finalAddress?.score ??
                                        0) ==
                                    5
                                ? SizedBox.shrink()
                                : IconButton(
                                    icon: Icon(Icons.edit),
                                    tooltip: 'Edit Address',
                                    onPressed: () async {
                                      var userProfileProvider =
                                          Provider.of<UserProfileProvider>(
                                              context,
                                              listen: false);
                                      final trialStatus = userProfileProvider
                                              .trialInfo['status'] ??
                                          '';
                                      final trialSubdestinations =
                                          userProfileProvider.trialInfo[
                                                  'subDestinations'] ??
                                              0;
                                      if (trialStatus != '' &&
                                          trialSubdestinations < 1) {
                                        showDialog(
                                          context: context,
                                          barrierColor: Theme.of(context)
                                              .colorScheme
                                              .surfaceContainerLowest,
                                          builder: (BuildContext context) {
                                            return Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.end,
                                                  children: [
                                                    IconButton(
                                                      icon: Icon(Icons.close),
                                                      onPressed: () {
                                                        Navigator.of(context)
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
                                                          'You\'ve reached your limit for ',
                                                      style: CustomTypography(
                                                              context)
                                                          .Body1,
                                                    ),
                                                    TextSpan(
                                                      text:
                                                          '“editing locations”',
                                                      style: CustomTypography(
                                                              context)
                                                          .Body1
                                                          .copyWith(
                                                            color: AppColors
                                                                .warning,
                                                          ),
                                                    ),
                                                    TextSpan(
                                                      text:
                                                          '.  Consider upgrading your account to unlock more possibilities!',
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
                                      // Store the necessary navigation data before pushing
                                      final navigationData = {
                                        'accountId': widget.accountId,
                                        'subAccountId': widget.subAccountId,
                                        'sovId': widget.sovId,
                                        'accountName': widget.accountName,
                                        'subAccountName': widget.subAccountName,
                                        'sovName': widget.sovName,
                                        'locationId': locationProfileProvider
                                                .locationProfile?.id ??
                                            "",
                                        'searchQuery': widget.searchQuery,
                                        'page': widget.page,
                                        'totalPages': widget.totalPages,
                                      };
                                      var value =
                                          await Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => AddLocationScreen(
                                            accountId: widget.accountId,
                                            subAccountId: widget.subAccountId,
                                            sovId: widget.sovId,
                                            accountName: widget.accountName,
                                            subAccountName:
                                                widget.subAccountName,
                                            sovName: widget.sovName,
                                            locationId: locationProfileProvider
                                                    .locationProfile?.id ??
                                                "",
                                            locationName:
                                                locationProfileProvider
                                                        .locationProfile
                                                        ?.finalAddress
                                                        ?.locationName ??
                                                    "",
                                            locationIdForRef:
                                                locationProfileProvider
                                                        .locationProfile
                                                        ?.finalAddress
                                                        ?.locationIdForRef ??
                                                    "",
                                            searchQuery:
                                                widget.searchQuery ?? "",
                                            page: widget.page,
                                            totalPages: widget
                                                    .locationId!.isNotEmpty
                                                ? (locationProfileProvider
                                                            .resetTotalPage! -
                                                        1)
                                                    .toString()
                                                : widget.totalPages!,
                                          ),
                                        ),
                                      );
                                      if (value != null) {
                                        _refreshData();
                                      }
                                      /*if(value == true) {
                                    if (mounted) {
                                      Navigator.pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              LocationProfile(
                                                accountId: navigationData['accountId'] ??
                                                    "",
                                                subAccountId: navigationData['subAccountId'] ??
                                                    "",
                                                sovId: navigationData['sovId'] ??
                                                    "",
                                                accountName: navigationData['accountName'] ??
                                                    "",
                                                subAccountName: navigationData['subAccountName'] ??
                                                    "",
                                                sovName: navigationData['sovName'] ??
                                                    "",
                                                locationId: navigationData['locationId'] ??
                                                    "",
                                                searchQuery: navigationData['searchQuery'] ??
                                                    "",
                                                page: navigationData['page'] ??
                                                    "1",
                                                totalPages: navigationData['totalPages'] ??
                                                    "1",
                                              ),
                                        ),

                                            (route) => false,
                                      );
                                    }
                                  }*/
                                    }),

                            // Todo: implement history feature
                            /* IconButton(
                              icon: Icon(Icons.history),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Coming Soon',
                                        style: typography.Body1),
                                  ),
                                );
                              },
                            ),*/
                          ],
                        ),
                        InkWell(
                          onTap: () async {
                            final navigationData = {
                              'accountId': widget.accountId,
                              'subAccountId': widget.subAccountId,
                              'sovId': widget.sovId,
                              'accountName': widget.accountName,
                              'subAccountName': widget.subAccountName,
                              'sovName': widget.sovName,
                              'locationId':
                                  locationProfileProvider.locationProfile?.id ??
                                      "",
                              'searchQuery': widget.searchQuery,
                              'page': widget.page,
                              'totalPages': widget.totalPages,
                            };

                            var value = await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AddLocationScreen(
                                  accountId: widget.accountId,
                                  subAccountId: widget.subAccountId,
                                  sovId: widget.sovId,
                                  accountName: widget.accountName,
                                  subAccountName: widget.subAccountName,
                                  sovName: widget.sovName,
                                  locationId: locationProfileProvider
                                          .locationProfile?.id ??
                                      "",
                                  locationName: locationProfileProvider
                                          .locationProfile
                                          ?.finalAddress
                                          ?.locationName ??
                                      "",
                                  locationIdForRef: locationProfileProvider
                                          .locationProfile
                                          ?.finalAddress
                                          ?.locationIdForRef ??
                                      "",
                                  searchQuery: widget.searchQuery ?? "",
                                  page: widget.page,
                                  totalPages: widget.locationId!.isNotEmpty
                                      ? (locationProfileProvider
                                                  .resetTotalPage! -
                                              1)
                                          .toString()
                                      : widget.totalPages!,
                                ),
                              ),
                            );
                            if (value == true) {
                              _refreshData();
                            }
                          },
                          child: Icon(Icons.edit),
                        ),
                      ],
                    ),
                  ),
                  ListTile(
                    title: Text(
                      locationProfileProvider
                              .locationProfile?.finalAddress?.address ??
                          '',
                      style: typography.Body1,
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  ),

                  Divider(),
                  // Campus Id, if present editable
                  if (locationProfileProvider
                              .locationProfile?.finalAddress?.campusId !=
                          null &&
                      locationProfileProvider
                              .locationProfile?.finalAddress?.campusId! !=
                          '')
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Campus',
                                  style: typography.H6.copyWith(height: 1.2)),
                              SizedBox(height: 4),
                              Text(
                                  locationProfileProvider.locationProfile
                                          ?.finalAddress?.campusId ??
                                      '',
                                  style: typography.Body1),
                            ],
                          ),
                          IconButton(
                            icon:
                                Icon(Icons.edit, color: AppColors.primaryMain),
                            onPressed: () =>
                                _editCampusId(locationProfileProvider),
                          ),
                        ],
                      ),
                    ),
                  Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Campus List',
                          style: typography.H6.copyWith(height: 1.2),
                        ),
                        locationProfileProvider
                                        .locationProfile?.finalAddress?.score !=
                                    5 &&
                                (locationProfileProvider.locationProfile
                                        ?.finalAddress?.placeTypes
                                        ?.any((placeType) =>
                                            [
                                              "premise",
                                              "subpremise",
                                              "rooftop",
                                            ].contains(
                                                placeType.toLowerCase()) !=
                                            true) ??
                                    false)
                            ? SizedBox()
                            : IconButton(
                                icon: Icon(Icons.add_location_alt),
                                onPressed: _handleSubDestinationTap,
                              ),
                      ],
                    ),
                  ),
                  (locationProfileProvider.locationProfile?.subdestinations ??
                              [])
                          .isEmpty
                      ? Center(
                          child: Container(
                              alignment: Alignment.center,
                              height: 400,
                              child:
                                  Text('No Campus', style: typography.Body1)))
                      : Container(
                          height: 210,
                          child: PageView.builder(
                            controller: PageController(viewportFraction: 0.9),
                            itemCount: (locationProfileProvider
                                        .locationProfile?.subdestinations ??
                                    [])
                                .length,
                            itemBuilder: (context, index) {
                              var subdestination = (locationProfileProvider
                                      .locationProfile?.subdestinations ??
                                  [])[index];
                              String occupancy =
                                  (subdestination.rented ?? false) == true
                                      ? 'Rented/Leased'
                                      : 'Owned';
                              return GestureDetector(
                                onTap: () =>
                                    _focusOnSubdestination(subdestination),
                                child: Card(
                                  margin: EdgeInsets.symmetric(
                                      vertical: 8, horizontal: 16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      ListTile(
                                        title: Text(subdestination.name ?? ''),
                                        subtitle:
                                            Text(subdestination.address ?? ''),
                                        trailing: IconButton(
                                          icon: Icon(Icons.map),
                                          onPressed: () {
                                            _focusOnSubdestination(
                                                subdestination);
                                          },
                                        ),
                                      ),
                                      Spacer(),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          locationProfileProvider.isLoading
                                              ? CircularProgressIndicator()
                                              : (subdestination.status ?? "")
                                                          .toLowerCase() ==
                                                      'added'
                                                  ? CustomButton(
                                                      type: ButtonType.elevated,
                                                      onPressed: () =>
                                                          _removeFromSOV(
                                                              subdestination
                                                                  .id!),
                                                      child: Text(
                                                        'Remove Campus',
                                                        style: typography.Body1,
                                                        textAlign:
                                                            TextAlign.center,
                                                      ),
                                                    )
                                                  : CustomButton(
                                                      type: ButtonType.elevated,
                                                      onPressed: () {
                                                        var provider = Provider
                                                            .of<MyLocationListProvider>(
                                                                context,
                                                                listen: false);
                                                        if (provider
                                                                    .locationProfile
                                                                    ?.finalAddress
                                                                    ?.campusId ==
                                                                null ||
                                                            provider
                                                                    .locationProfile
                                                                    ?.finalAddress
                                                                    ?.campusId ==
                                                                '') {
                                                          _showAddToSOVDialog(
                                                              subdestination
                                                                      .id ??
                                                                  "",
                                                              occupancy);
                                                        } else {
                                                          _addToSOV(
                                                              subdestination
                                                                      .id ??
                                                                  "",
                                                              occupancy:
                                                                  occupancy,
                                                              campusName: provider
                                                                      .locationProfile
                                                                      ?.finalAddress
                                                                      ?.campusId ??
                                                                  "");
                                                        }
                                                      },
                                                      child: Text('Add to SOV',
                                                          style:
                                                              typography.Body1),
                                                    ),
                                        ],
                                      ),
                                      SizedBox(height: 8),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                  Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Images',
                          style: typography.H6.copyWith(height: 1.2),
                        ),
                        IconButton(
                          icon: Icon(Icons.upload),
                          onPressed: _pickImage,
                        ),
                      ],
                    ),
                  ),
                  locationProfileProvider.isUploadingImage
                      ? Center(child: CircularProgressIndicator())
                      : _images.isNotEmpty ||
                              locationProfileProvider.locationProfile
                                      ?.screenshots?.isNotEmpty ==
                                  true
                          ? Column(
                              children: [
                                Container(
                                  height: 200,
                                  decoration: BoxDecoration(
                                    color:
                                        Theme.of(context).colorScheme.surface,
                                  ),
                                  child: PageView.builder(
                                    controller:
                                        PageController(viewportFraction: 0.9),
                                    itemCount: _images.length +
                                        (locationProfileProvider.locationProfile
                                                ?.screenshots?.length ??
                                            0),
                                    itemBuilder:
                                        (BuildContext context, int itemIndex) {
                                      if (itemIndex < _images.length) {
                                        return GestureDetector(
                                          onTap: () => _showImagePreview(
                                              _images[itemIndex]),
                                          child: Stack(
                                            children: [
                                              Center(
                                                child: Image.file(
                                                  _images[itemIndex],
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                              Positioned(
                                                top: 8,
                                                right: 8,
                                                child: IconButton(
                                                  icon: Icon(Icons.delete,
                                                      color: Colors.red),
                                                  onPressed: () {
                                                    setState(() {
                                                      _images
                                                          .removeAt(itemIndex);
                                                    });
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      } else {
                                        final screenshotIndex =
                                            itemIndex - _images.length;
                                        final screenshot =
                                            locationProfileProvider
                                                .locationProfile
                                                ?.screenshots?[screenshotIndex];
                                        return GestureDetector(
                                          onTap: () => _showImagePreviewFromUrl(
                                              screenshot?.imageUrl ?? ''),
                                          child: CachedNetworkImage(
                                            imageUrl:
                                                screenshot?.imageUrl ?? '',
                                            fit: BoxFit.cover,
                                            width: 150,
                                            placeholder: (context, url) => Center(
                                                child:
                                                    CircularProgressIndicator()),
                                            errorWidget:
                                                (context, url, error) =>
                                                    Icon(Icons.error),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ),
                                SizedBox(height: 14),
                              ],
                            )
                          : Center(
                              child:
                                  Text('No Images', style: typography.Body1)),
                  SizedBox(height: 16),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 16),
                    child: CustomButton(
                      type: ButtonType.elevated,
                      onPressed: _pickImage,
                      child: Text('Upload relevant image(s)',
                          style: typography.Body1),
                    ),
                  ),
                  SizedBox(height: 18),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  void _updateMarkers(Set<Marker> markers) {
    setState(() {
      _markers = markers;
    });
  }

  GoogleMapController? _mapController;

  Widget _geocodingScore() {
    return Consumer<MyLocationListProvider>(
        builder: (context, locationProfileProvider, child) {
      final screenWidth = MediaQuery.of(context).size.width;
      final screenHeight = MediaQuery.of(context).size.height;
      final dynamicTop = screenHeight * 0.17;
      final dynamicLeft = screenWidth * 0.37;
      double latitude =
          locationProfileProvider.locationProfile?.location.latitude ?? 0.0;

      double longitude =
          locationProfileProvider.locationProfile?.location.longitude ?? 0.0;

      List<Subdestination> filteredSubdestinations =
          (locationProfileProvider.locationProfile?.subdestinations ?? [])
              .where((sub) {
        final status = (sub.status ?? '').toLowerCase();
        return isSwitched ? status == 'added' : status != 'added';
      }).toList();

      return locationProfileProvider.isLoading
          ? Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Container(
                  height: MediaQuery.of(context).size.height / 2,
                  margin: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Screenshot(
                      controller: _geocodingScreenshotController,
                      child: RepaintBoundary(
                          key: _mapKey,
                          child: Stack(
                            children: [
                              GoogleMap(
                                key: ValueKey(
                                    '${latitude}_${longitude}_${_currentMapType.name}'),
                                mapType: _currentMapType,
                                mapToolbarEnabled: true,
                                markers: Set<Marker>.of(markers.values),
                                zoomControlsEnabled: false,
                                initialCameraPosition: CameraPosition(
                                  target: LatLng(latitude, longitude),
                                  zoom: 18,
                                ),
                                onMapCreated: (GoogleMapController controller) {
                                  _mapController = controller;
                                },
                                onCameraIdle: () {
                                  _mapIsReady = true;
                                },
                                onCameraMove: (_) {
                                  if (showViewMore) {
                                    setState(() {
                                      showViewMore =
                                          _mapIsReady == true ? false : true;
                                    });
                                  }
                                },
                                gestureRecognizers: <Factory<
                                    OneSequenceGestureRecognizer>>{
                                  Factory<OneSequenceGestureRecognizer>(
                                      () => EagerGestureRecognizer()),
                                },
                                onTap: _isAddingMarker ? _handleMapTap : null,
                              ),

                              // ✅ Show this only when `showViewMore == true`
                              if (showViewMore)
                                Positioned(
                                  top: dynamicTop,
                                  left: dynamicLeft,
                                  child: Container(
                                    alignment: Alignment.center,
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.8),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      "Click here",
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 14),
                                    ),
                                  ),
                                ),
                            ],
                          )),
                    ),
                  ),
                ),

                Positioned(
                  bottom: MediaQuery.of(context).size.height / 5.8,
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
                          backgroundColor:
                              Theme.of(context).colorScheme.brightness ==
                                      Brightness.light
                                  ? AppColors.paperElevation2Light
                                  : AppColors.paperElevation2,
                          onPressed: () {
                            setState(() {
                              _currentMapType =
                                  _currentMapType == MapType.normal
                                      ? MapType.satellite
                                      : MapType.normal;
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
                ),

                // Screenshot & Add Location Button
                Positioned(
                  top: 16,
                  right: 16,
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
                          onPressed: () async {
                            if (_isLoading) return;

                            try {
                              if (mounted) {
                                setState(() => _isLoading = true);
                              }

                              await _captureAndUploadMapScreenshot();
                            } finally {
                              if (mounted) {
                                setState(() => _isLoading = false);
                              }
                            }
                          },
                          backgroundColor:
                              Theme.of(context).colorScheme.brightness ==
                                      Brightness.light
                                  ? AppColors.paperElevation2Light
                                  : AppColors.paperElevation2,
                          child: _isLoading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                    strokeWidth: 2.0,
                                  ),
                                )
                              : Icon(Icons.camera_alt,
                                  color:
                                      Theme.of(context).colorScheme.onSurface),
                          tooltip: 'Capture and Upload Screenshot',
                        ),
                        SizedBox(width: 8),
                        if (locationProfileProvider
                                    .locationProfile?.finalAddress?.placeTypes
                                    ?.contains('premise') ==
                                true ||
                            locationProfileProvider
                                    .locationProfile?.finalAddress?.placeTypes
                                    ?.contains('subpremise') ==
                                true)
                          if (filteredSubdestinations.length > 0)
                            FloatingActionButton.small(
                              elevation: 0,
                              backgroundColor:
                                  Theme.of(context).colorScheme.brightness ==
                                          Brightness.light
                                      ? AppColors.paperElevation2Light
                                      : AppColors.paperElevation2,
                              onPressed: null,
                              child: Icon(Icons.add_location_alt,
                                  color: Colors.grey),
                              tooltip: 'Add Campus',
                            )
                          else
                            hasAnyPlan
                                ? FloatingActionButton.small(
                                    elevation: 0,
                                    backgroundColor: Theme.of(context)
                                                .colorScheme
                                                .brightness ==
                                            Brightness.light
                                        ? AppColors.paperElevation2Light
                                        : AppColors.paperElevation2,
                                    onPressed: _handleSubDestinationTap,
                                    child: Icon(Icons.add_location_alt,
                                        color: Colors.white),
                                    tooltip: 'Add Campus',
                                  )
                                : Container()
                      ],
                    ),
                  ),
                ),
              ],
            );
    });
  }

  Future<void> _captureAndUploadMapScreenshot() async {
    // Early exit if conditions aren't met
    if (!_mapIsReady || _mapController == null || !mounted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Map is not ready yet. Please wait.')),
        );
      }
      return;
    }

    try {
      // Double check mounted status
      if (!mounted) return;

      // Ensure the app is in the foreground
      final lifecycleState = WidgetsBinding.instance.lifecycleState;
      if (lifecycleState != AppLifecycleState.resumed) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Please bring the app to foreground to capture screenshot')),
          );
        }
        return;
      }

      // Wait for the next frame to ensure everything is rendered
      await SchedulerBinding.instance.endOfFrame;
      await Future.delayed(const Duration(milliseconds: 200));

      // Capture the screenshot
      final imageBytes = await _mapController!.takeSnapshot();
      if (imageBytes == null) {
        throw Exception('Failed to capture screenshot - null bytes returned');
      }

      // Save to temporary file
      final Directory tempDir = await getTemporaryDirectory();
      final String filePath =
          '${tempDir.path}/map_screenshot_${DateTime.now().millisecondsSinceEpoch}.png';
      final File file = File(filePath);
      await file.writeAsBytes(imageBytes);

      // Update UI with new image
      if (mounted) {
        setState(() {
          _images.add(file);
        });
      }

      // Upload the image
      final provider =
          Provider.of<MyLocationListProvider>(context, listen: false);
      await provider.uploadImage(
        context,
        filePath,
        widget.accountId,
        widget.subAccountId,
        widget.sovId,
        provider.locationProfile?.finalAddress?.locationId ?? "",
      );

      // Show success message
      if (mounted) {
        widget.onConfirmCallback?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Screenshot uploaded successfully!')),
        );
      }
    } catch (e, stackTrace) {
      print('Error capturing/uploading screenshot: $e');
      print('Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to capture screenshot: ${e.toString()}')),
        );
      }
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

  void _showImagePreview(File image) {
    var typography = CustomTypography(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.file(image),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Close'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showImagePreviewFromUrl(String imageUrl) {
    var typography = CustomTypography(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.network(imageUrl),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Close'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _onMarkerTapped(MarkerId markerId) async {
    var provider = Provider.of<MyLocationListProvider>(context, listen: false);

    if (markerId.value == provider.locationProfile?.finalAddress?.locationId) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return Center(child: CircularProgressIndicator());
        },
      );
      await provider.fetchIndividualLocationProfile(
          context, provider.locationProfile?.finalAddress?.locationId ?? '');

      Navigator.pop(context);

      showLocationDetailsPopup(context, provider.selectedLocation!, true);
    } else {
      provider.locationProfile?.subdestinations?.forEach((element) {
        print('Subdestination ID: ${element.id}');
      });

      var subdestination =
          provider.locationProfile?.subdestinations?.firstWhereOrNull(
        (element) => element.id == markerId.value,
      );

      if (subdestination != null) {
        bool isAdded = (subdestination.status ?? "").toLowerCase() == "added";

        if (isAdded) {
          // Show loading dialog while fetching data
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) {
              return Center(child: CircularProgressIndicator());
            },
          );

          // Call API to fetch location details
          await provider.fetchIndividualLocationProfile(
              context, subdestination.locationId!);

          // Close loading dialog
          Navigator.pop(context);

          if (provider.isHazardProcessed == false) {
            // Show hazard processing message
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: Text("Processing Hazard"),
                  content: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Expanded(
                          child:
                              Text("Hazard is being processed. Please wait.")),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close the dialog
                      },
                      child: Text("Close"),
                    ),
                  ],
                );
              },
            );
          } else {
            // Show detailed info popup
            showLocationDetailsPopup(context, provider.selectedLocation!);
          }
        } else {
          // Show occupancy selection window for non-added subdestination
          showDialog(
            context: context,
            builder: (context) {
              String occupancy = "Owned"; // Initial value

              return StatefulBuilder(
                builder: (context, setState) {
                  return AlertDialog(
                    title: Text(subdestination.name ?? 'Unknown Location'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(subdestination.address ?? 'Unknown Address'),
                        SizedBox(height: 8),
                        Text("Choose Occupancy Type:"),
                        Row(
                          children: [
                            Radio<String>(
                              value: "Owned",
                              groupValue: occupancy,
                              onChanged: (value) {
                                setState(() {
                                  occupancy = value!;
                                });
                              },
                            ),
                            Text("Owned"),
                            Radio<String>(
                              value: "Rented/leased",
                              groupValue: occupancy,
                              onChanged: (value) {
                                setState(() {
                                  occupancy = value!;
                                });
                              },
                            ),
                            Text("Rented/leased"),
                          ],
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Close the dialog
                        },
                        child: Text("Close"),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Close the dialog

                          var provider = Provider.of<MyLocationListProvider>(
                              context,
                              listen: false);
                          if (provider.locationProfile?.finalAddress
                                      ?.campusId ==
                                  null ||
                              provider.locationProfile?.finalAddress
                                      ?.campusId ==
                                  '') {
                            _showAddToSOVDialog(
                                subdestination.id ?? "", occupancy);
                          } else {
                            _addToSOV(subdestination.id ?? "",
                                occupancy: occupancy,
                                campusName: provider.locationProfile
                                        ?.finalAddress?.campusId ??
                                    "");
                          }
                        },
                        child: Text("Add to Campus"),
                      ),
                    ],
                  );
                },
              );
            },
          );
        }
      } else {
        print("No subdestination found for markerId: $markerId");
      }
    }
  }

  Future<Uint8List> createMarkerBitmap(Color color,
      {bool isSelected = false}) async {
    final PictureRecorder pictureRecorder = PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final double radius = 20.0;
    final Offset center = Offset(radius, radius);

    canvas.drawCircle(center, radius, paint);

    if (isSelected) {
      final Paint borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;
      canvas.drawCircle(center, radius, borderPaint);
    }

    final img = await pictureRecorder
        .endRecording()
        .toImage((radius * 2).toInt(), (radius * 2).toInt());
    final ByteData? byteData =
        await img.toByteData(format: ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  void _handleMapTap(LatLng latLng) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Marker'),
          content:
              const Text('Do you want to tag this building as your location?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _addMarker(latLng);
                Navigator.of(context).pop();
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _addMarker(LatLng latLng) {
    if (markers.isNotEmpty) {
      markers.clear();
    }

    var markerIdVal = "hardcoded_id";
    final MarkerId markerId = MarkerId(markerIdVal);

    final Marker marker = Marker(
      zIndex: 6,
      markerId: markerId,
      position: latLng,
      infoWindow: InfoWindow(
        title: 'Click here',
        onTap: () {
          // Handle info window tap if needed
          print('Info window tapped');
        },
      ),
      onTap: () {
        _onMarkerTapped(markerId);
      },
    );

    setState(() {
      markers[markerId] = marker;
      _isAddingMarker = false; // Exit "add marker" mode after adding a marker
    });
  }

  void _handleSubDestinationTap() {
    var userProfileProvider =
        Provider.of<UserProfileProvider>(context, listen: false);
    final trialStatus = userProfileProvider.trialInfo['status'] ?? '';
    final trialSubdestinations =
        userProfileProvider.trialInfo['subDestinations'] ?? 0;
    if (trialStatus != '' && trialSubdestinations < 1) {
      showDialog(
        barrierColor: Theme.of(context).colorScheme.surfaceContainerLowest,
        context: context,
        builder: (BuildContext context) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
              MessageCard(
                isUpgrade: true,
                messageTextSpans: [
                  TextSpan(
                    text: 'You\'ve reached your limit for ',
                    style: CustomTypography(context).Body1,
                  ),
                  TextSpan(
                    text: '“creating campus”',
                    style: CustomTypography(context).Body1.copyWith(
                          color: AppColors.warning,
                        ),
                  ),
                  TextSpan(
                    text:
                        '.  Consider upgrading your account to unlock more possibilities!',
                    style: CustomTypography(context).Body1,
                  ),
                ],
              ),
            ],
          );
        },
      );
      return;
    }

    var typography = CustomTypography(context);
    var locationProfileProvider =
        Provider.of<MyLocationListProvider>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        // Moved outside StatefulBuilder

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            Future<void> handleCreate() async {
              if (addCampusLoading1) return; // Prevent multiple clicks

              setDialogState(() {
                addCampusLoading1 = true;
              });

              try {
                await locationProfileProvider.createSubdestination(
                  context,
                  widget.accountId,
                  widget.subAccountId,
                  widget.sovId,
                  locationProfileProvider
                          .locationProfile?.finalAddress?.locationId ??
                      '',
                  locationProfileProvider
                          .locationProfile?.finalAddress?.latitude ??
                      0,
                  locationProfileProvider
                          .locationProfile?.finalAddress?.longitude ??
                      0,
                  locationProfileProvider
                          .locationProfile?.finalAddress?.placeId ??
                      '',
                );

                await _getData();
                // ScaffoldMessenger.of(context).showSnackBar(
                //   SnackBar(content: Text('Campus created Successfully')),
                // );
                Navigator.of(dialogContext).pop();
              } catch (error) {
                print('Error creating subdestination: $error');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text('Failed to create campus: ${error.toString()}')),
                );
              } finally {
                if (mounted) {
                  // Check if widget is still mounted
                  setDialogState(() {
                    addCampusLoading1 = false;
                  });
                }
              }
            }

            return WillPopScope(
              onWillPop: () async => !isLoading,
              // Prevent back button while loading
              child: AlertDialog(
                title: Text(
                    LanguageService.getTranslated(context, "create_campus"),
                    style: typography.H6),
                content: Container(
                  width: double.maxFinite, // Ensure dialog takes full width
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        LanguageService.getTranslated(
                            context, "confirm_create_campus"),
                        style: typography.Body1,
                      ),
                    ],
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () => Navigator.of(dialogContext).pop(),
                    child: isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            LanguageService.getTranslated(context, "cancel"),
                            style: typography.Body1.copyWith(
                              color: isLoading ? Colors.grey : null,
                            ),
                          ),
                  ),
                  TextButton(
                    onPressed: addCampusLoading1 ? null : handleCreate,
                    child: addCampusLoading1
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            LanguageService.getTranslated(context, "add"),
                            style: typography.Body1.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _editName(MyLocationListProvider provider) {
    var typography = CustomTypography(context);
    _nameController.text =
        provider.locationProfile?.finalAddress?.locationName ?? '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Consumer<MyLocationListProvider>(
            builder: (context, locationProfileProvider, child) {
          return AlertDialog(
            title: Text(LanguageService.getTranslated(context, "edit_name"),
                style: typography.H6),
            content: Container(
              margin: EdgeInsets.only(top: 16),
              child: TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Enter the new name',
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary),
                  ),
                ),
                style: typography.Body1,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(LanguageService.getTranslated(context, "cancel"),
                    style: typography.Body1),
              ),
              TextButton(
                onPressed: () {
                  locationProfileProvider
                      .updateLocationName(
                    context,
                    widget.accountId,
                    widget.subAccountId,
                    widget.sovId,
                    locationProfileProvider
                            .locationProfile?.finalAddress?.locationId ??
                        '',
                    _nameController.text,
                  )
                      .then((value) {
                    _getData();
                  });
                  Navigator.of(context).pop();
                },
                child: locationProfileProvider.isLoading
                    ? const CircularProgressIndicator()
                    : Text(LanguageService.getTranslated(context, "save"),
                        style: typography.Body1),
              ),
            ],
          );
        });
      },
    );
  }

  void _editCampusId(MyLocationListProvider provider) {
    var typography = CustomTypography(context);
    _campusIdController.text =
        provider.locationProfile?.finalAddress?.campusId ?? '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Consumer<MyLocationListProvider>(
            builder: (context, locationProfileProvider, child) {
          return AlertDialog(
            title: Text('Edit Campus ID', style: typography.H6),
            content: Container(
              margin: EdgeInsets.only(top: 16),
              child: TextField(
                controller: _campusIdController,
                decoration: InputDecoration(
                  hintText: 'Enter the new campus ID',
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary),
                  ),
                ),
                style: typography.Body1,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Cancel', style: typography.Body1),
              ),
              TextButton(
                onPressed: () {
                  locationProfileProvider
                      .updateCampusId(
                    context,
                    locationProfileProvider
                            .locationProfile?.finalAddress?.campusKey ??
                        '',
                    _campusIdController.text,
                  )
                      .then((value) {
                    _getData();
                  });
                  Navigator.of(context).pop();
                },
                child: locationProfileProvider.isLoading
                    ? const CircularProgressIndicator()
                    : Text('Save', style: typography.Body1),
              ),
            ],
          );
        });
      },
    );
  }

  void _showAddToSOVDialog(String subdestinationId, String occupancy) {
    TextEditingController campusNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Enter Campus Name"),
          content: TextField(
            controller: campusNameController,
            decoration: InputDecoration(
              hintText: "Campus Name",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                String campusName = campusNameController.text.trim();
                if (campusName.isNotEmpty) {
                  Navigator.of(context).pop(); // Close the dialog
                  _addToSOV(subdestinationId,
                      occupancy: occupancy, campusName: campusName);
                  _getData();
                } else {
                  // Show a message if the campus name is empty
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text("Please enter a campus name"),
                  ));
                }
              },
              child: Text("Submit"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addToSOV(String subdestinationId,
      {required String occupancy, required String campusName}) async {
    var provider = Provider.of<MyLocationListProvider>(context, listen: false);
    var user = FirebaseAuth.instance.currentUser;

    await provider.addSubdestinationToSOV(
      context: context,
      accountId: widget.accountId,
      subAccountId: widget.subAccountId,
      campusName: campusName,
      userId: user?.uid ?? '',
      locationId: provider.locationProfile?.finalAddress?.locationId ?? '',
      subDestinationId: subdestinationId,
      occupancy: occupancy,
      accountName: widget.accountName,
      subAccountName: widget.subAccountName,
    );

    final updatedSub = provider.locationProfile?.subdestinations?.firstWhere(
      (sub) => sub.id == subdestinationId,
    );

    if (updatedSub != null) {
      updatedSub.status = 'added';
      provider.notifyListeners(); // 🔔 Trigger UI update
    }
  }

  Future<void> _removeFromSOV(String subdestinationId) async {
    var provider = Provider.of<MyLocationListProvider>(context, listen: false);
    await provider.removeSubdestinationFromSOV(
      context,
      widget.accountId,
      widget.subAccountId,
      widget.sovId,
      provider.locationProfile?.finalAddress?.locationId ?? '',
      subdestinationId,
    );
  }

  Future<void> addMarkerFromPlaceId(
      Suggestion suggestion, BuildContext context) async {
    // Add the marker
    try {
      final placeId = suggestion.placeId;
      var placeApiProvider = PlaceApiProvider(Uuid().v4());
      final latLng = await placeApiProvider.getLatLngFromPlaceId(placeId);
      print('Latitude: ${latLng.latitude}, Longitude: ${latLng.longitude}');
      _addMarker(latLng);

      // Move the camera to the selected location
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newLatLng(latLng));
      Navigator.of(context).pop();
    } catch (e) {
      print('Error fetching location from place ID: $e');
    }
  }

  searchLocations(String text) {
    final sessionToken = Uuid().v4();
    final provider = PlaceApiProvider(sessionToken);
    return provider.fetchSuggestions(text, 'en');
  }

  void _focusOnSubdestination(Subdestination subdestination) async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newLatLng(
        LatLng(subdestination.lat!, subdestination.lng!)));

    MarkerId markerId = MarkerId(subdestination.id!);
    Marker? marker = markers[markerId];

    if (marker != null) {
      var isAdded = (subdestination.status ?? "").toLowerCase() == "added";

      setState(() {
        markers[markerId] = marker.copyWith(
          iconParam: BitmapDescriptor.defaultMarkerWithHue(
              isAdded ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueAzure),
          infoWindowParam: InfoWindow(
            title: subdestination.name,
            snippet: subdestination.address,
            onTap: () {
              _onMarkerTapped(markerId);
            },
          ),
        );
        var provider =
            Provider.of<LocationProfileProvider>(context, listen: false);

        // Reset other markers to their original color
        markers.forEach((id, m) {
          if (id != markerId) {
            var otherIsAdded = provider.subdestinations
                    .firstWhere((sub) => sub.id == id.value)
                    .status
                    ?.toLowerCase() ==
                "added";
            markers[id] = m.copyWith(
              iconParam: BitmapDescriptor.defaultMarkerWithHue(otherIsAdded
                  ? BitmapDescriptor.hueGreen
                  : BitmapDescriptor.hueAzure),
            );
          }
        });

        // Set the focused marker color
        markers[markerId] = marker.copyWith(
          iconParam:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        );
      });
    }
  }

  String getOrdinal(int number) {
    if (number >= 11 && number <= 13) {
      return '${number}';
    }

    switch (number % 10) {
      case 1:
        return '${number}';
      case 2:
        return '${number}';
      case 3:
        return '${number}';
      default:
        return '${number}';
    }
  }

  String formatLocationText(int location, int total) {
    if (total == 0) {
      return '';
    }
    if (widget.locationId!.isNotEmpty) {
      return '';
    }
    return ' (${getOrdinal(location)} / $_totalPages)';
  }
}

class _ChatbotContent extends StatefulWidget {
  final String? locationId;

  const _ChatbotContent({this.locationId});

  @override
  State<_ChatbotContent> createState() => _ChatbotContentState();
}

class _ChatbotContentState extends State<_ChatbotContent> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _sessionId;
  bool _isTyping = false;
  bool _hasText = false;
  bool _showEligibilityButton = true;
  bool _showLocationsButton = true;
  List<Map<String, dynamic>> messages = [];

  bool get _showSuggestions =>
      messages.where((m) => m["isBot"] == false).isEmpty;

  @override
  void initState() {
    super.initState();
    _sessionId = const Uuid().v4();
    messages.add({
      "isBot": true,
      "text": "Hi, I'm RiskBuddy your personalized Assistant.",
    });
    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _currentTime() {
    final now = DateTime.now();
    final hour = now.hour > 12
        ? now.hour - 12
        : now.hour == 0
            ? 12
            : now.hour;
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? "PM" : "AM";
    return "$hour:$minute $period";
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;
    final userMessage = _controller.text.trim();

    setState(() {
      messages.add({"isBot": false, "text": userMessage});
      _isTyping = true;
    });

    _controller.clear();
    _scrollToBottom();

    final provider =
        Provider.of<MyLocationListProvider>(context, listen: false);

    try {
      final reply = await provider.sendChatMessageProfile(
        context: context,
        message: userMessage,
        locationId: widget.locationId,
        accountName: provider.locationProfile?.finalAddress?.accountName,
        isLocationProfile: true,
      );
      // final reply = await provider.sendChatMessage(
      //   context: context,
      //   message: userMessage,
      //   locationId: widget.locationId ?? "",
      //   sessionId: _sessionId!,
      //   locationName: provider.selectedLocation?.locationName ?? "",
      //   accountName: provider.selectedLocation?.accountName ?? "",
      // );

      debugPrint("BOT REPLY => $reply");
      setState(() {
        _isTyping = false;
        messages.add({"isBot": true, "text": reply ?? "No response"});
      });
      _scrollToBottom();
    } catch (e) {
      setState(() => _isTyping = false);
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        /// ── Header ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primaryMain,
                child:
                    const Icon(Icons.smart_toy, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "RiskBuddy",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    children: [
                      SvgPicture.asset(
                        "assets/images/ai.svg",
                        color: AppColors.primaryMain,
                        width: 12,
                        height: 12,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        "Smarter decisions, lower risk.",
                        style: TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  // IconButton(
                  //   icon: const Icon(Icons.open_in_full,
                  //       color: Colors.grey, size: 18),
                  //   onPressed: () {
                  //     // Navigator.pop(context);
                  //     // Navigator.push(
                  //     //   context,
                  //     //   MaterialPageRoute(
                  //     //     builder: (_) =>
                  //     //         ChatbotPage(locationId: widget.locationId),
                  //     //   ),
                  //     // );
                  //   },
                  // ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ],
          ),
        ),

        const Divider(color: Color(0xFF2A2A2A), height: 1),

        /// ── Messages ──
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            itemCount: messages.length + (_isTyping ? 1 : 0),
            itemBuilder: (context, index) {
              if (_isTyping && index == messages.length) {
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Text("...",
                        style: TextStyle(color: Colors.white)),
                  ),
                );
              }

              final message = messages[index];
              final isBot = message["isBot"] as bool;

              return Column(
                crossAxisAlignment:
                    isBot ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color: isBot
                          ? const Color(0xFF1E1E1E)
                          : const Color(0xFF2D2D2D),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: isBot
                        ? _buildFormattedText(context, message["text"])
                        : Text(
                            message["text"],
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13),
                          ),
                    // child: Text(
                    //   message["text"],
                    //   style: const TextStyle(color: Colors.white, fontSize: 13),
                    // ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      _currentTime(),
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        if (_showSuggestions) _buildSuggestionContainer(),

        /// ── Input Bar ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          color: Colors.black,
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: const Color(0xFF3A3A3A), width: 1),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: "Ask about risk data, eligibility...",
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                      border: InputBorder.none,
                      isCollapsed: true,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                GestureDetector(
                  onTap: _hasText ? _sendMessage : null,
                  child: Icon(
                    Icons.telegram_sharp,
                    color: _hasText ? AppColors.primaryMain : Colors.grey,
                    size: 38,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          height: 25,
        )
      ],
    );
  }

  Widget _buildSuggestionContainer() {
    final suggestions = [
      "Tell me about my locations",
      "What are the top risks for this location?",
      "Summarize this location",
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: suggestions.map((text) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                _controller.text = text;
                _sendMessage();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryMain,
                    width: 1,
                  ),
                ),
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.primaryMain,
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

Widget _buildFormattedText(BuildContext context, String rawText) {
  final text = rawText.replaceAll('**', '');
  final lines = text.split('\n');
  final List<Widget> elements = [];

  for (int i = 0; i < lines.length; i++) {
    final trimmed = lines[i].trim();

    // Skip lines that are just "4." etc.
    if (RegExp(r'^\d+\.$').hasMatch(trimmed)) continue;

    if (trimmed.isEmpty) {
      elements.add(const SizedBox(height: 8));
      continue;
    }

    if (trimmed.endsWith(':') && !trimmed.startsWith('*')) {
      elements.add(Padding(
        padding: EdgeInsets.only(top: i > 0 ? 8.0 : 0, bottom: 4),
        child: Text(
          trimmed,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: AppColors.primaryMain,
          ),
        ),
      ));
    } else if (trimmed.startsWith('*')) {
      final bulletText = trimmed.substring(1).trim();
      elements.add(Padding(
        padding: const EdgeInsets.only(left: 8, bottom: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '• ',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
            ),
            Expanded(
              child: Text(
                bulletText,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ));
    } else {
      final isHighRisk =
          trimmed.contains('Very High') || trimmed.contains('High');
      elements.add(Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          trimmed,
          style: TextStyle(
            fontSize: 13,
            height: 1.5,
            color: isHighRisk ? Colors.white : Colors.white,
          ),
        ),
      ));
    }
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: elements,
  );
}

class _ChatbotBottomSheet extends StatefulWidget {
  final String? locationId;

  const _ChatbotBottomSheet({this.locationId});

  @override
  State<_ChatbotBottomSheet> createState() => _ChatbotBottomSheetState();
}

class _ChatbotBottomSheetState extends State<_ChatbotBottomSheet> {
  bool _isFullScreen = false;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: Container(
        height: _isFullScreen ? screenHeight : screenHeight * 0.62,
        decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            GestureDetector(
              onTap: () => setState(() => _isFullScreen = !_isFullScreen),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade600,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Icon(
                      _isFullScreen
                          ? Icons.keyboard_arrow_down
                          : Icons.keyboard_arrow_up,
                      color: Colors.grey,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: _ChatbotContent(locationId: widget.locationId),
            ),
          ],
        ),
      ),
    );
  }
}
