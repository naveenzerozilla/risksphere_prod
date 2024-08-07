import 'package:flutter/material.dart';
import 'package:green/design_system/primitives/utilities/custom_spacing.dart';
import 'package:provider/provider.dart';
import '../../../constants/enums.dart';
import '../../../design_system/components/custom_button.dart';
import '../../../design_system/components/rating_slider.dart';
import '../../../design_system/primitives/custom_typography.dart';
import '../../../providers/location_list_provider.dart';
import 'multi_select_dropdown.dart';

class ListingsFilterScreen extends StatefulWidget {
  final String accountId;
  final String subAccountId;
  final String sovId;
  final String? searchQuery;

  const ListingsFilterScreen(
      {super.key,
      required this.accountId,
      required this.subAccountId,
      required this.sovId,
      required this.searchQuery});

  @override
  _ListingsFilterScreenState createState() => _ListingsFilterScreenState();
}

class _ListingsFilterScreenState extends State<ListingsFilterScreen> {
  // List of titles to be displayed in the filter list.
  // Property Type and Construction Type are excluded.
  List<String> expansionTitles = [
    'Geographical',
    'Ratings',
    // 'Property Type',  // Excluded
    // 'Construction Type',  // Excluded
    //'Certifications',
    //'Hazard',
  ];

  Map<String, List<String>> subValues = {
    'Geographical': ['Select Country', 'Select State'],
    'Ratings': List.generate(5, (index) => 'Rating ${index + 1}'),
    // 'Property Type': ['Commercial', 'Residential', 'Industrial', 'Other'],  // Excluded
    // 'Construction Type': ['Merceise', 'Wood', 'Concrete', 'Steel', 'Others'],  // Excluded
    //'Certifications': ['Manually Certified', 'Auto Certified'],
    //'Hazard': ['Earthquake', 'Hurricane', 'Fire', 'Flood', 'Tornado', 'Others'],
  };

  String searchQuery = "";

  bool showGeographical = true;
  bool showRatings = true;

  // bool showPropertyType = true; // Excluded
  // bool showConstructionType = true; // Excluded
  bool showCertifications = true;
  bool showHazard = true;

  String? selectedCountry;
  String? selectedState;
  String? zipcode;

  List<String> countries = [
    'Afghanistan',
    'Albania',
    'Algeria',
    'Andorra',
    'Angola',
    'Antigua and Barbuda',
    'Argentina',
    'Armenia',
    'Australia',
    'Austria',
    'Azerbaijan',
    'Bahamas',
    'Bahrain',
    'Bangladesh',
    'Barbados',
    'Belarus',
    'Belgium',
    'Belize',
    'Benin',
    'Bhutan',
    'Bolivia',
    'Bosnia and Herzegovina',
    'Botswana',
    'Brazil',
    'Brunei',
    'Bulgaria',
    'Burkina Faso',
    'Burundi',
    'Cabo Verde',
    'Cambodia',
    'Cameroon',
    'Canada',
    'Central African Republic',
    'Chad',
    'Chile',
    'China',
    'Colombia',
    'Comoros',
    'Congo, Democratic Republic of the',
    'Congo, Republic of the',
    'Costa Rica',
    'Croatia',
    'Cuba',
    'Cyprus',
    'Czech Republic',
    'Denmark',
    'Djibouti',
    'Dominica',
    'Dominican Republic',
    'Ecuador',
    'Egypt',
    'El Salvador',
    'Equatorial Guinea',
    'Eritrea',
    'Estonia',
    'Eswatini',
    'Ethiopia',
    'Fiji',
    'Finland',
    'France',
    'Gabon',
    'Gambia',
    'Georgia',
    'Germany',
    'Ghana',
    'Greece',
    'Grenada',
    'Guatemala',
    'Guinea',
    'Guinea-Bissau',
    'Guyana',
    'Haiti',
    'Honduras',
    'Hungary',
    'Iceland',
    'India',
    'Indonesia',
    'Iran',
    'Iraq',
    'Ireland',
    'Israel',
    'Italy',
    'Jamaica',
    'Japan',
    'Jordan',
    'Kazakhstan',
    'Kenya',
    'Kiribati',
    'Korea, North',
    'Korea, South',
    'Kosovo',
    'Kuwait',
    'Kyrgyzstan',
    'Laos',
    'Latvia',
    'Lebanon',
    'Lesotho',
    'Liberia',
    'Libya',
    'Liechtenstein',
    'Lithuania',
    'Luxembourg',
    'Madagascar',
    'Malawi',
    'Malaysia',
    'Maldives',
    'Mali',
    'Malta',
    'Marshall Islands',
    'Mauritania',
    'Mauritius',
    'Mexico',
    'Micronesia',
    'Moldova',
    'Monaco',
    'Mongolia',
    'Montenegro',
    'Morocco',
    'Mozambique',
    'Myanmar',
    'Namibia',
    'Nauru',
    'Nepal',
    'Netherlands',
    'New Zealand',
    'Nicaragua',
    'Niger',
    'Nigeria',
    'North Macedonia',
    'Norway',
    'Oman',
    'Pakistan',
    'Palau',
    'Panama',
    'Papua New Guinea',
    'Paraguay',
    'Peru',
    'Philippines',
    'Poland',
    'Portugal',
    'Qatar',
    'Romania',
    'Russia',
    'Rwanda',
    'Saint Kitts and Nevis',
    'Saint Lucia',
    'Saint Vincent and the Grenadines',
    'Samoa',
    'San Marino',
    'Sao Tome and Principe',
    'Saudi Arabia',
    'Senegal',
    'Serbia',
    'Seychelles',
    'Sierra Leone',
    'Singapore',
    'Slovakia',
    'Slovenia',
    'Solomon Islands',
    'Somalia',
    'South Africa',
    'South Sudan',
    'Spain',
    'Sri Lanka',
    'Sudan',
    'Suriname',
    'Sweden',
    'Switzerland',
    'Syria',
    'Taiwan',
    'Tajikistan',
    'Tanzania',
    'Thailand',
    'Timor-Leste',
    'Togo',
    'Tonga',
    'Trinidad and Tobago',
    'Tunisia',
    'Turkey',
    'Turkmenistan',
    'Tuvalu',
    'Uganda',
    'Ukraine',
    'United Arab Emirates',
    'United Kingdom',
    'United States of America',
    'Uruguay',
    'Uzbekistan',
    'Vanuatu',
    'Vatican City',
    'Venezuela',
    'Vietnam',
    'Yemen',
    'Zambia',
    'Zimbabwe'
  ];

  List<bool> ratings = [false, false, false, false, false];
  List<String> selectedCampusIds = [];
  int selectedRating = 3;

  // Excluded Property Type
  // Map<String, bool> propertyTypes = {
  //   'Commercial': false,
  //   'Residential': false,
  //   'Industrial': false,
  //   'Other': false,
  // };

  // Excluded Construction Type
  // Map<String, bool> constructionTypes = {
  //   'Merceise': false,
  //   'Wood': false,
  //   'Concrete': false,
  //   'Steel': false,
  //   'Others': false,
  // };

  // Map<String, bool> certifications = {
  //   'Manually Certified': false,
  //   'Auto Certified': false,
  // };
  //
  // Map<String, bool> hazards = {
  //   'Earthquake': false,
  //   'Hurricane': false,
  //   'Fire': false,
  //   'Flood': false,
  //   'Tornado': false,
  //   'Others': false,
  // };

  void toggleCategory(String category, bool isSelected) {
    switch (category) {
      case 'Geographical':
        showGeographical = isSelected;
        break;
      case 'Ratings':
        showRatings = isSelected;
        break;
      // case 'Property Type':  // Excluded
      //   showPropertyType = isSelected;
      //   break;
      // case 'Construction Type':  // Excluded
      //   showConstructionType = isSelected;
      //   break;
      //   case 'Certifications':
      //     showCertifications = isSelected;
      //     break;
      //   case 'Hazard':
      //     showHazard = isSelected;
      //     break;
    }
  }

  void updateSearchQuery(String newQuery) {
    setState(() {
      searchQuery = newQuery.toLowerCase();
    });
  }

  void removeFilter(String filterCategory, String filterValue) {
    setState(() {
      switch (filterCategory) {
        case 'Geographical':
          if (filterValue == selectedCountry) selectedCountry = null;
          if (filterValue == selectedState) selectedState = null;
          if (filterValue == zipcode) zipcode = null;
          break;
        case 'Ratings':
          int ratingIndex = int.parse(filterValue.split(' ').last) - 1;
          ratings[ratingIndex] = false;
          break;
        case 'Campus Ids':
          selectedCampusIds.remove(filterValue);
          break;
        // case 'Property Type':  // Excluded
        //   propertyTypes[filterValue] = false;
        //   break;
        // case 'Construction Type':  // Excluded
        //   constructionTypes[filterValue] = false;
        //   break;
        //   case 'Certifications':
        //     certifications[filterValue] = false;
        //     break;
        //   case 'Hazard':
        //     hazards[filterValue] = false;
        //     break;
      }
    });
  }

  void clearAllFilters() {
    setState(() {
      selectedCountry = null;
      selectedState = null;
      ratings = [false, false, false, false, false];
      // propertyTypes.updateAll((key, value) => false);  // Excluded
      // constructionTypes.updateAll((key, value) => false);  // Excluded
      // certifications.updateAll((key, value) => false);
      // hazards.updateAll((key, value) => false);
    });

    // Clear filters in the provider
    final locationListProvider =
        Provider.of<LocationListProvider>(context, listen: false);
    locationListProvider.countries = [];
    locationListProvider.state = '';
    locationListProvider.zipcode = '';
    locationListProvider.propertyType =
        []; // Still need to clear even though it's excluded
    locationListProvider.constructionType =
        []; // Still need to clear even though it's excluded
    locationListProvider.certifications = [];
    locationListProvider.hazard = [];
    locationListProvider.rating = [];
    locationListProvider.selectedCampusIds = [];

    locationListProvider.page = 0; // Reset page to 0

    // Fetch the unfiltered location list
    locationListProvider.fetchLocationList(
      context,
      widget.accountId,
      widget.subAccountId,
      widget.sovId,
      "",
      // No search query
      0,
      // Reset page to 0
      40, // Page size
    );

    Navigator.of(context).pop(); // Close the filter screen
  }

  void applyFilters(BuildContext context) {
    List<String> selectedCountries =
        selectedCountry != null ? [selectedCountry!] : [];
    List<int> selectedRatings = [];
    for (int i = 0; i < ratings.length; i++) {
      if (ratings[i]) selectedRatings.add(i + 1);
    }
    print('Selected ratings: $selectedRatings');
    print('After loop: $ratings');

    // List<String> selectedPropertyTypes = [];  // Excluded
    // propertyTypes.forEach((key, value) {
    //   if (value) selectedPropertyTypes.add(key);
    // });

    // List<String> selectedConstructionTypes = [];  // Excluded
    // constructionTypes.forEach((key, value) {
    //   if (value) selectedConstructionTypes.add(key);
    // });

    // List<String> selectedCertifications = [];
    // certifications.forEach((key, value) {
    //   if (value) selectedCertifications.add(key);
    // });
    //
    // List<String> selectedHazards = [];
    // hazards.forEach((key, value) {
    //   if (value) selectedHazards.add(key);
    // });

    // Update the provider with the selected filters
    Provider.of<LocationListProvider>(context, listen: false).countries =
        selectedCountries;
    Provider.of<LocationListProvider>(context, listen: false).state =
        selectedState ?? "";
    Provider.of<LocationListProvider>(context, listen: false).propertyType =
        []; // Empty as excluded
    Provider.of<LocationListProvider>(context, listen: false).constructionType =
        []; // Empty as excluded
    Provider.of<LocationListProvider>(context, listen: false).certifications =
        []; //selectedCertifications;
    Provider.of<LocationListProvider>(context, listen: false).hazard =
        []; //selectedHazards;
    Provider.of<LocationListProvider>(context, listen: false).rating =
        selectedRatings;

    Provider.of<LocationListProvider>(context, listen: false).zipcode = zipcode ?? "";
    Provider.of<LocationListProvider>(context, listen: false).selectedCampusIds = selectedCampusIds;

    // Reset page and fetch the location list with updated filters
    Provider.of<LocationListProvider>(context, listen: false).page = 0;
    Provider.of<LocationListProvider>(context, listen: false).fetchLocationList(
      context,
      widget.accountId,
      widget.subAccountId,
      widget.sovId,
      widget.searchQuery ?? "",
      0,
      // Reset page to 0
      40, // Page size
    );
    Provider.of<LocationListProvider>(context, listen: false).fetchCertifiedLocationList(
      context,
      widget.accountId,
      widget.subAccountId,
      widget.sovId,
      widget.searchQuery ?? "",
      0,
      // Reset page to 0
      40, // Page size
    );

    Navigator.of(context).pop(); // Close the drawer
  }

  List<Widget> getFilterChips() {
    List<Widget> chips = [];

    // Add a chip only if a country is selected
    if (selectedCountry != null && selectedCountry!.isNotEmpty) {
      chips.add(
        Chip(
          label: Text(selectedCountry!),
          onDeleted: () => removeFilter('Geographical', selectedCountry!),
        ),
      );
    }

    // Add a chip only if a state is entered
    if (selectedState != null && selectedState!.isNotEmpty) {
      chips.add(
        Chip(
          label: Text(selectedState!),
          onDeleted: () => removeFilter('Geographical', selectedState!),
        ),
      );
    }

    // Add a chip only if a zipcode is entered
    if (zipcode != null && zipcode!.isNotEmpty) {
      chips.add(
        Chip(
          label: Text(zipcode!),
          onDeleted: () => removeFilter('Geographical', zipcode!),
        ),
      );
    }

    // Add chips for each selected rating
    for (int i = 0; i < ratings.length; i++) {
      if (ratings[i]) {
        chips.add(
          Chip(
            label: Text('Rating ${i + 1}'),
            onDeleted: () => removeFilter('Ratings', 'Rating ${i + 1}'),
          ),
        );
      }
    }

    // Add chips for each selected campus ID
    selectedCampusIds.forEach((campusId) {
      chips.add(
        Chip(
          label: Text(campusId),
          onDeleted: () => setState(() {
            selectedCampusIds.remove(campusId);
          }),
        ),
      );
    });

    // Excluded Property Type
    // propertyTypes.forEach((key, value) {
    //   if (value) {
    //     chips.add(
    //       Chip(
    //         label: Text(key),
    //         onDeleted: () => removeFilter('Property Type', key),
    //       ),
    //     );
    //   }
    // });

    // Excluded Construction Type
    // constructionTypes.forEach((key, value) {
    //   if (value) {
    //     chips.add(
    //       Chip(
    //         label: Text(key),
    //         onDeleted: () => removeFilter('Construction Type', key),
    //       ),
    //     );
    //   }
    // });

    // Add chips for each selected certification
    /*certifications.forEach((key, value) {
      if (value) {
        chips.add(
          Chip(
            label: Text(key),
            onDeleted: () => removeFilter('Certifications', key),
          ),
        );
      }
    });

    // Add chips for each selected hazard
    hazards.forEach((key, value) {
      if (value) {
        chips.add(
          Chip(
            label: Text(key),
            onDeleted: () => removeFilter('Hazard', key),
          ),
        );
      }
    });*/

    return chips;
  }

  @override
  void initState() {
    final locationListProvider =
        Provider.of<LocationListProvider>(context, listen: false);

    // Initialize filter values from provider
    selectedCountry = locationListProvider.countries.isNotEmpty
        ? locationListProvider.countries.first
        : null;
    selectedState = locationListProvider.state;
    zipcode = locationListProvider.zipcode;
    ratings = List.generate(
        5, (index) => locationListProvider.rating.contains(index + 1));
    print('Campus IDs: ${locationListProvider.campusIds}');
    selectedCampusIds = locationListProvider.selectedCampusIds;
    // Excluded Property Type
    // propertyTypes = Map.fromIterable(locationListProvider.propertyType, key: (e) => e, value: (e) => true);
    // Excluded Construction Type
    // constructionTypes = Map.fromIterable(locationListProvider.constructionType, key: (e) => e, value: (e) => true);
    //certifications = Map.fromIterable(locationListProvider.certifications, key: (e) => e, value: (e) => true);
    //hazards = Map.fromIterable(locationListProvider.hazard, key: (e) => e, value: (e) => true);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    List<String> filteredTitles = expansionTitles.where((title) {
      return title.toLowerCase().contains(searchQuery) ||
          subValues[title]!
              .any((sub) => sub.toLowerCase().contains(searchQuery));
    }).toList();
    final campusIds = Provider.of<LocationListProvider>(context).campusIds;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: CustomSpacing.eight),
        Padding(
          padding: EdgeInsets.only(left: CustomSpacing.four),
          child: Text('Filters', style: CustomTypography.H6),
        ),
        Padding(
          padding: EdgeInsets.all(CustomSpacing.four),
          child: Text('Apply filters to table data',
              style: CustomTypography.Subtitle2),
        ),
        SizedBox(height: CustomSpacing.two),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: CustomSpacing.four),
          child: TextFormField(
            decoration: InputDecoration(
              labelText: 'Search filter categories',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            style: CustomTypography.Body1,
            onChanged: updateSearchQuery,
          ),
        ),
        SizedBox(height: CustomSpacing.two),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: CustomSpacing.four),
          child: Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: getFilterChips(),
          ),
        ),
        SizedBox(height: CustomSpacing.two),
        Expanded(
          child: ListView(
            children: filteredTitles.map((title) {
              switch (title) {
                case 'Geographical':
                  return ExpansionTile(
                    title: Text('Geographical', style: CustomTypography.Body1),
                    children: [
                      Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: CustomSpacing.four),
                            child: MultiSelectDropdown(
                              items: campusIds,
                              selectedItems: selectedCampusIds,
                              onChanged: (newSelection) {
                                setState(() {
                                  selectedCampusIds = newSelection;
                                });
                              },
                            ),
                          ),
                          // Add zipcode input field here
                          Padding(
                            padding: EdgeInsets.only(left: CustomSpacing.four, right: CustomSpacing.four, top: CustomSpacing.two),
                            child: TextFormField(
                              decoration: InputDecoration(
                                counterText: '',
                                labelText: 'Enter Zipcode',
                                hintText: 'Enter Zipcode',
                                hintStyle: CustomTypography.Body1,
                                labelStyle: CustomTypography.Body1,
                                border: const OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(8)),
                                ),
                              ),
                              style: CustomTypography.Body1,
                              maxLength: 10,
                              initialValue: zipcode,
                              // Pre-fill with selected zipcode if available
                              onChanged: (newValue) {
                                setState(() {
                                  zipcode =
                                      newValue; // Update zipcode state as user types
                                });
                              },
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(
                                left: CustomSpacing.four,
                                right: CustomSpacing.four,
                                top: CustomSpacing.two),
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              // Ensures the dropdown expands to fit available space
                              decoration: InputDecoration(
                                labelText: 'Select Country',
                                hintText: 'Select Country',
                                hintStyle: CustomTypography.Body1,
                                labelStyle: CustomTypography.Body1,
                                border: const OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(8)),
                                ),
                              ),
                              style: CustomTypography.Body1,
                              value: selectedCountry,
                              onChanged: (newValue) {
                                setState(() {
                                  selectedCountry = newValue;
                                });
                              },
                              items: countries.map((country) {
                                return DropdownMenuItem(
                                  child: Text(
                                    country,
                                    style: CustomTypography.Body1,
                                    overflow: TextOverflow
                                        .ellipsis, // Handle overflow with ellipsis
                                  ),
                                  value: country,
                                );
                              }).toList(),
                            ),
                          ),

                          SizedBox(height: CustomSpacing.two),
                          /*Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: CustomSpacing.four),
                            child: TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Enter State',
                                hintText: 'Enter State',
                                hintStyle: CustomTypography.Body1,
                                labelStyle: CustomTypography.Body1,
                                border: const OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(8)),
                                ),
                              ),
                              style: CustomTypography.Body1,
                              initialValue: selectedState,
                              // Pre-fill with selected state if available
                              onChanged: (newValue) {
                                setState(() {
                                  selectedState =
                                      newValue; // Update state as user types
                                });
                              },
                            ),
                          ),*/
                          SizedBox(height: CustomSpacing.two),
                        ],
                      ),
                    ],
                  );
                case 'Ratings':
                  return ExpansionTile(
                    title: Text('Ratings', style: CustomTypography.Body1),
                    children: List.generate(5, (index) {
                      return CheckboxListTile(
                        controlAffinity: ListTileControlAffinity.leading,
                        value: ratings[index],
                        onChanged: (bool? value) {
                          setState(() {
                            ratings[index] = value!;
                          });
                        },
                        title: Row(
                          children: [
                            Expanded(
                              child: RatingSlider(
                                width: 200,
                                progress: index + 1,
                                total: 5,
                                progressColor: [
                                  Colors.red[800]!,
                                  Colors.orange[100]!,
                                  Colors.blue[200]!,
                                  Colors.green[200]!,
                                  Colors.yellow[100]!
                                ][index],
                                thumbColor: [
                                  Colors.red[800]!,
                                  Colors.orange[800]!,
                                  Colors.blue[700]!,
                                  Colors.green[800]!,
                                  Colors.yellow[700]!
                                ][index],
                                textColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  );
                // Excluded Property Type
                // case 'Property Type':
                //   return ExpansionTile(
                //     title: Text('Property Type', style: CustomTypography.Body1),
                //     children: propertyTypes.keys.map((type) {
                //       return CheckboxListTile(
                //         controlAffinity: ListTileControlAffinity.leading,
                //         title: Text(type),
                //         value: propertyTypes[type],
                //         onChanged: (bool? value) {
                //           setState(() {
                //             propertyTypes[type] = value!;
                //           });
                //         },
                //       );
                //     }).toList(),
                //   );
                // Excluded Construction Type
                // case 'Construction Type':
                //   return ExpansionTile(
                //     title: Text('Construction Type', style: CustomTypography.Body1),
                //     children: constructionTypes.keys.map((type) {
                //       return CheckboxListTile(
                //         controlAffinity: ListTileControlAffinity.leading,
                //         title: Text(type, style: CustomTypography.Body1),
                //         value: constructionTypes[type],
                //         onChanged: (bool? value) {
                //           setState(() {
                //             constructionTypes[type] = value!;
                //           });
                //         },
                //       );
                //     }).toList(),
                //   );
                //   case 'Certifications':
                //     return ExpansionTile(
                //       title: Text('Certifications', style: CustomTypography.Body1),
                //       children: certifications.keys.map((type) {
                //         return CheckboxListTile(
                //           controlAffinity: ListTileControlAffinity.leading,
                //           title: Text(type, style: CustomTypography.Body1),
                //           value: certifications[type],
                //           onChanged: (bool? value) {
                //             setState(() {
                //               certifications[type] = value!;
                //             });
                //           },
                //         );
                //       }).toList(),
                //     );
                //   case 'Hazard':
                //     return ExpansionTile(
                //       title: Text('Hazard', style: CustomTypography.Body1),
                //       children: hazards.keys.map((type) {
                //         return CheckboxListTile(
                //           controlAffinity: ListTileControlAffinity.leading,
                //           title: Text(type, style: CustomTypography.Body1),
                //           value: hazards[type],
                //           onChanged: (bool? value) {
                //             setState(() {
                //               hazards[type] = value!;
                //             });
                //           },
                //         );
                //       }).toList(),
                //     );
                default:
                  return Container();
              }
            }).toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              CustomButton(
                type: ButtonType.elevated,
                onPressed: () {
                  applyFilters(context);
                },
                child: Text('Apply', style: CustomTypography.ButtonLarge),
              ),
              ElevatedButton(
                onPressed: () {
                  clearAllFilters();
                },
                child: Text('Clear All', style: CustomTypography.ButtonLarge),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
