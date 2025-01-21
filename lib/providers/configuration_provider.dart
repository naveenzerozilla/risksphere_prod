
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:green/service/api_service.dart';

import '../design_system/primitives/custom_typography.dart';
import '../utils/api_constants.dart';

class ConfigurationProvider extends ChangeNotifier {

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  set isLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Map<String, dynamic> _configurations = {};
  Map<String, dynamic> get configurations => _configurations;
  set configurations(Map<String, dynamic> value) {
    _configurations = value;
    notifyListeners();
  }

  Map<String, dynamic> _vendors = {};
  Map<String, dynamic> get vendors => _vendors;
  set vendors(Map<String, dynamic> value) {
    _vendors = value;
    notifyListeners();
  }

  // Get API for configuration
  Future<void> getConfiguration(
      {String? accountId, String? subAccountId}) async {
    try {
      isLoading = true;
      ApiService apiService = ApiService(AppConstant.CONFIGURATIONS);
      if (accountId != null && subAccountId != null) {
        apiService = ApiService(
            '${AppConstant.CONFIGURATIONS}?account_id=$accountId&sub_account_id=$subAccountId');
      } else if (accountId != null) {
        apiService = ApiService('${AppConstant.CONFIGURATIONS_ACCOUNTS}?account_id=$accountId');
      } else {
        apiService = ApiService(AppConstant.CONFIGURATIONS);
      }

      var response = await apiService.get();
      log(response.toString());
      configurations = response;
    } catch (e) {
      print(e);
    } finally {
      isLoading = false;
    }
  }

  // Get API for vendors
  Future<void> getVendors() async {
    try {
      isLoading = true;
      ApiService apiService = ApiService(AppConstant.VENDOR_MANAGEMENT_URL);
      var response = await apiService.get();
      log(response.toString());
      vendors = response;

    } catch (e) {
      print(e);
    } finally {
      isLoading = false;
    }
  }

  Future<void> updateConfiguration(
      BuildContext context,
      String id,
      String key,
      String level,
      dynamic value, {
        String? accountId,
        String? subAccountId,
      }) async {
    var typography = CustomTypography(context);
    try {
      isLoading = true;

      ApiService apiService = ApiService(AppConstant.UPDATE_CONFIGURATION);
      var body = {
        "id": id,
        "key": key,
        "value": value,
        "level": "global", // Include level
        "update_all": true // Include update_all
      };

      var response = await apiService.patch(body); // Assuming PATCH is correct
      log(response.toString());

      // Refresh Configuration after update
      await getConfiguration(accountId: accountId, subAccountId: subAccountId);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Configuration updated successfully!',
            style: typography.Body1),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to update configuration: $e',
            style: typography.Body1),
      ));
    } finally {
      isLoading = false;
    }
  }




  String getConfigurationUrl({String? accountId, String? subAccountId, required String level}) {
    String baseUrl = AppConstant.CONFIGURATIONS;  // Base URL
    if (level != 'account' && level != 'sub_account' && level != 'global') {
      throw Exception("Invalid level");
    }
    if (accountId != null && subAccountId != null) {
      return '$baseUrl/$level?account_id=$accountId&sub_account_id=$subAccountId';
    } else if (accountId != null) {
      return '$baseUrl/$level?account_id=$accountId';
    } else {
      return '$baseUrl/$level';
    }
  }

  String patchConfigurationUrl({String? accountId, String? subAccountId}) {
    String baseUrl = AppConstant.UPDATE_CONFIGURATION;
    if (accountId != null && subAccountId != null) {
      return '$baseUrl?account_id=$accountId&sub_account_id=$subAccountId';
    } else if (accountId != null) {
      return '$baseUrl?account_id=$accountId';
    } else {
      return baseUrl;
    }
  }


}