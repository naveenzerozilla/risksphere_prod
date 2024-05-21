import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gcaptcha_v3/constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // Import for JSON encoding/decoding
import 'dart:developer'; // Import for logging
import '../design_system/components/custom_toast.dart';
import '../models/company_model.dart';
import '../models/corporate_user_model.dart';
import '../models/role_model.dart';
import '../models/user_corporate_model.dart';
import '../service/api_service.dart';
import '../utils/api_constants.dart';

class CorporateProvider with ChangeNotifier {
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

  List<CorporateUsers>? _employeesList = [];

  List<CorporateUsers>? get employeeList => _employeesList;

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

  CorporateUsers _employees = CorporateUsers();

  CorporateUsers get employees => _employees;

  UsersCorporate _employeesC = UsersCorporate();

  UsersCorporate get employeesC => _employeesC;


  List<Roles>? _roles = [];
  List<Roles>? get roles => _roles;


  /// Fetches all employees from the API based on search text and filter criteria.
  Future<List<CorporateUsers>> getCorporateUserList(
      BuildContext context, {
        String? companyId,
        String searchText = "",
        String roleFilter = "",
        bool isSearch = false,
      }) async {
    try {
      print("Company ID: $companyId");
      // Clear normal pagination is isSearch is true
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

      // Construct API URL with filters
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
      additionalParams += "&pageSize=5";

      ApiService apiService = ApiService(AppConstant.GET_CORPORATE_USER);
      String url = companyId != null && companyId != ""? "?users=true&company_id=$companyId" : "?users=true&current=true";
      if (additionalParams.isNotEmpty) {
        url += (url.contains("?") ? "&" : "?") + additionalParams.substring(1);
      }

      // Fetch data from API
      Map<String, dynamic> response = await apiService.get(url);

      // Parse response
      List<CorporateUsers> employees = [];
      if(response['users'] == null) {
        isLoading = false;
        isNextPageLoading = false;
        return [];
      }
      employees = (response['users'])
          .map<CorporateUsers>((employee) => CorporateUsers.fromJson(employee))
          .toList();

      // Update pagination variables
      print("Contains Key? ${response.containsKey('pageToken')}");
      if (response.containsKey('pageToken')) {
        nextPageToken = response['pageToken'];
      } else {
        nextPageToken = null;
      }
      nextPageExists = response.containsKey('nextPageExists') ? response['nextPageExists'] : false;

      // Update employee list and notify listeners
      _employeesList?.addAll(employees);
      notifyListeners();

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
          context, 'Error fetching corporate users. Please try again later.');
      return [];
    }
  }

  /// Changes status of an employee based on the employee ID and new status.
  Future<bool> changeCorporateEmployeeStatus(BuildContext context,
      String employeeId, bool newStatus) async {
    try {
      // Set loading state to true
      isStatusLoading = true;
      // Use API Service to update company status
      ApiService apiService = ApiService(AppConstant.UPDATE_USER_STATUS);
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
  Future<bool> deleteCompany(BuildContext context,
      List<String> employeeIds) async {
    try {
      // Set loading state to true
      isDeleteLoading = true;
      // Use API Service to update company status
      ApiService apiService = ApiService(AppConstant.DELETE_CORPORATE_EMPLOYEES);
      print(jsonEncode(employeeIds));
      print("url: ${AppConstant.DELETE_CORPORATE_EMPLOYEES}");
      Map<String, dynamic> body = {
        'data': {
          'user_id': employeeIds,
        },
      };
      print("Body: $body");
      // Send a DELETE request to the API
      Map<String, dynamic> response = await apiService.delete(body);
      print("Response: $response");
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

//
//   /// Delete Multiple Employees based on the employee ID.
//   Future<bool> deleteMultipleEmployees(BuildContext context, List<String> employeeIds) async {
//     try {
//       // Set loading state to true
//       isLoading = true;
//       // Use API Service to update company status
//       ApiService apiService = ApiService(AppConstant.CORPORATE_MANAGEMENT_URL);
//       Map<String, dynamic> body = {
//         'data': {
//           'company_id': employeeIds,
//         },
//       };
//       // Send a DELETE request to the API
//       Map<String, dynamic> response = await apiService.delete(body);
//       isLoading = false;
//       if(context.mounted) {
//         CustomToast.success(context, response['message']);
//       } else {
//         Future.delayed(Duration(seconds: 1), () {
//           if(context.mounted) CustomToast.success(context, response['message']);
//         });
//       }
//       return true;
//     } catch (e, stackTrace) {
//       // Catch any errors that occur during the process
//       print('Stack Trace: $stackTrace'); // Print the stack trace for debugging
//       log('Error: $e'); // Log the error
//       // Show a generic error message to the user
//       if(context.mounted) CustomToast.error(context, e.toString());
//       isLoading = false;
//       return false; // Return false in case of error
//     }
//   }
//
//   /// Create a new employee based on the employee data.
//   Future<bool> createEmployee(BuildContext context, Map<String, dynamic> employeeData) async {
//     try {
//       // Set loading state to true
//       isLoading = true;
//       // Use API Service to update company status
//       ApiService apiService = ApiService(AppConstant.CREATE_EMPLOYEES);
//       Map<String, dynamic> body = {
//         'data': employeeData,
//       };
//       print("Body: $body");
//       // Send a POST request to the API
//       Map<String, dynamic> response = await apiService.post(body);
//       isLoading = false;
//       if(context.mounted) {
//         CustomToast.success(context, response['message']);
//         getAllEmployees(context, '', '');
//       } else {
//         Future.delayed(Duration(seconds: 1), () {
//           if(context.mounted) CustomToast.success(context, response['message']);
//           getAllEmployees(context, '', '');
//         });
//       }
//       return true;
//     } catch (e, stackTrace) {
//       // Catch any errors that occur during the process
//       print('Stack Trace: $stackTrace'); // Print the stack trace for debugging
//       log('Error: $e'); // Log the error
//       // Show a generic error message to the user
//       if(context.mounted) CustomToast.error(context, e.toString());
//       isLoading = false;
//       return false; // Return false in case of error
//     }
//   }
//
//   /// Update a employee based on the employee ID and new employee data.
  Future<bool> updateCorporateEmployee(BuildContext context, Map<String, dynamic> employeeData) async {
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
          if (context.mounted) CustomToast.success(
              context, response['message']);
        });
       getCorporateUserList(context);
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
//
//   /// View an employee based on the employee ID.
//   Future<UsersCorporate> viewCorporateUserEmployee(BuildContext context, String employeeId) async {
//     try {
//
//       // Set loading state to true
//       isEditViewEmployeeLoading = true;
// print(employeeId);
//       // Use API Service to fetch employee data
//       ApiService apiService = ApiService(AppConstant.VIEW_EMPLOYEES);
//       Map<String, dynamic> response = await apiService.get();
//
//       // Check if response contains employee data
//       if (response.containsKey('corporate_users')) {
//
//         List<dynamic> companiesJson = response['user'];
//         List<UsersCorporate> companies = companiesJson.map((json) => UsersCorporate.fromJson(json)).toList();
//         // _company = companies[0];
//
//
//         // dynamic employeeJson = response['user'];
//         // UsersCorporate employee = UsersCorporate.fromJson(employeeJson);
//
//         // Update employee data in provider
//        _employeesC = employeesC;
//        print(_employeesC.name);
//
//         // Notify listeners of changes
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           notifyListeners();
//         });
//         isEditViewEmployeeLoading = false;
//
//         return employeesC;
//       } else {
//         print("welcome");
//         // If no employee data found, return an empty Employee object
//         isEditViewEmployeeLoading = false;
//        return UsersCorporate();
//       }
//     } catch (e, stackTrace) {
//       // Handle errors
//       print('Stack Trace: $stackTrace');
//       log('Error: $e');
//       if (context.mounted) CustomToast.error(context, e.toString());
//
//       // Set loading state to false
//       isEditViewEmployeeLoading = false;
//
//       // Return empty Employee object in case of error
//      return UsersCorporate();
//     }
//   }

  Future<UsersCorporate> viewCorporateUserEmployee(BuildContext context, String employeeId) async {
    try {
      // Set loading state to true
      isEditViewEmployeeLoading = true;

      // Use API Service to fetch employee data
      ApiService apiService = ApiService(AppConstant.VIEW_EMPLOYEES);
      Map<String, dynamic> response = await apiService.get("?user_id=$employeeId");

      UsersCorporate user = UsersCorporate();
        user = UsersCorporate.fromJson(response['user']);
      // Notify listeners of changes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });

      isEditViewEmployeeLoading = false;
      return user;
    } catch (e, stackTrace) {
      // Handle errors
      print('Error fetching corporate user employee: $e');
      print('Stack Trace: $stackTrace');
      if (context.mounted) CustomToast.error(context, 'Failed to load employee data.');

      // Set loading state to false
      isEditViewEmployeeLoading = false;
      return UsersCorporate(); // Return an empty UsersCorporate object
    }
  }

  // Future<UsersCorporate> viewCorporateUserEmployee(BuildContext context,
  //     String employeeId) async {
  //   try {
  //     // Set loading state to true
  //     isEditViewEmployeeLoading = true;
  //
  //     // Use API Service to fetch employee data
  //     ApiService apiService = ApiService(AppConstant.VIEW_EMPLOYEES);
  //     Map<String, dynamic> response = await apiService.get(
  //         "?user_id=$employeeId");
  //
  //     // Check if response contains employee data
  //     if (response.containsKey('user')) {
  //
  //     }
  //     List<dynamic> usersJson = response['user'];
  //     List<UsersCorporate> users =
  //     usersJson.map((json) => UsersCorporate.fromJson(json)).toList();
  //
  //     if (users.isNotEmpty) {
  //       _employeesC = users
  //           .first; // Assuming you want to load the first user for editing
  //       print(_employeesC.displayName); // Log to check data
  //     }
  //
  //     // Notify listeners of changes
  //     WidgetsBinding.instance.addPostFrameCallback((_) {
  //       notifyListeners();
  //     });
  //
  //     isEditViewEmployeeLoading = false;
  //     return _employeesC;
  //   }
  //   catch (e, stackTrace) {
  //     // Handle errors
  //     print('Stack Trace: $stackTrace');
  //     log('Error: $e');
  //     if (context.mounted) CustomToast.error(context, e.toString());
  //
  //     // Set loading state to false
  //     isEditViewEmployeeLoading = false;
  //     return UsersCorporate();
  //   }
  // }

//
//
//
//
//   /// Upload image and get image URL
//   Future<String> uploadImage(BuildContext context, File image) async {
//     try {
//       // Set loading state to true
//       isImageUploadLoading = true;
//       // Use API Service to update company status
//       ApiService apiService = ApiService(AppConstant.CORPORATE_MANAGEMENT_URL);
//       // Send a POST request to the API
//       Map<String, dynamic> response = await apiService.postMultiPart(image.absolute.path);
//       isImageUploadLoading = false;
//       if (response.containsKey('url')) {
//         return response['url'];
//       } else {
//         return '';
//       }
//     } catch (e, stackTrace) {
//       // Catch any errors that occur during the process
//       print('Stack Trace: $stackTrace'); // Print the stack trace for debugging
//       log('Error: $e'); // Log the error
//       // Show a generic error message to the user
//       if (context.mounted) CustomToast.error(context, e.toString());
//       isImageUploadLoading = false;
//       return ''; // Return false in case of error
//     }
//   }
//
//   /// Fetch Roles from the API
//   /// https://companies-nzc3rkheha-uc.a.run.app?role=internal
//   /// {
// //     "data": "Authenticated request success",
// //     "roles": [
// //         {
// //             "name": "Support",
// //             "role": "support",
// //             "is_applicable_for_internal": true,
// //             "status": true
// //         },
// //         {
// //             "name": "Admin",
// //             "role": "admin",
// //             "is_applicable_for_internal": true,
// //             "status": true
// //         }
// //     ]
// // }
//   /// Fetch Roles from the API
  Future<List<Roles>> getRoless(BuildContext context) async {
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

  /// Create a new employee based on the employee data.
  Future<bool> createCorporateEmployee(
      BuildContext context, Map<String, dynamic> employeeData) async {
    try {
      // Set loading state to true
      isLoading = true;
      // Use API Service to update company status
      ApiService apiService =
          ApiService(AppConstant.CREATE_CORPORATE_EMPLOYEES);
      Map<String, dynamic> body = {
        'data': employeeData,
      };
      print("Body: $body");
      // Send a POST request to the API
      Map<String, dynamic> response = await apiService.post(body);
      isLoading = false;
      if (context.mounted) {
        CustomToast.success(context, response['message']);
        // getAllEmployees(context, '', '');
      } else {
        Future.delayed(Duration(seconds: 1), () {
          if (context.mounted)
            CustomToast.success(context, response['message']);
          // getAllEmployees(context, '', '');
        });
      }
      return true;
    } catch (e, stackTrace) {
      // Catch any errors that occur during the process
      print('Stack Trace: $stackTrace'); // Print the stack trace for debugging
      log('Error: $e'); // Log the error
      // Show a generic error message to the user
      if (context.mounted) CustomToast.error(context, e.toString());
      return false;
    }
  }

  Future<List<Roles>> getRoles(BuildContext context) async {
    try {
      // Set loading state to true
      isLoading = true;
      // Use API Service to fetch companies
      ApiService apiService = ApiService(AppConstant.GET__ROLES_FOR_CORPORATE_EMPLOYEES);
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
  Future<List<Roles>> getRolesWithCompanyId(BuildContext context, String companyId) async {
    try {
      // Set loading state to true
      isLoading = true;
      // Use API Service to fetch companies
      ApiService apiService = ApiService(AppConstant.GET__ROLES_FOR_CORPORATE_EMPLOYEES);
      String params = companyId != ""? "&company_id=$companyId" : "";
      // Send a GET request to the API
      Map<String, dynamic> response = await apiService.get(params);
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