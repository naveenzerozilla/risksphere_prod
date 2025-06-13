import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';
import 'package:RiskSphere/models/hazard_data.dart';
import 'package:RiskSphere/providers/custom_tile_providers.dart';
import 'package:RiskSphere/providers/custom_tile_providers_main_hazards.dart';
import 'package:RiskSphere/screens/listings/account_list.dart';
import 'package:RiskSphere/screens/listings/hazard_proto.dart'
    hide CustomTileProvider;
import 'package:RiskSphere/screens/listings/sub_account_list.dart';
import 'package:RiskSphere/screens/listings/widgets/location_card.dart'
    show GeocodingDialog;
import 'package:RiskSphere/screens/listings/widgets/vertical_bar_indicator.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart' show DateFormat;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:RiskSphere/constants/enums.dart';
import 'package:RiskSphere/design_system/components/rating_widget.dart';
import 'package:RiskSphere/design_system/primitives/app_colors.dart';
import 'package:RiskSphere/design_system/primitives/custom_typography.dart';
import 'package:RiskSphere/design_system/primitives/utilities/custom_spacing.dart';
import 'package:RiskSphere/models/account_list_model.dart';
import 'package:RiskSphere/providers/location_profile_provider.dart';
import 'package:RiskSphere/providers/place_api_provider.dart';
import 'package:RiskSphere/providers/user_profile_provider.dart';
import 'package:RiskSphere/screens/listings/add_location_screen.dart';
import 'package:RiskSphere/screens/listings/widgets/dots_indicator.dart';
import 'package:RiskSphere/screens/listings/widgets/export_dialog.dart';
import 'package:RiskSphere/screens/listings/widgets/location_details_popup.dart';
import 'package:RiskSphere/screens/listings/widgets/message_card.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:google_maps_cluster_manager_2/google_maps_cluster_manager_2.dart'
    as cluster_manager;
import '../../design_system/components/custom_button.dart';
import '../../models/location_profile_model.dart';
import '../../models/my_location_list_model.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/my_location_list_provider.dart';
import '../../providers/theme_provider.dart';
import '../../design_system/components/custom_appbar.dart';
import '../../design_system/components/custom_drawer.dart';
import 'mapscreen.dart';
import 'widgets/location_list_map_view.dart';

class LocationProfile extends StatefulWidget {
  const LocationProfile({
    super.key,
    required this.accountId,
    required this.accountName,
    required this.subAccountId,
    required this.subAccountName,
    required this.sovId,
    required this.sovName,
    required this.page,
    required this.totalPages,
    required this.searchQuery,
    this.locationId = '',
    this.reset = false,
    this.hazardProcess,
    this.onConfirmCallback,
    this.onNavigateBack,
  });

  final String accountId;
  final String accountName;
  final String subAccountId;
  final String subAccountName;
  final String sovId;
  final String sovName;
  final String page;
  final String? totalPages;
  final String searchQuery;
  final String locationId;
  final bool reset;
  final bool? hazardProcess;
  final VoidCallback? onConfirmCallback;
  final VoidCallback? onNavigateBack;

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

  int tabIndex = 0;
  bool isLoading = false;
  bool addCampusLoading = false;
  bool addCampusLoading1 = false;
  String? selectedLoadingType;
  bool _isExpanded = false;
  bool _showNotificationDot = true;
  List<HazardData> mainHazards = [];
  int? _selectedScore;
  Set<Marker> _markers = {};
  Set<ClusterManager> _clusterManagers = {};

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
  bool _isTaggingSubDestination = false;
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

  TabController? _tabController;
  TextEditingController _nameController = TextEditingController();
  TextEditingController _addressController = TextEditingController();
  TextEditingController _campusIdController = TextEditingController();
  TextEditingController searchController = TextEditingController();
  ScrollController? _campusScrollController;
  List<File> _images = [];
  String autoCompleteSuggestionSessionToken = Uuid().v4();
  MapType _currentMapType = MapType.satellite;
  MapType _currentMapType1 = MapType.normal;
  bool _isBottomSheetExpanded = false;
  bool bottomsheetopened = false;
  bool _isBottomSheetFullScreen = false;
  bool isSwitched = false;
  bool confirmload = false;

  static CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(40.32434, -111.889),
    zoom: 16,
  );

  MarkerId? _selectedMarker;
  late String _totalPages;

  late TextEditingController _searchController;

  ScrollController _scrollController = ScrollController();

  String _formatDate(int secondsSinceEpoch) {
    try {
      final date =
          DateTime.fromMillisecondsSinceEpoch(secondsSinceEpoch * 1000);
      return DateFormat('yyyy-MM-dd HH:mm').format(date);
    } catch (e) {
      return '';
    }
  }

  String _formatTimestamp(int? seconds) {
    if (seconds == null) return '';
    final dateTime = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
  }

  @override
  void initState() {
    if (!_isInitialized) {
      // Only run if not initialized
      _searchController = TextEditingController();
      _tabController = TabController(length: 2, vsync: this);
      super.initState();
      _totalPages = widget.totalPages!;
      _campusScrollController = ScrollController();
      _pageController =
          PageController(viewportFraction: 0.9, initialPage: selectedIndex);

      // Execute parallel API calls
      _fetchAllData();

      _isInitialized = true; // Mark as initialized

      _tabController!.addListener(() {
        setState(() {
          tabIndex = _tabController!.index;
        });
      });
    }
  }

  _fetchAllData() async {
    await Future.wait(<Future>[
      _getData(),
      _initializeClusterManager(),
      _fetchMainHazardLayers(),
    ]);
  }

//   Future<void> _navigateRight() async {
//     if (_isLoading) return;
//
//     setState(() {
//       _isLoading = true;
//     });
//
//     print('Navigating from page ${widget.page} of ${widget.totalPages}');
//
//     final locationProvider =
//         Provider.of<MyLocationListProvider>(context, listen: false);
//
//     int currentPage = int.tryParse(widget.page) ?? 1;
//     // int? totalPages = widget.locationId.isNotEmpty
//     //     ? int.tryParse(locationProvider.totalPages.toString())
//     //     : int.tryParse(widget.totalPages!) ??
//     //         int.tryParse(locationProvider.totalPages.toString());
//     int? totalPages = widget.locationId.isNotEmpty
//         ? int.parse(locationProvider.totalPages.toString())
//         : int.tryParse(widget.totalPages!) ==
//                 int.parse(locationProvider.totalPages.toString())
//             ? int.tryParse(widget.totalPages!)
//             : int.parse(locationProvider.totalPages.toString());
//     print(currentPage);
// print(totalPages);
// print(widget.totalPages);
//     totalPages.toString() == "0" ? widget.totalPages : totalPages;
// print(totalPages);
// print(totalPages);
//     if (currentPage >= totalPages!) {
//       // if (currentPage >= (totalPages ?? 0)) {
//       print('Already on the last page.');
//       setState(() {
//         _isLoading = false;
//       });
//       return;
//     }
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

    totalPages = widget.locationId.isNotEmpty
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

  void _navigateLeft() {
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
    int? totalPages = widget.locationId.isNotEmpty
        ? int.parse(locationProvider.totalPages.toString())
        : int.tryParse(widget.totalPages!) ==
                int.parse(locationProvider.totalPages.toString())
            ? int.tryParse(widget.totalPages!)
            : int.parse(locationProvider.totalPages.toString());
    // int? totalPages = widget.locationId.isNotEmpty
    //     ? locationProvider.resetTotalPage
    //     : (int.tryParse(widget.totalPages!) ?? 1);
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
          page: pageToNavigate.toString(),
          totalPages: totalPages.toString(),
        ),
      ),
    );
  }

  // Future<void> _navigateRight() async {
  //   print("object");
  //   if (_isLoading) return;
  //
  //   setState(() {
  //     _isLoading = true;
  //   });
  //
  //   print('Navigating from page ${widget.page} of ${widget.totalPages}');
  //
  //   final locationProvider =
  //       Provider.of<MyLocationListProvider>(context, listen: false);
  //
  //   int currentPage = int.tryParse(widget.page) ?? 1;
  //   int? totalPages = widget.locationId.isNotEmpty
  //       ? int.parse(locationProvider.totalPages.toString())
  //       : int.tryParse(widget.totalPages!) ==
  //               int.parse(locationProvider.totalPages.toString())
  //           ? int.tryParse(widget.totalPages!)
  //           : int.parse(locationProvider.totalPages.toString());
  //
  //   if (currentPage >= totalPages!) {
  //     print('Already on the last page.');
  //     setState(() {
  //       _isLoading = false;
  //     });
  //     return;
  //   }
  //
  //   int pageToNavigate = currentPage + 1;
  //   print('Navigating to page: $pageToNavigate');
  //
  //   bool alreadyExists = false;
  //   Navigator.popUntil(context, (route) {
  //     if (route.settings.name == 'LocationProfile$pageToNavigate') {
  //       alreadyExists = true;
  //     }
  //     return true;
  //   });
  //
  //   if (alreadyExists) {
  //     print('Page $pageToNavigate already exists. Not pushing a new one.');
  //     setState(() {
  //       _isLoading = false;
  //     });
  //     return;
  //   }
  //
  //   // Execute navigation in a separate microtask to ensure UI updates first
  //   Future.microtask(() {
  //     print("testsuccess");
  //     Navigator.of(context)
  //         .pushReplacement(
  //       MaterialPageRoute(
  //         builder: (context) => LocationProfile(
  //           accountId: widget.accountId,
  //           subAccountId: widget.subAccountId,
  //           sovId: widget.sovId,
  //           accountName: widget.accountName,
  //           subAccountName: widget.subAccountName,
  //           sovName: widget.sovName,
  //           searchQuery: widget.searchQuery,
  //           page: pageToNavigate.toString(),
  //           totalPages: totalPages.toString(),
  //         ),
  //       ),
  //     )
  //         .then((_) {
  //       setState(() {
  //         _isLoading = false;
  //       });
  //     });
  //   });
  // }
  //
  // void _navigateLeft() {
  //   int currentPage = int.tryParse(widget.page) ?? 1;
  //
  //   // Prevent navigation beyond first page
  //   if (currentPage <= 1) {
  //     print('Already on the first page.');
  //     return;
  //   }
  //
  //   int pageToNavigate = currentPage - 1;
  //   print('Navigating to page: $pageToNavigate');
  //
  //   final locationProvider =
  //       Provider.of<MyLocationListProvider>(context, listen: false);
  //   int? totalPages = widget.locationId.isNotEmpty
  //       ? int.parse(locationProvider.totalPages.toString())
  //       : int.tryParse(widget.totalPages!) ==
  //               int.parse(locationProvider.totalPages.toString())
  //           ? int.tryParse(widget.totalPages!)
  //           : int.parse(locationProvider.totalPages.toString());
  //   // int? totalPages = widget.locationId.isNotEmpty
  //   //     ? locationProvider.resetTotalPage
  //   //     : (int.tryParse(widget.totalPages!) ?? 1);
  //   Navigator.of(context).replace(
  //     oldRoute: ModalRoute.of(context)!,
  //     newRoute: MaterialPageRoute(
  //       builder: (context) => LocationProfile(
  //         accountId: widget.accountId,
  //         subAccountId: widget.subAccountId,
  //         sovId: widget.sovId,
  //         accountName: widget.accountName,
  //         subAccountName: widget.subAccountName,
  //         sovName: widget.sovName,
  //         searchQuery: widget.searchQuery,
  //         page: pageToNavigate.toString(),
  //         totalPages: totalPages.toString(),
  //       ),
  //     ),
  //   );
  // }

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

  Future<void> _getData() async {
    // Make API call to get the data
    // await Provider.of<DashboardProvider>(context, listen: false).getDashboardData(context);
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
    print("ADDsubDestionationstart");
    try {
      var provider =
          Provider.of<MyLocationListProvider>(context, listen: false);
      Map<MarkerId, Marker> newMarkers = {}; // Temporary map to hold markers

      for (var subdestination
          in provider.locationProfile?.subdestinations ?? []) {
        print("ADDsubDestionationstart1oop");
        try {
          var markerId = MarkerId(subdestination.id!);
          var isAdded = (subdestination.status ?? "").toLowerCase() == "added";

          var marker = Marker(
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
    // Make API call to upload the images
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

  @override
  void dispose() {
    // TODO: implement dispose
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
            backgroundColor: themeProvider.getTheme.colorScheme.background,
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
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Left Column
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          InkWell(
                                              onTap: () {
                                                !bottomsheetopened
                                                    ? Navigator.pop(
                                                        context, false)
                                                    : null;
                                              },
                                              child: Icon(
                                                  Icons.arrow_back_ios_new,
                                                  size: 20)),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 4.0),
                                            child: Row(
                                              children: [
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 2.0, bottom: 6),
                                                  child: Row(
                                                    children: [
                                                      InkWell(
                                                        onTap: () {
                                                          !bottomsheetopened
                                                              ? Navigator
                                                                  .pushAndRemoveUntil(
                                                                  context,
                                                                  MaterialPageRoute(
                                                                      builder:
                                                                          (context) =>
                                                                              AccountListScreen()),
                                                                  (route) =>
                                                                      false, // This removes all previous routes
                                                                ).then((_) {
                                                                  // Optional: Add any actions to perform after navigation
                                                                })
                                                              : null;
                                                        },
                                                        child: Text(
                                                            widget.accountName,
                                                            style: typography
                                                                .InputLabel),
                                                      ),
                                                      Text(' > ',
                                                          style: typography
                                                              .InputLabel),
                                                      InkWell(
                                                        onTap: () {
                                                          !bottomsheetopened
                                                              ? Navigator
                                                                  .pushAndRemoveUntil(
                                                                  context,
                                                                  MaterialPageRoute(
                                                                    builder:
                                                                        (context) =>
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
                                                                      false, // This removes all previous routes
                                                                ).then((_) {
                                                                  // Optional: Add any actions to perform after navigation
                                                                })
                                                              : null;
                                                        },
                                                        child: Text(
                                                            widget
                                                                .subAccountName,
                                                            style: typography
                                                                .InputLabel),
                                                      ),
                                                      Text(' > ',
                                                          style: typography
                                                              .InputLabel),
                                                      InkWell(
                                                        onTap: () {
                                                          !bottomsheetopened
                                                              ? Navigator.pop(
                                                                  context)
                                                              : null;
                                                        },
                                                        child: Text(
                                                            widget.accountName,
                                                            style: typography
                                                                .InputLabel),
                                                      ),
                                                      Text(' > ',
                                                          style: TextStyle(
                                                              fontSize: 12,
                                                              color: Colors
                                                                  .white70)),
                                                      Text("Location Profile",
                                                          // _masterTabController!.index
                                                          //     .toString() ==
                                                          //     "0"
                                                          //     ? "Location list"
                                                          //     : _masterTabController!.index
                                                          //     .toString() ==
                                                          //     "1"
                                                          //     ? "Sovs"
                                                          //     : _masterTabController!
                                                          //     .index
                                                          //     .toString() ==
                                                          //     "2"
                                                          //     ? "Shared"
                                                          //     : "Configure",
                                                          style: TextStyle(
                                                              fontSize: 12,
                                                              color: Colors
                                                                  .white)),
                                                    ],
                                                  ),
                                                ),
                                                // Container(
                                                //   child: MaintenanceUI(isMaintenance: isMaintenance),
                                                // ),
                                              ],
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    SizedBox(
                                                        height:
                                                            CustomSpacing.two),
                                                    Text(
                                                      locationProfileProvider
                                                              .locationProfile
                                                              ?.finalAddress
                                                              ?.locationName ??
                                                          '',
                                                      style: typography.H6
                                                          .copyWith(
                                                              height: 1.2),
                                                      overflow: TextOverflow
                                                          .ellipsis, // Handle overflow
                                                    ),
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
                                              // Text(_isBottomSheetFullScreen.toString()),
                                              // Text(bottomsheetopened.toString()),
                                              IconButton(
                                                  splashRadius: 1,
                                                  padding: EdgeInsets.zero,
                                                  icon: Icon(Icons.edit,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .primary),
                                                  onPressed: () {
                                                    bottomsheetopened != true
                                                        ? _editName(
                                                            locationProfileProvider)
                                                        : null;
                                                  }),
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
                              Container(
                                padding: EdgeInsets.only(left: 16, right: 24),
                                child: Row(
                                  children: [
                                    Text("Rating"),
                                    SizedBox(width: 3),
                                    InkWell(
                                        onTap: () {
                                          bottomsheetopened != true
                                              ? showDialog(
                                                  context: context,
                                                  builder: (context) =>
                                                      GeocodingDialog(
                                                          title: 'Geocoding',
                                                          status: true),
                                                )
                                              : null;
                                        },
                                        child: Icon(Icons.info,
                                            color: Colors.lightBlueAccent))
                                  ],
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(left: 16, right: 24),
                                child: Row(
                                  // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    VerticalBarIndicator(
                                        score: context
                                                .read<MyLocationListProvider>()
                                                .locationProfile
                                                ?.geocodingScore ??
                                            0),
                                    SizedBox(width: 8),
                                    (locationProfileProvider.locationProfile
                                                    ?.finalAddress?.score ??
                                                0) ==
                                            5
                                        ? SvgPicture.asset(
                                            'assets/images/certified_five.svg',
                                            width: 24,
                                            height: 24)
                                        : SizedBox.shrink(),
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: tabIndex == 0
                                    ? MediaQuery.of(context).size.height * 0.70
                                    : MediaQuery.of(context).size.height * 0.80,
                                child: DefaultTabController(
                                  length: _tabController!.length,
                                  // Only two active tabs
                                  child: Column(
                                    children: [
                                      TabBar(
                                        onTap: (index) {
                                          if (bottomsheetopened || index >= 2)
                                            return; // Block tap if bottom sheet open or index is disabled
                                          setState(() => tabIndex = index);
                                        },
                                        tabs: [
                                          Tab(text: 'Geocoding'),
                                          Tab(text: 'Risk Score'),
                                        ],
                                      ),
                                      Container(
                                        // height: MediaQuery.of(context).size.height * 0.5,
                                        height: tabIndex == 0
                                            ? MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.58
                                            : MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.55,
                                        child: TabBarView(
                                          physics:
                                              NeverScrollableScrollPhysics(),
                                          // Prevent swipe navigation
                                          children: [
                                            _geocodingScore(),
                                            _riskScore(),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              _isBottomSheetExpanded
                                  ?
                                  //     Center(
                                  //         child: ClipRRect(
                                  //           borderRadius: BorderRadius.circular(12),
                                  //           child: BackdropFilter(
                                  //             filter: ImageFilter.blur(
                                  //                 sigmaX: 5, sigmaY: 5),
                                  //             child: Container(
                                  //               width: 300,
                                  //               height: 200,
                                  //               color: Colors.white.withOpacity(0.3),
                                  //               child: Text('Blurred Dialog'),
                                  //             ),
                                  //           ),
                                  //         ),
                                  //       )

                                  // Stack(
                                  //         children: [
                                  //           Positioned.fill(
                                  //             child: RepaintBoundary(
                                  //               // Ensures Flutter renders this section
                                  //               child: ClipRect(
                                  //                 child: BackdropFilter(
                                  //                   filter: ImageFilter.blur(
                                  //                       sigmaX: 5, sigmaY: 5),
                                  //                   child: Container(
                                  //                     color: Colors.transparent,
                                  //                   ),
                                  //                 ),
                                  //               ),
                                  //             ),
                                  //           ),
                                  //         ],
                                  //       )
                                  // : SizedBox.shrink(),

                                  // _isBottomSheetExpanded == true
                                  //     ? Stack(
                                  //         children: [
                                  //           Positioned.fill(
                                  //             child: BackdropFilter(
                                  //               filter: ImageFilter.blur(
                                  //                   sigmaX: 5, sigmaY: 5),
                                  //               child: Container(
                                  //                 color: Colors.black.withOpacity(0.2),
                                  //               ),
                                  //             ),
                                  //           ),
                                  //         ],
                                  //       )
                                  SizedBox(
                                      width: double.infinity,
                                      height: 300,
                                      // or MediaQuery.of(context).size.height
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
                  // Show bottom sheet when tabIndex is 0
                  if (!_isBottomSheetFullScreen && tabIndex == 0)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: _buildBottomSheet(),
                    ),

                  if (_isBottomSheetFullScreen)
                    Positioned.fill(
                      child: _locationProfileBody(),
                    ),

                  if (_selectedMarker != null) _buildCustomInfoWindow(),
                  // if (_isBottomSheetFullScreen)
                  //   Positioned.fill(
                  //     child: _locationProfileBody(),
                  //   ),
                  // if (_selectedMarker != null) _buildCustomInfoWindow(),
                ],
              );
            }),
          );
        });
      }),
    );
  }

  Widget _buildCustomInfoWindow() {
    var typography = CustomTypography(context);
    var marker = markers[_selectedMarker];
    var isSubdestination =
        marker?.infoWindow.title?.contains("Subdestination") ?? false;
    var isAdded = marker?.infoWindow.snippet?.contains("Added") ?? false;
    String occupancy =
        marker?.infoWindow.snippet?.split("Occupancy: ")?.last ?? "";

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
                            marker?.markerId?.value ?? "", occupancy);
                      } else {
                        _addToSOV(marker?.markerId?.value ?? "",
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
                : 100,
          ),
          // height: _isBottomSheetExpanded ? 600 : 100,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              SizedBox(height: 20),
              if (!_isBottomSheetExpanded) ...[
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    SizedBox(height: 20),
                    ListTile(
                      title: Text(
                        '${widget.accountName}/${widget.subAccountName}-${widget.sovName}/${locationProfileProvider.locationProfile?.finalAddress?.locationIdForRef ?? ''}${formatLocationText((int.tryParse(widget.page) ?? 1) + 0, (int.tryParse(widget.totalPages!) ?? 1))}',
                        style: typography.Subtitle1.copyWith(
                            fontWeight: FontWeight.w500),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      trailing: IconButton(
                        icon: Icon(_isBottomSheetExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down),
                        onPressed: () {
                          print("object");
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
                Center(
                  child: InkWell(
                    // behavior: HitTestBehavior.translucent,
                    // Ensures taps register
                    onTap: () {
                      setState(() {
                        _isBottomSheetExpanded = !_isBottomSheetExpanded;
                        bottomsheetopened = false;
                      });
                      print(bottomsheetopened);
                    },
                    child: Container(
                      width: 25,
                      height: 25,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.onSurface,
                          width: 1,
                        ),
                      ),
                      child: Icon(Icons.close),
                    ),
                  ),
                ),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ListTile(
                      title: Text(
                        '${widget.accountName}/${widget.subAccountName}-${widget.sovName}/${locationProfileProvider.locationProfile?.finalAddress?.locationIdForRef ?? ''}${formatLocationText((int.tryParse(widget.page) ?? 1) + 0, (int.tryParse(widget.totalPages!) ?? 1))}',
                        style: typography.Subtitle1.copyWith(
                            fontWeight: FontWeight.w500),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      trailing: IconButton(
                        icon: Icon(_isBottomSheetExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down),
                        onPressed: () {
                          // setState(() {
                          //   _isBottomSheetExpanded = !_isBottomSheetExpanded;
                          // });

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
                  ],
                ),
                Divider(),
                Row(
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width / 1,
                      padding: EdgeInsets.only(left: 16),
                      child: Text(
                        locationProfileProvider
                                .locationProfile?.finalAddress?.address ??
                            'N/A',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14, color: Colors.white),
                      ),
                    )
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Address',
                        style: typography.H6.copyWith(height: 0.5),
                      ),
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
                    ],
                  ),
                ),
                DefaultTabController(
                  length: 2, // Number of tabs
                  child: Column(
                    children: [
                      TabBar(
                        onTap: (index) {
                          if (!mounted) return;
                          if (index == 0) {
                            setState(() => tabIndex = 0);
                            Provider.of<MyLocationListProvider>(context,
                                    listen: false)
                                .fetchLocations();
                          }
                          // Do nothing if index == 1
                        },
                        tabs: [
                          Tab(
                            text: 'Campus',
                          ),
                          Tab(
                            text: 'Media Gallery',
                          ),
                        ],
                      ),
                      Container(
                        constraints: BoxConstraints(
                          minHeight: 10,
                          maxHeight: Platform.isAndroid
                              ? MediaQuery.of(context).size.height * 0.38
                              : MediaQuery.of(context).size.height * 0.31,
                        ),
                        child: TabBarView(
                          physics: NeverScrollableScrollPhysics(),
                          children: [
                            _campusWidget(),
                            _mediaGalleryWidget(),
                          ],
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

        int notAddedCount = allSubdestinations
            .where((sub) => (sub.status ?? '').toLowerCase() != 'added')
            .length;

        // List<Subdestination> filteredSubdestinations = allSubdestinations
        //     .where((sub) {
        //   final status = (sub.status ?? '').toLowerCase();
        //   return isSwitched ? status == 'added' : status != 'added';
        // }).toList();

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
                                        activeColor: Colors.blue,
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
                                height: 230,
                                child:
                                    Text('No Campus', style: typography.Body1)))
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
                                        : MediaQuery.of(context).size.height /
                                            7),
                                child: PageView.builder(
                                  key: const ValueKey('campus_page_view'),
                                  controller: _pageController,
                                  itemCount: filteredSubdestinations.length,
                                  itemBuilder: (context, index) {
                                    int totalItems =
                                        filteredSubdestinations.length;

                                    int addedSelectedCount =
                                        filteredSubdestinations.where((item) {
                                      final id = item.id ?? '';
                                      final status =
                                          (item?.status ?? '').toLowerCase();
                                      final isSelected =
                                          selectedIds.contains(id);
                                      return isSelected && status == 'added';
                                    }).length;

                                    var subdestination =
                                        filteredSubdestinations[index];
                                    final id = subdestination.id ?? '';
                                    final status =
                                        (subdestination?.status ?? '')
                                            .toLowerCase();
                                    final isSelected = selectedIds.contains(id);
                                    final canSelect = status != 'added';
                                    return
                                        // status == 'added'?
                                        GestureDetector(
                                      onTap: () {
                                        if (isSelectionMode && canSelect) {
                                          setState(() {
                                            if (isSelected) {
                                              selectedIds.remove(id);
                                            } else {
                                              selectedIds.add(id);
                                            }
                                            if (selectedIds.isEmpty) {
                                              isSelectionMode = false;
                                            }
                                          });
                                        } else {
                                          _focusOnSubdestination(
                                              subdestination!);
                                        }
                                      },
                                      onLongPress: () {
                                        if (canSelect) {
                                          setState(() {
                                            isSelectionMode = true;
                                            if (isSelected) {
                                              selectedIds.remove(id);
                                            } else {
                                              selectedIds.add(id);
                                            }
                                            if (selectedIds.isEmpty) {
                                              isSelectionMode = false;
                                            }
                                          });
                                        }
                                      },
                                      onDoubleTap: () {
                                        setState(() {
                                          selectedIndex = index;
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
                                                (subdestination?.rented ??
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
                                                  // leading: isSelectionMode &&
                                                  //         canSelect
                                                  leading: canSelect
                                                      ? Checkbox(
                                                          value: isSelected,
                                                          onChanged:
                                                              (bool? checked) {
                                                            setState(() {
                                                              if (checked ==
                                                                  true) {
                                                                selectedIds
                                                                    .add(id);
                                                              } else {
                                                                selectedIds
                                                                    .remove(id);
                                                              }
                                                              isSelectionMode =
                                                                  selectedIds
                                                                      .isNotEmpty;
                                                            });
                                                          },
                                                        )
                                                      : null,
                                                  title: Text(
                                                    subdestination?.name ?? '',
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  subtitle: Text(
                                                    subdestination?.address ??
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
                                                                    ?.status ??
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
                                                                    null)
                                                                  return;
                                                                if (!mounted)
                                                                  return;
                                                                setState(() {
                                                                  occupancy =
                                                                      value;
                                                                  subdestination
                                                                          ?.rented =
                                                                      false;
                                                                  isLoading =
                                                                      true;
                                                                  selectedLoadingType =
                                                                      value;
                                                                });

                                                                var provider =
                                                                    Provider.of<
                                                                            MyLocationListProvider>(
                                                                        context,
                                                                        listen:
                                                                            false);
                                                                bool result =
                                                                    await provider
                                                                        .changeOccupancy(
                                                                  context,
                                                                  subdestination
                                                                          ?.locationId ??
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
                                                                  setState(() {
                                                                    occupancy =
                                                                        "Rented/Leased";
                                                                    subdestination
                                                                            ?.rented =
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
                                                        value: "Rented/Leased",
                                                        groupValue: occupancy,
                                                        onChanged: isLoading
                                                            ? null
                                                            : (value) async {
                                                                if (value ==
                                                                    null)
                                                                  return;
                                                                if (!mounted)
                                                                  return;
                                                                setState(() {
                                                                  occupancy =
                                                                      value;
                                                                  subdestination
                                                                          ?.rented =
                                                                      true;
                                                                  isLoading =
                                                                      true;
                                                                  selectedLoadingType =
                                                                      value;
                                                                });

                                                                var provider =
                                                                    Provider.of<
                                                                            MyLocationListProvider>(
                                                                        context,
                                                                        listen:
                                                                            false);
                                                                bool result =
                                                                    await provider
                                                                        .changeOccupancy(
                                                                  context,
                                                                  subdestination
                                                                          ?.locationId ??
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
                                                                  setState(() {
                                                                    occupancy =
                                                                        "Owned";
                                                                    subdestination
                                                                            ?.rented =
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
                                    // :Container();
                                  },
                                  onPageChanged: (index) {
                                    setState(() {
                                      selectedIndex = index;
                                    });
                                    // var subdestination = locationProfileProvider.subdestinations[index];
                                    // _focusOnSubdestination(subdestination);
                                    var subdestination = locationProfileProvider
                                        .subdestinations[index];
                                    _focusOnSubdestination(subdestination);
                                  },
                                ),
                              ),
                              SizedBox(height: 70),
                              if (isSelectionMode &&
                                  // selectedIds.length > 1 &&
                                  !isSwitched)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 32.0, vertical: 8.0),
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
                                            builder: (context, setStateDialog) {
                                              return AlertDialog(
                                                title: Text(
                                                    "Confirm Add to Campus"),
                                                content: SizedBox(
                                                  width: double.maxFinite,
                                                  height: 180,
                                                  child: ListView.separated(
                                                    itemCount:
                                                        tempSelectedIds.length,
                                                    separatorBuilder: (context,
                                                            index) =>
                                                        SizedBox(height: 12),
                                                    itemBuilder:
                                                        (context, index) {
                                                      final selectedId =
                                                          tempSelectedIds
                                                              .toList()[index];
                                                      final item =
                                                          filteredSubdestinations
                                                              .firstWhere(
                                                                  (element) =>
                                                                      element
                                                                          .id ==
                                                                      selectedId);

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
                                                                (bool? value) {
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
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            12,
                                                                        color: Colors
                                                                            .grey),
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
                                                        Navigator.of(context)
                                                            .pop(),
                                                    child: Text("Cancel"),
                                                  ),
                                                  ElevatedButton(
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.zero,
                                                      ),
                                                    ),
                                                    onPressed: confirmload
                                                        ? null
                                                        : () async {
                                                            setStateDialog(() {
                                                              confirmload =
                                                                  true;
                                                            });

                                                            try {
                                                              var provider =
                                                                  Provider.of<
                                                                          MyLocationListProvider>(
                                                                      context,
                                                                      listen:
                                                                          false);
                                                              final campusId = provider
                                                                      .locationProfile
                                                                      ?.finalAddress
                                                                      ?.campusId ??
                                                                  "";

                                                              for (String id
                                                                  in tempSelectedIds) {
                                                                final subdestination =
                                                                    filteredSubdestinations.firstWhere(
                                                                        (item) =>
                                                                            item.id ==
                                                                            id);
                                                                String
                                                                    occupancy =
                                                                    (subdestination.rented ??
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

                                                              setState(() {
                                                                selectedIds
                                                                    .clear();
                                                                isLoadingAddToCampus =
                                                                    false;
                                                                isSelectionMode =
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
                                                                    .pop(true);
                                                              }
                                                            } catch (e) {
                                                              print(
                                                                  "Error: $e");
                                                            } finally {
                                                              if (context
                                                                  .mounted) {
                                                                setState(() {
                                                                  confirmload =
                                                                      false;
                                                                });
                                                              }
                                                            }
                                                          },
                                                    child: confirmload
                                                        ? SizedBox(
                                                            width: 20,
                                                            height: 20,
                                                            child:
                                                                CircularProgressIndicator(
                                                              strokeWidth: 2,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                          )
                                                        : Text("Confirm"),
                                                  )
                                                ],
                                              );
                                            },
                                          );
                                        },
                                      );
                                    },
                                    child: isLoadingAddToCampus
                                        ? SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Colors.white),
                                            ),
                                          )
                                        : Text('Add Location to Campus',
                                            style: typography.Body1),
                                  ),
                                ),
                              // SizedBox(height: 5),
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

  Widget _mediaGalleryWidget() {
    var typography = CustomTypography(context);
    return Consumer<MyLocationListProvider>(
      builder: (context, locationProfileProvider, child) {
        return Builder(
          builder: (context) {
            return Stack(
              children: [
                if (_isBottomSheetExpanded)
                  Scrollbar(
                    thumbVisibility: true,
                    child: ListView(
                      children: [
                        // Removed Expanded from here
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
                            ? Center(
                                child: Container(
                                  height: 200,
                                  alignment: Alignment.center,
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : _images.isNotEmpty ||
                                    locationProfileProvider.locationProfile
                                            ?.screenshots?.isNotEmpty ==
                                        true
                                ? Column(
                                    // Wrapped in Column instead of Expanded
                                    children: [
                                      Container(
                                        height:
                                            MediaQuery.of(context).size.height /
                                                4,
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .surface,
                                        ),
                                        child: PageView.builder(
                                          key: ValueKey(
                                            _images.length +
                                                (locationProfileProvider
                                                        .locationProfile
                                                        ?.screenshots
                                                        ?.length ??
                                                    0),
                                          ),
                                          controller: PageController(
                                              viewportFraction: 0.9),
                                          itemCount: _images.length +
                                              (locationProfileProvider
                                                      .locationProfile
                                                      ?.screenshots
                                                      ?.length ??
                                                  0),
                                          itemBuilder: (BuildContext context,
                                              int itemIndex) {
                                            if (itemIndex < _images.length) {
                                              final localImage =
                                                  _images[itemIndex];

                                              return Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8.0),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Expanded(
                                                      child: Stack(
                                                        children: [
                                                          Center(
                                                            child: ClipRRect(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          16),
                                                              child: Image.file(
                                                                localImage,
                                                                width: double
                                                                    .infinity,
                                                                height: double
                                                                    .infinity,
                                                                fit: BoxFit
                                                                    .cover,
                                                              ),
                                                            ),
                                                          ),
                                                          Positioned(
                                                            top: 8,
                                                            right: 8,
                                                            child: IconButton(
                                                              icon: Icon(
                                                                  Icons.delete,
                                                                  color: Colors
                                                                      .red),
                                                              onPressed: () {
                                                                print(
                                                                    localImage ??
                                                                        '');
                                                                setState(() {
                                                                  _images.removeAt(
                                                                      itemIndex);
                                                                });
                                                              },
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    const Padding(
                                                      padding: EdgeInsets.only(
                                                          left: 10.0),
                                                      child: Text(
                                                        '',
                                                        style:
                                                            TextStyle(), // You can add styling if needed
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              left: 10.0),
                                                      child: Text(
                                                        "",
                                                        // _formatTimestamp(DateTime.now().second),
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodyMedium,
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
                                                          ?.screenshots?[
                                                      screenshotIndex];

                                              if (screenshot == null)
                                                return const SizedBox();

                                              return Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8.0),
                                                child: GestureDetector(
                                                  onTap: () =>
                                                      _showImagePreviewFromUrl(
                                                          screenshot.imageUrl ??
                                                              ''),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Expanded(
                                                        child: Stack(
                                                          children: [
                                                            Center(
                                                              child: ClipRRect(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            16),
                                                                child: Image
                                                                    .network(
                                                                  screenshot
                                                                          .imageUrl ??
                                                                      '',
                                                                  width: double
                                                                      .infinity,
                                                                  height: double
                                                                      .infinity,
                                                                  fit: BoxFit
                                                                      .cover,
                                                                ),
                                                              ),
                                                            ),
                                                            Positioned(
                                                              top: 8,
                                                              right: 8,
                                                              child: IconButton(
                                                                icon: Icon(
                                                                    Icons
                                                                        .delete,
                                                                    color: Colors
                                                                        .red),
                                                                onPressed: () {
                                                                  print(screenshot
                                                                          .imageUrl ??
                                                                      '');
                                                                  setState(() {
                                                                    locationProfileProvider
                                                                        .locationProfile
                                                                        ?.screenshots
                                                                        ?.removeAt(
                                                                            screenshotIndex);
                                                                  });
                                                                },
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(
                                                                left: 10.0),
                                                        child: Text(
                                                          '${screenshot.name ?? ''} (@)',
                                                          style:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .bodyMedium,
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(
                                                                left: 10.0),
                                                        child: Text(
                                                          _formatTimestamp(
                                                              screenshot
                                                                  .createdAt
                                                                  ?.iSeconds),
                                                          style:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .bodyMedium,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                    ],
                                  )
                                : Center(
                                    child: Container(
                                      height:
                                          MediaQuery.of(context).size.height /
                                              4,
                                      alignment: Alignment.center,
                                      child: Text(
                                        'No Images',
                                        style: typography.Body1,
                                      ),
                                    ),
                                  ),
                        // Removed Expanded from here
                        Container(
                          margin: EdgeInsets.symmetric(horizontal: 30),
                          child: CustomButton(
                            type: ButtonType.elevated,
                            onPressed: _pickImage,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(Icons.upload_sharp,
                                    color: Colors.black, size: 20),
                                SizedBox(width: 20),
                                InkWell(
                                  onTap: _pickImage,
                                  child: Text(
                                    'Upload relevant image(s)',
                                    style: TextStyle(
                                        color: Colors.black, fontSize: 16),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  // Widget _mediaGalleryWidget() {
  //   var typography = CustomTypography(context);
  //   return Consumer<MyLocationListProvider>(
  //       builder: (context, locationProfileProvider, child) {
  //     return Builder(builder: (context) {
  //       return Stack(
  //         children: [
  //           if (_isBottomSheetExpanded)
  //             Scrollbar(
  //               thumbVisibility: true,
  //               child: ListView(
  //                 children: [
  //                   Expanded(
  //                     flex: 1,
  //                     child: Padding(
  //                       padding: const EdgeInsets.symmetric(horizontal: 16.0),
  //                       child: Row(
  //                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                         children: [
  //                           Text(
  //                             'Images',
  //                             style: typography.H6.copyWith(height: 1.2),
  //                           ),
  //                           IconButton(
  //                             icon: Icon(Icons.upload),
  //                             onPressed: _pickImage,
  //                           ),
  //                         ],
  //                       ),
  //                     ),
  //                   ),
  //                   locationProfileProvider.isUploadingImage
  //                       ? Center(
  //                           child: Container(
  //                               height: 200,
  //                               alignment: Alignment.center,
  //                               child: CircularProgressIndicator()))
  //                       : _images.isNotEmpty ||
  //                               locationProfileProvider.locationProfile
  //                                       ?.screenshots?.isNotEmpty ==
  //                                   true
  //                           ? Expanded(
  //                               flex: 1,
  //                               child: Column(
  //                                 children: [
  //                                   Container(
  //                                     height:
  //                                         MediaQuery.of(context).size.height /
  //                                             4,
  //                                     decoration: BoxDecoration(
  //                                       color: Theme.of(context)
  //                                           .colorScheme
  //                                           .surface,
  //                                     ),
  //                                     child: PageView.builder(
  //                                       key: ValueKey(
  //                                         _images.length +
  //                                             (locationProfileProvider
  //                                                     .locationProfile
  //                                                     ?.screenshots
  //                                                     ?.length ??
  //                                                 0),
  //                                       ),
  //                                       controller: PageController(
  //                                           viewportFraction: 0.9),
  //                                       itemCount: _images.length +
  //                                           (locationProfileProvider
  //                                                   .locationProfile
  //                                                   ?.screenshots
  //                                                   ?.length ??
  //                                               0),
  //                                       itemBuilder: (BuildContext context,
  //                                           int itemIndex) {
  //                                         if (itemIndex < _images.length) {
  //                                           // ✅ Local image
  //                                           final localImage =
  //                                               _images[itemIndex];
  //
  //                                           return Padding(
  //                                             padding:
  //                                                 const EdgeInsets.symmetric(
  //                                                     horizontal: 8.0),
  //                                             child: Column(
  //                                               crossAxisAlignment:
  //                                                   CrossAxisAlignment.start,
  //                                               children: [
  //                                                 Expanded(
  //                                                   child: Stack(
  //                                                     children: [
  //                                                       Center(
  //                                                         child: ClipRRect(
  //                                                           borderRadius:
  //                                                               BorderRadius
  //                                                                   .circular(
  //                                                                       16),
  //                                                           child: Image.file(
  //                                                             localImage,
  //                                                             width: double
  //                                                                 .infinity,
  //                                                             height: double
  //                                                                 .infinity,
  //                                                             fit: BoxFit.cover,
  //                                                           ),
  //                                                         ),
  //                                                       ),
  //                                                       Positioned(
  //                                                         top: 8,
  //                                                         right: 8,
  //                                                         child: IconButton(
  //                                                           icon: Icon(
  //                                                               Icons.delete,
  //                                                               color:
  //                                                                   Colors.red),
  //                                                           onPressed: () {
  //                                                             print(
  //                                                                 localImage ??
  //                                                                     '');
  //                                                             setState(() {
  //                                                               _images.removeAt(
  //                                                                   itemIndex);
  //                                                             });
  //                                                           },
  //                                                         ),
  //                                                       ),
  //                                                     ],
  //                                                   ),
  //                                                 ),
  //                                                 const SizedBox(height: 2),
  //                                                 const Padding(
  //                                                   padding: EdgeInsets.only(
  //                                                       left: 10.0),
  //                                                   child: Text(
  //                                                     '',
  //                                                     style:
  //                                                         TextStyle(), // You can add styling if needed
  //                                                   ),
  //                                                 ),
  //                                                 Padding(
  //                                                   padding:
  //                                                       const EdgeInsets.only(
  //                                                           left: 10.0),
  //                                                   child: Text(
  //                                                     "",
  //                                                     // _formatTimestamp(DateTime.now().second),
  //                                                     style: Theme.of(context)
  //                                                         .textTheme
  //                                                         .bodyMedium,
  //                                                   ),
  //                                                 ),
  //                                               ],
  //                                             ),
  //                                           );
  //                                         } else {
  //                                           final screenshotIndex =
  //                                               itemIndex - _images.length;
  //                                           final screenshot =
  //                                               locationProfileProvider
  //                                                       .locationProfile
  //                                                       ?.screenshots?[
  //                                                   screenshotIndex];
  //
  //                                           if (screenshot == null)
  //                                             return const SizedBox();
  //
  //                                           return Padding(
  //                                             padding:
  //                                                 const EdgeInsets.symmetric(
  //                                                     horizontal: 8.0),
  //                                             child: GestureDetector(
  //                                               onTap: () =>
  //                                                   _showImagePreviewFromUrl(
  //                                                       screenshot.imageUrl ??
  //                                                           ''),
  //                                               child: Column(
  //                                                 crossAxisAlignment:
  //                                                     CrossAxisAlignment.start,
  //                                                 children: [
  //                                                   Expanded(
  //                                                     child: Stack(
  //                                                       children: [
  //                                                         Center(
  //                                                           child: ClipRRect(
  //                                                             borderRadius:
  //                                                                 BorderRadius
  //                                                                     .circular(
  //                                                                         16),
  //                                                             child:
  //                                                                 Image.network(
  //                                                               screenshot
  //                                                                       .imageUrl ??
  //                                                                   '',
  //                                                               width: double
  //                                                                   .infinity,
  //                                                               height: double
  //                                                                   .infinity,
  //                                                               fit: BoxFit
  //                                                                   .cover,
  //                                                             ),
  //                                                           ),
  //                                                         ),
  //                                                         Positioned(
  //                                                           top: 8,
  //                                                           right: 8,
  //                                                           child: IconButton(
  //                                                             icon: Icon(
  //                                                                 Icons.delete,
  //                                                                 color: Colors
  //                                                                     .red),
  //                                                             onPressed: () {
  //                                                               print(screenshot
  //                                                                       .imageUrl ??
  //                                                                   '');
  //                                                               setState(() {
  //                                                                 locationProfileProvider
  //                                                                     .locationProfile
  //                                                                     ?.screenshots
  //                                                                     ?.removeAt(
  //                                                                         screenshotIndex);
  //                                                               });
  //                                                             },
  //                                                           ),
  //                                                         ),
  //                                                       ],
  //                                                     ),
  //                                                   ),
  //                                                   const SizedBox(height: 2),
  //                                                   Padding(
  //                                                     padding:
  //                                                         const EdgeInsets.only(
  //                                                             left: 10.0),
  //                                                     child: Text(
  //                                                       '${screenshot.name ?? ''} (@)',
  //                                                       style: Theme.of(context)
  //                                                           .textTheme
  //                                                           .bodyMedium,
  //                                                     ),
  //                                                   ),
  //                                                   Padding(
  //                                                     padding:
  //                                                         const EdgeInsets.only(
  //                                                             left: 10.0),
  //                                                     child: Text(
  //                                                       _formatTimestamp(
  //                                                           screenshot.createdAt
  //                                                               ?.iSeconds),
  //                                                       style: Theme.of(context)
  //                                                           .textTheme
  //                                                           .bodyMedium,
  //                                                     ),
  //                                                   ),
  //                                                 ],
  //                                               ),
  //                                             ),
  //                                           );
  //                                         }
  //                                       },
  //                                     ),
  //                                   ),
  //                                   SizedBox(height: 8),
  //                                 ],
  //                               ),
  //                             )
  //                           : Center(
  //                               child: Container(
  //                                   height:
  //                                       MediaQuery.of(context).size.height / 4,
  //                                   alignment: Alignment.center,
  //                                   child: Text('No Images',
  //                                       style: typography.Body1))),
  //                   Expanded(
  //                     flex: 1,
  //                     child: Container(
  //                       margin: EdgeInsets.symmetric(horizontal: 30),
  //                       child: CustomButton(
  //                         type: ButtonType.elevated,
  //                         onPressed: _pickImage,
  //                         child: Row(
  //                           mainAxisAlignment: MainAxisAlignment.center,
  //                           crossAxisAlignment: CrossAxisAlignment.center,
  //                           children: [
  //                             Icon(Icons.upload_sharp,
  //                                 color: Colors.black, size: 20),
  //                             SizedBox(width: 20),
  //                             InkWell(
  //                               onTap: _pickImage,
  //                               child: Text('Upload relevant image(s)',
  //                                   style: TextStyle(
  //                                       color: Colors.black, fontSize: 16)
  //                                   // typography.Body1
  //                                   ),
  //                             ),
  //                           ],
  //                         ),
  //                       ),
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //         ],
  //       );
  //     });
  //   });
  // }

  // Call this function to show the popup on tap
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
                          icon: Icon(Icons.edit,
                              color: Theme.of(context).colorScheme.primary),
                          onPressed: () {
                            _editName(locationProfileProvider);
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
                          'Address',
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
                                                        ?.locationProfile
                                                        ?.finalAddress
                                                        ?.locationIdForRef ??
                                                    "",
                                            searchQuery:
                                                widget.searchQuery ?? "",
                                            page: widget.page,
                                            totalPages: widget
                                                    .locationId.isNotEmpty
                                                ? (locationProfileProvider
                                                            .resetTotalPage! -
                                                        1)
                                                    .toString()
                                                : widget.totalPages!,
                                          ),
                                        ),
                                      );

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
                              height: 200,
                              child:
                                  Text('No Campus', style: typography.Body1)))
                      : Container(
                          height: 200,
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
                                  (subdestination?.rented ?? false) == true
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
                                          child: Image.network(
                                            screenshot?.imageUrl ?? '',
                                            fit: BoxFit.cover,
                                            width: 150,
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ),
                                SizedBox(height: 16),
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
                  SizedBox(height: 16),
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
      double latitude =
          locationProfileProvider.locationProfile?.location?.latitude ?? 0.0;
      double longitude =
          locationProfileProvider.locationProfile?.location?.longitude ?? 0.0;

      return locationProfileProvider.isLoading
          ? Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Container(
                  height: MediaQuery.of(context).size.height * 0.5,
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
                        child: GoogleMap(
                          key: ValueKey(
                              '${latitude}_${longitude}_${_currentMapType.name}'),
                          mapType: _currentMapType,
                          onCameraIdle: () {
                            _mapIsReady = true;
                          },
                          markers: Set<Marker>.of(markers.values),
                          zoomControlsEnabled: true,
                          initialCameraPosition: CameraPosition(
                            target: LatLng(latitude, longitude),
                            zoom: 18,
                          ),
                          onMapCreated: (GoogleMapController controller) {
                            _mapController = controller;
                          },
                          gestureRecognizers: <Factory<
                              OneSequenceGestureRecognizer>>{
                            Factory<OneSequenceGestureRecognizer>(
                                () => EagerGestureRecognizer()),
                          },
                          onTap: _isAddingMarker ? _handleMapTap : null,
                        ),
                      ),
                    ),
                  ),

                  // ClipRRect(
                  //   borderRadius: BorderRadius.circular(20),
                  //   child: Screenshot(
                  //     controller: _geocodingScreenshotController,
                  //     child: RepaintBoundary(
                  //       key: _mapKey,
                  //       child: GoogleMap(
                  //         // key: UniqueKey(),
                  //         mapType: _currentMapType,
                  //         onCameraIdle: () {
                  //           _mapIsReady = true;
                  //         },
                  //         markers: Set<Marker>.of(markers.values),
                  //         zoomControlsEnabled: true,
                  //         initialCameraPosition: CameraPosition(
                  //           target: LatLng(latitude, longitude),
                  //           zoom: 18,
                  //         ),
                  //         onMapCreated: (GoogleMapController controller) {
                  //           _mapController = controller;
                  //         },
                  //         gestureRecognizers: <Factory<
                  //             OneSequenceGestureRecognizer>>{
                  //           Factory<OneSequenceGestureRecognizer>(
                  //               () => EagerGestureRecognizer()),
                  //         },
                  //         onTap: _isAddingMarker ? _handleMapTap : null,
                  //       ),
                  //     ),
                  //   ),
                  // ),
                ),

                if ((int.tryParse(widget.page) ?? 1) > 1 &&
                    (widget.locationId.isNotEmpty
                            ? locationProfileProvider.resetTotalPage! - 1
                            : int.tryParse(widget.totalPages!) ?? 0) >
                        0)
                  Positioned(
                    left: 16,
                    top: 0,
                    bottom: 0,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FloatingActionButton(
                        shape: CircleBorder(),
                        mini: true,
                        backgroundColor:
                            Theme.of(context).brightness == Brightness.light
                                ? AppColors.paperElavation25Light
                                : AppColors.paperElavation25,
                        onPressed: _navigateLeft,
                        child: Icon(Icons.chevron_left, size: 30),
                      ),
                    ),
                  ),

                // Right navigation button
                if ((int.tryParse(widget.page) ?? 1) <
                    (widget.locationId.isNotEmpty
                        ? locationProfileProvider.resetTotalPage! - 1
                        : (int.tryParse(widget.totalPages!) ?? 1)))
                  Positioned(
                    right: 16,
                    top: 0,
                    bottom: 0,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: FloatingActionButton(
                        mini: true,
                        shape: CircleBorder(),
                        backgroundColor:
                            Theme.of(context).brightness == Brightness.light
                                ? AppColors.paperElavation25Light
                                : AppColors.paperElavation25,
                        onPressed: _isLoading ? null : _navigateRight,
                        child: Icon(Icons.chevron_right, size: 30),
                      ),
                    ),
                  ),

                // Floating Action Buttons (Map Type & Screenshot)
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
                            true)
                          FloatingActionButton.small(
                            elevation: 0,
                            backgroundColor:
                                Theme.of(context).colorScheme.brightness ==
                                        Brightness.light
                                    ? AppColors.paperElevation2Light
                                    : AppColors.paperElevation2,
                            onPressed: _handleSubDestinationTap,
                            child: Icon(Icons.add_location_alt,
                                color: Colors.white),
                            tooltip: 'Add Campus',
                          ),
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

  // Future<void> _captureAndUploadMapScreenshot() async {
  //   if (!_mapIsReady) {
  //     print('Map is not ready yet.');
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Please wait for the map to finish loading')),
  //     );
  //     return;
  //   }
  //
  //   try {
  //     final imageBytes = await _mapController?.takeSnapshot();
  //
  //     if (imageBytes != null) {
  //       final Directory tempDir = await getTemporaryDirectory();
  //       final String filePath =
  //           '${tempDir.path}/map_screenshot${Random().nextInt(10000000)}.png';
  //       final File file = File(filePath);
  //       await file.writeAsBytes(imageBytes);
  //
  //       setState(() {
  //         _images.add(file);
  //       });
  //
  //       var provider =
  //           Provider.of<MyLocationListProvider>(context, listen: false);
  //       await provider.uploadImage(
  //         context,
  //         filePath,
  //         widget.accountId,
  //         widget.subAccountId,
  //         widget.sovId,
  //         provider.locationProfile?.finalAddress?.locationId ?? "",
  //       );
  //
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Screenshot uploaded successfully')),
  //       );
  //     }
  //   } catch (e) {
  //     print('Error capturing map screenshot: $e');
  //   }
  // }

  Widget _riskScore() {
    var typography = CustomTypography(context);

    return Consumer<MyLocationListProvider>(
      builder: (context, locationProfileProvider, child) {
        double latitude =
            locationProfileProvider.locationProfile?.location.latitude ?? 0.0;
        double longitude =
            locationProfileProvider.locationProfile?.location.longitude ?? 0.0;

        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: Stack(
            children: [
              // ✅ Let the map fill the stack naturally
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Screenshot(
                  controller: _riskScoreScreenshotController,
                  child: GoogleMap(
                    mapType: MapType.normal,
                    zoomControlsEnabled: true,
                    markers: Set<Marker>.of(markers.values),
                    initialCameraPosition: CameraPosition(
                      target: LatLng(latitude, longitude),
                      zoom: 13,
                    ),
                    onMapCreated: (GoogleMapController controller) {
                      if (!_controller.isCompleted) {
                        _controller.complete(controller);
                      }
                    },
                    gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                      Factory<OneSequenceGestureRecognizer>(
                        () => EagerGestureRecognizer(),
                      ),
                    },
                    onTap: _isAddingMarker ? _handleMapTap : null,
                    tileOverlays: _getTileOverlays(),
                  ),
                ),
              ),

              Positioned(
                top: 40,
                bottom: 50,
                left: 0,
                child: _buildHazardControls(),
              ),

              if ((int.tryParse(widget.page) ?? 1) > 1)
                Positioned(
                  left: 16,
                  child: _buildNavigationButton(
                    alignment: Alignment.centerLeft,
                    icon: Icons.chevron_left,
                    onPressed: _navigateLeft,
                  ),
                ),

              if ((int.tryParse(widget.page) ?? 1) <
                  (widget.locationId.isNotEmpty
                      ? locationProfileProvider.resetTotalPage! - 1
                      : (int.tryParse(widget.totalPages!) ?? 1)))
                Positioned(
                  right: 16,
                  child: _buildNavigationButton(
                    alignment: Alignment.centerRight,
                    icon: Icons.chevron_right,
                    onPressed: _navigateRight,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // Widget _riskScore() {
  //   var typography = CustomTypography(context);
  //
  //   return Consumer<MyLocationListProvider>(
  //     builder: (context, locationProfileProvider, child) {
  //       // Ensure safe latitude and longitude values
  //       double latitude =
  //           locationProfileProvider.locationProfile?.location.latitude ?? 0.0;
  //       double longitude =
  //           locationProfileProvider.locationProfile?.location.longitude ?? 0.0;
  //       return Stack(
  //         children: [
  //           // Google Map
  //           Positioned.fill(
  //             child: ClipRRect(
  //               borderRadius: BorderRadius.circular(20),
  //               child: Screenshot(
  //                 controller: _riskScoreScreenshotController,
  //                 child: GoogleMap(
  //                   mapType: MapType.normal,
  //                   zoomControlsEnabled: true,
  //                   markers: Set<Marker>.of(markers.values),
  //                   initialCameraPosition: CameraPosition(
  //                     target: LatLng(latitude, longitude),
  //                     zoom: 13,
  //                   ),
  //                   onMapCreated: (GoogleMapController controller) {
  //                     if (!_controller.isCompleted) {
  //                       _controller.complete(controller);
  //                     }
  //                   },
  //                   gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
  //                     Factory<OneSequenceGestureRecognizer>(
  //                           () => EagerGestureRecognizer(),
  //                     ),
  //                   },
  //                   onTap: _isAddingMarker ? _handleMapTap : null,
  //                   tileOverlays: _getTileOverlays(),
  //                 ),
  //               ),
  //             ),
  //           ),
  //
  //           // Hazard Controls
  //           Positioned(
  //             bottom: 0,
  //             left: 0,
  //             child: _buildHazardControls(),
  //           ),
  //
  //           // Left Navigation Button
  //           if ((int.tryParse(widget.page) ?? 1) > 1)
  //             Positioned(
  //               left: 16,
  //               child: _buildNavigationButton(
  //                 alignment: Alignment.centerLeft,
  //                 icon: Icons.chevron_left,
  //                 onPressed: _navigateLeft,
  //               ),
  //             ),
  //
  //           // Right Navigation Button
  //           if ((int.tryParse(widget.page) ?? 1) <
  //               (widget.locationId.isNotEmpty
  //                   ? locationProfileProvider.resetTotalPage! - 1
  //                   : (int.tryParse(widget.totalPages!) ?? 1)))
  //             Positioned(
  //               right: 16,
  //               child: _buildNavigationButton(
  //                 alignment: Alignment.centerRight,
  //                 icon: Icons.chevron_right,
  //                 onPressed: _navigateRight,
  //               ),
  //             ),
  //         ],
  //       );
  //       //   Stack(
  //       //   children: [
  //       //     // Google Map
  //       //     Positioned.fill(
  //       //       child: ClipRRect(
  //       //         borderRadius: BorderRadius.circular(20),
  //       //         child: Screenshot(
  //       //           controller: _riskScoreScreenshotController,
  //       //           child: GoogleMap(
  //       //             // key: _googleMapKey,
  //       //             mapType: MapType.normal,
  //       //             // mapType: _currentMapType1,
  //       //             zoomControlsEnabled: true,
  //       //             markers: Set<Marker>.of(markers.values),
  //       //             initialCameraPosition: CameraPosition(
  //       //               target: LatLng(latitude, longitude),
  //       //               zoom: 13,
  //       //             ),
  //       //             onMapCreated: (GoogleMapController controller) {
  //       //               if (!_controller.isCompleted) {
  //       //                 _controller.complete(controller);
  //       //               }
  //       //             },
  //       //             gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
  //       //               Factory<OneSequenceGestureRecognizer>(
  //       //                 () => EagerGestureRecognizer(), // Allows button taps
  //       //               ),
  //       //             },
  //       //             onTap: _isAddingMarker ? _handleMapTap : null,
  //       //             tileOverlays: _getTileOverlays(),
  //       //           ),
  //       //         ),
  //       //       ),
  //       //     ),
  //       //
  //       //     // Hazard Controls (Bottom)
  //       //     Positioned(
  //       //       bottom: 0,
  //       //       left: 0,
  //       //       child: _buildHazardControls(),
  //       //     ),
  //       //
  //       //     // Map Type Selector (Top Right)
  //       //     // Positioned(
  //       //     //   top: 16,
  //       //     //   right: 16,
  //       //     //   child: _buildMapTypeSelector(),
  //       //     // ),
  //       //
  //       //     // Left Navigation Button
  //       //     if ((int.tryParse(widget.page) ?? 1) > 1)
  //       //       _buildNavigationButton(
  //       //         alignment: Alignment.centerLeft,
  //       //         left: 16,
  //       //         icon: Icons.chevron_left,
  //       //         onPressed: _navigateLeft,
  //       //       ),
  //       //
  //       //     // Right Navigation Button
  //       //     if ((int.tryParse(widget.page) ?? 1) <
  //       //         (widget.locationId.isNotEmpty
  //       //             ? locationProfileProvider.resetTotalPage! - 1
  //       //             : (int.tryParse(widget.totalPages!) ?? 1)))
  //       //       _buildNavigationButton(
  //       //         alignment: Alignment.centerRight,
  //       //         right: 16,
  //       //         icon: Icons.chevron_right,
  //       //         onPressed: _navigateRight,
  //       //       ),
  //       //   ],
  //       // );
  //     },
  //   );
  // }

  /// Returns tile overlays with safe null checks
  Set<TileOverlay> _getTileOverlays() {
    if (0 == 1) return {}; // No overlays if this condition is met

    if (_selectedHazard != null &&
        _tileProviders.containsKey(_selectedHazard) &&
        _mainHazardTileProvider != null &&
        selectedHazardId != null &&
        selectedVendor != null) {
      return {
        TileOverlay(
          tileOverlayId: TileOverlayId(selectedHazardId!),
          tileProvider: _mainHazardTileProvider!,
        ),
        TileOverlay(
          tileOverlayId: TileOverlayId(_selectedHazard!),
          tileProvider: _tileProviders[_selectedHazard!]!,
        ),
      };
    }

    if (_mainHazardTileProvider != null &&
        selectedHazardId != null &&
        selectedVendor != null) {
      return {
        TileOverlay(
          tileOverlayId: TileOverlayId(selectedHazardId!),
          tileProvider: _mainHazardTileProvider!,
        ),
      };
    }
    return {};
  }

  Widget _buildNavigationButton({
    Alignment alignment = Alignment.center,
    double? left,
    double? right,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Positioned(
      left: left,
      right: right,
      top: 0,
      bottom: 0,
      child: Align(
        alignment: alignment,
        child: FloatingActionButton(
          shape: CircleBorder(),
          mini: true,
          backgroundColor: Theme.of(context).brightness == Brightness.light
              ? AppColors.paperElavation25Light
              : AppColors.paperElavation25,
          onPressed: onPressed,
          child: Icon(icon, size: 30),
        ),
      ),
    );
  }

  Widget _buildHazardControls() {
    var typography = CustomTypography(context);

    // Show loading spinner if the main hazards are loading
    if (isLoadingMainHazards) {
      return Positioned(
        bottom: 33,
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
      if (!(2 == 2 || 1 == 1) || mainHazards.isEmpty) {
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

  Widget _buildMapTypeSelector() {
    return Container(
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
      child: PopupMenuButton<MapType>(
        onSelected: (MapType selectedType) {
          setState(() {
            _currentMapType1 = selectedType;
          });
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<MapType>>[
          PopupMenuItem<MapType>(
            value: MapType.normal,
            child: Text('Map'),
          ),
          PopupMenuItem<MapType>(
            value: MapType.satellite,
            child: Text('Satellite'),
          ),
          PopupMenuItem<MapType>(
            value: MapType.terrain,
            child: Text('Terrain'),
          ),
        ],
        child: Material(
          elevation: 0,
          color: Theme.of(context).colorScheme.brightness == Brightness.light
              ? AppColors.paperElevation2Light
              : AppColors.paperElevation2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getMapTypeLabel(_currentMapType1),
                  style: TextStyle(color: Colors.grey),
                ),
                SizedBox(width: 4),
                Icon(Icons.arrow_drop_down, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getMapTypeLabel(MapType mapType) {
    switch (mapType) {
      case MapType.normal:
        return 'Map';
      case MapType.satellite:
        return 'Satellite';
      case MapType.terrain:
        return 'Terrain';
      default:
        return 'Map';
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

  Future<void> _goToTheInitialPin() async {
    final GoogleMapController? controller =
        await _controller.future.catchError((error) {
      print('Error initializing Google Map Controller: $error');
      return null;
    });

    if (controller != null) {
      var provider =
          Provider.of<MyLocationListProvider>(context, listen: false);
      var mainMarkerPosition = CameraPosition(
        target: LatLng(
          provider.locationProfile?.finalAddress?.latitude ?? 0,
          provider.locationProfile?.finalAddress?.longitude ?? 0,
        ),
        zoom: 16,
      );
      await controller
          .animateCamera(CameraUpdate.newCameraPosition(mainMarkerPosition));
    } else {
      print('Google Map Controller is null');
    }
  }

  void _onMarkerTapped(MarkerId markerId) async {
    print('Marker tapped: $markerId');
    var provider = Provider.of<MyLocationListProvider>(context, listen: false);

    if (markerId.value == provider.locationProfile?.finalAddress?.locationId) {
      // Show loading dialog while fetching data
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return Center(child: CircularProgressIndicator());
        },
      );
      // Call API to fetch main location details
      await provider.fetchIndividualLocationProfile(
          context, provider.locationProfile?.finalAddress?.locationId ?? '');

      // Close loading dialog
      Navigator.pop(context);

      showLocationDetailsPopup(context, provider.selectedLocation!, true);
    } else {
      print(
          'Subdestinations: ${provider.locationProfile?.subdestinations?.length}');
      provider.locationProfile?.subdestinations?.forEach((element) {
        print('Subdestination ID: ${element.id}');
      });

      var subdestination =
          provider.locationProfile?.subdestinations?.firstWhereOrNull(
        (element) => element.id == markerId.value,
      );
      print('Subdestination tapped: ${subdestination?.name}');

      if (subdestination != null) {
        bool isAdded = (subdestination.status ?? "").toLowerCase() == "added";
        print('Subdestination tapped: ${subdestination.name}');
        print('Subdestination status: ${subdestination.status}');

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
        // If no subdestination is found, handle the main location
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
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Campus created Successfully')),
                );
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
                title: Text('Create Campus', style: typography.H6),
                content: Container(
                  width: double.maxFinite, // Ensure dialog takes full width
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Do you want to get campus for this location?',
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
                            'Cancel',
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
                            'Add',
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
            title: Text('Edit Name', style: typography.H6),
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
                child: Text('Cancel', style: typography.Body1),
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
                    : Text('Save', style: typography.Body1),
              ),
            ],
          );
        });
      },
    );
  }

  void _editAddress(MyLocationListProvider provider) {
    var typography = CustomTypography(context);
    _addressController.text =
        provider.locationProfile?.finalAddress?.address ?? '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Consumer<MyLocationListProvider>(
            builder: (context, locationProfileProvider, child) {
          return AlertDialog(
            title: Text('Edit address & run geocoding',
                style: typography.H6.copyWith(height: 1.2)),
            content: TextField(
              controller: _addressController,
              decoration: InputDecoration(
                hintText: 'Enter the new address',
                border: OutlineInputBorder(),
              ),
              style: typography.Body1,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Cancel', style: typography.Body1),
              ),
              TextButton(
                onPressed: () {
                  locationProfileProvider
                      .updateLocationAddress(
                    context,
                    widget.accountId,
                    widget.subAccountId,
                    widget.sovId,
                    locationProfileProvider
                            .locationProfile?.finalAddress?.locationId ??
                        '',
                    _addressController.text,
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

  Widget _buildSubdestinationCard(
      Subdestination subdestination, bool isAdded, Function() onAddToSOV) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        title: Text(subdestination.name ?? ''),
        subtitle: Text(subdestination.address ?? ''),
        trailing: ElevatedButton(
          onPressed: onAddToSOV,
          style: ElevatedButton.styleFrom(
            backgroundColor: isAdded ? Colors.green : Colors.blue,
          ),
          child: Text(isAdded ? 'Added' : 'Add to SOV'),
        ),
      ),
    );
  }

  Widget _mainMarkerInfoWindow(String title, String address) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Text(
            address,
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
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
    print('User ID: ${user?.uid}');
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

    // ✅ Instead of _getData(), manually update the local model
    final updatedSub = provider.locationProfile?.subdestinations?.firstWhere(
      (sub) => sub.id == subdestinationId,
    );

    if (updatedSub != null) {
      updatedSub.status = 'added';
      provider.notifyListeners(); // 🔔 Trigger UI update
    }
    //     .then((value) {
    //   _getData();
    // });
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
      return '${number}th';
    }

    switch (number % 10) {
      case 1:
        return '${number}st';
      case 2:
        return '${number}nd';
      case 3:
        return '${number}rd';
      default:
        return '${number}th';
    }
  }

  String formatLocationText(int location, int total) {
    if (total == 0) {
      return '';
    }
    if (widget.locationId.isNotEmpty) {
      return '';
    }
    return ' - (${getOrdinal(location)} Location of $_totalPages)';
  }
}
