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
import '../../utils/app_update.dart';
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

    // ✅ Single pipeline: update check FIRST, then navigate
    // _initialScreenFuture = _checkUpdateThenNavigate();
    _initialScreenFuture = _determineInitialScreen();
  }

  /// Step 1: Check for update → show dialog if needed → then determine screen
  // Future<Widget> _checkUpdateThenNavigate() async {
  //   try {
  //     final updateStatus = await UpdateService.checkForUpdate();
  //
  //     debugPrint('── Splash Update Check ──');
  //     debugPrint('hasUpdate : ${updateStatus.hasUpdate}');
  //     debugPrint('isForce   : ${updateStatus.isForce}');
  //     debugPrint('version   : ${updateStatus.latestVersion}');
  //
  //     if (updateStatus.hasUpdate && mounted) {
  //       // ✅ Wait for dialog/bottom sheet to be dismissed before continuing
  //       await UpdateService.showUpdateDialog(context, updateStatus);
  //
  //       // Track update status in prefs (optional)
  //       await SharedPreferenceService.setBool(
  //         "pending_soft_update",
  //         updateStatus.isForce != true,
  //       );
  //       await SharedPreferenceService.setString(
  //         "pending_update_version",
  //         updateStatus.latestVersion ?? "",
  //       );
  //
  //       // ✅ If force update: keep showing splash (user must update)
  //       // The bottom sheet is non-dismissible so app stays blocked
  //       if (updateStatus.isForce == true) {
  //         // Return a blocker screen — user cannot proceed
  //         return _buildBlockerScreen();
  //       }
  //     }
  //   } catch (e) {
  //     debugPrint('Update check error: $e');
  //   }
  //
  //   // ✅ Step 2: Proceed to determine actual screen
  //   return _determineInitialScreen();
  // }

  /// Blocker screen shown after force update dialog is dismissed
  /// (user tapped "Update Now" and came back without updating)
  // Widget _buildBlockerScreen() {
  //   return Scaffold(
  //     body: Center(
  //       child: Padding(
  //         padding: const EdgeInsets.all(32.0),
  //         child: Column(
  //           mainAxisAlignment: MainAxisAlignment.center,
  //           children: [
  //             SvgPicture.asset(
  //               'assets/images/logo.svg',
  //               width: 120,
  //               height: 120,
  //             ),
  //             const SizedBox(height: 32),
  //             const Text(
  //               'Update Required',
  //               style: TextStyle(
  //                 fontSize: 22,
  //                 fontWeight: FontWeight.bold,
  //               ),
  //             ),
  //             const SizedBox(height: 12),
  //             const Text(
  //               'Please update the app to continue.',
  //               textAlign: TextAlign.center,
  //               style: TextStyle(fontSize: 15, color: Colors.grey),
  //             ),
  //             const SizedBox(height: 32),
  //             ElevatedButton(
  //               style: ElevatedButton.styleFrom(
  //                 padding: const EdgeInsets.symmetric(
  //                   horizontal: 40,
  //                   vertical: 14,
  //                 ),
  //                 shape: RoundedRectangleBorder(
  //                   borderRadius: BorderRadius.circular(10),
  //                 ),
  //               ),
  //               onPressed: () async {
  //                 await UpdateService.performForceUpdate();
  //               },
  //               child: const Text(
  //                 'Update Now',
  //                 style: TextStyle(fontSize: 16),
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

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

    if (user == null) {
      return const LoginScreen();
    }

    try {
      final tokenResult = await user.getIdTokenResult(true);
      final claims = tokenResult.claims ?? {};
      await SharedPreferenceService.setClaims(claims);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<UserProfileProvider>().getAllUserData(context, '', '');
      });

      await Future.delayed(const Duration(milliseconds: 2000));

      debugPrint(
          'wasLaunchedViaShare: ${PendingSharedLocation.wasLaunchedViaShare}');
      debugPrint('sharedText: ${PendingSharedLocation.sharedText}');

      if (PendingSharedLocation.wasLaunchedViaShare) {
        final text = PendingSharedLocation.sharedText ?? '';
        PendingSharedLocation.sharedText = null;
        PendingSharedLocation.wasLaunchedViaShare = false;

        debugPrint(' Navigating with text: $text');

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
      debugPrint('Session restore error: $e');
      return const LoginScreen();
    }
  }

  Future<void> _resolveAndNavigate(String sharedText) async {
    double? lat;
    double? lng;
    String? placeName;

    debugPrint(' sharedText: $sharedText');

    final urlRegex = RegExp(r'https?://\S+');
    final urlMatch = urlRegex.firstMatch(sharedText);
    if (urlMatch == null) {
      debugPrint('No URL found');
      _goToAddLocation(lat, lng);
      return;
    }

    String resolvedUrl = urlMatch.group(0)!.trim();
    debugPrint(' Extracted URL: $resolvedUrl');

    try {
      String currentUrl = resolvedUrl;

      for (int i = 0; i < 10; i++) {
        debugPrint(' Fetching: $currentUrl');

        final request = http.Request('GET', Uri.parse(currentUrl))
          ..followRedirects = false
          ..headers['User-Agent'] =
              'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 '
                  'Chrome/91.0.4472.120 Mobile Safari/537.36';

        final streamedResponse = await request.send();
        final statusCode = streamedResponse.statusCode;

        if ((statusCode == 301 ||
                statusCode == 302 ||
                statusCode == 303 ||
                statusCode == 307 ||
                statusCode == 308) &&
            streamedResponse.headers['location'] != null) {
          final nextUrl = streamedResponse.headers['location']!;
          currentUrl = nextUrl.startsWith('http')
              ? nextUrl
              : Uri.parse(currentUrl).resolve(nextUrl).toString();
          debugPrint('🔥 HTTP Redirect → $currentUrl');
          continue;
        }

        final body = await streamedResponse.stream.bytesToString();

        final metaRefreshMatch = RegExp(
          '<meta[^>]+http-equiv=["\']refresh["\'][^>]+'
          'content=["\'][^;]+;\\s*url=([^"\'> ]+)',
          caseSensitive: false,
        ).firstMatch(body);

        if (metaRefreshMatch != null) {
          String metaUrl = metaRefreshMatch.group(1)!.trim();
          if (!metaUrl.startsWith('http')) {
            metaUrl = Uri.parse(currentUrl).resolve(metaUrl).toString();
          }
          currentUrl = metaUrl;
          debugPrint(' Meta-refresh → $currentUrl');
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
            debugPrint(' Canonical URL → $currentUrl');
          }
        }

        final fullMapsUrlMatch =
            RegExp(r'https://www\.google\.com/maps[^"<\s]+').firstMatch(body);

        if (fullMapsUrlMatch != null) {
          currentUrl = fullMapsUrlMatch.group(0)!;
          debugPrint(' Found full maps URL in body → $currentUrl');
        }

        resolvedUrl = currentUrl;
        debugPrint(' Final resolved URL: $resolvedUrl');
        break;
      }
    } catch (e) {
      debugPrint(' Resolve failed: $e');
    }

    final placeMatch = RegExp(r'/maps/place/([^/@]+)').firstMatch(resolvedUrl);
    if (placeMatch != null) {
      placeName = Uri.decodeComponent(
        placeMatch.group(1)!.replaceAll('+', ' '),
      );
      debugPrint(' Place name: $placeName');
    }

    final coordMatch =
        RegExp(r'/@(-?\d+\.\d+),(-?\d+\.\d+)').firstMatch(resolvedUrl);
    if (coordMatch != null) {
      lat = double.tryParse(coordMatch.group(1) ?? '');
      lng = double.tryParse(coordMatch.group(2) ?? '');
      debugPrint(' Format1 lat:$lat lng:$lng');
    }

    if (lat == null) {
      final uri = Uri.tryParse(resolvedUrl);
      final q = uri?.queryParameters['q'];
      if (q != null && q.contains(',')) {
        final parts = q.split(',');
        lat = double.tryParse(parts[0].trim());
        lng = double.tryParse(parts[1].trim());
        debugPrint(' Format2 lat:$lat lng:$lng');
      }
    }

    if (lat == null) {
      final match =
          RegExp(r'!3d(-?\d+\.\d+)!4d(-?\d+\.\d+)').firstMatch(resolvedUrl);
      if (match != null) {
        lat = double.tryParse(match.group(1) ?? '');
        lng = double.tryParse(match.group(2) ?? '');
        debugPrint(' Format3 lat:$lat lng:$lng');
      }
    }

    if (lat == null) {
      final uri = Uri.tryParse(resolvedUrl);
      final ll = uri?.queryParameters['ll'];
      if (ll != null && ll.contains(',')) {
        final parts = ll.split(',');
        lat = double.tryParse(parts[0].trim());
        lng = double.tryParse(parts[1].trim());
        debugPrint(' Format4 lat:$lat lng:$lng');
      }
    }

    if ((lat == null || lng == null) && placeName != null) {
      try {
        debugPrint(' Geocoding: $placeName');
        final locations = await locationFromAddress(placeName);
        if (locations.isNotEmpty) {
          lat = locations.first.latitude;
          lng = locations.first.longitude;
          debugPrint(' Geocoded lat:$lat lng:$lng');
        }
      } catch (e) {
        debugPrint('Geocoding failed: $e');
      }
    }

    debugPrint(' Final → lat:$lat lng:$lng place:$placeName');
    _goToAddLocation(lat, lng, placeName: placeName);
  }

  void _goToAddLocation(double? lat, double? lng, {String? placeName}) async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;

    final accountId = await SharedPreferenceService.getDefaultAccountID() ?? '';

    final subAccountId =
        await SharedPreferenceService.getDefaultSubAccountID() ?? '';
    final accountName =
        await SharedPreferenceService.GetDefaultAccountName() ?? '';
    final subAccountName =
        await SharedPreferenceService.GetDefaultSUBAccountName() ?? '';

    Navigator.pushAndRemoveUntil(
      ctx,
      MaterialPageRoute(
        builder: (_) => AddLocationScreen(
          accountId: accountId ?? '',
          subAccountId: subAccountId ?? '',
          accountName: accountName ?? '',
          subAccountName: subAccountName ?? '',
          sovId: '',
          locationName: placeName,
          initialLat: lat,
          initialLng: lng,
        ),
      ),
      (route) => false,
    );
  }

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
