import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:RiskSphere/design_system/primitives/custom_typography.dart';
import 'package:RiskSphere/models/account_list_model.dart';
import 'package:RiskSphere/models/location_list_model.dart';
import 'package:RiskSphere/models/location_profile_model.dart';
import 'package:RiskSphere/models/my_location_list_model.dart';
import 'package:RiskSphere/models/sov_list_model.dart';
import 'package:RiskSphere/providers/sov_list_provider.dart';
import 'package:RiskSphere/screens/listings/widgets/auto_complete_options_sovs.dart';
import 'package:RiskSphere/service/api_service.dart';
import 'package:RiskSphere/utils/api_constants.dart';
import 'package:RiskSphere/utils/common_headers.dart';
import 'package:provider/provider.dart';
import '../constants/enums.dart';
import '../design_system/components/custom_button.dart';
import '../design_system/components/custom_toast.dart';

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:RiskSphere/design_system/primitives/custom_typography.dart';
import 'package:RiskSphere/models/location_list_model.dart';
import 'package:RiskSphere/service/api_service.dart';
import 'package:RiskSphere/utils/api_constants.dart';

import '../screens/listings/widgets/auto_complete_options.dart';
import '../service/language_service.dart';

MyLocationModel parseLocationModel(Map<String, dynamic> json) {
  return MyLocationModel.fromJson(json);
}

UserManagementResponse parseUserManagement(String body) {
  final jsonMap = jsonDecode(body);
  return UserManagementResponse.fromJson(jsonMap);
}

MyLocationModel parseMyLocationModel(Map<String, dynamic> json) {
  return MyLocationModel.fromJson(json);
}

class MyLocationListProvider extends ChangeNotifier {
  final Set<String> selectedLocationIds = {};
  final Set<String> excludedLocationIds = {};
  bool isGlobalSelectAll = false;
  bool isFetchingAllIds = false;
  bool isExportLoading = false;
  bool isAddTagFetchingIds = false;
  bool isDeleteFetchingIds = false;
  int totalLocationCount = 0;
  double? dataCompletenessScore;
  bool isAddToSOVPreparing = false;

  // 🔹 Dialog submit button
  bool isAddToSOVSubmitting = false;

  void setPreparing(bool v) {
    isAddToSOVPreparing = v;
    notifyListeners();
  }

  void setSubmitting(bool v) {
    isAddToSOVSubmitting = v;
    notifyListeners();
  }

  void setDataCompletenessScore(double value) {
    dataCompletenessScore = value;
    notifyListeners();
  }

  // 🔹 CHECK IF ITEM IS SELECTED
  bool isSelected(String id) {
    if (isGlobalSelectAll) {
      return !excludedLocationIds.contains(id);
    }
    return selectedLocationIds.contains(id);
  }

  // 🔹 SELECT ALL (GLOBAL)
  void selectAllGlobal({required int totalCount}) {
    isGlobalSelectAll = true;
    totalLocationCount = totalCount;
    selectedLocationIds.clear();
    excludedLocationIds.clear();
    notifyListeners();
  }

  void addIdToSelection(String locationId) {
    selectedLocationIds.add(locationId);
    notifyListeners();
  }

  void removeIdFromSelection(String id) {
    selectedLocationIds.remove(id);

    // 👇 VERY IMPORTANT
    if (isGlobalSelectAll) {
      isGlobalSelectAll = false;
    }

    notifyListeners();
  }

  // void removeIdFromSelection(String locationId) {
  //   selectedLocationIds.remove(locationId);
  //
  //   // if nothing selected → exit selection mode
  //   if (selectedLocationIds.isEmpty) {
  //     isGlobalSelectAll = false;
  //   }
  //   notifyListeners();
  // }

  bool _isLoading = false;
  int currentPage = 1;
  bool _isFetching = false; // prevent concurrent API calls
  bool get isFetchingMore => isNextPageLoading; // optional alias for clarity

  bool get isLastPage => currentPage >= totalPages;

  void setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  int get selectedCount {
    if (isGlobalSelectAll) {
      return totalLocationCount - excludedLocationIds.length;
    }
    return selectedLocationIds.length;
  }

  void goToNextPage() {
    currentPage++;
    notifyListeners(); // Triggers UI update
  }

  int locationHits = 0;
  int certifiedLocationHits = 0;
  bool isConflict = false;
  bool isHazardCanStart = false;
  bool isAnyLocationSelected = false;

  Future<void> fetchLocations() async {
    isLoading = true;
    locationHits = 0; // Set count to 0 while loading
    certifiedLocationHits = 0;
    notifyListeners();

    await Future.delayed(Duration(seconds: 2)); // Simulate API call

    locationHits = 10; // Example count after API call
    certifiedLocationHits = 5;

    isLoading = false;
    notifyListeners();
  }

  bool get isLoading => _isLoading;

  set isLoading(bool value) {
    _isLoading = value;
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  bool _isSearchLoading = false;

  bool get isSearchLoading => _isSearchLoading;

  set isSearchLoading(bool value) {
    _isSearchLoading = value;
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  bool _isHeatMapGeneratingLive = false;

  bool get isHeatMapGeneratingLive => _isHeatMapGeneratingLive;

  void setHeatmapGeneratingLive(bool value) {
    _isHeatMapGeneratingLive = value;
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  bool _isAllLocationLoading = false;

  bool get isAllLocationLoading => _isAllLocationLoading;

  set isAllLocationLoading(bool value) {
    _isAllLocationLoading = value;
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  bool _isCertifiedLoading = false;

  bool get isCertifiedLoading => _isCertifiedLoading;

  set isCertifiedLoading(bool value) {
    _isCertifiedLoading = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
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

  bool _isNextPageCertifiedLoading = false;

  bool get isNextPageCertifiedLoading => _isNextPageCertifiedLoading;

  set isNextPageCertifiedLoading(bool value) {
    _isNextPageCertifiedLoading = value;
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  bool _isAddLocationLoading = false;

  bool get isAddLocationLoading => _isAddLocationLoading;

  set isAddLocationLoading(bool value) {
    _isAddLocationLoading = value;
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      notifyListeners();
    });
  }

  Map<String, Map<String, dynamic>?> sovMeta = {};
  Map<String, StreamSubscription<DocumentSnapshot>> _listeners = {};

  void listenToSovMeta(String sovId) {
    // Prevent duplicate listeners
    if (_listeners.containsKey(sovId)) return;

    final sub = FirebaseFirestore.instance
        .collection("location_recommendations")
        .doc(sovId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        sovMeta[sovId] = snapshot.data();
      } else {
        sovMeta[sovId] = null;
      }
      notifyListeners(); // 🔥 only affected rows update
    });

    _listeners[sovId] = sub;
  }

  bool _isAddTagsLoading = false;

  bool get isAddTagsLoading => _isAddTagsLoading;

  set isAddTagsLoading(bool value) {
    _isAddTagsLoading = value;
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      notifyListeners();
    });
  }

  bool _isDeleteTagLoading = false;

  bool get isDeleteTagLoading => _isDeleteTagLoading;

  set isDeleteTagLoading(bool value) {
    _isDeleteTagLoading = value;
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      notifyListeners();
    });
  }

  bool _isHeatMapGenerating = false;

  bool get isHeatMapGenerating => _isHeatMapGenerating;

  set isHeatMapGenerating(bool value) {
    _isHeatMapGenerating = value;
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
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

  bool _isImageUploadLoading = false;

  bool get isImageUploadLoading => _isImageUploadLoading;

  set isImageUploadLoading(bool value) {
    _isImageUploadLoading = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  bool _isAddToSOVLoading = false;

  bool get isAddToSOVLoading => _isAddToSOVLoading;

  set isAddToSOVLoading(bool value) {
    _isAddToSOVLoading = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  bool _isUploadingImage = false;

  bool get isUploadingImage => _isUploadingImage;

  set isUploadingImage(bool value) {
    _isUploadingImage = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  bool _isMainTileProvidersLoading = false;

  bool get isMainTileProvidersLoading => _isMainTileProvidersLoading;

  set isMainTileProvidersLoading(bool value) {
    _isMainTileProvidersLoading = value;
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  List<String> _countries = [];
  String _state = '';
  List<String> _propertyType = [];
  List<String> _constructionType = [];
  List<String> _certifications = [];
  List<String> _hazard = [];
  List<int> _rating = [];

  List<String> _countryList = [];
  List<String> _hazardList = [];

  // Getter for the country and hazard list
  List<String> get countryList => _countryList;

  List<String> get hazardList => _hazardList;

  // Setters for country and hazard lists
  set countryList(List<String> value) {
    _countryList = value;
    notifyListeners();
  }

  set hazardList(List<String> value) {
    _hazardList = value;
    notifyListeners();
  }

  // Getters for the filter values
  List<String> get countries => _countries;

  String get state => _state;

  List<String> get propertyType => _propertyType;

  List<String> get constructionType => _constructionType;

  List<String> get certifications => _certifications;

  List<String> get hazard => _hazard;

  List<int> get rating => _rating;
  String _zipcode = '';
  String _sortBy = '';

  String get zipcode => _zipcode;

  set zipcode(String value) {
    _zipcode = value;
    notifyListeners();
  }

  String get sortBy => _sortBy;

  set sortBy(String value) {
    _sortBy = value;
    notifyListeners();
  }

  // Setters for the filter values
  set countries(List<String> value) {
    _countries = value;
    notifyListeners();
  }

  set state(String value) {
    _state = value;
    notifyListeners();
  }

  set propertyType(List<String> value) {
    _propertyType = value;
    notifyListeners();
  }

  set constructionType(List<String> value) {
    _constructionType = value;
    notifyListeners();
  }

  set certifications(List<String> value) {
    _certifications = value;
    notifyListeners();
  }

  set hazard(List<String> value) {
    _hazard = value;
    notifyListeners();
  }

  set rating(List<int> value) {
    _rating = value;
    notifyListeners();
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

  int? _totalPages = 1;

  int get totalPages => _totalPages!;

  set totalPages(int value) {
    _totalPages = value;
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  int _certifiedPage = 1;

  int get certifiedPage => _certifiedPage;

  set certifiedPage(int value) {
    _certifiedPage = value;
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  int _certifiedTotalPages = 1;

  int get certifiedTotalPages => _certifiedTotalPages;

  set certifiedTotalPages(int value) {
    _certifiedTotalPages = value;
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  double mainSovRating = 0;

  List<Location> _locationListOld = [];

  List<Location> get locationListOld => _locationListOld;

  set locationListOld(List<Location> value) {
    _locationListOld = value;
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  int? _locationCount = 0;

  int get locationcount => _locationCount!;

  set locationcount(int value) {
    _locationCount = value;
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  List<MyLocation> _myLocationList = [];

  List<MyLocation> get myLocationList => _myLocationList;

  set myLocationList(List<MyLocation> value) {
    _myLocationList = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  List<MyLocation> _overallLocationList = [];

  List<MyLocation> get overallLocationList => _overallLocationList;

  set overallLocationList(List<MyLocation> value) {
    _overallLocationList = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  List<MyLocation> _myLocationConflictList = [];

  List<MyLocation> get myLocationConflictList => _myLocationConflictList;

  set myLocationConflictList(List<MyLocation> value) {
    _myLocationConflictList = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  List<MyLocation> _certifiedLocationList = [];

  List<MyLocation> get certifiedLocationList => _certifiedLocationList;

  set certifiedLocationList(List<MyLocation> value) {
    _certifiedLocationList = value;
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  List<MyLocation> _searchLocationList = [];

  List<MyLocation> get searchLocationList => _searchLocationList;

  set searchLocationList(List<MyLocation> value) {
    _searchLocationList = value;
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  MyLocation? _locationProfile;

  MyLocation? get locationProfile => _locationProfile;

  set locationProfile(MyLocation? value) {
    _locationProfile = value;
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  GraphData? _grapData;

  GraphData? get grapDataProfile => _grapData;

  set grapDataProfile(GraphData? value) {
    _grapData = value;
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  List<MyLocation> _fullLocationList = [];

  List<MyLocation> get fullLocationList => _fullLocationList;

  set fullLocationList(List<MyLocation> value) {
    _fullLocationList = value;
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // Method to add to the certified location list
  void addToCertifiedLocationList(List<MyLocation> newLocations) {
    _certifiedLocationList.addAll(newLocations);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  List<String> _summaryList = [];

  List<String> get summaryList => _summaryList;

  set summaryList(List<String> value) {
    _summaryList = value;
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void addToLocationListOld(List<Location> newLocations) {
    _locationListOld.addAll(newLocations);
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void addToMyLocationList(List<MyLocation> newLocations) {
    _myLocationList.addAll(newLocations);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  List<String> _campusIds = [];

  List<String> get campusIds => _campusIds;

  set campusIds(List<String> value) {
    _campusIds = value;
    notifyListeners();
  }

  List<String> _selectedCampusIds = [];

  List<String> get selectedCampusIds => _selectedCampusIds;

  set selectedCampusIds(List<String> value) {
    _selectedCampusIds = value;
    notifyListeners();
  }

  void clearDataCompletenessScore() {
    dataCompletenessScore = null;
    notifyListeners();
  }

  bool get hasDataCompletenessFilter => dataCompletenessScore != null;

  bool isCertifiedTabAllowed() {
    return certifiedLocationHits > 0;
  }

  Map<String, dynamic>? hazardData;
  Map<String, dynamic>? geocodingData;
  Map<String, dynamic>? mainHazardData;

  /// Pagination variables
  String? locationListPageToken;
  String? locationListDirection;
  bool locationListNextPageExists = true;

  String? certifiedLocationListPageToken;
  String? certifiedLocationListDirection;
  bool certifiedLocationListNextPageExists = true;

  Map<String, List<int>> _hazardRatings = {};

  Map<String, List<int>> get hazardRatings => _hazardRatings;

  set hazardRatings(Map<String, List<int>> value) {
    _hazardRatings = value;
    notifyListeners();
  }

  // Clear all hazard filters
  void clearAllHazardFilters() {
    _hazardRatings = {};
    notifyListeners();
  }

  // Example of clearing other filters
  void clearCountryFilter() {
    _countries = [];
    notifyListeners();
  }

  void clearCertificationsFilter() {
    _certifications = [];
    notifyListeners();
  }

  void clearHazardFilter(String hazardName) {
    _hazardRatings.remove(hazardName);
    notifyListeners();
  }

  void clearRatingsFilter() {
    _rating = [];
    notifyListeners();
  }

  // Method to clear all filters
  void clearAllFilters() {
    _countries = [];
    _certifications = [];
    _hazardRatings = {};
    _propertyType = [];
    _constructionType = [];
    _rating = [];
    _sortBy = "";
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  bool hasAnyFilterApplied() {
    return _countries.isNotEmpty ||
        _certifications.isNotEmpty ||
        _hazardRatings.isNotEmpty ||
        _propertyType.isNotEmpty ||
        _constructionType.isNotEmpty ||
        _rating.isNotEmpty;
  }

  /// Selection mode

  // Selected Locations Set
  final Set<MyLocation> _selectedLocations = {};

  // Getter for selected locations
  Set<MyLocation> get selectedLocations => _selectedLocations;

  // Add to selection
  void addToSelection(MyLocation? location) {
    if (location != null) {
      _selectedLocations.add(location);
      notifyListeners();
    }
  }

  // Remove from selection
  void removeFromSelection(MyLocation? location) {
    if (location != null) {
      _selectedLocations.remove(location);
      notifyListeners();
    }
  }

  // Toggle selection
  void toggleSelection(String id) {
    if (selectedLocationIds.contains(id)) {
      selectedLocationIds.remove(id);
    } else {
      selectedLocationIds.add(id);
    }

    // 🔥 VERY IMPORTANT
    isGlobalSelectAll = false;
    notifyListeners();
  }

  // void toggleSelection(MyLocation loc) {
  //   loc.isSelected = !(loc.isSelected ?? false);
  //
  //   if (loc.isSelected!) {
  //     if (!selectedLocations.contains(loc)) {
  //       selectedLocations.add(loc);
  //     }
  //   } else {
  //     selectedLocations.remove(loc);
  //   }
  //
  //   notifyListeners();
  // }
  // 🔹 TOGGLE ITEM
  void toggleItem(String id) {
    if (isGlobalSelectAll) {
      if (excludedLocationIds.contains(id)) {
        excludedLocationIds.remove(id);
      } else {
        excludedLocationIds.add(id);
      }
    } else {
      if (selectedLocationIds.contains(id)) {
        selectedLocationIds.remove(id);
      } else {
        selectedLocationIds.add(id);
      }
    }
    notifyListeners();
  }

  // void selectAllGlobal({
  //   required bool isCertified,
  //   required int totalCount,
  // }) {
  //   isGlobalSelectAll = true;
  //   selectedLocationIds.clear();
  //
  //   final sourceList = isCertified ? certifiedLocationList : myLocationList;
  //
  //   for (final loc in sourceList) {
  //     if (loc.id != null) {
  //       selectedLocationIds.add(loc.id!);
  //       loc.isSelected = true; // visible items tick
  //     }
  //   }
  //
  //   totalLocationCount = totalCount;
  //
  //   notifyListeners();
  // }

  // void selectAllLocations(bool isCertified) {
  //   selectedLocations.clear();
  //
  //   if (isCertified) {
  //     for (var loc in certifiedLocationList) {
  //       loc.isSelected = true;
  //       selectedLocations.add(loc);
  //     }
  //   } else {
  //     for (var loc in myLocationList) {
  //       loc.isSelected = true;
  //       selectedLocations.add(loc);
  //     }
  //   }
  //
  //   notifyListeners();
  // }
  void selectAll(List<String> allIds) {
    selectedLocationIds
      ..clear()
      ..addAll(allIds);

    totalLocationCount = allIds.length;
    isGlobalSelectAll = true;
    notifyListeners();
  }

  // void clearSelection() {
  //   selectedLocationIds.clear();
  //   isGlobalSelectAll = false;
  //   notifyListeners();
  // }
  void clearSelection() {
    isGlobalSelectAll = false;
    selectedLocationIds.clear();
    excludedLocationIds.clear();
    notifyListeners();
  }

  // void clearSelection() {
  //   // 1️⃣ Clear ID-based selection
  //   selectedLocationIds.clear();
  //   isGlobalSelectAll = false;
  //
  //   // 2️⃣ Reset UI selection flags (for visible pages only)
  //   for (var loc in myLocationList) {
  //     loc.isSelected = false;
  //   }
  //
  //   for (var loc in certifiedLocationList) {
  //     loc.isSelected = false;
  //   }
  //
  //   // 3️⃣ (Optional) clear legacy list if still used elsewhere
  //   selectedLocations.clear();
  //   selectedLocationIds.clear();
  //   // 4️⃣ Notify ONCE
  //   notifyListeners();
  // }

  /// Location profile variables
  List<Subdestination> _subdestinations = [];

  List<Subdestination> get subdestinations => _subdestinations;

  set subdestinations(List<Subdestination> value) {
    _subdestinations = value;
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  bool isHazardProcessed = false;
  MyLocation? selectedLocation;

  bool _isIndividualLocationLoading = false;

  bool get isIndividualLocationLoading => _isIndividualLocationLoading;

  set isIndividualLocationLoading(bool value) {
    _isIndividualLocationLoading = value;
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  int? resetTotalPage;

  Future<void> deleteSelectedLocations1(
    BuildContext context,
    String accountId,
    String subAccountId,
  ) async {
    await deleteLocations1(context, accountId, subAccountId);

    clearSelection();
  }

  // Delete selected locations
  Future<void> deleteSelectedLocations(
    BuildContext context,
    String accountId,
    String subAccountId,
  ) async {
    List<String> idsToDelete = [];
    if (isGlobalSelectAll) {
      idsToDelete = await fetchAllLocationIdsForDelete(
        accountId: accountId,
        subAccountId: subAccountId,
      );
    } else {
      idsToDelete = selectedLocationIds.toList();
    }

    if (idsToDelete.isEmpty) {
      CustomToast.error(context, "No locations found");
      return;
    }

    await deleteLocations(
      context,
      accountId,
      subAccountId,
      '',
      idsToDelete,
      isGlobal: false, // explicit IDs only
    );

    clearSelection();
  }

  Future<List<String>> fetchAllLocationIdsForDelete({
    required String accountId,
    required String subAccountId,
    int pageSize = 1000,
  }) async {
    isDeleteFetchingIds = true;
    notifyListeners();

    final List<String> allIds = [];
    int page = 1;
    bool hasMore = true;

    try {
      while (hasMore) {
        final headers = await CommonHeaders.createHeaders();
        final url =
            "${AppConstant.MY_LOCATION}?account_id=$accountId&sub_account_id=$subAccountId&show_full_list=true";

        final response = await http.get(Uri.parse(url), headers: headers);
        if (response.statusCode != 200) break;

        final jsonResponse = json.decode(response.body);
        final model = MyLocationModel.fromJson(jsonResponse);

        final results = model.results ?? [];
        for (final loc in results) {
          if (loc.id != null) allIds.add(loc.id!);
        }

        final totalRecords = model.totalRecords ?? 0;
        final totalPages = (totalRecords / pageSize).ceil();
        page++;
        hasMore = page <= totalPages;
      }
    } finally {
      isDeleteFetchingIds = false;
      notifyListeners();
    }

    return allIds;
  }

  Future<void> addSelectedToSOV(
      BuildContext context,
      String accountID,
      String subAccountID,
      String accountName,
      String subAccountName,
      TabController? masterTabController,
      [String? locationId]) async {
    await showAddToSOVDialog(context, accountID, subAccountID, accountName,
        subAccountName, masterTabController, locationId);
    clearSelection();
  }

  Future<void> addSelectedToSOV1(
    BuildContext context,
    String accountID,
    String subAccountID,
    String accountName,
    String subAccountName,
    TabController? masterTabController,
    List<String> locationIds,
  ) async {
    // Implement your add to SOV logic here
    // Show pop up with account name an sub account name prefilled an non editable.. and user will select the sov name from autocomplete dropdown and enter comma separated location tags (optional)
    // On submit, call the addLocationToSOV method with the selected sov id and location ids
    await showAddToSOVDialog1(context, accountID, subAccountID, accountName,
        subAccountName, masterTabController, locationIds);
    clearSelection();
  }

  // Add tags to selected locations
  Future<void> addTagsToSelectedLocations(
    BuildContext context,
    String accountId,
    String subAccountId,
  ) async {
    final bool isGlobal = isGlobalSelectAll;

    final List<String> locationIds =
        isGlobal ? <String>[] : selectedLocationIds.toList();

    if (!isGlobal && locationIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select at least one location"),
        ),
      );
      return;
    }

    await showAddTagDialog(
      context,
      accountId,
      subAccountId,
      locationIds,
      isGlobal: isGlobal,
    );

    clearSelection();
  }

  // Future<void> addTagsToSelectedLocations(
  //     BuildContext context, String accountId, String subAccountId,
  //     [String? locationId]) async {
  //   // get the list of ids
  //   await showAddTagDialog(
  //       context,
  //       accountId,
  //       subAccountId,
  //       locationId == null
  //           ? _selectedLocations.map((location) => location.id ?? "").toList()
  //           : [locationId]);
  //
  //   clearSelection();
  // }

  Future<void> addLocationToSOV(
      BuildContext context, Map<String, dynamic> body) async {
    // Your logic for adding a location to SOV
    log("Adding location to SOV: $body");
    isAddToSOVLoading = true;
    try {
      ApiService apiService = ApiService(AppConstant.ADD_TO_SOV);
      var response = await apiService.post(body);
      log(response.toString());
      CustomToast.success(context, response['message']);
      Navigator.pop(context);
    } on BackendException catch (e, stackTrace) {
      log("Error adding location to SOV: ${e.message}");
      log(stackTrace.toString());
      Navigator.pop(context);
      CustomToast.error(context, e.message);
    } catch (e, stackTrace) {
      log("Error adding location to SOV: $e");
      log(e.toString());
      log(stackTrace.toString());
      Navigator.pop(context);
      CustomToast.error(context, e.toString());
    } finally {
      isAddToSOVLoading = false;
    }
  }

  Future<Map<String, dynamic>?> addCommentsLocation(
      BuildContext context, String locationId, String comment) async {
    try {
      isAddTagsLoading = true;
      ApiService apiService = ApiService(AppConstant.ADD_COMMENT);

      var body = {
        "location_id": locationId,
        "comment": comment,
      };

      var response = await apiService.post(body);
      log(response.toString());

      if (response['message'] != null) {
        CustomToast.success(context, response['message']);
      }

      // ✅ Return full API response to the caller
      return response;
    } on BackendException catch (e, stackTrace) {
      log("Error adding tags to location: ${e.message}");
      log(stackTrace.toString());
      CustomToast.error(context, e.message);
      return null;
    } catch (e, stackTrace) {
      log("Error adding tags to location: $e");
      log(stackTrace.toString());
      return null;
    } finally {
      isAddTagsLoading = false;
    }
  }

  // Future<void> addCommentsLocation(
  //     BuildContext context, String locationId, String comment) async {
  //   try {
  //     isAddTagsLoading = true;
  //     ApiService apiService = ApiService(AppConstant.ADD_COMMENT);
  //     var body = {
  //       "location_id": locationId,
  //       "comment": comment,
  //     };
  //     var response = await apiService.post(body);
  //     log(response.toString());
  //     CustomToast.success(context, response['message']);
  //   } on BackendException catch (e, stackTrace) {
  //     log("Error adding tags to location: ${e.message}");
  //     log(stackTrace.toString());
  //     CustomToast.error(context, e.message);
  //   } catch (e, stackTrace) {
  //     log("Error adding tags to location: $e");
  //     log(e.toString());
  //     log(stackTrace.toString());
  //   } finally {
  //     isAddTagsLoading = false;
  //   }
  // }

  // Add Tags to location
  Future<void> addTagsToLocation(
    BuildContext context,
    String accountId,
    String subAccountId,
    List<String> locationId,
    List<String> tags, {
    required bool isGlobal,
  }) async {
    try {
      isAddTagsLoading = true;
      notifyListeners();

      final dio = Dio();
      final headers = await CommonHeaders.createHeaders();

      final body = {
        "data": {
          "account_id": accountId,
          "sub_account_id": subAccountId,
          "tags": tags,
          if (!isGlobal) "location_list": locationId,
        }
      };

      final response = await dio.post(
        "${AppConstant.MY_LOCATION}/tags",
        data: body,
        options: Options(
          headers: headers,
          contentType: Headers.jsonContentType,
        ),
      );

      log("ADD TAG RESPONSE → ${response.data}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        CustomToast.success(
          context,
          response.data?['message'] ?? "Tags added successfully",
        );
      } else {
        CustomToast.error(
          context,
          response.data?['message'] ?? "Failed to add tags",
        );
      }
    } on DioException catch (e, stackTrace) {
      log("DIO ERROR ADD TAG → ${e.response?.data}");
      log(stackTrace.toString());

      CustomToast.error(
        context,
        e.response?.data?['message'] ?? "Something went wrong",
      );
    } catch (e, stackTrace) {
      log("UNKNOWN ERROR ADD TAG → $e");
      log(stackTrace.toString());

      CustomToast.error(context, "Something went wrong");
    } finally {
      isAddTagsLoading = false;
      notifyListeners();
    }
  }

  // Future<void> addTagsToLocation(
  //   BuildContext context,
  //   String accountId,
  //   String subAccountId,
  //   List<String> locationId,
  //   List<String> tags, {
  //   required bool isGlobal,
  // }) async {
  //   try {
  //     isAddTagsLoading = true;
  //     notifyListeners();
  //
  //     ApiService apiService = ApiService("${AppConstant.MY_LOCATION}/tags");
  //
  //     final Map<String, dynamic> body = {
  //       "data": {
  //         "account_id": accountId,
  //         "sub_account_id": subAccountId,
  //         "tags": tags,
  //         if (isGlobal) "select_all": true,
  //         if (!isGlobal) "location_list": locationId,
  //       }
  //     };
  //
  //     final response = await apiService.post(body);
  //     log(response.toString());
  //
  //     CustomToast.success(context, response['message']);
  //   } on BackendException catch (e, stackTrace) {
  //     log("Error adding tags to location: ${e.message}");
  //     log(stackTrace.toString());
  //     CustomToast.error(context, e.message);
  //   } catch (e, stackTrace) {
  //     log("Error adding tags to location: $e");
  //     log(stackTrace.toString());
  //     CustomToast.error(context, "Something went wrong");
  //   } finally {
  //     isAddTagsLoading = false;
  //     notifyListeners();
  //   }
  // }

  // Future<void> addTagsToLocation(BuildContext context, String accountId,
  //     String subAccountId, List<String> locationId, List<String> tags) async {
  //   try {
  //     isAddTagsLoading = true;
  //     ApiService apiService = ApiService(AppConstant.MY_LOCATION + "/tags");
  //     var body = {
  //       "data": {
  //         "account_id": accountId,
  //         "sub_account_id": subAccountId,
  //         "location_list": locationId,
  //         "tags": tags
  //       }
  //     };
  //     var response = await apiService.post(body);
  //     log(response.toString());
  //     CustomToast.success(context, response['message']);
  //     Navigator.pop(context);
  //   } on BackendException catch (e, stackTrace) {
  //     log("Error adding tags to location: ${e.message}");
  //     log(stackTrace.toString());
  //     CustomToast.error(context, e.message);
  //   } catch (e, stackTrace) {
  //     log("Error adding tags to location: $e");
  //     log(e.toString());
  //     log(stackTrace.toString());
  //     // CustomToast.error(context, e.toString());
  //   } finally {
  //     isAddTagsLoading = false;
  //   }
  // }

  // Delete Tags from location
  Future<void> deleteTagFromLocation(BuildContext context, String accountId,
      String subAccountId, String locationId, String tag) async {
    // {{locations_base_url}}/tags/OGUlME8NFKzmesfo3j1S/garden
    try {
      isDeleteTagLoading = true;
      ApiService apiService =
          ApiService("${AppConstant.MY_LOCATION}/tags/$locationId/$tag");
      var response = await apiService.delete({});
      log(response.toString());
      CustomToast.success(context, response['message']);
      Navigator.pop(context);
    } on BackendException catch (e, stackTrace) {
      log("Error deleting tag from location: ${e.message}");
      log(stackTrace.toString());
      CustomToast.error(context, e.message);
    } catch (e, stackTrace) {
      log("Error deleting tag from location: $e");
      log(e.toString());
      log(stackTrace.toString());
      // CustomToast.error(context, e.toString());
    } finally {
      isDeleteTagLoading = false;
    }
  }

  Future<List<MyLocation>> performGlobalSearch(
      BuildContext context, String query) async {
    if (query.isEmpty) {
      searchLocationList = []; // Clear the search results if query is empty
      notifyListeners();
      return [];
    }

    try {
      isSearchLoading = true; // Notify UI that loading has started

      // Construct the API Service for the global search endpoint
      ApiService apiService =
          ApiService('${AppConstant.GLOBAL_SEARCH}?search=$query');

      // Fetch the search results
      final response = await apiService.get();

      if (response.containsKey('result')) {
        // Parse the response and update locationList
        List<MyLocation> searchResults = (response['result'] as List)
            .map((e) => MyLocation.fromJson(e))
            .toList();

        searchLocationList = searchResults; // Update the provider state
        return searchResults;
      } else {
        print("Failed to load search results");
        return [];
      }
    } on BackendException catch (e) {
      //CustomToast.error(context, e.message); // Show error toast
      log("Global search backend error: ${e.message}");
      return [];
    } catch (e) {
      // CustomToast.error(context, "An unexpected error occurred."); // Show generic error
      log("Global search error: $e");
      return [];
    } finally {
      isSearchLoading = false; // Notify UI that loading has stopped
    }
  }

  void updateCampusIds(List<String> campusIds) {
    _campusIds = campusIds;
    notifyListeners();
  }

  // Method to fetch filter options
  Future<void> fetchInitialFilterOptions(
      String accountId, String subAccountId) async {
    final url = Uri.parse(
        "${AppConstant.MY_LOCATION}/filter_options?account_id=$accountId&sub_account_id=$subAccountId");
    print(url);

    try {
      var headers = await CommonHeaders.createHeaders();
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print(data);

        // Update countryList and hazardList from the API response
        countryList = List<String>.from(data['countryList']);
        hazardList = List<String>.from(data['hazardList']);
        campusIds = List<String>.from(data['campusList']);
        print("Country List: $countryList");
        print("Hazard List: $hazardList");
      } else {
        throw Exception("Failed to load filter options");
      }
    } catch (e) {
      print("Error fetching filter options: $e");
    }
  }

  /// Fetch all sov list
  Future<void> fetchAllLocationList(
      BuildContext context, String? accountID, String? subAccountID,
      {String? processId, String? subProcessId}) async {
    print("Sovlist called");
    var typography = CustomTypography(context);
    try {
      isAllLocationLoading = true;

      var headers = await CommonHeaders.createHeaders();
      log(headers.toString());

      var url;
      if (processId != null && subProcessId != null) {
        url = AppConstant.MY_LOCATION +
            "?show_full_list=false&account_id=$accountID&sub_account_id=$subAccountID&process_id=$processId&sub_process_id=$subProcessId";
      } else if (processId != null) {
        url = AppConstant.MY_LOCATION +
            "?show_full_list=false&account_id=$accountID&sub_account_id=$subAccountID&process_id=$processId";
      } else {
        url = AppConstant.MY_LOCATION +
            "?show_full_list=true&account_id=$accountID&sub_account_id=$subAccountID";
      }

      url = AppConstant.MY_LOCATION +
          "?show_full_list=true&account_id=$accountID&sub_account_id=$subAccountID";

      print(url);
      var uri = Uri.parse(url);

      var response = await http.get(
        uri,
        headers: headers,
        //body: body,
      );
      log(response.body);
      print(response.statusCode);

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        // MyLocationModel locationListModel =
        //     MyLocationModel.fromJson(jsonResponse);
        final locationListModel =
            await compute<Map<String, dynamic>, MyLocationModel>(
                MyLocationModel.fromJson, jsonResponse as Map<String, dynamic>);

        //summaryList = locationListModel.summaryList ?? [];
        //mainSovRating = locationListModel. ?? 0.0;

        fullLocationList = locationListModel.results ?? [];

        log(fullLocationList.toString());
      } else {
        print(json.decode(response.body)["error"]);
        throw Exception('Failed to load data');
      }
      isAllLocationLoading = false;
    } on BackendException catch (e, stackTrace) {
      isAllLocationLoading = false;
      print(stackTrace);
      print(e.message);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          e.message,
          style: typography.Body1,
        ),
      ));
    } catch (e, stackTrace) {
      isAllLocationLoading = false;
      print(stackTrace);
      print(e);
      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      //   content: Text(
      //     "Error fetching data",
      //     style: typography.Body1,
      //   ),
      // ));
    }
  }

  // ADD THIS AT TOP OF PROVIDER CLASS
  // int page = 1;
  // int totalPages = 0;
  int totalRecords = 0;

  //
  // List<MyLocation> fullLocationList = [];
  // bool _isFetching = false;

  void setParsedLocationList(List<MyLocation> items) {
    myLocationList = items;
    notifyListeners();
  }

  final Dio dio = Dio(
    BaseOptions(
      connectTimeout: Duration(seconds: 15),
      receiveTimeout: Duration(seconds: 20),
    ),
  );

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
    ),
  );

  Future<void> fetchLocationListMapSov(
    BuildContext context,
    String searchQuery,
    int requestedPage,
    int pageSize,
    String? accountID,
    String? subAccountID,
    String? processId,
    String? subProcessId,
    String? sovID,
  ) async {
    if (_isFetching) return;
    _isFetching = true;

    try {
      if (requestedPage == 1) {
        fullLocationList = [];
        page = 1;
        isLoading = true;
        notifyListeners();
      } else {
        isNextPageLoading = true;
        notifyListeners();
      }

      final headers = await CommonHeaders.createHeaders();

      String url =
          "${AppConstant.MY_LOCATION}?page=$requestedPage&pageSize=$pageSize"
          "&account_id=$accountID&sub_account_id=$subAccountID&show_full_list=true";

      if (sovID != null && sovID.isNotEmpty) {
        url += "&sov_id=$sovID";
      }

      // Dio with increased timeout
      final response = await _dio.get(
        url,
        options: Options(
          headers: headers,
          receiveTimeout: Duration(minutes: 2), // Increase timeout
          sendTimeout: Duration(seconds: 30),
        ),
      );

      if (response.statusCode == 200) {
        // ⚠ FIX: Convert to Map<String, dynamic>
        final jsonResponse = Map<String, dynamic>.from(response.data);

        final locationListModel =
            await compute(parseLocationModel, jsonResponse);

        totalRecords = locationListModel.totalRecords ?? 0;
        totalPages = (totalRecords / pageSize).ceil();
        page = requestedPage;

        if (requestedPage == 1) {
          fullLocationList = locationListModel.results ?? [];
        } else {
          fullLocationList.addAll(locationListModel.results ?? []);
        }

        notifyListeners();
      }
    } catch (e) {
      print("DIO LOCATION ERROR: $e");
    } finally {
      _isFetching = false;
      isLoading = false;
      isNextPageLoading = false;
      notifyListeners();
    }
  }

  // Future<void> fetchLocationListMapSov(
  //   BuildContext context,
  //   String searchQuery,
  //   int requestedPage,
  //   int pageSize,
  //   String? accountID,
  //   String? subAccountID,
  //   String? processId,
  //   String? subProcessId,
  //   String? sovID,
  // ) async {
  //   if (_isFetching) return;
  //   _isFetching = true;
  //
  //   try {
  //     // If first page → clear list
  //     if (requestedPage == 1) {
  //       fullLocationList = [];
  //       page = 1;
  //       isLoading = true;
  //       notifyListeners();
  //     } else {
  //       isNextPageLoading = true;
  //       notifyListeners();
  //     }
  //
  //     // Build URL
  //     var headers = await CommonHeaders.createHeaders();
  //     var url =
  //         "${AppConstant.MY_LOCATION}?page=$requestedPage&pageSize=$pageSize"
  //         "&account_id=$accountID&sub_account_id=$subAccountID &show_full_list=true";
  //
  //     if (sovID != null && sovID.isNotEmpty) {
  //       url += "&sov_id=$sovID";
  //     }
  //
  //     var response = await http.get(Uri.parse(url), headers: headers);
  //
  //     if (response.statusCode == 200) {
  //       var jsonResponse = json.decode(response.body);
  //
  //       final locationListModel =
  //           await compute<Map<String, dynamic>, MyLocationModel>(
  //               MyLocationModel.fromJson, jsonResponse as Map<String, dynamic>);
  //
  //       // READ TOTAL COUNT
  //       totalRecords = locationListModel.totalRecords ?? 0;
  //
  //       // CALCULATE TOTAL PAGES
  //       totalPages = (totalRecords / pageSize).ceil();
  //
  //       // SAVE CURRENT PAGE
  //       page = requestedPage;
  //
  //       // APPEND RESULTS
  //       if (requestedPage == 1) {
  //         fullLocationList = locationListModel.results ?? [];
  //       } else {
  //         fullLocationList.addAll(locationListModel.results ?? []);
  //       }
  //
  //       notifyListeners();
  //     }
  //   } catch (e) {
  //     print("Error fetching locations: $e");
  //   } finally {
  //     _isFetching = false;
  //     isLoading = false;
  //     isNextPageLoading = false;
  //     notifyListeners();
  //   }
  // }

  Future<void> fetchLocationListSov(
    BuildContext context,
    String searchQuery,
    int requestedPage,
    int pageSize,
    String? accountID,
    String? subAccountID,
    String? processId,
    String? subProcessId,
    String? sovID,
  ) async {
    if (_isFetching) return;
    _isFetching = true;

    try {
      // If first page → clear list
      if (requestedPage == 1) {
        fullLocationList = [];
        page = 1;
        isLoading = true;
        notifyListeners();
      } else {
        isNextPageLoading = true;
        notifyListeners();
      }

      // Build URL
      var headers = await CommonHeaders.createHeaders();
      var url =
          "${AppConstant.MY_LOCATION}?page=$requestedPage&pageSize=$pageSize"
          "&account_id=$accountID&sub_account_id=$subAccountID";

      if (sovID != null && sovID.isNotEmpty) {
        url += "&sov_id=$sovID";
      }

      var response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);

        final locationListModel =
            await compute<Map<String, dynamic>, MyLocationModel>(
                MyLocationModel.fromJson, jsonResponse as Map<String, dynamic>);

        // READ TOTAL COUNT
        totalRecords = locationListModel.totalRecords ?? 0;

        // CALCULATE TOTAL PAGES
        totalPages = (totalRecords / pageSize).ceil();

        // SAVE CURRENT PAGE
        page = requestedPage;

        // APPEND RESULTS
        if (requestedPage == 1) {
          fullLocationList = locationListModel.results ?? [];
        } else {
          fullLocationList.addAll(locationListModel.results ?? []);
        }

        notifyListeners();
      }
    } catch (e) {
      print("Error fetching locations: $e");
    } finally {
      _isFetching = false;
      isLoading = false;
      isNextPageLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchLocationList(
    BuildContext context,
    String searchQuery,
    int page,
    int pageSize,
    String? accountID,
    String? subAccountID,
    String? processId,
    String? subProcessId,
    String? sovID,
  ) async {
    if (_isFetching) return; // Prevent multiple concurrent calls
    _isFetching = true;

    try {
      // If requested page is beyond total pages, return early
      if (page > totalPages && totalPages != 0) return;

      if (page == 1) {
        myLocationList = [];
        isLoading = true;
      } else {
        isNextPageLoading = true;
      }
      notifyListeners(); // Update UI for loader

      var headers = await CommonHeaders.createHeaders();

      // Build URL dynamically
      var url = sovID != null && sovID.isNotEmpty
          ? "${AppConstant.MY_LOCATION}?page=$page&pageSize=$pageSize&account_id=$accountID&sub_account_id=$subAccountID&sov_id=$sovID&zip=&search=&sort=&campus_name="
          : "${AppConstant.MY_LOCATION}?page=$page&pageSize=$pageSize&account_id=$accountID&sub_account_id=$subAccountID";

      if (countries.isNotEmpty) url += "&country=${countries.join(',')}";
      if (zipcode.isNotEmpty) url += "&zip=$state";
      if (sortBy.isNotEmpty) url += "&sort=$sortBy";
      if (dataCompletenessScore != null)
        url += "&data_completeness_score=$dataCompletenessScore";
      if (certifications.isNotEmpty) {
        for (var cert in certifications) {
          if (cert == "Manual Certified") url += "&manual_certified=true";
          if (cert == "Auto Certified") url += "&auto_certified=true";
        }
      }
      if (hazardRatings.isNotEmpty)
        url += "&hazard=${jsonEncode(hazardRatings)}";
      if (rating.isNotEmpty) url += "&score=${rating.join(',')}";
      if (_selectedCampusIds.isNotEmpty)
        url += "&campus_id=${_selectedCampusIds.join(',')}";
      if (processId != null) url += "&process_id=$processId";
      if (subProcessId != null) url += "&sub_process_id=$subProcessId";

      var uri = Uri.parse(url);
      var response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        // MyLocationModel locationListModel =
        //     MyLocationModel.fromJson(jsonResponse);
        final locationListModel =
            await compute<Map<String, dynamic>, MyLocationModel>(
                MyLocationModel.fromJson, jsonResponse as Map<String, dynamic>);

        locationHits = locationListModel.totalRecords ?? 0;
        certifiedLocationHits = locationListModel.totalCertified ?? 0;
        isConflict = locationListModel.isConflict ?? false;
        isHazardCanStart = locationListModel.isHazardCanStart ?? false;
        isAnyLocationSelected =
            locationListModel.isAnyHazardProcessing ?? false;

        // Calculate total pages
        totalPages = (locationHits / pageSize).ceil();

        if (page == 1) {
          myLocationList = locationListModel.results ?? [];
          grapDataProfile = locationListModel.graphData;
          locationcount = locationListModel.totalRecords ?? 0;
        } else {
          // Append next page results
          addToMyLocationList(locationListModel.results ?? []);
        }
      } else {
        var errorMsg =
            json.decode(response.body)["error"] ?? "Failed to load data";
        throw Exception(errorMsg);
      }
    } catch (e, stackTrace) {
      print("Error fetching locations: $e");
      print(stackTrace);
    } finally {
      // Reset loading flags
      isLoading = false;
      isNextPageLoading = false;
      _isFetching = false;
      notifyListeners();
    }
  }

  Future<void> fetchLocationList1(
    BuildContext context,
    int page,
    int pageSize,
    String? accountID,
    String? subAccountID,
    String? processId,
    String? subProcessId,
    String? sovID,
  ) async {
    if (_isFetching) return; // Prevent multiple concurrent calls
    _isFetching = true;

    try {
      // If requested page is beyond total pages, return early
      if (page > totalPages && totalPages != 0) return;

      if (page == 1) {
        overallLocationList = [];
        isLoading = true;
      } else {
        isNextPageLoading = true;
      }
      notifyListeners(); // Update UI for loader

      var headers = await CommonHeaders.createHeaders();

      // Build URL dynamically
      var url = sovID != null && sovID.isNotEmpty
          ? "${AppConstant.MY_LOCATION}?page=$page&pageSize=$pageSize&account_id=$accountID&sub_account_id=$subAccountID&sov_id=$sovID&zip=&search=&sort=&campus_name="
          : "${AppConstant.MY_LOCATION}?page=$page&pageSize=$pageSize&account_id=$accountID&sub_account_id=$subAccountID";

      if (countries.isNotEmpty) url += "&country=${countries.join(',')}";
      if (zipcode.isNotEmpty) url += "&zip=$state";
      if (sortBy.isNotEmpty) url += "&sort=$sortBy";
      if (certifications.isNotEmpty) {
        for (var cert in certifications) {
          if (cert == "Manual Certified") url += "&manual_certified=true";
          if (cert == "Auto Certified") url += "&auto_certified=true";
        }
      }
      if (hazardRatings.isNotEmpty)
        url += "&hazard=${jsonEncode(hazardRatings)}";
      if (rating.isNotEmpty) url += "&score=${rating.join(',')}";
      if (_selectedCampusIds.isNotEmpty)
        url += "&campus_id=${_selectedCampusIds.join(',')}";
      if (processId != null) url += "&process_id=$processId";
      if (subProcessId != null) url += "&sub_process_id=$subProcessId";

      var uri = Uri.parse(url);
      var response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        // MyLocationModel locationListModel =
        //     MyLocationModel.fromJson(jsonResponse);
        final locationListModel =
            await compute<Map<String, dynamic>, MyLocationModel>(
                MyLocationModel.fromJson, jsonResponse as Map<String, dynamic>);
        isAnyLocationSelected =
            locationListModel.isAnyHazardProcessing ?? false;

        // Calculate total pages
        totalPages = (locationHits / pageSize).ceil();

        if (page == 1) {
          overallLocationList = locationListModel.results ?? [];
        } else {
          // Append next page results
          addToMyLocationList(locationListModel.results ?? []);
        }
      } else {
        var errorMsg =
            json.decode(response.body)["error"] ?? "Failed to load data";
        throw Exception(errorMsg);
      }
    } catch (e, stackTrace) {
      print("Error fetching locations: $e");
      print(stackTrace);
    } finally {
      // Reset loading flags
      isLoading = false;
      isNextPageLoading = false;
      _isFetching = false;
      notifyListeners();
    }
  }

  Future<void> fetchLocationConflictList(
      BuildContext context,
      String searchQuery,
      int page,
      int pageSize,
      String? accountID,
      String? subAccountID,
      String? processId,
      String? subProcessId,
      [String? sovID]) async {
    if (_isFetching) return; // Prevent multiple concurrent calls
    _isFetching = true;

    var typography = CustomTypography(context);
    try {
      if (page - 1 > totalPages) return;

      if (page == 1) {
        myLocationConflictList = [];
        isLoading = true;
      } else {
        isNextPageLoading = true;
      }

      var headers = await CommonHeaders.createHeaders();
      log(headers.toString());

      var url;
      if (sovID != null) {
        url =
            "${AppConstant.MY_LOCATION}?page=$page&pageSize=$pageSize&account_id=$accountID&show_full_list=true&conflicts=true&sub_account_id=$subAccountID&sov_id=$sovID";
      } else {
        url =
            "${AppConstant.MY_LOCATION}?page=$page&pageSize=$pageSize&account_id=$accountID&sub_account_id=$subAccountID&conflicts=true&show_full_list=true";
      }

      if (countries.isNotEmpty) url += "&country=${countries.join(',')}";
      if (zipcode.isNotEmpty) url += "&zip=$state";
      if (sortBy.isNotEmpty) url += "&sort=$sortBy";
      if (certifications.isNotEmpty) {
        for (var cert in certifications) {
          if (cert == "Manual Certified") url += "&manual_certified=true";
          if (cert == "Auto Certified") url += "&auto_certified=true";
        }
      }
      if (hazardRatings.isNotEmpty)
        url += "&hazard=${jsonEncode(hazardRatings)}";
      if (rating.isNotEmpty) url += "&score=${rating.join(',')}";
      if (_selectedCampusIds.isNotEmpty)
        url += "&campus_id=${_selectedCampusIds.join(',')}";
      if (processId != null) url += "&process_id=$processId";
      if (subProcessId != null) url += "&sub_process_id=$subProcessId";

      print(url);
      var uri = Uri.parse(url);

      var response = await http.get(uri, headers: headers);
      // log(response.body);
      // print(response.statusCode);

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        // MyLocationModel locationListModel =
        //     MyLocationModel.fromJson(jsonResponse);
        final locationListModel =
            await compute<Map<String, dynamic>, MyLocationModel>(
                MyLocationModel.fromJson, jsonResponse as Map<String, dynamic>);
        // locationHits = locationListModel.totalRecords ?? 0;
        // certifiedLocationHits = locationListModel.totalCertified ?? 0;
        isConflict = locationListModel.isConflict!;
        isHazardCanStart = locationListModel.isHazardCanStart!;
        isAnyLocationSelected = locationListModel.isAnyHazardProcessing!;
        totalPages = locationHits ~/ pageSize;

        if (page == 1) {
          myLocationConflictList = locationListModel.results ?? [];
        } else {
          addToMyLocationList(locationListModel.results ?? []);
        }

        log(myLocationConflictList.toString());
        print("totalPages: $totalPages");
        // log(page.toString());
      } else {
        print(json.decode(response.body)["error"]);
        throw Exception('Failed to load data');
      }
    } on BackendException catch (e, stackTrace) {
      print(stackTrace);
      print(e.message);
    } catch (e, stackTrace) {
      print(stackTrace);
    } finally {
      isLoading = false;
      isNextPageLoading = false;
      _isFetching = false; // Release the fetch lock
      notifyListeners(); // Notify UI only once at the end
    }
  }

  UserManagementResponse? userManagement;

  Future<void> fetchUserManagement() async {
    final url = Uri.parse(
      "https://us-central1-project-green-r5-1-qa.cloudfunctions.net/user_management?current_role=true&current_user=true",
    );

    try {
      final headers = await CommonHeaders.createHeaders();
      final response = await http.get(url, headers: headers);

      print("RAW API RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        userManagement = await compute(parseUserManagement, response.body);

        // print("User Name: ${userManagement?.user.roles.first.name}");
        // print("Can Edit SOV: ${userManagement?.user.roles.first.sovOperations.edit}");
      } else {
        print("Failed to load user roles");
        throw Exception("Failed to load user management data");
      }
    } catch (e, stacktrace) {
      print("Error fetching User Management: $e");
      print(stacktrace);
    }
  }

  /// Fetch sov list with pagination, search query, and filters
  Future<void> fetchCertifiedLocationList(
    BuildContext context,
    String searchQuery,
    int page,
    int pageSize,
    String? accountID,
    String? subAccountID,
    String? processId,
    String? subProcessId, [
    String? sovID,
  ]) async {
    try {
      // Stop extra page calls
      if (page > certifiedTotalPages && page != 1) return;

      if (page == 1) {
        isCertifiedLoading = true;
        certifiedLocationList = []; // <--- ADD THIS
      } else {
        isNextPageCertifiedLoading = true;
      }
      notifyListeners();
      var headers = await CommonHeaders.createHeaders();

      var url =
          "${AppConstant.MY_LOCATION}?page=$page&pageSize=$pageSize&score=5&account_id=$accountID&sub_account_id=$subAccountID";

      if (sovID != null) url += "&sov_id=$sovID";
      if (countries.isNotEmpty) url += "&country=${countries.join(",")}";

      if (certifications.isNotEmpty) {
        if (certifications.contains("Manual Certified")) {
          url += "&manual_certified=true";
        }
        if (certifications.contains("Auto Certified")) {
          url += "&auto_certified=true";
        }
      }

      if (hazardRatings.isNotEmpty) {
        for (var hazard in hazardRatings.keys) {
          url += "&hazard=${jsonEncode(hazardRatings[hazard])}";
        }
      }

      if (processId != null) url += "&process_id=$processId";
      if (subProcessId != null) url += "&sub_process_id=$subProcessId";

      var response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        final locationListModel = await compute(
            parseMyLocationModel, jsonResponse as Map<String, dynamic>);

        // FIX: Use totalPages from API
        int totalItems = locationListModel.totalCertified ?? 0;
        certifiedTotalPages = (totalItems / pageSize).ceil();

        if (page == 1) {
          certifiedLocationList = locationListModel.results ?? [];
        } else {
          certifiedLocationList.addAll(locationListModel.results ?? []);
        }
      }

      isCertifiedLoading = false;
      isNextPageCertifiedLoading = false;
      notifyListeners();
    } catch (e) {
      isCertifiedLoading = false;
      isNextPageCertifiedLoading = false;
      notifyListeners();
    }
  }

  // Future<void> fetchCertifiedLocationList(
  //     BuildContext context,
  //     String searchQuery,
  //     int page,
  //     int pageSize,
  //     String? accountID,
  //     String? subAccountID,
  //     String? processId,
  //     String? subProcessId,
  //     [String? sovID]) async {
  //   var typography = CustomTypography(context);
  //   try {
  //     print("Condition: Certified fetch with rating 5");
  //     print("Rating: 5");
  //     print(sovID.toString());
  //
  //     if (page - 1 > certifiedTotalPages) return;
  //     if (page == 1) {
  //       isCertifiedLoading = true;
  //     } else {
  //       isNextPageCertifiedLoading = true;
  //     }
  //
  //     var headers = await CommonHeaders.createHeaders();
  //     log(headers.toString());
  //
  //     // Construct the URL with default rating=5
  //     var url;
  //     if (sovID != null) {
  //       url = AppConstant.MY_LOCATION +
  //           "?page=$page&pageSize=$pageSize&score=5&account_id=$accountID&sub_account_id=$subAccountID&sov_id=$sovID";
  //     } else {
  //       url = AppConstant.MY_LOCATION +
  //           "?page=$page&pageSize=$pageSize&score=5&account_id=$accountID&sub_account_id=$subAccountID";
  //     }
  //
  //     if (countries.isNotEmpty) {
  //       url += "&country=${countries.join(",")}";
  //     }
  //     if (zipcode.isNotEmpty) {
  //       url += "&zip=$state";
  //     }
  //     print("Certifications: $certifications");
  //
  //     if (certifications.isNotEmpty) {
  //       for (var cert in certifications) {
  //         if (cert == "Manual Certified") {
  //           url += "&manual_certified=true";
  //         } else if (cert == "Auto Certified") {
  //           url += "&auto_certified=true";
  //         }
  //       }
  //     }
  //     print("Hazard Ratings: $hazardRatings");
  //     if (hazardRatings.isNotEmpty) {
  //       for (var hazard in hazardRatings.keys) {
  //         url += "&hazard=${jsonEncode(hazardRatings[hazard])}";
  //       }
  //     }
  //
  //     if (_selectedCampusIds.isNotEmpty) {
  //       url += "&campus_id=${_selectedCampusIds.join(",")}";
  //     }
  //
  //     if (processId != null) {
  //       url += "&process_id=$processId";
  //     }
  //
  //     if (subProcessId != null) {
  //       url += "&sub_process_id=$subProcessId";
  //     }
  //
  //     print(url);
  //     var uri = Uri.parse(url);
  //
  //     var response = await http.get(uri, headers: headers);
  //     print(response.body);
  //     print(response.statusCode);
  //
  //     if (response.statusCode == 200) {
  //       var jsonResponse = json.decode(response.body);
  //       // MyLocationModel locationListModel =
  //       //     MyLocationModel.fromJson(jsonResponse);
  //       final locationListModel =
  //           await compute<Map<String, dynamic>, MyLocationModel>(
  //               MyLocationModel.fromJson, jsonResponse as Map<String, dynamic>);
  //       certifiedLocationHits = locationListModel.totalCertified ?? 0;
  //       totalPages = locationListModel.totalRecords ?? 1;
  //
  //       print(totalPages.toString());
  //       //summaryList = locationListModel.summaryList ?? [];
  //       if (page == 1) {
  //         certifiedLocationList = locationListModel.results ?? [];
  //       } else {
  //         addToCertifiedLocationList(locationListModel.results ?? []);
  //       }
  //       log(certifiedLocationList.toString());
  //
  //     } else {
  //       print(json.decode(response.body)["error"]);
  //       throw Exception('Failed to load data');
  //     }
  //     isCertifiedLoading = false;
  //     isNextPageCertifiedLoading = false;
  //   } on BackendException catch (e, stackTrace) {
  //     isCertifiedLoading = false;
  //     isNextPageCertifiedLoading = false;
  //     print(stackTrace);
  //     print(e.message);
  //     // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
  //     //   content: Text(
  //     //     e.message,
  //     //     style: typography.Body1,
  //     //   ),
  //     // ));
  //   } catch (e, stackTrace) {
  //     isCertifiedLoading = false;
  //     isNextPageCertifiedLoading = false;
  //     print(stackTrace);
  //     // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
  //     //   content: Text(
  //     //     e.toString(),
  //     //     style: typography.Body1,
  //     //   ),
  //     // ));
  //   }
  // }

  // Add this method for deleting locations
  Future<void> deleteLocations(BuildContext context, String accountId,
      String subAccountId, String sovId, List<String> locationList,
      {bool isGlobal = false}) async {
    try {
      isDeleteLocationLoading = true;
      notifyListeners();

      final headers = await CommonHeaders.createHeaders();

      late String body;

      if (isGlobal) {
        body = json.encode({
          "data": {
            "account_id": accountId,
            "sub_account_id": subAccountId,
            "select_all": true,
            if (sovId.isNotEmpty) "sov_id": sovId,
            if (sovId.isNotEmpty) "from_location_list": false,
          }
        });
      } else if (sovId.isEmpty) {
        body = json.encode({
          "data": locationList.map((locationId) {
            return {
              "location_id": locationId,
            };
          }).toList(),
        });
      } else {
        body = json.encode({
          "data": locationList.map((locationId) {
            return {
              "location_id": locationId,
              "account_id": accountId,
              "sub_account_id": subAccountId,
              "sov_id": sovId,
              "from_location_list": false,
            };
          }).toList(),
        });
      }

      debugPrint("DELETE BODY => $body");

      final url =
          Uri.parse("${AppConstant.MY_LOCATION}?from_location_list=true");

      final response = await http.delete(
        url,
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final message =
            jsonDecode(response.body)?["message"] ?? "Deleted successfully";

        CustomToast.success(context, message);
        if (!isGlobal) {
          for (final locationId in locationList) {
            _myLocationList.removeWhere(
              (location) => location.id == locationId,
            );
          }

          locationHits = (_myLocationList.length).clamp(0, locationHits);
        }

        notifyListeners();
      } else {
        final error = jsonDecode(response.body)?["message"] ?? "Delete failed";
        CustomToast.error(context, error);
      }
    } catch (e, stackTrace) {
      debugPrint("DELETE ERROR: $e");
      debugPrint(stackTrace.toString());
      CustomToast.error(context, "Error deleting locations");
    } finally {
      isDeleteLocationLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteLocations1(
    BuildContext context,
    String accountId,
    String subAccountId,
  ) async {
    try {
      isDeleteLocationLoading = true;

      var headers = await CommonHeaders.createHeaders();

      // Prepare the body as a list of objects with individual location_id
      var body;

      body = json.encode({
        "data": {
          "account_id": accountId,
          "sub_account_id": subAccountId,
        }
      });

      print(body);

      // URL with the parameter from_location_list=true
      var url = Uri.parse(AppConstant.MY_LOCATION + "?from_location_list=true");
      log(url.toString());

      // Make the DELETE request
      var response = await http.delete(
        url,
        headers: headers,
        body: body,
      );
      print(response.body);

      if (response.statusCode == 200) {
        log("Locations deleted successfully.");
        CustomToast.success(
            context, jsonDecode(response.body)?["message"] ?? "Success");

        // locationList.forEach((locationId) {
        //
        //   if (_myLocationList.any((location) => location.id == locationId)) {
        //     // Decrement the hit counter if the location exists
        //     locationHits--;
        //     _myLocationList
        //         .removeWhere((location) => location.id == locationId);
        //   }
        // });
        notifyListeners();
      } else {
        log("Failed to delete locations: ${response.body}");
        CustomToast.error(context, jsonDecode(response.body)["message"]);
      }
      isDeleteLocationLoading = false;
    } on BackendException catch (e) {
      isDeleteLocationLoading = false;
      log("Error deleting locations: ${e.message}");
      CustomToast.error(context, jsonDecode(e.message));
      throw e;
    } catch (e) {
      isDeleteLocationLoading = false;
      log("Error deleting locations: $e");
      CustomToast.error(context, "Error deleting locations: $e");
      throw e;
    } finally {
      isDeleteLocationLoading = false;
    }
  }

  // Add Location
  Future<bool> addLocation(
    BuildContext context,
    String accountId,
    String subAccountId,
    String sovId,
    Map<String, dynamic> body,
  ) async {
    try {
      isAddLocationLoading = true;
      ApiService apiService = ApiService(
          "${AppConstant.GET_LOCATION_PROFILE_NEW + "/addlocation"}");
      var response = await apiService.post(body);
      log(response.toString());
      CustomToast.success(context, response['message']);
      Navigator.pop(context);
      isAddLocationLoading = false;
      return true;
    } on BackendException catch (e) {
      isAddLocationLoading = false;
      // CustomToast.error(context, e.message);
      return false;
    } catch (e) {
      isAddLocationLoading = false;
      // CustomToast.error(context, e.toString());
      return false;
    }
  }

  // Fetch Main Tile Providers URLs for each hazards and respective vendors
  Future<void> fetchMainTileProviders(BuildContext context) async {
    try {
      isMainTileProvidersLoading = true;
      ApiService apiService =
          ApiService(AppConstant.MAIN_HAZARDS_TILE_PROVIDERS);
      var response = await apiService.get();
      log(response.toString());
      mainHazardData = response;
    } on BackendException catch (e, stack) {
      log("Error fetching main tile providers: ${e.message}");
      print(stack);
      CustomToast.error(context, e.message);
    } catch (e, stack) {
      log("Error fetching main tile providers: $e");
      print(stack);
    } finally {
      isMainTileProvidersLoading = false;
    }
  }

  // Generate Heatmap
  Future<Map<String, dynamic>?> generateHeatMapForLocationsGeocoding(
      BuildContext context,
      String accountId,
      String subAccountId,
      bool isGeocoding,
      bool regenerate,
      [String? sovId]) async {
    isHeatMapGenerating = true;
    try {
      ApiService apiService =
          ApiService("${AppConstant.MY_LOCATION}/generateheatmap");
      final body = {
        "data": {
          "account_id": accountId,
          "sub_account_id": subAccountId,
          "sov_id": sovId == null || sovId.isEmpty ? false : true,
          "is_geocoding": isGeocoding,
          "is_all_locations": true,
          "regenerate": regenerate,
        }
      };

      print(body);
      var response = await apiService.post(body);
      log("Heatmap generation response: ${response.toString()}");

      // Assuming the response is JSON and can be parsed to a Map
      final Map<String, dynamic> responseData = response;
      //Navigator.pop(context);

      if (isGeocoding) {
        geocodingData = responseData;
      } else {
        hazardData = responseData;
      }

      return responseData; // Return the parsed response data
    } on BackendException catch (e, stack) {
      log("BackendException in heatmap generation: ${e.message}");
      print(stack);
      return null; // Return null in case of BackendException
    } catch (e, stack) {
      log("Exception in heatmap generation: $e");
      print(stack);
      return null; // Return null in case of other errors
    } finally {
      isHeatMapGenerating = false; // Ensuring state is reset
    }
  }

  Future<void> showAddToSOVDialog(
      BuildContext context,
      String accountID,
      String subAccountID,
      String accountName,
      String subAccountName,
      TabController? masterTabController,
      [String? locationId]) async {
    var typography = CustomTypography(context);
    TextEditingController sovController = TextEditingController();
    TextEditingController tagsController = TextEditingController();
    String selectedSovId =
        ""; // To hold the SoV ID when user selects from autocomplete

    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Add to SoV",
                      style: typography.H5_Regular,
                    ),
                    SizedBox(height: 16.0),
                    // Account Name (Pre-filled and non-editable)
                    TextField(
                      controller: TextEditingController(text: accountName),
                      enabled: false,
                      decoration: InputDecoration(
                        labelText: "Account Name",
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 8.0),
                    // Sub-account Name (Pre-filled and non-editable)
                    TextField(
                      controller: TextEditingController(text: subAccountName),
                      enabled: false,
                      decoration: InputDecoration(
                        labelText: "Sub-account Name",
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 8.0),
                    // SoV Autocomplete Dropdown
                    Consumer<SOVListProvider>(
                      builder: (context, sovProvider, child) {
                        return Column(
                          children: [
                            TextField(
                              controller: sovController,
                              onChanged: (value) {
                                setState(() {
                                  // Reset SoV ID when typing
                                  selectedSovId = "";

                                  // Filter the autocomplete list based on user input
                                  sovProvider.updateFilteredList(value);
                                });
                              },
                              decoration: InputDecoration(
                                labelText: "Name of the SoV",
                                border: const OutlineInputBorder(),
                                suffixIcon: Icon(Icons.search),
                              ),
                            ),
                            if (sovController.text.isNotEmpty)
                              AutocompleteOptionsSovs(
                                options: sovProvider.filteredAutoCompleteList,
                                onSelected: (Result selection) {
                                  setState(() {
                                    selectedSovId = selection.sovId ?? "";
                                    sovController.text = selection.name ?? "";
                                    sovProvider.clearAutoCompleteList();
                                  });
                                },
                                isLoading: sovProvider.isAutoCompleteLoading,
                              ),
                          ],
                        );
                      },
                    ),
                    /*
                    SizedBox(height: 8.0),
                    // Comma-separated Tags (Optional)
                    TextField(
                      controller: tagsController,
                      decoration: InputDecoration(
                        labelText: "Enter comma-separated tags (optional)",
                        border: const OutlineInputBorder(),
                      ),
                    ),*/
                    SizedBox(height: 16.0),
                    // Add/Cancel Buttons
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: isAddToSOVLoading
                                  ? const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                  : CustomButton(
                                      onPressed: () async {
                                        if (sovController.text.isEmpty) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                "Please select or enter an SoV name.",
                                                style: typography.Body1,
                                              ),
                                            ),
                                          );
                                          return;
                                        }

                                        setState(() {
                                          isAddToSOVLoading =
                                              true; // 🔹 Show loader
                                        });

                                        try {
                                          // Prepare the body
                                          Map<String, dynamic> body = {
                                            "location_list": locationId == null
                                                ? _selectedLocations
                                                    .map((location) =>
                                                        location.id)
                                                    .toList()
                                                : [locationId],
                                            "account_id": accountID,
                                            "sub_account_id": subAccountID,
                                            "sov": {
                                              "sov_id": selectedSovId,
                                              "sov_name": sovController.text,
                                            }
                                          };

                                          // 🔹 Perform async operation
                                          await addLocationToSOV(context, body);

                                          // 🔹 After success, navigate or perform next action
                                          setState(() {
                                            masterTabController?.animateTo(0);
                                          });
                                        } catch (e) {
                                          // 🔹 Handle errors
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content: Text("Error: $e")),
                                          );
                                        } finally {
                                          // 🔹 Always hide loader
                                          setState(() {
                                            isAddToSOVLoading = false;
                                          });
                                        }
                                      },
                                      child: Text(
                                        "Add",
                                        style: typography.ButtonLargeBlack,
                                      ),
                                      type: ButtonType.elevated,
                                    ),
                            )

                            // Expanded(
                            //   child: isAddToSOVLoading
                            //       ? Center(
                            //           child: CircularProgressIndicator(),
                            //         )
                            //       : CustomButton(
                            //           onPressed: () async {
                            //             if (sovController.text.isEmpty) {
                            //               ScaffoldMessenger.of(context)
                            //                   .showSnackBar(SnackBar(
                            //                 content: Text(
                            //                   "Please select or enter an SoV name.",
                            //                   style: typography.Body1,
                            //                 ),
                            //               ));
                            //               return;
                            //             }
                            //
                            //             // Prepare the body with location, account, sub-account, and sov details
                            //             Map<String, dynamic> body = {
                            //               "location_list": locationId == null
                            //                   ? _selectedLocations
                            //                       .map(
                            //                           (location) => location.id)
                            //                       .toList()
                            //                   : [locationId],
                            //               "account_id": accountID,
                            //               "sub_account_id": subAccountID,
                            //               "sov": {
                            //                 "sov_id": selectedSovId,
                            //                 // Empty if creating new SoV
                            //                 "sov_name": sovController.text,
                            //                 // Mandatory if creating new SoV
                            //               }
                            //             };
                            //
                            //             // Call your method to add the location to the SoV
                            //             await addLocationToSOV(context, body);
                            //
                            //             setState(() {
                            //               masterTabController?.animateTo(1);
                            //             });
                            //           },
                            //           child: Text(
                            //             "Add",
                            //             style: typography.ButtonLargeBlack,
                            //           ),
                            //           type: ButtonType.elevated,
                            //         ),
                            // ),
                          ],
                        ),
                        SizedBox(width: 8.0),
                        CustomButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text(
                            "Cancel",
                            style: typography.ButtonLarge,
                          ),
                          type: ButtonType.text,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      // Clear the input fields after dialog is closed
      sovController.clear();
      tagsController.clear();
      selectedSovId = "";
    });
  }

  Future<void> showAddToSOVDialog1(
    BuildContext context,
    String accountID,
    String subAccountID,
    String accountName,
    String subAccountName,
    TabController? masterTabController,
    List<String> locationIds,
  ) async {
    var typography = CustomTypography(context);
    TextEditingController sovController = TextEditingController();
    TextEditingController tagsController = TextEditingController();
    String selectedSovId = "";

    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Add to SoV", style: typography.H5_Regular),
                    SizedBox(height: 16),

                    // Account name
                    TextField(
                      controller: TextEditingController(text: accountName),
                      enabled: false,
                      decoration: InputDecoration(
                        labelText: "Account Name",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 8),

                    // Sub account name
                    TextField(
                      controller: TextEditingController(text: subAccountName),
                      enabled: false,
                      decoration: InputDecoration(
                        labelText: "Sub-account Name",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 8),

                    // SoV Autocomplete
                    Consumer<SOVListProvider>(
                      builder: (context, sovProvider, child) {
                        return Column(
                          children: [
                            TextField(
                              controller: sovController,
                              onChanged: (value) {
                                selectedSovId = "";
                                sovProvider.updateFilteredList(value);
                              },
                              decoration: InputDecoration(
                                labelText: "Name of the SoV",
                                border: OutlineInputBorder(),
                                suffixIcon: Icon(Icons.search),
                              ),
                            ),

                            // dropdown list
                            if (sovController.text.isNotEmpty)
                              AutocompleteOptionsSovs(
                                options: sovProvider.filteredAutoCompleteList,
                                isLoading: sovProvider.isAutoCompleteLoading,
                                onSelected: (Result selection) {
                                  setState(() {
                                    selectedSovId = selection.sovId ?? "";
                                    sovController.text = selection.name ?? "";
                                    sovProvider.clearAutoCompleteList();
                                  });
                                },
                              ),
                          ],
                        );
                      },
                    ),

                    SizedBox(height: 16),

                    // Add + Cancel buttons
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Consumer<MyLocationListProvider>(
                              builder: (context, provider, _) {
                                return provider.isAddToSOVSubmitting
                                    ? const Center(
                                        child: CircularProgressIndicator())
                                    : CustomButton(
                                        onPressed: () async {
                                          if (sovController.text.isEmpty) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                  content: Text(
                                                      "Please select an SoV")),
                                            );
                                            return;
                                          }

                                          try {
                                            provider.setSubmitting(true);

                                            final body = {
                                              "location_list": locationIds,
                                              // already passed in
                                              "account_id": accountID,
                                              "sub_account_id": subAccountID,
                                              "sov": {
                                                "sov_id": selectedSovId,
                                                "sov_name": sovController.text,
                                              }
                                            };

                                            await provider.addLocationToSOV(
                                                context, body);

                                            masterTabController?.animateTo(0);
                                          } finally {
                                            provider.setSubmitting(false);
                                          }
                                        },
                                        type: ButtonType.elevated,
                                        child: Text("Add",
                                            style: typography.ButtonLargeBlack),
                                      );
                              },
                            ),

                            // Expanded(
                            //   child: isAddToSOVLoading
                            //       ? Center(child: CircularProgressIndicator())
                            //       : CustomButton(
                            //           onPressed: () async {
                            //             if (sovController.text.isEmpty) {
                            //               ScaffoldMessenger.of(context)
                            //                   .showSnackBar(
                            //                 SnackBar(
                            //                   content: Text(
                            //                     "Please select or enter an SoV name.",
                            //                     style: typography.Body1,
                            //                   ),
                            //                 ),
                            //               );
                            //               return;
                            //             }
                            //
                            //             setState(
                            //                 () => isAddToSOVLoading = true);
                            //
                            //             try {
                            //               // FIXED ✔ Always use locationIds list
                            //               Map<String, dynamic> body = {
                            //                 "location_list": locationIds,
                            //                 "account_id": accountID,
                            //                 "sub_account_id": subAccountID,
                            //                 "sov": {
                            //                   "sov_id": selectedSovId,
                            //                   "sov_name": sovController.text,
                            //                 }
                            //               };
                            //
                            //               await addLocationToSOV(context, body);
                            //
                            //               masterTabController?.animateTo(0);
                            //             } catch (e) {
                            //               ScaffoldMessenger.of(context)
                            //                   .showSnackBar(
                            //                 SnackBar(
                            //                     content: Text("Error: $e")),
                            //               );
                            //             } finally {
                            //               setState(
                            //                   () => isAddToSOVLoading = false);
                            //             }
                            //           },
                            //           child: Text(
                            //             "Add",
                            //             style: typography.ButtonLargeBlack,
                            //           ),
                            //           type: ButtonType.elevated,
                            //         ),
                            // ),
                          ],
                        ),
                        SizedBox(height: 8),
                        CustomButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text("Cancel", style: typography.ButtonLarge),
                          type: ButtonType.text,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      sovController.clear();
      tagsController.clear();
      selectedSovId = "";
    });
  }

  Future<void> showAddTagDialog(
    BuildContext context,
    String accountId,
    String subAccountId,
    List<String> locationId, {
    required bool isGlobal,
  }) async {
    var typography = CustomTypography(context);
    TextEditingController tagsController = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.85,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  /// TITLE
                  Text(
                    "Add Tags",
                    textAlign: TextAlign.center,
                    style: typography.H5_Regular.copyWith(height: 1.5),
                  ),

                  const SizedBox(height: 16),

                  /// INPUT
                  TextField(
                    controller: tagsController,
                    decoration: const InputDecoration(
                      labelText: "Enter comma-separated tags",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// ACTIONS
                  Consumer<MyLocationListProvider>(
                    builder: (_, provider, __) {
                      return Row(
                        children: [
                          /// CANCEL
                          Expanded(
                            child: CustomButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              type: ButtonType.text,
                              child: Text(
                                "Cancel",
                                style: typography.ButtonLarge,
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          /// ADD / LOADER
                          Expanded(
                            child: provider.isAddTagsLoading
                                ? const Center(
                                    child: SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    ),
                                  )
                                : CustomButton(
                                    type: ButtonType.elevated,
                                    onPressed: () async {
                                      if (tagsController.text.trim().isEmpty) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text("Please enter tags."),
                                          ),
                                        );
                                        return;
                                      }

                                      final tags = tagsController.text
                                          .split(',')
                                          .map((e) => e.trim())
                                          .where((e) => e.isNotEmpty)
                                          .toList();

                                      await addTagsToLocation(
                                        context,
                                        accountId,
                                        subAccountId,
                                        isGlobal ? [] : locationId,
                                        tags,
                                        isGlobal: isGlobal,
                                      );

                                      if (!isGlobal) {
                                        for (final id in locationId) {
                                          final loc = getLocationById(id);
                                          loc?.tags ??= [];
                                          loc?.tags!.addAll(tags);
                                        }
                                      }

                                      Navigator.pop(context);
                                    },
                                    child: const Text("Add"),
                                  ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 12),
                ],
              ),

              // Column(
              //   mainAxisSize: MainAxisSize.min,
              //   children: [
              //     Text("Add Tags",
              //         style: typography.H5_Regular.copyWith(height: 1.5)),
              //     const SizedBox(height: 16),
              //     TextField(
              //       controller: tagsController,
              //       decoration: const InputDecoration(
              //         labelText: "Enter comma-separated tags",
              //         border: OutlineInputBorder(),
              //       ),
              //     ),
              //     const SizedBox(height: 16),
              //     Consumer<MyLocationListProvider>(
              //       builder: (_, provider, __) {
              //         return
              //           Expanded(
              //                                           child:
              //           provider.isAddTagsLoading
              //             ? const CircularProgressIndicator()
              //             : CustomButton(
              //                 onPressed: () async {
              //                   if (tagsController.text.isEmpty) {
              //                     ScaffoldMessenger.of(context).showSnackBar(
              //                       const SnackBar(
              //                         content: Text("Please enter tags."),
              //                       ),
              //                     );
              //                     return;
              //                   }
              //
              //                   final tags = tagsController.text.split(",");
              //
              //                   await addTagsToLocation(
              //                     context,
              //                     accountId,
              //                     subAccountId,
              //                     isGlobal ? [] : locationId,
              //                     tags,
              //                     isGlobal: isGlobal,
              //                   );
              //
              //                   if (!isGlobal) {
              //                     for (final id in locationId) {
              //                       final loc = getLocationById(id);
              //                       loc?.tags ??= [];
              //                       loc?.tags!.addAll(tags);
              //                     }
              //                   }
              //
              //                   Navigator.pop(context);
              //                 },
              //                 child: const Text("Add"),
              //                 type: ButtonType.elevated,
              //               ));
              //       },
              //     ),
              //                             CustomButton(
              //                               onPressed: () {
              //                                 Navigator.pop(context);
              //                               },
              //                               child: Text(
              //                                 "Cancel",
              //                                 style: typography.ButtonLarge,
              //                               ),
              //                               type: ButtonType.text,
              //                             ),
              //   ],
              // ),
            ),
          ),
        );
      },
    );

    tagsController.clear();
  }

  // Future<void> showAddTagDialog(BuildContext context, String accountId,
  //     String subAccountId, List<String> locationId) async {
  //   var typography = CustomTypography(context);
  //   TextEditingController tagsController = TextEditingController();
  //
  //   await showDialog(
  //     context: context,
  //     builder: (BuildContext dialogContext) {
  //       return StatefulBuilder(
  //         builder: (BuildContext context, StateSetter setState) {
  //           return AlertDialog(
  //             content: SingleChildScrollView(
  //               child: Column(
  //                 mainAxisSize: MainAxisSize.min,
  //                 children: [
  //                   Text(
  //                     "Add Tags",
  //                     style: typography.H5_Regular.copyWith(height: 1.5),
  //                   ),
  //                   SizedBox(height: 16.0),
  //                   // Comma-separated Tags (Optional)
  //                   TextField(
  //                     controller: tagsController,
  //                     decoration: InputDecoration(
  //                       labelText: "Enter comma-separated tags",
  //                       border: const OutlineInputBorder(),
  //                     ),
  //                   ),
  //                   SizedBox(height: 16.0),
  //                   // Add/Cancel Buttons
  //                   Consumer<MyLocationListProvider>(
  //                       builder: (context, myLocationListProvider, child) {
  //                     return Column(
  //                       children: [
  //                         Row(
  //                           mainAxisAlignment: MainAxisAlignment.center,
  //                           children: [
  //                             Expanded(
  //                               child: myLocationListProvider.isAddTagsLoading
  //                                   ? Center(
  //                                       child: CircularProgressIndicator(),
  //                                     )
  //                                   : CustomButton(
  //                                       onPressed: () async {
  //                                         if (tagsController.text.isEmpty) {
  //                                           ScaffoldMessenger.of(context)
  //                                               .showSnackBar(SnackBar(
  //                                             content: Text(
  //                                               "Please enter tags.",
  //                                               style: typography.Body1,
  //                                             ),
  //                                           ));
  //                                           return;
  //                                         }
  //
  //                                         // Call your method to add the location to the SoV
  //                                         await addTagsToLocation(
  //                                             context,
  //                                             accountId,
  //                                             subAccountId,
  //                                             locationId,
  //                                             tagsController.text.split(","));
  //                                         //Locally update the tags
  //                                         locationId.forEach((element) {
  //                                           final MyLocation? location =
  //                                               getLocationById(element);
  //
  //                                           if (location == null)
  //                                             return; // 🔒 very important
  //
  //                                           location.tags ??= [];
  //                                           location.tags!.addAll(
  //                                               tagsController.text.split(","));
  //                                         });
  //
  //                                         locationId.forEach((element) {
  //                                           MyLocation location =
  //                                               getCertifiedLocationById(
  //                                                   element);
  //                                           if (location.tags == null) {
  //                                             location.tags = tagsController
  //                                                 .text
  //                                                 .split(",");
  //                                           } else {
  //                                             location.tags?.addAll(
  //                                                 tagsController.text
  //                                                     .split(","));
  //                                           }
  //                                         });
  //                                         fullLocationList.forEach((element) {
  //                                           MyLocation location = element;
  //                                           if (location.tags == null) {
  //                                             location.tags = tagsController
  //                                                 .text
  //                                                 .split(",");
  //                                           } else {
  //                                             location.tags?.addAll(
  //                                                 tagsController.text
  //                                                     .split(","));
  //                                           }
  //                                         });
  //                                       },
  //                                       child: Text(
  //                                         "Add",
  //                                         style: typography.ButtonLargeBlack,
  //                                       ),
  //                                       type: ButtonType.elevated,
  //                                     ),
  //                             ),
  //                           ],
  //                         ),
  //                         SizedBox(width: 8.0),
  //                         CustomButton(
  //                           onPressed: () {
  //                             Navigator.pop(context);
  //                           },
  //                           child: Text(
  //                             "Cancel",
  //                             style: typography.ButtonLarge,
  //                           ),
  //                           type: ButtonType.text,
  //                         ),
  //                       ],
  //                     );
  //                   }),
  //                 ],
  //               ),
  //             ),
  //           );
  //         },
  //       );
  //     },
  //   ).then((_) {
  //     // Clear the input fields after dialog is closed
  //     tagsController.clear();
  //   });
  // }

  Future<List<String>> fetchAllLocationIds({
    required String accountId,
    required String subAccountId,
    int pageSize = 1000,
  }) async {
    isFetchingAllIds = true;
    notifyListeners();

    final List<String> allIds = [];
    int page = 1;
    bool hasMore = true;

    try {
      while (hasMore) {
        final headers = await CommonHeaders.createHeaders();

        final url =
            "${AppConstant.MY_LOCATION}&account_id=$accountId&sub_account_id=$subAccountId";

        final response = await http.get(Uri.parse(url), headers: headers);
        if (response.statusCode != 200) break;

        final jsonResponse = json.decode(response.body);
        final model = MyLocationModel.fromJson(jsonResponse);

        final results = model.results ?? [];

        for (final loc in results) {
          if (loc.id != null) {
            allIds.add(loc.id!);
          }
        }

        final totalRecords = model.totalRecords ?? 0;
        final totalPages = (totalRecords / pageSize).ceil();

        page++;
        hasMore = page <= totalPages;
      }
    } finally {
      isFetchingAllIds = false;
      notifyListeners();
    }

    return allIds;
  }

  Future<List<String>> fetchAllLocationIdsForAddTag({
    required String accountId,
    required String subAccountId,
    int pageSize = 1000,
  }) async {
    isAddTagFetchingIds = true;
    notifyListeners();

    final List<String> allIds = [];
    int page = 1;
    bool hasMore = true;

    try {
      while (hasMore) {
        final headers = await CommonHeaders.createHeaders();
        final url =
            "${AppConstant.MY_LOCATION}?account_id=$accountId&sub_account_id=$subAccountId";

        final response = await http.get(Uri.parse(url), headers: headers);
        if (response.statusCode != 200) break;

        final jsonResponse = json.decode(response.body);
        final model = MyLocationModel.fromJson(jsonResponse);

        for (final loc in model.results ?? []) {
          if (loc.id != null) allIds.add(loc.id!);
        }

        final totalRecords = model.totalRecords ?? 0;
        final totalPages = (totalRecords / pageSize).ceil();
        page++;
        hasMore = page <= totalPages;
      }
    } finally {
      isAddTagFetchingIds = false;
      notifyListeners();
    }

    return allIds;
  }

  Future<void> showDeleteTagDialog(BuildContext context, String accountId,
      String subAccountId, String locationId, String tag) async {
    var typography = CustomTypography(context);

    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Delete Tag",
                      style: typography.H5_Regular.copyWith(height: 1.5),
                    ),
                    SizedBox(height: 16.0),
                    // Comma-separated Tags (Optional)
                    Text(
                      "Are you sure you want to delete the tag '$tag'?",
                      style: typography.Body1,
                    ),
                    SizedBox(height: 16.0),
                    // Add/Cancel Buttons
                    Consumer<MyLocationListProvider>(
                        builder: (context, myLocationListProvider, child) {
                      return Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: myLocationListProvider.isDeleteTagLoading
                                    ? Center(
                                        child: CircularProgressIndicator(),
                                      )
                                    : CustomButton(
                                        onPressed: () async {
                                          // API call
                                          await deleteTagFromLocation(
                                            context,
                                            accountId,
                                            subAccountId,
                                            locationId,
                                            tag,
                                          );

                                          // 🔒 SAFE local updates (no crashes)
                                          final MyLocation? location =
                                              getLocationById(locationId);
                                          if (location != null) {
                                            location.tags?.remove(tag);
                                          }

                                          final MyLocation? certifiedLocation =
                                              getCertifiedLocationById(
                                                  locationId);
                                          if (certifiedLocation != null) {
                                            certifiedLocation.tags?.remove(tag);
                                          }

                                          // ❌ REMOVE THIS LOOP (WRONG FOR GLOBAL SELECT)
                                          // fullLocationList.forEach((element) {
                                          //   element.tags?.remove(tag);
                                          // });

                                          notifyListeners(); // ensure UI refresh
                                        },
                                        child: Text(
                                          "Delete",
                                          style: typography.ButtonLargeBlack,
                                        ),
                                        type: ButtonType.elevated,
                                      ),
                              ),
                            ],
                          ),
                          SizedBox(width: 8.0),
                          CustomButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text(
                              "Cancel",
                              style: typography.ButtonLarge,
                            ),
                            type: ButtonType.text,
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Show dialog for generating heatmap as it is a paid service.. we ask user and on the button we show 2 Credits
  Future<void> showGenerateHeatMapDialog(
      BuildContext context, String accountId, String subAccountId,
      [String? sovId]) async {
    var typography = CustomTypography(context);

    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Generate Heatmap",
                      style: typography.H5_Regular,
                    ),
                    SizedBox(height: 16.0),
                    // Warning Message
                    Text(
                      "Generating a heatmap is a paid service. Are you sure you want to proceed?",
                      style: typography.Body1,
                    ),
                    SizedBox(height: 16.0),
                    // Add/Cancel Buttons
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: isHeatMapGenerating
                                  ? Center(
                                      child: CircularProgressIndicator(),
                                    )
                                  : CustomButton(
                                      onPressed: () async {
                                        // Call your method to generate the heatmap
                                        await generateHeatMapForLocationsGeocoding(
                                            context,
                                            accountId,
                                            subAccountId,
                                            false,
                                            false,
                                            sovId);
                                      },
                                      child: Text(
                                        "Generate Heatmap (2 Credits)",
                                        style: typography.ButtonLarge,
                                      ),
                                      type: ButtonType.elevated,
                                    ),
                            ),
                          ],
                        ),
                        SizedBox(width: 8.0),
                        CustomButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text(
                            "Cancel",
                            style: typography.ButtonLarge,
                          ),
                          type: ButtonType.text,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Upload SOV
  Future<String> uploadSov(BuildContext context, File sovFile, String accountId,
      String subAccountId, String sovId, String tags, String sovName) async {
    var typography = CustomTypography(context);
    try {
      isImageUploadLoading = true;
      ApiService apiService = ApiService(AppConstant.UPLOAD_SOV_LOCATIONS);

      print("Uploading SOV: $sovFile");
      print("Uploading SOV: $accountId");
      print("Uploading SOV: $subAccountId");
      print("Uploading SOV: $sovId");
      print("Uploading SOV: $tags");
      print("Uploading SOV: $sovName");
      print("url: ${AppConstant.UPLOAD_SOV_LOCATIONS}");
      // Send a POST request to the API to upload the image
      Map<String, dynamic> response = await apiService.postMultiPartSOVPartial(
          sovFile, accountId, subAccountId, sovId, tags, sovName, context);
      // print(response!.message.toString());
      isImageUploadLoading = false;
      Navigator.pop(context);
/*      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          response['message']??LanguageService.getTranslated(context, "sub_account_list_app_sov_upload_success"),
          style: typography.Body1,
        ),
      ));*/
      print("total records: " + response['total_records'].toString());
      if (response['total_records'] == 0) {
        print("total records: " + response['total_records'].toString());
        String tempId = (response['temp_id'] ?? '') + "+";
        print("tempIdLocal: " + tempId);
        return tempId;
      }
      return response['temp_id'] ?? '';
    } on BackendException catch (e, stack) {
      print(stack);

      isImageUploadLoading = false;

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
      } catch (decodeError, stackTrace) {
        // Handle any JSON parsing errors
        print('JSON Decode Error: $decodeError');
        print(stackTrace);

        // Fallback to the raw message or a generic error message
        message = e.message ??
            'An unexpected error occurred. Please try again later.';
      }

      // Display the error message in a SnackBar

      return ''; // Return an empty string or handle the error as needed
    } catch (e, stackTrace) {
      print(stackTrace);
      print("Error uploading SOV: $e");
      // Handle other unexpected exceptions

      isImageUploadLoading = false;
      return ''; // Return empty string or handle the error as needed
    }
  }

  MyLocation? getLocationById(String id) {
    try {
      return myLocationList.firstWhere((loc) => loc.id == id);
    } catch (_) {
      return null;
    }
  }

  MyLocation getCertifiedLocationById(String locationId) {
    return certifiedLocationList
        .firstWhere((element) => element.id == locationId);
  }

  Future<void> fetchCampusIds(
      String accountId, String subAccountId, String sovId) async {
    final url = Uri.parse(
        "${AppConstant.baseURL}/accounts/$accountId/subaccount/$subAccountId/sov/$sovId/location?pageSize=10&campus_id_list=true");

    try {
      var headers = await CommonHeaders.createHeaders();
      final response = await http.get(url, headers: headers);
      print(response.body);
      if (response.statusCode == 200) {
        final data = json.decode(response.body); // Parse as a Map
        print(data);

        // Extracting the list from the "result" field
        campusIds = List<String>.from(data['result']);
      } else {
        print("Failed to load campus IDs");
        print(response.body);
        throw Exception("Failed to load campus IDs");
      }
    } on BackendException catch (e, stackTrace) {
      print(stackTrace);
      print("Error fetching campus IDs: ${e.message}");
    } catch (e, stackTrace) {
      print(stackTrace);
      print("Error fetching campus IDs: $e");
    }
  }

  /// Profile apis

  /// Fetch location with pagination, search query, and filters
  Future<void> fetchLocationListProfile(
    BuildContext context,
    String searchQuery,
    int page,
    int totalPages,
    String? accountID,
    String? subAccountID,
    String? sovID,
    String? locationId,
  ) async {
    var typography = CustomTypography(context);
    try {
      // Check if api is already working
      if (isLoading) return;
      // dont call api is next page does not exist
      if (page > totalPages) return;

      isLoading = true;

      var headers = await CommonHeaders.createHeaders();

      print('Location ID: $locationId');
      log(headers.toString());

      var url;
      if (sovID != null && sovID.isNotEmpty) {
        url = AppConstant.MY_LOCATION +
            "?page=$page&pageSize=1&account_id=$accountID&sub_account_id=$subAccountID&sov_id=$sovID";
      } else {
        url = AppConstant.MY_LOCATION +
            "?page=$page&pageSize=1&account_id=$accountID&sub_account_id=$subAccountID";
      }

      if (locationId != null && locationId.isNotEmpty) {
        url +=
            "&zip=&search=&sort=&campus_name=&filter_by_location_id=$locationId";
      }
      if (countries.isNotEmpty) {
        url += "&country=${countries.join(",")}";
      }
      if (zipcode.isNotEmpty) {
        url += "&zip=$state";
      }

      if (certifications.isNotEmpty) {
        for (var cert in certifications) {
          if (cert == "Manual Certified") {
            url += "&manual_certified=true";
          } else if (cert == "Auto Certified") {
            url += "&auto_certified=true";
          }
        }
      }
      if (hazardRatings.isNotEmpty) {
        for (var hazard in hazardRatings.keys) {
          url += "&hazard=${jsonEncode(hazardRatings[hazard])}";
        }
      }
      if (rating.isNotEmpty) {
        url += "&score=${rating.join(",")}";
      }

      if (_selectedCampusIds.isNotEmpty) {
        url += "&campus_id=${_selectedCampusIds.join(",")}";
      }

      print(url);
      var uri = Uri.parse(url);

      var response = await http.get(
        uri,
        headers: headers,
        //body: body,
      );
      log(response.body);
      print(response.statusCode);

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        // MyLocationModel locationListModel =
        //     MyLocationModel.fromJson(jsonResponse);
        final locationListModel =
            await compute<Map<String, dynamic>, MyLocationModel>(
                MyLocationModel.fromJson, jsonResponse as Map<String, dynamic>);

        //summaryList = locationListModel.summaryList ?? [];
        //mainSovRating = locationListModel. ?? 0.0;

        if (locationListModel.totalRecords != null) {
          // Assuming you are using a fixed page size (e.g., 1 from your URL)
          _totalPages = (locationListModel.totalRecords! / 1).ceil();
          notifyListeners();
        }
        if (locationId != null && locationId.isNotEmpty) {
          locationProfile = locationListModel.filterByLocationResult;
          grapDataProfile = locationListModel.graphData;
          resetTotalPage = locationListModel.totalRecords ?? 1;
        } else {
          locationProfile = locationListModel.results?.first;
          grapDataProfile = locationListModel.graphData;
        }

        log(resetTotalPage.toString() ?? "");
        log(locationProfile?.toString() ?? "");

        log(page.toString());
      } else {
        print(json.decode(response.body)?["error"] ?? "");
        throw Exception('Failed to load data');
      }
      isLoading = false;
    } on BackendException catch (e, stackTrace) {
      isLoading = false;
      print(stackTrace);
      print(e.message);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          e.message,
          style: typography.Body1,
        ),
      ));
    } catch (e, stackTrace) {
      isLoading = false;
      print(stackTrace);
      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      //   content: Text(
      //     "Error fetching data",
      //     style: typography.Body1,
      //   ),
      // ));
    }
  }

  // Fetch Location By ID
  Future<void> fetchIndividualLocationProfile(
      BuildContext context, String locationId) async {
    var typography = CustomTypography(context);
    try {
      isIndividualLocationLoading = true;
      notifyListeners();

      ApiService apiService = ApiService(
          "${AppConstant.GET_LOCATION_PROFILE_INDIVIDUAL_NEW}?location_id=$locationId");

      var response = await apiService.get();
      print("Response: $response");
      if (response.containsKey('result')) {
        selectedLocation = MyLocation.fromJson(response['result']);
        isHazardProcessed = response['result']['is_hazard_processed'] ?? false;
        print("isHazardProcessed: $isHazardProcessed");
      } else {
        selectedLocation = null;
        isHazardProcessed = false;
      }

      isIndividualLocationLoading = false;
      notifyListeners();
    } on BackendException catch (e, stackTrace) {
      isIndividualLocationLoading = false;
      print(stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message, style: typography.Body1),
      ));
    } catch (e, stackTrace) {
      isIndividualLocationLoading = false;
      print(stackTrace);
      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      //   content: Text(e.toString(), style: typography.Body1),
      // ));
    } finally {
      isIndividualLocationLoading = false;
      notifyListeners();
    }
  }

  Future<void> uploadImage(
      BuildContext context,
      String filePath,
      String accountId,
      String subAccountId,
      String sovId,
      String locationId) async {
    try {
      isUploadingImage = true;
      ApiService apiService =
          ApiService(AppConstant.UPLOAD_IMAGES_NEW + "/$locationId");

      print("Uploading image to ${apiService.url}");
      var response = await apiService.postMultiPartLocationProfile(
          File(filePath),
          accountId,
          subAccountId,
          sovId,
          locationId,
          "file_${DateTime.now().millisecondsSinceEpoch}.jpg}");

      isUploadingImage = false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(response['message'] ?? "Image uploaded successfully"),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString()),
      ));
    } finally {
      isUploadingImage = false;
    }
  }

  Future<void> createSubdestination(
      BuildContext context,
      String accountId,
      String subAccountId,
      String sovId,
      String locationId,
      double lat,
      double lng,
      String placeId) async {
    var typography = CustomTypography(context);
    try {
      // isLoading = true;
      notifyListeners();

      String url =
          "${AppConstant.SOV_COMPLETE_STATUS1}location_id=$locationId&lat=$lat&lng=$lng&subdestination=true&place_id=$placeId";
      ApiService apiService = ApiService(url);

      var response = await apiService.get();

      if (response.containsKey('results')) {
        //result = LocationProfileModel.fromJson(response['result']);
        subdestinations = locationProfile?.subdestinations ?? [];
      } else {
        locationProfile = null;
        grapDataProfile = null;
        subdestinations = [];
      }

      // isLoading = false;
      notifyListeners();
    } on BackendException catch (e, stackTrace) {
      // isLoading = false;
      print(stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message, style: typography.Body1),
      ));
    } catch (e, stackTrace) {
      // isLoading = false;
      print(stackTrace);
      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      //   content: Text(e.toString(), style: typography.Body1),
      // ));
    } finally {
      // isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addSubdestinationToSOV({
    required BuildContext context,
    required String accountId,
    required String subAccountId,
    required String campusName,
    required String userId,
    required String locationId,
    required String subDestinationId,
    required String occupancy,
    required String accountName,
    required String subAccountName,
  }) async {
    var typography = CustomTypography(context);
    try {
      isLoading = true;
      notifyListeners();

      String url = "${AppConstant.ADD_SUBDESTINATION}";
      ApiService apiService = ApiService(url);

      // Retrieve the subdestination details from the list using the provided ID
      var subdestination = locationProfile?.subdestinations
          ?.firstWhere((sd) => sd.id == subDestinationId);

      var body = {
        "data": {
          "account_id": accountId,
          "sub_account_id": subAccountId,
          "campus_name": campusName,
          "user_id": userId,
          "location_id": locationId,
          "add_location": true,
          "locations": [
            {
              "id": subdestination?.id,
              "lat": subdestination?.lat,
              "lng": subdestination?.lng,
              "title": subdestination?.name,
              "icon": "",
              "name": subdestination?.name,
              "place_id": subdestination?.placeId,
              "address": subdestination?.address,
              "types": subdestination?.types,
              "isMainLocation": false,
              "status": "",
              "rented": occupancy.toLowerCase() == "Rented".toLowerCase()
                  ? true
                  : false,
              "account_name": accountName,
              "sub_account_name": subAccountName,
            }
          ]
        }
      };

      var response = await apiService.post(body);

      if (response.containsKey('processed')) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              response['message'] ?? "Subdestination added successfully",
              style: typography.Body1),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text("Failed to add subdestination", style: typography.Body1),
        ));
      }

      isLoading = false;
      notifyListeners();
    } on BackendException catch (e, stackTrace) {
      isLoading = false;
      print(stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message, style: typography.Body1),
      ));
    } catch (e, stackTrace) {
      isLoading = false;
      print(stackTrace);
      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      //   content: Text(e.toString(), style: typography.Body1),
      // ));
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addSelectedSubdestinationToSOV(
      BuildContext context,
      String accountId,
      String subAccountId,
      String sovId,
      String locationId,
      List<String> subDestinationId) async {
    var typography = CustomTypography(context);
    try {
      isLoading = true;
      notifyListeners();

      String url =
          "${AppConstant.GET_LOCATION_PROFILE}/$accountId/subaccount/$subAccountId/sov/$sovId/location?location_id=$locationId";
      ApiService apiService = ApiService(url);
      // Retrieve the subdestination details from the list using the provided ID
      var subdestinations = _subdestinations
          .where((sd) => subDestinationId.contains(sd.id))
          .toList();
      var body = {
        "data": {
          "add_location": true,
          "location_id": locationId,
          "locations": subdestinations.map((sd) {
            return {
              "id": sd.id,
              "lat": sd.lat,
              "lng": sd.lng,
              "title": sd.name,
              "icon": "",
              "name": sd.name,
              "place_id": sd.placeId,
              "address": sd.address,
              "types": sd.types,
              "isMainLocation": false,
              "status": ""
            };
          }).toList()
        }
      };

      var response = await apiService.post(body);

      if (response.containsKey('processed')) {
        //result = LocationProfileModel.fromJson(response['result']);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              response['message'] ?? "Subdestination added successfully",
              style: typography.Body1),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text("Failed to add subdestination", style: typography.Body1),
        ));
      }

      isLoading = false;
      notifyListeners();
    } on BackendException catch (e, stackTrace) {
      isLoading = false;
      print(stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message, style: typography.Body1),
      ));
    } catch (e, stackTrace) {
      isLoading = false;
      print(stackTrace);
      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      //   content: Text(e.toString(), style: typography.Body1),
      // ));
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeSubdestinationFromSOV(
      BuildContext context,
      String accountId,
      String subAccountId,
      String sovId,
      String locationId,
      String subDestinationId) async {
    var typography = CustomTypography(context);
    try {
      isLoading = true;
      notifyListeners();

      String url =
          "${AppConstant.GET_LOCATION_PROFILE}/$accountId/subaccount/$subAccountId/sov/$sovId/location?location_id=$locationId";
      ApiService apiService = ApiService(url);

      var body = {
        "data": {
          "location_id": locationId,
          "subdestination_id": subDestinationId,
        }
      };

      var response = await apiService.delete(body);

      //result = LocationProfileModel.fromJson(response['result']);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            response['message'] ?? "Subdestination removed successfully",
            style: typography.Body1),
      ));

      isLoading = false;
      notifyListeners();
    } on BackendException catch (e, stackTrace) {
      isLoading = false;
      print(stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message, style: typography.Body1),
      ));
    } catch (e, stackTrace) {
      isLoading = false;
      print(stackTrace);
      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      //   content: Text(e.toString(), style: typography.Body1),
      // ));
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> markAsCompleteSov(
    BuildContext context,
    String accountId,
    String subAccountId,
    String sovId,
  ) async {
    var typography = CustomTypography(context);
    try {
      isLoading = true;
      notifyListeners();
      String url = "${AppConstant.SOV_COMPLETE_STATUS}";
      ApiService apiService = ApiService(url);
      // Create data payload
      List<String> locationIds =
          _selectedLocations.map((location) => location.id ?? "").toList();
      final data = {
        "status": "completed",
        "location_id": locationIds,
        "sov_id": sovId,
      };
      var body = data;
      var response = await apiService.patch(body);
      if (response.containsKey('result')) {
        //result = LocationProfileModel.fromJson(response['result']);
        subdestinations = locationProfile?.subdestinations ?? [];
      } else {
        locationProfile?.finalAddress = null;
        subdestinations = [];
      }

      isLoading = false;
      notifyListeners();
      return true;
    } on BackendException catch (e, stackTrace) {
      isLoading = false;
      print(e);
      print(stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message, style: typography.Body1),
      ));
      return false;
    } catch (e, stackTrace) {
      isLoading = false;
      print(e);
      print(stackTrace);
      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      //   content: Text(e.toString(), style: typography.Body1),
      // ));
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
      return true;
    }
  }

  Future<bool> updateLocationName(
      BuildContext context,
      String accountId,
      String subAccountId,
      String sovId,
      String locationId,
      String locationName) async {
    var typography = CustomTypography(context);
    try {
      isLoading = true;
      notifyListeners();
      String url =
          "${AppConstant.GET_LOCATION_PROFILE}/$accountId/subaccount/$subAccountId/sov/${sovId.isEmpty ? "undefined" : sovId}/location";
      ApiService apiService = ApiService(url);
      // Create data payload
      final data = {
        "data": {
          "location_name": locationName,
          "location_type": locationProfile?.finalAddress?.locationType,
          "description": locationProfile?.finalAddress?.description,
          "address": locationProfile?.finalAddress?.address,
          "city": locationProfile?.finalAddress?.city,
          "state": locationProfile?.finalAddress?.state,
          "zip": locationProfile?.finalAddress?.zip,
          "country": locationProfile?.finalAddress?.country,
          "latitude": locationProfile?.finalAddress?.latitude,
          "longitude": locationProfile?.finalAddress?.longitude,
          "location_id": locationProfile?.finalAddress?.locationId,
        }
      };
      var body = data;
      var response = await apiService.patch(body);
      if (response.containsKey('result')) {
        //result = LocationProfileModel.fromJson(response['result']);
        subdestinations = locationProfile?.subdestinations ?? [];
      } else {
        locationProfile?.finalAddress = null;
        subdestinations = [];
      }

      isLoading = false;
      notifyListeners();
      return true;
    } on BackendException catch (e, stackTrace) {
      isLoading = false;
      print(e);
      print(stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message, style: typography.Body1),
      ));
      return false;
    } catch (e, stackTrace) {
      isLoading = false;
      print(e);
      print(stackTrace);
      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      //   content: Text(e.toString(), style: typography.Body1),
      // ));
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
      return true;
    }
  }

  Future<bool> updateLocationAddress(
      BuildContext context,
      String accountId,
      String subAccountId,
      String sovId,
      String locationId,
      String locationAddress) async {
    var typography = CustomTypography(context);
    try {
      isLoading = true;
      notifyListeners();
      String url =
          "${AppConstant.GET_LOCATION_PROFILE}/$accountId/subaccount/$subAccountId/sov/$sovId/location";
      ApiService apiService = ApiService(url);
      // Create data payload
      final data = {
        "data": {
          "location_name": locationProfile?.finalAddress?.locationName,
          "location_type": locationProfile?.finalAddress?.locationType,
          "description": locationProfile?.finalAddress?.description,
          "address": locationAddress,
          "city": locationProfile?.finalAddress?.city,
          "state": locationProfile?.finalAddress?.state,
          "zip": locationProfile?.finalAddress?.zip,
          "country": locationProfile?.finalAddress?.country,
          "latitude": locationProfile?.finalAddress?.latitude,
          "longitude": locationProfile?.finalAddress?.longitude,
          "location_id": locationProfile?.finalAddress?.locationId,
        }
      };
      var body = data;
      var response = await apiService.patch(body);
      if (response.containsKey('result')) {
        //result = LocationProfileModel.fromJson(response['result']);
        subdestinations = locationProfile?.subdestinations ?? [];
      } else {
        locationProfile = null;
        grapDataProfile = null;
        subdestinations = [];
      }

      isLoading = false;
      notifyListeners();
      return true;
    } on BackendException catch (e, stackTrace) {
      isLoading = false;
      print(e);
      print(stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message, style: typography.ButtonLargeBlack),
      ));
      return false;
    } catch (e, stackTrace) {
      isLoading = false;
      print(e);
      print(stackTrace);
      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      //   content: Text(e.toString(), style: typography.Body1),
      // ));
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
      return true;
    }
  }

  Future<String> updateLocationDetails(
      BuildContext context,
      String accountId,
      String subAccountId,
      String sovId,
      String locationId,
      Map<String, dynamic> data) async {
    var typography = CustomTypography(context);
    try {
      isLoading = true;
      notifyListeners();
      String url = "${AppConstant.GET_LOCATION_PROFILE_NEW + "/editlocation"}";
      ApiService apiService = ApiService(url);
      var body = data;
      var response = await apiService.patch(body);
      if (response.containsKey('result')) {
        //result = LocationProfileModel.fromJson(response['result']);
        subdestinations = locationProfile?.subdestinations ?? [];
      } else {
        locationProfile = null;
        grapDataProfile = null;
        subdestinations = [];
      }

      isLoading = false;
      notifyListeners();
      return true.toString();
    } on BackendException catch (e, stackTrace) {
      if (e.statusCode == 422) {
        try {
          print("Error 422: ${e.message}");
          // convert e.message to map
          print(e.message);
          var resultLocation = json.decode(e.message);
          var toDeleteLocationId = resultLocation["to_delete_location"];
          locationProfile?.finalAddress?.locationId =
              resultLocation["location_data"]["location_id"];
          locationProfile?.finalAddress?.locationName =
              resultLocation["location_data"]["location_name"];
          locationProfile?.finalAddress?.locationType =
              resultLocation["location_data"]["location_type"];
          locationProfile?.finalAddress?.description =
              resultLocation["location_data"]["description"];
          locationProfile?.finalAddress?.address =
              resultLocation["location_data"]["address"];
          locationProfile?.finalAddress?.city =
              resultLocation["location_data"]["city"];
          locationProfile?.finalAddress?.state =
              resultLocation["location_data"]["state"];
          locationProfile?.finalAddress?.zip =
              resultLocation["location_data"]["zip"];
          locationProfile?.finalAddress?.country =
              resultLocation["location_data"]["country"];
          locationProfile?.finalAddress?.latitude =
              resultLocation["location_data"]["latitude"];
          locationProfile?.finalAddress?.longitude =
              resultLocation["location_data"]["longitude"];
          locationProfile?.finalAddress?.ownerId =
              resultLocation["location_data"]["owner_id"];
          locationProfile?.finalAddress?.ownerName =
              resultLocation["location_data"]["owner_name"];
          locationProfile?.finalAddress?.ownerEmail =
              resultLocation["location_data"]["owner_email"];
          locationProfile?.finalAddress?.autoCertified =
              resultLocation["location_data"]["auto_certified"];
          locationProfile?.finalAddress?.campusId =
              resultLocation["location_data"]["campus_id"];
          locationProfile?.finalAddress?.percent =
              resultLocation["location_data"]["percent"];
          locationProfile?.finalAddress?.score =
              resultLocation["location_data"]["score"];

          locationProfile?.finalAddress?.placeTypes =
              resultLocation["location_data"]["place_types"] is String
                  ? [resultLocation["location_data"]["place_types"]]
                  : (resultLocation["location_data"]["place_types"] as List?)
                      ?.map((item) => item as String)
                      .toList();
          locationProfile?.screenshots =
              resultLocation["location_data"]["screen_shots"] ?? [];
          subdestinations = locationProfile?.subdestinations ?? [];
          String accountName = resultLocation["location_data"]["account_name"];
          String subAccountName =
              resultLocation["location_data"]["sub_account_name"];
          String sovName = resultLocation["location_data"]["sov_name"];
          String page = "0";
          String totalPages = "1";
          String searchQuery = "";
        } catch (e, stackTrace) {
          isLoading = false;
          print(e);
          print(stackTrace);
          // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          //   content: Text(e.toString(), style: typography.Body1),
          // ));
          return false.toString();
        }
      }

      isLoading = false;
      print(e);
      print(stackTrace);
      // Todo: Add condition based on response
      if (e.statusCode != 422) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.message, style: typography.ButtonLargeBlack),
        ));
      }

      return false.toString();
    } catch (e, stackTrace) {
      isLoading = false;
      print(e);
      print(stackTrace);
      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      //   content: Text(e.toString(), style: typography.Body1),
      // ));
      return false.toString();
    } finally {
      isLoading = false;
      notifyListeners();
      return true.toString();
    }
  }

  // Edit Campus Id
  Future<void> updateCampusId(
      BuildContext context, String campusKey, String campusId) async {
    var typography = CustomTypography(context);
    try {
      isLoading = true;
      notifyListeners();
      String url = "${AppConstant.EDIT_CAMPUS}";
      ApiService apiService = ApiService(url);
      // Create data payload
      final data = {
        "data": {
          "campus_name": campusId,
          "campus_id": campusKey,
        }
      };
      var body = data;
      var response = await apiService.patch(body);
      if (response.containsKey('result')) {
        //result = LocationProfileModel.fromJson(response['result']);
        subdestinations = locationProfile?.subdestinations ?? [];
      } else {
        locationProfile = null;
        grapDataProfile = null;
        subdestinations = [];
      }

      isLoading = false;
      notifyListeners();
    } on BackendException catch (e, stackTrace) {
      isLoading = false;
      print(e);
      print(stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message, style: typography.Body1),
      ));
    } catch (e, stackTrace) {
      isLoading = false;
      print(e);
      print(stackTrace);
      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      //   content: Text(e.toString(), style: typography.Body1),
      // ));
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Change Occupancy

/*
Request URL:
https://us-central1-project-green-f4d78.cloudfunctions.net/locations/rented
Request Method:
PATCH
{
  "data": {
    "location_id": "bUysRMYYFTaQJiti48u1",
    "rented": true,
    "base_location_id": "B6tQ2lb3MRwirg9LtKJl"
  }
}
 */

  Future<bool> changeOccupancy(BuildContext context, String locationId,
      bool rented, String baseLocationId) async {
    var typography = CustomTypography(context);
    try {
      isLoading = true;
      notifyListeners();
      String url = "${AppConstant.CHANGE_OCCUPANCY}";
      ApiService apiService = ApiService(url);

      // Create data payload
      final data = {
        "data": {
          "location_id": locationId,
          "rented": rented,
          "base_location_id": baseLocationId,
        }
      };
      var body = data;
      var response = await apiService.patch(body);

      if (response.containsKey('subdestination')) {
        // Process the result if present
        subdestinations = locationProfile?.subdestinations ?? [];
        return true; // Indicate success
      } else {
        locationProfile = null;
        subdestinations = [];
        return false; // Indicate failure
      }
    } on BackendException catch (e, stackTrace) {
      print(e);
      print(stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message, style: typography.Body1),
      ));
      return false; // Indicate failure
    } catch (e, stackTrace) {
      print(e);
      print(stackTrace);
      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      //   content: Text(e.toString(), style: typography.Body1),
      // ));
      return false; // Indicate failure
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
