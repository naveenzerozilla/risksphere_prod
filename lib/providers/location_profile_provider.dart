import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:green/design_system/primitives/custom_typography.dart';
import 'package:green/models/location_profile_model.dart';
import 'package:green/screens/listings/location_list.dart';
import 'package:green/screens/listings/location_profile_preview.dart';
import 'package:green/service/api_service.dart';
import 'package:green/utils/api_constants.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../models/location_list_model.dart';
import '../utils/common_headers.dart';
import 'location_list_provider.dart';

class LocationProfileProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool _isUploadingImage = false;

  bool get isLoading => _isLoading;

  bool get isUploadingImage => _isUploadingImage;

  set isLoading(bool value) {
    _isLoading = value;
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  set isUploadingImage(bool value) {
    _isUploadingImage = value;
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  LocationProfileModel? _result;

  LocationProfileModel? get result => _result;

  set result(LocationProfileModel? value) {
    _result = value;
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  List<Subdestination> _subdestinations = [];

  List<Subdestination> get subdestinations => _subdestinations;

  set subdestinations(List<Subdestination> value) {
    _subdestinations = value;
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  String? _totalPages;
  String? get totalPages => _totalPages;
  set totalPages(String? value) {
    _totalPages = value;
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  Future<void> fetchLocationDetails(BuildContext context, String accountId,
      String subAccountId, String sovId, String searchQuery, String page, String totalPages) async {
    var typography = CustomTypography(context);
    try {
      print('page: $page');
      print('totalPages: $totalPages');
    /*  if (((int.tryParse(page)??0)) >= (int.tryParse(totalPages)?? 1)) {
        return;
      }*/
      isLoading = true;
      var locationListProvider  = Provider.of<LocationListProvider>(context, listen: false);
      var headers =  await CommonHeaders.createHeaders();

      log(headers.toString());
      var body = json.encode({
        "data": {
          "search": searchQuery,
          "countryOptions": locationListProvider.countries,
          "state": locationListProvider.state,
          "propertyType": locationListProvider.propertyType,
          "constructionType": locationListProvider.constructionType,
          "certifications": locationListProvider.certifications,
          "hazard": locationListProvider.hazard,
          "rating": locationListProvider.rating,
          "campus_id": [],
          "zipcode": locationListProvider.zipcode,
        }
      });

      log(body);
      var url = Uri.parse(AppConstant.GET_SOV_LIST +
          "/$accountId/subaccount/$subAccountId/sov/$sovId/location?page=$page&pageSize=1");
      print(url.toString());

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
        if (locationListModel.results == null || locationListModel.results!.isEmpty) {
          subdestinations = [];
        } else {
          subdestinations =
              (locationListModel.results ?? [])?[0].subdestinations ?? [];
        }
        print('latitude: ${locationListModel.results?[0].latitude}');
        print('longitude: ${locationListModel.results?[0].longitude}');
        result = LocationProfileModel(
          locationId: locationListModel.results?[0].locationId,
          locationName: locationListModel.results?[0].locationName,
          accountId: accountId,
          subAccountId: subAccountId,
          sovId: sovId,
          subdestinations: subdestinations,
          locationIdForRef: locationListModel.results?[0].locationIdForRef,
          country: locationListModel.results?[0].country,
          city: locationListModel.results?[0].city,
          state: locationListModel.results?[0].state,
          zip: locationListModel.results?[0].zip,
          address: locationListModel.results?[0].address,
          latitude: locationListModel.results?[0].latitude,
          longitude: locationListModel.results?[0].longitude,
          locationType: locationListModel.results?[0].locationType,
          description: locationListModel.results?[0].description,
          ownerEmail: locationListModel.results?[0].ownerEmail,
          ownerId: locationListModel.results?[0].ownerId,
          ownerName: locationListModel.results?[0].ownerName,
          autoCertified: locationListModel.results?[0].autoCertified,
          campusId: locationListModel.results?[0].campusId,
          percent: locationListModel.results?[0].percent,
          score: locationListModel.results?[0].score,
          placeTypes: locationListModel.results?[0].placeTypes,
          screenShots: locationListModel.results?[0].screenShots,
          placeId: locationListModel.results?[0].placeId,
        );
        totalPages = locationListModel.totalPages.toString();
        print('totalPagesMain: $totalPages');
      } else {
        print(json.decode(response.body)["error"]);
        throw Exception('Failed to load data');
      }





      isLoading = false;
    } on BackendException catch (e, stackTrace) {

      isLoading = false;
      print(stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message, style: typography.Body1),
      ));
    } catch (e, stackTrace) {
      isLoading = false;
      print(stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString(), style: typography.Body1),
      ));
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
      ApiService apiService = ApiService(AppConstant.GET_LOCATION_PROFILE/*"https://da10-49-205-131-127.ngrok-free.app/project-green-f4d78/us-central1/accounts"*/ +
          "/$accountId/subaccount/$subAccountId/sov/$sovId/location?location_id=$locationId");

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
          "${AppConstant.GET_LOCATION_PROFILE}/$accountId/subaccount/$subAccountId/sov/$sovId/location?location_id=$locationId&lat=$lat&lng=$lng&subdestination=true&place_id=$placeId";
      ApiService apiService = ApiService(url);

      var response = await apiService.get();

      if (response.containsKey('result')) {
        //result = LocationProfileModel.fromJson(response['result']);
        subdestinations = result?.subdestinations ?? [];
      } else {
        result = null;
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString(), style: typography.Body1),
      ));
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addSubdestinationToSOV(BuildContext context, String accountId,
      String subAccountId, String sovId, String locationId, String subDestinationId) async {
    var typography = CustomTypography(context);
    try {
      isLoading = true;
      notifyListeners();

      String url =
          "${AppConstant.GET_LOCATION_PROFILE}/$accountId/subaccount/$subAccountId/sov/$sovId/location?location_id=$locationId";
      ApiService apiService = ApiService(url);
      // Retrieve the subdestination details from the list using the provided ID
      var subdestination = _subdestinations.firstWhere((sd) => sd.id == subDestinationId);

      var body = {
        "data": {
          "add_location": true,
          "location_id": locationId,
          "locations": [
            {
              "id": subdestination.id,
              "lat": subdestination.lat,
              "lng": subdestination.lng,
              "title": subdestination.name,
              "icon": "",
              "name": subdestination.name,
              "place_id": subdestination.placeId,
              "address": subdestination.address,
              "types": subdestination.types,
              "isMainLocation": false,
              "status": ""
            }
          ]
        }
      };

      var response = await apiService.post(body);

      if (response.containsKey('processed')) {
        //result = LocationProfileModel.fromJson(response['result']);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(response['message'] ?? "Subdestination added successfully", style: typography.Body1),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Failed to add subdestination", style: typography.Body1),
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString(), style: typography.Body1),
      ));
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addSelectedSubdestinationToSOV(BuildContext context, String accountId,
      String subAccountId, String sovId, String locationId, List<String> subDestinationId) async {
    var typography = CustomTypography(context);
    try {
      isLoading = true;
      notifyListeners();

      String url =
          "${AppConstant.GET_LOCATION_PROFILE}/$accountId/subaccount/$subAccountId/sov/$sovId/location?location_id=$locationId";
      ApiService apiService = ApiService(url);
      // Retrieve the subdestination details from the list using the provided ID
      var subdestinations = _subdestinations.where((sd) => subDestinationId.contains(sd.id)).toList();
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
          content: Text(response['message'] ?? "Subdestination added successfully", style: typography.Body1),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Failed to add subdestination", style: typography.Body1),
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString(), style: typography.Body1),
      ));
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeSubdestinationFromSOV(BuildContext context, String accountId,
      String subAccountId, String sovId, String locationId, String subDestinationId) async {
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
          content: Text(response['message'] ?? "Subdestination removed successfully", style: typography.Body1),
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString(), style: typography.Body1),
      ));
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String> updateLocationDetails(BuildContext context, String accountId,
      String subAccountId, String sovId, String locationId, Map<String, dynamic> data) async {
    var typography = CustomTypography(context);
    try {
      isLoading = true;
      notifyListeners();
      String url =
          "${AppConstant.GET_LOCATION_PROFILE}/$accountId/subaccount/$subAccountId/sov/$sovId/location";
      ApiService apiService = ApiService(url);
      var body = data;
      var response = await apiService.patch(body);
      if (response.containsKey('result')) {
        //result = LocationProfileModel.fromJson(response['result']);
        subdestinations = result?.subdestinations ?? [];
      } else {
        result = null;
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
          result?.locationId = resultLocation["location_data"]["location_id"];
          result?.locationName =
          resultLocation["location_data"]["location_name"];
          result?.locationType =
          resultLocation["location_data"]["location_type"];
          result?.description = resultLocation["location_data"]["description"];
          result?.address = resultLocation["location_data"]["address"];
          result?.city = resultLocation["location_data"]["city"];
          result?.state = resultLocation["location_data"]["state"];
          result?.zip = resultLocation["location_data"]["zip"];
          result?.country = resultLocation["location_data"]["country"];
          result?.latitude = resultLocation["location_data"]["latitude"];
          result?.longitude = resultLocation["location_data"]["longitude"];
          result?.ownerId = resultLocation["location_data"]["owner_id"];
          result?.ownerName = resultLocation["location_data"]["owner_name"];
          result?.ownerEmail = resultLocation["location_data"]["owner_email"];
          result?.autoCertified =
          resultLocation["location_data"]["auto_certified"];
          result?.campusId = resultLocation["location_data"]["campus_id"];
          result?.percent = resultLocation["location_data"]["percent"];
          result?.score = resultLocation["location_data"]["score"];

          result?.placeTypes = resultLocation["location_data"]["place_types"] is String
          ? [resultLocation["location_data"]["place_types"]]
              : (resultLocation["location_data"]["place_types"] as List?)?.map((item) => item as String).toList();
          result?.screenShots = resultLocation["location_data"]["screen_shots"]??[];
          subdestinations = result?.subdestinations ?? [];
          String accountName = resultLocation["location_data"]["account_name"];
          String subAccountName = resultLocation["location_data"]["sub_account_name"];
          String sovName = resultLocation["location_data"]["sov_name"];
          String page = "0";
          String totalPages = "1";
          String searchQuery = "";
          Navigator.push(context, MaterialPageRoute(builder: (_) =>
              LocationProfilePreview(accountId: accountId,
                  accountName: accountName,
                  subAccountId: subAccountId,
                  subAccountName: subAccountName,
                  sovId: sovId,
                  sovName: sovName,
                  page: page,
                  totalPages: totalPages,
                  searchQuery: searchQuery,
                toDeleteLocationId: toDeleteLocationId,
              )));
        } catch (e, stackTrace) {
          isLoading = false;
          print(e);
          print(stackTrace);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString(), style: typography.Body1),
          ));
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString(), style: typography.Body1),
      ));
      return false.toString();
    } finally {
      isLoading = false;
      notifyListeners();
      return true.toString();
    }
  }

  Future<bool> autocompleteUserConfirmation(BuildContext context, String accountId,
      String subAccountId, String sovId, String locationId) async {
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
          "location_id": locationId,
          "auto_complete": true,
        }
      };
      var body = data;
      var response = await apiService.post(body);
      if (response.containsKey('message')) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message'], style: typography.Body1)));
        // Back to location profile page
        Navigator.of(context).pop();
        // back to sov listing page
        Navigator.of(context).pop();
      } else {
        result = null;
        subdestinations = [];
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Location Merged", style: typography.Body1,)));

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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString(), style: typography.Body1),
      ));
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
      return true;
    }
  }


  Future<bool> updateLocationName(BuildContext context, String accountId,
      String subAccountId, String sovId, String locationId, String locationName) async {
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
          "location_name": locationName,
          "location_type": result?.locationType,
          "description": result?.description,
          "address": result?.address,
          "city": result?.city,
          "state": result?.state,
          "zip": result?.zip,
          "country": result?.country,
          "latitude": result?.latitude,
          "longitude": result?.longitude,
          "location_id": result?.locationId,
        }
      };
      var body = data;
      var response = await apiService.patch(body);
      if (response.containsKey('result')) {
        //result = LocationProfileModel.fromJson(response['result']);
        subdestinations = result?.subdestinations ?? [];
      } else {
        result = null;
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString(), style: typography.Body1),
      ));
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
      return true;
    }
  }

  Future<bool> updateLocationAddress(BuildContext context, String accountId,
      String subAccountId, String sovId, String locationId, String locationAddress) async {
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
          "location_name": result?.locationName,
          "location_type": result?.locationType,
          "description": result?.description,
          "address": locationAddress,
          "city": result?.city,
          "state": result?.state,
          "zip": result?.zip,
          "country": result?.country,
          "latitude": result?.latitude,
          "longitude": result?.longitude,
          "location_id": result?.locationId,
        }
      };
      var body = data;
      var response = await apiService.patch(body);
      if (response.containsKey('result')) {
        //result = LocationProfileModel.fromJson(response['result']);
        subdestinations = result?.subdestinations ?? [];
      } else {
        result = null;
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString(), style: typography.Body1),
      ));
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
      return true;
    }
  }
}
