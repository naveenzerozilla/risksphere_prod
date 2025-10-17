import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gcaptcha_v3/constants.dart';
import 'package:RiskSphere/models/avatar_model.dart';
import 'package:RiskSphere/models/company_type_model.dart';
import 'package:RiskSphere/models/user_profile_model.dart';
import 'package:RiskSphere/models/user_team_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // Import for JSON encoding/decoding
import 'dart:developer'; // Import for logging

import '../design_system/components/custom_toast.dart';
import '../models/company_model.dart';
import '../models/employee_list_model.dart';
import '../models/networking_model.dart';
import '../models/view_employee_model.dart';
import '../screens/home/dashboard_screen.dart';
import '../service/api_service.dart';
import '../service/shared_preference_service.dart';
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
//    WidgetsBinding.instance.addPostFrameCallback((_) {
    notifyListeners();
    //   });
  }

  bool _isAvatarLoading = false;

  bool get isAvatarLoading => _isAvatarLoading;

  set isAvatarLoading(bool value) {
    _isAvatarLoading = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  bool _isUserTeamLoading = false;

  bool get isUserTeamLoading => _isUserTeamLoading;

  set isUserTeamLoading(bool value) {
    _isUserTeamLoading = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  bool _isTeamSearchLoading = false;

  bool get isTeamSearchLoading => _isTeamSearchLoading;

  set isTeamSearchLoading(bool value) {
    _isTeamSearchLoading = value;
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

  List<Manager?> _myManager = [];

  List<Manager?> get myManager => _myManager;

  List<Reportee?> _myReportee = [];

  List<Reportee?> get myReportee => _myReportee;

  List<Delegate?> _myDeligate = [];

  List<Delegate?> get myDeligate => _myDeligate;

  List<NetworkingUsers?> _networkingUsers = [];

  List<NetworkingUsers?> get networkingUsers => _networkingUsers;

  Map<String, dynamic> _trialInfo = {};

  Map<String, dynamic> get trialInfo => _trialInfo;

  /// Fetches all user data from the API.
  Future<UserData?> getAllUserData(
      BuildContext context, String searchText, String filter) async {
    try {
      // Set loading state to true
      isLoading = true;
      // Use API Service to fetch companies
      ApiService apiService = ApiService(AppConstant.GET_USER_DETAILS);
      // Send a GET request to the API
      Map<String, dynamic> response =
          await apiService.get('?current_user=true');
      // Parse the response into a list of employees
      UserData? userDataLocal;
      print("Contains Key user? ${response.containsKey('user')}");
      if (response.containsKey('user')) {
        userDataLocal = UserData.fromJson(response['user']);
      }
      print("user: $userDataLocal");
      // Update the list of companies and notify listeners
      if (userDataLocal != null) {
        _userData = userDataLocal;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
      }
      await fetchTrialInfo();
      isLoading = false;
      return userDataLocal;
    } on BackendException catch (e) {
      // Catch any errors that occur during the process
      print('Error1: $e'); // Log the error
      // Show a generic error message to the user
      // if (context.mounted) CustomToast.error(context, e.message);
      await fetchTrialInfo();
      isLoading = false;
      return null; // Return an empty list in case of error
    } catch (e, stackTrace) {
      // Catch any errors that occur during the process
      print('Stack Trace: $stackTrace'); // Print the stack trace for debugging
      log('Error2: $e'); // Log the error
      // Show a generic error message to the user
      // TODO: Display a generic error message to the user

      await fetchTrialInfo();
      isLoading = false;
      if (!context.mounted) return null;
      /* CustomToast.error(
          context, 'Error fetching companies. Please try again later.');*/
      return null; // Return an empty list in case of error
    }
  }

  Future<void> fetchTrialInfo() async {
    bool isTrialApplicable =
        await SharedPreferenceService.isTrialApplicable() ?? false;
    int trialDays = await SharedPreferenceService.getTrialPeriodDays() ?? 0;
    int trialSubdestination =
        await SharedPreferenceService.getTrialSubDestinations() ?? 0;
    int trialEditLocations =
        await SharedPreferenceService.getTrialEditLocations() ?? 0;
    int trialMaxLocations =
        await SharedPreferenceService.getTrialMaxLocations() ?? 0;
    int trialLocations = await SharedPreferenceService.getTrialLocations() ?? 0;
    int totalTrialUsers =
        await SharedPreferenceService.getTotalTrialUsers() ?? 0;
    int totalTrialUsersVerified =
        await SharedPreferenceService.getTotalUsersVerified() ?? 0;

    print("trial period details: $isTrialApplicable, $trialDays");

    if (isTrialApplicable) {
      _trialInfo = {
        'remainingDays': trialDays,
        'status': trialDays <= 0
            ? 'Expired'
            : trialDays <= (trialDays * 0.4)
                ? '$trialDays days left'
                : '$trialDays day(s) left',
        'subDestinations': trialSubdestination,
        'editLocations': trialEditLocations,
        'maxLocations': trialMaxLocations,
        'locations': trialLocations,
        'totalUsers': totalTrialUsers,
        'totalUsersVerified': totalTrialUsersVerified,
      };
    } else {
      _trialInfo = {'status': ''}; // No trial case
    }
    notifyListeners();
  }

  /// Update a employee based on the employee ID and new employee data.
  Future<bool> updateUserData(
      BuildContext context, Map<String, dynamic> employeeData) async {
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
          if (context.mounted)
            CustomToast.success(context, response['message']);
        });
        getAllUserData(context, '', '');
      }
      return true;
    } catch (e, stackTrace) {
      // Catch any errors that occur during the process
      print('Stack Trace: $stackTrace'); // Print the stack trace for debugging
      log('Error: $e'); // Log the error
      // Show a generic error message to the user
      // if (context.mounted) CustomToast.error(context, e.toString());
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
      // if (context.mounted) CustomToast.error(context, error);
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
      // if (context.mounted) CustomToast.error(context, e.toString());
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
      // if (context.mounted) CustomToast.error(context, e.toString());
      isLoading = false;
      return []; // Return an empty list in case of error
    }
  }

  /// Get User Team Members from the API
  Future<List<Manager>> getUserTeamMembers(BuildContext context) async {
    try {
      // Set loading state to true
      isUserTeamLoading = true;
      // Use API Service to fetch companies
      ApiService apiService = ApiService(AppConstant.GET_USER_TEAMS);
      // Send a GET request to the API
      Map<String, dynamic> response = await apiService.get();
      // Parse the response into a list of corporateType
      List<Manager> managerList = [];
      List<Reportee>? reporteeList = [];
      List<Delegate> delegateList = [];
      print("Contains Key? ${response.containsKey('users')}");
      // Parse corporateType from the response
      if (response.containsKey('users')) {
        // Parse corporateType from the response
        if (response['users']['my_manager'] != null) {
          managerList = ((response['users']['my_manager'] as List?)
                      ?.map((manager) {
                        if (manager != null) {
                          return Manager.fromJson(manager);
                        }
                        return null;
                      })
                      .where((manager) => manager != null) // Remove null values
                      .toList() ??
                  [])
              .cast<Manager>();
        }

        if (response['users']['my_reportee'] != null) {
          reporteeList = ((response['users']['my_reportee'] as List?)
                      ?.map((reportee) {
                        if (reportee != null) {
                          return Reportee.fromJson(reportee);
                        }
                        return null;
                      })
                      .where(
                          (reportee) => reportee != null) // Remove null values
                      .toList() ??
                  [])
              .cast<Reportee>();
        }

        if (response['users']['my_deligate'] != null) {
          delegateList = ((response['users']['my_deligate'] as List?)
                      ?.map((delegate) {
                        if (delegate != null) {
                          return Delegate.fromJson(delegate);
                        }
                        return null;
                      })
                      .where(
                          (delegate) => delegate != null) // Remove null values
                      .toList() ??
                  [])
              .cast<Delegate>();
        }

        // Similarly handle my_assignee if needed

        print("Manager: $managerList");
        print("Reportee: $reporteeList");
        print("Delegate: $delegateList");

        _myManager = managerList;
        _myReportee = reporteeList;
        _myDeligate = delegateList;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
      }
      isUserTeamLoading = false;
      return managerList;
    } catch (e, stackTrace) {
      // Catch any errors that occur during the process
      print('Stack Trace: $stackTrace'); // Print the stack trace for debugging
      log('Error: $e'); // Log the error
      // Show a generic error message to the user
      // if (context.mounted) CustomToast.error(context, e.toString());
      isUserTeamLoading = false;
      return []; // Return an empty list in case of error
    }
  }

  /// Delete a manager/delegate/reportee based on the employee ID
  Future<bool> deleteTeamMember(
      BuildContext context, String userId, String type) async {
    try {
      // Set loading state to true
      isUserTeamLoading = true;
      // Use API Service to update company status
      ApiService apiService = ApiService(AppConstant.DELETE_TEAM_MEMBER);
      Map<String, dynamic> body = {
        'data': {
          'action': type,
          'user_id': userId,
        },
      };
      // Send a PATCH request to the API
      Map<String, dynamic> response = await apiService.delete(body);
      isUserTeamLoading = false;
      if (context.mounted) {
        CustomToast.success(context, response['message']);
      } else {
        Future.delayed(Duration(seconds: 1), () {
          if (context.mounted)
            CustomToast.success(context, response['message']);
        });
        getUserTeamMembers(context);
      }
      return true;
    } catch (e, stackTrace) {
      // Catch any errors that occur during the process
      print('Stack Trace: $stackTrace'); // Print the stack trace for debugging
      log('Error: $e'); // Log the error
      // Show a generic error message to the user
      // if (context.mounted) CustomToast.error(context, e.toString());
      isUserTeamLoading = false;
      return false; // Return false in case of error
    }
  }

  /// Search a team member based on name and email
  Future<List<NetworkingUsers>> getUserSuggestions(
      BuildContext context, String query) async {
    try {
      // Set loading state to true
      isTeamSearchLoading = true;
      // Use API Service to fetch companies
      ApiService apiService =
          ApiService(AppConstant.GET_NETWORKING_USER_SUGGESTIONS);
      // Send a GET request to the API
      Map<String, dynamic> response =
          await apiService.get('?search=$query&within_company=true');

      // Parse the response into a list of employees
      List<NetworkingUsers> networkingUsersLocal = [];

      print("Response: $response");
      print("Contains Key users? ${response.containsKey('users')}");
      if (response.containsKey('result')) {
        print("Users: ${response['result']}");
        networkingUsersLocal = (response['result'] as List)
            .map((networkUsers) => NetworkingUsers.fromJson(networkUsers))
            .toList();
        print("Networking Users: $networkingUsersLocal");
      }
      // Update the list of companies and notify listeners
      _networkingUsers = networkingUsersLocal;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      isTeamSearchLoading = false;
      return networkingUsersLocal;
    } catch (e, stackTrace) {
      // Catch any errors that occur during the process
      print('Stack Trace: $stackTrace'); // Print the stack trace for debugging
      log('Error: $e'); // Log the error
      // Show a generic error message to the user
      String errorMessage =
          'Error fetching user suggestions. Please try again later.';
      if (e is String) {
        errorMessage = e;
      }
      isTeamSearchLoading = false;
      if (!context.mounted) return [];
      //CustomToast.error(context, errorMessage);
      return []; // Return an empty list in case of error
    }
  }

  /// Add a team member based on the employee ID.
  Future<bool> addTeamMember(
      BuildContext context, String userId, String type) async {
    try {
      // Set loading state to true
      isUserTeamLoading = true;
      // Use API Service to update company status
      ApiService apiService = ApiService(AppConstant.ADD_TEAM_MEMBERS);
      Map<String, dynamic> body = {
        'data': {
          'action': type,
          'user_id': userId,
        },
      };
      // Send a PATCH request to the API
      Map<String, dynamic> response = await apiService.post(body);
      if (context.mounted) {
        CustomToast.success(context, response['message']);
        return true;
      } else {
        isUserTeamLoading = false;
        await Future.delayed(Duration(seconds: 1), () {
          if (context.mounted)
            CustomToast.success(context, response['message']);
        });

        return true;
      }
    } catch (e, stackTrace) {
      // Catch any errors that occur during the process
      print('Stack Trace: $stackTrace'); // Print the stack trace for debugging
      log('Error: $e'); // Log the error
      // Show a generic error message to the user
      // if (context.mounted) CustomToast.error(context, e.toString());
      isUserTeamLoading = false;
      return false; // Return false in case of error
    }
  }

  Future<void> signInRoleBasedSwitch(BuildContext context, Map<String, dynamic> payload) async {

    try {
      ApiService apiService = ApiService('${AppConstant.SWITCH_INDIVIDUAL_URL}');
    var response = await apiService.post(payload);
      if (response['message'] == "Last selected role updated successfully" ) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
              builder: (_) => DashboardScreen()),
        );
        CustomToast.success(context, 'Last selected role updated successfully');
      } else {
        print(response.toString());
        log('Error updating hazard data: ${response['message'] ?? 'Unknown error'}');
      }
    } catch (e, stackTrace) {
      log('Error fetching data: $e');
      print(stackTrace.toString());
      log(stackTrace.toString());
    }
  }
}
