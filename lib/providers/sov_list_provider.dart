import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:RiskSphere/design_system/primitives/custom_typography.dart';
import 'package:RiskSphere/models/sov_list_model.dart';
import 'package:RiskSphere/service/api_service.dart';
import 'package:RiskSphere/utils/api_constants.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../models/transfer_autocomplete_model.dart';
import '../service/firestore_service.dart';
import '../service/language_service.dart';
import '../utils/common_headers.dart';

SovListModel parseSovList(Map<String, dynamic> json) {
  return SovListModel.fromJson(json);
}

SovListModel parseMonitoringSovList(Map<String, dynamic> json) {
  return SovListModel(
    events: json['events'] != null
        ? List<SovItem>.from(
            (json['events'] as List).map((x) => SovItem.fromJson(x)))
        : [],
  );
}

UserListModel parseUserList(Map<String, dynamic> jsonData) {
  return UserListModel.fromJson(jsonData);
}

class SOVListProvider extends ChangeNotifier {
  List<SovItem> monitoringSovList = [];
  List<SovItem> monitoringFilterList = [];

  bool _isLoading = false;
  bool isRequestSent = false;
  final Set<String> requestedUserIds = {};

  bool isConnectRequestLoading = false;

  bool get isLoading => _isLoading;

  set isLoading(bool value) {
    _isLoading = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  Map<String, dynamic>? companyCredits;
  bool isCreditsLoading = false;

  Map<String, Map<String, dynamic>?> sovMeta = {};

  final Map<String, StreamSubscription<DocumentSnapshot>> _sovListeners = {};

  void listenToSovMeta(String sovId) {
    if (_sovListeners.containsKey(sovId)) return;
    final firestore = FirestoreService.db;
    final sub = firestore
        .collection("location_recommendations")
        .doc(sovId)
        .snapshots()
        .listen((snap) {
      if (snap.exists) {
        sovMeta[sovId] = snap.data();
      } else {
        sovMeta[sovId] = null;
      }

      notifyListeners();
    });

    _sovListeners[sovId] = sub;
  }

  void clearSovList() {
    sovList.clear();
    notifyListeners();
  }
  bool _showCheckbox = false;

  bool get showCheckbox => _showCheckbox;

  set showCheckbox(bool value) {
    _showCheckbox = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  bool _isNextPageLoading = false;

  bool get isNextPageLoading => _isNextPageLoading;

  set isNextPageLoading(bool value) {
    _isNextPageLoading = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  bool _isRenameLoading = false;

  bool get isRenameLoading => _isRenameLoading;

  set isRenameLoading(bool value) {
    _isRenameLoading = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  bool _isDuplicateLoading = false;

  bool get isDuplicateLoading => _isDuplicateLoading;

  set isDuplicateLoading(bool value) {
    _isDuplicateLoading = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  bool _showLocationCountLoading = false;

  bool get showLocationCountLoading => _showLocationCountLoading;

  set showLocationCountLoading(bool value) {
    _showLocationCountLoading = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  bool _showOverallScoreLoading = false;

  bool get showOverallScoreLoading => _showOverallScoreLoading;

  set showOverallScoreLoading(bool value) {
    _showOverallScoreLoading = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  List<UserResult> allUserList = [];
  List<UserResult> filteredUserList = [];

  String selectedUserType = "All";
  String selectedRole = "All";
  String selectedStatus = "All";

  List<String> userTypes = ["All"];
  List<String> roles = ["All"];
  List<String> statusList = ["All", "Verified", "Pending"];

  List<String> extractUserTypes(List<UserResult> users) {
    final types = <String>{};
    for (var user in users) {
      if (user.userType != null && user.userType!.isNotEmpty) {
        types.add(user.userType!);
      }
    }
    return types.toList();
  }

  List<String> extractRoles(List<UserResult> users) {
    final roles = <String>{};
    for (var user in users) {
      if (user.roles != null) {
        for (var role in user.roles!) {
          if (role.isNotEmpty) {
            roles.add(role);
          }
        }
      }
    }
    return roles.toList();
  }

  void applyFilters() {
    filteredUserList = allUserList.where((user) {
      // Filter by user type
      if (selectedUserType != "All") {
        if (user.userType?.toLowerCase() != selectedUserType.toLowerCase()) {
          return false;
        }
      }

      if (selectedRole != "All") {
        final hasRole = user.roles?.any(
              (role) => role.toLowerCase() == selectedRole.toLowerCase(),
            ) ??
            false;
        if (!hasRole) {
          return false;
        }
      }

      if (selectedStatus != "All") {
        final shouldBeVerified = selectedStatus == "Verified";
        if (user.isVerified != shouldBeVerified) {
          return false;
        }
      }

      return true;
    }).toList();

    notifyListeners();
  }

  bool _isAddAccountLoading = false;

  bool get isAddAccountLoading => _isAddAccountLoading;

  set isAddAccountLoading(bool value) {
    _isAddAccountLoading = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  bool _isAutoCompleteLoading = false;

  bool get isAutoCompleteLoading => _isAutoCompleteLoading;

  set isAutoCompleteLoading(bool value) {
    _isAutoCompleteLoading = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  bool _isExportLoading = false;

  bool get isExportLoading => _isExportLoading;

  set isExportLoading(bool value) {
    _isExportLoading = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  bool _isTransferLoading = false;

  bool get isTransferLoading => _isTransferLoading;

  set isTransferLoading(bool value) {
    _isTransferLoading = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // columns
  bool _showLocationCount = true;

  bool get showLocationCount => _showLocationCount;

  set showLocationCount(bool value) {
    _showLocationCount = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  bool _showOverallScore = true;

  bool get showOverallScore => _showOverallScore;

  set showOverallScore(bool value) {
    _showOverallScore = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  int _page = 0;

  int get page => _page;

  set page(int value) {
    _page = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  int _totalPages = 1;

  int get totalPages => _totalPages;

  set totalPages(int value) {
    _totalPages = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  int _totalEvent = 0;

  int get totalEvent => _totalEvent;

  set totalEvent(int value) {
    _totalEvent = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  int _totalImpactLocation = 0;

  int get totalImpactLocation => _totalImpactLocation;

  set totalImpactLocation(int value) {
    _totalImpactLocation = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  int _hurricaneMonitoringLocations = 0;

  int get hurricaneMonitoringLocations => _hurricaneMonitoringLocations;

  set hurricaneMonitoringLocations(int value) {
    _hurricaneMonitoringLocations = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  int _earthquakeMonitoringLocations = 0;

  int get earthquakeMonitoringLocations => _earthquakeMonitoringLocations;

  set earthquakeMonitoringLocations(int value) {
    _earthquakeMonitoringLocations = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  List<Result> _sovList = [];

  List<Result> get sovList => _sovList;

  set sovList(List<Result> value) {
    _sovList = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  TotalCountHeader _sovCounterList = TotalCountHeader();

  TotalCountHeader get sovCounterList => _sovCounterList;

  set sovCounterList(TotalCountHeader value) {
    _sovCounterList = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void addToSovList(List<Result> newAccounts) {
    _sovList.addAll(newAccounts);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  List<Result> _autoCompleteSovList = [];

  List<Result> get autoCompleteSovList => _autoCompleteSovList;

  set autoCompleteSovList(List<Result> value) {
    _autoCompleteSovList = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  List<Results> _autoCompleteSovList1 = [];

  List<Results> get autoCompleteSovList1 => _autoCompleteSovList1;

  set autoCompleteSovList1(List<Results> value) {
    _autoCompleteSovList1 = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void clearAutoCompleteList() {
    autoCompleteSovList = [];
  }

  int sovHits = 0;

  List<Result> filteredAutoCompleteList = [];
  List<Results> filteredAutoCompleteList1 = [];
  List<Results> filteredAutoCompleteList2 = [];
  List<Result> filtersovlist = [];
  Filters? filterlist;
  Cards? cardlist;

  Future<List<TransferAutocompleteModel>> fetchcompanySearchList(
      String searchQuery) async {
    try {
      ApiService apiService = ApiService(AppConstant.GET_SEARCH_LIST_BY_SOV);
      String url = '';
      if (searchQuery.isNotEmpty) {
        url += '&user_search=$searchQuery';
      }

      var response = await apiService.get(url);
      SovListModel sovListModel = SovListModel.fromJson(response);
      log(response.toString());

      final List<dynamic> items = (response['result'] as List?) ?? [];
      return items
          .map((e) =>
              TransferAutocompleteModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, stack) {
      print("Error fetching company search list: $e");
      print(stack);
      return [];
    }
  }

  Future<void> fetchSovList1(
    BuildContext context,
    String searchQuery,
    int page,
    int pageSize,
    String? type,
  ) async {
    try {
      if (isLoading || isNextPageLoading) return;

      if (page == 1) {
        isLoading = true;
        filtersovlist = [];
        notifyListeners();
      } else {
        isNextPageLoading = true;
        notifyListeners();
      }

      ApiService apiService = ApiService(AppConstant.GET_SOV_LIST_BY_SOV);

      String url = '?page=$page&pageSize=$pageSize&type=$type';

      if (searchQuery.isNotEmpty) {
        url += '&search=$searchQuery';
      }

      var response = await apiService.get(url);

      SovListModel sovListModel = await compute(parseSovList, response);

      filtersovlist = sovListModel.result ?? [];
    } catch (e, stack) {
      print(e);
      print(stack);
    } finally {
      isLoading = false;
      isNextPageLoading = false;
      notifyListeners(); // VERY IMPORTANT
    }
  }

  /// Fetch sov list with pagination and search query

  Future<void> fetchSovList(
    BuildContext context,
    String searchQuery,
    int page,
    int pageSize,
    String? type,
  ) async {
    if (isLoading || isNextPageLoading) return;

    try {
      if (page == 1) {
        isLoading = true;
        filtersovlist = [];
      } else {
        isNextPageLoading = true;
      }

      notifyListeners();

      final apiService = ApiService(AppConstant.GET_SOV_LIST_BY_SOV);

      String url = '?page=$page&pageSize=$pageSize&type=$type';
      if (searchQuery.isNotEmpty) {
        url += '&search=$searchQuery';
      }

      final response = await apiService.get(url);

      final SovListModel sovListModel = await compute(parseSovList, response);

      filtersovlist = sovListModel.result ?? [];
      showLocationCount = sovListModel.settings?.locationCount ?? true;
      showOverallScore = sovListModel.settings?.overAllScore ?? true;

      sovHits = sovListModel.totalRecords ?? 0;
      totalPages = (sovHits / pageSize).ceil();
      sovCounterList = sovListModel.totalCountHeader!;

      if (page == 1) {
        sovList = sovListModel.result ?? [];
      } else {
        addToSovList(sovListModel.result ?? []);
      }

      for (var item in sovList) {
        if (item.sovId != null) {
          listenToSovMeta(item.sovId!);
        }
      }
    } catch (e, stack) {
      debugPrint(' fetchSovList error: $e');
      debugPrint('$stack');
    } finally {
      isLoading = false;
      isNextPageLoading = false;
      notifyListeners();
    }
  }

  List<Result> allVendorList = [];
  List<UserResult> allVendorList1 = [];
  List<UserResult> filteredAutoCompleteList12 = [];

  Future<void> fetchMonitoringSovList(
    BuildContext context,
    String searchQuery,
    int page,
    int pageSize,
    String? type,
    String? monitoringID,
  ) async {
    if (isLoading || isNextPageLoading) return;

    try {
      if (page == 1) {
        isLoading = true;
      } else {
        isNextPageLoading = true;
      }

      notifyListeners();

      final apiService = ApiService(AppConstant.GET_EVENET_SOV_LIST_BY_SOV);

      String url = "/$monitoringID?page=$page&pageSize=$pageSize";

      if (searchQuery.isNotEmpty) {
        url += '&search=$searchQuery';
      }

      final response = await apiService.get(url);

      debugPrint("RAW RESPONSE: $response");

      final SovListModel model = SovListModel.fromJson(response);

      final List<SovItem> newList = model.events ?? [];

      debugPrint("PARSED EVENTS COUNT: ${newList.length}");
      /// SAFE AGGREGATION COUNTS PARSING
      if (model.aggregationCounts != null) {
        // Convert to int safely
        totalEvent = _safeIntParse(model.aggregationCounts!.totalNoOfEvents);
        totalImpactLocation =
            _safeIntParse(model.aggregationCounts!.totalImpactedLocations);
        hurricaneMonitoringLocations = _safeIntParse(
            model.aggregationCounts!.hurricaneMonitoringLocations);
        earthquakeMonitoringLocations = _safeIntParse(
            model.aggregationCounts!.earthquakeMonitoringLocations);

        debugPrint(
            "Total Events: $totalEvent | Total Impact Locations: $totalImpactLocation");
      } else {
        debugPrint("⚠ aggregationCounts is null - setting defaults");
        totalEvent = 0;
        totalImpactLocation = 0;
      }

      if (page == 1) {
        monitoringSovList = newList;
      } else {
        final existingIds = monitoringSovList.map((e) => e.id).toSet();
        final uniqueList =
            newList.where((e) => !existingIds.contains(e.id)).toList();
        monitoringSovList.addAll(uniqueList);
      }

      /// sync filtered list
      monitoringFilterList = List.from(monitoringSovList);

      /// pagination
      if (newList.length < pageSize) {
        totalPages = page;
      } else {
        totalPages = page + 1;
      }

      /// meta listener
      for (var item in newList) {
        if (item.id != null) {
          listenToSovMeta(item.id!);
        }
      }

      debugPrint(
          "Page: $page | New: ${newList.length} | Total: ${monitoringSovList.length}");
    } catch (e, stack) {
      debugPrint('❌ fetchMonitoringSovList error: $e');
      debugPrint('❌ Stack: $stack');
    } finally {
      isLoading = false;
      isNextPageLoading = false;
      notifyListeners();
    }
  }

  int _safeIntParse(dynamic value) {
    if (value == null) return 0;

    if (value is int) return value;
    if (value is double) return value.toInt();

    if (value is String) {
      return int.tryParse(value) ?? 0;
    }

    return 0;
  }

  Future<void> fetchvendorList(
    BuildContext context,
    String query,
    int page,
    int pageSize,
    String? type,
  ) async {
    if (isLoading || isNextPageLoading) return;

    try {
      if (page == 1) {
        isLoading = true;
        allVendorList.clear();
        filteredAutoCompleteList1.clear();
      } else {
        isNextPageLoading = true;
      }

      notifyListeners();

      final apiService = ApiService(
        type != "corporate"
            ? AppConstant.GET_CORPORATE_DASHBOARD
            : AppConstant.GET_VENDOR_HAZARD,
      );

      final response = await apiService.get(query);

      final SovListModel sovListModel = await compute(parseSovList, response);

      /// Metadata
      filterlist = sovListModel.filters;
      cardlist = sovListModel.cards;

      final List<Result> results = sovListModel.result ?? [];

      allVendorList.addAll(results);

      filteredAutoCompleteList1 = sovListModel.results ?? [];
      // filteredAutoCompleteList1 = results;
      // filteredAutoCompleteList2 = List.from(allVendorList);

      /// Pagination tracking
      this.page = page;
      // totalPages = sovListModel.totalPages ?? totalPages;

      /// Listen to meta updates
      for (final item in results) {
        if (item.sovId != null) {
          listenToSovMeta(item.sovId!);
        }
      }
    } catch (e, stack) {
      debugPrint('fetchvendorList error: $e');
      debugPrint('$stack');
    } finally {
      isLoading = false;
      isNextPageLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchCompanyCredits(
    BuildContext context,
    String companyId,
  ) async {
    if (isCreditsLoading) return;

    if (companyId.isEmpty) {
      debugPrint(" companyId is empty");
      return;
    }

    try {
      isCreditsLoading = true;
      notifyListeners();

      final apiService = ApiService("${AppConstant.GET_COMPANY_ID}$companyId");

      final response = await apiService.get("");

      final data = jsonEncode(response);
      companyCredits = data as Map<String, dynamic>?;

      debugPrint(" Company Credits Loaded");
    } catch (e, stackTrace) {
      debugPrint("fetchCompanyCredits Error: $e");
      debugPrint("$stackTrace");

      if (context.mounted) {
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(content: Text("Error loading credits")),
        // );
      }
    } finally {
      isCreditsLoading = false;
      notifyListeners();
    }
  }

  bool hasMoreData = true;

  Future<void> fetchUserList(
    BuildContext context,
    String query,
    int page,
    int pageSize,
    String? type,
  ) async {
    if (isLoading || isNextPageLoading || !hasMoreData) return;

    try {
      if (page == 1) {
        isLoading = true;
        hasMoreData = true; // reset
        allUserList.clear();
        filteredUserList.clear();
      } else {
        isNextPageLoading = true;
      }

      notifyListeners();

      final apiService = ApiService(AppConstant.Fetch_USER_LIST);

      final queryParams = {
        "search": query,
        "page": page.toString(),
        "pageSize": pageSize.toString(),
        if (selectedUserType != "All") "user_type": selectedUserType,
        if (selectedRole != "All") "role": selectedRole,
        if (selectedStatus != "All")
          "is_verified": selectedStatus == "Verified" ? "true" : "false",
      };

      final queryString = Uri(queryParameters: queryParams).query;

      final response = await apiService.get("?$queryString");

      final UserListModel userListModel =
          await compute(parseUserList, response);

      final List<UserResult> results = userListModel.result ?? [];

      if (results.isEmpty) {
        hasMoreData = false;
        return;
      }

      if (page == 1) {
        allUserList = results;
      } else {
        allUserList.addAll(results);
      }

      userTypes = ["All", ...extractUserTypes(allUserList)];
      roles = ["All", ...extractRoles(allUserList)];

      applyFilters();

      this.page = page;

      debugPrint(' Loaded ${results.length} users | Page: $page');
    } catch (e, stackTrace) {
      debugPrint(' fetchUserList Error: $e');
      debugPrint('$stackTrace');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading users')),
        );
      }
    } finally {
      isLoading = false;
      isNextPageLoading = false;
      notifyListeners();
    }
  }

  void clearVendorList() {
    allVendorList.clear();
    filteredAutoCompleteList1.clear();
  }

  /// Rename sov
  Future<void> renameSov(BuildContext context, String accountId,
      String subAccountId, String sovId, String newName) async {
    var typography = CustomTypography(context);
    try {
      isRenameLoading = true;

      ApiService apiService = ApiService(AppConstant.RENAME_SUB_ACCOUNT +
          "/$accountId/subaccount/$subAccountId/sov");
      var response = await apiService.patch({
        'data': {
          'sov_id': sovId,
          "rename_sov": true,
          'name': newName,
        }
      });
      log(response.toString());

      int index = sovList.indexWhere((element) => element.sovId == sovId);
      if (index != -1) {
        sovList[index].name = newName;
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

  /// Duplicate SOV
  Future<bool> duplicateSov(BuildContext context, String sovId) async {
    var typography = CustomTypography(context);

    if (isDuplicateLoading) return false;

    try {
      isDuplicateLoading = true;
      notifyListeners();

      ApiService apiService = ApiService(
        "${AppConstant.DUPLICATE_SUB_ACCOUNT}/undefined/subaccount/undefined/sov",
      );

      final response = await apiService.post({
        'data': {
          'sov_id': sovId,
          'duplicate': true,
        }
      });

      log(response.toString());

      final Result duplicatedSovAccount =
          Result.fromJson(response['updated_record']);

      sovList = [duplicatedSovAccount, ...sovList];

      isDuplicateLoading = false;
      notifyListeners();

      return true;
    } on BackendException catch (e) {
      isDuplicateLoading = false;
      notifyListeners();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message, style: typography.Body1)),
      );
      return false;
    } catch (e, stack) {
      log(e.toString());
      log(stack.toString());

      isDuplicateLoading = false;
      notifyListeners();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString(), style: typography.Body1)),
      );
      return false;
    }
  }

  Future<bool> changeColumnVisibility(
      BuildContext context, String accountId, String subAccountId,
      {required bool showLocationCount,
      required bool showOverallScore,
      required String type}) async {
    var typography = CustomTypography(context);
    try {
      if (type == 'location_count') {
        showLocationCountLoading = true;
      } else if (type == 'over_all_score') {
        showOverallScoreLoading = true;
      }

      ApiService apiService = ApiService(
          AppConstant.CHANGE_COLUMN_VISIBILITY_SUB_ACCOUNT +
              "/$accountId/subaccount/$subAccountId/sov"); // Updated URL

      var response = await apiService.patch({
        'data': {
          'table_setting': true,
          'location_count': showLocationCount,
          'over_all_score': showOverallScore,
        }
      });
      log(response.toString());
      showLocationCountLoading = false;
      showOverallScoreLoading = false;
      return true;
    } on BackendException catch (e) {
      showLocationCountLoading = false;
      showOverallScoreLoading = false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          e.message,
          style: typography.Body1,
        ),
      ));
      return false;
    } catch (e) {
      showLocationCountLoading = false;
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

  /// Fetch autocomplete sov list
  Future<void> fetchAutoCompleteSovList(
      BuildContext context, String searchQuery) async {
    var typography = CustomTypography(context);
    try {
      isAutoCompleteLoading = true;

      print("Fetching autocomplete list for query: $searchQuery");
      ApiService apiService = ApiService(AppConstant.GET_AUTOCOMPLETE_SOV_LIST);
      String url = '?sub_account_name=$searchQuery';
      var response = await apiService.get(url);
      log(response.toString());

      SovListModel accountListModel = SovListModel.fromJson(response);

      autoCompleteSovList = accountListModel.result ?? [];
      log(autoCompleteSovList.toString());
      print("Updated autoCompleteAccountList: $autoCompleteSovList");
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
    } finally {
      isAutoCompleteLoading = false;
    }
  }

  Future<void> fetchAutoCompleteSovListLocations(
    BuildContext context,
    String accountId,
    String subAccountId, {
    String searchQuery = "",
  }) async {
    var typography = CustomTypography(context);


    try {
      isAutoCompleteLoading = true;
      notifyListeners();

      ApiService apiService = ApiService(AppConstant.GET_AUTOCOMPLETE_SOV_LIST);

      String url =
          '?account_id=$accountId&sub_account_id=$subAccountId&show_full_list=true';

      if (searchQuery.trim().isNotEmpty) {
        url += '&search_query=${Uri.encodeComponent(searchQuery.trim())}';
      }

      var response = await apiService.get(url);

      SovListModel accountListModel = SovListModel.fromJson(response);

      autoCompleteSovList1 = accountListModel.results ?? [];

      // Apply filtering
      if (searchQuery.trim().isNotEmpty) {
        final query = searchQuery.toLowerCase().trim();
        filteredAutoCompleteList1 = autoCompleteSovList1.where((sov) {
          final name = sov.name?.toLowerCase() ?? '';
          return name.contains(query);
        }).toList();
      } else {
        filteredAutoCompleteList1 = List.from(autoCompleteSovList1);
      }
    } on BackendException catch (e) {
      print("BackendException: ${e.message}");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message, style: typography.Body1)),
        );
      }
    } catch (e) {
      print("Error: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text("Failed to load SOV list", style: typography.Body1)),
        );
      }
    } finally {
      isAutoCompleteLoading = false;
      notifyListeners();
    }
  }

// Add this method for client-side filtering of already loaded data
  void updateFilteredList(String query) {
    if (query.isEmpty) {
      // If query is empty, show all items
      filteredAutoCompleteList = List.from(autoCompleteSovList);
    } else {
      // Filter based on query
      final queryLower = query.toLowerCase();
      filteredAutoCompleteList = autoCompleteSovList.where((sov) {
        final name = sov.name?.toLowerCase() ?? '';
        // final description = sov.description?.toLowerCase() ?? '';

        return name.contains(queryLower);
      }).toList();
    }
    notifyListeners();
  }

  /// Add sov
  Future<void> addSubAccount(BuildContext context, String accountId,
      String subAccountId, String accountName) async {
    var typography = CustomTypography(context);
    try {
      isAddAccountLoading = true;

      ApiService apiService = ApiService(AppConstant.ADD_SUB_ACCOUNT +
          "/$accountId/subaccount/$subAccountId/sov");
      var response = await apiService.post({
        'data': {
          'sub_account_name': accountName,
        }
      });
      log(response.toString());

      // Parse the response to get the newly added SOV account
      Result newSovAccount = Result.fromJson(response['updated_record']);

      // Prepend the new SOV account to the beginning of the list
      sovList = [newSovAccount, ...sovList];

      isAddAccountLoading = false;
    } on BackendException catch (e) {
      isAddAccountLoading = false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message, style: typography.Body1),
      ));
    } catch (e) {
      isAddAccountLoading = false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString(), style: typography.Body1),
      ));
    }
  }

  // Request access with message
  Future<void> requestAccess(
      BuildContext context, String accountId, String message) async {
    var typography = CustomTypography(context);
    try {
      ApiService apiService = ApiService(AppConstant.REQUEST_ACCESS);
      var response = await apiService.post({
        'data': {
          'account_id': accountId,
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

  Future<void> exportData1(
      BuildContext context,
      String accountId,
      String subAccountId,
      List<Map<String, dynamic>> exportData,
      List<String> sovIds) async {
    try {
      _isExportLoading = true;
      notifyListeners();

      final URL = "${AppConstant.EXPORT_SOV}";
      print('Request URL: $URL');

      final dio = Dio();
      dio.options.headers = await CommonHeaders.createDownloadHeaders();

      log('Headers: ${dio.options.headers}');
      dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
        print('REQUEST[${options.method}] => PATH: ${options.path}');
        return handler.next(options);
      }, onResponse: (response, handler) {
        print(
            'RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
        return handler.next(response);
      }, onError: (DioException e, handler) {
        print(
            'ERROR[${e.response?.statusCode}] => PATH: ${e.requestOptions.path}');
        return handler.next(e);
      }));

      final payload = {
        "fileType": "profile", // or "table" based on your needs
        "format": "excel", // matches your format dropdown
        "includeImage": false, // or true based on your requirements
        "sov_ids": sovIds // CORRECTED: Use the SOV IDs directly
      };

      print('Request Payload: ${json.encode(payload)}');

      final response = await dio.post(
        URL,
        data: payload,
        // CORRECTED: Send the proper payload, not wrapped in "data"
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
          SnackBar(
              content: Text(
                  'Error during export data process: ${response.statusCode}')),
        );
        return;
      }

      final contentDisposition = response.headers.value('content-disposition');
      var filename = 'exported_locations.xlsx';
      if (contentDisposition != null) {
        final filenameMatch =
            RegExp(r'filename="([^"]+)"').firstMatch(contentDisposition);
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
        SnackBar(
            content: Text(
                '$filePath ${LanguageService.getTranslated(context, "export_sov_modal_success_message")}')),
      );
    } catch (e) {
      if (e is DioException) {
        print('STATUS: ${e.response?.statusCode}');
      } else {
        print('Error: $e');
      }
      print('Error during export data process: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(LanguageService.getTranslated(
                context, "export_sov_modal_failure_message"))),
      );
    } finally {
      _isExportLoading = false;
      notifyListeners();
      print('Export data process completed.');
      Navigator.pop(context);
    }
  }

  Future<void> exportData(
      BuildContext context,
      String accountId,
      String subAccountId,
      List<Map<String, dynamic>> exportData,
      String sovId) async {
    try {
      _isExportLoading = true;
      notifyListeners();

      print('Starting export data process...');
      print('Account ID: $accountId');
      print('SubAccount ID: $subAccountId');
      print('SOV ID: $sovId');
      print('Export Data: $exportData');

      final URL = '${AppConstant.EXPORT}/$accountId/$subAccountId/null';
      print('Request URL: $URL');

      final dio = Dio();
      dio.options.headers = await CommonHeaders.createDownloadHeaders();

      log('Headers: ${dio.options.headers}');
      dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
        print('REQUEST[${options.method}] => PATH: ${options.path}');
        return handler.next(options);
      }, onResponse: (response, handler) {
        print(
            'RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
        return handler.next(response);
      }, onError: (DioException e, handler) {
        print(
            'ERROR[${e.response?.statusCode}] => PATH: ${e.requestOptions.path}');
        return handler.next(e);
      }));

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
          SnackBar(
              content: Text(
                  'Error during export data process: ${response.statusCode}')),
        );
        return;
      }

      final contentDisposition = response.headers.value('content-disposition');
      var filename = 'downloaded_file.xlsx';
      if (contentDisposition != null) {
        final filenameMatch =
            RegExp(r'filename="([^"]+)"').firstMatch(contentDisposition);
        if (filenameMatch != null) {
          filename = filenameMatch.group(1)!;
        }
      }


      final bytes = response.data;

      final tempDir = await getTemporaryDirectory();

      final filePath = path.join(tempDir.path, filename);


      final file = File(filePath);
      await file.writeAsBytes(bytes);

      await OpenFile.open(filePath);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                '$filePath ${LanguageService.getTranslated(context, "export_sov_modal_success_message")}')),
      );
    } catch (e) {
      if (e is DioException) {
        print('Dio error!');
        print('STATUS: ${e.response?.statusCode}');

      } else {
        print('Error: $e');
      }
      print('Error during export data process: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(LanguageService.getTranslated(
                context, "export_sov_modal_failure_message"))),
      );
    } finally {
      _isExportLoading = false;
      notifyListeners();
      print('Export data process completed.');
      Navigator.pop(context);
    }
  }

  Future<void> exportDataSov(
    BuildContext context,
    String accountId,
    String subAccountId,
    Map<String, dynamic> exportPayload,
    String sovId,
  ) async {
    try {
      _isExportLoading = true;
      notifyListeners();

      print('Export Payload: ${jsonEncode(exportPayload)}');

      final URL = AppConstant.EXPORT_SOV;
      final dio = Dio();
      dio.options.headers = await CommonHeaders.createDownloadHeaders();

      final response = await dio.post(
        URL,
        data: exportPayload, // ✔ FIXED
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: false,
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error ${response.statusCode}')),
        );
        return;
      }

      final contentDisposition = response.headers.value('content-disposition');
      var filename = 'download.xlsx';
      if (contentDisposition != null) {
        final match =
            RegExp(r'filename="([^"]+)"').firstMatch(contentDisposition);
        if (match != null) filename = match.group(1)!;
      }

      final tempDir = await getTemporaryDirectory();
      final filePath = path.join(tempDir.path, filename);
      final file = File(filePath);
      await file.writeAsBytes(response.data);

      await OpenFile.open(filePath);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Export successful: $filePath")),
      );
    } catch (e) {
      print('Export error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Export failed")),
      );
    } finally {
      _isExportLoading = false;
      notifyListeners();
      Navigator.pop(context);
    }
  }

  /// Transfer sov
  Future<bool> transferSOV(BuildContext context, String accountId,
      String? subAccountId, String? sovId, String newOwnerId) async {
    try {
      isTransferLoading = true;

      ApiService apiService = ApiService(AppConstant.TRANSFER_SOV);
      var response = await apiService.post({
        'data': {
          'to_user_id': newOwnerId,
          'sov_id': sovId,
        },
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(response['message'] ?? 'Sov transferred successfully'),
      ));

      // Update the account list UI
      int index =
          sovList.indexWhere((element) => element.subAccountId == subAccountId);
      if (index != -1) {
        // sovList[index].disabled = true;
      }

      isTransferLoading = false;
      return true;
    } on BackendException catch (e) {
      isTransferLoading = false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message),
      ));
      return false;
    } catch (e) {
      isTransferLoading = false;
      print(e);
      return false;
    }
  }

  Future<bool> shareSov({
    required dynamic sovId,
    required List<Map<String, dynamic>> shareWithList,
  }) async {
    isLoading = true;
    notifyListeners();

    try {
      ApiService apiService = ApiService(AppConstant.SHARE_SOV_LIST);
      var payload = {
        "sov_id": sovId is Set ? sovId.toList() : sovId,
        "share_with": shareWithList.map((item) {
          return item.map((key, value) =>
              MapEntry(key, value is Set ? value.toList() : value));
        }).toList(),
      };

      var response = await apiService.post(payload);
      log("Share SOV Response: $response");

      return true;
    } catch (e) {
      print("Share SOV Error: $e");
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> sendConnectionRequest(
    BuildContext context, {
    required String userId,
    required String message,
  }) async {
    var typography = CustomTypography(context);

    if (isConnectRequestLoading) return false;

    try {
      isConnectRequestLoading = true;
      notifyListeners();

      print(" API CALL STARTED FOR USER: $userId");

      ApiService apiService = ApiService(
        AppConstant.sendConnectionRequest,
      );

      final response = await apiService.post({
        "data": {
          "action": "send_request",
          "user_id": userId,
          "message": message,
        }
      });
      requestedUserIds.add(userId);
      isConnectRequestLoading = false;
      notifyListeners();
      return true;
    } on BackendException catch (e) {
      isConnectRequestLoading = false;
      notifyListeners();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message, style: typography.Body1),
        ),
      );

      return false;
    } catch (e, stack) {
      debugPrint(" ERROR: $e");
      debugPrint(" STACK: $stack");

      isConnectRequestLoading = false;
      notifyListeners();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Something went wrong", style: typography.Body1),
        ),
      );

      return false;
    }
  }
}
