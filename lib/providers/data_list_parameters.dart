import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../design_system/primitives/custom_typography.dart';
import '../models/DataParameterModel.dart';
import '../service/api_service.dart';
import '../utils/api_constants.dart';

class SubaccountParameterProvider with ChangeNotifier {
  // List<SubaccountParameter> _parameters = [];
  bool _isLoading = false;
  DataParametersModel? _parameters;

  bool get isLoading => _isLoading;

  List<String> _imageUrls = [];

  List<String> get imageUrls => _imageUrls;

  void setImageUrls(List<String> urls) {
    _imageUrls = urls;
    notifyListeners(); // This is important
  }
  DataParametersModel? get parameters => _parameters;

  // List<SubaccountParameter> get parameters => _parameters;

  Future<void> fetchSubaccountParameters(
      BuildContext context, String? subaccountId) async {
    var typography = CustomTypography(context);
    _isLoading = true;
    notifyListeners();

    try {
      ApiService apiService = ApiService(AppConstant.GET_DATA_PARAMETERS);
      String url = '$subaccountId'; // append subaccountId to base URL

      final response =
          await apiService.get(url); // your ApiService handles decoding
      print(response.toString());
      debugPrint("✅ Subaccount parameters fetched successfully");
      print(response['result'].toString());
      DataParametersModel dataParameters =
          DataParametersModel.fromJson(response);

      _parameters = dataParameters;
      // print(dataParameters.result!.length.toString());
      // print(dataParameters.result![0].criticality!.impactType.toString());
      print("dataParameters.result.toString()");
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
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text(
      //       'Something went wrong: $e',
      //       style: typography.Body1,
      //     ),
      //   ),
      // );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  Future<void> submitParameterUpdate({
    required BuildContext context,
    required String subaccountId,
    required String parameterId,
    required Map<String, dynamic> updatedFields,
  }) async {
    var typography = CustomTypography(context);

    try {
      ApiService apiService = ApiService(
          AppConstant.GET_DATA_PARAMETERS + subaccountId + '/' + parameterId);

      final response = await apiService.patch(updatedFields);


      debugPrint("✅ Parameter updated: $response");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Parameter updated successfully", style: typography.Body1),
        ),
      );
    } on BackendException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message, style: typography.Body1)),
      );
    } catch (e, stackTrace) {
      debugPrint("❌ Error: $e");
      debugPrint(stackTrace.toString());
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text("Something went wrong: $e", style: typography.Body1)),
      // );
    }
  }


// Future<void> submitParameterUpdate({
  //   required BuildContext context,
  //   required String subaccountId,
  //   required String parameterId,
  //   required Map<String, dynamic> updatedFields,
  // }) async {
  //   var typography = CustomTypography(context);
  //   _isLoading = true;
  //   notifyListeners();
  //
  //   try {
  //     // ✅ Make sure this constant points to your PATCH/UPDATE base endpoint
  //     ApiService apiService = ApiService(
  //         AppConstant.GET_DATA_PARAMETERS + subaccountId+'/'+parameterId);
  //
  //     // 🔧 Construct the final endpoint using subaccountId/parameterId
  //     String patchUrl = '$subaccountId/$parameterId';
  //
  //     // 🛠️ Send the patch request
  //     final response = await apiService.patch({
  //       "data": updatedFields,
  //     });
  //
  //     debugPrint("✅ Parameter updated: $response");
  //
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content:
  //             Text("Parameter updated successfully", style: typography.Body1),
  //       ),
  //     );
  //   } on BackendException catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text(e.message, style: typography.Body1)),
  //     );
  //   } catch (e, stackTrace) {
  //     debugPrint("❌ Error: $e");
  //     debugPrint(stackTrace.toString());
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //           content: Text("Something went wrong: $e", style: typography.Body1)),
  //     );
  //   } finally {
  //     _isLoading = false;
  //     notifyListeners();
  //   }
  // }
}
