import 'dart:developer';
import 'package:RiskSphere/models/TransactionModel.dart' hide Result;
import 'package:flutter/material.dart';
import '../design_system/primitives/custom_typography.dart';
import '../models/invoice_model.dart';
import '../service/api_service.dart';
import '../utils/api_constants.dart';

class InvoiceProvider extends ChangeNotifier {
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

  Future<void> fetchInvoiceList(BuildContext context,String? value) async {
    final typography = CustomTypography(context);

    _isLoading = true;
    notifyListeners();

    try {
      ApiService apiService = ApiService(AppConstant.GET_INVOICE_LIST+(value != null ? '?plan_type_id=$value' : ''));
      var response = await apiService.get('');

      log('API response: $response');
      Invoicemodel transactionListData = Invoicemodel.fromJson(response);

      _transactions = transactionListData.result ?? [];

      log('✅ Success: Transaction list fetched successfully. Total records1: ${_transactions.length}');

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
