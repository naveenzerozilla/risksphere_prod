import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:RiskSphere/providers/news_feed_provider.dart';
import 'package:RiskSphere/screens/event/widgets/hazard_info_section.dart';
import 'package:RiskSphere/screens/event/widgets/image_filter_section.dart';
import 'package:RiskSphere/screens/listings/hazard_proto.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../design_system/components/custom_appbar.dart';

class NotificationMapScreen extends StatefulWidget {
  final Map<String, dynamic> notificationData;

  NotificationMapScreen({required this.notificationData});

  @override
  _NotificationMapScreenState createState() => _NotificationMapScreenState();
}


class _NotificationMapScreenState extends State<NotificationMapScreen> {
  late GoogleMapController _mapController;
  Set<Marker> _markers = {};
  Set<Marker> _allMarkers = {}; // Store all markers
  String? selectedDate;
  List<String> availableDates = [];
  bool _isLoading = true;
  String? mapUrl;
  String? selectedFilter; // Track the selected filter
  Map<String, int> impactCounts = {'High': 0, 'Medium': 0, 'Low': 0};
  bool _isExpanded = false;
  bool _showNotificationDot = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() {
      _isLoading = true;
    });

    final provider = Provider.of<NewsFeedProvider>(context, listen: false);

    // Fetch event dates
    await provider.fetchEventDate(eventId: widget.notificationData['eventId']);
    if (provider.eventDate.isNotEmpty) {
      final uniqueDates = provider.eventDate
          .map((e) => _formatDate(e['ddmmyyhhmm'] as String))
          .toSet();
      availableDates = uniqueDates.toList();
      selectedDate = availableDates.first;

      // Fetch event info for the first date
      await _fetchEventInfo(selectedDate!);
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _fetchEventInfo(String date) async {
    final provider = Provider.of<NewsFeedProvider>(context, listen: false);
    setState(() {
      _isLoading = true;
    });

    await provider.fetchEventInfo(eventId: widget.notificationData['eventId']);

    if (provider.eventInfo.isNotEmpty) {
      final result = provider.eventInfo;
      mapUrl = result['map_url'];

      // Reset impact counts and markers
      impactCounts = {'High': 0, 'Medium': 0, 'Low': 0};
      _allMarkers = result['locations_data'].map<Marker>((location) {
        final impact = _extractImpact(location['event']);
        if (impact != null && impactCounts.containsKey(impact)) {
          impactCounts[impact] = (impactCounts[impact] ?? 0) + 1;
        }
        return Marker(
          markerId: MarkerId(location['location_id']),
          position: LatLng(location['latitude'], location['longitude']),
          infoWindow: InfoWindow(
            title: location['location_name'],
            snippet: impact ?? 'No impact', // Show impact or fallback
          ),
        );
      }).toSet();

      _markers = _allMarkers; // Initialize _markers to all markers
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _filterMarkers(String label) {
    setState(() {
      if (selectedFilter == label) {
        // If filter is already selected, reset to show all markers
        selectedFilter = null;
        _markers = _allMarkers;
      } else {
        // Apply the filter
        selectedFilter = label;
        _markers = _allMarkers.where((marker) {
          final impact = marker.infoWindow.snippet; // Extract impact from snippet
          return impact == label;
        }).toSet();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: CustomAppBar(
          isExpanded: _isExpanded,
          showDropdown: true,
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
        body: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Column(
          children: [
            // Hazard Info Section with Date Dropdown
            HazardInfoSection(
              hazardName: "Event Hazard",
              selectedDate: selectedDate!,
              availableDates: availableDates,
              onDateChanged: _onDateChanged,
            ),

            // Map Container
            Expanded(
              child: Container(
                margin: EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.0),
                  color: Colors.grey.shade100,
                ),
                clipBehavior: Clip.antiAlias,
                child: GoogleMap(
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  markers: _markers,
                  initialCameraPosition: CameraPosition(
                    target: LatLng(20.5937, 78.9629), // Example: India
                    zoom: 5.0,
                  ),
                  // tileOverlays: {
                  //   if (mapUrl != null)
                  //     TileOverlay(
                  //       tileOverlayId: TileOverlayId('map'),
                  //       tileProvider: CustomTileProvider(baseUrl: mapUrl!),
                  //     ),
                  // },
                ),
              ),
            ),

            // Filter Section
            ImpactFilterSection(
              filters: [
                {'label': 'High', 'color': Colors.red, 'count': impactCounts['High'] ?? 0},
                {'label': 'Medium', 'color': Colors.orange, 'count': impactCounts['Medium'] ?? 0},
                {'label': 'Low', 'color': Colors.green, 'count': impactCounts['Low'] ?? 0},
              ],
              selectedFilter: selectedFilter,
              onFilterSelected: _filterMarkers,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String ddmmyyhhmm) {
    final day = ddmmyyhhmm.substring(0, 2);
    final month = ddmmyyhhmm.substring(2, 4);
    final year = '20${ddmmyyhhmm.substring(4, 6)}';
    final hour = ddmmyyhhmm.substring(6, 8);
    final minute = ddmmyyhhmm.substring(8, 10);

    final parsedDate = DateTime.parse('$year-$month-$day $hour:$minute');
    return DateFormat('MM/dd/yyyy HH:mm:ss').format(parsedDate);
  }

  String? _extractImpact(Map<String, dynamic> json) {
    for (final entry in json.entries) {
      if (entry.key == 'impact') {
        return entry.value.toString();
      } else if (entry.value is Map) {
        final impact = _extractImpact(entry.value as Map<String, dynamic>);
        if (impact != null) return impact;
      }
    }
    return null;
  }


  void _onDateChanged(String? newDate) {
    if (newDate != null) {
      setState(() {
        selectedDate = newDate;
        _fetchEventInfo(newDate);
      });
    }
  }

}
