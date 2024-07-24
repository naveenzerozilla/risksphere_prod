import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:green/models/upload_sov_model.dart';
import 'package:green/screens/listings/sub_account_list.dart';
import 'package:green/service/api_service.dart';
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

  Future<bool> fetchSovHeaders(BuildContext context, String tempProcessId) async {
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

  Future<void> submitSovHeadersAccounts(BuildContext context, String tempId, String docUrl, List<Map<String, dynamic>> fields) async {
    try {
      bool hasUnmappedFields = fields.any((field) => field['status'] == 'Unmapped');

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

      if (response['data'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Submission successful"),
          ),
        );
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => LocationDataScreen(
            response: response,
            tempId: tempId,
            targetHeaders: targetHeaders,
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

  Future<void> submitSovHeadersSubAccounts(BuildContext context, String tempId, String docUrl, List<Map<String, dynamic>> fields, String accountId, String accountName) async {
    try {
      bool hasUnmappedFields = fields.any((field) => field['status'] == 'Unmapped');

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

      if (response['data'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Submission successful"),
          ),
        );
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => LocationDataScreen(
            response: response,
            tempId: tempId,
            targetHeaders: targetHeaders,
            accountId: accountId,
            accountName: accountName,
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


  Future<bool> submitLocationsAccounts(BuildContext context, String tempId, List<Map<String, dynamic>> locationsToSubmit, String formatType, List<Map<String, dynamic>> targetHeaders) async {
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
          'targetHeaders': targetHeaders,
        }
      };

      log('Request Body: $body');
      ApiService apiService = ApiService(AppConstant.UPLOAD_SOV_ACCOUNT);
      var response = await apiService.post(body);

      log('Response: $response');

      if (response['results'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? "SOV submitted successfully"),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AccountListScreen()), // Navigate to AccountsScreen
        );
        return true; // Indicate success
      } else {
        throw Exception('Failed to submit data');
      }
    } catch (error) {
      log('Submission Error: $error');
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


  Future<bool> submitLocationsSubAccounts(BuildContext context, String tempId, List<Map<String, dynamic>> locationsToSubmit, String formatType, List<Map<String, dynamic>> targetHeaders, String accountId, String accountName) async {
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
          'targetHeaders': targetHeaders,
        }
      };

      log('Request Body: $body');
      ApiService apiService = ApiService(AppConstant.UPLOAD_SOV_ACCOUNT);
      var response = await apiService.post(body);

      log('Response: $response');

      if (response['results'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? "SOV submitted successfully"),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => SubAccountListScreen(accountId: accountId, accountName: accountName)), // Navigate to AccountsScreen
        );
        return true; // Indicate success
      } else {
        throw Exception('Failed to submit data');
      }
    } catch (error) {
      log('Submission Error: $error');
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








}
