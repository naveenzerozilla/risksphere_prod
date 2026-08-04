import 'dart:developer';

import 'package:RiskSphere/utils/toast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'appcheckService.dart';

class CommonHeaders {
  static Future<Map<String, String>> createHeaders() async {
    Map<String, String> headers = {};

    try {
      try {
        await FirebaseAuth.instance.currentUser
            ?.reload()
            .timeout(const Duration(seconds: 3));
      } catch (reloadError) {
        debugPrint('  FirebaseAuth user reload skipped/timed out: $reloadError');
      }
      IdTokenResult? token =
          await FirebaseAuth.instance.currentUser?.getIdTokenResult();

      headers['Authorization'] = 'Bearer ${token?.token ?? ""}';
      headers['Content-Type'] = 'application/json';

      try {
        final appCheckToken = await AppCheckService.getToken();
        if (appCheckToken != null) {
          headers['X-Firebase-AppCheck'] = appCheckToken;
          debugPrint(' ===== APP CHECK TOKEN ADDED =====');
          debugPrint(' Token preview: ${appCheckToken.substring(0, 30)}...');
          debugPrint(' Token length: ${appCheckToken.length}');
        } else {
          debugPrint(' AppCheck token is NULL - not added to headers');
        }
      } catch (e) {
        debugPrint(' AppCheck skipped: $e');
      }
      debugPrint(' Final Headers:');
      headers.forEach((key, value) {
        if (key == 'Authorization') {
          debugPrint(
              '   $key: Bearer ...${value.substring(value.length - 10)}');
        } else if (key == 'X-Firebase-AppCheck') {
          debugPrint('   $key: ${value.substring(0, 20)}... ');
        } else {
          debugPrint('   $key: $value');
        }
      });
    } catch (e) {
      final errorString = e.toString();
      if (errorString.contains('network-request-failed')) {
        errorToast(pleaseCheckYourInternetConnectivityAndTryAgain);
      }
      debugPrint(' createHeaders error: $e');
    }

    return headers;
  }

  static Future<Map<String, String>> createHeaders1() async {
    Map<String, String> headers = {};
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");
      final idToken = await user.getIdToken(true);
      if (idToken!.isEmpty) throw Exception("Token is empty");

      final appCheckToken = await AppCheckService.getToken();

      headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer $idToken",
        "X-Firebase-AppCheck": appCheckToken ?? '',
      };
    } catch (e) {
      debugPrint("Error while creating headers: $e");
      rethrow;
    }
    return headers;
  }

  static Future<Map<String, String>> createMultiPartHeaders() async {
    Map<String, String> headers = {};
    try {
      try {
        await FirebaseAuth.instance.currentUser
            ?.reload()
            .timeout(const Duration(seconds: 3));
      } catch (reloadError) {
        debugPrint('  FirebaseAuth user reload skipped/timed out: $reloadError');
      }
      IdTokenResult? token =
          await FirebaseAuth.instance.currentUser?.getIdTokenResult();

      final appCheckToken = await AppCheckService.getToken();

      headers['Authorization'] = 'Bearer ${token?.token ?? ""}';
      headers['X-Firebase-AppCheck'] = appCheckToken ?? '';
    } catch (e) {
      final errorString = e.toString();
      if (errorString.contains('network-request-failed')) {
        errorToast(pleaseCheckYourInternetConnectivityAndTryAgain);
      }
    }
    return headers;
  }

  static Future<Map<String, String>> createMultiPartHeadersSOV() async {
    Map<String, String> headers = {'Content-Type': 'multipart/form-data'};
    try {
      try {
        await FirebaseAuth.instance.currentUser
            ?.reload()
            .timeout(const Duration(seconds: 3));
      } catch (reloadError) {
        debugPrint('  FirebaseAuth user reload skipped/timed out: $reloadError');
      }
      IdTokenResult? token =
          await FirebaseAuth.instance.currentUser?.getIdTokenResult();

      final appCheckToken = await AppCheckService.getToken();

      headers['Authorization'] = 'Bearer ${token?.token ?? ""}';
      headers['X-Firebase-AppCheck'] = appCheckToken ?? '';
    } catch (e) {
      final errorString = e.toString();
      if (errorString.contains('network-request-failed')) {
        errorToast(pleaseCheckYourInternetConnectivityAndTryAgain);
      }
    }
    return headers;
  }

  static Future<Map<String, String>> createDownloadHeaders() async {
    Map<String, String> headers = {};
    try {
      try {
        await FirebaseAuth.instance.currentUser
            ?.reload()
            .timeout(const Duration(seconds: 3));
      } catch (reloadError) {
        debugPrint('  FirebaseAuth user reload skipped/timed out: $reloadError');
      }
      IdTokenResult? token =
          await FirebaseAuth.instance.currentUser?.getIdTokenResult();

      final appCheckToken = await AppCheckService.getToken();

      headers['Authorization'] = 'Bearer ${token?.token ?? ""}';
      headers['Content-Type'] = 'application/json';
      headers['X-Firebase-AppCheck'] = appCheckToken ?? '';
      headers['Accept'] = '*/*';
      headers['Accept-Encoding'] = 'gzip, deflate, br';
      headers['Connection'] = 'keep-alive';
      headers['Cache-Control'] = 'no-cache';
      headers['Pragma'] = 'no-cache';
      headers['Expires'] = '0';
    } catch (e) {
      final errorString = e.toString();
      if (errorString.contains('network-request-failed')) {
        errorToast(pleaseCheckYourInternetConnectivityAndTryAgain);
      }
    }
    return headers;
  }
}

//App check or above

// import 'package:RiskSphere/utils/toast.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'appcheckService.dart';
//
// class CommonHeaders {
//   static Future<Map<String, String>> createHeaders1() async {
//     Map<String, String> headers = {};
//
//     try {
//       final user = FirebaseAuth.instance.currentUser;
//
//       if (user == null) {
//         throw Exception("User not logged in");
//       }
//
//       // Force refresh token
//       final idToken = await user.getIdToken(true);
//
//       if (idToken!.isEmpty) {
//         throw Exception("Token is empty");
//       }
//
//       String? appCheckToken;
//       try {
//         appCheckToken = await AppCheckService.getToken();
//       } catch (e) {
//         print("AppCheck token fetch error: $e");
//       }
//
//       headers = {
//         "Content-Type": "application/json",
//         "Authorization": "Bearer $idToken",
//       };
//       if (appCheckToken != null && appCheckToken.isNotEmpty) {
//         headers["X-Firebase-AppCheck"] = appCheckToken;
//       }
//
//       print("Generated Token: $idToken"); // Debug
//     } catch (e) {
//       print("Error while creating headers: $e");
//       rethrow; // Important: don't silently continue
//     }
//
//     return headers;
//   }
//
//   static Future<Map<String, String>> createHeaders() async {
//     Map<String, String> headers = {};
//
//     try {
//       await FirebaseAuth.instance.currentUser?.reload();
//
//       IdTokenResult? token =
//           await FirebaseAuth.instance.currentUser?.getIdTokenResult();
//
//       Map<String, dynamic>? claims = token?.claims ?? {};
//
//       // Add headers as needed
//       headers['Authorization'] =
//           'Bearer ${token?.token ?? ""}'; // Example: Authorization header with Bearer token
//       headers['Content-Type'] = 'application/json';
//
//       try {
//         final appCheckToken = await AppCheckService.getToken();
//         if (appCheckToken != null && appCheckToken.isNotEmpty) {
//           headers['X-Firebase-AppCheck'] = appCheckToken;
//         }
//       } catch (e) {
//         print("AppCheck token fetch error: $e");
//       }
//     } catch (e) {
//       // Handle errors
//
//       // Convert error to string
//       final errorString = e.toString();
//
//       // Check if the error is a network error
//       if (errorString.contains('network-request-failed')) {
//         print("No internet connection. Please check your connection.");
//         errorToast(pleaseCheckYourInternetConnectivityAndTryAgain);
//       }
//
//       print("Error while creating headers: $e");
//     }
//
//     // Return the headers map
//     return headers;
//   }
//
//   static Future<Map<String, String>> createMultiPartHeaders() async {
//     Map<String, String> headers = {};
//
//     try {
//       await FirebaseAuth.instance.currentUser?.reload();
//       IdTokenResult? token =
//           await FirebaseAuth.instance.currentUser?.getIdTokenResult();
//       Map<String, dynamic>? claims = token?.claims ?? {};
//
//       headers['Authorization'] = 'Bearer ${token?.token ?? ""}';
//
//       try {
//         final appCheckToken = await AppCheckService.getToken();
//         if (appCheckToken != null && appCheckToken.isNotEmpty) {
//           headers['X-Firebase-AppCheck'] = appCheckToken;
//         }
//       } catch (e) {
//         print("AppCheck token fetch error: $e");
//       }
//     } catch (e) {
//       final errorString = e.toString();
//       if (errorString.contains('network-request-failed')) {
//         print("No internet connection. Please check your connection.");
//         errorToast(pleaseCheckYourInternetConnectivityAndTryAgain);
//       }
//
//       print("Error while creating headers: $e");
//     }
//     return headers;
//   }
//
//   static Future<Map<String, String>> createMultiPartHeadersSOV() async {
//     Map<String, String> headers = {
//       'Content-Type': 'multipart/form-data',
//     };
//
//     try {
//       await FirebaseAuth.instance.currentUser?.reload();
//       IdTokenResult? token =
//           await FirebaseAuth.instance.currentUser?.getIdTokenResult();
//       Map<String, dynamic>? claims = token?.claims ?? {};
//
//       headers['Authorization'] = 'Bearer ${token?.token ?? ""}';
//
//       try {
//         final appCheckToken = await AppCheckService.getToken();
//         if (appCheckToken != null && appCheckToken.isNotEmpty) {
//           headers['X-Firebase-AppCheck'] = appCheckToken;
//         }
//       } catch (e) {
//         print("AppCheck token fetch error: $e");
//       }
//       print("Headers: $headers");
//     } catch (e) {
//       print("Error while creating headers: $e");
//
//       final errorString = e.toString();
//       if (errorString.contains('network-request-failed')) {
//         print("No internet connection. Please check your connection.");
//         errorToast(pleaseCheckYourInternetConnectivityAndTryAgain);
//       }
//
//       print("Error while creating headers: $e");
//     }
//
//     return headers;
//   }
//
//   static Future<Map<String, String>> createDownloadHeaders() async {
//     Map<String, String> headers = {};
//
//     try {
//       await FirebaseAuth.instance.currentUser?.reload();
//       IdTokenResult? token =
//           await FirebaseAuth.instance.currentUser?.getIdTokenResult();
//
//       headers['Authorization'] = 'Bearer ${token?.token ?? ""}';
//       headers['Content-Type'] = 'application/json';
//       headers['Accept'] = '*/*';
//       headers['Accept-Encoding'] = 'gzip, deflate, br';
//       headers['Connection'] = 'keep-alive';
//       headers['Cache-Control'] = 'no-cache';
//       headers['Pragma'] = 'no-cache';
//       headers['Expires'] = '0';
//
//       try {
//         final appCheckToken = await AppCheckService.getToken();
//         if (appCheckToken != null && appCheckToken.isNotEmpty) {
//           headers['X-Firebase-AppCheck'] = appCheckToken;
//         }
//       } catch (e) {
//         print("AppCheck token fetch error: $e");
//       }
//     } catch (e) {
//       final errorString = e.toString();
//       if (errorString.contains('network-request-failed')) {
//         print("No internet connection. Please check your connection.");
//         errorToast(pleaseCheckYourInternetConnectivityAndTryAgain);
//       }
//
//       print("Error while creating headers: $e");
//     }
//
//     return headers;
//   }
// }
