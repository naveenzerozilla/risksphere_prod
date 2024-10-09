import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:green/design_system/primitives/app_colors.dart';
import 'package:location/location.dart';

import '../../../constants/enums.dart';
import '../../../design_system/components/custom_button.dart';
import '../../../design_system/primitives/custom_typography.dart';

class MapFullScreen extends StatefulWidget {
  const MapFullScreen({super.key});

  @override
  State<MapFullScreen> createState() => _MapFullScreenState();
}

class _MapFullScreenState extends State<MapFullScreen> {
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(40.7138056, -111.889),
    zoom: 16,
  );

  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};
  LocationData? currentLocation;
  Location location = Location();
  MapType _currentMapType = MapType.normal;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    final GoogleMapController controller = await _controller.future;
    location.onLocationChanged.listen((LocationData locationData) {
      setState(() {
        currentLocation = locationData;
        controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(locationData.latitude!, locationData.longitude!),
              zoom: 16,
            ),
          ),
        );
      });
    });
  }

  void _addMarker(LatLng position) {
    final MarkerId markerId = MarkerId('selected_location');
    final Marker marker = Marker(
      markerId: markerId,
      position: position,
      infoWindow: InfoWindow(title: 'Selected Location'),
    );

    setState(() {
      markers.clear(); // Clear existing markers
      markers[markerId] = marker; // Add new marker
    });
  }

  void _toggleMapType() {
    setState(() {
      _currentMapType = _currentMapType == MapType.normal ? MapType.satellite : MapType.normal;
    });
  }

  @override
  Widget build(BuildContext context) {
    var typography = CustomTypography(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Map Full Screen'),
      ),
      body: Stack(
        children: [
          GoogleMap(
            mapType: _currentMapType,
            markers: Set<Marker>.of(markers.values),
            initialCameraPosition: _kGooglePlex,
            myLocationEnabled: true,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
            gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
              Factory<OneSequenceGestureRecognizer>(
                    () => EagerGestureRecognizer(),
              ),
            },
            onTap: (LatLng position) {
              _addMarker(position);
            },
          ),
          Positioned(
            top: 10,
            left: 4,
            child: FloatingActionButton.small(
              onPressed: _toggleMapType,
              materialTapTargetSize: MaterialTapTargetSize.padded,
              backgroundColor: AppColors.paperElavation25,
              child: const Icon(Icons.layers, size: 18.0),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            FloatingActionButton.extended(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: Icon(Icons.cancel),
              label: Text('Cancel', style: typography.ButtonLarge),
              backgroundColor: AppColors.paperElavation25,
            ),
            FloatingActionButton.extended(
              onPressed: () {
                // Submit logic
              },
              icon: Icon(Icons.check),
              label: Text('Submit', style: typography.ButtonLarge),
              backgroundColor: AppColors.paperElavation25,
            ),
          ],
        ),
      ),
    );
  }
}
