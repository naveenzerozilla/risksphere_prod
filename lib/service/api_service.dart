import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:green/utils/api_constants.dart';
import 'package:http/http.dart' as http;

import '../utils/common_headers.dart';

class ApiService {
  final String url;

  ApiService(this.url);

  /// Sends a GET request to the specified [url] with optional [additionalParams].
  /// Returns a Future containing the decoded JSON response.
  Future<Map<String, dynamic>> get(
      [String? additionalParams, bool? isList]) async {
    var headers = await CommonHeaders.createHeaders();
    log("Headers: $headers");
    log("URL: $url${additionalParams ?? ''}");
    final response = await http.get(Uri.parse('$url${additionalParams ?? ''}'),
        headers: headers);
    if (isList != null && isList) {
      return _handleResponse(response, isList);
    }
    return _handleResponse(response);
  }

  /// Sends a POST request to the specified [url] with the provided [body].
  /// Returns a Future containing the decoded JSON response.
  Future<Map<String, dynamic>> post(Map<String, dynamic> body,
      [String? additionalParams]) async {
    var headers = await CommonHeaders.createHeaders();
    log("Headers: $headers");
    log("URL: $url");
    log("Body: ${json.encode(body)}");
    final response = await http.post(
      Uri.parse('$url${additionalParams ?? ""}'),
      body: json.encode(body),
      headers: headers,
    );
    log("Response: ${response.body}");
    return _handleResponse(response);
  }

  /// Sends a PUT request to the specified [url] with the provided [body].
  /// Returns a Future containing the decoded JSON response.
  Future<Map<String, dynamic>> put(Map<String, dynamic> body) async {
    var headers = await CommonHeaders.createHeaders();
    final response = await http.put(
      Uri.parse('$url'),
      body: json.encode(body),
      headers: headers,
    );
    return _handleResponse(response);
  }

  /// Sends a DELETE request to the specified [url] with the provided [body].
  /// Returns a Future containing the decoded JSON response.
  Future<Map<String, dynamic>> delete(Map<String, dynamic> body) async {
    var headers = await CommonHeaders.createHeaders();
    log("Headers: $headers");
    log("URL: $url");
    log("Body: $body");
    final response = await http.delete(Uri.parse(url),
        body: json.encode(body), headers: headers);
    log("Response: ${response.body}");
    return _handleResponse(response);
  }

  /// Sends a PATCH request to the specified [url] with the provided [body].
  /// Returns a Future containing the decoded JSON response.
  Future<Map<String, dynamic>> patch(Map<String, dynamic> body) async {
    var headers = await CommonHeaders.createHeaders();
    log("Headers: $headers");
    log("URL: $url");
    log("Body: $body");
    final response = await http.patch(
      Uri.parse('$url'),
      body: json.encode(body),
      headers: headers,
    );
    log("Response: ${response.body}");
    return _handleResponse(response);
  }

  /// Sends a MultiPart POST request to the specified [url] with the provided [body].
  /// Returns a Future containing the decoded JSON response.
  /// The [body] should contain the file in the 'file' key and other form data in the 'data' key.
  Future<Map<String, dynamic>> postMultiPart(String filePath) async {
    var headers = await CommonHeaders.createMultiPartHeaders();
    print("Headers: $headers");
    print("URL: $url");

    var request =
        http.MultipartRequest('POST', Uri.parse(AppConstant.UPLOAD_FILE));
    request.files.add(await http.MultipartFile.fromPath('file', filePath));
    // Add headers to the request
    headers.forEach((key, value) {
      request.headers[key] = value;
    });

    // Send the request
    http.StreamedResponse response = await request.send();

    // Get response
    var responseData = await response.stream.bytesToString();
    print("Response: $responseData");

    // Handle response
    return _handleResponse(http.Response(responseData, response.statusCode));
  }

  /// Sends a MultiPart POST request to the specified [url] with the provided SOV.
  /// Returns a Future containing the decoded JSON response.
  /// The [body] should contain the file in the 'file' key and other form data in the 'data' key.
  Future<Map<String, dynamic>> postMultiPartSOV(File filePath,String accountId) async {
    var headers = await CommonHeaders.createMultiPartHeadersSOV();
    print("Headers: $headers");
    print("URL: $url");

    var request = http.MultipartRequest('POST', Uri.parse(AppConstant.SOV));
    request.fields['id'] = accountId;
    request.files.add(await http.MultipartFile.fromPath('file', filePath.path));
    // Add the id to the request body
    // request.files.add(await http('file', filePath));
    // Add headers to the request
    headers.forEach((key, value) {
      request.headers[key] = value;
    });

    // Send the request
    http.StreamedResponse response = await request.send();

    // Get response
    var responseData = await response.stream.bytesToString();
    print("Response: $responseData");

    // Handle response
    return _handleResponse(http.Response(responseData, response.statusCode));
  }

  /// Handles the HTTP response by checking the status code.
  /// If the status code is in the success range (200-299), decodes and returns the response body.
  /// Otherwise, throws a BackendException with the error message.
  Map<String, dynamic> _handleResponse(http.Response response, [bool? isList]) {
    final statusCode = response.statusCode;
    final body = response.body;
    log("Status Code: $statusCode");
    log("Response Body: $body");

    if (statusCode >= 200 && statusCode < 300) {
      if (isList != null && isList) {
        // Assuming the response body is wrapped in a list
        List<dynamic> responseList = json.decode(body);
        if (responseList.isNotEmpty) {
          return responseList[0]; // Return the first element of the list
        } else {
          // If the list is empty, return an empty map
          return {};
        }
      } else {
        // If not a list, directly decode the body
        return json.decode(body);
      }
    } else {
      // Server returned an error status code
      throw BackendException(_extractErrorMessage(body), statusCode);
    }
  }

  /// Extracts the error message from the response body.
  /// Returns the error message if available, otherwise returns a default error message.
  String _extractErrorMessage(String body) {
    try {
      final Map<String, dynamic> jsonResponse = json.decode(body);
      if (jsonResponse.containsKey('message')) {
        return jsonResponse['message'];
      } else if (jsonResponse.containsKey('error')) {
        return jsonResponse['error'];
      }
    } catch (_) {
      // If the response is not a valid JSON, return the whole body
    }
    return 'Something went wrong.';
  }
}

/// Exception thrown when an error occurs during backend communication.
class BackendException implements Exception {
  final String message;
  final int statusCode;

  BackendException(this.message, this.statusCode);

  @override
  String toString() {
    return 'BackendException: $message (Status Code: $statusCode)';
  }
}
