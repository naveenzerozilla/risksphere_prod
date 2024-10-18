import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:green/design_system/primitives/custom_typography.dart';
import 'package:green/models/account_list_model.dart';
import 'package:green/models/location_list_model.dart';
import 'package:green/models/my_location_list_model.dart';
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

import '../service/language_service.dart';

class MyLocationListProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  set isLoading(bool value) {
    _isLoading = value;
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  bool _isCertifiedLoading = false;
  bool get isCertifiedLoading => _isCertifiedLoading;
  set isCertifiedLoading(bool value) {
    _isCertifiedLoading = value;
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

  List<String> _countries = [];
  String _state = '';
  List<String> _propertyType = [];
  List<String> _constructionType = [];
  List<String> _certifications = [];
  List<String> _hazard = [];
  List<int> _rating = [];

  // Getters for the filter values
  List<String> get countries => _countries;
  String get state => _state;
  List<String> get propertyType => _propertyType;
  List<String> get constructionType => _constructionType;
  List<String> get certifications => _certifications;
  List<String> get hazard => _hazard;
  List<int> get rating => _rating;
  String _zipcode = '';
  String get zipcode => _zipcode;
  set zipcode(String value) {
    _zipcode = value;
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

  int _totalPages = 1;
  int get totalPages => _totalPages;
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

  List<Location> _certifiedLocationList = [];
  List<Location> get certifiedLocationList => _certifiedLocationList;
  set certifiedLocationList(List<Location> value) {
    _certifiedLocationList = value;
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // Method to add to the certified location list
  void addToCertifiedLocationList(List<Location> newLocations) {
    _certifiedLocationList.addAll(newLocations);
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

  int locationHits = 0;
  int certifiedLocationHits = 0;


  bool isCertifiedTabAllowed() {
    return _rating.isEmpty || _rating.contains(5);
  }

  /// Pagination variables
  String? locationListPageToken;
  String? locationListDirection;
  bool locationListNextPageExists = true;

  String? certifiedLocationListPageToken;
  String? certifiedLocationListDirection;
  bool certifiedLocationListNextPageExists = true;



  Future<void> fetchCampusIds(String accountId, String subAccountId, String sovId) async {
    final url = Uri.parse("https://us-central1-project-green-f4d78.cloudfunctions.net/accounts/$accountId/subaccount/$subAccountId/sov/$sovId/location?pageSize=10&campus_id_list=true");

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
    }
    catch (e, stackTrace) {
      print(stackTrace);
      print("Error fetching campus IDs: $e");
    }
  }

  /// Fetch sov list with pagination, search query, and filters
  Future<void> fetchLocationList(
      BuildContext context,
      String searchQuery,
      int page,
      String direction,
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
    var typography = CustomTypography(context);
    try {
      // Check if api is already working
      if (isLoading||isNextPageLoading) return;
      // dont call api is next page does not exist
      if (page>totalPages) return;
      if (page == 0) {
        myLocationList = [];
        isLoading = true;
      } else {
        isNextPageLoading = true;
      }

      var headers =  await CommonHeaders.createHeaders();

      print("Rating for all tab: $_rating");
      log(headers.toString());

      var url = AppConstant.MY_LOCATION +
          "?page=$page&pageSize=$pageSize";

      if (countries.isNotEmpty) {
        url+= "&countryOptions=${countries.join(",")}";
      }
      if (state.isNotEmpty) {
        url+= "&state=$state";
      }
      if (propertyType.isNotEmpty) {
        url+= "&propertyType=${propertyType.join(",")}";
      }
      if (constructionType.isNotEmpty) {
        url+= "&constructionType=${constructionType.join(",")}";
      }
      if (certifications.isNotEmpty) {
        url+= "&certifications=${certifications.join(",")}";
      }
      if (hazard.isNotEmpty) {
        url+= "&hazard=${hazard.join(",")}";
      }
      if (rating.isNotEmpty) {
        url+= "&rating=${rating.join(",")}";
      }
      if (zipcode.isNotEmpty) {
        url+= "&zipcode=$zipcode";
      }
      if (_selectedCampusIds.isNotEmpty) {
        url+= "&campus_id=${_selectedCampusIds.join(",")}";
      }


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
        MyLocationModel locationListModel = MyLocationModel.fromJson(jsonResponse);
        locationHits = locationListModel.totalRecords ?? 0;
        certifiedLocationHits = locationListModel.totalAutoCertified ?? 1;
        totalPages = locationHits ~/ pageSize;
        //summaryList = locationListModel.summaryList ?? [];
        //mainSovRating = locationListModel. ?? 0.0;
        if (page == 0) {
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          e.message,
          style: typography.Body1,
        ),
      ));
    } catch (e, stackTrace) {
      isLoading = false;
      isNextPageLoading = false;
      print(stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          e.toString(),
          style: typography.Body1,
        ),
      ));
    }
  }

  /// Fetch sov list with pagination, search query, and filters
  Future<void> fetchCertifiedLocationList(
      BuildContext context,
      String searchQuery,
      int page,
      int pageSize, {
        String type = "",
      }) async {
    var typography = CustomTypography(context);
    try {
      print("condition: ${rating.isNotEmpty && !rating.contains(5)}");
      print("rating: $rating");
     /* if (rating.isNotEmpty && !rating.contains(5)) {
        // If the rating filter is not set to 5, set certifiedLocationHits to 0 and skip fetching
        certifiedLocationHits = 0;
        certifiedLocationList = [];
        notifyListeners();
        return;
      }*/
      if(page>certifiedTotalPages) return;
      if (page == 0) {
        isCertifiedLoading = true;
      } else {
        isNextPageCertifiedLoading = true;
      }

      var headers =  await CommonHeaders.createHeaders();

      log(headers.toString());
      /*  var ratingLocal = [];
      if (ratingLocal.isEmpty) {
        ratingLocal = [5];
      }else if (!ratingLocal.contains(5)) {
        ratingLocal.add(5);
      }*/
      print(_countries);
      /*var body = json.encode({
        "data": {
          "search": searchQuery,
          "countryOptions": _countries,
          "state": _state,
          "propertyType": _propertyType,
          "constructionType": _constructionType,
          "certifications": _certifications,
          "hazard": _hazard,
          //if rating 5 not present, we add 5 as default
          "rating": ratingLocal,
          "zipcode": zipcode,
          "campus_id": _selectedCampusIds,
        }
      });*/
      var url = AppConstant.MY_LOCATION +
          "?page=$page&pageSize=$pageSize&rating=5";
      if (countries.isNotEmpty) {
        url+= "&countryOptions=${countries.join(",")}";
      }
      if (state.isNotEmpty) {
        url+= "&state=$state";
      }
      if (propertyType.isNotEmpty) {
        url+= "&propertyType=${propertyType.join(",")}";
      }
      if (constructionType.isNotEmpty) {
        url+= "&constructionType=${constructionType.join(",")}";
      }
      if (hazard.isNotEmpty) {
        url+= "&hazard=${hazard.join(",")}";
      }
      if (zipcode.isNotEmpty) {
        url+= "&zipcode=$zipcode";
      }
      if (_selectedCampusIds.isNotEmpty) {
        url+= "&campus_id=${_selectedCampusIds.join(",")}";
      }
      print(url);
      var uri = Uri.parse(url);


      var response = await http.get(
        uri,
        headers: headers,
      );
      print(response.body);
      print(response.statusCode);

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        LocationListModel locationListModel = LocationListModel.fromJson(jsonResponse);
        certifiedLocationHits = locationListModel.totalHits ?? 0;
        totalPages = locationListModel.totalPages ?? 1;
        summaryList = locationListModel.summaryList ?? [];
        if (page == 0) {
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          e.message,
          style: typography.Body1,
        ),
      ));
    } catch (e, stackTrace) {
      isCertifiedLoading = false;
      isNextPageCertifiedLoading = false;
      print(stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          e.toString(),
          style: typography.Body1,
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
      Navigator.pop(context);
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

  // Add this method for deleting locations
  Future<void> deleteLocations(
      BuildContext context,
      String accountId,
      String subAccountId,
      String sovId,
      List<Map<String, String>> locationList,
      ) async {
    try {
      isDeleteLocationLoading = true;
      var headers = await CommonHeaders.createHeaders();
      var body = json.encode({"data": {"location_list": locationList}});

      var url = Uri.parse(AppConstant.ADD_ACCOUNT +
          "?bulk_delete_location_list=true");
      log(url.toString());

      var response = await http.delete(
        url,
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        log("Locations deleted successfully.");
        CustomToast.success(context, jsonDecode(response.body)["message"]);
        // remove the deleted locations from the list and update respective list counters
        locationList.forEach((element) {
          if (_locationListOld.any((location) => location.locationId == element["location_id"])) {
            // only decrement if present in the location list
            if (_locationListOld.any((location) => location.locationId == element["location_id"])) {
              locationHits--;
            }
            _locationListOld.removeWhere((location) => location.locationId == element["location_id"]);
            if (_certifiedLocationList.any((location) => location.locationId == element["location_id"])) {
              certifiedLocationHits--;
            }

            _certifiedLocationList.removeWhere((location) => location.locationId == element["location_id"]);

          }
        });
        notifyListeners();

      } else {
        log("Failed to delete locations: ${response.body}");
        CustomToast.success(context, jsonDecode(response.body)["message"]);
      }
    } on BackendException catch (e) {
      log("Error deleting locations: ${e.message}");
      CustomToast.success(context, jsonDecode(e.message));
      throw e;
    }
    catch (e) {
      log("Error deleting locations: $e");
      CustomToast.success(context, "Error deleting locations: $e");
      throw e;
    } finally {
      isDeleteLocationLoading = false;
    }
  }


  /// Upload SOV
  Future<String> uploadSovAccount(BuildContext context, File sovFile,String accountId, String subAccountId, String sovId) async {
    var typography = CustomTypography(context);
    try {
      isImageUploadLoading = true;
      ApiService apiService = ApiService(AppConstant.UPLOAD_SOV_SUB_ACCOUNT + '/upload');
      print(apiService);
      // Send a POST request to the API to upload the image
      Map<String, dynamic> response = await apiService.postMultiPartSOVPartial(sovFile, accountId, subAccountId, sovId);
      // print(response!.message.toString());
      isImageUploadLoading = false;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          response['message']??LanguageService.getTranslated(context, "sub_account_list_app_sov_upload_success"),
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
    }on BackendException catch (e) {
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
    }

    catch (e) {
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

}

