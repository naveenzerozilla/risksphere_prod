import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_places_autocomplete_text_field/google_places_autocomplete_text_field.dart';
import 'package:green/constants/enums.dart';
import 'package:green/design_system/primitives/app_colors.dart';
import 'package:green/design_system/primitives/custom_typography.dart';
import 'package:green/design_system/primitives/utilities/custom_spacing.dart';
import 'package:green/providers/place_api_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../design_system/components/custom_button.dart';
import '../../providers/theme_provider.dart';
import '../../design_system/components/custom_appbar.dart';
import '../../design_system/components/custom_drawer.dart';

class LocationProfile extends StatefulWidget {
  const LocationProfile({super.key});

  @override
  State<LocationProfile> createState() => _LocationProfileState();
}

class _LocationProfileState extends State<LocationProfile>
    with SingleTickerProviderStateMixin {
  // App Bar
  bool _isExpanded = false;
  bool _showNotificationDot = true;

  // Google Maps
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};

  bool _isAddingMarker = false;
  bool _isTaggingSubDestination = false;

  TabController? _tabController;
  TextEditingController _nameController = TextEditingController();
  TextEditingController searchController = TextEditingController();
  List<Suggestion> _searchLocations = [];

  void _add() {
    var markerIdVal = "hardcoded_id";
    final MarkerId markerId = MarkerId(markerIdVal);

    // creating a new MARKER
    final Marker marker = Marker(
      markerId: markerId,
      position: LatLng(40.71381056, -111.8887178),
      infoWindow: InfoWindow(title: markerIdVal, snippet: '*'),
      onTap: () {
        _onMarkerTapped(markerId);
      },
    );

    setState(() {
      // adding a new marker to map
      markers[markerId] = marker;
    });
  }

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(40.7138056, -111.889),
    zoom: 16,
  );

  static const CameraPosition _kLake = CameraPosition(
      bearing: 192.8334901395799,
      target: LatLng(37.43296265331129, -122.08832357078792),
      tilt: 59.440717697143555,
      zoom: 19.151926040649414);

  @override
  void initState() {
    _add();
    _tabController = TabController(length: 4, vsync: this);
    super.initState();
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
            // Google Maps
            /*GoogleMap(
              mapType: MapType.normal,
              markers: Set<Marker>.of(markers.values),
              initialCameraPosition: _kGooglePlex,
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
              },
            ),*/
            GoogleMap(
              mapType: MapType.normal,
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
                  : _isTaggingSubDestination
                  ? _handleSubDestinationTap
                  : null,
            ),
            // Persistent Bottom Sheet
            _locationProfileBody(),
          ],
        ),
        floatingActionButtonLocation:
            FloatingActionButtonLocation.startTop,
        floatingActionButton: /*FloatingActionButton(
          onPressed: _goToTheInitialPin,
          child: const Icon(Icons.location_searching),
        ),*/ Padding(
          padding: const EdgeInsets.only(top:260.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            FloatingActionButton.small(
              onPressed: _toggleTagSubDestinationMode,
              child: _isTaggingSubDestination
                  ? const Icon(Icons.cancel)
                  : const Icon(Icons.add_location_alt),
              backgroundColor: Colors.grey,
            ),
            const SizedBox(height: 16.0),
            FloatingActionButton.small(
              onPressed: _toggleAddMarkerMode,
              child: _isAddingMarker
                  ? const Icon(Icons.cancel)
                  : const Icon(Icons.add_location),
            ),
            const SizedBox(height: 16.0),
            FloatingActionButton.small(
              onPressed: _toggleAddMarkerMode,
              child: Icon(Icons.send),
            ),
            const SizedBox(height: 16.0),
            FloatingActionButton.small(
              onPressed: _searchWithPlacesAPI,
              child: Icon(Icons.search),
            ),
          ],
          ),
        ),
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
                        // Logo
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            SvgPicture.asset(
                              'assets/images/jpmorganlogo.svg',
                              semanticsLabel: 'J.P.Morgan',
                              height: 30,
                            ),
                          ],
                        ),
                        SizedBox(height: CustomSpacing.two),
                        Text(
                          'JP Morgan - RS/24/Q1/000002',
                          style: CustomTypography.Caption,
                        ),
                        SizedBox(height: CustomSpacing.two),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'J P Morgan, South Salt Lake, 2610 S State St, Salt Lake City, UT, 84115-3119, USA',
                                style: CustomTypography.H6.copyWith(height: 1.5),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.edit, color: AppColors.primaryMain),
                              onPressed: _editName,
                            ),
                          ],
                        ),

                        SizedBox(height: CustomSpacing.two),
                        Text(
                          'J P Morgan, South Salt Lake, 2610 S State St, Salt Lake City, UT, 84115-3119, USA',
                          style: CustomTypography.Caption,
                        ),
                        SizedBox(height: CustomSpacing.two),

                      ],
                    ),
                  ),
                  Divider(),
                  Container(
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
                        Text(
                          'The JP Morgan Bengaluru Head Office is built with high-quality materials, advanced safety features, and sustainable elements, demonstrating a commitment to durability, security, and environmental responsibility.',
                          style: CustomTypography.Caption,
                        ),
                      ],
                    ),
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
                                    Text(
                                      'GEOMETRIC_CENTER',
                                      style: CustomTypography.Body1.copyWith(
                                        color: Theme.of(context).colorScheme.brightness == Brightness.light
                                            ? AppColors.black
                                            : AppColors.white,
                                      ),
                                    ),
                                    SizedBox(height: CustomSpacing.four),
                                    Text(
                                      'Property type',
                                      style: CustomTypography.Caption,
                                    ),
                                    SizedBox(height: CustomSpacing.two),
                                    Text(
                                      'premise',
                                      style: CustomTypography.Body1.copyWith(
                                        color: Theme.of(context).colorScheme.brightness == Brightness.light
                                            ? AppColors.black
                                            : AppColors.white,
                                      ),
                                    ),
                                    SizedBox(height: CustomSpacing.four),
                                    Text(
                                      'Ratings',
                                      style: CustomTypography.Caption,
                                    ),
                                    SizedBox(height: CustomSpacing.two),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: LinearProgressIndicator(
                                            minHeight: 10,
                                            value: 0.8,
                                            color: Theme.of(context).colorScheme.primary,
                                            backgroundColor: Theme.of(context).colorScheme.inverseSurface,
                                          ),
                                        ),
                                        SizedBox(width: CustomSpacing.two),
                                        Text(
                                          '4/5',
                                          style: CustomTypography.Caption,
                                        ),
                                      ],
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
                ],
              ),
            ),
          ],
        );
      },
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
              ListTile(
                leading: Icon(Icons.delete),
                title: Text('Remove Marker'),
                onTap: () {
                  Navigator.pop(context);
                  _removeMarker(markerId);
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
          content: const Text('Do you want to tag this building as your location?'),
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

  void _handleSubDestinationTap(LatLng latLng) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Tag Sub-Destination'),
          content: const Text('Do you want to tag a sub-destination at this location?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _addSubDestinationMarker(latLng);
                Navigator.of(context).pop();
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _addSubDestinationMarker(LatLng latLng) {
    var markerIdVal = "sub_destination_${DateTime.now().millisecondsSinceEpoch}";
    final MarkerId markerId = MarkerId(markerIdVal);

    final Marker marker = Marker(
      markerId: markerId,
      position: latLng,
      infoWindow: InfoWindow(title: markerIdVal, snippet: '*'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      onTap: () {
        _onMarkerTapped(markerId);
      },
    );

    setState(() {
      markers[markerId] = marker;
    });
  }

  void _editName() {
    _nameController.text = 'J P Morgan, South Salt Lake, 2610 S State St, Salt Lake City, UT, 84115-3119, USA'; // Set the initial value

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Name'),
          content: TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'Enter the new name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Update the name with the edited value
                setState(() {
                  // Update your UI with the edited name
                });
                Navigator.of(context).pop();
              },
              child: Text('Save'),
            ),
          ],
        );
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
                  _searchLocations = await searchLocations(textEditingValue.text);
                  // If single suggestion is found, select it automatically
                  if (_searchLocations.length == 1) {
                    // Select the first suggestion
                    searchController.text = _searchLocations.first.description;
                    // Add the marker
                    try {
                      final placeId = _searchLocations.first.placeId;
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
            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
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

  Future<void> addMarkerFromPlaceId(Suggestion suggestion, BuildContext context) async {
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

}
