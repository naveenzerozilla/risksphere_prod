import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:RiskSphere/design_system/components/custom_toast.dart';
import 'package:flutter/material.dart';
import 'package:RiskSphere/design_system/primitives/custom_typography.dart';
import 'package:RiskSphere/models/account_list_model.dart';
import 'package:RiskSphere/models/sub_account_list_model.dart';
import 'package:RiskSphere/service/api_service.dart';
import 'package:RiskSphere/utils/api_constants.dart';

import '../service/language_service.dart';
import '../utils/toast.dart';

class SubAccountListProvider extends ChangeNotifier {
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  set isLoading(bool value) {
    _isLoading = value;
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  bool _isNextPageLoading = false;

  bool get isNextPageLoading => _isNextPageLoading;

  set isNextPageLoading(bool value) {
    _isNextPageLoading = value;
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  bool _isDeleteLocationLoading = false;

  bool get isDeleteLocationLoading => _isDeleteLocationLoading;

  set isDeleteLocationLoading(bool value) {
    _isDeleteLocationLoading = value;
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      notifyListeners();
    });
  }

  bool _isRenameLoading = false;

  bool get isRenameLoading => _isRenameLoading;

  set isRenameLoading(bool value) {
    _isRenameLoading = value;
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  bool _isDuplicateLoading = false;

  bool get isDuplicateLoading => _isDuplicateLoading;

  set isDuplicateLoading(bool value) {
    _isDuplicateLoading = value;
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  bool _isOwnerLoading = false;

  bool get isOwnerLoading => _isOwnerLoading;

  set isOwnerLoading(bool value) {
    _isOwnerLoading = value;
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  bool _showSOVCountLoading = false;

  bool get showSOVCountLoading => _showSOVCountLoading;

  set showSOVCountLoading(bool value) {
    _showSOVCountLoading = value;
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  bool _showSubAccountCountLoading = false;

  bool get showSubAccountCountLoading => _showSubAccountCountLoading;

  set showSubAccountCountLoading(bool value) {
    _showSubAccountCountLoading = value;
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  bool _showOverallScoreLoading = false;

  bool get showOverallScoreLoading => _showOverallScoreLoading;

  set showOverallScoreLoading(bool value) {
    _showOverallScoreLoading = value;
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  bool _isAddAccountLoading = false;

  bool get isAddSubAccountLoading => _isAddAccountLoading;

  set isAddSubAccountLoading(bool value) {
    _isAddAccountLoading = value;
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  bool _isAutoCompleteLoading = false;

  bool get isAutoCompleteLoading => _isAutoCompleteLoading;

  set isAutoCompleteLoading(bool value) {
    _isAutoCompleteLoading = value;
    WidgetsBinding.instance!.addPostFrameCallback((_) {
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

  bool _isTransferLoading = false;

  bool get isTransferLoading => _isTransferLoading;

  set isTransferLoading(bool value) {
    _isTransferLoading = value;
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // Column visibility

  bool _showOwner = true;

  bool get showOwner => _showOwner;

  set showOwner(bool value) {
    _showOwner = value;
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  bool _showSovCount = true;

  bool get showSovCount => _showSovCount;

  set showSovCount(bool value) {
    _showSovCount = value;
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  bool _showOverallScore = true;

  bool get showOverallScore => _showOverallScore;

  set showOverallScore(bool value) {
    _showOverallScore = value;
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // Pagination
  int _page = 1;

  int get page => _page;

  set page(int value) {
    _page = value;
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  int _totalPages = 1;

  int get totalPages => _totalPages;

  set totalPages(int value) {
    _totalPages = value;
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  int totalRecords = 0;

  List<SubAccounts> _subAccountList = [];

  List<SubAccounts> get subAccountList => _subAccountList;

  set subAccountList(List<SubAccounts> value) {
    _subAccountList = value;
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void addToSubAccountList(List<SubAccounts> newAccounts) {
    _subAccountList.addAll(newAccounts);
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  List<SubAccounts> _autoCompleteSubAccountList = [];

  List<SubAccounts> get autoCompleteSubAccountList =>
      _autoCompleteSubAccountList;

  set autoCompleteSubAccountList(List<SubAccounts> value) {
    _autoCompleteSubAccountList = value;
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void clearAutoCompleteList() {
    autoCompleteSubAccountList = [];
  }

  /// Fetch sub accounts list with pagination and search query
  Future<void> fetchSubAccountList(
      BuildContext context,
      String selectedAccountId,
      String searchQuery,
      int page,
      int pageSize) async {
    var typography = CustomTypography(context);
    bool isConnectedToInternet = await checkIsConnectedToInternet();
    if (isConnectedToInternet != "ConnectivityResult.none") {
      var typography = CustomTypography(context);
      try {
        if (page == 1) {
          isLoading = true;
        } else {
          isNextPageLoading = true;
        }

        ApiService apiService = ApiService(AppConstant.GET_SUB_ACCOUNT_LIST +
            "/sub_accounts?account_id=$selectedAccountId");
        String url = '&page=$page&pageSize=$pageSize';
        if (searchQuery.isNotEmpty) {
          url += '&search=$searchQuery';
        }

        var response = await apiService.get(url);
        log(response.toString());

        SubAccountListModel subAccountListModel =
            SubAccountListModel.fromJson(response);

        showOwner = subAccountListModel.settings?.owner ?? true;
        showSovCount = subAccountListModel.settings?.sovCount ?? true;
        totalRecords = subAccountListModel.totalHits ?? 0;
        totalPages = totalRecords ~/ pageSize;

        //totalPages = subAccountListModel.totalPages??1;
        if (page == 1) {
          subAccountList = subAccountListModel.results ?? [];
        } else {
          addToSubAccountList(subAccountListModel.results ?? []);
        }
        log(subAccountList.toString());
        log(totalPages.toString());
        log(page.toString());
        isLoading = false;
        isNextPageLoading = false;
      } on BackendException catch (e, stackTrace) {
        isLoading = false;
        isNextPageLoading = false;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            e.message,
            style: typography.Body1,
          ),
        ));
        print(stackTrace);
      } catch (e, stackTrace) {
        isLoading = false;
        isNextPageLoading = false;
        // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        //   content: Text(
        //     e.toString(),
        //     style: typography.Body1,
        //   ),
        // ));
        print(e);
        print(stackTrace);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          "Please check your internet connectivity and try again",
          style: typography.Body1,
        ),
      ));
      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      //   content: Text(
      //     pleaseCheckYourInternetConnectivityAndTryAgain.toString(),
      //     style: typography.Body1,
      //   ),
      // ));
    }
  }

  /// Rename sub account
  Future<void> renameSubAccount(BuildContext context, String accountId,
      String subAccountId, String newName) async {
    var typography = CustomTypography(context);
    try {
      isRenameLoading = true;

      ApiService apiService = ApiService(AppConstant.RENAME_SUB_ACCOUNT +
          "/$accountId/subaccount"); // Updated URL
      var response = await apiService.patch({
        'data': {
          "rename_subaccount": true,
          'sub_account_id': subAccountId, // Updated field
          'sub_account_name': newName, // Updated field
        }
      });
      log(response.toString());

      // Update account name in the list
      int index = subAccountList
          .indexWhere((element) => element.subAccountId == subAccountId);
      if (index != -1) {
        subAccountList[index].name = newName;
      }

      isRenameLoading = false;
    } on BackendException catch (e) {
      isRenameLoading = false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          e.message,
          style: typography.Body1,
        ),
      ));
    } catch (e) {
      isRenameLoading = false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          e.toString(),
          style: typography.Body1,
        ),
      ));
    }
  }

  Future<bool> deleteAccount(
      BuildContext context, String accountId, String subaccountId) async {
    try {
      isDeleteLocationLoading = true;
      notifyListeners(); // Notify UI to update the button state

      ApiService apiService = ApiService(
          "${AppConstant.DELETE_SUB_ACCOUNT}account_id=$accountId&sub_account_id=$subaccountId");
      var response = await apiService.delete({});

      log(response.toString());
      CustomToast.success(context, response['message']);

      return true; // Return true only if successful
    } on BackendException catch (e, stackTrace) {
      log("Error deleting account: ${e.message}");
      log(stackTrace.toString());
      CustomToast.error(context, e.message);
      return false;
    } catch (e, stackTrace) {
      log("Unexpected error: $e");
      log(stackTrace.toString());
      CustomToast.error(context, "An unexpected error occurred");
      return false;
    } finally {
      isDeleteLocationLoading = false;
      notifyListeners(); // Notify UI to remove the loader
    }
  }

  /// Duplicate sub account
  Future<void> duplicateSubAccount(
      BuildContext context, String accountId, String subAccountId) async {
    var typography = CustomTypography(context);
    try {
      isDuplicateLoading = true;

      ApiService apiService = ApiService(
          AppConstant.DUPLICATE_SUB_ACCOUNT + "/$accountId/subaccount");
      var response = await apiService.post({
        'data': {
          'sub_account_id': subAccountId,
          'duplicate': true,
        }
      });
      log(response.toString());

      // Parse the response to get the duplicated sub-account
      SubAccounts duplicatedSubAccount =
          SubAccounts.fromJson(response['updated_record']);

      // Prepend the duplicated sub-account to the beginning of the list
      subAccountList = [duplicatedSubAccount, ...subAccountList];

      isDuplicateLoading = false;
    } on BackendException catch (e) {
      isDuplicateLoading = false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message, style: typography.Body1),
      ));
    } catch (e) {
      isDuplicateLoading = false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString(), style: typography.Body1),
      ));
    }
  }

  /// Change column visibility
  Future<bool> changeColumnVisibility(BuildContext context,
      {required String accountId,
      required bool showOwner,
      required bool showSOVCount,
      required bool showOverallScore,
      required String type}) async {
    var typography = CustomTypography(context);
    try {
      if (type == 'owner') {
        isOwnerLoading = true;
      } else if (type == 'sov_count') {
        showSOVCountLoading = true;
      } else if (type == 'sub_account_count') {
        showSubAccountCountLoading = true;
      } else if (type == 'overall_score') {
        showOverallScoreLoading = true;
      }

      ApiService apiService = ApiService(
          AppConstant.CHANGE_COLUMN_VISIBILITY_SUB_ACCOUNT +
              "/$accountId/subaccount"); // Updated URL

      var response = await apiService.patch({
        'data': {
          'table_setting': true,
          'owner': showOwner,
          'sov_count': showSOVCount,
          'overall_score': showOverallScore,
        }
      });
      log(response.toString());
      isOwnerLoading = false;
      showSOVCountLoading = false;
      showSubAccountCountLoading = false;
      showOverallScoreLoading = false;
      return true;
    } on BackendException catch (e) {
      isOwnerLoading = false;
      showSOVCountLoading = false;
      showSubAccountCountLoading = false;
      showOverallScoreLoading = false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          e.message,
          style: typography.Body1,
        ),
      ));
      return false;
    } catch (e) {
      isOwnerLoading = false;
      showSOVCountLoading = false;
      showSubAccountCountLoading = false;
      showOverallScoreLoading = false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          e.toString(),
          style: typography.Body1,
        ),
      ));
      return false;
    }
  }

  /// Fetch autocomplete sub account list
  Future<void> fetchAutoCompleteSubAccountList(
      BuildContext context, String searchQuery, String accountId) async {
    var typography = CustomTypography(context);
    try {
      isAutoCompleteLoading = true;

      print("Fetching autocomplete list for query: $searchQuery");
      ApiService apiService = ApiService(AppConstant.GET_SUB_ACCOUNT_LIST);

      String url =
          '/sub_accounts?account_id=$accountId&search=$searchQuery'; // Updated field
      var response = await apiService.get(url);
      log(response.toString());

      SubAccountListModel accountListModel =
          SubAccountListModel.fromJson(response);

      autoCompleteSubAccountList = accountListModel.results ?? [];
      log(autoCompleteSubAccountList.toString());
      print("Updated autoCompleteSubAccountList: $autoCompleteSubAccountList");
    } on BackendException catch (e, stack) {
      /*ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message, style: typography.Body1,),
      ));*/
      print(e.message);
      print(stack);
    } catch (e, stack) {
      print(e.toString());
      print(stack);
      /*ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString(), style: typography.Body1,),
      ));*/
    } finally {
      isAutoCompleteLoading = false;
    }
  }

  /// Add sub account
  Future<void> addSubAccount(
      BuildContext context, String accountName, String accountId) async {
    var typography = CustomTypography(context);
    try {
      isAddSubAccountLoading = true;

      ApiService apiService =
          ApiService(AppConstant.ADD_SUB_ACCOUNT + "/$accountId");
      var response = await apiService.post({
        'data': {
          'name': accountName,
        }
      });
      log(response.toString());

      // Parse the response to get the newly added sub-account
      SubAccounts newSubAccount =
          SubAccounts.fromJson(response['updated_record']);
      newSubAccount.sovCount = 0;
      totalRecords = totalRecords + 1;

      // Prepend the new sub-account to the beginning of the list
      subAccountList = [newSubAccount, ...subAccountList];

      isAddSubAccountLoading = false;
    } on BackendException catch (e, stackTrace) {
      isAddSubAccountLoading = false;
      print(stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message, style: typography.Body1),
      ));
    } catch (e, stackTrace) {
      print(stackTrace);
      isAddSubAccountLoading = false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString(), style: typography.Body1),
      ));
    }
  }

  /// Request access with message
  Future<void> requestAccess(BuildContext context, String subAccountId,
      String message, String accountId) async {
    var typography = CustomTypography(context);
    try {
      ApiService apiService =
          ApiService(AppConstant.REQUEST_ACCESS + "/$accountId/subaccount");
      var response = await apiService.post({
        'data': {
          'sub_account_id': subAccountId,
          'message': message,
        }
      });
      log(response.toString());
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          'Request sent successfully!',
          style: typography.Body1,
        ),
      ));
    } on BackendException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          e.message,
          style: typography.Body1,
        ),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          e.toString(),
          style: typography.Body1,
        ),
      ));
    }
  }

  /// Upload SOV
  Future<String> uploadSovAccount(BuildContext context, File sovFile,
      String accountId, String subAccountId, String name) async {
    var typography = CustomTypography(context);
    try {
      isImageUploadLoading = true;
      ApiService apiService =
          ApiService(AppConstant.UPLOAD_SOV_SUB_ACCOUNT + '/upload');
      print(apiService);
      // Send a POST request to the API to upload the image
      Map<String, dynamic> response = await apiService
          .postMultiPartSOVSubAccounts(sovFile, accountId, subAccountId, name);
      // print(response!.message.toString());
      isImageUploadLoading = false;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          response['message'] ??
              LanguageService.getTranslated(
                  context, "sub_account_list_app_sov_upload_success"),
          style: typography.Body1,
        ),
      ));
      print("total records: " + response['total_records'].toString());
      if (response['total_records'] == 0) {
        print("total records: " + response['total_records'].toString());
        String tempId = (response['temp_id'] ?? '') + "+";
        print("tempIdLocal: " + tempId);
        return tempId;
      }
      return response['temp_id'] ?? '';
    } on BackendException catch (e) {
      isImageUploadLoading = false;
      Navigator.pop(context);

      print("Raw Backend Exception Message: ${e.message}");

      // Initialize a variable to store the error message
      String message = '';

      try {
        // Check if the message is a JSON string
        if (e.message.trim().startsWith('{') &&
            e.message.trim().endsWith('}')) {
          // Attempt to parse the message as JSON
          final Map<String, dynamic> errorJson = jsonDecode(e.message.trim());

          // Extract the error message
          message = errorJson['error'] ?? 'An unexpected error occurred';
        } else {
          // If it's not JSON, use the message as-is
          message = e.message;
        }
      } catch (decodeError) {
        // Handle any JSON parsing errors
        print('JSON Decode Error: $decodeError');

        // Fallback to the raw message or a generic error message
        message = e.message ??
            'An unexpected error occurred. Please try again later.';
      }

      // Display the error message in a SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: typography.Body1,
          ),
        ),
      );

      return ''; // Return an empty string or handle the error as needed
    } catch (e) {
      // Handle other unexpected exceptions
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${e.toString()}',
            style: typography.Body1,
          ),
        ),
      );
      isImageUploadLoading = false;
      return ''; // Return empty string or handle the error as needed
    }
  }

  /// Transfer sub account
  Future<void> transferSubAccount(BuildContext context, String accountId,
      String? subAccountId, String newOwnerId) async {
    try {
      isTransferLoading = true;

      ApiService apiService = ApiService(AppConstant.TRANSFER_SUBACCOUNT);
      var response = await apiService.post({
        'data': {
          'to_user_id': newOwnerId,
          'account_id': accountId,
          'sub_account_id': subAccountId,
        },
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text(response['message'] ?? 'Sub Account transferred successfully'),
      ));

      // Update the account list UI
      int index = subAccountList
          .indexWhere((element) => element.subAccountId == subAccountId);
      if (index != -1) {
        subAccountList[index].disabled = true;
      }

      isTransferLoading = false;
    } on BackendException catch (e) {
      isTransferLoading = false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message),
      ));
    } catch (e) {
      isTransferLoading = false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to transfer sub account: ${e.toString()}'),
      ));
    }
  }
}
