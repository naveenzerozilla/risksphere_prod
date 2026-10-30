import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:app_links/app_links.dart';
import 'package:flutter_sharing_intent/flutter_sharing_intent.dart';

import 'package:RiskSphere/main.dart'; // for navigatorKey
import 'package:RiskSphere/models/pending_data.dart';
import 'package:RiskSphere/screens/listings/add_location_screen.dart';
import 'package:RiskSphere/screens/onboarding/login_screen.dart';
import 'package:RiskSphere/service/shared_preference_service.dart';

class DeepLinkService {
  static late AppLinks _appLinks;

  static void initialize() {
    _handleDeepLink();
    _handleSharedGoogleMapsLink();
  }

  static void _handleSharedGoogleMapsLink() {
    FlutterSharingIntent.instance.getInitialSharing().then((value) {
      debugPrint(' getInitialSharing called, count: ${value.length}');
      if (value.isNotEmpty) {
        final text = value.first.value ?? '';
        debugPrint(' Shared text: $text');
        PendingSharedLocation.sharedText = text;
        PendingSharedLocation.wasLaunchedViaShare = true;
      } else {
        debugPrint(' No shared text received');
      }
    });

    FlutterSharingIntent.instance.getMediaStream().listen((value) {
      if (value.isNotEmpty) {
        final text = value.first.value ?? '';
        debugPrint(' Warm share: $text');
        extractLatLngAndNavigate(text);
      }
    });
  }

  static Future<void> resolveAndNavigate(String sharedText) async {
    double? lat;
    double? lng;

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
          String nextUrl = streamedResponse.headers['location']!;
          if (nextUrl.startsWith('/')) {
            final uri = Uri.parse(currentUrl);
            nextUrl = '${uri.scheme}://${uri.host}$nextUrl';
          }
          currentUrl = nextUrl;
          debugPrint(' Redirected to: $currentUrl');
        } else {
          resolvedUrl = currentUrl;
          break;
        }
      }
    } catch (e) {
      debugPrint(' Resolution error: $e');
    }

    debugPrint(' Final URL: $resolvedUrl');

    final uri = Uri.tryParse(resolvedUrl);
    if (uri != null) {
      final q = uri.queryParameters['q'];
      if (q != null && q.contains(',')) {
        final parts = q.split(',');
        lat = double.tryParse(parts[0].trim());
        lng = double.tryParse(parts[1].trim());
      }

      if (lat == null) {
        final match =
            RegExp(r'/@(-?\d+\.\d+),(-?\d+\.\d+)').firstMatch(resolvedUrl);
        if (match != null) {
          lat = double.tryParse(match.group(1) ?? '');
          lng = double.tryParse(match.group(2) ?? '');
        }
      }
    }

    debugPrint(' Extracted lat: $lat, lng: $lng');
    _goToAddLocation(lat, lng);
  }

  static void _goToAddLocation(double? lat, double? lng) async {
    final user = FirebaseAuth.instance.currentUser;
    final context = navigatorKey.currentContext;
    if (context == null) return;
    final accountId = await SharedPreferenceService.getDefaultAccountID() ?? '';

    final subAccountId =
        await SharedPreferenceService.getDefaultSubAccountID() ?? '';
    final accountName =
        await SharedPreferenceService.GetDefaultAccountName() ?? '';
    final subAccountName =
        await SharedPreferenceService.GetDefaultSUBAccountName() ?? '';

    if (user != null) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => AddLocationScreen(
            accountId: accountId,
            subAccountId: subAccountId,
            sovId: '',
            locationId: '',
            accountName:
                (accountName.isNotEmpty) ? accountName : 'Default Account',
            subAccountName: (subAccountName.isNotEmpty)
                ? subAccountName
                : 'Default Subaccount',
          ),
        ),
        (route) => false,
      );
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  static void extractLatLngAndNavigate(String sharedText) async {
    double? lat;
    double? lng;

    String resolvedUrl = sharedText.trim();
    debugPrint('Original shared URL: $resolvedUrl');

    if (resolvedUrl.contains('goo.gl') || resolvedUrl.contains('maps.app')) {
      try {
        final response = await http.get(
          Uri.parse(resolvedUrl),
          headers: {'User-Agent': 'Mozilla/5.0'},
        );
        resolvedUrl = response.request?.url.toString() ?? resolvedUrl;
        debugPrint('Resolved URL: $resolvedUrl');
      } catch (e) {
        debugPrint('Failed to resolve URL: $e');
      }
    }

    final uri = Uri.tryParse(resolvedUrl);
    if (uri != null) {
      final q = uri.queryParameters['q'];
      if (q != null && q.contains(',')) {
        final parts = q.split(',');
        lat = double.tryParse(parts[0].trim());
        lng = double.tryParse(parts[1].trim());
      }

      if (lat == null) {
        final match =
            RegExp(r'/@(-?\d+\.\d+),(-?\d+\.\d+)').firstMatch(resolvedUrl);
        if (match != null) {
          lat = double.tryParse(match.group(1) ?? '');
          lng = double.tryParse(match.group(2) ?? '');
        }
      }
    }

    debugPrint('Extracted → lat: $lat, lng: $lng');

    if (lat == null || lng == null) {
      debugPrint('Could not extract lat/lng from shared URL');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    final context = navigatorKey.currentContext;
    if (context == null) return;
    final accountId = await SharedPreferenceService.getDefaultAccountID() ?? '';

    final subAccountId =
        await SharedPreferenceService.getDefaultSubAccountID() ?? '';
    final accountName =
        await SharedPreferenceService.GetDefaultAccountName() ?? '';
    final subAccountName =
        await SharedPreferenceService.GetDefaultSUBAccountName() ?? '';

    if (user != null) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => AddLocationScreen(
            accountId: accountId,
            subAccountId: subAccountId,
            sovId: '',
            locationId: '',
            accountName:
                (accountName.isNotEmpty) ? accountName : 'Default Account',
            subAccountName: (subAccountName.isNotEmpty)
                ? subAccountName
                : 'Default Subaccount',
          ),
        ),
        (route) => false,
      );
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  static void _handleDeepLink() async {
    _appLinks = AppLinks();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final uri = await _appLinks.getInitialLink();
      if (uri != null && uri.host == 'app.risksphere.ai') {
        _routeFromDeepLink(uri);
      }
    });

    _appLinks.uriLinkStream.listen((uri) {
      if (uri.host == 'app.risksphere.ai') {
        _routeFromDeepLink(uri);
      }
    });
  }

  static void _routeFromDeepLink(Uri uri) async {
    final user = FirebaseAuth.instance.currentUser;
    final context = navigatorKey.currentContext;
    if (context == null) return;

    if (user != null) {
      PendingDeepLink.isDeepLinkPending = true;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => AddLocationScreen(
            accountId: '',
            subAccountId: '',
            sovId: '',
          ),
        ),
        (route) => false,
      );
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }
}
