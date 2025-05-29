import 'dart:convert';

import 'package:async/async.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:RiskSphere/models/maintainance_model.dart';
import 'package:RiskSphere/service/api_service.dart';
import '../utils/api_constants.dart';

class JobMonitoringProvider extends ChangeNotifier {
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  set isLoading(bool val) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isLoading = val;
      notifyListeners();
    });
  }

  bool _isSummaryLoading = false;
  bool get isSummaryLoading => _isSummaryLoading;
  set isSummaryLoading(bool val) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isSummaryLoading = val;
      notifyListeners();
    });
  }
  //processing
  bool _isProcessing = false;
  String _processStatus = 'completed'; // Default status

  bool get isProcessing => _isProcessing;
  String get processStatus => _processStatus;
  void updateProcessStatus(String newStatus) {
    if (_processStatus != newStatus) {
      _processStatus = newStatus;
      _isProcessing = newStatus.toLowerCase() == 'processing';

      notifyListeners();
    }
  }


  // void setProcessing(bool value) {
  //   _isProcessing = value;
  //   notifyListeners();
  // }




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

  // Whether the user is a super admin
  bool _isSuperAdmin = false;

  bool get isSuperAdmin => _isSuperAdmin;

  // List of document IDs for specific processes
  List<String> _docIds = [];

  List<String> get docIds => _docIds;

  List<MaintainanceModel> maintainancePeriods = [];

  // Fetch Job Monitoring Data (handle batching for `whereIn` clause)
  /*Stream<QuerySnapshot> getJobMonitoringData() {
    if (_isSuperAdmin) {
      // Fetch all processes if the user is a super admin
      return _fireStore
          .collection('processes')
          .orderBy('created_at', descending: true)
          .snapshots();
    } else if (_docIds.isNotEmpty) {
      // Fetch processes in batches of 30
      List<Stream<QuerySnapshot>> streams = [];
      const batchSize = 30;

      for (int i = 0; i < _docIds.length; i += batchSize) {
        final batch = _docIds.sublist(
          i,
          i + batchSize > _docIds.length ? _docIds.length : i + batchSize,
        );

        streams.add(
          _fireStore
              .collection('processes')
              .where(FieldPath.documentId, whereIn: batch)
              .snapshots(),
        );
      }

      // Merge all streams
      return StreamGroup.merge(streams);
    } else {
      // Return an empty stream if there are no document IDs
      return Stream.empty();
    }
  }*/

  // Fetch Job Monitoring Data (handle filtering by `company_id`)
  Stream<QuerySnapshot<Map<String, dynamic>>> getJobMonitoringData(String accountId, String subAccountId) {
    // if (_isSuperAdmin) {
    //   // Fetch all processes if the user is a super admin
    //   return _fireStore
    //       .collection('processes')
    //
    //       .where('process_type', isEqualTo: 'hazard')
    //       .orderBy('created_at', descending: true)
    //       .snapshots();
    // }
    //
    // if (_docIds.isNotEmpty) {
    //   // Query for non-super-admins filtered by company IDs
    //   return _fireStore
    //       .collection('processes')
    //       .where('company_id', whereIn: _docIds) // Filter by company IDs
    //
    //       .where('process_type', isEqualTo: 'hazard')
    //
    //       .orderBy('created_at', descending: true)
    //       .snapshots();
    // }
      return _fireStore
          .collection('processes')

          .where('process_type', isEqualTo: 'hazard')
          .orderBy('created_at', descending: true)
          .snapshots();

    // Return an empty stream if there are no company IDs
    return Stream.empty();
  }

  // Fetch Summary for both process and sub process
  Future<Map<String, dynamic>?> fetchSummary(String id) async {
    try {
      isSummaryLoading = true; // Trigger loader
      notifyListeners();

      // Initialize the API service
      ApiService apiService = ApiService('${AppConstant.GET_JOB_MONITORING_SUMMARY}/$id');
      final response = await apiService.get();

      if (response != null) {
        print('Summary Data: $response');
        return response;
      }
      return null; // Handle null response
    } catch (error) {
      print('Error fetching summary: $error');
      return null;
    } finally {
      isSummaryLoading = false; // Stop loader
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> fetchLocationSummary(String accountId,String subaccountId) async {
    try {
      isSummaryLoading = true; // Trigger loader
      notifyListeners();
      print('${AppConstant.LOCATION_SUMMARY}?account_id=$accountId&sub_account_id=$subaccountId');
      // Initialize the API service
      ApiService apiService = ApiService('${AppConstant.LOCATION_SUMMARY}?account_id=$accountId&sub_account_id=$subaccountId');

      final response = await apiService.get();

      if (response != null) {
        print('Summary Data: $response');
        print('Summary Data: ${response.length}');
        return response;
      }
      return null; // Handle null response
    } catch (error) {
      print('Error fetching summary: $error');
      return null;
    } finally {
      isSummaryLoading = false; // Stop loader
      notifyListeners();
    }
  }



/*  // Fetch company IDs from the API
  Future<void> fetchCompanyIds() async {
    try {
      isLoading = true;

      ApiService apiService = ApiService(AppConstant.GET_JOB_MONITORING);
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
  }*/

  // Fetch company IDs from the API
  Future<void> fetchCompanyIds() async {
    isLoading = true; // Start loading
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners(); // Notify listeners to reflect loading state
    });

    try {
      // Initialize the API service
      final ApiService apiService = ApiService(AppConstant.GET_JOB_MONITORING);
      final response = await apiService.get('?monitoring_processes=true');

      if (response == null) {
        throw Exception('API response is null');
      }

      // Check if the user is a super admin
      _isSuperAdmin = response['is_super_admin'] ?? false;

      if (!_isSuperAdmin) {
        final ApiService apiServiceNew = ApiService(AppConstant.GET_CURRENT_COMPANY_ID);
        // Fetch company IDs for non-super-admins
        final companyResponse =
        await apiServiceNew.get();

        if (companyResponse != null) {
          _docIds = [companyResponse['company_id']]; // Assign as company ID
        } else {
          throw Exception('Failed to fetch company ID');
        }
      } else {
        _docIds = []; // Clear docIds for super admins
      }

      print('Super Admin: $_isSuperAdmin');
      print('Company IDs (docIds): $_docIds');
    } catch (error, stackTrace) {
      print('Error fetching company IDs: $error');
      print('Stack trace: $stackTrace');
    } finally {
      // Stop loading and notify listeners
      isLoading = false;
      notifyListeners();
    }
  }



  // Add maintenance period
  Future<String> addMaintainancePeriod(String processStartTime, String processEndTime) async {
    try {
      var body = {
        "data": {
          'start_time': processStartTime,
          'end_time': processEndTime,
        }
      };

      isAddLoading = true;
      print(jsonEncode(body));

      ApiService apiService = ApiService(AppConstant.GET_JOB_MONITORING);
      var response = await apiService.post(body);
      print(response);

      isAddLoading = false;
      return response['message'];
    } catch (e) {
      isAddLoading = false;
      print(e);
      return 'Error adding maintenance period';
    }
  }

  // Get maintenance periods
  Future<void> getMaintainancePeriod() async {
    try {
      isLoading = true;

      ApiService apiService = ApiService(AppConstant.GET_JOB_MONITORING);
      var response = await apiService.get();
      print(response);

      MaintainanceResponse maintainanceResponse = MaintainanceResponse.fromJson(response);
      maintainancePeriods = maintainanceResponse.results ?? [];

      isLoading = false;
      notifyListeners();
    } catch (e, stack) {
      isLoading = false;
      print(e);
      print(stack);
    }
  }

  // Edit maintenance period
  Future<String> editMaintainancePeriod(String processStartTime, String processEndTime, String id) async {
    try {
      var body = {
        "data": {
          'id': id,
          'start_time': processStartTime,
          'end_time': processEndTime,
        }
      };

      isLoading = true;

      ApiService apiService = ApiService(AppConstant.GET_JOB_MONITORING);
      var response = await apiService.patch(body);

      isLoading = false;
      return response['message'] ?? 'Update successful';
    } catch (e) {
      isLoading = false;
      return 'Update failed';
    }
  }

  // Delete maintenance period
  Future<bool> deleteMaintainancePeriod(String id) async {
    try {
      isDeleteLoading = true;

      ApiService apiService = ApiService('${AppConstant.GET_JOB_MONITORING}/$id');
      var body = {
        "data": {'id': id},
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
