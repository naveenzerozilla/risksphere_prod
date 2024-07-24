import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
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
import 'package:green/screens/listings/widgets/export_dialog.dart';
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

class LocationProfile extends StatefulWidget {
  const LocationProfile({
    super.key,
    required this.accountId,
    required this.accountName,
    required this.subAccountId,
    required this.subAccountName,
    required this.sovId,
    required this.sovName,
    required this.locationId,
    required this.locationName,
  });

  final String accountId;
  final String accountName;
  final String subAccountId;
  final String subAccountName;
  final String sovId;
  final String sovName;
  final String locationId;
  final String locationName;

  @override
  State<LocationProfile> createState() => _LocationProfileState();
}

class _LocationProfileState extends State<LocationProfile>
    with SingleTickerProviderStateMixin {
  // App Bar
  bool _isExpanded = false;
  bool _showNotificationDot = true;

  // Google Maps
  GlobalKey _googleMapKey = GlobalKey();
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};
  ScreenshotController screenshotController = ScreenshotController();

  bool _isAddingMarker = false;
  bool _isTaggingSubDestination = false;

  TabController? _tabController;
  TextEditingController _nameController = TextEditingController();
  TextEditingController _addressController = TextEditingController();
  TextEditingController searchController = TextEditingController();
  List<Suggestion> _searchLocations = [];
  List<File> _images = [];

  String autoCompleteSuggestionSessionToken = Uuid().v4();

  MapType _currentMapType = MapType.normal;

  void _add() {
    var markerIdVal = "hardcoded_id";
    final MarkerId markerId = MarkerId(markerIdVal);

    var controller =
        Provider.of<LocationProfileProvider>(context, listen: false);
    print(
        'Latitude: ${controller.result?.latitude}, Longitude: ${controller.result?.longitude}');
    final Marker marker = Marker(
      markerId: markerId,
      position: LatLng(controller.result?.latitude ?? 123.432432,
          controller.result?.longitude ?? -111.889),
      infoWindow: InfoWindow(title: markerIdVal, snippet: '*'),
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
  }

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(40.32434, -111.889),
    zoom: 16,
  );

  @override
  void initState() {
    _getData();

    _tabController = TabController(length: 4, vsync: this);
    super.initState();
  }

  Future<void> _getData() async {
    // Make API call to get the data
    await Provider.of<LocationProfileProvider>(context, listen: false)
        .fetchLocationDetails(context, widget.accountId, widget.subAccountId,
            widget.sovId, widget.locationId);
    _addSubdestinationMarkers();
    _add();
  }

  void _addSubdestinationMarkers() {
    var provider = Provider.of<LocationProfileProvider>(context, listen: false);
    provider.result?.subdestinations?.forEach((subdestination) {
      var markerId = MarkerId(subdestination.id!);
      var marker = Marker(
        markerId: markerId,
        position: LatLng(subdestination.lat!, subdestination.lng!),
        infoWindow: InfoWindow(
            title: subdestination.name, snippet: subdestination.address),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        onTap: () {
          _onMarkerTapped(markerId);
        },
      );
      markers[markerId] = marker;
    });
  }

  Future<void> _pickImage() async {
    final pickedFiles = await ImagePicker().pickMultiImage();
    setState(() {
      _images.addAll(pickedFiles.map((file) => File(file.path)));
    });
    // Make API call to upload the images
    for (var file in pickedFiles) {
      await Provider.of<LocationProfileProvider>(context, listen: false)
          .uploadImage(context, file.path, widget.accountId,
              widget.subAccountId, widget.sovId, widget.locationId);
    }
  }

  Future<void> _captureAndUploadMapScreenshot() async {
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

      await Provider.of<LocationProfileProvider>(context, listen: false)
          .uploadImage(context, filePath, widget.accountId, widget.subAccountId,
              widget.sovId, widget.locationId);
    }
  }

  @override
  Widget build(BuildContext context) {
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
            Screenshot(
              controller: screenshotController,
              child: GoogleMap(
                key: _googleMapKey,
                mapType: _currentMapType,
                markers: Set<Marker>.of(markers.values),
                initialCameraPosition: _kGooglePlex,
                onMapCreated: (GoogleMapController controller) {
                  _controller.complete(controller);
                },
                gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                  Factory<OneSequenceGestureRecognizer>(
                    () => EagerGestureRecognizer(),
                  ),
                },
                onTap: _isAddingMarker
                    ? _handleMapTap
                    : /*_isTaggingSubDestination
                        ? _handleSubDestinationTap
                        : */
                    null,
              ),
            ),
            // Persistent Bottom Sheet
            _locationProfileBody(),
            Consumer<LocationProfileProvider>(
              builder: (context, provider, child) {
                return provider.isUploadingImage
                    ? Center(child: CircularProgressIndicator())
                    : SizedBox.shrink();
              },
            ),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
        floatingActionButton: Consumer<LocationProfileProvider>(
            builder: (context, locationProfileProvider, child) {
          return Padding(
            padding: const EdgeInsets.only(top: 160.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                (locationProfileProvider.result?.score ?? 0) == 3 ||
                        (locationProfileProvider.result?.score ?? 0) == 4
                    ? SizedBox(height: CustomSpacing.eight)
                    : SizedBox(),
                (locationProfileProvider.result?.score ?? 0) == 3 ||
                        (locationProfileProvider.result?.score ?? 0) == 4
                    ? _buildGoogleSearchBar(context)
                    : SizedBox(),
                (locationProfileProvider.result?.score ?? 0) == 3 ||
                        (locationProfileProvider.result?.score ?? 0) == 4
                    ? SizedBox(height: CustomSpacing.eight)
                    : SizedBox(),
                Row(
                  children: [
                    ((locationProfileProvider.result?.score ?? 0) == 5) &&
                            (((locationProfileProvider.result?.placeTypes?[0] ??
                                            "")
                                        .toLowerCase() ==
                                    "premise") ||
                                ((locationProfileProvider
                                                .result?.placeTypes?[0] ??
                                            "")
                                        .toLowerCase() ==
                                    "subpremise") ||
                                ((locationProfileProvider
                                                .result?.placeTypes?[0] ??
                                            "")
                                        .toLowerCase() ==
                                    "rooftop"))
                        ? FloatingActionButton.small(
                            onPressed: _handleSubDestinationTap,
                            child: const Icon(Icons.add_location_alt),
                            tooltip: 'Add Sub-Destination',
                          )
                        : SizedBox.shrink(),
                    Spacer(),
                    Padding(
                      padding: EdgeInsets.only(right: CustomSpacing.eight),
                      child: FloatingActionButton.small(
                        onPressed: _captureAndUploadMapScreenshot,
                        child: Icon(Icons.camera),
                        tooltip: 'Capture and Upload Screenshot',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
                (locationProfileProvider.result?.score ?? 0) == 1 ||
                        (locationProfileProvider.result?.score ?? 0) == 2
                    ? FloatingActionButton.small(
                        onPressed: _toggleAddMarkerMode,
                        child: _isAddingMarker
                            ? const Icon(Icons.cancel)
                            : const Icon(Icons.add_location),
                      )
                    : SizedBox.shrink(),

                //change map type
                FloatingActionButton.small(
                  onPressed: () {
                    setState(() {
                      _currentMapType = _currentMapType == MapType.normal
                          ? MapType.satellite
                          : MapType.normal;
                    });
                  },
                  child: Icon(Icons.map),
                  tooltip: 'Change Map Type',
                ),
              ],
            ),
          );
        }),
      );
    });
  }

  Widget _locationProfileBody() {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.1,
      maxChildSize: 0.8,
      builder: (BuildContext context, ScrollController scrollController) {
        return ListView(
          controller: scrollController,
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.paperElevation2,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20)),
                      color: AppColors.paperElevation2,
                    ),
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: CustomSpacing.four),
                        Consumer<LocationProfileProvider>(
                          builder: (context, provider, child) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Row(
                                children: [
                                  Text(
                                    provider.result?.locationIdForRef ?? '',
                                    style: CustomTypography.Caption,
                                  ),
                                  Spacer(),
                                  PopupMenuButton<int>(
                                    offset: Offset(0, 50),
                                    icon: Icon(Icons.more_vert), // Three vertical dots icon
                                    onSelected: (value) {
                                      if (value == 1) {
                                        // Show export dialog
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return ExportDialog(
                                              accountId: widget.accountId,
                                              subAccountId: widget.subAccountId,
                                              sovId: [widget.sovId],
                                              locationId: widget.locationId,
                                            );
                                          },
                                        );
                                      } else if (value == 2) {
                                        // Navigate to Edit Location
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => AddLocationScreen(accountId: widget.accountId, subAccountId: widget.subAccountId, sovId: widget.sovId, locationId: widget.locationId, accountName: widget.accountName, subAccountName: widget.subAccountName, sovName: widget.sovName, locationName: widget.locationName,)), // Replace with your Edit Location screen
                                        );
                                      }
                                    },
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    itemBuilder: (context) {
                                      List<PopupMenuEntry<int>> items = [
                                        PopupMenuItem(
                                          value: 1,
                                          child: Row(
                                            children: [
                                              Icon(Icons.download),
                                              SizedBox(width: 8),
                                              Text('Export', style: CustomTypography.Body1),
                                            ],
                                          ),
                                        ),
                                      ];

                                      // Check the condition and add Edit Location item if score is not 5
                                      if ((provider.result?.score ?? 0) != 5) {
                                        items.add(PopupMenuDivider());
                                        items.add(
                                          PopupMenuItem(
                                            value: 2,
                                            child: Row(
                                              children: [
                                                Icon(Icons.edit),
                                                SizedBox(width: 8),
                                                Text('Edit Location', style: CustomTypography.Body1),
                                              ],
                                            ),
                                          ),
                                        );
                                      }

                                      return items;
                                    },
                                  ),

                              ],
                              ),
                            );
                          },
                        ),
                        SizedBox(height: CustomSpacing.two),
                        Row(
                          children: [
                            Expanded(
                              child: Consumer<LocationProfileProvider>(
                                builder: (context, provider, child) {
                                  return Text(
                                    provider.result?.locationName ?? '',
                                    style: CustomTypography.H6
                                        .copyWith(height: 1.5),
                                  );
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Consumer<LocationProfileProvider>(
                                  builder: (context, provider, child) {
                                return IconButton(
                                    icon: Icon(Icons.edit,
                                        color: AppColors.primaryMain),
                                    onPressed: () =>
                                        (provider.result?.score ?? 0) == 5
                                            ? _editName(provider)
                                            : _editAddress(provider));
                              }),
                            ),
                          ],
                        ),
                        SizedBox(height: CustomSpacing.two),
                        Consumer<LocationProfileProvider>(
                          builder: (context, provider, child) {
                            return Text(
                              provider.result?.address ?? '',
                              style: CustomTypography.Caption,
                            );
                          },
                        ),
                        SizedBox(height: CustomSpacing.two),
                      ],
                    ),
                  ),
                  Consumer<LocationProfileProvider>(
                      builder: (context, provider, child) {
                    return provider.result?.description != null &&
                            provider.result?.description != ""
                        ? Divider()
                        : SizedBox();
                  }),
                  Consumer<LocationProfileProvider>(
                    builder: (context, provider, child) {
                      return provider.result?.description != null &&
                              provider.result?.description != ""
                          ? Container(
                              decoration: BoxDecoration(
                                color: AppColors.paperElevation2,
                              ),
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: CustomSpacing.two),
                                  Text(
                                    'Description',
                                    style: CustomTypography.H6,
                                  ),
                                  SizedBox(height: CustomSpacing.four),
                                  Consumer<LocationProfileProvider>(
                                    builder: (context, provider, child) {
                                      return Text(
                                        provider.result?.description ??
                                            'No description available.',
                                        style: CustomTypography.Caption,
                                      );
                                    },
                                  ),
                                ],
                              ),
                            )
                          : SizedBox();
                    },
                  ),
                  Container(
                    height: 300,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                    ),
                    child: Column(
                      children: [
                        TabBar(
                          isScrollable: true,
                          labelStyle: CustomTypography.Subtitle2,
                          controller: _tabController,
                          indicatorColor: Theme.of(context).colorScheme.primary,
                          labelColor: Theme.of(context).colorScheme.primary,
                          unselectedLabelColor:
                              Theme.of(context).colorScheme.onSurface,
                          tabs: const [
                            Tab(
                              text: 'Hazard',
                            ),
                            Tab(text: 'Construction'),
                            Tab(text: 'Occupancy'),
                            Tab(text: 'Geocoding'),
                          ],
                        ),
                        Container(
                          height: 250,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.paperElevation2,
                                ),
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: CustomSpacing.four),
                                    Text(
                                      'Coming Soon!',
                                      style: CustomTypography.H6,
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                height: 200,
                                decoration: BoxDecoration(
                                  color: AppColors.paperElevation2,
                                ),
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: CustomSpacing.four),
                                    Text(
                                      'Coming Soon!',
                                      style: CustomTypography.H6,
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                height: 200,
                                decoration: BoxDecoration(
                                  color: AppColors.paperElevation2,
                                ),
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: CustomSpacing.four),
                                    Text(
                                      'Coming Soon!',
                                      style: CustomTypography.H6,
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                height: 200,
                                decoration: BoxDecoration(
                                  color: AppColors.paperElevation2,
                                ),
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: CustomSpacing.four),
                                    Text(
                                      'Geocode type',
                                      style: CustomTypography.Caption,
                                    ),
                                    SizedBox(height: CustomSpacing.two),
                                    Consumer<LocationProfileProvider>(
                                      builder: (context, provider, child) {
                                        // Check if locationType is a List and join items with a comma
                                        String locationTypeDisplay = 'N/A';
                                        if (provider.result != null) {
                                          if (provider.result!.locationType
                                              is String) {
                                            locationTypeDisplay =
                                                provider.result!.locationType;
                                          } else if (provider
                                              .result!.locationType is List) {
                                            locationTypeDisplay = (provider
                                                    .result!
                                                    .locationType as List)
                                                .join(', ');
                                          }
                                        }

                                        return Text(
                                          locationTypeDisplay,
                                          style:
                                              CustomTypography.Body1.copyWith(
                                            color: Theme.of(context)
                                                        .colorScheme
                                                        .brightness ==
                                                    Brightness.light
                                                ? AppColors.black
                                                : AppColors.white,
                                          ),
                                        );
                                      },
                                    ),
                                    SizedBox(height: CustomSpacing.four),
                                    Text(
                                      'Property type',
                                      style: CustomTypography.Caption,
                                    ),
                                    SizedBox(height: CustomSpacing.two),
                                    Consumer<LocationProfileProvider>(
                                        builder: (context, provider, child) {
                                      return Text(
                                        provider.result?.placeTypes?[0] ??
                                            'N/A',
                                        style: CustomTypography.Body1.copyWith(
                                          color: Theme.of(context)
                                                      .colorScheme
                                                      .brightness ==
                                                  Brightness.light
                                              ? AppColors.black
                                              : AppColors.white,
                                        ),
                                      );
                                    }),
                                    SizedBox(height: CustomSpacing.four),
                                    Text(
                                      'Ratings',
                                      style: CustomTypography.Caption,
                                    ),
                                    SizedBox(height: CustomSpacing.two),
                                    Center(
                                      child: Consumer<LocationProfileProvider>(
                                          builder: (context, provider, child) {
                                        return RatingSlider(
                                          progress: provider.result?.score ?? 0,
                                          total: 5,
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.9,
                                          progressColor: [
                                            Colors.red[800]!,
                                            Colors.orange[100]!,
                                            Colors.blue[200]!,
                                            Colors.green[200]!,
                                            Colors.yellow[100]!
                                          ][(provider.result?.score ?? 1) - 1],
                                          thumbColor: [
                                            Colors.red[800]!,
                                            Colors.orange[800]!,
                                            Colors.blue[700]!,
                                            Colors.green[800]!,
                                            Colors.yellow[700]!
                                          ][(provider.result?.score ?? 1) - 1],
                                          textColor: Colors.white,
                                        );
                                      }),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(),
                  _images.isNotEmpty ||
                          context
                                  .read<LocationProfileProvider>()
                                  .result
                                  ?.screenShots
                                  ?.isNotEmpty ==
                              true
                      ? Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: CustomSpacing.two),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Images',
                                    style: CustomTypography.H6,
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.add_a_photo),
                                    onPressed: _pickImage,
                                  ),
                                ],
                              ),
                              SizedBox(height: CustomSpacing.eight),
                              CarouselSlider.builder(
                                itemCount: _images.length +
                                    (context
                                            .read<LocationProfileProvider>()
                                            .result
                                            ?.screenShots
                                            ?.length ??
                                        0),
                                itemBuilder: (BuildContext context,
                                    int itemIndex, int pageViewIndex) {
                                  if (itemIndex < _images.length) {
                                    return GestureDetector(
                                      onTap: () {
                                        _showImagePreview(_images[itemIndex]);
                                      },
                                      child: Stack(
                                        children: [
                                          Image.file(
                                            _images[itemIndex],
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                          ),
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: IconButton(
                                              icon: Icon(Icons.delete,
                                                  color: Colors.red),
                                              onPressed: () {
                                                setState(() {
                                                  _images.removeAt(itemIndex);
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
                                    final screenshot = context
                                        .read<LocationProfileProvider>()
                                        .result
                                        ?.screenShots?[screenshotIndex];
                                    return GestureDetector(
                                      onTap: () {
                                        _showImagePreviewFromUrl(
                                            screenshot?.imageUrl ?? '');
                                      },
                                      child: Stack(
                                        children: [
                                          Image.network(
                                            screenshot?.imageUrl ?? '',
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                },
                                options: CarouselOptions(
                                  height: 200,
                                  autoPlay: true,
                                  enlargeCenterPage: true,
                                  aspectRatio: 2.0,
                                  onPageChanged: (index, reason) {
                                    setState(() {
                                      // Handle carousel page change if needed
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        )
                      : SizedBox(),
                  Divider(),
                  Consumer<LocationProfileProvider>(
                    builder: (context, provider, child) {
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: provider.subdestinations.length,
                        itemBuilder: (context, index) {
                          var subdestination = provider.subdestinations[index];
                          return CheckboxListTile(
                            value: subdestination.isChecked,
                            title: Text(subdestination.name ?? ''),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(subdestination.address ?? ''),
                                Chip(
                                  label: Text(subdestination.status == null ||
                                          subdestination.status == ""
                                      ? 'NOT ADDED'
                                      : subdestination.status!),
                                ),
                              ],
                            ),
                            onChanged: (bool? value) {
                              setState(() {
                                subdestination.isChecked = value ?? false;
                              });
                            },
                            secondary: IconButton(
                              icon: Icon(Icons.location_on),
                              onPressed: () {
                                _focusOnSubdestination(subdestination);
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                  SizedBox(height: CustomSpacing.eight),
                  Consumer<LocationProfileProvider>(
                      builder: (context, locationProfileProvider, child) {
                    return locationProfileProvider.subdestinations.isEmpty
                        ? SizedBox()
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 24.0),
                                child: locationProfileProvider.isLoading
                                    ? const CircularProgressIndicator()
                                    : CustomButton(
                                        type: ButtonType.elevated,
                                        onPressed: _addSelectedToSOV,
                                        child: Text(
                                          'Add to SOV',
                                          style:
                                              CustomTypography.Body1.copyWith(
                                                  fontWeight: FontWeight.w500),
                                        ),
                                      ),
                              ),
                            ],
                          );
                  }),
                  SizedBox(height: CustomSpacing.twentyFour),
                ],
              ),
            ),
          ],
        );
      },
    );
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

  Widget _buildGoogleSearchBar(BuildContext context) {
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
                  hintStyle: CustomTypography.Body1,
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
          var apiProvider =
              PlaceApiProvider(autoCompleteSuggestionSessionToken);
          return await apiProvider.fetchSuggestions(pattern, 'en');
        },
        itemBuilder: (context, suggestion) {
          return ListTile(
            title: Text(suggestion.description),
          );
        },
        onSelected: (suggestion) async {
          /* var placeApiProvider = PlaceApiProvider(autoCompleteSuggestionSessionToken);
          // print full details
          print("This is the suggestion$suggestion");
          final latLng = await placeApiProvider.getLatLngFromPlaceId(suggestion.placeId);
          */ /*_addMarker(latLng);
          final GoogleMapController controller = await _controller.future;
          controller.animateCamera(CameraUpdate.newLatLng(latLng));*/

          var placeApiProvider = PlaceApiProvider(Uuid().v4());
          // Get full place details
          final placeDetails =
              await placeApiProvider.getPlaceDetails(suggestion.placeId);
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
              "location_id": widget.locationId,
            }
          };
          bool result =
              await Provider.of<LocationProfileProvider>(context, listen: false)
                  .updateLocationDetails(
                      context,
                      widget.accountId,
                      widget.subAccountId,
                      widget.sovId,
                      widget.locationId,
                      data);
          if (result) {
            _getData();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Failed to update location details',
                  style: CustomTypography.Body1),
            ));
          }
        },
      ),
    );
  }

  Future<void> _goToTheInitialPin() async {
    final GoogleMapController controller = await _controller.future;
    await controller
        .animateCamera(CameraUpdate.newCameraPosition(_kGooglePlex));
  }

  void _onMarkerTapped(MarkerId markerId) {
    // Handle marker tap
    print('Marker Tapped: $markerId');
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          child: Wrap(
            children: <Widget>[
              Consumer<LocationProfileProvider>(
                builder: (context, locationProfileProvider, child) {
                  var subdestination = locationProfileProvider.subdestinations
                      .firstWhereOrNull(
                          (element) => element.id == markerId.value);

                  if (subdestination == null) {
                    print(
                        'No subdestination found for markerId: ${markerId.value}');
                    return SizedBox();
                  }

                  print(
                      'Subdestination found: ${subdestination.id}, Status: ${subdestination.status}');

                  return subdestination.status?.toLowerCase() == "added"
                      ? SizedBox()
                      : ListTile(
                          leading: locationProfileProvider.isLoading
                              ? const CircularProgressIndicator()
                              : Icon(Icons.add),
                          title:
                              Text('Add to SOV', style: CustomTypography.Body1),
                          onTap: () async {
                            await _addToSOV(markerId.value);
                            Navigator.pop(context);
                          },
                        );
                },
              ),
              Consumer<LocationProfileProvider>(
                builder: (context, locationProfileProvider, child) {
                  var subdestination = locationProfileProvider.subdestinations
                      .firstWhereOrNull(
                          (element) => element.id == markerId.value);

                  if (subdestination == null) {
                    print(
                        'No subdestination found for markerId: ${markerId.value}');
                    return SizedBox();
                  }

                  print(
                      'Subdestination found: ${subdestination.id}, Status: ${subdestination.status}');

                  return subdestination.status?.toLowerCase() != "added"
                      ? SizedBox()
                      : ListTile(
                          leading: locationProfileProvider.isLoading
                              ? const CircularProgressIndicator()
                              : Icon(Icons.delete),
                          title: Text('Remove Marker',
                              style: CustomTypography.Body1),
                          onTap: () async {
                            await _removeFromSOV(markerId.value);
                            Navigator.pop(context);
                          },
                        );
                },
              ),
            ],
          ),
        );
      },
    );
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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Sub-Destinations', style: CustomTypography.H6),
          content: const Text(
              'Do you want to get sub-destinations for this location?',
              style: CustomTypography.Body1),
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
                  widget.locationId,
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
    _nameController.text = provider.result?.locationName ?? '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Consumer<LocationProfileProvider>(
            builder: (context, locationProfileProvider, child) {
          return AlertDialog(
            title: Text('Edit Name', style: CustomTypography.H6),
            content: TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Enter the new name',
              ),
              style: CustomTypography.Body1,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Cancel', style: CustomTypography.Body1),
              ),
              TextButton(
                onPressed: () {
                  locationProfileProvider
                      .updateLocationName(
                    context,
                    widget.accountId,
                    widget.subAccountId,
                    widget.sovId,
                    widget.locationId,
                    _nameController.text,
                  )
                      .then((value) {
                    _getData();
                  });
                  Navigator.of(context).pop();
                },
                child: locationProfileProvider.isLoading
                    ? const CircularProgressIndicator()
                    : Text('Save', style: CustomTypography.Body1),
              ),
            ],
          );
        });
      },
    );
  }

  void _editAddress(LocationProfileProvider provider) {
    _addressController.text = provider.result?.address ?? '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Consumer<LocationProfileProvider>(
            builder: (context, locationProfileProvider, child) {
          return AlertDialog(
            title: Text('Edit address & run geocoding',
                style: CustomTypography.H5_Regular),
            content: TextField(
              controller: _addressController,
              decoration: InputDecoration(
                hintText: 'Enter the new address',
                border: OutlineInputBorder(),
              ),
              style: CustomTypography.Body1,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Cancel', style: CustomTypography.Body1),
              ),
              TextButton(
                onPressed: () {
                  locationProfileProvider
                      .updateLocationAddress(
                    context,
                    widget.accountId,
                    widget.subAccountId,
                    widget.sovId,
                    widget.locationId,
                    _addressController.text,
                  )
                      .then((value) {
                    _getData();
                  });
                  Navigator.of(context).pop();
                },
                child: locationProfileProvider.isLoading
                    ? const CircularProgressIndicator()
                    : Text('Save', style: CustomTypography.Body1),
              ),
            ],
          );
        });
      },
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
    var provider = Provider.of<LocationProfileProvider>(context, listen: false);
    var checkedSubdestinations =
        provider.subdestinations.where((sd) => sd.isChecked).toList();
    // Check for selections
    if (checkedSubdestinations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Please select at least one subdestination',
                style: CustomTypography.Body1)),
      );
      return;
    }

    await provider.addSelectedSubdestinationToSOV(
      context,
      widget.accountId,
      widget.subAccountId,
      widget.sovId,
      widget.locationId,
      checkedSubdestinations.map((sd) => sd.id!).toList(),
    );

    // Optionally, you can refresh the data or show a success message here
    _getData();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Selected subdestinations added to SOV',
              style: CustomTypography.Body1)),
    );
  }

  Future<void> _addToSOV(String subdestinationId) async {
    var provider = Provider.of<LocationProfileProvider>(context, listen: false);
    await provider.addSubdestinationToSOV(
      context,
      widget.accountId,
      widget.subAccountId,
      widget.sovId,
      widget.locationId,
      subdestinationId,
    );
  }

  Future<void> _removeFromSOV(String subdestinationId) async {
    var provider = Provider.of<LocationProfileProvider>(context, listen: false);
    await provider.removeSubdestinationFromSOV(
      context,
      widget.accountId,
      widget.subAccountId,
      widget.sovId,
      widget.locationId,
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
      setState(() {
        markers[markerId] = marker.copyWith(
          infoWindowParam: InfoWindow(
            title: subdestination.name,
            snippet: subdestination.address,
            onTap: () {
              _onMarkerTapped(markerId);
            },
          ),
        );
      });

      marker.onTap!();
    }
  }
}
