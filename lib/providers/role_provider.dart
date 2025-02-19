import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gcaptcha_v3/constants.dart';
import 'package:RiskSphare/models/role_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // Import for JSON encoding/decoding
import 'dart:developer'; // Import for logging

import '../design_system/components/custom_toast.dart';
import '../models/company_model.dart';
import '../service/api_service.dart';
import '../utils/api_constants.dart';

class RoleProvider with ChangeNotifier {


  bool _isLoading = false;
  bool get isLoading => _isLoading;
  set isLoading(bool value) {
    _isLoading = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  bool _isStatusLoading = false;
  bool get isStatusLoading => _isStatusLoading;
  set isStatusLoading(bool value) {
    _isStatusLoading = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  List<Roles> _roles = [];
  List<Roles> get roles => _roles;
  set roles(List<Roles> value) {
    _roles = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }


  /// Fetches all roles from the API.
  // Update API call method to handle the new JSON structure and parse it into your model classes
  Future<List<Roles>> getAllRoles(BuildContext context) async {
    try {
      // Set loading state to true
      isLoading = true;
      // Use API Service to fetch roles
      ApiService apiService = ApiService(AppConstant.GET_ROLES);

      // Send a GET request to the API
      Map<String, dynamic> response = await apiService.get("", true);

      // Parse the response into a RoleModel
      RoleModel roleModel = RoleModel.fromJson(response);

      // Extract roles from the RoleModel
      List<Roles> roles = roleModel.roles ?? [];

      // Update the list of roles and notify listeners
      _roles = roles;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      isLoading = false;
      return roles;
    } catch (e, stackTrace) {
      // Catch any errors that occur during the process
      print('Stack Trace: $stackTrace'); // Print the stack trace for debugging
      log('Error: $e'); // Log the error
      // Show a generic error message to the user
      // TODO: Display a generic error message to the user

      isLoading = false;
      if (!context.mounted) return [];
      CustomToast.error(context, 'Error fetching roles. Please try again later.');
      return []; // Return an empty list in case of error
    }
  }

  /// Changes status of a role based on the role ID and new status.
  Future<bool> changeRoleStatus(BuildContext context, String roleId, bool newStatus) async {
    try {
      // Set loading state to true
      isStatusLoading = true;
      // Use API Service to update company status
      ApiService apiService = ApiService(AppConstant.CHANGE_STATUS);
      Map<String, dynamic> body = {
        'data': {
          "update_category":true,
          'id': roleId,
          'status': newStatus,
        },
      };
      // Send a PATCH request to the API
      Map<String, dynamic> response = await apiService.patch(body);
      isStatusLoading = false;
      if(context.mounted) {
        CustomToast.success(context, response['message']);
      } else {
        Future.delayed(Duration(seconds: 1), () {
          if(context.mounted) CustomToast.success(context, response['message']);
        });
      }


      return newStatus;
    } catch (e, stackTrace) {
      // Catch any errors that occur during the process
      print('Stack Trace: $stackTrace'); // Print the stack trace for debugging
      log('Error: $e'); // Log the error
      // Show a generic error message to the user for type BackendException text
      if(context.mounted) CustomToast.error(context, e.toString());
      isStatusLoading = false;
      return false; // Return false in case of error
    }
  }

}