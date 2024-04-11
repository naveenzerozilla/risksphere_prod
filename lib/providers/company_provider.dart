import 'dart:convert';
import 'dart:developer';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/company_model.dart';

class CompanyProvider with ChangeNotifier {


  bool _isLoading = false;
  bool get isLoading => _isLoading;
  set isLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  List<CompanyModel> _companies = [];
  List<CompanyModel> get companies => _companies;

  // Get all companies based on search text and filter using firebase user

  Future<List<CompanyModel>> getAllCompanies(String searchText, String filter) async {
    try {
      User user = FirebaseAuth.instance.currentUser!;
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable(
          'user_management');
      final result = await callable.call();
      log('Cloud Function result: ${json.encode(result.data)}');


      // Parse the data as JSON
      final jsonData = json.decode(json.encode(result.data));

      // Convert the JSON data to the expected type
      final data = Map<String, dynamic>.from(jsonData);

      return data['companies'].map<CompanyModel>((company) =>
          CompanyModel.fromJson(company)).toList();
    } catch (e, stackTrace) {
      print('Stack Trace: $stackTrace');
      log('Error: $e');
      return [];
    }
  }
}