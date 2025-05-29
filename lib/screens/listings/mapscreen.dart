import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapScreenpage extends StatefulWidget {
  @override
  _MapScreenpageState createState() => _MapScreenpageState();
}

class _MapScreenpageState extends State<MapScreenpage> {
  final GlobalKey _mapKey = GlobalKey();
  GoogleMapController? _mapController;

  Future<void> _captureMapScreenshot() async {
    try {
      final imageBytes = await _mapController?.takeSnapshot();
      if (imageBytes != null) {
        // Do something with the image bytes (e.g., show in dialog or save)
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            content: Image.memory(imageBytes),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('Error capturing screenshot: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Map Screenshot'),
        actions: [
          IconButton(
            icon: Icon(Icons.camera_alt),
            onPressed: _captureMapScreenshot,
          ),
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(37.42796133580664, -122.085749655962),
          zoom: 14.4746,
        ),
        onMapCreated: (controller) {
          _mapController = controller;
        },
      ),
    );
  }
}
