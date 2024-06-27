import 'package:firebase_auth/firebase_auth.dart';

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
      IdTokenResult? token = await FirebaseAuth.instance.currentUser?.getIdTokenResult();

      // Extract claims from the token or default to an empty map
      Map<String, dynamic>? claims = token?.claims ?? {};

      // Add headers as needed
      headers['Authorization'] = 'Bearer ${token?.token??""}'; // Example: Authorization header with Bearer token
      headers['Content-Type'] = 'application/json';
      // Add more headers if necessary

    } catch (e) {
      // Handle errors
      print("Error while creating headers: $e");
    }

    // Return the headers map
    return headers;
  }

  static Future<Map<String, String>> createMultiPartHeaders() async {
    Map<String, String> headers = {};

    try {
      await FirebaseAuth.instance.currentUser?.reload();
      IdTokenResult? token = await FirebaseAuth.instance.currentUser?.getIdTokenResult();
      Map<String, dynamic>? claims = token?.claims ?? {};

      headers['Authorization'] = 'Bearer ${token?.token??""}';
    } catch (e) {
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
      IdTokenResult? token = await FirebaseAuth.instance.currentUser?.getIdTokenResult();
      Map<String, dynamic>? claims = token?.claims ?? {};

      headers['Authorization'] = 'Bearer ${token?.token??""}';
    } catch (e) {
      print("Error while creating headers: $e");
    }

    return headers;
  }
}
