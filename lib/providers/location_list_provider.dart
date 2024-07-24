import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:green/design_system/primitives/custom_typography.dart';
import 'package:green/models/account_list_model.dart';
import 'package:green/models/location_list_model.dart';
import 'package:green/models/sov_list_model.dart';
import 'package:green/service/api_service.dart';
import 'package:green/utils/api_constants.dart';
import 'package:green/utils/common_headers.dart';
import '../design_system/components/custom_toast.dart';

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:green/design_system/primitives/custom_typography.dart';
import 'package:green/models/location_list_model.dart';
import 'package:green/service/api_service.dart';
import 'package:green/utils/api_constants.dart';

class LocationListProvider extends ChangeNotifier {
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

  bool _isAddLocationLoading = false;
  bool get isAddLocationLoading => _isAddLocationLoading;
  set isAddLocationLoading(bool value) {
    _isAddLocationLoading = value;
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
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

  List<Location> _locationList = [];
  List<Location> get locationList => _locationList;
  set locationList(List<Location> value) {
    _locationList = value;
    WidgetsBinding.instance!.addPostFrameCallback((_) {
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

  void addToLocationList(List<Location> newLocations) {
    _locationList.addAll(newLocations);
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  int locationHits = 0;

  /// Fetch sov list with pagination, search query, and filters
  Future<void> fetchLocationList(
      BuildContext context,
      String selectedAccountId,
      String selectedSubAccountId,
      String selectedSovId,
      String searchQuery,
      int page,
      int pageSize, {
        String type = "",
        List<String> countries = const [],
        String state = "",
        List<String> propertyType = const [],
        List<String> constructionType = const [],
        List<String> certifications = const [],
        List<String> hazard = const [],
        List<int> rating = const [],
      }) async {
    try {
      if (page == 0) {
        isLoading = true;
      } else {
        isNextPageLoading = true;
      }

      var headers =  await CommonHeaders.createHeaders();

      log(headers.toString());
      var body = json.encode({"data":{
        "search": searchQuery,
        "countryOptions": countries,
        "state": state,
        "propertyType": propertyType,
        "constructionType": constructionType,
        "certifications": certifications,
        "hazard": hazard,
        "rating": rating,
      }});

      log(body);
      var url = Uri.parse(AppConstant.GET_SOV_LIST +
          "/$selectedAccountId/subaccount/$selectedSubAccountId/sov/$selectedSovId/location?page=$page&pageSize=$pageSize");
      log(url.toString());

      var response = await http.post(
        url,
        headers: headers,
        body: body,
      );
      print(response.body);
      print(response.statusCode);

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        LocationListModel locationListModel = LocationListModel.fromJson(jsonResponse);
        locationHits = locationListModel.totalHits ?? 0;
        totalPages = locationListModel.totalPages ?? 1;
        summaryList = locationListModel.summaryList ?? [];
        if (page == 0) {
          locationList = locationListModel.results ?? [];
        } else {
          addToLocationList(locationListModel.results ?? []);
        }
        log(locationList.toString());
        log(totalPages.toString());
        log(page.toString());
      } else {
        throw Exception('Failed to load data');
      }
      isLoading = false;
      isNextPageLoading = false;
    } on BackendException catch (e, stackTrace) {
      isLoading = false;
      isNextPageLoading = false;
      print(stackTrace);
      print(e.message);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          e.message,
          style: CustomTypography.Body1,
        ),
      ));
    } catch (e, stackTrace) {
      isLoading = false;
      isNextPageLoading = false;
      print(stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          e.toString(),
          style: CustomTypography.Body1,
        ),
      ));
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
      ApiService apiService = ApiService(AppConstant.ADD_LOCATION +
          "/$accountId/subaccount/$subAccountId/sov/$sovId/location");
      var response = await apiService.post(body);
      log(response.toString());
      CustomToast.success(context, response['message']);
      isAddLocationLoading = false;
      return true;
    } on BackendException catch (e) {
      isAddLocationLoading = false;
      CustomToast.error(context, e.message);
      return false;
    } catch (e) {
      isAddLocationLoading = false;
      CustomToast.error(context, e.toString());
      return false;
    }
  }
}

