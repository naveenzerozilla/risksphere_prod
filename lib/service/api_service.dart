import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:RiskSphere/utils/api_constants.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:http/http.dart' as http;

import '../providers/auth_provider.dart';
import '../utils/common_headers.dart';

class ApiService {
  final String endpoint;

  ApiService(this.endpoint);

  String get url => '$endpoint';

  /// Sends a GET request to the specified [url] with optional [additionalParams].
  /// Returns a Future containing the decoded JSON response.
  /// Sends a GET request to the specified [url] with optional [additionalParams].
  /// Returns a Future containing the decoded JSON response.
  ///
  Future<Map<String, dynamic>> get(
      [String? additionalParams, bool? isList]
      ) async {
    var headers = await CommonHeaders.createHeaders();
    final fullUrl = '$url${additionalParams ?? ''}';

    log("URL: $fullUrl");

    // Create a custom trace
    final trace = FirebasePerformance.instance.newTrace("get_api_call");
    await trace.start();

    // Start HTTP metric
    final metric = FirebasePerformance.instance.newHttpMetric(fullUrl, HttpMethod.Get);
    await metric.start();

    try {
      final response = await http.get(Uri.parse(fullUrl), headers: headers);

      // Set metric details
      metric.httpResponseCode = response.statusCode;
      metric.requestPayloadSize = 0;
      metric.responsePayloadSize = response.bodyBytes.length;

      // Add a custom attribute to the trace
      trace.putAttribute("url", fullUrl);
      trace.setMetric("response_size", response.bodyBytes.length);

      if (isList != null && isList) {
        return _handleResponse(response, isList);
      }
      return _handleResponse(response);
    } catch (e) {
      metric.putAttribute("error", e.toString());
      trace.putAttribute("error", e.toString());
      rethrow;
    } finally {
      await metric.stop();
      await trace.stop(); // Stop trace after HTTP metric
    }
  }
  // Future<Map<String, dynamic>> get(
  //     [String? additionalParams, bool? isList]) async {
  //   var headers = await CommonHeaders.createHeaders();
  //   final fullUrl = '$url${additionalParams ?? ''}';
  //
  //   log("URL: $fullUrl");
  //
  //   // Start Firebase Performance metric
  //   final metric = FirebasePerformance.instance.newHttpMetric(
  //     fullUrl,
  //     HttpMethod.Get,
  //   );
  //   await metric.start();
  //
  //   try {
  //     final response = await http.get(Uri.parse(fullUrl), headers: headers);
  //
  //     metric.httpResponseCode = response.statusCode;
  //     metric.responsePayloadSize = response.bodyBytes.length;
  //
  //     if (isList != null && isList) {
  //       return _handleResponse(response, isList);
  //     }
  //     return _handleResponse(response);
  //   } catch (e) {
  //     metric.putAttribute("error", e.toString());
  //     rethrow;
  //   } finally {
  //     await metric.stop();
  //   }
  // }

  /// Sends a POST request to the specified [url] with the provided [body].
  /// Returns a Future containing the decoded JSON response.
  Future<Map<String, dynamic>> post(Map<String, dynamic> body,
      [String? additionalParams]) async {
    var headers = await CommonHeaders.createHeaders();
    final fullUrl = '$url${additionalParams ?? ""}';

    log("URL: $fullUrl");
    log("Body: ${json.encode(body)}");

    // Start Firebase Performance metric
    final metric = FirebasePerformance.instance.newHttpMetric(
      fullUrl,
      HttpMethod.Post,
    );
    await metric.start();

    try {
      final response = await http.post(
        Uri.parse(fullUrl),
        body: json.encode(body),
        headers: headers,
      );

      metric.httpResponseCode = response.statusCode;
      metric.responsePayloadSize = response.bodyBytes.length;

      return _handleResponse(response);
    } catch (e) {
      metric.putAttribute("error", e.toString());
      rethrow;
    } finally {
      await metric.stop();
    }
  }

  // Future<Map<String, dynamic>> get(
  //     [String? additionalParams, bool? isList]) async {
  //   var headers = await CommonHeaders.createHeaders();
  //   // log("Headers: $headers");
  //   log("URL: $url${additionalParams ?? ''}");
  //   final response = await http.get(Uri.parse('$url${additionalParams ?? ''}'),
  //       headers: headers);
  //   if (isList != null && isList) {
  //     return _handleResponse(response, isList);
  //   }
  //   return _handleResponse(response);
  // }
  //
  // /// Sends a POST request to the specified [url] with the provided [body].
  // /// Returns a Future containing the decoded JSON response.
  // Future<Map<String, dynamic>> post(Map<String, dynamic> body,
  //     [String? additionalParams]) async {
  //   var headers = await CommonHeaders.createHeaders();
  //   // log("Headers: $headers");
  //   log("URL: $url");
  //   log("Body: ${json.encode(body)}");
  //   final response = await http.post(
  //     Uri.parse('$url${additionalParams ?? ""}'),
  //     body: json.encode(body),
  //     headers: headers,
  //   );
  //   print("Response: ${response.body}");
  //   print("Response Code: ${response.statusCode}");
  //   log("Response: ${response.body}");
  //   return _handleResponse(response);
  // }

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
    // log("Headers: $headers");
    log("URL: $url");
    log("Body: $body");
    final response = await http.delete(Uri.parse(url),
        body: json.encode(body), headers: headers);
    log("Response: ${response.body}");
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> deleteUser() async {
    var headers = await CommonHeaders.createHeaders();
    log("DELETE URL: $url");

    final response = await http.delete(
      Uri.parse(url),
      headers: headers,
    );

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
  Future<Map<String, dynamic>> postMultiPartSOVAccounts(
      File filePath, String accountId, String name) async {
    await FirebaseAuth.instance.currentUser?.reload();
    IdTokenResult? token =
        await FirebaseAuth.instance.currentUser?.getIdTokenResult();
    var headers = {
      'Authorization': 'Bearer ${token?.token ?? ""}',
      'Content-Type': 'multipart/form-data',
    };
    var request = http.MultipartRequest(
        'POST', Uri.parse(AppConstant.UPLOAD_SOV_ACCOUNT + '/upload'));
    request.fields.addAll(
        {'sov_name': name, 'account_id': accountId, 'device': 'mobile'});
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
      return _handleResponse(
          http.Response(responseData, streamedResponse.statusCode));
    } else {
      String responseData = await streamedResponse.stream.bytesToString();
      print(responseData);
      throw BackendException(
          responseData ?? "An error occurred", streamedResponse.statusCode);
    }
  }

  Future<Map<String, dynamic>> postMultiPartSOVSubAccounts(
      File filePath, String accountId, String subAccountId, String name) async {
    await FirebaseAuth.instance.currentUser?.reload();
    IdTokenResult? token =
        await FirebaseAuth.instance.currentUser?.getIdTokenResult();
    var headers = {
      'Authorization': 'Bearer ${token?.token ?? ""}',
      'Content-Type': 'multipart/form-data',
    };
    var request = http.MultipartRequest(
        'POST', Uri.parse(AppConstant.UPLOAD_SOV_ACCOUNT + '/upload'));
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
      return _handleResponse(
          http.Response(responseData, streamedResponse.statusCode));
    } else {
      String responseData = await streamedResponse.stream.bytesToString();
      print(responseData);
      throw BackendException(
          responseData ?? "An error occurred", streamedResponse.statusCode);
    }
  }

  Future<Map<String, dynamic>> postMultiPartSOVPartial(
      File filePath,
      String accountId,
      String subAccountId,
      String sovId,
      String tags,
      String sovName) async {
    await FirebaseAuth.instance.currentUser?.reload();
    IdTokenResult? token =
        await FirebaseAuth.instance.currentUser?.getIdTokenResult();
    var headers = {
      'Authorization': 'Bearer ${token?.token ?? ""}',
      'Content-Type': 'multipart/form-data',
    };
    var request = http.MultipartRequest(
        'POST', Uri.parse(AppConstant.UPLOAD_SOV_LOCATIONS));
    var body;
    if (sovName.isNotEmpty) {
      body = {
        //  'data': {
        'account_id': accountId,
        'sub_account_id': subAccountId,
        "name": sovName,
        "new": sovName.isNotEmpty ? 'true' : 'false',
        "add_to_sov": sovName.isNotEmpty ? 'true' : 'false',
        'sov_id': sovId,
        'tags': tags,
        //   }
      };
    } else {
      body = {
        //  'data': {
        'account_id': accountId,
        'sub_account_id': subAccountId,
        "name": sovName,
        "new": 'false',
        "add_to_sov": 'false',
        'sov_id': sovId,
        //   }
      };
    }
    request.fields.addAll(body);
    print("Request Fields: ${request.fields}");
    print("Request Files path: ${filePath.path}");
    request.files.add(await http.MultipartFile.fromPath('file', filePath.path));
    print("Request Files: ${request.files}");
    request.headers.addAll(headers);
    log("Request headers: ${request.headers}");
    print('url: ${request.url}');

    http.StreamedResponse streamedResponse = await request.send();

    print("Response Code: ${streamedResponse.statusCode}");
    print("Response Reason: ${streamedResponse.reasonPhrase}");
    if (streamedResponse.statusCode == 200) {
      String responseData = await streamedResponse.stream.bytesToString();
      print(responseData);
      return _handleResponse(
          http.Response(responseData, streamedResponse.statusCode));
    } else {
      String responseData = await streamedResponse.stream.bytesToString();
      print(responseData);
      throw BackendException(
          responseData ?? "An error occurred", streamedResponse.statusCode);
    }
  }

  Future<Map<String, dynamic>> postMultiPartLocationProfile(
      File filePath,
      String accountId,
      String subAccountId,
      String sovId,
      String locationId,
      String name) async {
    await FirebaseAuth.instance.currentUser?.reload();
    IdTokenResult? token =
        await FirebaseAuth.instance.currentUser?.getIdTokenResult();
    var headers = {
      'Authorization': 'Bearer ${token?.token ?? ""}',
      'Content-Type': 'multipart/form-data',
    };
    var request = http.MultipartRequest(
        'POST', Uri.parse(AppConstant.UPLOAD_IMAGES_NEW + "/$locationId"));
    request.fields.addAll({
      'location_id': locationId,
    });
    print("Request Fields: ${request.fields}");
    print("Request Files path: ${filePath.path}");
    request.files.add(await http.MultipartFile.fromPath(
        'file_${DateTime.now().millisecondsSinceEpoch}', filePath.path));
    print("Request Files: ${request.files}");
    request.headers.addAll(headers);
    log("Request headers: ${request.headers}");

    http.StreamedResponse streamedResponse = await request.send();

    if (streamedResponse.statusCode == 200) {
      String responseData = await streamedResponse.stream.bytesToString();
      print(responseData);
      return _handleResponse(
          http.Response(responseData, streamedResponse.statusCode));
    } else {
      String responseData = await streamedResponse.stream.bytesToString();
      print("Reason" + responseData);
      throw BackendException(
          responseData ?? "An error occurred", streamedResponse.statusCode);
    }
  }

  Future<http.StreamedResponse> downloadFile(
      String url, Map<String, dynamic> body) async {
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
  Future<Map<String, dynamic>> _handleResponse(http.Response response,
      [bool? isList]) async {
    final statusCode = response.statusCode;
    final body = response.body;
    log("Status Code: $statusCode");
    log("Response Body: $body");
    await AuthNotifier().getAllClaims();

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
