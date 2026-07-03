import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:RiskSphere/design_system/primitives/custom_typography.dart';
import 'package:RiskSphere/models/upload_sov_model.dart';
import 'package:RiskSphere/screens/listings/widgets/mapping_screen.dart';
import 'package:RiskSphere/screens/processMonitoringScreen/process_monitoring_system.dart';
import 'package:RiskSphere/service/api_service.dart';
import 'package:RiskSphere/service/shared_preference_service.dart';
import 'package:RiskSphere/utils/api_constants.dart';
import '../screens/listings/widgets/location_data.dart';

class UploadSovProvider extends ChangeNotifier {
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  set isLoading(bool value) {
    _isLoading = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  bool isInitialLoad = true;

  // List<Map<String, dynamic>> geocodingList = [];

  void toggleSelection(int index) {
    geocodingList[index]['isChecked'] =
        !(geocodingList[index]['isChecked'] ?? false);
    notifyListeners(); // Notify only for this change
  }

  // bool areAllSelected() {
  //   return geocodingList.every((item) => item['isChecked'] == true);
  // }

  bool _isSubmitLoading = false;

  bool get isSubmitLoading => _isSubmitLoading;

  set isSubmitLoading(bool value) {
    _isSubmitLoading = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  List<Map<String, dynamic>> geocodingList = [];

  void setGeocodingList(List<Map<String, dynamic>> list) {
    _geocodingList = list;
    notifyListeners();
  }

  void toggleItem(String id, bool value) {
    final index = _geocodingList.indexWhere((item) => item['id'] == id);
    if (index != -1) {
      _geocodingList[index]['isChecked'] = value;
      notifyListeners();
    }
  }

  bool get areAllSelected =>
      _geocodingList.isNotEmpty &&
      _geocodingList.every((item) => item['isChecked'] == true);

  void toggleSelectAll(bool value) {
    for (var item in _geocodingList) {
      item['isChecked'] = value;
    }
    notifyListeners();
  }

  void toggleLocation(String id, bool isChecked) {
    for (var location in geocodingList) {
      if (location['id'] == id) {
        location['isChecked'] = isChecked;
        break;
      }
    }
    notifyListeners();
  }

  // void toggleSelectAll(bool isChecked) {
  //   for (var location in geocodingList) {
  //     location['isChecked'] = isChecked;
  //   }
  //   notifyListeners();
  // }

  // bool get areAllSelected =>
  //     geocodingList.isNotEmpty &&
  //         geocodingList.every((item) => item['isChecked'] == true);

  SovUploadModel? _sovUploadModel;

  SovUploadModel? get sovUploadModel => _sovUploadModel;

  set sovUploadModel(SovUploadModel? value) {
    _sovUploadModel = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  List<Map<String, dynamic>> _geocodingList = [];

  List<Map<String, dynamic>> _duplicateLocations = [];

  List<Map<String, dynamic>> get duplicateLocations => _duplicateLocations;

  set duplicateLocations(List<Map<String, dynamic>> value) {
    _duplicateLocations = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  List<Map<String, dynamic>> _conflictLocations = [];

  List<Map<String, dynamic>> get conflictLocations => _conflictLocations;

  set conflictLocations(List<Map<String, dynamic>> value) {
    _conflictLocations = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // List<Map<String, dynamic>> geocodingList = [];

  bool get isAllSelected =>
      geocodingList.isNotEmpty &&
      geocodingList.every((item) => item['isChecked'] == true);

  // void toggleSelectAll(bool value) {
  //   for (var item in geocodingList) {
  //     item['isChecked'] = value;
  //   }
  //   notifyListeners();
  // }

  void toggleItemChecked(int index, bool value) {
    geocodingList[index]['isChecked'] = value;
    notifyListeners();
  }

  int locationCount = 0;
  int duplicateCount = 0;
  int conflictCount = 0;

  void refreshCounts() {
    notifyListeners();
  }

  //count update logic

  // int get locationCount => geocodingList.length;
  // int get duplicateCount => duplicateLocations.length;
  // int get conflictCount => conflictLocations.length;

  // Update methods (use `.toList()` to trigger reactivity)
  void updateLocation(int index, Map<String, dynamic> updatedLocation) {
    if (index >= 0 && index < _geocodingList.length) {
      _geocodingList = List.from(_geocodingList)..[index] = updatedLocation;
      notifyListeners();
    }
  }

  void updateDuplicate(int index, Map<String, dynamic> updatedDuplicate) {
    if (index >= 0 && index < _duplicateLocations.length) {
      _duplicateLocations = List.from(_duplicateLocations)
        ..[index] = updatedDuplicate;
      notifyListeners();
    }
  }

  void updateConflict(int index, Map<String, dynamic> updatedConflict) {
    if (index >= 0 && index < _conflictLocations.length) {
      _conflictLocations = List.from(_conflictLocations)
        ..[index] = updatedConflict;
      notifyListeners();
    }
  }

  // Method to refresh counts explicitly
  // void refreshCounts() {
  //   notifyListeners(); // This will trigger UI update
  // }

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

  Future<void> submitSovHeadersAccounts(
    BuildContext context,
    String tempId,
    String docUrl,
    List<Map<String, dynamic>> fields,
    String subAccountName,
  ) async {
    try {
      bool hasUnmappedFields =
          fields.any((field) => field['status'] == 'Unmapped');

      if (hasUnmappedFields) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("There are unmapped fields")),
        );
        return;
      }

      List<Map<String, dynamic>> targetHeaders = [];
      List<String> headersList = [];

      for (var field in fields) {
        final String targetName = field['target'] ?? '';
        final String spreadsheetName = field['spreadsheet'] ?? '';
        final String id = field['id'] ?? '${targetName}_ignore';
        final int percentage = field['percentage'] ?? 100;
        var isDataParam = field['is_data_parameter'] == true ? true : false;

        // Build structure like:
        // { "Location Name": { "id": "...", "name": "...", "percentage": 100 } }
        final Map<String, dynamic> headerEntry = {
          targetName: {
            "id": id,
            "name": spreadsheetName.isNotEmpty ? spreadsheetName : "Ignore",
            "percentage": percentage,
            if (isDataParam) "is_data_parameter": true,
          },
        };

        targetHeaders.add(headerEntry);
        headersList.add(targetName);
      }

      final body = {
        "data": {
          "temp_id": tempId,
          "headers": headersList,
          "targetheaders": targetHeaders,
          "url": docUrl,
        }
      };

      isLoading = true;
      ApiService apiService = ApiService(AppConstant.UPLOAD_SOV_ACCOUNT);
      var response = await apiService.post(body);
      log(response.toString());

      if (response['message'] != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => LocationDataScreen(
              processId: response['process_id'] ?? "",
              tempId: tempId,
              subAccountName: subAccountName,
            ),
          ),
        );
      } else {
        throw Exception('Failed to submit data');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Submission failed2")),
      );
    } finally {
      isLoading = false;
    }
  }

  // Future<void> submitSovHeadersAccounts(
  //     BuildContext context,
  //     String tempId,
  //     String docUrl,
  //     List<Map<String, dynamic>> fields,
  //     String subAccountName) async {
  //   try {
  //     bool hasUnmappedFields =
  //         fields.any((field) => field['status'] == 'Unmapped');
  //
  //     if (hasUnmappedFields) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text("There are unmapped fields"),
  //         ),
  //       );
  //       return;
  //     }
  //
  //     List<Map<String, String>> targetHeaders = [];
  //     List<String> headersList = [];
  //
  //     for (var field in fields) {
  //       String matchedField = field['spreadsheet'] ?? '';
  //       targetHeaders.add({field['target']: matchedField});
  //       headersList.add(field['target']);
  //     }
  //
  //     final body = {
  //       'data': {
  //         'temp_id': tempId,
  //         'headers': headersList,
  //         'targetheaders': targetHeaders,
  //         'url': docUrl,
  //       }
  //     };
  //
  //     isLoading = true;
  //     ApiService apiService = ApiService(AppConstant.UPLOAD_SOV_ACCOUNT);
  //     var response = await apiService.post(body);
  //     log(response.toString());
  //
  //     if (response['message'] != null) {
  //       Navigator.of(context).push(MaterialPageRoute(
  //         builder: (context) => LocationDataScreen(
  //           processId: response['process_id'] ?? "",
  //           tempId: tempId,
  //           subAccountName: subAccountName,
  //         ),
  //       ));
  //     } else {
  //       throw Exception('Failed to submit data');
  //     }
  //   } catch (error) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text("Submission failed"),
  //       ),
  //     );
  //   } finally {
  //     isLoading = false;
  //   }
  // }
  Future<void> submitSovHeadersSubAccounts(
    BuildContext context,
    String tempId,
    String docUrl,
    List<Map<String, dynamic>> fields,
    String accountId,
    String accountName,
    String subAccountName,
    String subAccountId,
  ) async {
    try {
      List<Map<String, dynamic>> targetHeaders = [];
      List<String> headersList = [];

      for (var field in fields) {
        final String targetName = field['target'] ?? '';
        final String spreadsheetName = field['spreadsheet'] ?? '';
        final String id = field['id'] ?? '';
        final int percentage = field['percentage'] ?? 0;
        final bool isDataParam = field['is_data_parameter'] == true;

        final Map<String, dynamic> headerEntry = {
          targetName: {
            "id": id,
            "name": spreadsheetName.isNotEmpty ? spreadsheetName : "Ignore",
            "percentage": percentage,
            if (isDataParam) "is_data_parameter": true
          }
        };

        targetHeaders.add(headerEntry);
        headersList.add(targetName);
      }

      final body = {
        "data": {
          "temp_id": tempId,
          "headers": headersList,
          "targetheaders": targetHeaders,
          "url": docUrl,
        }
      };

      print(const JsonEncoder.withIndent('  ').convert(body));

      isLoading = true;
      ApiService apiService = ApiService(AppConstant.UPLOAD_SOV_ACCOUNT);

      var response = await apiService.post(body);

      print(response);

      if (response['message'] == null) {
        throw Exception("Server returned error → Missing 'message' key");
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LocationDataScreen(
            processId: response['process_id'] ?? "",
            tempId: tempId,
            accountId: accountId,
            accountName: accountName,
            subAccountName: subAccountName,
            subAccountId: subAccountId,
          ),
        ),
      );
    } catch (error, stacktrace) {
      print("========== SUBMISSION ERROR ==========");
      print("ERROR: $error");
      print("STACKTRACE: $stacktrace");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Submission failed: $error")),
      );
    } finally {
      isLoading = false;
    }
  }

  // Future<void> submitSovHeadersSubAccounts(
  //     BuildContext context,
  //     String tempId,
  //     String docUrl,
  //     List<Map<String, dynamic>> fields,
  //     String accountId,
  //     String accountName,
  //     String subAccountName,
  //     String subAccountId) async {
  //   try {
  //     bool hasUnmappedFields =
  //         fields.any((field) => field['status'] == 'Unmapped');
  //
  //     // if (hasUnmappedFields) {
  //     //   ScaffoldMessenger.of(context).showSnackBar(
  //     //     SnackBar(
  //     //       content: Text(
  //     //         "There are unmapped fields",
  //     //         style: CustomTypography(context).Body1,
  //     //       ),
  //     //     ),
  //     //   );
  //     //   return;
  //     // }
  //
  //     List<Map<String, String>> targetHeaders = [];
  //     List<String> headersList = [];
  //
  //     for (var field in fields) {
  //       String matchedField = field['spreadsheet'] ?? '';
  //       targetHeaders.add({field['target']: matchedField});
  //       headersList.add(field['target']);
  //     }
  //
  //     final body = {
  //       'data': {
  //         'temp_id': tempId,
  //         'headers': headersList,
  //         'targetheaders': targetHeaders,
  //         'url': docUrl,
  //       }
  //     };
  //
  //     isLoading = true;
  //     ApiService apiService = ApiService(AppConstant.UPLOAD_SOV_ACCOUNT);
  //     var response = await apiService.post(body);
  //     log(response.toString());
  //
  //     if (response['message'] != null) {
  //       Navigator.pushReplacement(
  //           context,
  //           MaterialPageRoute(
  //             builder: (context) => LocationDataScreen(
  //               processId: response['process_id'] ?? "",
  //               tempId: tempId,
  //               accountId: accountId,
  //               accountName: accountName,
  //               subAccountName: subAccountName,
  //               subAccountId: subAccountId,
  //             ),
  //           ));
  //     } else {
  //       throw Exception('Failed to submit data');
  //     }
  //   } catch (error) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text("Submission failed"),
  //       ),
  //     );
  //   } finally {
  //     isLoading = false;
  //   }
  // }

  Future<Map<String, dynamic>> fetchLocations(
      BuildContext context, String processId) async {
    try {
      isLoading = true;
      notifyListeners();
      ApiService apiService =
          ApiService(AppConstant.FETCH_LOCATIONS_DUPLICATION_CHECK);
      String url = '/$processId';

      var response = await apiService.get(url);
      log(response.toString());
      List<dynamic> data = response['result'] ?? [];
      print("api locations length: ${data.length}");
      geocodingList = List<Map<String, dynamic>>.from(data);
      // **Update counts in UploadSovProvider**

      // locationCount = geocodingList.length;

      if (isInitialLoad) {
        isInitialLoad = false;
      }

      isLoading = false;
      notifyListeners();
      return response ?? {};
    } on BackendException catch (e, stackTrace) {
      print(e);
      print(stackTrace);
      isLoading = false;
      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      //   content: Text(e.message),
      // ));
      return {};
    } catch (e, stackTrace) {
      print(stackTrace);
      print(e);
      isLoading = false;
      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      //   content: Text(e.toString()),
      // ));
      return {};
    }
  }

  Future<Map<String, dynamic>> fetchDuplicates(
      BuildContext context, String processId) async {
    try {
      isLoading = true;
      notifyListeners();
      ApiService apiService =
          ApiService(AppConstant.FETCH_LOCATION_DUPLICATIONS);
      String url = '/$processId';

      var response = await apiService.get(url);
      log(response.toString());
      List<dynamic> data = response['result'] ?? [];

      duplicateLocations = data.map((item) {
        return {
          'address': item['address'] ?? '',
          'city': item['property City'] ?? '',
          'country': item['Country'] ?? '',
          'location_name': item['Location Name'] ?? '',
          'postal_code': item['Postal Code'] ?? '',
          'state': item['State'] ?? '',
          'doc_id': item['doc_id'] ?? '',
          'duplicates': item['duplicates'] ?? [],
          'formatted_address': item['formatted_address'],
          'id': item['id'] ?? '',
          'is_duplicate': item['is_duplicate'] ?? false,
          'line_no': item['line_no'] ?? '',
          'process_id': item['process_id'] ?? '',

          'type': item['type'] ?? '',
          // 'duplicates':item['duplicates']?.isNotEmpty == true
          //     ? [item['duplicates'][0]] // Pick the first duplicate
          //     : null
        };
      }).toList();
      print(duplicateLocations.toString());
      print("duplicateLocations.toString()");
      // **Update duplicate count**
      duplicateCount = duplicateLocations.length;
      // locationCount = geocodingList.length;
      if (isInitialLoad) {
        isInitialLoad = false;
      }

      isLoading = false;
      notifyListeners();
      return response ?? {};
    } on BackendException catch (e, stackTrace) {
      print(e);
      print(stackTrace);
      isLoading = false;
      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      //   content: Text(e.message),
      // ));
      return {};
    } catch (e, stackTrace) {
      print(stackTrace);
      print(e);
      isLoading = false;
      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      //   content: Text(e.toString()),
      // ));
      return {};
    }
  }

  Future<Map<String, dynamic>> fetchConflicts(
      BuildContext context, String processId) async {
    try {
      isLoading = true;
      notifyListeners();
      ApiService apiService = ApiService(AppConstant.FETCH_LOCATION_CONFLICTS);
      String url = '/$processId';

      var response = await apiService.get(url);
      log(response.toString());
      List<dynamic> data = response['result'] ?? [];
      conflictLocations = data.map((item) {
        return {
          'formatted_address': item['formatted_address'],
          'id': item['id'],
          'conflicts': item['similar'] ?? [],
        };
      }).toList();
      conflictCount = conflictLocations.length;
      if (isInitialLoad) {
        isInitialLoad = false;
      }
      isLoading = false;
      notifyListeners();
      return response ?? {};
    } on BackendException catch (e, stackTrace) {
      print(e);
      print(stackTrace);
      isLoading = false;
      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      //   content: Text(e.message),
      // ));
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
    // BuildContext context,
    String accountId,
    String subAccountId,
    String processId,
    List<Map<String, dynamic>> selectedRows,
    String id,
  ) async {
    try {
      isLoading = true;

      // Prepare the data payload
      final List<Map<String, dynamic>> requestData = selectedRows.map((row) {
        return {
          'account_id': accountId,
          'sub_account_id': subAccountId,
          'unique_object_id': row['id'],
          'process_id': processId,
          'is_duplicate': false,
          'location_id': row['duplicates'][0]?['location_id'] ?? "",
        };
      }).toList();
      //
      // // Log the request body for debugging
      // log('Request Payload: $requestData');

      // API endpoint and request
      ApiService apiService =
          ApiService(AppConstant.FETCH_LOCATION_DUPLICATIONS);
      var response = await apiService.patch({'data': requestData});

      log('Response: $response');

      // Handle response
      if (response['message'] != null) {
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(
        //     content:
        //         Text(response['message'] ?? "Location marked as not duplicate"),
        //   ),
        // );
        return true; // Success
      } else {
        throw Exception('Failed to mark as not duplicate');
      }
    } catch (error) {
      log('Error: $error');
      // log('StackTrace: $stackTrace');
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text("Failed to update duplicate status"),
      //   ),
      // );
      return false; // Failure
    } finally {
      isLoading = false;
    }
  }

  Future<bool> resolveConflict(
    // BuildContext context,
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
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(
        //     content:
        //         Text(response['message'] ?? "Conflict resolved successfully"),
        //   ),
        // );
        return true; // Success
      } else {
        throw Exception('Failed to resolve conflict');
      }
    } catch (error, stackTrace) {
      log('Error: $error');
      log('StackTrace: $stackTrace');
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text("Failed to resolve conflict"),
      //   ),
      // );
      return false; // Failure
    } finally {
      isLoading = false;
    }
  }

  Future<bool> startHazard(
    // BuildContext context,
    Map<String, dynamic> conflictData,
  ) async {
    try {
      isLoading = true;

      // Prepare API service
      ApiService apiService = ApiService(AppConstant.START_HAZARD_CONFLICTS);

      // Make the PATCH request
      var response = await apiService.post({'data': conflictData});

      // Log the response for debugging
      log('Response: $response');

      // Handle response
      if (response['message'] != null) {
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(
        //     content: Text(response['message'] ?? "Hazard started successfully"),
        //   ),
        // );
        return true; // Success
      } else {
        throw Exception('Failed to start hazard');
      }
    } catch (error, stackTrace) {
      log('StackTrace: $stackTrace');
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text("Failed to start hazard"),
      //   ),
      // );
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

      ApiService apiService = ApiService(
          AppConstant.CANCEL_SOV_UPLOAD_PROCESS + '/${processId.toString()}');
      String url = '';
      print(AppConstant.CANCEL_SOV_UPLOAD_PROCESS + '/${processId.toString()}');

      var response = await apiService.delete({'data': {}});
      log(response.toString());
      isLoading = false;
      return true;
    } on BackendException catch (e, stackTrace) {
      print(e);
      print(stackTrace);
      isLoading = false;
      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      //   content: Text(e.message),
      // ));
      return false;
    } catch (e, stackTrace) {
      print(stackTrace);
      print(e);
      isLoading = false;
      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      //   content: Text(e.toString()),
      // ));
      return false;
    }
  }

  Future<bool> submitLocationsAccounts(
      BuildContext context,
      String tempId,
      List<Map<String, dynamic>> locationsToSubmit,
      List<Map<String, dynamic>> duplicationToSubmit,
      String formatType,
      String accountId,
      String subAccountId) async {
    try {
      isSubmitLoading = true;
      final formattedLocations = locationsToSubmit.map((location) {
        final fields = location['fields'] as List<dynamic>;
        final formattedFields = fields.map((field) {
          return MapEntry(field['key'], field['value'].toString());
        }).toList();
        return Map.fromEntries(formattedFields);
      }).toList();
      final formattedDuplication = duplicationToSubmit.map((location) {
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
          'duplicates': formattedDuplication,
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
              builder: (context) => ProcessMonitoringScreen(
                    accountId: accountId,
                    subAccountId: subAccountId,
                  )), // Navigate to AccountsScreen
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
      List<Map<String, dynamic>> duplicationToSubmit,
      String formatType,
      String accountId,
      String accountName,
      String subAccountId) async {
    try {
      isSubmitLoading = true;
      /* final formattedLocations = locationsToSubmit.map((location) {
        final fields = location['fields'] as List<dynamic>;
        final formattedFields = fields.map((field) {
          return MapEntry(field['key'], field['value'].toString());
        }).toList();
        return Map.fromEntries(formattedFields);
      }).toList();*/
      print("objectaddsove theing");
      final body = {
        'data': {
          // 'account_id': accountId,
          'temp_id': tempId,
          'duplicates': [],
          'formatType': formatType,
          'locations': locationsToSubmit,
          'sub_account_id': subAccountId,
        }
      };

      log('Request Body: $body');
      ApiService apiService = ApiService(AppConstant.UPLOAD_SOV_ACCOUNT);
      var response = await apiService.post(body);

      log('Response: $response');

      if (response['message'] != null) {
        print(response['message']);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? "Submitted successfully"),
          ),
        );
        // Navigator.pushReplacement(
        //   context,
        //   MaterialPageRoute(
        //       builder: (context) => SubAccountListScreen(
        //           accountId: accountId,
        //           accountName: accountName)), // Navigate to AccountsScreen
        // );
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
      String subAccountName,
      String subAccountId,
      String tempProcessId,
      String state, {
        VoidCallback? onProcessCompleted,   // 🔥 Added callback
      }) async {
    try {
      // 🔥 CASE 1: Upload still in progress → Go to Mapping Screen
      if (state.toLowerCase() == 'upload') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MappingScreen(
              tempId: tempProcessId,
              accountId: accountId,
              subAccountId: subAccountId,
              accountName: accountName,
              subAccountName: subAccountName,
            ),
          ),
        );
        return;
      }

      String processId =
          await SharedPreferenceService.getSovUploadProcessId() ?? "";

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LocationDataScreen(
            processId: processId,
            tempId: tempProcessId,
            accountId: accountId,
            subAccountId: subAccountId,
            accountName: accountName,
            subAccountName: subAccountName,
          ),
        ),
      );
        await SharedPreferenceService.clearSovUploadState();
      await SharedPreferenceService.clearSovUploadTempId();
      await SharedPreferenceService.clearSovAccountId();
      await SharedPreferenceService.clearSovSubAccountId();

      if (onProcessCompleted != null) {
        onProcessCompleted();
      }
    }
    on BackendException catch (e, stackTrace) {
      print(stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
    catch (e, stackTrace) {
      print(stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }




  List<Map<String, dynamic>> _getSelectedGeocodingLocations() {
    if (geocodingList.every((element) => element['isChecked'] == false)) {
      return geocodingList;
    } else {
      return geocodingList
          .where((element) => element['isChecked'] == true)
          .toList();
    }
  }



  Future<void> commitSelectedLocations(BuildContext context, String accountId,
      String accountName, String tempId, String subAccountId) async {

    await _submitLocations(context, geocodingList, duplicateLocations,
        "use_sov_data", tempId, accountId, accountName, subAccountId);
  }

  void _commitAllLocations(BuildContext context, String accountId,
      String accountName, String tempId) {
    _submitLocations(context, geocodingList, duplicateLocations,
        "refresh_all_data", tempId, accountId, accountName, '');
  }

  Future<void> _submitLocations(
      BuildContext context,
      List<Map<String, dynamic>> locationsToSubmit,
      List<Map<String, dynamic>> duplicationToSubmit,
      String formatType,
      String tempId,
      String accountId,
      String accountName,
      String subAccountId) async {
    if (accountId.isNotEmpty) {
      await submitLocationsSubAccounts(
          context,
          tempId,
          locationsToSubmit,
          duplicationToSubmit,
          formatType,
          accountId,
          accountName,
          subAccountId);
      return;
    } else {
      await submitLocationsAccounts(
        context,
        tempId,
        locationsToSubmit,
        duplicationToSubmit,
        formatType,
        accountId,
        subAccountId,
      );
    }
  }
}
