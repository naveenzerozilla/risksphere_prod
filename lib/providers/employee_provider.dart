import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gcaptcha_v3/constants.dart';
import 'package:green/models/company_type_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // Import for JSON encoding/decoding
import 'dart:developer'; // Import for logging

import '../design_system/components/custom_toast.dart';
import '../models/company_model.dart';
import '../models/employee_list_model.dart';
import '../models/view_employee_model.dart';
import '../service/api_service.dart';
import '../utils/api_constants.dart';

class EmployeeProvider with ChangeNotifier {
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

  bool _isDeleteLoading = false;

  bool get isDeleteLoading => _isDeleteLoading;

  set isDeleteLoading(bool value) {
    _isDeleteLoading = value;
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

  bool _isEditViewEmployeeLoading = false;

  bool get isEditViewEmployeeLoading => _isEditViewEmployeeLoading;

  set isEditViewEmployeeLoading(bool value) {
    _isEditViewEmployeeLoading = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  /// Pagination
  bool _isNextPageLoading = false;

  bool get isNextPageLoading => _isNextPageLoading;

  set isNextPageLoading(bool value) {
    _isNextPageLoading = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  String? nextPageToken;
  bool nextPageExists = true;

  List<Employees>? _employeesList = [];

  List<Employees>? get employeeList => _employeesList;

  Employee _employees = Employee();

  Employee get employees => _employees;

  List<Roles>? _roles = [];

  List<Roles>? get roles => _roles;

  String activeCount = "";
  String allCount = "";

  /// Fetches all employees from the API based on search text and filter criteria.
  Future<List<Employees>> getAllEmployees(BuildContext context,
      {String searchText = "",
      String roleFilter = "",
      bool isSearch = false, bool status = false}) async {
    try {
      // Clear normal pagination if isSearch is true
      if (isSearch) {
        nextPageToken = null;
        nextPageExists = true;
      }

      // Check loading state and pagination
      if (isLoading || isNextPageLoading) return _employeesList ?? [];
      if (!nextPageExists) return _employeesList ?? [];

      // Set loading state
      if (nextPageToken == null && nextPageExists) {
        _employeesList = [];
        isLoading = true;
      } else {
        isNextPageLoading = true;
      }

      // Construct API URL with filters and pagination
      String additionalParams = "";
      if (searchText.isNotEmpty) {
        additionalParams += "&search=$searchText";
      }
      if (roleFilter.isNotEmpty) {
        additionalParams += "&role_filter=$roleFilter";
      }
      if (nextPageToken != null) {
        additionalParams += "&pageToken=$nextPageToken&direction=forward";
      }
      additionalParams += "&pageSize=10"; // Adjust page size as needed
      if (status) {
        additionalParams += "&active_users=$status";
      }

      // Construct the URL with correct formatting
      String url = AppConstant.GET_EMPLOYEES;
      if (additionalParams.isNotEmpty) {
        // Check if the base URL already contains a "?"
        final bool hasQueryParams = url.contains("?");

        // If the base URL already contains a "?", use "&" to append additionalParams
        // Otherwise, use "?"
        final String separator = hasQueryParams ? "&" : "?";

        // If additionalParams starts with "&" or "?", remove the first character
        final String formattedParams =
        additionalParams.startsWith("&") || additionalParams.startsWith("?")
            ? additionalParams.substring(1)
            : additionalParams;

        // Construct the final URL with additional parameters
        print("Formatted Params: $formattedParams");
        print("URL: $url");
        print("Separator: $separator");
        url = "$separator$formattedParams";
      } else {
        url = "";
      }

      ApiService apiService = ApiService(AppConstant.GET_EMPLOYEES);

      // Fetch data from API
      Map<String, dynamic> response = await apiService.get(url);

      // Parse response
      List<Employees> employees = [];
      /*if ((!isSearch)&&response.containsKey('employees')) {
        var model = EmployeeListModel.fromJson(response);
        if (model.employees != null) {
          employees = model.employees!;
        }
        if (model.counts != null) {
          activeCount = model.counts!.active.toString();
          allCount = model.counts!.users.toString();
        }
      } else
      if (isSearch&&response.containsKey('users') && response['users']!= null &&response['users']['employees'] != null && response['users']['employees'].isNotEmpty) {
        var model = EmployeeListModel.fromJson(response, isSearch: true); // Parse the entire model
        if (model.users != null && model.users!.employees != null) {
          employees = model.users!.employees!;
          print("Parsed users: ${employees.length}");
          if (model.counts != null) {
            activeCount = model.users?.counts?.active?.toString()??"0";
            allCount = model.users?.counts?.users?.toString()??"0";
          }
        } else {
          print("No 'employees' found within 'users'.");
        }
      } else {
        print("Response does not contain 'data' key or it is null.");
      }*/

      if (response.containsKey('users') && response['users'].containsKey('employees')) {
        employees = (response['users']['employees'] as List)
            .map((employee) => Employees.fromJson(employee))
            .toList();
        if (response['users'].containsKey('counts')) {
          activeCount = response['users']['counts']['active'].toString();
          allCount = response['users']['counts']['users'].toString();
        }
      }

      _employeesList?.addAll(employees);
      notifyListeners();

      // Update pagination variables
      nextPageToken =
          response.containsKey('pageToken') ? response['pageToken'] : null;
      nextPageExists = response.containsKey('nextPageExists')
          ? response['nextPageExists']
          : false;

      // Reset loading state
      isLoading = false;
      isNextPageLoading = false;

      return _employeesList ?? [];
    } catch (e, stackTrace) {
      print('Stack Trace: $stackTrace');
      log('Error: $e');

      // Handle error and reset loading state
      isLoading = false;
      isNextPageLoading = false;
      if (!context.mounted) return [];
      CustomToast.error(
          context, 'Error fetching employees. Please try again later.');
      return [];
    }
  }

  /// Changes status of an employee based on the employee ID and new status.
  Future<bool> changeEmployeeStatus(
      BuildContext context, String employeeId, bool newStatus) async {
    try {
      // Set loading state to true
      isStatusLoading = true;
      // Use API Service to update company status
      ApiService apiService = ApiService(AppConstant.UPDATE_EMPLOYEES);
      Map<String, dynamic> body = {
        'data': {
          'user_id': employeeId,
          'status': newStatus,
        },
      };
      // Send a PATCH request to the API
      Map<String, dynamic> response = await apiService.patch(body);
      isStatusLoading = false;
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
      isStatusLoading = false;
      return false; // Return false in case of error
    }
  }

  /// Deletes a company based on the company ID.
  /// {
//     "data":{
//         "company_id":["VfIz7kXeFMK2ezIbKKCu","YqpcooTwU3MisGMj0ANH"]
//         }
// }
  Future<bool> deleteCompany(
      BuildContext context, List<String> employeeIds) async {
    try {
      // Set loading state to true
      isDeleteLoading = true;
      // Use API Service to update company status
      ApiService apiService = ApiService(AppConstant.GET_EMPLOYEES);
      Map<String, dynamic> body = {
        'data': {
          'user_id': employeeIds,
        },
      };
      // Send a DELETE request to the API
      Map<String, dynamic> response = await apiService.delete(body);
      isDeleteLoading = false;
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
      // Show a generic error message to the user
      if (context.mounted) CustomToast.error(context, e.toString());
      isDeleteLoading = false;
      return false; // Return false in case of error
    }
  }

  /// Delete Multiple Employees based on the employee ID.
  Future<bool> deleteMultipleEmployees(
      BuildContext context, List<String> employeeIds) async {
    try {
      // Set loading state to true
      isLoading = true;
      // Use API Service to update company status
      ApiService apiService = ApiService(AppConstant.CORPORATE_MANAGEMENT_URL);
      Map<String, dynamic> body = {
        'data': {
          'user_id': employeeIds,
        },
      };
      // Send a DELETE request to the API
      Map<String, dynamic> response = await apiService.delete(body);
      isLoading = false;
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
      // Show a generic error message to the user
      if (context.mounted) CustomToast.error(context, e.toString());
      isLoading = false;
      return false; // Return false in case of error
    }
  }

  /// Create a new employee based on the employee data.
  Future<bool> createEmployee(
      BuildContext context, Map<String, dynamic> employeeData) async {
    try {
      // Set loading state to true
      isLoading = true;
      // Use API Service to update company status
      ApiService apiService = ApiService(AppConstant.CREATE_EMPLOYEES);
      Map<String, dynamic> body = {
        'data': employeeData,
      };
      print("Body: $body");
      // Send a POST request to the API
      Map<String, dynamic> response = await apiService.post(body);
      isLoading = false;
      if (context.mounted) {
        CustomToast.success(context, response['message']);
        getAllEmployees(context);
      } else {
        Future.delayed(Duration(seconds: 1), () {
          if (context.mounted)
            CustomToast.success(context, response['message']);
          getAllEmployees(context);
        });
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

  /// Update a employee based on the employee ID and new employee data.
  Future<bool> updateEmployee(
      BuildContext context, Map<String, dynamic> employeeData) async {
    try {
      // Set loading state to true
      isLoading = true;
      // Use API Service to update company status
      ApiService apiService = ApiService(AppConstant.UPDATE_EMPLOYEES);
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
          if (context.mounted)
            CustomToast.success(context, response['message']);
        });
        getAllEmployees(context);
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

  /// View an employee based on the employee ID.
  Future<Employee> viewEmployee(BuildContext context, String employeeId) async {
    try {
      // Set loading state to true
      isEditViewEmployeeLoading = true;

      // Use API Service to fetch employee data
      ApiService apiService = ApiService(AppConstant.VIEW_EMPLOYEES);
      Map<String, dynamic> response =
          await apiService.get("?user_id=$employeeId");

      // Check if response contains employee data
      if (response.containsKey('user')) {
        dynamic employeeJson = response['user'];
        Employee employee = Employee.fromJson(employeeJson);

        // Update employee data in provider
        _employees = employee;

        // Notify listeners of changes
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
        isEditViewEmployeeLoading = false;

        return employee;
      } else {
        // If no employee data found, return an empty Employee object
        isEditViewEmployeeLoading = false;
        return Employee();
      }
    } catch (e, stackTrace) {
      // Handle errors
      print('Stack Trace: $stackTrace');
      log('Error: $e');
      if (context.mounted) CustomToast.error(context, e.toString());

      // Set loading state to false
      isEditViewEmployeeLoading = false;

      // Return empty Employee object in case of error
      return Employee();
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
      Map<String, dynamic> response =
          await apiService.postMultiPart(image.absolute.path);
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
  /// https://companies-nzc3rkheha-uc.a.run.app?role=internal
  /// {
//     "data": "Authenticated request success",
//     "roles": [
//         {
//             "name": "Support",
//             "role": "support",
//             "is_applicable_for_internal": true,
//             "status": true
//         },
//         {
//             "name": "Admin",
//             "role": "admin",
//             "is_applicable_for_internal": true,
//             "status": true
//         }
//     ]
// }
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
