import 'package:RiskSphere/screens/event/widgets/hazard_info_section.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' hide Marker;
import '../../providers/custom_tile_providers.dart';
import '../../utils/global_imports.dart';

class EventVisulisationScreen extends StatefulWidget {
  final Map<String, dynamic> notificationData;

  const EventVisulisationScreen({required this.notificationData});

  @override
  State<EventVisulisationScreen> createState() =>
      _EventVisulisationScreenState();
}

class _EventVisulisationScreenState extends State<EventVisulisationScreen> {
  int _currentPage = 0;
  bool _showGraph = false;
  Set<Marker> _markers = {};
  Set<Marker> _allMarkers = {};
  String? selectedDate = "";
  List<String> availableDates = [];
  bool isMapView = true;
  String? _currentMapUrl;
  Set<TileOverlay> _tileOverlays = {};

  Future<void> _initialize() async {
    setState(() => _isLoading = true);
    await _fetchEventInfo();
    setState(() => _isLoading = false);
  }
  GoogleMapController? _mapController;
  int _selectedTab = 0;
  bool _isExpanded = false;
  bool _showNotificationDot = true;
  final PageController _pageController = PageController();
  bool _isLoading = true;

  late double _initialLat;
  late double _initialLng;
  LatLng? _initialMapCenter;
  List<dynamic> locationsData = [];

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

      // Set<Marker> markers = locations.map<Marker>((location) {
      //   return Marker(
      //     markerId: MarkerId(
      //       location['location_id'],
      //     ),
      //     position: LatLng(
      //       location['latitude'],
      //       location['longitude'],
      //     ),
      //     // infoWindow: const InfoWindow.n
      //     onTap: () {
      //       _showLocationDetails(location);
      //     },
      //   );
      // }).toSet();
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
        // mapUrl = fetchedMapUrl;
        // locationsData = locations;
        // _markers = markers;
        // _allMarkers = markers;
        _isLoading = false;
      });

      /// MOVE CAMERA TO FIRST LOCATION
      if (_markers.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            try {
              _mapController!.animateCamera(
                CameraUpdate.newLatLngZoom(
                  _initialMapCenter!,
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

  // ─── Sample Data ───────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _locationExposures = [
    {
      'city': 'Tampa, FL',
      'county': 'Hillsborough, FL',
      'category': 'Cat 4',
      'tiv': '\$8.4B',
      'eventScore': [4, 3, 4, 2, 1],
      'catColor': Colors.red,
    },
    {
      'city': 'Fort Myers, FL',
      'county': 'Lee, FL',
      'category': 'Cat 3',
      'tiv': '\$6.2B',
      'eventScore': [3, 3, 2, 2, 1],
      'catColor': Colors.orange,
    },
    {
      'city': 'Miami, FL',
      'county': 'Miami-Dade, FL',
      'category': 'Cat 4',
      'tiv': '\$4.1B',
      'eventScore': [4, 3, 3, 2, 1],
      'catColor': Colors.red,
    },
  ];

  // ─── Chart Data ────────────────────────────────────────────────────────
  List<FlSpot> _windSpeedData() => [
        const FlSpot(0, 40),
        const FlSpot(1, 55),
        const FlSpot(2, 75),
        const FlSpot(3, 95),
        const FlSpot(4, 112),
        const FlSpot(5, 100),
        const FlSpot(6, 80),
        const FlSpot(7, 60),
      ];

  List<FlSpot> _surgeData() => [
        const FlSpot(0, 10),
        const FlSpot(1, 15),
        const FlSpot(2, 20),
        const FlSpot(3, 25),
        const FlSpot(4, 30),
        const FlSpot(5, 22),
        const FlSpot(6, 18),
        const FlSpot(7, 12),
      ];

  List<FlSpot> _rainfallData() => [
        const FlSpot(0, 5),
        const FlSpot(1, 8),
        const FlSpot(2, 12),
        const FlSpot(3, 18),
        const FlSpot(4, 22),
        const FlSpot(5, 20),
        const FlSpot(6, 15),
        const FlSpot(7, 10),
      ];

  List<FlSpot> _waveData() => [
        const FlSpot(0, 8),
        const FlSpot(1, 12),
        const FlSpot(2, 18),
        const FlSpot(3, 22),
        const FlSpot(4, 28),
        const FlSpot(5, 25),
        const FlSpot(6, 20),
        const FlSpot(7, 14),
      ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
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
      body: SafeArea(
        child: Column(
          children: [
            HazardInfoSection(
              hazardName: widget.notificationData['title'] ?? "Event Hazard",
              selectedDate: "12/1/1111",
              availableDates: availableDates,
              onDateChanged: (value) {
                setState(() {
                  selectedDate = value;
                });
                _fetchEventInfo();
              },
            ),
            Expanded(
                child: isMapView
                    ? Stack(
                        children: [
                          Container(
                            margin: const EdgeInsets.fromLTRB(16, 1, 16, 2.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20.0),
                              color: Colors.grey.shade100,
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: GoogleMap(
                              onMapCreated: (controller) {
                                _mapController = controller;
                              },
                              // markers: _markers,
                              initialCameraPosition: CameraPosition(
                                target: _initialMapCenter ??
                                    LatLng(20.5937, 78.9629),
                                zoom: 5.0,
                              ),
                              tileOverlays: _tileOverlays,
                              mapToolbarEnabled: false,
                              mapType: MapType.normal,
                              myLocationButtonEnabled: true,
                              zoomControlsEnabled: true,
                              onCameraMove: (_) {
                                if (_tileOverlays.isNotEmpty) {
                                  final overlay = _tileOverlays.first;
                                  _mapController!
                                      .clearTileCache(overlay.tileOverlayId);
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
                          // Positioned(
                          //   bottom: 30,
                          //   left: 30,
                          //   child: _buildLegend(),
                          // ),
                        ],
                      )
                    : Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
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
                                        child: const Text("Location Name"),
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

                                            final eventMap = location['event']
                                                    as Map<String, dynamic>? ??
                                                {};

                                            final firstEvent =
                                                eventMap.isNotEmpty
                                                    ? eventMap.values.first
                                                        as Map<String, dynamic>
                                                    : {};

                                            return Container(
                                              decoration: BoxDecoration(
                                                border: Border(
                                                  left: BorderSide(
                                                    color: Colors.grey.shade700,
                                                  ),
                                                  right: BorderSide(
                                                    color: Colors.grey.shade700,
                                                  ),
                                                  bottom: BorderSide(
                                                    color: Colors.grey.shade700,
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
                                                            right: BorderSide(
                                                              color: Colors.grey
                                                                  .shade700,
                                                            ),
                                                          ),
                                                        ),
                                                        child: Text(
                                                          location['location_name']
                                                                  ?.toString() ??
                                                              '',
                                                          maxLines: 2,
                                                          overflow: TextOverflow
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
                                                            right: BorderSide(
                                                              color: Colors.grey
                                                                  .shade700,
                                                            ),
                                                          ),
                                                        ),
                                                        child: Text(
                                                          location['address']
                                                                  ?.toString() ??
                                                              '',
                                                          maxLines: 3,
                                                          overflow: TextOverflow
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
                                                            right: BorderSide(
                                                              color: Colors.grey
                                                                  .shade700,
                                                            ),
                                                          ),
                                                        ),
                                                        child: Text(
                                                          firstEvent['hazard_name']
                                                                  ?.toString() ??
                                                              '',
                                                          maxLines: 2,
                                                          overflow: TextOverflow
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
                                                          overflow: TextOverflow
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
            _buildTabBar(),
            Expanded(
              child: _selectedTab == 0
                  ? _buildOverviewTab()
                  : _buildLocationExposureTab(),
            ),
            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }
 Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _buildTab('Overview', 0),
          _buildTab('Location Exposure', 1),
        ],
      ),
    );
  }

  Widget _buildTab(String title, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryMain : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  // ─── Overview Tab ──────────────────────────────────────────────────────
  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Storm Overview', showGraphToggle: true),
          const SizedBox(height: 12),
          if (_showGraph) ...[
            _buildStormGraph(),
            const SizedBox(height: 12),
            _buildGraphStats(),
          ] else ...[
            _buildStormOverviewGrid(),
          ],
          const SizedBox(height: 16),
          _buildSectionHeader('Hurricane Summary'),
          const SizedBox(height: 12),
          _buildHurricaneSummary(),
          const SizedBox(height: 16),
          _buildSectionHeader('Storm Movement'),
          const SizedBox(height: 12),
          _buildStormMovement(),
          const SizedBox(height: 16),
          _buildSectionHeader('Critical Infrastructure Impact (Near Location)'),
          const SizedBox(height: 12),
          _buildInfrastructureImpact(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {bool showGraphToggle = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF2196F3),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        if (showGraphToggle)
          Row(
            children: [
              const Text('Graph',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(width: 6),
              Switch(
                value: _showGraph,
                onChanged: (v) => setState(() => _showGraph = v),
                activeColor: const Color(0xFF2196F3),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildStormOverviewGrid() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _buildOverviewItem('Storm Name', 'Milton'),
          _buildOverviewItem('Storm Category', 'Category 4\n(130-157 mph)'),
          _buildOverviewItem('Forecast Time', '09 Oct 2024 •\n18:00 UTC'),
        ],
      ),
    );
  }

  Widget _buildOverviewItem(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 10)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ─── Storm Graph ───────────────────────────────────────────────────────
  Widget _buildStormGraph() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(10),
      ),
      child: LineChart(
        LineChartData(
          backgroundColor: const Color(0xFF1E1E1E),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            getDrawingHorizontalLine: (_) => FlLine(
              color: Colors.white12,
              strokeWidth: 0.5,
            ),
            getDrawingVerticalLine: (_) => FlLine(
              color: Colors.white12,
              strokeWidth: 0.5,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, _) => Text(
                  value.toInt().toString(),
                  style: const TextStyle(color: Colors.white38, fontSize: 8),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  const labels = [
                    'Oct 03',
                    'Oct 04',
                    'Oct 05',
                    'Oct 06',
                    'Oct 07',
                    'Oct 08',
                    'Oct 09',
                    'Oct 10'
                  ];
                  final idx = value.toInt();
                  if (idx < 0 || idx >= labels.length) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    labels[idx],
                    style: const TextStyle(color: Colors.white38, fontSize: 7),
                  );
                },
              ),
            ),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            _buildLine(_windSpeedData(), Colors.red),
            _buildLine(_surgeData(), Colors.purple),
            _buildLine(_rainfallData(), Colors.blue),
            _buildLine(_waveData(), Colors.teal),
          ],
        ),
      ),
    );
  }

  LineChartBarData _buildLine(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 2,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: false),
    );
  }

  Widget _buildGraphStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildLegendItem(Colors.red, 'Max Wind Speed', '112 mph'),
        _buildLegendItem(Colors.purple, 'Max Surge', '6-9 ft'),
        _buildLegendItem(Colors.blue, 'Max Rainfall', '9-12 in'),
        _buildLegendItem(Colors.teal, 'Max Wave\nSpeed', '10-15 ft'),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label, String value) {
    return Column(
      children: [
        Row(
          children: [
            Icon(Icons.circle, color: color, size: 8),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(color: Colors.white54, fontSize: 9)),
          ],
        ),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildHurricaneSummary() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _buildSummaryItem('Max wind\nspeed', '112 mph'),
          _buildSummaryItem('Storm\nSurge', '6-9 ft'),
          _buildSummaryItem('Rainfall', '9-12 in'),
          _buildSummaryItem('Wave\nHeight', 'Milton'),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 10)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildStormMovement() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _buildOverviewItem('Forward Speed', '13 mph'),
          _buildOverviewItem('Forecast Track Point', '18'),
        ],
      ),
    );
  }

  Widget _buildInfrastructureImpact() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildImpactChip('Airport', Colors.red),
              _buildImpactChip('Seaport', Colors.red),
              _buildImpactChip('Energy', Colors.orange),
              _buildImpactChip('Medicalfac', Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImpactChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w500)),
    );
  }

  // ─── Location Exposure Tab ─────────────────────────────────────────────
  Widget _buildLocationExposureTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Location Exposure (KAC Data)',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
              ),
              IconButton(
                icon:
                    const Icon(Icons.download_outlined, color: Colors.white70),
                onPressed: () {},
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            itemCount: _locationExposures.length,
            itemBuilder: (context, index) {
              return _buildLocationCard(_locationExposures[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLocationCard(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['city'],
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  ),
                  Text(
                    data['county'],
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (data['catColor'] as Color).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: (data['catColor'] as Color).withOpacity(0.6)),
                ),
                child: Text(
                  data['category'],
                  style: TextStyle(
                      color: data['catColor'] as Color,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TIV Exposed :',
                        style: TextStyle(color: Colors.white54, fontSize: 11)),
                    Text(
                      data['tiv'],
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    const Text('Event Score :',
                        style: TextStyle(color: Colors.white54, fontSize: 11)),
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(
                        5,
                        (i) => Container(
                          width: 18,
                          height: 18,
                          margin: const EdgeInsets.only(right: 3),
                          decoration: BoxDecoration(
                            color: _scoreColor((data['eventScore'] as List)[i])
                                .withOpacity(0.8),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Center(
                            child: Text(
                              '${(data['eventScore'] as List)[i]}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Mini spark line
              SizedBox(
                width: 100,
                height: 50,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(
                      leftTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: List.generate(
                          5,
                          (i) => FlSpot(i.toDouble(),
                              ((data['eventScore'] as List)[i]).toDouble()),
                        ),
                        isCurved: true,
                        color: Colors.red,
                        barWidth: 1.5,
                        dotData: const FlDotData(show: false),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _scoreColor(int score) {
    switch (score) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.lightGreen;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.red;
      case 5:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
 Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          OutlinedButton.icon(
            onPressed: _currentPage > 0
                ? () {
                    setState(() => _currentPage--);
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                : null,
            icon: const Icon(Icons.arrow_back, size: 14),
            label: const Text('Previous'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white70,
              side: const BorderSide(color: Colors.white24),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              setState(() => _currentPage++);
              _pageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            icon: const Icon(Icons.arrow_forward,
                size: 14, color: Colors.black87),
            label: const Text('Next', style: TextStyle(color: Colors.black87)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryMain,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }
}
