import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gcaptcha_v3/constants.dart';
import 'package:RiskSphare/models/company_type_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // Import for JSON encoding/decoding
import 'dart:developer'; // Import for logging

import '../design_system/components/custom_toast.dart';
import '../models/company_model.dart';
import '../service/api_service.dart';
import '../utils/api_constants.dart';

class CompanyProvider with ChangeNotifier {
  /// Loading state variables
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  set isLoading(bool value) {
    _isLoading = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  bool _isCompanyListLoading = false;
  bool get isCompanyListLoading => _isCompanyListLoading;
  set isCompanyListLoading(bool value) {
    _isCompanyListLoading = value;
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

  ///Pagination variables
 /* String? companyListPageToken;
  String? companyListDirection;
  bool companyListNextPageExists = true;*/

  /// Pagination variables
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


  /// Data variables
  List<Companies> _companies = [];

  List<Companies> get companies => _companies;

  List<CorporateType> _corporateType = [];

  List<CorporateType> get corporateType => _corporateType;

  Companies _company = Companies();

  Companies get company => _company;

  /// Fetches all companies from the API based on search text and filter criteria.
  Future<List<Companies>> getAllCompanies(
      BuildContext context,
      String searchText,
      String companyTypeFilter,
      String role, {
        bool isSearch = false,
      }) async {
    try {
      if (isSearch) {
        _page = 1;
        _companies.clear();
      }

      // Prevent loading if already in progress or no more pages
      if (isLoading || isNextPageLoading || _page > _totalPages) return _companies;

      // Set loading state
      if (_page == 1) {
        _companies.clear();
        isLoading = true;
      } else {
        isNextPageLoading = true;
      }

      // Build query parameters
      String url = AppConstant.CORPORATE_MANAGEMENT_URL_NEW;
      String additionalParams = "?page=$_page&pageSize=10";
      if (searchText.isNotEmpty) additionalParams += "&search=$searchText";
      if (companyTypeFilter.isNotEmpty) additionalParams += "&company_filter=$companyTypeFilter";
      if (role.isNotEmpty) additionalParams += "&role_filter=$role";

      // Make API call
      ApiService apiService = ApiService(url + additionalParams);
      Map<String, dynamic> response = await apiService.get();

      // Parse response
      if (response.containsKey('result')) {
        List<Companies> companiesLocal = (response['result'] as List)
            .map((company) => Companies.fromJson(company))
            .toList();
        _companies.addAll(companiesLocal);
      }

      // Update pagination
      if (response.containsKey('totalRecords')) {
        int totalRecords = response['totalRecords'];
        _totalPages = (totalRecords / 10).ceil(); // Assuming pageSize is 10
      } else {
        _totalPages = 1; // Default to 1 if not provided
      }

      // Reset loading states
      isLoading = false;
      isNextPageLoading = false;

      notifyListeners();
      return _companies;
    } catch (e, stackTrace) {
      log('Error: $e');
      print('Stack Trace: $stackTrace');

      // Reset loading states
      isLoading = false;
      isNextPageLoading = false;

      if (context.mounted) {
        CustomToast.error(context, 'Error fetching companies. Please try again later.');
      }
      return [];
    }
  }


  /// Changes status of a company based on the company ID and new status.
  Future<bool> changeCompanyStatus(
      BuildContext context, String companyId, bool newStatus) async {
    try {
      // Set loading state to true
      isStatusLoading = true;
      // Use API Service to update company status
      ApiService apiService = ApiService(AppConstant.CORPORATE_MANAGEMENT_URL);
      Map<String, dynamic> body = {
        'data': {
          'company_id': companyId,
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
  Future<bool> deleteCompany(
      BuildContext context, List<String> companyIds) async {
    try {
      // Set loading state to true
      isDeleteLoading = true;
      // Use API Service to update company status
      ApiService apiService = ApiService(AppConstant.CORPORATE_MANAGEMENT_URL);
      Map<String, dynamic> body = {
        'data': {
          'company_id': companyIds,
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

  /// Delete Multiple Companies based on the company ID.
  Future<bool> deleteMultipleCompanies(
      BuildContext context, List<String> companyIds) async {
    try {
      // Set loading state to true
      isLoading = true;
      // Use API Service to update company status
      ApiService apiService = ApiService(AppConstant.CORPORATE_MANAGEMENT_URL);
      Map<String, dynamic> body = {
        'data': {
          'company_id': companyIds,
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

  /// Create a new company based on the company data.
  Future<bool> createCompany(
      BuildContext context, Map<String, dynamic> companyData) async {
    try {
      // Set loading state to true
      isLoading = true;
      // Use API Service to update company status
      ApiService apiService = ApiService(AppConstant.CREATE_CORPORATE_URL);
      Map<String, dynamic> body = {
        'data': companyData,
      };
      print("Body: $body");
      // Send a POST request to the API
      Map<String, dynamic> response = await apiService.post(body);
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

  /// Update a company based on the company ID and new company data.
  Future<bool> updateCompany(
      BuildContext context, Map<String, dynamic> companyData) async {
    try {
      // Set loading state to true
      isLoading = true;
      // Use API Service to update company status
      ApiService apiService = ApiService(AppConstant.UPDATE_CORPORATE_URL);
      Map<String, dynamic> body = {
        'data': companyData,
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
      }
      getAllCompanies(context, "", "", "");
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

  /// View a company based on the company ID.
  Future<Companies> viewCompany(BuildContext context, String companyId) async {
    try {
      // Set loading state to true
      isLoading = true;
      // Use API Service to update company status
      ApiService apiService = ApiService(AppConstant.CORPORATE_MANAGEMENT_URL_NEW);
      // Send a GET request to the API

      Map<String, dynamic> response =
          await apiService.get("?company_id=$companyId");
      isLoading = false;

      if (response.containsKey('company')) {
        Map<String, dynamic> companiesJson = response['company'];
        Companies companies =Companies.fromJson(companiesJson);

        _company = companies;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
        return companies;
      } else {
        return Companies();
      }

    } catch (e, stackTrace) {
      // Catch any errors that occur during the process
      print('Stack Trace: $stackTrace'); // Print the stack trace for debugging
      log('Error: $e'); // Log the error
      // Show a generic error message to the user
      if (context.mounted) CustomToast.error(context, e.toString());
      isLoading = false;
      return Companies(); // Return empty list in case of error
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
  Future<List<CorporateType>> getCorporateType(BuildContext context) async {
    try {
      // Set loading state to true
      isLoading = true;
      // Use API Service to fetch companies
      ApiService apiService = ApiService(AppConstant.GET_CORPORATE_ROLES);
      // Send a GET request to the API
      Map<String, dynamic> response = await apiService.get();
      // Parse the response into a list of corporateType
      List<CorporateType> corporateType = [];
      print("Contains Key? ${response.containsKey('corporate_type')}");
      if (response.containsKey('corporate_type')) {
        // Parse corporateType from the response
        corporateType = (response['corporate_type'] as List)
            .map((corporateType) => CorporateType.fromJson(corporateType))
            .toList();

        _corporateType = corporateType;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
      }
      isLoading = false;
      return corporateType;
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
