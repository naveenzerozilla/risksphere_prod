import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:RiskSphere/screens/listings/widgets/vertical_flat_bar_indicator.dart';
import 'package:provider/provider.dart';
import '../../../constants/enums.dart';
import '../../../design_system/primitives/utilities/custom_spacing.dart';
import '../../../design_system/components/custom_button.dart';
import '../../../design_system/primitives/custom_typography.dart';
import '../../../providers/location_list_provider.dart';
import '../../../providers/my_location_list_provider.dart';
import 'multi_select_dropdown.dart';
import 'vertical_bar_indicator.dart';

class ListingsFilterScreen extends StatefulWidget {
  final String accountId;
  final String subAccountId;
  final String sovId;
  final String? searchQuery;
  final bool showGeoRatings;
  final String? initialProcessId;
  final String? initialSubProcessId;

  const ListingsFilterScreen({
    super.key,
    required this.accountId,
    required this.subAccountId,
    required this.sovId,
    required this.searchQuery,
    this.showGeoRatings = true,
    this.initialProcessId,
    this.initialSubProcessId,
  });

  @override
  _ListingsFilterScreenState createState() => _ListingsFilterScreenState();
}

class _ListingsFilterScreenState extends State<ListingsFilterScreen> {
  bool isLoading = true;

  // Geographical
  String? selectedCountry;
  String? zipcode;
  String? sortBy;

  // Campus
  List<String> selectedCampusIds = [];

  // Certifications
  bool manualCertified = false;
  bool autoCertified = false;

  // Geo Ratings
  List<int> geoRatings = [1, 2, 3, 4, 5]; // Assuming 1 to 5 ratings

  // To store selected geo ratings
  List<int> selectedGeoRatings = [];

  // Hazard Ratings (with multiple selections possible)
  Map<String, List<int>> hazardRatings = {
    'Earthquake': [],
    'Fire': [],
    'Flood': [],
    'Tornado': [],
    'Others': [],
  };
  bool _showSortOptions = false; // Controls visibility of radio options
  String _selectedSortOption = "none";

  final List<Map<String, String>> sortOptions = [
    {"key": "none", "label": "None"},
    {"key": "address_asc", "label": "Addresses (A to Z)"},
    {"key": "address_desc", "label": "Addresses (Z to A)"},
    {"key": "geocode_high_to_low", "label": "Geocoding Rating (High to Low)"},
    {"key": "geocode_low_to_high", "label": "Geocoding Rating (Low to High)"},
    {"key": "hazard_high_to_low", "label": "Hazard Rating (High to Low)"},
    {"key": "hazard_low_to_high", "label": "Hazard Rating (Low to High)"},
  ];

  // Search query
  String searchQuery = '';

  @override
  void initState() {
    // TODO: implement initState
    fetchFilterOptions();
    super.initState();
  }

  // Fetch the initial filter options
  void fetchFilterOptions() async {
    final locationListProvider =
        Provider.of<MyLocationListProvider>(context, listen: false);
    await locationListProvider.fetchInitialFilterOptions(
        widget.accountId, widget.subAccountId);
    setState(() {
      isLoading = false; // Stop showing loader once data is fetched
      // add a list of hazards to hazardRatings (refresh all hazardRatings keys with the provider hazard list)
      print("hazard ratings from api${locationListProvider.hazardList}");
      hazardRatings = Map.fromIterable(locationListProvider.hazardList,
          key: (hazard) => hazard, value: (hazard) => []);
      print("hazard ratings after api${hazardRatings}");
    });
    loadInitialFilters();
  }

  // Update search query
  void updateSearchQuery(String newQuery) {
    setState(() {
      searchQuery = newQuery.toLowerCase();
    });
  }

  // Apply filters
  void applyFilters(BuildContext context) {
    print(sortBy);
    print(sortBy);
    final locationListProvider =
        Provider.of<MyLocationListProvider>(context, listen: false);
    locationListProvider.countries =
        selectedCountry != null ? [selectedCountry!] : [];
    locationListProvider.zipcode = zipcode ?? '';
    locationListProvider.sortBy = sortBy ?? '';

    locationListProvider.certifications = [
      if (manualCertified) 'Manual Certified',
      if (autoCertified) 'Auto Certified'
    ];
    print("certifications are: ${locationListProvider.certifications}");

    // API Format for hazard ratings
    Map<String, List<int>> hazardsForApi = {};
    hazardRatings.forEach((hazard, ratings) {
      if (ratings.isNotEmpty) {
        hazardsForApi[hazard] = ratings;
      }
    });
    print("hazardsForApi: $hazardsForApi");
    locationListProvider.hazardRatings = hazardsForApi;
    // Pass selected geo ratings to the provider or API
    print('location hazard ratings: ${locationListProvider.hazardRatings}');
    locationListProvider.rating = selectedGeoRatings;
    print(hazardsForApi); // Pass this to the API
    locationListProvider.selectedCampusIds = selectedCampusIds;

    if (widget.showGeoRatings) {
      Provider.of<MyLocationListProvider>(context, listen: false)
          .fetchLocationList(
        context,
        "",
        1,
        40,
        widget.accountId,
        widget.subAccountId,
        widget.initialProcessId,
        widget.initialSubProcessId,
      );
    } else {
      Provider.of<MyLocationListProvider>(context, listen: false)
          .fetchCertifiedLocationList(
        context,
        "",
        1,
        40,
        widget.accountId,
        widget.subAccountId,
        widget.initialProcessId,
        widget.initialSubProcessId,
      );
    }

    Navigator.of(context).pop(); // Close the filter screen
  }

  // Load initial filters from the provider
  void loadInitialFilters() {
    final locationListProvider =
        Provider.of<MyLocationListProvider>(context, listen: false);

    setState(() {
      selectedCountry = locationListProvider.countries.isNotEmpty
          ? locationListProvider.countries.first
          : null;
      zipcode = locationListProvider.zipcode;
      sortBy = locationListProvider.sortBy;
      manualCertified =
          locationListProvider.certifications.contains('Manual Certified');
      autoCertified =
          locationListProvider.certifications.contains('Auto Certified');
      selectedGeoRatings = locationListProvider.rating;

      // update hazardRatings with the provider hazard ratings
      hazardRatings.forEach((hazard, ratings) {
        if (locationListProvider.hazardRatings.containsKey(hazard)) {
          hazardRatings[hazard] = locationListProvider.hazardRatings[hazard]!;
        }
      });
    });
  }

  // UI for Geographical, Campus, Certifications, and other filters
  @override
  Widget build(BuildContext context) {
    var typography = CustomTypography(context);
    if (isLoading) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: CircularProgressIndicator(), // Loader
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: CustomSpacing.eight),
        Padding(
          padding: EdgeInsets.only(left: CustomSpacing.four),
          child: Text('Filters', style: typography.H6),
        ),
        Padding(
          padding: EdgeInsets.all(CustomSpacing.four),
          child:
              Text('Apply filters to table data', style: typography.Subtitle2),
        ),
        SizedBox(height: CustomSpacing.two),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: CustomSpacing.four),
          child: TextFormField(
            decoration: InputDecoration(
              labelText: 'Search',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            style: typography.Body1,
            onChanged: updateSearchQuery,
          ),
        ),
        SizedBox(height: CustomSpacing.two),
        Expanded(
          child: Consumer<MyLocationListProvider>(
              builder: (context, locationListProvider, child) {
            return ListView(
              children: [
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: CustomSpacing.four),
                        child: Text(
                          'Sort By',
                          style: typography.Base_Light,
                        ),
                      ),
                      SizedBox(height: 10),
                      Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: CustomSpacing.four),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _showSortOptions =
                                  !_showSortOptions; // Toggle visibility
                              print("object");
                            });
                            print("_" + _showSortOptions.toString());
                            print(_showSortOptions);
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  // Prevents overflow issues in text
                                  child: Text(
                                    sortOptions.firstWhere(
                                      (option) =>
                                          option["key"] == _selectedSortOption,
                                      orElse: () =>
                                          {"label": "Select Sort Option"},
                                    )["label"]!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: typography.Body1,
                                  ),
                                ),
                                Icon(
                                  _showSortOptions
                                      ? Icons.arrow_drop_up
                                      : Icons.arrow_drop_down,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Show Radio Buttons only when _showSortOptions is true
                      if (_showSortOptions)
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: CustomSpacing.four),
                          child: Column(
                            children: sortOptions.map((option) {
                              return RadioListTile<String>(
                                title: Text(
                                  option["label"] ?? "",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                value: option["key"] ?? "",
                                groupValue: _selectedSortOption,
                                onChanged: (String? value) {
                                  setState(() {
                                    _selectedSortOption = value ?? "none";
                                    _showSortOptions =
                                        false; // Hide options after selection
                                    sortBy = _selectedSortOption;
                                  });
                                  print(value);
                                  print(value);
                                  print(value);
                                },
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                ),

                buildGeographicalFilter(
                    context, typography, locationListProvider.countryList),

                // Campus Filter
                buildCampusFilter(context, typography),

                // Certifications Filter
                // buildCertificationsFilter(typography),

                // Geo Ratings Filter with VerticalBarIndicator
                if (widget.showGeoRatings) buildGeoRatingsFilter(typography),

                // Hazard Filter with dropdown and multiple rating checkboxes
                buildHazardFilterWithDropdown(
                    typography, locationListProvider.hazardList),
              ],
            );
          }),
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
                child: Text('Apply', style: typography.ButtonLarge),
              ),
              ElevatedButton(
                onPressed: () {
                  Provider.of<MyLocationListProvider>(context, listen: false)
                      .clearAllFilters();
                  if (widget.showGeoRatings) {
                    Provider.of<MyLocationListProvider>(context, listen: false)
                        .fetchLocationList(
                      context,
                      "",
                      1,
                      40,
                      widget.accountId,
                      widget.subAccountId,
                      widget.initialProcessId,
                      widget.initialSubProcessId,
                    );
                  } else {
                    Provider.of<MyLocationListProvider>(context, listen: false)
                        .fetchCertifiedLocationList(
                      context,
                      "",
                      1,
                      40,
                      widget.accountId,
                      widget.subAccountId,
                      widget.initialProcessId,
                      widget.initialSubProcessId,
                    );
                  }
                },
                child: Text('Clear All', style: typography.ButtonLarge),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Geographical Filter Section
  Widget buildGeographicalFilter(BuildContext context,
      CustomTypography typography, List<String> countryList) {
    return ExpansionTile(
      title: Text('Geographical', style: typography.Body1),
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
              horizontal: CustomSpacing.four, vertical: CustomSpacing.two),
          child: DropdownButtonFormField<String>(
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Choose country',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            value: selectedCountry,
            onChanged: (value) {
              setState(() {
                selectedCountry = value;
              });
            },
            items: countryList
                .map((country) => DropdownMenuItem<String>(
                      value: country,
                      child: Text(country, style: typography.Body1),
                    ))
                .toList(),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(
              horizontal: CustomSpacing.four, vertical: CustomSpacing.two),
          child: TextFormField(
            decoration: InputDecoration(
              labelText: 'Zipcode',
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            maxLength: 15,
            style: typography.Body1,
            onChanged: (value) {
              setState(() {
                zipcode = value;
              });
            },
          ),
        ),
      ],
    );
  }

  // Campus Filter Section
  Widget buildCampusFilter(BuildContext context, CustomTypography typography) {
    final locationListProvider = Provider.of<LocationListProvider>(context);

    // Check if campusIds is empty
    if (locationListProvider.campusIds.isEmpty) {
      return SizedBox
          .shrink(); // Return an empty widget if no campus data is available
    }

    // Prefill selectedCampusIds if not already set
    if (selectedCampusIds.isEmpty) {
      selectedCampusIds = locationListProvider.campusIds;
    }

    return ExpansionTile(
      title: Text('Campus', style: typography.Body1),
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: CustomSpacing.four),
          child: MultiSelectDropdown(
            items: locationListProvider.campusIds,
            selectedItems: selectedCampusIds,
            onChanged: (newSelection) {
              setState(() {
                selectedCampusIds = newSelection;
              });
            },
          ),
        ),
      ],
    );
  }

  // Certifications Filter Section
  Widget buildCertificationsFilter(CustomTypography typography) {
    return ExpansionTile(
      title: Text('Certifications', style: typography.Body1),
      children: [
        CheckboxListTile(
          title: Text('Manual Certified', style: typography.Body1),
          value: manualCertified,
          onChanged: (bool? value) {
            setState(() {
              manualCertified = value!;
            });
          },
        ),
        CheckboxListTile(
          title: Text('Auto Certified', style: typography.Body1),
          value: autoCertified,
          onChanged: (bool? value) {
            setState(() {
              autoCertified = value!;
            });
          },
        ),
      ],
    );
  }

  // Geo Ratings Filter Section with VerticalBarIndicator
  Widget buildGeoRatingsFilter(CustomTypography typography) {
    return ExpansionTile(
      title: Text('Geo Ratings', style: typography.Body1),
      children: geoRatings.map((rating) {
        return CheckboxListTile(
          title: Row(
            children: [
              VerticalFlatBarIndicator(score: rating),
              // Displays the rating bars
              SizedBox(width: 1),
              manualCertified
                  ? SvgPicture.asset('assets/images/certified_five.svg',
                      width: 24, height: 24)
                  : Container(
                      margin: EdgeInsets.only(left: 4),
                      child: CircleAvatar(
                        radius: 10,
                        backgroundColor: Colors.green.withOpacity(0.6),
                        child: Center(
                          child: Text(
                            rating.toString(),
                            style: typography.Body1.copyWith(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
            ],
          ),
          value: selectedGeoRatings.contains(rating),
          onChanged: (bool? value) {
            setState(() {
              if (value == true) {
                selectedGeoRatings.add(rating);
              } else {
                selectedGeoRatings.remove(rating);
              }
            });
          },
        );
      }).toList(),
    );
  }

  // Hazard Filter Section with dropdown and multiple rating checkboxes
  Widget buildHazardFilterWithDropdown(
      CustomTypography typography, List<String> hazardList) {
    print("hazard ratings from api${hazardList}");
    print("hazard ratings after api${hazardRatings}");
    return ExpansionTile(
      title: Text('Hazard', style: typography.Body1),
      children: hazardRatings.keys.map((hazard) {
        return ListTile(
          leading: Checkbox(
            value: hazardRatings[hazard]!.isNotEmpty,
            onChanged: (bool? value) {
              setState(() {
                if (value == true && hazardRatings[hazard]!.isEmpty) {
                  hazardRatings[hazard] = [1]; // Default selection if checked
                } else {
                  hazardRatings[hazard] = [];
                }
              });
            },
          ),
          title: Text(hazard,
              style: typography.Body1,
              overflow: TextOverflow.ellipsis,
              maxLines: 1),
          trailing: PopupMenuButton<List<int>>(
            offset: Offset(-160, 0),
            // Offset to make menu appear on the left
            position: PopupMenuPosition.under,
            constraints: BoxConstraints(maxWidth: 200),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hazardRatings[hazard]!.isEmpty)
                    Text('All', style: typography.Body1)
                  else
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: hazardRatings[hazard]!
                          .map(
                            (rating) => Padding(
                              padding: EdgeInsets.only(right: 4),
                              child: _buildRatingCircle(
                                  rating, _getRatingColor(rating)),
                            ),
                          )
                          .toList(),
                    ),
                  Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
            itemBuilder: (context) => [
              PopupMenuItem<List<int>>(
                value: [],
                child: Text('All', style: typography.Body1),
                onTap: () {
                  setState(() {
                    hazardRatings[hazard] = [];
                  });
                },
              ),
              PopupMenuItem<List<int>>(
                enabled: false, // Prevents the menu from closing on tap
                height: 200, // Adjust based on your needs
                child: StatefulBuilder(
                  builder: (context, setStatePopup) {
                    return Container(
                      width: 150,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(5, (index) {
                          int score = index + 1;
                          return Row(
                            children: [
                              Checkbox(
                                value: hazardRatings[hazard]!.contains(score),
                                onChanged: (bool? value) {
                                  setState(() {
                                    setStatePopup(() {
                                      if (value == true) {
                                        hazardRatings[hazard]!.add(score);
                                      } else {
                                        hazardRatings[hazard]!.remove(score);
                                      }
                                      // If no ratings are selected, revert to "All"
                                      if (hazardRatings[hazard]!.isEmpty) {
                                        hazardRatings[hazard] = [];
                                      }
                                    });
                                  });
                                },
                              ),
                              _buildRatingCircle(score, _getRatingColor(score)),
                            ],
                          );
                        }),
                      ),
                    );
                  },
                ),
                value: null,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

// Helper method to build rating circle
  Widget _buildRatingCircle(int rating, Color color) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          rating.toString(),
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

// Helper method to get rating color
  Color _getRatingColor(int rating) {
    switch (rating) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.lightGreen;
      case 3:
        return Colors.yellow;
      case 4:
        return Colors.orange;
      case 5:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
