import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
  const AddLocationScreen({super.key});

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
  TextEditingController _locationAddress1Controller = TextEditingController();
  TextEditingController _locationAddress2Controller = TextEditingController();
  TextEditingController _locationCityController = TextEditingController();
  TextEditingController _locationStateController = TextEditingController();
  TextEditingController _locationZipCodeController = TextEditingController();
  String _selectedCountry = "United States";
  TextEditingController _formattedAddressController = TextEditingController();

  @override
  Widget build(BuildContext context1) {
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text(
                            LanguageService.getTranslated(
                                context, "addlocation_app_title"),
                            style: CustomTypography.H5_Regular),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text(
                          LanguageService.getTranslated(
                              context, "addlocation_app_subtitle"),
                          style: CustomTypography.Subtitle1,
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
                                            context, "addlocation_location_name_hint"),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: CustomSpacing.four),
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
                                        'Office',
                                        'Warehouse',
                                        'Retail',
                                        'Other'
                                      ].map<DropdownMenuItem<String>>((String value) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(value),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                  SizedBox(height: CustomSpacing.three),
                                  // Location Address 1
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: TextFormField(
                                      controller: _locationAddress1Controller,
                                      decoration: InputDecoration(
                                        labelText: LanguageService.getTranslated(
                                            context, "addlocation_address1"),
                                        border: OutlineInputBorder(),
                                        hintText: LanguageService.getTranslated(
                                            context, "addlocation_address1_hint"),

                                      ),
                                    ),
                                  ),
                                  SizedBox(height: CustomSpacing.three),
                                  // Location Address 2
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: TextFormField(
                                      controller: _locationAddress2Controller,
                                      decoration: InputDecoration(
                                        labelText: LanguageService.getTranslated(
                                            context, "addlocation_address2"),
                                        border: OutlineInputBorder(),
                                        hintText: LanguageService.getTranslated(
                                            context, "addlocation_address2_hint"),
                                      ),
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
                                  // Country just show flag and country name
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: CountryPickerFlagName(onCountryChange: (country) {
                                            setState(() {
                                              _selectedCountry = country.name;
                                            });
                                          }, initialValue: country_picker.Country(phoneCode: '1', countryCode: getCountryCodeFromName(_selectedCountry)??"", e164Sc: 1, geographic: true, level: 1, name: _selectedCountry, example: '', displayName: '', displayNameNoCountryCode: '', e164Key: '', ),),
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
                                    ),
                                  ),
                                  SizedBox(height: CustomSpacing.three),
                                  // Formatted Address
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: TextFormField(
                                      controller: _formattedAddressController,
                                      decoration: InputDecoration(
                                        labelText: LanguageService.getTranslated(
                                            context, "addlocation_formatted_address"),
                                        border: OutlineInputBorder(),
                                        hintText: LanguageService.getTranslated(
                                            context, "addlocation_formatted_address_hint"),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: CustomSpacing.three),
                                  // Google map preview container
                                  ClipRRect(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                      child: Container(
                                        height: 300,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: themeProvider.getTheme.colorScheme.onSurface,
                                          ),
                                          borderRadius: BorderRadius.circular(8.0),
                                        ),
                                        child: GoogleMap(
                                          initialCameraPosition: CameraPosition(
                                            target: LatLng(37.7749, -122.4194),
                                            zoom: 14.4746,
                                          ),
                                          markers: {
                                            Marker(
                                              markerId: MarkerId('1'),
                                              position: LatLng(37.7749, -122.4194),
                                            ),
                                          },
                                        ),
                                      ),
                                    ),
                                  ),

                                  SizedBox(height: CustomSpacing.four),
                                  // Save Button
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: CustomButton(
                                            type: ButtonType.elevated,
                                            onPressed: () {
                                              // Apply filters logic
                                            },
                                            child: Text('Create', style: CustomTypography.ButtonLarge),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: CustomSpacing.three),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: CustomButton(
                                            type: ButtonType.outlined,
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                            child: Text('Cancel', style: CustomTypography.ButtonLarge),
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
