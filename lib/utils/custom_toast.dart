import 'package:flutter/material.dart';

class CustomToast {
  static void showToast(String title, String message, GlobalKey<NavigatorState> navigatorKey) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(top: 20, left: 16, right: 16),
          content: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(message),
              ],
            ),
          ),
          duration: const Duration(seconds: 10),
        ),
      );
    }
  }
}
