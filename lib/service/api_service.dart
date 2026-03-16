import 'dart:developer';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:http/http.dart' as http;
import '../utils/global_imports.dart';

class ApiService {
  final String endpoint;

  ApiService(this.endpoint);

  String get url => '$endpoint';

  Future<Map<String, dynamic>> get(
      [String? additionalParams, bool? isList]) async {
    var headers = await CommonHeaders.createHeaders();
    final fullUrl = '$url${additionalParams ?? ''}';

    log("URL: $fullUrl");

    // Create a custom trace
    final trace = FirebasePerformance.instance.newTrace("get_api_call");
    await trace.start();

    // Start HTTP metric
    final metric =
        FirebasePerformance.instance.newHttpMetric(fullUrl, HttpMethod.Get);
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

  Future<Map<String, dynamic>> put(Map<String, dynamic> body) async {
    var headers = await CommonHeaders.createHeaders();
    final response = await http.put(
      Uri.parse('$url'),
      body: json.encode(body),
      headers: headers,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> delete1(Map<String, dynamic> body) async {
    final uri = Uri.parse(url);

    final headers = await CommonHeaders.createHeaders1();

    final encodedBody = jsonEncode(body);

    log("🗑️ DELETE URL: $url");
    log("🗑️ DELETE Headers: $headers");
    log("🗑️ DELETE Body Sending: $encodedBody");

    final request = http.Request("DELETE", uri);

    // ✅ Ensure JSON headers are not overridden
    request.headers.clear();
    request.headers.addAll({
      ...headers,
      "Content-Type": "application/json",
      "Accept": "application/json",
    });

    // ✅ Explicitly assign encoded body
    request.body = encodedBody;

    // 🔥 IMPORTANT: Set content length manually (some servers require this)
    request.headers["Content-Length"] =
        utf8.encode(encodedBody).length.toString();

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    log("🗑️ DELETE Status: ${response.statusCode}");
    log("🗑️ DELETE Response: ${response.body}");

    return _handleResponse(response);
  }

  // Future<Map<String, dynamic>> delete1(Map<String, dynamic> body) async {
  //   var headers = await CommonHeaders.createHeaders1();
  //   // log("Headers: $headers");
  //   log("URL: $url");
  //   log("Body: $body");
  //   final response = await http.delete(Uri.parse(url),
  //       body: json.encode(body), headers: headers);
  //   log("Response: ${response.body}");
  //   return _handleResponse(response);
  // }

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

    request.files.add(await http.MultipartFile.fromPath('file', filePath.path));

    request.headers.addAll(headers);

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

  Future<Map<String, dynamic>> postMultiPartSOVPartial(
    File filePath,
    String accountId,
    String subAccountId,
    String sovId,
    String tags,
    String sovName,
    BuildContext context,
  ) async {
    var typography = CustomTypography(context);
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
        'account_id': accountId,
        'sub_account_id': subAccountId,
        "name": sovName,
        "new": 'false',
        "add_to_sov": 'false',
        'sov_id': sovId,
      };
    }
    request.fields.addAll(body);

    request.files.add(await http.MultipartFile.fromPath('file', filePath.path));

    request.headers.addAll(headers);

    http.StreamedResponse streamedResponse = await request.send();

    print("Response Code: ${streamedResponse.statusCode}");
    print("Response Reason: ${streamedResponse.reasonPhrase}");

    if (streamedResponse.statusCode == 200) {
      String responseData = await streamedResponse.stream.bytesToString();

      return _handleResponse(
          http.Response(responseData, streamedResponse.statusCode));
    } else {
      String responseData = await streamedResponse.stream.bytesToString();

      final decoded = jsonDecode(responseData);
      final errorMessage = decoded['error'] ?? 'Something went wrong';
      print(errorMessage);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage, style: TextStyle(color: Colors.black)),
        ),
      );
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

class BackendException implements Exception {
  final String message;
  final int statusCode;

  BackendException(this.message, this.statusCode);

  @override
  String toString() {
    return 'BackendException: $message (Status Code: $statusCode)';
  }
}
