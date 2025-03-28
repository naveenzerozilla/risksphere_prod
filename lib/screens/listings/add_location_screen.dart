import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:RiskSphare/providers/location_list_provider.dart';
import 'package:RiskSphare/providers/location_profile_provider.dart';
import 'package:RiskSphare/providers/my_location_list_provider.dart';
import 'package:RiskSphare/providers/user_profile_provider.dart';
import 'package:RiskSphare/screens/listings/location_profile.dart';
import 'package:RiskSphare/screens/listings/widgets/auto_complete_options_sovs.dart';
import 'package:RiskSphare/screens/listings/widgets/map_full_screen.dart';
import 'package:RiskSphare/screens/listings/widgets/message_card.dart';
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
import '../../providers/place_api_provider.dart';
import '../../providers/sov_list_provider.dart';
import '../../providers/theme_provider.dart';
import '../../service/language_service.dart';
import 'package:country_picker/country_picker.dart' as country_picker;

class AddLocationScreen extends StatefulWidget {
  final String accountId;
  final String accountName;
  final String subAccountId;
  final String subAccountName;
  final String sovId;
  final String sovName;
  final String locationId;
  final String locationName;
  final String locationIdForRef;
  final String searchQuery;
  final String page;
  final String totalPages;

  const AddLocationScreen(
      {super.key,
      required this.accountId,
      required this.subAccountId,
      required this.sovId,
      this.locationId = "",
      this.accountName = "",
      this.subAccountName = "",
      this.sovName = "",
      this.locationName = "",
      this.locationIdForRef = "",
      this.searchQuery = "",
      this.page = "0",
      this.totalPages = "1"});

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
  TextEditingController _locationCityController = TextEditingController();
  TextEditingController _locationStateController = TextEditingController();
  TextEditingController _locationZipCodeController = TextEditingController();
  TextEditingController _locationDescriptionController =
      TextEditingController();
  String _selectedCountry = "United States";

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

  initState() {
    super.initState();
    if (widget.locationId.isNotEmpty) {
      // get location details
      var provider =
          Provider.of<MyLocationListProvider>(context, listen: false);
      _locationNameController.text =
          provider.locationProfile?.finalAddress?.locationName ?? "";
      _locationAddressController.text =
          provider.locationProfile?.finalAddress?.address ?? "";
      _selectedCountry = provider.locationProfile?.finalAddress?.country ?? "";
      _locationZipCodeController.text =
          provider.locationProfile?.finalAddress?.zip ?? "";
      //_selectedLocationType = provider.result?.locationType??"";
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
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (provider.locationProfile?.finalAddress?.latitude != null &&
            provider.locationProfile?.finalAddress?.longitude != null) {
          final MarkerId markerId = MarkerId("location_marker");
          final marker = Marker(
            markerId: markerId,
            position: LatLng(
              double.parse(
                  provider.locationProfile!.finalAddress!.latitude!.toString()),
              double.parse(provider.locationProfile!.finalAddress!.longitude!
                  .toString()),
            ),
            infoWindow: InfoWindow(
                title: provider.locationProfile?.finalAddress?.locationName),
          );
          setState(() {
            markers[markerId] = marker;
          });

          // Move camera to marker position
          final GoogleMapController controller = await _mapController.future;
          controller.animateCamera(CameraUpdate.newLatLng(
            LatLng(
              double.parse(
                  provider.locationProfile!.finalAddress!.latitude!.toString()),
              double.parse(provider.locationProfile!.finalAddress!.longitude!
                  .toString()),
            ),
          ));
        }
      });
    }
    print("account name: ${widget.accountName}");
    print("sub account name: ${widget.subAccountName}");
  }

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
          body: Stack(
            children: [
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
                int locations = userProfileProvider.trialInfo['locations'] ?? 0;
                int total = userProfileProvider.trialInfo['maxLocations'] ?? 0;
                return Column(
                  children: [
                    SizedBox(height: CustomSpacing.four),
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
                                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        margin:
                                            EdgeInsets.only(left: 8, right: 8),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(8),
                                            topRight: Radius.circular(8),
                                            bottomLeft: Radius.circular(8),
                                            bottomRight: Radius.circular(8),
                                          ),
                                          clipBehavior: Clip.antiAlias,
                                          child: Container(
                                            height: 180,
                                            width: double.infinity,
                                            child: Image.asset(
                                              'assets/images/google_map.png',
                                              fit: BoxFit.cover,
                                            ),
                                            // GoogleMap(
                                            //   mapType: MapType.satellite,
                                            //   initialCameraPosition: _defaultLocation,
                                            //   onMapCreated: (GoogleMapController controller) {
                                            //     _mapController.complete(controller);
                                            //   },
                                            //   markers: Set<Marker>.of(markers.values),
                                            // ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: CustomSpacing.four),
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(left: 8.0),
                                        child: Text(
                                            widget.locationId.isEmpty
                                                ? LanguageService.getTranslated(
                                                    context,
                                                    "addlocation_app_title")
                                                : "Edit Location",
                                            style: typography.H5_Regular),
                                      ),
                                      if (trialStatus.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: MessageCard(
                                              isError: locations < 1,
                                              messageTextSpans: [
                                                TextSpan(
                                                  text:
                                                      '$locations of $total locations left.',
                                                ),
                                                TextSpan(
                                                  recognizer:
                                                      TapGestureRecognizer()
                                                        ..onTap = () {
                                                          ScaffoldMessenger.of(
                                                                  context)
                                                              .showSnackBar(
                                                            SnackBar(
                                                              content: Text(
                                                                "Coming Soon!",
                                                                style: typography
                                                                        .Body1
                                                                    .copyWith(
                                                                  color: AppColors
                                                                      .primaryMain,
                                                                ),
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                  text: ' Upgrade Now!',
                                                  style: TextStyle(
                                                    color:
                                                        AppColors.primaryMain,
                                                  ),
                                                ),
                                              ]),
                                        ),
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(left: 8.0),
                                        child: Text(
                                          widget.locationId.isEmpty
                                              ? LanguageService.getTranslated(
                                                  context,
                                                  "addlocation_app_subtitle")
                                              : "Please provide the necessary information to update the location details",
                                          style: typography.Subtitle1,
                                        ),
                                      ),
                                      SizedBox(
                                        height: CustomSpacing.four,
                                      ),
                                      // Location Name
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: TypeAheadField<Suggestion>(
                                          hideOnEmpty: true,
                                          // hideSuggestionsOnKeyboardHide: true, // Hides suggestions when keyboard is closed
                                          hideKeyboardOnDrag: true,
                                          controller: _locationNameController,
                                          suggestionsCallback: (pattern) async {
                                            if (pattern.isEmpty ||
                                                _isSelectedFromAutocomplete)
                                              return [];
                                            final apiProvider =
                                                PlaceApiProvider(sessionToken);
                                            return await apiProvider
                                                .fetchSuggestions(
                                                    pattern, 'en');
                                          },
                                          loadingBuilder: (context) =>
                                              SizedBox(height: 0),
                                          itemBuilder: (context, suggestion) {
                                            if (areFieldsDisabled())
                                              return Container();
                                            return ListTile(
                                              title: Text(
                                                suggestion.description,
                                                style: typography.Body1,
                                              ),
                                            );
                                          },
                                          builder:
                                              (context, controller, focusNode) {
                                            return Container(
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withOpacity(0.1),
                                                    blurRadius: 8,
                                                    offset: Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: TextField(
                                                enabled: !areFieldsDisabled(),
                                                controller: controller,
                                                focusNode: focusNode,
                                                onTap: () {
                                                  if (_isSelectedFromAutocomplete) {
                                                    focusNode
                                                        .unfocus(); // Prevent dropdown from showing again
                                                  }
                                                },
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
                                                decoration: InputDecoration(
                                                  labelText: LanguageService
                                                      .getTranslated(context,
                                                          "addlocation_location_name"),
                                                  border: OutlineInputBorder(),
                                                  prefixIcon:
                                                      Icon(Icons.search),
                                                ),
                                              ),
                                            );
                                          },
                                          onSelected: areFieldsDisabled()
                                              ? null
                                              : (suggestion) {
                                                  _isSelectedFromAutocomplete =
                                                      true;
                                                  _handlePlaceSelection(
                                                      suggestion);
                                                },
                                        ),
                                      ),

                                      // Padding(
                                      //   padding: const EdgeInsets.all(8.0),
                                      //   child: TypeAheadField<Suggestion>(
                                      //     hideOnEmpty: true,
                                      //     hideKeyboardOnDrag: false,
                                      //     controller: _locationNameController,
                                      //     suggestionsCallback: (pattern) async {
                                      //       if (pattern.isEmpty) return [];
                                      //       final apiProvider =
                                      //           PlaceApiProvider(sessionToken);
                                      //       return await apiProvider
                                      //           .fetchSuggestions(pattern, 'en');
                                      //     },
                                      //     loadingBuilder: (context) {
                                      //       /*return ListTile(
                                      //         title: Text('Loading...'),
                                      //       );*/
                                      //       return SizedBox(
                                      //         height: 0,
                                      //       );
                                      //     },
                                      //     itemBuilder: (context, suggestion) {
                                      //       if (areFieldsDisabled()) {
                                      //         return Container(); // Return an empty widget but still valid
                                      //       }
                                      //       return ListTile(
                                      //         title: Text(
                                      //           suggestion.description,
                                      //           style: typography.Body1,
                                      //         ),
                                      //       );
                                      //     },
                                      //     builder:
                                      //         (context, controller, focusNode) {
                                      //       return Container(
                                      //         decoration: BoxDecoration(
                                      //           borderRadius:
                                      //               BorderRadius.circular(8),
                                      //           boxShadow: [
                                      //             BoxShadow(
                                      //               color: Colors.black
                                      //                   .withOpacity(0.1),
                                      //               blurRadius: 8,
                                      //               offset: Offset(0, 2),
                                      //             ),
                                      //           ],
                                      //         ),
                                      //         child: TextField(
                                      //           enabled: !areFieldsDisabled(),
                                      //           controller: controller,
                                      //           focusNode: focusNode,
                                      //           onChanged: (value) {
                                      //             if (_isSelectedFromAutocomplete) {
                                      //               _isSelectedFromAutocomplete =
                                      //                   false;
                                      //               return;
                                      //             }
                                      //             if (value.isEmpty) {
                                      //               markers.clear();
                                      //               return;
                                      //             }
                                      //           },
                                      //           decoration: InputDecoration(
                                      //             labelText:
                                      //                 LanguageService.getTranslated(
                                      //                     context,
                                      //                     "addlocation_location_name"),
                                      //             border: OutlineInputBorder(),
                                      //             prefixIcon: Icon(Icons.search),
                                      //           ),
                                      //         ),
                                      //       );
                                      //     },
                                      //     onSelected:
                                      //     areFieldsDisabled()?null:(suggestion) {
                                      //       _handlePlaceSelection(suggestion);
                                      //     },
                                      //   ),
                                      // ),

                                      SizedBox(height: CustomSpacing.four),
                                      // Location Address
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: TextFormField(
                                          enabled: !areFieldsDisabled(),
                                          controller:
                                              _locationAddressController,
                                          decoration: InputDecoration(
                                            labelText:
                                                LanguageService.getTranslated(
                                                    context,
                                                    "addlocation_address1"),
                                            border: OutlineInputBorder(),
                                            hintText:
                                                LanguageService.getTranslated(
                                                    context,
                                                    "addlocation_address1_hint"),
                                          ),
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return LanguageService.getTranslated(
                                                  context,
                                                  "addlocation_address_error");
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                      SizedBox(height: CustomSpacing.three),
                                      // Country just show flag and country name
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(left: 8.0),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: StatefulBuilder(
                                                builder: (BuildContext context,
                                                    StateSetter setState) {
                                                  bool disabled =
                                                      areFieldsDisabled();
                                                  return AbsorbPointer(
                                                    absorbing: disabled,
                                                    // Prevent interactions if disabled
                                                    child: Opacity(
                                                      opacity:
                                                          disabled ? 0.5 : 1.0,
                                                      // Visual indication of disabled state
                                                      child:
                                                          CountryPickerFlagName(
                                                        key: countryPickerKey,
                                                        onCountryChange:
                                                            (country) {
                                                          if (!disabled) {
                                                            setState(() {
                                                              _selectedCountry =
                                                                  country.name;
                                                            });
                                                          }
                                                        },
                                                        initialValue:
                                                            country_picker
                                                                .Country(
                                                          phoneCode: '1',
                                                          countryCode:
                                                              getCountryCodeFromName(
                                                                      _selectedCountry) ??
                                                                  "",
                                                          e164Sc: 1,
                                                          geographic: true,
                                                          level: 1,
                                                          name:
                                                              _selectedCountry,
                                                          example: '',
                                                          displayName: '',
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
                                          ],
                                        ),
                                      ),

                                      SizedBox(height: CustomSpacing.three),
                                      // Location Zip/Postal Code
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: TextFormField(
                                          style: typography.Body1,
                                          enabled: !areFieldsDisabled(),
                                          controller:
                                              _locationZipCodeController,
                                          decoration: InputDecoration(
                                            labelText:
                                                LanguageService.getTranslated(
                                                    context, "addlocation_zip"),
                                            border: OutlineInputBorder(),
                                            hintText:
                                                LanguageService.getTranslated(
                                                    context,
                                                    "addlocation_zip_hint"),
                                          ),
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return LanguageService
                                                  .getTranslated(context,
                                                      "addlocation_zip_error");
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                      SizedBox(height: CustomSpacing.three),
                                      // Optional Details text with divider in row
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Row(
                                          children: [
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Text(
                                                LanguageService.getTranslated(
                                                    context,
                                                    "addlocation_optional_details"),
                                                style: typography.Body1,
                                              ),
                                            ),
                                            Expanded(
                                              child: Divider(
                                                color: themeProvider.getTheme
                                                    .colorScheme.onSurface,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(height: CustomSpacing.three),
                                      // Selecting whether rented or leased
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
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
                                              "Rented",
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
                                              "Leased",
                                              style: typography.Body1,
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(height: CustomSpacing.three),
                                      // Location Type Dropdown
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: DropdownButtonFormField<String>(
                                          decoration: InputDecoration(
                                            labelText:
                                                LanguageService.getTranslated(
                                                    context,
                                                    "addlocation_location_type"),
                                            border: OutlineInputBorder(),
                                          ),
                                          value: _selectedLocationType,
                                          onChanged: areFieldsDisabled()
                                              ? null // Disable dropdown if `areFieldsDisabled` is true
                                              : (String? newValue) {
                                                  setState(() {
                                                    _selectedLocationType =
                                                        newValue;
                                                  });
                                                },
                                          items: <String>[
                                            'Residential',
                                            'Commercial',
                                            'Industrial',
                                          ].map<DropdownMenuItem<String>>(
                                              (String value) {
                                            return DropdownMenuItem<String>(
                                              value: value,
                                              child: Text(value),
                                            );
                                          }).toList(),
                                        ),
                                      ),

                                      SizedBox(height: CustomSpacing.three),
                                      // Location City
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: TextFormField(
                                          enabled: !areFieldsDisabled(),
                                          controller: _locationCityController,
                                          decoration: InputDecoration(
                                            labelText:
                                                LanguageService.getTranslated(
                                                    context,
                                                    "addlocation_city"),
                                            border: OutlineInputBorder(),
                                            hintText:
                                                LanguageService.getTranslated(
                                                    context,
                                                    "addlocation_city_hint"),
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: CustomSpacing.three),
                                      // Location State/Province/Region
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: TextFormField(
                                          enabled: !areFieldsDisabled(),
                                          controller: _locationStateController,
                                          decoration: InputDecoration(
                                            labelText:
                                                LanguageService.getTranslated(
                                                    context,
                                                    "addlocation_state"),
                                            border: OutlineInputBorder(),
                                            hintText:
                                                LanguageService.getTranslated(
                                                    context,
                                                    "addlocation_state_hint"),
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: CustomSpacing.three),
                                      // Description
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: TextFormField(
                                          enabled: !areFieldsDisabled(),
                                          maxLines: 3,
                                          controller:
                                              _locationDescriptionController,
                                          decoration: InputDecoration(
                                            labelText:
                                                LanguageService.getTranslated(
                                                    context,
                                                    "addlocation_description"),
                                            border: OutlineInputBorder(),
                                            hintText: LanguageService.getTranslated(
                                                context,
                                                "addlocation_description_hint"),
                                          ),
                                        ),
                                      ),

                                      SizedBox(height: CustomSpacing.three),
                                      Padding(
                                        padding: EdgeInsets.all(0.0),
                                        child: Row(
                                          children: [
                                            Checkbox(
                                              value: addToSOVCheck,
                                              onChanged: trialStatus.isNotEmpty
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
                                              "Add to SOV",
                                              style: typography.Body1,
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (addToSOVCheck)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // Account Name (Pre-filled and non-editable)
                                              TextField(
                                                controller:
                                                    TextEditingController(
                                                        text:
                                                            widget.accountName),
                                                enabled: false,
                                                decoration: InputDecoration(
                                                  labelText: "Account Name",
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
                                                decoration: InputDecoration(
                                                  labelText: "Sub-account Name",
                                                  border:
                                                      const OutlineInputBorder(),
                                                ),
                                              ),
                                              SizedBox(height: 8.0),
                                              // SoV Autocomplete Dropdown
                                              Consumer<SOVListProvider>(
                                                builder: (context, sovProvider,
                                                    child) {
                                                  return Column(
                                                    children: [
                                                      TextFormField(
                                                        controller:
                                                            sovController,
                                                        onChanged: (value) {
                                                          setState(() {
                                                            // Reset SoV ID when typing
                                                            selectedSovId = "";

                                                            // Filter the autocomplete list based on user input
                                                            sovProvider
                                                                .updateFilteredList(
                                                                    value);
                                                          });
                                                        },
                                                        validator: (value) {
                                                          if (addToSOVCheck) {
                                                            // Apply validation only if addToSOVCheck is true
                                                            if (value == null ||
                                                                value.isEmpty) {
                                                              return LanguageService
                                                                  .getTranslated(
                                                                context,
                                                                "addlocation_address_error",
                                                              );
                                                            }
                                                          }
                                                          return null;
                                                        },
                                                        // validator: (value) {
                                                        //   if (value == null || value.isEmpty) {
                                                        //     return LanguageService.getTranslated(
                                                        //         context,
                                                        //         "addlocation_address_error");
                                                        //   }
                                                        //   return null;
                                                        // },

                                                        decoration:
                                                            InputDecoration(
                                                          labelText:
                                                              "Name of the SoV",
                                                          border:
                                                              const OutlineInputBorder(),
                                                          suffixIcon: Icon(
                                                              Icons.search),
                                                        ),
                                                      ),
                                                      if (sovController
                                                          .text.isNotEmpty)
                                                        AutocompleteOptionsSovs(
                                                          options: sovProvider
                                                              .filteredAutoCompleteList,
                                                          onSelected:
                                                              (SovAccount
                                                                  selection) {
                                                            setState(() {
                                                              selectedSovId =
                                                                  selection
                                                                          .id ??
                                                                      "";
                                                              sovController
                                                                      .text =
                                                                  selection
                                                                          .name ??
                                                                      "";
                                                              sovProvider
                                                                  .clearAutoCompleteList();
                                                            });
                                                          },
                                                          isLoading: sovProvider
                                                              .isAutoCompleteLoading,
                                                        ),
                                                    ],
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      SizedBox(height: CustomSpacing.three),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8.0),
                                        child: Column(
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: CustomButton(
                                                    type: ButtonType.elevated,
                                                    onPressed: () async {
                                                      if (_formKey.currentState!
                                                          .validate()) {
                                                        var body =
                                                            _buildRequestBody(); // Use a helper method for the body
                                                        if (widget.locationId
                                                            .isEmpty) {
                                                          // Add Location
                                                          await _handleAddLocation(
                                                              context, body);
                                                        } else {
                                                          // Update Location
                                                          await _handleUpdateLocation(
                                                              context, body);
                                                        }
                                                      }
                                                    },
                                                    child: _buildButtonChild(
                                                        context),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: CustomSpacing.two),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: CustomButton(
                                                    type: ButtonType.outlined,
                                                    onPressed: () {
                                                      Navigator.pop(context);
                                                    },
                                                    child: Text(
                                                      LanguageService.getTranslated(
                                                          context,
                                                          "addlocation_cancel_button_text"),
                                                      style: typography
                                                          .ButtonLarge.copyWith(
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
                                  ),
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
            ],
          ),
        );
      }),
    );
  }

  Map<String, dynamic> _buildRequestBody() {
    return {
      "data": {
        "account_id": widget.accountId,
        "sub_account_id": widget.subAccountId,
        "sov_id": widget.sovId,
        "by_search": false,
        "location_name": _locationNameController.text,
        "location_type": [_selectedLocationType],
        "description": _locationDescriptionController.text,
        "address": _locationAddressController.text,
        "city": _locationCityController.text,
        "state": _locationStateController.text,
        "zip": _locationZipCodeController.text,
        "country": _selectedCountry,
        "new": addToSOVCheck,
        "rented": rented,
        "leased": leased,
        "latitude": markers.values.first.position.latitude,
        "longitude": markers.values.first.position.longitude,
        "user_id": FirebaseAuth.instance.currentUser!.uid,
        "add_to_sov": addToSOVCheck.toString(),
        "tags": "",
        "name": sovController.text.toString(),
        "account_name": widget.accountName,
        "sub_account_name": widget.subAccountName,
        if (widget.locationId.isNotEmpty) "location_id": widget.locationId,
      }
    };
  }

  Future<void> _handleAddLocation(
      BuildContext context, Map<String, dynamic> body) async {
    final locationListProvider =
        Provider.of<LocationListProvider>(context, listen: false);
    await locationListProvider.addLocation(
      context,
      widget.accountId,
      widget.subAccountId,
      widget.sovId,
      body,
    );
  }

  Future<void> _handleUpdateLocation(
      BuildContext context, Map<String, dynamic> body) async {
    final locationProfileProvider =
        Provider.of<MyLocationListProvider>(context, listen: false);
    var success = await locationProfileProvider.updateLocationDetails(
      context,
      widget.accountId,
      widget.subAccountId,
      widget.sovId,
      widget.locationId,
      body,
    );

    if (success.toLowerCase() == 'true' && mounted) {
      // Navigate and clear stack
      Navigator.pop(context);
      Future.microtask(() {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => LocationProfile(
                  accountId: widget.accountId,
                  subAccountId: widget.subAccountId,
                  sovId: widget.sovId,
                  accountName: widget.accountName,
                  subAccountName: widget.subAccountName,
                  sovName: widget.sovName,
                  locationId: widget.locationId,
                  searchQuery: widget.searchQuery,
                  page: widget.page,
                  totalPages: widget.totalPages,
                ),
              ),
              (route) => false,
            );
          }
        });
      });
    }
  }

  Widget _buildButtonChild(BuildContext context) {
    final locationListProvider = Provider.of<LocationListProvider>(context);
    final locationProfileProvider =
        Provider.of<MyLocationListProvider>(context);

    var typography = CustomTypography(context);
    if (locationListProvider.isAddLocationLoading ||
        locationProfileProvider.isLoading) {
      return Center(
        child: SizedBox(
          height: 25,
          width: 25,
          child: CircularProgressIndicator(
            color: AppColors.black,
          ),
        ),
      );
    } else {
      return Text(
        widget.locationId.isEmpty
            ? LanguageService.getTranslated(
                context, "addlocation_create_button_text")
            : "Update",
        style: typography.ButtonLarge.copyWith(
          color: Colors.black,
        ),
      );
    }
  }

  bool areFieldsDisabled() {
    var provider = Provider.of<UserProfileProvider>(context, listen: false);
    var trialStatus = provider.trialInfo['status'] ?? '';
    var locations = provider.trialInfo['locations'] ?? 0;
    var total = provider.trialInfo['maxLocations'] ?? 0;
    bool isAdd = widget.locationId.isEmpty;
    return trialStatus.isNotEmpty && locations < 1 && isAdd;
  }

  String? getCountryCodeFromName(String countryName) {
    return countryNameToCodeMap[countryName];
  }

  // Add method to handle place selection
  void _handlePlaceSelection(Suggestion suggestion) async {
    final placeApiProvider = PlaceApiProvider(sessionToken);
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

      // Update form fields
      setState(() {
        _locationNameController.text = placeDetails['name'] ?? '';
        _locationAddressController.text =
            placeDetails['formatted_address'] ?? '';
        if (city != null) _locationCityController.text = city;
        if (state != null) _locationStateController.text = state;

        if (postalCode != null) _locationZipCodeController.text = postalCode;
      });
      if (country != null) _updateSelectedCountry(country);

      // Add marker
      final geometry = placeDetails['geometry']['location'];
      final MarkerId markerId = MarkerId("selected_location");
      final marker = Marker(
        markerId: markerId,
        position: LatLng(geometry['lat'], geometry['lng']),
        infoWindow: InfoWindow(
          title: placeDetails['name'],
          snippet: placeDetails['formatted_address'],
        ),
      );

      setState(() {
        markers[markerId] = marker;
      });

      // Move camera to selected location
      final GoogleMapController controller = await _mapController.future;
      controller.animateCamera(CameraUpdate.newLatLng(
        LatLng(geometry['lat'], geometry['lng']),
      ));

      // Set flag to true
      _isSelectedFromAutocomplete = true;
    } catch (e) {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get place details: $e')),
      );
    }
  }

  // Method to handle country update
  void _updateSelectedCountry(String country) {
    setState(() {
      _selectedCountry = country;
      countryPickerKey = UniqueKey(); // Update key to force rebuild
    });
  }
}
