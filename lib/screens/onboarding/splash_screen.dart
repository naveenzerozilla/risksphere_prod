import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';
import 'package:RiskSphere/providers/theme_provider.dart';
import 'package:RiskSphere/providers/user_profile_provider.dart';
import 'package:RiskSphere/screens/home/dashboard_screen.dart';
import 'package:RiskSphere/screens/onboarding/login_screen.dart';
import 'package:RiskSphere/service/shared_preference_service.dart';
import 'package:http/http.dart' as http;
import '../../main.dart';
import '../../models/pending_location.dart';
import '../listings/add_location_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late ThemeProvider themeProvider;
  late Future<Widget> _initialScreenFuture;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
    _controller.forward();

    themeProvider = context.read<ThemeProvider>();
    _initialScreenFuture = _determineInitialScreen();
  }

  /// 🔐 SINGLE SOURCE OF TRUTH FOR INITIAL ROUTING
  Future<Widget> _determineInitialScreen() async {
    final auth = FirebaseAuth.instance;

    /// 1️⃣ First-run logic (ONLY ONCE)
    final bool? firstRun = await SharedPreferenceService.getBool("first_run");

    if (firstRun != false) {
      await SharedPreferenceService.setBool("first_run", false);
      await auth.signOut();
      return const LoginScreen();
    }

    /// 2️⃣ Wait until Firebase finishes restoring auth state
    User? user;
    try {
      user = await auth
          .authStateChanges()
          .timeout(const Duration(seconds: 5))
          .first;
    } catch (_) {
      user = null;
    }

    /// 3️⃣ No session → Login
    if (user == null) {
      // ✅ Not logged in but has shared text → LoginScreen
      // (PendingSharedLocation stays saved, can be used after login if needed)
      return const LoginScreen();
    }

    /// 4️⃣ Session exists → restore claims + profile
    try {
      final tokenResult = await user.getIdTokenResult(true);
      final claims = tokenResult.claims ?? {};
      await SharedPreferenceService.setClaims(claims);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<UserProfileProvider>().getAllUserData(context, '', '');
      });

      // ✅ Wait for getInitialSharing to complete
      await Future.delayed(const Duration(milliseconds: 2000));

      debugPrint(
          '🔥 After delay - wasLaunchedViaShare: ${PendingSharedLocation.wasLaunchedViaShare}');
      debugPrint(
          '🔥 After delay - sharedText: ${PendingSharedLocation.sharedText}');

      // ✅ CHECK GOOGLE MAPS SHARE
      if (PendingSharedLocation.wasLaunchedViaShare) {
        final text = PendingSharedLocation.sharedText ?? '';
        PendingSharedLocation.sharedText = null;
        PendingSharedLocation.wasLaunchedViaShare = false;

        debugPrint('🔥 Navigating with text: $text');

        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await _resolveAndNavigate(text);
        });

        return DashboardScreen();
      }

      if (PendingLocation.hasLocation) {
        return DashboardScreen(
          openAddLocation: true,
          latitude: PendingLocation.latitude,
          longitude: PendingLocation.longitude,
        );
      }

      return DashboardScreen();
    } catch (e) {
      return const LoginScreen();
    }

  }

  Future<void> _resolveAndNavigate(String sharedText) async {
    double? lat;
    double? lng;
    String? placeName;

    debugPrint('🔥 sharedText: $sharedText');

    final urlRegex = RegExp(r'https?://\S+');
    final urlMatch = urlRegex.firstMatch(sharedText);
    if (urlMatch == null) {
      debugPrint('No URL found');
      _goToAddLocation(lat, lng);
      return;
    }

    String resolvedUrl = urlMatch.group(0)!.trim();
    debugPrint('🔥 Extracted URL: $resolvedUrl');

    try {
      String currentUrl = resolvedUrl;

      for (int i = 0; i < 10; i++) {
        debugPrint('🔥 Fetching: $currentUrl');

        final request = http.Request('GET', Uri.parse(currentUrl))
          ..followRedirects = false
          ..headers['User-Agent'] =
              'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 Chrome/91.0.4472.120 Mobile Safari/537.36';

        final streamedResponse = await request.send();
        final statusCode = streamedResponse.statusCode;
        debugPrint('🔥 Status: $statusCode');
        debugPrint(
            '🔥 Location header: ${streamedResponse.headers['location']}');

        if ((statusCode == 301 ||
                statusCode == 302 ||
                statusCode == 303 ||
                statusCode == 307 ||
                statusCode == 308) &&
            streamedResponse.headers['location'] != null) {
          final nextUrl = streamedResponse.headers['location']!;
          if (nextUrl.startsWith('http')) {
            currentUrl = nextUrl;
          } else {
            final base = Uri.parse(currentUrl);
            currentUrl = base.resolve(nextUrl).toString();
          }
          debugPrint('🔥 HTTP Redirect → $currentUrl');
          continue;
        }

        final body = await streamedResponse.stream.bytesToString();

        // ✅ FIX 1: closed the RegExp() call, FIX 2: removed erroneous `!` before `refresh`
        final metaRefreshMatch = RegExp(
          '<meta[^>]+http-equiv=["\']refresh["\'][^>]+content=["\'][^;]+;\\s*url=([^"\'> ]+)',
          caseSensitive: false,
        ).firstMatch(body);

        if (metaRefreshMatch != null) {
          String metaUrl = metaRefreshMatch.group(1)!.trim();
          if (!metaUrl.startsWith('http')) {
            final base = Uri.parse(currentUrl);
            metaUrl = base.resolve(metaUrl).toString();
          }
          currentUrl = metaUrl;
          debugPrint('🔥 Meta-refresh → $currentUrl');
          continue;
        }

        final canonicalMatch = RegExp(
          '<link[^>]+rel=["\']canonical["\'][^>]+href=["\']([^"\']+)["\']',
          caseSensitive: false,
        ).firstMatch(body);

        if (canonicalMatch != null) {
          final canonical = canonicalMatch.group(1)!;
          if (canonical.contains('maps.google') ||
              canonical.contains('/maps/')) {
            currentUrl = canonical;
            debugPrint('🔥 Canonical URL → $currentUrl');
          }
        }

        final fullMapsUrlMatch =
            RegExp(r'https://www\.google\.com/maps[^"<\s]+').firstMatch(body);

        if (fullMapsUrlMatch != null) {
          currentUrl = fullMapsUrlMatch.group(0)!;
          debugPrint('🔥 Found full maps URL in body → $currentUrl');
        }

        resolvedUrl = currentUrl;
        debugPrint('🔥 Final resolved URL: $resolvedUrl');
        break;
      }
    } catch (e) {
      debugPrint('🔥 Resolve failed: $e');
    }

    debugPrint('🔥 Parsing from: $resolvedUrl');

    final placeMatch = RegExp(r'/maps/place/([^/@]+)').firstMatch(resolvedUrl);
    if (placeMatch != null) {
      placeName = Uri.decodeComponent(
        placeMatch.group(1)!.replaceAll('+', ' '),
      );
      debugPrint('🔥 Place name: $placeName');
    }

    final coordMatch =
        RegExp(r'/@(-?\d+\.\d+),(-?\d+\.\d+)').firstMatch(resolvedUrl);
    if (coordMatch != null) {
      lat = double.tryParse(coordMatch.group(1) ?? '');
      lng = double.tryParse(coordMatch.group(2) ?? '');
      debugPrint('🔥 Format1 lat:$lat lng:$lng');
    }

    if (lat == null) {
      final uri = Uri.tryParse(resolvedUrl);
      final q = uri?.queryParameters['q'];
      if (q != null && q.contains(',')) {
        final parts = q.split(',');
        lat = double.tryParse(parts[0].trim());
        lng = double.tryParse(parts[1].trim());
        debugPrint('🔥 Format2 lat:$lat lng:$lng');
      }
    }

    if (lat == null) {
      final match =
          RegExp(r'!3d(-?\d+\.\d+)!4d(-?\d+\.\d+)').firstMatch(resolvedUrl);
      if (match != null) {
        lat = double.tryParse(match.group(1) ?? '');
        lng = double.tryParse(match.group(2) ?? '');
        debugPrint('🔥 Format3 lat:$lat lng:$lng');
      }
    }

    if (lat == null) {
      final uri = Uri.tryParse(resolvedUrl);
      final ll = uri?.queryParameters['ll'];
      if (ll != null && ll.contains(',')) {
        final parts = ll.split(',');
        lat = double.tryParse(parts[0].trim());
        lng = double.tryParse(parts[1].trim());
        debugPrint('🔥 Format4 lat:$lat lng:$lng');
      }
    }

    if ((lat == null || lng == null) && placeName != null) {
      try {
        debugPrint('🔥 Geocoding: $placeName');
        final locations = await locationFromAddress(placeName);
        if (locations.isNotEmpty) {
          lat = locations.first.latitude;
          lng = locations.first.longitude;
          debugPrint('🔥 Geocoded lat:$lat lng:$lng');
        }
      } catch (e) {
        debugPrint('🔥 Geocoding failed: $e');
      }
    }

    debugPrint('🔥 Final → lat:$lat lng:$lng place:$placeName');
    _goToAddLocation(lat, lng, placeName: placeName);
  }

  // Future<void> _resolveAndNavigate(String sharedText) async {
  //   double? lat;
  //   double? lng;
  //   String? placeName;
  //
  //   debugPrint('🔥 sharedText: $sharedText');
  //
  //   final urlRegex = RegExp(r'https?://\S+');
  //   final urlMatch = urlRegex.firstMatch(sharedText);
  //   if (urlMatch == null) {
  //     debugPrint('No URL found');
  //     _goToAddLocation(lat, lng);
  //     return;
  //   }
  //
  //   String resolvedUrl = urlMatch.group(0)!.trim();
  //   debugPrint('🔥 Extracted URL: $resolvedUrl');
  //
  //   // ✅ Fix: Follow redirects manually with noRedirect client
  //   try {
  //     String currentUrl = resolvedUrl;
  //
  //     for (int i = 0; i < 10; i++) {
  //       debugPrint('🔥 Fetching: $currentUrl');
  //
  //       final request = http.Request('GET', Uri.parse(currentUrl))
  //         ..followRedirects = false
  //         ..headers['User-Agent'] =
  //             'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 Chrome/91.0.4472.120 Mobile Safari/537.36';
  //
  //       final streamedResponse = await request.send();
  //       debugPrint('🔥 Status: ${streamedResponse.statusCode}');
  //       debugPrint(
  //           '🔥 Location header: ${streamedResponse.headers['location']}');
  //
  //       if ((streamedResponse.statusCode == 301 ||
  //               streamedResponse.statusCode == 302 ||
  //               streamedResponse.statusCode == 303 ||
  //               streamedResponse.statusCode == 307 ||
  //               streamedResponse.statusCode == 308) &&
  //           streamedResponse.headers['location'] != null) {
  //         final nextUrl = streamedResponse.headers['location']!;
  //
  //         // ✅ Handle relative URLs
  //         if (nextUrl.startsWith('http')) {
  //           currentUrl = nextUrl;
  //         } else {
  //           final base = Uri.parse(currentUrl);
  //           currentUrl = base.resolve(nextUrl).toString();
  //         }
  //
  //         debugPrint('🔥 Redirecting → $currentUrl');
  //         continue;
  //       }
  //
  //       // Final URL reached
  //       resolvedUrl = currentUrl;
  //       debugPrint('🔥 Final resolved URL: $resolvedUrl');
  //       break;
  //     }
  //   } catch (e) {
  //     debugPrint('🔥 Resolve failed: $e');
  //   }
  //
  //   debugPrint('🔥 Parsing from: $resolvedUrl');
  //
  //   // Step 3: Extract place name from URL path
  //   final placeMatch = RegExp(r'/maps/place/([^/]+)').firstMatch(resolvedUrl);
  //   if (placeMatch != null) {
  //     placeName = Uri.decodeComponent(
  //       placeMatch.group(1)!.replaceAll('+', ' '),
  //     );
  //     debugPrint('🔥 Place name: $placeName');
  //   }
  //
  //   // Format 1: /@lat,lng
  //   final coordMatch =
  //       RegExp(r'/@(-?\d+\.\d+),(-?\d+\.\d+)').firstMatch(resolvedUrl);
  //   if (coordMatch != null) {
  //     lat = double.tryParse(coordMatch.group(1) ?? '');
  //     lng = double.tryParse(coordMatch.group(2) ?? '');
  //     debugPrint('🔥 Format1 lat:$lat lng:$lng');
  //   }
  //
  //   // Format 2: ?q=lat,lng
  //   if (lat == null) {
  //     final uri = Uri.tryParse(resolvedUrl);
  //     final q = uri?.queryParameters['q'];
  //     if (q != null && q.contains(',')) {
  //       final parts = q.split(',');
  //       lat = double.tryParse(parts[0].trim());
  //       lng = double.tryParse(parts[1].trim());
  //       debugPrint('🔥 Format2 lat:$lat lng:$lng');
  //     }
  //   }
  //
  //   // Format 3: !3d lat !4d lng
  //   if (lat == null) {
  //     final match =
  //         RegExp(r'!3d(-?\d+\.\d+)!4d(-?\d+\.\d+)').firstMatch(resolvedUrl);
  //     if (match != null) {
  //       lat = double.tryParse(match.group(1) ?? '');
  //       lng = double.tryParse(match.group(2) ?? '');
  //       debugPrint('🔥 Format3 lat:$lat lng:$lng');
  //     }
  //   }
  //
  //   // Step 5: Geocode place name if lat/lng still null
  //   if ((lat == null || lng == null) && placeName != null) {
  //     try {
  //       debugPrint('🔥 Geocoding: $placeName');
  //       final locations = await locationFromAddress(placeName);
  //       if (locations.isNotEmpty) {
  //         lat = locations.first.latitude;
  //         lng = locations.first.longitude;
  //         debugPrint('🔥 Geocoded lat:$lat lng:$lng');
  //       }
  //     } catch (e) {
  //       debugPrint('🔥 Geocoding failed: $e');
  //     }
  //   }
  //
  //   debugPrint('🔥 Final → lat:$lat lng:$lng place:$placeName');
  //   _goToAddLocation(lat, lng, placeName: placeName);
  // }

  void _goToAddLocation(double? lat, double? lng, {String? placeName}) async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;

    Navigator.pushAndRemoveUntil(
      ctx,
      MaterialPageRoute(
        builder: (_) => AddLocationScreen(
          accountId: '',
          subAccountId: '',
          sovId: '',
          locationName: placeName,
          initialLat: lat,
          initialLng: lng,
        ),
      ),
      (route) => false,
    );
  }

  // void _goToAddLocation(double? lat, double? lng, {String? placeName}) async {
  //   await Future.delayed(const Duration(milliseconds: 800));
  //   if (!mounted) return;
  //   final ctx = navigatorKey.currentContext;
  //   if (ctx == null) return;
  //
  //   print(lat);
  //   print(lng);
  //   print(placeName);
  //   Navigator.pushAndRemoveUntil(
  //     ctx,
  //     MaterialPageRoute(
  //       builder: (_) => AddLocationScreen(
  //         accountId: '',
  //         subAccountId: '',
  //         sovId: '',
  //         locationName: placeName,
  //       ),
  //     ),
  //     (route) => false,
  //   );
  // }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _initialScreenFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: themeProvider.getTheme.scaffoldBackgroundColor,
            body: Center(
              child: FadeTransition(
                opacity: _animation,
                child: SizedBox(
                  width: 200,
                  height: 200,
                  child: SvgPicture.asset(
                    'assets/images/logo.svg',
                    semanticsLabel: 'Logo',
                  ),
                ),
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.hasError) {
          return const LoginScreen();
        }

        return snapshot.data!;
      },
    );
  }
}
