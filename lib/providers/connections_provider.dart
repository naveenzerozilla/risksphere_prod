import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gcaptcha_v3/constants.dart';
import 'package:green/models/company_type_model.dart';
import 'package:green/models/connection_model.dart';
import 'package:green/models/connection_request_model.dart';
import 'package:green/models/networking_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // Import for JSON encoding/decoding
import 'dart:developer'; // Import for logging

import '../design_system/components/custom_toast.dart';
import '../models/company_model.dart';
import '../models/employee_list_model.dart';
import '../models/view_employee_model.dart';
import '../service/api_service.dart';
import '../utils/api_constants.dart';

class ConnectionsProvider with ChangeNotifier {


  bool _isLoading = false;
  bool get isLoading => _isLoading;
  set isLoading(bool value) {
    _isLoading = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  bool _isRequestLoading = false;
  bool get isRequestLoading => _isRequestLoading;
  set isRequestLoading(bool value) {
    _isRequestLoading = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  bool _isRequestActionLoading = false;
  bool get isRequestActionLoading => _isRequestActionLoading;
  set isRequestActionLoading(bool value) {
    _isRequestActionLoading = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  bool _isNetworkLoading = false;
  bool get isNetworkLoading => _isNetworkLoading;
  set isNetworkLoading(bool value) {
    _isNetworkLoading = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  bool _isConnectLoading = false;
  bool get isConnectLoading => _isConnectLoading;
  set isConnectLoading(bool value) {
    _isConnectLoading = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  List<CorporateConnection> _corporateConnections = [];
  List<CorporateConnection> get corporateConnections => _corporateConnections;

  List<NonCorporateConnection> _nonCorporateConnections = [];
  List<NonCorporateConnection> get nonCorporateConnections => _nonCorporateConnections;

  List<RequestUser> _requestUsers = [];
  List<RequestUser> get requestUsers => _requestUsers;

  List<NetworkingUsers> _networkingUsers = [];
  List<NetworkingUsers> get networkingUsers => _networkingUsers;

  String totalConnections = '0';
  String requestReceivedCount = '0';

  /// Fetches all connections Corporate and Non Corporate from the API.
  Future<List<NetworkingUsers>> getAllConnections(BuildContext context, String userId) async {
    try {
      // Set loading state to true
      isLoading = true;
      // Use API Service to fetch companies
      ApiService apiService = ApiService(AppConstant.GET_CONNECTIONS);
      // Send a GET request to the API
      Map<String, dynamic> response = await apiService.get('&user_id=$userId');

      // Parse the response into a list of employees
      List<CorporateConnection> corporateConnections = [];
      List<NonCorporateConnection> nonCorporateConnections = [];

      print("Response: $response");
      print("Contains Key user? ${response.containsKey('users')}");
      if (response.containsKey('users')) {
        print("Users: ${response['users']}");
        print("Contains Key corporate? ${response['users'].containsKey('corporate')}");
        if (response['users'].containsKey('corporate')) {
          corporateConnections = (response['users']['corporate'] as List)
              .map((corporate) => CorporateConnection.fromJson(corporate))
              .toList();
        }
        print("Contains Key non-corporate? ${response['users'].containsKey('non-corporate')}");
        if (response['users'].containsKey('non-corporate')) {
          nonCorporateConnections = (response['users']['non-corporate'] as List)
              .map((nonCorporate) => NonCorporateConnection.fromJson(nonCorporate))
              .toList();
        }
      }
      print("Corporate Connections: $corporateConnections");
      print("Non Corporate Connections: $nonCorporateConnections");
      if (response.containsKey('total_connections')) {
        totalConnections = response['total_connections'];
      }
      if (response.containsKey('request_received_count')) {
        requestReceivedCount = response['request_received_count'];
      }
      // Update the list of companies and notify listeners
      _corporateConnections = corporateConnections;
      _nonCorporateConnections = nonCorporateConnections;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      isLoading = false;
      return [];

    } catch (e, stackTrace) {
      // Catch any errors that occur during the process
      print('Stack Trace: $stackTrace'); // Print the stack trace for debugging
      log('Error: $e'); // Log the error
      // Show a generic error message to the user
      // TODO: Display a generic error message to the user

      isLoading = false;
      if (!context.mounted) return[];
      CustomToast.error(context, 'Error fetching connections. Please try again later.');
      return []; // Return an empty list in case of error
    }
  }

  /// Fetches all requests from the API.
  Future<List<RequestUser>> getAllRequests(BuildContext context, String userId) async {
    try {
      // Set loading state to true
      isRequestLoading = true;
      // Use API Service to fetch companies
      ApiService apiService = ApiService(AppConstant.GET_REQUESTS);
      // Send a GET request to the API
      Map<String, dynamic> response = await apiService.get('&user_id=$userId');

      // Parse the response into a list of employees
      List<RequestUser> requestUsers = [];

      print("Response: $response");
      print("Contains Key user? ${response.containsKey('users')}");
      if (response.containsKey('users')) {
        print("Users: ${response['users']}");
        print("Contains Key users? ${response['users'].containsKey('users')}");
        if (response['users'].containsKey('users')) {
          requestUsers = (response['users']['users'] as List)
              .map((requestUser) => RequestUser.fromJson(requestUser))
              .toList();
          print("Request Users: $requestUsers");
        }
        if (response['users'].containsKey('total_connections')) {
          totalConnections = response['users']['total_connections'].toString();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            notifyListeners();
          });
        }
        if (response['users'].containsKey('request_received_count')) {
          requestReceivedCount = response['users']['request_received_count'].toString();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            notifyListeners();
          });
        }
      }
      print("Request Users: $requestUsers");
      if (response.containsKey('total_connections')) {
        totalConnections = response['total_connections'];
      }
      if (response.containsKey('request_received_count')) {
        requestReceivedCount = response['request_received_count'];
      }
      // Update the list of companies and notify listeners
      _requestUsers = requestUsers;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      isRequestLoading = false;
      return [];
    } catch (e, stackTrace) {
      // Catch any errors that occur during the process
      print('Stack Trace: $stackTrace'); // Print the stack trace for debugging
      log('Error: $e'); // Log the error
      // Show a generic error message to the user
      String errorMessage = 'Error fetching requests. Please try again later.';
      if (e is String) {
        errorMessage = e;
      }
      if (!context.mounted) return [];
      CustomToast.error(context, errorMessage);
      isRequestLoading = false;
      return []; // Return an empty list in case of error
    }
  }

  /// Accepts or rejects a connection request.
  Future<void> acceptRejectRequest(BuildContext context, String userId, String action) async {
    try {
      // Set loading state to true
      isRequestActionLoading = true;
      // Use API Service to fetch companies
      ApiService apiService = ApiService(AppConstant.ACCEPT_REJECT_REQUEST);
      // Send a GET request to the API
      var body = {
        "data": {
          "action": action,
          "user_id": userId,
        }
      };
      Map<String, dynamic> response = await apiService.post(
        body,
      );

      // Parse the response into a list of employees
      print("Response: $response");
      if (response.containsKey('message')) {
        CustomToast.success(context, response['message']);
      }
      // Update the list of companies and notify listeners
      isRequestActionLoading = false;
      getAllRequests(context, userId);
    } catch (e, stackTrace) {
      // Catch any errors that occur during the process
      print('Stack Trace: $stackTrace'); // Print the stack trace for debugging
      log('Error: $e'); // Log the error
      // Show a generic error message to the user
      String errorMessage = 'Error accepting/rejecting request. Please try again later.';
      if (e is String) {
        errorMessage = e;
      }
      if (!context.mounted) return;
      CustomToast.error(context, errorMessage);
      isRequestActionLoading = false;
    }
  }


  /// Fetches user suggestions from the API based on the search query.
  Future<List<NetworkingUsers>> getUserSuggestions(BuildContext context, String query) async {
    try {
      // Set loading state to true
      isNetworkLoading = true;
      // Use API Service to fetch companies
      ApiService apiService = ApiService(AppConstant.GET_NETWORKING_USER_SUGGESTIONS);
      // Send a GET request to the API
      Map<String, dynamic> response = await apiService.get('?search=$query');

      // Parse the response into a list of employees
      List<NetworkingUsers> networkingUsersLocal = [];

      print("Response: $response");
      print("Contains Key users? ${response.containsKey('users')}");
      if (response.containsKey('users')) {
        print("Users: ${response['users']}");
          networkingUsersLocal = (response['users'] as List)
              .map((networkUsers) => NetworkingUsers.fromJson(networkUsers))
              .toList();
          print("Networking Users: $networkingUsersLocal");
      }
      // Update the list of companies and notify listeners
      _networkingUsers = networkingUsersLocal;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      isNetworkLoading = false;
      return networkingUsersLocal;
    } catch (e, stackTrace) {
      // Catch any errors that occur during the process
      print('Stack Trace: $stackTrace'); // Print the stack trace for debugging
      log('Error: $e'); // Log the error
      // Show a generic error message to the user
      String errorMessage = 'Error fetching user suggestions. Please try again later.';
      if (e is String) {
        errorMessage = e;
      }
      isNetworkLoading = false;
      if (!context.mounted) return [];
      CustomToast.error(context, errorMessage);
      return []; // Return an empty list in case of error
    }
  }

  /// Connects with a user. (Sends a networking request)
  Future<bool> connectUser(BuildContext context, String userId, String message) async {
    try {
      // Set loading state to true
      isConnectLoading = true;
      // Use API Service to fetch companies
      ApiService apiService = ApiService(AppConstant.SEND_NETWORKING_REQUEST);
      // Send a POST request to the API
      var body = {
        "data": {
          "action": "send_request",
          "user_id": userId,
          "message": message,
        }
      };
      Map<String, dynamic> response = await apiService.post(
        body,
      );

      // Parse the response into a list of employees
      print("Response: $response");
      if (response.containsKey('message')) {
        CustomToast.success(context, response['message']);
      }
      // Update the list of companies and notify listeners
      isConnectLoading = false;
      getAllConnections(context, userId);
      getAllRequests(context, userId);
      return true;
    } catch (e, stackTrace) {
      // Catch any errors that occur during the process
      print('Stack Trace: $stackTrace'); // Print the stack trace for debugging
      log('Error: $e'); // Log the error
      // Show a generic error message to the user
      String errorMessage = 'Error connecting with user. Please try again later.';
      if (e is String) {
        errorMessage = e;
      }
      if (!context.mounted) return false;
      CustomToast.error(context, errorMessage);
      isConnectLoading = false;
      return false;
    }
  }

}