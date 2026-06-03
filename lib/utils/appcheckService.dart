import 'package:firebase_app_check/firebase_app_check.dart';

import 'global_imports.dart';

class AppCheckService {
  static String? _cachedToken;
  static DateTime? _tokenExpiry;
  static Completer<String?>? _completer;

  static DateTime? _lastFailureTime;
  static int _failureCount = 0;

  static Future<String?> getToken() async {
    if (_cachedToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!)) {
      return _cachedToken;
    }

    if (_lastFailureTime != null) {
      final backoff = _getBackoffDuration();
      final nextRetry = _lastFailureTime!.add(backoff);
      if (DateTime.now().isBefore(nextRetry)) {
        final waitSecs = nextRetry.difference(DateTime.now()).inSeconds;
        debugPrint(' AppCheck: rate limited, retry in ${waitSecs}s');
        return _cachedToken;
      }
    }
    if (_completer != null) {
      debugPrint(' AppCheck: waiting for in-progress fetch');
      return _completer!.future;
    }

    _completer = Completer<String?>();

    try {
      final token = await FirebaseAppCheck.instance.getToken(false);

      if (token != null) {
        _cachedToken = token;
        _tokenExpiry = DateTime.now().add(const Duration(minutes: 50));
        _failureCount = 0;
        _lastFailureTime = null;
        debugPrint(' AppCheck token fetched and cached');
      }

      _completer!.complete(token);
      return token;
    } catch (e) {
      _failureCount++;
      _lastFailureTime = DateTime.now();
      debugPrint(' AppCheck error (failure #$_failureCount): $e');
      _completer!.complete(_cachedToken); // complete with stale/null
      return _cachedToken;
    } finally {
      _completer = null;
    }
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

