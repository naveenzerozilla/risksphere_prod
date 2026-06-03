import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../design_system/components/custom_toast.dart';
import '../design_system/primitives/custom_typography.dart';
import '../models/DataParameterModel.dart';
import '../service/api_service.dart';
import '../utils/api_constants.dart';
import 'package:provider/provider.dart';
import '../providers/my_location_list_provider.dart';

class SubaccountParameterProvider with ChangeNotifier {
  List<Hazard> _hazardList = [];

  List<Hazard> get hazardList => _hazardList;

  bool _isLoading = false;
  DataParametersModel? _parameters;

  bool get isLoading => _isLoading;

  List<String> _imageUrls = [];

  List<String> get imageUrls => _imageUrls;

  void setImageUrls(List<String> urls) {
    _imageUrls = urls;
    notifyListeners();
  }

  // int? updatedScore = 1;
  int? updatedScore;

  void setUpdatedScore(int score) {
    updatedScore = score;
    notifyListeners();
  }

  DataParametersModel? get parameters => _parameters;

  Future<void> fetchSubaccountParameters(
      BuildContext context,
      String? subaccountId,
      String? peril,
      String? level,
      String? locationId,
      String? campusId,
      String? fetchSubaccountParameters,
      String? selectedParameterList,
      String? sovId) async {
    var typography = CustomTypography(context);
    _isLoading = true;
    notifyListeners();

    try {
      print("selectedParameterList");
      print(selectedParameterList);
      print(fetchSubaccountParameters);
      ApiService apiService =
          ApiService(selectedParameterList!.toLowerCase() == 'location'
              ? AppConstant.GET_LOCATION_PARAMETERS
              : selectedParameterList.toLowerCase() == 'sov'
                  ? AppConstant.GET_SOV_PARAMETERS
                  : selectedParameterList.toLowerCase() == 'campus'
                      ? AppConstant.GET_CAMPUS_PARAMETERS
                      : AppConstant.GET_DATA_PARAMETERS);
      String url = selectedParameterList.toLowerCase() == 'location'
          ? '$locationId?peril=$peril'
          : selectedParameterList.toLowerCase() == 'sov'
              ? '$sovId?peril=$peril'
              : selectedParameterList.toLowerCase() == 'campus'
                  ? '$campusId?peril=$peril'
                  : '$subaccountId?peril=$peril';

      final response = await apiService.get(url);
      final dataParameters =
          await compute<Map<String, dynamic>, DataParametersModel>(
        DataParametersModel.fromJson,
        response as Map<String, dynamic>,
      );
      _parameters = dataParameters;
    } on BackendException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.message,
            style: typography.Body1,
          ),
        ),
      );
    } catch (e, stackTrace) {
      debugPrint(stackTrace.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchHazardList(BuildContext context) async {
    var typography = CustomTypography(context);
    _isLoading = true;
    notifyListeners();

    try {
      ApiService apiService = ApiService(AppConstant.GET_HAZARD_LIST);
      final response = await apiService.get();
      final result = response['result'] as List<dynamic>;
      _hazardList = result.map((json) => Hazard.fromJson(json)).toList();
    } on BackendException catch (e) {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text(
      //       e.message,
      //       style: typography.Body1,
      //     ),
      //   ),
      // );
    } catch (e, stackTrace) {
      debugPrint(stackTrace.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteParameterImage({
    required BuildContext context,
    required String selectedParameterList,
    required String locationId,
    required String sovId,
    required String campusId,
    required String subaccountId,
    required String parameterId,
    required Map<String, dynamic> imageObject, // ✅ single image object
  }) async {
    try {
      notifyListeners();

      String url = selectedParameterList.toLowerCase() == 'location'
          ? "${AppConstant.DELETE_LOCATION_IMAGE}$locationId/$parameterId"
          : selectedParameterList.toLowerCase() == 'sov'
              ? "${AppConstant.DELETE_SOV_IMAGE}$sovId/$parameterId"
              : selectedParameterList.toLowerCase() == 'campus'
                  ? "${AppConstant.DELETE_CAMPUS_IMAGE}$campusId/$parameterId"
                  : "${AppConstant.DELETE_DATA_IMAGE}$subaccountId/$parameterId";

      log(" DELETE URL: $url");
      log(" DELETE imageObject: ${jsonEncode(imageObject)}");

      ApiService apiService = ApiService(url);

      // Send ONLY the single image object — NOT the full reference list
      final response = await apiService.delete1(imageObject);

      log("DELETE RESPONSE: $response");

      CustomToast.success(
          context, response['message'] ?? "Image deleted successfully");
      return true;
    } on BackendException catch (e, stack) {
      log("Backend error: ${e.message}");
      CustomToast.error(context, e.message);
      return false;
    } catch (e, stack) {
      log("Unexpected error: $e");
      CustomToast.error(context, "Something went wrong");
      return false;
    } finally {
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> recommendationEngineApi(
    BuildContext context,
    String locationId,
    String dataCategoryId,
    String extractionKey,
  ) async {
    try {
      // isLoading = true;

      ApiService apiService = ApiService(AppConstant.VENDOR_DATA_COMPARISON);
      // ApiService apiService = ApiService(AppConstant.RECOMMENDATION_ENGINE_V2);
      var body = {
        "location_id": locationId,
        "data_category_id": dataCategoryId,
        "vendors": {
          "hazard_hub": extractionKey,
        }
      };


      var response = await apiService.post(body);

      log(response.toString());

      return response;
    } on BackendException catch (e, stackTrace) {
      log("Recommendation Engine Error: ${e.message}");
      log(stackTrace.toString());

      CustomToast.error(context, e.message);

      return null;
    } catch (e, stackTrace) {
      log("Recommendation Engine Error: $e");
      log(stackTrace.toString());

      return null;
    } finally {
      // isLoading = false;
    }
  }

  Future<Map<String, dynamic>?> vendorDataComparisonApi(
    BuildContext context,
    String locationId,
    String dataCategoryId,
    String extractionKey,
  ) async {
    try {
      ApiService apiService = ApiService(AppConstant.RECOMMENDATION_ENGINE_V2);

      var body = {
        "location_id": locationId,
        "data_category_id": dataCategoryId,
        "selected_vendor": "hazard_hub",
        "extraction_key": extractionKey,
      };

      var response = await apiService.post(body);

      log(response.toString());

      return response;
    } on BackendException catch (e, stackTrace) {
      log("Vendor Comparison Error: ${e.message}");
      log(stackTrace.toString());

      CustomToast.error(context, e.message);

      return null;
    } catch (e, stackTrace) {
      log("Vendor Comparison Error: $e");
      log(stackTrace.toString());

      return null;
    }
  }

  Future<void> submitParameterUpdate({
    required BuildContext context,
    required String subaccountId,
    required String locationId,
    required String sovId,
    required String campusId,
    required String parameterId,
    required Map<String, dynamic> updatedFields,
    required String selectedParameterList,
  }) async {
    var typography = CustomTypography(context);

    try {
      ApiService apiService = ApiService(
        selectedParameterList.toLowerCase() == 'location'
            ? AppConstant.GET_LOCATION_PARAMETERS +
                locationId +
                '/' +
                parameterId
            : selectedParameterList.toLowerCase() == 'sov'
                ? AppConstant.GET_SOV_PARAMETERS + sovId + '/' + parameterId
                : selectedParameterList.toLowerCase() == 'campus'
                    ? AppConstant.GET_CAMPUS_PARAMETERS +
                        campusId +
                        '/' +
                        parameterId
                    : AppConstant.GET_DATA_PARAMETERS +
                        subaccountId +
                        '/' +
                        parameterId,
      );

      final response = await apiService.patch(updatedFields);

      if (response != null && response['score'] != null) {
        final double score = (response['score'] as num).toDouble();

        setUpdatedScore(score.round());

        Provider.of<MyLocationListProvider>(
          context,
          listen: false,
        ).updateDataCompleteness(score);

        debugPrint("Stored & synced score: $score");
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Parameter updated successfully",
            style: typography.ButtonLargeBlack,
          ),
        ),
      );
    } on BackendException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message, style: typography.Body1)),
      );
    } catch (e, stackTrace) {
      debugPrint("Error: $e");
      debugPrint(stackTrace.toString());
    }
  }

// Future<void> submitParameterUpdate({
//   required BuildContext context,
//   required String subaccountId,
//   required String locationId,
//   required String sovId,
//   required String campusId,
//   required String parameterId,
//   required Map<String, dynamic> updatedFields,
//   required String selectedParameterList,
// }) async {
//   var typography = CustomTypography(context);
//
//   try {
//     ApiService apiService = ApiService(
//       selectedParameterList.toLowerCase() == 'location'
//           ? AppConstant.GET_LOCATION_PARAMETERS +
//               locationId +
//               '/' +
//               parameterId
//           : selectedParameterList.toLowerCase() == 'sov'
//               ? AppConstant.GET_SOV_PARAMETERS + sovId + '/' + parameterId
//               : selectedParameterList.toLowerCase() == 'campus'
//                   ? AppConstant.GET_CAMPUS_PARAMETERS +
//                       campusId +
//                       '/' +
//                       parameterId
//                   : AppConstant.GET_DATA_PARAMETERS +
//                       subaccountId +
//                       '/' +
//                       parameterId,
//     );
//
//     final response = await apiService.patch(updatedFields);
//
//     // ⭐ Extract and store score
//     // if (response != null && response['score'] != null) {
//       final score = response['score'];
//
//       // ⭐ Correct way inside provider
//       setUpdatedScore(score);
//
//       print("Stored score globally: $score");
//     // }
//
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(
//           "Parameter updated successfully",
//           style: typography.ButtonLargeBlack,
//         ),
//       ),
//     );
//   } on BackendException catch (e) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(e.message, style: typography.Body1)),
//     );
//   } catch (e, stackTrace) {
//     debugPrint("Error: $e");
//     debugPrint(stackTrace.toString());
//   }
// }
}

class Hazard {
  final String id;
  final String name;

  Hazard({required this.id, required this.name});

  factory Hazard.fromJson(Map<String, dynamic> json) {
    return Hazard(
      id: json['id'],
      name: json['hazard_name'],
    );
  }
}
