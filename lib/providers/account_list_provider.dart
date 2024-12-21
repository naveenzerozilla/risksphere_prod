import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:green/design_system/primitives/custom_typography.dart';
import 'package:green/models/account_list_model.dart';
import 'package:green/service/api_service.dart';
import 'package:green/service/language_service.dart';
import 'package:green/utils/api_constants.dart';

class AccountListProvider extends ChangeNotifier {

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
    notifyListeners(); // This ensures the UI updates
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
  bool get isAddAccountLoading => _isAddAccountLoading;
  set isAddAccountLoading(bool value) {
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

  // Column Visibility
  bool _showOwner = true;
  bool get showOwner => _showOwner;
  set showOwner(bool value) {
    _showOwner = value;
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  bool _showSOVCount = true;
  bool get showSOVCount => _showSOVCount;
  set showSOVCount(bool value) {
    _showSOVCount = value;
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  bool _showSubAccountCount = true;
  bool get showSubAccountCount => _showSubAccountCount;
  set showSubAccountCount(bool value) {
    _showSubAccountCount = value;
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

  int accountHits = 0;

  List<Accounts> _accountList = [];
  List<Accounts> get accountList => _accountList;
  set accountList(List<Accounts> value) {
    _accountList = value;
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      notifyListeners();
    });
  }
  void addToAccountList(List<Accounts> newAccounts) {
    _accountList.addAll(newAccounts);
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  List<Accounts> _autoCompleteAccountList = [];
  List<Accounts> get autoCompleteAccountList => _autoCompleteAccountList;
  set autoCompleteAccountList(List<Accounts> value) {
    _autoCompleteAccountList = value;
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      notifyListeners();
    });
  }
  void clearAutoCompleteList() {
    autoCompleteAccountList = [];
  }

  /// Fetch account list with pagination and search query
  Future<void> fetchAccountList(BuildContext context, String searchQuery, int page, int pageSize) async {
    var typography = CustomTypography(context);
    try {
      if(isLoading || isNextPageLoading) return;
      if (page == 1) {
        isLoading = true;
      } else {
        isNextPageLoading = true;
      }
      ApiService apiService = ApiService(AppConstant.GET_ACCOUNT_LIST);
      String url = '?page=$page&pageSize=$pageSize';
      if (searchQuery.isNotEmpty) {
        url += '&search=$searchQuery'; // Change ? to & here
      }

      var response = await apiService.get(url);
      log(response.toString());


      AccountListModel accountListModel = AccountListModel.fromJson(response);

      showOwner = accountListModel.settings?.owner ?? true;
      showSOVCount = accountListModel.settings?.sovCount ?? true;
      showSubAccountCount = accountListModel.settings?.subAccountCount ?? true;
      showOverallScore = accountListModel.settings?.overallScore ?? true;
      accountHits = accountListModel.totalRecords??0;
      totalPages = accountHits~/pageSize;
     // totalPages = accountListModel.totalPages??1;
      if (page == 1) {
        accountList = accountListModel.results ?? [];
      } else {
        addToAccountList(accountListModel.results ?? []);
      }
      log(accountList.toString());
      log(totalPages.toString());
      log(page.toString());
      isLoading = false;
      isNextPageLoading = false;
    } on BackendException catch (e, stackTrace) {
      print(stackTrace);
      isLoading = false;
      isNextPageLoading = false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message, style: typography.Body1,),

      ));
    } catch (e, stackTrace) {
      print(stackTrace);
      isLoading = false;
      isNextPageLoading = false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString(), style: typography.Body1,),

      ));
    }
  }

  /// Rename account
  Future<void> renameAccount(BuildContext context, String accountId, String newName) async {
    var typography = CustomTypography(context);
    try {
      isRenameLoading = true;

      ApiService apiService = ApiService(AppConstant.RENAME_ACCOUNT);
      var response = await apiService.patch({'data':{
        "rename_account": true,
        'account_id': accountId,
        'account_name': newName,
      }});
      log(response.toString());

      // Update account name in the list
      int index = accountList.indexWhere((element) => element.accountId == accountId);
      if (index != -1) {
        accountList[index].accountName = newName;
      }

      isRenameLoading = false;
    } on BackendException catch (e) {
      isRenameLoading = false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message, style: typography.Body1,),

      ));
    } catch (e) {
      isRenameLoading = false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString(), style: typography.Body1,),

      ));
    }
  }

  /// Duplicate account
  Future<void> duplicateAccount(BuildContext context, String accountId) async {
    var typography = CustomTypography(context);
    try {
      isDuplicateLoading = true;

      ApiService apiService = ApiService(AppConstant.DUPLICATE_ACCOUNT);
      var response = await apiService.post({'data':{
        'account_id': accountId,
        'duplicate': true,
      }});
      log(response.toString());

      // Parse the response to get the duplicated account
      Accounts duplicatedAccount = Accounts.fromJson(response['updated_record']["duplicatedAccountData"]);

      // Prepend the duplicated account to the beginning of the list
      accountList = [duplicatedAccount, ...accountList];

      isDuplicateLoading = false;
    } on BackendException catch (e) {
      isDuplicateLoading = false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message, style: typography.Body1,),

      ));
    } catch (e) {
      isDuplicateLoading = false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString(), style: typography.Body1,),

      ));
    }
  }


  /// Change column visibility
  Future<bool> changeColumnVisibility(BuildContext context, {required bool showOwner, required bool showSOVCount, required bool showSubAccountCount, required bool showOverallScore, required String type}) async {
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

      ApiService apiService = ApiService(AppConstant.CHANGE_COLUMN_VISIBILITY);

      var response = await apiService.patch({'data':{
        'table_setting': true,
        'owner': showOwner,
        'sov_count': showSOVCount,
        'sub_account_count': showSubAccountCount,
        'overall_score': showOverallScore,
      }});
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
        content: Text(e.message, style: typography.Body1,),

      ));
      return false;
    } catch (e) {
      isOwnerLoading = false;
      showSOVCountLoading = false;
      showSubAccountCountLoading = false;
      showOverallScoreLoading = false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString(), style: typography.Body1,),

      ));
      return false;
    }
  }

  /// Fetch autocomplete account list
  Future<void> fetchAutoCompleteAccountList(BuildContext context, String searchQuery) async {
    var typography = CustomTypography(context);
    try {
      isAutoCompleteLoading = true;

      print("Fetching autocomplete list for query: $searchQuery");
      ApiService apiService = ApiService(AppConstant.GET_ACCOUNT_LIST);
      String url = '?search=$searchQuery';
      var response = await apiService.get(url);
      log(response.toString());

      AccountListModel accountListModel = AccountListModel.fromJson(response);

      autoCompleteAccountList = accountListModel.results ?? [];
      log(autoCompleteAccountList.toString());
      print("Updated autoCompleteAccountList: $autoCompleteAccountList");
    } on BackendException catch (e, stackTrace) {
      print(stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message, style: typography.Body1,),

      ));
    } catch (e, stackTrace) {
      print(stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString(), style: typography.Body1,),

      ));
    } finally {
      isAutoCompleteLoading = false;
    }
  }

  /// Add account
  Future<void> addAccount(BuildContext context, String accountName) async {
    var typography = CustomTypography(context);
    try {
      isAddAccountLoading = true;

      ApiService apiService = ApiService(AppConstant.ADD_ACCOUNT);
      var response = await apiService.post({'data':{
        'account_name': accountName,
      }});
      log(response.toString());

      // Parse the response to get the newly added account
      Accounts newAccount = Accounts.fromJson(response['updated_record']);
      newAccount.sovCount = 0;
      newAccount.subAccountCount = 0;
      accountHits++;

      // Prepend the new account to the beginning of the list
      accountList = [newAccount, ...accountList];

      isAddAccountLoading = false;
    } on BackendException catch (e) {
      isAddAccountLoading = false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message, style: typography.Body1,),

      ));
    } catch (e) {
      isAddAccountLoading = false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString(), style: typography.Body1,),

      ));
    }
  }


  // Request access with message
  Future<void> requestAccess(BuildContext context, String accountId, String message) async {
    var typography = CustomTypography(context);
    try {
      ApiService apiService = ApiService(AppConstant.REQUEST_ACCESS);
      var response = await apiService.post({'data':{
        'account_id': accountId,
        'message': message,
      }});
      log(response.toString());
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Request sent successfully!', style: typography.Body1,),

      ));
    } on BackendException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message, style: typography.Body1,),

      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString(), style: typography.Body1,),

      ));
    }
  }

  Future<String> uploadSovAccount(BuildContext context, File sovFile,String accountId, String name) async {
    var typography = CustomTypography(context);
    try {
      isImageUploadLoading = true;
      ApiService apiService = ApiService(AppConstant.UPLOAD_SOV_ACCOUNT + '/upload');
      print(AppConstant.UPLOAD_SOV_ACCOUNT + '/upload');
      print(apiService);
      // Send a POST request to the API to upload the image
      Map<String, dynamic> response = await apiService.postMultiPartSOVAccounts(sovFile, accountId, name);
      // print(response!.message.toString());
      isImageUploadLoading = false;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          response['message']??LanguageService.getTranslated(context, "account_list_app_sov_upload_success"),
          style: typography.Body1,
        ),
      ));
      print("total records: "+response['total_records'].toString());
      if(response['total_records'] == 0){
        print("total records: "+response['total_records'].toString());
        String tempId = (response['temp_id']??'') + "+";
        print("tempIdLocal: "+tempId);
        return tempId;
      }
      return response['temp_id']??'';
    } on BackendException catch (e) {
      isImageUploadLoading = false;
      Navigator.pop(context);

      print("Raw Backend Exception Message: ${e.message}");

      // Initialize a variable to store the error message
      String message = '';

      try {
        // Check if the message is a JSON string
        if (e.message.trim().startsWith('{') && e.message.trim().endsWith('}')) {
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
        message = e.message ?? 'An unexpected error occurred. Please try again later.';
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
    }catch (e) {
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

  Future<void> transferAccount(BuildContext context, String accountId, String newOwnerId) async {
    var typography = CustomTypography(context);
    try {
      isTransferLoading = true;

      ApiService apiService = ApiService(AppConstant.TRANSFER_ACCOUNT);
      var response = await apiService.post({
        'data': {
          'to_user_id': newOwnerId,
          'account_id': accountId,
        },
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(response['message'] ?? 'Account transferred successfully'),
      ));

      // Update the account list UI
      int index = accountList.indexWhere((element) => element.accountId == accountId);
      if (index != -1) {
        accountList[index].disabled = true;
      }

      isTransferLoading = false;
    } on BackendException catch (e) {
      isTransferLoading = false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message),
      ));
    }
    catch (e) {
      isTransferLoading = false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to transfer account: ${e.toString()}'),
      ));
    }
  }

}
