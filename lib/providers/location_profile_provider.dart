import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:green/design_system/primitives/custom_typography.dart';
import 'package:green/models/location_profile_model.dart';
import 'package:green/service/api_service.dart';
import 'package:green/utils/api_constants.dart';
import 'package:http/http.dart' as http;

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

  Future<void> fetchLocationDetails(BuildContext context, String accountId,
      String subAccountId, String sovId, String locationId) async {
    try {
      isLoading = true;
      ApiService apiService = ApiService(AppConstant.GET_LOCATION_PROFILE +
          "/$accountId/subaccount/$subAccountId/sov/$sovId/location?location_id=$locationId");
      var response = await apiService.get("");
      log(response.toString());

      if (response.containsKey('result')) {
        result = LocationProfileModel.fromJson(response['result']);
        subdestinations = result?.subdestinations ?? [];
      } else {
        result = null;
        subdestinations = [];
      }

      isLoading = false;
    } on BackendException catch (e, stackTrace) {
      isLoading = false;
      print(stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message, style: CustomTypography.Body1),
      ));
    } catch (e, stackTrace) {
      isLoading = false;
      print(stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString(), style: CustomTypography.Body1),
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
        content: Text(e.message, style: CustomTypography.Body1),
      ));
    } catch (e, stackTrace) {
      isLoading = false;
      print(stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString(), style: CustomTypography.Body1),
      ));
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addSubdestinationToSOV(BuildContext context, String accountId,
      String subAccountId, String sovId, String locationId, String subDestinationId) async {
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
          content: Text(response['message'] ?? "Subdestination added successfully", style: CustomTypography.Body1),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Failed to add subdestination", style: CustomTypography.Body1),
        ));
      }

      isLoading = false;
      notifyListeners();
    } on BackendException catch (e, stackTrace) {
      isLoading = false;
      print(stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message, style: CustomTypography.Body1),
      ));
    } catch (e, stackTrace) {
      isLoading = false;
      print(stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString(), style: CustomTypography.Body1),
      ));
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addSelectedSubdestinationToSOV(BuildContext context, String accountId,
      String subAccountId, String sovId, String locationId, List<String> subDestinationId) async {
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
          content: Text(response['message'] ?? "Subdestination added successfully", style: CustomTypography.Body1),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Failed to add subdestination", style: CustomTypography.Body1),
        ));
      }

      isLoading = false;
      notifyListeners();
    } on BackendException catch (e, stackTrace) {
      isLoading = false;
      print(stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message, style: CustomTypography.Body1),
      ));
    } catch (e, stackTrace) {
      isLoading = false;
      print(stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString(), style: CustomTypography.Body1),
      ));
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeSubdestinationFromSOV(BuildContext context, String accountId,
      String subAccountId, String sovId, String locationId, String subDestinationId) async {
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

      if (response.containsKey('processed')) {
        //result = LocationProfileModel.fromJson(response['result']);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(response['message'] ?? "Subdestination removed successfully", style: CustomTypography.Body1),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Failed to remove subdestination", style: CustomTypography.Body1),
        ));
      }

      isLoading = false;
      notifyListeners();
    } on BackendException catch (e, stackTrace) {
      isLoading = false;
      print(stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message, style: CustomTypography.Body1),
      ));
    } catch (e, stackTrace) {
      isLoading = false;
      print(stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString(), style: CustomTypography.Body1),
      ));
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateLocationDetails(BuildContext context, String accountId,
      String subAccountId, String sovId, String locationId, Map<String, dynamic> data) async {
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
      return true;
    } on BackendException catch (e, stackTrace) {
      isLoading = false;
      print(e);
      print(stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message, style: CustomTypography.Body1),
      ));
      return false;
    } catch (e, stackTrace) {
      isLoading = false;
      print(e);
      print(stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString(), style: CustomTypography.Body1),
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
        content: Text(e.message, style: CustomTypography.Body1),
      ));
      return false;
    } catch (e, stackTrace) {
      isLoading = false;
      print(e);
      print(stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString(), style: CustomTypography.Body1),
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
        content: Text(e.message, style: CustomTypography.Body1),
      ));
      return false;
    } catch (e, stackTrace) {
      isLoading = false;
      print(e);
      print(stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString(), style: CustomTypography.Body1),
      ));
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
      return true;
    }
  }
}
