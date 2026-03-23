import 'package:firebase_app_check/firebase_app_check.dart';

import 'global_imports.dart';

class AppCheckService {
  static String? _cachedToken;
  static DateTime? _tokenExpiry;
  static Completer<String?>? _completer; // ✅ use Completer instead of Future

  static DateTime? _lastFailureTime;
  static int _failureCount = 0;

  static Future<String?> getToken() async {
    // Return cached token if still valid
    if (_cachedToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!)) {
      return _cachedToken;
    }

    // Back off if failing repeatedly
    if (_lastFailureTime != null) {
      final backoff = _getBackoffDuration();
      final nextRetry = _lastFailureTime!.add(backoff);
      if (DateTime.now().isBefore(nextRetry)) {
        final waitSecs = nextRetry.difference(DateTime.now()).inSeconds;
        debugPrint('⏸️ AppCheck: rate limited, retry in ${waitSecs}s');
        return _cachedToken;
      }
    }

    // ✅ If fetch already in progress, wait for same Completer
    if (_completer != null) {
      debugPrint('⏳ AppCheck: waiting for in-progress fetch');
      return _completer!.future;
    }

    // ✅ Start new fetch with Completer
    _completer = Completer<String?>();

    try {
      debugPrint(
          '🔄 Fetching new AppCheck token (failure count: $_failureCount)');
      final token = await FirebaseAppCheck.instance.getToken(false);

      if (token != null) {
        _cachedToken = token;
        _tokenExpiry = DateTime.now().add(const Duration(minutes: 50));
        _failureCount = 0;
        _lastFailureTime = null;
        debugPrint('✅ AppCheck token fetched and cached');
      }

      _completer!.complete(token);
      return token;
    } catch (e) {
      _failureCount++;
      _lastFailureTime = DateTime.now();
      debugPrint('❌ AppCheck error (failure #$_failureCount): $e');
      _completer!.complete(_cachedToken); // complete with stale/null
      return _cachedToken;
    } finally {
      _completer = null; // ✅ always clear
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
    debugPrint('🗑️ AppCheck cache cleared');
  }
}

// // appcheckService.dart
// import 'package:firebase_app_check/firebase_app_check.dart';
// import 'package:flutter/foundation.dart';
//
// class AppCheckService {
//   static String? _cachedToken;
//   static DateTime? _tokenExpiry;
//   static Future<String?>? _ongoingFetch; // 👈 lock for concurrent calls
//
//   static Future<String?> getToken() async {
//     // Return cached token if still valid
//     if (_cachedToken != null &&
//         _tokenExpiry != null &&
//         DateTime.now().isBefore(_tokenExpiry!)) {
//       return _cachedToken;
//     }
//
//     // If a fetch is already in progress, wait for it instead of starting a new one
//     if (_ongoingFetch != null) {
//       debugPrint('⏳ AppCheck: waiting for in-progress fetch');
//       return _ongoingFetch;
//     }
//
//     // Start a new fetch and store the Future so concurrent callers can await it
//     _ongoingFetch = _fetchToken();
//     try {
//       final token = await _ongoingFetch;
//       return token;
//     } finally {
//       _ongoingFetch = null; // 👈 always clear the lock
//     }
//   }
//
//   static Future<String?> _fetchToken() async {
//     try {
//       debugPrint('🔄 Fetching new AppCheck token');
//       final token = await FirebaseAppCheck.instance.getToken(false);
//
//       if (token != null) {
//         _cachedToken = token;
//         _tokenExpiry = DateTime.now().add(const Duration(minutes: 50));
//         debugPrint('✅ AppCheck token cached');
//       }
//
//       return token;
//     } catch (e) {
//       debugPrint('❌ AppCheck error: $e');
//       return _cachedToken; // fallback to expired cached token
//     }
//   }
//
//   static void clearCache() {
//     _cachedToken = null;
//     _tokenExpiry = null;
//     _ongoingFetch = null;
//     debugPrint('🗑️ AppCheck token cache cleared');
//   }
// }

// import 'package:firebase_app_check/firebase_app_check.dart';
// import 'package:flutter/foundation.dart';
//
// class AppCheckService {
//   static String? _cachedToken;
//   static DateTime? _tokenExpiry;
//
//   static Future<String?> getToken() async {
//     try {
//       // use cached token if still valid
//       if (_cachedToken != null &&
//           _tokenExpiry != null &&
//           DateTime.now().isBefore(_tokenExpiry!)) {
//         debugPrint('🛡️ Using cached AppCheck token');
//         return _cachedToken;
//       }
//
//       debugPrint('🔄 Fetching new AppCheck token');
//
//       final token = await FirebaseAppCheck.instance.getToken(false);
//
//       if (token != null) {
//         _cachedToken = token;
//
//         // token valid approx 1 hour
//         _tokenExpiry = DateTime.now().add(const Duration(minutes: 50));
//       }
//
//       debugPrint('🛡️ AppCheck token: $token');
//
//       return token;
//     } catch (e) {
//       debugPrint('❌ AppCheck error: $e');
//       return _cachedToken;
//     }
//   }
// }
// // class AppCheckService {
// //   static String? _cachedToken;
// //   static DateTime? _tokenExpiry;
// //
// //   static Future<String?> getToken() async {
// //     try {
// //       // Clear old cached token
// //       _cachedToken = null;
// //       _tokenExpiry = null;
// //
// //       debugPrint('🔄 Fetching new AppCheck token');
// //       final token = await FirebaseAppCheck.instance
// //           .getToken(true); // true = force refresh
// //       debugPrint('🛡️ Token result: $token');
// //       return token;
// //     } catch (e) {
// //       debugPrint('❌ AppCheck error: $e');
// //       return null;
// //     }
// //   }
// // // static Future<String?> getToken() async {
// // //   try {
// // //     if (_cachedToken != null &&
// // //         _tokenExpiry != null &&
// // //         DateTime.now().isBefore(_tokenExpiry!)) {
// // //       debugPrint('Using cached AppCheck token');
// // //       return _cachedToken;
// // //     }
// // //
// // //     debugPrint('🔄 Fetching new AppCheck token');
// // //
// // //     final token = await FirebaseAppCheck.instance.getToken(false);
// // //     debugPrint('🛡️ Raw token: $token');
// // //
// // //     if (token != null) {
// // //       _cachedToken = token;
// // //
// // //       // AppCheck tokens valid ~1 hour
// // //       _tokenExpiry = DateTime.now().add(const Duration(minutes: 50));
// // //     }
// // //
// // //     debugPrint('✅ Token fetched');
// // //     return token;
// // //   } catch (e) {
// // //     debugPrint('❌ AppCheck error: $e');
// // //
// // //     // fallback
// // //     return _cachedToken;
// // //   }
// // // }
// // }
// // class AppCheckService {
// //   static String? _cachedToken;
// //   static DateTime? _tokenExpiry;
// //
// //   static Future<String?> getToken() async {
// //     try {
// //       if (_cachedToken != null &&
// //           _tokenExpiry != null &&
// //           DateTime.now().isBefore(_tokenExpiry!)) {
// //         debugPrint(
// //             '✅ AppCheck CACHED token: ${_cachedToken!.substring(0, 20)}...');
// //         return _cachedToken;
// //       }
// //
// //       debugPrint('🔄 AppCheck fetching NEW token...');
// //       final token = await FirebaseAppCheck.instance.getToken();
// //
// //       _cachedToken = token;
// //       _tokenExpiry = DateTime.now().add(const Duration(minutes: 50));
// //
// //       // 👇 ADD THIS - shows full token in debug mode only
// //       if (kDebugMode) {
// //         debugPrint('🛡️ =============================');
// //         debugPrint('🛡️ FULL APP CHECK TOKEN (copy this to Firebase Console):');
// //         debugPrint('🛡️ $token');
// //         debugPrint('🛡️ =============================');
// //       }
// //
// //       debugPrint('✅ AppCheck NEW token fetched: ${token?.substring(0, 20)}...');
// //       return token;
// //     } catch (e) {
// //       debugPrint('❌ AppCheck getToken error: $e');
// //       if (_cachedToken != null) {
// //         debugPrint('⚠️ Using expired cached token as fallback');
// //         return _cachedToken;
// //       }
// //       return null;
// //     }
// //   }
// //
// //   static void clearCache() {
// //     _cachedToken = null;
// //     _tokenExpiry = null;
// //     debugPrint('🗑️ AppCheck token cache cleared');
// //   }
// // }
//
// // import 'package:firebase_app_check/firebase_app_check.dart';
// // import 'package:flutter/foundation.dart';
// //
// // class AppCheckService {
// //   static String? _cachedToken;
// //   static DateTime? _tokenExpiry;
// //
// //   static Future<String?> getToken() async {
// //     try {
// //       if (_cachedToken != null &&
// //           _tokenExpiry != null &&
// //           DateTime.now().isBefore(_tokenExpiry!)) {
// //         debugPrint(
// //             '✅ AppCheck CACHED token: ${_cachedToken!.substring(0, 20)}...');
// //         return _cachedToken;
// //       }
// //
// //       debugPrint('🔄 AppCheck fetching NEW token...');
// //       final token = await FirebaseAppCheck.instance.getToken();
// //
// //       _cachedToken = token;
// //       _tokenExpiry = DateTime.now().add(const Duration(minutes: 50));
// //
// //       debugPrint('✅ AppCheck NEW token fetched: ${token?.substring(0, 20)}...');
// //       return token;
// //     } catch (e) {
// //       debugPrint('❌ AppCheck getToken error: $e');
// //       if (_cachedToken != null) {
// //         debugPrint('⚠️ Using expired cached token as fallback');
// //         return _cachedToken;
// //       }
// //       return null;
// //     }
// //   }
// //
// //   // Call this on logout to clear cache
// //   static void clearCache() {
// //     _cachedToken = null;
// //     _tokenExpiry = null;
// //     debugPrint('🗑️ AppCheck token cache cleared');
// //   }
// // }
