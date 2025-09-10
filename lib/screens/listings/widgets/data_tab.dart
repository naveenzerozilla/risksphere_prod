import 'dart:collection';
import 'dart:convert';
import 'dart:ui' as BorderType;

// import 'package:RiskSphare/screens/listings/widgets/parameter_listing_filter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

// import 'package:RiskSphare/design_system/repo/color_pallets_screen.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../../constants/enums.dart';
import '../../../design_system/components/custom_button.dart';
import '../../../design_system/primitives/custom_typography.dart';
import '../../../design_system/primitives/utilities/custom_spacing.dart';
import '../../../design_system/primitives/app_colors.dart';
import '../../../models/DataParameterModel.dart';
import '../../../providers/account_list_provider.dart';
import '../../../providers/configuration_provider.dart';
import '../../../providers/data_list_parameters.dart';
import '../../../providers/my_location_list_provider.dart';
import '../../../service/language_service.dart';
import '../../../utils/ImpactDataCard.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

import 'listings_filter_screen.dart';

class DataTab extends StatefulWidget {
  final String? accountName;
  final String? accountId;
  final String? subaccountId;
  final String? locationId;

  const DataTab({
    Key? key,
    this.accountName,
    this.accountId,
    this.subaccountId,
    this.locationId,
  }) : super(key: key);

  @override
  _DataTabState createState() => _DataTabState();
}

class _DataTabState extends State<DataTab> {
  TextEditingController _userSearchController = TextEditingController();
  List<String> selectedServices = [];
  List<int> selectedStars = [];
  List<String> vendorList = [];
  String? expandedElement;

  @override
  void initState() {
    super.initState();
    _getData();
  }

  _getData() async {
    // Fetch data from API
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SubaccountParameterProvider>(context, listen: false)
          .fetchHazardList(context);
      Provider.of<SubaccountParameterProvider>(context, listen: false)
          .fetchSubaccountParameters(context, widget.subaccountId, '', '', '');
    });
  }

  String? selectedHazard;
  String selectedParameter = 'All Parameters';
  String selectedParameterList = 'Select';

  final uniqueResults = <String, Result>{};

  void _showParameterBottomSheet() async {
    setState(() => isFocused = true);

    await showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: Colors.black87,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            'All',
            'Critical Impact Parameters',
            'Medium Impact Parameters',
            'Low Impact Parameters',
            'My Parameters',
          ].map((option) {
            return RadioListTile<String>(
              title: Text(option, style: TextStyle(color: Colors.white)),
              value: option,
              groupValue: selectedParameter,
              activeColor: Colors.blue,
              onChanged: (value) {
                setState(() => selectedParameter = value!);
                Navigator.pop(context);
              },
            );
          }).toList(),
        );
      },
    );

    // Remove the focus effect after bottom sheet closes
    setState(() => isFocused = false);
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool isFocused = false;

  bool showDropdown = false;
  bool showDropdownList = false;
  TextEditingController _controller = TextEditingController();
  TextEditingController _controllerlist = TextEditingController();
  List<String> parameters = [
    'All Parameters',
    'Critical Impact Parameters',
    'Medium Impact Parameters',
    'Low Impact Parameters',
    'My Parameters',
  ];
  List<String> parametersList = [
    'Sub Account',
    'Location',
    'Campus',
    'Sov',
  ];

  // List<String> parameters = ['Earthquake', 'Riverine Flood', 'Wildfire'];
  List<String> filteredParameters = [];

  void _onSearchChanged(String value) {
    setState(() {
      _searchText = value.toLowerCase(); // ensure case-insensitive search
    });
  }

  void _selectParameter(String value) {
    setState(() {
      selectedParameter = value;
      _controller.text = value;
      showDropdown = false;
    });
  }

  final List<String> items = [
    '% Completed',
    'Score',
    'Weightage %',
    'Data Completeness Score',
  ];

  String selectedItem = 'data';
  bool showMissingDataDropdown = false;
  bool showMissingDataDropdown1 = false;
  String? selectedPeril;

  List<String> perils = ["Earthquake", "Riverine Flood", "Wildfire"];
  List<String> filteredPerils = [];

  void submitHazard(String hazardName) async {
    print(" Submitting hazard: $hazardName");
    await Provider.of<SubaccountParameterProvider>(context, listen: false)
        .fetchSubaccountParameters(
            context, widget.subaccountId, hazardName, '', widget.locationId);
  }

  String _searchText = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.transparent,
      body: Consumer<SubaccountParameterProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading == true) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.parameters == null ||
              provider.parameters!.result == null) {
            return const Center(child: Text("No parameters found"));
          }

          // Grouping logic starts here
          Map<String, List<Result>> groupedResults = {};

          for (var result in provider.parameters!.result!) {
            final impactType = result.criticality?.impactType?.toString() ?? '';

            groupedResults.putIfAbsent(impactType, () => []);

            // Avoid duplicate entries (optional check based on a unique property like name)
            if (!groupedResults[impactType]!
                .any((r) => r.name == result.name)) {
              groupedResults[impactType]!.add(result);
            }
          }
          final uniqueResultList = uniqueResults.values.toList();
          return RefreshIndicator(
            onRefresh: () async {
              await Provider.of<SubaccountParameterProvider>(context,
                      listen: false)
                  .fetchSubaccountParameters(
                      context, widget.subaccountId, '', '', '');
            },
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 5),
                  const SizedBox(height: 12),
                  Container(
                    margin: const EdgeInsets.only(right: 12, left: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showDropdownList)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[900],
                              border: Border.all(color: Colors.white24),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  itemCount: parametersList.length,
                                  itemBuilder: (context, index) {
                                    final item = parametersList[index];
                                    final isSelected =
                                        selectedParameterList == item;

                                    return ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: Icon(
                                        isSelected
                                            ? Icons.radio_button_checked
                                            : Icons.radio_button_unchecked,
                                        color: isSelected
                                            ? Colors.lightBlue
                                            : Colors.white,
                                      ),
                                      title: Text(
                                        item,
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.lightBlue
                                              : Colors.white,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                      tileColor: isSelected
                                          ? Colors.blueGrey[800]
                                          : Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      onTap: () {
                                        setState(() {
                                          selectedParameterList = item;
                                          _controllerlist.text = item;
                                          showDropdownList = false;
                                        });
                                        print(item);
                                        print(selectedParameterList);
                                        Provider.of<SubaccountParameterProvider>(
                                                context,
                                                listen: false)
                                            .fetchSubaccountParameters(
                                          context,
                                          widget.subaccountId,
                                          '',
                                          selectedParameterList,
                                          widget.locationId,
                                        );
                                      },
                                    );
                                  },
                                )
                              ],
                            ),
                          ),

                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _controller,
                          readOnly: true,
                          onTap: () {
                            setState(() => showDropdown = !showDropdown);
                          },
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Select parameters',
                            labelStyle: TextStyle(color: Colors.white),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                            filled: true,
                            fillColor: Colors.black,
                            suffixIcon: Icon(Icons.arrow_drop_down,
                                color: Colors.white),
                          ),
                        ),

                        // Dropdown with search and list
                        if (showDropdown)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[900],
                              border: Border.all(color: Colors.white24),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  itemCount: parameters.length,
                                  itemBuilder: (context, index) {
                                    final item = parameters[index];
                                    final isSelected =
                                        selectedParameter == item;

                                    return ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: Icon(
                                        isSelected
                                            ? Icons.radio_button_checked
                                            : Icons.radio_button_unchecked,
                                        color: isSelected
                                            ? Colors.lightBlue
                                            : Colors.white,
                                      ),
                                      title: Text(
                                        item,
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.lightBlue
                                              : Colors.white,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                      tileColor: isSelected
                                          ? Colors.blueGrey[800]
                                          : Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      onTap: () {
                                        setState(() {
                                          selectedParameter = item;
                                          _controller.text = item;
                                          showDropdown = false;
                                        });
                                      },
                                    );
                                  },
                                )
                              ],
                            ),
                          ),

                        const SizedBox(height: 10),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  showMissingDataDropdown =
                                      !showMissingDataDropdown;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 35),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2E3A59),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.white30),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    SizedBox(width: 40),
                                    Text('All Parameters',
                                        style: TextStyle(color: Colors.white)),
                                    SizedBox(width: 20),
                                    Container(
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.red,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                                groupedResults.length
                                                    .toString(),
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ),
                                          Icon(Icons.arrow_drop_down_sharp)
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  showMissingDataDropdown1 =
                                      !showMissingDataDropdown1;
                                });
                              },
                              child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2E3A59),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.white30),
                                  ),
                                  child: const Icon(Icons.filter_alt,
                                      color: Colors.white)),
                            ),
                          ],
                        ),

                        // Dropdown Panel
                        if (showMissingDataDropdown)
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.all(16),
                            width: 320,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: groupedResults.length,
                                    itemBuilder: (context, index) {
                                      final impactType =
                                          groupedResults.keys.elementAt(index);
                                      final resultsForImpactType =
                                          groupedResults[impactType]!;

                                      // Reorder this group's list: move selected item to the top
                                      final reorderedResults =
                                          List.from(resultsForImpactType);
                                      final selectedIndex =
                                          reorderedResults.indexWhere(
                                              (e) => e.name == selectedPeril);
                                      if (selectedIndex != -1) {
                                        final selectedItem = reorderedResults
                                            .removeAt(selectedIndex);
                                        reorderedResults.insert(
                                            0, selectedItem);
                                      }

                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            impactType.toUpperCase(),
                                            style: TextStyle(
                                              color: impactType == "medium"
                                                  ? Colors.purple
                                                  : impactType == "high"
                                                      ? Colors.green
                                                      : Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          ...reorderedResults.map((e) {
                                            final displayName =
                                                e.name ?? "Unnamed";
                                            final isSelected =
                                                displayName == selectedPeril;

                                            return RadioListTile<String>(
                                              value: displayName,
                                              groupValue: selectedPeril,
                                              onChanged: (value) {
                                                if (value != null) {
                                                  setState(() {
                                                    selectedPeril = value;
                                                    showMissingDataDropdown =
                                                        false;
                                                  });
                                                }
                                              },
                                              title: Text(
                                                displayName,
                                                style: TextStyle(
                                                  color: isSelected
                                                      ? Colors.orange
                                                      : Colors.white,
                                                  fontWeight: isSelected
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                                ),
                                              ),
                                              activeColor: Colors.lightBlue,
                                            );
                                          }).toList(),
                                          const SizedBox(height: 8),
                                        ],
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            ),
                          ),
                        if (showMissingDataDropdown1)
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.all(16),
                            width: 400,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextFormField(
                                  onChanged: _onSearchChanged,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    hintText: 'Search parameters',
                                    hintStyle:
                                        const TextStyle(color: Colors.white60),
                                    prefixIcon: const Icon(Icons.search,
                                        color: Colors.white60),
                                    filled: true,
                                    fillColor: Colors.black,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text('Select Peril',
                                    style: TextStyle(color: Colors.white70)),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 200,
                                  child: SingleChildScrollView(
                                    child:
                                        Consumer<SubaccountParameterProvider>(
                                      builder: (context, provider, child) {
                                        final searchQuery =
                                            _searchText.toLowerCase();
                                        final hazards = provider.hazardList
                                            .where((hazard) => hazard.name
                                                .toLowerCase()
                                                .contains(searchQuery))
                                            .toList();

                                        return Column(
                                          children: [
                                            // ✅ "None" option
                                            RadioListTile<String>(
                                              value: '',
                                              groupValue: selectedHazard ?? '',
                                              onChanged: (value) {
                                                setState(() {
                                                  selectedHazard = value;
                                                  showMissingDataDropdown1 =
                                                      false;
                                                });
                                                submitHazard(
                                                    ''); // call with empty
                                              },
                                              title: const Text("None",
                                                  style: TextStyle(
                                                      color: Colors.white)),
                                              activeColor: Colors.lightBlue,
                                            ),

                                            // ✅ Dynamic hazard options
                                            if (hazards.isNotEmpty)
                                              ...hazards.map((hazard) {
                                                return RadioListTile<String>(
                                                  value: hazard.name,
                                                  groupValue: selectedHazard,
                                                  onChanged: (value) {
                                                    setState(() {
                                                      selectedHazard = value;
                                                      showMissingDataDropdown1 =
                                                          false;
                                                    });

                                                    if (value != null) {
                                                      submitHazard(value);
                                                    }
                                                  },
                                                  title: Text(hazard.name,
                                                      style: const TextStyle(
                                                          color: Colors.white)),
                                                  activeColor: Colors.lightBlue,
                                                );
                                              }).toList()
                                            else
                                              const Center(
                                                child: Text(
                                                  "No hazards found",
                                                  style: TextStyle(
                                                      color: Colors.white70),
                                                ),
                                              )
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                      ],
                    ),
                  ),
                  Consumer<MyLocationListProvider>(
                    builder: (context, provider, child) {
                      return Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: _buildSelectedFilterChips(provider),
                      );
                    },
                  ),
                  if (groupedResults.isNotEmpty) ...[
                    SizedBox(height: 10),
                    provider.parameters!.completeness.toString() == "null"
                        ? Container()
                        : Container(
                            width: MediaQuery.of(context).size.width,
                            margin: const EdgeInsets.only(right: 12, left: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  offset: const Offset(0, 4),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Data completeness Score",
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700)),
                                  SizedBox(height: 5),
                                  // DropdownButtonHideUnderline(
                                  //   child: DropdownButton<String>(
                                  //     value: selectedItem == 'data'
                                  //         ? null
                                  //         : selectedItem,
                                  //     hint: Row(
                                  //       children: const [
                                  //         Text(
                                  //           'data',
                                  //           style: TextStyle(
                                  //               color: Colors.blueAccent),
                                  //         ),
                                  //         SizedBox(height: 4),
                                  //         Icon(Icons.arrow_drop_down_outlined,
                                  //             color: Colors.white),
                                  //       ],
                                  //     ),
                                  //     icon: const SizedBox.shrink(),
                                  //     dropdownColor: Colors.black,
                                  //     style:
                                  //         const TextStyle(color: Colors.white),
                                  //     items: items.map((String value) {
                                  //       return DropdownMenuItem<String>(
                                  //         value: value,
                                  //         child: Text(
                                  //           value,
                                  //           style: const TextStyle(
                                  //               color: Colors.blue),
                                  //         ),
                                  //       );
                                  //     }).toList(),
                                  //     onChanged: (String? newValue) {
                                  //       setState(() {
                                  //         selectedItem = newValue!;
                                  //       });
                                  //     },
                                  //     selectedItemBuilder:
                                  //         (BuildContext context) {
                                  //       return items.map((String value) {
                                  //         return Row(
                                  //           children: [
                                  //             Text(
                                  //               value,
                                  //               style: const TextStyle(
                                  //                   fontSize: 14,
                                  //                   fontWeight: FontWeight.bold,
                                  //                   color: Colors.blueAccent),
                                  //             ),
                                  //             const SizedBox(height: 4),
                                  //             const Icon(
                                  //                 Icons
                                  //                     .arrow_drop_down_outlined,
                                  //                 color: Colors.blueAccent),
                                  //           ],
                                  //         );
                                  //       }).toList();
                                  //     },
                                  //   ),
                                  // ),
                                  Consumer<SubaccountParameterProvider>(
                                    builder: (context, provider, child) {
                                      return SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Row(
                                          children: groupedResults.entries
                                              .map((entry) {
                                            final impactType = entry.key;
                                            final resultsForImpactType =
                                                entry.value;

                                            final dataElements =
                                                resultsForImpactType
                                                    .where((e) =>
                                                        e.name != null &&
                                                        e.name!.isNotEmpty &&
                                                        e.parameterType !=
                                                            null &&
                                                        e.user != null)
                                                    .toList();

                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 8.0),
                                              child: DataCompletenessCard(
                                                title: dataElements.isNotEmpty
                                                    ? dataElements[0].name ??
                                                        'Unknown'
                                                    : 'Unknown',
                                                weightage: provider
                                                    .parameters!.completeness!,
                                                parameterType: impactType,
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      );
                                    },
                                  ),
                                ]),
                          ),
                    SizedBox(height: 10),
                    ListView.builder(
                      physics: NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      scrollDirection: Axis.vertical,
                      itemCount: groupedResults.length,
                      itemBuilder: (context, index) {
                        final impactType = groupedResults.keys.elementAt(index);
                        final resultsForImpactType =
                            groupedResults[impactType]!;
                        final dataElements = resultsForImpactType
                            .where((e) =>
                                e.name != null &&
                                e.name!.isNotEmpty &&
                                e.parameterType != null &&
                                e.user != null)
                            .map((e) => ImpactDataElement(
                                  name: e.name!,
                                  user: e.user!,
                                  result: e,
                                  parameterType:
                                      e.parameterType!, // <-- Fix here
                                ))
                            .toList();
                        return Container(
                          padding:
                              EdgeInsets.only(left: 10, right: 10, bottom: 10),
                          child: ImpactDataCard(
                            subAccountId: widget.subaccountId,
                            title: impactType,
                            titleColor: impactType == "high"
                                ? Color(0xFFEF5350)
                                : impactType == "low"
                                    ? const Color(0xFF9C27B0)
                                    : impactType == "medium"
                                        ? const Color(0xFFEF6C00)
                                        : impactType == "general"
                                            ? const Color.fromARGB(
                                                255, 41, 182, 246)
                                            : Colors.white,
                            dataElements: dataElements,
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 20),
                  ] else ...[
                    Container(
                        height: MediaQuery.of(context).size.height / 2,
                        child: Center(child: Text("No Data Available")))
                  ]
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildSelectedFilterChips(MyLocationListProvider provider) {
    final chips = <Widget>[];
    final typography = CustomTypography(context);

    // Add selected country chip
    if (provider.countries.isNotEmpty) {
      chips.add(
        Chip(
          label: Text('Country: ${provider.countries.first}'),
          onDeleted: () {
            // provider.countries = [];
            // provider.fetchLocationList(context, "", 1, 40, widget.accountId,
            //     widget.subAccountId, widget.initialProcessId, widget.initialSubProcessId);
          },
        ),
      );
    }

    // Add zipcode chip
    if (provider.zipcode.isNotEmpty) {
      chips.add(
        Chip(
          label: Text('Zip: ${provider.zipcode}'),
          onDeleted: () {
            // provider.zipcode = '';
            // provider.fetchLocationList(context, "", 1, 40, widget.accountId,
            //     widget.subAccountId, widget.initialProcessId, widget.initialSubProcessId);
          },
        ),
      );
    }

    // Add certification chips
    for (var cert in provider.certifications) {
      chips.add(
        Chip(
          label: Text(cert),
          onDeleted: () {
            // provider.certifications.remove(cert);
            // provider.fetchLocationList(context, "", 1, 40, widget.accountId,
            //     widget.subAccountId, widget.initialProcessId, widget.initialSubProcessId);
          },
        ),
      );
    }

    // Add geo rating chips
    if (provider.rating.isNotEmpty) {
      chips.add(
        Chip(
          label: Text('Ratings: ${provider.rating.join(', ')}'),
          onDeleted: () {
            // provider.rating = [];
            // provider.fetchLocationList(context, "", 1, 40, widget.accountId,
            //     widget.subAccountId, widget.initialProcessId, widget.initialSubProcessId);
          },
        ),
      );
    }

    // Add hazard rating chips
    for (var entry in provider.hazardRatings.entries) {
      if (entry.value.isNotEmpty) {
        chips.add(
          Chip(
            label: Text('${entry.key}: ${entry.value.join(', ')}'),
            onDeleted: () {
              // provider.hazardRatings.remove(entry.key);
              // provider.fetchLocationList(context, "", 1, 40, widget.accountId,
              //     widget.subAccountId, widget.initialProcessId, widget.initialSubProcessId);
            },
          ),
        );
      }
    }

    // Add campus chips
    if (provider.selectedCampusIds.isNotEmpty) {
      chips.add(
        Chip(
          label:
              Text('Campuses: ${provider.selectedCampusIds.length} selected'),
          onDeleted: () {
            // provider.selectedCampusIds = [];
            // provider.fetchLocationList(context, "", 1, 40, widget.accountId,
            //     widget.subAccountId, widget.initialProcessId, widget.initialSubProcessId);
          },
        ),
      );
    }

    return chips;
  }
}

class ImageUploadCard extends StatefulWidget {
  final String subAccountId;
  final String title;
  User user;
  Result result;
  ParameterType? parametertype;
  final Function(List<ImageProvider>) onImagesUpdated;

  ImageUploadCard({
    Key? key,
    required this.subAccountId,
    required this.title,
    required this.user,
    required this.result,
    required this.onImagesUpdated,
    required this.parametertype,
  }) : super(key: key);

  @override
  _ImageUploadCardState createState() => _ImageUploadCardState();
}

class _ImageUploadCardState extends State<ImageUploadCard> {
  List<ImageProvider> uploadedImages = [];
  TextEditingController monthlyRentedController = TextEditingController();
  TextEditingController paramAController = TextEditingController();
  TextEditingController paramBController = TextEditingController();
  TextEditingController unitController = TextEditingController();
  TextEditingController jsonController = TextEditingController();
  TextEditingController valueTypeController = TextEditingController();
  TextEditingController currencyController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  final ImagePicker _picker = ImagePicker();
  List<String> items = ['( 0 - 10)', '( 11 -20 )', '( 21 -100 )'];
  List<Color> itemColors = [Colors.green, Colors.orange, Colors.red];
  List<IconData> itemIcons = [
    Icons.stacked_line_chart_outlined,
    Icons.sports_tennis_outlined,
    Icons.sports_motorsports_rounded
  ];
  String? selectedValue;
  bool isUploading = false;
  var references;
  List<File> selectedImages = [];
  List<String> selectedTags = [];
  Map<File, List<String>> fileTags = {};
  Map<File, TextEditingController> tagControllers = {};

  void addImage(String existingImageUrl) {
    bool isUploading = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Upload",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),

                    // Upload button
                    DottedBorder(
                      // radius: Radius.circular(12),
                      // dashPattern: [6, 3],
                      // color: Colors.grey,
                      child: InkWell(
                        onTap: () async {
                          FilePickerResult? result =
                              await FilePicker.platform.pickFiles(
                            allowMultiple: true,
                            type: FileType.any,
                          );
                          if (result != null) {
                            for (var path in result.paths.whereType<String>()) {
                              final file = File(path);
                              // Add new files to the existing list if not already added
                              if (!selectedImages.contains(file)) {
                                selectedImages.add(file);
                                fileTags[file] = [];
                                tagControllers[file] = TextEditingController();
                              }
                            }
                            setModalState(() {});
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          height: 150,
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cloud_upload,
                                  size: 40, color: Colors.grey),
                              const SizedBox(height: 8),
                              Text("Click to upload or drag and drop"),
                              const SizedBox(height: 4),
                              Text("Select multiple files",
                                  style: TextStyle(color: Colors.blue)),
                              const SizedBox(height: 4),
                              Text("Max file size per file is 200 MB",
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // File previews with tags
                    if (selectedImages.isNotEmpty)
                      Column(
                        children: selectedImages.map((file) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  file.path.toLowerCase().endsWith('.jpg') ||
                                          file.path
                                              .toLowerCase()
                                              .endsWith('.jpeg') ||
                                          file.path
                                              .toLowerCase()
                                              .endsWith('.png') ||
                                          file.path
                                              .toLowerCase()
                                              .endsWith('.gif')
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          child: Image.file(
                                            file,
                                            width: 40,
                                            height: 40,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : Icon(Icons.insert_drive_file,
                                          color: Colors.blue, size: 40),
                                  SizedBox(width: 8),
                                  Expanded(
                                      child: Text(file.path.split('/').last)),
                                  IconButton(
                                    icon: Icon(Icons.clear, color: Colors.red),
                                    onPressed: () {
                                      setModalState(() {
                                        selectedImages.remove(file);
                                        fileTags.remove(file);
                                        tagControllers.remove(file);
                                      });
                                    },
                                  ),
                                ],
                              ),
                              TextFormField(
                                controller: tagControllers[file],
                                onFieldSubmitted: (value) {
                                  final tags = value.trim().split(' ');
                                  setModalState(() {
                                    fileTags[file]!.addAll(tags.where((tag) =>
                                        tag.isNotEmpty &&
                                        !fileTags[file]!.contains(tag)));
                                    tagControllers[file]!.clear();
                                  });
                                },
                                decoration: InputDecoration(
                                  hintText:
                                      "Enter tags for this file (space-separated)",
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              Wrap(
                                spacing: 6,
                                children: fileTags[file]!.map((tag) {
                                  return Chip(
                                    label: Text(tag),
                                    onDeleted: () {
                                      setModalState(() {
                                        fileTags[file]!.remove(tag);
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                              SizedBox(height: 12),
                            ],
                          );
                        }).toList(),
                      ),

                    // Submit button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text("Cancel"),
                        ),
                        ElevatedButton(
                          onPressed: isUploading
                              ? null
                              : () async {
                                  List<String> existingUrls = [];

                                  final refs =
                                      widget.result.parameterValue?.reference;

                                  if (refs != null && refs.isNotEmpty) {
                                    for (var ref in refs) {
                                      if (ref.url != null &&
                                          ref.url!.isNotEmpty) {
                                        existingUrls.addAll(List<String>.from(
                                            ref.url!)); // ✅ fix applied here
                                      }
                                    }
                                  }

                                  if (selectedImages.isEmpty &&
                                      existingUrls.isEmpty) {
                                    Fluttertoast.showToast(
                                      msg:
                                          "Please select file(s) or provide an existing image URL",
                                    );
                                    return;
                                  }

                                  setModalState(() => isUploading = true);

                                  try {
                                    List<String> downloadUrls = [];

                                    // Upload newly selected images
                                    for (File file in selectedImages) {
                                      final fileName =
                                          file.path.split('/').last;
                                      final storageRef =
                                          FirebaseStorage.instance.ref().child(
                                              'uploads/${DateTime.now().millisecondsSinceEpoch}_$fileName');

                                      final uploadTask =
                                          storageRef.putFile(file);
                                      final snapshot = await uploadTask;
                                      final downloadUrl =
                                          await snapshot.ref.getDownloadURL();
                                      downloadUrls.add(downloadUrl);
                                    }

                                    final List<Map<String, dynamic>>
                                        references = [];

                                    // Add existing images
                                    if (existingUrls.isNotEmpty) {
                                      for (var url in existingUrls) {
                                        references.add({
                                          "url": [url],
                                          "tags": [],
                                          "name": "existing_image",
                                        });
                                      }
                                    }

                                    // Add newly uploaded images
                                    for (int i = 0;
                                        i < selectedImages.length;
                                        i++) {
                                      final file = selectedImages[i];
                                      references.add({
                                        "url": [downloadUrls[i]],
                                        "tags": fileTags[file] ?? [],
                                        "name": file.path.split('/').last,
                                      });
                                    }

                                    final updatedFields = {
                                      "value": "",
                                      "param_type": "Files",
                                      "reference": references,
                                    };

                                    final provider = Provider.of<
                                        SubaccountParameterProvider>(
                                      context,
                                      listen: false,
                                    );

                                    await provider.submitParameterUpdate(
                                      context: context,
                                      subaccountId: widget.subAccountId,
                                      parameterId:
                                          widget.result.dataCategoryId!,
                                      updatedFields: updatedFields,
                                    );

                                    if (context.mounted) {
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                        Provider.of<
                                            SubaccountParameterProvider>(
                                          context,
                                          listen: false,
                                        ).fetchSubaccountParameters(context,
                                            widget.subAccountId, '', '', '');
                                      });
                                      Navigator.pop(context);
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text("Upload failed: $e")),
                                      );
                                    }
                                  } finally {
                                    if (context.mounted) {
                                      setModalState(() => isUploading = false);
                                    }
                                  }
                                },

                          // onPressed: isUploading
                          //     ? null
                          //     : () async {
                          //         widget
                          //             .result.parameterValue!.reference!.length;
                          //         String selectedImageUrl = '';
                          //
                          //         if (widget.result.parameterValue!.reference!
                          //                 .length >
                          //             0) {
                          //           selectedImageUrl = widget
                          //               .result
                          //               .parameterValue!
                          //               .reference![0]
                          //               .url[0]; // Get the first URL
                          //         }
                          //
                          //         // Ensure either selected images or an existing image URL is provided
                          //         if (selectedImages.isEmpty &&
                          //             existingImageUrl.isEmpty) {
                          //           Fluttertoast.showToast(
                          //               msg:
                          //                   "Please select file(s) or provide an existing image URL");
                          //           return;
                          //         }
                          //
                          //         setModalState(() => isUploading = true);
                          //
                          //         try {
                          //           List<String> downloadUrls = [];
                          //
                          //           // If there are selected images, upload them and get their download URLs
                          //           for (File file in selectedImages) {
                          //             final fileName =
                          //                 file.path.split('/').last;
                          //             final storageRef =
                          //                 FirebaseStorage.instance.ref().child(
                          //                     'uploads/${DateTime.now().millisecondsSinceEpoch}_$fileName');
                          //
                          //             final uploadTask =
                          //                 storageRef.putFile(file);
                          //             final snapshot = await uploadTask;
                          //             final downloadUrl =
                          //                 await snapshot.ref.getDownloadURL();
                          //             downloadUrls.add(downloadUrl);
                          //           }
                          //
                          //           final List<Map<String, dynamic>>
                          //               references = [];
                          //
                          //           // Add the existing image URL if provided
                          //           if (existingImageUrl.isNotEmpty) {
                          //             references.add({
                          //               "url": [existingImageUrl],
                          //               // Use the existing image URL
                          //               "tags": [],
                          //               // Handle the existing image's tags if needed
                          //               "name": "existing_image",
                          //               // Use a name or leave it as 'existing_image'
                          //             });
                          //           }
                          //
                          //           // Add newly uploaded file URLs to the references list
                          //           for (int i = 0;
                          //               i < selectedImages.length;
                          //               i++) {
                          //             final file = selectedImages[i];
                          //             references.add({
                          //               "url": [downloadUrls[i]],
                          //               // New download URL
                          //               "tags": fileTags[file] ?? [],
                          //               // Tags for the file
                          //               "name": file.path.split('/').last,
                          //               // Name of the uploaded file
                          //             });
                          //           }
                          //
                          //           final updatedFields = {
                          //             "value": "",
                          //             "param_type": "Files",
                          //             "reference": references,
                          //             // This contains both the existing and newly uploaded URLs
                          //           };
                          //
                          //           final provider = Provider.of<
                          //                   SubaccountParameterProvider>(
                          //               context,
                          //               listen: false);
                          //
                          //           await provider.submitParameterUpdate(
                          //             context: context,
                          //             subaccountId: widget.subAccountId,
                          //             parameterId:
                          //                 widget.result.dataCategoryId!,
                          //             updatedFields: updatedFields,
                          //           );
                          //
                          //           if (context.mounted) {
                          //             Navigator.pop(context);
                          //           }
                          //         } catch (e) {
                          //           if (context.mounted) {
                          //             ScaffoldMessenger.of(context)
                          //                 .showSnackBar(SnackBar(
                          //                     content:
                          //                         Text("Upload failed: $e")));
                          //           }
                          //         } finally {
                          //           if (context.mounted) {
                          //             setModalState(() => isUploading = false);
                          //           }
                          //         }
                          //       },
                          child: isUploading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : Text("Submit"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void deleteImage(int index) {
    setState(() {
      uploadedImages.removeAt(index);
      widget.onImagesUpdated(uploadedImages); // Notify parent of changes
    });
  }

  bool selectedBooleanValue = true;

  // final references = widget.result.parameterValue?.reference;
  bool isLoading = false;
  Set<int> expandedCards = {};
  Map<int, int> expandedCardsWithImage = {};
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate;
  final TextEditingController _dateController = TextEditingController();
  int selectedIndex = 0;
  String? selectedImageUrl;
  Map<String, dynamic>? selectedImageData;

  @override
  void initState() {
    super.initState();

    // Safely get the reference list
    references = widget.result.parameterValue?.reference;

    // Check if references list exists and has at least one item with non-empty url
    if (references != null &&
        references!.isNotEmpty &&
        references![0].url != null &&
        references![0].url!.isNotEmpty) {
      final int? timestamp = widget.result.parameterValue!.updatedAt!.iSeconds;
      final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp! * 1000);
      final formattedDate = DateFormat('dd/MM/yyyy HH:mm:ss').format(dateTime);
      selectedImageData = {
        'url': references![0].url![0],
        'uploadedBy': references![0].name ?? "Unknown",
        'dateTime': formattedDate,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    // final urls = widget.result.parameterValue?.reference?.first.url ?? [];
    // final imageUrls = urls.length > 1 ? urls.sublist(1) : [];

    // if (references == null || references.isEmpty) return Container();
    return Container(
      // color: AppColors.primaryMain.withOpacity(0.16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.parametertype!.name!.toLowerCase() == 'boolean') ...[
              Text(widget.title.toString()),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: RadioListTile<bool>(
                      title: Text("Yes"),
                      value: true,
                      groupValue: selectedBooleanValue,
                      onChanged: (value) {
                        setState(() {
                          selectedBooleanValue = value!;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<bool>(
                      title: Text("No"),
                      value: false,
                      groupValue: selectedBooleanValue,
                      onChanged: (value) {
                        setState(() {
                          selectedBooleanValue = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
            ] else ...[
              // For all other parameter types, use a unified approach
              ..._buildParameterFields(),
            ],
            Row(
              children: [
                _buildSubmitButton(),
                SizedBox(width: 8),
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width / 3,
                      child: Text(
                        "Edited by ${widget.user.name}",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text("03/03/2025 11:13:22")
                  ],
                )
              ],
            ),
            SizedBox(height: 16),
            // widget.result.parameterValue?.reference == null

            references == null || references!.isEmpty
                ? Container()
                : Builder(
                    builder: (context) {
                      // 🔒 Safe pre-computation of flattenedImages outside the builder
                      final flattenedImages = references!
                          .asMap()
                          .entries
                          .expand((entry) {
                            final index = entry.key;
                            final urls = entry.value.url ?? [];
                            return List.generate(
                              urls.length,
                              (j) => {
                                'url': urls[j],
                                'refIndex': index,
                                'imgIndex': j,
                              },
                            );
                          })
                          .where((img) =>
                              selectedImageData == null ||
                              selectedImageData!['url'] != img['url'])
                          .toList();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Card(
                            color: Colors.blueGrey[800],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            margin: EdgeInsets.symmetric(vertical: 10),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  Stack(
                                    children: [
                                      selectedImageData != null &&
                                              selectedImageData!['url'] != null
                                          ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: CachedNetworkImage(
                                                imageUrl:
                                                    selectedImageData!['url'],
                                                width: 70,
                                                height: 70,
                                                fit: BoxFit.cover,
                                                placeholder: (context, url) =>
                                                    CircularProgressIndicator(),
                                                errorWidget:
                                                    (context, url, error) =>
                                                        SvgPicture.asset(
                                                  'assets/images/files.svg',
                                                  color: Colors.white54,
                                                  width: 20,
                                                  height: 20,
                                                ),
                                              ),
                                            )
                                          : Container(
                                              width: 90,
                                              height: 90,
                                              decoration: BoxDecoration(
                                                color: Color(0xFF1E1E1E),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Icon(
                                                Icons.insert_drive_file,
                                                size: 48,
                                                color: Colors.grey[400],
                                              ),
                                            ),
                                      if (selectedImageData != null)
                                        Positioned(
                                          top: 4,
                                          right: 4,
                                          child: GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                selectedImageData = null;
                                              });
                                            },
                                            child: Container(
                                              height: 24,
                                              width: 24,
                                              decoration: BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.close,
                                                size: 16,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: selectedImageData != null
                                        ? Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text("Uploaded by",
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold)),
                                              Text(selectedImageData![
                                                  'uploadedBy']),
                                              SizedBox(height: 6),
                                              Text("Date & Time",
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold)),
                                              Text(
                                                  selectedImageData!['dateTime']
                                                      .toString()),
                                            ],
                                          )
                                        : SizedBox.shrink(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: flattenedImages.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 6,
                              mainAxisSpacing: 4,
                              childAspectRatio: 1,
                            ),
                            itemBuilder: (context, i) {
                              final imgData = flattenedImages[i];
                              final refIndex = imgData['refIndex'] as int;
                              final imgIndex = imgData['imgIndex'] as int;
                              final url = imgData['url'] as String;

                              final isImage =
                                  url.toLowerCase().contains(".jpg") ||
                                      url.toLowerCase().contains(".jpeg") ||
                                      url.toLowerCase().contains(".png");

                              return Stack(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      final int? timestamp = widget.result
                                          .parameterValue!.updatedAt!.iSeconds;
                                      final dateTime =
                                          DateTime.fromMillisecondsSinceEpoch(
                                              timestamp! * 1000);
                                      final formattedDate =
                                          DateFormat('dd/MM/yyyy HH:mm:ss')
                                              .format(dateTime);
                                      setState(() {
                                        selectedImageUrl = url;
                                        expandedCardsWithImage[0] = imgIndex;
                                        selectedImageData = {
                                          'url': url,
                                          'uploadedBy':
                                              references![refIndex].name ??
                                                  "Unknown",
                                          'dateTime': formattedDate
                                        };
                                      });
                                    },
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: isImage
                                          ? CachedNetworkImage(
                                              imageUrl: url,
                                              width: 100,
                                              height: 200,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) =>
                                                  CircularProgressIndicator(),
                                              errorWidget:
                                                  (context, url, error) =>
                                                      Icon(Icons.broken_image),
                                            )
                                          : Container(
                                              color: Colors.grey.shade900,
                                              width: double.infinity,
                                              padding: const EdgeInsets.all(8),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  SvgPicture.asset(
                                                    'assets/images/files.svg',
                                                    color: Colors.white54,
                                                    width: 30,
                                                    height: 30,
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    getFileNameFromUrl(url),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(
                                                      color: Colors.white70,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () {
                                        print("Deleter");
                                        setState(() {
                                          references![refIndex]
                                              .url
                                              ?.removeAt(imgIndex);
                                          if (refIndex == 0 &&
                                              expandedCardsWithImage[0] !=
                                                  null &&
                                              imgIndex <
                                                  expandedCardsWithImage[0]!) {
                                            expandedCardsWithImage[0] =
                                                expandedCardsWithImage[0]! - 1;
                                          }
                                        });
                                        WidgetsBinding.instance
                                            .addPostFrameCallback((_) {
                                          Provider.of<SubaccountParameterProvider>(
                                                  context,
                                                  listen: false)
                                              .fetchSubaccountParameters(
                                                  context,
                                                  widget.subAccountId,
                                                  '',
                                                  '',
                                                  '');
                                        });
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white,
                                          boxShadow: [
                                            BoxShadow(
                                                color: Colors.black26,
                                                blurRadius: 2),
                                          ],
                                        ),
                                        padding: EdgeInsets.all(4),
                                        child: Icon(Icons.close,
                                            size: 16, color: Colors.red),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),

            SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                // Check if selectedImageData is not null before accessing its 'url' field
                if (selectedImageData != null &&
                    selectedImageData!['url'] != null) {
                  String existingImageUrl = selectedImageData!['url'] ?? '';

                  if (existingImageUrl.isNotEmpty) {
                    // Call the addImage method and pass the existing image URL
                    addImage(existingImageUrl);
                  } else {
                    // Handle case where the URL is empty
                    addImage(existingImageUrl);
                    print("No image URL to send");
                  }
                } else {
                  // Handle case where selectedImageData is null or URL is not available
                  print("No image data available");
                  addImage(
                      ''); // Send an empty string or appropriate fallback data
                }
              },

              // onTap: addImage,
              child: Container(
                padding: EdgeInsets.all(5),
                width: 100,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(width: 0.8, color: Colors.white38),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, color: Colors.blueAccent, size: 22),
                      SizedBox(width: 6),
                      Text("Upload",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String getFileNameFromUrl(String url) {
    return Uri.decodeFull(url.split('/').last);
  }

  List<Widget> _buildParameterFields() {
    final fields = <Widget>[];
    final parameterType = widget.parametertype!.name!.toLowerCase();

    // Define field configurations
    final fieldConfigs = [
      if (widget.result.parameterNameA.toString().trim().isNotEmpty)
        _FieldConfig(
          label: widget.result.parameterNameA.toString(),
          controller: parameterType == 'date' || parameterType == 'timestamp'
              ? _dateController
              : paramAController,
          keyboardType: _getKeyboardType(parameterType),
          isDateField: parameterType == 'date' || parameterType == 'timestamp',
        ),
      if (widget.result.parameterNameB.toString().trim().isNotEmpty)
        _FieldConfig(
          label: widget.result.parameterNameB.toString(),
          controller: paramBController,
          keyboardType: _getKeyboardType(parameterType),
        ),
      if (widget.result.unitName.toString().trim().isNotEmpty)
        _FieldConfig(
          label: widget.result.unitName.toString(),
          controller: unitController,
          keyboardType: _getKeyboardType(parameterType),
        ),
    ];

    // Build fields with spacing
    for (var config in fieldConfigs) {
      fields.add(_buildTextFormField(config));
      fields.add(const SizedBox(height: 8));
    }

    return fields;
  }

  TextInputType _getKeyboardType(String parameterType) {
    switch (parameterType) {
      case 'number':
        return TextInputType.number;
      case 'date':
      case 'timestamp':
        return TextInputType.datetime;
      case 'json':
        return TextInputType.multiline;
      default:
        return TextInputType.text;
    }
  }

  Widget _buildTextFormField(_FieldConfig config) {
    final parameterType = widget.parametertype!.name!.toLowerCase();
    final isJson = parameterType == 'json';
    jsonController.text =
        isJson ? (widget.result.parameterValue?.value ?? '') : '';

    return TextFormField(
      controller: isJson ? jsonController : config.controller,
      readOnly: config.isDateField,
      keyboardType: config.keyboardType,
      maxLines: isJson ? 5 : 1,
      decoration: InputDecoration(
        labelText: config.label,
        border: OutlineInputBorder(),
      ),
      onTap: config.isDateField
          ? () async {
              final now = DateTime.now();
              final pickedDate = await showDatePicker(
                context: context,
                initialDate: now,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );

              if (pickedDate != null) {
                if (parameterType == 'timestamp') {
                  final pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(now),
                  );

                  if (pickedTime != null) {
                    final fullDateTime = DateTime(
                      pickedDate.year,
                      pickedDate.month,
                      pickedDate.day,
                      pickedTime.hour,
                      pickedTime.minute,
                    );

                    setState(() {
                      _selectedDate = fullDateTime;
                    });

                    config.controller.text =
                        '${fullDateTime.toLocal()}'.split('.').first;
                  }
                } else {
                  setState(() {
                    _selectedDate = pickedDate;
                  });

                  config.controller.text =
                      '${pickedDate.toLocal()}'.split(' ')[0];
                }
              }
            }
          : null,
    );
  }

  Widget _buildSubmitButton() {
    var typography = CustomTypography(context);
    return Row(
      children: [
        CustomButton(
          onPressed: isLoading ? null : _handleSubmit,
          child: isLoading
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: AppColors.black,
                    strokeWidth: 2.5,
                  ),
                )
              : Text(
                  'Submit',
                  style: typography.Body1.copyWith(color: AppColors.black),
                ),
          type: ButtonType.elevated,
        ),
      ],
    );
  }

  Future<void> _handleSubmit() async {
    setState(() => isLoading = true);

    try {
      dynamic value;
      final parameterType = widget.parametertype!.name!.toLowerCase();

      if (parameterType == 'date' || parameterType == 'timestamp') {
        if (_selectedDate == null) {
          _showError('Please select a date');
          return;
        }
        value = _selectedDate!.toIso8601String();
      } else if (parameterType == 'json') {
        final jsonText =
            paramAController.text.trim(); // or whatever controller you're using
        if (jsonText.isEmpty) {
          _showError('Please enter a JSON value');
          return;
        }
        try {
          value = json.decode(jsonText); // 👈 parse JSON
        } catch (e) {
          _showError('Invalid JSON format');
          return;
        }
      } else {
        // For all other types (string, text, unit, etc.)

        // Fetch and trim text
        final paramA = paramAController.text.trim();
        final paramB = paramBController.text.trim();
        final unit = unitController.text.trim();

        // Validate based on field visibility (only if label is not empty)
        if (widget.result.parameterNameA.toString().trim().isNotEmpty &&
            paramA.isEmpty) {
          _showError(
              'Please enter a value for ${widget.result.parameterNameA}');
          return;
        }

        if (widget.result.parameterNameB.toString().trim().isNotEmpty &&
            paramB.isEmpty) {
          _showError(
              'Please enter a value for ${widget.result.parameterNameB}');
          return;
        }

        if (widget.result.unitName.toString().trim().isNotEmpty &&
            unit.isEmpty) {
          _showError('Please enter a value for ${widget.result.unitName}');
          return;
        }

        // Set the value map
        value = {
          'parameterA': paramA.isEmpty ? null : paramA,
          'parameterB': paramB.isEmpty ? null : paramB,
          'unit': unit.isEmpty ? null : unit,
        };
      }

      final updatedFields = {
        "value": value,
        "parameter_type": widget.parametertype!.name,
        "reference": [
          {
            "url": "",
            "tags": [],
          }
        ],
      };
      // setState(() => isLoading = true);
      //
      // try {
      //   dynamic value;
      //   final parameterType = widget.parametertype!.name!.toLowerCase();
      //
      //   if (parameterType == 'number') {
      //     if (monthlyRentedController.text.isEmpty) {
      //       _showError('Please enter a number value');
      //       return;
      //     }
      //     value = double.tryParse(monthlyRentedController.text);
      //     if (value == null) {
      //       _showError('Invalid number');
      //       return;
      //     }
      //   }
      //   else
      //     if (parameterType == 'boolean') {
      //     if (selectedBooleanValue == null) {
      //       _showError('Please select Yes or No');
      //       return;
      //     }
      //     value = selectedBooleanValue;
      //   }
      //   else if (parameterType == 'date' || parameterType == 'timestamp') {
      //     if (_selectedDate == null) {
      //       _showError('Please select a date');
      //       return;
      //     }
      //     value = _selectedDate!.toIso8601String();
      //   }
      //   // Add other type handling as needed
      //
      //   final updatedFields = {
      //     "value": value,
      //     "parameter_type": widget.parametertype!.name,
      //     "reference": [
      //       {
      //         "url": "",
      //         "tags": [],
      //       }
      //     ],
      //   };

      final provider = Provider.of<SubaccountParameterProvider>(
        context,
        listen: false,
      );

      await provider.submitParameterUpdate(
        context: context,
        subaccountId: widget.subAccountId,
        parameterId: widget.result.dataCategoryId!,
        updatedFields: updatedFields,
      );
    } catch (e) {
      _showError('Error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _showError(String message) {
    var typography = CustomTypography(context);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: typography.Body1)),
    );
    setState(() => isLoading = false);
  }

// Helper class for field configuration

  Widget _buildDateTimeField({
    required String label,
    required String hint,
    required VoidCallback onIconPressed,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          readOnly: true,
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: IconButton(
              icon: const Icon(Icons.calendar_today, color: Colors.grey),
              onPressed: onIconPressed,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final format = DateFormat('dd/MM/yyyy hh:mm a');
    return format.format(date);
  }

  Future<void> _selectStartDate(BuildContext context) async {
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (selectedDate != null) {
      TimeOfDay? selectedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (selectedTime != null) {
        DateTime selectedDateTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          selectedTime.hour,
          selectedTime.minute,
        );
        setState(() {
          _startDate = selectedDateTime;
        });
      }
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    if (_startDate == null) return;

    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: _startDate!,
      firstDate: _startDate!,
      lastDate: DateTime(2100),
    );

    if (selectedDate != null) {
      TimeOfDay? selectedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (selectedTime != null) {
        DateTime selectedDateTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          selectedTime.hour,
          selectedTime.minute,
        );
        setState(() {
          _endDate = selectedDateTime;
        });
      }
    }
  }
}

class _FieldConfig {
  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool isDateField;

  _FieldConfig({
    required this.label,
    required this.controller,
    required this.keyboardType,
    this.isDateField = false,
  });
}

class ImpactDataElement {
  final String name;
  final User user;
  final Result result;
  final ParameterType parameterType;

  ImpactDataElement(
      {required this.name,
      required this.user,
      required this.result,
      required this.parameterType});
}

class DataCompletenessCard extends StatelessWidget {
  final String title;
  final Completeness weightage;
  final String parameterType;
  final IconData icon;

  const DataCompletenessCard({
    super.key,
    required this.title,
    required this.weightage,
    required this.parameterType,
    this.icon = Icons.percent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12, left: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.black,
              shape: BoxShape.rectangle,
              borderRadius:
                  BorderRadius.circular(8), // or 0 for a perfect square
            ),
            child: Center(
              child: SvgPicture.asset(
                'assets/images/Layer_1.svg',
                width: 24,
                height: 24,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Completed %',
            style: TextStyle(color: Colors.white60, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            parameterType.toLowerCase() == 'high'
                ? weightage!.high.toString()
                : weightage.low.toString(),
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 2,
            color: Colors.blueGrey,
          ),
          const SizedBox(height: 12),
          Text(
            '${parameterType[0].toUpperCase()}${parameterType.substring(1).toLowerCase()}',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.purpleAccent,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
