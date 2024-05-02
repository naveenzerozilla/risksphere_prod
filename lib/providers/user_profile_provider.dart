import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gcaptcha_v3/constants.dart';
import 'package:green/models/avatar_model.dart';
import 'package:green/models/company_type_model.dart';
import 'package:green/models/user_profile_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // Import for JSON encoding/decoding
import 'dart:developer'; // Import for logging

import '../design_system/components/custom_toast.dart';
import '../models/company_model.dart';
import '../models/employee_list_model.dart';
import '../models/view_employee_model.dart';
import '../service/api_service.dart';
import '../utils/api_constants.dart';

class UserProfileProvider with ChangeNotifier {


  bool _isLoading = false;
  bool get isLoading => _isLoading;
  set isLoading(bool value) {
    _isLoading = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  bool _isRolesLoading = false;
  bool get isRolesLoading => _isRolesLoading;
  set isRolesLoading(bool value) {
    _isRolesLoading = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  bool _isImageUploadLoading = false;
  bool get isImageUploadLoading => _isImageUploadLoading;
  set isImageUploadLoading(bool value) {
    _isImageUploadLoading = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  bool _isAvatarLoading = false;
  bool get isAvatarLoading => _isAvatarLoading;
  set isAvatarLoading(bool value) {
    _isAvatarLoading = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  UserData? _userData = UserData();
  UserData get userData => _userData!;
  set userData(UserData value) {
    _userData = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }


  Employee _employees = Employee();
  Employee get employees => _employees;

  List<Roles>? _roles = [];
  List<Roles>? get roles => _roles;

  List<Avatars?> _avatars = [];
  List<Avatars?> get avatars => _avatars;

  /// Fetches all user data from the API.
  Future<UserData?> getAllUserData(BuildContext context,String searchText, String filter) async {
    try {
      // Set loading state to true
      isLoading = true;
      // Use API Service to fetch companies
      ApiService apiService = ApiService(AppConstant.GET_USER_DETAILS);
      // Send a GET request to the API
      Map<String, dynamic> response = await apiService.get('?current_user=true');
      // Parse the response into a list of employees
      UserData? userDataLocal;
      print("Contains Key user? ${response.containsKey('user')}");
      if (response.containsKey('user')) {
        userDataLocal = UserData.fromJson(response['user']);
      }
      print("user: $userDataLocal");
      // Update the list of companies and notify listeners
      if(userDataLocal != null) {
        _userData = userDataLocal;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
      }
      isLoading = false;
      return userDataLocal;

    } catch (e, stackTrace) {
      // Catch any errors that occur during the process
      print('Stack Trace: $stackTrace'); // Print the stack trace for debugging
      log('Error: $e'); // Log the error
      // Show a generic error message to the user
      // TODO: Display a generic error message to the user

      isLoading = false;
      if (!context.mounted) return null;
      CustomToast.error(context, 'Error fetching companies. Please try again later.');
      return null; // Return an empty list in case of error
    }
  }


  /// Update a employee based on the employee ID and new employee data.
  Future<bool> updateUserData(BuildContext context, Map<String, dynamic> employeeData) async {
    try {
      // Set loading state to true
      isLoading = true;
      // Use API Service to update company status
      ApiService apiService = ApiService(AppConstant.UPDATE_USER_DETAILS);
      Map<String, dynamic> body = {
        'data': employeeData,
      };
      // Send a PATCH request to the API
      Map<String, dynamic> response = await apiService.patch(body);
      isLoading = false;
      if (context.mounted) {
        CustomToast.success(context, response['message']);
      } else {
        Future.delayed(Duration(seconds: 1), () {
          if (context.mounted) CustomToast.success(
              context, response['message']);
        });
        getAllUserData(context, '', '');
      }
      return true;
    } catch (e, stackTrace) {
      // Catch any errors that occur during the process
      print('Stack Trace: $stackTrace'); // Print the stack trace for debugging
      log('Error: $e'); // Log the error
      // Show a generic error message to the user
      if (context.mounted) CustomToast.error(context, e.toString());
      isLoading = false;
      return false; // Return false in case of error
    }
  }

  /// Get all avatar URLS

  Future<List<Avatars?>> getAvatarUrls(BuildContext context) async {
    try {
      // Set loading state to true
      isAvatarLoading = true;
      // Use API Service to fetch companies
      ApiService apiService = ApiService(AppConstant.GET_AVATARS);
      // Send a GET request to the API
      Map<String, dynamic> response = await apiService.get();
      // Parse the response into a list of employees
      List<Avatars?> avatarLocal = [];
      if (response.containsKey('avatars')) {
        avatarLocal = (response['avatars'] as List)
            .map((avatars) => Avatars.fromJson(avatars))
            .toList();
      }
      print("avatar: $avatarLocal");
      // Update the list of companies and notify listeners
      _avatars = avatarLocal;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      isAvatarLoading = false;
      return avatarLocal;
    } catch (e, stackTrace) {
      // Catch any errors that occur during the process
      print('Stack Trace: $stackTrace'); // Print the stack trace for debugging
      log('Error: $e'); // Log the error
      // Show a generic error message to the user
      String error = e.toString();
      if (context.mounted) CustomToast.error(context, error);
      isAvatarLoading = false;
      return []; // Return an empty list in case of error
    }
  }



  /// Upload image and get image URL
  Future<String> uploadImage(BuildContext context, File image) async {
    try {
      // Set loading state to true
      isImageUploadLoading = true;
      // Use API Service to update company status
      ApiService apiService = ApiService(AppConstant.CORPORATE_MANAGEMENT_URL);
      // Send a POST request to the API
      Map<String, dynamic> response = await apiService.postMultiPart(image.absolute.path);
      isImageUploadLoading = false;
      if (response.containsKey('url')) {
        return response['url'];
      } else {
        return '';
      }
    } catch (e, stackTrace) {
      // Catch any errors that occur during the process
      print('Stack Trace: $stackTrace'); // Print the stack trace for debugging
      log('Error: $e'); // Log the error
      // Show a generic error message to the user
      if (context.mounted) CustomToast.error(context, e.toString());
      isImageUploadLoading = false;
      return ''; // Return false in case of error
    }
  }

  /// Fetch Roles from the API
  Future<List<Roles>> getRoles(BuildContext context) async {
    try {
      // Set loading state to true
      isLoading = true;
      // Use API Service to fetch companies
      ApiService apiService = ApiService(AppConstant.GET_ROLES_FOR_EMPLOYEES);
      // Send a GET request to the API
      Map<String, dynamic> response = await apiService.get();
      // Parse the response into a list of corporateType
      List<Roles> rolesList = [];
      print("Contains Key? ${response.containsKey('roles')}");
      if (response.containsKey('roles')) {
        // Parse corporateType from the response
        rolesList = (response['roles'] as List)
            .map((roles) => Roles.fromJson(roles))
            .toList();
        print("Roles: $rolesList");

        _roles = rolesList;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });

      }
      isLoading = false;
      return rolesList;
    } catch (e, stackTrace) {
      // Catch any errors that occur during the process
      print('Stack Trace: $stackTrace'); // Print the stack trace for debugging
      log('Error: $e'); // Log the error
      // Show a generic error message to the user
      if (context.mounted) CustomToast.error(context, e.toString());
      isLoading = false;
      return []; // Return an empty list in case of error
    }
  }
}