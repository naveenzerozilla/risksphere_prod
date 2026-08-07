import 'package:RiskSphere/screens/event/widgets/hazard_info_section.dart';
import 'package:RiskSphere/main.dart' show routeObserver;
import 'package:fl_chart/fl_chart.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../providers/custom_tile_providers.dart';
import '../../utils/global_imports.dart' hide Marker;
import '../../models/sov_list_model.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import '../../utils/env.dart';

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

  static final http.Client _rawHttpClient = http.Client();

  @override
  void initState() {
    super.initState();

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
      // Only load GeoJSON storm data — eventInfo API is not called.
      await _loadStormData().timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          print("===== INITIALIZE TIMED OUT — forcing loading=false =====");
        },
      );
    } catch (e) {
      print("===== INITIALIZE ERROR: $e =====");
    } finally {
      // Always unblock the spinner — no matter what happened above
      if (mounted) setState(() => _isLoading = false);
      print("===== INITIALIZE END =====");
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
        debugPrint('No frontendUrls found in notificationData');
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
    print("===== loadStormGeoJson =====");
    try {
      // URLs arrive already resolved by _loadStormData — use directly.
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
        print("loadStormGeoJson: one or more URLs are empty — aborting");
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

      final trackJson = jsonDecode(geojsonStrings[0]);
      final pointJson = jsonDecode(geojsonStrings[1]);
      final coneJson = jsonDecode(geojsonStrings[2]);
      final uiDataJson = jsonDecode(geojsonStrings[3]);

      // Optimize: Cache/Pre-create circle icons exactly once to avoid redundant redraws
      final BitmapDescriptor redCircleIcon =
          await _getCircleIcon(Colors.red, 24);
      final BitmapDescriptor orangeCircleIcon =
          await _getCircleIcon(Colors.orange, 24);
      final BitmapDescriptor yellowCircleIcon =
          await _getCircleIcon(Colors.yellow, 24);

      // Parse all GeoJSON features synchronously (much faster than compute() isolate overhead for these sizes)
      final pointFeatures = pointJson['features'] as List<dynamic>? ?? [];
      final uiFeatures = uiDataJson['features'] as List<dynamic>? ?? [];
      final trackFeatures = trackJson['features'] as List<dynamic>? ?? [];
      final coneFeatures = coneJson['features'] as List<dynamic>? ?? [];

      final pointMarkerData = _parsePointMarkers({'features': pointFeatures});
      final polylineData = _parsePolylines(trackFeatures);
      final polygonData = _parsePolygonData(coneFeatures);
      final uiMarkerData = _parseUiMarkerData(uiFeatures);

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
      print("Error loading or parsing storm GeoJSON: $e");
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

    // Filter all feature lists to only the clicked event's data
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
    final stormId = trackProps['STORMID']?.toString() ?? 'N/A';
    final vmax = (trackProps['VMAX'] as num?)?.toDouble() ?? 0.0;
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

    // React code uses a fixed 8% (0.08) damage ratio for estimated claims calculation
    double damageRatio = 0.08;

    double estClaims = totalTiv * damageRatio;

    setState(() {
      _stormOverview = {
        // Always show the clicked event name — not the GeoJSON internal NAME
        'stormName': clickedEventName.isNotEmpty
            ? widget.notificationData['title']
            : stormName,
        'stormId': stormId,
        'category': _categoryFromVmax(vmax),
        'forecastTime': _formatDtg(dtg),
        'forwardSpeed': fspd != null ? '$fspd mph' : 'N/A',
        // Track point count from the filtered (event-specific) points
        'trackPointCount': sourcePoint.length.toString(),
        'maxWindSpeed': vmax > 0 ? '${vmax.toStringAsFixed(0)} mph' : 'N/A',
        'locationsImpacted': locationsCount.toString(),
        'totalExposedValue': _formatCurrency(totalTiv),
        'estClaims': _formatCurrency(estClaims),
      };
    });
  }

  double _categoryValueFromProps(Map<String, dynamic> props) {
    // Check CAT_DESC first
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

    // Fall back to SS (Saffir-Simpson) Category if present
    final ssCat = props['SS_CAT'] ?? props['CATEGORY'] ?? props['SSCAT'];
    if (ssCat != null) {
      final double? parsedSS = double.tryParse(ssCat.toString());
      if (parsedSS != null) return parsedSS;
    }

    // Fall back to calculation from VMAX (wind speed)
    final vmax = (props['VMAX'] as num?)?.toDouble() ?? 0.0;
    if (vmax >= 157) return 5.0;
    if (vmax >= 130) return 4.0;
    if (vmax >= 111) return 3.0;
    if (vmax >= 96) return 2.0;
    if (vmax >= 74) return 1.0;
    if (vmax >= 39) return 0.5;
    return 0.0;
  }

  /// Wind-speed-over-time chart — only plots points belonging to the
  /// clicked event (filtered by storm name).
  void _buildWindSpeedChart(List<dynamic> pointFeatures) {
    if (pointFeatures.isEmpty) return;

    final clickedEventName = (widget.notificationData['title'] as String? ?? '')
        .trim()
        .toUpperCase();

    // Filter to the clicked storm; fall back to all if NAME field is absent
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

    // Get only the last 5 forecast points
    final lastFivePoints = sortedPoints.length > 5
        ? sortedPoints.sublist(sortedPoints.length - 5)
        : sortedPoints;

    final wind = <FlSpot>[];
    final intensity = <FlSpot>[];
    final labels = <String>[];

    int indexCounter = 0;
    for (var i = 0; i < lastFivePoints.length; i++) {
      final props =
          (lastFivePoints[i]['properties'] as Map<String, dynamic>?) ?? {};
      final dtg = (props['DTG'] ?? '').toString();
      final v = (props['VMAX'] as num?)?.toDouble();
      if (v != null) {
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
    });
  }

  /// Location Exposure list, built from ui_data.geojson. Each location
  /// already carries its own local hazard values per the data dictionary.
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
      final windSpeedRaw =
          props['usofcl_swath_wind_mph_LABEL'] ?? props['wind_speed'];
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
        'catColor': _colorForCategory(categoryLabel),
        'lat': lat,
        'lng': lng,
        'rawProps': props,
        'hazards': {
          'Surge': props['usofcl_fcst_surge_ft_LABEL']?.toString(),
          'Rain': props['usofcl_fcst_rain_in_LABEL']?.toString(),
          'Wave': props['usofcl_fcst_wave_ft_LABEL']?.toString(),
          'Wind': windSpeedRaw?.toString(),
        },
      });
    }

    setState(() {
      _locationExposures = exposures;
      // Default the "selected location" (used by Hurricane Summary) to the
      // first property until the user taps a marker on the map.
      _selectedLocationProps ??= uiFeatures.isNotEmpty
          ? (uiFeatures.first['properties'] as Map<String, dynamic>?)
          : null;
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

  // NOTE: assumes FCST_DTG / DTG are in yyyyMMddHH format, matching the
  // sample keys seen in storm_forecast_points.geojson. If FCST_DTG uses a
  // different format (e.g. ISO 8601), adjust this parser accordingly.
  String _formatDtg(String? dtg) {
    if (dtg == null || dtg.length < 10) return dtg ?? 'N/A';
    try {
      final year = dtg.substring(0, 4);
      final month = int.parse(dtg.substring(4, 6));
      final day = dtg.substring(6, 8);
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
      return '$day ${months[month - 1]} $year •\n$hour:00 UTC';
    } catch (_) {
      return dtg;
    }
  }

  String _formatDtgShort(String? dtg) {
    if (dtg == null || dtg.isEmpty) return '';
    try {
      // Handle standard format: yyyyMMddHH (10 characters)
      if (dtg.length >= 10) {
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
        return '${months[month - 1]} $day $hour:00';
      }

      // Fallback format: yyyyMMdd
      if (dtg.length >= 8) {
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

      return dtg;
    } catch (_) {
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

    // Note: _isLoading is already managed by _initialize().
    // Do NOT set it here to avoid races with the global loading state.

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

      setState(() {
        locationsData = locations;
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
                  hazardName:
                      widget.notificationData['title'] ?? "Event Hazard",
                  selectedDate: "12/1/1111",
                  availableDates: availableDates,
                  lastUpdated: _lastUpdatedString,
                  onDateChanged: (value) {
                    setState(() {
                      selectedDate = value;
                    });
                    // Re-resolve URLs fresh from notificationData and reload
                    _loadStormData();
                  },
                ),
                Expanded(
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          )
                        : isMapView
                            ? Stack(
                                children: [
                                  Container(
                                    margin: const EdgeInsets.fromLTRB(
                                        16, 1, 16, 2.0),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20.0),
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
                                      mapType: MapType.normal,
                                      myLocationButtonEnabled: true,
                                      zoomControlsEnabled: true,
                                      onCameraMove: (_) {
                                        if (_tileOverlays.isNotEmpty) {
                                          final overlay = _tileOverlays.first;
                                          _mapController!.clearTileCache(
                                              overlay.tileOverlayId);
                                        }
                                      },
                                    ),
                                  ),
                                  if (_isLoading)
                                    const Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                      ),
                                    ),
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
                                                    const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  border: Border(
                                                    right: BorderSide(
                                                      color:
                                                          Colors.grey.shade700,
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
                                                padding:
                                                    const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  border: Border(
                                                    right: BorderSide(
                                                      color:
                                                          Colors.grey.shade700,
                                                    ),
                                                  ),
                                                ),
                                                child: const Text("Address"),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  border: Border(
                                                    right: BorderSide(
                                                      color:
                                                          Colors.grey.shade700,
                                                    ),
                                                  ),
                                                ),
                                                child:
                                                    const Text("Hazard Name"),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(12),
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
                                              child:
                                                  CircularProgressIndicator(),
                                            )
                                          : locationsData.isEmpty
                                              ? const Center(
                                                  child: Text(
                                                    "No Data Found",
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                )
                                              : ListView.builder(
                                                  itemCount:
                                                      locationsData.length,
                                                  itemBuilder:
                                                      (context, index) {
                                                    final location =
                                                        locationsData[index];

                                                    final eventMap =
                                                        location['event']
                                                                as Map<String,
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
                                                            Expanded(
                                                              flex: 3,
                                                              child: Container(
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
                                                                  maxLines: 2,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                ),
                                                              ),
                                                            ),
                                                            Expanded(
                                                              flex: 4,
                                                              child: Container(
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
                                                                  maxLines: 3,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                ),
                                                              ),
                                                            ),
                                                            Expanded(
                                                              flex: 2,
                                                              child: Container(
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
                                                                  maxLines: 2,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                ),
                                                              ),
                                                            ),
                                                            Expanded(
                                                              flex: 2,
                                                              child: Container(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .all(
                                                                        12),
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

  // ─── Overview Tab (now driven by _stormOverview / selected location) ──
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
            const SizedBox(height: 20),
            _buildSectionHeader('Storm Intensity Over Time'),
            const SizedBox(height: 12),
            _buildStormIntensityGraph(),
          ] else ...[
            _buildStormOverviewGrid(),
          ],
          const SizedBox(height: 16),
          _buildSectionHeader('Hurricane Summary'),
          const SizedBox(height: 4),
          if (_selectedLocationProps != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Showing local hazard data for: '
                '${_firstNonEmpty(_selectedLocationProps!, [
                          'name',
                          'LocationName',
                          'address'
                        ]) ?? 'Selected location'}',
                style: const TextStyle(color: Colors.white38, fontSize: 10),
              ),
            ),
          _buildHurricaneSummary(),
          const SizedBox(height: 16),
          _buildSectionHeader('Storm Movement'),
          const SizedBox(height: 12),
          _buildStormMovement(),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Half: Storm Metadata
          const Text(
            'STORM METADATA',
            style: TextStyle(
              color: Colors.blueAccent,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOverviewItem('Storm Name',
                  _stormOverview['stormName']?.toString() ?? 'N/A'),
              _buildOverviewItem(
                  'ATCF ID', _stormOverview['stormId']?.toString() ?? 'N/A'),
              _buildOverviewItem(
                  'Category', _stormOverview['category']?.toString() ?? 'N/A'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOverviewItem('Forecast Time',
                  _stormOverview['forecastTime']?.toString() ?? 'N/A'),
              _buildOverviewItem('Forward Speed',
                  _stormOverview['forwardSpeed']?.toString() ?? 'N/A'),
              _buildOverviewItem('Max Wind Speed',
                  _stormOverview['maxWindSpeed']?.toString() ?? 'N/A'),
            ],
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

  // ─── Storm Graph — plots wind speed over the forecast track chronology ──
  List<FlSpot> _getMockedSurgeSeries() {
    return _windSpeedSeries.map((spot) {
      double surgeVal = (spot.y - 30) * 0.054 + 1.0;
      if (surgeVal < 0) surgeVal = 0;
      return FlSpot(spot.x, surgeVal * 8);
    }).toList();
  }

  List<FlSpot> _getMockedRainSeries() {
    return _windSpeedSeries.map((spot) {
      double rainVal = (spot.y - 30) * 0.07 + 1.0;
      if (rainVal < 0) rainVal = 0;
      return FlSpot(spot.x, rainVal * 8);
    }).toList();
  }

  List<FlSpot> _getMockedWaveSeries() {
    return _windSpeedSeries.map((spot) {
      double waveVal = (spot.y - 30) * 0.046 + 1.0;
      if (waveVal < 0) waveVal = 0;
      return FlSpot(spot.x, waveVal * 8);
    }).toList();
  }

  Widget _buildStormGraph() {
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
                        style:
                            const TextStyle(color: Colors.white38, fontSize: 8),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= _chartDateLabels.length) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          _chartDateLabels[idx],
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 7),
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
                maxY: 160,
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  _buildLine(_windSpeedSeries, Colors.red),
                  _buildLine(_getMockedSurgeSeries(), Colors.purple),
                  _buildLine(_getMockedRainSeries(), Colors.blue),
                  _buildLine(_getMockedWaveSeries(), Colors.teal),
                ],
              ),
            ),
    );
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
          : LineChart(
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
                      reservedSize: 36,
                      getTitlesWidget: (value, _) {
                        if (value == 0.0 || value == 0.5) {
                          return const Text('TS',
                              style: TextStyle(
                                  color: Colors.white38, fontSize: 8));
                        } else if (value == 1.0) {
                          return const Text('Cat 1',
                              style: TextStyle(
                                  color: Colors.white38, fontSize: 8));
                        } else if (value == 2.0) {
                          return const Text('Cat 2',
                              style: TextStyle(
                                  color: Colors.white38, fontSize: 8));
                        } else if (value == 3.0) {
                          return const Text('Cat 3',
                              style: TextStyle(
                                  color: Colors.white38, fontSize: 8));
                        } else if (value == 4.0) {
                          return const Text('Cat 4',
                              style: TextStyle(
                                  color: Colors.white38, fontSize: 8));
                        } else if (value == 5.0) {
                          return const Text('Cat 5',
                              style: TextStyle(
                                  color: Colors.white38, fontSize: 8));
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= _chartDateLabels.length) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          _chartDateLabels[idx],
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 7),
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
                lineBarsData: [
                  LineChartBarData(
                    spots: _intensitySeries,
                    isStepLineChart: true,
                    lineChartStepData: const LineChartStepData(
                      stepDirection: LineChartStepData.stepDirectionForward,
                    ),
                    color: Colors.orange,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Colors.red.withOpacity(0.35),
                          Colors.orange.withOpacity(0.2),
                          Colors.yellow.withOpacity(0.1),
                          Colors.green.withOpacity(0.05),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
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
    final loc = _selectedLocationProps;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildLegendItem(
            Colors.red,
            'Max Wind Speed',
            _maxWindSpeedFromSeries > 0
                ? '${_maxWindSpeedFromSeries.toStringAsFixed(0)} mph'
                : (_stormOverview['maxWindSpeed']?.toString() ?? 'N/A')),
        _buildLegendItem(Colors.purple, 'Storm Surge',
            loc?['usofcl_fcst_surge_ft_LABEL']?.toString() ?? 'N/A'),
        _buildLegendItem(Colors.blue, 'Rainfall',
            loc?['usofcl_fcst_rain_in_LABEL']?.toString() ?? 'N/A'),
        _buildLegendItem(Colors.teal, 'Wave\nHeight',
            loc?['usofcl_fcst_wave_ft_LABEL']?.toString() ?? 'N/A'),
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
    final loc = _selectedLocationProps;

    // Fallback checks matching the keys mapped in React component
    final surge = loc?['usofcl_fcst_surge_ft_LABEL'] ?? loc?['surge'] ?? 'N/A';
    final rain = loc?['usofcl_fcst_rain_in_LABEL'] ??
        loc?['rainfall'] ??
        loc?['rain'] ??
        'N/A';
    final wave = loc?['usofcl_fcst_wave_ft_LABEL'] ??
        loc?['wave_height'] ??
        loc?['wave'] ??
        'N/A';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _buildSummaryItem('Max wind\nspeed',
              _stormOverview['maxWindSpeed']?.toString() ?? 'N/A'),
          _buildSummaryItem('Storm\nSurge', surge.toString()),
          _buildSummaryItem('Rainfall', rain.toString()),
          _buildSummaryItem('Wave\nHeight', wave.toString()),
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
              textAlign: TextAlign.center,
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
          _buildOverviewItem('Forward Speed',
              _stormOverview['forwardSpeed']?.toString() ?? 'N/A'),
          _buildOverviewItem('Forecast Track Point',
              _stormOverview['trackPointCount']?.toString() ?? 'N/A'),
        ],
      ),
    );
  }

  // ─── Location Exposure Tab (now driven by _locationExposures) ─────────
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
          child: _locationExposures.isEmpty
              ? const Center(
                  child: Text(
                    "No Location Exposure Data",
                    style: TextStyle(
                        color: Colors.white54,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                  ),
                )
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

  Widget _buildLocationCard(Map<String, dynamic> data) {
    final hazards = (data['hazards'] as Map<String, dynamic>?) ?? {};

    return GestureDetector(
      onTap: () {
        final lat = data['lat'] as double?;
        final lng = data['lng'] as double?;
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
      child: Container(
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['city'],
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if ((data['county'] as String).isNotEmpty)
                        Text(
                          data['county'],
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 11),
                        ),
                    ],
                  ),
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
            const Text('TIV Exposed :',
                style: TextStyle(color: Colors.white54, fontSize: 11)),
            Text(
              data['tiv'],
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
            ),
            const SizedBox(height: 8),
            const Text('Local Hazards :',
                style: TextStyle(color: Colors.white54, fontSize: 11)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: hazards.entries
                  .where(
                      (e) => e.value != null && e.value.toString().isNotEmpty)
                  .map((e) => _buildHazardChip(e.key, e.value.toString()))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHazardChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(color: Colors.white70, fontSize: 10),
      ),
    );
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
    final vmax = (props['VMAX'] as num?)?.toDouble() ?? 0.0;
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
      'snippet': 'Wind Max: ${props['VMAX']} mph | Time: ${props['DTG']}',
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
    // Default colours (blue swath)
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
