import 'package:RiskSphere/screens/event/widgets/hazard_info_section.dart';
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
  Set<Polyline> _polylines = {};
  Set<Polygon> _polygons = {};
  Set<Marker> _allMarkers = {};
  String? selectedDate = "";
  List<String> availableDates = [];
  bool isMapView = true;
  String? _currentMapUrl;
  Set<TileOverlay> _tileOverlays = {};

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = true);

    // await _fetchEventInfo();

    await loadStormGeoJson();

    setState(() => _isLoading = false);
  }

  Future<String> _getLocalFileContent(String filename, String url) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$filename');

      if (await file.exists()) {
        print("Loading $filename from local cache...");
        return await file.readAsString();
      }

      print("Downloading $filename from remote URL...");
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        await file.writeAsString(response.body);
        return response.body;
      } else {
        throw Exception("Failed to download $filename");
      }
    } catch (e) {
      print("Error in local cache for $filename: $e");
      final response = await http.get(Uri.parse(url));
      return response.body;
    }
  }

  Future<void> loadStormGeoJson() async {
    try {
      final dynamic rawUrls = widget.notificationData['frontendUrls'];
      FrontendUrls? urls;
      if (rawUrls is FrontendUrls) {
        urls = rawUrls;
      } else if (rawUrls is Map<String, dynamic>) {
        urls = FrontendUrls.fromJson(rawUrls);
      } else if (rawUrls is String) {
        try {
          urls = FrontendUrls.fromJson(jsonDecode(rawUrls));
        } catch (e) {
          print("Error parsing frontendUrls JSON string: $e");
        }
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

      final trackUrl = urls?.stormTrackGeojson ??
          'https://storage.googleapis.com/project-green-r5-1-qa.appspot.com/event/kineticast/hurricane/frontend_assets/BAVI/storm_track.geojson';
      final pointUrl = urls?.stormForecastPointsGeojson ??
          'https://storage.googleapis.com/project-green-r5-1-qa.appspot.com/event/kineticast/hurricane/frontend_assets/BAVI/storm_forecast_points.geojson';
      final swathUrl = urls?.stormSwathGeojson ??
          'https://storage.googleapis.com/project-green-r5-1-qa.appspot.com/event/kineticast/hurricane/frontend_assets/BAVI/storm_swath.geojson';
      final uiDataUrl = urls?.uiDataGeojson ??
          'https://storage.googleapis.com/project-green-r5-1-qa.appspot.com/event/kineticast/hurricane/frontend_assets/BAVI/ui_data.geojson';

      // Storm Track — source of GLOBAL storm metadata (NAME, FCST_DTG, VMAX, FSPD)
      final trackString = await _getLocalFileContent(
        getCacheFilename(trackUrl, 'storm_track.geojson'),
        trackUrl,
      );
      final trackJson = jsonDecode(trackString);

      // Forecast Points — chronological points, used for map animation +
      // the wind-speed-over-time chart.
      final pointString = await _getLocalFileContent(
        getCacheFilename(pointUrl, 'storm_forecast_points.geojson'),
        pointUrl,
      );
      final pointJson = jsonDecode(pointString);

      // Storm Swath/Cone — visual overlay only.
      final swathString = await _getLocalFileContent(
        getCacheFilename(swathUrl, 'storm_swath.geojson'),
        swathUrl,
      );
      final coneJson = jsonDecode(swathString);

      // UI Data — master location dataset, already enriched per-location
      // with local hazard values. Source of the Exposure Table + the
      // per-location Hurricane Summary values shown on marker tap.
      final uiDataString = await _getLocalFileContent(
        getCacheFilename(uiDataUrl, 'ui_data.geojson'),
        uiDataUrl,
      );
      final uiDataJson = jsonDecode(uiDataString);

      // ── DEBUG: print the real keys coming back for ui_data.geojson ──
      // Remove this block once field names are confirmed.
      final _uiFeaturesDebug = uiDataJson['features'] as List<dynamic>? ?? [];
      if (_uiFeaturesDebug.isNotEmpty) {
        final _firstProps =
            _uiFeaturesDebug.first['properties'] as Map<String, dynamic>? ?? {};
        print("=== ui_data.geojson FIRST FEATURE PROPERTIES ===");
        print(const JsonEncoder.withIndent('  ').convert(_firstProps));
        print("=== ALL KEYS: ${_firstProps.keys.toList()} ===");
      }

      // ── DEBUG: print the real keys coming back for storm_track.geojson ──
      final _trackFeaturesDebug = trackJson['features'] as List<dynamic>? ?? [];
      if (_trackFeaturesDebug.isNotEmpty) {
        final _firstTrackProps =
            _trackFeaturesDebug.first['properties'] as Map<String, dynamic>? ??
                {};
        print("=== storm_track.geojson FIRST FEATURE PROPERTIES ===");
        print(const JsonEncoder.withIndent('  ').convert(_firstTrackProps));
        print("=== ALL KEYS: ${_firstTrackProps.keys.toList()} ===");
      }

      // Pre-create circle icons for storm forecast points (Red for hurricane, Orange for storm, Yellow for depression)
      final BitmapDescriptor redCircleIcon =
          await _getCircleIcon(Colors.red, 24);
      final BitmapDescriptor orangeCircleIcon =
          await _getCircleIcon(Colors.orange, 24);
      final BitmapDescriptor yellowCircleIcon =
          await _getCircleIcon(Colors.yellow, 24);

      // Parse Markers from forecast points
      final pointFeatures = pointJson['features'] as List<dynamic>? ?? [];
      Set<Marker> markers = {};
      for (var feature in pointFeatures) {
        final geometry = feature['geometry'];
        if (geometry == null || geometry['type'] != 'Point') continue;

        final coords = geometry['coordinates'] as List<dynamic>;
        if (coords.length < 2) continue;

        final lat = coords[1].toDouble();
        final lng = coords[0].toDouble();

        final props = feature['properties'] as Map<String, dynamic>? ?? {};

        final markerId = props['ID']?.toString() ??
            props['DTG']?.toString() ??
            UniqueKey().toString();

        final vmax = (props['VMAX'] as num?)?.toDouble() ?? 0.0;

        BitmapDescriptor icon = yellowCircleIcon;
        if (vmax >= 74) {
          icon = redCircleIcon;
        } else if (vmax >= 39) {
          icon = orangeCircleIcon;
        }

        markers.add(
          Marker(
            markerId: MarkerId(markerId),
            position: LatLng(lat, lng),
            icon: icon,
            anchor: const Offset(0.5, 0.5),
            infoWindow: InfoWindow(
              title: props['NAME']?.toString() ?? "Forecast Point",
              snippet: "Wind Max: ${props['VMAX']} mph | Time: ${props['DTG']}",
            ),
          ),
        );
      }

      // Parse UI Data Locations (Azure markers). Tapping a marker updates
      // the "selected location" that drives the per-location Hurricane
      // Summary values (storm category / surge / rainfall / wave / wind).
      final uiFeatures = uiDataJson['features'] as List<dynamic>? ?? [];
      for (var feature in uiFeatures) {
        final geometry = feature['geometry'];
        if (geometry == null || geometry['type'] != 'Point') continue;
        final coords = geometry['coordinates'] as List<dynamic>;
        if (coords.length < 2) continue;
        final lat = coords[1].toDouble();
        final lng = coords[0].toDouble();

        final props = feature['properties'] as Map<String, dynamic>? ?? {};
        final markerId =
            props['location_id']?.toString() ?? UniqueKey().toString();

        markers.add(
          Marker(
            markerId: MarkerId(markerId),
            position: LatLng(lat, lng),
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueAzure),
            infoWindow: InfoWindow(
              title:
                  _firstNonEmpty(props, ['name', 'LocationName', 'address']) ??
                      "Asset Location",
              snippet:
                  "TIV Exposed: ${props['TIV_Exposed'] ?? ''} | Category: ${props['usofcl_fcst_sscats_LABEL'] ?? ''}",
            ),
            onTap: () {
              setState(() => _selectedLocationProps = props);
            },
          ),
        );
      }

      // Parse Polylines from tracks
      final trackFeatures = trackJson['features'] as List<dynamic>? ?? [];
      Set<Polyline> polylines = {};
      int polylineIndex = 0;
      for (var feature in trackFeatures) {
        final geometry = feature['geometry'];
        if (geometry == null || geometry['type'] != 'LineString') continue;
        final coords = geometry['coordinates'] as List<dynamic>;
        List<LatLng> points = coords.map((c) {
          final list = c as List<dynamic>;
          return LatLng(list[1].toDouble(), list[0].toDouble());
        }).toList();

        polylines.add(
          Polyline(
            polylineId: PolylineId('track_${polylineIndex++}'),
            points: points,
            color: Colors.red,
            width: 3,
          ),
        );
      }

      // Parse Polygons from cone/swath
      final coneFeatures = coneJson['features'] as List<dynamic>? ?? [];
      Set<Polygon> polygons = {};
      int polygonIndex = 0;
      for (var feature in coneFeatures) {
        final geometry = feature['geometry'];
        if (geometry == null) continue;
        final geomType = geometry['type'];
        final props = feature['properties'] as Map<String, dynamic>? ?? {};

        if (geomType == 'Polygon') {
          final coordsList = geometry['coordinates'] as List<dynamic>;
          for (var ring in coordsList) {
            final points = (ring as List<dynamic>).map((c) {
              final list = c as List<dynamic>;
              return LatLng(list[1].toDouble(), list[0].toDouble());
            }).toList();

            Color polyColor = Colors.blue.withOpacity(0.15);
            Color strokeColor = Colors.blue.withOpacity(0.5);

            if (props['COLOR'] != null) {
              final colorStr = props['COLOR'].toString();
              try {
                if (colorStr.length == 8) {
                  final a = int.parse(colorStr.substring(0, 2), radix: 16);
                  final r = int.parse(colorStr.substring(2, 4), radix: 16);
                  final g = int.parse(colorStr.substring(4, 6), radix: 16);
                  final b = int.parse(colorStr.substring(6, 8), radix: 16);
                  polyColor = Color.fromARGB(a, r, g, b);
                  strokeColor = Color.fromARGB(255, r, g, b);
                }
              } catch (_) {}
            }

            polygons.add(
              Polygon(
                polygonId: PolygonId('swath_${polygonIndex++}'),
                points: points,
                fillColor: polyColor,
                strokeColor: strokeColor,
                strokeWidth: 1,
              ),
            );
          }
        }
      }

      setState(() {
        _markers = markers;
        _polylines = polylines;
        _polygons = polygons;
      });

      // ── Build the dynamic Overview + Location Exposure data ──
      _buildGlobalStormOverview(trackFeatures, pointFeatures, uiFeatures);
      _buildWindSpeedChart(pointFeatures);
      _buildLocationExposuresFromUiFeatures(uiFeatures);

      if (markers.isNotEmpty) {
        final firstPoint = markers.first.position;
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
    }
  }

  // ════════════════════════════════════════════════════════════════════
  //  DYNAMIC DATA (parsed from JSON) — replaces the old hardcoded values
  // ════════════════════════════════════════════════════════════════════

  /// Global storm metadata — from the FIRST feature of storm_track.geojson,
  /// per the data dictionary: NAME, FCST_DTG, VMAX, FSPD. Track point count
  /// comes from storm_forecast_points.geojson's feature count.
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

  /// The currently "selected" property location (defaults to the first
  /// entry in ui_data.geojson, updates when a marker is tapped). Drives the
  /// per-location Hurricane Summary values.
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

    final trackProps =
        (trackFeatures.first['properties'] as Map<String, dynamic>?) ?? {};

    final stormName = trackProps['NAME']?.toString() ??
        trackProps['STORMNAME']?.toString() ??
        'Unknown';
    final stormId = trackProps['STORMID']?.toString() ?? 'N/A';
    final vmax = (trackProps['VMAX'] as num?)?.toDouble() ?? 0.0;
    final fspd = trackProps['FSPD'];
    final dtg = trackProps['FCST_DTG']?.toString() ?? trackProps['DTG']?.toString();

    // Financial calculations
    final locationsCount = uiFeatures.length;
    double totalTiv = 0.0;
    for (var feature in uiFeatures) {
      final props = (feature['properties'] as Map<String, dynamic>?) ?? {};
      final rawTiv = props['TIV_Exposed'] ?? props['TIV'];
      if (rawTiv != null) {
        final tivVal = (rawTiv is num) ? rawTiv.toDouble() : double.tryParse(rawTiv.toString());
        if (tivVal != null) {
          totalTiv += tivVal;
        }
      }
    }

    double damageRatio = 0.05; // default 5%
    if (vmax >= 157) damageRatio = 0.15;
    else if (vmax >= 130) damageRatio = 0.12;
    else if (vmax >= 111) damageRatio = 0.10;
    else if (vmax >= 96) damageRatio = 0.08;
    else if (vmax >= 74) damageRatio = 0.05;
    else damageRatio = 0.02;

    double estClaims = totalTiv * damageRatio;

    setState(() {
      _stormOverview = {
        'stormName': stormName,
        'stormId': stormId,
        'category': _categoryFromVmax(vmax),
        'forecastTime': _formatDtg(dtg),
        'forwardSpeed': fspd != null ? '$fspd mph' : 'N/A',
        'trackPointCount': pointFeatures.length.toString(),
        'maxWindSpeed': vmax > 0 ? '${vmax.toStringAsFixed(0)} mph' : 'N/A',
        'locationsImpacted': locationsCount.toString(),
        'totalExposedValue': _formatCurrency(totalTiv),
        'estClaims': _formatCurrency(estClaims),
      };
    });
  }

  double _categoryValueFromProps(Map<String, dynamic> props) {
    final catDesc = props['CAT_DESC']?.toString().toLowerCase() ?? '';
    if (catDesc.contains('5')) return 5.0;
    if (catDesc.contains('4')) return 4.0;
    if (catDesc.contains('3')) return 3.0;
    if (catDesc.contains('2')) return 2.0;
    if (catDesc.contains('1')) return 1.0;
    if (catDesc.contains('tropical storm') || catDesc.contains('ts')) return 0.5;
    if (catDesc.contains('depression') || catDesc.contains('td')) return 0.2;

    final vmax = (props['VMAX'] as num?)?.toDouble() ?? 0.0;
    if (vmax >= 157) return 5.0;
    if (vmax >= 130) return 4.0;
    if (vmax >= 111) return 3.0;
    if (vmax >= 96) return 2.0;
    if (vmax >= 74) return 1.0;
    if (vmax >= 39) return 0.5;
    return 0.0;
  }

  /// Wind-speed-over-time chart, built from the chronological
  /// storm_forecast_points.geojson (DTG + VMAX per point).
  void _buildWindSpeedChart(List<dynamic> pointFeatures) {
    if (pointFeatures.isEmpty) return;

    final sortedPoints = List<dynamic>.from(pointFeatures);
    sortedPoints.sort((a, b) {
      final dtgA =
          ((a['properties'] as Map<String, dynamic>?)?['DTG'] ?? '').toString();
      final dtgB =
          ((b['properties'] as Map<String, dynamic>?)?['DTG'] ?? '').toString();
      return dtgA.compareTo(dtgB);
    });

    final wind = <FlSpot>[];
    final intensity = <FlSpot>[];
    final labels = <String>[];

    for (var i = 0; i < sortedPoints.length; i++) {
      final props =
          (sortedPoints[i]['properties'] as Map<String, dynamic>?) ?? {};
      final v = (props['VMAX'] as num?)?.toDouble();
      if (v != null) {
        wind.add(FlSpot(i.toDouble(), v));
        intensity.add(FlSpot(i.toDouble(), _categoryValueFromProps(props)));
      }
      labels.add(_formatDtgShort(props['DTG']?.toString()));
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

    for (var feature in uiFeatures) {
      final props = (feature['properties'] as Map<String, dynamic>?) ?? {};

      final locationName =
          _firstNonEmpty(props, ['name', 'LocationName', 'address']) ??
              'Unknown';
      final county = _firstNonEmpty(props, ['County', 'county_name']) ?? '';
      final categoryLabel =
          props['usofcl_fcst_sscats_LABEL']?.toString() ?? 'N/A';
      final tiv = _formatCurrency(props['TIV_Exposed'] ?? props['TIV']);

      final geometry = feature['geometry'];
      final coords = geometry != null ? geometry['coordinates'] as List<dynamic>? : null;
      final lat = (coords != null && coords.length >= 2) ? coords[1].toDouble() : null;
      final lng = (coords != null && coords.length >= 2) ? coords[0].toDouble() : null;

      exposures.add({
        'city': locationName,
        'county': county,
        'category': categoryLabel,
        'tiv': tiv,
        'catColor': _colorForCategory(categoryLabel),
        'lat': lat,
        'lng': lng,
        'rawProps': props,
        // Raw hazard labels shown as chips on the card instead of a
        // synthetic 1-5 score, since the dictionary only gives us these
        // descriptive LABEL strings, not a numeric score.
        'hazards': {
          'Surge': props['usofcl_fcst_surge_ft_LABEL']?.toString(),
          'Rain': props['usofcl_fcst_rain_in_LABEL']?.toString(),
          'Wave': props['usofcl_fcst_wave_ft_LABEL']?.toString(),
          'Wind': props['usofcl_swath_wind_mph_LABEL']?.toString(),
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
    if (dtg == null || dtg.length < 8) return '';
    try {
      final month = int.parse(dtg.substring(4, 6));
      final day = dtg.substring(6, 8);
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
    } catch (_) {
      return '';
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

      setState(() {
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
                                margin:
                                    const EdgeInsets.fromLTRB(16, 1, 16, 2.0),
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

                                                final eventMap =
                                                    location['event'] as Map<
                                                            String, dynamic>? ??
                                                        {};

                                                final firstEvent = eventMap
                                                        .isNotEmpty
                                                    ? eventMap.values.first
                                                        as Map<String, dynamic>
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
              _buildOverviewItem('Storm Name', _stormOverview['stormName']?.toString() ?? 'N/A'),
              _buildOverviewItem('ATCF ID', _stormOverview['stormId']?.toString() ?? 'N/A'),
              _buildOverviewItem('Category', _stormOverview['category']?.toString() ?? 'N/A'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOverviewItem('Forecast Time', _stormOverview['forecastTime']?.toString() ?? 'N/A'),
              _buildOverviewItem('Forward Speed', _stormOverview['forwardSpeed']?.toString() ?? 'N/A'),
              _buildOverviewItem('Max Wind Speed', _stormOverview['maxWindSpeed']?.toString() ?? 'N/A'),
            ],
          ),
          const Divider(color: Colors.white12, height: 24),
          // Bottom Half: Financial Impact
          const Text(
            'FINANCIAL IMPACT AGGREGATIONS',
            style: TextStyle(
              color: Colors.greenAccent,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOverviewItem('Locations Impacted', _stormOverview['locationsImpacted']?.toString() ?? 'N/A'),
              _buildOverviewItem('Total Exposed Value', _stormOverview['totalExposedValue']?.toString() ?? 'N/A'),
              _buildOverviewItem('Est. Claims (5-15%)', _stormOverview['estClaims']?.toString() ?? 'N/A'),
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
                            style: const TextStyle(color: Colors.white38, fontSize: 8),
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
                              style: TextStyle(color: Colors.white38, fontSize: 8));
                        } else if (value == 1.0) {
                          return const Text('Cat 1',
                              style: TextStyle(color: Colors.white38, fontSize: 8));
                        } else if (value == 2.0) {
                          return const Text('Cat 2',
                              style: TextStyle(color: Colors.white38, fontSize: 8));
                        } else if (value == 3.0) {
                          return const Text('Cat 3',
                              style: TextStyle(color: Colors.white38, fontSize: 8));
                        } else if (value == 4.0) {
                          return const Text('Cat 4',
                              style: TextStyle(color: Colors.white38, fontSize: 8));
                        } else if (value == 5.0) {
                          return const Text('Cat 5',
                              style: TextStyle(color: Colors.white38, fontSize: 8));
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

  // Local hazard values (surge/rain/wave/wind) come from ui_data.geojson
  // for whichever location is currently selected (tap a marker on the map
  // to change it — defaults to the first location).
  Widget _buildHurricaneSummary() {
    final loc = _selectedLocationProps;
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
          _buildSummaryItem('Storm\nSurge',
              loc?['usofcl_fcst_surge_ft_LABEL']?.toString() ?? 'N/A'),
          _buildSummaryItem('Rainfall',
              loc?['usofcl_fcst_rain_in_LABEL']?.toString() ?? 'N/A'),
          _buildSummaryItem('Wave\nHeight',
              loc?['usofcl_fcst_wave_ft_LABEL']?.toString() ?? 'N/A'),
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
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            const Text('Local Hazards :',
                style: TextStyle(color: Colors.white54, fontSize: 11)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: hazards.entries
                  .where((e) => e.value != null && e.value.toString().isNotEmpty)
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
