import 'dart:convert';
import 'dart:developer';
import 'package:RiskSphere/models/TransactionModel.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../design_system/primitives/custom_typography.dart';
import '../screens/payments/paymentScreen.dart';
import '../service/api_service.dart';
import '../utils/api_constants.dart';
import '../utils/common_headers.dart';

class PaymentProvider extends ChangeNotifier {
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  SessionData? _sessionData;

  SessionData? get sessionData => _sessionData;

  String? _paymentIntent;

  String? get paymentIntent => _paymentIntent;
  String? _invoiceId;

  String? get invoiceId => _invoiceId;

  List<Plans> _plan = [];

  List<Plans> get plan => _plan;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setSessionData(SessionData data) {
    _sessionData = data;
    notifyListeners();
  }

  void _setPaymentIntent(String? intent) {
    _paymentIntent = intent;
    notifyListeners();
  }

  void _setInvoiceId(String? intent) {
    _invoiceId = intent;
    notifyListeners();
  }

  List<Result> _transactions = [];

  List<Result> get transactions => _transactions;

  void setTransactionData(List<Result> data) {
    _transactions = data;
    notifyListeners();
  }

  void setPlanData(List<Plans> data) {
    _plan = data;
    notifyListeners();
  }

  Future<void> makePaymentsuccess({required String sessionId}) async {
    _setLoading(true);
    try {
      final paymentIntentData = await _createCheckoutSuccess(
        sessionId: sessionId,
      );
    } catch (e) {
      debugPrint(" Payment Error: ${e.toString()}");
    } finally {
      _setLoading(false);
    }
  }

  Future<void> makePayment({
    required BuildContext context,
    required String amount,
    required String currency,
    required Map<String, dynamic> summary,
    String? hazardName,
    String? vendorName,
  }) async {
    _setLoading(true);
    try {
      final paymentIntentData = await _createPaymentIntent(
          amount, currency, summary, hazardName!, vendorName);
      if (paymentIntentData != null &&
          paymentIntentData['session'] != null &&
          paymentIntentData['session']['url'] != null &&
          paymentIntentData['session']['id'] != null) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Paymentscreen(
              paymentUrl: paymentIntentData['session']['url'],
              paymentSuccessUrl: paymentIntentData['session']['id'],
            ),
          ),
        );
      } else {
        throw Exception("Invalid payment intent data");
      }
    } catch (e) {
      debugPrint(" Payment Error: ${e.toString()}");
      print("Invalid payment intent data");
      _showSnackBar(context, "Invalid payment intent data");
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>?> _createPaymentIntent(
    String amount,
    String currency,
    Map<String, dynamic> summary,
    String hazardName,
    String? vendorName,
  ) async {
    try {
      print("createPaymentIntent");
      final sessionData = await _createCheckoutSession(
        amount: amount,
        currency: currency,
        summary: summary,
        hazardName: hazardName,
        vendorName: vendorName,
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
    String? hazardName,
    String? vendorName,
  }) async {
    final Uri url = Uri.parse(AppConstant.PAYMNET_GATEWAY_URL);
    final headers = await CommonHeaders.createHeaders();
    print("object");
    print(summary['planId']);
    final requestBody = {
      "data": {
        "amount": double.parse(amount) * 100,
        // "currency": currency,
        "plans": List.generate(
          summary['planId']?.length ?? 0,
          (i) {
            String planTypeId = summary['planType']?[i] ?? "";
            Map<String, dynamic> plan = {
              "plan_id": summary['planId']?[i] ?? "",
              "plan_type_id": planTypeId,
              "plan_type":
                  summary['selectedPlanType']?[i]?.toString().toLowerCase() ??
                      "",
              "selected_plan": summary['usercount']?[i] ?? "",
              "plan_name": summary['titles']?[i] ?? "",
              "price": summary['licenseprice']?[i] ?? "",
            };

            if (planTypeId == "event_cost") {
              plan["vendor"] = vendorName ?? "";
              plan["event_type"] = hazardName ?? "";
            }

            return plan;
          },
        ),

        // "plans": List.generate(
        //     summary['planId']?.length ?? 0,
        //     (i) => {
        //           "plan_id": summary['planId']?[i] ?? "",
        //           "plan_type_id": summary['planType']?[i] ?? "",
        //           "plan_type": summary['selectedPlanType']?[i]
        //                   ?.toString()
        //                   .toLowerCase() ??
        //               "",
        //           "selected_plan": summary['usercount']?[i] ?? "",
        //           "plan_name": summary['titles']?[i] ?? "",
        //           "price":amount, //summary['licenseprice']?[i] ?? "",
        //       "vendor": summary['planType']?[i] == "event_cost" ? (vendorName ?? "") : "",
        //       "event_type": summary['planType']?[i] == "event_cost" ? (hazardName ?? "") : "",
        //
        //         }),
      }
    };
    print(requestBody);

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(requestBody),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to create checkout session: ${response.body}',
      );
    } else if (response.statusCode == 500) {
      throw Exception('Internal Server Error: ${response.body}');
    }
    final Map<String, dynamic> jsonBody = jsonDecode(response.body);
    return jsonBody;
  }

  Future<Map<String, dynamic>> _createCheckoutSuccess({
    required String sessionId,
  }) async {
    _setLoading(true);
    try {
      final Uri url = Uri.parse(AppConstant.PAYMNET_DETAILS_URL);
      final headers = await CommonHeaders.createHeaders();

      final requestBody = {
        "data": {"session_id": sessionId},
      };

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(requestBody),
      );

      final Map<String, dynamic> jsonBody = jsonDecode(response.body);

      if (response.statusCode != 200) {
        log('Error: ${jsonBody['message']}');
        throw Exception(
            'Failed to create checkout session: ${jsonBody['message']}');
      }

      log('Success: Checkout session created successfully');
      log('Response: $jsonBody');

      final paymentInfo = TransactionModel.fromJson(jsonBody);
      _setPaymentIntent(paymentInfo.paymentIntent);
      _setInvoiceId(paymentInfo.invoiceId);
      setPlanData(paymentInfo.plans ?? []);

      if (paymentInfo.sessionData != null) {
        setSessionData(paymentInfo.sessionData!);
      }

      return jsonBody;
    } catch (e) {
      log('Exception in createCheckoutSession: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchTransactionList(
      BuildContext context, String? value, String? date) async {
    final typography = CustomTypography(context);

    _isLoading = true;
    notifyListeners();

    try {
      ApiService apiService = ApiService(AppConstant.GET_Transaction_LIST +
          (date != null && date.isNotEmpty
              ? date
              : (value != null ? '?plan_type_id=$value' : '')));

      var response = await apiService.get('');
      log('API response: $response');
      TransactionModel transactionListData =
          TransactionModel.fromJson(response);

      _transactions = transactionListData.result ?? [];

      log(' Success: Transaction list fetched successfully. Total records: ${_transactions.length}');

      _isLoading = false;
      notifyListeners();
    } on BackendException catch (e, stackTrace) {
      print(stackTrace);
      _isLoading = false;
      notifyListeners();
      log(' BackendException: ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message, style: typography.Body1),
      ));
    } catch (e, stackTrace) {
      print(stackTrace);
      _isLoading = false;
      notifyListeners();
      log(' Exception: ${e.toString()}');
    }
  }
}
