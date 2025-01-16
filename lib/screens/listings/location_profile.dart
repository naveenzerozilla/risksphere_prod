import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:collection/collection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:green/constants/enums.dart';
import 'package:green/design_system/components/rating_widget.dart';
import 'package:green/design_system/primitives/app_colors.dart';
import 'package:green/design_system/primitives/custom_typography.dart';
import 'package:green/design_system/primitives/utilities/custom_spacing.dart';
import 'package:green/models/account_list_model.dart';
import 'package:green/providers/location_profile_provider.dart';
import 'package:green/providers/place_api_provider.dart';
import 'package:green/providers/user_profile_provider.dart';
import 'package:green/screens/listings/add_location_screen.dart';
import 'package:green/screens/listings/widgets/dots_indicator.dart';
import 'package:green/screens/listings/widgets/export_dialog.dart';
import 'package:green/screens/listings/widgets/location_details_popup.dart';
import 'package:green/screens/listings/widgets/message_card.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';

import '../../design_system/components/custom_button.dart';
import '../../design_system/components/rating_slider.dart';
import '../../models/location_profile_model.dart';
import '../../models/my_location_list_model.dart';
import '../../providers/my_location_list_provider.dart';
import '../../providers/theme_provider.dart';
import '../../design_system/components/custom_appbar.dart';
import '../../design_system/components/custom_drawer.dart';

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
  });

  final String accountId;
  final String accountName;
  final String subAccountId;
  final String subAccountName;
  final String sovId;
  final String sovName;
  final String page;
  final String totalPages;
  final String searchQuery;
  final String locationId;
  final bool reset;

  @override
  State<LocationProfile> createState() => _LocationProfileState();
}

class _LocationProfileState extends State<LocationProfile>
    with SingleTickerProviderStateMixin {
  // App Bar
  bool _isExpanded = false;
  bool _showNotificationDot = true;

  // Google Maps
  UniqueKey _googleMapKey = UniqueKey();
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};
  ScreenshotController screenshotController = ScreenshotController();

  bool _isAddingMarker = false;
  bool _isTaggingSubDestination = false;

  TabController? _tabController;
  TextEditingController _nameController = TextEditingController();
  TextEditingController _addressController = TextEditingController();
  TextEditingController _campusIdController = TextEditingController();
  TextEditingController searchController = TextEditingController();
  List<Suggestion> _searchLocations = [];
  List<File> _images = [];

  String autoCompleteSuggestionSessionToken = Uuid().v4();

  MapType _currentMapType = MapType.normal;
  bool _isBottomSheetExpanded = false;
  bool _isBottomSheetFullScreen = false;

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(40.32434, -111.889),
    zoom: 16,
  );

  MarkerId? _selectedMarker;

  late TextEditingController _searchController;

  ScrollController _scrollController = ScrollController();

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Update the key to force a rebuild of the Google Map widget
    setState(() {
      _googleMapKey = UniqueKey();
    });
  }

  @override
  void initState() {
    _searchController = TextEditingController();
    _getData();
    _tabController = TabController(length: 4, vsync: this);
    super.initState();
  }

  Future<void> _getData() async {
    // Make API call to get the data
    await Provider.of<MyLocationListProvider>(context, listen: false)
        .fetchLocationListProfile(
      context,
      "",
      int.parse(widget.page),
      int.parse(widget.totalPages),
      widget.accountId,
      widget.subAccountId,
      widget.sovId,
      widget.locationId,
    );

    _addSubdestinationMarkers();
    _add();
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
    var provider = Provider.of<MyLocationListProvider>(context, listen: false);
    Map<MarkerId, Marker> newMarkers = {}; // Temporary map to hold markers

    for (var subdestination
        in provider.locationProfile?.subdestinations ?? []) {
      var markerId = MarkerId(subdestination.id!);
      var isAdded = (subdestination.status ?? "").toLowerCase() == "added";
      var marker = Marker(
        zIndex: isAdded ? 5 : 0,
        markerId: markerId,
        position: LatLng(subdestination.lat!, subdestination.lng!),
        icon: BitmapDescriptor.defaultMarkerWithHue(
            isAdded ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueAzure),
        onTap: () {
          _onMarkerTapped(markerId);
        },
      );

      newMarkers[markerId] = marker; // Add marker to the temporary map
    }

    setState(() {
      markers =
          newMarkers; // Set all markers at once to avoid unnecessary rebuilds
    });

    _add();
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

  Future<void> _captureAndUploadMapScreenshot() async {
    var typography = CustomTypography(context);
    // Request storage permission
    // Log initial permission status
    PermissionStatus initialStatus =
        await Permission.manageExternalStorage.status;
    print('Initial permission status: $initialStatus');

    // Request storage permission
    PermissionStatus status = await Permission.manageExternalStorage.request();
    print('After request, permission status: $status');

    if (status.isGranted) {
      Uint8List? screenshot = await screenshotController.capture();
      if (screenshot != null) {
        final Directory tempDir = await getTemporaryDirectory();
        final String filePath =
            '${tempDir.path}/map_screenshot${Random().nextInt(10000000)}.png';
        final File file = File(filePath);
        await file.writeAsBytes(screenshot);

        setState(() {
          _images.add(file);
        });

        var provider =
            Provider.of<MyLocationListProvider>(context, listen: false);
        await provider.uploadImage(
            context,
            filePath,
            widget.accountId,
            widget.subAccountId,
            widget.sovId,
            provider.locationProfile?.finalAddress!.locationId ?? "");
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Failed to capture screenshot', style: typography.Body1),
          ),
        );
      }
    } else if (status.isDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Storage permission denied', style: typography.Body1),
        ),
      );
    } else if (status.isPermanentlyDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Storage permission permanently denied',
              style: typography.Body1),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: () {
              openAppSettings();
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    var typography = CustomTypography(context);
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
            body: locationProfileProvider.isLoading
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                        ],
                      ),
                    ],
                  )
                : Stack(
                    children: [
                      Column(
                        children: [
                          /*Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color:
                            Theme.of(context).colorScheme.surfaceContainerHigh,
                        borderRadius:
                            BorderRadius.circular(16), // Rounded edges
                      ),
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                      child: DefaultTabController(
                        length: 4,
                        child: Column(
                          children: <Widget>[
                            // Container for the TabBar with arrows
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHigh,
                              ),
                              height: 50,
                              child: Row(
                                children: <Widget>[
                                  // Left arrow button
                                  IconButton(
                                    icon: Icon(Icons.arrow_left,
                                        color: Colors.grey),
                                    onPressed: _scrollLeft,
                                  ),
                                  // Scrollable TabBar
                                  Expanded(
                                    child: SingleChildScrollView(
                                      controller: _scrollController,
                                      scrollDirection: Axis.horizontal,
                                      child: TabBar(
                                        tabAlignment: TabAlignment.start,
                                        labelStyle: typography.Subtitle2,
                                        isScrollable: true,
                                        indicatorColor: Colors.lightBlueAccent,
                                        labelColor: Colors.lightBlueAccent,
                                        unselectedLabelColor: Colors.grey,
                                        tabs: [
                                          Tab(
                                            text: 'Overall Score',
                                          ),
                                          Tab(text: 'Geocoding Score'),
                                          Tab(text: 'Risk Score'),
                                          Tab(text: 'Hazard Score'),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Right arrow button
                                  IconButton(
                                    icon: Icon(Icons.arrow_right,
                                        color: Colors.grey),
                                    onPressed: _scrollRight,
                                  ),
                                ],
                              ),
                            ),

                            // TabBarView for the tab content
                      Expanded(
                        child: TabBarView(
                          children: [
                            Center(child: Text('Overall Score Content')),
                            Center(child: Text('Geocoding Score Content')),
                            Center(child: Text('Risk Content')),
                            Center(child: Text('Contruction Content')),
                          ],
                        ),
                      ),
                          ],
                        ),
                      ),
                    ),*/
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Left Column
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                SizedBox(
                                                    height: CustomSpacing.two),
                                                Text(
                                                  locationProfileProvider
                                                          .locationProfile
                                                          ?.finalAddress
                                                          ?.locationName ??
                                                      '',
                                                  style: typography.H6
                                                      .copyWith(height: 1.2),
                                                  overflow: TextOverflow
                                                      .ellipsis, // Handle overflow
                                                ),
                                                Text(
                                                  '${locationProfileProvider.locationProfile?.finalAddress?.locationIdForRef ?? ''}',
                                                  style: typography.Subtitle2
                                                      .copyWith(
                                                    fontWeight: FontWeight.w500,
                                                    color:
                                                        AppColors.primaryMain,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            splashRadius: 1,
                                            padding: EdgeInsets.zero,
                                            icon: Icon(Icons.edit,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary),
                                            onPressed: () {
                                              _editName(
                                                  locationProfileProvider);
                                            },
                                            constraints:
                                                BoxConstraints(), // Minimal icon space
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
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        /*    Icon(Icons.share),
                                    SizedBox(width: CustomSpacing.six),*/
                                        TooltipTheme(
                                          data: TooltipThemeData(
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .surface,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            textStyle: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface,
                                              fontSize: 14,
                                            ),
                                            padding: EdgeInsets.all(8),
                                            verticalOffset: 20,
                                            preferBelow: false,
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                                right: 12.0),
                                            child: Tooltip(
                                              showDuration:
                                                  Duration(seconds: 5),
                                              triggerMode:
                                                  TooltipTriggerMode.tap,
                                              preferBelow: true,
                                              richMessage: TextSpan(
                                                children: [
                                                  TextSpan(
                                                    text:
                                                        'Geocode Type: ${locationProfileProvider.locationProfile?.finalAddress?.locationType ?? 'Unknown'}\n',
                                                    style: typography.Subtitle1,
                                                  ),
                                                  TextSpan(
                                                    text:
                                                        'Property Type: ${locationProfileProvider.locationProfile?.finalAddress?.placeTypes?.join(', ') ?? 'Unknown'}\n',
                                                    style: typography.Subtitle1,
                                                  ),
                                                  TextSpan(
                                                    text:
                                                        '${locationProfileProvider.locationProfile?.finalAddress?.description ?? ""}\n',
                                                    style: typography.Subtitle1,
                                                  ),
                                                ],
                                                style: typography.Subtitle1,
                                              ),
                                              child: Icon(Icons.info),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          /*ListTile(

                        title: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
      */
                          SizedBox(
                            height: CustomSpacing.two,
                          ),
                          /*                          Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    locationProfileProvider.result?.locationName ??
                                        '',
                                    style:
                                    typography.H6.copyWith(height: 1.2),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.edit,
                                      color: Theme.of(context).colorScheme.primary),
                                  onPressed: () {
                                    // Handle edit button press
                                    _editName(locationProfileProvider);
                                  },
                                ),
                              ],
                            ),
                            Text(
                              '${locationProfileProvider.result?.locationIdForRef ?? ''}',
                              style: typography.Subtitle1.copyWith(
                                  fontWeight: FontWeight.w500, color: AppColors.primaryMain),
                            )*/ /*
                          ],
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                        trailing:
                      ),
                      */
                          Padding(
                            padding: EdgeInsets.only(left: 16, right: 24),
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
                                (locationProfileProvider.locationProfile
                                                ?.finalAddress?.score ??
                                            0) ==
                                        5
                                    ? SvgPicture.asset(
                                        'assets/images/certified.svg')
                                    : SizedBox.shrink(),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Stack(
                              children: [
                                Container(
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
                                      controller: screenshotController,
                                      child: GoogleMap(
                                        key: _googleMapKey,
                                        mapType: _currentMapType,
                                        markers: Set<Marker>.of(markers.values),
                                        initialCameraPosition: _kGooglePlex,
                                        onMapCreated:
                                            (GoogleMapController controller) {
                                          if (!_controller.isCompleted) {
                                            _controller.complete(controller);
                                          }
                                        },
                                        gestureRecognizers: <Factory<
                                            OneSequenceGestureRecognizer>>{
                                          Factory<OneSequenceGestureRecognizer>(
                                            () => EagerGestureRecognizer(),
                                          ),
                                        },
                                        onTap: _isAddingMarker
                                            ? _handleMapTap
                                            : null,
                                      ),
                                    ),
                                  ),
                                ),
                                /*Consumer<MyLocationListProvider>(
                                builder: (context, locationProfileProvider, child) {
                              return Positioned(
                                top: 16,
                                left: 28,
                                right: 0,
                                child: (locationProfileProvider.locationProfile?.finalAddress?.score ?? 0) ==
                                            3 ||
                                        (locationProfileProvider.locationProfile?.finalAddress?.score ??
                                                0) ==
                                            4
                                    ? Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Expanded(
                                              child: _buildGoogleSearchBar(context)),
                                        ],
                                      )
                                    : SizedBox(),
                              );
                            }),*/
                                // Left navigation button
                                Consumer<MyLocationListProvider>(builder:
                                    (context, locationProfileProvider, child) {
                                  return ((int.tryParse(widget.page) ??
                                                  1) <=
                                              1 ||
                                          (widget
                                                      .locationId.isNotEmpty
                                                  ? locationProfileProvider
                                                          .resetTotalPage -
                                                      1
                                                  : int.tryParse(
                                                      widget.totalPages)) ==
                                              0)
                                      ? SizedBox.shrink()
                                      : Positioned(
                                          left: 16,
                                          top: 0,
                                          bottom: 0,
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: FloatingActionButton(
                                              shape: CircleBorder(),
                                              mini: true,
                                              backgroundColor: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.light
                                                  ? AppColors
                                                      .paperElavation25Light
                                                  : AppColors.paperElavation25,
                                              onPressed: _navigateLeft,
                                              child: Icon(
                                                Icons.chevron_left,
                                                size: 30,
                                              ),
                                            ),
                                          ),
                                        );
                                }),
                                // Right navigation button
                                ((int.tryParse(widget.page) ?? 1) >=
                                            (widget.locationId.isNotEmpty
                                                ? locationProfileProvider
                                                        .resetTotalPage -
                                                    1
                                                : (int.tryParse(
                                                        widget.totalPages) ??
                                                    1)) ||
                                        (widget.locationId.isNotEmpty
                                                ? locationProfileProvider
                                                        .resetTotalPage -
                                                    1
                                                : int.tryParse(
                                                    widget.totalPages)) ==
                                            0)
                                    ? SizedBox.shrink()
                                    : Positioned(
                                        right: 16,
                                        top: 0,
                                        bottom: 0,
                                        child: Align(
                                          alignment: Alignment.centerRight,
                                          child: FloatingActionButton(
                                            mini: true,
                                            shape: CircleBorder(),
                                            backgroundColor: Theme.of(context)
                                                        .brightness ==
                                                    Brightness.light
                                                ? AppColors
                                                    .paperElavation25Light
                                                : AppColors.paperElavation25,
                                            onPressed: _navigateRight,
                                            child: Icon(
                                              Icons.chevron_right,
                                              size: 30,
                                            ),
                                          ),
                                        ),
                                      ),
                                /*
                          Autocomplete
                          Consumer<MyLocationListProvider>(
                                builder: (context, locationProfileProvider, child) {
                              return Positioned(
                                top: 16,
                                left: 28,
                                right: 0,
                                child: (locationProfileProvider.locationProfile?.finalAddress?.score ?? 0) ==
                                            3 ||
                                        (locationProfileProvider.locationProfile?.finalAddress?.score ??
                                                0) ==
                                            4
                                    ? Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Expanded(
                                              child: _buildGoogleSearchBar(context)),
                                        ],
                                      )
                                    : SizedBox(),
                              );
                            }),*/
                                Consumer<MyLocationListProvider>(builder:
                                    (context, locationProfileProvider, child) {
                                  print(
                                      'Subdestinations: ${locationProfileProvider.locationProfile?.subdestinations}');
                                  print('Show icon: ${(locationProfileProvider.locationProfile?.finalAddress?.score ?? 0) == 5} && ${([
                                        locationProfileProvider.locationProfile
                                            ?.finalAddress?.locationType!
                                      ].any((placeType) => [
                                            "premise",
                                            "subpremise",
                                            "rooftop"
                                          ].contains(placeType?.toLowerCase())) ?? false)}, place types are: ${locationProfileProvider.locationProfile?.finalAddress?.placeTypes}');
                                  return Positioned(
                                    bottom: 16,
                                    left: 16,
                                    child: Container(
                                      margin: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                                    .colorScheme
                                                    .brightness ==
                                                Brightness.light
                                            ? AppColors.paperElevation2Light
                                            : AppColors.paperElevation2,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.1),
                                            blurRadius: 10,
                                            offset: Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          FloatingActionButton.small(
                                            elevation: 0,
                                            onPressed:
                                                _captureAndUploadMapScreenshot,
                                            backgroundColor: Theme.of(context)
                                                        .colorScheme
                                                        .brightness ==
                                                    Brightness.light
                                                ? AppColors.paperElevation2Light
                                                : AppColors.paperElevation2,
                                            child: Icon(Icons.camera,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface),
                                            tooltip:
                                                'Capture and Upload Screenshot',
                                          ),
                                          SizedBox(height: 8),
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
                                                _currentMapType =
                                                    _currentMapType ==
                                                            MapType.normal
                                                        ? MapType.satellite
                                                        : MapType.normal;
                                              });
                                            },
                                            child: Icon(Icons.map,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface),
                                            tooltip: 'Change Map Type',
                                          ),
                                          SizedBox(height: 8),
                                          FloatingActionButton.small(
                                            elevation: 0,
                                            backgroundColor: Theme.of(context)
                                                        .colorScheme
                                                        .brightness ==
                                                    Brightness.light
                                                ? AppColors.paperElevation2Light
                                                : AppColors.paperElevation2,
                                            onPressed: _goToTheInitialPin,
                                            child: Icon(Icons.pin_drop,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface),
                                            tooltip: 'Go to Initial Pin',
                                          ),
                                          (locationProfileProvider
                                                              .locationProfile
                                                              ?.finalAddress
                                                              ?.score ??
                                                          0) ==
                                                      5 &&
                                                  (locationProfileProvider
                                                          .locationProfile
                                                          ?.finalAddress
                                                          ?.placeTypes
                                                          ?.any((placeType) => [
                                                                "premise",
                                                                "subpremise",
                                                                "rooftop",
                                                              ].contains(placeType
                                                                  .toLowerCase())) ??
                                                      false)
                                              ? FloatingActionButton.small(
                                                  elevation: 0,
                                                  backgroundColor: Theme.of(
                                                                  context)
                                                              .colorScheme
                                                              .brightness ==
                                                          Brightness.light
                                                      ? AppColors
                                                          .paperElevation2Light
                                                      : AppColors
                                                          .paperElevation2,
                                                  onPressed:
                                                      _handleSubDestinationTap,
                                                  child: Icon(
                                                      Icons.add_location_alt,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSurface),
                                                  tooltip: 'Add Campus',
                                                )
                                              : SizedBox.shrink(),
                                          /*
                                      Add Marker
                                      (locationProfileProvider.locationProfile?.finalAddress?.score ?? 0) ==
                                                  1 ||
                                              (locationProfileProvider
                                                          .locationProfile?.finalAddress?.score ??
                                                      0) ==
                                                  2
                                          ? FloatingActionButton.small(
                                        elevation: 0,
                                              backgroundColor:
                                              Theme.of(context).colorScheme.brightness ==
                                                  Brightness.light
                                                  ? AppColors.paperElevation2Light
                                                  : AppColors.paperElevation2,
                                              onPressed: _toggleAddMarkerMode,
                                              child: _isAddingMarker
                                                  ? const Icon(Icons.cancel)
                                                  : const Icon(Icons.add_location),
                                              tooltip: 'Add Marker',
                                            )
                                          : SizedBox.shrink(),*/
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                          if (!_isBottomSheetFullScreen) _buildBottomSheet(),
                        ],
                      ),
                      if (_isBottomSheetFullScreen)
                        Positioned.fill(
                          child: _locationProfileBody(),
                        ),
                      /*Consumer<LocationProfileProvider>(
                    builder: (context, provider, child) {
                      return provider.isUploadingImage ? Center(child: CircularProgressIndicator()) : SizedBox.shrink();
                    },
                  ),*/
                      if (_selectedMarker != null) _buildCustomInfoWindow(),
                    ],
                  ),
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
    return Consumer<MyLocationListProvider>(
        builder: (context, locationProfileProvider, child) {
      return AnimatedContainer(
        duration: Duration(milliseconds: 300),
        height: _isBottomSheetExpanded
            ? MediaQuery.of(context).size.height * 0.3
            : MediaQuery.of(context).size.height * 0.14,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.light
              ? AppColors.paperElavation25Light
              : AppColors.paperElavation25,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                ListTile(
                  title: Text(
                    '${widget.accountName}/${widget.subAccountName}-${widget.sovName}/${locationProfileProvider.locationProfile?.finalAddress?.locationIdForRef ?? ''}${formatLocationText((int.tryParse(widget.page) ?? 1) + 0, (int.tryParse(widget.totalPages) ?? 1))}',
                    style: typography.Subtitle1.copyWith(
                        fontWeight: FontWeight.w500),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  trailing: IconButton(
                    icon: Icon(_isBottomSheetExpanded
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_up),
                    onPressed: () {
                      setState(() {
                        _isBottomSheetExpanded = !_isBottomSheetExpanded;
                      });
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
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(context).colorScheme.onSurface,
                                width: 1,
                              ),
                            ),
                            child: IconButton(
                              icon: Icon(Icons.fullscreen),
                              onPressed: () {
                                setState(() {
                                  _isBottomSheetFullScreen = true;
                                });
                              },
                            ),
                          ),
                        ),
                      ),
              ],
            ),
            if (_isBottomSheetExpanded)
              Expanded(
                child: Scrollbar(
                  thumbVisibility: true,
                  child: ListView(
                    children: [
                      Divider(),
                      /*ListTile(
                        title: Text(
                          locationProfileProvider.locationProfile?.finalAddress?.address ?? '',
                          style: typography.Body1,
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                        trailing: IconButton(
                          icon: Icon(Icons.edit,
                              color: Theme.of(context).colorScheme.primary),
                          onPressed: () =>
                              _editAddress(locationProfileProvider),
                        ),
                      ),*/

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
                                IconButton(
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
                                ),
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
                                          Provider.of<UserProfileProvider>(context, listen: false);
                                          final trialStatus = userProfileProvider.trialInfo['status'] ?? '';
                                          final trialSubdestinations =
                                              userProfileProvider.trialInfo['subDestinations'] ?? 0;
                                          if (trialStatus != '' && trialSubdestinations < 1) {
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return MessageCard(
                                                  messageTextSpans: [
                                                    TextSpan(
                                                      text: 'You\'ve reached your limit for ',
                                                      style: CustomTypography(context).Body1,
                                                    ),
                                                    TextSpan(
                                                      text: '“editing locations”',
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
                                            'subAccountName':
                                                widget.subAccountName,
                                            'sovName': widget.sovName,
                                            'locationId':
                                                locationProfileProvider
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
                                                subAccountId:
                                                    widget.subAccountId,
                                                sovId: widget.sovId,
                                                accountName: widget.accountName,
                                                subAccountName:
                                                    widget.subAccountName,
                                                sovName: widget.sovName,
                                                locationId:
                                                    locationProfileProvider
                                                            .locationProfile
                                                            ?.id ??
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
                                                                .resetTotalPage -
                                                            1)
                                                        .toString()
                                                    : widget.totalPages,
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
                                      style:
                                          typography.H6.copyWith(height: 1.2)),
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
                      Divider(),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                'Campus List',
                                style: typography.H6.copyWith(height: 1.2),
                              ),
                            ),
                            locationProfileProvider.locationProfile
                                            ?.finalAddress?.score !=
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
                      (locationProfileProvider
                                      .locationProfile?.subdestinations ??
                                  [])
                              .isEmpty
                          ? Center(
                              child: Text('No Campus', style: typography.Body1))
                          : Container(
                              height: 240,
                              child: PageView.builder(
                                controller:
                                    PageController(viewportFraction: 0.9),
                                itemCount: (locationProfileProvider
                                            .locationProfile?.subdestinations ??
                                        [])
                                    .length,
                                itemBuilder: (context, index) {
                                  var subdestination = locationProfileProvider
                                      .locationProfile?.subdestinations![index];
                                  return GestureDetector(
                                    onTap: () =>
                                        _focusOnSubdestination(subdestination!),
                                    child: Card(
                                      margin: EdgeInsets.symmetric(
                                          vertical: 8, horizontal: 16),
                                      child: StatefulBuilder(
                                        builder: (context, setState) {
                                          String occupancy =
                                              (subdestination?.rented ?? false)
                                                  ? 'Rented/Leased'
                                                  : 'Owned';

                                          return Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              ListTile(
                                                title: Text(
                                                    subdestination?.name ?? ''),
                                                subtitle: Text(
                                                    subdestination?.address ??
                                                        ''),
                                                trailing: IconButton(
                                                  icon: Icon(Icons.map),
                                                  onPressed: () =>
                                                      _focusOnSubdestination(
                                                          subdestination!),
                                                ),
                                              ),
                                              if ((subdestination?.status ?? "")
                                                      .toLowerCase() ==
                                                  'added')
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    SizedBox(height: 8),
                                                    Padding(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 16.0),
                                                      child: Text(
                                                        "Occupancy Type",
                                                        style: typography.Body1,
                                                      ),
                                                    ),
                                                    Row(
                                                      children: [
                                                        Radio<String>(
                                                          value: "Owned",
                                                          groupValue: occupancy,
                                                          onChanged:
                                                              (value) async {
                                                            var provider = Provider
                                                                .of<MyLocationListProvider>(
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
                                                            print(
                                                                'Result: $result');
                                                            if (result) {
                                                              setState(() {
                                                                occupancy =
                                                                    value!;
                                                              });
                                                            } else {
                                                              ScaffoldMessenger
                                                                      .of(context)
                                                                  .showSnackBar(
                                                                SnackBar(
                                                                  content: Text(
                                                                      'Failed to change occupancy',
                                                                      style: typography
                                                                          .Body1),
                                                                ),
                                                              );
                                                            }
                                                          },
                                                        ),
                                                        Text("Owned"),
                                                        Radio<String>(
                                                          value:
                                                              "Rented/Leased",
                                                          groupValue: occupancy,
                                                          onChanged:
                                                              (value) async {
                                                            var provider = Provider
                                                                .of<MyLocationListProvider>(
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
                                                            print(
                                                                'Result: $result');
                                                            if (result) {
                                                              setState(() {
                                                                occupancy =
                                                                    value!;
                                                              });
                                                            } else {
                                                              ScaffoldMessenger
                                                                      .of(context)
                                                                  .showSnackBar(
                                                                SnackBar(
                                                                  content: Text(
                                                                      'Failed to change occupancy',
                                                                      style: typography
                                                                          .Body1),
                                                                ),
                                                              );
                                                            }
                                                          },
                                                        ),
                                                        Text("Rented/Leased"),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              Spacer(),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceEvenly,
                                                children: [
                                                  Chip(
                                                    padding: EdgeInsets.all(12),
                                                    label: Text(
                                                      subdestination?.status ??
                                                          "Not Added",
                                                      style: typography.Body1,
                                                    ),
                                                    backgroundColor:
                                                        (subdestination?.status ??
                                                                        "")
                                                                    .toLowerCase() ==
                                                                'added'
                                                            ? Colors.green
                                                            : Theme.of(context)
                                                                .colorScheme
                                                                .surface,
                                                  ),
                                                  locationProfileProvider
                                                          .isLoading
                                                      ? CircularProgressIndicator()
                                                      : (subdestination?.status ??
                                                                      "")
                                                                  .toLowerCase() ==
                                                              'added'
                                                          ? CustomButton(
                                                              type: ButtonType
                                                                  .elevated,
                                                              onPressed: () =>
                                                                  _removeFromSOV(
                                                                      subdestination
                                                                              ?.id ??
                                                                          ""),
                                                              child: Text(
                                                                'Remove Campus',
                                                                style:
                                                                    typography
                                                                        .Body1,
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                              ),
                                                            )
                                                          : CustomButton(
                                                              type: ButtonType
                                                                  .elevated,
                                                              onPressed: () {
                                                                var provider =
                                                                    Provider.of<
                                                                            MyLocationListProvider>(
                                                                        context,
                                                                        listen:
                                                                            false);
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
                                                                              ?.id ??
                                                                          "",
                                                                      occupancy);
                                                                } else {
                                                                  _addToSOV(
                                                                    subdestination
                                                                            ?.id ??
                                                                        "",
                                                                    occupancy:
                                                                        occupancy,
                                                                    campusName: provider
                                                                            .locationProfile
                                                                            ?.finalAddress
                                                                            ?.campusId ??
                                                                        "",
                                                                  );
                                                                }
                                                              },
                                                              child: Text(
                                                                  'Add to Campus',
                                                                  style:
                                                                      typography
                                                                          .Body1),
                                                            ),
                                                ],
                                              ),
                                              SizedBox(height: 8),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                },
                                onPageChanged: (index) {
                                  var subdestination = locationProfileProvider
                                      .subdestinations[index];
                                  _focusOnSubdestination(subdestination);
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
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surface,
                                      ),
                                      child: PageView.builder(
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
                                                          _images.removeAt(
                                                              itemIndex);
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
                                                        ?.screenshots?[
                                                    screenshotIndex];
                                            return GestureDetector(
                                              onTap: () =>
                                                  _showImagePreviewFromUrl(
                                                      screenshot?.imageUrl ??
                                                          ''),
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
                                  child: Text('No Images',
                                      style: typography.Body1)),
                      SizedBox(height: 24),
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
              ),
          ],
        ),
      );
    });
  }

  // Call this function to show the popup on tap
  void showLocationDetailsPopup(BuildContext context, MyLocation location,
      [bool hideNavigation = false]) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return LocationDetailsPopup(
          address: location.finalAddress?.address ?? 'Unknown Address',
          locationId: location.finalAddress?.locationId ?? 'Unknown ID',
          geocodingScore: location.finalAddress?.score ?? 0,
          riskScore: location.hazard?['Overall']?.rating ?? 0,
          //location.riskScore ?? 0,
          hazards: location.hazard ?? {},
          geocodedAt: [location.finalAddress?.locationType ?? ""],
          occupancy: location.finalAddress?.placeTypes ?? ["--"],
          campus: location.finalAddress?.campusId,
          accountId: widget.accountId,
          subAccountId: widget.subAccountId,
          sovId: widget.sovId,
          accountName: widget.accountName,
          subAccountName: widget.subAccountName,
          sovName: widget.sovName,
          hideNavigation: hideNavigation,
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
                '${widget.accountName}/${widget.subAccountName}-${widget.sovName}/${locationProfileProvider.locationProfile?.finalAddress?.locationIdForRef ?? ''}${formatLocationText((int.tryParse(widget.page) ?? 1) + 0, (int.tryParse(widget.totalPages) ?? 1))}',
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
                            IconButton(
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
                            ),
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
                                      Provider.of<UserProfileProvider>(context, listen: false);
                                      final trialStatus = userProfileProvider.trialInfo['status'] ?? '';
                                      final trialSubdestinations =
                                          userProfileProvider.trialInfo['subDestinations'] ?? 0;
                                      if (trialStatus != '' && trialSubdestinations < 1) {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return MessageCard(
                                              messageTextSpans: [
                                                TextSpan(
                                                  text: 'You\'ve reached your limit for ',
                                                  style: CustomTypography(context).Body1,
                                                ),
                                                TextSpan(
                                                  text: '“editing locations”',
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
                                                            .resetTotalPage -
                                                        1)
                                                    .toString()
                                                : widget.totalPages,
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
                  /*ListTile(
                    title: Text(
                      locationProfileProvider
                              .locationProfile?.finalAddress?.address ??
                          '',
                      style: typography.Body1,
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    trailing: IconButton(
                      icon: Padding(
                        padding: const EdgeInsets.only(left: 5.0),
                        child: Icon(Icons.edit, color: AppColors.primaryMain),
                      ),
                      onPressed: () => _editAddress(locationProfileProvider),
                    ),
                  ),*/
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
                        Flexible(
                          child: Text(
                            'Campus List',
                            style: typography.H6.copyWith(height: 1.2),
                          ),
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
                          child: Text('No Campus', style: typography.Body1))
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
                                          Chip(
                                            padding: EdgeInsets.all(12),
                                            label: Text(
                                                subdestination.status ??
                                                    "Not Added",
                                                style: typography.Body1),
                                            backgroundColor:
                                                (subdestination.status ?? "")
                                                            .toLowerCase() ==
                                                        'added'
                                                    ? Colors.green
                                                    : Theme.of(context)
                                                        .colorScheme
                                                        .surface,
                                          ),
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

  void _toggleAddMarkerMode() {
    setState(() {
      _isAddingMarker = !_isAddingMarker;
    });
  }

  void _toggleTagSubDestinationMode() {
    setState(() {
      _isTaggingSubDestination = !_isTaggingSubDestination;
    });
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
        context: context,
        builder: (BuildContext context) {
          return MessageCard(
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
        bool isLoading = false; // Moved outside StatefulBuilder

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            Future<void> handleCreate() async {
              if (isLoading) return; // Prevent multiple clicks

              setDialogState(() {
                isLoading = true;
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
                    isLoading = false;
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
                      if (isLoading) ...[
                        const SizedBox(height: 16),
                        Center(
                          // Center the loader
                          child: Container(
                            width: 24, // Explicit size for visibility
                            height: 24,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2.5, // Make it more visible
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () => Navigator.of(dialogContext).pop(),
                    child: Text(
                      'Cancel',
                      style: typography.Body1.copyWith(
                        color: isLoading ? Colors.grey : null,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: isLoading ? null : handleCreate,
                    child: Text(
                      'Add',
                      style: typography.Body1.copyWith(
                        color: isLoading ? Colors.grey : null,
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

  Widget _customInfoWindow(String title, String address, bool isAdded,
      Function() onAddToSOV, Function() onRemoveFromSOV) {
    var typography = CustomTypography(context);
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
            style: typography.H7.copyWith(
                color: Colors.white, fontWeight: FontWeight.bold, height: 1.2),
          ),
          SizedBox(height: 16),
          Text(
            address,
            style: typography.Body1.copyWith(color: Colors.white),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (isAdded)
                ElevatedButton.icon(
                  onPressed: onRemoveFromSOV,
                  icon: Icon(Icons.delete, color: Colors.red),
                  label: Text('Remove',
                      style: typography.Body1.copyWith(color: Colors.red)),
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.black),
                ),
              if (!isAdded)
                ElevatedButton.icon(
                  onPressed: onAddToSOV,
                  icon: Icon(Icons.add, color: Colors.blue),
                  label: Text('Add to SOV',
                      style: typography.Body1.copyWith(color: Colors.blue)),
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.black),
                ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildGoogleSearchBar(BuildContext context) {
    var typography = CustomTypography(context);
    return Container(
      padding: EdgeInsets.only(right: 16, top: 16),
      margin: EdgeInsets.only(right: 16),
      child: TypeAheadField<Suggestion>(
        builder: (context, controller, focusNode) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                  hintText: 'Search location',
                  hintStyle: typography.Body1,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  suffixIcon: Icon(Icons.search),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: SizedBox(
                        height: 20,
                        width: 20,
                        child: SvgPicture.asset(
                          "assets/images/googleLogo.svg",
                          width: 20,
                          height: 20,
                        )),
                  ),
                  prefixIconConstraints: BoxConstraints(
                    maxHeight: 40,
                    maxWidth: 40,
                  )),
            ),
          );
        },
        suggestionsCallback: (pattern) async {
          print('Pattern: $pattern');
          var apiProvider =
              PlaceApiProvider(autoCompleteSuggestionSessionToken);
          return await apiProvider.fetchSuggestions(pattern, 'en');
        },
        itemBuilder: (context, suggestion) {
          print('Suggestion: ${suggestion.description}');
          return ListTile(
            title: Text(suggestion.description, style: typography.Body1),
          );
        },
        onSelected: (suggestion) async {
          final GoogleMapController controller = await _controller.future;

          var placeApiProvider = PlaceApiProvider(Uuid().v4());
          // Get full place details
          final placeDetails =
              await placeApiProvider.getPlaceDetails(suggestion.placeId);
          final geometry = placeDetails['geometry']['location'];

          // Create a temporary marker
          final MarkerId markerId = MarkerId("temporary_marker");
          final Marker marker = Marker(
            markerId: markerId,
            position: LatLng(geometry['lat'], geometry['lng']),
            infoWindow: InfoWindow(
              title: placeDetails['name'],
              snippet: placeDetails['formatted_address'],
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor
                .hueOrange), // Change the color to orange for temporary markers
          );

          setState(() {
            markers[markerId] = marker;
          });

          // Move the camera to the selected location
          controller.animateCamera(CameraUpdate.newLatLng(
            LatLng(geometry['lat'], geometry['lng']),
          ));

          // Show confirmation bottom sheet
          showModalBottomSheet(
            context: context,
            builder: (BuildContext context) {
              return _buildConfirmationBottomSheet(
                context,
                placeDetails,
                geometry['lat'],
                geometry['lng'],
              );
            },
          );
        },
      ),
    );
  }

  void _addSelectedToSOV() async {
    var typography = CustomTypography(context);
    var provider = Provider.of<MyLocationListProvider>(context, listen: false);
    var checkedSubdestinations =
        provider.subdestinations.where((sd) => sd.isChecked).toList();
    // Check for selections
    if (checkedSubdestinations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Please select at least one subdestination',
                style: typography.Body1)),
      );
      return;
    }

    await provider.addSelectedSubdestinationToSOV(
      context,
      widget.accountId,
      widget.subAccountId,
      widget.sovId,
      provider.locationProfile?.finalAddress?.locationId ?? '',
      checkedSubdestinations.map((sd) => sd.id!).toList(),
    );

    // Optionally, you can refresh the data or show a success message here
    _getData();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Selected subdestinations added to SOV',
              style: typography.Body1)),
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
    await provider
        .addSubdestinationToSOV(
      context: context,
      accountId: widget.accountId,
      subAccountId: widget.subAccountId,
      campusName: campusName,
      userId: user?.uid ?? '',
      locationId: provider.locationProfile?.finalAddress?.locationId ?? '',
      subDestinationId: subdestinationId,
      occupancy: occupancy,
    )
        .then((value) {
      _getData();
    });
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

  Widget _buildConfirmationBottomSheet(BuildContext context,
      Map<String, dynamic> placeDetails, double lat, double lng) {
    var typography = CustomTypography(context);
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 16),
          Text(
            placeDetails['name'] ?? 'Selected Location',
            style: typography.H6,
          ),
          SizedBox(height: 8),
          Text(
            placeDetails['formatted_address'] ?? 'No address available',
            style: typography.Body1,
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the bottom sheet

                  // Remove the temporary marker
                  setState(() {
                    markers.remove(MarkerId("temporary_marker"));
                  });
                  _goToTheInitialPin();
                },
                child: Text('Cancel', style: typography.Body1),
              ),
              SizedBox(width: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the bottom sheet

                  // Remove the temporary marker and add a permanent one
                  setState(() {
                    markers.remove(MarkerId("temporary_marker"));

                    // Add permanent marker
                    final MarkerId permanentMarkerId =
                        MarkerId(placeDetails['place_id']);
                    final Marker permanentMarker = Marker(
                      markerId: permanentMarkerId,
                      position: LatLng(lat, lng),
                      infoWindow: InfoWindow(
                        title: placeDetails['name'],
                        snippet: placeDetails['formatted_address'],
                      ),
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor
                              .hueRed), // Change to a permanent color
                    );

                    markers[permanentMarkerId] = permanentMarker;
                  });

                  // Continue with existing functionality
                  _confirmLocationSelection(placeDetails, lat, lng);
                },
                child: Text('OK', style: typography.Body1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLocationSelection(
      Map<String, dynamic> placeDetails, double lat, double lng) async {
    var typography = CustomTypography(context);
    // Continue with the existing functionality to handle the selected location
    // This could include updating the state, making API calls, etc.

    // Example:
    print('Confirmed Location: ${placeDetails['name']} at ($lat, $lng)');

    final geometry = placeDetails['geometry']['location'];
    final addressComponents = placeDetails['address_components'];

    // Extract required fields from address components
    String city = '';
    String state = '';
    String zip = '';
    String country = '';

    for (var component in addressComponents) {
      print('Component: $component');
      final types = component['types'];
      if (types.contains('locality')) {
        city = component['long_name'];
      } else if (types.contains('administrative_area_level_1')) {
        state = component['short_name'];
      } else if (types.contains('postal_code')) {
        zip = component['long_name'];
      } else if (types.contains('country')) {
        country = component['long_name'];
      }
    }

    // Create data payload

    var provider = Provider.of<MyLocationListProvider>(context, listen: false);
    final data = {
      "data": {
        "location_name": placeDetails['name'],
        "location_type": placeDetails['types'],
        "description": "",
        "address": placeDetails['formatted_address'],
        "city": city,
        "state": state,
        "zip": zip,
        "country": country,
        "latitude": geometry['lat'],
        "longitude": geometry['lng'],
        "by_search": true,
        "location_id": provider.locationProfile?.finalAddress?.locationId ?? "",
        "place_id": placeDetails['place_id'],
      }
    };
    String result = await provider.updateLocationDetails(
        context,
        widget.accountId,
        widget.subAccountId,
        widget.sovId,
        provider.locationProfile?.finalAddress?.locationId ?? '',
        data);
    if (result.toLowerCase() == 'true') {
      _getData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text('Failed to update location details', style: typography.Body1),
      ));
    }
  }

  void _navigateRight() {
    print('Page: ${widget.page}, Total Pages: ${widget.totalPages}');
    if ((int.tryParse(widget.page) ?? 1) >
        (widget.locationId.isNotEmpty
                ? Provider.of<MyLocationListProvider>(context, listen: false)
                        .resetTotalPage -
                    1
                : (int.tryParse(widget.totalPages) ?? 1)) -
            0) {
      return;
    }
    int pageToNavigate = 1;
    bool isLocationIdNotNull = widget.locationId.isNotEmpty;
    if (isLocationIdNotNull) {
      pageToNavigate = (int.tryParse(widget.page) ?? 1);
    } else {
      pageToNavigate = (int.tryParse(widget.page) ?? 1) + 1;
    }
    Navigator.pushReplacement(
      context,
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
          totalPages: (isLocationIdNotNull
              ? Provider.of<MyLocationListProvider>(context, listen: false)
                  .resetTotalPage
                  .toString()
              : widget.totalPages),
        ),
      ),
    );
  }

  void _navigateLeft() {
    if ((int.tryParse(widget.page) ?? 1) <= 1) {
      return;
    }
    bool isLocationIdNotNull = widget.locationId.isNotEmpty;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LocationProfile(
          accountId: widget.accountId,
          subAccountId: widget.subAccountId,
          sovId: widget.sovId,
          accountName: widget.accountName,
          subAccountName: widget.subAccountName,
          sovName: widget.sovName,
          searchQuery: widget.searchQuery,
          page: ((int.tryParse(widget.page) ?? 1) - 1).toString(),
          totalPages: (isLocationIdNotNull
              ? Provider.of<MyLocationListProvider>(context, listen: false)
                  .resetTotalPage
                  .toString()
              : widget.totalPages),
        ),
      ),
    );
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
    return ' - (${getOrdinal(location)} Location of $total)';
  }
}
