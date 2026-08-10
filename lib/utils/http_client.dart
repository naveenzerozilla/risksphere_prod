import 'package:http/http.dart' as http;
import 'package:firebase_performance/firebase_performance.dart';

import 'appcheckService.dart';

class PerformanceHttpClient extends http.BaseClient {
  final http.Client _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final appCheckToken = await AppCheckService.getToken();
    if (appCheckToken != null) {
      request.headers['X-Firebase-AppCheck'] = appCheckToken;
    }

    final metric = FirebasePerformance.instance.newHttpMetric(
      request.url.toString(),
      _getHttpMethod(request.method),
    );

    await metric.start();

    try {
      final response = await _inner.send(request);
      metric.httpResponseCode = response.statusCode;
      metric.responsePayloadSize = response.contentLength ?? 0;
      return response;
    } catch (e) {
      metric.putAttribute("error", e.toString());
      rethrow;
    } finally {
      await metric.stop();
    }
  }

  HttpMethod _getHttpMethod(String method) {
    switch (method.toUpperCase()) {
      case 'POST':
        return HttpMethod.Post;
      case 'PUT':
        return HttpMethod.Put;
      case 'DELETE':
        return HttpMethod.Delete;
      case 'PATCH':
        return HttpMethod.Patch;
      case 'GET':
      default:
        return HttpMethod.Get;
    }
  }
}
