import 'dart:collection';
import 'dart:convert';
import 'dart:ui' as BorderType;
import 'package:RiskSphere/models/view_employee_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../../constants/enums.dart';
import '../../../design_system/components/custom_appbar.dart';
import '../../../design_system/components/custom_button.dart';
import '../../../design_system/components/custom_drawer.dart';
import '../../../design_system/primitives/custom_typography.dart';
import '../../../design_system/primitives/app_colors.dart';
import '../../../models/DataParameterModel.dart';
import '../../../providers/data_list_parameters.dart';
import '../../../providers/job_monitoring_provier.dart';
import '../../../providers/my_location_list_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../service/language_service.dart';
import '../../../utils/ImpactDataCard.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart' hide Reference;

import '../processing_summary.dart';

class DataTab extends StatefulWidget {
  final String? accountName;
  final String? accountId;
  final String? subaccountId;
  final String? locationId;
  final String? sovId;
  final String? campusId;
  final bool? campusStatus;
  final String? status;
  final bool showAppBar;
  final String? sovName;

  const DataTab({
    Key? key,
    this.accountName,
    this.accountId,
    this.subaccountId,
    this.locationId,
    this.sovId,
    this.campusId,
    this.campusStatus,
    this.status,
    this.showAppBar = false,
    this.sovName,
  }) : super(key: key);

  @override
  _DataTabState createState() => _DataTabState();
}

class _DataTabState extends State<DataTab> {
  String? selectedParameterList = 'Location';
  TextEditingController _userSearchController = TextEditingController();
  List<String> selectedServices = [];
  List<int> selectedStars = [];
  bool isLoading = false;
  List<String> vendorList = [];
  String? expandedElement;
  bool isDropdownOpen = false;
  Map<String, TextEditingController> jsonControllers = {};
  TimeOfDay? selectedTime;
  bool showDropdown = false;
  String? selectedParameter;
  final GlobalKey itemKey = GlobalKey();
  Map<String, GlobalKey> itemKeys = {};
  List<dynamic> subList = [];
  String? expandedImpactType; // high / medium / low
  String? expandedParameterName; // e.g., "Year Built"
  bool _isExpanded = false;
  bool _showNotificationDot = true;
  Map<String, bool> expandedMap = {};

  void toggleExpand(String key) {
    setState(() {
      expandedMap[key] = !(expandedMap[key] ?? false);
    });
  }

  final Map<String, bool> impactExpandedMap = {};

  @override
  void initState() {
    super.initState();
    _getData();
    selectedParameterList = widget.status.toString() == "subaccount"
        ? "Sub Account"
        : widget.status.toString() == "sov"
            ? "sov"
            : 'Location';
  }

  File? selectedImageFile; // <--- ADD THIS
  String? uploadedImageUrl;
  String selectedFilterImpact = "all"; // all, low, medium, high

  _getData() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider =
          Provider.of<SubaccountParameterProvider>(context, listen: false);

      provider.fetchHazardList(context);

      provider.fetchSubaccountParameters(
        context,
        widget.subaccountId,
        '',
        selectedParameterList,
        widget.locationId,
        widget.campusId,
        selectedParameterList,
        selectedParameterList,
        // ✔ (your API signature uses this twice)
        widget.sovId, // ✔ Correct sovId
      );
    });
  }

  Future<void> _getRefreshData() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SubaccountParameterProvider>(
        context,
        listen: false,
      ).fetchSubaccountParameters(
          context,
          widget.subaccountId,
          '',
          selectedParameterList,
          widget.locationId,
          widget.campusId,
          selectedParameterList,
          selectedParameterList,
          widget.sovId);
      print(selectedParameterList);
    });
  }

  String? selectedHazard;

  final uniqueResults = <String, Result>{};

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool isFocused = false;

  // bool showDropdown = false;
  bool showDropdownList = false;
  TextEditingController _controller = TextEditingController();
  TextEditingController _controllerlist = TextEditingController();
  String selectedImpactFilter = "all"; // all | low | medium | high
  String? selectedDropdownLabel;

  List<Result> currentSublist = [];

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
            context,
            widget.subaccountId,
            hazardName,
            '',
            widget.locationId,
            '',
            selectedParameterList,
            widget.sovId,
            widget.campusId);
  }

  String _searchText = '';

  @override
  Widget build(BuildContext context) {
    return SafeArea(child:
        Consumer<ThemeProvider>(builder: (context, themeProvider, child) {
      return Consumer<MyLocationListProvider>(
          builder: (context, locationProfileProvider, child) {
        return Scaffold(
          backgroundColor: themeProvider.getTheme.colorScheme.background,
          appBar: widget.showAppBar
              ? CustomAppBar(
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
                )
              : null,
          drawer: widget.showAppBar ? CustomDrawer() : null,
          key: _scaffoldKey,
          body: Consumer<SubaccountParameterProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading == true) {
                return const Center(child: CircularProgressIndicator());
              }

              Map<String, List<Result>> groupedResults = {
                "high": [],
                "medium": [],
                "low": [],
              };

              // Process results and group them
              for (final result
                  in (provider.parameters?.result ?? const <Result>[])) {
                String bucket = "low"; // 👉 Default to LOW always

                // If criticality exists and has entries
                if (result.criticality != null &&
                    result.criticality!.isNotEmpty) {
                  final impact = result.criticality!.first.impactType
                          ?.toLowerCase()
                          .trim() ??
                      "";

                  if (impact == "high") {
                    bucket = "high";
                  } else if (impact == "medium") {
                    bucket = "medium";
                  } else if (impact == "low") {
                    bucket = "low";
                  } else {
                    bucket = "low"; // 👉 Unknown impact → LOW
                  }
                }

                // Always add item to the appropriate bucket
                groupedResults[bucket]!.add(result);
              }

              // Build displayGroups based on selectedImpactFilter
              final Map<String, List<Result>> displayGroups =
                  selectedImpactFilter == "all"
                      ? groupedResults
                      : {
                          selectedImpactFilter:
                              groupedResults[selectedImpactFilter] ?? []
                        };

              final visibleEntries = displayGroups.entries
                  .where((e) => e.value.isNotEmpty)
                  .toList();

              // Extract the impact cards building logic
              List<Widget> buildImpactCards() {
                if (visibleEntries.isEmpty) return [SizedBox.shrink()];

                return visibleEntries.map((entry) {
                  final impactType = entry.key;
                  final resultsForImpactType = entry.value;

                  // Selected sub-item for this impact group
                  final selectedName = selectedSubItem[impactType];

                  // REORDER LIST so selected item comes FIRST
                  List<Result> reorderedList = List.from(resultsForImpactType);

                  if (selectedName != null) {
                    final selectedElement = reorderedList.firstWhere(
                      (e) => e.name == selectedName,
                      orElse: () => reorderedList.isNotEmpty
                          ? reorderedList.first
                          : throw StateError('No element found'),
                    );

                    // Move selected element to front if it exists
                    if (reorderedList.contains(selectedElement)) {
                      reorderedList.remove(selectedElement);
                      reorderedList.insert(0, selectedElement);
                    }
                  }

                  // Convert to ImpactDataElements
                  final dataElements = reorderedList
                      .where((e) =>
                          e.name != null &&
                          e.parameterType != null &&
                          e.user != null)
                      .map((e) => ImpactDataElement(
                            name: e.name!,
                            user: e.user!,
                            result: e,
                            parameterType: e.parameterType!,
                            parameterValue: e.parameterValue!,
                          ))
                      .toList();

                  if (dataElements.isEmpty) return SizedBox.shrink();

                  String cardKey = "card_${impactType}";
                  itemKeys.putIfAbsent(cardKey, () => GlobalKey());
                  return Container(
                    key: itemKeys[cardKey],
                    padding: EdgeInsets.only(left: 10, right: 10, bottom: 10),
                    child: ImpactDataCard(
                      accountId: widget.accountId,
                      subAccountId: widget.subaccountId,
                      locationId: widget.locationId,
                      sovId: widget.sovId,
                      campusId: widget.campusId,
                      title: impactType,
                      titleColor: impactType == "high"
                          ? Color(0xFFF44336)
                          : impactType == "medium"
                              ? Color(0xFFFFA726)
                              : Color(0xFFCE93D8),
                      dataElements: dataElements,
                      selectedParameterList: selectedParameterList!,
                      onRefresh: () => _getRefreshData(),
                      expandElementName: selectedDropdownLabel,
                      onExpanded: () {
                        final ctx = itemKeys[cardKey]!.currentContext;
                        if (ctx != null) {
                          Scrollable.ensureVisible(
                            ctx,
                            duration: Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                            alignment: 0.1,
                          );
                        }
                      },
                    ),
                  );
                }).toList();
              }

              return RefreshIndicator(
                onRefresh: () async {
                  await Provider.of<SubaccountParameterProvider>(context,
                          listen: false)
                      .fetchSubaccountParameters(
                          context,
                          widget.subaccountId,
                          '',
                          selectedParameterList,
                          widget.locationId,
                          widget.campusId,
                          selectedParameterList,
                          selectedParameterList,
                          widget.sovId);
                },
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 110),
                  children: [
                    widget.showAppBar
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  child: Text(
                                    widget.sovName.toString(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                              ),
                              Consumer<MyLocationListProvider>(
                                builder: (context, myLocationListProvider, _) {
                                  if (myLocationListProvider
                                      .myLocationList.isEmpty) {
                                    return const SizedBox.shrink();
                                  }

                                  return IconButton(
                                    onPressed: isLoading
                                        ? null
                                        : () async {
                                            if (!mounted) return;

                                            setState(() => isLoading = true);

                                            final jobProvider = context
                                                .read<JobMonitoringProvider>();

                                            try {
                                              final summaryData =
                                                  await jobProvider
                                                      .fetchLocationSummary(
                                                widget.accountId!,
                                                widget.subaccountId!,
                                                widget.sovId!,
                                              );

                                              if (!mounted) return;

                                              if (summaryData != null) {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        ProcessSummaryPage(
                                                      summaryData: summaryData,
                                                      sovId: widget.sovId,
                                                    ),
                                                  ),
                                                );
                                              } else {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Failed to fetch summary',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodyMedium
                                                          ?.copyWith(
                                                              color:
                                                                  Colors.white),
                                                    ),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }
                                            } catch (e) {
                                              if (mounted) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Error: $e',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodyMedium
                                                          ?.copyWith(
                                                              color:
                                                                  Colors.white),
                                                    ),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }
                                            } finally {
                                              if (mounted) {
                                                setState(
                                                    () => isLoading = false);
                                              }
                                            }
                                          },
                                    icon: isLoading
                                        ? const SizedBox(
                                            height: 24,
                                            width: 24,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2),
                                          )
                                        : SvgPicture.asset(
                                            'assets/images/contract.svg',
                                            height: 22,
                                            width: 22,
                                          ),
                                  );
                                },
                              ),
                              InkWell(
                                onTap: () {
                                  Navigator.pop(context);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: AppColors.primaryMain,
                                      // outline color
                                      width: 1,
                                    ),
                                  ),
                                  child: const Text(
                                    "Location List",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.primaryMain,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Container(),
                    SizedBox(height: 5),
                    const SizedBox(height: 12),
                    Container(
                      margin: const EdgeInsets.only(
                          right: 12, left: 12, bottom: 15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          widget.status.toString() == "subaccount"
                              ? Container()
                              : twoButtonDropdown(context),
                          const SizedBox(height: 10),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                  child: impactDropdown(groupedResults,
                                      (String impactType) {
                                setState(() {
                                  // Update selected sub-item for this impact type
                                  selectedSubItem[impactType] =
                                      selectedDropdownLabel;
                                });
                              })),
                              const SizedBox(width: 10),
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
                                      color: Colors.white),
                                ),
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
                                        final impactType = groupedResults.keys
                                            .elementAt(index);
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
                                      hintText: 'Search perils',
                                      hintStyle: const TextStyle(
                                          color: Colors.white60),
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
                                              RadioListTile<String>(
                                                value: '',
                                                groupValue:
                                                    selectedHazard ?? '',
                                                onChanged: (value) async {
                                                  setState(() {
                                                    selectedHazard = value;
                                                    showMissingDataDropdown1 =
                                                        false;
                                                  });

                                                  // Call submitHazard if needed
                                                  submitHazard('');

                                                  // 🔥 Call your API directly when NONE is selected
                                                  final locationListProvider =
                                                      Provider.of<
                                                              MyLocationListProvider>(
                                                          context,
                                                          listen: false);

                                                  await locationListProvider
                                                      .fetchLocationList(
                                                    context,
                                                    "",
                                                    1,
                                                    5,
                                                    widget.accountId,
                                                    widget.subaccountId,
                                                    "",
                                                    "",
                                                    widget.sovId,
                                                  );

                                                  print(
                                                      "🔄 Peril cleared — refreshed location list");
                                                },
                                                title: const Text(
                                                  "None",
                                                  style: TextStyle(
                                                      color: Colors.white),
                                                ),
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
                                                            color:
                                                                Colors.white)),
                                                    activeColor:
                                                        Colors.lightBlue,
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
                      Consumer<SubaccountParameterProvider>(
                          builder: (context, provider, child) {
                        final resultList = provider.parameters?.result ?? [];
                        return provider.isLoading
                            ? Container(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Center(
                                    child: Text(
                                      "No Data Found",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: EdgeInsets.only(left: 18),
                                    child: Text(
                                        LanguageService.getTranslated(
                                            context, "data_completeness_score"),
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700)),
                                  ),
                                  SizedBox(height: 5),
                                  Consumer<SubaccountParameterProvider>(
                                    builder: (context, provider, child) {
                                      final resultList =
                                          provider.parameters?.result ?? [];

                                      // Group by impact (default to low when missing/empty)
                                      Map<String, List<Result>> groupedResults =
                                          {
                                        "high": [],
                                        "medium": [],
                                        "low": [],
                                      };

                                      for (var item in resultList) {
                                        String? impact;

                                        if (item.criticality == null ||
                                            item.criticality!.isEmpty) {
                                          impact = "low";
                                        } else {
                                          impact = item
                                              .criticality!.first.impactType
                                              ?.toLowerCase();
                                          if (impact == null ||
                                              impact.trim().isEmpty) {
                                            impact = "low";
                                          }
                                        }

                                        String bucket;
                                        if (impact == "high")
                                          bucket = "high";
                                        else if (impact == "medium")
                                          bucket = "medium";
                                        else
                                          bucket = "low";

                                        groupedResults[bucket]!.add(item);
                                      }

                                      // Calculate %
                                      int calculatePercent(List<Result> list) {
                                        if (list.isEmpty) return 0;
                                        final filled = list
                                            .where((e) =>
                                                e.parameterValue?.value !=
                                                    null &&
                                                e.parameterValue!.value
                                                    .toString()
                                                    .trim()
                                                    .isNotEmpty)
                                            .length;
                                        return ((filled / list.length) * 100)
                                            .round();
                                      }

                                      final visibleCards = groupedResults
                                          .entries
                                          .where((e) => e.value.isNotEmpty)
                                          .map((e) => {
                                                "impact": e.key,
                                                "percent":
                                                    calculatePercent(e.value),
                                              })
                                          .toList();

                                      return SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Row(
                                          children: visibleCards.map((item) {
                                            final impactType =
                                                item["impact"] as String;
                                            final percent =
                                                item["percent"] as int;

                                            return DataCompletenessCard(
                                              title: impactType,
                                              percent: percent,
                                              impactType: impactType,
                                            );
                                          }).toList(),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              );
                      }),
                      SizedBox(height: 16),
                      Builder(builder: (context) {
                        // Build a map of groups to show based on the selectedImpactFilter.
                        final Map<String, List<Result>> displayGroups =
                            selectedImpactFilter == "all"
                                ? groupedResults
                                : {
                                    selectedImpactFilter:
                                        groupedResults[selectedImpactFilter] ??
                                            []
                                  };

                        final visibleEntries = displayGroups.entries
                            .where((e) => e.value.isNotEmpty)
                            .toList();

                        if (visibleEntries.isEmpty) return SizedBox.shrink();

                        return ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: visibleEntries.length,
                          itemBuilder: (context, index) {
                            final impactType = visibleEntries[index].key;
                            final resultsForImpactType =
                                visibleEntries[index].value;

                            // Selected sub-item for this impact group
                            final selectedName = selectedSubItem[impactType];

                            // Reorder list so selected item comes first
                            List<Result> reorderedList =
                                List.from(resultsForImpactType);

                            if (selectedName != null) {
                              final selectedElement = reorderedList.firstWhere(
                                (e) => e.name == selectedName,
                                orElse: () => reorderedList.first,
                              );

                              reorderedList.remove(selectedElement);
                              reorderedList.insert(0, selectedElement);
                            }

                            // Convert to ImpactDataElements
                            final dataElements = reorderedList
                                .where((e) =>
                                    e.name != null &&
                                    e.parameterType != null &&
                                    e.user != null)
                                .map(
                                  (e) => ImpactDataElement(
                                    name: e.name!,
                                    user: e.user!,
                                    result: e,
                                    parameterType: e.parameterType!,
                                    parameterValue: e.parameterValue!,
                                  ),
                                )
                                .toList();

                            if (dataElements.isEmpty)
                              return const SizedBox.shrink();

                            // Keys & state
                            final cardKey = "card_$impactType";
                            itemKeys.putIfAbsent(cardKey, () => GlobalKey());
                            final isExpanded =
                                impactExpandedMap[impactType] ?? true;

                            return Container(
                              key: itemKeys[cardKey],
                              padding: const EdgeInsets.only(
                                  left: 10, right: 10, bottom: 10),
                              child: Column(
                                children: [
                                  /// 🔴 HEADER (ONLY ONE HEADER — NO DUPLICATION)
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        impactExpandedMap[impactType] =
                                            !isExpanded;
                                      });
                                    },
                                    child: Container(
                                      height: 48,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: impactType == "high"
                                            ? const Color(0xFFF44336)
                                            : impactType == "medium"
                                                ? const Color(0xFFFFA726)
                                                : const Color(0xFFCE93D8),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "${impactType.toUpperCase()} Impact Parameter",
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Icon(
                                            isExpanded
                                                ? Icons.expand_less // minimize
                                                : Icons.expand_more,
                                            // expand
                                            color: Colors.white,
                                            size: 26,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  /// 🔴 EXPAND / COLLAPSE CONTENT
                                  AnimatedCrossFade(
                                    duration: const Duration(milliseconds: 300),
                                    crossFadeState: isExpanded
                                        ? CrossFadeState.showSecond
                                        : CrossFadeState.showFirst,
                                    firstChild: const SizedBox.shrink(),
                                    secondChild: ImpactDataCard(
                                      accountId: widget.accountId,
                                      subAccountId: widget.subaccountId,
                                      locationId: widget.locationId,
                                      sovId: widget.sovId,
                                      campusId: widget.campusId,
                                      title: impactType,
                                      titleColor: impactType == "high"
                                          ? const Color(0xFFF44336)
                                          : impactType == "medium"
                                              ? const Color(0xFFFFA726)
                                              : const Color(0xFFCE93D8),
                                      dataElements: dataElements,
                                      selectedParameterList:
                                          selectedParameterList!,
                                      onRefresh: () => _getRefreshData(),

                                      /// 🔥 IMPORTANT — prevents duplicate header
                                      showHeader: false,

                                      expandElementName:
                                          selectedDropdownLabel,
                                      onExpanded: () {
                                        final ctx =
                                            itemKeys[cardKey]!.currentContext;
                                        if (ctx != null) {
                                          Scrollable.ensureVisible(
                                            ctx,
                                            duration: const Duration(
                                                milliseconds: 400),
                                            curve: Curves.easeInOut,
                                            alignment: 0.1,
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );

                      }),
                      Consumer<SubaccountParameterProvider>(
                        builder: (context, provider, child) {
                          final List<DataCategories> items = provider.parameters
                                  ?.vendorData?.hazardHub?.dataCategories ??
                              [];

                          if (items.isEmpty) {
                            return const SizedBox.shrink(); // or Container()
                          }

                          return Container(
                            child: HazardHubCard(items: items),
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
              );
            },
          ),
        );
      });
    }));
  }

  Map<String, List<Result>> reorderedSubItems = {
    "all": [],
    "low": [],
    "medium": [],
    "high": [],
  };

  Widget impactDropdown(
    Map<String, List<Result>> groupedResults,
    Function(String impactType) onRadioSelect,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _controller,
          readOnly: true,
          onTap: () => setState(() => showDropdown = !showDropdown),
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Select Parameter",
            filled: true,
            fillColor: Colors.black,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            suffixIcon: Icon(Icons.arrow_drop_down, color: Colors.white),
          ),
        ),
        if (showDropdown)
          Container(
            // margin: const EdgeInsets.only(top: 2),
            // padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 44,
                  child: ListTile(
                    dense: true,
                    visualDensity: VisualDensity(vertical: -2),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                    title: const Text("All",
                        style: TextStyle(color: Colors.white)),
                    onTap: () {
                      setState(() {
                        selectedImpactFilter = "all";
                        _controller.text = "All";
                        showDropdown = false;
                        showDropdownList = false; // don't show sub list for All
                      });
                    },
                  ),
                ),
                SizedBox(
                  height: 44,
                  child: ListTile(
                    dense: true,
                    visualDensity: VisualDensity(vertical: -2),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                    title: const Text("Low Impact",
                        style: TextStyle(color: Colors.white)),
                    onTap: () {
                      setState(() {
                        selectedImpactFilter = "low";
                        _controller.text = "Low Impact";
                        showDropdown = false;
                        showDropdownList = true;
                      });
                    },
                  ),
                ),
                SizedBox(
                  height: 44,
                  child: ListTile(
                    dense: true,
                    visualDensity: VisualDensity(vertical: -2),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                    title: const Text("Medium Impact",
                        style: TextStyle(color: Colors.white)),
                    onTap: () {
                      setState(() {
                        selectedImpactFilter = "medium";
                        _controller.text = "Medium Impact";
                        showDropdown = false;
                        showDropdownList = true;
                      });
                    },
                  ),
                ),
                SizedBox(
                  height: 44,
                  child: ListTile(
                    dense: true,
                    visualDensity: VisualDensity(vertical: -2),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                    title: const Text("High Impact",
                        style: TextStyle(color: Colors.white)),
                    onTap: () {
                      setState(() {
                        selectedImpactFilter = "high";
                        _controller.text = "High Impact";
                        showDropdown = false;
                        showDropdownList = true;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        if (showDropdownList && selectedImpactFilter != "all")
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
                  (groupedResults[selectedImpactFilter] ?? []).map<Widget>((e) {
                final displayName = e.name ?? "Unnamed";
                return SizedBox(
                  height: 40, // reduce height here (adjust as needed)
                  child: RadioListTile<String>(
                    value: displayName,
                    groupValue: selectedDropdownLabel,
                    title: Text(displayName,
                        style: TextStyle(color: Colors.white)),
                    onChanged: (v) {
                      setState(() {
                        selectedDropdownLabel = v;
                        showDropdownList = false;
                      });
                      onRadioSelect(selectedImpactFilter);
                    },
                    activeColor: Colors.lightBlue,
                    dense: true,
                    visualDensity:
                        const VisualDensity(vertical: -3, horizontal: -1),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

// Track selected sub-item per group
  Map<String, String?> selectedSubItem = {
    "all": null,
    "low": null,
    "medium": null,
    "high": null,
  };

  Widget dropdownItem(
      String label, String key, Map<String, List<Result>> groupedResults) {
    final bool isExpanded = selectedImpactFilter == key;

    // Initialize items list for each impact
    if (reorderedSubItems[key] == null || reorderedSubItems[key]!.isEmpty) {
      reorderedSubItems[key] = key == "all"
          ? groupedResults.values.expand((e) => e).toList()
          : groupedResults[key] ?? [];
    }

    final List<Result> list = reorderedSubItems[key]!;
    final String? selectedName = selectedSubItem[key];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // MAIN CATEGORY (NO RADIO BUTTON)
        InkWell(
          onTap: () {
            setState(() {
              selectedImpactFilter = key;
            });
          },
          child: Row(
            children: [
              Icon(
                isExpanded
                    ? Icons.keyboard_arrow_down
                    : Icons.keyboard_arrow_right,
                color: Colors.white,
                size: 26,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isExpanded ? Colors.lightBlue : Colors.white,
                  fontWeight: isExpanded ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),

        // SUBLIST SHOWING RADIO BUTTONS
        if (isExpanded)
          Padding(
            padding: EdgeInsets.only(left: 40, top: 6, bottom: 12),
            child: Column(
              children: list.map((item) {
                final name = item.name ?? "Unnamed";
                final bool isItemSelected = selectedName == name;

                return InkWell(
                  onTap: () {
                    setState(() {
                      // SELECT ITEM
                      selectedSubItem[key] = name;

                      // MOVE ITEM TO TOP
                      reorderedSubItems[key]!.remove(item);
                      reorderedSubItems[key]!.insert(0, item);
                      print(
                          "Selected Impact Category: $label"); // ex: Low Impact
                      print("Selected Sub Item: $name");
                    });
                  },
                  child: Row(
                    children: [
                      Icon(
                        isItemSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: isItemSelected ? Colors.lightBlue : Colors.white,
                        size: 22,
                      ),
                      SizedBox(width: 8),
                      Text(
                        name,
                        style: TextStyle(
                          color: isItemSelected
                              ? Colors.lightBlue
                              : Colors.white70,
                          fontWeight: isItemSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      )
                    ],
                  ),
                );
              }).toList(),
            ),
          )
      ],
    );
  }

  Widget twoButtonDropdown(BuildContext context) {
    final List<String> parametersList = [
      'Sub Account',
      'Location',
      'Campus',
      'Sov',
    ];

    final filteredParametersList = parametersList.where((item) {
      final sovId = widget.sovId;
      final campusStatus = widget.campusStatus ?? false;

      if (!campusStatus && item == 'Campus') {
        return false;
      }

      if (sovId == null && (item == 'Campus' || item == 'Sov')) {
        return false;
      }

      if (sovId != null && sovId.isEmpty && item == 'Sov') {
        return false;
      }

      if (sovId != null &&
          sovId.isNotEmpty &&
          !campusStatus &&
          item == 'Campus') {
        return false;
      }

      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      isDropdownOpen = !isDropdownOpen;
                    });
                  },
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      selectedParameterList!.isEmpty
                          ? "Sub Account"
                          : selectedParameterList!,
                      style: TextStyle(
                        color: selectedParameterList!.isEmpty
                            ? Colors.white54
                            : Colors.white,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    isDropdownOpen = !isDropdownOpen;
                  });
                },
                icon: Icon(
                  isDropdownOpen
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),

        // Dropdown list
        if (isDropdownOpen)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
            child: Column(
              children: filteredParametersList.map((item) {
                return InkWell(
                  onTap: () {
                    setState(() {
                      selectedParameterList = item;
                      _controllerlist.text = item;
                      isDropdownOpen = false;
                    });

                    // Call provider
                    Provider.of<SubaccountParameterProvider>(
                      context,
                      listen: false,
                    ).fetchSubaccountParameters(
                        context,
                        widget.subaccountId,
                        '',
                        selectedParameterList,
                        widget.locationId,
                        widget.campusId,
                        selectedParameterList,
                        selectedParameterList,
                        widget.sovId);
                    print(selectedParameterList);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    child: Row(
                      children: [
                        Text(
                          item,
                          style: TextStyle(
                            color: selectedParameterList == item
                                ? Colors.lightBlue
                                : Colors.white,
                            fontWeight: selectedParameterList == item
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
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
  final String accountId;
  final String subAccountId;
  final String locationId;
  final String sovId;
  final String campusId;
  final String title;
  User user;
  Result result;
  ParameterType? parametertype;
  final dynamic parameterValue;
  final Function(List<ImageProvider>) onImagesUpdated;
  final String selectedParameterList;
  final Future<void> Function()? onRefresh;

  ImageUploadCard({
    Key? key,
    required this.accountId,
    required this.subAccountId,
    required this.locationId,
    required this.sovId,
    required this.campusId,
    required this.title,
    required this.user,
    required this.result,
    required this.onImagesUpdated,
    required this.parametertype,
    this.parameterValue,
    required this.selectedParameterList,
    this.onRefresh,
  }) : super(key: key);

  @override
  _ImageUploadCardState createState() => _ImageUploadCardState();
}

class _ImageUploadCardState extends State<ImageUploadCard> {
  Set<String> _userEditedFields = {};
  List<ImageProvider> uploadedImages = [];
  TextEditingController monthlyRentedController = TextEditingController();
  TextEditingController paramAController = TextEditingController();
  TextEditingController paramBController = TextEditingController();
  TextEditingController unitController = TextEditingController();
  TextEditingController jsonController = TextEditingController();
  TextEditingController valueTypeController = TextEditingController();
  TextEditingController currencyController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  TextEditingController timestampDateController = TextEditingController();
  DateTime? selectedTimestamp;
  TimeOfDay? selectedTime;
  DateTime? selectedTimestampDate;
  TextEditingController timestampTimeController = TextEditingController();

  TimeOfDay? selectedTimestampTime;
  TextEditingController timeController = TextEditingController();
  TextEditingController timestampController = TextEditingController();
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

  void addImage(BuildContext context, String existingImageUrl) {
    final provider = Provider.of<SubaccountParameterProvider>(
      context,
      listen: false,
    );
    final locationListProvider = Provider.of<MyLocationListProvider>(
      context,
      listen: false,
    );

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
                                    onPressed: () async {
                                      setModalState(() {
                                        selectedImages.remove(file);
                                        fileTags.remove(file);
                                        tagControllers.remove(file);
                                      });

                                      await provider.deleteParameterImage(
                                        context: context,
                                        selectedParameterList:
                                            widget.selectedParameterList,
                                        locationId: widget.locationId,
                                        sovId: widget.sovId,
                                        campusId: widget.campusId,
                                        subaccountId: widget.subAccountId,
                                        parameterId:
                                            widget.result.dataCategoryId!,
                                        // 🔥 REQUIRED
                                        imageObject: {
                                          "url": [
                                            file.absolute.path,
                                          ],
                                          // MUST be a LIST of URLs
                                          "tags": fileTags,
                                          // "name": widget.result.parameterValue!
                                          //     .reference!.first.name,
                                          // MUST be LIST (not string)
                                          "size": widget.result.parameterValue!
                                              .reference!.first.size
                                              .toString()
                                          // MUST be INT
                                        },
                                      );

                                      setState(() {
                                        _userEditedFields.clear();
                                      });

                                      locationListProvider.fetchLocationList(
                                          context,
                                          "",
                                          1,
                                          5,
                                          widget.accountId,
                                          widget.subAccountId,
                                          "",
                                          "",
                                          widget.sovId);
                                    },
                                  ),

                                  // IconButton(
                                  //   icon: Icon(Icons.clear, color: Colors.red),
                                  //   onPressed: () {
                                  //     setModalState(() {
                                  //       selectedImages.remove(file);
                                  //       fileTags.remove(file);
                                  //       tagControllers.remove(file);
                                  //     });
                                  //   },
                                  // ),
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

                                  // COLLECT EXISTING URLS
                                  if (refs != null && refs.isNotEmpty) {
                                    for (var ref in refs) {
                                      if (ref.url != null &&
                                          ref.url!.isNotEmpty) {
                                        existingUrls.addAll(
                                            List<String>.from(ref.url!));
                                      }
                                    }
                                  }

                                  // NO IMAGES SELECTED
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

                                    // UPLOAD NEW IMAGES
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

                                    // BUILD REFERENCES (RAW MAP)
                                    final List<Map<String, dynamic>>
                                        referenceMaps = [];

                                    // EXISTING IMAGES
                                    if (existingUrls.isNotEmpty) {
                                      for (var url in existingUrls) {
                                        referenceMaps.add({
                                          "url": [url],
                                          "tags": [],
                                          // "name": url.split('/').last,
                                          "size": 0,
                                        });
                                      }
                                    }

                                    // NEW UPLOADED IMAGES
                                    for (int i = 0;
                                        i < selectedImages.length;
                                        i++) {
                                      final file = selectedImages[i];
                                      referenceMaps.add({
                                        "url": [downloadUrls[i]],
                                        "tags": fileTags[file] ?? [],
                                        // "name": file.path.split('/').last,
                                        "size": file.lengthSync(),
                                      });
                                    }

                                    // ---- CONVERT TO List<Reference> FOR UI ----
                                    final List<Reference> referenceModels =
                                        referenceMaps.map((m) {
                                      return Reference(
                                        url: List<String>.from(m["url"] ?? []),
                                        tags:
                                            List<String>.from(m["tags"] ?? []),
                                        name: m["name"]?.toString(),
                                        size: m["size"] is int ? m["size"] : 0,
                                      );
                                    }).toList();

                                    final updatedFields = {
                                      "value": "",
                                      "param_type": "Files",
                                      "reference": referenceMaps,
                                      // backend accepts map format
                                    };

                                    final provider = Provider.of<
                                        SubaccountParameterProvider>(
                                      context,
                                      listen: false,
                                    );

                                    // API CALL
                                    await provider.submitParameterUpdate(
                                      context: context,
                                      subaccountId: widget.subAccountId,
                                      locationId: widget.locationId,
                                      sovId: widget.sovId,
                                      campusId: widget.campusId,
                                      parameterId:
                                          widget.result.dataCategoryId!,
                                      updatedFields: updatedFields,
                                      selectedParameterList:
                                          widget.selectedParameterList,
                                    );

                                    // UPDATE UI IMMEDIATELY
                                    setState(() {
                                      widget.result.parameterValue?.reference =
                                          referenceModels;
                                      this.references = referenceModels;
                                    });

                                    // REFRESH LIST
                                    await Provider.of<MyLocationListProvider>(
                                            context,
                                            listen: false)
                                        .fetchLocationList(
                                            context,
                                            "",
                                            1,
                                            10,
                                            widget.accountId,
                                            widget.subAccountId,
                                            "",
                                            "",
                                            '');

                                    if (context.mounted) {
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
                          child: isUploading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                )
                              : Text("Submit"),
                        ),

//                         ElevatedButton(
//                           onPressed: isUploading
//                               ? null
//                               : () async {
//                                   List<String> existingUrls = [];
//
//                                   final refs =
//                                       widget.result.parameterValue?.reference;
//
//                                   if (refs != null && refs.isNotEmpty) {
//                                     for (var ref in refs) {
//                                       if (ref.url != null &&
//                                           ref.url!.isNotEmpty) {
//                                         existingUrls.addAll(List<String>.from(
//                                             ref.url!)); // ✅ fix applied here
//                                       }
//                                     }
//                                   }
//
//                                   if (selectedImages.isEmpty &&
//                                       existingUrls.isEmpty) {
//                                     Fluttertoast.showToast(
//                                       msg:
//                                           "Please select file(s) or provide an existing image URL",
//                                     );
//                                     return;
//                                   }
//
//                                   setModalState(() => isUploading = true);
//
//                                   try {
//                                     List<String> downloadUrls = [];
//
//                                     // Upload newly selected images
//                                     for (File file in selectedImages) {
//                                       final fileName =
//                                           file.path.split('/').last;
//                                       final storageRef =
//                                           FirebaseStorage.instance.ref().child(
//                                               'uploads/${DateTime.now().millisecondsSinceEpoch}_$fileName');
//
//                                       final uploadTask =
//                                           storageRef.putFile(file);
//                                       final snapshot = await uploadTask;
//                                       final downloadUrl =
//                                           await snapshot.ref.getDownloadURL();
//                                       downloadUrls.add(downloadUrl);
//                                     }
//
//                                     final List<Map<String, dynamic>> references = [];
//
//                                     // Add existing images
//                                     // Add existing images
//                                     if (existingUrls.isNotEmpty) {
//                                       for (var url in existingUrls) {
//                                         references.add({
//                                           "url": [url],
//                                           "tags": [],
//                                           "name": url.split('/').last,   // FIXED
//                                           "size": 0                      // FIXED
//                                         });
//                                       }
//                                     }
// // Add newly uploaded images
//                                     for (int i = 0; i < selectedImages.length; i++) {
//                                       final file = selectedImages[i];
//                                       references.add({
//                                         "url": [downloadUrls[i]],
//                                         "tags": fileTags[file] ?? [],
//                                         "name": file.path.split('/').last,
//                                         "size": file.lengthSync()
//                                       });
//                                     }
//
//                                     final updatedFields = {
//                                       "value": "",
//                                       "param_type": "Files",
//                                       "reference": references,
//                                     };
//
//                                     final provider = Provider.of<
//                                         SubaccountParameterProvider>(
//                                       context,
//                                       listen: false,
//                                     );
//
//                                     await provider.submitParameterUpdate(
//                                         context: context,
//                                         subaccountId: widget.subAccountId,
//                                         locationId: widget.locationId,
//                                         sovId: widget.sovId,
//                                         campusId: widget.campusId,
//                                         parameterId:
//                                             widget.result.dataCategoryId!,
//                                         updatedFields: updatedFields,
//                                         selectedParameterList:
//                                             widget.selectedParameterList);
//
//
//                                     // UPDATE UI IMMEDIATELY
//                                     setState(() {
//                                       widget.result.parameterValue?.reference = references;
//                                       this.references = references;
//                                     });
//                                     await Provider.of<MyLocationListProvider>(
//                                             context,
//                                             listen: false)
//                                         .fetchLocationList(
//                                             context,
//                                             "",
//                                             1,
//                                             10,
//                                             widget.accountId,
//                                             widget.subAccountId,
//                                             "",
//                                             "",
//                                             '');
//
//                                     if (context.mounted) {
//                                       WidgetsBinding.instance
//                                           .addPostFrameCallback((_) {
//                                         final locationListProvider =
//                                             Provider.of<MyLocationListProvider>(
//                                           context,
//                                           listen: false,
//                                         );
//                                         locationListProvider.fetchLocationList(
//                                             context,
//                                             "",
//                                             1,
//                                             5,
//                                             widget.accountId,
//                                             widget.subAccountId,
//                                             "",
//                                             "",
//                                             '');
//                                       });
//
//                                       Navigator.pop(context);
//                                     }
//                                   } catch (e) {
//                                     if (context.mounted) {
//                                       ScaffoldMessenger.of(context)
//                                           .showSnackBar(
//                                         SnackBar(
//                                             content: Text("Upload failed: $e")),
//                                       );
//                                     }
//                                   } finally {
//                                     if (context.mounted) {
//                                       setModalState(() => isUploading = false);
//                                     }
//                                   }
//                                 },
//                           child: isUploading
//                               ? SizedBox(
//                                   width: 20,
//                                   height: 20,
//                                   child: CircularProgressIndicator(
//                                       color: Colors.white, strokeWidth: 2))
//                               : Text("Submit"),
//                         ),
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
  File? selectedImageFile; // <--- ADD THIS
  String? uploadedImageUrl;
  bool _isDeletingImage = false;

  TimeOfDay _parseBackendTime(String raw) {
    try {
      final hh = int.parse(raw.substring(0, 2));
      final mm = int.parse(raw.substring(3, 5));
      return TimeOfDay(hour: hh, minute: mm);
    } catch (_) {
      return TimeOfDay.now();
    }
  }

  @override
  void initState() {
    super.initState();

    references = widget.result.parameterValue?.reference;

    // Extract value correctly from result.parameterValue.value
    final rawValue = widget.result.parameterValue?.value;

    if (rawValue != null) {
      if (rawValue is Map) {
        // Handle JSON structure with separate fields
        if (rawValue['parameterA'] != null || rawValue['value'] != null) {
          // Get parameterA value - check both 'parameterA' and 'value' keys
          paramAController.text =
              (rawValue['parameterA'] ?? rawValue['value'] ?? '').toString();
        }

        if (rawValue['parameterB'] != null) {
          paramBController.text = rawValue['parameterB'].toString();
        }

        if (rawValue['unit'] != null) {
          unitController.text = rawValue['unit'].toString();
        }
      } else if (rawValue is String && _isJsonObject(rawValue)) {
        // Handle stringified JSON
        try {
          final parsedJson = jsonDecode(rawValue) as Map<String, dynamic>;

          if (parsedJson['parameterA'] != null || parsedJson['value'] != null) {
            paramAController.text =
                (parsedJson['parameterA'] ?? parsedJson['value'] ?? '')
                    .toString();
          }

          if (parsedJson['parameterB'] != null) {
            paramBController.text = parsedJson['parameterB'].toString();
          }

          if (parsedJson['unit'] != null) {
            unitController.text = parsedJson['unit'].toString();
          }
        } catch (e) {
          // If it's not valid JSON, treat it as a simple value for paramA
          paramAController.text = rawValue.toString();
        }
      } else {
        // For simple string/number - put it in paramA
        paramAController.text = rawValue.toString();
      }
    }

    // -------------------------
    //     JSON TYPE HANDLING
    // -------------------------
    if (widget.parametertype?.name?.toLowerCase() == "time") {
      final raw = widget.result.parameterValue?.value?.toString(); // "13:05:00"

      if (raw != null && raw.isNotEmpty) {
        selectedTime = _parseBackendTime(raw);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            timeController.text = selectedTime!.format(context);
          }
        });
      }
    } else if (widget.parametertype?.name?.toLowerCase() == "timestamp") {
      final raw = widget.result.parameterValue?.value;

      if (raw != null) {
        try {
          DateTime? dt;

          // Check if it's a Map (Firestore timestamp)
          if (raw is Map && raw.containsKey("_seconds")) {
            final sec = raw["_seconds"];
            dt = DateTime.fromMillisecondsSinceEpoch(sec * 1000);
          }
          // Check if it's a string
          else if (raw is String) {
            // Check for Firestore timestamp string
            if (raw.contains("_seconds")) {
              final match = RegExp(r'_seconds[\s:]*(\d+)').firstMatch(raw);
              if (match != null) {
                final sec = int.parse(match.group(1)!);
                dt = DateTime.fromMillisecondsSinceEpoch(sec * 1000);
              }
            } else {
              // Try to parse as ISO string
              dt = DateTime.tryParse(raw);
            }
          }

          if (dt != null) {
            selectedTimestampDate = DateTime(dt.year, dt.month, dt.day);
            selectedTimestampTime = TimeOfDay(hour: dt.hour, minute: dt.minute);

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;

              // Format for display (dd/MM/yyyy hh:mm a)
              timestampController.text =
                  "${selectedTimestampDate!.day.toString().padLeft(2, '0')}/"
                  "${selectedTimestampDate!.month.toString().padLeft(2, '0')}/"
                  "${selectedTimestampDate!.year} "
                  "${selectedTimestampTime!.format(context)}";
            });
          }
        } catch (e) {
          print("Timestamp init parse error: $e");
        }
      }
    } else if (widget.parametertype?.name?.toLowerCase() == "json") {
      String? raw = widget.result.parameterValue?.value;

      if (raw != null && raw.trim().isNotEmpty) {
        // ✔ Web shows raw JSON string exactly as received
        jsonController.text = raw;
      } else {
        jsonController.clear();
      }
    }
  }

  String fixJson(String input) {
    String text = input.trim();

    // Add quotes around keys (name → "name")
    text = text.replaceAllMapped(
        RegExp(r'(\w+)\s*:'), (match) => '"${match[1]}":');

    // Add quotes around string values (vishal → "vishal")
    text = text.replaceAllMapped(
        RegExp(r':\s*([a-zA-Z]+)(\s|}|,)', multiLine: true),
        (match) => ':"${match[1]}"${match[2]}');

    // Add commas between lines if missing
    text = text.replaceAll(RegExp(r'"\s*\n'), '",\n');

    return text;
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
            ] else if (widget.parametertype?.name?.toLowerCase() == "time") ...[
              // ---------------- TIME PICKER ----------------
              GestureDetector(
                onTap: () async {
                  TimeOfDay? picked = await showTimePicker(
                    context: context,
                    initialTime: selectedTime ?? TimeOfDay.now(),
                  );

                  if (picked != null) {
                    setState(() {
                      selectedTime = picked;
                      timeController.text = picked.format(context);
                    });
                  }
                },
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: timeController,
                    maxLines: 1,
                    style: TextStyle(
                      overflow: TextOverflow.ellipsis, // ✔ valid here
                    ),
                    decoration: InputDecoration(
                      labelText: "Select Time",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ] else if (widget.parametertype?.name?.toLowerCase() ==
                "timestamp") ...[
              GestureDetector(
                onTap: () async {
                  // -------- PICK DATE FIRST --------
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: selectedTimestampDate ?? DateTime.now(),
                    firstDate: DateTime(1970),
                    lastDate: DateTime(2100),
                  );

                  if (pickedDate != null) {
                    selectedTimestampDate = pickedDate;

                    // -------- THEN PICK TIME --------
                    TimeOfDay? pickedTime = await showTimePicker(
                      context: context,
                      initialTime: selectedTimestampTime ?? TimeOfDay.now(),
                    );

                    if (pickedTime != null) {
                      selectedTimestampTime = pickedTime;

                      // ---- FORMAT FOR DISPLAY (dd/MM/yyyy hh:mm AM/PM) ----
                      final display =
                          "${pickedDate.month.toString().padLeft(2, '0')}/"
                          "${pickedDate.day.toString().padLeft(2, '0')}/"
                          "${pickedDate.year} "
                          "${pickedTime.format(context)}";

                      setState(() {
                        timestampController.text = display;
                      });
                    }
                  }
                },
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: timestampController,
                    maxLines: 1,
                    style: TextStyle(
                      overflow: TextOverflow.ellipsis, // ✔ valid here
                    ),
                    decoration: InputDecoration(
                      labelText: "Select Timestamp (Date + Time)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ] else if (widget.parametertype?.name?.toLowerCase() == "json") ...[
              TextFormField(
                controller: jsonController,
                maxLines: 8,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: widget.result.parameterNameA ?? "JSON Data",
                  labelStyle: const TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white38),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueAccent),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter JSON data';
                  }

                  try {
                    jsonDecode(value);
                  } catch (_) {
                    return 'Invalid JSON format';
                  }
                  return null;
                },
              ),
              SizedBox(height: 5),
            ] else ...[
              // For all other parameter types, use a unified approach
              ..._buildParameterFields(),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSubmitButton(),
                SizedBox(width: 2),
                GestureDetector(
                  onTap: () {
                    // Check if selectedImageData is not null before accessing its 'url' field
                    if (selectedImageData != null &&
                        selectedImageData!['url'] != null) {
                      String existingImageUrl = selectedImageData!['url'] ?? '';

                      if (existingImageUrl.isNotEmpty) {
                        // Call the addImage method and pass the existing image URL
                        addImage(context, existingImageUrl);
                      } else {
                        // Handle case where the URL is empty
                        addImage(context, existingImageUrl);
                        print("No image URL to send");
                      }
                    } else {
                      // Handle case where selectedImageData is null or URL is not available
                      print("No image data available");
                      addImage(context,
                          ''); // Send an empty string or appropriate fallback data
                    }
                  },

                  // onTap: addImage,
                  child: Container(
                    padding: EdgeInsets.all(5),
                    width: MediaQuery.of(context).size.width / 4,
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
              ],
            ),
            // SizedBox(height: 16),
            (widget.result.parameterValue?.reference == null ||
                    widget.result.parameterValue!.reference!.isEmpty ||
                    widget.result.parameterValue!.reference!.first.url ==
                        null ||
                    widget.result.parameterValue!.reference!.first.url!
                        .every((u) => u == null || u.toString().trim().isEmpty))
                ? Container()
                : Builder(
                    builder: (context) {
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
                                borderRadius: BorderRadius.circular(8)),
                            margin: EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Stack(
                                  children: [
                                    selectedImageData != null
                                        ? Builder(builder: (context) {
                                            final rawUrl =
                                                selectedImageData?['url'];
                                            String imageUrl = '';
                                            if (rawUrl is String) {
                                              imageUrl = rawUrl;
                                            } else if (rawUrl is List &&
                                                rawUrl.isNotEmpty) {
                                              imageUrl =
                                                  rawUrl.first.toString();
                                            }

                                            if (imageUrl.isNotEmpty) {
                                              return InkWell(
                                                onTap: () {
                                                  showDialog(
                                                    context: context,
                                                    builder: (_) =>
                                                        PreviewPopup(
                                                            url: imageUrl),
                                                  );
                                                },
                                                child: Container(
                                                  padding: const EdgeInsets.all(
                                                      12.0),
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                    child: CachedNetworkImage(
                                                      imageUrl: imageUrl,
                                                      width: 70,
                                                      height: 70,
                                                      fit: BoxFit.cover,
                                                      placeholder: (context,
                                                              url) =>
                                                          SizedBox(
                                                              width: 24,
                                                              height: 24,
                                                              child:
                                                                  CircularProgressIndicator()),
                                                      errorWidget: (context,
                                                              url, error) =>
                                                          SvgPicture.asset(
                                                        'assets/images/files.svg',
                                                        color: Colors.white54,
                                                        width: 20,
                                                        height: 20,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            } else {
                                              return Container(
                                                padding:
                                                    const EdgeInsets.all(12.0),
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
                                                    color: Colors.grey[400]),
                                              );
                                            }
                                          })
                                        : Container(),

                                    // CLOSE ICON
                                    if (selectedImageData != null)
                                      Positioned(
                                        top: 1,
                                        right: 1,
                                        child: InkWell(
                                          onTap: () async {
                                            if (_isDeletingImage) return;

                                            setState(() {
                                              _isDeletingImage =
                                                  true; // show loader
                                            });

                                            final provider = Provider.of<
                                                    SubaccountParameterProvider>(
                                                context,
                                                listen: false);
                                            final locationListProvider =
                                                Provider.of<
                                                        MyLocationListProvider>(
                                                    context,
                                                    listen: false);

                                            // Extract URL
                                            final rawUrl =
                                                selectedImageData?['url'];
                                            String imageUrl = "";

                                            if (rawUrl is String)
                                              imageUrl = rawUrl;
                                            if (rawUrl is List &&
                                                rawUrl.isNotEmpty)
                                              imageUrl = rawUrl.first;

                                            final Map<String, dynamic>
                                                imageObject = {
                                              "url": [imageUrl],
                                              "tags":
                                                  selectedImageData?['tags'] ??
                                                      [],
                                              "size":
                                                  selectedImageData?['size'] ??
                                                      0,
                                            };

                                            // ❌ DO NOT CLEAR UI HERE (this causes expansion collapse)

                                            // 2️⃣ DELETE API
                                            await provider.deleteParameterImage(
                                              context: context,
                                              selectedParameterList:
                                                  widget.selectedParameterList,
                                              locationId: widget.locationId,
                                              sovId: widget.sovId,
                                              campusId: widget.campusId,
                                              subaccountId: widget.subAccountId,
                                              parameterId:
                                                  widget.result.dataCategoryId!,
                                              imageObject: imageObject,
                                            );

                                            // 3️⃣ REFRESH LIST
                                            _userEditedFields.clear();
                                            await locationListProvider
                                                .fetchLocationList(
                                              context,
                                              "",
                                              1,
                                              5,
                                              widget.accountId,
                                              widget.subAccountId,
                                              "",
                                              "",
                                              widget.sovId,
                                            );

                                            if (widget.onRefresh != null) {
                                              await widget.onRefresh!();
                                            }

                                            // 4️⃣ NOW SAFE TO CLEAR (after rebuild)
                                            setState(() {
                                              selectedImageData = null;
                                              _isDeletingImage = false;
                                            });
                                          },

                                          // onTap: () async {
                                          //   if (_isDeletingImage)
                                          //     return; // prevent double tap
                                          //
                                          //   setState(() {
                                          //     _isDeletingImage =
                                          //         true; // show loader
                                          //   });
                                          //
                                          //   final provider = Provider.of<
                                          //           SubaccountParameterProvider>(
                                          //       context,
                                          //       listen: false);
                                          //   final locationListProvider =
                                          //       Provider.of<
                                          //               MyLocationListProvider>(
                                          //           context,
                                          //           listen: false);
                                          //
                                          //   final rawUrl =
                                          //       selectedImageData?['url'];
                                          //   String imageUrl = "";
                                          //
                                          //   if (rawUrl is String)
                                          //     imageUrl = rawUrl;
                                          //   if (rawUrl is List &&
                                          //       rawUrl.isNotEmpty)
                                          //     imageUrl = rawUrl.first;
                                          //
                                          //   final Map<String, dynamic>
                                          //       imageObject = {
                                          //     "url": [imageUrl],
                                          //     "tags":
                                          //         selectedImageData?['tags'] ??
                                          //             [],
                                          //     // "name": selectedImageData?[
                                          //     //         'name'] ??
                                          //     //     'Unknown',
                                          //     "size":
                                          //         selectedImageData?['size'] ??
                                          //             0,
                                          //   };
                                          //
                                          //   // 1️⃣ CLEAR PREVIEW
                                          //   setState(() {
                                          //     selectedImageData = null;
                                          //   });
                                          //
                                          //   // 2️⃣ CALL DELETE API
                                          //   await provider.deleteParameterImage(
                                          //     context: context,
                                          //     selectedParameterList:
                                          //         widget.selectedParameterList,
                                          //     locationId: widget.locationId,
                                          //     sovId: widget.sovId,
                                          //     campusId: widget.campusId,
                                          //     subaccountId: widget.subAccountId,
                                          //     parameterId:
                                          //         widget.result.dataCategoryId!,
                                          //     imageObject: imageObject,
                                          //   );
                                          //
                                          //   // 3️⃣ REFRESH PAGE
                                          //   _userEditedFields.clear();
                                          //   await locationListProvider
                                          //       .fetchLocationList(
                                          //     context,
                                          //     "",
                                          //     1,
                                          //     5,
                                          //     widget.accountId,
                                          //     widget.subAccountId,
                                          //     "",
                                          //     "",
                                          //     widget.sovId,
                                          //   );
                                          //
                                          //   if (widget.onRefresh != null) {
                                          //     await widget.onRefresh!();
                                          //   }
                                          //
                                          //   // 4️⃣ HIDE LOADER
                                          //   setState(() {
                                          //     _isDeletingImage = false;
                                          //   });
                                          // },
                                          child: _isDeletingImage
                                              ? SizedBox(
                                                  height: 20,
                                                  width: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: Colors.red,
                                                  ),
                                                )
                                              : Container(
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: Colors.white,
                                                    boxShadow: [
                                                      BoxShadow(
                                                          color: Colors.black26,
                                                          blurRadius: 2),
                                                    ],
                                                  ),
                                                  padding: EdgeInsets.all(3),
                                                  child: Icon(Icons.close,
                                                      color: Colors.red),
                                                ),
                                        ),
                                      ),
                                  ],
                                ),

                                SizedBox(width: 16),

                                // MIDDLE: Metadata
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
                                            Text(
                                                selectedImageData?['uploadedBy']
                                                        ?.toString() ??
                                                    'Unknown'),
                                            SizedBox(height: 6),
                                            Text("Date & Time",
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            Text(selectedImageData?['dateTime']
                                                    ?.toString() ??
                                                ''),
                                          ],
                                        )
                                      : SizedBox.shrink(),
                                ),

                                // RIGHT: DOWNLOAD ICON
                                if (selectedImageData != null)
                                  IconButton(
                                    icon: Icon(Icons.download,
                                        size: 28, color: Colors.white),
                                    onPressed: () {
                                      final rawUrl = selectedImageData?['url'];
                                      String imageUrl = '';
                                      if (rawUrl is String) {
                                        imageUrl = rawUrl;
                                      } else if (rawUrl is List &&
                                          rawUrl.isNotEmpty) {
                                        imageUrl = rawUrl.first.toString();
                                      }

                                      if (imageUrl.isNotEmpty) {
                                        final fileName = Uri.parse(imageUrl)
                                                .pathSegments
                                                .isNotEmpty
                                            ? Uri.parse(imageUrl)
                                                .pathSegments
                                                .last
                                            : 'download';
                                        downloadFile(
                                            imageUrl, fileName, context);
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  'No downloadable URL available')),
                                        );
                                      }
                                    },
                                  ),
                              ],
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
                                        selectedImageData = {
                                          'url': url,
                                          'uploadedBy':
                                              references![refIndex].name,
                                          'tags': references![refIndex].tags,
                                          'size': references![refIndex].size,
                                          'dateTime': formattedDate,
                                        };
                                      });

                                      // setState(() {
                                      //   selectedImageUrl = url;
                                      //   expandedCardsWithImage[0] = imgIndex;
                                      //   selectedImageData = {
                                      //     'url': url,
                                      //     'uploadedBy':
                                      //         references![refIndex].name,
                                      //     'dateTime': formattedDate,
                                      //     'tags': widget.result.parameterValue!
                                      //         .reference!.first.tags,
                                      //     'size': widget.result.parameterValue!
                                      //         .reference!.first.size,
                                      //     // 🔥 add this!
                                      //   };
                                      // });
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
                                  // Positioned(
                                  //   top: 4,
                                  //   right: 4,
                                  //   child: GestureDetector(
                                  //     onTap: () async {
                                  //       final provider = Provider.of<
                                  //           SubaccountParameterProvider>(
                                  //         context,
                                  //         listen: false,
                                  //       );
                                  //       final locationListProvider =
                                  //           Provider.of<MyLocationListProvider>(
                                  //         context,
                                  //         listen: false,
                                  //       );
                                  //       final rawUrl =
                                  //           selectedImageData?['url'];
                                  //       String imageUrl = "";
                                  //
                                  //       if (rawUrl is String) imageUrl = rawUrl;
                                  //       if (rawUrl is List && rawUrl.isNotEmpty)
                                  //         imageUrl = rawUrl.first;
                                  //
                                  //       /// Build image object required by backend
                                  //       final Map<String, dynamic> imageObject =
                                  //           {
                                  //         "url": [imageUrl],
                                  //         "tags":
                                  //             selectedImageData?['tags'] ?? [],
                                  //         "size":
                                  //             selectedImageData?['size'] ?? 0,
                                  //       };
                                  //
                                  //       // -------------------------
                                  //       // 1️⃣ CLEAR PREVIEW FROM UI
                                  //       // -------------------------
                                  //       setState(() {
                                  //         selectedImageData = null;
                                  //       });
                                  //
                                  //       // -------------------------
                                  //       // 2️⃣ CALL DELETE API
                                  //       // -------------------------
                                  //       await provider.deleteParameterImage(
                                  //         context: context,
                                  //         selectedParameterList:
                                  //             widget.selectedParameterList,
                                  //         locationId: widget.locationId,
                                  //         sovId: widget.sovId,
                                  //         campusId: widget.campusId,
                                  //         subaccountId: widget.subAccountId,
                                  //         parameterId:
                                  //             widget.result.dataCategoryId!,
                                  //         imageObject: imageObject,
                                  //       );
                                  //
                                  //       // -------------------------
                                  //       // 3️⃣ REFRESH AFTER DELETE
                                  //       // -------------------------
                                  //       await Provider.of<
                                  //                   MyLocationListProvider>(
                                  //               context,
                                  //               listen: false)
                                  //           .fetchLocationList(
                                  //               context,
                                  //               "",
                                  //               1,
                                  //               10,
                                  //               widget.accountId,
                                  //               widget.subAccountId,
                                  //               "",
                                  //               "",
                                  //               '');
                                  //     },
                                  //     child: Container(
                                  //       decoration: BoxDecoration(
                                  //         shape: BoxShape.circle,
                                  //         color: Colors.white,
                                  //         boxShadow: [
                                  //           BoxShadow(
                                  //               color: Colors.black26,
                                  //               blurRadius: 2),
                                  //         ],
                                  //       ),
                                  //       padding: EdgeInsets.all(4),
                                  //       child: Icon(Icons.delete,
                                  //           size: 16, color: Colors.red),
                                  //     ),
                                  //   ),
                                  // ),
                                ],
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
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

    // Define field configurations with proper field names
    final fieldConfigs = [
      if (widget.result.parameterNameA.toString().trim().isNotEmpty)
        _FieldConfig(
          label: widget.result.parameterNameA.toString(),
          fieldName: 'parameterA',
          // Add this
          controller: parameterType == 'date' || parameterType == 'timestamp'
              ? _dateController
              : paramAController,
          keyboardType: _getKeyboardType(parameterType),
          isDateField: parameterType == 'date' || parameterType == 'timestamp',
        ),
      if (widget.result.parameterNameB.toString().trim().isNotEmpty)
        _FieldConfig(
          label: widget.result.parameterNameB.toString(),
          fieldName: 'parameterB', // Add this
          controller: paramBController,
          keyboardType: _getKeyboardType(parameterType),
        ),
      if (widget.result.unitName.toString().trim().isNotEmpty)
        _FieldConfig(
          label: widget.result.unitName.toString(),
          fieldName: 'unit', // Add this
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

  // List<Widget> _buildParameterFields() {
  //   final fields = <Widget>[];
  //   final parameterType = widget.parametertype!.name!.toLowerCase();
  //
  //   // Define field configurations
  //   final fieldConfigs = [
  //     if (widget.result.parameterNameA.toString().trim().isNotEmpty)
  //       _FieldConfig(
  //         label: widget.result.parameterNameA.toString(),
  //         controller: parameterType == 'date' || parameterType == 'timestamp'
  //             ? _dateController
  //             : paramAController,
  //         keyboardType: _getKeyboardType(parameterType),
  //         isDateField: parameterType == 'date' || parameterType == 'timestamp',
  //       ),
  //     if (widget.result.parameterNameB.toString().trim().isNotEmpty)
  //       _FieldConfig(
  //         label: widget.result.parameterNameB.toString(),
  //         controller: paramBController,
  //         keyboardType: _getKeyboardType(parameterType),
  //       ),
  //     if (widget.result.unitName.toString().trim().isNotEmpty)
  //       _FieldConfig(
  //         label: widget.result.unitName.toString(),
  //         controller: unitController,
  //         keyboardType: _getKeyboardType(parameterType),
  //       ),
  //   ];
  //
  //   // Build fields with spacing
  //   for (var config in fieldConfigs) {
  //     fields.add(_buildTextFormField(config));
  //     fields.add(const SizedBox(height: 8));
  //   }
  //
  //   return fields;
  // }

  TextInputType _getKeyboardType(String parameterType) {
    switch (parameterType) {
      case 'number':
        return TextInputType.number;
      case 'date':
      case 'time':
        return TextInputType.datetime;
      case 'json':
        return TextInputType.multiline;
      default:
        return TextInputType.text;
    }
  }

  String _extractCleanValue(dynamic rv, String fieldName) {
    if (rv == null) return "";

    try {
      dynamic current = rv;

      // 🔥 1 — Handle String input first
      if (current is String) {
        // Check if it's a stringified Firestore timestamp
        if (current.contains("_seconds") && current.contains("_nanoseconds")) {
          // Extract seconds using regex
          final match = RegExp(r"_seconds[\s:]*(\d+)").firstMatch(current);
          if (match != null) {
            final sec = int.parse(match.group(1)!);
            final dt = DateTime.fromMillisecondsSinceEpoch(sec * 1000);
            return DateFormat("dd/MM/yyyy hh:mm a").format(dt);
          }
        }

        // Check if it's a JSON object (but not a Firestore timestamp)
        if (current.trim().startsWith("{") &&
            current.trim().endsWith("}") &&
            !current.contains("_seconds")) {
          try {
            current = jsonDecode(current); // Parse JSON
            // Continue processing as Map below
          } catch (e) {
            // If json decode fails, return as string
            return current.toString();
          }
        }
        // Check if it's an ISO date string
        else if (current.contains("T") && current.contains("Z")) {
          try {
            final dt = DateTime.parse(current);
            return DateFormat("dd/MM/yyyy hh:mm a").format(dt);
          } catch (e) {
            // If parse fails, return original
            return current.toString();
          }
        } else {
          // Plain string - return as is
          return current.toString();
        }
      }

      // 🔥 2 — Now handle Map input (including parsed JSON)
      if (current is Map) {
        // Check if it's a Firestore timestamp map
        if (current.containsKey("_seconds") &&
            current.containsKey("_nanoseconds")) {
          int sec = current["_seconds"];
          final dt = DateTime.fromMillisecondsSinceEpoch(sec * 1000);
          return DateFormat("dd/MM/yyyy hh:mm a").format(dt);
        }

        // Extract field values from the map
        if (fieldName == 'parameterA' ||
            fieldName == widget.result.parameterNameA) {
          return (current['parameterA'] ?? current['value'] ?? "").toString();
        }

        if (fieldName == 'parameterB' ||
            fieldName == widget.result.parameterNameB) {
          return (current['parameterB'] ?? "").toString();
        }

        if (fieldName == 'unit' || fieldName == widget.result.unitName) {
          return (current['unit'] ?? "").toString();
        }

        // Default: return the whole JSON as string
        return jsonEncode(current);
      }

      // 🔥 3 — For any other type (int, double, bool, etc.)
      return current.toString();
    } catch (e) {
      print("Error extracting value: $e");
      return rv.toString();
    }
  }

  // String _extractCleanValue(dynamic rv, String fieldName) {
  //   if (rv == null) return "";
  //
  //   try {
  //     dynamic current = rv;
  //
  //     // If it's a string that looks like JSON, parse it
  //     if (current is String &&
  //         current.trim().startsWith("{") &&
  //         current.contains(":")) {
  //       current = jsonDecode(current);
  //     }
  //
  //     // If it's a Map, extract the specific field value
  //     if (current is Map) {
  //       // For different field types, extract the right value
  //       if (fieldName == 'parameterA' ||
  //           fieldName == widget.result.parameterNameA) {
  //         return (current['parameterA'] ?? current['value'] ?? "").toString();
  //       } else if (fieldName == 'parameterB' ||
  //           fieldName == widget.result.parameterNameB) {
  //         return (current['parameterB'] ?? "").toString();
  //       } else if (fieldName == 'unit' || fieldName == widget.result.unitName) {
  //         return (current['unit'] ?? "").toString();
  //       }
  //
  //       // If we're looking for a specific timestamp/date format
  //       if (current.containsKey("_seconds") &&
  //           current.containsKey("_nanoseconds")) {
  //         int seconds = current["_seconds"];
  //         DateTime dt = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
  //         return DateFormat("dd/MM/yyyy hh:mm a").format(dt);
  //       }
  //
  //       // Default: return the whole JSON as string
  //       return jsonEncode(current);
  //     }
  //
  //     // If it's not a Map, return as string
  //     return current.toString();
  //   } catch (e) {
  //     return rv.toString();
  //   }
  // }

  bool _isJsonObject(String s) {
    if (s.trim().startsWith("{") && s.trim().endsWith("}")) {
      return true;
    }
    return false;
  }

  Widget _buildTextFormField(_FieldConfig config) {
    final rv = widget.result.parameterValue?.value;
    // Pass the field name to extract the correct value
    final cleaned = _extractCleanValue(rv, config.label);
    final fieldKey = config.label; // Use label as unique identifier

    // -------- CASE: multi-field JSON --------
    if (_isJsonObject(cleaned)) {
      final map = jsonDecode(cleaned) as Map<String, dynamic>;
      final children = map.entries.map<Widget>((e) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: TextFormField(
            controller: TextEditingController(text: e.value.toString()),
            decoration: InputDecoration(
              labelText: e.key,
              border: OutlineInputBorder(),
            ),
          ),
        );
      }).toList();
      return Column(
        children: children,
      );
    }

    // -------- CASE: simple field --------
    // Initialize the controller value only once when widget is built
    // if (!config.isInitialized) {
    //   config.controller.text = cleaned;
    //   config.isInitialized = true;
    // }

    return TextFormField(
      controller: config.controller,
      readOnly: config.isDateField,
      keyboardType: config.keyboardType,
      maxLines: 1,
      decoration: InputDecoration(
        labelText: config.label,
        border: OutlineInputBorder(),
      ),
      onChanged: (value) {
        // Mark this field as edited by user
        if (!_userEditedFields.contains(fieldKey)) {
          setState(() {
            _userEditedFields.add(fieldKey);
          });
        }
        print("User typed: $value for field: $fieldKey");
      },
    );
  }

  // Widget _buildTextFormField(_FieldConfig config) {
  //   final rv = widget.result.parameterValue?.value;
  //   final cleaned = _extractCleanValue(rv);
  //   final fieldKey = config.label; // Use label as unique identifier
  //
  //   // -------- CASE: multi-field JSON --------
  //   if (_isJsonObject(cleaned)) {
  //     final map = jsonDecode(cleaned) as Map<String, dynamic>;
  //     final children = map.entries.map<Widget>((e) {
  //       return Padding(
  //         padding: const EdgeInsets.only(bottom: 12.0),
  //         child: TextFormField(
  //           controller: TextEditingController(text: e.value.toString()),
  //           decoration: InputDecoration(
  //             labelText: e.key,
  //             border: OutlineInputBorder(),
  //           ),
  //         ),
  //       );
  //     }).toList();
  //     return Column(
  //       children: children,
  //     );
  //   }
  //
  //   // -------- CASE: simple field --------
  //   // Only update from backend if user hasn't edited this field
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     if (!_userEditedFields.contains(fieldKey) &&
  //         config.controller.text != cleaned) {
  //       config.controller.text = cleaned;
  //     }
  //   });
  //
  //   return TextFormField(
  //     controller: config.controller,
  //     readOnly: config.isDateField,
  //     keyboardType: config.keyboardType,
  //     maxLines: 1,
  //     decoration: InputDecoration(
  //       labelText: config.label,
  //       border: OutlineInputBorder(),
  //     ),
  //     onChanged: (value) {
  //       // Mark this field as edited by user
  //       if (!_userEditedFields.contains(fieldKey)) {
  //         setState(() {
  //           _userEditedFields.add(fieldKey);
  //         });
  //       }
  //       print("User typed: $value");
  //     },
  //   );
  // }

  Widget _buildSubmitButton() {
    var typography = CustomTypography(context);
    return Row(
      children: [
        SizedBox(
          width: MediaQuery.of(context).size.width / 2.3,
          child: CustomButton(
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
                    "Submit",
                    style: typography.Body1.copyWith(color: AppColors.black),
                  ),
            type: ButtonType.elevated,
          ),
        ),
      ],
    );
  }

  Future<void> _handleSubmit() async {
    setState(() => isLoading = true);
    List<Map<String, dynamic>> referenceData = [];

    final existingRef = widget.result.parameterValue?.reference;
// If new image selected
    if (selectedImageFile != null) {
      referenceData = [
        {
          "url": [uploadedImageUrl], // <-- returned from your upload API
          "tags": [],
          // "name": "",
          "size": selectedImageFile!.lengthSync(),
        }
      ];
    }
// If no new image, keep existing one
    else if (existingRef != null && existingRef.isNotEmpty) {
      referenceData = existingRef.map((ref) {
        return {
          "url": ref.url ?? [],
          "tags": ref.tags ?? [],
          // "name": ref.name ?? "",
          "size": ref.size ?? 0,
        };
      }).toList();
    }
// If nothing exists
    else {
      referenceData = [];
      // referenceData = [
      //   {"url": [], "tags": [], "size": 0}
      // ];
    }
    try {
      dynamic value;
      final parameterType = widget.parametertype!.name!.toLowerCase();

      if (parameterType == 'time') {
        if (selectedTime == null) {
          _showError("Please select a time");
          return;
        }

        final hh = selectedTime!.hour.toString().padLeft(2, '0');
        final mm = selectedTime!.minute.toString().padLeft(2, '0');

        value = "$hh:$mm:00"; // <-- "13:05:00"
      } else if (parameterType == 'timestamp') {
        String raw = timestampController.text.trim();

        if (raw.isEmpty) {
          _showError("Please select a timestamp");
          return;
        }

        try {
          // ---------- CLEAN ----------
          raw = raw
              .replaceAll(
                  RegExp(
                      r'[\u00A0\u1680\u2000-\u200D\u2028\u2029\u202F\u205F\u3000]'),
                  ' ')
              .replaceAll(RegExp(r'[\u200B-\u200D]'), '') // zero width
              .replaceAll(RegExp(r'[^\x00-\x7F]'), '') // remove non-ascii
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();

          // Example cleaned: "12/30/2025 11:55 PM" or "30/12/2025 11:55 PM"

          // ---------- EXTRACT PARTS (date + time) ----------
          // Accepts these common separators (slash, dash, dot)
          final match = RegExp(
                  r'([0-3]?\d)[\/\-\.\s]([0-1]?\d)[\/\-\.\s](\d{4})\s+(\d{1,2}:\d{2})\s*([AaPp][Mm])')
              .firstMatch(raw);

          if (match == null) {
            // fallback: try a more permissive split (date and time separated by space)
            final sp = raw.split(' ');
            if (sp.length < 3)
              throw FormatException('Unrecognized timestamp format');
            final datePart = sp[0]; // could be dd/mm or mm/dd
            final timePart = sp.sublist(1).join(' '); // "11:55 PM"
            // try to parse with heuristics below
            raw = "$datePart $timePart";
          }

          // If we have a regex match, rebuild normalized parts
          String datePart;
          String timePart;
          if (match != null) {
            final p1 = match.group(1)!; // first number
            final p2 = match.group(2)!; // second number
            final p3 = match.group(3)!; // year
            datePart = "$p1/$p2/$p3";
            timePart = "${match.group(4)!} ${match.group(5)!}";
          } else {
            // split fallback (eg. "12/30/2025 11:55 PM")
            final parts = raw.split(' ');
            datePart = parts[0];
            timePart = parts.sublist(1).join(' ');
          }

          // ---------- DETECT ORDER (dd/mm vs mm/dd) ----------
          final dateSegments = datePart.split(RegExp(r'[\/\-\.]'));
          if (dateSegments.length != 3) throw FormatException('Bad date part');

          final a = int.tryParse(dateSegments[0]) ?? 0;
          final b = int.tryParse(dateSegments[1]) ?? 0;
          final year = int.tryParse(dateSegments[2]) ?? 0;

          int day;
          int month;

          // Heuristics:
          // - if first segment > 12 => it's day (DD/MM/YYYY)
          // - else if second segment > 12 => first is month (MM/DD/YYYY)
          // - else default to DD/MM/YYYY (your earlier format), but you can change if desired
          if (a > 12 && a <= 31) {
            day = a;
            month = b;
          } else if (b > 12 && b <= 31) {
            month = a;
            day = b;
          } else {
            // ambiguous (e.g. 05/06). Default to DD/MM/YYYY as your UI used earlier.
            day = a;
            month = b;
          }

          // ---------- PARSE timePart using DateFormat.jm ----------
          // normalize spaces, uppercase AM/PM
          timePart =
              timePart.replaceAll(RegExp(r'\s+'), ' ').trim().toUpperCase();

          final parsedTime =
              DateFormat.jm().parseLoose(timePart); // more forgiving

          final dtLocal = DateTime(
            year,
            month,
            day,
            parsedTime.hour,
            parsedTime.minute,
            0,
          );

          // ---------- CONVERT TO UTC and exact format ----------
          final dtUtc = dtLocal.toUtc();
          final formatted = "${dtUtc.year.toString().padLeft(4, '0')}-"
              "${dtUtc.month.toString().padLeft(2, '0')}-"
              "${dtUtc.day.toString().padLeft(2, '0')}T"
              "${dtUtc.hour.toString().padLeft(2, '0')}:"
              "${dtUtc.minute.toString().padLeft(2, '0')}:00.000Z";

          value = formatted; // final value sent to backend
        } catch (e) {
          print("Timestamp parse error: $e");
          _showError("Invalid timestamp format");
          return;
        }
      } else if (parameterType.toLowerCase() == 'json') {
        String rawText = jsonController.text.trim();

        rawText = rawText
            .replaceAll('“', '"')
            .replaceAll('”', '"')
            .replaceAll('‘', "'")
            .replaceAll('’', "'");

        value = rawText;
      }

      // ---------------- NUMBER ----------------
      else if (parameterType == 'number') {
        final txt = paramAController.text.trim();
        if (txt.isEmpty) {
          _showError('Please enter a number');
          return;
        }

        // Web sends: "{\"value\":\"99\"}"
        // value = json.encode({"value": txt});
        value = json.encode({
          "value": paramAController.text.trim(),
          "unit": unitController.text.trim().isEmpty
              ? null
              : unitController.text.trim(),
          "parameterB": paramBController.text.trim().isEmpty
              ? null
              : paramBController.text.trim(),
        });
      }

      // ---------------- BOOLEAN ----------------
      else if (parameterType == 'boolean') {
        if (selectedBooleanValue == null) {
          _showError('Please select Yes or No');
          return;
        }

        // Web sends boolean normally
        value = selectedBooleanValue;
      }

      // ---------------- DEFAULT TEXT / UNIT / PARAMETER A/B ----------------
      else {
        final paramA = paramAController.text.trim();
        final paramB = paramBController.text.trim();
        final unit = unitController.text.trim();

        if (widget.result.parameterNameA!.trim().isNotEmpty && paramA.isEmpty) {
          _showError(
              'Please enter a value for ${widget.result.parameterNameA}');
          return;
        }

        if (widget.result.parameterNameB!.trim().isNotEmpty && paramB.isEmpty) {
          _showError(
              'Please enter a value for ${widget.result.parameterNameB}');
          return;
        }

        if (widget.result.unitName!.trim().isNotEmpty && unit.isEmpty) {
          _showError('Please enter a value for ${widget.result.unitName}');
          return;
        }
        value = json.encode({
          "value": paramAController.text.trim(),
          "unit": unitController.text.trim(),
          "parameterB": paramBController.text.trim(),
        });
      }

      // ---------- MATCH WEB EXACTLY ----------
      final updatedFields = {
        "value": value, // always stringified JSON when number/json
        "param_type": widget.parametertype!.name,
        "reference": referenceData,
        // "reference": [
        //   {
        //     "url": [""], // array, like Web
        //     "tags": [],
        //     "size": 0,
        //   }
        // ],
      };

      final provider = Provider.of<SubaccountParameterProvider>(
        context,
        listen: false,
      );
      final locationListProvider = Provider.of<MyLocationListProvider>(
        context,
        listen: false,
      );

      await provider.submitParameterUpdate(
        context: context,
        subaccountId: widget.subAccountId,
        locationId: widget.locationId,
        sovId: widget.sovId,
        campusId: widget.campusId,
        parameterId: widget.result.dataCategoryId!,
        updatedFields: updatedFields,
        selectedParameterList: widget.selectedParameterList!,
      );

      setState(() {
        _userEditedFields.clear();
      });

      locationListProvider.fetchLocationList(context, "", 1, 5,
          widget.accountId, widget.subAccountId, "", "", widget.sovId);

      if (widget.onRefresh != null) {
        await widget.onRefresh!();
      }
    } catch (e) {
      _showError('Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showError(String message) {
    var typography = CustomTypography(context);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: TextStyle(color: Colors.black))),
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
  final String fieldName; // Add this: 'parameterA', 'parameterB', or 'unit'
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool isDateField;
  bool isInitialized = false;

  _FieldConfig({
    required this.label,
    required this.fieldName, // Add this parameter
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
  final ParameterValue parameterValue;

  ImpactDataElement({
    required this.name,
    required this.user,
    required this.result,
    required this.parameterType,
    required this.parameterValue,
  });
}

class DataCompletenessCard extends StatefulWidget {
  final String title;
  final int percent;
  final String impactType;

  const DataCompletenessCard({
    super.key,
    required this.title,
    required this.percent,
    required this.impactType,
  });

  @override
  State<DataCompletenessCard> createState() => _DataCompletenessCardState();
}

class _DataCompletenessCardState extends State<DataCompletenessCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 115,
      margin: const EdgeInsets.only(right: 2, left: 12),
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
          /// ICON BOX (same as original)
          SizedBox(
            height: 55,
            width: 55,
            child: SegmentedProgress(percent: widget.percent),
          ),

          const SizedBox(height: 10),

          Text(
            'Completed ${widget.percent}%',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
          const SizedBox(height: 6),

          Text(
            widget.impactType[0].toUpperCase() +
                widget.impactType.substring(1).toLowerCase(),
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

class SegmentedProgressPainter extends CustomPainter {
  final int percent;

  SegmentedProgressPainter(this.percent);

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 12.0;
    final totalSegments = 12;
    final anglePerSegment = (360 / totalSegments) * 0.9; // segment thickness
    final gap = (360 / totalSegments) * 0.1; // small gap between segments

    final rect = Offset.zero & size;
    final radius = size.width / 2;

    final completedSegments = ((percent / 100) * totalSegments).floor();

    for (int i = 0; i < totalSegments; i++) {
      final paint = Paint()
        ..color = i < completedSegments ? Colors.green : Colors.green.shade900
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(center: Offset(radius, radius), radius: radius - 5),
        radians((360 / totalSegments) * i),
        radians(anglePerSegment),
        false,
        paint,
      );
    }
  }

  double radians(double deg) => deg * (3.141592653589793 / 180);

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class SegmentedProgress extends StatelessWidget {
  final int percent; // 0 to 100

  const SegmentedProgress({super.key, required this.percent});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: SegmentedProgressPainter(percent),
      child: Center(
        child: Text(
          "$percent%",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

Future<void> downloadFile(
    String url, String fileName, BuildContext context) async {
  try {
    // Ask storage permission (Android)
    await Permission.storage.request();

    final dir = await getApplicationDocumentsDirectory();
    final savePath = "${dir.path}/$fileName";

    Dio dio = Dio();

    await dio.download(
      url,
      savePath,
      onReceiveProgress: (received, total) {
        if (total != -1) {
          print(
              "Download progress: ${(received / total * 100).toStringAsFixed(0)}%");
        }
      },
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Downloaded successfully: $fileName")),
    );

    print("Saved to: $savePath");
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Download failed: $e")),
    );
  }
}

class PreviewPopup extends StatelessWidget {
  final String url;

  const PreviewPopup({super.key, required this.url});

  // ---------- URL CLEANER ----------
  String cleanUrl(String url) {
    return url.split("?").first.trim(); // Remove ?alt=media&token=...
  }

  // ---------- FORMAT DETECTORS ----------
  bool isImage(String url) {
    final u = cleanUrl(url).toLowerCase();
    return u.endsWith(".png") ||
        u.endsWith(".jpg") ||
        u.endsWith(".jpeg") ||
        u.endsWith(".gif") ||
        u.endsWith(".bmp") ||
        u.endsWith(".webp");
  }

  bool isSvg(String url) => cleanUrl(url).toLowerCase().endsWith(".svg");

  bool isPdf(String url) => cleanUrl(url).toLowerCase().endsWith(".pdf");

  bool isDoc(String url) {
    final u = cleanUrl(url).toLowerCase();
    return u.endsWith(".doc") ||
        u.endsWith(".docx") ||
        u.endsWith(".ppt") ||
        u.endsWith(".pptx") ||
        u.endsWith(".xls") ||
        u.endsWith(".xlsx");
  }

  // ---------- MAIN POPUP UI ----------
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black87,
      insetPadding: EdgeInsets.all(16),
      child: Container(
        padding: EdgeInsets.all(12),
        width: double.infinity,
        height: 380,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text("Preview",
                style: TextStyle(fontSize: 18, color: Colors.white)),
            SizedBox(height: 12),
            Expanded(child: _buildPreviewContent()),
            SizedBox(height: 12),
            Align(
              alignment: Alignment.bottomRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child:
                    Text("Close", style: TextStyle(color: Colors.blueAccent)),
              ),
            )
          ],
        ),
      ),
    );
  }

  // ---------- PREVIEW CONTENT ----------
  Widget _buildPreviewContent() {
    const double boxWidth = 250;
    const double boxHeight = 250;
    const double borderRadius = 16;

    BoxDecoration boxDecoration = BoxDecoration(
      color: Colors.black12,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: Colors.white24, width: 1),
    );

    // ---------------- IMAGE PREVIEW ----------------
    if (isImage(url)) {
      return Container(
        width: boxWidth,
        height: boxHeight,
        decoration: boxDecoration,
        clipBehavior: Clip.antiAlias,
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 4.0,
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.fill,
            placeholder: (_, __) =>
                Center(child: CircularProgressIndicator(color: Colors.white)),
            errorWidget: (_, __, ___) =>
                Icon(Icons.broken_image, size: 40, color: Colors.white70),
          ),
        ),
      );
    }

    // ---------------- SVG PREVIEW ----------------
    if (isSvg(url)) {
      return Container(
        width: boxWidth,
        height: boxHeight,
        decoration: boxDecoration,
        clipBehavior: Clip.antiAlias,
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 4.0,
          child: SvgPicture.network(
            url,
            fit: BoxFit.contain,
            placeholderBuilder: (_) =>
                Center(child: CircularProgressIndicator(color: Colors.white)),
          ),
        ),
      );
    }

    // ---------------- PDF / DOC / OTHER FILE PREVIEW ----------------
    return Container(
      width: boxWidth,
      height: boxHeight,
      decoration: boxDecoration,
      padding: const EdgeInsets.all(20),
      child: _fileIcon(
        isPdf(url)
            ? Icons.picture_as_pdf
            : isDoc(url)
                ? Icons.description
                : Icons.insert_drive_file,
        isPdf(url)
            ? "PDF File"
            : isDoc(url)
                ? "Document File"
                : "Unsupported Format",
      ),
    );
  }

  Widget _fileIcon(IconData icon, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 80, color: Colors.white70),
        SizedBox(height: 12),
        Text(label, style: TextStyle(color: Colors.white70)),
      ],
    );
  }
}

class HazardHubCard extends StatefulWidget {
  final List<DataCategories> items;

  const HazardHubCard({super.key, required this.items});

  @override
  State<HazardHubCard> createState() => _HazardHubCardState();
}

class _HazardHubCardState extends State<HazardHubCard> {
  int expandedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: const BoxDecoration(
            color: Color(0xFF66BB6A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
          ),
          child: const Text(
            "HazardHub",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),

        /// BODY
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(10)),
            border: Border.all(color: Colors.grey.shade700),
          ),
          child: Column(
            children: List.generate(widget.items.length, (index) {
              final item = widget.items[index];
              final isExpanded = expandedIndex == index;

              final data = item.parameterData;
              final title = data?.name ?? "-";
              // final key = data?.key ?? "-";

              final parsed = parseParameterValue(data?.parameterValue);

              final score = parsed['score']?.toString() ?? "--";

              return Column(
                children: [
                  _mainRow(
                    title: title,
                    // keyName: key,
                    score: score,
                    isExpanded: isExpanded,
                    onTap: () {
                      setState(() {
                        expandedIndex = isExpanded ? -1 : index;
                      });
                    },
                  ),
                  if (isExpanded) _expandedSection(parsed),
                  const Divider(height: 1, color: Colors.grey),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  /// ================= MAIN ROW =================
  Widget _mainRow({
    required String title,
    // required String keyName,
    required String score,
    required bool isExpanded,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// TITLE + ICON
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _chip("Score : $score"),
                const SizedBox(width: 5),
                Icon(
                  isExpanded ? Icons.remove : Icons.add_circle_outline,
                  color: Colors.grey,
                )
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// ================= EXPANDED =================
  Widget _expandedSection(Map<String, dynamic> data) {
    final entries = data.entries.where((e) => e.key != "score").toList();

    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade700),
        borderRadius: BorderRadius.circular(8),
        color: const Color(0xFF3A3A3A),
      ),
      child: Column(
        children: [
          /// TABLE HEADER
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: [
                _headerCell("Category"),
                _verticalDivider(),
                _headerCell("Value / Detail"),
              ],
            ),
          ),

          /// ROWS
          ...List.generate(entries.length, (index) {
            final e = entries[index];
            return Column(
              children: [
                _dataRow(
                  formatKey(e.key),
                  e.value.toString(),
                ),
                if (index != entries.length - 1)
                  Divider(height: 1, color: Colors.grey.shade700),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _headerCell(String text) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _verticalDivider() {
    return Container(
      width: 1,
      height: double.infinity,
      color: Colors.grey.shade700,
    );
  }

  Widget _dataRow(String label, String value) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade700),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// CATEGORY
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ),
            ),

            /// VERTICAL DIVIDER
            Container(
              width: 1,
              color: Colors.grey.shade700,
            ),

            /// VALUE
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ================= HELPERS =================
  Map<String, dynamic> parseParameterValue(ParameterValue? paramValue) {
    if (paramValue?.value == null) return {};
    try {
      final decoded = jsonDecode(paramValue!.value!);
      return decoded['value'] ?? {};
    } catch (_) {
      return {};
    }
  }

  Widget _chip(String text, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color ?? const Color(0xFF3A3A3A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }

  String formatKey(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((e) => e.isEmpty ? e : '${e[0].toUpperCase()}${e.substring(1)}')
        .join(' ');
  }
}

/// ================= STYLES =================
const _headerStyle = TextStyle(
  color: Colors.white,
  fontWeight: FontWeight.w600,
  fontSize: 13,
);

const _cellStyle = TextStyle(
  color: Colors.white,
  fontSize: 13,
);
