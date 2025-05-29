/*
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:green/constants/enums.dart';
import 'package:green/design_system/primitives/app_colors.dart';
import 'package:green/design_system/primitives/custom_typography.dart';
import 'package:green/design_system/primitives/utilities/custom_spacing.dart';
import 'package:green/models/account_list_model.dart';
import 'package:green/providers/location_profile_provider.dart';
import 'package:green/providers/place_api_provider.dart';
import 'package:green/screens/listings/add_location_screen.dart';
import 'package:green/screens/listings/widgets/dots_indicator.dart';
import 'package:green/screens/listings/widgets/export_dialog.dart';
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
import '../../providers/theme_provider.dart';
import '../../design_system/components/custom_appbar.dart';
import '../../design_system/components/custom_drawer.dart';

class LocationProfilePreview extends StatefulWidget {
  const LocationProfilePreview({
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
    required this.toDeleteLocationId,
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
  final String toDeleteLocationId;

  @override
  State<LocationProfilePreview> createState() => _LocationProfilePreviewState();
}

class _LocationProfilePreviewState extends State<LocationProfilePreview>
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

  TextEditingController _nameController = TextEditingController();
  TextEditingController _addressController = TextEditingController();
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

    super.initState();
  }

  Future<void> _getData() async {
    // Make API call to get the data
   */
/* await Provider.of<LocationProfileProvider>(context, listen: false)
        .fetchLocationDetails(context, widget.accountId, widget.subAccountId,
        widget.sovId, widget.searchQuery, widget.page, widget.totalPages);
    _addSubdestinationMarkers();
    _add();*//*

    _add();
  }

  void _add() {
    var controller =
    Provider.of<LocationProfileProvider>(context, listen: false);
    var markerIdVal = controller.result?.locationId ?? '1';
    final MarkerId markerId = MarkerId(markerIdVal);

    print(
        'Latitude: ${controller.result?.latitude}, Longitude: ${controller.result?.longitude}');
    final Marker marker = Marker(
      markerId: markerId,
      position: LatLng(controller.result?.latitude ?? 123.432432,
          controller.result?.longitude ?? -111.889),
      infoWindow: InfoWindow(
          title: controller.result?.locationName ?? "",
          snippet: controller.result?.address ?? ""),
      onTap: () {
        _onMarkerTapped(markerId);
      },
    );

    setState(() {
      markers[markerId] = marker;
    });
    _controller.future.then((value) => value.animateCamera(
        CameraUpdate.newLatLng(LatLng(controller.result?.latitude ?? 123.432432,
            controller.result?.longitude ?? -111.889))));
    // if rating is 3 or 4
    if (controller.result?.score == 3 || controller.result?.score == 4) {
      setState(() {
        _searchController.text = controller.result?.address ?? "";
      });
    }
  }

  void _addSubdestinationMarkers() {
    var provider = Provider.of<LocationProfileProvider>(context, listen: false);
    for (var subdestination in provider.result?.subdestinations ?? []) {
      var markerId = MarkerId(subdestination.id!);
      var isAdded = (subdestination.status ?? "").toLowerCase() == "added";
      var marker = Marker(
        zIndex: isAdded ? 5 : 0,
        markerId: markerId,
        position: LatLng(subdestination.lat!, subdestination.lng!),
        icon: BitmapDescriptor.defaultMarkerWithHue(
            isAdded ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueAzure),
        infoWindow: InfoWindow(
            title: subdestination.name, snippet: subdestination.address),
        onTap: () {
          _onMarkerTapped(markerId);
        },
      );

      setState(() {
        markers[markerId] = marker;
      });
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
      Provider.of<LocationProfileProvider>(context, listen: false);
      await provider.uploadImage(context, file.path, widget.accountId,
          widget.subAccountId, widget.sovId, provider.result!.locationId ?? "");
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
        Provider.of<LocationProfileProvider>(context, listen: false);
        await provider.uploadImage(
            context,
            filePath,
            widget.accountId,
            widget.subAccountId,
            widget.sovId,
            provider.result!.locationId ?? "");
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to capture screenshot',
                style: typography.Body1),
          ),
        );
      }
    } else if (status.isDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
          Text('Storage permission denied', style: typography.Body1),
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
    return Consumer<ThemeProvider>(builder: (context, themeProvider, child) {
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
        body: Stack(
          children: [
            Column(
              children: [
                ListTile(
                title: Text(
                  'Seems this Address already exists in the database!!',
                  style: typography.Subtitle1.copyWith(
                      fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  'Please check and confirm!!',
                  style: typography.Body1,
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
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
                              onMapCreated: (GoogleMapController controller) {
                                _controller.complete(controller);
                              },
                              gestureRecognizers: <Factory<
                                  OneSequenceGestureRecognizer>>{
                                Factory<OneSequenceGestureRecognizer>(
                                      () => EagerGestureRecognizer(),
                                ),
                              },
                              onTap: _isAddingMarker ? _handleMapTap : null,
                            ),
                          ),
                        ),
                      ),

                      Consumer<LocationProfileProvider>(
                          builder: (context, locationProfileProvider, child) {
                            return Positioned(
                              bottom: 16,
                              left: 16,
                              child: Container(
                                margin: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.paperElevation2,
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
                                    SizedBox(height: 8),
                                    FloatingActionButton.small(
                                      backgroundColor: AppColors.paperElevation2,
                                      onPressed: () {
                                        setState(() {
                                          _currentMapType =
                                          _currentMapType == MapType.normal
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
            */
/*Consumer<LocationProfileProvider>(
              builder: (context, provider, child) {
                return provider.isUploadingImage ? Center(child: CircularProgressIndicator()) : SizedBox.shrink();
              },
            ),*//*

            if (_selectedMarker != null) _buildCustomInfoWindow(),
          ],
        ),
      );
    });
  }

  Widget _buildCustomInfoWindow() {
    var marker = markers[_selectedMarker];
    var isSubdestination =
        marker?.infoWindow.title?.contains("Subdestination") ?? false;
    var isAdded = marker?.infoWindow.snippet?.contains("Added") ?? false;

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
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                    ),
                  ElevatedButton.icon(
                    onPressed: () => _addToSOV(_selectedMarker!.value),
                    icon: Icon(Icons.add, color: Colors.blue),
                    label: Text('Add to SOV',
                        style: TextStyle(color: Colors.blue)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
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

  void _addCustomMarker(LatLng position, String title, String address,
      bool isSubdestination, bool isAdded,
      {VoidCallback? onAddToSOV, VoidCallback? onRemoveFromSOV}) async {
    */
/* Uint8List markerBitmap = await createCustomMarkerBitmap(isSubdestination ? _subdestinationMarkerKey : _mainMarkerKey);

    final Marker marker = Marker(
      markerId: MarkerId("custom_marker_${markers.length}"),
      position: position,
      icon: BitmapDescriptor.fromBytes(markerBitmap),
      infoWindow: InfoWindow(
        title: title,
        snippet: address,
        onTap: () {
          setState(() {
            _selectedMarker = MarkerId("custom_marker_${markers.length}");
          });
        },
      ),
    );

    setState(() {
      markers[marker.markerId] = marker;
    });*//*

  }

  Widget _buildBottomSheet() {
    var typography = CustomTypography(context);
    return Consumer<LocationProfileProvider>(
        builder: (context, locationProfileProvider, child) {
          return AnimatedContainer(
            duration: Duration(milliseconds: 300),
            height: _isBottomSheetExpanded
                ? MediaQuery.of(context).size.height * 0.5
                : MediaQuery.of(context).size.height * 0.14,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ListTile(
                      title: Text(
                        '${widget.accountName}/${widget.subAccountName}-${widget.sovName}/${locationProfileProvider.result?.locationIdForRef ?? ''}',
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
                          ListTile(
                            title: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    locationProfileProvider.result?.locationName ??
                                        '',
                                    style:
                                    typography.H6.copyWith(height: 1.2),
                                  ),
                                ),
                              ],
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16),
                            trailing: TooltipTheme(
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
                              child: Padding(
                                padding: const EdgeInsets.only(right: 12.0),
                                child: Tooltip(
                                  showDuration: Duration(seconds: 5),
                                  triggerMode: TooltipTriggerMode.tap,
                                  preferBelow: true,
                                  richMessage: TextSpan(
                                    children: [
                                      TextSpan(
                                        text:
                                        'Geocode Type: ${locationProfileProvider.result?.locationType ?? 'Unknown'}\n',
                                        style: typography.Subtitle1,
                                      ),
                                      // Comma seperated
                                      TextSpan(
                                        text:
                                        'Property Type: ${locationProfileProvider.result?.placeTypes?.join(', ') ?? 'Unknown'}\n',
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
                            padding: EdgeInsets.only(left: 16, right: 24),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                RatingSlider(
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
                                ),
                                SvgPicture.asset('assets/images/certified.svg'),
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
                              ],
                            ),
                          ),
                          ListTile(
                            title: Text(
                              locationProfileProvider.result?.address ?? '',
                              style: typography.Body1,
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16),

                          ),
                          Divider(),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    'Is this the same location?',
                                    style: typography.H6.copyWith(height: 1.2),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              CustomButton(
                                type: ButtonType.text,
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text('No',
                                    style: typography.Body1),
                              ),
                              Consumer<LocationProfileProvider>(
                                builder: (context, locationProfileProvider, child) {
                                  return locationProfileProvider.isLoading?
                                  CircularProgressIndicator():
                                  CustomButton(
                                    type: ButtonType.elevated,
                                    onPressed: () {
                                      locationProfileProvider.autocompleteUserConfirmation(context, widget.accountId, widget.subAccountId, widget.sovId, widget.toDeleteLocationId,);



                                    },
                                    child: Text('Yes',
                                        style: typography.Body1),
                                  );
                                }
                              ),
                            ],
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

  Widget _locationProfileBody() {
    var typography = CustomTypography(context);
    return Consumer<LocationProfileProvider>(
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
                    '${widget.accountName}/${widget.subAccountName}-${widget.sovName}/${locationProfileProvider.result?.locationIdForRef ?? ''}',
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
                                locationProfileProvider.result?.locationName ?? '',
                                style: typography.H6.copyWith(height: 1.2),
                              ),
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
                                    'Geocode Type: ${locationProfileProvider.result?.locationType ?? 'Unknown'}\n',
                                    style: typography.Subtitle1,
                                  ),
                                  // Comma seperated
                                  TextSpan(
                                    text:
                                    'Property Type: ${locationProfileProvider.result?.placeTypes?.join(', ') ?? 'Unknown'}\n',
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset('assets/images/certified.svg'),
                          SizedBox(width: 8),
                          RatingSlider(
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
                          ),
                        ],
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
                          ],
                        ),
                      ),
                      ListTile(
                        title: Text(
                          locationProfileProvider.result?.address ?? '',
                          style: typography.Body1,
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),

                      ),
                      Divider(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                'Is this the same location?',
                                style: typography.H6.copyWith(height: 1.2),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          CustomButton(
                            type: ButtonType.text,
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text('No', style: typography.Body1),
                          ),
                          CustomButton(
                            type: ButtonType.elevated,
                            onPressed: () {
                              locationProfileProvider.autocompleteUserConfirmation(context, widget.accountId, widget.subAccountId, widget.sovId, widget.toDeleteLocationId,);
                            },
                            child: Text('Yes', style: typography.Body1),
                          ),
                        ],
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
      Provider.of<LocationProfileProvider>(context, listen: false);
      var mainMarkerPosition = CameraPosition(
        target: LatLng(
          provider.result?.latitude ?? 0,
          provider.result?.longitude ?? 0,
        ),
        zoom: 16,
      );
      await controller
          .animateCamera(CameraUpdate.newCameraPosition(mainMarkerPosition));
    } else {
      print('Google Map Controller is null');
    }
  }

  void _onMarkerTapped(MarkerId markerId) {
    var provider = Provider.of<LocationProfileProvider>(context, listen: false);
    var subdestination = provider.subdestinations
        .firstWhereOrNull((element) => element.id == markerId.value);
    if (subdestination != null) {
      showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            child: _customInfoWindow(
              subdestination.name ?? '',
              subdestination.address ?? '',
              (subdestination.status ?? "").toLowerCase() == "added",
                  () => _addToSOV(subdestination.id!).then((value) {
                Navigator.pop(context);
                _getData();
              }),
                  () => _removeFromSOV(subdestination.id!).then((value) {
                Navigator.pop(context);
                _getData();
              }),
            ),
          );
        },
      );
    } else {
      */
/*var mainLocation = provider.result;
      showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            child: _mainMarkerInfoWindow(
              mainLocation?.locationName ?? '',
              mainLocation?.address ?? '',
            ),
          );
        },
      );*//*

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
      infoWindow: InfoWindow(title: markerIdVal, snippet: '*'),
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
    var locationProfileProvider =
    Provider.of<LocationProfileProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        var typography = CustomTypography(context);
        return AlertDialog(
          title: Text('Add Sub-Destinations', style: typography.H6),
          content: Text(
              'Do you want to get sub-destinations for this location?',
              style: typography.Body1),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                var provider = Provider.of<LocationProfileProvider>(context,
                    listen: false);
                await Provider.of<LocationProfileProvider>(context,
                    listen: false)
                    .createSubdestination(
                  context,
                  widget.accountId,
                  widget.subAccountId,
                  widget.sovId,
                  locationProfileProvider.result?.locationId ?? '',
                  provider.result?.latitude ?? 0,
                  provider.result?.longitude ?? 0,
                  provider.result?.placeId ?? '',
                )
                    .then((value) {
                  _getData();
                });
                Navigator.of(context).pop();
              },
              child: Consumer<LocationProfileProvider>(
                  builder: (context, locationProfileProvider, child) {
                    return locationProfileProvider.isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Add');
                  }),
            ),
          ],
        );
      },
    );
  }

  void _editName(LocationProfileProvider provider) {
    var typography = CustomTypography(context);
    _nameController.text = provider.result?.locationName ?? '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Consumer<LocationProfileProvider>(
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
                        locationProfileProvider.result?.locationId ?? '',
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

  void _editAddress(LocationProfileProvider provider) {
    var typography = CustomTypography(context);
    _addressController.text = provider.result?.address ?? '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Consumer<LocationProfileProvider>(
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
                        locationProfileProvider.result?.locationId ?? '',
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
                      style:
                      typography.Body1.copyWith(color: Colors.red)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                ),
              if (!isAdded)
                ElevatedButton.icon(
                  onPressed: onAddToSOV,
                  icon: Icon(Icons.add, color: Colors.blue),
                  label: Text('Add to SOV',
                      style:
                      typography.Body1.copyWith(color: Colors.blue)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
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

  void _removeMarker(MarkerId markerId) {
    setState(() {
      markers.remove(markerId);
    });
  }

  void _searchWithPlacesAPI() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Search location'),
          content: Autocomplete<Suggestion>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text == '') {
                return const Iterable<Suggestion>.empty();
              } else {
                return Future.delayed(Duration.zero, () async {
                  _searchLocations =
                  await searchLocations(textEditingValue.text);
                  // If single suggestion is found, select it automatically
                  if (_searchLocations.length == 1) {
                    // Select the first suggestion
                    searchController.text = _searchLocations.first.description;
                    // Add the marker
                    try {
                      final placeId = _searchLocations.first.placeId;
                      var placeApiProvider = PlaceApiProvider(Uuid().v4());
                      final latLng =
                      await placeApiProvider.getLatLngFromPlaceId(placeId);
                      print(
                          'Latitude: ${latLng.latitude}, Longitude: ${latLng.longitude}');
                      _addMarker(latLng);
                      // Move the camera to the selected location
                      final GoogleMapController controller =
                      await _controller.future;
                      controller.animateCamera(CameraUpdate.newLatLng(latLng));
                      Navigator.of(context).pop();
                    } catch (e) {
                      print('Error fetching location from place ID: $e');
                    }

                    // Clear the suggestions
                    _searchLocations.clear();
                  }
                  return _searchLocations;
                });
              }
            },
            displayStringForOption: (suggestion) => suggestion.description,
            onSelected: (suggestion) {
              searchController.text = suggestion.description;
              // Add the marker
              addMarkerFromPlaceId(suggestion, context);
            },
            fieldViewBuilder:
                (context, controller, focusNode, onFieldSubmitted) {
              return TextField(
                controller: controller,
                focusNode: focusNode,
                decoration: InputDecoration(
                  hintText: 'Search location',
                  border: OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.search),
                    onPressed: () {
                      // Search for a location using the Places API
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Search for a location using the Places API
                Navigator.of(context).pop();
              },
              child: const Text('Search'),
            ),
          ],
        );
      },
    );
  }

  void _addSelectedToSOV() async {
    var typography = CustomTypography(context);
    var provider = Provider.of<LocationProfileProvider>(context, listen: false);
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
      provider.result?.locationId ?? '',
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

  Future<void> _addToSOV(String subdestinationId) async {
    var provider = Provider.of<LocationProfileProvider>(context, listen: false);
    await provider
        .addSubdestinationToSOV(
      context,
      widget.accountId,
      widget.subAccountId,
      widget.sovId,
      provider.result?.locationId ?? '',
      subdestinationId,
    )
        .then((value) {
      _getData();
    });
  }

  Future<void> _removeFromSOV(String subdestinationId) async {
    var provider = Provider.of<LocationProfileProvider>(context, listen: false);
    await provider.removeSubdestinationFromSOV(
      context,
      widget.accountId,
      widget.subAccountId,
      widget.sovId,
      provider.result?.locationId ?? '',
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

    var provider = Provider.of<LocationProfileProvider>(context, listen: false);
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
        "location_id": provider.result?.locationId ?? "",
        "place_id": placeDetails['place_id'],
      }
    };
    String result = await provider.updateLocationDetails(
        context,
        widget.accountId,
        widget.subAccountId,
        widget.sovId,
        provider.result?.locationId ?? '',
        data);
    if (result.toLowerCase().toString() == "true") {
      _getData();
    } else {

    }
  }

}
*/
