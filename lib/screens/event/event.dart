// import 'package:RiskSphere/screens/event/widgets/hazard_info_section.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import '../../providers/custom_tile_providers.dart';
// import '../../utils/global_imports.dart' hide Marker;
// import '../../models/sov_list_model.dart';
// import 'dart:convert';
// import 'package:flutter/services.dart';
// import 'dart:ui' as ui;
// import 'package:http/http.dart' as http;
// import 'dart:io';
// import 'package:path_provider/path_provider.dart';
// import 'package:flutter/foundation.dart';
// import '../../utils/env.dart';
//
// Map<String, dynamic> parseJson(String body) {
//   return jsonDecode(body) as Map<String, dynamic>;
// }
//
// class EventVisulisationScreen extends StatefulWidget {
//   final Map<String, dynamic> notificationData;
//
//   const EventVisulisationScreen({required this.notificationData});
//
//   @override
//   State<EventVisulisationScreen> createState() =>
//       _EventVisulisationScreenState();
// }
//
// class _EventVisulisationScreenState extends State<EventVisulisationScreen> {
//   int _currentPage = 0;
//   bool _showGraph = false;
//
//   Set<Marker> _markers = {};
//   Set<Polyline> _polylines = {};
//   Set<Polygon> _polygons = {};
//   Set<Marker> _allMarkers = {};
//   String? selectedDate = "";
//   List<String> availableDates = [];
//   bool isMapView = true;
//   String? _currentMapUrl;
//   Set<TileOverlay> _tileOverlays = {};
//
//   BitmapDescriptor? _redCircleIcon;
//   BitmapDescriptor? _orangeCircleIcon;
//   BitmapDescriptor? _yellowCircleIcon;
//   BitmapDescriptor? _azureIcon;
//
//   // Raw HTTP client to bypass AppCheck and global HTTP interceptor overhead for public static assets
//   static final http.Client _rawHttpClient = http.Client();
//
//   // In-memory cache for fully parsed storm visualizations to make subsequent loads instant (0ms)
//   static final Map<String, Map<String, dynamic>> _parsedStormCache = {};
//
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       // Delaying heavy parsing until the transition animation completes
//       Future.delayed(const Duration(milliseconds: 1), () {
//         if (mounted) {
//           _initialize();
//         }
//       });
//     });
//   }
//
//   Future<void> _initialize() async
//     setState(() => _isLoading = true);
//
//     // 1. Fetch map tile overlay URL and locations data from the API first
//     await _fetchEventInfo(updateLoading: false);
//
//     // 2. Load and render storm GeoJSON layers asynchronously in the background
//     await loadStormGeoJson();
//
//     setState(() => _isLoading = false);
//   }
//
//   Future<String> _getLocalFileContent(String filename, String url) async {
//     try {
//       final directory = await getApplicationDocumentsDirectory();
//       final file = File('${directory.path}/$filename');
//
//       bool isCacheValid = false;
//       if (await file.exists()) {
//         try {
//           final lastModified = await file.lastModified();
//           final age = DateTime.now().difference(lastModified);
//           if (age.inMinutes < 30) {
//             isCacheValid = true;
//           }
//         } catch (e) {
//           print("Error checking cache file age: $e");
//         }
//       }
//
//       if (isCacheValid) {
//         try {
//           print("Loading $filename from valid local cache...");
//           return await file.readAsString();
//         } catch (e) {
//           print("Error reading cached file $filename: $e");
//         }
//       }
//
//       print("================ HTTP REQUEST ================");
//       print("Method: GET");
//       print("URL: $url");
//       print("Headers: {}");
//       print("==============================================");
//       try {
//         final response = await _rawHttpClient
//             .get(Uri.parse(url))
//             .timeout(const Duration(seconds: 10));
//         if (response.statusCode == 200) {
//           try {
//             await file.writeAsString(response.body);
//           } catch (e) {
//             print("Error saving $filename to cache: $e");
//           }
//           return response.body;
//         } else {
//           throw Exception(
//               "Failed to download $filename: Status ${response.statusCode}");
//         }
//       } catch (downloadError) {
//         if (await file.exists()) {
//           print(
//               "Download failed. Falling back to old cached file $filename. Error: $downloadError");
//           return await file.readAsString();
//         }
//         rethrow;
//       }
//     } catch (e) {
//       print("Error in local cache/download for $filename: $e");
//       rethrow;
//     }
//   }
//
//   Future<void> loadStormGeoJson() async {
//     final sw = Stopwatch()..start();
//     try {
//       final eventId = widget.notificationData['eventId']?.toString() ?? '';
//
//       // Check RAM cache first. If hit, restore state instantly and return.
//       if (eventId.isNotEmpty && _parsedStormCache.containsKey(eventId)) {
//         final cached = _parsedStormCache[eventId]!;
//         setState(() {
//           _markers = cached['markers'] as Set<Marker>;
//           _polylines = cached['polylines'] as Set<Polyline>;
//           _polygons = cached['polygons'] as Set<Polygon>;
//           _stormOverview = cached['overview'] as Map<String, dynamic>;
//           _windSpeedSeries = cached['windSpeedSeries'] as List<FlSpot>;
//           _intensitySeries = cached['intensitySeries'] as List<FlSpot>;
//           _chartDateLabels = cached['chartDateLabels'] as List<String>;
//           _maxWindSpeedFromSeries = cached['maxWindSpeedFromSeries'] as double;
//           _locationExposures =
//               cached['locationExposures'] as List<Map<String, dynamic>>;
//           _initialMapCenter = cached['initialMapCenter'] as LatLng?;
//           locationsData = cached['locationsData'] as List<dynamic>;
//         });
//
//         if (_initialMapCenter != null) {
//           WidgetsBinding.instance.addPostFrameCallback((_) {
//             if (mounted && _mapController != null) {
//               try {
//                 _mapController!.moveCamera(
//                   CameraUpdate.newLatLngZoom(_initialMapCenter!, 5),
//                 );
//               } catch (_) {}
//             }
//           });
//         }
//         return;
//       }
//
//       final dynamic rawUrls = widget.notificationData['frontendUrls'];
//       FrontendUrls? urls;
//       if (rawUrls is FrontendUrls) {
//         urls = rawUrls;
//       } else if (rawUrls is Map<String, dynamic>) {
//         urls = FrontendUrls.fromJson(rawUrls);
//       } else if (rawUrls is String) {
//         try {
//           urls = FrontendUrls.fromJson(jsonDecode(rawUrls));
//         } catch (e) {
//           print("Error parsing frontendUrls JSON string: $e");
//         }
//       }
//
//       String getCacheFilename(String url, String defaultName) {
//         try {
//           final uri = Uri.parse(url);
//           final segments = uri.pathSegments;
//           if (segments.length >= 2) {
//             return "${segments[segments.length - 2]}_${segments.last}";
//           } else if (segments.isNotEmpty) {
//             return segments.last;
//           }
//         } catch (e) {
//           print("Error getting cache filename for $url: $e");
//         }
//         return defaultName;
//       }
//
//       final bucket = Env.get('FIREBASE_STORAGE_BUCKET').isNotEmpty
//           ? Env.get('FIREBASE_STORAGE_BUCKET')
//           : 'risksphere-qa.firebasestorage.app';
//
//       String? trackUrl = urls?.stormTrackGeojson;
//       String? pointUrl = urls?.stormForecastPointsGeojson;
//       String? swathUrl = urls?.stormSwathGeojson;
//
//       if (trackUrl == null || pointUrl == null || swathUrl == null) {
//         Map<String, dynamic>? rawMap;
//         if (rawUrls is Map<String, dynamic>) {
//           rawMap = rawUrls;
//         } else if (rawUrls is Map) {
//           rawMap = Map<String, dynamic>.from(rawUrls);
//         } else if (rawUrls is String) {
//           try {
//             rawMap = jsonDecode(rawUrls) as Map<String, dynamic>?;
//           } catch (_) {}
//         }
//         if (rawMap != null) {
//           trackUrl ??= rawMap['storm_track']?.toString() ??
//               rawMap['storm_track.geojson']?.toString();
//           pointUrl ??= rawMap['storm_forecast_points']?.toString() ??
//               rawMap['storm_forecast_points.geojson']?.toString();
//           swathUrl ??= rawMap['storm_swath']?.toString() ??
//               rawMap['storm_swath.geojson']?.toString();
//         }
//       }
//       String getProxyUrl(String originalUrl) {
//         if (originalUrl.startsWith('http') &&
//             !originalUrl.startsWith('https://app.risksphere.ai')) {
//           return 'https://app.risksphere.ai/api/geojson/proxy?url=${Uri.encodeComponent(originalUrl)}';
//         }
//         return originalUrl;
//       }
//
//       // Download independently with null/empty safety checks and route through the web proxy
//       final trackFuture = (trackUrl != null && trackUrl.isNotEmpty)
//           ? _getLocalFileContent(
//               getCacheFilename(trackUrl, 'storm_track.geojson'),
//               getProxyUrl(trackUrl))
//           : Future.value('{"type": "FeatureCollection", "features": []}');
//
//       final pointFuture = (pointUrl != null && pointUrl.isNotEmpty)
//           ? _getLocalFileContent(
//               getCacheFilename(pointUrl, 'storm_forecast_points.geojson'),
//               getProxyUrl(pointUrl))
//           : Future.value('{"type": "FeatureCollection", "features": []}');
//
//       final swathFuture = (swathUrl != null && swathUrl.isNotEmpty)
//           ? _getLocalFileContent(
//               getCacheFilename(swathUrl, 'storm_swath.geojson'),
//               getProxyUrl(swathUrl))
//           : Future.value('{"type": "FeatureCollection", "features": []}');
//
//       final responses = await Future.wait([
//         trackFuture,
//         pointFuture,
//         swathFuture,
//       ]);
//       print("Download Time : ${sw.elapsedMilliseconds} ms");
//       final decoded = await Future.wait([
//         compute(parseJson, responses[0]),
//         compute(parseJson, responses[1]),
//         compute(parseJson, responses[2]),
//       ]);
//       print("JSON Decode Time : ${sw.elapsedMilliseconds} ms");
//       final trackJson = decoded[0];
//       final pointJson = decoded[1];
//       final coneJson = decoded[2];
//
//       // Pre-create circle icons (Red for hurricane, Orange for storm, Yellow for depression) if not already cached
//       _redCircleIcon ??= await _getCircleIcon(Colors.red, 24);
//       _orangeCircleIcon ??= await _getCircleIcon(Colors.orange, 24);
//       _yellowCircleIcon ??= await _getCircleIcon(Colors.yellow, 24);
//
//       // Parse Markers from forecast points
//       final pointFeatures = pointJson['features'] as List<dynamic>? ?? [];
//       Set<Marker> markers = {};
//       int processedCount = 0;
//       final markerSW = Stopwatch()..start();
//       for (var feature in pointFeatures) {
//         processedCount++;
//         if (processedCount % 500 == 0) {
//           await Future.delayed(Duration.zero);
//         }
//         final geometry = feature['geometry'];
//         if (geometry == null || geometry['type'] != 'Point') continue;
//
//         final coords = geometry['coordinates'] as List<dynamic>;
//         if (coords.length < 2) continue;
//
//         final lat = coords[1].toDouble();
//         final lng = coords[0].toDouble();
//
//         final props = feature['properties'] as Map<String, dynamic>? ?? {};
//
//         final markerId = props['ID']?.toString() ??
//             props['DTG']?.toString() ??
//             UniqueKey().toString();
//
//         final vmax = (props['VMAX'] as num?)?.toDouble() ?? 0.0;
//
//         BitmapDescriptor icon = _yellowCircleIcon!;
//         if (vmax >= 74) {
//           icon = _redCircleIcon!;
//         } else if (vmax >= 39) {
//           icon = _orangeCircleIcon!;
//         }
//
//         markers.add(
//           Marker(
//             markerId: MarkerId(markerId),
//             position: LatLng(lat, lng),
//             icon: icon,
//             anchor: const Offset(0.5, 0.5),
//             infoWindow: InfoWindow(
//               title: props['NAME']?.toString() ?? "Forecast Point",
//               snippet: "Wind Max: ${props['VMAX']} mph | Time: ${props['DTG']}",
//             ),
//           ),
//         );
//       }
//       print("Forecast Marker Time : ${markerSW.elapsedMilliseconds} ms");
//       print("Forecast Marker Count : ${markers.length}");
//       _azureIcon ??=
//           BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
//       final uiMarkerSW = Stopwatch()..start();
//       for (var loc in locationsData) {
//         processedCount++;
//         if (processedCount % 500 == 0) {
//           await Future.delayed(Duration.zero);
//         }
//         final props = loc as Map<String, dynamic>? ?? {};
//
//         double? lat;
//         final rawLat = props['latitude'] ?? props['lat'];
//         if (rawLat is num) {
//           lat = rawLat.toDouble();
//         } else if (rawLat is String) {
//           lat = double.tryParse(rawLat);
//         }
//
//         double? lng;
//         final rawLng = props['longitude'] ?? props['lng'];
//         if (rawLng is num) {
//           lng = rawLng.toDouble();
//         } else if (rawLng is String) {
//           lng = double.tryParse(rawLng);
//         }
//
//         if (lat == null || lng == null) continue;
//
//         final markerId =
//             props['location_id']?.toString() ?? UniqueKey().toString();
//
//         markers.add(
//           Marker(
//             markerId: MarkerId(markerId),
//             position: LatLng(lat, lng),
//             icon: _azureIcon!,
//             infoWindow: InfoWindow(
//               title:
//                   _firstNonEmpty(props, ['location_name', 'name', 'LocationName', 'address']) ??
//                       "Asset Location",
//               snippet:
//                   "TIV Exposed: ${_formatCurrency(props['TIV_Exposed'] ?? props['TIV'] ?? props['pd_value_sum'])} | Category: ${props['usofcl_fcst_sscats_LABEL'] ?? ''}",
//             ),
//             onTap: () {
//               setState(() => _selectedLocationProps = props);
//             },
//           ),
//         );
//       }
//       print("UI Marker Time : ${uiMarkerSW.elapsedMilliseconds} ms");
//       print("Total Marker Count : ${markers.length}");
//       // Parse Polylines from tracks
//       final trackFeatures = trackJson['features'] as List<dynamic>? ?? [];
//       Set<Polyline> polylines = {};
//       int polylineIndex = 0;
//       final polylineSW = Stopwatch()..start();
//       for (var feature in trackFeatures) {
//         processedCount++;
//         if (processedCount % 500 == 0) {
//           await Future.delayed(Duration.zero);
//         }
//         final geometry = feature['geometry'];
//         if (geometry == null || geometry['type'] != 'LineString') continue;
//         final coords = geometry['coordinates'] as List<dynamic>;
//         List<LatLng> points = coords.map((c) {
//           final list = c as List<dynamic>;
//           return LatLng(list[1].toDouble(), list[0].toDouble());
//         }).toList();
//
//         polylines.add(
//           Polyline(
//             polylineId: PolylineId('track_${polylineIndex++}'),
//             points: points,
//             color: Colors.red,
//             width: 3,
//           ),
//         );
//       }
//       print("Polyline Time : ${polylineSW.elapsedMilliseconds} ms");
//       print("Polyline Count : ${polylines.length}");
//       // Parse Polygons from cone/swath
//       final coneFeatures = coneJson['features'] as List<dynamic>? ?? [];
//       Set<Polygon> polygons = {};
//       int polygonIndex = 0;
//       final polygonSW = Stopwatch()..start();
//       for (var feature in coneFeatures) {
//         processedCount++;
//         if (processedCount % 500 == 0) {
//           await Future.delayed(Duration.zero);
//         }
//         final geometry = feature['geometry'];
//         if (geometry == null) continue;
//         final geomType = geometry['type'];
//         final props = feature['properties'] as Map<String, dynamic>? ?? {};
//
//         if (geomType == 'Polygon') {
//           final coordsList = geometry['coordinates'] as List<dynamic>;
//           for (var ring in coordsList) {
//             final points = (ring as List<dynamic>).map((c) {
//               final list = c as List<dynamic>;
//               return LatLng(list[1].toDouble(), list[0].toDouble());
//             }).toList();
//             Color polyColor = Colors.blue.withOpacity(0.15);
//             Color strokeColor = Colors.blue.withOpacity(0.5);
//
//             if (props['COLOR'] != null) {
//               final colorStr = props['COLOR'].toString();
//               try {
//                 if (colorStr.length == 8) {
//                   final a = int.parse(colorStr.substring(0, 2), radix: 16);
//                   final r = int.parse(colorStr.substring(2, 4), radix: 16);
//                   final g = int.parse(colorStr.substring(4, 6), radix: 16);
//                   final b = int.parse(colorStr.substring(6, 8), radix: 16);
//                   polyColor = Color.fromARGB(a, r, g, b);
//                   strokeColor = Color.fromARGB(255, r, g, b);
//                 }
//               } catch (_) {}
//             }
//
//             polygons.add(
//               Polygon(
//                 polygonId: PolygonId('swath_${polygonIndex++}'),
//                 points: points,
//                 fillColor: polyColor,
//                 strokeColor: strokeColor,
//                 strokeWidth: 1,
//               ),
//             );
//           }
//         }
//       }
//       print("Polygon Time : ${polygonSW.elapsedMilliseconds} ms");
//       print("Polygon Count : ${polygons.length}");
//
//       // ── Build the dynamic Overview + Location Exposure data ──
//       _buildGlobalStormOverview(trackFeatures, pointFeatures, locationsData);
//       _buildWindSpeedChart(pointFeatures);
//       _buildLocationExposuresFromUiFeatures(locationsData);
//
//       setState(() {
//         _markers = markers;
//         _polylines = polylines;
//         _polygons = polygons;
//       });
//       if (markers.isNotEmpty) {
//         final firstPoint = markers.first.position;
//         _initialMapCenter = firstPoint;
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           if (mounted && _mapController != null) {
//             try {
//               _mapController!.animateCamera(
//                 CameraUpdate.newLatLngZoom(firstPoint, 5),
//               );
//             } catch (_) {}
//           }
//         });
//       }
//
//       // Save fully parsed results to RAM cache before exiting
//       if (eventId.isNotEmpty) {
//         _parsedStormCache[eventId] = {
//           'markers': markers,
//           'polylines': polylines,
//           'polygons': polygons,
//           'overview': _stormOverview,
//           'windSpeedSeries': _windSpeedSeries,
//           'intensitySeries': _intensitySeries,
//           'chartDateLabels': _chartDateLabels,
//           'maxWindSpeedFromSeries': _maxWindSpeedFromSeries,
//           'locationExposures': _locationExposures,
//           'initialMapCenter': _initialMapCenter,
//           'locationsData': locationsData,
//         };
//       }
//     } catch (e) {
//       print("Error loading or parsing storm GeoJSON: $e");
//     }
//   }
//
//   // ════════════════════════════════════════════════════════════════════
//   //  DYNAMIC DATA (parsed from JSON) — replaces the old hardcoded values
//   // ════════════════════════════════════════════════════════════════════
//
//   /// Global storm metadata — from the FIRST feature of storm_track.geojson,
//   /// per the data dictionary: NAME, FCST_DTG, VMAX, FSPD. Track point count
//   /// comes from storm_forecast_points.geojson's feature count.
//   Map<String, dynamic> _stormOverview = {
//     'stormName': 'N/A',
//     'stormId': 'N/A',
//     'category': 'N/A',
//     'forecastTime': 'N/A',
//     'forwardSpeed': 'N/A',
//     'trackPointCount': 'N/A',
//     'maxWindSpeed': 'N/A',
//     'locationsImpacted': 'N/A',
//     'totalExposedValue': 'N/A',
//     'estClaims': 'N/A',
//   };
//
//   /// The currently "selected" property location (defaults to the first
//   /// entry in ui_data.geojson, updates when a marker is tapped). Drives the
//   /// per-location Hurricane Summary values.
//   Map<String, dynamic>? _selectedLocationProps;
//
//   List<Map<String, dynamic>> _locationExposures = [];
//
//   List<FlSpot> _windSpeedSeries = [];
//   List<FlSpot> _intensitySeries = [];
//   List<String> _chartDateLabels = [];
//   double _maxWindSpeedFromSeries = 0;
//
//   void _buildGlobalStormOverview(
//     List<dynamic> trackFeatures,
//     List<dynamic> pointFeatures,
//     List<dynamic> uiFeatures,
//   ) {
//     if (trackFeatures.isEmpty) return;
//
//     final trackProps =
//         (trackFeatures.first['properties'] as Map<String, dynamic>?) ?? {};
//
//     final stormName = trackProps['NAME']?.toString() ??
//         trackProps['STORMNAME']?.toString() ??
//         'Unknown';
//     final stormId = trackProps['STORMID']?.toString() ?? 'N/A';
//     final vmax = (trackProps['VMAX'] as num?)?.toDouble() ?? 0.0;
//     final fspd = trackProps['FSPD'];
//     final dtg =
//         trackProps['FCST_DTG']?.toString() ?? trackProps['DTG']?.toString();
//
//     // Financial calculations
//     final locationsCount = uiFeatures.length;
//     double totalTiv = 0.0;
//     for (var loc in uiFeatures) {
//       final props = loc as Map<String, dynamic>? ?? {};
//       final rawTiv =
//           props['TIV_Exposed'] ?? props['TIV'] ?? props['pd_value_sum'];
//       if (rawTiv != null) {
//         final tivVal = (rawTiv is num)
//             ? rawTiv.toDouble()
//             : double.tryParse(rawTiv.toString());
//         if (tivVal != null) {
//           totalTiv += tivVal;
//         }
//       }
//     }
//
//     double damageRatio = 0.05; // default 5%
//     if (vmax >= 157)
//       damageRatio = 0.15;
//     else if (vmax >= 130)
//       damageRatio = 0.12;
//     else if (vmax >= 111)
//       damageRatio = 0.10;
//     else if (vmax >= 96)
//       damageRatio = 0.08;
//     else if (vmax >= 74)
//       damageRatio = 0.05;
//     else
//       damageRatio = 0.02;
//
//     double estClaims = totalTiv * damageRatio;
//
//     setState(() {
//       _stormOverview = {
//         'stormName': stormName,
//         'stormId': stormId,
//         'category': _categoryFromVmax(vmax),
//         'forecastTime': _formatDtg(dtg),
//         'forwardSpeed': fspd != null ? '$fspd mph' : 'N/A',
//         'trackPointCount': pointFeatures.length.toString(),
//         'maxWindSpeed': vmax > 0 ? '${vmax.toStringAsFixed(0)} mph' : 'N/A',
//         'locationsImpacted': locationsCount.toString(),
//         'totalExposedValue': _formatCurrency(totalTiv),
//         'estClaims': _formatCurrency(estClaims),
//       };
//     });
//   }
//
//   double _categoryValueFromProps(Map<String, dynamic> props) {
//     final catDesc = props['CAT_DESC']?.toString().toLowerCase() ?? '';
//     if (catDesc.contains('5')) return 5.0;
//     if (catDesc.contains('4')) return 4.0;
//     if (catDesc.contains('3')) return 3.0;
//     if (catDesc.contains('2')) return 2.0;
//     if (catDesc.contains('1')) return 1.0;
//     if (catDesc.contains('tropical storm') || catDesc.contains('ts'))
//       return 0.5;
//     if (catDesc.contains('depression') || catDesc.contains('td')) return 0.2;
//
//     final vmax = (props['VMAX'] as num?)?.toDouble() ?? 0.0;
//     if (vmax >= 157) return 5.0;
//     if (vmax >= 130) return 4.0;
//     if (vmax >= 111) return 3.0;
//     if (vmax >= 96) return 2.0;
//     if (vmax >= 74) return 1.0;
//     if (vmax >= 39) return 0.5;
//     return 0.0;
//   }
//
//   /// Wind-speed-over-time chart, built from the chronological
//   /// storm_forecast_points.geojson (DTG + VMAX per point).
//   void _buildWindSpeedChart(List<dynamic> pointFeatures) {
//     if (pointFeatures.isEmpty) return;
//
//     final sortedPoints = List<dynamic>.from(pointFeatures);
//     sortedPoints.sort((a, b) {
//       final dtgA =
//           ((a['properties'] as Map<String, dynamic>?)?['DTG'] ?? '').toString();
//       final dtgB =
//           ((b['properties'] as Map<String, dynamic>?)?['DTG'] ?? '').toString();
//       return dtgA.compareTo(dtgB);
//     });
//
//     final wind = <FlSpot>[];
//     final intensity = <FlSpot>[];
//     final labels = <String>[];
//
//     for (var i = 0; i < sortedPoints.length; i++) {
//       final props =
//           (sortedPoints[i]['properties'] as Map<String, dynamic>?) ?? {};
//       final v = (props['VMAX'] as num?)?.toDouble();
//       if (v != null) {
//         wind.add(FlSpot(i.toDouble(), v));
//         intensity.add(FlSpot(i.toDouble(), _categoryValueFromProps(props)));
//       }
//       labels.add(_formatDtgShort(props['DTG']?.toString()));
//     }
//
//     setState(() {
//       _windSpeedSeries = wind;
//       _intensitySeries = intensity;
//       _chartDateLabels = labels;
//       _maxWindSpeedFromSeries = wind.isEmpty
//           ? 0
//           : wind.map((e) => e.y).reduce((a, b) => a > b ? a : b);
//     });
//   }
//
//   void _buildLocationExposuresFromUiFeatures(List<dynamic> uiFeatures) {
//     final exposures = <Map<String, dynamic>>[];
//
//     for (var loc in uiFeatures) {
//       final props = loc as Map<String, dynamic>? ?? {};
//
//       final locationName =
//           _firstNonEmpty(props, ['location_name', 'name', 'LocationName', 'address']) ??
//               'Unknown';
//       final county = _firstNonEmpty(props, ['County', 'county_name', 'county']) ?? '';
//       final state = _firstNonEmpty(props, ['State', 'state']) ?? '-';
//       final categoryLabel =
//           props['usofcl_fcst_sscats_LABEL']?.toString() ??
//           props['category']?.toString() ?? 'N/A';
//       final tiv = _formatCurrency(
//           props['TIV_Exposed'] ?? props['TIV'] ?? props['pd_value_sum']);
//
//       final stateVal = _firstNonEmpty(props, ['State', 'state']) ?? '-';
//       final windSpeedRaw = props['usofcl_swath_wind_mph_LABEL'] ?? props['wind_speed'];
//       double windNum = 0.0;
//       if (windSpeedRaw is num) {
//         windNum = windSpeedRaw.toDouble();
//       } else if (windSpeedRaw != null) {
//         windNum = double.tryParse(windSpeedRaw.toString()) ?? 0.0;
//       }
//       final int eventScore = (windNum > 0) ? ((windNum / 157.0) * 100.0).round().clamp(0, 100) : 0;
//
//       double? lat;
//       final rawLat = props['latitude'] ?? props['lat'];
//       if (rawLat is num) {
//         lat = rawLat.toDouble();
//       } else if (rawLat is String) {
//         lat = double.tryParse(rawLat);
//       }
//
//       double? lng;
//       final rawLng = props['longitude'] ?? props['lng'];
//       if (rawLng is num) {
//         lng = rawLng.toDouble();
//       } else if (rawLng is String) {
//         lng = double.tryParse(rawLng);
//       }
//
//       exposures.add({
//         'city': locationName,
//         'county': county,
//         'state': stateVal,
//         'event_score': eventScore,
//         'category': categoryLabel,
//         'tiv': tiv,
//         'catColor': _colorForCategory(categoryLabel),
//         'lat': lat,
//         'lng': lng,
//         'rawProps': props,
//         'hazards': {
//           'Surge': props['usofcl_fcst_surge_ft_LABEL']?.toString(),
//           'Rain': props['usofcl_fcst_rain_in_LABEL']?.toString(),
//           'Wave': props['usofcl_fcst_wave_ft_LABEL']?.toString(),
//           'Wind': props['usofcl_swath_wind_mph_LABEL']?.toString(),
//         },
//       });
//     }
//
//     setState(() {
//       _locationExposures = exposures;
//
//       _selectedLocationProps ??= uiFeatures.isNotEmpty
//           ? (uiFeatures.first['properties'] as Map<String, dynamic>?)
//           : null;
//     });
//   }
//
//   String? _firstNonEmpty(Map<String, dynamic> props, List<String> keys) {
//     for (final key in keys) {
//       final value = props[key];
//       if (value != null && value.toString().trim().isNotEmpty) {
//         return value.toString();
//       }
//     }
//     return null;
//   }
//
//   String _categoryFromVmax(double vmax) {
//     if (vmax >= 157) return 'Category 5\n(157+ mph)';
//     if (vmax >= 130) return 'Category 4\n(130-156 mph)';
//     if (vmax >= 111) return 'Category 3\n(111-129 mph)';
//     if (vmax >= 96) return 'Category 2\n(96-110 mph)';
//     if (vmax >= 74) return 'Category 1\n(74-95 mph)';
//     if (vmax >= 39) return 'Tropical Storm\n(39-73 mph)';
//     return 'Tropical Depression\n(<39 mph)';
//   }
//
//   String _formatLastUpdated(DateTime dateTime) {
//     const months = [
//       'Jan',
//       'Feb',
//       'Mar',
//       'Apr',
//       'May',
//       'Jun',
//       'Jul',
//       'Aug',
//       'Sep',
//       'Oct',
//       'Nov',
//       'Dec'
//     ];
//     final monthStr = months[dateTime.month - 1];
//     final day = dateTime.day;
//     final year = dateTime.year;
//
//     int hour = dateTime.hour;
//     final ampm = hour >= 12 ? 'PM' : 'AM';
//     hour = hour % 12;
//     if (hour == 0) hour = 12;
//
//     final minute = dateTime.minute.toString().padLeft(2, '0');
//
//     return "Last Updated: $monthStr $day, $year $hour:$minute $ampm";
//   }
//
//   String get _lastUpdatedString {
//     final rawTimestamp = widget.notificationData['timestamp'];
//     if (rawTimestamp is DateTime) {
//       return _formatLastUpdated(rawTimestamp);
//     } else if (rawTimestamp is String) {
//       final parsed = DateTime.tryParse(rawTimestamp);
//       if (parsed != null) {
//         return _formatLastUpdated(parsed);
//       }
//       return "Last Updated: $rawTimestamp";
//     }
//     return "Last Updated: N/A";
//   }
//
//   // NOTE: assumes FCST_DTG / DTG are in yyyyMMddHH format, matching the
//   // sample keys seen in storm_forecast_points.geojson. If FCST_DTG uses a
//   // different format (e.g. ISO 8601), adjust this parser accordingly.
//   String _formatDtg(String? dtg) {
//     if (dtg == null || dtg.length < 10) return dtg ?? 'N/A';
//     try {
//       final year = dtg.substring(0, 4);
//       final month = int.parse(dtg.substring(4, 6));
//       final day = dtg.substring(6, 8);
//       final hour = dtg.substring(8, 10);
//       const months = [
//         'Jan',
//         'Feb',
//         'Mar',
//         'Apr',
//         'May',
//         'Jun',
//         'Jul',
//         'Aug',
//         'Sep',
//         'Oct',
//         'Nov',
//         'Dec'
//       ];
//       return '${months[month - 1]} $day, $year •\n$hour:00 UTC';
//     } catch (_) {
//       return dtg;
//     }
//   }
//
//   String _formatDtgShort(String? dtg) {
//     if (dtg == null || dtg.length < 8) return '';
//     try {
//       final month = int.parse(dtg.substring(4, 6));
//       final day = dtg.substring(6, 8);
//       const months = [
//         'Jan',
//         'Feb',
//         'Mar',
//         'Apr',
//         'May',
//         'Jun',
//         'Jul',
//         'Aug',
//         'Sep',
//         'Oct',
//         'Nov',
//         'Dec'
//       ];
//       if (dtg.length >= 10) {
//         final hour = dtg.substring(8, 10);
//         return '${months[month - 1]} $day $hour:00';
//       }
//       return '${months[month - 1]} $day';
//     } catch (_) {
//       return '';
//     }
//   }
//
//   String _formatCurrency(dynamic raw) {
//     if (raw == null) return 'N/A';
//     final value =
//         (raw is num) ? raw.toDouble() : double.tryParse(raw.toString());
//     if (value == null) return raw.toString();
//     if (value >= 1e9) return '\$${(value / 1e9).toStringAsFixed(1)}B';
//     if (value >= 1e6) return '\$${(value / 1e6).toStringAsFixed(1)}M';
//     if (value >= 1e3) return '\$${(value / 1e3).toStringAsFixed(1)}K';
//     return '\$${value.toStringAsFixed(0)}';
//   }
//
//   Color _colorForCategory(String category) {
//     if (category.contains('5') || category.contains('4')) return Colors.red;
//     if (category.contains('3') || category.contains('2')) {
//       return Colors.orange;
//     }
//     if (category.contains('1') ||
//         category.toLowerCase().contains('tropical storm')) {
//       return Colors.yellow;
//     }
//     return Colors.grey;
//   }
//
//   Future<BitmapDescriptor> _getCircleIcon(Color color, int size) async {
//     final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
//     final Canvas canvas = Canvas(pictureRecorder);
//     final Paint paint = Paint()
//       ..color = color
//       ..style = PaintingStyle.fill;
//
//     final Paint borderPaint = Paint()
//       ..color = Colors.white
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 2.0;
//
//     final double radius = size / 2.0;
//     canvas.drawCircle(Offset(radius, radius), radius - 2.0, paint);
//     canvas.drawCircle(Offset(radius, radius), radius - 2.0, borderPaint);
//
//     final ui.Image image =
//         await pictureRecorder.endRecording().toImage(size, size);
//     final ByteData? byteData =
//         await image.toByteData(format: ui.ImageByteFormat.png);
//     return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
//   }
//
//   GoogleMapController? _mapController;
//   int _selectedTab = 0;
//   bool _isExpanded = false;
//   bool _showNotificationDot = true;
//   final PageController _pageController = PageController();
//   bool _isLoading = true;
//
//   late double _initialLat;
//   late double _initialLng;
//   LatLng? _initialMapCenter;
//   List<dynamic> locationsData = [];
//
//   void _buildTileOverlay(String? url) {
//     if (url == null || url.isEmpty) {
//       if (_tileOverlays.isNotEmpty) {
//         setState(() => _tileOverlays = {});
//       }
//       return;
//     }
//     if (url == _currentMapUrl) return;
//     _currentMapUrl = url;
//
//     setState(() {
//       _tileOverlays = {
//         TileOverlay(
//           tileOverlayId: const TileOverlayId('map'),
//           tileProvider: CustomTileProvider1(baseUrl: url),
//           fadeIn: false,
//           transparency: 0.0,
//           zIndex: 1,
//         ),
//       };
//     });
//   }
//
//   Future<void> _fetchEventInfo({bool updateLoading = true}) async {
//     final provider = Provider.of<NewsFeedProvider>(
//       context,
//       listen: false,
//     );
//
//     final eventId = widget.notificationData['eventId'];
//
//     print("EVENT ID 👉 $eventId");
//
//     if (updateLoading) {
//       setState(() => _isLoading = true);
//     }
//
//     try {
//       // 1. Fetch Earth Engine Map Overlay URL
//       final fetchedMapUrl = await provider.fetchMapUrl(
//         eventId,
//       );
//
//       print("FINAL MAP URL 👉 $fetchedMapUrl");
//
//       // 2. Fetch full Event Info (which returns the locations_data collection)
//       await provider.fetchEventInfo(
//         eventId: eventId,
//       );
//
//       final result = provider.eventInfo;
//       if (result.isNotEmpty) {
//         final fetchedLocations = result['locations_data'] as List<dynamic>? ?? [];
//         setState(() {
//           locationsData = fetchedLocations;
//         });
//
//         // Set the map center focus using the first asset location safely
//         if (fetchedLocations.isNotEmpty) {
//           final firstLocation = fetchedLocations.first;
//
//           double? lat;
//           final rawLat = firstLocation['latitude'] ?? firstLocation['lat'];
//           if (rawLat is num) {
//             lat = rawLat.toDouble();
//           } else if (rawLat is String) {
//             lat = double.tryParse(rawLat);
//           }
//
//           double? lng;
//           final rawLng = firstLocation['longitude'] ?? firstLocation['lng'];
//           if (rawLng is num) {
//             lng = rawLng.toDouble();
//           } else if (rawLng is String) {
//             lng = double.tryParse(rawLng);
//           }
//
//           _initialLat = lat ?? 20.5937;
//           _initialLng = lng ?? 78.9629;
//           _initialMapCenter = LatLng(_initialLat, _initialLng);
//         }
//       }
//
//       if (updateLoading) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//
//       /// BUILD TILE OVERLAY
//       _buildTileOverlay(
//         fetchedMapUrl,
//       );
//     } catch (e) {
//       print("ERROR FETCHING MAP URL / EVENT INFO: $e");
//       if (updateLoading) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }
//
//   @override
//   void dispose() {
//     _pageController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       child: Consumer<ThemeProvider>(builder: (
//         context,
//         themeProvider,
//         child,
//       ) {
//         return Scaffold(
//           backgroundColor: const Color(0xFF0D0D0D),
//           appBar: CustomAppBar(
//             isExpanded: _isExpanded,
//             showDropdown: true,
//             showNotificationDot: _showNotificationDot,
//             onExpandPressed: (isExpanded) {
//               setState(() => _isExpanded = isExpanded);
//             },
//             onSearchPressed: () {
//               setState(() => _isExpanded = !_isExpanded);
//             },
//           ),
//           body: SafeArea(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.start,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 HazardInfoSection(
//                   hazardName:
//                       widget.notificationData['title'] ?? "Event Hazard",
//                   selectedDate: "12/1/1111",
//                   lastUpdated: _lastUpdatedString,
//                   availableDates: availableDates,
//                   onDateChanged: (value) {
//                     setState(() {
//                       selectedDate = value;
//                     });
//                     _fetchEventInfo();
//                   },
//                 ),
//                 Expanded(
//                     child: _isLoading
//                         ? const Center(
//                             child: CircularProgressIndicator(
//                               color: Colors.white,
//                             ),
//                           )
//                         : isMapView
//                             ? Stack(
//                                 children: [
//                                   Container(
//                                     margin: const EdgeInsets.fromLTRB(
//                                         16, 1, 16, 2.0),
//                                     decoration: BoxDecoration(
//                                       borderRadius: BorderRadius.circular(20.0),
//                                       color: Colors.grey.shade100,
//                                     ),
//                                     clipBehavior: Clip.antiAlias,
//                                     child: GoogleMap(
//                                       onMapCreated: (controller) {
//                                         _mapController = controller;
//                                         if (_initialMapCenter != null) {
//                                           _mapController!.moveCamera(
//                                             CameraUpdate.newLatLngZoom(
//                                                 _initialMapCenter!, 5),
//                                           );
//                                         }
//                                       },
//                                       initialCameraPosition: CameraPosition(
//                                         target: _initialMapCenter ??
//                                             LatLng(20.5937, 78.9629),
//                                         zoom: 5,
//                                       ),
//                                       markers: _markers,
//                                       polylines: _polylines,
//                                       polygons: _polygons,
//                                       tileOverlays: _tileOverlays,
//                                       mapToolbarEnabled: false,
//                                       mapType: MapType.normal,
//                                       myLocationButtonEnabled: true,
//                                       zoomControlsEnabled: true,
//                                     ),
//                                   ),
//                                 ],
//                               )
//                             : Padding(
//                                 padding: const EdgeInsets.all(16),
//                                 child: Column(
//                                   children: [
//                                     Container(
//                                       decoration: BoxDecoration(
//                                         color: Colors.grey.shade800,
//                                         border: Border.all(
//                                           color: Colors.grey.shade700,
//                                         ),
//                                       ),
//                                       child: IntrinsicHeight(
//                                         child: Row(
//                                           children: [
//                                             Expanded(
//                                               flex: 3,
//                                               child: Container(
//                                                 padding:
//                                                     const EdgeInsets.all(12),
//                                                 decoration: BoxDecoration(
//                                                   border: Border(
//                                                     right: BorderSide(
//                                                       color:
//                                                           Colors.grey.shade700,
//                                                     ),
//                                                   ),
//                                                 ),
//                                                 child:
//                                                     const Text("Location Name"),
//                                               ),
//                                             ),
//                                             Expanded(
//                                               flex: 4,
//                                               child: Container(
//                                                 padding:
//                                                     const EdgeInsets.all(12),
//                                                 decoration: BoxDecoration(
//                                                   border: Border(
//                                                     right: BorderSide(
//                                                       color:
//                                                           Colors.grey.shade700,
//                                                     ),
//                                                   ),
//                                                 ),
//                                                 child: const Text("Address"),
//                                               ),
//                                             ),
//                                             Expanded(
//                                               flex: 2,
//                                               child: Container(
//                                                 padding:
//                                                     const EdgeInsets.all(12),
//                                                 decoration: BoxDecoration(
//                                                   border: Border(
//                                                     right: BorderSide(
//                                                       color:
//                                                           Colors.grey.shade700,
//                                                     ),
//                                                   ),
//                                                 ),
//                                                 child:
//                                                     const Text("Hazard Name"),
//                                               ),
//                                             ),
//                                             Expanded(
//                                               flex: 2,
//                                               child: Container(
//                                                 padding:
//                                                     const EdgeInsets.all(12),
//                                                 child: const Text("Event Name"),
//                                               ),
//                                             ),
//                                           ],
//                                         ),
//                                       ),
//                                     ),
//                                     Expanded(
//                                       child: _isLoading
//                                           ? const Center(
//                                               child:
//                                                   CircularProgressIndicator(),
//                                             )
//                                           : locationsData.isEmpty
//                                               ? const Center(
//                                                   child: Text(
//                                                     "No Data Found",
//                                                     style: TextStyle(
//                                                       fontSize: 16,
//                                                       fontWeight:
//                                                           FontWeight.w600,
//                                                     ),
//                                                   ),
//                                                 )
//                                               : ListView.builder(
//                                                   itemCount:
//                                                       locationsData.length,
//                                                   itemBuilder:
//                                                       (context, index) {
//                                                     final location =
//                                                         locationsData[index];
//
//                                                     final eventMap =
//                                                         location['event']
//                                                                 as Map<String,
//                                                                     dynamic>? ??
//                                                             {};
//
//                                                     final firstEvent = eventMap
//                                                             .isNotEmpty
//                                                         ? eventMap.values.first
//                                                             as Map<String,
//                                                                 dynamic>
//                                                         : {};
//
//                                                     return Container(
//                                                       decoration: BoxDecoration(
//                                                         border: Border(
//                                                           left: BorderSide(
//                                                             color: Colors
//                                                                 .grey.shade700,
//                                                           ),
//                                                           right: BorderSide(
//                                                             color: Colors
//                                                                 .grey.shade700,
//                                                           ),
//                                                           bottom: BorderSide(
//                                                             color: Colors
//                                                                 .grey.shade700,
//                                                           ),
//                                                         ),
//                                                       ),
//                                                       child: IntrinsicHeight(
//                                                         child: Row(
//                                                           crossAxisAlignment:
//                                                               CrossAxisAlignment
//                                                                   .stretch,
//                                                           children: [
//                                                             Expanded(
//                                                               flex: 3,
//                                                               child: Container(
//                                                                 padding:
//                                                                     const EdgeInsets
//                                                                         .all(
//                                                                         12),
//                                                                 decoration:
//                                                                     BoxDecoration(
//                                                                   border:
//                                                                       Border(
//                                                                     right:
//                                                                         BorderSide(
//                                                                       color: Colors
//                                                                           .grey
//                                                                           .shade700,
//                                                                     ),
//                                                                   ),
//                                                                 ),
//                                                                 child: Text(
//                                                                   location['location_name']
//                                                                           ?.toString() ??
//                                                                       '',
//                                                                   maxLines: 2,
//                                                                   overflow:
//                                                                       TextOverflow
//                                                                           .ellipsis,
//                                                                 ),
//                                                               ),
//                                                             ),
//                                                             Expanded(
//                                                               flex: 4,
//                                                               child: Container(
//                                                                 padding:
//                                                                     const EdgeInsets
//                                                                         .all(
//                                                                         12),
//                                                                 decoration:
//                                                                     BoxDecoration(
//                                                                   border:
//                                                                       Border(
//                                                                     right:
//                                                                         BorderSide(
//                                                                       color: Colors
//                                                                           .grey
//                                                                           .shade700,
//                                                                     ),
//                                                                   ),
//                                                                 ),
//                                                                 child: Text(
//                                                                   location['address']
//                                                                           ?.toString() ??
//                                                                       '',
//                                                                   maxLines: 3,
//                                                                   overflow:
//                                                                       TextOverflow
//                                                                           .ellipsis,
//                                                                 ),
//                                                               ),
//                                                             ),
//                                                             Expanded(
//                                                               flex: 2,
//                                                               child: Container(
//                                                                 padding:
//                                                                     const EdgeInsets
//                                                                         .all(
//                                                                         12),
//                                                                 decoration:
//                                                                     BoxDecoration(
//                                                                   border:
//                                                                       Border(
//                                                                     right:
//                                                                         BorderSide(
//                                                                       color: Colors
//                                                                           .grey
//                                                                           .shade700,
//                                                                     ),
//                                                                   ),
//                                                                 ),
//                                                                 child: Text(
//                                                                   firstEvent['hazard_name']
//                                                                           ?.toString() ??
//                                                                       '',
//                                                                   maxLines: 2,
//                                                                   overflow:
//                                                                       TextOverflow
//                                                                           .ellipsis,
//                                                                 ),
//                                                               ),
//                                                             ),
//                                                             Expanded(
//                                                               flex: 2,
//                                                               child: Container(
//                                                                 padding:
//                                                                     const EdgeInsets
//                                                                         .all(
//                                                                         12),
//                                                                 child: Text(
//                                                                   firstEvent['event_name']
//                                                                           ?.toString() ??
//                                                                       '',
//                                                                   maxLines: 2,
//                                                                   overflow:
//                                                                       TextOverflow
//                                                                           .ellipsis,
//                                                                 ),
//                                                               ),
//                                                             ),
//                                                           ],
//                                                         ),
//                                                       ),
//                                                     );
//                                                   },
//                                                 ),
//                                     )
//                                   ],
//                                 ),
//                               )),
//                 _buildTabBar(),
//                 Expanded(
//                   child: _selectedTab == 0
//                       ? _buildOverviewTab()
//                       : _buildLocationExposureTab(),
//                 ),
//                 // if (_locationExposures.length > 1) _buildBottomNavigation(),
//               ],
//             ),
//           ),
//         );
//       }),
//     );
//   }
//
//   Widget _buildTabBar() {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
//       decoration: BoxDecoration(
//         color: const Color(0xFF1E1E1E),
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Row(
//         children: [
//           _buildTab('Overview', 0),
//           _buildTab('Location Exposure', 1),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildTab(String title, int index) {
//     final isSelected = _selectedTab == index;
//     return Expanded(
//       child: GestureDetector(
//         onTap: () => setState(() => _selectedTab = index),
//         child: Container(
//           padding: const EdgeInsets.symmetric(vertical: 10),
//           decoration: BoxDecoration(
//             color: isSelected ? AppColors.primaryMain : Colors.transparent,
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: Text(
//             title,
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               color: isSelected ? Colors.black : Colors.white,
//               fontSize: 13,
//               fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   // ─── Overview Tab (now driven by _stormOverview / selected location) ──
//   Widget _buildOverviewTab() {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           _buildSectionHeader('Storm Overview', showGraphToggle: true),
//           const SizedBox(height: 12),
//           if (_showGraph) ...[
//             _buildStormGraph(),
//             const SizedBox(height: 12),
//             _buildGraphStats(),
//             const SizedBox(height: 20),
//             _buildSectionHeader('Storm Intensity Over Time'),
//             const SizedBox(height: 12),
//             _buildStormIntensityGraph(),
//           ] else ...[
//             _buildStormOverviewGrid(),
//           ],
//           const SizedBox(height: 16),
//           _buildSectionHeader('Hurricane Summary'),
//           const SizedBox(height: 4),
//           if (_selectedLocationProps != null)
//             Padding(
//               padding: const EdgeInsets.only(bottom: 8),
//               child: Text(
//                 'Showing local hazard data for: '
//                 '${_firstNonEmpty(_selectedLocationProps!, [
//                           'name',
//                           'LocationName',
//                           'address'
//                         ]) ?? 'Selected location'}',
//                 style: const TextStyle(color: Colors.white38, fontSize: 10),
//               ),
//             ),
//           _buildHurricaneSummary(),
//           const SizedBox(height: 16),
//           _buildSectionHeader('Storm Movement'),
//           const SizedBox(height: 12),
//           _buildStormMovement(),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildSectionHeader(String title, {bool showGraphToggle = false}) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Text(
//           title,
//           style: const TextStyle(
//             color: Color(0xFF2196F3),
//             fontWeight: FontWeight.bold,
//             fontSize: 14,
//           ),
//         ),
//         if (showGraphToggle)
//           Row(
//             children: [
//               const Text('Graph',
//                   style: TextStyle(color: Colors.white70, fontSize: 12)),
//               const SizedBox(width: 6),
//               Switch(
//                 value: _showGraph,
//                 onChanged: (v) => setState(() => _showGraph = v),
//                 activeColor: const Color(0xFF2196F3),
//                 materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
//               ),
//             ],
//           ),
//       ],
//     );
//   }
//
//   Widget _buildStormOverviewGrid() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: const Color(0xFF1E1E1E),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.white10),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Top Half: Storm Metadata
//           const Text(
//             'STORM METADATA',
//             style: TextStyle(
//               color: Colors.blueAccent,
//               fontSize: 10,
//               fontWeight: FontWeight.bold,
//               letterSpacing: 1.2,
//             ),
//           ),
//           const SizedBox(height: 12),
//           Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _buildOverviewItem('Storm Name',
//                   _stormOverview['stormName']?.toString() ?? 'N/A'),
//               _buildOverviewItem(
//                   'ATCF ID', _stormOverview['stormId']?.toString() ?? 'N/A'),
//               _buildOverviewItem(
//                   'Category', _stormOverview['category']?.toString() ?? 'N/A'),
//             ],
//           ),
//           const SizedBox(height: 12),
//           Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _buildOverviewItem('Forecast Time',
//                   _stormOverview['forecastTime']?.toString() ?? 'N/A'),
//               _buildOverviewItem('Forward Speed',
//                   _stormOverview['forwardSpeed']?.toString() ?? 'N/A'),
//               _buildOverviewItem('Max Wind Speed',
//                   _stormOverview['maxWindSpeed']?.toString() ?? 'N/A'),
//             ],
//           ),
//           // const Divider(color: Colors.white12, height: 24),
//           // // Bottom Half: Financial Impact
//           // const Text(
//           //   'FINANCIAL IMPACT AGGREGATIONS',
//           //   style: TextStyle(
//           //     color: Colors.greenAccent,
//           //     fontSize: 10,
//           //     fontWeight: FontWeight.bold,
//           //     letterSpacing: 1.2,
//           //   ),
//           // ),
//           // const SizedBox(height: 12),
//           // Row(
//           //   crossAxisAlignment: CrossAxisAlignment.start,
//           //   children: [
//           //     _buildOverviewItem('Locations Impacted', _stormOverview['locationsImpacted']?.toString() ?? 'N/A'),
//           //     _buildOverviewItem('Total Exposed Value', _stormOverview['totalExposedValue']?.toString() ?? 'N/A'),
//           //     _buildOverviewItem('Est. Claims (5-15%)', _stormOverview['estClaims']?.toString() ?? 'N/A'),
//           //   ],
//           // ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildOverviewItem(String label, String value) {
//     return Expanded(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(label,
//               style: const TextStyle(color: Colors.white54, fontSize: 10)),
//           const SizedBox(height: 4),
//           Text(value,
//               style: const TextStyle(
//                   color: Colors.white,
//                   fontSize: 11,
//                   fontWeight: FontWeight.w600)),
//         ],
//       ),
//     );
//   }
//
//   // ─── Storm Graph — plots wind speed over the forecast track chronology ──
//   List<FlSpot> _getMockedSurgeSeries() {
//     return _windSpeedSeries.map((spot) {
//       double surgeVal = spot.y > 30 ? (spot.y - 30) * 0.15 : 0.0;
//       return FlSpot(spot.x, surgeVal * 8);
//     }).toList();
//   }
//
//   List<FlSpot> _getMockedRainSeries() {
//     return _windSpeedSeries.map((spot) {
//       double rainVal = spot.y > 20 ? (spot.y - 20) * 0.10 : 0.0;
//       return FlSpot(spot.x, rainVal * 8);
//     }).toList();
//   }
//
//   List<FlSpot> _getMockedWaveSeries() {
//     return _windSpeedSeries.map((spot) {
//       double waveVal = spot.y > 30 ? (spot.y - 30) * 0.20 : 0.0;
//       return FlSpot(spot.x, waveVal * 8);
//     }).toList();
//   }
//
//   Widget _buildStormGraph() {
//     return Container(
//       height: 240,
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: const Color(0xFF1E1E1E),
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: _windSpeedSeries.isEmpty
//           ? const Center(
//               child: Text(
//                 'No forecast wind data available',
//                 style: TextStyle(color: Colors.white38, fontSize: 12),
//               ),
//             )
//           : LineChart(
//               LineChartData(
//                 backgroundColor: const Color(0xFF1E1E1E),
//                 gridData: FlGridData(
//                   show: true,
//                   drawVerticalLine: true,
//                   getDrawingHorizontalLine: (_) => FlLine(
//                     color: Colors.white12,
//                     strokeWidth: 0.5,
//                   ),
//                   getDrawingVerticalLine: (_) => FlLine(
//                     color: Colors.white12,
//                     strokeWidth: 0.5,
//                   ),
//                 ),
//                 titlesData: FlTitlesData(
//                   leftTitles: AxisTitles(
//                     sideTitles: SideTitles(
//                       showTitles: true,
//                       reservedSize: 28,
//                       getTitlesWidget: (value, _) => Text(
//                         value.toInt().toString(),
//                         style:
//                             const TextStyle(color: Colors.white38, fontSize: 8),
//                       ),
//                     ),
//                   ),
//                   bottomTitles: AxisTitles(
//                     sideTitles: SideTitles(
//                       showTitles: true,
//                       reservedSize: 50,
//                       getTitlesWidget: (value, _) {
//                         final idx = value.toInt();
//                         if (idx < 0 || idx >= _chartDateLabels.length) {
//                           return const SizedBox.shrink();
//                         }
//                         if (_chartDateLabels.length > 8 && idx % 4 != 0) {
//                           return const SizedBox.shrink();
//                         }
//                         return Padding(
//                           padding: const EdgeInsets.only(top: 8.0),
//                           child: Transform.rotate(
//                             angle: -0.5,
//                             child: Text(
//                               _chartDateLabels[idx],
//                               style: const TextStyle(
//                                   color: Colors.white38, fontSize: 7),
//                             ),
//                           ),
//                         );
//                       },
//                     ),
//                   ),
//                   rightTitles: AxisTitles(
//                     sideTitles: SideTitles(
//                       showTitles: true,
//                       reservedSize: 28,
//                       getTitlesWidget: (value, _) {
//                         final rightVal = value / 8;
//                         if (rightVal % 5 == 0) {
//                           return Text(
//                             rightVal.toInt().toString(),
//                             style: const TextStyle(
//                                 color: Colors.white38, fontSize: 8),
//                           );
//                         }
//                         return const SizedBox.shrink();
//                       },
//                     ),
//                   ),
//                   topTitles: const AxisTitles(
//                       sideTitles: SideTitles(showTitles: false)),
//                 ),
//                 minY: 0,
//                 maxY: 160,
//                 borderData: FlBorderData(show: false),
//                 lineBarsData: [
//                   _buildLine(_windSpeedSeries, const Color(0xFFE53935)),
//                   // Red
//                   _buildLine(_getMockedSurgeSeries(), const Color(0xFF2196F3)),
//                   // Blue
//                   _buildLine(_getMockedRainSeries(), const Color(0xFF4CAF50)),
//                   // Green
//                   _buildLine(_getMockedWaveSeries(), const Color(0xFF9C27B0)),
//                   // Purple
//                 ],
//               ),
//             ),
//     );
//   }
//
//   Widget _buildStormIntensityGraph() {
//     return Container(
//       height: 240,
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: const Color(0xFF1E1E1E),
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: _intensitySeries.isEmpty
//           ? const Center(
//               child: Text(
//                 'No intensity timeline data available',
//                 style: TextStyle(color: Colors.white38, fontSize: 12),
//               ),
//             )
//           : BarChart(
//               BarChartData(
//                 backgroundColor: const Color(0xFF1E1E1E),
//                 gridData: FlGridData(
//                   show: true,
//                   drawVerticalLine: true,
//                   drawHorizontalLine: true,
//                   getDrawingHorizontalLine: (_) => FlLine(
//                     color: Colors.white12,
//                     strokeWidth: 0.5,
//                   ),
//                   getDrawingVerticalLine: (_) => FlLine(
//                     color: Colors.white12,
//                     strokeWidth: 0.5,
//                   ),
//                 ),
//                 titlesData: FlTitlesData(
//                   leftTitles: AxisTitles(
//                     sideTitles: SideTitles(
//                       showTitles: true,
//                       reservedSize: 36,
//                       getTitlesWidget: (value, _) {
//                         if (value == 1.0) {
//                           return const Text('Cat 1',
//                               style: TextStyle(
//                                   color: Colors.white38, fontSize: 8));
//                         } else if (value == 2.0) {
//                           return const Text('Cat 2',
//                               style: TextStyle(
//                                   color: Colors.white38, fontSize: 8));
//                         } else if (value == 3.0) {
//                           return const Text('Cat 3',
//                               style: TextStyle(
//                                   color: Colors.white38, fontSize: 8));
//                         } else if (value == 4.0) {
//                           return const Text('Cat 4',
//                               style: TextStyle(
//                                   color: Colors.white38, fontSize: 8));
//                         } else if (value == 5.0) {
//                           return const Text('Cat 5',
//                               style: TextStyle(
//                                   color: Colors.white38, fontSize: 8));
//                         }
//                         return const SizedBox.shrink();
//                       },
//                     ),
//                   ),
//                   bottomTitles: AxisTitles(
//                     sideTitles: SideTitles(
//                       showTitles: true,
//                       reservedSize: 50,
//                       getTitlesWidget: (value, _) {
//                         final idx = value.toInt();
//                         if (idx < 0 || idx >= _chartDateLabels.length) {
//                           return const SizedBox.shrink();
//                         }
//                         if (_chartDateLabels.length > 8 && idx % 4 != 0) {
//                           return const SizedBox.shrink();
//                         }
//                         return Padding(
//                           padding: const EdgeInsets.only(top: 8.0),
//                           child: Transform.rotate(
//                             angle: -0.5,
//                             child: Text(
//                               _chartDateLabels[idx],
//                               style: const TextStyle(
//                                   color: Colors.white38, fontSize: 7),
//                             ),
//                           ),
//                         );
//                       },
//                     ),
//                   ),
//                   rightTitles: const AxisTitles(
//                       sideTitles: SideTitles(showTitles: false)),
//                   topTitles: const AxisTitles(
//                       sideTitles: SideTitles(showTitles: false)),
//                 ),
//                 minY: 0,
//                 maxY: 5,
//                 borderData: FlBorderData(show: false),
//                 barGroups: _intensitySeries.map((spot) {
//                   final val = spot.y;
//                   Color barColor =
//                       const Color(0xFF2196F3); // Blue for TS / TD (below Cat 1)
//                   if (val >= 4.0) {
//                     barColor =
//                         const Color(0xFFE57373); // Light red/pink for Cat 4/5
//                   } else if (val >= 1.0) {
//                     barColor =
//                         const Color(0xFFFFB74D); // Yellow/orange for Cat 1/2/3
//                   }
//
//                   return BarChartGroupData(
//                     x: spot.x.toInt(),
//                     barRods: [
//                       BarChartRodData(
//                         toY: val,
//                         color: barColor,
//                         width: 6,
//                         borderRadius: const BorderRadius.only(
//                           topLeft: Radius.circular(1),
//                           topRight: Radius.circular(1),
//                         ),
//                       )
//                     ],
//                   );
//                 }).toList(),
//               ),
//             ),
//     );
//   }
//
//   LineChartBarData _buildLine(List<FlSpot> spots, Color color) {
//     return LineChartBarData(
//       spots: spots,
//       isCurved: true,
//       color: color,
//       barWidth: 2,
//       dotData: const FlDotData(show: false),
//       belowBarData: BarAreaData(show: false),
//     );
//   }
//
//   Widget _buildGraphStats() {
//     final loc = _selectedLocationProps;
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceAround,
//       children: [
//         _buildLegendItem(
//             const Color(0xFFE53935),
//             'Max Wind Speed',
//             _maxWindSpeedFromSeries > 0
//                 ? '${_maxWindSpeedFromSeries.toStringAsFixed(0)} mph'
//                 : (_stormOverview['maxWindSpeed']?.toString() ?? 'N/A')),
//         _buildLegendItem(const Color(0xFF2196F3), 'Max Surge',
//             loc?['usofcl_fcst_surge_ft_LABEL']?.toString() ?? 'N/A'),
//         _buildLegendItem(const Color(0xFF4CAF50), 'Max Rainfall',
//             loc?['usofcl_fcst_rain_in_LABEL']?.toString() ?? 'N/A'),
//         _buildLegendItem(const Color(0xFF9C27B0), 'Max Wave Height',
//             loc?['usofcl_fcst_wave_ft_LABEL']?.toString() ?? 'N/A'),
//       ],
//     );
//   }
//
//   Widget _buildLegendItem(Color color, String label, String value) {
//     return Column(
//       children: [
//         Row(
//           children: [
//             Icon(Icons.circle, color: color, size: 8),
//             const SizedBox(width: 4),
//             Text(label,
//                 style: const TextStyle(color: Colors.white54, fontSize: 9)),
//           ],
//         ),
//         Text(value,
//             style: const TextStyle(
//                 color: Colors.white,
//                 fontSize: 11,
//                 fontWeight: FontWeight.bold)),
//       ],
//     );
//   }
//
//   // Local hazard values (surge/rain/wave/wind) come from ui_data.geojson
//   // for whichever location is currently selected (tap a marker on the map
//   // to change it — defaults to the first location).
//   Widget _buildHurricaneSummary() {
//     final loc = _selectedLocationProps;
//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: const Color(0xFF1E1E1E),
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: Row(
//         children: [
//           _buildSummaryItem('Max wind\nspeed',
//               _stormOverview['maxWindSpeed']?.toString() ?? 'N/A'),
//           _buildSummaryItem('Storm\nSurge',
//               loc?['usofcl_fcst_surge_ft_LABEL']?.toString() ?? 'N/A'),
//           _buildSummaryItem('Rainfall',
//               loc?['usofcl_fcst_rain_in_LABEL']?.toString() ?? 'N/A'),
//           _buildSummaryItem('Wave\nHeight',
//               loc?['usofcl_fcst_wave_ft_LABEL']?.toString() ?? 'N/A'),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildSummaryItem(String label, String value) {
//     return Expanded(
//       child: Column(
//         children: [
//           Text(label,
//               textAlign: TextAlign.center,
//               style: const TextStyle(color: Colors.white54, fontSize: 10)),
//           const SizedBox(height: 4),
//           Text(value,
//               textAlign: TextAlign.center,
//               style: const TextStyle(
//                   color: Colors.white,
//                   fontWeight: FontWeight.bold,
//                   fontSize: 12)),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildStormMovement() {
//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: const Color(0xFF1E1E1E),
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: Row(
//         children: [
//           _buildOverviewItem('Forward Speed',
//               _stormOverview['forwardSpeed']?.toString() ?? 'N/A'),
//           _buildOverviewItem('Forecast Track Point',
//               _stormOverview['trackPointCount']?.toString() ?? 'N/A'),
//         ],
//       ),
//     );
//   }
//
//   // ─── Location Exposure Tab (now driven by _locationExposures) ─────────
//   Widget _buildLocationExposureTab() {
//     return Column(
//       children: [
//         Padding(
//           padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               const Text(
//                 'Location Exposure (KAC Data)',
//                 style: TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.bold,
//                     fontSize: 14),
//               ),
//               IconButton(
//                 icon:
//                     const Icon(Icons.download_outlined, color: Colors.white70),
//                 onPressed: () {},
//               ),
//             ],
//           ),
//         ),
//         Expanded(
//           child: _locationExposures.isEmpty
//               ? const Center(
//                   child: Text(
//                     "No Location Exposure Data",
//                     style: TextStyle(
//                         color: Colors.white54,
//                         fontSize: 14,
//                         fontWeight: FontWeight.w600),
//                   ),
//                 )
//               : ListView.builder(
//                   padding:
//                       const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
//                   itemCount: _locationExposures.length,
//                   itemBuilder: (context, index) {
//                     return _buildLocationCard(_locationExposures[index]);
//                   },
//                 ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildLocationCard(Map<String, dynamic> data) {
//     final hazards = (data['hazards'] as Map<String, dynamic>?) ?? {};
//
//     return GestureDetector(
//       onTap: () {
//         final lat = data['lat'] as double?;
//         final lng = data['lng'] as double?;
//         if (lat != null && lng != null && _mapController != null) {
//           _mapController!.animateCamera(
//             CameraUpdate.newLatLngZoom(LatLng(lat, lng), 12.0),
//           );
//           if (data['rawProps'] != null) {
//             setState(() {
//               _selectedLocationProps = data['rawProps'] as Map<String, dynamic>;
//               isMapView = true;
//             });
//           }
//         }
//       },
//       child: Container(
//         margin: const EdgeInsets.only(bottom: 10),
//         padding: const EdgeInsets.all(12),
//         decoration: BoxDecoration(
//           color: const Color(0xFF1E1E1E),
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         data['city'],
//                         style: const TextStyle(
//                             color: Colors.white,
//                             fontWeight: FontWeight.bold,
//                             fontSize: 14),
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                       if ((data['county'] as String).isNotEmpty)
//                         Text(
//                           data['county'],
//                           style: const TextStyle(
//                               color: Colors.white54, fontSize: 11),
//                         ),
//                     ],
//                   ),
//                 ),
//                 Container(
//                   padding:
//                       const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//                   decoration: BoxDecoration(
//                     color: (data['catColor'] as Color).withOpacity(0.2),
//                     borderRadius: BorderRadius.circular(20),
//                     border: Border.all(
//                         color: (data['catColor'] as Color).withOpacity(0.6)),
//                   ),
//                   child: Text(
//                     data['category'],
//                     style: TextStyle(
//                         color: data['catColor'] as Color,
//                         fontSize: 11,
//                         fontWeight: FontWeight.bold),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 10),
//             const Text('TIV Exposed :',
//                 style: TextStyle(color: Colors.white54, fontSize: 11)),
//             Text(
//               data['tiv'],
//               style: const TextStyle(
//                   color: Colors.white,
//                   fontWeight: FontWeight.bold,
//                   fontSize: 13),
//             ),
//             const SizedBox(height: 8),
//             const Text('Local Hazards :',
//                 style: TextStyle(color: Colors.white54, fontSize: 11)),
//             const SizedBox(height: 4),
//             Wrap(
//               spacing: 6,
//               runSpacing: 6,
//               children: hazards.entries
//                   .where(
//                       (e) => e.value != null && e.value.toString().isNotEmpty)
//                   .map((e) => _buildHazardChip(e.key, e.value.toString()))
//                   .toList(),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildHazardChip(String label, String value) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(0.06),
//         borderRadius: BorderRadius.circular(6),
//         border: Border.all(color: Colors.white24),
//       ),
//       child: Text(
//         '$label: $value',
//         style: const TextStyle(color: Colors.white70, fontSize: 10),
//       ),
//     );
//   }
//
//   Widget _buildBottomNavigation() {
//     return Container(
//       padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
//       decoration: const BoxDecoration(
//         color: Color(0xFF1E1E1E),
//         border: Border(top: BorderSide(color: Colors.white12)),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           OutlinedButton.icon(
//             onPressed: _currentPage > 0
//                 ? () {
//                     setState(() => _currentPage--);
//                     _pageController.previousPage(
//                       duration: const Duration(milliseconds: 300),
//                       curve: Curves.easeInOut,
//                     );
//                   }
//                 : null,
//             icon: const Icon(Icons.arrow_back, size: 14),
//             label: const Text('Previous'),
//             style: OutlinedButton.styleFrom(
//               foregroundColor: Colors.white70,
//               side: const BorderSide(color: Colors.white24),
//               shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(8)),
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//             ),
//           ),
//           ElevatedButton.icon(
//             onPressed: () {
//               setState(() => _currentPage++);
//               _pageController.nextPage(
//                 duration: const Duration(milliseconds: 300),
//                 curve: Curves.easeInOut,
//               );
//             },
//             icon: const Icon(Icons.arrow_forward,
//                 size: 14, color: Colors.black87),
//             label: const Text('Next', style: TextStyle(color: Colors.black87)),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: AppColors.primaryMain,
//               shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(8)),
//               padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
