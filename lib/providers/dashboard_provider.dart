import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gcaptcha_v3/constants.dart';
import 'package:RiskSphere/models/dashboard_model.dart';
import 'package:RiskSphere/models/role_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // Import for JSON encoding/decoding
import 'dart:developer'; // Import for logging

import '../design_system/components/custom_toast.dart';
import '../models/company_model.dart';
import '../service/api_service.dart';
import '../utils/api_constants.dart';

class DashboardProvider with ChangeNotifier {


  bool _isLoading = false;
  bool get isLoading => _isLoading;
  set isLoading(bool value) {
    _isLoading = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  bool _isRoleLoading = false;
  bool get isRoleLoading => _isRoleLoading;
  set isRoleLoading(bool value) {
    _isRoleLoading = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  bool _isCompanyLoading = false;
  bool get isCompanyLoading => _isCompanyLoading;
  set isCompanyLoading(bool value) {
    _isCompanyLoading = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  DashboardModel? dashboardModel;
  DashboardModel? get dashboard => dashboardModel;
  set dashboard(DashboardModel? value) {
    dashboardModel = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }


  /// Fetches all data from the API.
  // Update API call method to handle the new JSON structure and parse it into your model classes
  Future<DashboardModel?> getDashboardData(BuildContext context) async {
    try {
      // Set loading state to true
      isLoading = true;
      // Use API Service to fetch roles
      ApiService apiService = ApiService(AppConstant.GET_DASHBOARD);

      // Send a GET request to the API
      Map<String, dynamic> response = await apiService.get("");

      // Parse the response into a DashboardModel
      DashboardModel dashboardModel = DashboardModel.fromJson(response);
      // Update the dashboard model and notify listeners
      this.dashboard = dashboardModel;
      // Set loading state to false
      isLoading = false;
      return dashboardModel; // Return the dashboard model

    } catch (e, stackTrace) {
      // Catch any errors that occur during the process
      print('Stack Trace: $stackTrace'); // Print the stack trace for debugging
      log('Error: $e'); // Log the error
      // Show a generic error message to the user
      // TODO: Display a generic error message to the user

      isLoading = false;
      if (!context.mounted) return null;
      // CustomToast.error(context, 'Error fetching data. Please try again later.');
      return null; // Return an empty list in case of error
    }
  }

  /// Fetch data based on the date for role selected by the user.
  Future<DashboardModel?> getDashboardDataForRoles(BuildContext context, DateTime pickedDate) async {
    try {
      // Set loading state to true
      isRoleLoading = true;
      // Use API Service to fetch roles
      ApiService apiService = ApiService(AppConstant.GET_DASHBOARD);

      // Send a GET request to the API
      Map<String, dynamic> response = await apiService.get("?type=role&month=${pickedDate.month}&year=${pickedDate.year}");

      // Parse the response into a DashboardModel
      DashboardModel? dashboardModel = DashboardModel.fromJson(response);
      // Update the dashboard model role part and notify the listeners
      this.dashboard?.roles = dashboardModel.roles;
      // Set loading state to false
      isRoleLoading = false;
      return dashboardModel; // Return the dashboard model

    } catch (e, stackTrace) {
      // Catch any errors that occur during the process
      print('Stack Trace: $stackTrace'); // Print the stack trace for debugging
      log('Error: $e'); // Log the error
      // Show a generic error message to the user
      // TODO: Display a generic error message to the user

      isRoleLoading = false;
      if (!context.mounted) return null;
      // CustomToast.error(context, 'Error fetching data. Please try again later.');
      return null; // Return an empty list in case of error
    }
  }

  /// Fetch data based on the date for company selected by the user.
  Future<DashboardModel?> getDashboardDataForCompanies(BuildContext context, DateTime pickedDate) async {
    try {
      // Set loading state to true
      isCompanyLoading = true;
      // Use API Service to fetch roles
      ApiService apiService = ApiService(AppConstant.GET_DASHBOARD);

      // Send a GET request to the API
      Map<String, dynamic> response = await apiService.get("?type=company&month=${pickedDate.month}&year=${pickedDate.year}");

      // Parse the response into a DashboardModel
      DashboardModel dashboardModel = DashboardModel.fromJson(response);
      // Update the dashboard model company part and notify the listeners
      this.dashboard?.companyType = dashboardModel.companyType;
      // Set loading state to false
      isCompanyLoading = false;
      return dashboardModel; // Return the dashboard model

    } catch (e, stackTrace) {
      // Catch any errors that occur during the process
      print('Stack Trace: $stackTrace'); // Print the stack trace for debugging
      log('Error: $e'); // Log the error
      // Show a generic error message to the user
      // TODO: Display a generic error message to the user

      isCompanyLoading = false;
      if (!context.mounted) return null;
      // CustomToast.error(context, 'Error fetching data. Please try again later.');
      return null; // Return an empty list in case of error
    }
  }


}