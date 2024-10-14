import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gcaptcha_v3/constants.dart';
import 'package:green/models/maintainance_model.dart';
import 'package:green/service/api_service.dart';

import '../utils/api_constants.dart';

class JobMonitoringProvider extends ChangeNotifier {

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  set isLoading(bool val) {
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      _isLoading = val;
      notifyListeners();
    });
  }

  bool _isAddLoading = false;

  bool get isAddLoading => _isAddLoading;

  set isAddLoading(bool val) {
    _isAddLoading = val;
    notifyListeners();
  }

  bool _isEditLoading = false;

  bool get isEditLoading => _isEditLoading;

  set isEditLoading(bool val) {
    _isEditLoading = val;
    notifyListeners();
  }

  bool _isDeleteLoading = false;

  bool get isDeleteLoading => _isDeleteLoading;

  set isDeleteLoading(bool val) {
    _isDeleteLoading = val;
    notifyListeners();
  }

  final _fireStore = FirebaseFirestore.instance;

  late Stream<QuerySnapshot> _jobMonitoringData;

  List<MaintainanceModel> maintainancePeriods = [];

  JobMonitoringProvider() {
    _jobMonitoringData = getJobMonitoringData();
  }

  // Store whether the user is a super admin
  bool _isSuperAdmin = false;

  bool get isSuperAdmin => _isSuperAdmin;

  // Store the fetched list of document IDs
  List<String> _docIds = [];

  List<String> get docIds => _docIds;

  // Get Job Monitoring Data Stream (based on user role and document IDs)
  Stream<QuerySnapshot> getJobMonitoringData() {
    if (_isSuperAdmin) {
      // Fetch all processes if the user is a super admin
      return _fireStore.collection('processes').orderBy('created_at', descending: true).snapshots();
    } else if (_docIds.isNotEmpty) {
      // Fetch processes matching the document IDs if not a super admin
      return _fireStore
          .collection('processes')
          .where(FieldPath.documentId, whereIn: _docIds)
          .orderBy('created_at', descending: true)
          .snapshots();
    } else {
      // Return an empty stream if there are no document IDs
      return Stream.empty();
    }
  }

  Stream<QuerySnapshot> get jobMonitoringData => _jobMonitoringData;


  // Function to fetch company IDs from the API
  Future<void> fetchCompanyIds() async {
    try {
      isLoading = true;
      ApiService apiService = ApiService(
          AppConstant.GET_JOB_MONITORING); // Replace with correct endpoint
      var response = await apiService.get('?monitoring_processes=true');
      print(response);

      // Check if the user is a super admin
      _isSuperAdmin = response['is_super_admin'] ?? false;

      // If not a super admin, fetch the result (list of document IDs)
      if (!_isSuperAdmin) {
        _docIds = List<String>.from(response['result'] ?? []);
      }

      isLoading = false;
      notifyListeners();
    } catch (e, stack) {
      isLoading = false;
      print(e);
      print(stack);
    }
  }


  // Add maintainance period
  Future<String> addMaintainancePeriod(String processStartTime,
      String processEndTime) async {
    try {
      // Convert to UTC
      var body = {
        "data": {
          'start_time': processStartTime,
          'end_time': processEndTime
        }
      };

      isAddLoading = true;
      print(jsonEncode(body));
      ApiService apiService = ApiService(AppConstant.GET_JOB_MONITORING);
      var response = await apiService.post(body);
      print(response);
      /*final HttpsCallable callable =
      FirebaseFunctions.instance.httpsCallable('job_monitoring');
      final result = await callable.call(body);*/
      isAddLoading = false;
      //print(result.data);
      return response['message'];
    } on BackendException catch (e) {
      isAddLoading = false;
      print(e.message);
      return e.message;
    }
    catch (e, stack) {
      isAddLoading = false;
      print(e);
      print(stack);
      return 'error';
    }
  }

  // Get Maintainance period
  Future<void> getMaintainancePeriod() async {
    try {
      isLoading = true;
      print('getMaintainancePeriod');
      ApiService apiService = ApiService(AppConstant.GET_JOB_MONITORING);
      var response = await apiService.get();
      isLoading = false;
      print(response);
      MaintainanceResponse maintainanceResponse = MaintainanceResponse.fromJson(
          response);
      maintainancePeriods = maintainanceResponse.results!;
      print(maintainancePeriods);
    } catch (e, stack) {
      isLoading = false;
      print(e);
      print(stack);
    }
  }

  // Edit maintainance period
  Future<String> editMaintainancePeriod(String processStartTime,
      String processEndTime, String id) async {
    try {
      var body = {
        "data": {
          'id': id,
          'start_time': processStartTime,
          'end_time': processEndTime
        }
      };

      isLoading = true;
      ApiService apiService = ApiService('${AppConstant.GET_JOB_MONITORING}');
      var response = await apiService.patch(body);
      isLoading = false;
      return 'Update successful';
    } catch (e, stack) {
      isLoading = false;
      return 'Update failed';
    }
  }


  // Delete maintainance period
  Future<bool> deleteMaintainancePeriod(String id) async {
    try {
      isDeleteLoading = true;
      ApiService apiService = ApiService(
          '${AppConstant.GET_JOB_MONITORING}/$id');
      var body = {
        "data": {
          'id': id
        }
      };
      var response = await apiService.delete(body);
      print(response);
      isDeleteLoading = false;
      return true;
    } catch (e, stack) {
      isDeleteLoading = false;
      print(e);
      print(stack);
      return false;
    }
  }




}