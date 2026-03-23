import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

class DeepLinkService {
  static final AppLinks _appLinks = AppLinks();
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // Initialize and listen to deep links
  static Future<void> init() async {
    // App opened FROM COLD START via deep link
    final initialLink = await _appLinks.getInitialLink();
    if (initialLink != null) {
      _handleLink(initialLink);
    }

    // App already OPEN and link clicked
    _appLinks.uriLinkStream.listen((uri) {
      _handleLink(uri);
    });
  }

  // Handle the incoming link
  static void _handleLink(Uri uri) {
    debugPrint('Deep link received: $uri');

    final path = uri.path;
    final queryParams = uri.queryParameters;

    // Example: /register?fromInvite=true&email=viku@yopmail.com
    if (path.contains('/register')) {
      final email = queryParams['email'] ?? '';
      final fromInvite = queryParams['fromInvite'] ?? 'false';

      navigatorKey.currentState?.pushNamed(
        '/register',
        arguments: {
          'email': email,
          'fromInvite': fromInvite,
        },
      );
    }

    // Example: /login
    else if (path.contains('/login')) {
      navigatorKey.currentState?.pushNamed('/login');
    }

    // Add more routes as needed
    else if (path.contains('/reset-password')) {
      final token = queryParams['token'] ?? '';
      navigatorKey.currentState?.pushNamed(
        '/reset-password',
        arguments: {'token': token},
      );
    }
  }
}