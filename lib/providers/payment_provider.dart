import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../screens/paymentScreen.dart';
import '../utils/api_constants.dart';
import '../utils/common_headers.dart';

class PaymentProvider extends ChangeNotifier {
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> makePayment({
    required BuildContext context,
    required String amount,
    required String currency,
    required Map<String, dynamic> summary,
  }) async {
    _setLoading(true);
    try {
      final paymentIntentData =
          await _createPaymentIntent(amount, currency, summary);
      // await createPaymentIntent1(amount: amount, currency: currency);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              Paymentscreen(paymentUrl: paymentIntentData!['session']['url']),
        ),
      );
    } catch (e) {
      debugPrint(" Payment Error: ${e.toString()}");
      _showSnackBar(context, "Payment failed");
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>?> _createPaymentIntent(
    String amount,
    String currency,
    Map<String, dynamic> summary,
  ) async {
    try {
      final sessionData = await _createCheckoutSession(
        amount: amount,
        currency: currency,
        summary: summary,
      );

      return sessionData;
    } catch (e) {
      debugPrint(" Failed to create payment intent: ${e.toString()}");
      return null;
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<Map<String, dynamic>> _createCheckoutSession({
    required String amount,
    required String currency,
    required Map<String, dynamic> summary,
  }) async {
    final Uri url = Uri.parse(AppConstant.PAYMNET_GATEWAY_URL);
    final headers = await CommonHeaders.createHeaders();

    final requestBody = {
      "data": {
        "amount": int.parse(amount) * 100,
        "currency": currency,
        "plans": List.generate(
            summary['planId']?.length ?? 0,
            (i) => {
                  "plan_id": summary['planId']?[i] ?? "",
                  "plan_type": summary['selectedPlanType']?[i]
                          ?.toString()
                          .toLowerCase() ??
                      "",
                  "selected_plan": summary['usercount']?[i] ?? "",
                  "plan_name": summary['titles']?[i] ?? "",
                  "price": summary['licenseprice']?[i] ?? "",
                }),
      }
    };

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(requestBody),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to create checkout session: ${response.body}',
      );
    }
    final Map<String, dynamic> jsonBody = jsonDecode(response.body);
    return jsonBody;
  }

  Future<Map<String, dynamic>> createPaymentIntent({
    required String amount,
    required String currency,
    required Map<String, dynamic> summary,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(
            // 'https://api.stripe.com/v1/payment_intents'
            "https://checkout.stripe.com/pay/"),
        headers: {
          'Authorization':
              'Bearer sk_test_51RWO7ARtw6KU9heKR9SYZEqGyhQkzhLFO31YZ40e2LqKec5MAdvzP7Xwgj26b66QRVGETt9dhJjzsVo56tzm2T4X00yCZMH6Io',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          "data": {
            "amount": int.parse(amount) * 100,
            "plans": List.generate(summary['planId']?.length ?? 0, (index) {
              return {
                "plan_id": summary['planId']?[index] ?? "",
                "plan_type": summary['selectedPlanType']?[index]
                        ?.toString()
                        .toLowerCase() ??
                    "",
                "selected_plan": summary['usercount']?[index] ?? "",
                "plan_name": summary['titles']?[index] ?? "",
                "price": summary['licenseprice']?[index] ?? "",
              };
            }),
          }
        },
      );

      print('Stripe response body: ${response.body}');
      print('Stripe response body: ${response.body}');

      final Map<String, dynamic> body = jsonDecode(response.body);

      if (response.statusCode != 200) {
        throw Exception('Stripe Error: ${body['error']['message']}');
      } else {
        print('Stripe response: $body');
      }

      return body;
    } catch (err) {
      throw Exception(err.toString());
    }
  }

  Future<Map<String, dynamic>> createPaymentIntent1({
    required String amount,
    required String currency,
    required Map<String, dynamic> summary,
  }) async {
    try {
      List<Map<String, dynamic>> plans = List.generate(
        summary['planId']?.length ?? 0,
        (i) => {
          "plan_id": summary['planId']?[i] ?? "",
          "plan_type":
              summary['selectedPlanType']?[i]?.toString().toLowerCase() ?? "",
          "selected_plan": summary['usercount']?[i] ?? "",
          "plan_name": summary['titles']?[i] ?? "",
          "price": summary['licenseprice']?[i] ?? "",
        },
      );

      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/checkout/sessions'),
        headers: {
          'Authorization':
              'Bearer sk_test_51RWO7ARtw6KU9heKR9SYZEqGyhQkzhLFO31YZ40e2LqKec5MAdvzP7Xwgj26b66QRVGETt9dhJjzsVo56tzm2T4X00yCZMH6Io',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'payment_method_types[]': 'card',
          'line_items[0][price_data][currency]': currency,
          'line_items[0][price_data][product_data][name]':
              summary['titles']?[0] ?? 'Product',
          'line_items[0][price_data][unit_amount]':
              (int.parse(amount) * 100).toString(),
          'line_items[0][quantity]': '1',
          'mode': 'payment',
          'success_url': 'https://yourdomain.com/success',
          'cancel_url': 'https://yourdomain.com/cancel',
          'metadata[plans]': jsonEncode(plans),
        },
      );

      final Map<String, dynamic> body = jsonDecode(response.body);
      print(response.body);

      if (response.statusCode != 200) {
        throw Exception('Stripe Error: ${body['error']['message']}');
      }

      return body; // You can use body['id'] as the session ID
    } catch (err) {
      throw Exception(err.toString());
    }
  }
}
