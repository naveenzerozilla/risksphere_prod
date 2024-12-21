import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:green/design_system/primitives/custom_typography.dart';
import 'package:green/models/upload_sov_model.dart';
import 'package:green/screens/listings/sub_account_list.dart';
import 'package:green/screens/listings/widgets/mapping_screen.dart';
import 'package:green/screens/processMonitoringScreen/process_monitoring_system.dart';
import 'package:green/service/api_service.dart';
import 'package:green/service/shared_preference_service.dart';
import 'package:green/utils/api_constants.dart';

import '../screens/listings/account_list.dart';
import '../screens/listings/widgets/location_data.dart';

class UploadSovProvider extends ChangeNotifier {
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  set isLoading(bool value) {
    _isLoading = value;
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  bool _isSubmitLoading = false;

  bool get isSubmitLoading => _isSubmitLoading;

  set isSubmitLoading(bool value) {
    _isSubmitLoading = value;
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  SovUploadModel? _sovUploadModel;

  SovUploadModel? get sovUploadModel => _sovUploadModel;

  set sovUploadModel(SovUploadModel? value) {
    _sovUploadModel = value;
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  Future<void> createEmptySov(BuildContext context, String tempId) async {
    var typography = CustomTypography(context);
    try {
      isLoading = true;

      if (tempId.contains('+')) {
        tempId = tempId.replaceAll('+', '');
      }
      final body = {
        'data': {
          'temp_id': tempId,
          "create_empty_sov": true,
        }
      };

      isLoading = true;
      ApiService apiService = ApiService(AppConstant.UPLOAD_SOV_ACCOUNT);
      var response = await apiService.post(body);
      log(response.toString());

      if (response['message'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['message'] ?? "Empty SOV created",
              style: typography.Body1,
            ),
          ),
        );
      } else {
        throw Exception(response['error'] ?? 'Failed to create empty SOV');
      }
    } catch (error, stackTrace) {
      print(error);
      print(stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Submission failed"),
        ),
      );
    } finally {
      isLoading = false;
    }
  }

  Future<bool> fetchSovHeaders(
      BuildContext context, String tempProcessId) async {
    try {
      isLoading = true;

      ApiService apiService = ApiService(AppConstant.UPLOAD_SOV_ACCOUNT);
      String url = '?temp_process_id=$tempProcessId';

      var response = await apiService.get(url);
      log(response.toString());

      SovUploadModel sovUploadModelLocal = SovUploadModel.fromJson(response);
      sovUploadModel = sovUploadModelLocal;

      print(sovUploadModelLocal.toString());
      log(sovUploadModel.toString());
      isLoading = false;
      return true;
    } on BackendException catch (e, stackTrace) {
      print(e);
      print(stackTrace);
      isLoading = false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message),
      ));
      return false;
    } catch (e, stackTrace) {
      print(stackTrace);
      print(e);
      isLoading = false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString()),
      ));
      return false;
    }
  }

  Future<void> submitSovHeadersAccounts(BuildContext context, String tempId,
      String docUrl, List<Map<String, dynamic>> fields) async {
    try {
      bool hasUnmappedFields =
          fields.any((field) => field['status'] == 'Unmapped');

      if (hasUnmappedFields) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("There are unmapped fields"),
          ),
        );
        return;
      }

      List<Map<String, String>> targetHeaders = [];
      List<String> headersList = [];

      for (var field in fields) {
        String matchedField = field['spreadsheet'] ?? '';
        targetHeaders.add({field['target']: matchedField});
        headersList.add(field['target']);
      }

      final body = {
        'data': {
          'temp_id': tempId,
          'headers': headersList,
          'targetheaders': targetHeaders,
          'url': docUrl,
        }
      };

      isLoading = true;
      ApiService apiService = ApiService(AppConstant.UPLOAD_SOV_ACCOUNT);
      var response = await apiService.post(body);
      log(response.toString());

      if (response['message'] != null) {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => LocationDataScreen(
            processId: response['process_id'] ?? "",
            tempId: tempId,
          ),
        ));
      } else {
        throw Exception('Failed to submit data');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Submission failed"),
        ),
      );
    } finally {
      isLoading = false;
    }
  }

  Future<void> submitSovHeadersSubAccounts(
      BuildContext context,
      String tempId,
      String docUrl,
      List<Map<String, dynamic>> fields,
      String accountId,
      String accountName,
      String subAccountId) async {
    try {
      bool hasUnmappedFields =
          fields.any((field) => field['status'] == 'Unmapped');

      if (hasUnmappedFields) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "There are unmapped fields",
              style: CustomTypography(context).Body1,
            ),
          ),
        );
        return;
      }

      List<Map<String, String>> targetHeaders = [];
      List<String> headersList = [];

      for (var field in fields) {
        String matchedField = field['spreadsheet'] ?? '';
        targetHeaders.add({field['target']: matchedField});
        headersList.add(field['target']);
      }

      final body = {
        'data': {
          'temp_id': tempId,
          'headers': headersList,
          'targetheaders': targetHeaders,
          'url': docUrl,
        }
      };

      isLoading = true;
      ApiService apiService = ApiService(AppConstant.UPLOAD_SOV_ACCOUNT);
      var response = await apiService.post(body);
      log(response.toString());

      if (response['message'] != null) {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => LocationDataScreen(
            processId: response['process_id'] ?? "",
            tempId: tempId,
            accountId: accountId,
            accountName: accountName,
            subAccountId: subAccountId,
          ),
        ));
      } else {
        throw Exception('Failed to submit data');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Submission failed"),
        ),
      );
    } finally {
      isLoading = false;
    }
  }

  Future<Map<String, dynamic>> fetchLocations(
      BuildContext context, String processId) async {
    try {
      isLoading = true;

      ApiService apiService =
          ApiService(AppConstant.FETCH_LOCATIONS_DUPLICATION_CHECK);
      String url = '/$processId';

      var response = await apiService.get(url);
      log(response.toString());
      isLoading = false;
      return response ?? {};
    } on BackendException catch (e, stackTrace) {
      print(e);
      print(stackTrace);
      isLoading = false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message),
      ));
      return {};
    } catch (e, stackTrace) {
      print(stackTrace);
      print(e);
      isLoading = false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString()),
      ));
      return {};
    }
  }

  Future<Map<String, dynamic>> fetchDuplicates(
      BuildContext context, String processId) async {
    try {
      isLoading = true;

      ApiService apiService =
          ApiService(AppConstant.FETCH_LOCATION_DUPLICATIONS);
      String url = '/$processId';

      var response = await apiService.get(url);
      log(response.toString());
      isLoading = false;
      return response ?? {};
    } on BackendException catch (e, stackTrace) {
      print(e);
      print(stackTrace);
      isLoading = false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message),
      ));
      return {};
    } catch (e, stackTrace) {
      print(stackTrace);
      print(e);
      isLoading = false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString()),
      ));
      return {};
    }
  }

  Future<Map<String, dynamic>> fetchConflicts(
      BuildContext context, String processId) async {
    try {
      isLoading = true;

      ApiService apiService = ApiService(AppConstant.FETCH_LOCATION_CONFLICTS);
      String url = '/$processId';

      var response = await apiService.get(url);
      log(response.toString());
      isLoading = false;
      return response ?? {};
    } on BackendException catch (e, stackTrace) {
      print(e);
      print(stackTrace);
      isLoading = false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message),
      ));
      return {};
    } catch (e, stackTrace) {
      print(stackTrace);
      print(e);
      isLoading = false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString()),
      ));
      return {};
    }
  }

  Future<bool> markAsNotDuplicate(
    BuildContext context,
    String accountId,
    String subAccountId,
    String processId,
    List<Map<String, dynamic>> selectedRows,
    String id,
  ) async {
    try {
      isLoading = true;
      log("Selected Rows: $selectedRows");

      // Prepare the data payload
      final List<Map<String, dynamic>> requestData = selectedRows.map((row) {
        return {
          'account_id': accountId,
          'sub_account_id': subAccountId,
          'unique_object_id': row['id'],
          'process_id': processId,
          'is_duplicate': false,
          'location_id': row['top_duplicate']?['location_id'] ?? "",
        };
      }).toList();

      // Log the request body for debugging
      log('Request Payload: $requestData');

      // API endpoint and request
      ApiService apiService =
          ApiService(AppConstant.FETCH_LOCATION_DUPLICATIONS);
      var response = await apiService.patch({'data': requestData});

      log('Response: $response');

      // Handle response
      if (response['message'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(response['message'] ?? "Location marked as not duplicate"),
          ),
        );
        return true; // Success
      } else {
        throw Exception('Failed to mark as not duplicate');
      }
    } catch (error, stackTrace) {
      log('Error: $error');
      log('StackTrace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to update duplicate status"),
        ),
      );
      return false; // Failure
    } finally {
      isLoading = false;
    }
  }

  Future<bool> resolveConflict(
    BuildContext context,
    List<Map<String, dynamic>> conflictData,
  ) async {
    try {
      isLoading = true;

      // Log the request data for debugging
      log('Conflict Data: $conflictData');

      // Prepare API service
      ApiService apiService =
          ApiService(AppConstant.RESOLVE_LOCATION_CONFLICTS);

      // Make the PATCH request
      var response = await apiService.patch({'data': conflictData});

      // Log the response for debugging
      log('Response: $response');

      // Handle response
      if (response['message'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(response['message'] ?? "Conflict resolved successfully"),
          ),
        );
        return true; // Success
      } else {
        throw Exception('Failed to resolve conflict');
      }
    } catch (error, stackTrace) {
      log('Error: $error');
      log('StackTrace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to resolve conflict"),
        ),
      );
      return false; // Failure
    } finally {
      isLoading = false;
    }
  }

  // cancel whole process
  Future<bool> cancelSovUploadProcess(
      BuildContext context, String processId) async {
    try {
      isLoading = true;

      ApiService apiService =
          ApiService(AppConstant.CANCEL_SOV_UPLOAD_PROCESS + '/$processId');
      String url = '';

      var response = await apiService.delete({'data': {}});
      log(response.toString());
      isLoading = false;
      return true;
    } on BackendException catch (e, stackTrace) {
      print(e);
      print(stackTrace);
      isLoading = false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message),
      ));
      return false;
    } catch (e, stackTrace) {
      print(stackTrace);
      print(e);
      isLoading = false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString()),
      ));
      return false;
    }
  }

  Future<bool> submitLocationsAccounts(BuildContext context, String tempId,
      List<Map<String, dynamic>> locationsToSubmit, String formatType) async {
    try {
      isSubmitLoading = true;
      final formattedLocations = locationsToSubmit.map((location) {
        final fields = location['fields'] as List<dynamic>;
        final formattedFields = fields.map((field) {
          return MapEntry(field['key'], field['value'].toString());
        }).toList();
        return Map.fromEntries(formattedFields);
      }).toList();

      final body = {
        'data': {
          'temp_id': tempId,
          'locations': formattedLocations,
          'formatType': formatType,
        }
      };

      log('Request Body: $body');
      ApiService apiService = ApiService(AppConstant.UPLOAD_SOV_ACCOUNT);
      var response = await apiService.post(body);

      log('Response: $response');

      if (response['message'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? "SOV submitted successfully"),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  ProcessMonitoringScreen()), // Navigate to AccountsScreen
        );
        return true; // Indicate success
      } else {
        throw Exception('Failed to submit data');
      }
    } catch (error, stackTrace) {
      log('Submission Error: $error');
      log('Submission Error: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Submission failed"),
        ),
      );
      return false; // Indicate failure
    } finally {
      isSubmitLoading = false;
    }
  }

  Future<bool> submitLocationsSubAccounts(
      BuildContext context,
      String tempId,
      List<Map<String, dynamic>> locationsToSubmit,
      String formatType,
      String accountId,
      String accountName) async {
    try {
      isSubmitLoading = true;
      /* final formattedLocations = locationsToSubmit.map((location) {
        final fields = location['fields'] as List<dynamic>;
        final formattedFields = fields.map((field) {
          return MapEntry(field['key'], field['value'].toString());
        }).toList();
        return Map.fromEntries(formattedFields);
      }).toList();*/

      final body = {
        'data': {
          'temp_id': tempId,
          'locations': locationsToSubmit,
          'formatType': formatType,
        }
      };

      log('Request Body: $body');
      ApiService apiService = ApiService(AppConstant.UPLOAD_SOV_ACCOUNT);
      var response = await apiService.post(body);

      log('Response: $response');

      if (response['message'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? "Submitted successfully"),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => SubAccountListScreen(
                  accountId: accountId,
                  accountName: accountName)), // Navigate to AccountsScreen
        );
        // Navigator.push(context, MaterialPageRoute(builder: (_) => ProcessMonitoringScreen()));
        //Navigator.pop(context);
        return true; // Indicate success
      } else {
        throw Exception('Failed to submit data');
      }
    } catch (error, stackTrace) {
      log('Submission Error: $error');
      log('Submission Error: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Submission failed"),
        ),
      );
      return false; // Indicate failure
    } finally {
      isSubmitLoading = false;
    }
  }

  Future<void> fetchSovUploadData(
      BuildContext context,
      String accountId,
      String accountName,
      String subAccountId,
      String tempProcessId,
      String state) async {
    try {
      if (state.toLowerCase() == 'upload') {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => MappingScreen(
                      tempId: tempProcessId,
                      accountId: accountId,
                      subAccountId: subAccountId,
                      accountName: accountName,
                    )));
      } else {
        String processId = await SharedPreferenceService.getSovUploadProcessId()??"";
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LocationDataScreen(
              processId: processId,
              tempId: tempProcessId,
              accountId: accountId,
              subAccountId: subAccountId,
              accountName: accountName,
            ),
          ),
        );
      }
    } on BackendException catch (e, stackTrace) {
      print(e);
      print(stackTrace);
      isLoading = false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message),
      ));
    } catch (e, stackTrace) {
      print(stackTrace);
      print(e);
      isLoading = false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString()),
      ));
    }
  }
}
