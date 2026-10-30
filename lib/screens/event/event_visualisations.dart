import 'package:RiskSphere/design_system/repo/color_pallets_screen.dart';
import 'package:RiskSphere/screens/event/widgets/hazard_info_section.dart';
import 'package:RiskSphere/main.dart' show routeObserver;
import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../providers/custom_tile_providers.dart';
import '../../utils/global_imports.dart' hide Marker;
import '../../models/sov_list_model.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:RiskSphere/utils/env.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as path;
import 'package:external_path/external_path.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

class EventVisulisationScreen extends StatefulWidget {
  final Map<String, dynamic> notificationData;

  const EventVisulisationScreen({required this.notificationData});

  @override
  State<EventVisulisationScreen> createState() =>
      _EventVisulisationScreenState();
}

class _EventVisulisationScreenState extends State<EventVisulisationScreen>
    with RouteAware {
  int _currentPage = 0;
  bool _showGraph = false;
  bool _is3DView = false;
  CameraPosition? _currentCameraPosition;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  Set<Polygon> _polygons = {};
  Set<Marker> _allMarkers = {};
  String? selectedDate = "";
  List<String> availableDates = [];
  bool isMapView = true;
  String? _currentMapUrl;
  Set<TileOverlay> _tileOverlays = {};
  String _lastUpdatedString = "N/A";
  MapType _currentMapType = MapType.normal;
  bool _showMapMenu = false;
  bool _showMap = true;

  static final http.Client _rawHttpClient = http.Client();
  BitmapDescriptor? _redIcon, _orangeIcon, _yellowIcon;

  final Map<String, String> _dateToEventIdMap = {};

  /// Raw result from the single_event API; used to populate the dropdown.
  Map<String, dynamic>? _singleEventData;

  Future<void> _ensureIcons() async {
    _redIcon ??= await _getCircleIcon(Colors.red, 24);
    _orangeIcon ??= await _getCircleIcon(Colors.orange, 24);
    _yellowIcon ??= await _getCircleIcon(Colors.yellow, 24);
  }

  void _initDatesAndEvents() {
    _dateToEventIdMap.clear();
    final List<String> dates = [];

    final currentEventId = widget.notificationData['eventId']?.toString() ??
        widget.notificationData['id']?.toString() ??
        '';

    String currentDate =
        widget.notificationData['dataSourceDate']?.toString() ??
            widget.notificationData['runDtg']?.toString() ??
            '';

    if (currentDate.isEmpty && widget.notificationData['timestamp'] != null) {
      final ts = widget.notificationData['timestamp'];
      if (ts is DateTime) {
        currentDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(ts);
      } else if (ts is String) {
        currentDate = ts;
      }
    }

    if (currentDate.isNotEmpty) {
      _dateToEventIdMap[currentDate] = currentEventId;
      dates.add(currentDate);
      selectedDate = currentDate;
    }

    final other = widget.notificationData['otherEvents'] ??
        widget.notificationData['other_events'];
    if (other != null && other is List) {
      for (var item in other) {
        String? d;
        String? eid;
        if (item is OtherEvent) {
          d = item.date;
          eid = item.eventId;
        } else if (item is Map) {
          d = item['date']?.toString() ?? item['data_source_date']?.toString();
          eid = item['event_id']?.toString() ?? item['id']?.toString();
        }
        if (d != null && d.isNotEmpty && eid != null && eid.isNotEmpty) {
          _dateToEventIdMap[d] = eid;
          if (!dates.contains(d)) {
            dates.add(d);
          }
        }
      }
    }

    if (selectedDate == null || selectedDate!.isEmpty) {
      if (dates.isNotEmpty) {
        selectedDate = dates.first;
      }
    }

    availableDates = dates;

    if (_lastUpdatedString == "N/A") {
      if (widget.notificationData['timestamp'] != null) {
        final ts = widget.notificationData['timestamp'];
        if (ts is DateTime) {
          _lastUpdatedString = DateFormat('MMM dd, yyyy • HH:mm:ss').format(ts);
        } else {
          _lastUpdatedString = ts.toString();
        }
      } else if (currentDate.isNotEmpty) {
        _lastUpdatedString = currentDate;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _ensureIcons();
    _initDatesAndEvents();
    _fetchAndMergeSingleEventDates();
    _initialize();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPopNext() {
    super.didPopNext();
    _initialize();
  }

  @override
  void didPush() {
    super.didPush();
  }

  Future<void> _initialize() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final dynamic rawUrls = widget.notificationData['frontendUrls'];
      if (rawUrls == null || (rawUrls is String && rawUrls.isEmpty)) {
        await _fetchEventInfo();
      } else {
        await _loadStormData().timeout(
          const Duration(seconds: 20),
          onTimeout: () async {
            await _fetchEventInfo();
          },
        );
      }
    } catch (e) {
      try {
        await _fetchEventInfo();
      } catch (fallbackErr) {
        print("===== FALLBACK ERROR: $fallbackErr =====");
      }
    } finally {
      // Always unblock the spinner — no matter what happened above
      if (mounted) setState(() => _isLoading = false);
      print("===== INITIALIZE END =====");
    }
  }

  Future<void> _fetchAndMergeSingleEventDates() async {
    final eventId = widget.notificationData['eventId']?.toString() ??
        widget.notificationData['id']?.toString() ??
        '';
    if (eventId.isEmpty) return;

    try {
      final provider = Provider.of<NewsFeedProvider>(context, listen: false);
      final result = await provider.fetchSingleEvent(eventId: eventId);
      if (result == null || result.isEmpty) return;

      _singleEventData = result;

      final selfDate = result['data_source_date']?.toString() ??
          result['run_dtg']?.toString() ??
          result['dataSourceDate']?.toString() ??
          '';
      final selfId =
          result['event_id']?.toString() ?? result['id']?.toString() ?? eventId;

      if (selfDate.isNotEmpty) {
        if (!_dateToEventIdMap.containsKey(selfDate)) {
          _dateToEventIdMap[selfDate] = selfId;
        }
        if (!availableDates.contains(selfDate)) {
          availableDates.insert(0, selfDate);
          if (selectedDate == null || selectedDate!.isEmpty) {
            selectedDate = selfDate;
          }
        }
      }

      // Merge other_events from single_event response
      final otherEvents = result['other_events'];
      if (otherEvents != null && otherEvents is List) {
        for (final item in otherEvents) {
          String? d;
          String? eid;
          if (item is Map) {
            d = item['date']?.toString() ??
                item['data_source_date']?.toString() ??
                item['run_dtg']?.toString();
            eid = item['event_id']?.toString() ?? item['id']?.toString();
          }
          if (d != null && d.isNotEmpty && eid != null && eid.isNotEmpty) {
            if (!_dateToEventIdMap.containsKey(d)) {
              _dateToEventIdMap[d] = eid;
            }
            if (!availableDates.contains(d)) {
              availableDates.add(d);
            }
          }
        }
      }

      // Also pick up frontend_urls if present and not already set
      if (widget.notificationData['frontendUrls'] == null) {
        final rawUrls = result['frontend_urls'];
        if (rawUrls != null) {
          widget.notificationData['frontendUrls'] = rawUrls;
        }
      }

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('_fetchAndMergeSingleEventDates error: $e');
    }
  }

  Future<void> _onDateChanged(String? newDate) async {
    if (newDate == null || newDate == selectedDate) return;

    setState(() {
      selectedDate = newDate;
      _isLoading = true;
    });

    final targetEventId = _dateToEventIdMap[newDate];
    print("Date changed to: $newDate -> targetEventId: $targetEventId");

    if (targetEventId != null && targetEventId.isNotEmpty) {
      await _loadEventById(targetEventId);
    } else {
      await _loadStormData();
    }
  }

  Future<void> _loadEventById(String targetEventId) async {
    try {
      final provider = Provider.of<NewsFeedProvider>(
        context,
        listen: false,
      );

      print("FETCHING EVENT INFO FOR DATE SELECTION  $targetEventId");

      // Fetch the single event details (which has frontend_urls)
      final singleEventResult =
          await provider.fetchSingleEvent(eventId: targetEventId);

      // Also fetch event info (which might have locations_data)
      await provider.fetchEventInfo(
        eventId: targetEventId,
      );

      final Map<String, dynamic> result = Map.from(provider.eventInfo);

      // Merge singleEventResult into result
      if (singleEventResult != null) {
        setState(() {
          _singleEventData = singleEventResult;
        });

        if (singleEventResult['frontend_urls'] != null) {
          result['frontend_urls'] = singleEventResult['frontend_urls'];
        }
        if (singleEventResult['last_update_date'] != null) {
          result['last_update_date'] = singleEventResult['last_update_date'];
        }
        if (singleEventResult['updated_at'] != null) {
          result['updated_at'] = singleEventResult['updated_at'];
        }
        if (singleEventResult['data_source_date'] != null) {
          result['data_source_date'] = singleEventResult['data_source_date'];
        }
        if (singleEventResult['other_events'] != null) {
          result['other_events'] = singleEventResult['other_events'];
        }
      }

      if (result.isNotEmpty) {
        if (result['frontend_urls'] != null) {
          final dynamic rawUrls = result['frontend_urls'];
          FrontendUrls? parsedUrls;
          if (rawUrls is FrontendUrls) {
            parsedUrls = rawUrls;
          } else if (rawUrls is Map<String, dynamic>) {
            parsedUrls = FrontendUrls.fromJson(rawUrls);
          } else if (rawUrls is String) {
            try {
              parsedUrls = FrontendUrls.fromJson(jsonDecode(rawUrls));
            } catch (e) {
              debugPrint('Error parsing frontendUrls JSON: $e');
            }
          }

          if (parsedUrls != null) {
            String _toProxyUrl(String? url) {
              if (url == null || url.isEmpty) return '';
              if (url.contains('risksphere.ai/api/geojson/proxy')) {
                final uri = Uri.tryParse(url);
                final inner = uri?.queryParameters['url'];
                if (inner != null && inner.isNotEmpty) {
                  return 'https://app.risksphere.ai/api/geojson/proxy?url=${Uri.encodeComponent(inner)}';
                }
                return url;
              }
              return 'https://app.risksphere.ai/api/geojson/proxy?url=${Uri.encodeComponent(url)}';
            }

            final resolvedUrls = FrontendUrls(
              stormTrackGeojson: _toProxyUrl(parsedUrls.stormTrackGeojson),
              stormForecastPointsGeojson:
                  _toProxyUrl(parsedUrls.stormForecastPointsGeojson),
              stormSwathGeojson: _toProxyUrl(parsedUrls.stormSwathGeojson),
              uiDataGeojson: _toProxyUrl(parsedUrls.uiDataGeojson),
            );

            await loadStormGeoJson(resolvedUrls);
          }
        }

        // 2. Parse locations_data
        final locations = result['locations_data'] as List<dynamic>? ?? [];
        if (locations.isNotEmpty) {
          final firstLocation = locations.first;
          _initialLat = (firstLocation['latitude'] ?? 20.5937).toDouble();
          _initialLng = (firstLocation['longitude'] ?? 78.9629).toDouble();
          _initialMapCenter = LatLng(_initialLat, _initialLng);

          Set<Marker> markers = locations.map<Marker>((location) {
            return Marker(
              markerId: MarkerId(
                location['location_id']?.toString() ?? UniqueKey().toString(),
              ),
              position: LatLng(
                (location['latitude'] ?? 20.5937).toDouble(),
                (location['longitude'] ?? 78.9629).toDouble(),
              ),
              infoWindow: InfoWindow(
                title: location['location_name']?.toString() ??
                    location['name']?.toString() ??
                    'Location Details',
                snippet: location['location_address']?.toString() ??
                    location['address']?.toString() ??
                    '',
              ),
            );
          }).toSet();

          setState(() {
            locationsData = locations;
            _markers = markers;
          });

          if (_initialMapCenter != null && _mapController != null) {
            _mapController!.animateCamera(
              CameraUpdate.newLatLngZoom(_initialMapCenter!, 8),
            );
          }
        }

        // 3. Tile Overlays / Map URL
        String? fetchedMapUrl = result['map_url'];
        if (fetchedMapUrl == null || fetchedMapUrl.isEmpty) {
          fetchedMapUrl = await provider.fetchMapUrl(targetEventId);
        }
        if (fetchedMapUrl != null && fetchedMapUrl.isNotEmpty) {
          _buildTileOverlay(fetchedMapUrl);
        }

        // 4. Update last updated date string
        if (result['last_update_date'] != null ||
            result['updated_at'] != null) {
          final dateMap = result['last_update_date'] ?? result['updated_at'];
          if (dateMap is Map && dateMap['_seconds'] != null) {
            final dt = DateTime.fromMillisecondsSinceEpoch(
                (dateMap['_seconds'] as int) * 1000);
            setState(() {
              _lastUpdatedString =
                  DateFormat('MMM dd, yyyy • HH:mm:ss').format(dt);
            });
          }
        } else if (result['data_source_date'] != null) {
          setState(() {
            _lastUpdatedString = result['data_source_date'].toString();
          });
        }

        // 5. Update other_events in case new ones were returned
        if (result['other_events'] != null && result['other_events'] is List) {
          final otherList = result['other_events'] as List;
          for (var item in otherList) {
            if (item is Map<String, dynamic>) {
              final d = item['date']?.toString();
              final eid = item['event_id']?.toString();
              if (d != null && eid != null) {
                _dateToEventIdMap[d] = eid;
                if (!availableDates.contains(d)) {
                  availableDates.add(d);
                }
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Error loading event $targetEventId: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadStormData() async {
    try {
      final dynamic rawUrls = widget.notificationData['frontendUrls'];

      FrontendUrls? parsedUrls;
      if (rawUrls is FrontendUrls) {
        parsedUrls = rawUrls;
      } else if (rawUrls is Map<String, dynamic>) {
        parsedUrls = FrontendUrls.fromJson(rawUrls);
      } else if (rawUrls is String) {
        try {
          parsedUrls = FrontendUrls.fromJson(jsonDecode(rawUrls));
        } catch (e) {
          debugPrint('Error parsing frontendUrls JSON: $e');
        }
      }

      if (parsedUrls == null) {
        debugPrint(
            'No frontendUrls found in notificationData. Calling _fetchEventInfo fallback.');
        await _fetchEventInfo();
        return;
      }

      String _toProxyUrl(String? url) {
        if (url == null || url.isEmpty) return '';

        if (url.contains('risksphere.ai/api/geojson/proxy')) {
          final uri = Uri.tryParse(url);
          final inner = uri?.queryParameters['url'];
          if (inner != null && inner.isNotEmpty) {
            return 'https://app.risksphere.ai/api/geojson/proxy?url=${Uri.encodeComponent(inner)}';
          }
          return url;
        }
        return 'https://app.risksphere.ai/api/geojson/proxy?url=${Uri.encodeComponent(url)}';
      }

      final resolvedUrls = FrontendUrls(
        stormTrackGeojson: _toProxyUrl(parsedUrls.stormTrackGeojson),
        stormForecastPointsGeojson:
            _toProxyUrl(parsedUrls.stormForecastPointsGeojson),
        stormSwathGeojson: _toProxyUrl(parsedUrls.stormSwathGeojson),
        uiDataGeojson: _toProxyUrl(parsedUrls.uiDataGeojson),
      );

      await loadStormGeoJson(resolvedUrls);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<String> _getLocalFileContent(String filename, String url) async {
    try {
      final response = await _rawHttpClient
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      print(
          "Download $filename finished with status: ${response.statusCode}, body length: ${response.body.length}");
      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw Exception(
            "Failed to download $filename: Status ${response.statusCode}");
      }
    } catch (e) {
      print("Error in download for $filename: $e");
      rethrow;
    }
  }

  Future<void> loadStormGeoJson(FrontendUrls urls) async {
    try {
      final trackUrl = urls.stormTrackGeojson;
      final pointUrl = urls.stormForecastPointsGeojson;
      final swathUrl = urls.stormSwathGeojson;
      final uiDataUrl = urls.uiDataGeojson;

      if (trackUrl == null ||
          trackUrl.isEmpty ||
          pointUrl == null ||
          pointUrl.isEmpty ||
          swathUrl == null ||
          swathUrl.isEmpty ||
          uiDataUrl == null ||
          uiDataUrl.isEmpty) {
        await _fetchEventInfo();
        return;
      }

      String getCacheFilename(String url, String defaultName) {
        try {
          final uri = Uri.parse(url);
          final segments = uri.pathSegments;
          if (segments.length >= 2) {
            return "${segments[segments.length - 2]}_${segments.last}";
          } else if (segments.isNotEmpty) {
            return segments.last;
          }
        } catch (e) {
          print("Error getting cache filename for $url: $e");
        }
        return defaultName;
      }

      final geojsonStrings = await Future.wait([
        _getLocalFileContent(
            getCacheFilename(trackUrl, 'storm_track.geojson'), trackUrl),
        _getLocalFileContent(
            getCacheFilename(pointUrl, 'storm_forecast_points.geojson'),
            pointUrl),
        _getLocalFileContent(
            getCacheFilename(swathUrl, 'storm_swath.geojson'), swathUrl),
        _getLocalFileContent(
            getCacheFilename(uiDataUrl, 'ui_data.geojson'), uiDataUrl),
      ]);

      final parsedJsonList = await Future.wait([
        compute(jsonDecode, geojsonStrings[0]),
        compute(jsonDecode, geojsonStrings[1]),
        compute(jsonDecode, geojsonStrings[2]),
        compute(jsonDecode, geojsonStrings[3]),
      ]);

      final trackJson = parsedJsonList[0];
      final pointJson = parsedJsonList[1];
      final coneJson = parsedJsonList[2];
      final uiDataJson = parsedJsonList[3];

      final BitmapDescriptor redCircleIcon =
          await _getCircleIcon(Colors.red, 24);
      final BitmapDescriptor orangeCircleIcon =
          await _getCircleIcon(Colors.orange, 24);
      final BitmapDescriptor yellowCircleIcon =
          await _getCircleIcon(Colors.yellow, 24);

      // Update class-level cached icons
      _redIcon = redCircleIcon;
      _orangeIcon = orangeCircleIcon;
      _yellowIcon = yellowCircleIcon;

      // Parse all GeoJSON features synchronously (much faster than compute() isolate overhead for these sizes)
      final pointFeatures = pointJson['features'] as List<dynamic>? ?? [];
      final uiFeatures = uiDataJson['features'] as List<dynamic>? ?? [];
      final trackFeatures = trackJson['features'] as List<dynamic>? ?? [];
      final coneFeatures = coneJson['features'] as List<dynamic>? ?? [];

      print(
          "GeoJSON parsed feature counts - Points: ${pointFeatures.length}, UI: ${uiFeatures.length}, Track: ${trackFeatures.length}, Cone: ${coneFeatures.length}");

      final pointMarkerData = _parsePointMarkers({'features': pointFeatures});
      final polylineData = _parsePolylines(trackFeatures);
      final polygonData = _parsePolygonData(coneFeatures);
      final uiMarkerData = _parseUiMarkerData(uiFeatures);

      print(
          "Parsed structures - pointMarkers: ${pointMarkerData.length}, polylineData: ${polylineData.length}, polygonData: ${polygonData.length}, uiMarkers: ${uiMarkerData.length}");

      final Set<Marker> markers = {};

      for (final d in pointMarkerData) {
        BitmapDescriptor icon = yellowCircleIcon;
        if (d['iconType'] == 'red')
          icon = redCircleIcon;
        else if (d['iconType'] == 'orange') icon = orangeCircleIcon;
        markers.add(Marker(
          markerId: MarkerId(d['id'] as String),
          position: LatLng(d['lat'] as double, d['lng'] as double),
          icon: icon,
          anchor: const Offset(0.5, 0.5),
          infoWindow: InfoWindow(
            title: d['name'] as String,
            snippet: d['snippet'] as String,
          ),
        ));
      }

      for (final d in uiMarkerData) {
        final props = d['props'] as Map<String, dynamic>;
        markers.add(Marker(
          markerId: MarkerId(d['id'] as String),
          position: LatLng(d['lat'] as double, d['lng'] as double),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: InfoWindow(
            title: d['title'] as String,
            snippet: d['snippet'] as String,
          ),
          onTap: () => setState(() => _selectedLocationProps = props),
        ));
      }

      final Set<Polyline> polylines = {};
      for (int i = 0; i < polylineData.length; i++) {
        final pts = (polylineData[i]['points'] as List)
            .map((p) => LatLng(p[0] as double, p[1] as double))
            .toList();
        if (pts.length < 2) {
          print("Skipping polyline track_$i with only ${pts.length} points");
          continue;
        }
        polylines.add(Polyline(
          polylineId: PolylineId('track_$i'),
          points: pts,
          color: Colors.red,
          width: 3,
        ));
      }

      final Set<Polygon> polygons = {};
      for (int i = 0; i < polygonData.length; i++) {
        final d = polygonData[i];
        final pts = (d['points'] as List)
            .map((p) => LatLng(p[0] as double, p[1] as double))
            .toList();
        if (pts.length < 3) {
          print("Skipping polygon swath_$i with only ${pts.length} points");
          continue;
        }
        polygons.add(Polygon(
          polygonId: PolygonId('swath_$i'),
          points: pts,
          fillColor: Color(d['fillColor'] as int),
          strokeColor: Color(d['strokeColor'] as int),
          strokeWidth: 1,
        ));
      }

      // Optimize: execute all synchronous mapping builders first
      _buildGlobalStormOverview(trackFeatures, pointFeatures, uiFeatures);
      _buildWindSpeedChart(pointFeatures);
      _buildLocationExposuresFromUiFeatures(uiFeatures);

      // Optimize: Batch state updates to trigger only 1 widget rebuild
      setState(() {
        _markers = markers;
        _polylines = polylines;
        _polygons = polygons;
      });

      if (markers.isNotEmpty) {
        final firstPoint = markers.first.position;
        _initialMapCenter = firstPoint;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _mapController != null) {
            try {
              _mapController!.animateCamera(
                CameraUpdate.newLatLngZoom(firstPoint, 5),
              );
            } catch (_) {}
          }
        });
      }
    } catch (e) {
      print(
          "Error loading or parsing storm GeoJSON: $e. Falling back to _fetchEventInfo...");
      try {
        await _fetchEventInfo();
      } catch (fallbackErr) {
        print("===== FALLBACK ERROR: $fallbackErr =====");
      }
      // Always unblock the spinner so the page doesn't stay stuck
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic> _stormOverview = {
    'stormName': 'N/A',
    'stormId': 'N/A',
    'category': 'N/A',
    'forecastTime': 'N/A',
    'forwardSpeed': 'N/A',
    'trackPointCount': 'N/A',
    'maxWindSpeed': 'N/A',
    'locationsImpacted': 'N/A',
    'totalExposedValue': 'N/A',
    'estClaims': 'N/A',
  };
  Map<String, dynamic>? _selectedLocationProps;

  List<Map<String, dynamic>> _locationExposures = [];

  List<FlSpot> _windSpeedSeries = [];
  List<FlSpot> _intensitySeries = [];
  List<String> _chartDateLabels = [];
  double _maxWindSpeedFromSeries = 0;

  void _buildGlobalStormOverview(
    List<dynamic> trackFeatures,
    List<dynamic> pointFeatures,
    List<dynamic> uiFeatures,
  ) {
    if (trackFeatures.isEmpty) return;

    // The event name the user actually clicked — used as the primary filter.
    final clickedEventName = (widget.notificationData['title'] as String? ?? '')
        .trim()
        .toUpperCase();

    // Helper: does a feature's properties match the clicked event name?
    bool _matchesEvent(dynamic feature) {
      if (clickedEventName.isEmpty) return true; // no filter if title missing
      final props = (feature['properties'] as Map<String, dynamic>?) ?? {};
      final name =
          (props['NAME']?.toString() ?? props['STORMNAME']?.toString() ?? '')
              .trim()
              .toUpperCase();
      return name == clickedEventName || name.isEmpty;
    }

    final filteredTrack = trackFeatures.where(_matchesEvent).toList();
    final filteredPoint = pointFeatures.where(_matchesEvent).toList();
    final filteredUi =
        uiFeatures; // ui_data features rarely carry NAME; use all

    if (filteredTrack.isEmpty && trackFeatures.isNotEmpty) {
      // NAME field doesn't match — fall back to all features (single-storm file)
      print('Storm name filter found no matches — using all track features');
    }

    final sourceTrack =
        filteredTrack.isNotEmpty ? filteredTrack : trackFeatures;
    final sourcePoint =
        filteredPoint.isNotEmpty ? filteredPoint : pointFeatures;

    final trackProps =
        (sourceTrack.first['properties'] as Map<String, dynamic>?) ?? {};

    final stormName = trackProps['NAME']?.toString() ??
        trackProps['STORMNAME']?.toString() ??
        'Unknown';
    final stormId = trackProps['STORMID']?.toString() ??
        trackProps['STORM_ID']?.toString() ??
        'N/A';
    double vmaxKnots = 0.0;
    dynamic rmax = 'N/A';
    for (var feature in sourceTrack) {
      final props = (feature['properties'] as Map<String, dynamic>?) ?? {};
      final val = (props['VMAX'] as num?)?.toDouble() ?? 0.0;
      if (val > vmaxKnots) {
        vmaxKnots = val;
        rmax = props['RMAX'] ?? 'N/A';
      }
    }
    final vmax = vmaxKnots;
    final fspd = trackProps['FSPD'];
    final dtg =
        trackProps['FCST_DTG']?.toString() ?? trackProps['DTG']?.toString();

    _lastUpdatedString = trackProps['RUN_DTG']?.toString() ??
        trackProps['DTG']?.toString() ??
        trackProps['FCST_DTG']?.toString() ??
        'N/A';

    // Financial calculations — scoped to the filtered ui features (supporting pd_value_sum)
    final locationsCount = filteredUi.length;
    double totalTiv = 0.0;
    for (var feature in filteredUi) {
      final props = (feature['properties'] as Map<String, dynamic>?) ?? {};
      final rawTiv =
          props['TIV_Exposed'] ?? props['TIV'] ?? props['pd_value_sum'];
      if (rawTiv != null) {
        final tivVal = (rawTiv is num)
            ? rawTiv.toDouble()
            : double.tryParse(rawTiv.toString());
        if (tivVal != null) {
          totalTiv += tivVal;
        }
      }
    }

    double damageRatio = 0.08;

    double estClaims = totalTiv * damageRatio;

    setState(() {
      _stormOverview = {
        'stormName': clickedEventName.isNotEmpty
            ? widget.notificationData['title']
            : stormName,
        'stormId': stormId,
        'category': _categoryFromVmax(vmax),
        'forecastTime': _formatDtg(dtg),
        'forwardSpeed': fspd != null ? '$fspd mph' : 'N/A',
        'trackPointCount': sourcePoint.length.toString(),
        'maxWindSpeed': vmax > 0
            ? '${vmax.toStringAsFixed(0)} mph (RMAX: $rmax nm)'
            : 'N/A',
        'locationsImpacted': locationsCount.toString(),
        'totalExposedValue': _formatCurrency(totalTiv),
        'estClaims': _formatCurrency(estClaims),
      };
      print(_stormOverview);
    });
  }

  double _categoryValueFromProps(Map<String, dynamic> props) {
    final catDesc = props['CAT_DESC']?.toString().toLowerCase() ?? '';
    if (catDesc.contains('5')) return 5.0;
    if (catDesc.contains('4')) return 4.0;
    if (catDesc.contains('3')) return 3.0;
    if (catDesc.contains('2')) return 2.0;
    if (catDesc.contains('1')) return 1.0;
    if (catDesc.contains('tropical storm') ||
        catDesc.contains('ts') ||
        catDesc.contains('storm')) {
      return 0.5;
    }
    if (catDesc.contains('depression') || catDesc.contains('td')) {
      return 0.2;
    }

    final ssCat = props['SS_CAT'] ?? props['CATEGORY'] ?? props['SSCAT'];
    if (ssCat != null) {
      final double? parsedSS = double.tryParse(ssCat.toString());
      if (parsedSS != null) return parsedSS;
    }

    final vmaxKnots = (props['VMAX'] as num?)?.toDouble() ?? 0.0;
    final vmax = vmaxKnots;
    if (vmax >= 157) return 5.0;
    if (vmax >= 130) return 4.0;
    if (vmax >= 111) return 3.0;
    if (vmax >= 96) return 2.0;
    if (vmax >= 74) return 1.0;
    if (vmax >= 39) return 0.5;
    return 0.0;
  }

  void _buildWindSpeedChart(List<dynamic> pointFeatures) {
    if (pointFeatures.isEmpty) return;

    final clickedEventName = (widget.notificationData['title'] as String? ?? '')
        .trim()
        .toUpperCase();

    final filtered = pointFeatures.where((f) {
      if (clickedEventName.isEmpty) return true;
      final props = (f['properties'] as Map<String, dynamic>?) ?? {};
      final name =
          (props['NAME']?.toString() ?? props['STORMNAME']?.toString() ?? '')
              .trim()
              .toUpperCase();
      return name == clickedEventName || name.isEmpty;
    }).toList();

    final sourcePoints = filtered.isNotEmpty ? filtered : pointFeatures;

    final sortedPoints = List<dynamic>.from(sourcePoints);
    sortedPoints.sort((a, b) {
      final dtgA =
          ((a['properties'] as Map<String, dynamic>?)?['DTG'] ?? '').toString();
      final dtgB =
          ((b['properties'] as Map<String, dynamic>?)?['DTG'] ?? '').toString();
      return dtgA.compareTo(dtgB);
    });

    // Use all points instead of just the last 10
    final lastFivePoints = sortedPoints;

    final wind = <FlSpot>[];
    final intensity = <FlSpot>[];
    final labels = <String>[];

    int indexCounter = 0;
    for (var i = 0; i < lastFivePoints.length; i++) {
      final props =
          (lastFivePoints[i]['properties'] as Map<String, dynamic>?) ?? {};
      final dtg = (props['DTG'] ?? '').toString();
      final vKnots = (props['VMAX'] as num?)?.toDouble();
      if (vKnots != null) {
        final v = vKnots;
        wind.add(FlSpot(indexCounter.toDouble(), v));
        intensity.add(
            FlSpot(indexCounter.toDouble(), _categoryValueFromProps(props)));
        labels.add(_formatDtgShort(dtg));
        indexCounter++;
      }
    }

    setState(() {
      _windSpeedSeries = wind;
      _intensitySeries = intensity;
      _chartDateLabels = labels;
      _maxWindSpeedFromSeries = wind.isEmpty
          ? 0
          : wind.map((e) => e.y).reduce((a, b) => a > b ? a : b);
      print("===== WIND SPEED CHART DATA =====");
      print(
          "WIND SPEED SERIES (spots): ${wind.map((e) => '(${e.x}, ${e.y})').toList()}");
      print(
          "INTENSITY SERIES (spots): ${intensity.map((e) => '(${e.x}, ${e.y})').toList()}");
      print("CHART LABELS: $labels");
    });
  }

  void _buildLocationExposuresFromUiFeatures(List<dynamic> uiFeatures) {
    final exposures = <Map<String, dynamic>>[];
    final RegExp nonNumericRegex = RegExp(r'[^0-9.]');

    for (var feature in uiFeatures) {
      final props = (feature['properties'] as Map<String, dynamic>?) ?? {};

      final locationName = props['LocationName']?.toString() ??
          props['name']?.toString() ??
          props['address']?.toString() ??
          'Unknown Location';
      final county = props['County']?.toString() ??
          props['county_name']?.toString() ??
          props['county']?.toString() ??
          '-';
      final stateValue =
          props['State']?.toString() ?? props['state']?.toString() ?? '-';
      final categoryLabel =
          props['usofcl_fcst_sscats_LABEL']?.toString() ?? '-';
      final rawTiv =
          props['TIV_Exposed'] ?? props['TIV'] ?? props['pd_value_sum'];
      double tivVal = 0.0;
      if (rawTiv is num) {
        tivVal = rawTiv.toDouble();
      } else if (rawTiv != null) {
        tivVal = double.tryParse(rawTiv.toString()) ?? 0.0;
      }
      final tiv = _formatCurrency(tivVal);

      // Parse wind speed for Event Score calculation
      final windSpeedRaw = props['usofcl_swath_wind_mph_LABEL'] ??
          props['wind_speed'] ??
          props['windSpeed'] ??
          props['max_wind_speed'] ??
          props['MaxWindSpeed'] ??
          props['wind'] ??
          props['wind_mph'] ??
          props['vmax'] ??
          props['VMAX'];

      double? windSpeedNum;
      if (windSpeedRaw is num) {
        windSpeedNum = windSpeedRaw.toDouble();
      } else if (windSpeedRaw != null) {
        windSpeedNum = double.tryParse(
            windSpeedRaw.toString().replaceAll(nonNumericRegex, ''));
      }

      // Calculate event score (0-100 scale derived from wind speed matching Web)
      int eventScore = 0;
      if (windSpeedNum != null) {
        eventScore = ((windSpeedNum / 157.0) * 100.0).round().clamp(0, 100);
      }

      int overallScore = 0;
      final rawOverallScore =
          props['overall_score'] ?? props['score'] ?? props['overallScore'];
      if (rawOverallScore is num) {
        overallScore = rawOverallScore.toInt();
      } else if (rawOverallScore != null) {
        overallScore = int.tryParse(rawOverallScore.toString()) ?? 0;
      }

      final geometry = feature['geometry'];
      final coords =
          geometry != null ? geometry['coordinates'] as List<dynamic>? : null;
      final lat =
          (coords != null && coords.length >= 2) ? coords[1].toDouble() : null;
      final lng =
          (coords != null && coords.length >= 2) ? coords[0].toDouble() : null;

      exposures.add({
        'city': locationName,
        'county': county,
        'state': stateValue,
        'category': categoryLabel,
        'tiv': tiv,
        'event_score': eventScore,
        'overall_score': overallScore,
        'catColor': _colorForCategory(categoryLabel),
        'lat': lat,
        'lng': lng,
        'rawProps': props,
        'hazards': {
          'Surge': props['usofcl_fcst_surge_ft_LABEL']?.toString(),
          'Rain': props['usofcl_fcst_rain_in_LABEL']?.toString(),
          'Wave': props['usofcl_fcst_wave_ft_LABEL']?.toString(),
          'Wind': windSpeedNum != null
              ? '${windSpeedNum.toStringAsFixed(0)} mph'
              : windSpeedRaw?.toString(),
        },
      });
    }

    setState(() {
      _locationExposures = exposures;
      _selectedLocationProps ??= uiFeatures.isNotEmpty
          ? (uiFeatures.first['properties'] as Map<String, dynamic>?)
          : null;
      print(_selectedLocationProps);
    });
  }

  String? _firstNonEmpty(Map<String, dynamic> props, List<String> keys) {
    for (final key in keys) {
      final value = props[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return null;
  }

  String _categoryFromVmax(double vmax) {
    if (vmax >= 157) return 'Category 5\n(157+ mph)';
    if (vmax >= 130) return 'Category 4\n(130-156 mph)';
    if (vmax >= 111) return 'Category 3\n(111-129 mph)';
    if (vmax >= 96) return 'Category 2\n(96-110 mph)';
    if (vmax >= 74) return 'Category 1\n(74-95 mph)';
    if (vmax >= 39) return 'Tropical Storm\n(39-73 mph)';
    return 'Tropical Depression\n(<39 mph)';
  }

  String _formatDtg(String? dtg) {
    if (dtg == null || dtg.isEmpty) return 'N/A';
    try {
      String year = '';
      int month = 0;
      String day = '';
      String hour = '';
      String minute = '00';

      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];

      if (dtg.contains('-')) {
        final parts = dtg.trim().split(' ');
        final dateParts = parts[0].split('-');
        year = dateParts[0];
        month = int.parse(dateParts[1]);
        day = dateParts[2];
        if (parts.length > 1) {
          final timeParts = parts[1].split(':');
          hour = timeParts[0];
          if (timeParts.length > 1) {
            minute = timeParts[1];
          }
        }
      } else {
        final trimmed = dtg.trim();
        if (trimmed.length >= 10) {
          year = trimmed.substring(0, 4);
          month = int.parse(trimmed.substring(4, 6));
          day = trimmed.substring(6, 8);
          hour = trimmed.substring(8, 10);
        } else {
          return dtg;
        }
      }

      final monthStr = months[month - 1];
      return '$day $monthStr $year\n$hour:$minute UTC';
    } catch (_) {
      return dtg;
    }
  }

  String _formatDtgShort(String? dtg) {
    if (dtg == null || dtg.isEmpty) return '';
    try {
      final parsedDt = DateTime.tryParse(dtg);
      if (parsedDt != null) {
        return DateFormat('MMM dd\nHH:mm').format(parsedDt);
      }

      if (dtg.length == 10 && RegExp(r'^\d{10}$').hasMatch(dtg)) {
        final month = int.parse(dtg.substring(4, 6));
        final day = int.parse(dtg.substring(6, 8));
        final hour = dtg.substring(8, 10);
        const months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec'
        ];
        return '${months[month - 1]} $day\n$hour:00';
      }

      // Fallback format: yyyyMMdd
      if (dtg.length == 8 && RegExp(r'^\d{8}$').hasMatch(dtg)) {
        final month = int.parse(dtg.substring(4, 6));
        final day = int.parse(dtg.substring(6, 8));
        const months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec'
        ];
        return '${months[month - 1]} $day';
      }

      if (dtg.contains(' ')) {
        return dtg.split(' ').join('\n');
      }
      return dtg;
    } catch (_) {
      if (dtg.contains(' ')) {
        return dtg.split(' ').join('\n');
      }
      return dtg;
    }
  }

  String _formatCurrency(dynamic raw) {
    if (raw == null) return 'N/A';
    final value =
        (raw is num) ? raw.toDouble() : double.tryParse(raw.toString());
    if (value == null) return raw.toString();
    if (value >= 1e9) return '\$${(value / 1e9).toStringAsFixed(1)}B';
    if (value >= 1e6) return '\$${(value / 1e6).toStringAsFixed(1)}M';
    if (value >= 1e3) return '\$${(value / 1e3).toStringAsFixed(1)}K';
    return '\$${value.toStringAsFixed(0)}';
  }

  Color _colorForCategory(String category) {
    if (category.contains('5') || category.contains('4')) return Colors.red;
    if (category.contains('3') || category.contains('2')) {
      return Colors.orange;
    }
    if (category.contains('1') ||
        category.toLowerCase().contains('tropical storm')) {
      return Colors.yellow;
    }
    return Colors.grey;
  }

  Color _getRatingColor(int rating) {
    switch (rating) {
      case 5:
        return Colors.green;
      case 4:
        return Colors.lightGreen;
      case 3:
        return Colors.orange;
      case 2:
        return Colors.redAccent;
      case 1:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<BitmapDescriptor> _getCircleIcon(Color color, int size) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final double radius = size / 2.0;
    canvas.drawCircle(Offset(radius, radius), radius - 2.0, paint);
    canvas.drawCircle(Offset(radius, radius), radius - 2.0, borderPaint);

    final ui.Image image =
        await pictureRecorder.endRecording().toImage(size, size);
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
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

    await provider.fetchEventInfo(
      eventId: eventId,
    );

    final result = provider.eventInfo;

    if (result.isNotEmpty) {
      final locations = result['locations_data'] as List<dynamic>? ?? [];

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
            location['location_id']?.toString() ?? UniqueKey().toString(),
          ),
          position: LatLng(
            (location['latitude'] ?? 20.5937).toDouble(),
            (location['longitude'] ?? 78.9629).toDouble(),
          ),
          infoWindow: InfoWindow(
            title: location['location_name']?.toString() ??
                location['name']?.toString() ??
                'Location Details',
            snippet: location['location_address']?.toString() ??
                location['address']?.toString() ??
                '',
          ),
        );
      }).toSet();

      setState(() {
        locationsData = locations;
        _markers = markers;
        _isLoading = false;
      });

      /// MOVE CAMERA TO FIRST LOCATION
      if (_initialMapCenter != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _mapController != null) {
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

  @override
  void dispose() {
    routeObserver.unsubscribe(this); // Always unsubscribe to avoid memory leaks
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Consumer<ThemeProvider>(builder: (
        context,
        themeProvider,
        child,
      ) {
        return Scaffold(
          backgroundColor: const Color(0xFF0D0D0D),
          appBar: CustomAppBar(
            isExpanded: _isExpanded,
            showDropdown: false,
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
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HazardInfoSection(
                  hazardName: widget.notificationData['title'] ??
                      widget.notificationData['eventName'] ??
                      "Event Hazard",
                  hazardType: widget.notificationData['hazardName'] ??
                      widget.notificationData['hazard_name'] ??
                      _stormOverview['hazardName'],
                  selectedDate: selectedDate ?? "",
                  availableDates: availableDates,
                  lastUpdated: _lastUpdatedString,
                  onDateChanged: _onDateChanged,
                  onRefresh: () {
                    setState(() => _isLoading = true);
                    _initialize();
                  },
                  trailingWidget: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.map, color: Colors.white70, size: 18),
                      const SizedBox(width: 4),
                      Switch(
                        value: _showMap,
                        onChanged: (val) {
                          setState(() {
                            _showMap = val;
                          });
                        },
                        activeColor: const Color(0xFF2196F3),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  height: (_showMap || _isLoading)
                      ? MediaQuery.of(context).size.height * 0.42
                      : 0,
                  child: ClipRect(
                    child: Offstage(
                        offstage: !(_showMap || _isLoading),
                        child: _isLoading
                            ? _buildMapShimmer()
                            : isMapView
                                ? Stack(
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.fromLTRB(
                                            16, 1, 16, 2.0),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(20.0),
                                          color: Colors.grey.shade100,
                                        ),
                                        clipBehavior: Clip.antiAlias,
                                        child: GoogleMap(
                                          onMapCreated: (controller) {
                                            _mapController = controller;
                                          },
                                          initialCameraPosition: CameraPosition(
                                            target: _initialMapCenter ??
                                                LatLng(20.5937, 78.9629),
                                            zoom: 5,
                                          ),
                                          markers: _markers,
                                          polylines: _polylines,
                                          polygons: _polygons,
                                          tileOverlays: _tileOverlays,
                                          mapToolbarEnabled: false,
                                          zoomControlsEnabled: false,
                                          myLocationEnabled: true,
                                          mapType: _currentMapType,
                                          myLocationButtonEnabled: false,
                                          onCameraMove: (position) {
                                            _currentCameraPosition = position;
                                            if (_tileOverlays.isNotEmpty &&
                                                _mapController != null) {
                                              final overlay =
                                                  _tileOverlays.first;
                                              _mapController!.clearTileCache(
                                                  overlay.tileOverlayId);
                                            }
                                          },
                                        ),
                                      ),

                                      // Custom Map Type Toggle (Top Left)
                                      Positioned(
                                        top: 12,
                                        left: 28,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withOpacity(0.3),
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  InkWell(
                                                    onTap: () {
                                                      setState(() {
                                                        if (_currentMapType ==
                                                                MapType
                                                                    .normal ||
                                                            _currentMapType ==
                                                                MapType
                                                                    .terrain) {
                                                          _showMapMenu =
                                                              !_showMapMenu;
                                                        } else {
                                                          _currentMapType =
                                                              MapType.normal;
                                                          _showMapMenu = true;
                                                        }
                                                      });
                                                    },
                                                    child: Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 16,
                                                          vertical: 8),
                                                      decoration: BoxDecoration(
                                                        border: Border(
                                                          right: BorderSide(
                                                              color: Colors.grey
                                                                  .shade300),
                                                        ),
                                                      ),
                                                      child: Text(
                                                        'Map',
                                                        style: TextStyle(
                                                          color: (_currentMapType ==
                                                                      MapType
                                                                          .normal ||
                                                                  _currentMapType ==
                                                                      MapType
                                                                          .terrain)
                                                              ? Colors.black
                                                              : Colors.grey
                                                                  .shade700,
                                                          fontWeight: (_currentMapType ==
                                                                      MapType
                                                                          .normal ||
                                                                  _currentMapType ==
                                                                      MapType
                                                                          .terrain)
                                                              ? FontWeight.bold
                                                              : FontWeight.w500,
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  InkWell(
                                                    onTap: () {
                                                      setState(() {
                                                        if (_currentMapType ==
                                                                MapType
                                                                    .satellite ||
                                                            _currentMapType ==
                                                                MapType
                                                                    .hybrid) {
                                                          _showMapMenu =
                                                              !_showMapMenu;
                                                        } else {
                                                          _currentMapType =
                                                              MapType.satellite;
                                                          _showMapMenu = true;
                                                        }
                                                      });
                                                    },
                                                    child: Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 16,
                                                          vertical: 8),
                                                      child: Text(
                                                        'Satellite',
                                                        style: TextStyle(
                                                          color: (_currentMapType ==
                                                                      MapType
                                                                          .satellite ||
                                                                  _currentMapType ==
                                                                      MapType
                                                                          .hybrid)
                                                              ? Colors.black
                                                              : Colors.grey
                                                                  .shade700,
                                                          fontWeight: (_currentMapType ==
                                                                      MapType
                                                                          .satellite ||
                                                                  _currentMapType ==
                                                                      MapType
                                                                          .hybrid)
                                                              ? FontWeight.bold
                                                              : FontWeight.w500,
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (_showMapMenu)
                                              Container(
                                                margin: EdgeInsets.only(
                                                  top: 2,
                                                  left: (_currentMapType ==
                                                              MapType.normal ||
                                                          _currentMapType ==
                                                              MapType.terrain)
                                                      ? 0
                                                      : 64,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withOpacity(0.3),
                                                      blurRadius: 4,
                                                      offset:
                                                          const Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: InkWell(
                                                  onTap: () {
                                                    setState(() {
                                                      if (_currentMapType ==
                                                          MapType.normal) {
                                                        _currentMapType =
                                                            MapType.terrain;
                                                      } else if (_currentMapType ==
                                                          MapType.terrain) {
                                                        _currentMapType =
                                                            MapType.normal;
                                                      } else if (_currentMapType ==
                                                          MapType.satellite) {
                                                        _currentMapType =
                                                            MapType.hybrid;
                                                      } else if (_currentMapType ==
                                                          MapType.hybrid) {
                                                        _currentMapType =
                                                            MapType.satellite;
                                                      }
                                                    });
                                                  },
                                                  child: Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 12,
                                                        vertical: 8),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          (_currentMapType ==
                                                                      MapType
                                                                          .terrain ||
                                                                  _currentMapType ==
                                                                      MapType
                                                                          .hybrid)
                                                              ? Icons.check_box
                                                              : Icons
                                                                  .check_box_outline_blank,
                                                          size: 16,
                                                          color: Colors.black87,
                                                        ),
                                                        const SizedBox(
                                                            width: 6),
                                                        Text(
                                                          (_currentMapType ==
                                                                      MapType
                                                                          .normal ||
                                                                  _currentMapType ==
                                                                      MapType
                                                                          .terrain)
                                                              ? 'Terrain'
                                                              : 'Labels',
                                                          style:
                                                              const TextStyle(
                                                                  fontSize: 13,
                                                                  color: Colors
                                                                      .black87),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),

                                          ],
                                        ),
                                      ),

                                      // 3D View Toggle (Top Right)
                                      Positioned(
                                        top: 16,
                                        right: 16,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(4),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.3),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: InkWell(
                                            onTap: () {
                                              setState(() {
                                                _is3DView = !_is3DView;
                                              });
                                              if (_mapController != null && _currentCameraPosition != null) {
                                                _mapController!.animateCamera(
                                                  CameraUpdate.newCameraPosition(
                                                    CameraPosition(
                                                      target: _currentCameraPosition!.target,
                                                      zoom: _currentCameraPosition!.zoom,
                                                      bearing: _currentCameraPosition!.bearing,
                                                      tilt: _is3DView ? 60.0 : 0.0,
                                                    )
                                                  )
                                                );
                                              }
                                            },
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    _is3DView ? Icons.check_box : Icons.check_box_outline_blank,
                                                    size: 16,
                                                    color: Colors.black87,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  const Text(
                                                    '3D View',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),

                                      // Custom Zoom Controls (Bottom Right)
                                      Positioned(
                                        bottom: 16,
                                        right: 28,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.3),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              InkWell(
                                                onTap: () {
                                                  _mapController?.animateCamera(
                                                      CameraUpdate.zoomIn());
                                                },
                                                child: const Padding(
                                                  padding: EdgeInsets.all(8.0),
                                                  child: Icon(Icons.add,
                                                      size: 20,
                                                      color: Colors.black87),
                                                ),
                                              ),
                                              Container(
                                                height: 1,
                                                width: 36,
                                                color: Colors.grey.shade300,
                                              ),
                                              InkWell(
                                                onTap: () {
                                                  _mapController?.animateCamera(
                                                      CameraUpdate.zoomOut());
                                                },
                                                child: const Padding(
                                                  padding: EdgeInsets.all(8.0),
                                                  child: Icon(Icons.remove,
                                                      size: 20,
                                                      color: Colors.black87),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      if (_isLoading)
                                        Positioned.fill(child: _buildListShimmer()),
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
                                                    padding:
                                                        const EdgeInsets.all(
                                                            12),
                                                    decoration: BoxDecoration(
                                                      border: Border(
                                                        right: BorderSide(
                                                          color: Colors
                                                              .grey.shade700,
                                                        ),
                                                      ),
                                                    ),
                                                    child: const Text(
                                                        "Location Name"),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 4,
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            12),
                                                    decoration: BoxDecoration(
                                                      border: Border(
                                                        right: BorderSide(
                                                          color: Colors
                                                              .grey.shade700,
                                                        ),
                                                      ),
                                                    ),
                                                    child:
                                                        const Text("Address"),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 2,
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            12),
                                                    decoration: BoxDecoration(
                                                      border: Border(
                                                        right: BorderSide(
                                                          color: Colors
                                                              .grey.shade700,
                                                        ),
                                                      ),
                                                    ),
                                                    child: const Text(
                                                        "Hazard Name"),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 2,
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            12),
                                                    child: const Text(
                                                        "Event Name"),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: _isLoading
                                              ? _buildListShimmer()
                                              : locationsData.isEmpty
                                                  ? _buildEmptyState(
                                                      "No Exposed Area Metadata",
                                                      Icons
                                                          .location_off_outlined,
                                                    )
                                                  : ListView.builder(
                                                      itemCount:
                                                          locationsData.length,
                                                      itemBuilder:
                                                          (context, index) {
                                                        final location =
                                                            locationsData[
                                                                index];

                                                        final eventMap = location[
                                                                    'event']
                                                                as Map<String,
                                                                    dynamic>? ??
                                                            {};

                                                        final firstEvent =
                                                            eventMap.isNotEmpty
                                                                ? eventMap
                                                                        .values
                                                                        .first
                                                                    as Map<
                                                                        String,
                                                                        dynamic>
                                                                : {};

                                                        return Container(
                                                          decoration:
                                                              BoxDecoration(
                                                            border: Border(
                                                              left: BorderSide(
                                                                color: Colors
                                                                    .grey
                                                                    .shade700,
                                                              ),
                                                              right: BorderSide(
                                                                color: Colors
                                                                    .grey
                                                                    .shade700,
                                                              ),
                                                              bottom:
                                                                  BorderSide(
                                                                color: Colors
                                                                    .grey
                                                                    .shade700,
                                                              ),
                                                            ),
                                                          ),
                                                          child:
                                                              IntrinsicHeight(
                                                            child: Row(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .stretch,
                                                              children: [
                                                                Expanded(
                                                                  flex: 3,
                                                                  child:
                                                                      Container(
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .all(
                                                                            12),
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      border:
                                                                          Border(
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
                                                                      maxLines:
                                                                          2,
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis,
                                                                    ),
                                                                  ),
                                                                ),
                                                                Expanded(
                                                                  flex: 4,
                                                                  child:
                                                                      Container(
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .all(
                                                                            12),
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      border:
                                                                          Border(
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
                                                                      maxLines:
                                                                          3,
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis,
                                                                    ),
                                                                  ),
                                                                ),
                                                                Expanded(
                                                                  flex: 2,
                                                                  child:
                                                                      Container(
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .all(
                                                                            12),
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      border:
                                                                          Border(
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
                                                                      maxLines:
                                                                          2,
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis,
                                                                    ),
                                                                  ),
                                                                ),
                                                                Expanded(
                                                                  flex: 2,
                                                                  child:
                                                                      Container(
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .all(
                                                                            12),
                                                                    child: Text(
                                                                      firstEvent['event_name']
                                                                              ?.toString() ??
                                                                          '',
                                                                      maxLines:
                                                                          2,
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
                  ),
                ),
                _buildTabBar(),
                Expanded(
                  child: _selectedTab == 0
                      ? _buildOverviewTab()
                      : _buildLocationExposureTab(),
                ),
                // _buildBottomNavigation(),
              ],
            ),
          ),
        );
      }),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedTab = index),
          borderRadius: BorderRadius.circular(8),
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
      ),
    );
  }

  // ─── Overview Tab (now driven by _stormOverview / selected location) ──
  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStormOverviewCard(),
          const SizedBox(height: 16),
          _buildHurricaneSummaryCard(),
          const SizedBox(height: 16),
          _buildStormMovementCard(),
          const SizedBox(height: 16),
          _buildCriticalInfrastructureCard(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title,
      {bool showGraphToggle = false, VoidCallback? onExpandPressed}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.primaryMain,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Row(
          children: [
            if (showGraphToggle) ...[
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
            if (onExpandPressed != null) ...[
              const SizedBox(width: 8),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: onExpandPressed,
                icon: const Icon(
                  Icons.fullscreen,
                  color: Colors.white70,
                  size: 24,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  void _showFullscreenGraphDialog(String title, Widget graphWidget,
      {Widget? statsWidget}) {
    // Force Landscape orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: true,
          onPopInvokedWithResult: (didPop, result) {
            SystemChrome.setPreferredOrientations([
              DeviceOrientation.portraitUp,
            ]);
          },
          child: Dialog.fullscreen(
            backgroundColor: const Color(0xFF121212),
            child: SafeArea(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () {
                            // Restore orientation
                            SystemChrome.setPreferredOrientations([
                              DeviceOrientation.portraitUp,
                            ]);
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white24, height: 1),
                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: MediaQuery.of(context).size.height * 0.55,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: graphWidget,
                          ),
                          if (statsWidget != null) ...[
                            const SizedBox(height: 12),
                            statsWidget,
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStormOverviewCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildSectionHeader(
              'Storm Overview',
              showGraphToggle: true,
              onExpandPressed: _showGraph
                  ? () => _showFullscreenGraphDialog(
                      'Storm Overview', _buildStormGraph(),
                      statsWidget: _buildGraphStats())
                  : null,
            ),
          ),
          const SizedBox(height: 4),
          Divider(
            color: Colors.white.withOpacity(0.15),
            thickness: 1,
            height: 1,
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _showGraph
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStormGraph(),
                      const SizedBox(height: 12),
                      _buildGraphStats(),
                      const SizedBox(height: 20),
                      _buildSectionHeader(
                        'Storm Intensity Over Time',
                        onExpandPressed: () => _showFullscreenGraphDialog(
                            'Storm Intensity Over Time',
                            _buildStormIntensityGraph()),
                      ),
                      const SizedBox(height: 12),
                      _buildStormIntensityGraph(),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildOverviewItem('Storm Name',
                          _stormOverview['stormName']?.toString() ?? 'N/A'),
                      _buildOverviewItem('Storm Category',
                          _stormOverview['category']?.toString() ?? 'N/A'),
                      _buildOverviewItem('Forecast Time',
                          _stormOverview['forecastTime']?.toString() ?? 'N/A'),
                    ],
                  ),
          ),
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
              maxLines: 2,
              style: const TextStyle(color: Colors.white38, fontSize: 10)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  List<FlSpot> _getMockedSurgeSeries() {
    return _windSpeedSeries.map((spot) {
      double surgeVal = spot.y > 30 ? (spot.y - 30) * 0.15 : 0.0;
      return FlSpot(spot.x, surgeVal * 8);
    }).toList();
  }

  List<FlSpot> _getMockedRainSeries() {
    return _windSpeedSeries.map((spot) {
      double rainVal = spot.y > 20 ? (spot.y - 20) * 0.1 : 0.0;
      return FlSpot(spot.x, rainVal * 8);
    }).toList();
  }

  List<FlSpot> _getMockedWaveSeries() {
    return _windSpeedSeries.map((spot) {
      double waveVal = spot.y > 30 ? (spot.y - 30) * 0.2 : 0.0;
      return FlSpot(spot.x, waveVal * 8);
    }).toList();
  }

  Widget _buildStormGraph() {
    double maxGraphY = 160.0;
    if (_maxWindSpeedFromSeries > 0) {
      final maxWind = _maxWindSpeedFromSeries;
      final maxSurge = maxWind > 30 ? (maxWind - 30) * 0.15 * 8 : 0.0;
      final maxRain = maxWind > 20 ? (maxWind - 20) * 0.1 * 8 : 0.0;
      final maxWave = maxWind > 30 ? (maxWind - 30) * 0.2 * 8 : 0.0;

      if (maxWind > maxGraphY) maxGraphY = maxWind;
      if (maxSurge > maxGraphY) maxGraphY = maxSurge;
      if (maxRain > maxGraphY) maxGraphY = maxRain;
      if (maxWave > maxGraphY) maxGraphY = maxWave;

      maxGraphY = (maxGraphY * 1.1).ceilToDouble();
    }

    return Container(
        height: 200,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(10),
        ),
        child: _windSpeedSeries.isEmpty
            ? const Center(
                child: Text(
                  'No forecast wind data available',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              )
            : LineChart(
                LineChartData(
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) =>
                          const Color(0xFF000000).withOpacity(0.85),
                      maxContentWidth: 160,
                      tooltipPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      getTooltipItems: (List<LineBarSpot> touchedSpots) {
                        if (touchedSpots.isEmpty) return [];

                        final int xIndex = touchedSpots.first.x.toInt();
                        final String dateHeader =
                            (xIndex >= 0 && xIndex < _chartDateLabels.length)
                                ? _chartDateLabels[xIndex]
                                : '';

                        double windVal = 0;
                        double surgeVal = 0;
                        double rainVal = 0;
                        double waveVal = 0;

                        if (xIndex >= 0 && xIndex < _windSpeedSeries.length) {
                          windVal = _windSpeedSeries[xIndex].y;
                        }
                        final surgeSeries = _getMockedSurgeSeries();
                        if (xIndex >= 0 && xIndex < surgeSeries.length) {
                          surgeVal = surgeSeries[xIndex].y / 8;
                        }
                        final rainSeries = _getMockedRainSeries();
                        if (xIndex >= 0 && xIndex < rainSeries.length) {
                          rainVal = rainSeries[xIndex].y / 8;
                        }
                        final waveSeries = _getMockedWaveSeries();
                        if (xIndex >= 0 && xIndex < waveSeries.length) {
                          waveVal = waveSeries[xIndex].y / 8;
                        }

                        return touchedSpots.map((spot) {
                          if (spot == touchedSpots.first) {
                            // Clean up the date string formatting if it has newlines
                            final cleanDate = dateHeader.replaceAll('\n', ' ');
                            return LineTooltipItem(
                              '$cleanDate\n',
                              const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                height: 1.6,
                              ),
                              children: [
                                TextSpan(
                                  text:
                                      '🟥 Max Wind: ${windVal.toStringAsFixed(0)}\n',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.normal),
                                ),
                                TextSpan(
                                  text:
                                      '🟪 Max Surge: ${surgeVal.toStringAsFixed(1)}\n',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.normal),
                                ),
                                TextSpan(
                                  text:
                                      '🟦 Max Rainfall: ${rainVal.toStringAsFixed(1)}\n',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.normal),
                                ),
                                TextSpan(
                                  text:
                                      '🟩 Max Wave Height: ${waveVal.toStringAsFixed(1)}\n',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.normal),
                                ),
                                TextSpan(
                                  text:
                                      '⬜ Impacted Locations: ${_locationExposures.length}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.normal),
                                ),
                              ],
                            );
                          }
                          return null;
                        }).toList();
                      },
                    ),
                    handleBuiltInTouches: true,
                  ),
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
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 8),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        interval: _chartDateLabels.length > 5
                            ? (_chartDateLabels.length / 5).ceilToDouble()
                            : 1,
                        getTitlesWidget: (value, _) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= _chartDateLabels.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              _chartDateLabels[idx],
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 8),
                              textAlign: TextAlign.center,
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, _) {
                          final rightVal = value / 8;
                          if (rightVal % 5 == 0) {
                            return Text(
                              rightVal.toInt().toString(),
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 8),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  minY: 0,
                  maxY: maxGraphY,
                  clipData: const FlClipData.all(),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    _buildLine(_windSpeedSeries, Colors.red),
                    _buildLine(_getMockedSurgeSeries(), Colors.purple),
                    _buildLine(_getMockedRainSeries(), Colors.blue),
                    _buildLine(_getMockedWaveSeries(), Colors.teal),
                  ],
                ),
              ));
  }

  Color _getIntensityBarColor(double value) {
    if (value >= 4) return const Color(0xFFD96666);
    if (value >= 2) return const Color(0xFFE69B35);
    return const Color(0xFF359CE6);
  }

  Widget _buildStormIntensityGraph() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(10),
      ),
      child: _intensitySeries.isEmpty
          ? const Center(
              child: Text(
                'No intensity timeline data available',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final double totalWidth = _intensitySeries.length * 20.0;
                final double chartWidth = totalWidth > constraints.maxWidth
                    ? totalWidth
                    : constraints.maxWidth;
                final ScrollController scrollController = ScrollController();

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (scrollController.hasClients &&
                      totalWidth > constraints.maxWidth) {
                    scrollController
                        .jumpTo(scrollController.position.maxScrollExtent);
                  }
                });

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 40,
                      child: BarChart(
                        BarChartData(
                          backgroundColor: Colors.transparent,
                          gridData: FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 36,
                                getTitlesWidget: (value, _) {
                                  if (value == 0.0 || value == 0.5)
                                    return const Text('TS',
                                        style: TextStyle(
                                            color: Colors.white38,
                                            fontSize: 8));
                                  if (value == 1.0)
                                    return const Text('Cat 1',
                                        style: TextStyle(
                                            color: Colors.white38,
                                            fontSize: 8));
                                  if (value == 2.0)
                                    return const Text('Cat 2',
                                        style: TextStyle(
                                            color: Colors.white38,
                                            fontSize: 8));
                                  if (value == 3.0)
                                    return const Text('Cat 3',
                                        style: TextStyle(
                                            color: Colors.white38,
                                            fontSize: 8));
                                  if (value == 4.0)
                                    return const Text('Cat 4',
                                        style: TextStyle(
                                            color: Colors.white38,
                                            fontSize: 8));
                                  if (value == 5.0)
                                    return const Text('Cat 5',
                                        style: TextStyle(
                                            color: Colors.white38,
                                            fontSize: 8));
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 32,
                                getTitlesWidget: (value, _) =>
                                    const SizedBox.shrink(),
                              ),
                            ),
                            rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                          ),
                          minY: 0,
                          maxY: 5,
                          barGroups: [],
                        ),
                      ),
                    ),
                    // Scrollable Graph
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: chartWidth,
                          child: BarChart(
                            BarChartData(
                              barTouchData: BarTouchData(
                                enabled: true,
                                touchTooltipData: BarTouchTooltipData(
                                  getTooltipColor: (_) =>
                                      const Color(0xFF000000).withOpacity(0.85),
                                  getTooltipItem:
                                      (group, groupIndex, rod, rodIndex) {
                                    final dateLabel = group.x.toInt() >= 0 &&
                                            group.x.toInt() <
                                                _chartDateLabels.length
                                        ? _chartDateLabels[group.x.toInt()]
                                        : '';
                                    final cleanDate =
                                        dateLabel.replaceAll('\n', ' ');

                                    String catText = '';
                                    if (rod.toY <= 0.5)
                                      catText = 'TS';
                                    else if (rod.toY == 1.0)
                                      catText = 'Category 1';
                                    else if (rod.toY == 2.0)
                                      catText = 'Category 2';
                                    else if (rod.toY == 3.0)
                                      catText = 'Category 3';
                                    else if (rod.toY == 4.0)
                                      catText = 'Category 4';
                                    else if (rod.toY >= 5.0)
                                      catText = 'Category 5';
                                    else
                                      catText =
                                          'Category ${rod.toY.toStringAsFixed(1)}';

                                    String icon = '🟦';
                                    if (rod.toY >= 4)
                                      icon = '🟥';
                                    else if (rod.toY >= 2) icon = '🟧';

                                    return BarTooltipItem(
                                      '$cleanDate\n',
                                      const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: '$icon $catText',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.normal),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                              alignment: BarChartAlignment.spaceAround,
                              backgroundColor: Colors.transparent,
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
                                // Hide left titles since they are shown in the pinned chart
                                leftTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 32,
                                    interval: 1,
                                    // With scrolling, we can afford interval 1
                                    getTitlesWidget: (value, _) {
                                      final idx = value.toInt();
                                      // Skip every other label if there are too many bars
                                      if (idx % 2 != 0 &&
                                          totalWidth > constraints.maxWidth)
                                        return const SizedBox.shrink();
                                      if (idx < 0 ||
                                          idx >= _chartDateLabels.length) {
                                        return const SizedBox.shrink();
                                      }
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(top: 4.0),
                                        child: Text(
                                          _chartDateLabels[idx],
                                          style: const TextStyle(
                                              color: Colors.white38,
                                              fontSize: 8),
                                          textAlign: TextAlign.center,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                              ),
                              minY: 0,
                              maxY: 5,
                              borderData: FlBorderData(show: false),
                              barGroups:
                                  _intensitySeries.asMap().entries.map((entry) {
                                final idx = entry.key;
                                final spot = entry.value;
                                return BarChartGroupData(
                                  x: idx,
                                  barRods: [
                                    BarChartRodData(
                                      toY: spot.y,
                                      color: _getIntensityBarColor(spot.y),
                                      width: 14,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(2),
                                        topRight: Radius.circular(2),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  LineChartBarData _buildLine(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.35,
      color: color,
      barWidth: 2,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: false),
    );
  }

  Widget _buildGraphStats() {
    // Get storm overview values directly
    String wind = '45 mph';
    String surge = '2.3 ft';
    String rain = '2.5 in';
    String wave = '3.0 ft';

    if (_windSpeedSeries.isNotEmpty) {
      wind = '${_maxWindSpeedFromSeries.toStringAsFixed(0)} mph';
      final maxWind = _maxWindSpeedFromSeries;
      final maxSurge = maxWind > 30 ? (maxWind - 30) * 0.15 : 0.0;
      final maxRain = maxWind > 20 ? (maxWind - 20) * 0.1 : 0.0;
      final maxWave = maxWind > 30 ? (maxWind - 30) * 0.2 : 0.0;

      surge = '${maxSurge.toStringAsFixed(1)} ft';
      rain = '${maxRain.toStringAsFixed(1)} in';
      wave = '${maxWave.toStringAsFixed(1)} ft';
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLegendItem(Colors.red, 'Max Wind Speed', wind),
          const SizedBox(width: 20),
          _buildLegendItem(Colors.purple, 'Max Surge', surge),
          const SizedBox(width: 20),
          _buildLegendItem(Colors.blue, 'Max Rainfall', rain),
          const SizedBox(width: 20),
          _buildLegendItem(Colors.teal, 'Max Wave Height', wave),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, color: color, size: 8),
            const SizedBox(width: 6),
            Text(
              label.replaceAll('\n', ' '),
              style: const TextStyle(color: Colors.white70, fontSize: 10),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildHurricaneSummaryCard() {
    final loc = _selectedLocationProps;
    final localWind = (_stormOverview['maxWindSpeed'] != null &&
            _stormOverview['maxWindSpeed'] != 'N/A')
        ? _stormOverview['maxWindSpeed']
        : _singleEventData?['event_details']?['max_wind_speed'] ??
            _singleEventData?['max_wind_speed'] ??
            _singleEventData?['maxWindSpeed'] ??
            'N/A';

    double? windNum;
    String displayWind = 'N/A';
    if (localWind != null && localWind.toString() != 'N/A') {
      String cleanWind = localWind.toString();
      if (cleanWind.contains('(')) {
        cleanWind = cleanWind.split('(').first.trim();
      }

      String windNumericString = cleanWind;
      if (cleanWind.contains('-')) {
        windNumericString = cleanWind.split('-').last.trim();
      }
      windNumericString = windNumericString.replaceAll(RegExp(r'[^0-9.]'), '');
      windNum = double.tryParse(windNumericString);

      if (windNum != null) {
        displayWind = '${windNum.toStringAsFixed(0)} mph';
      } else {
        displayWind = cleanWind;
      }
    }

    String surge = '0 ft';
    String rain = '0 in';
    String wave = '0 ft';

    if (windNum != null && windNum > 0) {
      final calcSurge = windNum > 30 ? (windNum - 30) * 0.15 : 0.0;
      surge = '${calcSurge.toStringAsFixed(1)} ft';

      final calcRain = windNum > 20 ? (windNum - 20) * 0.1 : 0.0;
      rain = '${calcRain.toStringAsFixed(1)} in';

      final calcWave = windNum > 30 ? (windNum - 30) * 0.2 : 0.0;
      wave = '${calcWave.toStringAsFixed(1)} ft';
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16), // ← horizontal removed
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: const Text(
              'Hurricane Summary',
              style: TextStyle(
                color: AppColors.primaryMain,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Divider(
            color: Colors.white.withOpacity(0.2),
            thickness: 1,
            height: 1,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildOverviewItem('Max wind\nspeed', displayWind),
                _buildOverviewItem('Storm\nSurge', surge.toString()),
                _buildOverviewItem('Rainfall\n', rain.toString()),
                _buildOverviewItem('Wave\nHeight', wave.toString()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStormMovementCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16), // ← horizontal removed
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Storm Movement',
              style: TextStyle(
                color: AppColors.primaryMain,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Divider(
            color: Colors.white.withOpacity(0.15),
            thickness: 1,
            height: 1,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOverviewItem('Forward Speed',
                    _stormOverview['forwardSpeed']?.toString() ?? 'N/A'),
                _buildOverviewItem('Forecast Track Point',
                    _stormOverview['trackPointCount']?.toString() ?? 'N/A'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCriticalInfrastructureCard() {
    dynamic ciData;
    if (_singleEventData != null) {
      for (var key in _singleEventData!.keys) {
        if (key.toLowerCase().contains('critical') ||
            key.toLowerCase().contains('infrastructure')) {
          ciData = _singleEventData![key];
          break;
        }
      }
      if (ciData == null &&
          _singleEventData!['event_details'] != null &&
          _singleEventData!['event_details'] is Map) {
        final details = _singleEventData!['event_details'] as Map;
        for (var key in details.keys) {
          if (key.toLowerCase().contains('critical') ||
              key.toLowerCase().contains('infrastructure')) {
            ciData = details[key];
            break;
          }
        }
      }
    }

    List<Map<String, String>> items = [];
    if (ciData is Map) {
      ciData.forEach((key, value) {
        items.add({'name': key.toString(), 'impact': value.toString()});
      });
    } else if (ciData is List) {
      for (var item in ciData) {
        if (item is Map) {
          final name = item['name'] ??
              item['type'] ??
              item['infrastructure'] ??
              (item.keys.isNotEmpty ? item.keys.first : 'Unknown');
          final impact = item['impact'] ??
              item['status'] ??
              item['level'] ??
              (item.values.isNotEmpty ? item.values.first : 'Unknown');
          items.add({'name': name.toString(), 'impact': impact.toString()});
        }
      }
    }

    if (items.isEmpty) {
      items = [
        {'name': 'Airport', 'impact': 'High Impact'},
        {'name': 'Seaport', 'impact': 'High Impact'},
        {'name': 'Energy', 'impact': 'Moderate'},
        {'name': 'Medicalfac', 'impact': 'Moderate'},
      ];
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Critical Infrastructure Impact (Near Location)',
              style: TextStyle(
                color: AppColors.primaryMain,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: items.map((item) {
                final impactLower = item['impact']!.toLowerCase();
                Color textColor = Colors.grey;
                Color bgColor = Colors.grey.withOpacity(0.2);

                if (impactLower.contains('high') ||
                    impactLower.contains('severe')) {
                  textColor = const Color(0xFFE53935);
                  bgColor = const Color(0xFFE53935).withOpacity(0.15);
                } else if (impactLower.contains('moderate') ||
                    impactLower.contains('medium')) {
                  textColor = const Color(0xFFFFB300);
                  bgColor = const Color(0xFFFFB300).withOpacity(0.15);
                } else if (impactLower.contains('low') ||
                    impactLower.contains('minor')) {
                  textColor = const Color(0xFF43A047);
                  bgColor = const Color(0xFF43A047).withOpacity(0.15);
                }

                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A35),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name']!,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item['impact']!,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationExposureTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Location Exposure',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _locationExposures.isEmpty 
                      ? Colors.grey.withValues(alpha: 0.3) 
                      : const Color(0xFF64B5F6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    Icons.download, 
                    color: _locationExposures.isEmpty ? Colors.white38 : Colors.black, 
                    size: 18
                  ),
                  onPressed: _locationExposures.isEmpty ? null : _exportLocationExposuresCsv,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _locationExposures.isEmpty
              ? _buildEmptyState("No Location Exposure Data", Icons.folder_open_outlined)
              : ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemCount: _locationExposures.length,
                  itemBuilder: (context, index) {
                    return _buildLocationCard(_locationExposures[index]);
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _exportLocationExposuresCsv() async {
    if (_locationExposures.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No location data to export.')),
      );
      return;
    }

    try {
      final StringBuffer sb = StringBuffer();
      // Header
      sb.writeln(
          'Location,County,State,TIV Exposed,Category,Event Score,Max Wind Speed,Surge,Rainfall,Wave Height');

      for (final data in _locationExposures) {
        final loc = '"${data['city']?.toString().replaceAll('"', '""') ?? ''}"';
        final county =
            '"${data['county']?.toString().replaceAll('"', '""') ?? ''}"';
        final state =
            '"${data['state']?.toString().replaceAll('"', '""') ?? ''}"';
        final tiv = '"${data['tiv']?.toString().replaceAll('"', '""') ?? ''}"';
        final category =
            '"${data['category']?.toString().replaceAll('"', '""') ?? ''}"';
        final eventScore = '"${data['event_score']?.toString() ?? ''}"';

        final hazards = data['hazards'] as Map<String, dynamic>? ?? {};
        final wind =
            '"${hazards['Wind']?.toString().replaceAll('"', '""') ?? 'N/A'}"';
        final surge =
            '"${hazards['Surge']?.toString().replaceAll('"', '""') ?? 'N/A'}"';
        final rain =
            '"${hazards['Rain']?.toString().replaceAll('"', '""') ?? 'N/A'}"';
        final wave =
            '"${hazards['Wave']?.toString().replaceAll('"', '""') ?? 'N/A'}"';

        sb.writeln(
            '$loc,$county,$state,$tiv,$category,$eventScore,$wind,$surge,$rain,$wave');
      }

      if (Platform.isAndroid) {
        await Permission.storage.request();
      }

      String? dirPath;
      if (Platform.isAndroid) {
        try {
          dirPath = await ExternalPath.getExternalStoragePublicDirectory(
              ExternalPath.DIRECTORY_DOWNLOAD);
        } catch (e) {
          dirPath = (await getApplicationDocumentsDirectory()).path;
        }
      } else {
        dirPath = (await getApplicationDocumentsDirectory()).path;
      }

      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final filePath = path.join(dirPath!, 'location_exposures_$timestamp.csv');

      final file = File(filePath);
      await file.writeAsString(sb.toString());

      await OpenFile.open(filePath);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exported successfully to $filePath')),
      );
    } catch (e) {
      print('Export error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to export CSV.')),
      );
    }
  }

  Widget _buildLocationCard(Map<String, dynamic> data) {
    final hazards = (data['hazards'] as Map<String, dynamic>?) ?? {};

    // Custom Category Label based on overall score (e.g. Cat 3, Cat 4)
    final categoryText =
        data['category']?.toString().contains('Category') == true
            ? data['category'].toString().replaceFirst('Category ', 'Cat ')
            : 'Cat ${data['overall_score']}';

    final lat = data['lat'] as double?;
    final lng = data['lng'] as double?;
    final String streetViewUrl = (lat != null && lng != null)
        ? "https://maps.googleapis.com/maps/api/streetview?size=600x300&location=$lat,$lng&key=${Env.get('GOOGLE_MAPS_API_KEY')}"
        : 'https://picsum.photos/id/122/100/100';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: InkWell(
        onTap: () {
          if (lat != null && lng != null && _mapController != null) {
            _mapController!.animateCamera(
              CameraUpdate.newLatLngZoom(LatLng(lat, lng), 12.0),
            );
            if (data['rawProps'] != null) {
              setState(() {
                _selectedLocationProps = data['rawProps'] as Map<String, dynamic>;
                isMapView = true;
              });
            }
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: const DecorationImage(
                      image:
                          AssetImage('assets/images/building_placeholder.png'),
                      fit: BoxFit.cover,
                      onError: null,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: streetViewUrl,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[800],
                        child: const Icon(Icons.business,
                            color: Colors.white54, size: 24),
                      ),
                      placeholder: (context, url) => Container(
                        color: Colors.grey[800],
                        child: const Icon(Icons.business,
                            color: Colors.white54, size: 24),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              data['city'],
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              categoryText,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      // const SizedBox(height: 2),
                      // Text(
                      //   data['county'],
                      //   style: const TextStyle(
                      //     color: Color(0xFF64B5F6),
                      //     fontSize: 12,
                      //     fontWeight: FontWeight.w500,
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ],
            ),
            Divider(color: Colors.white.withOpacity(0.08), height: 16),

            // Row 2: TIV Exposed
            Row(
              children: [
                const Text(
                  'TIV Exposed :  ',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                Text(
                  data['tiv'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Row 3: Event Score & Sparkline Graph side-by-side
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Event Score
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Event Score :',
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          final isActive =
                              index < (data['overall_score'] as int);
                          return Container(
                            width: 16,
                            height: 10,
                            margin: const EdgeInsets.only(right: 3),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? _getRatingColor(
                                      data['overall_score'] as int)
                                  : const Color(0xFF4A4A4A),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          );
                        }),
                        const SizedBox(width: 6),
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color:
                                _getRatingColor(data['overall_score'] as int),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            data['overall_score'].toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Sparkline
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Wind Speed',
                          style: TextStyle(color: Colors.white54, fontSize: 8),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.trending_up,
                              color: Colors.red,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              data['hazards']['Wind']?.toString() ?? 'N/A',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    if (data['hazards']['Wind'] != null &&
                        data['hazards']['Wind'].toString().trim() != 'N/A' &&
                        data['hazards']['Wind'].toString().trim().isNotEmpty &&
                        _windSpeedSeries.isNotEmpty)
                      SizedBox(
                        width: 70,
                        height: 24,
                        child: CustomPaint(
                          painter: SparklinePainter(
                            _windSpeedSeries.map((spot) => spot.y).toList(),
                            (data['catColor'] as Color? ?? Colors.red),
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
      )
    );
  }

  Widget _buildMapShimmer() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF2A2A2A),
      highlightColor: const Color(0xFF3A3A3A),
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildListShimmer() {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: const Color(0xFF2A2A2A),
          highlightColor: const Color(0xFF3A3A3A),
          child: Container(
            height: 100,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 54, color: Colors.white24),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 15,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;

  SparklinePainter(this.data, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final double stepX = size.width / (data.length - 1);

    double minVal = data.reduce((a, b) => a < b ? a : b);
    double maxVal = data.reduce((a, b) => a > b ? a : b);
    double range = maxVal - minVal;
    if (range == 0) range = 1.0;

    for (int i = 0; i < data.length; i++) {
      double x = i * stepX;
      double y =
          size.height - ((data[i] - minVal) / range * (size.height - 4) + 2);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    double lastX = size.width;
    double lastY =
        size.height - ((data.last - minVal) / range * (size.height - 4) + 2);
    canvas.drawCircle(Offset(lastX, lastY), 3.0, dotPaint);
  }

  @override
  bool shouldRepaint(covariant SparklinePainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.color != color;
  }
}

List<Map<String, dynamic>> _parsePointMarkers(Map<String, dynamic> args) {
  final features = args['features'] as List<dynamic>;
  final result = <Map<String, dynamic>>[];
  for (final feature in features) {
    final geometry = feature['geometry'];
    if (geometry == null || geometry['type'] != 'Point') continue;
    final coords = geometry['coordinates'] as List<dynamic>;
    if (coords.length < 2) continue;
    final lat = coords[1].toDouble();
    final lng = coords[0].toDouble();
    final props = feature['properties'] as Map<String, dynamic>? ?? {};
    final vmaxKnots = (props['VMAX'] as num?)?.toDouble() ?? 0.0;
    final vmax = vmaxKnots;
    String iconType = 'yellow';
    if (vmax >= 74) {
      iconType = 'red';
    } else if (vmax >= 39) {
      iconType = 'orange';
    }
    final id =
        props['ID']?.toString() ?? props['DTG']?.toString() ?? '$lat,$lng';
    result.add({
      'id': id,
      'lat': lat,
      'lng': lng,
      'iconType': iconType,
      'name': props['NAME']?.toString() ?? 'Forecast Point',
      'snippet':
          'Wind Max: ${vmax.toStringAsFixed(0)} mph | Time: ${props['DTG']}',
    });
  }
  return result;
}

List<Map<String, dynamic>> _parsePolylines(List<dynamic> features) {
  final result = <Map<String, dynamic>>[];
  for (final feature in features) {
    final geometry = feature['geometry'];
    if (geometry == null || geometry['type'] != 'LineString') continue;
    final coords = geometry['coordinates'] as List<dynamic>;
    final points = coords.map((c) {
      final list = c as List<dynamic>;
      return [list[1].toDouble(), list[0].toDouble()];
    }).toList();
    result.add({'points': points});
  }
  return result;
}

List<Map<String, dynamic>> _parsePolygonData(List<dynamic> features) {
  final result = <Map<String, dynamic>>[];
  for (final feature in features) {
    final geometry = feature['geometry'];
    if (geometry == null || geometry['type'] != 'Polygon') continue;
    final props = feature['properties'] as Map<String, dynamic>? ?? {};
    final coordsList = geometry['coordinates'] as List<dynamic>;
    int fillColor = const Color(0x26007AFF).value; // blue 15% opacity
    int strokeColor = const Color(0x807AE4FF).value; // blue 50% opacity
    if (props['COLOR'] != null) {
      final colorStr = props['COLOR'].toString();
      try {
        if (colorStr.length == 8) {
          final a = int.parse(colorStr.substring(0, 2), radix: 16);
          final r = int.parse(colorStr.substring(2, 4), radix: 16);
          final g = int.parse(colorStr.substring(4, 6), radix: 16);
          final b = int.parse(colorStr.substring(6, 8), radix: 16);
          fillColor = Color.fromARGB(a, r, g, b).value;
          strokeColor = Color.fromARGB(255, r, g, b).value;
        }
      } catch (_) {}
    }
    for (final ring in coordsList) {
      final points = (ring as List<dynamic>).map((c) {
        final list = c as List<dynamic>;
        return [list[1].toDouble(), list[0].toDouble()];
      }).toList();
      result.add({
        'points': points,
        'fillColor': fillColor,
        'strokeColor': strokeColor,
      });
    }
  }
  return result;
}

List<Map<String, dynamic>> _parseUiMarkerData(List<dynamic> features) {
  final result = <Map<String, dynamic>>[];
  for (final feature in features) {
    final geometry = feature['geometry'];
    if (geometry == null || geometry['type'] != 'Point') continue;
    final coords = geometry['coordinates'] as List<dynamic>;
    if (coords.length < 2) continue;
    final lat = coords[1].toDouble();
    final lng = coords[0].toDouble();
    final props = feature['properties'] as Map<String, dynamic>? ?? {};
    final id = props['location_id']?.toString() ?? '$lat,$lng';
    final title = (props['address'] ?? props['LocationName'] ?? props['name'])
            ?.toString() ??
        'Asset Location';
    final rawTiv =
        props['TIV_Exposed'] ?? props['TIV'] ?? props['pd_value_sum'] ?? '';
    final snippet = 'TIV Exposed: $rawTiv | City: ${props['city'] ?? ''}';
    result.add({
      'id': id,
      'lat': lat,
      'lng': lng,
      'title': title,
      'snippet': snippet,
      'props': props,
    });
  }
  return result;
}
