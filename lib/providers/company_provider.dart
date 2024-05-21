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
  String? companyListPageToken;
  String? companyListDirection;
  bool companyListNextPageExists = true;

  /// Data variables
  List<Companies> _companies = [];

  List<Companies> get companies => _companies;

  List<CorporateType> _corporateType = [];

  List<CorporateType> get corporateType => _corporateType;

  Companies _company = Companies();

  Companies get company => _company;

  /// Fetches all companies from the API based on search text and filter criteria.
  Future<List<Companies>> getAllCompanies(BuildContext context,
      String searchText, String companyTypeFilter, String role, [bool isSearch = false]) async {
    try {
      // Clear normal pagination is isSearch is true
      if (isSearch) {
        companyListPageToken = null;
        companyListNextPageExists = true;
      }
      // Check if api is already working
      if (isLoading||isCompanyListLoading) return _companies;
      // dont call api is next page does not exist
      if (!companyListNextPageExists) return _companies;
      // Set loading state to true
      if(companyListPageToken == null && companyListNextPageExists) {
        _companies = [];
        isLoading = true;
      } else {
        isCompanyListLoading = true;
      }
      // Use API Service to fetch companies
      ApiService apiService = ApiService(AppConstant.CORPORATE_MANAGEMENT_URL);
      String additionalParams = "";
      if (searchText.isNotEmpty) {
        additionalParams += "&search=$searchText";
      }
      if (companyTypeFilter.isNotEmpty) {
        additionalParams += "&company_filter=$companyTypeFilter";
      }
      if (role.isNotEmpty) {
        additionalParams += "&role_filter=$role";
      }
      if (companyListPageToken != null) {
        additionalParams += "&pagetoken=$companyListPageToken&direction=forward";
      }

      additionalParams += "&pageSize=2";

      // Construct the URL with correct formatting
      String url = AppConstant.CORPORATE_MANAGEMENT_URL;
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


      // Send a GET request to the API
      Map<String, dynamic> response = await apiService.get(url);

      // Parse the response into a list of companies
      List<Companies> companiesLocal = [];
      if (response.containsKey('companies')) {
        companiesLocal = (response['companies'] as List)
            .map((company) => Companies.fromJson(company))
            .toList();
      }
      if (response.containsKey('pageToken')) {
        companyListPageToken = response['pageToken'];
      } else {
        companyListPageToken = null;
      }
      if (response.containsKey('nextPageExists')) {
        companyListNextPageExists = response['nextPageExists'];
        if (!companyListNextPageExists) {
          companyListPageToken = null;
        }
      } else {
        companyListNextPageExists = false;
      }
      // Update the list of companies and notify listeners
      _companies.addAll(companiesLocal);

      isLoading = false;
      isCompanyListLoading = false;
        notifyListeners();

      return _companies;
    } catch (e, stackTrace) {
      // Catch any errors that occur during the process
      print('Stack Trace: $stackTrace'); // Print the stack trace for debugging
      log('Error: $e'); // Log the error
      // Show a generic error message to the user
      // TODO: Display a generic error message to the user

      isLoading = false;
      isCompanyListLoading = false;
      if (!context.mounted) return [];
      CustomToast.error(
          context, 'Error fetching companies. Please try again later.');
      return []; // Return an empty list in case of error
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
      ApiService apiService = ApiService(AppConstant.CORPORATE_MANAGEMENT_URL);
      // Send a GET request to the API
      Map<String, dynamic> response =
          await apiService.get("?company_id=$companyId");
      isLoading = false;
      if (response.containsKey('company')) {
        List<dynamic> companiesJson = response['company'];
        List<Companies> companies =
            companiesJson.map((json) => Companies.fromJson(json)).toList();
        _company = companies[0];
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
        return companies[0];
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
