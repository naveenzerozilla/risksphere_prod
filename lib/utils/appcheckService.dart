import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

class AppCheckService {
  static String? _cachedToken;
  static DateTime? _tokenExpiry;

  static Future<String?> getToken() async {
    try {
      // ✅ USE CACHE
      if (_cachedToken != null &&
          _tokenExpiry != null &&
          DateTime.now().isBefore(_tokenExpiry!)) {
        debugPrint('✅ Using cached AppCheck token');
        return _cachedToken;
      }

      debugPrint('🔄 Fetching new AppCheck token');

      final token = await FirebaseAppCheck.instance.getToken(false);

      if (token != null) {
        _cachedToken = token;

        // AppCheck tokens valid ~1 hour
        _tokenExpiry = DateTime.now().add(const Duration(minutes: 50));
      }

      debugPrint('✅ Token fetched');
      return token;
    } catch (e) {
      debugPrint('❌ AppCheck error: $e');

      // fallback
      return _cachedToken;
    }
  }
}
// class AppCheckService {
//   static String? _cachedToken;
//   static DateTime? _tokenExpiry;
//
//   static Future<String?> getToken() async {
//     try {
//       if (_cachedToken != null &&
//           _tokenExpiry != null &&
//           DateTime.now().isBefore(_tokenExpiry!)) {
//         debugPrint(
//             '✅ AppCheck CACHED token: ${_cachedToken!.substring(0, 20)}...');
//         return _cachedToken;
//       }
//
//       debugPrint('🔄 AppCheck fetching NEW token...');
//       final token = await FirebaseAppCheck.instance.getToken();
//
//       _cachedToken = token;
//       _tokenExpiry = DateTime.now().add(const Duration(minutes: 50));
//
//       // 👇 ADD THIS - shows full token in debug mode only
//       if (kDebugMode) {
//         debugPrint('🛡️ =============================');
//         debugPrint('🛡️ FULL APP CHECK TOKEN (copy this to Firebase Console):');
//         debugPrint('🛡️ $token');
//         debugPrint('🛡️ =============================');
//       }
//
//       debugPrint('✅ AppCheck NEW token fetched: ${token?.substring(0, 20)}...');
//       return token;
//     } catch (e) {
//       debugPrint('❌ AppCheck getToken error: $e');
//       if (_cachedToken != null) {
//         debugPrint('⚠️ Using expired cached token as fallback');
//         return _cachedToken;
//       }
//       return null;
//     }
//   }
//
//   static void clearCache() {
//     _cachedToken = null;
//     _tokenExpiry = null;
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
//       if (_cachedToken != null &&
//           _tokenExpiry != null &&
//           DateTime.now().isBefore(_tokenExpiry!)) {
//         debugPrint(
//             '✅ AppCheck CACHED token: ${_cachedToken!.substring(0, 20)}...');
//         return _cachedToken;
//       }
//
//       debugPrint('🔄 AppCheck fetching NEW token...');
//       final token = await FirebaseAppCheck.instance.getToken();
//
//       _cachedToken = token;
//       _tokenExpiry = DateTime.now().add(const Duration(minutes: 50));
//
//       debugPrint('✅ AppCheck NEW token fetched: ${token?.substring(0, 20)}...');
//       return token;
//     } catch (e) {
//       debugPrint('❌ AppCheck getToken error: $e');
//       if (_cachedToken != null) {
//         debugPrint('⚠️ Using expired cached token as fallback');
//         return _cachedToken;
//       }
//       return null;
//     }
//   }
//
//   // Call this on logout to clear cache
//   static void clearCache() {
//     _cachedToken = null;
//     _tokenExpiry = null;
//     debugPrint('🗑️ AppCheck token cache cleared');
//   }
// }
