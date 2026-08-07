import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:RiskSphere/providers/news_feed_provider.dart';
import 'package:RiskSphere/screens/event/widgets/hazard_info_section.dart';
import 'package:RiskSphere/screens/event/widgets/image_filter_section.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';


import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
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
  String? _currentMapUrl;
  Set<TileOverlay> _tileOverlays =
      {}; // ✅ stored as field, never rebuilt in build()
  String? selectedFilter;
  Map<String, int> impactCounts = {'High': 0, 'Medium': 0, 'Low': 0};
  bool _isExpanded = false;
  bool _showNotificationDot = true;

  late double _initialLat;
  late double _initialLng;
  late LatLng _initialMapCenter;
  List<dynamic> locationsData = [];

  void _showLocationDetails(
    Map<String, dynamic> location,
  ) {
    final eventMap = location['event'] as Map<String, dynamic>? ?? {};

    final firstEvent = eventMap.isNotEmpty
        ? eventMap.values.first as Map<String, dynamic>
        : {};

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Expanded(
                child: Text(
                  "Location Details",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow(
                  "Location Name",
                  location['location_name'] ?? '',
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  "Address",
                  location['address'] ?? '',
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  "Hazard Type",
                  firstEvent['hazard_name'] ?? '',
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  "Event Severity",
                  firstEvent['impact_value']?.toString() ?? '',
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  "Event Name",
                  firstEvent['event_name'] ?? '',
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  "Vendor Name",
                  firstEvent['vendor_name'] ?? '',
                ),
              ],
            ),
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("Close"),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 6,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              "$title :",
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String get _lastUpdatedString {
    final DateTime date = widget.notificationData['timestamp'] ?? DateTime.now();
    return "Last Updated: ${DateFormat('MMM dd, yyyy hh:mm a').format(date)} EDT";
  }

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

    debugPrint(" Map Center: $_initialMapCenter");

    _initialize();
  }

  void _buildTileOverlay(String? url) {
    if (url == null || url.isEmpty) {
      if (_tileOverlays.isNotEmpty) setState(() => _tileOverlays = {});
      return;
    }
    if (url == _currentMapUrl) return;
    _currentMapUrl = url;
    setState(() => _tileOverlays = {});

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _tileOverlays = {
          TileOverlay(
            tileOverlayId: const TileOverlayId('map'),
            tileProvider: CustomTileProvider1(baseUrl: url),
            fadeIn: false,
            // ✅ false prevents ghost overlay on iOS
            transparency: 0.0,
            zIndex: 1,
          ),
        };
      });
    });
  }

  // // ✅ Only call this when the URL actually changes — not on every rebuild
  // void _buildTileOverlay(String? url) {
  //   if (url == null || url.isEmpty) {
  //     if (_tileOverlays.isNotEmpty) {
  //       setState(() => _tileOverlays = {});
  //     }
  //     return;
  //   }
  //
  //   // Same URL — don't recreate, overlay is already alive
  //   if (url == _currentMapUrl) return;
  //
  //   _currentMapUrl = url;
  //   setState(() {
  //     _tileOverlays = {
  //       TileOverlay(
  //         tileOverlayId: const TileOverlayId('map'),
  //         tileProvider: CustomTileProvider1(baseUrl: url),
  //         fadeIn: true,
  //         // smooth tile appearance
  //         transparency: 0.0,
  //         zIndex: 1,
  //       ),
  //     };
  //   });
  // }

  bool isMapView = true;

  Future<void> _initialize() async {
    setState(() => _isLoading = true);
    await _fetchEventInfo();
    setState(() => _isLoading = false);
  }

  Future<void> _fetchEventInfo() async {
    final provider = Provider.of<NewsFeedProvider>(
      context,
      listen: false,
    );

    final eventId = widget.notificationData['eventId'];

    print("EVENT ID 👉 $eventId");

    setState(() => _isLoading = true);

    await provider.fetchEventInfo(
      eventId: eventId,
    );

    final result = provider.eventInfo;

    if (result.isNotEmpty) {
      final locations = result['locations_data'] as List<dynamic>? ?? [];

      /// SET INITIAL MAP POSITION FROM FIRST LOCATION
      if (locations.isNotEmpty) {
        final firstLocation = locations.first;

        _initialLat = (firstLocation['latitude'] ?? 20.5937).toDouble();

        _initialLng = (firstLocation['longitude'] ?? 78.9629).toDouble();

        _initialMapCenter = LatLng(
          _initialLat,
          _initialLng,
        );
      }

      String? fetchedMapUrl = result['map_url'];

      if (fetchedMapUrl == null || fetchedMapUrl.isEmpty) {
        fetchedMapUrl = await provider.fetchMapUrl(
          eventId,
        );
      }

      print("FINAL MAP URL 👉 $fetchedMapUrl");

      Set<Marker> markers = locations.map<Marker>((location) {
        return Marker(
          markerId: MarkerId(
            location['location_id'],
          ),
          position: LatLng(
            location['latitude'],
            location['longitude'],
          ),
          // infoWindow: const InfoWindow.n
          onTap: () {
            _showLocationDetails(location);
          },
        );
      }).toSet();
      // Set<Marker> markers = locations.map<Marker>((location) {
      //   return Marker(
      //     markerId: MarkerId(
      //       location['location_id'],
      //     ),
      //     position: LatLng(
      //       location['latitude'],
      //       location['longitude'],
      //     ),
      //     infoWindow: const InfoWindow(
      //       title: '',
      //     ),
      //     onTap: () {
      //       _showLocationDetails(location);
      //     },
      //   );
      // }).toSet();

      setState(() {
        mapUrl = fetchedMapUrl;
        locationsData = locations;
        _markers = markers;
        _allMarkers = markers;
        _isLoading = false;
      });

      /// MOVE CAMERA TO FIRST LOCATION
      if (_markers.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            try {
              _mapController.animateCamera(
                CameraUpdate.newLatLngZoom(
                  _initialMapCenter,
                  8,
                ),
              );
            } catch (_) {}
          }
        });
      }

      /// BUILD TILE OVERLAY
      _buildTileOverlay(
        fetchedMapUrl,
      );
    } else {
      print("EVENT INFO EMPTY");

      setState(() {
        locationsData = [];
        _isLoading = false;
      });
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
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : Column(
                children: [
                  HazardInfoSection(
                    hazardName:
                        widget.notificationData['title'] ?? "Event Hazard",
                    selectedDate: selectedDate!,
                    lastUpdated: _lastUpdatedString,
                    availableDates: availableDates,
                    onDateChanged: (value) {
                      setState(() {
                        selectedDate = value;
                      });
                      _fetchEventInfo();
                    },
                  ),

                  /// MAP / TABLE TOGGLE
                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey.shade600,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                isMapView = true;
                              });
                            },
                            child: Container(
                              height: 42,
                              decoration: BoxDecoration(
                                color: isMapView
                                    ? Colors.grey.shade700
                                    : Colors.transparent,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  bottomLeft: Radius.circular(8),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.map, size: 18),
                                  SizedBox(width: 6),
                                  Text("MAP"),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                isMapView = false;
                              });
                            },
                            child: Container(
                              height: 42,
                              decoration: BoxDecoration(
                                color: !isMapView
                                    ? Colors.grey.shade700
                                    : Colors.transparent,
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(8),
                                  bottomRight: Radius.circular(8),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.table_rows, size: 18),
                                  SizedBox(width: 6),
                                  Text("TABLE"),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                      child: isMapView
                          ? Stack(
                              children: [
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
                                    // ✅ ADD THIS — forces iOS to re-request tiles cleanly on zoom
                                    onCameraMove: (_) {
                                      if (_tileOverlays.isNotEmpty) {
                                        final overlay = _tileOverlays.first;
                                        _mapController.clearTileCache(
                                            overlay.tileOverlayId);
                                      }
                                    },
                                  ),
                                  // child: GoogleMap(
                                  //   onMapCreated: (controller) {
                                  //     _mapController = controller;
                                  //   },
                                  //   markers: _markers,
                                  //   initialCameraPosition: CameraPosition(
                                  //     target: _initialMapCenter,
                                  //     zoom: 5.0,
                                  //   ),
                                  //   tileOverlays: _tileOverlays,
                                  //   mapToolbarEnabled: false,
                                  //   mapType: MapType.normal,
                                  //   myLocationButtonEnabled: true,
                                  //   zoomControlsEnabled: true,
                                  // ),
                                ),
                                Positioned(
                                  bottom: 30,
                                  left: 30,
                                  child: _buildLegend(),
                                ),
                              ],
                            )
                          : Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  /// HEADER
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade800,
                                      border: Border.all(
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    child: IntrinsicHeight(
                                      child: Row(
                                        children: [
                                          Expanded(
                                            flex: 3,
                                            child: Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                border: Border(
                                                  right: BorderSide(
                                                    color: Colors.grey.shade700,
                                                  ),
                                                ),
                                              ),
                                              child:
                                                  const Text("Location Name"),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 4,
                                            child: Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                border: Border(
                                                  right: BorderSide(
                                                    color: Colors.grey.shade700,
                                                  ),
                                                ),
                                              ),
                                              child: const Text("Address"),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                border: Border(
                                                  right: BorderSide(
                                                    color: Colors.grey.shade700,
                                                  ),
                                                ),
                                              ),
                                              child: const Text("Hazard Name"),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Container(
                                              padding: const EdgeInsets.all(12),
                                              child: const Text("Event Name"),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: _isLoading
                                        ? const Center(
                                            child: CircularProgressIndicator(),
                                          )
                                        : locationsData.isEmpty
                                            ? const Center(
                                                child: Text(
                                                  "No Data Found",
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              )
                                            : ListView.builder(
                                                itemCount: locationsData.length,
                                                itemBuilder: (context, index) {
                                                  final location =
                                                      locationsData[index];

                                                  final eventMap =
                                                      location['event'] as Map<
                                                              String,
                                                              dynamic>? ??
                                                          {};

                                                  final firstEvent = eventMap
                                                          .isNotEmpty
                                                      ? eventMap.values.first
                                                          as Map<String,
                                                              dynamic>
                                                      : {};

                                                  return Container(
                                                    decoration: BoxDecoration(
                                                      border: Border(
                                                        left: BorderSide(
                                                          color: Colors
                                                              .grey.shade700,
                                                        ),
                                                        right: BorderSide(
                                                          color: Colors
                                                              .grey.shade700,
                                                        ),
                                                        bottom: BorderSide(
                                                          color: Colors
                                                              .grey.shade700,
                                                        ),
                                                      ),
                                                    ),
                                                    child: IntrinsicHeight(
                                                      child: Row(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .stretch,
                                                        children: [
                                                          /// LOCATION NAME
                                                          Expanded(
                                                            flex: 3,
                                                            child: Container(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(12),
                                                              decoration:
                                                                  BoxDecoration(
                                                                border: Border(
                                                                  right:
                                                                      BorderSide(
                                                                    color: Colors
                                                                        .grey
                                                                        .shade700,
                                                                  ),
                                                                ),
                                                              ),
                                                              child: Text(
                                                                location['location_name']
                                                                        ?.toString() ??
                                                                    '',
                                                                maxLines: 2,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                            ),
                                                          ),

                                                          /// ADDRESS
                                                          Expanded(
                                                            flex: 4,
                                                            child: Container(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(12),
                                                              decoration:
                                                                  BoxDecoration(
                                                                border: Border(
                                                                  right:
                                                                      BorderSide(
                                                                    color: Colors
                                                                        .grey
                                                                        .shade700,
                                                                  ),
                                                                ),
                                                              ),
                                                              child: Text(
                                                                location['address']
                                                                        ?.toString() ??
                                                                    '',
                                                                maxLines: 3,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                            ),
                                                          ),

                                                          /// HAZARD NAME
                                                          Expanded(
                                                            flex: 2,
                                                            child: Container(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(12),
                                                              decoration:
                                                                  BoxDecoration(
                                                                border: Border(
                                                                  right:
                                                                      BorderSide(
                                                                    color: Colors
                                                                        .grey
                                                                        .shade700,
                                                                  ),
                                                                ),
                                                              ),
                                                              child: Text(
                                                                firstEvent['hazard_name']
                                                                        ?.toString() ??
                                                                    '',
                                                                maxLines: 2,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                            ),
                                                          ),

                                                          /// EVENT NAME
                                                          Expanded(
                                                            flex: 2,
                                                            child: Container(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(12),
                                                              child: Text(
                                                                firstEvent['event_name']
                                                                        ?.toString() ??
                                                                    '',
                                                                maxLines: 2,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                  )
                                ],
                              ),
                            )),

                  ImpactFilterSection(
                    filters: [
                      {
                        'label': 'High',
                        'color': Colors.red,
                        'count': impactCounts['High'] ?? 0,
                      },
                      {
                        'label': 'Moderate',
                        'color': Colors.orange,
                        'count': impactCounts['Medium'] ?? 0,
                      },
                      {
                        'label': 'Low',
                        'color': Colors.green,
                        'count': impactCounts['Low'] ?? 0,
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
