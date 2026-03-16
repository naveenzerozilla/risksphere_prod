import 'dart:async';
import 'dart:io';
import 'package:RiskSphere/screens/home/dashboard_screen.dart';
import 'package:RiskSphere/screens/listings/sub_account_list.dart';
import 'package:RiskSphere/screens/listings/widgets/message_card.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';

import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:RiskSphere/providers/location_list_provider.dart';
import 'package:RiskSphere/providers/my_location_list_provider.dart';
import 'package:RiskSphere/providers/user_profile_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../constants/enums.dart';
import '../../design_system/components/country_picker_flag_name.dart';
import '../../design_system/components/custom_appbar.dart';
import '../../design_system/components/custom_button.dart';
import '../../design_system/components/custom_drawer.dart';
import '../../design_system/primitives/app_colors.dart';
import '../../design_system/primitives/custom_typography.dart';
import '../../design_system/primitives/utilities/custom_spacing.dart';
import '../../models/sov_list_model.dart';
import '../../providers/configuration_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/place_api_provider.dart';
import '../../providers/sov_list_provider.dart';
import '../../providers/theme_provider.dart';
import '../../service/language_service.dart';
import 'package:country_picker/country_picker.dart' as country_picker;

import '../../service/shared_preference_service.dart';
import '../payments/purchase_license.dart';
import 'account_list.dart';

class AddLocationScreen extends StatefulWidget {
  final String? newUser;
  final String? accountId;
  final String? subAccountId;
  final String? accountName;
  final String? subAccountName;
  final String sovId;
  final String sovName;
  final String? locationId;
  final String? locationName;
  final String? locationIdForRef;
  final String searchQuery;
  final String? page;
  final String? totalPages;
  final bool? is_conflict;
  final double? initialLat; // ADD THIS
  final double? initialLng; // ADD THIS

  const AddLocationScreen({
    super.key,
    this.newUser,
    required this.accountId,
    required this.subAccountId,
    required this.sovId,
    this.locationId,
    this.accountName,
    this.subAccountName,
    this.sovName = "",
    this.locationName,
    this.locationIdForRef,
    this.searchQuery = "",
    this.page,
    this.totalPages,
    this.is_conflict,
    this.initialLat,
    this.initialLng,
  });

  @override
  State<AddLocationScreen> createState() => _AddLocationScreenState();
}

class _AddLocationScreenState extends State<AddLocationScreen> {
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isExpanded = false;
  bool _showNotificationDot = true;
  TextEditingController _locationNameController = TextEditingController();
  String? _selectedLocationType;
  TextEditingController _locationAddressController = TextEditingController();
  TextEditingController _latitudeController = TextEditingController();
  TextEditingController _longitudeController = TextEditingController();
  TextEditingController _locationAddress1Controller = TextEditingController();
  TextEditingController _locationCityController = TextEditingController();
  TextEditingController _locationStateController = TextEditingController();
  TextEditingController _locationZipCodeController = TextEditingController();
  TextEditingController _locationDescriptionController =
      TextEditingController();
  TextEditingController tagController = TextEditingController();
  final List<String> tags = [];
  bool isSovSelected = false;
  bool isHasAnyPlan = false;
  String _selectedCountry = "United States";
  bool hasAnyPlan = false;
  String? trialMap;
  String? hasLicenseStatus = "1";
  String? hasGeocodingStatus = "1";
  String? hasHazardLicenseStatus = "1";
  String? hazardLicenseStatus1 = "1";
  String? hazardLicenseStatus2 = "1";
  String? getLocationImprovementCount = "1";

  final Completer<GoogleMapController> _mapController = Completer();
  static const CameraPosition _defaultLocation = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );
  Map<MarkerId, Marker> markers = {};
  final sessionToken = const Uuid().v4();
  bool _isSelectedFromAutocomplete = false;

  Key countryPickerKey = UniqueKey(); // Unique key to force rebuild
  bool addToSOVCheck = false;
  bool disableToggle = false;
  String selectedSovId = "";
  TextEditingController sovController = TextEditingController();

  // radio group for rented and leased
  bool rented = false;
  bool leased = false;
  Timer? _debounce;
  LatLng? _selectedLatLng;
  bool isSearchSelected = false;
  Position? _currentPosition;
  bool _isLocationLoading = false;
  String _locationError = '';

  bool get isEditMode => widget.locationId?.isNotEmpty == true;

  @override
  initState() {
    super.initState();

    if (widget.locationId?.isNotEmpty != true ? false : true) {
      var provider =
          Provider.of<MyLocationListProvider>(context, listen: false);
      _locationNameController.text =
          provider.locationProfile?.finalAddress?.locationName ?? "";
      _locationAddressController.text =
          provider.locationProfile?.finalAddress?.address ?? "";
      _locationAddress1Controller.text =
          provider.locationProfile?.finalAddress?.locationName ?? "";
      _selectedCountry = provider.locationProfile?.finalAddress?.country ?? "";
      _locationZipCodeController.text =
          provider.locationProfile?.finalAddress?.zip ?? "";
      //_selectedLocationType = provider.result?.locationType??"";
      final lat = provider.locationProfile?.finalAddress?.latitude;
      final lng = provider.locationProfile?.finalAddress?.longitude;

      if (lat != null && lng != null) {
        _selectedLatLng = LatLng(lat, lng);
        _latitudeController.text = lat.toStringAsFixed(6);
        _longitudeController.text = lng.toStringAsFixed(6);
      }

      // _latitudeController.text = provider
      //         .locationProfile?.finalAddress?.latitude
      //         ?.toStringAsFixed(6) ??
      //     "";
      // _longitudeController.text = provider
      //         .locationProfile?.finalAddress?.longitude
      //         ?.toStringAsFixed(6) ??
      //     "";
      _locationCityController.text =
          provider.locationProfile?.finalAddress?.city ?? "";
      _locationStateController.text =
          provider.locationProfile?.finalAddress?.state ?? "";
      _locationDescriptionController.text =
          provider.locationProfile?.finalAddress?.description ?? "";
      if (provider.locationProfile?.finalAddress?.sovId != null) {
        addToSOVCheck = true;
        selectedSovId = provider.locationProfile!.finalAddress!.sovId!;
        sovController.text = provider.locationProfile!.finalAddress!.sovName!;
        disableToggle = true;
      }
    }
    if (!isEditMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (widget.initialLat != null && widget.initialLng != null) {
          final position = LatLng(widget.initialLat!, widget.initialLng!);

          // 1️⃣ Set lat/lng fields & marker immediately (no map move yet)
          setState(() {
            _selectedLatLng = position;
            _latitudeController.text = position.latitude.toStringAsFixed(6);
            _longitudeController.text = position.longitude.toStringAsFixed(6);
          });

          // 2️⃣ Pre-fill name fields from placeName right away
          if (widget.locationName != null && widget.locationName!.isNotEmpty) {
            _locationNameController.text = widget.locationName!;
            _locationAddress1Controller.text = widget.locationName!;
            _locationAddressController.text = widget.locationName!;
          }

          // 3️⃣ Wait for map to be ready, then move camera
          final controller = await _mapController.future;
          controller.animateCamera(CameraUpdate.newLatLngZoom(position, 16));

          // 4️⃣ Reverse geocode to fill city/state/zip/country
          await _updateAddressFromCoordinates(position);

          // 5️⃣ Restore location name AFTER reverse geocode
          //    (because _updateFormFieldsWithPlacemark overwrites _locationAddress1Controller)
          if (widget.locationName != null && widget.locationName!.isNotEmpty) {
            setState(() {
              _locationAddress1Controller.text = widget.locationName!;
            });
          }
        } else {
          _getCurrentLocation(); // fallback to GPS
        }
      });
    }
    if (!isEditMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _getCurrentLocation();
      });
    }
    _initPgAdmin();
    if (widget.locationId?.isNotEmpty == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _getData();
        _initLocationFields();
        await _initMapFromApi(); // 🔥 THIS fixes Google Map
      });
    }
  }

  Future<void> _initMapFromApi() async {
    final provider =
        Provider.of<MyLocationListProvider>(context, listen: false);

    final lat = provider.locationProfile?.finalAddress?.latitude;
    final lng = provider.locationProfile?.finalAddress?.longitude;

    if (lat == null || lng == null) return;

    final position = LatLng(lat, lng);

    // Wait until map is created
    while (!_mapController.isCompleted) {
      await Future.delayed(const Duration(milliseconds: 50));
    }

    await _updateMap(position);
  }

  void _initLocationFields() {
    var provider = Provider.of<MyLocationListProvider>(context, listen: false);

    _locationNameController.text = (widget.is_conflict!
        ? widget.locationName
        : provider.locationProfile?.finalAddress?.locationName ??
            widget.searchQuery!)!;

    _locationAddressController.text = (widget.is_conflict!
        ? widget.locationName
        : provider.locationProfile?.finalAddress?.locationName ??
            widget.searchQuery!)!;

    _selectedCountry = provider.locationProfile?.finalAddress?.country ?? "";
    _locationZipCodeController.text =
        provider.locationProfile?.finalAddress?.zip ?? "";
    _locationCityController.text =
        provider.locationProfile?.finalAddress?.city ?? "";
    _locationStateController.text =
        provider.locationProfile?.finalAddress?.state ?? "";

    if (provider.locationProfile?.finalAddress?.sovId != null) {
      addToSOVCheck = true;
      selectedSovId = provider.locationProfile!.finalAddress!.sovId!;
      sovController.text = provider.locationProfile!.finalAddress!.sovName!;
      disableToggle = true;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _updateMap(LatLng position, {double zoom = 16}) async {
    setState(() {
      _selectedLatLng = position;
      _latitudeController.text = position.latitude.toStringAsFixed(6);
      _longitudeController.text = position.longitude.toStringAsFixed(6);
    });

    if (_mapController.isCompleted) {
      final controller = await _mapController.future;
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(position, zoom),
      );
    }
  }

// Add this method to get current location
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLocationLoading = true;
      _locationError = '';
    });

    bool serviceEnabled;
    LocationPermission permission;

    // ✅ Check service
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      setState(() {
        _locationError = 'Please enable location services.';
        _isLocationLoading = false;
      });
      return;
    }

    // ✅ Check permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _locationError = 'Location permission denied.';
          _isLocationLoading = false;
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _locationError =
            'Location permission permanently denied. Enable in settings.';
        _isLocationLoading = false;
      });
      return;
    }

    // ✅ Finally get current position
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      // _currentPosition = position;
      _currentPosition = position;
      _updateMap(
        LatLng(position.latitude, position.longitude),
      );
      // _selectedLatLng = LatLng(position.latitude, position.longitude);
      _isLocationLoading = false;
    });

    // Move map
    final controller = await _mapController.future;
    controller.animateCamera(CameraUpdate.newLatLngZoom(_selectedLatLng!, 16));

    // Optional: update address
    await _updateAddressFromCoordinates(_selectedLatLng!);
  }

  Future<void> _initPgAdmin() async {
    hasAnyPlan = await SharedPreferenceService.getHasAnyPlan();
    String? geoCodingStatus =
        await SharedPreferenceService.getGeocodingLicense();
    String? userLicenseStatus = await SharedPreferenceService.getUserLicense();
    String? hazardLicenseStatus =
        await SharedPreferenceService.getHazardLicense();
    var hazardLicenseStatus11 =
        await SharedPreferenceService.getTrialMaxLocations();
    var hazardLicenseStatus22 =
        await SharedPreferenceService.getTrialLocations();
    var getLicenseImprovementCount =
        await SharedPreferenceService.getHasImpromentLicenseCount();

    trialMap = await SharedPreferenceService.getTrialPeriodStartRaw();

    if (mounted)
      setState(() {
        hasAnyPlan = hasAnyPlan;
        hasLicenseStatus = userLicenseStatus ?? "";
        hasGeocodingStatus = geoCodingStatus ?? "";
        hasHazardLicenseStatus = hazardLicenseStatus ?? "";
        hazardLicenseStatus1 = hazardLicenseStatus11.toString() ?? "";
        hazardLicenseStatus2 = hazardLicenseStatus22.toString();
        getLocationImprovementCount = getLicenseImprovementCount.toString();
      });
  }

  Future<void> _getData() async {
    await _setClaims();
    await Provider.of<MyLocationListProvider>(context, listen: false)
      ..fetchIndividualLocationProfile(context, widget.locationId ?? '');
    final dashboardProvider =
        Provider.of<DashboardProvider>(context, listen: false);
    final userProfileProvider =
        Provider.of<UserProfileProvider>(context, listen: false);
    final configurationProvider =
        Provider.of<ConfigurationProvider>(context, listen: false);
    final sovProvider = Provider.of<SOVListProvider>(context, listen: false);

    try {
      final results = await Future.wait([
        dashboardProvider.getDashboardData(context),
        userProfileProvider.getAllUserData(context, "", ""),
        configurationProvider.getConfiguration(
            accountId: null, subAccountId: null),
        configurationProvider.getVendors(),
        sovProvider.fetchAutoCompleteSovListLocations(
            context, widget.accountId!, widget.subAccountId!),
      ]);

      userProfileProvider.fetchTrialInfo();

      var config = configurationProvider.configurations['result'] ?? {};
      // subscriptions = config['subscribe'] ?? {};

      if (mounted) {
        //   WidgetsBinding.instance.addPostFrameCallback((_) {
        //     svendorList = configurationProvider.vendors['result'] ?? [];
        //   });
        // });etState(() {
      }
    } catch (error) {
      print("Error fetching data: $error");
    }
  }

  _setClaims() async {
    final adminValues = await Future.wait([
      SharedPreferenceService.getHasAnyPlan(),
    ]);

    isHasAnyPlan = adminValues[4] ?? false;

    if (mounted) setState(() {});
  }

  final GlobalKey _dropdownKey = GlobalKey();
  double _dropdownWidth = 0;

  @override
  Widget build(BuildContext context1) {
    var typography = CustomTypography(context);
    return SafeArea(
      child: Consumer<ThemeProvider>(
          builder: (buildContext, themeProvider, child) {
        return Scaffold(
          resizeToAvoidBottomInset: true,
          key: _scaffoldKey,
          backgroundColor: themeProvider.getTheme.colorScheme.background,
          appBar: CustomAppBar(
            margin: 8,
            isExpanded: _isExpanded,
            showNotificationDot: _showNotificationDot,
            onExpandPressed: (isExpanded) {
              setState(() {
                _isExpanded = isExpanded;
              });
            },
            onSearchPressed: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
          ),
          drawer: CustomDrawer(),
          body: Consumer<UserProfileProvider>(
              builder: (context, userProfileProvider, child) {
            final trialStatus = userProfileProvider.trialInfo['status'] ?? '';

            return (trialStatus.contains('Expired') && isHasAnyPlan == false)
                ? Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surface
                          .withOpacity(0.95),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: MessageCard(
                            messageTextSpans: [
                              TextSpan(
                                text:
                                    'We hope you\'ve enjoyed your trial period! To continue accessing your account and keep your data safe, please upgrade before ${trialMap ?? 'your trial end date'}. After this date, we will need to delete your data. Thank you for being with us!',
                                style: typography.Body1,
                              ),
                              // tappable
                              TextSpan(
                                text: ' Upgrade Now!',
                                style: typography.Body1.copyWith(
                                  color: AppColors.primaryMain,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    Navigator.of(context).push(
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                PurchaseLicensePage()));
                                  },
                              ),
                            ],
                            isError: true,
                          ),
                        ),
                      ],
                    ),
                  )
                : Stack(children: [
                    // Background image
                    Positioned.fill(
                      child: Image.asset(
                        'assets/images/mesh.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                    Consumer<UserProfileProvider>(
                        builder: (context, userProfileProvider, child) {
                      final trialStatus =
                          userProfileProvider.trialInfo['status'] ?? '';
                      int locations =
                          userProfileProvider.trialInfo['locations'] ?? 0;
                      int total =
                          userProfileProvider.trialInfo['maxLocations'] ?? 0;
                      return Column(
                        children: [
                          if (widget.newUser.toString() == "true") ...[
                            Row(children: [
                              Expanded(
                                flex: 8,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      SizedBox(width: 10),
                                      InkWell(
                                        onTap: () {
                                          Navigator.pushAndRemoveUntil(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  AccountListScreen(),
                                            ),
                                            (route) => false,
                                          );
                                        },
                                        child: Text(widget.accountName!,
                                            style: typography.InputLabel),
                                      ),
                                      Text(' > ', style: typography.InputLabel),
                                      InkWell(
                                        onTap: () {
                                          Navigator.pushAndRemoveUntil(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  SubAccountListScreen(
                                                accountId: widget.accountId!,
                                                accountName:
                                                    widget.accountName ??
                                                        widget.accountName,
                                              ),
                                            ),
                                            (route) => false,
                                          );
                                        },
                                        child: Text(widget.subAccountName ?? "",
                                            style: typography.InputLabel),
                                      ),
                                      Text(' > ',
                                          style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.white70)),
                                      Text(
                                        "Your first location",
                                        style: TextStyle(
                                            fontSize: 14, color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ]),
                          ],
                          // Text(userProfileProvider.trialInfo.toString()),

                          SizedBox(height: CustomSpacing.two),

                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                //color: Theme.of(context).hoverColor.withOpacity(0.1),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(24),
                                  topRight: Radius.circular(24),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Form
                                  Expanded(
                                    child: SingleChildScrollView(
                                      padding: EdgeInsets.only(
                                          right: 8,
                                          left: 8,
                                          bottom: MediaQuery.of(context)
                                              .viewInsets
                                              .bottom),
                                      keyboardDismissBehavior:
                                          ScrollViewKeyboardDismissBehavior
                                              .onDrag,
                                      child: Form(
                                        key: _formKey,
                                        child: KeyboardVisibilityBuilder(
                                            builder:
                                                (context, isKeyboardVisible) {
                                          return Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              if (!isKeyboardVisible) ...[
                                                Container(
                                                  margin: const EdgeInsets
                                                      .symmetric(horizontal: 8),
                                                  child: SizedBox(
                                                    height: 240,
                                                    width: double.infinity,
                                                    child:
                                                        // _isSelectedFromAutocomplete
                                                        //     ?
                                                        AbsorbPointer(
                                                            absorbing: isEditMode ||
                                                                !isSearchSelected,
                                                            // absorbing: !isSearchSelected,
                                                            child: GoogleMap(
                                                              myLocationButtonEnabled:
                                                                  false,
                                                              zoomControlsEnabled:
                                                                  false,
                                                              zoomGesturesEnabled:
                                                                  true,
                                                              scrollGesturesEnabled:
                                                                  true,
                                                              rotateGesturesEnabled:
                                                                  isSearchSelected,
                                                              tiltGesturesEnabled:
                                                                  isSearchSelected,
                                                              mapType: MapType
                                                                  .normal,
                                                              initialCameraPosition:
                                                                  CameraPosition(
                                                                target: _selectedLatLng ??
                                                                    (_currentPosition != null
                                                                        ? LatLng(
                                                                            _currentPosition!.latitude,
                                                                            _currentPosition!.longitude,
                                                                          )
                                                                        : const LatLng(40.7128, -74.0060)),
                                                                zoom: 16,
                                                              ),
                                                              onMapCreated:
                                                                  (controller) {
                                                                if (!_mapController
                                                                    .isCompleted) {
                                                                  _mapController
                                                                      .complete(
                                                                          controller);
                                                                }
                                                              },
                                                              markers:
                                                                  _selectedLatLng ==
                                                                          null
                                                                      ? {}
                                                                      : {
                                                                          Marker(
                                                                            markerId:
                                                                                const MarkerId('selected_location'),
                                                                            position:
                                                                                _selectedLatLng!,
                                                                            draggable:
                                                                                isSearchSelected,
                                                                            icon:
                                                                                BitmapDescriptor.defaultMarkerWithHue(
                                                                              BitmapDescriptor.hueRed,
                                                                            ),
                                                                          ),
                                                                        },
                                                              onTap:
                                                                  (position) async {
                                                                if (!isSearchSelected)
                                                                  return;
                                                                await _updateMap(
                                                                    position);
                                                                await _updateAddressFromCoordinates(
                                                                    position);
                                                              },
                                                              gestureRecognizers: {
                                                                Factory<
                                                                    OneSequenceGestureRecognizer>(
                                                                  () =>
                                                                      EagerGestureRecognizer(),
                                                                ),
                                                              },
                                                            )),
                                                  ),
                                                ),
                                              ],
                                              // Text(widget.locationName.toString()),
                                              // Text("widget.locationName".toString()),
                                              SizedBox(
                                                  height: CustomSpacing.four),
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 8.0),
                                                child: Text(
                                                    !isEditMode
                                                        ? LanguageService
                                                            .getTranslated(
                                                                context,
                                                                "add_location")
                                                        : LanguageService
                                                            .getTranslated(
                                                                context,
                                                                "edit_location"),
                                                    style:
                                                        typography.H5_Regular),
                                              ),

                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 8.0, top: 4),
                                                child: Text(
                                                  isEditMode
                                                      ? LanguageService
                                                          .getTranslated(
                                                              context,
                                                              "create_location_info")
                                                      : LanguageService
                                                          .getTranslated(
                                                              context,
                                                              "create_location_info"),
                                                  // style: typography.Subtitle1,
                                                ),
                                              ),
                                              SizedBox(
                                                height: CustomSpacing.two,
                                              ),
                                              // widget.locationId!.isEmpty
                                              //     ?
                                              Container(
                                                // color: Colors.black,
                                                padding:
                                                    const EdgeInsets.all(8),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  children: [
                                                    _buildToggleButton(
                                                      title: LanguageService
                                                          .getTranslated(
                                                              context,
                                                              "search_address"),
                                                      isSelected:
                                                          !isSearchSelected,
                                                      onTap: () {
                                                        print(isSearchSelected);
                                                        setState(() {
                                                          isSearchSelected =
                                                              false;
                                                          _locationNameController
                                                              .clear();
                                                          _locationAddress1Controller
                                                              .clear();
                                                          _locationAddressController
                                                              .clear();
                                                          _locationCityController
                                                              .clear();
                                                          _locationStateController
                                                              .clear();
                                                          _locationZipCodeController
                                                              .clear();
                                                          _locationDescriptionController
                                                              .clear();
                                                          markers.clear();
                                                          _selectedLatLng =
                                                              null; // Clear selected coordinates
                                                          _isSelectedFromAutocomplete =
                                                              false;
                                                        });
                                                        _getCurrentLocation();
                                                      },
                                                    ),
                                                    // const SizedBox(width: 4),
                                                    _buildToggleButton(
                                                      title: LanguageService
                                                          .getTranslated(
                                                              context,
                                                              "manual_entry"),
                                                      isSelected:
                                                          isSearchSelected,
                                                      onTap: () {
                                                        setState(() {
                                                          isSearchSelected =
                                                              true;
                                                          _locationNameController
                                                              .clear();
                                                          _locationAddress1Controller
                                                              .clear();
                                                          _locationAddressController
                                                              .clear();
                                                          _locationCityController
                                                              .clear();
                                                          _locationStateController
                                                              .clear();
                                                          _locationZipCodeController
                                                              .clear();
                                                          _locationDescriptionController
                                                              .clear();
                                                          markers.clear();
                                                          _selectedLatLng =
                                                              null; // Clear selected coordinates
                                                          _isSelectedFromAutocomplete =
                                                              false;
                                                        });
                                                      },
                                                    ),
                                                    const SizedBox(width: 15),
                                                    // const Spacer(),
                                                    Tooltip(
                                                      message:
                                                          'Address Entry Options\nSearch Address:\nUse Google Places to automatically find and validate addresses with precise geocoding.\n\nManual Entry:\nDirectly type in address details when you need more control over the input. Manually set the pin on the map to ensure accurate location.',
                                                      padding:
                                                          const EdgeInsets.all(
                                                              10),
                                                      textStyle:
                                                          const TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 13),
                                                      decoration: BoxDecoration(
                                                        color: Colors.black87,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                      ),
                                                      preferBelow: false,
                                                      child: InkWell(
                                                        onTap: () {
                                                          // Optional: show a dialog instead of tooltip on tap (for mobile)
                                                          showDialog(
                                                            context: context,
                                                            builder:
                                                                (context) =>
                                                                    AlertDialog(
                                                              backgroundColor:
                                                                  Colors
                                                                      .black87,
                                                              shape: RoundedRectangleBorder(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              12)),
                                                              title: Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .spaceAround,
                                                                children: [
                                                                  const Text(
                                                                    'Address Entry Options',
                                                                    style: TextStyle(
                                                                        color: Colors
                                                                            .white),
                                                                  ),
                                                                  IconButton(
                                                                      color: Colors
                                                                          .red,
                                                                      onPressed:
                                                                          () {
                                                                        Navigator.of(context)
                                                                            .pop();
                                                                      },
                                                                      icon: Icon(
                                                                          Icons
                                                                              .close))
                                                                ],
                                                              ),
                                                              content:
                                                                  const Text(
                                                                'Search Address:\nUse Google Places to automatically find and validate addresses with precise geocoding.\n\nManual Entry:\nDirectly type in address details when you need more control over the input. Manually set the pin on the map to ensure accurate location.',
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .white70),
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                        child: const Icon(
                                                          Icons.info_outline,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              // : Container(),
                                              SizedBox(
                                                  height: CustomSpacing.two),
                                              // Location Address
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Autocomplete<Suggestion>(
                                                  optionsBuilder: (TextEditingValue
                                                      textEditingValue) async {
                                                    if (textEditingValue
                                                            .text.isEmpty ||
                                                        _isSelectedFromAutocomplete) {
                                                      return const Iterable<
                                                          Suggestion>.empty();
                                                    }

                                                    // ✅ Debounce logic
                                                    _debounce?.cancel();
                                                    final completer = Completer<
                                                        List<Suggestion>>();
                                                    _debounce = Timer(
                                                        const Duration(
                                                            milliseconds: 400),
                                                        () async {
                                                      final apiProvider =
                                                          PlaceApiProvider(
                                                              sessionToken);
                                                      final results =
                                                          await apiProvider
                                                              .fetchSuggestions(
                                                        textEditingValue.text,
                                                        'en',
                                                      );
                                                      if (!completer
                                                          .isCompleted) {
                                                        completer
                                                            .complete(results);
                                                      }
                                                    });

                                                    return completer.future;
                                                  },
                                                  displayStringForOption:
                                                      (option) =>
                                                          option.description,
                                                  fieldViewBuilder: (context,
                                                      controller,
                                                      focusNode,
                                                      onFieldSubmitted) {
                                                    _locationNameController =
                                                        controller;

                                                    // ✅ ADD THESE 3 LINES
                                                    if (controller
                                                            .text.isEmpty &&
                                                        widget.locationName !=
                                                            null &&
                                                        widget.locationName!
                                                            .isNotEmpty) {
                                                      WidgetsBinding.instance
                                                          .addPostFrameCallback(
                                                              (_) {
                                                        controller.text = widget
                                                            .locationName!;
                                                      });
                                                    }

                                                    return TextField(
                                                      enabled:
                                                          !areFieldsDisabled(),
                                                      controller: controller,
                                                      focusNode: focusNode,
                                                      onChanged: (value) {
                                                        if (_isSelectedFromAutocomplete) {
                                                          _isSelectedFromAutocomplete =
                                                              false;
                                                          return;
                                                        }
                                                        if (value.isEmpty) {
                                                          markers.clear();
                                                        }
                                                      },
                                                      decoration:
                                                          InputDecoration(
                                                        labelText: isSearchSelected
                                                            ? LanguageService
                                                                .getTranslated(
                                                                    context,
                                                                    "enter_address_manually")
                                                            : LanguageService
                                                                .getTranslated(
                                                                    context,
                                                                    "search_property"),
                                                        border:
                                                            const OutlineInputBorder(),
                                                        prefixIcon: const Icon(
                                                            Icons.search),
                                                      ),
                                                    );
                                                  },
                                                  onSelected:
                                                      areFieldsDisabled()
                                                          ? null
                                                          : (Suggestion
                                                              selection) {
                                                              _isSelectedFromAutocomplete =
                                                                  true;
                                                              _handlePlaceSelection(
                                                                  selection);
                                                            },
                                                ),
                                              ),

                                              SizedBox(
                                                height: CustomSpacing.one,
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: TextFormField(
                                                  autovalidateMode:
                                                      AutovalidateMode
                                                          .onUserInteraction,
                                                  enabled: !areFieldsDisabled(),
                                                  controller:
                                                      _locationAddress1Controller,
                                                  decoration: InputDecoration(
                                                    labelText: LanguageService
                                                        .getTranslated(context,
                                                            "location_name"),
                                                    border:
                                                        OutlineInputBorder(),
                                                  ),
                                                  validator: (value) {
                                                    if (value == null ||
                                                        value.isEmpty) {
                                                      return LanguageService
                                                          .getTranslated(
                                                              context,
                                                              "address_required");
                                                    }
                                                    return null;
                                                  },
                                                ),
                                              ),
                                              SizedBox(
                                                  height: CustomSpacing.one),
                                              // Location Address
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: TextFormField(
                                                  autovalidateMode:
                                                      AutovalidateMode
                                                          .onUserInteraction,
                                                  enabled: !areFieldsDisabled(),
                                                  controller:
                                                      _locationAddressController,
                                                  decoration: InputDecoration(
                                                    labelText: LanguageService
                                                        .getTranslated(
                                                            context, "address"),
                                                    border:
                                                        OutlineInputBorder(),
                                                    hintText: LanguageService
                                                        .getTranslated(
                                                            context, "address"),
                                                  ),
                                                  validator: (value) {
                                                    if (value == null ||
                                                        value.isEmpty) {
                                                      return LanguageService
                                                          .getTranslated(
                                                              context,
                                                              "address_required");
                                                    }
                                                    return null;
                                                  },
                                                ),
                                              ),
                                              SizedBox(
                                                  height: CustomSpacing.three),
                                              // Country just show flag and country name
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Row(
                                                  // crossAxisAlignment:
                                                  //     CrossAxisAlignment.start,
                                                  children: [
                                                    /// 🌍 Country Picker
                                                    Expanded(
                                                      flex: 1,
                                                      child: StatefulBuilder(
                                                        builder: (BuildContext
                                                                context,
                                                            StateSetter
                                                                setState) {
                                                          final bool disabled =
                                                              areFieldsDisabled();

                                                          return AbsorbPointer(
                                                            absorbing: disabled,
                                                            child: Opacity(
                                                              opacity: disabled
                                                                  ? 0.5
                                                                  : 1.0,
                                                              child:
                                                                  CountryPickerFlagNameCreate(
                                                                key:
                                                                    countryPickerKey,
                                                                onCountryChange:
                                                                    (country) {
                                                                  if (!disabled) {
                                                                    setState(
                                                                        () {
                                                                      _selectedCountry =
                                                                          country
                                                                              .name;
                                                                    });
                                                                  }
                                                                },
                                                                initialValue:
                                                                    country_picker
                                                                        .Country(
                                                                  phoneCode:
                                                                      '1',
                                                                  countryCode:
                                                                      getCountryCodeFromName(
                                                                              _selectedCountry) ??
                                                                          "",
                                                                  e164Sc: 1,
                                                                  geographic:
                                                                      true,
                                                                  level: 1,
                                                                  name:
                                                                      _selectedCountry,
                                                                  example: '',
                                                                  displayName:
                                                                      '',
                                                                  displayNameNoCountryCode:
                                                                      '',
                                                                  e164Key: '',
                                                                ),
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                    SizedBox(width: 2),
                                                    Expanded(
                                                      flex: 6,
                                                      child: TextFormField(
                                                        autovalidateMode:
                                                            AutovalidateMode
                                                                .onUserInteraction,
                                                        style: typography.Body1,
                                                        enabled:
                                                            !areFieldsDisabled(),
                                                        controller:
                                                            _locationZipCodeController,
                                                        decoration:
                                                            InputDecoration(
                                                          labelText: LanguageService
                                                              .getTranslated(
                                                                  context,
                                                                  "zip_postal_code"),
                                                          hintText: LanguageService
                                                              .getTranslated(
                                                                  context,
                                                                  "zip_postal_code"),
                                                          border:
                                                              const OutlineInputBorder(),
                                                          isDense:
                                                              true, // ✅ height match with country picker
                                                        ),
                                                        validator: (value) {
                                                          if (value == null ||
                                                              value.isEmpty) {
                                                            return LanguageService
                                                                .getTranslated(
                                                                    context,
                                                                    "zip_code_required");
                                                          }
                                                          return null;
                                                        },
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              // Padding(
                                              //   padding:
                                              //       const EdgeInsets.only(left: 8.0),
                                              //   child: Row(
                                              //     mainAxisSize: MainAxisSize.min,
                                              //     mainAxisAlignment:
                                              //         MainAxisAlignment.start,
                                              //     children: [
                                              //       Expanded(
                                              //         child: StatefulBuilder(
                                              //           builder: (BuildContext
                                              //                   context,
                                              //               StateSetter setState) {
                                              //             bool disabled =
                                              //                 areFieldsDisabled();
                                              //             return AbsorbPointer(
                                              //               absorbing: disabled,
                                              //               // Prevent interactions if disabled
                                              //               child: Opacity(
                                              //                 opacity: disabled
                                              //                     ? 0.5
                                              //                     : 1.0,
                                              //                 // Visual indication of disabled state
                                              //                 child:
                                              //                     CountryPickerFlagName(
                                              //                   key: countryPickerKey,
                                              //                   onCountryChange:
                                              //                       (country) {
                                              //                     if (!disabled) {
                                              //                       setState(() {
                                              //                         _selectedCountry =
                                              //                             country
                                              //                                 .name;
                                              //                       });
                                              //                     }
                                              //                   },
                                              //                   initialValue:
                                              //                       country_picker
                                              //                           .Country(
                                              //                     phoneCode: '1',
                                              //                     countryCode:
                                              //                         getCountryCodeFromName(
                                              //                                 _selectedCountry) ??
                                              //                             "",
                                              //                     e164Sc: 1,
                                              //                     geographic: true,
                                              //                     level: 1,
                                              //                     name:
                                              //                         _selectedCountry,
                                              //                     example: '',
                                              //                     displayName: '',
                                              //                     displayNameNoCountryCode:
                                              //                         '',
                                              //                     e164Key: '',
                                              //                   ),
                                              //                 ),
                                              //               ),
                                              //             );
                                              //           },
                                              //         ),
                                              //       ),
                                              //     ],
                                              //   ),
                                              // ),
                                              //
                                              // SizedBox(height: CustomSpacing.three),
                                              // // Location Zip/Postal Code
                                              // Padding(
                                              //   padding: const EdgeInsets.all(8.0),
                                              //   child: TextFormField(
                                              //     autovalidateMode: AutovalidateMode
                                              //         .onUserInteraction,
                                              //     style: typography.Body1,
                                              //     enabled: !areFieldsDisabled(),
                                              //     controller:
                                              //         _locationZipCodeController,
                                              //     decoration: InputDecoration(
                                              //       labelText:
                                              //           LanguageService.getTranslated(
                                              //               context,
                                              //               "zip_postal_code"),
                                              //       border: OutlineInputBorder(),
                                              //       hintText:
                                              //           LanguageService.getTranslated(
                                              //               context,
                                              //               "zip_postal_code"),
                                              //     ),
                                              //     validator: (value) {
                                              //       if (value == null ||
                                              //           value.isEmpty) {
                                              //         return LanguageService
                                              //             .getTranslated(context,
                                              //                 "zip_code_required");
                                              //       }
                                              //       return null;
                                              //     },
                                              //   ),
                                              // ),
                                              SizedBox(
                                                  height: CustomSpacing.three),
                                              Row(
                                                children: [
                                                  const SizedBox(width: 10),

                                                  /// LATITUDE
                                                  Expanded(
                                                    child: TextFormField(
                                                      controller:
                                                          _latitudeController,
                                                      decoration:
                                                          InputDecoration(
                                                        labelText:
                                                            LanguageService
                                                                .getTranslated(
                                                                    context,
                                                                    "latitude"),
                                                        labelStyle:
                                                            const TextStyle(
                                                                color: Colors
                                                                    .white70),
                                                        filled: true,
                                                        fillColor: Colors.white
                                                            .withOpacity(0.05),
                                                        enabledBorder:
                                                            OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                          borderSide:
                                                              const BorderSide(
                                                                  color: Colors
                                                                      .white30),
                                                        ),
                                                        focusedBorder:
                                                            OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                          borderSide:
                                                              const BorderSide(
                                                                  color: Colors
                                                                      .white60,
                                                                  width: 1.5),
                                                        ),
                                                        contentPadding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 12,
                                                                vertical: 10),
                                                      ),
                                                      style: const TextStyle(
                                                          color: Colors.white),
                                                      keyboardType:
                                                          const TextInputType
                                                              .numberWithOptions(
                                                              decimal: true),
                                                      onChanged: (value) {
                                                        final lat =
                                                            double.tryParse(
                                                                value);
                                                        final lng = double.tryParse(
                                                            _longitudeController
                                                                .text);

                                                        if (lat != null &&
                                                            lng != null) {
                                                          setState(() {
                                                            _selectedLatLng =
                                                                LatLng(
                                                                    lat, lng);
                                                          });
                                                        }
                                                      },
                                                    ),
                                                  ),

                                                  const SizedBox(width: 16),

                                                  /// LONGITUDE
                                                  Expanded(
                                                    child: TextFormField(
                                                      controller:
                                                          _longitudeController,
                                                      decoration:
                                                          InputDecoration(
                                                        labelText:
                                                            LanguageService
                                                                .getTranslated(
                                                                    context,
                                                                    "longitude"),
                                                        labelStyle:
                                                            const TextStyle(
                                                                color: Colors
                                                                    .white70),
                                                        filled: true,
                                                        fillColor: Colors.white
                                                            .withOpacity(0.05),
                                                        enabledBorder:
                                                            OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                          borderSide:
                                                              const BorderSide(
                                                                  color: Colors
                                                                      .white70),
                                                        ),
                                                        focusedBorder:
                                                            OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                          borderSide:
                                                              const BorderSide(
                                                                  color: Colors
                                                                      .white,
                                                                  width: 1.5),
                                                        ),
                                                        contentPadding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 12,
                                                                vertical: 10),
                                                      ),
                                                      style: const TextStyle(
                                                          color: Colors.white),
                                                      keyboardType:
                                                          const TextInputType
                                                              .numberWithOptions(
                                                              decimal: true),
                                                      onChanged: (value) {
                                                        final lat =
                                                            double.tryParse(
                                                                _latitudeController
                                                                    .text);
                                                        final lng =
                                                            double.tryParse(
                                                                value);

                                                        if (lat != null &&
                                                            lng != null) {
                                                          setState(() {
                                                            _selectedLatLng =
                                                                LatLng(
                                                                    lat, lng);
                                                          });
                                                        }
                                                      },
                                                    ),
                                                  ),

                                                  const SizedBox(width: 10),
                                                ],
                                              ),

//                                         Row(
//                                           children: [
//                                             SizedBox(width: 10),
//                                             // Latitude field
//                                             Expanded(
//                                               child: TextFormField(
//                                                 // controller: _latitudeController,
//                                                 controller:
//                                                     TextEditingController(
//                                                   text: _selectedLatLng !=
//                                                               null &&
//                                                           _selectedLatLng!
//                                                                   .longitude !=
//                                                               null
//                                                       ? _selectedLatLng!
//                                                           .longitude
//                                                           .toString()
//                                                       : '',
//                                                 ),
//                                                 decoration: InputDecoration(
//                                                   labelText: LanguageService
//                                                       .getTranslated(
//                                                           context, "latitude"),
//                                                   labelStyle: const TextStyle(
//                                                       color: Colors.white70),
//                                                   filled: true,
//                                                   fillColor: Colors.white
//                                                       .withOpacity(0.05),
//                                                   enabledBorder:
//                                                       OutlineInputBorder(
//                                                     borderRadius:
//                                                         BorderRadius.circular(
//                                                             8),
//                                                     borderSide:
//                                                         const BorderSide(
//                                                             color:
//                                                                 Colors.white30),
//                                                   ),
//                                                   focusedBorder:
//                                                       OutlineInputBorder(
//                                                     borderRadius:
//                                                         BorderRadius.circular(
//                                                             8),
//                                                     borderSide:
//                                                         const BorderSide(
//                                                             color:
//                                                                 Colors.white60,
//                                                             width: 1.5),
//                                                   ),
//                                                   contentPadding:
//                                                       const EdgeInsets
//                                                           .symmetric(
//                                                           horizontal: 12,
//                                                           vertical: 10),
//                                                 ),
//                                                 style: const TextStyle(
//                                                     color: Colors.white),
//                                                 readOnly: false,
//                                                 onChanged: (value) {
//                                                   final lat =
//                                                       double.tryParse(value);
//                                                   final lng = double.tryParse(
//                                                       _longitudeController
//                                                           .text);
//                                                   if (lat != null &&
//                                                       lng != null) {
//                                                     setState(() {
//                                                       _selectedLatLng =
//                                                           LatLng(lat, lng);
//                                                     });
//                                                   }
//                                                 },
//                                               ),
//                                             ),
//                                             const SizedBox(width: 16),
// // Longitude field
//                                             Expanded(
//                                               child: TextFormField(
//                                                 controller:
//                                                     TextEditingController(
//                                                   text: _selectedLatLng !=
//                                                               null &&
//                                                           _selectedLatLng!
//                                                                   .latitude !=
//                                                               null
//                                                       ? _selectedLatLng!
//                                                           .latitude
//                                                           .toString()
//                                                       : '',
//                                                 ),
//                                                 decoration: InputDecoration(
//                                                   labelText: LanguageService
//                                                       .getTranslated(
//                                                           context, "longitude"),
//                                                   labelStyle: const TextStyle(
//                                                       color: Colors.white70),
//                                                   filled: true,
//                                                   fillColor: Colors.white
//                                                       .withOpacity(0.05),
//                                                   enabledBorder:
//                                                       OutlineInputBorder(
//                                                     borderRadius:
//                                                         BorderRadius.circular(
//                                                             8),
//                                                     borderSide:
//                                                         const BorderSide(
//                                                             color:
//                                                                 Colors.white70),
//                                                   ),
//                                                   focusedBorder:
//                                                       OutlineInputBorder(
//                                                     borderRadius:
//                                                         BorderRadius.circular(
//                                                             8),
//                                                     borderSide:
//                                                         const BorderSide(
//                                                             color: Colors.white,
//                                                             width: 1.5),
//                                                   ),
//                                                   contentPadding:
//                                                       const EdgeInsets
//                                                           .symmetric(
//                                                           horizontal: 12,
//                                                           vertical: 10),
//                                                 ),
//                                                 style: const TextStyle(
//                                                     color: Colors.white),
//                                                 readOnly: false,
//                                                 onChanged: (value) {
//                                                   final lat = double.tryParse(
//                                                       _latitudeController.text);
//                                                   final lng =
//                                                       double.tryParse(value);
//                                                   if (lat != null &&
//                                                       lng != null) {
//                                                     setState(() {
//                                                       _selectedLatLng =
//                                                           LatLng(lat, lng);
//                                                     });
//                                                   }
//                                                 },
//                                               ),
//                                             ),
//                                             SizedBox(width: 10),
//                                             SizedBox(width: 10),
//                                           ],
//                                         ),

                                              SizedBox(
                                                  height: CustomSpacing.three),
                                              // Optional Details text with divider in row
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Row(
                                                  children: [
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              8.0),
                                                      child: Text(
                                                        LanguageService
                                                            .getTranslated(
                                                                context,
                                                                "optional_details"),
                                                        style: typography.Body1,
                                                      ),
                                                    ),
                                                    Expanded(
                                                      child: Divider(
                                                        color: themeProvider
                                                            .getTheme
                                                            .colorScheme
                                                            .onSurface,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              SizedBox(
                                                  height: CustomSpacing.three),
                                              // Selecting whether rented or leased
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8.0),
                                                child: Row(
                                                  children: [
                                                    Checkbox(
                                                      value: rented,
                                                      onChanged: areFieldsDisabled()
                                                          ? null // Disable checkbox if `areFieldsDisabled` returns true
                                                          : (bool? value) {
                                                              setState(() {
                                                                rented =
                                                                    !rented; // Toggle `rented`
                                                                if (rented) {
                                                                  leased =
                                                                      false; // Ensure mutual exclusivity
                                                                }
                                                              });
                                                            },
                                                    ),
                                                    SizedBox(width: 8),
                                                    Text(
                                                      LanguageService
                                                          .getTranslated(
                                                              context,
                                                              "rented"),
                                                      style: typography.Body1,
                                                    ),
                                                    SizedBox(width: 16),
                                                    Checkbox(
                                                      value: leased,
                                                      onChanged: areFieldsDisabled()
                                                          ? null // Disable checkbox if `areFieldsDisabled` returns true
                                                          : (bool? value) {
                                                              setState(() {
                                                                leased =
                                                                    !leased; // Toggle `leased`
                                                                if (leased) {
                                                                  rented =
                                                                      false; // Ensure mutual exclusivity
                                                                }
                                                              });
                                                            },
                                                    ),
                                                    SizedBox(width: 8),
                                                    Text(
                                                      LanguageService
                                                          .getTranslated(
                                                              context, "owned"),
                                                      style: typography.Body1,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              SizedBox(
                                                  height: CustomSpacing.three),
                                              // Location Type Dropdown
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: LayoutBuilder(
                                                  builder:
                                                      (context, constraints) {
                                                    // Schedule a post-frame callback to capture the width
                                                    WidgetsBinding.instance
                                                        .addPostFrameCallback(
                                                            (_) {
                                                      final RenderBox?
                                                          renderBox =
                                                          _dropdownKey
                                                                  .currentContext
                                                                  ?.findRenderObject()
                                                              as RenderBox?;
                                                      if (renderBox != null &&
                                                          _dropdownWidth !=
                                                              renderBox
                                                                  .size.width) {
                                                        setState(() {
                                                          _dropdownWidth =
                                                              renderBox
                                                                  .size.width;
                                                        });
                                                      }
                                                    });

                                                    return Container(
                                                      key: _dropdownKey,
                                                      child:
                                                          DropdownButtonFormField2<
                                                              String>(
                                                        decoration:
                                                            InputDecoration(
                                                          labelText: LanguageService
                                                              .getTranslated(
                                                                  context,
                                                                  "location_type"),
                                                          border:
                                                              OutlineInputBorder(),
                                                        ),
                                                        isExpanded: true,
                                                        value:
                                                            _selectedLocationType,
                                                        onChanged:
                                                            areFieldsDisabled()
                                                                ? null
                                                                : (String?
                                                                    newValue) {
                                                                    setState(
                                                                        () {
                                                                      _selectedLocationType =
                                                                          newValue;
                                                                    });
                                                                  },
                                                        items: [
                                                          'Residential',
                                                          'Commercial',
                                                          'Industrial'
                                                        ]
                                                            .map((item) =>
                                                                DropdownMenuItem<
                                                                    String>(
                                                                  value: item,
                                                                  child: Text(
                                                                      item),
                                                                ))
                                                            .toList(),
                                                        dropdownStyleData:
                                                            DropdownStyleData(
                                                          width: _dropdownWidth ==
                                                                  0
                                                              ? null
                                                              : _dropdownWidth,
                                                          // match width
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .surface,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        10),
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),

                                              SizedBox(
                                                  height: CustomSpacing.three),
                                              // Location City
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: TextFormField(
                                                  enabled: !areFieldsDisabled(),
                                                  controller:
                                                      _locationCityController,
                                                  decoration: InputDecoration(
                                                    labelText: LanguageService
                                                        .getTranslated(
                                                            context, "city"),
                                                    border:
                                                        OutlineInputBorder(),
                                                    hintText: LanguageService
                                                        .getTranslated(
                                                            context, "city"),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                  height: CustomSpacing.three),
                                              // Location State/Province/Region
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: TextFormField(
                                                  enabled: !areFieldsDisabled(),
                                                  controller:
                                                      _locationStateController,
                                                  decoration: InputDecoration(
                                                    labelText: LanguageService
                                                        .getTranslated(
                                                            context, "state"),
                                                    border:
                                                        OutlineInputBorder(),
                                                    hintText: LanguageService
                                                        .getTranslated(context,
                                                            "enter_state_name"),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                  height: CustomSpacing.three),
                                              // Description
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: TextFormField(
                                                  enabled: !areFieldsDisabled(),
                                                  maxLines: 3,
                                                  controller:
                                                      _locationDescriptionController,
                                                  decoration: InputDecoration(
                                                    labelText: LanguageService
                                                        .getTranslated(context,
                                                            "description"),
                                                    border:
                                                        OutlineInputBorder(),
                                                    hintText: LanguageService
                                                        .getTranslated(context,
                                                            "addlocation_description_hint"),
                                                  ),
                                                ),
                                              ),

                                              SizedBox(
                                                  height: CustomSpacing.three),
                                              Padding(
                                                padding: EdgeInsets.all(0.0),
                                                child: Row(
                                                  children: [
                                                    Checkbox(
                                                      value: addToSOVCheck,
                                                      onChanged: (trialStatus
                                                                  .isNotEmpty &&
                                                              !hasAnyPlan)
                                                          ? null
                                                          : areFieldsDisabled()
                                                              ? null // Disable checkbox if `areFieldsDisabled` is true
                                                              : (bool? value) {
                                                                  setState(() {
                                                                    addToSOVCheck =
                                                                        !addToSOVCheck;
                                                                  });
                                                                },
                                                    ),
                                                    SizedBox(width: 8),
                                                    Text(
                                                      LanguageService
                                                          .getTranslated(
                                                              context,
                                                              "add_to_sov"),
                                                      style: typography.Body1,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (int.parse(
                                                      hasHazardLicenseStatus
                                                          .toString()) >
                                                  0) ...[
                                                Container(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          left: 10),
                                                  child: Text(
                                                    isEditMode
                                                        ? "Available improvement credits "
                                                                " : " +
                                                            getLocationImprovementCount
                                                                .toString()
                                                        : LanguageService
                                                                .getTranslated(
                                                                    context,
                                                                    "available_locations") +
                                                            " : " +
                                                            hasHazardLicenseStatus
                                                                .toString(),
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 20,
                                                    ),
                                                  ),
                                                )
                                              ] else if (!hasAnyPlan) ...[
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              left: 10),
                                                      child: Text(
                                                        LanguageService
                                                                .getTranslated(
                                                                    context,
                                                                    "available_locations") +
                                                            " : " +
                                                            hazardLicenseStatus2
                                                                .toString(),
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 20,
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(width: 5),
                                                    InkWell(
                                                        onTap: () {
                                                          if (Platform.isIOS) {
                                                            Fluttertoast
                                                                .showToast(
                                                              msg:
                                                                  "Please complete the payment on the website.",
                                                              toastLength: Toast
                                                                  .LENGTH_SHORT,
                                                              gravity:
                                                                  ToastGravity
                                                                      .BOTTOM,
                                                            );
                                                          } else {
                                                            Navigator.push(
                                                                context,
                                                                MaterialPageRoute(
                                                                    builder:
                                                                        (context) =>
                                                                            PurchaseLicensePage()));
                                                          }
                                                        },
                                                        child: Text(
                                                          "Upgrade Now",
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.orange,
                                                              fontSize: 16),
                                                        ))
                                                  ],
                                                ),
                                              ] else ...[
                                                Container(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          left: 10),
                                                  child: const Text(
                                                    "No locations. Upgrade Now to create SOV!",
                                                    style: TextStyle(
                                                      color: Colors.redAccent,
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                              if (addToSOVCheck)
                                                Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8.0),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      SizedBox(height: 8.0),
                                                      // Account Name (Pre-filled and non-editable)
                                                      TextField(
                                                        controller:
                                                            TextEditingController(
                                                                text: widget
                                                                    .accountName),
                                                        enabled: false,
                                                        decoration:
                                                            InputDecoration(
                                                          labelText: LanguageService
                                                              .getTranslated(
                                                                  context,
                                                                  "account_name"),
                                                          border:
                                                              const OutlineInputBorder(),
                                                        ),
                                                      ),
                                                      SizedBox(height: 8.0),
                                                      // Sub-account Name (Pre-filled and non-editable)
                                                      TextField(
                                                        controller:
                                                            TextEditingController(
                                                                text: widget
                                                                    .subAccountName),
                                                        enabled: false,
                                                        decoration:
                                                            InputDecoration(
                                                          labelText: LanguageService
                                                              .getTranslated(
                                                                  context,
                                                                  "sub_account_name"),
                                                          border:
                                                              const OutlineInputBorder(),
                                                        ),
                                                      ),
                                                      SizedBox(height: 8.0),
                                                      Consumer<SOVListProvider>(
                                                        builder: (context,
                                                            sovProvider,
                                                            child) {
                                                          return Column(
                                                            children: [
                                                              TextFormField(
                                                                controller:
                                                                    sovController,
                                                                onChanged:
                                                                    (value) {
                                                                  setState(() {
                                                                    selectedSovId =
                                                                        "";
                                                                    isSovSelected =
                                                                        false;
                                                                  });

                                                                  _debounce
                                                                      ?.cancel();
                                                                  _debounce = Timer(
                                                                      Duration(
                                                                          milliseconds:
                                                                              300),
                                                                      () {
                                                                    sovProvider
                                                                        .fetchSovList(
                                                                      context,
                                                                      value,
                                                                      1,
                                                                      // IMPORTANT
                                                                      100,
                                                                      '',
                                                                    );
                                                                  });
                                                                },
                                                                onTap: () {
                                                                  if (!isSovSelected &&
                                                                      sovController
                                                                          .text
                                                                          .isEmpty) {
                                                                    sovProvider
                                                                        .setLoading(
                                                                            true);
                                                                    sovProvider
                                                                        .fetchSovList1(
                                                                            context,
                                                                            "",
                                                                            1,
                                                                            100,
                                                                            '');
                                                                  }
                                                                },
                                                                decoration:
                                                                    InputDecoration(
                                                                  labelText: LanguageService
                                                                      .getTranslated(
                                                                          context,
                                                                          "name_of_sov"),
                                                                  border:
                                                                      OutlineInputBorder(),
                                                                  suffixIcon: sovProvider
                                                                          .isLoading
                                                                      ? Padding(
                                                                          padding: const EdgeInsets
                                                                              .all(
                                                                              10),
                                                                          child:
                                                                              SizedBox(
                                                                            width:
                                                                                20,
                                                                            height:
                                                                                20,
                                                                            child:
                                                                                CircularProgressIndicator(strokeWidth: 2),
                                                                          ),
                                                                        )
                                                                      : Icon(Icons
                                                                          .search),
                                                                ),
                                                              ),

                                                              // SHOW LIST ONLY WHEN NOT SELECTED + NOT LOADING + LIST AVAILABLE
                                                              if (!isSovSelected &&
                                                                  !sovProvider
                                                                      .isLoading &&
                                                                  sovProvider
                                                                      .filtersovlist
                                                                      .isNotEmpty)
                                                                Container(
                                                                  margin: EdgeInsets
                                                                      .only(
                                                                          top:
                                                                              4),
                                                                  child: ListView
                                                                      .builder(
                                                                    shrinkWrap:
                                                                        true,
                                                                    physics:
                                                                        NeverScrollableScrollPhysics(),
                                                                    itemCount: sovProvider
                                                                        .filtersovlist
                                                                        .length,
                                                                    itemBuilder:
                                                                        (context,
                                                                            index) {
                                                                      final sov =
                                                                          sovProvider
                                                                              .filtersovlist[index];
                                                                      return ListTile(
                                                                        title: Text(sov.name ??
                                                                            ''),
                                                                        onTap:
                                                                            () {
                                                                          setState(
                                                                              () {
                                                                            selectedSovId =
                                                                                sov.sovId ?? "";
                                                                            sovController.text =
                                                                                sov.name ?? "";
                                                                            isSovSelected =
                                                                                true;
                                                                          });

                                                                          sovProvider
                                                                              .clearAutoCompleteList();
                                                                        },
                                                                      );
                                                                    },
                                                                  ),
                                                                ),

                                                              // HIDE LIST WHILE LOADING
                                                              if (!isSovSelected &&
                                                                  sovProvider
                                                                      .isLoading)
                                                                SizedBox(),
                                                            ],
                                                          );
                                                        },
                                                      ),

                                                      // SoV Autocomplete Dropdown// SoV Autocomplete Dropdown
                                                      // // SoV Autocomplete Dropdown
                                                      // Consumer<SOVListProvider>(
                                                      //   builder: (context, sovProvider, child) {
                                                      //     return Column(
                                                      //       children: [
                                                      //         TextFormField(
                                                      //           controller: sovController,
                                                      //           onChanged: (value) {
                                                      //             // Reset SoV ID immediately when typing
                                                      //             setState(() {
                                                      //               selectedSovId = "";
                                                      //             });
                                                      //
                                                      //             // Debounce provider call to avoid spamming updates
                                                      //             _debounce?.cancel();
                                                      //             _debounce = Timer(const Duration(milliseconds: 300), () {
                                                      //               // Fetch filtered SOV list when user types
                                                      //               sovProvider.fetchAutoCompleteSovListLocations(
                                                      //                 context,
                                                      //                 widget.accountId,
                                                      //                 widget.subAccountId,
                                                      //                 searchQuery: value, // Pass the search query
                                                      //               );
                                                      //             });
                                                      //           },
                                                      //           onTap: () {
                                                      //             // Clear and fetch initial list when field is tapped
                                                      //             if (sovController.text.isEmpty) {
                                                      //               sovProvider.fetchAutoCompleteSovListLocations(
                                                      //                 context,
                                                      //                 widget.accountId,
                                                      //                 widget.subAccountId,
                                                      //               );
                                                      //             }
                                                      //           },
                                                      //           validator: (value) {
                                                      //             if (addToSOVCheck) {
                                                      //               // Apply validation only if addToSOVCheck is true
                                                      //               if (value == null || value.isEmpty) {
                                                      //                 return LanguageService.getTranslated(
                                                      //                   context,
                                                      //                   "addlocation_address_error",
                                                      //                 );
                                                      //               }
                                                      //             }
                                                      //             return null;
                                                      //           },
                                                      //           decoration: InputDecoration(
                                                      //             labelText: "Name of the SoV",
                                                      //             border: const OutlineInputBorder(),
                                                      //             suffixIcon: Icon(Icons.search),
                                                      //           ),
                                                      //         ),
                                                      //         Text(sovProvider.filteredAutoCompleteList1.length.toString()),
                                                      //         // Show autocomplete options when provider has results
                                                      //         if (sovProvider.filteredAutoCompleteList1.isNotEmpty)
                                                      //           Container(
                                                      //             decoration: BoxDecoration(
                                                      //               color: Theme.of(context).colorScheme.surface,
                                                      //               borderRadius: BorderRadius.circular(8),
                                                      //               boxShadow: [
                                                      //                 BoxShadow(
                                                      //                   color: Colors.black.withOpacity(0.1),
                                                      //                   blurRadius: 4,
                                                      //                   offset: Offset(0, 2),
                                                      //                 ),
                                                      //               ],
                                                      //             ),
                                                      //             margin: EdgeInsets.only(top: 4),
                                                      //             child: ListView.builder(
                                                      //               shrinkWrap: true,
                                                      //               physics: NeverScrollableScrollPhysics(),
                                                      //               itemCount: sovProvider.filteredAutoCompleteList1.length,
                                                      //               itemBuilder: (context, index) {
                                                      //                 final sov = sovProvider.filteredAutoCompleteList1[index];
                                                      //                 return ListTile(
                                                      //                   title: Text(sov.name ?? ''),
                                                      //                   subtitle: sov.name != null ? Text(sov.name!) : null,
                                                      //                   onTap: () {
                                                      //                     setState(() {
                                                      //                       selectedSovId = sov.sovId ?? "";
                                                      //                       sovController.text = sov.name ?? "";
                                                      //                       sovProvider.clearAutoCompleteList();
                                                      //                     });
                                                      //                   },
                                                      //                 );
                                                      //               },
                                                      //             ),
                                                      //           ),
                                                      //       ],
                                                      //     );
                                                      //   },
                                                      // ),
                                                      SizedBox(height: 8),
                                                      TextField(
                                                        controller:
                                                            tagController,
                                                        style: const TextStyle(
                                                            color:
                                                                Colors.white),
                                                        decoration:
                                                            InputDecoration(
                                                          labelText:
                                                              "Enter tags separated by commas",
                                                          labelStyle:
                                                              const TextStyle(
                                                                  color: Colors
                                                                      .white),
                                                          enabledBorder:
                                                              const OutlineInputBorder(
                                                            borderSide:
                                                                BorderSide(
                                                                    color: Colors
                                                                        .grey),
                                                          ),
                                                          focusedBorder:
                                                              const OutlineInputBorder(
                                                            borderSide:
                                                                BorderSide(
                                                                    color: Colors
                                                                        .blue),
                                                          ),
                                                          hintStyle:
                                                              const TextStyle(
                                                                  color: Colors
                                                                      .white54),
                                                        ),
                                                        onChanged: (value) {
                                                          if (value
                                                              .contains(',')) {
                                                            final tag = value
                                                                .replaceAll(
                                                                    ',', '')
                                                                .trim();

                                                            if (tag.isNotEmpty &&
                                                                !tags.contains(
                                                                    tag)) {
                                                              setState(() {
                                                                tags.add(tag);
                                                              });
                                                            }

                                                            tagController
                                                                .clear();
                                                          }
                                                        },
                                                      ),

                                                      const SizedBox(
                                                          height: 12),

                                                      /// 🧩 TAG CHIPS
                                                      if (tags.isNotEmpty)
                                                        Wrap(
                                                          spacing: 8,
                                                          runSpacing: 8,
                                                          children:
                                                              tags.map((tag) {
                                                            return Chip(
                                                              label: Text(
                                                                tag,
                                                                style: const TextStyle(
                                                                    color: Colors
                                                                        .white),
                                                              ),
                                                              backgroundColor:
                                                                  Colors.grey[
                                                                      700],
                                                              deleteIconColor:
                                                                  Colors.white,
                                                              onDeleted: () {
                                                                setState(() {
                                                                  tags.remove(
                                                                      tag);
                                                                });
                                                              },
                                                            );
                                                          }).toList(),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              SizedBox(
                                                  height: CustomSpacing.three),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8.0),
                                                child: Column(
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: Consumer<
                                                              UserProfileProvider>(
                                                            builder: (context,
                                                                userProfileProvider,
                                                                child) {
                                                              final trialStatus =
                                                                  userProfileProvider
                                                                              .trialInfo[
                                                                          'status'] ??
                                                                      '';
                                                              final bool
                                                                  isTrialExpired =
                                                                  trialStatus.contains(
                                                                          'Expired') &&
                                                                      isHasAnyPlan ==
                                                                          false;

                                                              return CustomButton(
                                                                type: ButtonType
                                                                    .elevated,

                                                                // 🚫 Disable when expired
                                                                onPressed:
                                                                    isTrialExpired
                                                                        ? null
                                                                        : () async {
                                                                            if (_formKey.currentState!.validate()) {
                                                                              var body = _buildRequestBody();

                                                                              if (isEditMode) {
                                                                                await _handleUpdateLocation(context, body);
                                                                              } else {
                                                                                await _handleAddLocation(context, body);
                                                                              }
                                                                            }
                                                                          },

                                                                child: _buildButtonChild(
                                                                    context,
                                                                    isTrialExpired),
                                                              );
                                                            },
                                                          ),
                                                        ),
                                                        // Expanded(
                                                        //   child: CustomButton(
                                                        //     type: ButtonType.elevated,
                                                        //     onPressed: () async {
                                                        //       if (_formKey
                                                        //           .currentState!
                                                        //           .validate()) {
                                                        //         var body =
                                                        //             _buildRequestBody();
                                                        //         if (isEditMode) {
                                                        //           // ✅ EDIT MODE → UPDATE
                                                        //           await _handleUpdateLocation(
                                                        //               context, body);
                                                        //         } else {
                                                        //           // ✅ ADD MODE → ADD
                                                        //           await _handleAddLocation(
                                                        //               context, body);
                                                        //         }
                                                        //
                                                        //         // if (isEditMode) {
                                                        //         //   await Provider.of<
                                                        //         //               LocationListProvider>(
                                                        //         //           context,
                                                        //         //           listen:
                                                        //         //               false)
                                                        //         //       .addLocation(
                                                        //         //     context,
                                                        //         //     widget.accountId!,
                                                        //         //     widget
                                                        //         //         .subAccountId!,
                                                        //         //     widget.sovId,
                                                        //         //     widget
                                                        //         //         .accountName!,
                                                        //         //     widget
                                                        //         //         .subAccountName!,
                                                        //         //     body,
                                                        //         //   );
                                                        //         // } else {
                                                        //         //   // Update Location
                                                        //         //   await _handleUpdateLocation(
                                                        //         //       context, body);
                                                        //         // }
                                                        //       }
                                                        //     },
                                                        //     child: _buildButtonChild(
                                                        //         context),
                                                        //   ),
                                                        // ),
                                                      ],
                                                    ),
                                                    SizedBox(
                                                        height:
                                                            CustomSpacing.two),
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: CustomButton(
                                                            type: ButtonType
                                                                .outlined,
                                                            onPressed: () {
                                                              if (widget.newUser
                                                                      .toString() ==
                                                                  "true") {
                                                                Navigator.of(
                                                                        context)
                                                                    .push(
                                                                  MaterialPageRoute(
                                                                      builder:
                                                                          (_) =>
                                                                              DashboardScreen(
                                                                                newUser: "false",
                                                                              )),
                                                                );
                                                              } else {
                                                                Navigator.pop(
                                                                    context);
                                                              }
                                                            },
                                                            child: Text(
                                                              LanguageService
                                                                  .getTranslated(
                                                                      context,
                                                                      "cancel"),
                                                              style: typography
                                                                      .ButtonLarge
                                                                  .copyWith(
                                                                color: themeProvider
                                                                    .getTheme
                                                                    .colorScheme
                                                                    .primary,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          );
                                        }),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                    // Consumer<UserProfileProvider>(
                    //   builder: (context, userProfile, child) {
                    //     final trialStatus =
                    //         userProfile.trialInfo['status'] ?? '';
                    //     if (trialStatus.contains('Expired') &&
                    //         isHasAnyPlan == false) {
                    //       return Container(
                    //         padding: EdgeInsets.symmetric(
                    //             horizontal: 16, vertical: 8),
                    //         decoration: BoxDecoration(
                    //           color: Theme.of(context)
                    //               .colorScheme
                    //               .surface
                    //               .withOpacity(0.95),
                    //         ),
                    //         child: Column(
                    //           mainAxisAlignment: MainAxisAlignment.center,
                    //           children: [
                    //             SizedBox(height: CustomSpacing.four),
                    //             // Text(isHasAnyPlan.toString()),
                    //             Padding(
                    //               padding: const EdgeInsets.all(8.0),
                    //               child: MessageCard(
                    //                 messageTextSpans: [
                    //                   TextSpan(
                    //                     text:
                    //                         'We hope you\'ve enjoyed your trial period! To continue accessing your account and keep your data safe, please upgrade before December 24, 2026. After this date, we will need to delete your data. Thank you for being with us!',
                    //                     style: typography.Body1,
                    //                   ),
                    //                   // tappable
                    //                   TextSpan(
                    //                     text: ' Upgrade Now!',
                    //                     style: typography.Body1.copyWith(
                    //                       color: AppColors.primaryMain,
                    //                     ),
                    //                     recognizer: TapGestureRecognizer()
                    //                       ..onTap = () {
                    //                         Navigator.of(context).push(
                    //                             MaterialPageRoute(
                    //                                 builder: (_) =>
                    //                                     PurchaseLicensePage()));
                    //                       },
                    //                   ),
                    //                 ],
                    //                 isError: true,
                    //               ),
                    //             ),
                    //           ],
                    //         ),
                    //       );
                    //     }
                    //     return SizedBox.shrink();
                    //   },
                    // ),
                  ]);
          }),
        );
      }),
    );
  }

  Map<String, dynamic> _buildRequestBody() {
    String tagsString =
        tags.map((e) => "'${e.trim()}'").where((e) => e != "''").join(',');

    return {
      "data": {
        "account_id": widget.accountId,
        "sub_account_id": widget.subAccountId,
        "sov_id": null,
        "by_search": false,
        "location_name": _locationAddress1Controller.text,
        //_locationNameController.text,
        "location_type": [_selectedLocationType],
        "description": _locationDescriptionController.text,
        "address": _locationAddressController.text,
        "city": _locationCityController.text,
        "state": _locationStateController.text,
        "zip": _locationZipCodeController.text,
        "country": _selectedCountry,
        "is_autocomplete": _isSelectedFromAutocomplete,
        "new": addToSOVCheck,
        "rented": rented,
        "leased": leased,
        "latitude": _selectedLatLng?.latitude.toString() ?? _latitudeController,
        // markers.isNotEmpty ? markers.values.first.position.latitude : "0.0",
        "longitude":
            _selectedLatLng?.longitude.toString() ?? _longitudeController,

        // markers.isNotEmpty
        //     ? markers.values.first.position.longitude
        //     : "0.0",
        // "latitude": markers.values.first.position.latitude ?? "0.0",
        // "longitude": markers.values.first.position.longitude,
        "user_id": FirebaseAuth.instance.currentUser!.uid,
        "add_to_sov": addToSOVCheck.toString(),
        "tags": tagsString, // Send the actual tags list
        "name": sovController.text.toString(),
        "account_name": widget.accountName,
        "sub_account_name": widget.subAccountName,
        if (widget.is_conflict == true) "is_conflict": widget.is_conflict,
        if (isEditMode) "location_id": widget.locationId,
      }
    };
  }

  Future<void> _handleAddLocation(
      BuildContext context, Map<String, dynamic> body) async {
    final locationListProvider =
        Provider.of<LocationListProvider>(context, listen: false);
    if (widget.accountId == null || widget.subAccountId == null) {
      // Handle the error, e.g. show a dialog or return early
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Account ID or Sub Account ID is missing.")),
      );
      return;
    }
    await locationListProvider.addLocation(
      context,
      widget.accountId!,
      widget.subAccountId!,
      widget.sovId,
      widget.accountName ?? "Default Account",
      widget.subAccountName ?? "Default Subaccount",
      body,
    );
  }

  Future<void> _handleUpdateLocation(
    BuildContext context,
    Map<String, dynamic> body,
  ) async {
    final locationProfileProvider =
        Provider.of<MyLocationListProvider>(context, listen: false);

    final success = await locationProfileProvider.updateLocationDetails(
      context,
      widget.accountId!,
      widget.subAccountId!,
      widget.sovId,
      widget.locationId!,
      body,
    );

    if (!mounted) return;
    if (success.toLowerCase() == 'true') {
      Navigator.pop(context, true);
    }
  }

  // Future<void> _handleUpdateLocation(
  //     BuildContext context, Map<String, dynamic> body) async {
  //   final locationProfileProvider =
  //       Provider.of<MyLocationListProvider>(context, listen: false);
  //   var success = await locationProfileProvider.updateLocationDetails(
  //     context,
  //     widget.accountId!,
  //     widget.subAccountId!,
  //     widget.sovId,
  //     widget.locationId!,
  //     body,
  //   );
  //
  //   if (success.toLowerCase() == 'true' && mounted) {
  //     if (widget.is_conflict == true) {
  //       Navigator.pop(context);
  //     } else {
  //       WidgetsBinding.instance.addPostFrameCallback((_) async {
  //         if (!mounted) return;
  //         Navigator.pop(context, true);
  //         // Navigate and wait for result
  //         // final result = await Navigator.pushAndRemoveUntil(
  //         //   context,
  //         //   MaterialPageRoute(
  //         //     builder: (context) => LocationProfile(
  //         //       accountId: widget.accountId!,
  //         //       subAccountId: widget.subAccountId!,
  //         //       sovId: widget.sovId,
  //         //       accountName: widget.accountName!,
  //         //       subAccountName: widget.subAccountName!,
  //         //       sovName: widget.sovName,
  //         //       locationId: widget.locationId,
  //         //       searchQuery: widget.searchQuery,
  //         //       page: widget.page!,
  //         //       totalPages: widget.totalPages,
  //         //     ),
  //         //   ),
  //         //   (route) => false,
  //         // );
  //
  //         // Reload the page when coming back
  //         if (mounted) {
  //           setState(() {});
  //         }
  //       });
  //     }
  //   }
  // }
  Widget _buildButtonChild(BuildContext context, bool isTrialExpired) {
    final locationListProvider = Provider.of<LocationListProvider>(context);
    final locationProfileProvider =
        Provider.of<MyLocationListProvider>(context);

    final typography = CustomTypography(context);

    // Loader
    if (locationListProvider.isAddLocationLoading ||
        locationProfileProvider.isLoading) {
      return SizedBox(
        height: 25,
        width: 25,
        child: CircularProgressIndicator(
          color: AppColors.black,
        ),
      );
    }

    // 🔴 Expired State
    if (isTrialExpired) {
      return Text(
        "Expired",
        style: typography.ButtonLarge.copyWith(
          color: Colors.red,
        ),
      );
    }

    return Text(
      isEditMode
          ? LanguageService.getTranslated(context, "update")
          : LanguageService.getTranslated(context, "create"),
      style: typography.ButtonLarge.copyWith(
        color: Colors.black,
      ),
    );
  }

  // Widget _buildButtonChild(BuildContext context) {
  //   final locationListProvider = Provider.of<LocationListProvider>(context);
  //   final locationProfileProvider =
  //   Provider.of<MyLocationListProvider>(context);
  //
  //   final typography = CustomTypography(context);
  //
  //   return Consumer<UserProfileProvider>(
  //     builder: (context, userProfileProvider, child) {
  //       final trialStatus = userProfileProvider.trialInfo['status'] ?? '';
  //       final bool isTrialExpired =
  //           trialStatus.contains('Expired') && isHasAnyPlan == false;
  //
  //       // Show loader
  //       if (locationListProvider.isAddLocationLoading ||
  //           locationProfileProvider.isLoading) {
  //         return Center(
  //           child: SizedBox(
  //             height: 25,
  //             width: 25,
  //             child: CircularProgressIndicator(
  //               color: AppColors.black,
  //             ),
  //           ),
  //         );
  //       }
  //
  //       // 🔴 If Trial Expired → Show Expired
  //       if (isTrialExpired) {
  //         return Text(
  //           "Expired",
  //           style: typography.ButtonLarge.copyWith(
  //             color: Colors.red,
  //           ),
  //         );
  //       }
  //
  //       // ✅ Normal Create / Update
  //       return Text(
  //         isEditMode
  //             ? LanguageService.getTranslated(context, "update")
  //             : LanguageService.getTranslated(context, "create"),
  //         style: typography.ButtonLarge.copyWith(
  //           color: Colors.black,
  //         ),
  //       );
  //     },
  //   );
  // }
  // Widget _buildButtonChild(BuildContext context) {
  //   final locationListProvider = Provider.of<LocationListProvider>(context);
  //   final locationProfileProvider =
  //       Provider.of<MyLocationListProvider>(context);
  //   Consumer<UserProfileProvider>(
  //       builder: (context, userProfileProvider, child) {
  //         final trialStatus = userProfileProvider.trialInfo['status'] ?? '';
  //
  //         return (trialStatus.contains('Expired') && isHasAnyPlan == false)
  //             ? Container(
  //           padding:
  //           EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  //           decoration: BoxDecoration(
  //             color: Theme.of(context)
  //                 .colorScheme
  //                 .surface
  //                 .withOpacity(0.95),
  //           ),
  //           child: Column(
  //             mainAxisAlignment: MainAxisAlignment.center,
  //             children: [
  //               SizedBox(height: 10),
  //               Padding(
  //                 padding: const EdgeInsets.all(8.0),
  //                 child: MessageCard(
  //                   messageTextSpans: [
  //                     TextSpan(
  //                       text:  'We hope you\'ve enjoyed your trial period! To continue accessing your account and keep your data safe, please upgrade before December 31, 2026. After this date, we will need to delete your data. Thank you for being with us!',
  //                       style: typography.Body1,
  //                     ),
  //                     // tappable
  //                     TextSpan(a
  //                       text: ' Upgrade Now!',
  //                       style: typography.Body1.copyWith(
  //                         color: AppColors.primaryMain,
  //                       ),
  //                       recognizer: TapGestureRecognizer()
  //                         ..onTap = () {
  //                           Navigator.of(context).push(
  //                               MaterialPageRoute(
  //                                   builder: (_) =>
  //                                       PurchaseLicensePage()));
  //                         },
  //                     ),
  //                   ],
  //                   isError: true,
  //                 ),
  //               ),
  //             ],
  //           ),
  //         )
  //             :
  //   var typography = CustomTypography(context);
  //   if (locationListProvider.isAddLocationLoading ||
  //       locationProfileProvider.isLoading) {
  //     return Center(
  //       child: SizedBox(
  //         height: 25,
  //         width: 25,
  //         child: CircularProgressIndicator(
  //           color: AppColors.black,
  //         ),
  //       ),
  //     );
  //   } else {
  //     return Text(
  //       isEditMode
  //           ? LanguageService.getTranslated(context, "update")
  //           : LanguageService.getTranslated(context, "create"),
  //       // widget.locationId?.isNotEmpty == true ? false : true ? LanguageService.getTranslated(context, "create")
  //       //     : LanguageService.getTranslated(context, "update"),
  //       style: typography.ButtonLarge.copyWith(
  //         color: Colors.black,
  //       ),
  //     );
  //   }
  // }

  bool areFieldsDisabled() {
    var provider = Provider.of<UserProfileProvider>(context, listen: false);
    var trialStatus = provider.trialInfo['status'] ?? '';
    var locations = provider.trialInfo['locations'] ?? 0;
    var total = provider.trialInfo['maxLocations'] ?? 0;
    var hasanyPlan = hasAnyPlan;
    bool isAddMode = !isEditMode;
    return trialStatus.isNotEmpty && locations < 1 && isAddMode && !hasanyPlan;
  }

  String? getCountryCodeFromName(String countryName) {
    return countryNameToCodeMap[countryName];
  }

  // Add method to handle place selection
  void _handlePlaceSelection(Suggestion suggestion) async {
    final placeApiProvider = PlaceApiProvider(sessionToken);
    // Declare geometry variable at the method level
    Map<String, dynamic>? geometry;

    try {
      final placeDetails =
          await placeApiProvider.getPlaceDetails(suggestion.placeId);

      // Extract address components
      final addressComponents = placeDetails['address_components'] as List;
      String? city, state, country, postalCode;

      for (var component in addressComponents) {
        final types = component['types'] as List;
        if (types.contains('locality')) {
          city = component['long_name'];
        } else if (types.contains('administrative_area_level_1')) {
          state = component['long_name'];
        } else if (types.contains('country')) {
          country = component['long_name'];
        } else if (types.contains('postal_code')) {
          postalCode = component['long_name'];
        }
      }

      // Get geometry data
      geometry = placeDetails['geometry']['location'] as Map<String, dynamic>;

      // Update form fields
      setState(() {
        _locationNameController.text = placeDetails['formatted_address'] ??
            ''; //placeDetails['name'] ?? '';
        _locationAddress1Controller.text = placeDetails['name'] ?? '';
        _locationAddressController.text =
            placeDetails['formatted_address'] ?? '';
        if (city != null) _locationCityController.text = city;
        if (state != null) _locationStateController.text = state;
        if (postalCode != null) _locationZipCodeController.text = postalCode;

        // Store coordinates but DON'T show marker for autocomplete selections
        _selectedLatLng = LatLng(geometry!['lat'], geometry!['lng']);
      });

      if (country != null) _updateSelectedCountry(country);

      // Move camera to selected location but don't add marker
      // Move camera to selected location
      if (geometry != null) {
        try {
          if (!mounted) return;
          if (!_mapController.isCompleted) return; // ✅ ADD THIS

          final GoogleMapController controller = await _mapController.future;
          controller.animateCamera(CameraUpdate.newLatLng(
            LatLng(geometry!['lat'], geometry!['lng']),
          ));
        } catch (e) {
          // Map was disposed (keyboard open hid the map) — safe to ignore
          debugPrint('Map camera update skipped: $e');
        }
      }
      // if (geometry != null) {
      //   final GoogleMapController controller = await _mapController.future;
      //   controller.animateCamera(CameraUpdate.newLatLng(
      //     LatLng(geometry!['lat'], geometry!['lng']),
      //   ));
      // }

      // Set flag to true
      _isSelectedFromAutocomplete = true;
    } catch (e) {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get place details: $e')),
      );
    }
  }

  void _updateSelectedCountry(String country) {
    setState(() {
      _selectedCountry = country;
      countryPickerKey = UniqueKey(); // Update key to force rebuild
    });
  }

  Future<void> _updateAddressFromCoordinates(LatLng position) async {
    print(" Coordinates received: ${position.latitude}, ${position.longitude}");

    try {
      print(" Attempting reverse geocoding...");

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      print(
          " Reverse geocoding successful, found ${placemarks.length} placemarks");

      if (placemarks.isNotEmpty) {
        final place = placemarks[0];
        print("🏠 Address components:");
        print("   Street: ${place}");
        print("   Locality: ${place.subAdministrativeArea}");
        print("   Administrative Area: ${place.administrativeArea}");
        print("   Postal Code: ${place.name}");
        print("   Country: ${place.country}");
        print("   Country: ${place}");

        _updateFormFieldsWithPlacemark(place);
      } else {
        print(" No placemarks found");
        _setFallbackAddress(position);
      }
    } catch (e) {
      print("Reverse geocoding failed: $e");
      print(" Platform: ${Theme.of(context).platform}");

      // Use fallback address with coordinates
      _setFallbackAddress(position);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Address lookup unavailable. Using coordinates as location reference.'),
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  void _setFallbackAddress(LatLng position) {
    setState(() {
      _locationAddressController.text =
          "Coordinates: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}";
      _locationCityController.text = "Drag pin to set address";
      _locationStateController.text = "Drag pin to set state";
      _locationZipCodeController.text = "Drag pin to set zip code";
    });
  }

  void _updateFormFieldsWithPlacemark(Placemark place) {
    setState(() {
      // Build address from available components
      String address = "";
      if (place.street != null && place.street!.isNotEmpty) {
        address = place.street!;
        if (place.subThoroughfare != null &&
            place.subThoroughfare!.isNotEmpty) {
          address = "$address";
        }
      }

      // _locationAddress1Controller.text = "${place.name}";
      _locationAddressController.text =
          "${place.name ?? ""}${place.subLocality != null && place.subLocality!.isNotEmpty ? ", ${place.subLocality}" : ""}"
          "${place.locality != null && place.locality!.isNotEmpty ? ", ${place.locality}" : ""}"
          "${place.administrativeArea != null && place.administrativeArea!.isNotEmpty ? ", ${place.administrativeArea}" : ""}"
          "${place.postalCode != null && place.postalCode!.isNotEmpty ? ", ${place.postalCode}" : ""}"
          "${place.country != null && place.country!.isNotEmpty ? ", ${place.country}" : ""}";
      _locationNameController.text =
          "${place.name ?? ""}${place.subLocality != null && place.subLocality!.isNotEmpty ? ", ${place.subLocality}" : ""}"
          "${place.locality != null && place.locality!.isNotEmpty ? ", ${place.locality}" : ""}"
          "${place.administrativeArea != null && place.administrativeArea!.isNotEmpty ? ", ${place.administrativeArea}" : ""}"
          "${place.postalCode != null && place.postalCode!.isNotEmpty ? ", ${place.postalCode}" : ""}"
          "${place.country != null && place.country!.isNotEmpty ? ", ${place.country}" : ""}";

      _locationCityController.text = place.locality ?? "City not available";
      _locationStateController.text =
          place.administrativeArea ?? "State not available";
      _locationZipCodeController.text = place.postalCode ?? "Zip not available";

      if (place.country != null && place.country!.isNotEmpty) {
        _selectedCountry = place.country!;
      }
    });
    // Update country picker if country changed
    if (place.country != null && place.country!.isNotEmpty) {
      _updateSelectedCountry(place.country!);
    }
  }

  Widget _buildToggleButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF90CAF9) : Colors.black26,
          borderRadius: BorderRadius.only(
            topLeft:
                !isSearchSelected ? Radius.circular(8) : Radius.circular(8),
            bottomLeft:
                !isSearchSelected ? Radius.circular(8) : Radius.circular(8),
            topRight:
                isSearchSelected ? Radius.circular(8) : Radius.circular(8),
            bottomRight:
                isSearchSelected ? Radius.circular(8) : Radius.circular(8),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
