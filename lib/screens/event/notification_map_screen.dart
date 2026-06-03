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
import '../../providers/custom_tile_providers.dart';

class NotificationMapScreen extends StatefulWidget {
  final Map<String, dynamic> notificationData;

  NotificationMapScreen({required this.notificationData});

  @override
  _NotificationMapScreenState createState() => _NotificationMapScreenState();
}

class _NotificationMapScreenState extends State<NotificationMapScreen> {
  late GoogleMapController _mapController;
  Set<Marker> _markers = {};
  Set<Marker> _allMarkers = {};
  String? selectedDate;
  List<String> availableDates = [];
  bool _isLoading = true;
  String? mapUrl;
  String? _currentMapUrl; // ✅ track last-built URL
  Set<TileOverlay> _tileOverlays =
      {}; // ✅ stored as field, never rebuilt in build()
  String? selectedFilter;
  Map<String, int> impactCounts = {'High': 0, 'Medium': 0, 'Low': 0};
  bool _isExpanded = false;
  bool _showNotificationDot = true;

  late double _initialLat;
  late double _initialLng;
  late LatLng _initialMapCenter;

  @override
  void initState() {
    super.initState();

    final DateTime date =
        widget.notificationData['timestamp'] ?? DateTime.now();

    selectedDate = DateFormat('MMM dd, yyyy HH:mm').format(date);
    availableDates = [selectedDate!];

    _initialLat = widget.notificationData['lat'] ?? 20.5937;
    _initialLng = widget.notificationData['long'] ?? 78.9629;
    _initialMapCenter = LatLng(_initialLat, _initialLng);

    debugPrint("📍 Map Center: $_initialMapCenter");

    _initialize();
  }

  // ✅ Only call this when the URL actually changes — not on every rebuild
  void _buildTileOverlay(String? url) {
    if (url == null || url.isEmpty) {
      if (_tileOverlays.isNotEmpty) {
        setState(() => _tileOverlays = {});
      }
      return;
    }

    // Same URL — don't recreate, overlay is already alive
    if (url == _currentMapUrl) return;

    _currentMapUrl = url;
    setState(() {
      _tileOverlays = {
        TileOverlay(
          tileOverlayId: const TileOverlayId('map'),
          tileProvider: CustomTileProvider1(baseUrl: url),
          fadeIn: true,
          // smooth tile appearance
          transparency: 0.0,
          zIndex: 1,
        ),
      };
    });
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = true);
    await _fetchEventInfo();
    setState(() => _isLoading = false);
  }

  Future<void> _fetchEventInfo() async {
    final provider = Provider.of<NewsFeedProvider>(context, listen: false);
    final eventId = widget.notificationData['eventId'];

    print("EVENT ID 👉 $eventId");

    setState(() => _isLoading = true);

    await provider.fetchEventInfo(eventId: eventId);

    final result = provider.eventInfo;

    if (result.isNotEmpty) {
      String? fetchedMapUrl = result['map_url'];

      if (fetchedMapUrl == null || fetchedMapUrl.isEmpty) {
        fetchedMapUrl = await provider.fetchMapUrl(eventId);
      }

      print("FINAL MAP URL 👉 $fetchedMapUrl");

      Set<Marker> markers =
          (result['locations_data'] as List).map<Marker>((location) {
        return Marker(
          markerId: MarkerId(location['location_id']),
          position: LatLng(location['latitude'], location['longitude']),
          infoWindow: InfoWindow(
            title: location['location_name'],
          ),
        );
      }).toSet();

      setState(() {
        mapUrl = fetchedMapUrl;
        _markers = markers;
        _allMarkers = markers;
        _isLoading = false;
      });

      //  Build overlay AFTER setState — only if URL changed
      _buildTileOverlay(fetchedMapUrl);
    } else {
      print(" EVENT INFO EMPTY");
      setState(() => _isLoading = false);
    }
  }

  void _filterMarkers(String label) {
    setState(() {
      if (selectedFilter == label) {
        selectedFilter = null;
        _markers = _allMarkers;
      } else {
        selectedFilter = label;
        _markers = _allMarkers.where((marker) {
          final impact = marker.infoWindow.snippet;
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
            setState(() => _isExpanded = isExpanded);
          },
          onSearchPressed: () {
            setState(() => _isExpanded = !_isExpanded);
          },
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  HazardInfoSection(
                    hazardName:
                        widget.notificationData['title'] ?? "Event Hazard",
                    selectedDate: selectedDate!,
                    availableDates: availableDates,
                    onDateChanged: (value) {
                      setState(() => selectedDate = value);
                      _fetchEventInfo();
                    },
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        // ✅ MAP
                        Container(
                          margin: const EdgeInsets.all(16.0),
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
                              target: _initialMapCenter,
                              zoom: 5.0,
                            ),
                            tileOverlays: _tileOverlays,
                            mapToolbarEnabled: false,
                            mapType: MapType.normal,
                            myLocationButtonEnabled: true,
                            zoomControlsEnabled: true,
                          ),
                        ),

                        // 🔥 LEGEND BOX (BOTTOM LEFT)
                        Positioned(
                          bottom: 30,
                          left: 30,
                          child: _buildLegend(),
                        ),
                      ],
                    ),
                  ),
                  // Expanded(
                  //   child: Container(
                  //     margin: const EdgeInsets.all(16.0),
                  //     decoration: BoxDecoration(
                  //       borderRadius: BorderRadius.circular(20.0),
                  //       color: Colors.grey.shade100,
                  //     ),
                  //     clipBehavior: Clip.antiAlias,
                  //     child: GoogleMap(
                  //       onMapCreated: (controller) {
                  //         _mapController = controller;
                  //       },
                  //       markers: _markers,
                  //       initialCameraPosition: CameraPosition(
                  //         target: _initialMapCenter,
                  //         zoom: 5.0,
                  //       ),
                  //       // ✅ Use stored field — never inline TileOverlay() here
                  //       tileOverlays: _tileOverlays,
                  //       mapToolbarEnabled: false,
                  //       mapType: MapType.normal,
                  //       myLocationButtonEnabled: true,
                  //       zoomControlsEnabled: true,
                  //     ),
                  //   ),
                  // ),
                  ImpactFilterSection(
                    filters: [
                      {
                        'label': 'High',
                        'color': Colors.red,
                        'count': impactCounts['High'] ?? 0
                      },
                      {
                        'label': 'Moderate',
                        'color': Colors.orange,
                        'count': impactCounts['Medium'] ?? 0
                      },
                      {
                        'label': 'Low',
                        'color': Colors.green,
                        'count': impactCounts['Low'] ?? 0
                      },
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

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Area (sq km)",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),

          // 🔥 EXACT WEB GRADIENT
          Container(
            height: 12,
            width: 180,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(6)),
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0000FF), // blue
                  Color(0xFF00FFFF), // cyan
                  Color(0xFF00FF00), // green
                  Color(0xFFFFFF00), // yellow
                  Color(0xFFFF0000), // red
                ],
              ),
            ),
          ),

          const SizedBox(height: 6),

          Container(
            width: 180, // 👈 SAME as gradient width
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text("0", style: TextStyle(color: Colors.white, fontSize: 10)),
                Text("25k",
                    style: TextStyle(color: Colors.white, fontSize: 10)),
                Text("50k",
                    style: TextStyle(color: Colors.white, fontSize: 10)),
                Text("75k",
                    style: TextStyle(color: Colors.white, fontSize: 10)),
                Text("100k+",
                    style: TextStyle(color: Colors.white, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:RiskSphere/providers/news_feed_provider.dart';
// import 'package:RiskSphere/screens/event/widgets/hazard_info_section.dart';
// import 'package:RiskSphere/screens/event/widgets/image_filter_section.dart';
// import 'package:RiskSphere/screens/listings/hazard_proto.dart';
// import 'package:provider/provider.dart';
// import 'package:intl/intl.dart';
//
// import '../../design_system/components/custom_appbar.dart';
// import '../../providers/custom_tile_providers.dart';
//
// class NotificationMapScreen extends StatefulWidget {
//   final Map<String, dynamic> notificationData;
//
//   NotificationMapScreen({required this.notificationData});
//
//   @override
//   _NotificationMapScreenState createState() => _NotificationMapScreenState();
// }
//
// class _NotificationMapScreenState extends State<NotificationMapScreen> {
//   late GoogleMapController _mapController;
//   Set<Marker> _markers = {};
//   Set<Marker> _allMarkers = {}; // Store all markers
//   String? selectedDate;
//   List<String> availableDates = [];
//   bool _isLoading = true;
//   String? mapUrl;
//   String? selectedFilter; // Track the selected filter
//   Map<String, int> impactCounts = {'High': 0, 'Medium': 0, 'Low': 0};
//   bool _isExpanded = false;
//   bool _showNotificationDot = true;
//
//   // ✅ ADD THESE PROPERTIES FOR MAP CENTER
//   late double _initialLat;
//   late double _initialLng;
//   late LatLng _initialMapCenter;
//
//   @override
//   void initState() {
//     super.initState();
//
//     final DateTime date =
//         widget.notificationData['timestamp'] ?? DateTime.now();
//
//     selectedDate = DateFormat('MMM dd, yyyy HH:mm').format(date);
//
//     availableDates = [selectedDate!];
//
//     // ✅ EXTRACT LAT/LONG FROM notificationData
//     _initialLat = widget.notificationData['lat'] ?? 20.5937;
//     _initialLng = widget.notificationData['long'] ?? 78.9629;
//     _initialMapCenter = LatLng(_initialLat, _initialLng);
//
//     debugPrint("📍 Map Center: $_initialMapCenter");
//
//     _initialize();
//   }
//
//   Future<void> _initialize() async {
//     setState(() {
//       _isLoading = true;
//     });
//
//     await _fetchEventInfo();
//
//     setState(() {
//       _isLoading = false;
//     });
//   }
//
//   Future<void> _fetchEventInfo() async {
//     final provider = Provider.of<NewsFeedProvider>(context, listen: false);
//
//     final eventId = widget.notificationData['eventId'];
//
//     print("EVENT ID 👉 $eventId");
//
//     setState(() {
//       _isLoading = true;
//     });
//
//     // 🔥 CALL MAIN API
//     await provider.fetchEventInfo(eventId: eventId);
//
//     final result = provider.eventInfo;
//
//     if (result.isNotEmpty) {
//       String? fetchedMapUrl = result['map_url'];
//
//       // 🔥 FALLBACK API (VERY IMPORTANT)
//       if (fetchedMapUrl == null || fetchedMapUrl.isEmpty) {
//         fetchedMapUrl = await provider.fetchMapUrl(eventId);
//       }
//
//       print("FINAL MAP URL 👉 $fetchedMapUrl");
//
//       // 🔥 CREATE MARKERS
//       Set<Marker> markers =
//           (result['locations_data'] as List).map<Marker>((location) {
//         return Marker(
//           markerId: MarkerId(location['location_id']),
//           position: LatLng(location['latitude'], location['longitude']),
//           infoWindow: InfoWindow(
//             title: location['location_name'],
//           ),
//         );
//       }).toSet();
//
//       // ✅ UPDATE UI PROPERLY
//       setState(() {
//         mapUrl = fetchedMapUrl;
//         _markers = markers;
//         _allMarkers = markers;
//         _isLoading = false;
//       });
//     } else {
//       print("❌ EVENT INFO EMPTY");
//
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }
//
//   void _filterMarkers(String label) {
//     setState(() {
//       if (selectedFilter == label) {
//         // If filter is already selected, reset to show all markers
//         selectedFilter = null;
//         _markers = _allMarkers;
//       } else {
//         // Apply the filter
//         selectedFilter = label;
//         _markers = _allMarkers.where((marker) {
//           final impact =
//               marker.infoWindow.snippet; // Extract impact from snippet
//           return impact == label;
//         }).toSet();
//       }
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       child: Scaffold(
//         appBar: CustomAppBar(
//           isExpanded: _isExpanded,
//           showDropdown: true,
//           showNotificationDot: _showNotificationDot,
//           onExpandPressed: (isExpanded) {
//             setState(() {
//               _isExpanded = isExpanded;
//             });
//           },
//           onSearchPressed: () {
//             setState(() {
//               _isExpanded = !_isExpanded;
//             });
//           },
//         ),
//         body: _isLoading
//             ? Center(child: CircularProgressIndicator())
//             : Column(
//                 children: [
//                   // Hazard Info Section with Date Dropdown
//                   HazardInfoSection(
//                     hazardName:
//                         widget.notificationData['title'] ?? "Event Hazard",
//                     selectedDate: selectedDate!,
//                     availableDates: availableDates,
//                     onDateChanged: (value) {
//                       setState(() {
//                         selectedDate = value;
//                         _fetchEventInfo();
//                       });
//                     },
//                   ),
//
//                   // Map Container
//                   Expanded(
//                     child: Container(
//                         margin: EdgeInsets.all(16.0),
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.circular(20.0),
//                           color: Colors.grey.shade100,
//                         ),
//                         clipBehavior: Clip.antiAlias,
//                         child: GoogleMap(
//                           // key: ValueKey(mapUrl),
//                           onMapCreated: (controller) {
//                             _mapController = controller;
//                           },
//                           markers: _markers,
//                           // ✅ FIXED: Use dynamic map center from notificationData
//                           initialCameraPosition: CameraPosition(
//                             target: _initialMapCenter,
//                             // 📍 Uses lat/long from notificationData
//                             zoom: 5.0,
//                           ),
//                           tileOverlays: mapUrl != null && mapUrl!.isNotEmpty
//                               ? {
//                                   TileOverlay(
//                                     tileOverlayId: const TileOverlayId('map'),
//                                     tileProvider:
//                                         CustomTileProvider1(baseUrl: mapUrl!),
//                                   ),
//                                 }
//                               : {},
//
//                           mapType: MapType.normal,
//                           myLocationButtonEnabled: true,
//                           zoomControlsEnabled: true,
//                         )),
//                   ),
//                   ImpactFilterSection(
//                     filters: [
//                       {
//                         'label': 'High',
//                         'color': Colors.red,
//                         'count': impactCounts['High'] ?? 0
//                       },
//                       {
//                         'label': 'Modurate',
//                         'color': Colors.orange,
//                         'count': impactCounts['Medium'] ?? 0
//                       },
//                       {
//                         'label': 'Low',
//                         'color': Colors.green,
//                         'count': impactCounts['Low'] ?? 0
//                       },
//                     ],
//                     selectedFilter: selectedFilter,
//                     onFilterSelected: _filterMarkers,
//                   ),
//                 ],
//               ),
//       ),
//     );
//   }
//
//   String _formatDate(String ddmmyyhhmm) {
//     final day = ddmmyyhhmm.substring(0, 2);
//     final month = ddmmyyhhmm.substring(2, 4);
//     final year = '20${ddmmyyhhmm.substring(4, 6)}';
//     final hour = ddmmyyhhmm.substring(6, 8);
//     final minute = ddmmyyhhmm.substring(8, 10);
//
//     final parsedDate = DateTime.parse('$year-$month-$day $hour:$minute');
//     return DateFormat('MM/dd/yyyy HH:mm:ss').format(parsedDate);
//   }
//
//   String? _extractImpact(Map<String, dynamic> json) {
//     for (final entry in json.entries) {
//       if (entry.key == 'impact') {
//         return entry.value.toString();
//       } else if (entry.value is Map) {
//         final impact = _extractImpact(entry.value as Map<String, dynamic>);
//         if (impact != null) return impact;
//       }
//     }
//     return null;
//   }
// }
//
// // import 'dart:convert';
// // import 'package:flutter/material.dart';
// // import 'package:google_maps_flutter/google_maps_flutter.dart';
// // import 'package:RiskSphere/providers/news_feed_provider.dart';
// // import 'package:RiskSphere/screens/event/widgets/hazard_info_section.dart';
// // import 'package:RiskSphere/screens/event/widgets/image_filter_section.dart';
// // import 'package:RiskSphere/screens/listings/hazard_proto.dart';
// // import 'package:provider/provider.dart';
// // import 'package:intl/intl.dart';
// //
// // import '../../design_system/components/custom_appbar.dart';
// // import '../../providers/custom_tile_providers.dart';
// //
// // class NotificationMapScreen extends StatefulWidget {
// //   final Map<String, dynamic> notificationData;
// //
// //   NotificationMapScreen({required this.notificationData});
// //
// //   @override
// //   _NotificationMapScreenState createState() => _NotificationMapScreenState();
// // }
// //
// // class _NotificationMapScreenState extends State<NotificationMapScreen> {
// //   late GoogleMapController _mapController;
// //   Set<Marker> _markers = {};
// //   Set<Marker> _allMarkers = {}; // Store all markers
// //   String? selectedDate;
// //   List<String> availableDates = [];
// //   bool _isLoading = true;
// //   String? mapUrl;
// //   String? selectedFilter; // Track the selected filter
// //   Map<String, int> impactCounts = {'High': 0, 'Medium': 0, 'Low': 0};
// //   bool _isExpanded = false;
// //   bool _showNotificationDot = true;
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //
// //     final DateTime date =
// //         widget.notificationData['timestamp'] ?? DateTime.now();
// //
// //     selectedDate = DateFormat('MMM dd, yyyy HH:mm').format(date);
// //
// //     availableDates = [selectedDate!];
// //
// //     _initialize();
// //   }
// //
// //   Future<void> _initialize() async {
// //     setState(() {
// //       _isLoading = true;
// //     });
// //
// //     await _fetchEventInfo();
// //
// //     setState(() {
// //       _isLoading = false;
// //     });
// //   }
// //
// //   Future<void> _fetchEventInfo() async {
// //     final provider = Provider.of<NewsFeedProvider>(context, listen: false);
// //
// //     final eventId = widget.notificationData['eventId'];
// //
// //     print("EVENT ID 👉 $eventId");
// //
// //     setState(() {
// //       _isLoading = true;
// //     });
// //
// //     // 🔥 CALL MAIN API
// //     await provider.fetchEventInfo(eventId: eventId);
// //
// //     final result = provider.eventInfo;
// //
// //     if (result.isNotEmpty) {
// //       String? fetchedMapUrl = result['map_url'];
// //
// //       // 🔥 FALLBACK API (VERY IMPORTANT)
// //       if (fetchedMapUrl == null || fetchedMapUrl.isEmpty) {
// //         fetchedMapUrl = await provider.fetchMapUrl(eventId);
// //       }
// //
// //       print("FINAL MAP URL 👉 $fetchedMapUrl");
// //
// //       // 🔥 CREATE MARKERS
// //       Set<Marker> markers =
// //           (result['locations_data'] as List).map<Marker>((location) {
// //         return Marker(
// //           markerId: MarkerId(location['location_id']),
// //           position: LatLng(location['latitude'], location['longitude']),
// //           infoWindow: InfoWindow(
// //             title: location['location_name'],
// //           ),
// //         );
// //       }).toSet();
// //
// //       // ✅ UPDATE UI PROPERLY
// //       setState(() {
// //         mapUrl = fetchedMapUrl;
// //         _markers = markers;
// //         _allMarkers = markers;
// //         _isLoading = false;
// //       });
// //     } else {
// //       print("❌ EVENT INFO EMPTY");
// //
// //       setState(() {
// //         _isLoading = false;
// //       });
// //     }
// //   }
// //
// //   void _filterMarkers(String label) {
// //     setState(() {
// //       if (selectedFilter == label) {
// //         // If filter is already selected, reset to show all markers
// //         selectedFilter = null;
// //         _markers = _allMarkers;
// //       } else {
// //         // Apply the filter
// //         selectedFilter = label;
// //         _markers = _allMarkers.where((marker) {
// //           final impact =
// //               marker.infoWindow.snippet; // Extract impact from snippet
// //           return impact == label;
// //         }).toSet();
// //       }
// //     });
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return SafeArea(
// //       child: Scaffold(
// //         appBar: CustomAppBar(
// //           isExpanded: _isExpanded,
// //           showDropdown: true,
// //           showNotificationDot: _showNotificationDot,
// //           onExpandPressed: (isExpanded) {
// //             setState(() {
// //               _isExpanded = isExpanded;
// //             });
// //           },
// //           onSearchPressed: () {
// //             setState(() {
// //               _isExpanded = !_isExpanded;
// //             });
// //           },
// //         ),
// //         body: _isLoading
// //             ? Center(child: CircularProgressIndicator())
// //             : Column(
// //                 children: [
// //                   // Hazard Info Section with Date Dropdown
// //                   HazardInfoSection(
// //                     hazardName:
// //                         widget.notificationData['title'] ?? "Event Hazard",
// //                     selectedDate: selectedDate!,
// //                     availableDates: availableDates,
// //                     onDateChanged: (value) {
// //                       setState(() {
// //                         selectedDate = value;
// //                         _fetchEventInfo();
// //                       });
// //                     },
// //                   ),
// //
// //                   // Map Container
// //                   Expanded(
// //                     child: Container(
// //                         margin: EdgeInsets.all(16.0),
// //                         decoration: BoxDecoration(
// //                           borderRadius: BorderRadius.circular(20.0),
// //                           color: Colors.grey.shade100,
// //                         ),
// //                         clipBehavior: Clip.antiAlias,
// //                         child: GoogleMap(
// //                           // key: ValueKey(mapUrl),
// //                           onMapCreated: (controller) {
// //                             _mapController = controller;
// //                           },
// //                           markers: _markers,
// //                           initialCameraPosition: const CameraPosition(
// //                             target: LatLng(20.5937, 78.9629), // India
// //                             zoom: 5.0,
// //                           ),
// //                           tileOverlays: mapUrl != null && mapUrl!.isNotEmpty
// //                               ? {
// //                                   TileOverlay(
// //                                     tileOverlayId: const TileOverlayId('map'),
// //                                     tileProvider: CustomTileProvider1(baseUrl: mapUrl!),
// //                                   ),
// //                                 }
// //                               : {},
// //
// //                           mapType: MapType.normal,
// //                           myLocationButtonEnabled: true,
// //                           zoomControlsEnabled: true,
// //                         )),
// //                   ),
// //                   ImpactFilterSection(
// //                     filters: [
// //                       {
// //                         'label': 'High',
// //                         'color': Colors.red,
// //                         'count': impactCounts['High'] ?? 0
// //                       },
// //                       {
// //                         'label': 'Modurate',
// //                         'color': Colors.orange,
// //                         'count': impactCounts['Medium'] ?? 0
// //                       },
// //                       {
// //                         'label': 'Low',
// //                         'color': Colors.green,
// //                         'count': impactCounts['Low'] ?? 0
// //                       },
// //                     ],
// //                     selectedFilter: selectedFilter,
// //                     onFilterSelected: _filterMarkers,
// //                   ),
// //                 ],
// //               ),
// //       ),
// //     );
// //   }
// //
// //   String _formatDate(String ddmmyyhhmm) {
// //     final day = ddmmyyhhmm.substring(0, 2);
// //     final month = ddmmyyhhmm.substring(2, 4);
// //     final year = '20${ddmmyyhhmm.substring(4, 6)}';
// //     final hour = ddmmyyhhmm.substring(6, 8);
// //     final minute = ddmmyyhhmm.substring(8, 10);
// //
// //     final parsedDate = DateTime.parse('$year-$month-$day $hour:$minute');
// //     return DateFormat('MM/dd/yyyy HH:mm:ss').format(parsedDate);
// //   }
// //
// //   String? _extractImpact(Map<String, dynamic> json) {
// //     for (final entry in json.entries) {
// //       if (entry.key == 'impact') {
// //         return entry.value.toString();
// //       } else if (entry.value is Map) {
// //         final impact = _extractImpact(entry.value as Map<String, dynamic>);
// //         if (impact != null) return impact;
// //       }
// //     }
// //     return null;
// //   }
// // }
// //
