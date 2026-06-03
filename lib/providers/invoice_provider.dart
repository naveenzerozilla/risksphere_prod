import 'dart:developer';
import 'package:RiskSphere/models/TransactionModel.dart' hide Result;
import 'package:flutter/material.dart';
import '../design_system/primitives/custom_typography.dart';
import '../models/invoice_model.dart';
import '../service/api_service.dart';
import '../utils/api_constants.dart';

class InvoiceProvider extends ChangeNotifier {
  bool isHazardLoading = false;
  bool isLocalLoading = false;

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  SessionData? _sessionData;

  SessionData? get sessionData => _sessionData;

  String? _paymentIntent;

  String? get paymentIntent => _paymentIntent;
  String? _invoiceId;

  String? get invoiceId => _invoiceId;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setSessionData(SessionData data) {
    _sessionData = data;
    notifyListeners();
  }

  List<Result> _transactions = [];

  List<Result> get transactions => _transactions;

  void setTransactionData(List<Result> data) {
    _transactions = data;
    notifyListeners();
  }

  Future<void> fetchInvoiceList(BuildContext context, String? value) async {
    final typography = CustomTypography(context);

    _isLoading = true;
    notifyListeners();

    try {
      ApiService apiService = ApiService(AppConstant.GET_INVOICE_LIST +
          (value != null ? '?plan_type_id=$value' : ''));
      var response = await apiService.get('');

      log('API response: $response');
      Invoicemodel transactionListData = Invoicemodel.fromJson(response);

      _transactions = transactionListData.result ?? [];

      log(' Success: Transaction list fetched successfully. Total records1: ${_transactions.length}');

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

  List<ParameterItem> hazardHubList = [];

  Future<void> fetchHazardHubParameter(
      BuildContext context, String? value) async {
    final typography = CustomTypography(context);

    isHazardLoading = true;
    notifyListeners();

    try {
      ApiService apiService = ApiService(AppConstant.GET_HAZARDHUB_LIST);
      var response = await apiService.get('');

      ParameterResponse data = ParameterResponse.fromJson(response);
      hazardHubList = data.items ?? [];

      log(' HazardHub count: ${hazardHubList.length}');
    } on BackendException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message, style: typography.Body1)),
      );
    } catch (e) {
      log('Exception: ${e.toString()}');
    } finally {
      isHazardLoading = false;
      notifyListeners();
    }
  }

  List<ParameterItem> localList = [];
  List<ParameterItem>
  existingParameterList = [];

  bool isExistingParameterLoading = false;
  Future<void> fetchRiskParameter(BuildContext context, String? value) async {
    final typography = CustomTypography(context);

    isLocalLoading = true;
    notifyListeners();

    try {
      ApiService apiService = ApiService(AppConstant.GET_RISKSPHERE_LIST);
      var response = await apiService.get('');

      ParameterResponse data = ParameterResponse.fromJson(response);
      localList = data.items ?? [];

      log(' RiskSphere count: ${localList.length}');
    } on BackendException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message, style: typography.Body1)),
      );
    } catch (e) {
      log('Exception: ${e.toString()}');
    } finally {
      isLocalLoading = false;
      notifyListeners();
    }
  }

  bool isLinkParameterLoading = false;

  Future<bool> linkParameter(
    BuildContext context, {
    required int keyIndex,
    required List<ParameterItem> hazards,
    required List<ParameterItem> locals,
  }) async {
    var typography = CustomTypography(context);

    if (isLinkParameterLoading) return false;

    try {
      isLinkParameterLoading = true;
      notifyListeners();

      ApiService apiService = ApiService(
        AppConstant.PARAMETER_CONFIRM_API,
      );

      final payload = {
        "vendor_response_key": "hazard_hub",

        "key_id": keyIndex+1,

        "key_name": hazards.map((e) => e.name).toList(),

        "data_paramters": locals
            .map(
              (e) => {
                "data_category_id": e.id,
                "data_category_name": e.name,
                "vendor_key": "hazard_hub",
              },
            )
            .toList(),
      };

      log("PARAMETER PAYLOAD: $payload");

      final response = await apiService.patch(payload);

      log("PARAMETER RESPONSE: $response");

      return true;
    } on BackendException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.message,
            style: typography.Body1,
          ),
        ),
      );

      return false;
    } catch (e, stack) {
      log("LINK PARAMETER ERROR: $e");
      log("STACK: $stack");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString(),
            style: typography.Body1,
          ),
        ),
      );

      return false;
    } finally {
      isLinkParameterLoading = false;
      notifyListeners();
    }
  }
}
