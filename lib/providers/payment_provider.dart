import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:url_launcher/url_launcher.dart';

import '../design_system/primitives/custom_typography.dart';
import '../service/api_service.dart';
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
      print(paymentIntentData!['client_secret']);
      print("paymentIntentData!['client_secret']");
      if (paymentIntentData == null ||
          paymentIntentData['client_secret'] == null) {
        throw Exception("Stripe client_secret is missing.");
      }

      final clientSecret = paymentIntentData['client_secret'];
      debugPrint("Client Secret: $clientSecret");

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'RiskSphere',
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      // ✅ Log full payment data after success
      debugPrint("✅ Payment completed successfully.");
      final encoder = JsonEncoder.withIndent('  ');
      debugPrint(encoder.convert(paymentIntentData));

      _showSnackBar(context, "Payment successful!");
      _navigateToSuccessScreen(context);
    } catch (e) {
      debugPrint("❌ Payment Error: ${e.toString()}");
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

  void _navigateToSuccessScreen(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text("Payment Success")),
          body: const Center(child: Text("Thank you for your payment!")),
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _createCheckoutSession({
    required String amount,
    required String currency,
    required Map<String, dynamic> summary,
  }) async {
    final Uri url = Uri.parse(
        AppConstant.PAYMNET_GATEWAY_URL); // Make sure the URL is valid

    var headers = await CommonHeaders.createHeaders();

    final requestBody = {
      "data": {
        "amount": int.parse(amount) * 100,
        "currency": currency,
        "plans": List.generate(summary['planId']?.length ?? 0, (index) {
          return {
            "plan_id": summary['planId']?[index] ?? "",
            "plan_type":
                summary['selectedPlanType']?[index]?.toString().toLowerCase() ??
                    "",
            "selected_plan": summary['usercount']?[index] ?? "",
            "plan_name": summary['titles']?[index] ?? "",
            "price": summary['licenseprice']?[index] ?? "",
          };
        }),
      }
    };
    print("requestBody");
    print(requestBody);

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(requestBody),
    );

    if (response.statusCode != 200) {
      print(response.statusCode);
      print(response);
      throw Exception('Failed to create checkout session: ${response.body}');
    }
    print("response.body");
    print(response.body);
    final Map<String, dynamic> jsonBody = jsonDecode(response.body);
    print("response.body");
    print(jsonBody['session_id'].toString());
    print(jsonBody['client_secret'].toString());
    print(jsonBody['url_mode'].toString());
    print(jsonBody['url'].toString());
    print(jsonBody['session'].toString());
    print(jsonBody['session']['customer_details'].toString());
    print(jsonBody['session']['url'].toString());

    print("response.body");
    return jsonDecode(response.body);
  }

  Future<void> startCheckout({
    required String amount,
    required String currency,
    required Map<String, dynamic> summary,
  }) async {
    try {
      final sessionData = await _createCheckoutSession(
        amount: amount,
        currency: currency,
        summary: summary,
      );
      print(sessionData);
      print("sessionData");
      createPaymentIntent(
        amount: amount,
        currency: currency,
        summary: summary,
      );

      // final String sessionId = sessionData['id'];
      // createPaymentIntent
      // final String checkoutUrl = "https://checkout.stripe.com/pay/$sessionId";
      //
      // final uri = Uri.parse(checkoutUrl);
      // if (await canLaunchUrl(uri)) {
      //   await launchUrl(uri, mode: LaunchMode.externalApplication);
      // } else {
      //   throw 'Could not launch Stripe Checkout URL';
      // }
    } catch (e) {
      debugPrint('Error during checkout: $e');
    }
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
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization':
              'Bearer sk_test_51RWO7ARtw6KU9heKR9SYZEqGyhQkzhLFO31YZ40e2LqKec5MAdvzP7Xwgj26b66QRVGETt9dhJjzsVo56tzm2T4X00yCZMH6Io',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'amount': (int.parse(amount) * 100).toString(), // Stripe uses cents
          'currency': currency,
          'payment_method_types[]': 'card',
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
}

// class PaymentProvider extends ChangeNotifier {
//   bool _isLoading = false;
//
//   bool get isLoading => _isLoading;
//
//   void _setLoading(bool value) {
//     _isLoading = value;
//     notifyListeners();
//   }
//
//   Future<void> makePayment({
//     required BuildContext context,
//     required String amount,
//     required String currency,
//     required Map<String, dynamic> summary,
//   }) async {
//     _setLoading(true);
//     try {
//       final paymentIntentData =
//           await _createPaymentIntent(amount, currency, summary);
//       print(paymentIntentData['']);
//       print("paymentIntentData.toString()");
//       final clientSecret = paymentIntentData['client_secret'];
//
//       if (clientSecret == null) {
//         throw Exception("Stripe client_secret is missing.");
//       }
//       print("object");
//       print(clientSecret);
//       await Stripe.instance.initPaymentSheet(
//         paymentSheetParameters: SetupPaymentSheetParameters(
//           paymentIntentClientSecret: clientSecret,
//           merchantDisplayName: 'RiskSphere',
//         ),
//       );
//
//       await Stripe.instance.presentPaymentSheet();
//       // ✅ Log the full response after success
//       debugPrint("✅ Payment completed successfully.");
//       debugPrint("🔽 Full PaymentIntent Response:");
//       debugPrint(paymentIntentData.toString(), wrapWidth: 5024);
//       final encoder = JsonEncoder.withIndent('  ');
//       final prettyString = encoder.convert(paymentIntentData);
//       debugPrint(prettyString);
//       paymentIntentData.forEach((key, value) {
//         debugPrint("$key: $value");
//       });
//
//       _showSnackBar(context, "Payment successful!");
//       _navigateToSuccessScreen(context);
//     } catch (e) {
//       print(e..toString());
//       _showSnackBar(context, "Payment failed");
//     } finally {
//       _setLoading(false);
//     }
//   }
//
//   Future<Map<String, dynamic>?> _createPaymentIntent(
//       String amount, String currency, Map<String, dynamic> summary) async {
//     return await startCheckout(
//         amount: amount, currency: currency, summary: summary);
//   }
//
//   void _showSnackBar(BuildContext context, String message) {
//     ScaffoldMessenger.of(context)
//         .showSnackBar(SnackBar(content: Text(message)));
//   }
//
//   void _navigateToSuccessScreen(BuildContext context) {
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(
//         builder: (_) => Scaffold(
//           appBar: AppBar(title: Text("Payment Success")),
//           body: Center(child: Text("Thank you for your payment!")),
//         ),
//       ),
//     );
//   }
//
//    Future<void> startCheckout({
//     required String amount,
//     required String currency,
//     required Map<String, dynamic> summary,
//   }) async {
//     try {
//       final sessionData = await _createCheckoutSession(
//         amount: amount,
//         currency: currency,
//         summary: summary,
//       );
//
//       final String sessionId = sessionData['id'];
//       final String checkoutUrl = "https://checkout.stripe.com/pay/$sessionId";
//
//       if (await canLaunchUrl(Uri.parse(checkoutUrl))) {
//         await launchUrl(Uri.parse(checkoutUrl), mode: LaunchMode.externalApplication);
//       } else {
//         throw 'Could not launch Stripe Checkout URL';
//       }
//     } catch (e) {
//       print('Error during checkout: $e');
//     }
//   }
//
//   static Future<Map<String, dynamic>> _createCheckoutSession({
//     required String amount,
//     required String currency,
//     required Map<String, dynamic> summary,
//   }) async {
//     final Uri url = Uri.parse(AppConstant.PAYMNET_GATEWAY_URL);
//     final headers = {
//       'Content-Type': 'application/json',
//       'Accept': 'application/json',
//     };
//
//     final requestBody = {
//       "data": {
//         "amount": int.parse(amount) * 100, // Stripe expects smallest currency unit
//         "currency": currency,
//         "plans": List.generate(summary['planId']?.length ?? 0, (index) {
//           return {
//             "plan_id": summary['planId']?[index] ?? "",
//             "plan_type": summary['selectedPlanType']?[index]
//                 ?.toString()
//                 .toLowerCase() ??
//                 "",
//             "selected_plan": summary['usercount']?[index] ?? "",
//             "plan_name": summary['titles']?[index] ?? "",
//             "price": summary['licenseprice']?[index] ?? "",
//           };
//         }),
//       }
//     };
//
//     final response = await http.post(url, headers: headers, body: jsonEncode(requestBody));
//
//     if (response.statusCode != 200) {
//       throw Exception('Failed to create checkout session: ${response.body}');
//     }
//
//     return jsonDecode(response.body);
//   }

// Future<Map<String, dynamic>> createPaymentIntent({
//   required String amount,
//   required String currency,
//   required Map<String, dynamic> summary,
// }) async {
//   try {
//     final response = await http.post(
//       Uri.parse(
//           // 'https://api.stripe.com/v1/payment_intents'
//               "https://checkout.stripe.com/pay/$session_id"
//       ),
//       headers: {
//         'Authorization':
//             'Bearer sk_test_51RWO7ARtw6KU9heKR9SYZEqGyhQkzhLFO31YZ40e2LqKec5MAdvzP7Xwgj26b66QRVGETt9dhJjzsVo56tzm2T4X00yCZMH6Io',
//         'Content-Type': 'application/x-www-form-urlencoded',
//       },
//       body: {
//         "data": {
//           "amount": int.parse(amount) * 100,
//           "plans": List.generate(summary['planId']?.length ?? 0, (index) {
//             return {
//               "plan_id": summary['planId']?[index] ?? "",
//               "plan_type": summary['selectedPlanType']?[index]
//                   ?.toString()
//                   .toLowerCase() ??
//                   "",
//               "selected_plan": summary['usercount']?[index] ?? "",
//               "plan_name": summary['titles']?[index] ?? "",
//               "price": summary['licenseprice']?[index] ?? "",
//             };
//           }),
//         }
//       },
//     );
//
//     print('Stripe response body: ${response.body}');
//     print('Stripe response body: ${response.body}');
//
//     final Map<String, dynamic> body = jsonDecode(response.body);
//
//     if (response.statusCode != 200) {
//       throw Exception('Stripe Error: ${body['error']['message']}');
//     } else {
//       print('Stripe response: $body');
//     }
//
//     return body;
//   } catch (err) {
//     throw Exception(err.toString());
//   }
// }

// Future<Map<String, dynamic>> createPaymentIntent1({
//   required String amount,
//   required String currency,
//   required Map<String, dynamic> summary,
// }) async {
//   try {
//     var headers = await CommonHeaders.createHeaders();
//
//     final requestBody = {
//       "data": {
//         "amount": int.parse(amount) * 100,
//         "plans": List.generate(summary['planId']?.length ?? 0, (index) {
//           return {
//             "plan_id": summary['planId']?[index] ?? "",
//             "plan_type": summary['selectedPlanType']?[index]
//                     ?.toString()
//                     .toLowerCase() ??
//                 "",
//             "selected_plan": summary['usercount']?[index] ?? "",
//             "plan_name": summary['titles']?[index] ?? "",
//             "price": summary['licenseprice']?[index] ?? "",
//           };
//         }),
//       }
//     };
//
//     final body = jsonEncode(requestBody);
//     final url = Uri.parse(AppConstant.PAYMNET_GATEWAY_URL);
//
//     print("Sending payment request to: $url");
//     print("Headers: $headers");
//     print("Body: $body");
//
//     final response = await http.post(url, headers: headers, body: body);
//
//     print("Response Status: ${response.statusCode}");
//     print("Response Body: ${response.body}");
//
//     final Map<String, dynamic> responseData = jsonDecode(response.body);
//
//     if (response.statusCode != 200) {
//       throw Exception(
//           'Stripe Error: ${responseData['error']?['message'] ?? 'Unknown error'}');
//     }
//
//     print('Stripe response: $responseData');
//     return responseData;
//   } on BackendException catch (e, stackTrace) {
//     print("BackendException caught:");
//     print(stackTrace);
//     print(e.message);
//     rethrow;
//   } catch (e, stackTrace) {
//     print("Exception caught:");
//     print(stackTrace);
//     print(e.toString());
//     throw Exception("Failed to create PaymentIntent: ${e.toString()}");
//   }
// }
