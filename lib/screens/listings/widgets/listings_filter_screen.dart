import 'package:flutter/material.dart';
import 'package:green/design_system/primitives/utilities/custom_spacing.dart';
import '../../../constants/enums.dart';
import '../../../design_system/components/custom_button.dart';
import '../../../design_system/components/rating_slider.dart';
import '../../../design_system/primitives/custom_typography.dart';

class ListingsFilterScreen extends StatefulWidget {
  @override
  _ListingsFilterScreenState createState() => _ListingsFilterScreenState();
}

class _ListingsFilterScreenState extends State<ListingsFilterScreen> {
  List<String> selectedTitles = [
    'Geographical',
    'Ratings',
    'Property Type',
    'Construction Type',
    'Certifications',
    'Hazard',
  ];

  List<String> expansionTitles = [
    'Geographical',
    'Ratings',
    'Property Type',
    'Construction Type',
    'Certifications',
    'Hazard',
  ];

  Map<String, List<String>> subValues = {
    'Geographical': ['Select Country', 'Select State'],
    'Ratings': List.generate(5, (index) => 'Rating ${index + 1}'),
    'Property Type': ['Commercial', 'Residential', 'Industrial', 'Other'],
    'Construction Type': ['Merceise', 'Wood', 'Concrete', 'Steel', 'Others'],
    'Certifications': ['Manually Certified', 'Auto Certified'],
    'Hazard': ['Earthquake', 'Hurricane', 'Fire', 'Flood', 'Tornado', 'Others'],
  };

  String searchQuery = "";

  bool showGeographical = true;
  bool showRatings = true;
  bool showPropertyType = true;
  bool showConstructionType = true;
  bool showCertifications = true;
  bool showHazard = true;

  String? selectedCountry;
  String? selectedState;

  List<String> countries = ['USA', 'Canada', 'Mexico'];
  List<String> states = ['California', 'Texas', 'New York'];

  List<bool> ratings = [false, false, false, false, false];
  int selectedRating = 3;

  Map<String, bool> propertyTypes = {
    'Commercial': false,
    'Residential': false,
    'Industrial': false,
    'Other': false,
  };

  Map<String, bool> constructionTypes = {
    'Merceise': false,
    'Wood': false,
    'Concrete': false,
    'Steel': false,
    'Others': false,
  };

  Map<String, bool> certifications = {
    'Manually Certified': false,
    'Auto Certified': false,
  };

  Map<String, bool> hazards = {
    'Earthquake': false,
    'Hurricane': false,
    'Fire': false,
    'Flood': false,
    'Tornado': false,
    'Others': false,
  };

  void toggleCategory(String category, bool isSelected) {
    switch (category) {
      case 'Geographical':
        showGeographical = isSelected;
        break;
      case 'Ratings':
        showRatings = isSelected;
        break;
      case 'Property Type':
        showPropertyType = isSelected;
        break;
      case 'Construction Type':
        showConstructionType = isSelected;
        break;
      case 'Certifications':
        showCertifications = isSelected;
        break;
      case 'Hazard':
        showHazard = isSelected;
        break;
    }
  }

  void updateSearchQuery(String newQuery) {
    setState(() {
      searchQuery = newQuery.toLowerCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    List<String> filteredTitles = expansionTitles.where((title) {
      return title.toLowerCase().contains(searchQuery) ||
          subValues[title]!.any((sub) => sub.toLowerCase().contains(searchQuery));
    }).toList();

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
          child: Text('Apply filters to table data', style: CustomTypography.Subtitle2),
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
                            child: DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                labelText: 'Select Country',
                                hintText: 'Select Country',
                                hintStyle: CustomTypography.Body1,
                                labelStyle: CustomTypography.Body1,
                                border: const OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(8)),
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
                                  child: Text(country, style: CustomTypography.Body1),
                                  value: country,
                                );
                              }).toList(),
                            ),
                          ),
                          SizedBox(height: CustomSpacing.two),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: CustomSpacing.four),
                            child: DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                labelText: 'Select State',
                                hintText: 'Select State',
                                hintStyle: CustomTypography.Body1,
                                labelStyle: CustomTypography.Body1,
                                border: const OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(8)),
                                ),
                              ),
                              style: CustomTypography.Body1,
                              value: selectedState,
                              onChanged: (newValue) {
                                setState(() {
                                  selectedState = newValue;
                                });
                              },
                              items: states.map((state) {
                                return DropdownMenuItem(
                                  child: Text(state, style: CustomTypography.Body1),
                                  value: state,
                                );
                              }).toList(),
                            ),
                          ),
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
                case 'Property Type':
                  return ExpansionTile(
                    title: Text('Property Type', style: CustomTypography.Body1),
                    children: propertyTypes.keys.map((type) {
                      return CheckboxListTile(
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(type),
                        value: propertyTypes[type],
                        onChanged: (bool? value) {
                          setState(() {
                            propertyTypes[type] = value!;
                          });
                        },
                      );
                    }).toList(),
                  );
                case 'Construction Type':
                  return ExpansionTile(
                    title: Text('Construction Type', style: CustomTypography.Body1),
                    children: constructionTypes.keys.map((type) {
                      return CheckboxListTile(
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(type, style: CustomTypography.Body1),
                        value: constructionTypes[type],
                        onChanged: (bool? value) {
                          setState(() {
                            constructionTypes[type] = value!;
                          });
                        },
                      );
                    }).toList(),
                  );
                case 'Certifications':
                  return ExpansionTile(
                    title: Text('Certifications', style: CustomTypography.Body1),
                    children: certifications.keys.map((type) {
                      return CheckboxListTile(
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(type, style: CustomTypography.Body1),
                        value: certifications[type],
                        onChanged: (bool? value) {
                          setState(() {
                            certifications[type] = value!;
                          });
                        },
                      );
                    }).toList(),
                  );
                case 'Hazard':
                  return ExpansionTile(
                    title: Text('Hazard', style: CustomTypography.Body1),
                    children: hazards.keys.map((type) {
                      return CheckboxListTile(
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(type, style: CustomTypography.Body1),
                        value: hazards[type],
                        onChanged: (bool? value) {
                          setState(() {
                            hazards[type] = value!;
                          });
                        },
                      );
                    }).toList(),
                  );
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
                  // Apply filters logic
                },
                child: Text('Apply', style: CustomTypography.ButtonLarge),
              ),
              ElevatedButton(
                onPressed: () {
                  // Clear filters logic
                  setState(() {
                    searchQuery = "";
                    selectedCountry = null;
                    selectedState = null;
                    ratings = [false, false, false, false, false];
                    propertyTypes.updateAll((key, value) => false);
                    constructionTypes.updateAll((key, value) => false);
                    certifications.updateAll((key, value) => false);
                    hazards.updateAll((key, value) => false);
                  });
                },
                child: Text('Cancel', style: CustomTypography.ButtonLarge),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
