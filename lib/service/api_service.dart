import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:green/utils/api_constants.dart';
import 'package:http/http.dart' as http;

import '../utils/common_headers.dart';

class ApiService {
  final String endpoint;

  ApiService(this.endpoint);

  String get url => '$endpoint';

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
    print("Response: ${response.body}");
    print("Response Code: ${response.statusCode}");
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
  Future<Map<String, dynamic>> postMultiPartSOVAccounts(File filePath, String accountId, String name) async {
    await FirebaseAuth.instance.currentUser?.reload();
    IdTokenResult? token = await FirebaseAuth.instance.currentUser?.getIdTokenResult();
    var headers = {
      'Authorization': 'Bearer ${token?.token ?? ""}',
      'Content-Type': 'multipart/form-data',
    };
    var request = http.MultipartRequest('POST', Uri.parse(AppConstant.UPLOAD_SOV_ACCOUNT + '/upload'));
    request.fields.addAll({
      'sov_name': name,
      'account_id': accountId,
      'device': 'mobile'
    });
    print("Request Fields: ${request.fields}");
    print("Request Files path: ${filePath.path}");
    request.files.add(await http.MultipartFile.fromPath('file', filePath.path));
    print("Request Files: ${request.files}");
    request.headers.addAll(headers);
    log("Request headers: ${request.headers}");

    http.StreamedResponse streamedResponse = await request.send();

    if (streamedResponse.statusCode == 200) {
      String responseData = await streamedResponse.stream.bytesToString();
      print(responseData);
      return _handleResponse(http.Response(responseData, streamedResponse.statusCode));
    } else {
      String responseData = await streamedResponse.stream.bytesToString();
      print(responseData);
      throw BackendException(responseData ?? "An error occurred", streamedResponse.statusCode);
    }
  }

  Future<Map<String, dynamic>> postMultiPartSOVSubAccounts(File filePath, String accountId, String subAccountId, String name) async {
    await FirebaseAuth.instance.currentUser?.reload();
    IdTokenResult? token = await FirebaseAuth.instance.currentUser?.getIdTokenResult();
    var headers = {
      'Authorization': 'Bearer ${token?.token ?? ""}',
      'Content-Type': 'multipart/form-data',
    };
    var request = http.MultipartRequest('POST', Uri.parse(AppConstant.UPLOAD_SOV_ACCOUNT + '/upload'));
    var body = {
    //  'data': {
        'sov_name': name,
        'account_id': accountId,
        'sub_account_id': subAccountId,
        'device': 'mobile'
   //   }
    };
    request.fields.addAll(body);
    print("Request Fields: ${request.fields}");
    print("Request Files path: ${filePath.path}");
    request.files.add(await http.MultipartFile.fromPath('file', filePath.path));
    print("Request Files: ${request.files}");
    request.headers.addAll(headers);
    log("Request headers: ${request.headers}");

    http.StreamedResponse streamedResponse = await request.send();

    print("Response Code: ${streamedResponse.statusCode}");
    print("Response Reason: ${streamedResponse.reasonPhrase}");
    if (streamedResponse.statusCode == 200) {
      String responseData = await streamedResponse.stream.bytesToString();
      print(responseData);
      return _handleResponse(http.Response(responseData, streamedResponse.statusCode));
    } else {
      String responseData = await streamedResponse.stream.bytesToString();
      print(responseData);
      throw BackendException(responseData ?? "An error occurred", streamedResponse.statusCode);
    }
  }

  Future<Map<String, dynamic>> postMultiPartLocationProfile(File filePath, String accountId, String subAccountId, String sovId, String locationId, String name) async {
    await FirebaseAuth.instance.currentUser?.reload();
    IdTokenResult? token = await FirebaseAuth.instance.currentUser?.getIdTokenResult();
    var headers = {
      'Authorization': 'Bearer ${token?.token ?? ""}',
      'Content-Type': 'multipart/form-data',
    };
    var request = http.MultipartRequest('POST', Uri.parse(AppConstant.GET_LOCATION_PROFILE + "/$accountId/subaccount/$subAccountId/sov/$sovId/location?location_id=$locationId"));
    request.fields.addAll({
      'location_id': locationId,
    });
    print("Request Fields: ${request.fields}");
    print("Request Files path: ${filePath.path}");
    request.files.add(await http.MultipartFile.fromPath('file_${DateTime.now().millisecondsSinceEpoch}', filePath.path));
    print("Request Files: ${request.files}");
    request.headers.addAll(headers);
    log("Request headers: ${request.headers}");

    http.StreamedResponse streamedResponse = await request.send();

    if (streamedResponse.statusCode == 200) {
      String responseData = await streamedResponse.stream.bytesToString();
      print(responseData);
      return _handleResponse(http.Response(responseData, streamedResponse.statusCode));
    } else {
      String responseData = await streamedResponse.stream.bytesToString();
      print("Reason"+responseData);
      throw BackendException(responseData ?? "An error occurred", streamedResponse.statusCode);
    }
  }

  Future<http.StreamedResponse> downloadFile(String url, Map<String, dynamic> body) async {
    var headers = await CommonHeaders.createDownloadHeaders();
    log("Headers: $headers");
    var request = http.Request('POST', Uri.parse(url));
    request.body = json.encode({"data": body});
    request.headers.addAll(headers);
    return await request.send();
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
      if (statusCode == 422) {
        throw BackendException(body, statusCode);
      }
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
