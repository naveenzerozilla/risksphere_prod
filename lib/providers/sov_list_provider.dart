import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:green/design_system/primitives/custom_typography.dart';
import 'package:green/models/account_list_model.dart';
import 'package:green/models/sov_list_model.dart';
import 'package:green/service/api_service.dart';
import 'package:green/utils/api_constants.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../service/language_service.dart';
import '../utils/common_headers.dart';

class SOVListProvider extends ChangeNotifier {

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



  bool _showLocationCountLoading = false;
  bool get showLocationCountLoading => _showLocationCountLoading;
  set showLocationCountLoading(bool value) {
    _showLocationCountLoading = value;
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

  bool _isExportLoading = false;
  bool get isExportLoading => _isExportLoading;
  set isExportLoading(bool value) {
    _isExportLoading = value;
    WidgetsBinding.instance!.addPostFrameCallback((_) {
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

  // columns
  bool _showLocationCount = true;
  bool get showLocationCount => _showLocationCount;
  set showLocationCount(bool value) {
    _showLocationCount = value;
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

  List<SovAccount> _accountList = [];
  List<SovAccount> get sovList => _accountList;
  set sovList(List<SovAccount> value) {
    _accountList = value;
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      notifyListeners();
    });
  }
  void addToAccountList(List<SovAccount> newAccounts) {
    _accountList.addAll(newAccounts);
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  List<SovAccount> _autoCompleteSovList = [];
  List<SovAccount> get autoCompleteSovList => _autoCompleteSovList;
  set autoCompleteSovList(List<SovAccount> value) {
    _autoCompleteSovList = value;
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      notifyListeners();
    });
  }
  void clearAutoCompleteList() {
    autoCompleteSovList = [];
  }

  /// Fetch sov list with pagination and search query
  Future<void> fetchSovList(BuildContext context, String selectedAccountId, String selectedSubAccountId, String searchQuery, int page, int pageSize) async {
    try {
      if (page == 0) {
        isLoading = true;
      } else {
        isNextPageLoading = true;
      }

      ApiService apiService = ApiService(AppConstant.GET_SOV_LIST+"/$selectedAccountId/subaccount/$selectedSubAccountId/sov/mobile");
      String url = '?page=$page&pageSize=$pageSize';
      if (searchQuery.isNotEmpty) {
        url += '?search=$searchQuery';
      }

      var response = await apiService.get(url);
      log(response.toString());

      SovListModel sovListModel = SovListModel.fromJson(response);

      showLocationCount = sovListModel.settings?.locationCount ?? true;
      showOverallScore = sovListModel.settings?.overAllScore ?? true;
      totalPages = sovListModel.totalPages??1;
      if (page == 0) {
        sovList = sovListModel.results ?? [];
      } else {
        addToAccountList(sovListModel.results ?? []);
      }
      log(sovList.toString());
      log(totalPages.toString());
      log(page.toString());
      isLoading = false;
      isNextPageLoading = false;
    } on BackendException catch (e) {
      isLoading = false;
      isNextPageLoading = false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message, style: CustomTypography.Body1,),

      ));
    } catch (e) {
      isLoading = false;
      isNextPageLoading = false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString(), style: CustomTypography.Body1,),

      ));
    }
  }

  /// Rename sov
  Future<void> renameSov(BuildContext context, String accountId, String subAccountId, String sovId, String newName) async {
    try {
      isRenameLoading = true;

      ApiService apiService = ApiService(AppConstant.RENAME_SUB_ACCOUNT+"/$accountId/subaccount/$subAccountId/sov");  // Updated URL
      var response = await apiService.patch({'data': {
        'sov_id': sovId,  // Updated field
        'name': newName,  // Updated field
      }});
      log(response.toString());

      // Update account name in the list
      int index = sovList.indexWhere((element) => element.accountId == accountId);
      if (index != -1) {
        sovList[index].name = newName;
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

  /// Duplicate sov
  Future<void> duplicateSubAccount(BuildContext context, String accountId, String subAccountId, String sovId) async {
    try {
      isDuplicateLoading = true;

      ApiService apiService = ApiService(AppConstant.DUPLICATE_SUB_ACCOUNT+"/$accountId/subaccount/$subAccountId/sov");
      var response = await apiService.post({'data': {
        'sov_id': sovId,
        'duplicate': true,
      }});
      log(response.toString());

      // Parse the response to get the duplicated SOV account
      SovAccount duplicatedSovAccount = SovAccount.fromJson(response['updated_record']);

      // Prepend the duplicated SOV account to the beginning of the list
      sovList = [duplicatedSovAccount, ...sovList];

      isDuplicateLoading = false;
    } on BackendException catch (e) {
      isDuplicateLoading = false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message, style: CustomTypography.Body1),
      ));
    } catch (e) {
      isDuplicateLoading = false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString(), style: CustomTypography.Body1),
      ));
    }
  }


  /// Change column visibility
  Future<bool> changeColumnVisibility(BuildContext context, String accountId, String subAccountId, {required bool showLocationCount, required bool showOverallScore, required String type}) async {
    try {
    if (type == 'location_count') {
        showLocationCountLoading = true;
      } else if (type == 'over_all_score') {
        showOverallScoreLoading = true;
      }

      ApiService apiService = ApiService(AppConstant.CHANGE_COLUMN_VISIBILITY_SUB_ACCOUNT+"/$accountId/subaccount/$subAccountId/sov");  // Updated URL

      var response = await apiService.patch({'data': {
        'table_setting': true,
        'location_count': showLocationCount,
        'over_all_score': showOverallScore,
      }});
      log(response.toString());
      showLocationCountLoading = false;
      showOverallScoreLoading = false;
      return true;
    } on BackendException catch (e) {
      showLocationCountLoading = false;
      showOverallScoreLoading = false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message, style: CustomTypography.Body1,),
      ));
      return false;
    } catch (e) {
      showLocationCountLoading = false;
      showOverallScoreLoading = false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString(), style: CustomTypography.Body1,),
      ));
      return false;
    }
  }

  /// Fetch autocomplete sov list
  Future<void> fetchAutoCompleteSubAccountList(BuildContext context, String searchQuery) async {
    try {
      isAutoCompleteLoading = true;

      print("Fetching autocomplete list for query: $searchQuery");
      ApiService apiService = ApiService(AppConstant.GET_SUB_ACCOUNT_LIST);
      String url = '?sub_account_name=$searchQuery';  // Updated field
      var response = await apiService.get(url);
      log(response.toString());

      SovListModel accountListModel = SovListModel.fromJson(response);

      autoCompleteSovList = accountListModel.results ?? [];
      log(autoCompleteSovList.toString());
      print("Updated autoCompleteAccountList: $autoCompleteSovList");
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

  /// Add sov
  Future<void> addSubAccount(BuildContext context, String accountId, String subAccountId, String accountName) async {
    try {
      isAddAccountLoading = true;

      ApiService apiService = ApiService(AppConstant.ADD_SUB_ACCOUNT+"/$accountId/subaccount/$subAccountId/sov");
      var response = await apiService.post({'data': {
        'sub_account_name': accountName,
      }});
      log(response.toString());

      // Parse the response to get the newly added SOV account
      SovAccount newSovAccount = SovAccount.fromJson(response['updated_record']);

      // Prepend the new SOV account to the beginning of the list
      sovList = [newSovAccount, ...sovList];

      isAddAccountLoading = false;
    } on BackendException catch (e) {
      isAddAccountLoading = false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message, style: CustomTypography.Body1),
      ));
    } catch (e) {
      isAddAccountLoading = false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString(), style: CustomTypography.Body1),
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

  Future<void> exportData(BuildContext context, String accountId, String subAccountId, Map<String, dynamic> exportData) async {
    try {
      _isExportLoading = true;
      notifyListeners();

      print('Starting export data process...');
      print('Account ID: $accountId');
      print('SubAccount ID: $subAccountId');
      print('Export Data: $exportData');

      final URL = '${AppConstant.GET_SOV_LIST}/$accountId/subaccount/$subAccountId/sov/download';
      print('Request URL: $URL');

      final dio = Dio();
      dio.options.headers = await CommonHeaders.createDownloadHeaders();

      log('Headers: ${dio.options.headers}');
      dio.interceptors.add(InterceptorsWrapper(
          onRequest: (options, handler) {
            print('REQUEST[${options.method}] => PATH: ${options.path}');
            return handler.next(options);
          },
          onResponse: (response, handler) {
            print('RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
            return handler.next(response);
          },
          onError: (DioError e, handler) {
            print('ERROR[${e.response?.statusCode}] => PATH: ${e.requestOptions.path}');
            return handler.next(e);
          }
      ));

      // Log the payload
      print('Request Payload: ${json.encode(exportData)}');

      final response = await dio.post(
        URL,
        data: {"data": exportData},
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: false,
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      print('Response received.');
      print('Response headers: ${response.headers}');

      if (response.statusCode != 200) {
        print('Error: received status code ${response.statusCode}');
        print('Response data: ${utf8.decode(response.data)}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error during export data process: ${response.statusCode}')),
        );
        return;
      }

      final contentDisposition = response.headers.value('content-disposition');
      var filename = 'downloaded_file.docx';
      if (contentDisposition != null) {
        final filenameMatch = RegExp(r'filename="([^"]+)"').firstMatch(contentDisposition);
        if (filenameMatch != null) {
          filename = filenameMatch.group(1)!;
        }
      }

      print('Filename extracted: $filename');

      final bytes = response.data;
      print('Bytes received: ${bytes.length}');

      final tempDir = await getTemporaryDirectory();
      print('Temporary directory path: ${tempDir.path}');

      final filePath = path.join(tempDir.path, filename);
      print('File path: $filePath');

      final file = File(filePath);
      await file.writeAsBytes(bytes);
      print('File written to disk.');

      await OpenFile.open(filePath);
      print('File opened.');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$filePath ${LanguageService.getTranslated(context, "export_sov_modal_success_message")}')),
      );
    } catch (e) {
      if (e is DioException) {
        print('Dio error!');
        print('STATUS: ${e.response?.statusCode}');
        print('DATA: ${e.response?.data}');
        print('HEADERS: ${e.response?.headers}');
      } else {
        print('Error: $e');
      }
      print('Error during export data process: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LanguageService.getTranslated(context, "export_sov_modal_failure_message"))),
      );
    } finally {
      _isExportLoading = false;
      notifyListeners();
      print('Export data process completed.');
    }
  }


  /// Transfer sov
  Future<void> transferSOV(BuildContext context, String accountId, String? subAccountId, String? sovId, String newOwnerId) async {
    try {
      isTransferLoading = true;

      ApiService apiService = ApiService(AppConstant.GET_ACCOUNT_LIST+"/$accountId/subaccount/$subAccountId/sov");
      var response = await apiService.post({
        'data': {
          'new_owner': newOwnerId,
          'account_id': accountId,
          'sub_account_id': subAccountId,
          'sov_id': sovId,
        },
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(response['message'] ?? 'Sov transferred successfully'),
      ));

      // Update the account list UI
      int index = sovList.indexWhere((element) => element.subAccountId == subAccountId);
      if (index != -1) {
        sovList[index].disabled = true;
      }

      isTransferLoading = false;
    } catch (e) {
      isTransferLoading = false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to transfer sov: ${e.toString()}'),
      ));
    }
  }

}
