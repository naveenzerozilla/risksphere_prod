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
import '../models/non_Corporate_user_model.dart';
import '../models/role_model.dart';
import '../models/user_corporate_model.dart';
import '../service/api_service.dart';
import '../utils/api_constants.dart';

class NonCorporateProvider with ChangeNotifier {


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

  /// Pagination
  int _page = 1;
  int get page => _page;
  set page(int value) {
    _page = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  int _totalPages = 1;
  int get totalPages => _totalPages;
  set totalPages(int value) {
    _totalPages = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  bool _isNextPageLoading = false;
  bool get isNextPageLoading => _isNextPageLoading;
  set isNextPageLoading(bool value) {
    _isNextPageLoading = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }



  List<IndividualUsers>? _employeesList = [];
  List<IndividualUsers>? get employeeList => _employeesList;

  bool _isEditViewEmployeeLoading = false;
  bool get isEditViewEmployeeLoading => _isEditViewEmployeeLoading;
  set isEditViewEmployeeLoading(bool value) {
    _isEditViewEmployeeLoading = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }
  IndividualUsers _employees = IndividualUsers();
  IndividualUsers get employees => _employees;

  UsersCorporate _employeesC = UsersCorporate();

  UsersCorporate get employeesC => _employeesC;


  List<Roles>? _roles = [];
  List<Roles>? get roles => _roles;

  String activeCount = "";
  String allCount = "";
  // List<Roles>? _roles = [];
  // List<Roles>? get roles => _roles;
  Future<List<IndividualUsers>> getNonCorporateUserList(BuildContext context,
      {String searchText = "", String roleFilter = "", bool isSearch = false, bool? status}) async {
    try {
      // Reset pagination for new searches
      if (isSearch) {
        page = 1;
        _employeesList = [];
      }

      // Prevent duplicate API calls
      if (isLoading || isNextPageLoading || page > totalPages) {
        return _employeesList ?? [];
      }

      // Set loading states
      if (page == 1) {
        _employeesList = [];
        isLoading = true;
      } else {
        isNextPageLoading = true;
      }

      // Construct API URL with pagination and filters
      String additionalParams = "?page=$page&pageSize=10";
      if (searchText.isNotEmpty) additionalParams += "&search=$searchText";
      if (roleFilter.isNotEmpty) additionalParams += "&role_filter=$roleFilter";
      if (status != null) additionalParams += "&active_users=$status";

      ApiService apiService = ApiService(AppConstant.NON_CORPORATE_USER_STATUS_NEW);
      String url = "$additionalParams";

      // Fetch data from API
      Map<String, dynamic> response = await apiService.get(url);

      // Parse response
      List<IndividualUsers> usersList = [];
      if (response.containsKey('result')) {
        usersList = (response['result'] as List)
            .map((user) => IndividualUsers.fromJson(user))
            .toList();
      }

      // Update pagination
      if (response.containsKey('totalRecords')) {
        int totalRecords = response['totalRecords'];
        totalPages = (totalRecords / 10).ceil(); // Assuming pageSize is 10
        allCount = totalRecords.toString();
      } else {
        totalPages = 1;
      }

      if (response.containsKey('active_count')) {
        activeCount = response['active_count'].toString();
      }

      // Add new data to the list
      _employeesList?.addAll(usersList);

      // Reset loading states
      isLoading = false;
      isNextPageLoading = false;

      notifyListeners();
      return _employeesList ?? [];
    } catch (e, stackTrace) {
      log('Error fetching non-corporate users: $e');
      print('Stack Trace: $stackTrace');
      handleError(context, e, stackTrace);

      // Reset loading states
      isLoading = false;
      isNextPageLoading = false;

      return [];
    }
  }
  void handleError(BuildContext context, dynamic e, StackTrace stackTrace) {
    log('Error: $e');
    print('Stack Trace: $stackTrace');
    if (context.mounted) {
      CustomToast.error(context, 'An error occurred. Please try again.');
    }
  }



  // Future<List<IndividualUsers>> getNonCorporateUserList(BuildContext context) async {
  //   try {
  //     print("welcome");
  //     // Set loading state to true
  //     isLoading = true;
  //     // Use API Service to fetch companies
  //     ApiService apiService = ApiService(AppConstant.NON_CORPORATE_USER_STATUS);
  //     // Map<String, dynamic> body = {
  //     //   'searchText': searchText,
  //     //   'filter': filter,
  //     // };
  //     // Send a GET request to the API
  //     Map<String, dynamic> response = await apiService.get();
  //
  //     // Parse the response into a list of employees
  //
  //     List<IndividualUsers> usersList = [];
  //     if (response.containsKey('individualUsers')) {
  //       usersList = (response['individualUsers'] as List)
  //           .map((user) => IndividualUsers.fromJson(user))
  //           .toList();
  //       print("Parsed users: ${usersList.length}");
  //     } else {
  //       print("No 'individual_users' key found in response.");
  //     }
  //     // List<IndividualUsers> employees = [];
  //     // print("Contains Key employees? ${response.containsKey('employees')}");
  //     // // if (response.containsKey('users') && response['users'].containsKey('employees')) {
  //     // employees = (response['users']response['individualUsers']  as List)
  //     //     .map((employee) => IndividualUsers.fromJson(employee))
  //     //     .toList();
  //     // // }
  //     print("Employees: $employees");
  //     print("Employees: $employees");
  //     // print(userli.length.toString());
  //     // Update the list of companies and notify listeners
  //     _employeesList = usersList;
  //     print("WEasdf");
  //     print(_employeesList?.length.toString());
  //     WidgetsBinding.instance.addPostFrameCallback((_) {
  //       notifyListeners();
  //     });
  //     isLoading = false;
  //     return usersList;
  //
  //   } catch (e, stackTrace) {
  //     // Catch any errors that occur during the process
  //     print('Stack Trace: $stackTrace'); // Print the stack trace for debugging
  //     log('Error: $e'); // Log the error
  //     // Show a generic error message to the user
  //     // TODO: Display a generic error message to the user
  //
  //     isLoading = false;
  //     if (!context.mounted) return[];
  //     CustomToast.error(context, 'Error fetching companies. Please try again later.');
  //     return []; // Return an empty list in case of error
  //   }
  // }

  /// Changes status of an employee based on the employee ID and new status.
  Future<bool> changeNonCorporateStatus(BuildContext context, String employeeId, bool newStatus) async {
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
//
//   /// Deletes a company based on the company ID.
//   /// {
// //     "data":{
// //         "company_id":["VfIz7kXeFMK2ezIbKKCu","YqpcooTwU3MisGMj0ANH"]
// //         }
// // }
  Future<bool> deleteNonCorporateUser(BuildContext context, List<String> nonCorporateIds) async {
    try {
      // Set loading state to true
      isDeleteLoading = true;
      // Use API Service to update company status
      ApiService apiService = ApiService(AppConstant.DELETE_CORPORATE_EMPLOYEES);
      Map<String, dynamic> body = {
        'data': {
          'user_id': nonCorporateIds,
        },
      };
      // Send a DELETE request to the API
      Map<String, dynamic> response = await apiService.delete(body);
      isDeleteLoading = false;
      if(context.mounted) {
        CustomToast.success(context, response['message']);
      } else {
        Future.delayed(Duration(seconds: 1), () {
          if(context.mounted) CustomToast.success(context, response['message']);
        });
      }
      return true;
    } catch (e, stackTrace) {
      // Catch any errors that occur during the process
      print('Stack Trace: $stackTrace'); // Print the stack trace for debugging
      log('Error: $e'); // Log the error
      // Show a generic error message to the user
      if(context.mounted) CustomToast.error(context, e.toString());
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
//   Future<bool> updateEmployee(BuildContext context, Map<String, dynamic> employeeData) async {
//     try {
//       // Set loading state to true
//       isLoading = true;
//       // Use API Service to update company status
//       ApiService apiService = ApiService(AppConstant.UPDATE_EMPLOYEES);
//       Map<String, dynamic> body = {
//         'data': employeeData,
//       };
//       // Send a PATCH request to the API
//       Map<String, dynamic> response = await apiService.patch(body);
//       isLoading = false;
//       if (context.mounted) {
//         CustomToast.success(context, response['message']);
//       } else {
//         Future.delayed(Duration(seconds: 1), () {
//           if (context.mounted) CustomToast.success(
//               context, response['message']);
//         });
//         getAllEmployees(context, '', '');
//       }
//       return true;
//     } catch (e, stackTrace) {
//       // Catch any errors that occur during the process
//       print('Stack Trace: $stackTrace'); // Print the stack trace for debugging
//       log('Error: $e'); // Log the error
//       // Show a generic error message to the user
//       if (context.mounted) CustomToast.error(context, e.toString());
//       isLoading = false;
//       return false; // Return false in case of error
//     }
//   }
//
//   /// View an employee based on the employee ID.
//   Future<Users> viewUserEmployee(BuildContext context, String employeeId) async {
//     try {
//       // Set loading state to true
//       isEditViewEmployeeLoading = true;
//
//       // Use API Service to fetch employee data
//       ApiService apiService = ApiService(AppConstant.VIEW_EMPLOYEES);
//       Map<String, dynamic> response = await apiService.get("?user_id=$employeeId");
//
//       // Check if response contains employee data
//       if (response.containsKey('user')) {
//         dynamic employeeJson = response['user'];
//         Users employee = Users.fromJson(employeeJson);
//
//         // Update employee data in provider
//         _employees = employee;
//
//         // Notify listeners of changes
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           notifyListeners();
//         });
//         isEditViewEmployeeLoading = false;
//
//         return employee;
//       } else {
//         // If no employee data found, return an empty Employee object
//         isEditViewEmployeeLoading = false;
//         return Users();
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
//       return Users();
//     }
//   }

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
//   Future<List<Roles>> getRoles(BuildContext context) async {
//     try {
//       // Set loading state to true
//       isLoading = true;
//       // Use API Service to fetch companies
//       ApiService apiService = ApiService(AppConstant.GET_ROLES_FOR_EMPLOYEES);
//       // Send a GET request to the API
//       Map<String, dynamic> response = await apiService.get();
//       // Parse the response into a list of corporateType
//       List<Roles> rolesList = [];
//       print("Contains Key? ${response.containsKey('roles')}");
//       if (response.containsKey('roles')) {
//         // Parse corporateType from the response
//         rolesList = (response['roles'] as List)
//             .map((roles) => Roles.fromJson(roles))
//             .toList();
//         print("Roles: $rolesList");
//
//         _roles = rolesList;
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           notifyListeners();
//         });
//
//       }
//       isLoading = false;
//       return rolesList;
//     } catch (e, stackTrace) {
//       // Catch any errors that occur during the process
//       print('Stack Trace: $stackTrace'); // Print the stack trace for debugging
//       log('Error: $e'); // Log the error
//       // Show a generic error message to the user
//       if (context.mounted) CustomToast.error(context, e.toString());
//       isLoading = false;
//       return []; // Return an empty list in case of error
//     }
//   }


  /// View an employee based on the employee ID.
  Future<UsersCorporate> viewNonCorporateUser(BuildContext context, String employeeId) async {
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


}