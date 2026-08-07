import 'package:firebase_app_check/firebase_app_check.dart';

import 'global_imports.dart';

class AppCheckService {
  static String? _cachedToken;
  static DateTime? _tokenExpiry;
  static Completer<String?>? _completer;

  static DateTime? _lastFailureTime;
  static int _failureCount = 0;

  static Future<String?> getToken() async {
    // AppCheck completely disabled to prevent network delays and rate-limiting blocks
    return null;
  }

  static Duration _getBackoffDuration() {
    const seconds = [10, 30, 60, 120, 300];
    final index = (_failureCount - 1).clamp(0, seconds.length - 1);
    return Duration(seconds: seconds[index]);
  }

  static void clearCache() {
    _cachedToken = null;
    _tokenExpiry = null;
    _completer = null;
    _failureCount = 0;
    _lastFailureTime = null;
    debugPrint(' AppCheck cache cleared');
  }
}

