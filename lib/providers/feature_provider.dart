import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gcaptcha_v3/constants.dart';
import 'package:RiskSphare/models/company_type_model.dart';
import 'package:RiskSphare/models/feature_list_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // Import for JSON encoding/decoding
import 'dart:developer'; // Import for logging

import '../design_system/components/custom_toast.dart';
import '../models/company_model.dart';
import '../service/api_service.dart';
import '../utils/api_constants.dart';

class FeatureProvider with ChangeNotifier {

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  set isLoading(bool value) {
    _isLoading = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  bool _isCreateFeatureLoading = false;
  bool get isCreateFeatureLoading => _isCreateFeatureLoading;
  set isCreateFeatureLoading(bool value) {
    _isCreateFeatureLoading = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  bool _isSubFeatureListLoading = false;
  bool get isSubFeatureListLoading => _isSubFeatureListLoading;
  set isSubFeatureListLoading(bool value) {
    _isSubFeatureListLoading = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  bool _isCreateSubFeatureLoading = false;
  bool get isCreateSubFeatureLoading => _isCreateSubFeatureLoading;
  set isCreateSubFeatureLoading(bool value) {
    _isCreateSubFeatureLoading = value; // Use the private variable here
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  List<Features?> _features = [];
  List<Features?> get features => _features;

  List<SubFeatures?> _subFeatures = [];
  List<SubFeatures?> get subFeatures => _subFeatures;

  /// Fetches all features from the API
  Future<List<Features?>> getAllFeatures(BuildContext context) async {
    try {
      // Set loading state to true
      isLoading = true;
      // Use API Service to fetch features
      ApiService apiService = ApiService(AppConstant.GET_FEATURE_LIST);
      // Send a GET request to the API
      Map<String, dynamic> response = await apiService.get();

      // Parse the response into a list of features
      List<Features> features = [];
      if (response.containsKey('features')) {
        features = (response['features'] as List)
            .map((company) => Features.fromJson(company))
            .toList();
      }
      // Update the list of features and notify listeners
      _features = features;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      isLoading = false;
      return features;

    } catch (e, stackTrace) {
      // Catch any errors that occur during the process
      print('Stack Trace: $stackTrace'); // Print the stack trace for debugging
      log('Error: $e'); // Log the error
      // Show a generic error message to the user
      // TODO: Display a generic error message to the user

      isLoading = false;
      if (!context.mounted) return[];
      CustomToast.error(context, 'Error fetching features. Please try again later.');
      return []; // Return an empty list in case of error
    }
  }

  /// Changes status of a feature based on the feature ID and new status.
  Future<void> changeFeatureStatus(BuildContext context, String featureId, bool newStatus) async {
    try {
      // Set loading state to true
      isLoading = true;
      // Use API Service to change feature status
      ApiService apiService = ApiService(AppConstant.GET_FEATURE_LIST);
      // Send a PUT request to the API with the feature ID and new status
      Map<String, dynamic> response = await apiService.put({
        'feature_id': featureId,
        'status': newStatus,
      });
      // Check if the response contains a success message
      if (response.containsKey('message')) {
        // Show a success message to the user
        CustomToast.success(context, response['message']);
      } else {
        // Show a generic error message to the user
        CustomToast.error(context, 'Error changing feature status. Please try again later.');
      }
      // Fetch all features again to update the list
      await getAllFeatures(context);
    } catch (e, stackTrace) {
      // Catch any errors that occur during the process
      print('Stack Trace: $stackTrace'); // Print the stack trace for debugging
      log('Error: $e'); // Log the error
      // Show a generic error message to the user
      CustomToast.error(context, 'Error changing feature status. Please try again later.');
    }
  }

  /// Creates a new feature with the provided name and sub-features.
/// {
//     "data":{
//         "feature":"ZZZ",
//         "feature_name":"Zee"
//         // "subfeature":"dxsd",
//         // "subfeature_name":"sxsx"
//     }
// }
  Future<void> createFeature(BuildContext context, String featureName, String featureTag) async {
    try {
      // Set loading state to true
      isCreateFeatureLoading = true;
      // Use API Service to create a new feature
      ApiService apiService = ApiService(AppConstant.ADD_FEATURE);
      // Send a POST request to the API with the feature name and sub-feature name
      Map<String, dynamic> response = await apiService.post({'data':{
        'feature': featureTag,
        'feature_name': featureName,
      }});
      // Check if the response contains a success message
      if (response.containsKey('mesaage')) {
        // Show a success message to the user
        CustomToast.success(context, response['mesaage']);
      } else {
        // Show a generic error message to the user
        CustomToast.error(context, response['error'] ?? 'Error creating feature. Please try again later.');
      }
      // Fetch all features again to update the list
      isCreateFeatureLoading = false;
      await getAllFeatures(context);
    } catch (e, stackTrace) {
      // Catch any errors that occur during the process
      print('Stack Trace: $stackTrace'); // Print the stack trace for debugging
      log('Error: $e'); // Log the error
      // Show a generic error message to the user
      CustomToast.error(context, 'Error creating feature. Please try again later.');
      isCreateFeatureLoading = false;
    }
  }

  /// Fetched All Sub Features based on the feature ID
  Future<List<SubFeatures?>> getSubFeatures(BuildContext context, String featureId) async {
    try {
      // Set loading state to true
      isSubFeatureListLoading = true;
      // Use API Service to fetch features
      ApiService apiService = ApiService(AppConstant.GET_FEATURE_LIST);
      // Send a GET request to the API
      Map<String, dynamic> response = await apiService.get('?feature=$featureId');

      // Parse the response into a list of features
      // {"featue":"BCNT","feature_name":"Black cap new 2","subfeatures":[{"name":"new","tag":"NEW"},{"name":"new2","tag":"NEW2"},{"name":"gsgs","tag":"SGGS"}]}
      List<SubFeatures> subFeatures = [];
      print("containsKey: ${response.containsKey('subfeatures')}");
      if (response.containsKey('subfeatures')) {
        subFeatures = (response['subfeatures'] as List)
            .map((company) => SubFeatures.fromJson(company))
            .toList();
      }
      print('Sub Features: $subFeatures');
      // Update the list of features and notify listeners
      _subFeatures = subFeatures;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      isSubFeatureListLoading = false;
      return subFeatures;
    } catch (e, stackTrace) {
      // Catch any errors that occur during the process
      print('Stack Trace: $stackTrace'); // Print the stack trace for debugging
      log('Error: $e'); // Log the error
      // Show a generic error message to the user
      CustomToast.error(
          context, 'Error fetching sub features. Please try again later.');
      isSubFeatureListLoading = false;
      return []; // Return an empty list in case of error
    }
  }

  /// Create Sub Feature based on the feature ID
  Future<void> createSubFeature(BuildContext context, String featureName, String featureTag, String subFeatureName, String subFeatureTag) async {
    try {
      // Set loading state to true
      isCreateSubFeatureLoading = true;
      // Use API Service to create a new feature
      ApiService apiService = ApiService(AppConstant.ADD_FEATURE);
      // Send a POST request to the API with the feature name and sub-feature name
      Map<String, dynamic> response = await apiService.post({
        "data":{
          "feature":featureTag,
          "subfeature":subFeatureTag,
          "subfeature_name":subFeatureName,
        }
      });
      // Check if the response contains a success message
      if (response.containsKey('mesaage')) {
        // Show a success message to the user
        CustomToast.success(context, response['mesaage']);
      } else {
        // Show a generic error message to the user
        CustomToast.error(context, response['error'] ?? 'Error creating sub feature. Please try again later.');
      }
      // Fetch all features again to update the list
      isCreateSubFeatureLoading = false;
      await getSubFeatures(context, featureTag);
    } catch (e, stackTrace) {
      // Catch any errors that occur during the process
      print('Stack Trace: $stackTrace'); // Print the stack trace for debugging
      log('Error: $e'); // Log the error
      // Show a generic error message to the user
      CustomToast.error(context, 'Error creating sub feature. Please try again later.');
      isCreateSubFeatureLoading = false;
    }
  }

}