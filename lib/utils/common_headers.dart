// import 'dart:developer';
//
// import 'package:RiskSphere/utils/toast.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
//
// import 'appcheckService.dart';
//
// class CommonHeaders {
//   static Future<Map<String, String>> createHeaders() async {
//     Map<String, String> headers = {};
//
//     try {
//       await FirebaseAuth.instance.currentUser?.reload();
//       IdTokenResult? token =
//           await FirebaseAuth.instance.currentUser?.getIdTokenResult();
//
//       headers['Authorization'] = 'Bearer ${token?.token ?? ""}';
//       headers['Content-Type'] = 'application/json';
//
//       try {
//         final appCheckToken = await AppCheckService.getToken();
//         if (appCheckToken != null) {
//           headers['X-Firebase-AppCheck'] = appCheckToken;
//           debugPrint(' ===== APP CHECK TOKEN ADDED =====');
//           debugPrint(' Token preview: ${appCheckToken.substring(0, 30)}...');
//           debugPrint(' Token length: ${appCheckToken.length}');
//         } else {
//           debugPrint(' AppCheck token is NULL - not added to headers');
//         }
//       } catch (e) {
//         debugPrint(' AppCheck skipped: $e');
//       }
//       debugPrint(' Final Headers:');
//       headers.forEach((key, value) {
//         if (key == 'Authorization') {
//           debugPrint(
//               '   $key: Bearer ...${value.substring(value.length - 10)}');
//         } else if (key == 'X-Firebase-AppCheck') {
//           debugPrint('   $key: ${value.substring(0, 20)}... ');
//         } else {
//           debugPrint('   $key: $value');
//         }
//       });
//     } catch (e) {
//       final errorString = e.toString();
//       if (errorString.contains('network-request-failed')) {
//         errorToast(pleaseCheckYourInternetConnectivityAndTryAgain);
//       }
//       debugPrint(' createHeaders error: $e');
//     }
//
//     return headers;
//   }
//
//   static Future<Map<String, String>> createHeaders1() async {
//     Map<String, String> headers = {};
//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       if (user == null) throw Exception("User not logged in");
//       final idToken = await user.getIdToken(true);
//       if (idToken!.isEmpty) throw Exception("Token is empty");
//
//       final appCheckToken = await AppCheckService.getToken();
//
//       headers = {
//         "Content-Type": "application/json",
//         "Authorization": "Bearer $idToken",
//         "X-Firebase-AppCheck": appCheckToken ?? '',
//       };
//     } catch (e) {
//       debugPrint("Error while creating headers: $e");
//       rethrow;
//     }
//     return headers;
//   }
//
//   static Future<Map<String, String>> createMultiPartHeaders() async {
//     Map<String, String> headers = {};
//     try {
//       await FirebaseAuth.instance.currentUser?.reload();
//       IdTokenResult? token =
//           await FirebaseAuth.instance.currentUser?.getIdTokenResult();
//
//       final appCheckToken = await AppCheckService.getToken();
//
//       headers['Authorization'] = 'Bearer ${token?.token ?? ""}';
//       headers['X-Firebase-AppCheck'] = appCheckToken ?? '';
//     } catch (e) {
//       final errorString = e.toString();
//       if (errorString.contains('network-request-failed')) {
//         errorToast(pleaseCheckYourInternetConnectivityAndTryAgain);
//       }
//     }
//     return headers;
//   }
//
//   static Future<Map<String, String>> createMultiPartHeadersSOV() async {
//     Map<String, String> headers = {'Content-Type': 'multipart/form-data'};
//     try {
//       await FirebaseAuth.instance.currentUser?.reload();
//       IdTokenResult? token =
//           await FirebaseAuth.instance.currentUser?.getIdTokenResult();
//
//       final appCheckToken = await AppCheckService.getToken();
//
//       headers['Authorization'] = 'Bearer ${token?.token ?? ""}';
//       headers['X-Firebase-AppCheck'] = appCheckToken ?? '';
//     } catch (e) {
//       final errorString = e.toString();
//       if (errorString.contains('network-request-failed')) {
//         errorToast(pleaseCheckYourInternetConnectivityAndTryAgain);
//       }
//     }
//     return headers;
//   }
//
//   static Future<Map<String, String>> createDownloadHeaders() async {
//     Map<String, String> headers = {};
//     try {
//       await FirebaseAuth.instance.currentUser?.reload();
//       IdTokenResult? token =
//           await FirebaseAuth.instance.currentUser?.getIdTokenResult();
//
//       final appCheckToken = await AppCheckService.getToken();
//
//       headers['Authorization'] = 'Bearer ${token?.token ?? ""}';
//       headers['Content-Type'] = 'application/json';
//       headers['X-Firebase-AppCheck'] = appCheckToken ?? '';
//       headers['Accept'] = '*/*';
//       headers['Accept-Encoding'] = 'gzip, deflate, br';
//       headers['Connection'] = 'keep-alive';
//       headers['Cache-Control'] = 'no-cache';
//       headers['Pragma'] = 'no-cache';
//       headers['Expires'] = '0';
//     } catch (e) {
//       final errorString = e.toString();
//       if (errorString.contains('network-request-failed')) {
//         errorToast(pleaseCheckYourInternetConnectivityAndTryAgain);
//       }
//     }
//     return headers;
//   }
// }

//App check or above

import 'package:RiskSphere/utils/toast.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommonHeaders {
  static Future<Map<String, String>> createHeaders1() async {
    Map<String, String> headers = {};

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception("User not logged in");
      }

      // Force refresh token
      final idToken = await user.getIdToken(true);

      if (idToken!.isEmpty) {
        throw Exception("Token is empty");
      }

      headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer $idToken",
      };

      print("Generated Token: $idToken"); // Debug
    } catch (e) {
      print("Error while creating headers: $e");
      rethrow; // Important: don't silently continue
    }

    return headers;
  }

  static Future<Map<String, String>> createHeaders() async {
    Map<String, String> headers = {};

    try {
      await FirebaseAuth.instance.currentUser?.reload();

      IdTokenResult? token =
          await FirebaseAuth.instance.currentUser?.getIdTokenResult();

      Map<String, dynamic>? claims = token?.claims ?? {};

      // Add headers as needed
      headers['Authorization'] =
          'Bearer ${token?.token ?? ""}'; // Example: Authorization header with Bearer token
      headers['Content-Type'] = 'application/json';
      // Add more headers if necessary
    } catch (e) {
      // Handle errors

      // Convert error to string
      final errorString = e.toString();

      // Check if the error is a network error
      if (errorString.contains('network-request-failed')) {
        print("No internet connection. Please check your connection.");
        errorToast(pleaseCheckYourInternetConnectivityAndTryAgain);
      }

      print("Error while creating headers: $e");
    }

    // Return the headers map
    return headers;
  }

  static Future<Map<String, String>> createMultiPartHeaders() async {
    Map<String, String> headers = {};

    try {
      await FirebaseAuth.instance.currentUser?.reload();
      IdTokenResult? token =
          await FirebaseAuth.instance.currentUser?.getIdTokenResult();
      Map<String, dynamic>? claims = token?.claims ?? {};

      headers['Authorization'] = 'Bearer ${token?.token ?? ""}';
    } catch (e) {
      final errorString = e.toString();
      if (errorString.contains('network-request-failed')) {
        print("No internet connection. Please check your connection.");
        errorToast(pleaseCheckYourInternetConnectivityAndTryAgain);
      }

      print("Error while creating headers: $e");
    }
    return headers;
  }

  static Future<Map<String, String>> createMultiPartHeadersSOV() async {
    Map<String, String> headers = {
      'Content-Type': 'multipart/form-data',
    };

    try {
      await FirebaseAuth.instance.currentUser?.reload();
      IdTokenResult? token =
          await FirebaseAuth.instance.currentUser?.getIdTokenResult();
      Map<String, dynamic>? claims = token?.claims ?? {};

      headers['Authorization'] = 'Bearer ${token?.token ?? ""}';
      print("Headers: $headers");
    } catch (e) {
      print("Error while creating headers: $e");

      final errorString = e.toString();
      if (errorString.contains('network-request-failed')) {
        print("No internet connection. Please check your connection.");
        errorToast(pleaseCheckYourInternetConnectivityAndTryAgain);
      }

      print("Error while creating headers: $e");
    }

    return headers;
  }

  static Future<Map<String, String>> createDownloadHeaders() async {
    Map<String, String> headers = {};

    try {
      await FirebaseAuth.instance.currentUser?.reload();
      IdTokenResult? token =
          await FirebaseAuth.instance.currentUser?.getIdTokenResult();

      headers['Authorization'] = 'Bearer ${token?.token ?? ""}';
      headers['Content-Type'] = 'application/json';
      headers['Accept'] = '*/*';
      headers['Accept-Encoding'] = 'gzip, deflate, br';
      headers['Connection'] = 'keep-alive';
      headers['Cache-Control'] = 'no-cache';
      headers['Pragma'] = 'no-cache';
      headers['Expires'] = '0';
    } catch (e) {
      final errorString = e.toString();
      if (errorString.contains('network-request-failed')) {
        print("No internet connection. Please check your connection.");
        errorToast(pleaseCheckYourInternetConnectivityAndTryAgain);
      }

      print("Error while creating headers: $e");
    }

    return headers;
  }
}
