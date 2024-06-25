import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:green/design_system/primitives/custom_typography.dart';
import 'package:green/models/account_list_model.dart';
import 'package:green/service/api_service.dart';
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
  bool get isAddAccountLoading => _isAddAccountLoading;
  set isAddAccountLoading(bool value) {
    _isAddAccountLoading = value;
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

  /// Fetch account list with pagination and search query
  Future<void> fetchAccountList(BuildContext context, String searchQuery, int page, int pageSize) async {
    try {
      if (page == 1) {
        isLoading = true;
      } else {
        isNextPageLoading = true;
      }

      ApiService apiService = ApiService(AppConstant.GET_ACCOUNT_LIST);
      String url = '?page=$page&pageSize=$pageSize';
      if (searchQuery.isNotEmpty) {
        url += '?search=$searchQuery';
      }

      var response = await apiService.get(url);
      log(response.toString());

      AccountListModel accountListModel = AccountListModel.fromJson(response);

      totalPages = accountListModel.totalPages??1;
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
    } on BackendException catch (e) {
      isLoading = false;
      isNextPageLoading = false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message, style: CustomTypography.Body1,),
        backgroundColor: Colors.red,
      ));
    } catch (e) {
      isLoading = false;
      isNextPageLoading = false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString(), style: CustomTypography.Body1,),
        backgroundColor: Colors.red,
      ));
    }
  }

  /// Rename account
  Future<void> renameAccount(BuildContext context, String accountId, String newName) async {
    try {
      isRenameLoading = true;

      ApiService apiService = ApiService(AppConstant.RENAME_ACCOUNT);
      var response = await apiService.post({'data':{
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
        content: Text(e.message, style: CustomTypography.Body1,),
        backgroundColor: Colors.red,
      ));
    } catch (e) {
      isRenameLoading = false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString(), style: CustomTypography.Body1,),
        backgroundColor: Colors.red,
      ));
    }
  }

  /// Duplicate account
  Future<void> duplicateAccount(BuildContext context, String accountId) async {
    try {
      isDuplicateLoading = true;

      ApiService apiService = ApiService(AppConstant.DUPLICATE_ACCOUNT);
      var response = await apiService.post({'data':{
        'account_id': accountId,
        'duplicate': true,
      }});
      log(response.toString());

      // Update account name in the list
      page = 1;
      fetchAccountList(context, '', 1, 10);

      isDuplicateLoading = false;
    } on BackendException catch (e) {
      isDuplicateLoading = false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message, style: CustomTypography.Body1,),
        backgroundColor: Colors.red,
      ));
    } catch (e) {
      isDuplicateLoading = false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString(), style: CustomTypography.Body1,),
        backgroundColor: Colors.red,
      ));
    }
  }

  /// Change column visibility
  Future<bool> changeColumnVisibility(BuildContext context, {required bool showOwner, required bool showSOVCount, required bool showSubAccountCount, required bool showOverallScore, required String type}) async {
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
        content: Text(e.message, style: CustomTypography.Body1,),
        backgroundColor: Colors.red,
      ));
      return false;
    } catch (e) {
      isOwnerLoading = false;
      showSOVCountLoading = false;
      showSubAccountCountLoading = false;
      showOverallScoreLoading = false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString(), style: CustomTypography.Body1,),
        backgroundColor: Colors.red,
      ));
      return false;
    }
  }

  /// Fetch autocomplete account list
  Future<void> fetchAutoCompleteAccountList(BuildContext context, String searchQuery) async {
    try {
      ApiService apiService = ApiService(AppConstant.GET_ACCOUNT_LIST);
      String url = '?account_name=$searchQuery';
      var response = await apiService.get(url);
      log(response.toString());

      AccountListModel accountListModel = AccountListModel.fromJson(response);

      autoCompleteAccountList = accountListModel.results ?? [];
      log(autoCompleteAccountList.toString());
    } on BackendException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message, style: CustomTypography.Body1,),
        backgroundColor: Colors.red,
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString(), style: CustomTypography.Body1,),
        backgroundColor: Colors.red,
      ));
    }
  }

  /// Add account
  Future<void> addAccount(BuildContext context, String accountName) async {
    try {
      isAddAccountLoading = true;

      ApiService apiService = ApiService(AppConstant.ADD_ACCOUNT);
      var response = await apiService.post({'data':{
        'account_name': accountName,
      }});
      log(response.toString());

      // Update account name in the list
      page = 1;
      fetchAccountList(context, '', 1, 10);

      isAddAccountLoading = false;
    } on BackendException catch (e) {
      isAddAccountLoading = false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message, style: CustomTypography.Body1,),
        backgroundColor: Colors.red,
      ));
    } catch (e) {
      isAddAccountLoading = false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString(), style: CustomTypography.Body1,),
        backgroundColor: Colors.red,
      ));
    }
  }

  // Request access with message
  Future<void> requestAccess(BuildContext context, String accountId, String message) async {
    try {
      ApiService apiService = ApiService(AppConstant.REQUEST_ACCESS);
      var response = await apiService.post({'data':{
        'account_id': accountId,
        'message': message,
      }});
      log(response.toString());
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Request sent successfully!', style: CustomTypography.Body1,),
        backgroundColor: Colors.green,
      ));
    } on BackendException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message, style: CustomTypography.Body1,),
        backgroundColor: Colors.red,
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString(), style: CustomTypography.Body1,),
        backgroundColor: Colors.red,
      ));
    }
  }
}
