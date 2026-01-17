import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:RiskSphere/service/api_service.dart';

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
      {String? accountId, String? subAccountId, String? updateallflag}) async {
    try {
      isLoading = true;
      ApiService apiService = ApiService(AppConstant.CONFIGURATIONS);
      if (accountId != null &&
          subAccountId != null &&
          updateallflag != "false") {
        apiService = ApiService(
            '${AppConstant.CONFIGURATIONS}?account_id=$accountId&sub_account_id=$subAccountId');
      } else if (accountId != null && updateallflag != "false") {
        apiService = ApiService(
            '${AppConstant.CONFIGURATIONS_ACCOUNTS}?account_id=$accountId');
      } else if (updateallflag == "false") {
        apiService = ApiService(
            '${AppConstant.CONFIGURATIONS_SUB_ACCOUNTS}?account_id=$accountId&sub_account_id=$subAccountId');
      } else {
        apiService = ApiService(AppConstant.CONFIGURATIONS);
      }

      var response = await apiService.get();

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
    bool value,
    dynamic status, {
    String? accountId,
    String? subAccountId,
    String? checklevel,
  }) async {
    var typography = CustomTypography(context);
    try {
      isLoading = true;

      ApiService apiService = ApiService(AppConstant.UPDATE_CONFIGURATION);
      var body = checklevel == "local"
          ? {
              "account_id": accountId,
              "id": id,
              "key": key,
              "level": level, // Include level
              "sub_account_id": subAccountId,
              "value": value,
            }
          : {
              "id": id,
              "key": key,
              "level": level,
              "update_all": status,
              "value": value,
            };

      var response = await apiService.patch(body); // Assuming PATCH is correct
      log(response.toString());

      await getConfiguration(accountId: accountId, subAccountId: subAccountId);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Configuration updated successfully!',
            style: TextStyle(color: Colors.black)),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text('Failed to update configuration: $e', style: typography.Body1),
      ));
    } finally {
      isLoading = false;
    }
  }

  Future<void> updateAccountNameConfigurations(
    BuildContext context,
    String accountName,

  ) async {
    var typography = CustomTypography(context);

    try {
      isLoading = true;
      notifyListeners();

      ApiService apiService = ApiService(AppConstant.UPDATE_ACCOUNT_NAME);

      final body = {
        "account_name": accountName,

      };

      final response = await apiService.patch(body);
      log(response.toString());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Company global configuration updated successfully.',
            style: TextStyle(color: Colors.black),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update global configuration',
            style: typography.Body1,
          ),
        ),
      );
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateSubAccountNameConfigurations(
    BuildContext context,
    String? subAccountName,
  ) async {
    var typography = CustomTypography(context);

    try {
      isLoading = true;
      notifyListeners();

      ApiService apiService = ApiService(AppConstant.UPDATE_ACCOUNT_NAME);

      final body = {
        "sub_account_name": subAccountName, // 👈 PAYLOAD UPDATED
      };

      final response = await apiService.patch(body);
      log(response.toString());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Company global configuration updated successfully.',
            style: TextStyle(color: Colors.black),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update global configuration',
            style: typography.Body1,
          ),
        ),
      );
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  String getConfigurationUrl(
      {String? accountId, String? subAccountId, required String level}) {
    String baseUrl = AppConstant.CONFIGURATIONS; // Base URL
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
