import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:RiskSphere/models/PricingModel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:RiskSphere/design_system/primitives/custom_typography.dart';
import 'package:RiskSphere/models/account_list_model.dart';
import 'package:RiskSphere/service/api_service.dart';
import 'package:RiskSphere/service/language_service.dart';
import 'package:RiskSphere/utils/api_constants.dart';

import '../design_system/components/custom_toast.dart';
import '../main.dart' hide CustomToast;
import '../utils/toast.dart';

class AccountListProvider extends ChangeNotifier {
  /// Firestore listeners per location
  final Map<String, StreamSubscription<DocumentSnapshot>> _sovListeners = {};
  final Map<String, Map<String, dynamic>?> sovMeta = {};
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  AccountListModel? accountListModel;
  StreamSubscription<DocumentSnapshot>? _locRecSub;
  String? _listeningSovId;
  final Map<String, StreamSubscription<DocumentSnapshot>> _sovMetaListeners =
      {};
  final Map<String, StreamSubscription<DocumentSnapshot>> _locationListeners =
      {};
  final Set<String> _blockedLocationIds = {};

  Set<String> get blockedLocationIds {
    final list = locRecMetaData?['blocked_locations'];
    if (list is List) {
      return list.map((e) => e.toString()).toSet();
    }
    return {};
  }

  void markHazardUnlocked(List<String> locationIds) {
    for (final item in missingParameterList) {
      if (locationIds.contains(item.locationId)) {
        item.hasVendorHazards = true;
      }
    }
    notifyListeners();
  }

  void listenToSovMeta(String sovId) {
    if (_sovMetaListeners.containsKey(sovId)) return;

    final sub = FirebaseFirestore.instance
        .collection("location_recommendations")
        .doc(sovId)
        .snapshots()
        .listen((snap) {
      if (snap.exists) {
        sovMeta[sovId] = snap.data();
      } else {
        sovMeta[sovId] = null;
      }
      notifyListeners(); // updates only dependent UI
    });

    _sovMetaListeners[sovId] = sub;
  }

  Map<String, dynamic>? locRecMetaData;

  bool get isRefreshPending => locRecMetaData?['refresh_pending'] == true;
  bool isLoading = false;
  bool isNextPageLoading = false;
  int page = 1;
  bool isUpdating = false;

  /// Tracks update-in-progress per locationId
  final Map<String, bool> _isLocationUpdating = {};

  bool isLocationUpdating(String locationId) =>
      _isLocationUpdating[locationId] == true;

  String? updatingItemId;

  bool isUpdatingItem(String id) => updatingItemId == id;

  // void startUpdating() {
  //   isUpdating = true;
  //   notifyListeners();
  // }
  void startUpdating(String locationId) {
    _blockedLocationIds.add(locationId);
    notifyListeners();
  }

  void stopUpdating(String locationId) {
    _blockedLocationIds.remove(locationId);
    notifyListeners();
  }

  // void startUpdating(String locationId) {
  //   blockedLocationIds.add(locationId);
  //   notifyListeners();
  // }
  //
  // void stopUpdating(String locationId) {
  //   blockedLocationIds.remove(locationId);
  //   notifyListeners();
  // }

  // void stopUpdating() {
  //   isUpdating = false;
  //   notifyListeners();
  // }

  bool hasLoadedOnce = false;
  String lastQuery = "";
  bool _isNextPageLoading = false;

  bool forceReload = false;
  String lastSearchQuery = "";

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
    notifyListeners(); // This ensures the UI updates
  }

  bool _isDeleteLocationLoading = false;

  bool get isDeleteLocationLoading => _isDeleteLocationLoading;

  set isDeleteLocationLoading(bool value) {
    _isDeleteLocationLoading = value;
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      notifyListeners();
    });
  }

  bool _isOwnerLoading = false;

  bool get isOwnerLoading => _isOwnerLoading;

  set isOwnerLoading(bool value) {
    _isOwnerLoading = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  bool _showSOVCountLoading = false;

  bool get showSOVCountLoading => _showSOVCountLoading;

  set showSOVCountLoading(bool value) {
    _showSOVCountLoading = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  bool _showSubAccountCountLoading = false;

  bool get showSubAccountCountLoading => _showSubAccountCountLoading;

  set showSubAccountCountLoading(bool value) {
    _showSubAccountCountLoading = value;
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

  bool _isImageUploadLoading = false;

  bool get isImageUploadLoading => _isImageUploadLoading;

  set isImageUploadLoading(bool value) {
    _isImageUploadLoading = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  Set<String> _previousBlockedLocationIds = {};

  bool _isTransferLoading = false;

  bool get isTransferLoading => _isTransferLoading;

  set isTransferLoading(bool value) {
    _isTransferLoading = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  //
  // void listenToLocationRecommendations(String? sovId) {
  //   _locRecSub?.cancel();
  //   _locRecSub = null;
  //   _listeningSovId = null;
  //
  //   if (sovId == null || sovId.isEmpty) {
  //     locRecMetaData = null;
  //     notifyListeners();
  //     return;
  //   }
  //
  //   _listeningSovId = sovId;
  //
  //   final docRef = firestore.collection('location_recommendations').doc(sovId);
  //
  //   _locRecSub = docRef.snapshots().listen(
  //     (snapshot) async {
  //       if (!snapshot.exists) {
  //         locRecMetaData = null;
  //         notifyListeners();
  //         return;
  //       }
  //
  //       final data = snapshot.data() as Map<String, dynamic>;
  //
  //       /// 🔥 CURRENT blocked locations from Firestore
  //       final List<dynamic> blocked = data['blocked_locations'] ?? [];
  //       final Set<String> currentBlockedIds =
  //           blocked.map((e) => e.toString()).toSet();
  //
  //       /// 🔥 FIND locations that JUST finished processing
  //       final Set<String> completedLocationIds =
  //           _previousBlockedLocationIds.difference(currentBlockedIds);
  //
  //       /// 🔄 Update meta used by UI
  //       locRecMetaData = {
  //         'is_stale': data['is_stale'] ?? false,
  //         'refresh_pending': data['refresh_pending'] ?? false,
  //         'refresh_triggered_at': data['refresh_triggered_at'],
  //         'refresh_completed_at': data['refresh_completed_at'],
  //         'refresh_failed_at': data['refresh_failed_at'],
  //         'blocked_locations': blocked,
  //       };
  //
  //       _previousBlockedLocationIds = currentBlockedIds;
  //
  //       notifyListeners();
  //
  //       // for (final locationId in completedLocationIds) {
  //       //   await _reloadSingleLocation(sovId, '');
  //       // }
  //     },
  //     onError: (error) {
  //       debugPrint(
  //           'Error listening to location_recommendations/$sovId: $error');
  //       locRecMetaData = null;
  //       notifyListeners();
  //     },
  //   );
  // }
  void listenToLocationRecommendations(String? sovId) {
    _locRecSub?.cancel();
    _locRecSub = null;
    _listeningSovId = null;

    if (sovId == null || sovId.isEmpty) {
      locRecMetaData = null;
      notifyListeners();
      return;
    }

    _listeningSovId = sovId;

    final docRef = firestore.collection('location_recommendations').doc(sovId);

    _locRecSub = docRef.snapshots().listen(
      (snapshot) async {
        if (!snapshot.exists) {
          locRecMetaData = null;
          notifyListeners();
          return;
        }

        final data = snapshot.data() as Map<String, dynamic>;

        final List<dynamic> blocked = data['blocked_locations'] ?? [];
        final Set<String> currentBlockedIds =
            blocked.map((e) => e.toString()).toSet();

        /// 🔥 LOCATIONS THAT JUST FINISHED PROCESSING
        final Set<String> completedLocationIds =
            _previousBlockedLocationIds.difference(currentBlockedIds);

        /// 🔄 UPDATE META
        locRecMetaData = {
          'is_stale': data['is_stale'] ?? false,
          'refresh_pending': data['refresh_pending'] ?? false,
          'refresh_triggered_at': data['refresh_triggered_at'],
          'refresh_completed_at': data['refresh_completed_at'],
          'refresh_failed_at': data['refresh_failed_at'],
          'blocked_locations': blocked,
        };

        _previousBlockedLocationIds = currentBlockedIds;

        notifyListeners();

        /// ✅ 🔥 RELOAD API WHEN PROCESSING COMPLETES
        if (completedLocationIds.isNotEmpty) {
          debugPrint(
              "Processing completed for locations: $completedLocationIds");

          await fetchMissingParameterList(
            navigatorKey.currentContext!,
            sovId,
            isRefresh: true,
          );
        }
      },
      onError: (error) {
        debugPrint(
            'Error listening to location_recommendations/$sovId: $error');
        locRecMetaData = null;
        notifyListeners();
      },
    );
  }

  Future<void> _reloadSingleLocation(
    String sovId,
    String locationId,
  ) async {
    try {
      final apiService = ApiService(AppConstant.GET_RECOMMENDATION_LIST);

      final response = await apiService.get(
        '?sov_id=$sovId&location_id=$locationId',
      );

      final model = await compute(AccountListModel.fromJson, response);

      final updatedItem = model.data?.first;
      if (updatedItem == null) return;

      final index = missingParameterList.indexWhere(
        (e) => e.locationId == locationId,
      );

      if (index != -1) {
        missingParameterList[index] = updatedItem;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to reload location $locationId: $e');
    }
  }

  void listenToLocationProcessing(String locationId) {
    if (_locationListeners.containsKey(locationId)) return;

    _isLocationUpdating[locationId] = true;
    notifyListeners();

    final sub = FirebaseFirestore.instance
        .collection("location_recommendations")
        .doc(locationId)
        .snapshots()
        .listen((snap) {
      if (!snap.exists) {
        _isLocationUpdating[locationId] = false;
        _blockedLocationIds.remove(locationId);
      } else {
        final status = snap.data()?['status'];
        final isProcessing = status == 'processing';

        _isLocationUpdating[locationId] = isProcessing;

        if (isProcessing) {
          _blockedLocationIds.add(locationId);
        } else {
          _blockedLocationIds.remove(locationId);
        }
      }
      notifyListeners();
    });

    _locationListeners[locationId] = sub;
  }

  // Column Visibility
  bool _showOwner = true;

  bool get showOwner => _showOwner;

  set showOwner(bool value) {
    _showOwner = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  bool _showSOVCount = true;

  bool get showSOVCount => _showSOVCount;

  set showSOVCount(bool value) {
    _showSOVCount = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  bool _showSubAccountCount = true;

  bool get showSubAccountCount => _showSubAccountCount;

  set showSubAccountCount(bool value) {
    _showSubAccountCount = value;
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

  String? _accountName = "Account Name"; // or "" / "false" / any string

  String get showAccountName => _accountName!;

  set showAccountName(String value) {
    _accountName = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // Pagination
  // int _page = 1;
  //
  // int get page => _page;
  //
  // set page(int value) {
  //   _page = value;
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     notifyListeners();
  //   });
  // }

  int _totalPages = 1;

  int get totalPages => _totalPages;

  set totalPages(int value) {
    _totalPages = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  int accountHits = 0;
  List<Data> _missingParameterList = [];

  List<Data> get missingParameterList => _missingParameterList;

  set missingParameterList(List<Data> value) {
    _missingParameterList = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  List<Accounts> _accountList = [];

  List<Accounts> get accountList => _accountList;

  set accountList(List<Accounts> value) {
    _accountList = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  List<Result> _pricingList = [];

  List<Result> get pricingList => _pricingList;

  set pricingList(List<Result> value) {
    _pricingList = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
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

  Future<void> fetchPricingList(
    BuildContext context,
    String searchQuery,
    int page,
    int pageSize,
  ) async {
    var typography = CustomTypography(context);

    try {
      if (isLoading || isNextPageLoading) return;

      if (page == 1) {
        isLoading = true;
      } else {
        isNextPageLoading = true;
      }
      notifyListeners();

      ApiService apiService = ApiService(AppConstant.GET_PRICING_LIST);
      String url = '';
      if (searchQuery.isNotEmpty) {
        url += '&search=$searchQuery';
      }

      final response = await apiService.get(url);
      log('API response: $response');

      final pricingListData = await compute(PricingModel.fromJson, response);

      pricingList = pricingListData.result ?? [];

      isLoading = false;
      isNextPageLoading = false;
      notifyListeners();
    } on BackendException catch (e, stackTrace) {
      print(stackTrace);

      isLoading = false;
      isNextPageLoading = false;
      notifyListeners();

      log('BackendException: ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.message,
            style: typography.ButtonLargeBlack,
          ),
        ),
      );
    } catch (e, stackTrace) {
      print(stackTrace);

      isLoading = false;
      isNextPageLoading = false;
      notifyListeners();

      log('Exception: ${e.toString()}');
    }
  }

  Future<void> createPlan(BuildContext context) async {
    var typography = CustomTypography(context);
    try {
      isDuplicateLoading = true;
      print(AppConstant.GET_PRICING_LIST);
      ApiService apiService = ApiService(AppConstant.GET_PRICING_LIST);
      var response = await apiService.post({
        'data': {
          'plan_name': 'New Plan',
          'description': 'asdf',
          'billing_cycle_monthly': true,
          'billing_cycle_yearly': true,
          'unit': 'Per User',
          'range_year': [
            {
              'start_count': 0,
              'end_count': 10,
              'price_per_user': 2,
              'range_price': 1,
            }
          ],
          'range_month': [
            {
              'start_count': 0,
              'end_count': 100,
              'price_per_user': 1,
              'range_price': 1,
            }
          ]
        }
      });

      log(response.toString());

      // Parse the response to get the duplicated account
      Accounts duplicatedAccount = Accounts.fromJson(
          response['updated_record']["duplicatedAccountData"]);

      // Prepend the duplicated account to the beginning of the list
      accountList = [duplicatedAccount, ...accountList];

      // ✅ Success message
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          'Success login',
          style: typography.ButtonLarge,
        ),
        backgroundColor: Colors.green,
      ));

      isDuplicateLoading = false;
    } on BackendException catch (e) {
      isDuplicateLoading = false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          e.message,
          style: typography.ButtonLarge,
        ),
      ));
    } catch (e) {
      isDuplicateLoading = false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          e.toString(),
          style: typography.ButtonLargeBlack,
        ),
      ));
    }
  }

  Future<void> fetchAccountList(
      BuildContext context, String searchQuery, int page, int pageSize) async {
    lastSearchQuery = searchQuery;

    try {
      if (isLoading || isNextPageLoading) return;

      if (page == 1) {
        isLoading = true;
        accountList.clear();
      } else {
        isNextPageLoading = true;
      }

      final apiService = ApiService(AppConstant.GET_ACCOUNT_LIST);
      var url = '?page=$page&pageSize=$pageSize';

      if (searchQuery.isNotEmpty) {
        url += '&search=$searchQuery';
      }

      final response = await apiService.get(url);
      final model = await compute(AccountListModel.fromJson, response);

      showOwner = model.settings?.owner ?? true;
      showSOVCount = model.settings?.sovCount ?? true;
      showSubAccountCount = model.settings?.subAccountCount ?? true;
      showOverallScore = model.settings?.overallScore ?? true;
      showAccountName =
          model.settings!.companyGlobalConfiguration!.accountName.toString();

      accountHits = model.totalRecords ?? 0;
      totalPages = (accountHits / pageSize).ceil();

      if (page == 1) {
        accountList = model.results ?? [];
      } else {
        addToAccountList(model.results ?? []);
      }
      hasLoadedOnce = true;
      forceReload = false;
    } finally {
      isLoading = false;
      isNextPageLoading = false;
      notifyListeners();
    }
  }

  Future<void> unlockHazardHubData(
    BuildContext context, {
    required List<String> locationIds,
  }) async {
    try {
      if (isUpdating) return;

      isUpdating = true;
      notifyListeners();

      final apiService = ApiService(AppConstant.HANDLE_VENDOR_DATA
          // 'https://us-central1-project-green-prod.cloudfunctions.net/recommendation_engine/handle_vendor_data',
          );

      final payload = {
        "location_ids": locationIds,
        "vendor_key": "hazard_hub",
      };

      await apiService.post(payload);
    } finally {
      isUpdating = false;
      notifyListeners();
    }
  }

  Future<void> fetchMissingParameterList(
    BuildContext context,
    String sovId, {
    bool isRefresh = false,
  }) async {
    try {
      if (isLoading) return;

      /// 🔄 FULL RESET ON REFRESH
      if (isRefresh) {
        _blockedLocationIds.clear();
        _previousBlockedLocationIds.clear();
        _isLocationUpdating.clear();
        updatingItemId = null;
      }

      isLoading = true;
      notifyListeners();

      final apiService = ApiService(AppConstant.GET_RECOMMENDATION_LIST);
      final response = await apiService.get('?sov_id=$sovId');

      final model = await compute(AccountListModel.fromJson, response);
      accountListModel = model;

      /// 🔥 CURRENT BLOCKED LOCATIONS FROM FIRESTORE
      final Set<String> currentBlocked =
          (locRecMetaData?['blocked_locations'] as List?)
                  ?.map((e) => e.toString())
                  .toSet() ??
              {};

      /// ✅ FILTER ONLY – NO SIDE EFFECTS
      missingParameterList = (model.data ?? []).where((item) {
        final locationId = item.locationId ?? '';
        final missing = item.totalUnfilledParameters ?? 0;

        // keep if still processing
        if (currentBlocked.contains(locationId)) {
          return true;
        }

        // keep if still missing parameters
        return missing > 0;
      }).toList();

      listenToSovMeta(sovId);
    } catch (e, stack) {
      debugPrint('fetchMissingParameterList error: $e');
      debugPrint(stack.toString());
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Future<void> fetchMissingParameterList(
  //   BuildContext context,
  //   String sovId, {
  //   bool isRefresh = false,
  // }) async {
  //   try {
  //     if (isLoading) return;
  //
  //     /// 🔄 FULL RESET ON REFRESH
  //     if (isRefresh) {
  //       blockedLocationIds.clear();
  //       _previousBlockedLocationIds.clear();
  //       _isLocationUpdating.clear();
  //       updatingItemId = null;
  //     }
  //
  //     isLoading = true;
  //     notifyListeners();
  //
  //     final apiService = ApiService(AppConstant.GET_RECOMMENDATION_LIST);
  //     final response = await apiService.get('?sov_id=$sovId');
  //
  //     final model = await compute(AccountListModel.fromJson, response);
  //
  //     accountListModel = model;
  //
  //     final Set<String> currentBlocked =
  //         (locRecMetaData?['blocked_locations'] as List?)
  //                 ?.map((e) => e.toString())
  //                 .toSet() ??
  //             {};
  //
  //     missingParameterList = (model.data ?? []).where((item) {
  //       final locationId = item.locationId ?? '';
  //       final missing = item.totalUnfilledParameters ?? 0;
  //
  //       // keep items still processing
  //       if (currentBlocked.contains(locationId)) {
  //         return true;
  //       }
  //       // Keeping listeners
  //       for (var item in sovList) {
  //         if (item.sovId != null) {
  //           listenToSovMeta(item.sovId!);
  //         }
  //       }
  //       // keep items with missing parameters
  //       return missing > 0;
  //     }).toList();
  //   } catch (e, stack) {
  //     debugPrint('fetchMissingParameterList error: $e');
  //     debugPrint(stack.toString());
  //   } finally {
  //     isLoading = false;
  //     notifyListeners();
  //   }
  // }

  // Future<void> fetchMissingParameterList(
  //   BuildContext context,
  //   String sovId, {
  //   bool isRefresh = false,
  // }) async {
  //   try {
  //     if (isLoading) return;
  //
  //     /// 🔥 FULL RESET ON REFRESH
  //     if (isRefresh) {
  //       blockedLocationIds.clear();
  //       _previousBlockedLocationIds.clear();
  //       _isLocationUpdating.clear();
  //       updatingItemId = null;
  //     }
  //
  //     isLoading = true;
  //     notifyListeners();
  //
  //     final apiService = ApiService(AppConstant.GET_RECOMMENDATION_LIST);
  //     final response = await apiService.get('?sov_id=$sovId');
  //     final model = await compute(AccountListModel.fromJson, response);
  //
  //     /// 🔥 ONLY CURRENT PROCESSING MATTERS
  //     final Set<String> currentBlocked =
  //         (locRecMetaData?['blocked_locations'] as List?)
  //                 ?.map((e) => e.toString())
  //                 .toSet() ??
  //             {};
  //
  //     /// ✅ FULL REFRESH LOGIC
  //     missingParameterList = (model.data ?? []).where((item) {
  //       final locationId = item.locationId ?? '';
  //       final missing = item.totalUnfilledParameters ?? 0;
  //
  //       // Keep if still processing
  //       if (currentBlocked.contains(locationId)) {
  //         return true;
  //       }
  //
  //       // Keep only if still missing
  //       return missing > 0;
  //     }).toList();
  //   } catch (e, stack) {
  //     debugPrint('fetchMissingParameterList error: $e');
  //     debugPrint(stack.toString());
  //   } finally {
  //     isLoading = false;
  //     notifyListeners();
  //   }
  // }

  // Future<void> fetchMissingParameterList(
  //   BuildContext context,
  //   String sovId, {
  //   bool isRefresh = false,
  // }) async {
  //   try {
  //     /// ⛔ Prevent duplicate calls
  //     if (isLoading) return;
  //
  //     isLoading = true;
  //     notifyListeners();
  //
  //     final apiService = ApiService(AppConstant.GET_RECOMMENDATION_LIST);
  //
  //     /// ✅ NO PAGE PARAM
  //     final url = '?sov_id=$sovId';
  //
  //     final response = await apiService.get(url);
  //
  //     final model = await compute(AccountListModel.fromJson, response);
  //
  //     /// ✅ Replace entire list (no append)
  //     missingParameterList = model.data ?? [];
  //   } catch (e, stack) {
  //     debugPrint('fetchMissingParameterList error: $e');
  //     debugPrint(stack.toString());
  //   } finally {
  //     isLoading = false;
  //     notifyListeners();
  //   }
  // }

  // Future<void> fetchMissingParameterList(
  //   BuildContext context,
  //   String sovId, {
  //   bool isRefresh = false,
  // }) async {
  //   try {
  //     if (isLoading || isNextPageLoading) return;
  //
  //     if (isRefresh) {
  //       page = 1;
  //       missingParameterList.clear();
  //     }
  //
  //     if (page == 1) {
  //       isLoading = true;
  //     } else {
  //       isNextPageLoading = true;
  //     }
  //
  //     notifyListeners();
  //
  //     final apiService = ApiService(AppConstant.GET_RECOMMENDATION_LIST);
  //     final url = '?sov_id=$sovId&page=$page';
  //
  //     final response = await apiService.get(url);
  //
  //     final model = await compute(AccountListModel.fromJson, response);
  //     final newList = model.data ?? [];
  //
  //     if (page == 1) {
  //       missingParameterList = newList;
  //     } else {
  //       missingParameterList.addAll(newList);
  //     }
  //
  //     if (newList.isNotEmpty) {
  //       page++;
  //     }
  //   } catch (e, stack) {
  //     debugPrint('fetchMissingParameterList error: $e');
  //     debugPrint(stack.toString());
  //   } finally {
  //     isLoading = false;
  //     isNextPageLoading = false;
  //     notifyListeners();
  //   }
  // }

  List<Accounts> parameterList = [];

  Future<void> updateRecommendation(
    BuildContext context,
    String locationId,
  ) async {
    try {
      /// 🔵 Screen-level loading
      isLoading = true;
      notifyListeners();

      final apiService = ApiService(AppConstant.SOV_PARAMETER_UPDATE);

      final response = await apiService.post({
        "location_id": locationId,
        "param_type": true,
        "data_parameters": [],
      });

      final List list = response['result'] ?? [];

      parameterList = list.map((e) => Accounts.fromJson(e)).toList();

      debugPrint("Parameters loaded: ${parameterList.length}");
    } catch (e, stack) {
      debugPrint("updateRecommendation error: $e");
      debugPrint(stack.toString());
      rethrow;
    } finally {
      /// ✅ Mark first load completed
      isLoading = false;
      hasLoadedOnce = true;
      notifyListeners();
    }
  }

  Future<void> updateRecommendationApi(
    BuildContext context,
    String locationId,
    Map<String, dynamic> payload,
  ) async {
    try {
      isDuplicateLoading = true;
      notifyListeners();

      final apiService = ApiService(AppConstant.SOV_PARAMETER_UPDATE);

      /// ✅ Final payload (already built in UI)
      final finalPayload = {
        "location_id": locationId,
        ...payload, // contains to_update_data_params
      };

      debugPrint("Submitting payload: $finalPayload");

      await apiService.post(finalPayload);
    } catch (e, stack) {
      debugPrint("Update error: $e");
      debugPrint(stack.toString());
      rethrow;
    } finally {
      isDuplicateLoading = false;
      notifyListeners();
    }
  }

  // Future<void> updateRecommendationApi(
  //   BuildContext context,
  //   String locationId,
  //   Map<String, TextEditingController> controllers,
  // ) async {
  //   try {
  //     isDuplicateLoading = true;
  //     notifyListeners();
  //
  //     final apiService = ApiService(AppConstant.SOV_PARAMETER_UPDATE);
  //
  //     final List<Map<String, dynamic>> toUpdateDataParams = [];
  //
  //     for (final param in parameterList) {
  //       final controller = controllers[param.dataCategoryId];
  //       final value = controller?.text.trim();
  //
  //       if (value == null || value.isEmpty) continue;
  //
  //       toUpdateDataParams.add({
  //         "value": jsonEncode({
  //           "value": value,
  //           "unit": "",
  //           "value_a": "",
  //           "value_b": "",
  //           "currency": "",
  //           "valuation_date": "",
  //         }),
  //         "param_type": param.parameterType, // e.g. "Number"
  //         "reference": {
  //           "url": [],
  //           "tags": [],
  //         },
  //         "data_category_id": param.dataCategoryId,
  //         "name": param.parameterNameA,
  //       });
  //     }
  //
  //     final payload = {
  //       "location_id": locationId,
  //       "to_update_data_params": toUpdateDataParams,
  //     };
  //
  //     debugPrint("Submitting payload: $payload");
  //
  //     await apiService.post(payload);
  //   } catch (e) {
  //     rethrow;
  //   } finally {
  //     isDuplicateLoading = false;
  //     notifyListeners();
  //   }
  // }

  // Future<List<Accounts>> updateRecommendation(
  //   BuildContext context,
  //   String locationId,
  // ) async {
  //   try {
  //     isDuplicateLoading = true;
  //     notifyListeners();
  //
  //     ApiService apiService = ApiService(AppConstant.SOV_PARAMETER_UPDATE);
  //
  //     final response = await apiService.post({
  //       "location_id": locationId,
  //       "param_type": true,
  //       "data_parameters": [],
  //     });
  //
  //     final AccountListModel model = AccountListModel.fromJson(response);
  //
  //     accountList = model.results!;
  //     print(accountList.length.toString());
  //
  //     return accountList;
  //   } catch (e) {
  //     rethrow;
  //   } finally {
  //     isDuplicateLoading = false;
  //     notifyListeners();
  //   }
  // }

  /// Rename account
  Future<void> renameAccount(
      BuildContext context, String accountId, String newName) async {
    var typography = CustomTypography(context);
    try {
      isRenameLoading = true;

      ApiService apiService = ApiService(AppConstant.RENAME_ACCOUNT);
      var response = await apiService.patch({
        'data': {
          "rename_account": true,
          'account_id': accountId,
          'account_name': newName,
        }
      });
      log(response.toString());

      // Update account name in the list
      int index =
          accountList.indexWhere((element) => element.accountId == accountId);
      if (index != -1) {
        accountList[index].accountName = newName;
      }

      isRenameLoading = false;
    } on BackendException catch (e) {
      isRenameLoading = false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          e.message,
          style: typography.ButtonLargeBlack,
        ),
      ));
    } catch (e) {
      isRenameLoading = false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          e.toString(),
          style: typography.ButtonLargeBlack,
        ),
      ));
    }
  }

  Future<void> renameSov(
      BuildContext context, String sovId, String newName) async {
    var typography = CustomTypography(context);
    try {
      isRenameLoading = true;

      ApiService apiService = ApiService(AppConstant.RENAME_SOV);
      var response = await apiService.patch({
        'data': {
          'name': newName,
          "rename_sov": true,
          'sov_id': sovId,
        }
      });
      log(response.toString());

      // Update account name in the list
      int index =
          accountList.indexWhere((element) => element.accountId == sovId);
      if (index != -1) {
        accountList[index].accountName = newName;
      }

      // isRenameLoading = false;
    } on BackendException catch (e) {
      isRenameLoading = false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          e.message,
          style: typography.ButtonLargeBlack,
        ),
      ));
    } catch (e) {
      isRenameLoading = false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          e.toString(),
          style: typography.ButtonLargeBlack,
        ),
      ));
    }
  }

  /// Duplicate account
  Future<void> duplicateAccount(BuildContext context, String accountId) async {
    var typography = CustomTypography(context);
    try {
      isDuplicateLoading = true;
      ApiService apiService = ApiService(AppConstant.DUPLICATE_ACCOUNT);
      var response = await apiService.post({
        'data': {
          'account_id': accountId,
          'duplicate': true,
        }
      });
      log(response.toString());

      // Parse the response to get the duplicated account
      Accounts duplicatedAccount = Accounts.fromJson(
          response['updated_record']["duplicatedAccountData"]);

      // Prepend the duplicated account to the beginning of the list
      accountList = [duplicatedAccount, ...accountList];

      // isDuplicateLoading = false;
    } on BackendException catch (e) {
      isDuplicateLoading = false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          e.message,
          style: typography.ButtonLargeBlack,
        ),
      ));
    } catch (e) {
      isDuplicateLoading = false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          e.toString(),
          style: typography.ButtonLargeBlack,
        ),
      ));
    }
  }

  Future<bool> changeColumnVisibility(BuildContext context,
      {required bool showOwner,
      required bool showSOVCount,
      required bool showSubAccountCount,
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

      ApiService apiService = ApiService(AppConstant.CHANGE_COLUMN_VISIBILITY);

      var response = await apiService.patch({
        'data': {
          'table_setting': true,
          'owner': showOwner,
          'sov_count': showSOVCount,
          'sub_account_count': showSubAccountCount,
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
          style: typography.ButtonLargeBlack,
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
          style: typography.ButtonLargeBlack,
        ),
      ));
      return false;
    }
  }

  /// Fetch autocomplete account list
  Future<void> fetchAutoCompleteAccountList(
      BuildContext context, String searchQuery) async {
    var typography = CustomTypography(context);
    try {
      isAutoCompleteLoading = true;

      print("Fetching autocomplete list for query: $searchQuery");
      ApiService apiService = ApiService(AppConstant.GET_ACCOUNT_LIST);
      String url = '?search=$searchQuery';
      var response = await apiService.get(url);
      log(response.toString());

      // AccountListModel accountListModel = AccountListModel.fromJson(response);

      final accountListModel =
          await compute(AccountListModel.fromJson, response);
      autoCompleteAccountList = accountListModel.results ?? [];
      log(autoCompleteAccountList.toString());
      print("Updated autoCompleteAccountList: $autoCompleteAccountList");
    } on BackendException catch (e, stackTrace) {
      print(stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          e.message,
          style: typography.ButtonLargeBlack,
        ),
      ));
    } catch (e, stackTrace) {
      print(stackTrace);
      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      //   content: Text(e.toString(), style: typography.ButtonLargeBlack,),
      //
      // ));
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
      var response = await apiService.post({
        'data': {
          'account_name': accountName,
        }
      });
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
        content: Text(
          e.message,
          style: typography.ButtonLargeBlack,
        ),
      ));
    } catch (e) {
      isAddAccountLoading = false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          e.toString(),
          style: typography.ButtonLargeBlack,
        ),
      ));
    }
  }

  // Delete Tags from location

  Future<bool> deleteAccount(BuildContext context, String accountId) async {
    try {
      isDeleteLocationLoading = true;
      notifyListeners(); // Notify UI to update the button state

      ApiService apiService =
          ApiService("${AppConstant.DELETE_ACCOUNT}account_id=$accountId");
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
      // CustomToast.error(context, "An unexpected error occurred");
      return false;
    } finally {
      // isDeleteLocationLoading = false;
      notifyListeners(); // Notify UI to remove the loader
    }
  }

  // Future<bool> deleteAccount(BuildContext context, String accountId,
  //    ) async {
  //   try {
  //     isAddAccountLoading = true;
  //     ApiService apiService =
  //     ApiService("${AppConstant.DELETE_ACCOUNT}account_id=$accountId");
  //     var response = await apiService.delete({});
  //     log(response.toString());
  //     CustomToast.success(context, response['message']);
  //   } on BackendException catch (e, stackTrace) {
  //     log("Error deleting tag from location: ${e.message}");
  //     log(stackTrace.toString());
  //     CustomToast.error(context, e.message);
  //   } catch (e, stackTrace) {
  //     log("Error deleting tag from location: $e");
  //     log(e.toString());
  //     log(stackTrace.toString());
  //     CustomToast.error(context, e.toString());
  //   } finally {
  //     isAddAccountLoading = false;
  //     return true;
  //   }
  // }

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
          style: typography.ButtonLargeBlack,
        ),
      ));
    } on BackendException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          e.message,
          style: typography.ButtonLargeBlack,
        ),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          e.toString(),
          style: typography.ButtonLargeBlack,
        ),
      ));
    }
  }

  Future<String> uploadSovAccount(
      BuildContext context, File sovFile, String accountId, String name) async {
    var typography = CustomTypography(context);
    try {
      isImageUploadLoading = true;
      ApiService apiService =
          ApiService(AppConstant.UPLOAD_SOV_ACCOUNT + '/upload');
      print(AppConstant.UPLOAD_SOV_ACCOUNT + '/upload');
      print(apiService);
      // Send a POST request to the API to upload the image
      Map<String, dynamic> response =
          await apiService.postMultiPartSOVAccounts(sovFile, accountId, name);
      // print(response!.message.toString());
      isImageUploadLoading = false;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          response['message'] ??
              LanguageService.getTranslated(
                  context, "account_list_app_sov_upload_success"),
          style: typography.ButtonLargeBlack,
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
            style: typography.ButtonLargeBlack,
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
            style: typography.ButtonLargeBlack,
          ),
        ),
      );
      isImageUploadLoading = false;
      return ''; // Return empty string or handle the error as needed
    }
  }

  Future<void> transferAccount(
      BuildContext context, String accountId, String newOwnerId) async {
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
        content:
            Text(response['message'] ?? 'Account transferred successfully'),
      ));

      // Update the account list UI
      int index =
          accountList.indexWhere((element) => element.accountId == accountId);
      if (index != -1) {
        accountList[index].disabled = true;
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
        content: Text('Failed to transfer account: ${e.toString()}'),
      ));
    }
  }
}
