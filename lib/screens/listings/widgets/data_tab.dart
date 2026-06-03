import 'dart:collection';
import 'dart:convert';
import 'dart:ui' as BorderType;
import 'package:RiskSphere/models/view_employee_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter/services.dart';
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
import 'package:http/http.dart' as http;
import '../processing_summary.dart';
import '../sync_parameter.dart';

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
                    bucket = "low";
                  }
                }

                groupedResults[bucket]!.add(result);
              }

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

                    if (reorderedList.contains(selectedElement)) {
                      reorderedList.remove(selectedElement);
                      reorderedList.insert(0, selectedElement);
                    }
                  }

                  final dataElements = reorderedList
                      .where(
                        (e) => e.user != null && e.parameterType != null,
                      )
                      .map(
                        (e) => ImpactDataElement(
                          name: e.name ?? "",
                          user: e.user!,
                          result: e,
                          parameterType: e.parameterType!,
                          parameterValue: e.parameterValue!,
                        ),
                      )
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
                      onExpanded: () async {
                        await Future.delayed(
                          const Duration(milliseconds: 150),
                        );

                        final ctx = itemKeys[cardKey]!.currentContext;

                        if (ctx != null) {
                          final renderBox = ctx.findRenderObject() as RenderBox;
                          final position =
                              renderBox.localToGlobal(Offset.zero).dy;

                          // if (position < 100 || position > MediaQuery.of(context).size.height - 200) {
                          //   Scrollable.ensureVisible(
                          //     ctx,
                          //     duration: const Duration(milliseconds: 250),
                          //     curve: Curves.easeOut,
                          //     alignment: 0.1,
                          //   );
                          // }
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
                                                  submitHazard('');
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
                                                      " Peril cleared — refreshed location list");
                                                },
                                                title: const Text(
                                                  "None",
                                                  style: TextStyle(
                                                      color: Colors.white),
                                                ),
                                                activeColor: Colors.lightBlue,
                                              ),

                                              //  Dynamic hazard options
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

                            final selectedName = selectedSubItem[impactType];

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
                            final dataElements = reorderedList.map((e) {
                              return ImpactDataElement(
                                name: e.name ?? "",
                                user: e.user!,
                                result: e,
                                parameterType: e.parameterType!,
                                parameterValue: e.parameterValue,
                              );
                            }).toList();

                            if (dataElements.isEmpty)
                              return const SizedBox.shrink();

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
                                            ? Color.fromRGBO(244, 67, 54, 0.08)
                                                .withOpacity(0.2)
                                            : impactType == "medium"
                                                ? Color.fromRGBO(
                                                        255, 167, 38, 0.5)
                                                    .withOpacity(0.2)
                                                : Color.fromRGBO(
                                                        206, 147, 216, 0.08)
                                                    .withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: impactType == "high"
                                              ? Color.fromRGBO(244, 67, 54, 0.5)
                                              : impactType == "medium"
                                                  ? Color.fromRGBO(
                                                      255, 167, 38, 0.5)
                                                  : Color.fromRGBO(
                                                      206, 147, 216, 0.5),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "${impactType[0].toUpperCase()}${impactType.substring(1)} Impact Parameter",
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
                                      showHeader: false,
                                      expandElementName: selectedDropdownLabel,
                                      onExpanded: () async {
                                        await Future.delayed(
                                          const Duration(milliseconds: 150),
                                        );

                                        final ctx =
                                            itemKeys[cardKey]!.currentContext;

                                        if (ctx != null) {
                                          final renderBox = ctx
                                              .findRenderObject() as RenderBox;
                                          final position = renderBox
                                              .localToGlobal(Offset.zero)
                                              .dy;

                                          // if (position < 100 || position > MediaQuery.of(context).size.height - 200) {
                                          //   Scrollable.ensureVisible(
                                          //     ctx,
                                          //     duration: const Duration(milliseconds: 250),
                                          //     curve: Curves.easeOut,
                                          //     alignment: 0.1,
                                          //   );
                                          // }
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
                      Padding(
                        padding: const EdgeInsets.all(0.0),
                        child: Consumer<SubaccountParameterProvider>(
                          builder: (context, provider, child) {
                            final List<DataCategories> items = provider
                                    .parameters
                                    ?.vendorData
                                    ?.hazardHub
                                    ?.dataCategories ??
                                [];

                            if (items.isEmpty) {
                              return const SizedBox.shrink(); // or Container()
                            }

                            return Container(
                              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                              child: HazardHubCard(items: items),
                            );
                          },
                        ),
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
    // if (provider.zipcode.isNotEmpty) {
    //   chips.add(
    //     Chip(
    //       label: Text('Zip: ${provider.zipcode}'),
    //       onDeleted: () {
    //         // provider.zipcode = '';
    //         // provider.fetchLocationList(context, "", 1, 40, widget.accountId,
    //         //     widget.subAccountId, widget.initialProcessId, widget.initialSubProcessId);
    //       },
    //     ),
    //   );
    // }

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
  LinkVendor? linkVendor;
  final dynamic parameterValue;
  final Function(List<ImageProvider>) onImagesUpdated;
  final String selectedParameterList;
  final Future<void> Function()? onRefresh;

  /// Second expand step for single HazardHub link: show value fields.
  final bool showManualValueFields;

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
    this.linkVendor,
    this.parameterValue,
    required this.selectedParameterList,
    this.onRefresh,
    this.showManualValueFields = false,
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
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () async {
                                      setModalState(() {
                                        selectedImages.remove(file);
                                        fileTags.remove(file);
                                        tagControllers.remove(file);
                                      });

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
                                  if (selectedImages.isEmpty) {
                                    Fluttertoast.showToast(
                                      msg: "Please select file(s)",
                                    );
                                    return;
                                  }

                                  setModalState(() => isUploading = true);

                                  try {
                                    List<String> uploadedUrls = [];

                                    for (File file in selectedImages) {
                                      final url =
                                          await uploadFileToFirebaseRest(file);

                                      uploadedUrls.add(url);
                                    }

                                    final List<Reference> references = [];

                                    final existingRefs =
                                        widget.result.parameterValue?.reference;

                                    if (existingRefs != null &&
                                        existingRefs.isNotEmpty) {
                                      references.addAll(existingRefs);
                                    }

                                    for (int i = 0;
                                        i < selectedImages.length;
                                        i++) {
                                      final file = selectedImages[i];

                                      references.add(
                                        Reference(
                                          url: [uploadedUrls[i]],
                                          // Keep as list if backend expects list
                                          tags: fileTags[file] ?? [],
                                          name: file.path.split('/').last,
                                          size: await file.length(),
                                        ),
                                      );
                                    }

                                    final updatedFields = {
                                      "value": "{}",
                                      "is_reference_updated": true,
                                      "param_type": "Number",
                                      "reference": references
                                          .map((e) => e.toJson())
                                          .toList(),
                                    };

                                    print(updatedFields);

                                    final subProvider = Provider.of<
                                        SubaccountParameterProvider>(
                                      context,
                                      listen: false,
                                    );

                                    await subProvider.submitParameterUpdate(
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

                                    if (widget.onRefresh != null) {
                                      await widget.onRefresh!();
                                      Navigator.pop(context);
                                    }
                                  } catch (e) {
                                    print(" Upload Error: $e");

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("Upload failed: $e"),
                                      ),
                                    );
                                  } finally {
                                    if (context.mounted) {
                                      setModalState(() => isUploading = false);
                                    }
                                  }
                                },
                          child: isUploading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text("Submit"),
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

  Future<String> uploadFileToFirebaseRest(File file) async {
    const bucket = "project-green-r5-1-qa.firebasestorage.app";

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("User not authenticated.");
    }

    final idToken = await user.getIdToken();

    final fileName = file.path.split('/').last;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final storagePath = "uploads/$timestamp-$fileName";

    final encodedPath = Uri.encodeComponent(storagePath);

    final uri = Uri.parse(
      "https://firebasestorage.googleapis.com/v0/b/$bucket/o"
      "?uploadType=media&name=$encodedPath",
    );

    final bytes = await file.readAsBytes();

    final response = await http.post(
      uri,
      headers: {
        "Content-Type": "application/octet-stream",
        "Authorization": "Bearer $idToken",
      },
      body: bytes,
    );

    if (response.statusCode != 200) {
      print(" Upload Error: ${response.body}");
      throw Exception("Upload failed: ${response.statusCode}");
    }

    final jsonResponse = jsonDecode(response.body);
    final downloadToken = jsonResponse["downloadTokens"];

    if (downloadToken == null) {
      throw Exception("Download token missing.");
    }

    //  Correct public URL (same as getDownloadURL in web)
    return "https://firebasestorage.googleapis.com/v0/b/"
        "$bucket/o/$encodedPath?alt=media&token=$downloadToken";
  }

  void deleteImage(int index) {
    setState(() {
      uploadedImages.removeAt(index);
      widget.onImagesUpdated(uploadedImages);
    });
  }

  bool isSyncing = false;
  bool selectedBooleanValue = true;

  bool get _hasHazardHubTag =>
      widget.result.tags?.contains("hazard_hub") ?? false;

  bool get _showHazardHubSyncPanel =>
      // _hasHazardHubTag &&
      (widget.linkVendor?.hazardHub?.items?.isNotEmpty ?? false);

  late final displayValue =
      widget.result.parameterValue?.otherSources?['hazard_hub'];

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
  File? selectedImageFile;
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
          paramAController.text = rawValue.toString();
        }
      } else {
        paramAController.text = rawValue.toString();
      }
    }
    if (widget.parametertype?.name?.toLowerCase() == "time") {
      final raw = widget.result.parameterValue?.value?.toString();

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
          dynamic decoded = raw;

          if (decoded is String &&
              decoded.trim().startsWith("{") &&
              decoded.trim().endsWith("}")) {
            decoded = jsonDecode(decoded);
          }

          if (decoded is Map &&
              decoded["value"] is String &&
              decoded["value"].toString().trim().startsWith("{")) {
            decoded["value"] = jsonDecode(decoded["value"]);
          }

          if (decoded is Map && decoded["value"] is Map) {
            final isoString = decoded["value"]["value"];
            if (isoString != null) {
              dt = DateTime.tryParse(isoString);
            }
          } else if (decoded is Map && decoded.containsKey("_seconds")) {
            final sec = decoded["_seconds"];
            dt = DateTime.fromMillisecondsSinceEpoch(sec * 1000);
          } else if (decoded is String) {
            dt = DateTime.tryParse(decoded);
          }

          if (dt != null) {
            selectedTimestampDate = DateTime(dt.year, dt.month, dt.day);
            selectedTimestampTime = TimeOfDay(hour: dt.hour, minute: dt.minute);

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;

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
        jsonController.text = raw;
      } else {
        jsonController.clear();
      }
    }
  }

  String _hazardHubItemDisplayName() {
    final items = widget.linkVendor?.hazardHub?.items;
    if (items == null || items.isEmpty) return '';
    return items.values.first.name ?? '';
  }

  String fixJson(String input) {
    String text = input.trim();

    text = text.replaceAllMapped(
        RegExp(r'(\w+)\s*:'), (match) => '"${match[1]}":');

    text = text.replaceAllMapped(
        RegExp(r':\s*([a-zA-Z]+)(\s|}|,)', multiLine: true),
        (match) => ':"${match[1]}"${match[2]}');

    text = text.replaceAll(RegExp(r'"\s*\n'), '",\n');

    return text;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Form(
        key: _formKey,
        child: Column(children: [
          if (_showHazardHubSyncPanel)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withOpacity(0.12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.compare_arrows,
                        color: Colors.white70,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "HazardHub parameter found",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  RichText(
                    text: TextSpan(
                      children: [
                        const TextSpan(
                          text: "HazardHub key: ",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        TextSpan(
                          text: (_hazardHubItemDisplayName()) +
                              " (${widget.result.name.toString()})",
                          style: TextStyle(
                            color: Color(0xFF79B8FF),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.linkVendor?.hazardHub?.items?.isNotEmpty ??
                      false) ...[
                    (() {
                      try {
                        final displayValue = widget
                            .result.parameterValue?.otherSources?['hazard_hub'];

                        if (displayValue == null ||
                            displayValue.toString().trim().isEmpty) {
                          return const SizedBox.shrink();
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 4),
                            RichText(
                              text: TextSpan(
                                children: [
                                  const TextSpan(
                                    text: "Value : ",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                  TextSpan(
                                    text: displayValue.toString(),
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      } catch (e) {
                        debugPrint("Hazard Hub Value Error: $e");
                        return const SizedBox.shrink();
                      }
                    })(),
                  ],
                  if (displayValue != null &&
                      displayValue.toString().trim().isNotEmpty) ...[
                    Text(""),
                  ] else ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 42,
                      child: StatefulBuilder(
                        builder: (context, setSyncState) {
                          final hasHazardHubTag =
                              widget.result.tags?.contains("hazard_hub") ??
                                  false;

                          final isSyncButton = !hasHazardHubTag;

                          return OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: hasHazardHubTag
                                    ? Colors.green
                                    : Color(0xFF5DA9FF),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: isSyncing || !isSyncButton
                                ? null
                                : () async {
                                    setSyncState(() {
                                      isSyncing = true;
                                    });

                                    try {
                                      final items =
                                          widget.linkVendor?.hazardHub?.items;

                                      String extractionKey = "";

                                      if (items != null && items.isNotEmpty) {
                                        final firstItem = items.values.first;

                                        extractionKey = firstItem.path ?? "";
                                      }

                                      print(
                                        "Extraction Key => $extractionKey",
                                      );

                                      if (extractionKey.isEmpty) {
                                        setSyncState(() {
                                          isSyncing = false;
                                        });

                                        return;
                                      }

                                      final response = await Provider.of<
                                          SubaccountParameterProvider>(
                                        context,
                                        listen: false,
                                      ).recommendationEngineApi(
                                        context,
                                        widget.locationId ?? "",
                                        widget.result.dataCategoryId ?? "",
                                        extractionKey,
                                      );

                                      print(
                                        "API RESPONSE => $response",
                                      );

                                      if (response != null) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => SyncParametersPage(
                                              response: response,
                                            ),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      print(
                                        "SYNC ERROR => $e",
                                      );
                                    } finally {
                                      setSyncState(() {
                                        isSyncing = false;
                                      });
                                      if (widget.onRefresh != null) {
                                        await widget.onRefresh!();
                                      }
                                    }
                                  },
                            child: isSyncing
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF79B8FF),
                                    ),
                                  )
                                : Text(
                                    hasHazardHubTag
                                        ? "From HazardHub"
                                        : "Sync from HazardHub",
                                    style: TextStyle(
                                      color: hasHazardHubTag
                                          ? Colors.green
                                          : Color(0xFF79B8FF),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          );
                        },
                      ),
                    ),
                  ]
                ],
              ),
            ),
          const SizedBox(height: 14),
          if (!_showHazardHubSyncPanel || widget.showManualValueFields) ...[
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
                    final existingImageUrl =
                        selectedImageData?['url']?.toString() ?? '';

                    if (existingImageUrl.isEmpty) {
                      print("No image data available");
                    }

                    addImage(context, existingImageUrl);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    width: MediaQuery.of(context).size.width / 4,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(width: 0.8, color: Colors.white38),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, color: Colors.blueAccent, size: 22),
                        SizedBox(width: 6),
                        Text(
                          "Upload",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
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
                                    if (selectedImageData != null)
                                      Positioned(
                                        top: 1,
                                        right: 1,
                                        child: InkWell(
                                          onTap: () async {
                                            if (_isDeletingImage) return;

                                            setState(() {
                                              _isDeletingImage = true;
                                            });

                                            final provider = Provider.of<
                                                SubaccountParameterProvider>(
                                              context,
                                              listen: false,
                                            );
                                            final locationListProvider =
                                                Provider.of<
                                                    MyLocationListProvider>(
                                              context,
                                              listen: false,
                                            );

                                            final rawUrl =
                                                selectedImageData?['url'];
                                            String imageUrl = "";
                                            if (rawUrl is String)
                                              imageUrl = rawUrl;
                                            else if (rawUrl is List &&
                                                rawUrl.isNotEmpty)
                                              imageUrl = rawUrl.first;

                                            String storageName = "";
                                            try {
                                              final uri = Uri.parse(imageUrl);
                                              final encodedPath =
                                                  uri.pathSegments.last;
                                              storageName = Uri.decodeComponent(
                                                  encodedPath);
                                            } catch (e) {
                                              storageName =
                                                  selectedImageData?['name'] ??
                                                      'Unknown';
                                              print("storageName fallback: $e");
                                            }
                                            String uploadedBy = "";
                                            try {
                                              final filenameFull =
                                                  storageName.split('/').last;
                                              final dashIndex =
                                                  filenameFull.indexOf('-');
                                              uploadedBy = dashIndex != -1
                                                  ? filenameFull
                                                      .substring(dashIndex + 1)
                                                  : filenameFull;
                                            } catch (e) {
                                              uploadedBy =
                                                  storageName.split('/').last;
                                            }

                                            final Map<String, dynamic>
                                                imageObject = {
                                              "url": [imageUrl],
                                              "tags":
                                                  selectedImageData?['tags'] ??
                                                      [],
                                              "size":
                                                  selectedImageData?['size'] ??
                                                      0,
                                              "name": uploadedBy,
                                              "uploadedBy": "",
                                            };

                                            print(
                                                " DELETE imageObject: ${jsonEncode(imageObject)}");

                                            final success = await provider
                                                .deleteParameterImage(
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

                                            if (success) {
                                              setState(() {
                                                references =
                                                    references?.where((ref) {
                                                  final urls = ref.url ?? [];
                                                  return !urls
                                                      .contains(imageUrl);
                                                }).toList();

                                                selectedImageData = null;
                                                _isDeletingImage = false;
                                              });

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
                                            } else {
                                              setState(() {
                                                _isDeletingImage = false;
                                              });
                                            }
                                          },
                                          child: _isDeletingImage
                                              ? const SizedBox(
                                                  height: 20,
                                                  width: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: Colors.red,
                                                  ),
                                                )
                                              : Container(
                                                  decoration:
                                                      const BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: Colors.white,
                                                  ),
                                                  padding:
                                                      const EdgeInsets.all(3),
                                                  child: const Icon(
                                                    Icons.delete,
                                                    color: Colors.red,
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
                                                'NA'),
                                          ],
                                        )
                                      : SizedBox.shrink(),
                                ),
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

                              final String? url = imgData['url']?.toString();

                              final String safeUrl = (url ?? "").trim();
                              final String lowerUrl = safeUrl.toLowerCase();

                              final bool isImage = lowerUrl.endsWith(".jpg") ||
                                  lowerUrl.endsWith(".jpeg") ||
                                  lowerUrl.endsWith(".png");

                              if (safeUrl.isEmpty) {
                                return Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.grey.shade800,
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.broken_image,
                                        color: Colors.white54),
                                  ),
                                );
                              }

                              return Stack(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      final int? timestamp = widget.result
                                          .parameterValue?.updatedAt?.iSeconds;

                                      final formattedDate = timestamp != null
                                          ? DateFormat('dd/MM/yyyy HH:mm:ss')
                                              .format(DateTime
                                                  .fromMillisecondsSinceEpoch(
                                                      timestamp * 1000))
                                          : "";

                                      setState(() {
                                        selectedImageData = {
                                          'url': safeUrl,
                                          'uploadedBy':
                                              references?[refIndex].name ?? "",
                                          'tags':
                                              references?[refIndex].tags ?? [],
                                          'size':
                                              references?[refIndex].size ?? 0,
                                          'dateTime': formattedDate,
                                        };
                                      });
                                    },
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: isImage
                                          ? CachedNetworkImage(
                                              imageUrl: safeUrl,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) =>
                                                  const Center(
                                                      child:
                                                          CircularProgressIndicator()),
                                              errorWidget:
                                                  (context, url, error) =>
                                                      const Icon(
                                                          Icons.broken_image),
                                            )
                                          : Container(
                                              color: Colors.grey.shade900,
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
                                                    getFileNameFromUrl(safeUrl),
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
                                ],
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
          ],
        ]),
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

      if (current is String) {
        if (current.contains("_seconds") && current.contains("_nanoseconds")) {
          final match = RegExp(r"_seconds[\s:]*(\d+)").firstMatch(current);
          if (match != null) {
            final sec = int.parse(match.group(1)!);
            final dt = DateTime.fromMillisecondsSinceEpoch(sec * 1000);
            return DateFormat("dd/MM/yyyy hh:mm a").format(dt);
          }
        }

        if (current.trim().startsWith("{") &&
            current.trim().endsWith("}") &&
            !current.contains("_seconds")) {
          try {
            current = jsonDecode(current);
          } catch (e) {
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
      if (current is Map) {
        if (current.containsKey("_seconds") &&
            current.containsKey("_nanoseconds")) {
          int sec = current["_seconds"];
          final dt = DateTime.fromMillisecondsSinceEpoch(sec * 1000);
          return DateFormat("dd/MM/yyyy hh:mm a").format(dt);
        }

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
        return jsonEncode(current);
      }

      return current.toString();
    } catch (e) {
      print("Error extracting value: $e");
      return rv.toString();
    }
  }

  bool _isJsonObject(String s) {
    if (s.trim().startsWith("{") && s.trim().endsWith("}")) {
      return true;
    }
    return false;
  }

  Widget _buildTextFormField(_FieldConfig config) {
    final rv = widget.result.parameterValue?.value;
    final cleaned = _extractCleanValue(rv, config.label) ?? "";
    final fieldKey = config.label;

    final paramType =
        widget.result.parameterValue?.paramType?.toLowerCase() ?? "";

    final isIntType = paramType == "int";
    final isNumType = paramType == "number";

    if (cleaned.contains("value:")) {
      final match = RegExp(r'value:\s*([^,}]+)').firstMatch(cleaned);

      if (match != null) {
        final extractedValue = match.group(1)?.trim() ?? "";
        if (!_userEditedFields.contains(fieldKey)) {
          config.controller.text = extractedValue;
        }

        return TextFormField(
          controller: config.controller,
          keyboardType: (isIntType || isNumType)
              ? const TextInputType.numberWithOptions(decimal: true)
              : config.keyboardType,
          inputFormatters: isIntType
              ? [FilteringTextInputFormatter.digitsOnly]
              : isNumType
                  ? [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d*'),
                      )
                    ]
                  : null,
          decoration: InputDecoration(
            labelText: config.label,
            border: const OutlineInputBorder(),
          ),
          onChanged: (value) {
            if (!_userEditedFields.contains(fieldKey)) {
              setState(() {
                _userEditedFields.add(fieldKey);
              });
            }
          },
        );
      }
    }

    if (!_userEditedFields.contains(fieldKey)) {
      config.controller.text = cleaned;
    }

    return TextFormField(
      controller: config.controller,
      readOnly: config.isDateField,
      keyboardType: (isIntType || isNumType)
          ? const TextInputType.numberWithOptions(decimal: true)
          : config.keyboardType,
      inputFormatters: isIntType
          ? [FilteringTextInputFormatter.digitsOnly]
          : isNumType
              ? [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^\d*\.?\d*'),
                  )
                ]
              : null,
      decoration: InputDecoration(
        labelText: config.label,
        border: const OutlineInputBorder(),
      ),
      onChanged: (value) {
        if (!_userEditedFields.contains(fieldKey)) {
          setState(() {
            _userEditedFields.add(fieldKey);
          });
        }
      },
    );
  }

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

    final currentRefs = references;

    /// -------- HANDLE REFERENCES --------
    if (currentRefs != null && currentRefs.isNotEmpty) {
      referenceData = currentRefs.map<Map<String, dynamic>>((ref) {
        return {
          "url": ref.url ?? [],
          "tags": ref.tags ?? [],
          "name": ref.name ?? "",
          "size": ref.size ?? 0,
          "uploadedBy": ref.uploadedBy ?? ""
        };
      }).toList();
    }

    /// If new image uploaded add it
    if (selectedImageFile != null && uploadedImageUrl != null) {
      referenceData.add({
        "url": [uploadedImageUrl],
        "tags": [],
        "name": "uploads/${DateTime.now().millisecondsSinceEpoch}.png",
        "size": selectedImageFile!.lengthSync(),
        "uploadedBy": "mobile"
      });
    }

    try {
      dynamic value;
      final parameterType = widget.parametertype!.name!.toLowerCase();

      /// ---------- TIME ----------
      if (parameterType == 'time') {
        if (selectedTime == null) {
          value = "{}";
        } else {
          final hh = selectedTime!.hour.toString().padLeft(2, '0');
          final mm = selectedTime!.minute.toString().padLeft(2, '0');

          final formattedTime = "$hh:$mm:00";

          value = json.encode({
            "value": {"value": formattedTime}
          });
        }
      }

      /// ---------- TIMESTAMP ----------
      else if (parameterType == 'timestamp') {
        String raw = timestampController.text.trim();

        if (raw.isEmpty) {
          value = "{}";
        } else {
          try {
            raw = raw
                .replaceAll(
                    RegExp(
                        r'[\u00A0\u1680\u2000-\u200D\u2028\u2029\u202F\u205F\u3000]'),
                    ' ')
                .replaceAll(RegExp(r'\s+'), ' ')
                .trim();

            final parsed = DateFormat("dd/MM/yyyy hh:mm a").parseLoose(raw);

            final utc = parsed.toUtc();

            final formatted = "${utc.year.toString().padLeft(4, '0')}-"
                "${utc.month.toString().padLeft(2, '0')}-"
                "${utc.day.toString().padLeft(2, '0')}T"
                "${utc.hour.toString().padLeft(2, '0')}:"
                "${utc.minute.toString().padLeft(2, '0')}:00.000Z";

            value = json.encode({
              "value": {"value": formatted}
            });
          } catch (e) {
            _showError("Invalid timestamp format");
            return;
          }
        }
      }

      /// ---------- JSON ----------
      else if (parameterType == 'json') {
        String rawText = jsonController.text.trim();

        if (rawText.isEmpty) {
          value = "{}";
        } else {
          rawText = rawText
              .replaceAll('\u201C', '"')
              .replaceAll('\u201D', '"')
              .replaceAll('\u2018', "'")
              .replaceAll('\u2019', "'");

          value = rawText;
        }
      }

      /// ---------- NUMBER ----------
      else if (parameterType == 'number') {
        final paramA = paramAController.text.trim();
        final unit = unitController.text.trim();
        final paramB = paramBController.text.trim();

        /// If all empty send {}
        if (paramA.isEmpty && unit.isEmpty && paramB.isEmpty) {
          value = "{}";
        } else {
          value = json.encode({
            "value": paramA,
            "unit": unit.isEmpty ? null : unit,
            "parameterB": paramB.isEmpty ? null : paramB,
          });
        }
      }

      /// ---------- BOOLEAN ----------
      else if (parameterType == 'boolean') {
        if (selectedBooleanValue == null) {
          value = "{}";
        } else {
          value = selectedBooleanValue;
        }
      }

      /// ---------- DEFAULT ----------
      else {
        final paramA = paramAController.text.trim();
        final paramB = paramBController.text.trim();
        final unit = unitController.text.trim();

        if (paramA.isEmpty && paramB.isEmpty && unit.isEmpty) {
          value = "{}";
        } else {
          value = json.encode({
            "value": paramA,
            "unit": unit,
            "parameterB": paramB,
          });
        }
      }

      /// ---------- FINAL PAYLOAD ----------
      final updatedFields = {
        "value": value,
        "param_type": widget.parametertype!.name,
        "is_reference_updated": true,
        "reference": referenceData,
      };

      final provider =
          Provider.of<SubaccountParameterProvider>(context, listen: false);

      final locationListProvider =
          Provider.of<MyLocationListProvider>(context, listen: false);

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

      locationListProvider.fetchLocationList(
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
  final ParameterValue? parameterValue;

  ImpactDataElement({
    required this.name,
    required this.user,
    required this.result,
    required this.parameterType,
    this.parameterValue,
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

String mapScoreToRiskLabel(String score) {
  switch (score.toUpperCase()) {
    case 'A':
      return 'Lowest Risk';
    case 'B':
      return 'Low Risk';
    case 'C':
      return 'Moderate Risk';
    case 'D':
      return 'High Risk';
    case 'F':
      return 'Very High Risk';
    default:
      return score; // fallback (numeric or NA)
  }
}

class HazardHubCard extends StatefulWidget {
  final List<DataCategories> items;

  HazardHubCard({super.key, required this.items});

  @override
  State<HazardHubCard> createState() => _HazardHubCardState();
}

class _HazardHubCardState extends State<HazardHubCard> {
  int expandedIndex = -1;
  bool isHeaderExpanded = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              isHeaderExpanded = !isHeaderExpanded;
            });
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Color.fromRGBO(104, 206, 109, 0.08).withOpacity(0.3),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(8),
                topRight: const Radius.circular(8),
                bottomLeft: isHeaderExpanded
                    ? const Radius.circular(2)
                    : const Radius.circular(8),
                bottomRight: isHeaderExpanded
                    ? const Radius.circular(2)
                    : const Radius.circular(8),
              ),
              border: Border.all(
                color: Color.fromRGBO(104, 206, 109, 0.5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "HazardHub",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Icon(
                  isHeaderExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.white,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 300),
          crossFadeState: isHeaderExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF252525),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
              border: Border.all(color: Colors.grey.shade700),
            ),
            child: Column(
              children: List.generate(widget.items.length, (index) {
                final item = widget.items[index];
                final isExpanded = expandedIndex == index;

                final data = item.parameterData;
                final title = data?.name ?? "NA";

                final expandedData =
                    parseParameterValue(data!.parameterValue!.value);
                final parsed = parseExpandedJson(expandedData);
                final value = parsed['value'];
                final rawScore =
                    value is Map ? value['score']?.toString() ?? 'NA' : 'NA';

                final score = mapScoreToRiskLabel(rawScore);

                return Column(
                  children: [
                    // Text(expandedData.toString()),
                    score.toString() == 'NA'
                        ? SizedBox.shrink()
                        : _mainRow(
                            title: title,
                            score: score,
                            isExpanded: isExpanded,
                            onTap: () {
                              setState(() {
                                expandedIndex = isExpanded ? -1 : index;
                              });
                            },
                          ),
                    if (isExpanded) _expandedSection(expandedData),
                    const Divider(height: 1, color: Colors.grey),
                  ],
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  Map<String, dynamic> parseExpandedJson(dynamic raw) {
    if (raw == null) return {};

    if (raw is Map<String, dynamic>) {
      return raw;
    }

    if (raw is String) {
      try {
        return jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {
        return {};
      }
    }

    return {};
  }

  String getScoreFromExpanded(dynamic raw) {
    final parsed = parseExpandedJson(raw);

    final value = parsed['value'];

    if (value is Map<String, dynamic>) {
      return value['score']?.toString() ?? 'NA';
    }

    if (value is String || value is num) {
      return value.toString();
    }

    return 'NA';
  }

  Widget _mainRow({
    required String title,
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
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _chip("Score : $score"),
                const SizedBox(width: 5),
                Icon(
                  isExpanded
                      ? Icons.remove_circle_outline_outlined
                      : Icons.add_circle_outline,
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

  Widget _expandedSection(Map<String, dynamic> data) {
    final dynamic value = data['value'];

    if (value == null) return const SizedBox.shrink();

    if (value is Map<String, dynamic>) {
      return _buildTable(value);
    }

    return _buildSingleValueTable(value);
  }

  Widget _buildSingleValueTable(dynamic value) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade700),
        borderRadius: BorderRadius.circular(8),
        color: const Color(0xFF3A3A3A),
      ),
      child: Column(
        children: [
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
                _headerCell("Value"),
              ],
            ),
          ),
          _dataRow("Value", value.toString()),
        ],
      ),
    );
  }

  Widget _buildTable(Map<String, dynamic> map) {
    final entries = map.entries.toList();

    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade700),
        borderRadius: BorderRadius.circular(8),
        color: const Color(0xFF3A3A3A),
      ),
      child: Column(
        children: [
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
                _headerCell("Value"),
              ],
            ),
          ),

          /// ROWS
          ...entries.asMap().entries.map((entry) {
            final index = entry.key;
            final key = entry.value.key;
            final value = entry.value.value;

            return Column(
              children: [
                _buildRow(key, value),
                if (index != entries.length - 1)
                  Divider(height: 1, color: Colors.grey.shade700),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildRow(String key, dynamic value) {
    if (value is Map<String, dynamic>) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              formatKey(key),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildTable(value),
          ],
        ),
      );
    }

    if (value is List) {
      if (value.isEmpty) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              formatKey(key),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...value.asMap().entries.map((entry) {
              final item = entry.value;

              if (item is Map<String, dynamic>) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildTable(item),
                );
              }

              // Fallback (rare)
              return _dataRow(
                formatKey(key),
                item.toString(),
              );
            }).toList(),
          ],
        ),
      );
    }

    return _dataRow(
      formatKey(key),
      value?.toString() ?? '—',
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
            fontSize: 18,
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
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            Container(
              width: 1,
              color: Colors.grey.shade700,
            ),
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> parseParameterValue(dynamic rawValue) {
    if (rawValue == null) return {};

    if (rawValue is Map<String, dynamic>) {
      return rawValue;
    }

    if (rawValue is String) {
      try {
        final decoded = jsonDecode(rawValue);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      } catch (e) {
        debugPrint("JSON parse error: $e");
      }
    }

    return {};
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
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
    );
  }

  String formatKey(String key) {
    return key
        .replaceAll('_', ' ')
        .replaceAllMapped(
          RegExp(r'([a-z])([A-Z])'),
          (m) => '${m[1]} ${m[2]}',
        )
        .split(' ')
        .map((e) => e.isEmpty ? e : '${e[0].toUpperCase()}${e.substring(1)}')
        .join(' ');
  }
}
