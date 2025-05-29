import 'dart:developer';

import 'package:RiskSphere/utils/toast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Helper class for creating common HTTP headers.
class CommonHeaders {
  /// Creates and returns a map of common HTTP headers, including authorization headers.
  /// This method is asynchronous and returns a Future containing the headers.
  static Future<Map<String, String>> createHeaders() async {
    // Initialize an empty map for headers
    Map<String, String> headers = {};

    try {
      // Reload the current user to get the latest information
      await FirebaseAuth.instance.currentUser?.reload();

      // Get the ID token result for the current user
      IdTokenResult? token =
          await FirebaseAuth.instance.currentUser?.getIdTokenResult();

      // Extract claims from the token or default to an empty map
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
        // Get.closeAllSnackbars();
        // Get.snackbar(
        //   'No Internet',
        //   pleaseCheckYourInternetConnectivityAndTryAgain,
        //   snackPosition: SnackPosition.BOTTOM,
        //   backgroundColor: Colors.red,
        //   colorText: Colors.white,
        // );

        // Optionally show a snackbar, dialog, or UI message
        // e.g., showSnackbar("No internet connection.");
        // Stop further execution
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
      // Handle errors

      // Convert error to string
      final errorString = e.toString();

      // Check if the error is a network error
      if (errorString.contains('network-request-failed')) {
        print("No internet connection. Please check your connection.");
        errorToast(pleaseCheckYourInternetConnectivityAndTryAgain);
        // Get.closeAllSnackbars();
        // Get.snackbar(
        //   'No Internet',
        //   pleaseCheckYourInternetConnectivityAndTryAgain,
        //   snackPosition: SnackPosition.BOTTOM,
        //   backgroundColor: Colors.red,
        //   colorText: Colors.white,
        // );

        // Optionally show a snackbar, dialog, or UI message
        // e.g., showSnackbar("No internet connection.");
        // Stop further execution
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

      // Handle errors

      // Convert error to string
      final errorString = e.toString();

      // Check if the error is a network error
      if (errorString.contains('network-request-failed')) {
        print("No internet connection. Please check your connection.");
        errorToast(pleaseCheckYourInternetConnectivityAndTryAgain);
        // Get.closeAllSnackbars();
        // Get.snackbar(
        //   'No Internet',
        //   pleaseCheckYourInternetConnectivityAndTryAgain,
        //   snackPosition: SnackPosition.BOTTOM,
        //   backgroundColor: Colors.red,
        //   colorText: Colors.white,
        // );

        // Optionally show a snackbar, dialog, or UI message
        // e.g., showSnackbar("No internet connection.");
        // Stop further execution
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
      headers['Accept'] = '*/*'; // Header for binary data
      headers['Accept-Encoding'] =
          'gzip, deflate, br'; // Header for binary data
      headers['Connection'] = 'keep-alive'; // Header for binary data
      headers['Cache-Control'] = 'no-cache'; // Header for binary data
      headers['Pragma'] = 'no-cache'; // Header for binary data
      headers['Expires'] = '0'; // Header for binary data
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

    return headers;
  }
}
