import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:green/providers/location_list_provider.dart';
import 'package:green/providers/location_profile_provider.dart';
import 'package:green/screens/listings/location_profile.dart';
import 'package:green/screens/listings/widgets/map_full_screen.dart';
import 'package:provider/provider.dart';

import '../../constants/enums.dart';
import '../../design_system/components/country_picker_flag_name.dart';
import '../../design_system/components/custom_appbar.dart';
import '../../design_system/components/custom_button.dart';
import '../../design_system/components/custom_drawer.dart';
import '../../design_system/primitives/custom_typography.dart';
import '../../design_system/primitives/utilities/custom_spacing.dart';
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

  initState() {
    super.initState();
    if (widget.locationId.isNotEmpty) {
      // get location details
      var provider =
          Provider.of<LocationProfileProvider>(context, listen: false);
      _locationNameController.text = provider.result?.locationName ?? "";
      _locationAddressController.text = provider.result?.address ?? "";
      _selectedCountry = provider.result?.country ?? "";
      _locationZipCodeController.text = provider.result?.zip ?? "";
      //_selectedLocationType = provider.result?.locationType??"";
      _locationCityController.text = provider.result?.city ?? "";
      _locationStateController.text = provider.result?.state ?? "";
      _locationDescriptionController.text = provider.result?.description ?? "";
    }
  }

  @override
  Widget build(BuildContext context1) {
    var typography = CustomTypography(context);
    return Consumer<ThemeProvider>(
        builder: (buildContext, themeProvider, child) {
      return Scaffold(
        key: _scaffoldKey,
        backgroundColor: themeProvider.getTheme.colorScheme.background,
        appBar: CustomAppBar(
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
            Column(
              children: [
                SizedBox(height: CustomSpacing.four),
                Stack(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Image.asset(
                            'assets/images/loginImage.png',
                            fit: BoxFit.fitWidth,
                          ),
                        ),
                      ],
                    ),
                    Positioned.fill(
                      child: Center(
                        child: Row(
                          children: [
                            Expanded(
                              child: Image.asset(
                                'assets/images/addLocationImage.png',
                                scale: 0.5,
                                height: 100,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: CustomSpacing.four),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text(
                            widget.locationId.isEmpty
                                ? LanguageService.getTranslated(
                                    context, "addlocation_app_title")
                                : "Edit Location",
                            style: typography.H5_Regular),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text(
                          widget.locationId.isEmpty
                              ? LanguageService.getTranslated(
                                  context, "addlocation_app_subtitle")
                              : "Please provide the necessary information to update the location details",
                          style: typography.Subtitle1,
                        ),
                      ),
                      SizedBox(
                        height: CustomSpacing.four,
                      ),
                      // Form
                      Expanded(
                        child: SingleChildScrollView(
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Location Name
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: TextFormField(
                                    controller: _locationNameController,
                                    decoration: InputDecoration(
                                      labelText: LanguageService.getTranslated(
                                          context, "addlocation_location_name"),
                                      border: OutlineInputBorder(),
                                      hintText: LanguageService.getTranslated(
                                          context,
                                          "addlocation_location_name_hint"),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return LanguageService.getTranslated(
                                            context,
                                            "addlocation_location_name_error");
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                SizedBox(height: CustomSpacing.four),
                                // Location Address
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: TextFormField(
                                    controller: _locationAddressController,
                                    decoration: InputDecoration(
                                      labelText: LanguageService.getTranslated(
                                          context, "addlocation_address1"),
                                      border: OutlineInputBorder(),
                                      hintText: LanguageService.getTranslated(
                                          context, "addlocation_address1_hint"),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
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
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: CountryPickerFlagName(
                                          onCountryChange: (country) {
                                            setState(() {
                                              _selectedCountry = country.name;
                                            });
                                          },
                                          initialValue: country_picker.Country(
                                            phoneCode: '1',
                                            countryCode: getCountryCodeFromName(
                                                    _selectedCountry) ??
                                                "",
                                            e164Sc: 1,
                                            geographic: true,
                                            level: 1,
                                            name: _selectedCountry,
                                            example: '',
                                            displayName: '',
                                            displayNameNoCountryCode: '',
                                            e164Key: '',
                                          ),
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
                                    controller: _locationZipCodeController,
                                    decoration: InputDecoration(
                                      labelText: LanguageService.getTranslated(
                                          context, "addlocation_zip"),
                                      border: OutlineInputBorder(),
                                      hintText: LanguageService.getTranslated(
                                          context, "addlocation_zip_hint"),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return LanguageService.getTranslated(
                                            context, "addlocation_zip_error");
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
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          LanguageService.getTranslated(context,
                                              "addlocation_optional_details"),
                                          style: typography.Body1,
                                        ),
                                      ),
                                      Expanded(
                                        child: Divider(
                                          color: themeProvider
                                              .getTheme.colorScheme.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Location Type Dropdown
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: DropdownButtonFormField<String>(
                                    decoration: InputDecoration(
                                      labelText: LanguageService.getTranslated(
                                          context, "addlocation_location_type"),
                                      border: OutlineInputBorder(),
                                    ),
                                    value: _selectedLocationType,
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        _selectedLocationType = newValue;
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
                                    controller: _locationCityController,
                                    decoration: InputDecoration(
                                      labelText: LanguageService.getTranslated(
                                          context, "addlocation_city"),
                                      border: OutlineInputBorder(),
                                      hintText: LanguageService.getTranslated(
                                          context, "addlocation_city_hint"),
                                    ),
                                  ),
                                ),
                                SizedBox(height: CustomSpacing.three),
                                // Location State/Province/Region
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: TextFormField(
                                    controller: _locationStateController,
                                    decoration: InputDecoration(
                                      labelText: LanguageService.getTranslated(
                                          context, "addlocation_state"),
                                      border: OutlineInputBorder(),
                                      hintText: LanguageService.getTranslated(
                                          context, "addlocation_state_hint"),
                                    ),
                                  ),
                                ),
                                SizedBox(height: CustomSpacing.three),
                                // Description
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: TextFormField(
                                    maxLines: 3,
                                    controller: _locationDescriptionController,
                                    decoration: InputDecoration(
                                      labelText: LanguageService.getTranslated(
                                          context, "addlocation_description"),
                                      border: OutlineInputBorder(),
                                      hintText: LanguageService.getTranslated(
                                          context,
                                          "addlocation_description_hint"),
                                    ),
                                  ),
                                ),
                                // Save Button
                                Consumer<LocationProfileProvider>(builder:
                                    (context, locationProfileProvider, child) {
                                  return Consumer<LocationListProvider>(builder:
                                      (context, locationListProvider, child) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8.0),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: CustomButton(
                                              type: ButtonType.elevated,
                                              onPressed: () async {
                                                if (widget.locationId.isEmpty) {
                                                  // add location api
                                                  // Required fields are location name, address, zip, country others are optional

                                                  if (_formKey.currentState!
                                                      .validate()) {
                                                    var body = {
                                                      "data": {
                                                        "location_name":
                                                            _locationNameController
                                                                .text,
                                                        "location_type":
                                                            _selectedLocationType,
                                                        "description":
                                                            _locationDescriptionController
                                                                .text,
                                                        "address":
                                                            _locationAddressController
                                                                .text,
                                                        "city":
                                                            _locationCityController
                                                                .text,
                                                        "state":
                                                            _locationStateController
                                                                .text,
                                                        "zip":
                                                            _locationZipCodeController
                                                                .text,
                                                        "country":
                                                            _selectedCountry
                                                      }
                                                    };
                                                    locationListProvider
                                                        .addLocation(
                                                            context,
                                                            widget.accountId,
                                                            widget.subAccountId,
                                                            widget.sovId,
                                                            body);
                                                  }
                                                } else {
                                                  // update location api
                                                  // Required fields are location name, address, zip, country others are optional

                                                  if (_formKey.currentState!
                                                      .validate()) {
                                                    var body = {
                                                      "data": {
                                                        "location_name":
                                                            _locationNameController
                                                                .text,
                                                        "location_type":
                                                            _selectedLocationType,
                                                        "description":
                                                            _locationDescriptionController
                                                                .text,
                                                        "address":
                                                            _locationAddressController
                                                                .text,
                                                        "city":
                                                            _locationCityController
                                                                .text,
                                                        "state":
                                                            _locationStateController
                                                                .text,
                                                        "zip":
                                                            _locationZipCodeController
                                                                .text,
                                                        "country":
                                                            _selectedCountry,
                                                        "location_id":
                                                            widget.locationId
                                                      }
                                                    };

                                                    var success =
                                                        await locationProfileProvider
                                                            .updateLocationDetails(
                                                                context,
                                                                widget
                                                                    .accountId,
                                                                widget
                                                                    .subAccountId,
                                                                widget.sovId,
                                                                widget
                                                                    .locationId,
                                                                body);
                                                    if (success.toLowerCase()=='true') {
                                                      Navigator.pushReplacement(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (_) =>
                                                              LocationProfile(
                                                            accountId: widget
                                                                .accountId,
                                                            accountName: widget
                                                                .accountName,
                                                            subAccountId: widget
                                                                .subAccountId,
                                                            subAccountName: widget
                                                                .subAccountName,
                                                            sovId: widget.sovId,
                                                            sovName:
                                                                widget.sovName,
                                                            searchQuery: widget
                                                                .searchQuery,
                                                            page: widget.page,
                                                            totalPages: widget
                                                                .totalPages,
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                  }
                                                }
                                              },
                                              child: locationListProvider
                                                          .isAddLocationLoading ||
                                                      locationProfileProvider
                                                          .isLoading
                                                  ? Center(
                                                      child: SizedBox(
                                                          height: 25,
                                                          width: 25,
                                                          child:
                                                              CircularProgressIndicator()))
                                                  : Text(
                                                      widget.locationId.isEmpty
                                                          ? LanguageService
                                                              .getTranslated(
                                                                  context,
                                                                  "addlocation_create_button_text")
                                                          : "Update",
                                                      style: typography
                                                          .ButtonLarge),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  });
                                }),
                                SizedBox(height: CustomSpacing.three),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0),
                                  child: Row(
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
                                              style:
                                                  typography.ButtonLarge),
                                        ),
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
              ],
            ),
          ],
        ),
      );
    });
  }

  String? getCountryCodeFromName(String countryName) {
    return countryNameToCodeMap[countryName];
  }
}
