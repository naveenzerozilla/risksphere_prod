import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gcaptcha_v3/constants.dart';
import 'package:RiskSphere/models/corporate_verification_list_model.dart';
import 'package:RiskSphere/models/role_model.dart';
import 'package:RiskSphere/models/user_verification_list_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // Import for JSON encoding/decoding
import 'dart:developer'; // Import for logging

import '../design_system/components/custom_toast.dart';
import '../models/company_model.dart';
import '../service/api_service.dart';
import '../utils/api_constants.dart';

class VerificationProvider with ChangeNotifier {
  bool _isCorporateLoading = false;

  bool get isCorporateLoading => _isCorporateLoading;

  set isCorporateLoading(bool value) {
    _isCorporateLoading = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }
  void setAcceptLoading(bool value) {
    isCorporateAcceptLoading = value;
    notifyListeners();
  }
  bool _isUserLoading = false;

  bool get isUserLoading => _isUserLoading;

  set isUserLoading(bool value) {
    _isUserLoading = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  bool _isCorporateAcceptLoading = false;

  bool get isCorporateAcceptLoading => _isCorporateAcceptLoading;

  set isCorporateAcceptLoading(bool value) {
    _isCorporateAcceptLoading = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  bool _isUserAcceptLoading = false;

  bool get isUserAcceptLoading => _isUserAcceptLoading;

  set isUserAcceptLoading(bool value) {
    _isUserAcceptLoading = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  bool _isCorporateRejectLoading = false;

  bool get isCorporateRejectLoading => _isCorporateRejectLoading;

  set isCorporateRejectLoading(bool value) {
    _isCorporateRejectLoading = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  bool _isUserRejectLoading = false;

  bool get isUserRejectLoading => _isUserRejectLoading;

  set isUserRejectLoading(bool value) {
    _isUserRejectLoading = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  bool _isUserRoleLoading = false;
  bool get isUserRoleLoading => _isUserRoleLoading;
  set isUserRoleLoading(bool value) {
    _isUserRoleLoading = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  List<Company> _corporateRequests = [];

  List<Company> get corporateRequests => _corporateRequests;

  set corporateRequests(List<Company> value) {
    _corporateRequests = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }



  List<Users> _userRequests = [];

  List<Users> get userRequests => _userRequests;

  set userRequests(List<Users> value) {
    _userRequests = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  /// Fetches all corporate requests from the API.
  // Update API call method to handle the new JSON structure and parse it into your model classes
  Future<List<Company>> getAllCorporateRequests(BuildContext context) async {
    try {
      // Set loading state to true
      isCorporateLoading = true;
      // Use API Service to fetch roles
      ApiService apiService =
          ApiService(AppConstant.GET_CORPORATE_VERIFICATION_REQUESTS);

      // Send a GET request to the API
      Map<String, dynamic> response = await apiService.get("");

      // Parse the response into a RoleModel
      CorporateVerificationListModel corporateRequests =
          CorporateVerificationListModel.fromJson(response);

      // Extract company from the CorporateRequests
      List<Company> companyList = corporateRequests.company ?? [];

      // Update the list of roles and notify listeners
      _corporateRequests = companyList;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      isCorporateLoading = false;
      return companyList;
    } catch (e, stackTrace) {
      // Catch any errors that occur during the process
      print('Stack Trace: $stackTrace'); // Print the stack trace for debugging
      log('Error: $e'); // Log the error
      // Show a generic error message to the user
      // TODO: Display a generic error message to the user

      isCorporateLoading = false;
      if (!context.mounted) return [];
      CustomToast.error(
          context, 'Error fetching roles. Please try again later.');
      return []; // Return an empty list in case of error
    }
  }

  /// Fetches all user requests from the API.
  // Update API call method to handle the new JSON structure and parse it into your model classes
  Future<List<Users>> getAllUserRequests(BuildContext context) async {
    try {
      // Set loading state to true
      isUserLoading = true;
      // Use API Service to fetch roles
      ApiService apiService =
      ApiService(AppConstant.GET_USER_VERIFICATION_REQUESTS);

      // Send a GET request to the API
      Map<String, dynamic> response = await apiService.get("");

      // Parse the response into a RoleModel
      UserVerificationListModel userRequests = UserVerificationListModel.fromJson(response);

      // Extract roles from the RoleModel
      List<Users> userList = userRequests.users ?? [];

      // Update the list of roles and notify listeners
      _userRequests = userList;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      isUserLoading = false;
      return userList;
    } on BackendException catch (e, stackTrace) {
      // Catch any errors that occur during the process
      print('Stack Trace: $stackTrace'); // Print the stack trace for debugging
      log('Error: $e'); // Log the error
      // Show a generic error message to the user
      isUserLoading = false;
      if (!context.mounted) return [];
      if(e.message != null) {
        CustomToast.error(context, e.message);
      } else {
        CustomToast.error(context, 'Error fetching requests. Please try again later.');
      }
      CustomToast.error(
          context, 'Error fetching requests. Please try again later.');
      return []; // Return an empty list in case of error
    }
    catch (e, stackTrace) {
      // Catch any errors that occur during the process
      print('Stack Trace: $stackTrace'); // Print the stack trace for debugging
      log('Error: $e'); // Log the error
      // Show a generic error message to the user
      isUserLoading = false;
      if (!context.mounted) return [];
      CustomToast.error(
          context, 'Error fetching requests. Please try again later.');
      return []; // Return an empty list in case of error
    }
  }

  /// Changes status of a role based on the role ID and new status for corporate.
  Future<bool> changeCorporateVerificationStatus(
      BuildContext context, String corporateId, bool newStatus) async {
    try {
      // Set loading state to true
      if (newStatus) {
        isCorporateAcceptLoading = true;
      } else {
        isCorporateRejectLoading = true;
      }
      // Use API Service to update company status
      ApiService apiService = ApiService(AppConstant.CHANGE_CORPORATE_STATUS);
      Map<String, dynamic> body = {
        "data": {
          "action": "process_verification",
          "type": newStatus ? "accept" : "ignore",
          // accept | ignore
          "is_corporate_verification": true,
          // If corporate verification then true, otherwise false
          "company_id": corporateId
        }
      };
      // Send a PATCH request to the API
      Map<String, dynamic> response = await apiService.post(body);
      if (newStatus) {
        isCorporateAcceptLoading = false;
      } else {
        isCorporateRejectLoading = false;
      }
      if (context.mounted) {
        CustomToast.success(context, response['message']);
      } else {
        Future.delayed(Duration(seconds: 1), () {
          if (context.mounted)
            CustomToast.success(context, response['message']);
        });
      }

      return newStatus;
    } catch (e, stackTrace) {
      // Catch any errors that occur during the process
      print('Stack Trace: $stackTrace'); // Print the stack trace for debugging
      log('Error: $e'); // Log the error
      // Show a generic error message to the user for type BackendException text
      if (context.mounted) CustomToast.error(context, e.toString());
      if (newStatus) {
        isCorporateAcceptLoading = false;
      } else {
        isCorporateRejectLoading = false;
      }
      return false; // Return false in case of error
    }
  }

  /// Changes status of a role based on the role ID and new status for user.
  Future<bool> changeUserVerificationStatus(
      BuildContext context, String userId, bool newStatus) async {
    try {
      // Set loading state to true
      if (newStatus) {
        isUserAcceptLoading = true;
      } else {
        isUserRejectLoading = true;
      }
      // Use API Service to update company status
      ApiService apiService = ApiService(AppConstant.CHANGE_CORPORATE_STATUS);
      Map<String, dynamic> body = {
        "data": {
          "action": "process_verification",
          "type": newStatus ? "accept" : "ignore",
          // accept | ignore
          "is_corporate_verification": false,
          // If corporate verification then true, otherwise false
          "user_id": userId
        }
      };
      // Send a PATCH request to the API
      Map<String, dynamic> response = await apiService.post(body);
      if (newStatus) {
        isUserAcceptLoading = false;
      } else {
        isUserRejectLoading = false;
      }
      if (context.mounted) {
        CustomToast.success(context, response['message']);
      } else {
        Future.delayed(Duration(seconds: 1), () {
          if (context.mounted)
            CustomToast.success(context, response['message']);
        });
      }

      return newStatus;
    } catch (e, stackTrace) {
      // Catch any errors that occur during the process
      print('Stack Trace: $stackTrace'); // Print the stack trace for debugging
      log('Error: $e'); // Log the error
      // Show a generic error message to the user for type BackendException text
      if (context.mounted) CustomToast.error(context, e.toString());
      if (newStatus) {
        isUserAcceptLoading = false;
      } else {
        isUserRejectLoading = false;
      }
      return false; // Return false in case of error
    }
  }

  /// Changes status of a role based on the role ID and new role for user.
  Future<bool> changeUserVerificationRole(
      BuildContext context, String userId, Roles role) async {
    try {
      // Set loading state to true
      isUserRoleLoading = true;
      // Use API Service to update company status
      ApiService apiService = ApiService(AppConstant.CHANGE_USER_ROLE);
      Map<String, dynamic> body = {
        "data": {
          "save_role": true,
          //add role key
          "role": role.toJson(),
          // If corporate verification then true, otherwise false
          "user_id": userId
        }
      };
      // Send a PATCH request to the API
      Map<String, dynamic> response = await apiService.post(body);
      isUserRoleLoading = false;
      if (context.mounted) {
        CustomToast.success(context, response['message']);
      } else {
        Future.delayed(Duration(seconds: 1), () {
          if (context.mounted)
            CustomToast.success(context, response['message']);
        });
      }

      return true;
    } catch (e, stackTrace) {
      // Catch any errors that occur during the process
      print('Stack Trace: $stackTrace'); // Print the stack trace for debugging
      log('Error: $e'); // Log the error
      // Show a generic error message to the user for type BackendException text
      if (context.mounted) CustomToast.error(context, e.toString());
      isUserRoleLoading = false;
      return false; // Return false in case of error
    }
  }
}
