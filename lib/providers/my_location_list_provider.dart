import 'dart:developer';
import 'dart:io';
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

class MyLocationListProvider extends ChangeNotifier {
  bool _isLoading = false;
  int currentPage = 1;

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

  set isHeatMapGeneratingLive(bool value) {
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

  List<MyLocation> _myLocationList = [];

  List<MyLocation> get myLocationList => _myLocationList;

  set myLocationList(List<MyLocation> value) {
    _myLocationList = value;
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
  void toggleSelection(MyLocation location) {
    if (_selectedLocations.contains(location)) {
      _selectedLocations.remove(location);
    } else {
      _selectedLocations.add(location);
    }
    notifyListeners();
  }

  // Select all locations (you might want to replace `getAllLocations()` with the actual location list)
  void selectAllLocations(bool isCertified) {
    if (isCertified) {
      _selectedLocations.addAll(certifiedLocationList);
    } else {
      _selectedLocations.addAll(myLocationList);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // Clear selection
  void clearSelection() {
    _selectedLocations.clear();
    notifyListeners();
  }

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

  // Delete selected locations
  Future<void> deleteSelectedLocations(
      BuildContext context, String accountId, String subAccountId) async {
    // get the list of ids
    List<String> locationIds =
        _selectedLocations.map((location) => location.id ?? "").toList();
    deleteLocations(context, accountId, subAccountId, "", locationIds);
    clearSelection();
  }

  // Add selected locations to SOV
  Future<void> addSelectedToSOV(
      BuildContext context,
      String accountID,
      String subAccountID,
      String accountName,
      String subAccountName,
      TabController? masterTabController,
      [String? locationId]) async {
    // Implement your add to SOV logic here
    // Show pop up with account name an sub account name prefilled an non editable.. and user will select the sov name from autocomplete dropdown and enter comma separated location tags (optional)
    // On submit, call the addLocationToSOV method with the selected sov id and location ids
    await showAddToSOVDialog(context, accountID, subAccountID, accountName,
        subAccountName, masterTabController, locationId);
    clearSelection();
  }

  // Add tags to selected locations
  Future<void> addTagsToSelectedLocations(
      BuildContext context, String accountId, String subAccountId,
      [String? locationId]) async {
    // get the list of ids
    await showAddTagDialog(
        context,
        accountId,
        subAccountId,
        locationId == null
            ? _selectedLocations.map((location) => location.id ?? "").toList()
            : [locationId]);

    clearSelection();
  }

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
      CustomToast.error(context, e.message);
    } catch (e, stackTrace) {
      log("Error adding location to SOV: $e");
      log(e.toString());
      log(stackTrace.toString());
      // CustomToast.error(context, e.toString());
    } finally {
      isAddToSOVLoading = false;
    }
  }

  // Add Tags to location
  Future<void> addTagsToLocation(BuildContext context, String accountId,
      String subAccountId, List<String> locationId, List<String> tags) async {
    try {
      isAddTagsLoading = true;
      ApiService apiService = ApiService(AppConstant.MY_LOCATION + "/tags");
      var body = {
        "data": {
          "account_id": accountId,
          "sub_account_id": subAccountId,
          "location_list": locationId,
          "tags": tags
        }
      };
      var response = await apiService.post(body);
      log(response.toString());
      CustomToast.success(context, response['message']);
      Navigator.pop(context);
    } on BackendException catch (e, stackTrace) {
      log("Error adding tags to location: ${e.message}");
      log(stackTrace.toString());
      CustomToast.error(context, e.message);
    } catch (e, stackTrace) {
      log("Error adding tags to location: $e");
      log(e.toString());
      log(stackTrace.toString());
      // CustomToast.error(context, e.toString());
    } finally {
      isAddTagsLoading = false;
    }
  }

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
      ApiService apiService = ApiService('${AppConstant.GLOBAL_SEARCH}/$query');

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
    var typography = CustomTypography(context);
    try {
      isAllLocationLoading = true;

      var headers = await CommonHeaders.createHeaders();

      print("Rating for all tab: $_rating. $rating");
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
        MyLocationModel locationListModel =
            MyLocationModel.fromJson(jsonResponse);
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

  /// Fetch sov list with pagination, search query, and filters
  Future<void> fetchLocationList(
      BuildContext context,
      String searchQuery,
      int page,
      int pageSize,
      String? accountID,
      String? subAccountID,
      String? processId,
      String? subProcessId,
      [String? sovID]) async {
    var typography = CustomTypography(context);
    try {
      // print('Api called page and total page are $page and $totalPages');
      // Check if api is already working
      // if (isLoading || isNextPageLoading) return;
      // dont call api is next page does not exist
      print(totalPages.toString());
      if (page - 1 > totalPages) return;
      if (page == 1) {
        myLocationList = [];
        isLoading = true;
      } else {
        isNextPageLoading = true;
      }

      var headers = await CommonHeaders.createHeaders();

      print("Rating for all tab: $_rating. $rating");
      log(headers.toString());

      var url;
      if (sovID != null) {
        url = AppConstant.MY_LOCATION +
            "?page=$page&pageSize=$pageSize&account_id=$accountID&sub_account_id=$subAccountID&sov_id=$sovID";
      } else {
        url = AppConstant.MY_LOCATION +
            "?page=$page&pageSize=$pageSize&account_id=$accountID&sub_account_id=$subAccountID";
      }
      if (countries.isNotEmpty) {
        url += "&country=${countries.join(",")}";
      }
      if (zipcode.isNotEmpty) {
        url += "&zip=$state";
      }
      if (sortBy.isNotEmpty) {
        url += "&sort=$sortBy";
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
        /*for (var hazard in hazardRatings.keys) {
          url += "&hazard=${jsonEncode(hazardRatings[hazard])}";
        }*/
        // we pass it in as json
        url += "&hazard=${jsonEncode(hazardRatings)}";
      }
      if (rating.isNotEmpty) {
        url += "&score=${rating.join(",")}";
      }

      if (_selectedCampusIds.isNotEmpty) {
        url += "&campus_id=${_selectedCampusIds.join(",")}";
      }

      if (processId != null) {
        url += "&process_id=$processId";
      }

      if (subProcessId != null) {
        url += "&sub_process_id=$subProcessId";
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
        MyLocationModel locationListModel =
            MyLocationModel.fromJson(jsonResponse);
        locationHits = locationListModel.totalRecords ?? 0;
        certifiedLocationHits = locationListModel.totalCertified ?? 0;
        isConflict = locationListModel.isConflict!;
        isHazardCanStart = locationListModel.isHazardCanStart!;
        isAnyLocationSelected = locationListModel.isAnyHazardProcessing!;

        totalPages = locationHits ~/ pageSize;
        //summaryList = locationListModel.summaryList ?? [];
        //mainSovRating = locationListModel. ?? 0.0;
        if (page == 1) {
          myLocationList = locationListModel.results ?? [];
        } else {
          addToMyLocationList(locationListModel.results ?? []);
        }
        log(myLocationList.toString());
        print("totalPages: $totalPages");
        log(page.toString());
      } else {
        print(json.decode(response.body)["error"]);
        throw Exception('Failed to load data');
      }
      isLoading = false;
      isNextPageLoading = false;
    } on BackendException catch (e, stackTrace) {
      isLoading = false;
      isNextPageLoading = false;
      print(stackTrace);
      print(e.message);
      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      //   content: Text(
      //     e.message,
      //     style: typography.Body1,
      //   ),
      // ));
    } catch (e, stackTrace) {
      isLoading = false;
      isNextPageLoading = false;
      print(stackTrace);
      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      //   content: Text(
      //     "Error fetching data",
      //     style: typography.Body1,
      //   ),
      // ));
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
      String? subProcessId,
      [String? sovID]) async {
    var typography = CustomTypography(context);
    try {
      print("Condition: Certified fetch with rating 5");
      print("Rating: 5");

      if (page - 1 > certifiedTotalPages) return;
      if (page == 1) {
        isCertifiedLoading = true;
      } else {
        isNextPageCertifiedLoading = true;
      }

      var headers = await CommonHeaders.createHeaders();
      log(headers.toString());

      // Construct the URL with default rating=5
      var url;
      if (sovID != null) {
        url = AppConstant.MY_LOCATION +
            "?page=$page&pageSize=$pageSize&score=5&account_id=$accountID&sub_account_id=$subAccountID&sov_id=$sovID";
      } else {
        url = AppConstant.MY_LOCATION +
            "?page=$page&pageSize=$pageSize&score=5&account_id=$accountID&sub_account_id=$subAccountID";
      }

      if (countries.isNotEmpty) {
        url += "&country=${countries.join(",")}";
      }
      if (zipcode.isNotEmpty) {
        url += "&zip=$state";
      }
      print("Certifications: $certifications");

      if (certifications.isNotEmpty) {
        for (var cert in certifications) {
          if (cert == "Manual Certified") {
            url += "&manual_certified=true";
          } else if (cert == "Auto Certified") {
            url += "&auto_certified=true";
          }
        }
      }
      print("Hazard Ratings: $hazardRatings");
      if (hazardRatings.isNotEmpty) {
        for (var hazard in hazardRatings.keys) {
          url += "&hazard=${jsonEncode(hazardRatings[hazard])}";
        }
      }

      if (_selectedCampusIds.isNotEmpty) {
        url += "&campus_id=${_selectedCampusIds.join(",")}";
      }

      if (processId != null) {
        url += "&process_id=$processId";
      }

      if (subProcessId != null) {
        url += "&sub_process_id=$subProcessId";
      }

      print(url);
      var uri = Uri.parse(url);

      var response = await http.get(uri, headers: headers);
      print(response.body);
      print(response.statusCode);

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        MyLocationModel locationListModel =
            MyLocationModel.fromJson(jsonResponse);
        certifiedLocationHits = locationListModel.totalCertified ?? 0;
        totalPages = locationListModel.totalRecords ?? 1;

        print(totalPages.toString());
        //summaryList = locationListModel.summaryList ?? [];
        if (page == 1) {
          certifiedLocationList = locationListModel.results ?? [];
        } else {
          addToCertifiedLocationList(locationListModel.results ?? []);
        }
        log(certifiedLocationList.toString());
        log(totalPages.toString());
        log(page.toString());
      } else {
        print(json.decode(response.body)["error"]);
        throw Exception('Failed to load data');
      }
      isCertifiedLoading = false;
      isNextPageCertifiedLoading = false;
    } on BackendException catch (e, stackTrace) {
      isCertifiedLoading = false;
      isNextPageCertifiedLoading = false;
      print(stackTrace);
      print(e.message);
      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      //   content: Text(
      //     e.message,
      //     style: typography.Body1,
      //   ),
      // ));
    } catch (e, stackTrace) {
      isCertifiedLoading = false;
      isNextPageCertifiedLoading = false;
      print(stackTrace);
      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      //   content: Text(
      //     e.toString(),
      //     style: typography.Body1,
      //   ),
      // ));
    }
  }

  // Add this method for deleting locations
  Future<void> deleteLocations(
    BuildContext context,
    String accountId,
    String subAccountId,
    String sovId,
    List<String> locationList, // Now a list of strings (location_id)
  ) async {
    try {
      isDeleteLocationLoading = true;

      var headers = await CommonHeaders.createHeaders();

      // Prepare the body as a list of objects with individual location_id
      var body; /*= json.encode({
        "data": locationList.map((locationId) {
          return {
            "location_id": locationId,
            // Uncomment the following if needed when `from_location_list` is false:
            // "account_id": accountId,
            // "sub_account_id": subAccountId,
            // "sov_id": "REqI5iQpNzA2qFQ7A4Uo", // Add sov_id when necessary
          };
        }).toList(),
      });*/
      if (sovId == '') {
        body = json.encode({
          "data": locationList.map((locationId) {
            return {
              "location_id": locationId,
              // Uncomment the following if needed when `from_location_list` is false:
              // "account_id": accountId,
              // "sub_account_id": subAccountId,
              // "sov_id": "REqI5iQpNzA2qFQ7A4Uo", // Add sov_id when necessary
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
              // Uncomment the following if needed when `from_location_list` is false:
              // "account_id": accountId,
              // "sub_account_id": subAccountId,
              // "sov_id": "REqI5iQpNzA2qFQ7A4Uo", // Add sov_id when necessary
            };
          }).toList(),
        });
      }
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

        // Remove the deleted locations from the local list and update respective counters
        locationList.forEach((locationId) {
          // Remove locations from the list if they match any in _locationListOld
          if (_myLocationList.any((location) => location.id == locationId)) {
            // Decrement the hit counter if the location exists
            locationHits--;
            _myLocationList
                .removeWhere((location) => location.id == locationId);
          }
        });
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
                                labelText: "Name of the SoV2",
                                border: const OutlineInputBorder(),
                                suffixIcon: Icon(Icons.search),
                              ),
                            ),
                            if (sovController.text.isNotEmpty)
                              AutocompleteOptionsSovs(
                                options: sovProvider.filteredAutoCompleteList,
                                onSelected: (SovAccount selection) {
                                  setState(() {
                                    selectedSovId = selection.id ?? "";
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
                                  ? Center(
                                      child: CircularProgressIndicator(),
                                    )
                                  : CustomButton(
                                      onPressed: () async {
                                        if (sovController.text.isEmpty) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(SnackBar(
                                            content: Text(
                                              "Please select or enter an SoV name.",
                                              style: typography.Body1,
                                            ),
                                          ));
                                          return;
                                        }

                                        // Prepare the body with location, account, sub-account, and sov details
                                        Map<String, dynamic> body = {
                                          "location_list": locationId == null
                                              ? _selectedLocations
                                                  .map(
                                                      (location) => location.id)
                                                  .toList()
                                              : [locationId],
                                          "account_id": accountID,
                                          "sub_account_id": subAccountID,
                                          "sov": {
                                            "sov_id": selectedSovId,
                                            // Empty if creating new SoV
                                            "sov_name": sovController.text,
                                            // Mandatory if creating new SoV
                                          }
                                        };

                                        // Call your method to add the location to the SoV
                                        await addLocationToSOV(context, body);

                                        setState(() {
                                          masterTabController?.animateTo(1);
                                        });
                                      },
                                      child: Text(
                                        "Add",
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
    ).then((_) {
      // Clear the input fields after dialog is closed
      sovController.clear();
      tagsController.clear();
      selectedSovId = "";
    });
  }

  Future<void> showAddTagDialog(BuildContext context, String accountId,
      String subAccountId, List<String> locationId) async {
    var typography = CustomTypography(context);
    TextEditingController tagsController = TextEditingController();

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
                      "Add Tags",
                      style: typography.H5_Regular.copyWith(height: 1.5),
                    ),
                    SizedBox(height: 16.0),
                    // Comma-separated Tags (Optional)
                    TextField(
                      controller: tagsController,
                      decoration: InputDecoration(
                        labelText: "Enter comma-separated tags",
                        border: const OutlineInputBorder(),
                      ),
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
                                child: myLocationListProvider.isAddTagsLoading
                                    ? Center(
                                        child: CircularProgressIndicator(),
                                      )
                                    : CustomButton(
                                        onPressed: () async {
                                          if (tagsController.text.isEmpty) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(SnackBar(
                                              content: Text(
                                                "Please enter tags.",
                                                style: typography.Body1,
                                              ),
                                            ));
                                            return;
                                          }

                                          // Call your method to add the location to the SoV
                                          await addTagsToLocation(
                                              context,
                                              accountId,
                                              subAccountId,
                                              locationId,
                                              tagsController.text.split(","));
                                          //Locally update the tags
                                          locationId.forEach((element) {
                                            MyLocation location =
                                                getLocationById(element);
                                            // Check if already empty or add to the existing tags
                                            if (location.tags == null) {
                                              location.tags = tagsController
                                                  .text
                                                  .split(",");
                                            } else {
                                              location.tags?.addAll(
                                                  tagsController.text
                                                      .split(","));
                                            }
                                          });
                                          locationId.forEach((element) {
                                            MyLocation location =
                                                getCertifiedLocationById(
                                                    element);
                                            if (location.tags == null) {
                                              location.tags = tagsController
                                                  .text
                                                  .split(",");
                                            } else {
                                              location.tags?.addAll(
                                                  tagsController.text
                                                      .split(","));
                                            }
                                          });
                                          fullLocationList.forEach((element) {
                                            MyLocation location = element;
                                            if (location.tags == null) {
                                              location.tags = tagsController
                                                  .text
                                                  .split(",");
                                            } else {
                                              location.tags?.addAll(
                                                  tagsController.text
                                                      .split(","));
                                            }
                                          });
                                        },
                                        child: Text(
                                          "Add",
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
                      );
                    }),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      // Clear the input fields after dialog is closed
      tagsController.clear();
    });
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
                                          // Call your method to add the location to the SoV
                                          await deleteTagFromLocation(
                                              context,
                                              accountId,
                                              subAccountId,
                                              locationId,
                                              tag);
                                          //Locally update the tags
                                          try {
                                            MyLocation location =
                                                getLocationById(locationId);
                                            location.tags?.remove(tag);
                                            MyLocation certifiedLocation =
                                                getCertifiedLocationById(
                                                    locationId);
                                            certifiedLocation.tags?.remove(tag);
                                            fullLocationList.forEach((element) {
                                              MyLocation location = element;
                                              location.tags?.remove(tag);
                                            });
                                          } catch (e) {
                                            print(e);
                                          }
                                        },
                                        child: Text(
                                          "Delete",
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
          sovFile, accountId, subAccountId, sovId, tags, sovName);
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: typography.Body1,
          ),
        ),
      );

      return ''; // Return an empty string or handle the error as needed
    } catch (e, stackTrace) {
      print(stackTrace);
      print("Error uploading SOV: $e");
      // Handle other unexpected exceptions
      Navigator.pop(context);
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text(
      //       '${e.toString()}',
      //       style: typography.Body1,
      //     ),
      //   ),
      // );
      isImageUploadLoading = false;
      return ''; // Return empty string or handle the error as needed
    }
  }

  MyLocation getLocationById(String locationId) {
    return myLocationList.firstWhere((element) => element.id == locationId);
  }

  MyLocation getCertifiedLocationById(String locationId) {
    return certifiedLocationList
        .firstWhere((element) => element.id == locationId);
  }

  Future<void> fetchCampusIds(
      String accountId, String subAccountId, String sovId) async {
    final url = Uri.parse(
        "https://us-central1-project-green-f4d78.cloudfunctions.net/accounts/$accountId/subaccount/$subAccountId/sov/$sovId/location?pageSize=10&campus_id_list=true");

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

      print("Rating for all tab: $_rating. $rating");
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
        url += "&filter_by_location_id=$locationId";
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
        MyLocationModel locationListModel =
            MyLocationModel.fromJson(jsonResponse);
        print(locationListModel.page.toString());
        print(locationListModel.pageSize.toString());
        print("totalPages");
        //summaryList = locationListModel.summaryList ?? [];
        //mainSovRating = locationListModel. ?? 0.0;

        if (locationListModel.totalRecords != null) {
          // Assuming you are using a fixed page size (e.g., 1 from your URL)
          _totalPages = (locationListModel.totalRecords! / 1).ceil();
          notifyListeners();
        }
        if (locationId != null && locationId.isNotEmpty) {
          locationProfile = locationListModel.filterByLocationResult?.first;
          resetTotalPage = locationListModel.totalRecords ?? 1;
        } else {
          locationProfile = locationListModel.results?.first;
        }

        log(resetTotalPage.toString() ?? "");
        log(locationProfile?.toString() ?? "");
        print("totalcount: ${locationListModel.totalRecords}");
        print("totalPages1: $totalPages");
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
      isLoading = true;
      notifyListeners();

      String url =
          "${AppConstant.GET_LOCATION_PROFILE}/$accountId/subaccount/$subAccountId/sov/${sovId.isEmpty ? "undefined" : sovId}/location?location_id=$locationId&lat=$lat&lng=$lng&subdestination=true&place_id=$placeId";
      ApiService apiService = ApiService(url);

      var response = await apiService.get();

      if (response.containsKey('results')) {
        //result = LocationProfileModel.fromJson(response['result']);
        subdestinations = locationProfile?.subdestinations ?? [];
      } else {
        locationProfile = null;
        subdestinations = [];
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
          content: Text(e.message, style: typography.Body1),
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
