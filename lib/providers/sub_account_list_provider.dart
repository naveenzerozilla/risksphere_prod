import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:green/design_system/primitives/custom_typography.dart';
import 'package:green/models/account_list_model.dart';
import 'package:green/models/sub_account_list_model.dart';
import 'package:green/service/api_service.dart';
import 'package:green/utils/api_constants.dart';

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

  List<SubAccounts> _subAccountList = [];
  List<SubAccounts> get subAccountList => _subAccountList;
  set subAccountList(List<SubAccounts> value) {
    _subAccountList = value;
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      notifyListeners();
    });
  }
  void addToAccountList(List<SubAccounts> newAccounts) {
    _subAccountList.addAll(newAccounts);
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  List<SubAccounts> _autoCompleteSubAccountList = [];
  List<SubAccounts> get autoCompleteSubAccountList => _autoCompleteSubAccountList;
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
  Future<void> fetchSubAccountList(BuildContext context, String selectedAccountId, String searchQuery, int page, int pageSize) async {
    try {
      if (page == 0) {
        isLoading = true;
      } else {
        isNextPageLoading = true;
      }

      ApiService apiService = ApiService(AppConstant.GET_SUB_ACCOUNT_LIST+"/$selectedAccountId/subaccount/mobile");
      String url = '?page=$page&pageSize=$pageSize';
      if (searchQuery.isNotEmpty) {
        url += '?search=$searchQuery';
      }

      var response = await apiService.get(url);
      log(response.toString());

      SubAccountListModel accountListModel = SubAccountListModel.fromJson(response);

      showOwner = accountListModel.settings?.owner ?? true;
      showSovCount = accountListModel.settings?.sovCount ?? true;

      totalPages = accountListModel.totalPages??1;
      if (page == 0) {
        subAccountList = accountListModel.results ?? [];
      } else {
        addToAccountList(accountListModel.results ?? []);
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
        content: Text(e.message, style: CustomTypography.Body1,),

      ));
      print(stackTrace);
    } catch (e, stackTrace) {
      isLoading = false;
      isNextPageLoading = false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString(), style: CustomTypography.Body1,),

      ));
      print(e);
      print(stackTrace);
    }
  }

  /// Rename sub account
  Future<void> renameSubAccount(BuildContext context, String accountId, String subAccountId, String newName) async {
    try {
      isRenameLoading = true;

      ApiService apiService = ApiService(AppConstant.RENAME_SUB_ACCOUNT+"/$accountId/subaccount");  // Updated URL
      var response = await apiService.patch({'data': {
        'sub_account_id': subAccountId,  // Updated field
        'sub_account_name': newName,  // Updated field
      }});
      log(response.toString());

      // Update account name in the list
      int index = subAccountList.indexWhere((element) => element.subAccountId == subAccountId);
      if (index != -1) {
        subAccountList[index].name = newName;
      }

      isRenameLoading = false;
    } on BackendException catch (e) {
      isRenameLoading = false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message, style: CustomTypography.Body1,),
      ));
    } catch (e) {
      isRenameLoading = false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString(), style: CustomTypography.Body1,),
      ));
    }
  }

  /// Duplicate sub account
  Future<void> duplicateSubAccount(BuildContext context, String accountId, String subAccountId) async {
    try {
      isDuplicateLoading = true;

      ApiService apiService = ApiService(AppConstant.DUPLICATE_SUB_ACCOUNT+"/$accountId/subaccount");  // Updated URL
      var response = await apiService.post({'data': {
        'sub_account_id': subAccountId,  // Updated field
        'duplicate': true,
      }});
      log(response.toString());

      // Refresh the sub accounts list
      page = 0;
      fetchSubAccountList(context, accountId, '', 0, 10);

      isDuplicateLoading = false;
    } on BackendException catch (e) {
      isDuplicateLoading = false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message, style: CustomTypography.Body1,),

      ));
    } catch (e) {
      isDuplicateLoading = false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString(), style: CustomTypography.Body1,),

      ));
    }
  }

  /// Change column visibility
  Future<bool> changeColumnVisibility(BuildContext context, {required String accountId, required bool showOwner, required bool showSOVCount, required bool showOverallScore, required String type}) async {
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

      ApiService apiService = ApiService(AppConstant.CHANGE_COLUMN_VISIBILITY_SUB_ACCOUNT+"/$accountId/subaccount");  // Updated URL

      var response = await apiService.patch({'data': {
        'table_setting': true,
        'owner': showOwner,
        'sov_count': showSOVCount,
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
      ));
      return false;
    } catch (e) {
      isOwnerLoading = false;
      showSOVCountLoading = false;
      showSubAccountCountLoading = false;
      showOverallScoreLoading = false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString(), style: CustomTypography.Body1,),
      ));
      return false;
    }
  }

  /// Fetch autocomplete sub account list
  Future<void> fetchAutoCompleteSubAccountList(BuildContext context, String searchQuery, String accountId) async {
    try {
      isAutoCompleteLoading = true;

      print("Fetching autocomplete list for query: $searchQuery");
      ApiService apiService = ApiService(AppConstant.GET_SUB_ACCOUNT_LIST+"/$accountId/subaccount");
      String url = '?sub_account_name=$searchQuery';  // Updated field
      var response = await apiService.get(url);
      log(response.toString());

      SubAccountListModel accountListModel = SubAccountListModel.fromJson(response);

      autoCompleteSubAccountList = accountListModel.results ?? [];
      log(autoCompleteSubAccountList.toString());
      print("Updated autoCompleteSubAccountList: $autoCompleteSubAccountList");
    } on BackendException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message, style: CustomTypography.Body1,),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString(), style: CustomTypography.Body1,),
      ));
    } finally {
      isAutoCompleteLoading = false;
    }
  }

  /// Add sub account
  Future<void> addSubAccount(BuildContext context, String subAccountId, String accountName, String accountId) async {
    try {
      isAddSubAccountLoading = true;

      ApiService apiService = ApiService(AppConstant.ADD_SUB_ACCOUNT+"/$accountId/subaccount");  // Updated URL
      var response = await apiService.post({'data': {
        'sub_account_name': accountName,  // Updated field
      }});
      log(response.toString());

      // Refresh the sub accounts list
      page = 0;
      fetchSubAccountList(context, accountId, '', 0, 10);

      isAddSubAccountLoading = false;
    } on BackendException catch (e) {
      isAddSubAccountLoading = false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message, style: CustomTypography.Body1,),

      ));
    } catch (e) {
      isAddSubAccountLoading = false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString(), style: CustomTypography.Body1,),

      ));
    }
  }

  /// Request access with message
  Future<void> requestAccess(BuildContext context, String subAccountId, String message, String accountId) async {
    try {
      ApiService apiService = ApiService(AppConstant.REQUEST_ACCESS+"/$accountId/subaccount");
      var response = await apiService.post({'data':{
        'sub_account_id': subAccountId,
        'message': message,
      }});
      log(response.toString());
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Request sent successfully!', style: CustomTypography.Body1,),

      ));
    } on BackendException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message, style: CustomTypography.Body1,),

      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString(), style: CustomTypography.Body1,),

      ));
    }
  }
}
