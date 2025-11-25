import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../design_system/primitives/custom_typography.dart';
import '../models/DataParameterModel.dart';
import '../service/api_service.dart';
import '../utils/api_constants.dart';

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
      print(AppConstant.GET_SOV_PARAMETERS + sovId + '/' + parameterId);
      print("Sovparameter");
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
      // ApiService apiService = ApiService(
      //
      //     selectedParameterList
      //     AppConstant.GET_DATA_PARAMETERS + subaccountId + '/' + parameterId);

      final response = await apiService.patch(updatedFields);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Parameter updated successfully",
              style: typography.ButtonLargeBlack),
        ),
      );
    } on BackendException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message, style: typography.Body1)),
      );
    } catch (e, stackTrace) {
      debugPrint(" Error: $e");
      debugPrint(stackTrace.toString());
    }
  }
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
