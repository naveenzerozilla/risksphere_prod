import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:RiskSphere/models/my_location_list_model.dart';
import 'package:RiskSphere/providers/location_list_provider.dart';
import 'package:RiskSphere/providers/my_location_list_provider.dart';
import 'package:RiskSphere/screens/listings/widgets/export_dialog.dart';
import 'package:RiskSphere/screens/listings/widgets/listings_filter_screen.dart';
import 'package:RiskSphere/screens/listings/widgets/location_card.dart';
import 'package:RiskSphere/screens/listings/widgets/location_list_map_view.dart';
import 'package:RiskSphere/screens/listings/widgets/mapping_screen.dart';
import 'package:RiskSphere/screens/listings/widgets/overall_score_table.dart';
import 'package:lottie/lottie.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:remixicon/remixicon.dart';

import '../../constants/enums.dart';
import '../../design_system/components/custom_appbar.dart';
import '../../design_system/components/custom_button.dart';
import '../../design_system/components/custom_drawer.dart';
import '../../design_system/primitives/app_colors.dart';
import '../../design_system/primitives/custom_typography.dart';
import '../../design_system/primitives/utilities/custom_spacing.dart';
import '../../providers/theme_provider.dart';
import 'package:RiskSphere/models/role_model.dart' as roleModel;
import '../../providers/upload_sov_provider.dart';
import '../../service/language_service.dart';
import '../../service/shared_preference_service.dart';
import '../processMonitoringScreen/process_monitoring_system.dart';
import 'widgets/maintenance_widget.dart';

class SovLocationList extends StatefulWidget {
  final String? accountID;
  final String? subAccountID;
  final String accountName;
  final String subAccountName;
  final String? sovID;
  final String sovName;
  final String? initialProcessId;
  final String? initialSubProcessId;

  const SovLocationList({
    super.key,
    this.accountID,
    this.subAccountID,
    this.accountName = '',
    this.subAccountName = '',
    this.sovID,
    this.sovName = '',
    this.initialProcessId,
    this.initialSubProcessId,
  });

  @override
  State<SovLocationList> createState() => _SovLocationListState();
}

class _SovLocationListState extends State<SovLocationList>
    with TickerProviderStateMixin {
  bool _isExpanded = false;
  bool _showNotificationDot = true;
  TabController? _tabController;
  Screens _selectedScreen = Screens.connectionList;
  TextEditingController _locationSearchController = TextEditingController();
  TextEditingController mobileController = TextEditingController();

  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String selectedDropdown = 'TPV';
  int? touchedIndex; // For showing overlay info
  bool longPressed = false;
  int requestActionIndex = 0;
  String selectedMetric = 'PD Value';
  String selectedMetric_pie = 'PD Value';
  String selectedView = "Overall Score";
  String selectedView1 = "Geocoding";

  PieColorData getPieColorsByPercent(dynamic pct) {
    if (pct == null) {
      // Default to bucket 1 (lowest) if null
      return PIE_COLORS[1]!;
    }

    // Safely convert dynamic to number
    final double percent =
        (pct is num) ? pct.toDouble() : double.tryParse(pct.toString()) ?? 0.0;

    int bucket;
    if (percent >= 80) {
      bucket = 5;
    } else if (percent >= 60) {
      bucket = 4;
    } else if (percent >= 40) {
      bucket = 3;
    } else if (percent >= 20) {
      bucket = 2;
    } else {
      bucket = 1;
    }

    // Always safely return a color (default if not found)
    return PIE_COLORS[bucket] ?? PIE_COLORS[1]!;
  }

  final Map<int, PieColorData> PIE_COLORS = {
    1: PieColorData(fill: '#EF5350', text: '#FFFFFF'),
    2: PieColorData(fill: '#FFF176', text: '#111111'),
    3: PieColorData(fill: '#90CAF9', text: '#111111'),
    4: PieColorData(fill: '#81C784', text: '#0A2E0A'),
    5: PieColorData(fill: '#2E7D32', text: '#FFFFFF'),
  };

  Color hexToColor(String hex) {
    var h = hex.replaceAll('#', '').trim();
    if (h.length == 6) {
      // Add opaque alpha
      h = 'FF$h';
    }
    return Color(int.parse('0x$h'));
  }

  List<roleModel.Roles> filterRoleList = [];

  List<roleModel.Roles> filterRoles = [];
  List<String> filterNames = [];
  List<String> filterEmails = [];
  List<String> filterPhones = [];
  List<String> filterCompanies = [];
  List<String> filterStatus = [];
  roleModel.Roles? selectedRoleForFilter;
  String selectedStatus = '';
  String locationQuery = '';

  bool showSelectAll = false;
  bool isAllSelected = false; // State variable to manage "Select All"

  Timer? deBouncer;

  List<MyLocation> selectedLocations = [];

  String? _uploadedFileName;
  TextEditingController _sovNameController = TextEditingController();
  late File files;

  bool isMaintenance = false;

  TabController? _mainTabController;
  int selectedMainTab = 0;
  int selectedTab = 0;

  void debounce(VoidCallback callback,
      {Duration duration = const Duration(seconds: 1)}) {
    if (deBouncer != null) {
      deBouncer!.cancel();
    }
    deBouncer = Timer(duration, callback);
  }

  void locationSearchClient(String query) async {
    debounce(() async {
      if (!mounted) return;
      locationQuery = query;
      Provider.of<LocationListProvider>(context, listen: false)
          .fetchLocationList(
        context,
        widget.accountID!,
        widget.subAccountID!,
        widget.sovID!,
        query,
        0,
        "forward",
        40,
        countries: [],
        // Add your filter parameters here
        state: "",
        propertyType: [],
        constructionType: [],
        certifications: [],
        hazard: [],
        rating: [],
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 3, vsync: this);
    _mainTabController?.addListener(() {
      setState(() {
        selectedMainTab = _mainTabController?.index ?? 0;
      }); // This ensures that the widget rebuilds when the tab changes
    });
    _tabController = TabController(length: 2, vsync: this);
    _tabController?.addListener(() {
      setState(() {
        selectedTab = _tabController?.index ?? 0;
      });
      if (_tabController?.index == 0) {
        _selectedScreen = Screens.locationList;
        var locationListProvider =
            Provider.of<MyLocationListProvider>(context, listen: false);
        locationListProvider.page = 1;
        Provider.of<MyLocationListProvider>(context, listen: false)
            .fetchLocationList(
              context,
              "",
              1,
              10,
              widget.accountID,
              widget.subAccountID,
              widget.initialProcessId,
              widget.initialSubProcessId,
              widget.sovID,
            )
            .then((value) => setState(() {}));
      } else {
        _selectedScreen = Screens.certifiedLocationList;
        var locationListProvider =
            Provider.of<MyLocationListProvider>(context, listen: false);
        locationListProvider.page = 1;
        locationListProvider.clearRatingsFilter();
        Provider.of<MyLocationListProvider>(context, listen: false)
            .fetchCertifiedLocationList(
              context,
              "",
              1,
              10,
              widget.accountID,
              widget.subAccountID,
              widget.initialProcessId,
              widget.initialSubProcessId,
              widget.sovID,
            )
            .then((value) => setState(() {}));
        /*Provider.of<LocationListProvider>(context, listen: false).page = 0;
        Provider.of<LocationListProvider>(context, listen: false).fetchCertifiedLocationList(
          context,
          "widget.accountId",
          "widget.subAccountId",
          "widget.sovId",
          locationQuery,
          0,
          40,
        );*/
      }
      setState(() {});
    });
    _getData();
  }

  // _getMaintainancePeriod() async {
  //   isMaintenance =
  //       await SharedPreferenceService.getScheduleInProgress() ?? false;
  // }

  _getData() async {
    print("Fetching location list for SOV ID: ${widget.sovID}");
    // Fetch data from API
    Provider.of<MyLocationListProvider>(context, listen: false)
        .fetchLocationList(
          context,
          "",
          1,
          40,
          widget.accountID,
          widget.subAccountID,
          widget.initialProcessId,
          widget.initialSubProcessId,
          widget.sovID,
        )
        .then((value) => setState(() {}));
    Provider.of<MyLocationListProvider>(context, listen: false)
        .fetchCertifiedLocationList(
          context,
          "",
          1,
          40,
          widget.accountID,
          widget.subAccountID,
          widget.initialProcessId,
          widget.initialSubProcessId,
          widget.sovID,
        )
        .then((value) => setState(() {}));
    //Provider.of<LocationListProvider>(context, listen: false).fetchCampusIds("widget.accountId", "widget.subAccountId", "widget.sovId");
    // _getMaintainancePeriod();
  }

  void searchNetworks(String query) async => debounce(() async {
        if (!mounted) return;
        /*await Provider.of<ConnectionsProvider>(context, listen: false)
        .getUserSuggestions(context, query);*/
      });

  @override
  Widget build(BuildContext context1) {
    return SafeArea(
      child: Consumer<ThemeProvider>(
        builder: (buildContext, themeProvider, child) {
          return Scaffold(
            key: _scaffoldKey,
            backgroundColor: themeProvider.getTheme.colorScheme.surface,
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
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/mesh.png',
                    fit: BoxFit.cover,
                  ),
                ),
                Consumer<MyLocationListProvider>(
                    builder: (context, myLocationListProvider, child) {
                  final isSelectionMode =
                      myLocationListProvider.selectedLocations.isNotEmpty;

                  var typography = CustomTypography(context);
                  return Column(
                    children: [
                      SizedBox(height: CustomSpacing.two),
                      Container(
                        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        padding: const EdgeInsets.fromLTRB(8, 8, 0, 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            // Set your border color here
                            width: 1.0, // Set the width of the border
                          ),
                          //color: Theme.of(context).colorScheme.surfaceContainerHigh,
                        ),
                        child: Consumer<MyLocationListProvider>(
                            builder: (context, locationListProvider, child) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (isSelectionMode) ...[
                                // Show selection count and select all button
                                SizedBox(width: CustomSpacing.two),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHigh,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    "${locationListProvider.selectedLocations.length}",
                                    style: typography.Body1.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 2),
                                TextButton(
                                  onPressed: () {
                                    if (_selectedScreen ==
                                        Screens.locationList) {
                                      if (locationListProvider
                                              .selectedLocations.length <
                                          locationListProvider
                                              .myLocationList.length) {
                                        locationListProvider
                                            .selectAllLocations(true);
                                      } else {
                                        locationListProvider.clearSelection();
                                      }
                                    } else if (_selectedScreen ==
                                        Screens.certifiedLocationList) {
                                      if (locationListProvider
                                              .selectedLocations.length <
                                          locationListProvider
                                              .certifiedLocationList.length) {
                                        locationListProvider
                                            .selectAllLocations(true);
                                      } else {
                                        locationListProvider.clearSelection();
                                      }
                                    }
                                  },
                                  // onPressed: () {
                                  //   if (_selectedScreen ==
                                  //       Screens.locationList) {
                                  //     if (locationListProvider
                                  //             .selectedLocations.length <
                                  //         locationListProvider
                                  //             .myLocationList.length) {
                                  //       locationListProvider
                                  //           .selectAllLocations(false);
                                  //     } else {
                                  //       locationListProvider.clearSelection();
                                  //     }
                                  //   } else if (_selectedScreen ==
                                  //       Screens.certifiedLocationList) {
                                  //     if (locationListProvider
                                  //             .selectedLocations.length <
                                  //         locationListProvider
                                  //             .certifiedLocationList.length) {
                                  //       locationListProvider
                                  //           .selectAllLocations(true);
                                  //     } else {
                                  //       locationListProvider.clearSelection();
                                  //     }
                                  //   }
                                  // },
                                  child: Text(
                                    _selectedScreen == Screens.locationList
                                        ? locationListProvider
                                                    .selectedLocations.length <
                                                locationListProvider
                                                    .myLocationList.length
                                            ? 'Select All'
                                            : 'Deselect All'
                                        : locationListProvider
                                                    .selectedLocations.length <
                                                locationListProvider
                                                    .certifiedLocationList
                                                    .length
                                            ? 'Select All'
                                            : 'Deselect All',
                                    style: typography.Body1.copyWith(
                                      color: AppColors.primaryMain,
                                    ),
                                  ),
                                ),
                                Spacer(),
                                // Action buttons for selected items
                                // export
                                IconButton(
                                  onPressed: () {
                                    // Implement bulk export
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title:
                                            Text('Export Selected Locations'),
                                        content: Text(
                                            'Are you sure you want to export ${locationListProvider.selectedLocations.length} locations?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              if (_selectedScreen ==
                                                  Screens.locationList) {
                                                // On export button click
                                                List<String> selectedSovIds =
                                                    Provider.of<MyLocationListProvider>(
                                                            context,
                                                            listen: false)
                                                        .myLocationList
                                                        .where((location) =>
                                                            location
                                                                .isSelected ??
                                                            false)
                                                        .map((sov) => sov.id!)
                                                        .toList();

                                                if (selectedSovIds.isNotEmpty) {
                                                  showDialog(
                                                    context: context,
                                                    builder:
                                                        (BuildContext context) {
                                                      return ExportDialog(
                                                        accountId:
                                                            widget.accountID!,
                                                        subAccountId: widget
                                                            .subAccountID!,
                                                        locationId:
                                                            selectedSovIds,
                                                      );
                                                    },
                                                  );
                                                } else {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(SnackBar(
                                                    content: Text(
                                                      LanguageService.getTranslated(
                                                          context,
                                                          "no_items_selected_error"),
                                                      style: typography.Body1,
                                                    ),
                                                  ));
                                                }
                                              } else if (_selectedScreen ==
                                                  Screens
                                                      .certifiedLocationList) {
                                                // On export button click
                                                List<String>
                                                    selectedLoactionIds =
                                                    Provider.of<MyLocationListProvider>(
                                                            context,
                                                            listen: false)
                                                        .certifiedLocationList
                                                        .where((location) =>
                                                            location
                                                                .isSelected ??
                                                            false)
                                                        .map((sov) => sov.id!)
                                                        .toList();

                                                if (selectedLoactionIds
                                                    .isNotEmpty) {
                                                  showDialog(
                                                    context: context,
                                                    builder:
                                                        (BuildContext context) {
                                                      return ExportDialog(
                                                        accountId:
                                                            widget.accountID!,
                                                        subAccountId: widget
                                                            .subAccountID!,
                                                        locationId:
                                                            selectedLoactionIds,
                                                      );
                                                    },
                                                  );
                                                } else {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(SnackBar(
                                                    content: Text(
                                                      LanguageService.getTranslated(
                                                          context,
                                                          "no_items_selected_error"),
                                                      style: typography.Body1,
                                                    ),
                                                  ));
                                                }
                                              }
                                            },
                                            child: Text('Export'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  icon: Icon(Icons.download),
                                  tooltip: 'Export Selected',
                                ),
                                IconButton(
                                    onPressed: () {
                                      // Implement bulk add to SOV
                                      locationListProvider
                                          .addTagsToSelectedLocations(
                                              context,
                                              widget.accountID!,
                                              widget.subAccountID!);
                                    },
                                    icon: Icon(Symbols.note_stack_add),
                                    tooltip: 'Add Tag'),
                                IconButton(
                                  onPressed: () async {
                                    setState(() {
                                      // Show loader
                                      locationListProvider.isLoading = true;
                                    });
                                    await locationListProvider
                                        .markAsCompleteSov(
                                      context,
                                      widget.accountID!,
                                      widget.subAccountID!,
                                      widget.sovID!,
                                    );
                                    setState(() {
                                      // Hide loader
                                      locationListProvider.isLoading = false;
                                    });
                                    // Refresh the page
                                    locationListProvider.fetchLocationList(
                                      context,
                                      locationQuery,
                                      1,
                                      40,
                                      widget.accountID,
                                      widget.subAccountID,
                                      widget.initialProcessId,
                                      widget.initialSubProcessId,
                                      widget.sovID,
                                    );
                                  },
                                  icon: locationListProvider.isLoading
                                      ? CircularProgressIndicator()
                                      : Icon(Symbols.done_all_rounded,
                                          color: Colors.green),
                                  tooltip: 'Mark as Complete',
                                ),

                                IconButton(
                                  onPressed: () {
                                    // Show delete confirmation dialog
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title:
                                            Text('Delete Selected Locations'),
                                        content: Text(
                                            'Are you sure you want to delete ${locationListProvider.selectedLocations.length} locations?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              locationListProvider
                                                  .deleteSelectedLocations(
                                                context,
                                                widget.accountID!,
                                                widget.subAccountID!,
                                              );
                                              Navigator.pop(context);
                                            },
                                            child: Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  icon: Icon(Icons.delete_outline),
                                  tooltip: 'Delete Selected',
                                ),
                              ] else ...[
                                SizedBox(
                                  width: 8,
                                ),
                                Expanded(
                                  child: Row(
                                    children: [
                                      //SizedBox(width: CustomSpacing.two),
                                      Text(
                                        "Locations",
                                        style: typography.Body1,
                                      ),
                                      /*
                                                  RatingHalfStars(
                                                    rating: widget.rating == '' ? 0 : (double.parse(widget.rating) * 5)/100,
                                                    maxRating: 5,
                                                    iconSize: 18,
                                                  ),*/
                                      Spacer(),
                                      SizedBox(width: CustomSpacing.two),
                                      selectedMainTab == 0
                                          ? Row(
                                              children: [
                                                InkWell(
                                                  onTap: () {
                                                    // Show end drawer
                                                    Scaffold.of(context)
                                                        .openEndDrawer();
                                                  },
                                                  child: Icon(
                                                    Icons.filter_list,
                                                    size: 24,
                                                  ),
                                                ),
                                                SizedBox(
                                                    width: CustomSpacing.two),
                                              ],
                                            )
                                          : SizedBox(),
                                      SizedBox(width: CustomSpacing.two),
                                      // TooltipTheme(
                                      //   data: TooltipThemeData(
                                      //     decoration: BoxDecoration(
                                      //       color: Theme.of(context)
                                      //           .colorScheme
                                      //           .surface,
                                      //       borderRadius:
                                      //           BorderRadius.circular(8),
                                      //     ),
                                      //     textStyle: TextStyle(
                                      //       color: Theme.of(context)
                                      //           .colorScheme
                                      //           .onSurface,
                                      //       fontSize: 14,
                                      //     ),
                                      //     padding: EdgeInsets.all(8),
                                      //     verticalOffset: 20,
                                      //     preferBelow: false,
                                      //   ),
                                      //   child: Tooltip(
                                      //     showDuration: Duration(seconds: 5),
                                      //     triggerMode: TooltipTriggerMode.tap,
                                      //     preferBelow: true,
                                      //     richMessage: TextSpan(
                                      //       children: [
                                      //         for (int i = 0;
                                      //             i <
                                      //                 locationListProvider
                                      //                     .summaryList.length;
                                      //             i++)
                                      //           TextSpan(
                                      //             text:
                                      //                 '• ${locationListProvider.summaryList[i]}\n',
                                      //             style: typography.Subtitle1,
                                      //           ),
                                      //       ],
                                      //       style: typography.Subtitle1,
                                      //     ),
                                      //     child: Icon(
                                      //       Icons.info,
                                      //     ),
                                      //   ),
                                      // ),
                                    ],
                                  ),
                                ),
                                // Options are Upload SOV, Add Location, Export Locations
                                PopupMenuButton(
                                  icon: Icon(Icons.more_vert),
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      child: ListTile(
                                        leading: Icon(Icons.download),
                                        title: Text('Export Locations',
                                            style: typography.Body1),
                                        onTap: () {
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return ExportDialog(
                                                accountId: widget.accountID!,
                                                subAccountId:
                                                    widget.subAccountID!,
                                                sovId: widget.sovID!,
                                                locationId: selectedMainTab == 0
                                                    ? myLocationListProvider
                                                        .myLocationList
                                                        .map((location) =>
                                                            location.id ?? "")
                                                        .toList()
                                                    : myLocationListProvider
                                                        .certifiedLocationList
                                                        .map((location) =>
                                                            location.id ?? "")
                                                        .toList(),
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ]
                            ],
                          );
                        }),
                      ),
                      SizedBox(height: CustomSpacing.two),

                      showSelectAll
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Checkbox(
                                  value: isAllSelected,
                                  onChanged: (value) {
                                    setState(() {
                                      isAllSelected = value ?? false;
                                      if (isAllSelected) {
                                        // Select all locations
                                        selectedLocations = List.from(
                                            Provider.of<LocationListProvider>(
                                                    context,
                                                    listen: false)
                                                .locationList);
                                      } else {
                                        // Deselect all locations
                                        selectedLocations.clear();
                                      }
                                    });
                                  },
                                ),
                                Text(
                                  LanguageService.getTranslated(
                                      context, "locationlist_app_select_all"),
                                  style: typography.Body1,
                                ),
                              ],
                            )
                          : /*Row(
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: 50,
                                      child: TextField(
                                        controller: _locationSearchController,
                                        onChanged: locationSearchClient,
                                        decoration: InputDecoration(
                                          hintText: LanguageService.getTranslated(
                                              context, 'locationlist_search_field_hint_text'),
                                          label: Text(
                                              LanguageService.getTranslated(
                                                  context, 'usermanagement_search_field_lable'),
                                              style: typography.Body1),
                                          hintStyle: typography.Body1,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: CustomSpacing.four),
                                  Builder(builder: (context) {
                                    return InkWell(
                                      onTap: () {
                                        // Show end drawer
                                        Scaffold.of(context).openEndDrawer();
                                      },
                                      child: Icon(
                                        Icons.filter_list,
                                        size: 28,
                                      ),
                                    );
                                  }),
                                  SizedBox(width: CustomSpacing.four),
                                ],
                              )*/
                          SizedBox(),
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHigh,
                          borderRadius:
                              BorderRadius.circular(16), // Rounded edges
                        ),
                        margin:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                        child: DefaultTabController(
                          length: 3,
                          child: Builder(builder: (context) {
                            return Column(
                              children: <Widget>[
                                // Container for the TabBar with arrows
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHigh,
                                  ),
                                  child: TabBar(
                                    controller: _mainTabController,
                                    dividerColor: Colors.transparent,
                                    indicatorPadding: EdgeInsets.symmetric(
                                        vertical: 8.0, horizontal: 8.0),
                                    indicator: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      // Makes the tab rounded
                                      color: AppColors.primaryMain.withOpacity(
                                          0.16), // Background color for the selected tab
                                    ),
                                    //indicatorColor: Colors.lightBlueAccent,
                                    labelColor: AppColors.primaryMain,
                                    isScrollable: true,
                                    tabAlignment: TabAlignment.start,
                                    unselectedLabelColor: Colors.grey,
                                    splashBorderRadius:
                                        BorderRadius.circular(8),
                                    tabs: [
                                      Tab(
                                        icon: _buildTabIcon(
                                            context,
                                            'assets/images/location_list_icon.svg',
                                            'Location List',
                                            0,
                                            18),
                                      ),
                                      Tab(
                                        icon: _buildTabIcon(
                                            context,
                                            'assets/images/overall_tab_icon.svg',
                                            'Overall Score',
                                            1,
                                            30),
                                      ),
                                      Tab(
                                        icon: _buildTabIcon(
                                            context,
                                            'assets/images/map_view_icon.svg',
                                            'Map View',
                                            2,
                                            18),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }),
                        ),
                      ),
                      SizedBox(height: CustomSpacing.two),
                      Expanded(
                        child: TabBarView(
                          // physics: NeverScrollableScrollPhysics(),
                          controller: _mainTabController,
                          children: [
                            // Location List
                            Column(
                              children: [
                                Consumer<MyLocationListProvider>(
                                  builder:
                                      (context, locationListProvider, child) {
                                    return TabBar(
                                      controller: _tabController,
                                      labelStyle: typography
                                          .BottomNavigationActiveLabel,
                                      tabs: [
                                        Tab(
                                          child: InkWell(
                                            onTap: () {
                                              _tabController?.animateTo(0);
                                            },
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Tab(
                                                  text: LanguageService
                                                      .getTranslated(context,
                                                          "locationlist_app_connections_tab_all"),
                                                ),
                                                SizedBox(
                                                    width: CustomSpacing.two),
                                                SizedBox(
                                                  height: 25,
                                                  child: Chip(
                                                    labelPadding:
                                                        EdgeInsets.all(0),
                                                    materialTapTargetSize:
                                                        MaterialTapTargetSize
                                                            .shrinkWrap,
                                                    label: Text(
                                                      locationListProvider
                                                              .isLoading
                                                          ? "0"
                                                          : locationListProvider
                                                              .locationHits
                                                              .toString(),
                                                      // locationListProvider
                                                      //     .locationHits
                                                      //     .toString(),
                                                      style: typography
                                                              .BottomNavigationActiveLabel
                                                          .copyWith(
                                                              height: -0.6),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () {
                                            if (locationListProvider
                                                .isCertifiedTabAllowed()) {
                                              _tabController?.animateTo(1);
                                            } else {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(SnackBar(
                                                content: Text(
                                                  "Please include a rating of 5 in filter to view certified locations.",
                                                  style: typography.Body1,
                                                ),
                                              ));
                                            }
                                          },
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Tab(
                                                text: LanguageService.getTranslated(
                                                    context,
                                                    "locationlist_app_connections_tab_certified"),
                                              ),
                                              SizedBox(
                                                  width: CustomSpacing.two),
                                              SizedBox(
                                                height: 25,
                                                child: Chip(
                                                  labelPadding:
                                                      EdgeInsets.all(0),
                                                  materialTapTargetSize:
                                                      MaterialTapTargetSize
                                                          .shrinkWrap,
                                                  label: Text(
                                                    locationListProvider
                                                            .isLoading
                                                        ? "0"
                                                        : locationListProvider
                                                            .certifiedLocationHits
                                                            .toString(),
                                                    // locationListProvider
                                                    //     .certifiedLocationHits
                                                    //     .toString(),
                                                    style: typography
                                                            .BottomNavigationActiveLabel
                                                        .copyWith(height: -0.6),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                SizedBox(height: CustomSpacing.four),
                                // SingleChildScrollView(
                                //   scrollDirection: Axis.horizontal,
                                //   child:

                                // ),
                                SizedBox(height: CustomSpacing.four),
                                Expanded(
                                  child: TabBarView(
                                    controller: _tabController,
                                    children: [
                                      _getLocationListAllUI(),
                                      _getLocationListCertifiedUI(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            // Overall Score
                            Consumer<MyLocationListProvider>(
                              builder: (context, locationListProvider, child) {
                                return LocationTable(
                                  accountID: widget.accountID!,
                                  subAccountID: widget.subAccountID!,
                                  initialProcessId: widget.initialProcessId,
                                  initialSubProcessId:
                                      widget.initialSubProcessId,
                                  sovId: widget.sovID!,
                                );

                                // LocationTable(
                                //     locations: locationListProvider
                                //         .myLocationList);
                              },
                            ),
                            // Map View
                            LocationListMapView(
                              accountId: widget.accountID!,
                              subAccountId: widget.subAccountID!,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
            endDrawer: Drawer(
              child: SafeArea(
                child: ListingsFilterScreen(
                  accountId: widget.accountID!,
                  subAccountId: widget.subAccountID!,
                  sovId: widget.sovID!,
                  searchQuery: locationQuery,
                  showGeoRatings: selectedMainTab == 0 && selectedTab != 1,
                  initialProcessId: widget.initialProcessId,
                  initialSubProcessId: widget.initialSubProcessId,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabIcon(BuildContext context, String iconPath, String label,
      int tabIndex, double iconSize) {
    // Check if TabController exists and whether this tab is selected
    bool isSelected = _mainTabController?.index == tabIndex;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0),
      // Adjust padding to control spacing
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: 12),
          // Add space between icon and label
          label == "Location List"
              ? Icon(Remix.file_list_3_line)
              : label == "Map View"
                  ? Icon(Remix.road_map_line)
                  : Icon(Remix.bar_chart_box_ai_line),
          SizedBox(width: 8),
          // Add space between icon and label
          if (isSelected) ...[
            SizedBox(width: 4), // Reduce the space between icon and label
            Text(
              label,
              style: TextStyle(
                color: AppColors.primaryMain,
                fontSize: 14,
              ),
            ),
            SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _getLiveUI() {
    var typography = CustomTypography(context);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('sov')
          .doc(widget.sovID)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Display a loading indicator while waiting for data
          return SizedBox(); // Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          // Handle error case
          return SizedBox();
        }

        if (snapshot.hasData && snapshot.data != null) {
          // Check if 'heatmap_status' field exists
          var data = snapshot.data!.data();
          var heatmapStatus = data != null && data.containsKey('heatmap_status')
              ? data['heatmap_status']
              : null;

          if (heatmapStatus != null) {
            print('Heatmap status: $heatmapStatus');
            return heatmapStatus.toString().toLowerCase() == 'initiated'
                ? Container(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => ProcessMonitoringScreen(
                                        accountId: widget.accountID,
                                        subAccountId: widget.subAccountID,
                                      )),
                            );
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0),
                                child: Row(
                                  children: [
                                    Lottie.asset(
                                      'assets/lottie/loading.json',
                                      // Lottie file for 'in-progress' animation
                                      width: 24,
                                      height: 24,
                                    ),
                                    SizedBox(width: 8.0),
                                    Text(
                                      'Generating Heatmap',
                                      style: typography.Body2.copyWith(
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: CustomSpacing.two),
                      ],
                    ),
                  )
                : SizedBox();
          } else {
            print("Field 'heatmap_status' does not exist in the document.");
          }
        }

        // Return an empty widget if no data is available or the field is missing
        return SizedBox();
      },
    );
  }

  _getLocationListAllUI() {
    var typography = CustomTypography(context);
    return Consumer<MyLocationListProvider>(
      builder: (context, locationListProvider, child) {
        return locationListProvider.isLoading
            ? Center(
                child: Container(
                child: CircularProgressIndicator(),
              ))
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Column(
                  children: [
                    // Filter chips row
                    Row(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                if (locationListProvider.countries.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4.0),
                                    child: Chip(
                                      label: Text(
                                          "Country: ${locationListProvider.countries.join(', ')}"),
                                      onDeleted: () {
                                        locationListProvider
                                            .clearCountryFilter();
                                        locationListProvider.fetchLocationList(
                                          context,
                                          locationQuery,
                                          1,
                                          40,
                                          widget.accountID,
                                          widget.subAccountID,
                                          widget.initialProcessId,
                                          widget.initialSubProcessId,
                                          widget.sovID,
                                        );
                                      },
                                    ),
                                  ),
                                if (locationListProvider
                                    .certifications.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4.0),
                                    child: Chip(
                                      label: Text(
                                          "Certifications: ${locationListProvider.certifications.join(', ')}"),
                                      onDeleted: () {
                                        locationListProvider
                                            .clearCertificationsFilter();
                                        locationListProvider.fetchLocationList(
                                          context,
                                          locationQuery,
                                          1,
                                          40,
                                          widget.accountID,
                                          widget.subAccountID,
                                          widget.initialProcessId,
                                          widget.initialSubProcessId,
                                          widget.sovID,
                                        );
                                      },
                                    ),
                                  ),
                                if (locationListProvider
                                    .hazardRatings.isNotEmpty)
                                  ...locationListProvider.hazardRatings.keys
                                      .map((hazard) => Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 4.0),
                                            child: Chip(
                                              label: Row(
                                                children: [
                                                  const SizedBox(width: 8),
                                                  if (locationListProvider
                                                      .hazardRatings[hazard]!
                                                      .isEmpty)
                                                    Text('All')
                                                  else
                                                    Row(
                                                      children:
                                                          locationListProvider
                                                              .hazardRatings[
                                                                  hazard]!
                                                              .map(
                                                                  (rating) =>
                                                                      Padding(
                                                                        padding: const EdgeInsets
                                                                            .only(
                                                                            right:
                                                                                4.0),
                                                                        child:
                                                                            CircleAvatar(
                                                                          radius:
                                                                              10,
                                                                          backgroundColor:
                                                                              _getRatingColor(rating),
                                                                          child:
                                                                              Text(
                                                                            '$rating',
                                                                            style:
                                                                                const TextStyle(color: Colors.white, fontSize: 12),
                                                                          ),
                                                                        ),
                                                                      ))
                                                              .toList(),
                                                    ),
                                                ],
                                              ),
                                              onDeleted: () {
                                                locationListProvider
                                                    .clearHazardFilter(hazard);
                                                locationListProvider
                                                    .fetchLocationList(
                                                  context,
                                                  locationQuery,
                                                  1,
                                                  40,
                                                  widget.accountID,
                                                  widget.subAccountID,
                                                  widget.initialProcessId,
                                                  widget.initialSubProcessId,
                                                  '',
                                                );
                                              },
                                            ),
                                          )),
                                if (locationListProvider.rating.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4.0),
                                    child: Chip(
                                      label: Text(
                                          "Ratings: ${locationListProvider.rating.join(', ')}"),
                                      onDeleted: () {
                                        locationListProvider
                                            .clearRatingsFilter();
                                        locationListProvider.fetchLocationList(
                                          context,
                                          locationQuery,
                                          1,
                                          40,
                                          widget.accountID,
                                          widget.subAccountID,
                                          widget.initialProcessId,
                                          widget.initialSubProcessId,
                                          widget.sovID,
                                        );
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        if (locationListProvider.hasAnyFilterApplied())
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: TextButton(
                              onPressed: () {
                                locationListProvider.clearAllFilters();
                                locationListProvider.fetchLocationList(
                                  context,
                                  locationQuery,
                                  1,
                                  40,
                                  widget.accountID,
                                  widget.subAccountID,
                                  widget.initialProcessId,
                                  widget.initialSubProcessId,
                                  '',
                                );
                              },
                              child: const Text(
                                'Clear All',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ),
                      ],
                    ),
                    // Main scrollable content

                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async {
                          // Reset to first page and refresh data
                          locationListProvider.page = 1;
                          await locationListProvider.fetchLocationList(
                            context,
                            locationQuery,
                            1,
                            40,
                            widget.accountID,
                            widget.subAccountID,
                            widget.initialProcessId,
                            widget.initialSubProcessId,
                            widget.sovID,
                          );
                        },
                        child: CustomScrollView(
                          slivers: [
                            // Charts section
                            SliverToBoxAdapter(
                              child: Container(
                                height: 430,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Consumer<MyLocationListProvider>(
                                        builder: (context, provider, _) {
                                          final pdValues = provider
                                              .grapDataProfile?.pdValues;

                                          if (pdValues == null) {
                                            return const Center(
                                              child: Text(
                                                "No data available",
                                                style: TextStyle(
                                                    color: Colors.white70),
                                              ),
                                            );
                                          }

                                          // ✅ Choose dataset based on dropdown selection
                                          final sourceData = selectedView ==
                                                  "Overall Score"
                                              ? pdValues.byOverallScore ?? {}
                                              : pdValues.byGeocodeScore ?? {};

                                          if (sourceData.isEmpty) {
                                            return const Center(
                                              child: Text(
                                                "No data available",
                                                style: TextStyle(
                                                    color: Colors.white70),
                                              ),
                                            );
                                          }

                                          final chartEntries =
                                              sourceData.entries.map((entry) {
                                            final data = entry.value;
                                            final label = selectedView ==
                                                    "By Overall Score"
                                                ? "Score ${data.overallScore}"
                                                : "Geocode ${entry.key}";
                                            return {
                                              'label': label,
                                              'value': data.totalPdValue ?? 0.0,
                                              'pct': data.pctOfTotal ?? 0.0,
                                            };
                                          }).toList();

                                          double total = chartEntries.fold(
                                              0.0,
                                              (a, e) =>
                                                  a + (e['value'] as double));

                                          final sections = chartEntries
                                              .asMap()
                                              .entries
                                              .map((entry) {
                                            final index = entry.key;
                                            final value =
                                                entry.value['value'] as double;
                                            final percent = total > 0
                                                ? (value / total) * 100
                                                : 0;
                                            final selected =
                                                index == touchedIndex;

                                            return PieChartSectionData(
                                              color: _getPieColor(percent),
                                              value: value,
                                              radius: selected ? 120 : 100,
                                              title:
                                                  "${percent.toStringAsFixed(1)}%",
                                              titleStyle: TextStyle(
                                                fontSize: selected ? 14 : 12,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            );
                                          }).toList();

                                          return Container(
                                            margin: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF111111),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                  color: Colors.white10),
                                            ),
                                            padding: const EdgeInsets.all(16),
                                            child: Column(
                                              // crossAxisAlignment:
                                              //     CrossAxisAlignment.center,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    const Text(
                                                      "Weighted Distribution (TPV)",
                                                      style: TextStyle(
                                                        color:
                                                            Color(0xFF90CAF9),
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                    SizedBox(width: 5),
                                                    Container(
                                                      height: 45,
                                                      constraints:
                                                          BoxConstraints(
                                                              minWidth: 130),
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                        border: Border.all(
                                                            color:
                                                                Colors.white24),
                                                        color: Colors.black87,
                                                      ),
                                                      child:
                                                          DropdownButtonHideUnderline(
                                                        child: DropdownButton2<
                                                            String>(
                                                          isExpanded: true,
                                                          value: selectedMetric,
                                                          items: const [
                                                            DropdownMenuItem(
                                                              value: 'PD Value',
                                                              child: Text(
                                                                  'PD Value'),
                                                            ),
                                                          ],
                                                          onChanged: (value) {
                                                            if (value != null) {
                                                              setState(() {
                                                                selectedMetric =
                                                                    value;
                                                              });
                                                            }
                                                          },
                                                          buttonStyleData:
                                                              ButtonStyleData(
                                                            height: 45,
                                                            width: 105,
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        12),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: Colors
                                                                  .transparent,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8),
                                                            ),
                                                          ),
                                                          iconStyleData:
                                                              const IconStyleData(
                                                            icon: Icon(
                                                                Icons
                                                                    .arrow_drop_down,
                                                                color: Colors
                                                                    .white),
                                                          ),
                                                          dropdownStyleData:
                                                              DropdownStyleData(
                                                            maxHeight: 200,
                                                            width: 120,
                                                            decoration:
                                                                BoxDecoration(
                                                              color: Colors
                                                                  .black87,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8),
                                                            ),
                                                            offset:
                                                                const Offset(
                                                                    0, 0),
                                                          ),
                                                          menuItemStyleData:
                                                              const MenuItemStyleData(
                                                            height: 40,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Container(
                                                  height: 40,
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                    border: Border.all(
                                                        color: Colors.white24),
                                                    color: Colors.black87,
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.start,
                                                    children: [
                                                      ToggleButtons(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                        borderColor:
                                                            Colors.white24,
                                                        selectedBorderColor:
                                                            AppColors
                                                                .primaryMain,
                                                        fillColor: AppColors
                                                            .primaryMain
                                                            .withOpacity(0.16),
                                                        selectedColor: AppColors
                                                            .primaryMain,
                                                        color: Colors.white,
                                                        constraints:
                                                            BoxConstraints(
                                                                minHeight: 36,
                                                                minWidth: 110),
                                                        isSelected: [
                                                          selectedView ==
                                                              "Overall Score",
                                                          selectedView ==
                                                              "Geocoding",
                                                        ],
                                                        onPressed: (index) {
                                                          setState(() {
                                                            selectedView = index ==
                                                                    0
                                                                ? "Overall Score"
                                                                : "Geocoding";
                                                          });
                                                        },
                                                        children: const [
                                                          Text("Overall Score"),
                                                          Text("Geocoding"),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(height: 25),

                                                // ===== Pie Chart =====
                                                Center(
                                                  child: Column(
                                                    children: [
                                                      SizedBox(
                                                        width: 170,
                                                        height: 170,
                                                        child: PieChart(
                                                          PieChartData(
                                                            centerSpaceRadius:
                                                                0,
                                                            sections: sections,
                                                            pieTouchData:
                                                                PieTouchData(
                                                              touchCallback:
                                                                  (event, res) {
                                                                setState(() {
                                                                  // ✅ Detect actual interaction
                                                                  if (!event
                                                                          .isInterestedForInteractions ||
                                                                      res?.touchedSection ==
                                                                          null) {
                                                                    return;
                                                                  }

                                                                  final index = res!
                                                                      .touchedSection!
                                                                      .touchedSectionIndex;

                                                                  // ✅ Toggle info card display on same slice click
                                                                  if (touchedIndex ==
                                                                      index) {
                                                                    touchedIndex =
                                                                        -1; // Hide
                                                                  } else {
                                                                    touchedIndex =
                                                                        index; // Show
                                                                  }
                                                                });
                                                              },
                                                            ),
                                                          ),
                                                        ),
                                                      ),

                                                      const SizedBox(
                                                          height: 33),

                                                      // ✅ Show info card below the pie when a slice is selected
                                                      AnimatedSwitcher(
                                                        duration:
                                                            const Duration(
                                                                milliseconds:
                                                                    250),
                                                        child: (touchedIndex !=
                                                                    null &&
                                                                touchedIndex! >=
                                                                    0 &&
                                                                touchedIndex! <
                                                                    chartEntries
                                                                        .length)
                                                            ? _buildInfoCard(
                                                                chartEntries[
                                                                    touchedIndex!])
                                                            : const SizedBox
                                                                .shrink(),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),

                                      // Bar chart - scrollable
                                      Container(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.9,
                                        child: Consumer<MyLocationListProvider>(
                                          builder: (context,
                                              locationListProvider, child) {
                                            if (selectedView == 'Geocoding') {
                                              final geocodingData =
                                                  locationListProvider
                                                      .grapDataProfile
                                                      ?.geocodeCounts;

                                              if (geocodingData == null) {
                                                return const Center(
                                                    child: Text(
                                                        'No geocoding data'));
                                              }

                                              // Convert to usable map
                                              final Map<String, dynamic>
                                                  geocodingMap =
                                                  geocodingData.toJson();

                                              // Sort descending by count
                                              final List<Map<String, dynamic>>
                                                  dataList = geocodingMap
                                                      .entries
                                                      .map((e) => {
                                                            'name':
                                                                'Geocode ${e.key}',
                                                            'count':
                                                                (e.value as num)
                                                                    .toDouble(),
                                                          })
                                                      .toList()
                                                    ..sort((a, b) => (b['count']
                                                            as double)
                                                        .compareTo(a['count']
                                                            as double));

                                              if (dataList.isEmpty) {
                                                return const Center(
                                                    child:
                                                        Text('No data found'));
                                              }

                                              // ✅ Get min, max, total
                                              final values = dataList
                                                  .map((e) =>
                                                      e['count'] as double)
                                                  .toList();
                                              final minValue = values.reduce(
                                                  (a, b) => a < b ? a : b);
                                              final maxValue = values.reduce(
                                                  (a, b) => a > b ? a : b);
                                              final total = values.fold<double>(
                                                  0.0, (sum, v) => sum + v);

                                              return Container(
                                                height: dataList.isEmpty
                                                    ? 160
                                                    : 400,
                                                margin:
                                                    const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color:
                                                      const Color(0xFF111111),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                      color: Colors.white10),
                                                ),
                                                padding:
                                                    const EdgeInsets.all(16),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            "Critical Missing Parameters (Geocoding)",
                                                            maxLines: 2,
                                                            style:
                                                                const TextStyle(
                                                              color: Color(
                                                                  0xFF90CAF9),
                                                              fontSize: 14,
                                                            ),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                        SizedBox(width: 12),
                                                        Container(
                                                          decoration:
                                                              BoxDecoration(
                                                            color:
                                                                Colors.black87,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12),
                                                            border: Border.all(
                                                                color: Colors
                                                                    .white24),
                                                          ),
                                                          child:
                                                              DropdownButtonHideUnderline(
                                                            child:
                                                                DropdownButton2<
                                                                    String>(
                                                              value:
                                                                  selectedView,
                                                              style: const TextStyle(
                                                                  color: Colors
                                                                      .white),
                                                              items: const [
                                                                DropdownMenuItem(
                                                                  value:
                                                                      'Geocoding',
                                                                  child: Text(
                                                                      'Geocoding'),
                                                                ),
                                                                DropdownMenuItem(
                                                                  value:
                                                                      'Parameter',
                                                                  child: Text(
                                                                      'Parameter'),
                                                                ),
                                                              ],
                                                              onChanged:
                                                                  (value) {
                                                                if (value !=
                                                                    null) {
                                                                  setState(() {
                                                                    selectedView =
                                                                        value;
                                                                  });
                                                                }
                                                              },
                                                              buttonStyleData:
                                                                  ButtonStyleData(
                                                                height: 45,
                                                                width: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width /
                                                                    3.2,
                                                                padding: const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        11),
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: Colors
                                                                      .black87,
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              8),
                                                                  border: Border.all(
                                                                      color: Colors
                                                                          .white24),
                                                                ),
                                                              ),
                                                              iconStyleData:
                                                                  const IconStyleData(
                                                                icon: Icon(
                                                                    Icons
                                                                        .arrow_drop_down,
                                                                    color: Colors
                                                                        .white),
                                                              ),
                                                              dropdownStyleData:
                                                                  DropdownStyleData(
                                                                maxHeight: 200,
                                                                width: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width /
                                                                    3.2,
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: Colors
                                                                      .black87,
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              8),
                                                                ),
                                                              ),
                                                              menuItemStyleData:
                                                                  const MenuItemStyleData(
                                                                height: 40,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 5),
                                                    Expanded(
                                                      child: ListView.builder(
                                                        physics:
                                                            const NeverScrollableScrollPhysics(),
                                                        shrinkWrap: true,
                                                        itemCount:
                                                            dataList.length,
                                                        itemBuilder:
                                                            (context, index) {
                                                          final item =
                                                              dataList[index];
                                                          final name =
                                                              item['name']
                                                                  as String;
                                                          final value =
                                                              item['count']
                                                                  as double;
                                                          final percent = total >
                                                                  0
                                                              ? (value /
                                                                      total) *
                                                                  100
                                                              : 0.0;

                                                          final color =
                                                              getColorByValue(
                                                                  value,
                                                                  minValue,
                                                                  maxValue,
                                                                  dataList
                                                                      .length);

                                                          return _buildBarItem1(
                                                              name,
                                                              value,
                                                              percent,
                                                              maxValue,
                                                              color);
                                                        },
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            } else {
                                              final parameterData =
                                                  locationListProvider
                                                      .grapDataProfile
                                                      ?.globalSovPerilCounts;

                                              // Convert the parameter data to usable format
                                              final Map<String, dynamic>
                                                  parameterMap =
                                                  parameterData?.toJson() ?? {};

                                              // Sort by missing descending so highest is first
                                              final List<Map<String, dynamic>>
                                                  dataList =
                                                  parameterMap.entries.map((e) {
                                                final perilData = e.value is Map
                                                    ? Map<String, dynamic>.from(
                                                        e.value)
                                                    : {};
                                                final total =
                                                    (perilData['total'] as num?)
                                                            ?.toDouble() ??
                                                        0.0;
                                                final completed =
                                                    (perilData['completed_data']
                                                                as num?)
                                                            ?.toDouble() ??
                                                        0.0;
                                                final missing =
                                                    total - completed;

                                                return {
                                                  'name': e.key,
                                                  'missing': missing,
                                                  'total': total,
                                                  'completed_data': completed,
                                                };
                                              }).toList()
                                                    ..sort((a, b) =>
                                                        (b['missing'] as double)
                                                            .compareTo(
                                                                a['missing']
                                                                    as double));

                                              final maxValue =
                                                  dataList.fold<double>(
                                                0.0,
                                                (prev, e) => e['missing'] > prev
                                                    ? e['missing']
                                                    : prev,
                                              );

                                              final total =
                                                  dataList.fold<double>(
                                                0.0,
                                                (sum, e) =>
                                                    sum +
                                                    (e['missing'] as double),
                                              );

                                              return Container(
                                                height: dataList.isEmpty
                                                    ? 160
                                                    : 400,
                                                margin:
                                                    const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color:
                                                      const Color(0xFF111111),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                      color: Colors.white10),
                                                ),
                                                padding:
                                                    const EdgeInsets.all(16),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            "Critical Missing Parameters (Parameter)",
                                                            maxLines: 2,
                                                            style:
                                                                const TextStyle(
                                                              color: Color(
                                                                  0xFF90CAF9),
                                                              fontSize: 14,
                                                            ),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            width: 12),
                                                        Container(
                                                          decoration:
                                                              BoxDecoration(
                                                            color:
                                                                Colors.black87,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12),
                                                            border: Border.all(
                                                                color: Colors
                                                                    .white24),
                                                          ),
                                                          child:
                                                              DropdownButtonHideUnderline(
                                                            child:
                                                                DropdownButton2<
                                                                    String>(
                                                              value:
                                                                  selectedView1,
                                                              style: const TextStyle(
                                                                  color: Colors
                                                                      .white),
                                                              items: const [
                                                                DropdownMenuItem(
                                                                  value:
                                                                      'Geocoding',
                                                                  child: Text(
                                                                      'Geocoding',
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis),
                                                                ),
                                                                DropdownMenuItem(
                                                                  value:
                                                                      'Parameter',
                                                                  child: Text(
                                                                      'Parameter',
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis),
                                                                ),
                                                              ],
                                                              onChanged:
                                                                  (value) {
                                                                if (value !=
                                                                    null) {
                                                                  setState(() {
                                                                    selectedView =
                                                                        value;
                                                                  });
                                                                }
                                                              },
                                                              buttonStyleData:
                                                                  ButtonStyleData(
                                                                height: 45,
                                                                width: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width /
                                                                    3.2,
                                                                padding: const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        11),
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: Colors
                                                                      .black87,
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              8),
                                                                  border: Border.all(
                                                                      color: Colors
                                                                          .white24),
                                                                ),
                                                              ),
                                                              iconStyleData:
                                                                  const IconStyleData(
                                                                icon: Icon(
                                                                    Icons
                                                                        .arrow_drop_down,
                                                                    color: Colors
                                                                        .white),
                                                              ),
                                                              dropdownStyleData:
                                                                  DropdownStyleData(
                                                                maxHeight: 200,
                                                                width: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width /
                                                                    3.2,
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: Colors
                                                                      .black87,
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              8),
                                                                ),
                                                              ),
                                                              menuItemStyleData:
                                                                  const MenuItemStyleData(
                                                                height: 40,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 10),
                                                    Expanded(
                                                      child: dataList.isEmpty
                                                          ? Container(
                                                              alignment:
                                                                  Alignment
                                                                      .center,
                                                              child: const Text(
                                                                'No data found',
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .white70,
                                                                    fontSize:
                                                                        14),
                                                              ),
                                                            )
                                                          : ListView.builder(
                                                              physics:
                                                                  const NeverScrollableScrollPhysics(),
                                                              shrinkWrap: true,
                                                              itemCount:
                                                                  parameterMap
                                                                      .length,
                                                              itemBuilder:
                                                                  (context,
                                                                      index) {
                                                                final item =
                                                                    dataList[
                                                                        index];
                                                                final name =
                                                                    item['name']
                                                                        as String;
                                                                final value =
                                                                    item['completed_data']
                                                                        as double;
                                                                final percent =
                                                                    total > 0
                                                                        ? (value /
                                                                                total) *
                                                                            100
                                                                        : 0.0;
                                                                return _buildBarItem(
                                                                    name,
                                                                    value,
                                                                    percent,
                                                                    maxValue);
                                                              },
                                                            ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  if (locationListProvider.isLoading) {
                                    return const Column(
                                      children: [
                                        SizedBox(height: 100),
                                        Center(
                                            child: CircularProgressIndicator()),
                                      ],
                                    );
                                  }
                                  if (locationListProvider
                                      .myLocationList.isEmpty) {
                                    return Center(
                                      child: Text(
                                        LanguageService.getTranslated(context,
                                            "location_list_app_no_accounts_text"),
                                        style: typography.Body1,
                                      ),
                                    );
                                  }

                                  if (index ==
                                      locationListProvider
                                          .myLocationList.length) {
                                    if (locationListProvider
                                        .isNextPageLoading) {
                                      return const Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Center(
                                            child: CircularProgressIndicator()),
                                      );
                                    } else if (locationListProvider.page >=
                                            locationListProvider.totalPages &&
                                        locationListProvider
                                            .myLocationList.isNotEmpty) {
                                      return Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Center(
                                          child: Text(
                                            LanguageService.getTranslated(
                                                context,
                                                "location_list_end_of_list"),
                                            style: typography.Body1,
                                          ),
                                        ),
                                      );
                                    } else {
                                      locationListProvider.page =
                                          locationListProvider.page + 1;
                                      locationListProvider.fetchLocationList(
                                        context,
                                        locationQuery,
                                        locationListProvider.page,
                                        1000,
                                        widget.accountID,
                                        widget.subAccountID,
                                        widget.initialProcessId,
                                        widget.initialSubProcessId,
                                        '',
                                      );
                                      return const SizedBox();
                                    }
                                  }

                                  return MyLocationCard(
                                    campusId: locationListProvider
                                            .myLocationList[index]
                                            .finalAddress
                                            ?.campusId ??
                                        '',
                                    imageUrl: locationListProvider
                                                .myLocationList[index]
                                                .screenshots
                                                ?.isNotEmpty ==
                                            true
                                        ? locationListProvider
                                                .myLocationList[index]
                                                .screenshots![0]
                                                .imageUrl ??
                                            ''
                                        : '',
                                    index: index,
                                    accountId: widget.accountID,
                                    subAccountId: widget.subAccountID,
                                    sovId: widget.sovID,
                                    sovName: widget.sovName,
                                    subAccountName: widget.subAccountName,
                                    locationId: locationListProvider
                                            .myLocationList[index].id ??
                                        '',
                                    accountName: locationListProvider
                                            .myLocationList[index]
                                            .finalAddress
                                            ?.accountName ??
                                        '',
                                    ownerName: locationListProvider
                                            .myLocationList[index]
                                            .finalAddress
                                            ?.ownerName ??
                                        '',
                                    companyName: locationListProvider
                                            .myLocationList[index]
                                            .finalAddress
                                            ?.companyName ??
                                        '',
                                    address: locationListProvider
                                            .myLocationList[index]
                                            .finalAddress
                                            ?.address ??
                                        '',
                                    percentage: double.parse(
                                        locationListProvider
                                                .myLocationList[index]
                                                .finalAddress
                                                ?.percent ??
                                            '0'),
                                    geocodingScore: locationListProvider
                                            .myLocationList[index]
                                            .finalAddress
                                            ?.score ??
                                        0,
                                    riskScore: int.parse(locationListProvider
                                        .myLocationList[index].overallScore
                                        .toString()),
                                    dataCompletenessScore: locationListProvider
                                            .myLocationList[index]
                                            .dataCompleteness
                                            ?.scorePd ??
                                        1,
                                    isAutoCertified: true,
                                    tags: (locationListProvider
                                            .myLocationList[index]?.tags ??
                                        []),
                                    onDelete: (locationId) {
                                      showDeleteConfirmationDialog(
                                        context,
                                        () async {
                                          await Provider.of<
                                                      MyLocationListProvider>(
                                                  context,
                                                  listen: false)
                                              .deleteLocations(
                                                  context,
                                                  widget.accountID!,
                                                  widget.subAccountID!,
                                                  widget.sovID!,
                                                  [locationId]);
                                          Provider.of<MyLocationListProvider>(
                                                  context,
                                                  listen: false)
                                              .fetchLocationList(
                                            context,
                                            locationQuery,
                                            1,
                                            1000,
                                            widget.accountID,
                                            widget.subAccountID,
                                            widget.initialProcessId,
                                            widget.initialSubProcessId,
                                            widget.sovID,
                                          );
                                          Navigator.of(context).pop();
                                        },
                                        [locationId],
                                      );
                                    },
                                    onAddToSOV: null,
                                    onAddTag: (locationId) {
                                      locationListProvider
                                          .addTagsToSelectedLocations(
                                              context,
                                              widget.accountID!,
                                              widget.subAccountID!,
                                              locationId);
                                    },
                                    getData: () {
                                      locationListProvider.fetchLocationList(
                                        context,
                                        locationQuery,
                                        1,
                                        1000,
                                        widget.accountID,
                                        widget.subAccountID,
                                        widget.initialProcessId,
                                        widget.initialSubProcessId,
                                        widget.sovID,
                                      );
                                    },
                                    lat: locationListProvider
                                            .myLocationList[index]
                                            .finalAddress
                                            ?.latitude
                                            ?.toString() ??
                                        "",
                                    long: locationListProvider
                                            .myLocationList[index]
                                            .finalAddress
                                            ?.longitude
                                            ?.toString() ??
                                        "",
                                    overallScore: locationListProvider
                                            .myLocationList[index].overallScore
                                            ?.toString() ??
                                        "0",
                                    hazardProcess: true,
                                  );
                                },
                                childCount:
                                    locationListProvider.myLocationList.isEmpty
                                        ? 1
                                        : locationListProvider
                                                .myLocationList.length +
                                            1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
      },
    );
  }

  _getLocationListCertifiedUI() {
    var typography = CustomTypography(context);
    return Consumer<MyLocationListProvider>(
      builder: (context, locationListProvider, child) {
        return locationListProvider.isLoading
            ? Center(
                child: Container(
                child: CircularProgressIndicator(),
              ))
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Column(
                  children: [
                    // Filter chips row
                    Row(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                if (locationListProvider.countries.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4.0),
                                    child: Chip(
                                      label: Text(
                                          "Country: ${locationListProvider.countries.join(', ')}"),
                                      onDeleted: () {
                                        locationListProvider
                                            .clearCountryFilter();
                                        locationListProvider
                                            .fetchCertifiedLocationList(
                                          context,
                                          locationQuery,
                                          1,
                                          40,
                                          widget.accountID,
                                          widget.subAccountID,
                                          widget.initialProcessId,
                                          widget.initialSubProcessId,
                                        );
                                      },
                                    ),
                                  ),
                                if (locationListProvider
                                    .certifications.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4.0),
                                    child: Chip(
                                      label: Text(
                                          "Certifications: ${locationListProvider.certifications.join(', ')}"),
                                      onDeleted: () {
                                        locationListProvider
                                            .clearCertificationsFilter();
                                        locationListProvider
                                            .fetchCertifiedLocationList(
                                          context,
                                          locationQuery,
                                          1,
                                          40,
                                          widget.accountID,
                                          widget.subAccountID,
                                          widget.initialProcessId,
                                          widget.initialSubProcessId,
                                        );
                                      },
                                    ),
                                  ),
                                if (locationListProvider
                                    .hazardRatings.isNotEmpty)
                                  ...locationListProvider.hazardRatings.keys
                                      .map((hazard) => Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 4.0),
                                            child: Chip(
                                              label: Row(
                                                children: [
                                                  const SizedBox(width: 8),
                                                  if (locationListProvider
                                                      .hazardRatings[hazard]!
                                                      .isEmpty)
                                                    Text('All')
                                                  else
                                                    Row(
                                                      children:
                                                          locationListProvider
                                                              .hazardRatings[
                                                                  hazard]!
                                                              .map(
                                                                  (rating) =>
                                                                      Padding(
                                                                        padding: const EdgeInsets
                                                                            .only(
                                                                            right:
                                                                                4.0),
                                                                        child:
                                                                            CircleAvatar(
                                                                          radius:
                                                                              10,
                                                                          backgroundColor:
                                                                              _getRatingColor(rating),
                                                                          child:
                                                                              Text(
                                                                            '$rating',
                                                                            style:
                                                                                const TextStyle(color: Colors.white, fontSize: 12),
                                                                          ),
                                                                        ),
                                                                      ))
                                                              .toList(),
                                                    ),
                                                ],
                                              ),
                                              onDeleted: () {
                                                locationListProvider
                                                    .clearHazardFilter(hazard);
                                                locationListProvider
                                                    .fetchCertifiedLocationList(
                                                  context,
                                                  locationQuery,
                                                  1,
                                                  40,
                                                  widget.accountID,
                                                  widget.subAccountID,
                                                  widget.initialProcessId,
                                                  widget.initialSubProcessId,
                                                );
                                              },
                                            ),
                                          )),
                                if (locationListProvider.rating.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4.0),
                                    child: Chip(
                                      label: Text(
                                          "Ratings: ${locationListProvider.rating.join(', ')}"),
                                      onDeleted: () {
                                        locationListProvider
                                            .clearRatingsFilter();
                                        locationListProvider
                                            .fetchCertifiedLocationList(
                                          context,
                                          locationQuery,
                                          1,
                                          40,
                                          widget.accountID,
                                          widget.subAccountID,
                                          widget.initialProcessId,
                                          widget.initialSubProcessId,
                                        );
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        if (locationListProvider.hasAnyFilterApplied())
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: TextButton(
                              onPressed: () {
                                locationListProvider.clearAllFilters();
                                locationListProvider.fetchCertifiedLocationList(
                                  context,
                                  locationQuery,
                                  1,
                                  40,
                                  widget.accountID,
                                  widget.subAccountID,
                                  widget.initialProcessId,
                                  widget.initialSubProcessId,
                                );
                              },
                              child: const Text(
                                'Clear All',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ),
                      ],
                    ),
                    // Main scrollable content
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async {
                          locationListProvider.certifiedPage = 1;
                          await locationListProvider.fetchCertifiedLocationList(
                            context,
                            locationQuery,
                            1,
                            40,
                            widget.accountID,
                            widget.subAccountID,
                            widget.initialProcessId,
                            widget.initialSubProcessId,
                          );
                        },
                        child: CustomScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: [
                            // Charts section

                            SliverToBoxAdapter(
                              child: Container(
                                height: 420,
                                // Set a fixed height for the scrollable row
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Consumer<MyLocationListProvider>(
                                        builder: (context, provider, _) {
                                          final pdValues = provider
                                              .grapDataProfile?.pdValues;

                                          if (pdValues == null) {
                                            return const Center(
                                              child: Text(
                                                "No data available",
                                                style: TextStyle(
                                                    color: Colors.white70),
                                              ),
                                            );
                                          }

                                          // ✅ Choose dataset based on dropdown selection
                                          final sourceData = selectedView ==
                                                  "Overall Score"
                                              ? pdValues.byOverallScore ?? {}
                                              : pdValues.byGeocodeScore ?? {};

                                          if (sourceData.isEmpty) {
                                            return const Center(
                                              child: Text(
                                                "No data available",
                                                style: TextStyle(
                                                    color: Colors.white70),
                                              ),
                                            );
                                          }

                                          final chartEntries =
                                              sourceData.entries.map((entry) {
                                            final data = entry.value;
                                            final label = selectedView ==
                                                    "By Overall Score"
                                                ? "Score ${data.overallScore}"
                                                : "Geocode ${entry.key}";
                                            return {
                                              'label': label,
                                              'value': data.totalPdValue ?? 0.0,
                                              'pct': data.pctOfTotal ?? 0.0,
                                            };
                                          }).toList();

                                          double total = chartEntries.fold(
                                              0.0,
                                              (a, e) =>
                                                  a + (e['value'] as double));

                                          final sections = chartEntries
                                              .asMap()
                                              .entries
                                              .map((entry) {
                                            final index = entry.key;
                                            final value =
                                                entry.value['value'] as double;
                                            final percent = total > 0
                                                ? (value / total) * 100
                                                : 0;
                                            final selected =
                                                index == touchedIndex;

                                            return PieChartSectionData(
                                              color: _getPieColor(percent),
                                              value: value,
                                              radius: selected ? 120 : 100,
                                              title:
                                                  "${percent.toStringAsFixed(1)}%",
                                              titleStyle: TextStyle(
                                                fontSize: selected ? 14 : 12,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            );
                                          }).toList();

                                          return Container(
                                            margin: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF111111),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                  color: Colors.white10),
                                            ),
                                            padding: const EdgeInsets.all(16),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    const Text(
                                                      "Weighted Distribution (TPV)",
                                                      style: TextStyle(
                                                        color:
                                                            Color(0xFF90CAF9),
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                    SizedBox(width: 5),
                                                    Container(
                                                      height: 45,
                                                      constraints:
                                                          BoxConstraints(
                                                              minWidth: 130),
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                        border: Border.all(
                                                            color:
                                                                Colors.white24),
                                                        color: Colors.black87,
                                                      ),
                                                      child:
                                                          DropdownButtonHideUnderline(
                                                        child: DropdownButton2<
                                                            String>(
                                                          isExpanded: true,
                                                          value: selectedMetric,
                                                          items: const [
                                                            DropdownMenuItem(
                                                              value: 'PD Value',
                                                              child: Text(
                                                                  'PD Value'),
                                                            ),
                                                          ],
                                                          onChanged: (value) {
                                                            if (value != null) {
                                                              setState(() {
                                                                selectedMetric =
                                                                    value;
                                                              });
                                                            }
                                                          },
                                                          buttonStyleData:
                                                              ButtonStyleData(
                                                            height: 45,
                                                            width: 105,
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        12),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: Colors
                                                                  .transparent,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8),
                                                            ),
                                                          ),
                                                          iconStyleData:
                                                              const IconStyleData(
                                                            icon: Icon(
                                                                Icons
                                                                    .arrow_drop_down,
                                                                color: Colors
                                                                    .white),
                                                          ),
                                                          dropdownStyleData:
                                                              DropdownStyleData(
                                                            maxHeight: 200,
                                                            width: 120,
                                                            decoration:
                                                                BoxDecoration(
                                                              color: Colors
                                                                  .black87,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8),
                                                            ),
                                                            offset:
                                                                const Offset(
                                                                    0, 0),
                                                          ),
                                                          menuItemStyleData:
                                                              const MenuItemStyleData(
                                                            height: 40,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 6),
                                                Container(
                                                  height: 40,
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                    border: Border.all(
                                                        color: Colors.white24),
                                                    color: Colors.black87,
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.start,
                                                    children: [
                                                      ToggleButtons(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                        borderColor:
                                                            Colors.white24,
                                                        selectedBorderColor:
                                                            AppColors
                                                                .primaryMain,
                                                        fillColor: AppColors
                                                            .primaryMain
                                                            .withOpacity(0.16),
                                                        selectedColor: AppColors
                                                            .primaryMain,
                                                        color: Colors.white,
                                                        constraints:
                                                            BoxConstraints(
                                                                minHeight: 36,
                                                                minWidth: 110),
                                                        isSelected: [
                                                          selectedView ==
                                                              "Overall Score",
                                                          selectedView ==
                                                              "Geocoding",
                                                        ],
                                                        onPressed: (index) {
                                                          setState(() {
                                                            selectedView = index ==
                                                                    0
                                                                ? "Overall Score"
                                                                : "Geocoding";
                                                          });
                                                        },
                                                        children: const [
                                                          Text("Overall Score"),
                                                          Text("Geocoding"),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(height: 25),

                                                // ===== Pie Chart =====
                                                Center(
                                                  child: Column(
                                                    children: [
                                                      SizedBox(
                                                        width: 180,
                                                        height: 180,
                                                        child: PieChart(
                                                          PieChartData(
                                                            centerSpaceRadius:
                                                                0,
                                                            sections: sections,
                                                            pieTouchData:
                                                                PieTouchData(
                                                              touchCallback:
                                                                  (event, res) {
                                                                setState(() {
                                                                  // ✅ Detect actual interaction
                                                                  if (!event
                                                                          .isInterestedForInteractions ||
                                                                      res?.touchedSection ==
                                                                          null) {
                                                                    return;
                                                                  }

                                                                  final index = res!
                                                                      .touchedSection!
                                                                      .touchedSectionIndex;

                                                                  // ✅ Toggle info card display on same slice click
                                                                  if (touchedIndex ==
                                                                      index) {
                                                                    touchedIndex =
                                                                        -1; // Hide
                                                                  } else {
                                                                    touchedIndex =
                                                                        index; // Show
                                                                  }
                                                                });
                                                              },
                                                            ),
                                                          ),
                                                        ),
                                                      ),

                                                      const SizedBox(
                                                          height: 33),

                                                      // ✅ Show info card below the pie when a slice is selected
                                                      AnimatedSwitcher(
                                                        duration:
                                                            const Duration(
                                                                milliseconds:
                                                                    250),
                                                        child: (touchedIndex !=
                                                                    null &&
                                                                touchedIndex! >=
                                                                    0 &&
                                                                touchedIndex! <
                                                                    chartEntries
                                                                        .length)
                                                            ? _buildInfoCard(
                                                                chartEntries[
                                                                    touchedIndex!])
                                                            : const SizedBox
                                                                .shrink(),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                      Container(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.9,
                                        child: Consumer<MyLocationListProvider>(
                                          builder: (context,
                                              locationListProvider, child) {
                                            if (selectedView1 == 'Geocoding') {
                                              final geocodingData =
                                                  locationListProvider
                                                      .grapDataProfile
                                                      ?.geocodeCounts;

                                              if (geocodingData == null) {
                                                return const Center(
                                                    child: Text(
                                                        'No geocoding data'));
                                              }

                                              // Convert to usable map
                                              final Map<String, dynamic>
                                                  geocodingMap =
                                                  geocodingData.toJson();

                                              // Sort descending by count
                                              final List<Map<String, dynamic>>
                                                  dataList = geocodingMap
                                                      .entries
                                                      .map((e) => {
                                                            'name':
                                                                'Geocode ${e.key}',
                                                            'count':
                                                                (e.value as num)
                                                                    .toDouble(),
                                                          })
                                                      .toList()
                                                    ..sort((a, b) => (b['count']
                                                            as double)
                                                        .compareTo(a['count']
                                                            as double));

                                              // if (dataList.isEmpty) {
                                              //   return const Center(
                                              //       child:
                                              //           Text('No data found'));
                                              // }

                                              final values = dataList
                                                  .map((e) =>
                                                      e['count'] as double)
                                                  .toList();
                                              final minValue = values.reduce(
                                                  (a, b) => a < b ? a : b);
                                              final maxValue = values.reduce(
                                                  (a, b) => a > b ? a : b);
                                              final total = values.fold<double>(
                                                  0.0, (sum, v) => sum + v);

                                              return Container(
                                                height: dataList.isEmpty
                                                    ? 160
                                                    : 400,
                                                margin:
                                                    const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color:
                                                      const Color(0xFF111111),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                      color: Colors.white10),
                                                ),
                                                padding:
                                                    const EdgeInsets.all(16),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            "Critical Missing Parameters (Geocoding)",
                                                            maxLines: 2,
                                                            style:
                                                                const TextStyle(
                                                              color: Color(
                                                                  0xFF90CAF9),
                                                              fontSize: 14,
                                                            ),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            width: 12),
                                                        Container(
                                                          decoration:
                                                              BoxDecoration(
                                                            color:
                                                                Colors.black87,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12),
                                                            border: Border.all(
                                                                color: Colors
                                                                    .white24),
                                                          ),
                                                          child:
                                                              DropdownButtonHideUnderline(
                                                            child:
                                                                DropdownButton2<
                                                                    String>(
                                                              value:
                                                                  selectedView1,
                                                              style: const TextStyle(
                                                                  color: Colors
                                                                      .white),
                                                              items: const [
                                                                DropdownMenuItem(
                                                                  value:
                                                                      'Geocoding',
                                                                  child: Text(
                                                                      'Geocoding',
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis),
                                                                ),
                                                                DropdownMenuItem(
                                                                  value:
                                                                      'Parameter',
                                                                  child: Text(
                                                                      'Parameter',
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis),
                                                                ),
                                                              ],
                                                              onChanged:
                                                                  (value) {
                                                                if (value !=
                                                                    null) {
                                                                  setState(() {
                                                                    selectedView1 =
                                                                        value;
                                                                  });
                                                                }
                                                              },
                                                              buttonStyleData:
                                                                  ButtonStyleData(
                                                                height: 45,
                                                                width: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width /
                                                                    3.2,
                                                                padding: const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        11),
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: Colors
                                                                      .black87,
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              8),
                                                                  border: Border.all(
                                                                      color: Colors
                                                                          .white24),
                                                                ),
                                                              ),
                                                              iconStyleData:
                                                                  const IconStyleData(
                                                                icon: Icon(
                                                                    Icons
                                                                        .arrow_drop_down,
                                                                    color: Colors
                                                                        .white),
                                                              ),
                                                              dropdownStyleData:
                                                                  DropdownStyleData(
                                                                maxHeight: 200,
                                                                width: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width /
                                                                    3.2,
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: Colors
                                                                      .black87,
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              8),
                                                                ),
                                                              ),
                                                              menuItemStyleData:
                                                                  const MenuItemStyleData(
                                                                height: 40,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 10),
                                                    Expanded(
                                                      child: ListView.builder(
                                                        physics:
                                                            const NeverScrollableScrollPhysics(),
                                                        shrinkWrap: true,
                                                        itemCount:
                                                            dataList.length,
                                                        itemBuilder:
                                                            (context, index) {
                                                          final item =
                                                              dataList[index];
                                                          final name =
                                                              item['name']
                                                                  as String;
                                                          final value =
                                                              item['count']
                                                                  as double;
                                                          final percent = total >
                                                                  0
                                                              ? (value /
                                                                      total) *
                                                                  100
                                                              : 0.0;
                                                          final color =
                                                              getColorByValue(
                                                                  value,
                                                                  minValue,
                                                                  maxValue,
                                                                  dataList
                                                                      .length);

                                                          return _buildBarItem1(
                                                              name,
                                                              value,
                                                              percent,
                                                              maxValue,
                                                              color);
                                                        },
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }

                                            // Handle Parameter view
                                            else {
                                              final parameterData =
                                                  locationListProvider
                                                      .grapDataProfile
                                                      ?.globalSovPerilCounts;

                                              // Convert the parameter data to usable format
                                              final Map<String, dynamic>
                                                  parameterMap =
                                                  parameterData?.toJson() ?? {};

                                              // Sort by missing descending so highest is first
                                              final List<Map<String, dynamic>>
                                                  dataList =
                                                  parameterMap.entries.map((e) {
                                                final perilData = e.value is Map
                                                    ? Map<String, dynamic>.from(
                                                        e.value)
                                                    : {};
                                                final total =
                                                    (perilData['total'] as num?)
                                                            ?.toDouble() ??
                                                        0.0;
                                                final completed =
                                                    (perilData['completed_data']
                                                                as num?)
                                                            ?.toDouble() ??
                                                        0.0;
                                                final missing =
                                                    total - completed;

                                                return {
                                                  'name': e.key,
                                                  'missing': missing,
                                                  'total': total,
                                                  'completed_data': completed,
                                                };
                                              }).toList()
                                                    ..sort((a, b) =>
                                                        (b['missing'] as double)
                                                            .compareTo(
                                                                a['missing']
                                                                    as double));

                                              final maxValue =
                                                  dataList.fold<double>(
                                                0.0,
                                                (prev, e) => e['missing'] > prev
                                                    ? e['missing']
                                                    : prev,
                                              );

                                              final total =
                                                  dataList.fold<double>(
                                                0.0,
                                                (sum, e) =>
                                                    sum +
                                                    (e['missing'] as double),
                                              );

                                              return Container(
                                                height: dataList.isEmpty
                                                    ? 160
                                                    : 400,
                                                margin:
                                                    const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color:
                                                      const Color(0xFF111111),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                      color: Colors.white10),
                                                ),
                                                padding:
                                                    const EdgeInsets.all(16),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            "Critical Missing Parameters (Parameter)",
                                                            maxLines: 2,
                                                            style:
                                                                const TextStyle(
                                                              color: Color(
                                                                  0xFF90CAF9),
                                                              fontSize: 14,
                                                            ),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            width: 12),
                                                        Container(
                                                          decoration:
                                                              BoxDecoration(
                                                            color:
                                                                Colors.black87,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12),
                                                            border: Border.all(
                                                                color: Colors
                                                                    .white24),
                                                          ),
                                                          child:
                                                              DropdownButtonHideUnderline(
                                                            child:
                                                                DropdownButton2<
                                                                    String>(
                                                              value:
                                                                  selectedView1,
                                                              style: const TextStyle(
                                                                  color: Colors
                                                                      .white),
                                                              items: const [
                                                                DropdownMenuItem(
                                                                  value:
                                                                      'Geocoding',
                                                                  child: Text(
                                                                      'Geocoding',
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis),
                                                                ),
                                                                DropdownMenuItem(
                                                                  value:
                                                                      'Parameter',
                                                                  child: Text(
                                                                      'Parameter',
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis),
                                                                ),
                                                              ],
                                                              onChanged:
                                                                  (value) {
                                                                if (value !=
                                                                    null) {
                                                                  setState(() {
                                                                    selectedView1 =
                                                                        value;
                                                                  });
                                                                }
                                                              },
                                                              buttonStyleData:
                                                                  ButtonStyleData(
                                                                height: 45,
                                                                width: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width /
                                                                    3.2,
                                                                padding: const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        11),
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: Colors
                                                                      .black87,
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              8),
                                                                  border: Border.all(
                                                                      color: Colors
                                                                          .white24),
                                                                ),
                                                              ),
                                                              iconStyleData:
                                                                  const IconStyleData(
                                                                icon: Icon(
                                                                    Icons
                                                                        .arrow_drop_down,
                                                                    color: Colors
                                                                        .white),
                                                              ),
                                                              dropdownStyleData:
                                                                  DropdownStyleData(
                                                                maxHeight: 200,
                                                                width: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width /
                                                                    3.2,
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: Colors
                                                                      .black87,
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              8),
                                                                ),
                                                              ),
                                                              menuItemStyleData:
                                                                  const MenuItemStyleData(
                                                                height: 40,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 10),
                                                    Expanded(
                                                      child: dataList.isEmpty
                                                          ? Container(
                                                              height: 50,
                                                              alignment:
                                                                  Alignment
                                                                      .center,
                                                              child: const Text(
                                                                'No data found',
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .white70,
                                                                    fontSize:
                                                                        14),
                                                              ),
                                                            )
                                                          : ListView.builder(
                                                              physics:
                                                                  const NeverScrollableScrollPhysics(),
                                                              shrinkWrap: true,
                                                              itemCount:
                                                                  parameterMap
                                                                      .length,
                                                              itemBuilder:
                                                                  (context,
                                                                      index) {
                                                                final item =
                                                                    dataList[
                                                                        index];
                                                                final name =
                                                                    item['name']
                                                                        as String;
                                                                final value =
                                                                    item['completed_data']
                                                                        as double;
                                                                final percent =
                                                                    total > 0
                                                                        ? (value /
                                                                                total) *
                                                                            100
                                                                        : 0.0;
                                                                return _buildBarItem(
                                                                    name,
                                                                    value,
                                                                    percent,
                                                                    maxValue);
                                                              },
                                                            ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // Location list
                            SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  if (locationListProvider.isCertifiedLoading) {
                                    return const Column(
                                      children: [
                                        SizedBox(height: 100),
                                        Center(
                                            child: CircularProgressIndicator()),
                                      ],
                                    );
                                  }
                                  if (locationListProvider
                                      .certifiedLocationList.isEmpty) {
                                    return Center(
                                      child: Text(
                                        LanguageService.getTranslated(context,
                                            "location_list_app_no_accounts_text"),
                                        style: typography.Body1,
                                      ),
                                    );
                                  }

                                  if (index ==
                                      locationListProvider
                                          .certifiedLocationList.length) {
                                    if (locationListProvider
                                        .isNextPageCertifiedLoading) {
                                      return const Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Center(
                                            child: CircularProgressIndicator()),
                                      );
                                    } else if (locationListProvider
                                                .certifiedPage >=
                                            locationListProvider
                                                .certifiedTotalPages &&
                                        locationListProvider
                                            .certifiedLocationList.isNotEmpty) {
                                      return Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Center(
                                          child: Text(
                                            LanguageService.getTranslated(
                                                context,
                                                "location_list_end_of_list"),
                                            style: typography.Body1,
                                          ),
                                        ),
                                      );
                                    } else {
                                      locationListProvider.certifiedPage =
                                          locationListProvider.certifiedPage +
                                              1;
                                      locationListProvider
                                          .fetchCertifiedLocationList(
                                        context,
                                        "",
                                        locationListProvider.certifiedPage,
                                        40,
                                        widget.accountID,
                                        widget.subAccountID,
                                        widget.initialProcessId,
                                        widget.initialSubProcessId,
                                      );
                                      return const SizedBox();
                                    }
                                  }

                                  return myLocationCertifiedCard(
                                      locationListProvider, index, context);
                                },
                                childCount: locationListProvider
                                        .certifiedLocationList.isEmpty
                                    ? 1
                                    : locationListProvider
                                            .certifiedLocationList.length +
                                        1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
      },
    );
  }

  Widget _buildInfoCard(Map<String, dynamic> data) {
    final pct = data['pct'] ?? 0.0;
    final val = data['value'] ?? 0.0;
    final label = data['label'] ?? 'Unknown';

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        key: ValueKey(label),
        // 🔑 Required for AnimatedSwitcher
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1C),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Percentage: ${pct.toStringAsFixed(0)}%",
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Container(
              height: 14,
              width: 1,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              color: Colors.white24,
            ),
            Text(
              "PD Value: ₹${val.toStringAsFixed(0)}M",
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Container(
              height: 14,
              width: 1,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              color: Colors.white24,
            ),
            Text(
              "Location: ${label == 'Unknown' ? '0' : label}",
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // Widget _buildInfoCard(Map<String, dynamic> data) {
  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
  //     decoration: BoxDecoration(
  //       color: const Color(0xFF1E1E1E),
  //       borderRadius: BorderRadius.circular(8),
  //       border: Border.all(color: Colors.white10),
  //     ),
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //       children: [
  //         Text(
  //           data['label'].toString(),
  //           style: const TextStyle(color: Colors.white70, fontSize: 12),
  //         ),
  //         Text(
  //           "${data['pct'].toStringAsFixed(2)}%",
  //           style: const TextStyle(color: Colors.lightBlueAccent, fontSize: 12),
  //         ),
  //         Text(
  //           "₹${(data['value'] as double).toStringAsFixed(0)}",
  //           style: const TextStyle(color: Colors.white70, fontSize: 12),
  //         ),
  //       ],
  //     ),
  //   );
  // }
  Color _getPieColor(var percent) {
    if (percent >= 80) return Colors.green;
    if (percent >= 60) return Colors.lightGreen;
    if (percent >= 40) return Colors.orange;
    if (percent >= 20) return Colors.deepOrange;
    return Colors.redAccent;
  }

  // _getLocationListCertifiedUI() {
  //   var typography = CustomTypography(context);
  //   return Consumer<MyLocationListProvider>(
  //     builder: (context, locationListProvider, child) {
  //       return Column(
  //         children: [
  //           Padding(
  //             padding: const EdgeInsets.symmetric(horizontal: 12.0),
  //             child: Row(
  //               children: [
  //                 // Horizontally scrollable row for all chips
  //                 Expanded(
  //                   child: SingleChildScrollView(
  //                     scrollDirection: Axis.horizontal,
  //                     child: Row(
  //                       children: [
  //                         // Show country options as chips
  //                         if (locationListProvider.countries.isNotEmpty)
  //                           Padding(
  //                             padding:
  //                                 const EdgeInsets.symmetric(horizontal: 4.0),
  //                             child: Chip(
  //                               label: Text(
  //                                   "Country: ${locationListProvider.countries.join(', ')}"),
  //                               onDeleted: () {
  //                                 locationListProvider.clearCountryFilter();
  //                                 locationListProvider
  //                                     .fetchCertifiedLocationList(
  //                                   context,
  //                                   locationQuery,
  //                                   1,
  //                                   40,
  //                                   widget.accountID,
  //                                   widget.subAccountID,
  //                                   widget.initialProcessId,
  //                                   widget.initialSubProcessId,
  //                                 );
  //                               },
  //                             ),
  //                           ),
  //
  //                         // Show certifications as chips
  //                         if (locationListProvider.certifications.isNotEmpty)
  //                           Padding(
  //                             padding:
  //                                 const EdgeInsets.symmetric(horizontal: 4.0),
  //                             child: Chip(
  //                               label: Text(
  //                                   "Certifications: ${locationListProvider.certifications.join(', ')}"),
  //                               onDeleted: () {
  //                                 locationListProvider
  //                                     .clearCertificationsFilter();
  //                                 locationListProvider
  //                                     .fetchCertifiedLocationList(
  //                                   context,
  //                                   locationQuery,
  //                                   1,
  //                                   40,
  //                                   widget.accountID,
  //                                   widget.subAccountID,
  //                                   widget.initialProcessId,
  //                                   widget.initialSubProcessId,
  //                                 );
  //                               },
  //                             ),
  //                           ),
  //
  //                         // Show hazard ratings as chips with circles for selected ratings
  //                         if (locationListProvider.hazardRatings.isNotEmpty)
  //                           for (var hazard
  //                               in locationListProvider.hazardRatings.keys)
  //                             Padding(
  //                               padding:
  //                                   const EdgeInsets.symmetric(horizontal: 4.0),
  //                               child: Chip(
  //                                 label: Row(
  //                                   children: [
  //                                     Text(hazard),
  //                                     // Hazard name
  //                                     const SizedBox(width: 8),
  //                                     // Space before ratings
  //                                     if (locationListProvider
  //                                         .hazardRatings[hazard]!.isEmpty)
  //                                       Text(
  //                                           'All') // If no ratings are selected
  //                                     else
  //                                       Row(
  //                                         children: locationListProvider
  //                                             .hazardRatings[hazard]!
  //                                             .map((rating) {
  //                                           return Padding(
  //                                             padding: const EdgeInsets.only(
  //                                                 right: 4.0),
  //                                             child: CircleAvatar(
  //                                               radius: 10,
  //                                               backgroundColor:
  //                                                   _getRatingColor(rating),
  //                                               child: Text(
  //                                                 '$rating',
  //                                                 style: const TextStyle(
  //                                                     color: Colors.white,
  //                                                     fontSize: 12),
  //                                               ),
  //                                             ),
  //                                           );
  //                                         }).toList(),
  //                                       ),
  //                                   ],
  //                                 ),
  //                                 onDeleted: () {
  //                                   locationListProvider
  //                                       .clearHazardFilter(hazard);
  //                                   locationListProvider
  //                                       .fetchCertifiedLocationList(
  //                                     context,
  //                                     locationQuery,
  //                                     1,
  //                                     40,
  //                                     widget.accountID,
  //                                     widget.subAccountID,
  //                                     widget.initialProcessId,
  //                                     widget.initialSubProcessId,
  //                                   );
  //                                 },
  //                               ),
  //                             ),
  //
  //                         // Show ratings as chips
  //                         if (locationListProvider.rating.isNotEmpty)
  //                           Padding(
  //                             padding:
  //                                 const EdgeInsets.symmetric(horizontal: 4.0),
  //                             child: Chip(
  //                               label: Text(
  //                                   "Ratings: ${locationListProvider.rating.join(', ')}"),
  //                               onDeleted: () {
  //                                 locationListProvider.clearRatingsFilter();
  //                                 locationListProvider
  //                                     .fetchCertifiedLocationList(
  //                                   context,
  //                                   locationQuery,
  //                                   1,
  //                                   40,
  //                                   widget.accountID,
  //                                   widget.subAccountID,
  //                                   widget.initialProcessId,
  //                                   widget.initialSubProcessId,
  //                                 );
  //                               },
  //                             ),
  //                           ),
  //                       ],
  //                     ),
  //                   ),
  //                 ),
  //
  //                 // Clear all filters button (text button at the end)
  //                 if (locationListProvider
  //                     .hasAnyFilterApplied()) // Check if any filter is applied
  //                   Padding(
  //                     padding: const EdgeInsets.symmetric(horizontal: 8.0),
  //                     child: TextButton(
  //                       onPressed: () {
  //                         locationListProvider.clearAllFilters();
  //                         locationListProvider.fetchLocationList(
  //                             context,
  //                             locationQuery,
  //                             1,
  //                             40,
  //                             widget.accountID,
  //                             widget.subAccountID,
  //                             widget.initialProcessId,
  //                             widget.initialSubProcessId,
  //                             '');
  //                       },
  //                       child: const Text(
  //                         'Clear All',
  //                         style: TextStyle(
  //                             color: Colors.red), // Color for emphasis
  //                       ),
  //                     ),
  //                   ),
  //               ],
  //             ),
  //           ),
  //           Expanded(
  //             child: Expanded(
  //               child: RefreshIndicator(
  //                 onRefresh: () async {
  //                   await locationListProvider.fetchCertifiedLocationList(
  //                     context,
  //                     locationQuery,
  //                     1,
  //                     40,
  //                     widget.accountID,
  //                     widget.subAccountID,
  //                     widget.initialProcessId,
  //                     widget.initialSubProcessId,
  //                   );
  //                 },
  //                 child: locationListProvider.isCertifiedLoading
  //                     ? Column(
  //                         children: [
  //                           SizedBox(height: 100),
  //                           Center(child: CircularProgressIndicator()),
  //                         ],
  //                       )
  //                     : locationListProvider.certifiedLocationList.isEmpty
  //                         ? Center(
  //                             child: Text(
  //                                 LanguageService.getTranslated(context,
  //                                     "location_list_app_no_accounts_text"),
  //                                 style: typography.Body1),
  //                           )
  //                         : ListView.builder(
  //                             physics: ClampingScrollPhysics(),
  //                             shrinkWrap: true,
  //                             itemCount: locationListProvider
  //                                 .certifiedLocationList.length,
  //                             itemBuilder: (context, index) {
  //                               if (index ==
  //                                   locationListProvider
  //                                           .certifiedLocationList.length -
  //                                       1) {
  //                                 if (locationListProvider
  //                                     .isNextPageCertifiedLoading) {
  //                                   return Padding(
  //                                     padding: const EdgeInsets.all(8.0),
  //                                     child: Center(
  //                                         child: CircularProgressIndicator()),
  //                                   );
  //                                 } else if (locationListProvider
  //                                             .certifiedPage >=
  //                                         locationListProvider
  //                                             .certifiedTotalPages &&
  //                                     locationListProvider
  //                                         .certifiedLocationList.isNotEmpty) {
  //                                   return Column(
  //                                     children: [
  //                                       myLocationCertifiedCard(
  //                                           locationListProvider,
  //                                           index,
  //                                           context),
  //                                       Padding(
  //                                         padding: const EdgeInsets.all(8.0),
  //                                         child: Center(
  //                                             child: Text(
  //                                                 LanguageService.getTranslated(
  //                                                     context,
  //                                                     "location_list_end_of_list"),
  //                                                 style: typography.Body1)),
  //                                       ),
  //                                     ],
  //                                   );
  //                                 } else {
  //                                   locationListProvider.certifiedPage =
  //                                       locationListProvider.certifiedPage + 1;
  //                                   locationListProvider
  //                                       .fetchCertifiedLocationList(
  //                                     context,
  //                                     "",
  //                                     locationListProvider.certifiedPage,
  //                                     40,
  //                                     widget.accountID,
  //                                     widget.subAccountID,
  //                                     widget.initialProcessId,
  //                                     widget.initialSubProcessId,
  //                                   );
  //                                   return SizedBox();
  //                                 }
  //                               }
  //
  //                               /*return locationListCard(index,
  //                       locationListProvider.certifiedLocationList);*/
  //                               return myLocationCertifiedCard(
  //                                   locationListProvider, index, context);
  //                             },
  //                           ),
  //               ),
  //             ),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  Color _getRatingColor(int rating) {
    switch (rating) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.yellow;
      case 4:
        return Colors.green;
      case 5:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  MyLocationCard myLocationCertifiedCard(
      MyLocationListProvider locationListProvider,
      int index,
      BuildContext context) {
    return MyLocationCard(
      imageUrl: locationListProvider
                  .certifiedLocationList[index].screenshots?.isNotEmpty ==
              true
          ? locationListProvider
                  .certifiedLocationList[index].screenshots![0].imageUrl ??
              ''
          : '',
      campusId: locationListProvider
              .certifiedLocationList[index].finalAddress?.campusId ??
          '',
      index: index,
      accountId: widget.accountID,
      subAccountId: widget.subAccountID,
      sovId: widget.sovID,
      sovName: widget.sovName,
      subAccountName: widget.subAccountName,
      isCertified: true,
      locationId: locationListProvider.certifiedLocationList[index].id ?? '',
      accountName: locationListProvider
              .certifiedLocationList[index].finalAddress?.accountName ??
          '',
      ownerName: locationListProvider
              .certifiedLocationList[index].finalAddress?.ownerName ??
          '',
      companyName: locationListProvider
              .certifiedLocationList[index].finalAddress?.companyName ??
          '',
      address: locationListProvider
              .certifiedLocationList[index].finalAddress?.address ??
          '',
      percentage: double.parse(locationListProvider
              .certifiedLocationList[index].finalAddress?.percent ??
          '0'),
      geocodingScore:
          locationListProvider.certifiedLocationList[index].geocodingScore ?? 0,
      riskScore: int.tryParse(locationListProvider
                  .certifiedLocationList[index].overallScore
                  ?.toString() ??
              '0') ??
          0,
      dataCompletenessScore: locationListProvider
              .certifiedLocationList[index].dataCompleteness?.scorePd ??
          0,
      isAutoCertified: true,
      tags: (locationListProvider.certifiedLocationList[index]?.tags ?? []),
      onDelete: (locationId) {
        // Show delete confirmation dialog
        showDeleteConfirmationDialog(
          context,
          () async {
            print("Deleting location $locationId");
            // Delete the location
            await Provider.of<MyLocationListProvider>(context, listen: false)
                .deleteLocations(context, widget.accountID!,
                    widget.subAccountID!, widget.sovID!, [locationId]);

            // Refresh the list after deletion
            Provider.of<MyLocationListProvider>(context, listen: false)
                .fetchLocationList(
              context,
              locationQuery,
              1,
              40,
              widget.accountID,
              widget.subAccountID,
              widget.initialProcessId,
              widget.initialSubProcessId,
              widget.sovID,
            );

            Navigator.of(context).pop();
          },
          [locationId],
        );
      },
      onAddToSOV: null,
      onAddTag: (locationId) {
        // Show add tag dialog
        // Implement bulk add tag
        locationListProvider.addTagsToSelectedLocations(
            context, widget.accountID!, widget.subAccountID!, locationId);
      },
      getData: () {
        locationListProvider.fetchLocationList(
          context,
          locationQuery,
          1,
          40,
          widget.accountID,
          widget.subAccountID,
          widget.initialProcessId,
          widget.initialSubProcessId,
          widget.sovID,
        );
      },
      hazardProcess: true,
    );
  }

  void showDeleteConfirmationDialog(
      BuildContext context, Function onDelete, List<String> locationIds) {
    var typography = CustomTypography(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.paperElevation2, // Dark background
          title: Text(
            'Are you sure you want to delete specified locations?',
            style: TextStyle(color: Colors.white), // White text
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.redAccent,
                size: 50,
              ),
              SizedBox(height: 16),
              Text(
                'This action is irreversible. Please proceed with caution.',
                style: TextStyle(color: Colors.white70), // Light grey text
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.white), // White text
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            Consumer<MyLocationListProvider>(
                builder: (context, locationListProvider, child) {
              return locationListProvider.isDeleteLocationLoading
                  ? CircularProgressIndicator()
                  : CustomButton(
                      type: ButtonType.danger,
                      child: Text('Delete',
                          style: typography.Body1.copyWith(
                              fontWeight: FontWeight.w500)),
                      onPressed: () {
                        //Navigator.of(context).pop(); // Close the dialog
                        print('Deleting locations b4: $locationIds');
                        onDelete(); // Trigger the delete action
                      },
                    );
            }),
          ],
        );
      },
    );
  }

  Future<void> _bulkDeleteLocations() async {
    var typography = CustomTypography(context);
    try {
      // Construct the list of location details for deletion
      List<Map<String, String>> locationList =
          selectedLocations.map((location) {
        return {
          "location_id": location.id ?? '',
          "owner_id": "widget.userId", // Assuming owner_id is userId
        };
      }).toList();

      // Make API call to delete locations
      await Provider.of<LocationListProvider>(context, listen: false)
          .deleteLocations(context, widget.accountID!, widget.subAccountID!,
              widget.sovID!, locationList);

      // Clear selections
      setState(() {
        selectedLocations.clear();
        showSelectAll = false;
        isAllSelected = false;
      });
    } catch (e) {
      // Error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete locations: ${e.toString()}')),
      );
    }
  }

  void _showUploadDialog(String accountId, String subAccountId, String sovId) {
    var typography = CustomTypography(context);
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, StateSetter setState) {
            return WillPopScope(
              onWillPop: () async {
                return false; // Disable the back button
              },
              child: AlertDialog(
                backgroundColor: Colors.black87,
                content: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text("Upload Partial List",
                          textAlign: TextAlign.start, style: typography.Body1),
                      SizedBox(height: 20),
                      _uploadedFileName == null
                          ? GestureDetector(
                              onTap: () async {
                                FilePickerResult? result =
                                    await FilePicker.platform.pickFiles(
                                  type: FileType.custom,
                                  allowedExtensions: ['xls', 'xlsx'],
                                );
                                if (result != null) {
                                  File file = File(result.files.single.path!);
                                  setState(() {
                                    files = file;
                                    String fileNameWithExtension =
                                        file.path.split('/').last;
                                    _uploadedFileName =
                                        fileNameWithExtension.split('.').first;
                                    _sovNameController.text =
                                        _uploadedFileName!;
                                  });
                                }
                              },
                              child: Container(
                                height: 150,
                                width: MediaQuery.of(context).size.width / 1.2,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.cloud_upload_outlined,
                                          color: Colors.white),
                                      SizedBox(height: 10),
                                      Text(
                                        LanguageService.getTranslated(context,
                                            "account_list_app_account_upload_drag_and_drop"),
                                        style: typography.Body1,
                                      ),
                                      SizedBox(height: 5),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Icon(Icons.info_outline,
                                              color: Colors.white54),
                                          SizedBox(width: 3),
                                          Text('Max file size is 200 MB',
                                              style: typography.Body1),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              height: 150,
                              width: MediaQuery.of(context).size.width / 1.2,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(Icons.description, size: 25),
                                  SizedBox(height: 10),
                                  Text(
                                    _sovNameController.text,
                                    style: typography.Body1,
                                  ),
                                  SizedBox(height: 10),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _uploadedFileName = null;
                                        _sovNameController.clear();
                                      });
                                    },
                                    child: Text(
                                      LanguageService.getTranslated(context,
                                          "account_list_app_cancel_text"),
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .error,
                                          fontSize: 14),
                                    ),
                                  ),
                                  SizedBox(height: 5),
                                ],
                              ),
                            ),
                      SizedBox(height: 20),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Consumer<MyLocationListProvider>(
                              builder: (_, locationListProvider, child) {
                            return locationListProvider.isImageUploadLoading
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : Container(
                                    width:
                                        MediaQuery.of(context).size.width / 1.2,
                                    child: CustomButton(
                                      onPressed: () async {
                                        String success = (await Provider.of<
                                                    LocationListProvider>(
                                                context,
                                                listen: false)
                                            .uploadSovAccount(
                                                context,
                                                files,
                                                accountId,
                                                subAccountId,
                                                sovId));

                                        print('Success: $success');
                                        // contain symbol +
                                        if (success.isNotEmpty &&
                                            success.contains('+')) {
                                          print('Inside + success: $success');
                                          // Show popup with title Empty SoV, body: Looks Like, Data has not been specified!! Do you want to continue creating an empty SOV, or abort? with 2 buttons: [create empty SOV]   [abort]
                                          showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  title: Text(
                                                    /*LanguageService.getTranslated(
                                                        context,
                                                        "account_list_app_empty_sov_title")*/
                                                    'Empty SOV',
                                                    style:
                                                        typography.H5_Regular,
                                                  ),
                                                  content: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        /* LanguageService.getTranslated(
                                                            context,
                                                            "account_list_app_empty_sov_text"),*/
                                                        'Looks Like, Data has not been specified!! Do you want to continue creating an empty SOV, or abort?',
                                                        style: typography.Body1,
                                                      ),
                                                      SizedBox(
                                                        height:
                                                            CustomSpacing.two,
                                                      ),
                                                      Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .stretch,
                                                        children: [
                                                          Consumer<
                                                                  UploadSovProvider>(
                                                              builder: (context,
                                                                  uploadSovProvider,
                                                                  child) {
                                                            return uploadSovProvider
                                                                    .isLoading
                                                                ? const Center(
                                                                    child:
                                                                        CircularProgressIndicator(),
                                                                  )
                                                                : CustomButton(
                                                                    onPressed:
                                                                        () async {
                                                                      // Create empty SOV
                                                                      var provider = Provider.of<
                                                                              UploadSovProvider>(
                                                                          context,
                                                                          listen:
                                                                              false);
                                                                      await provider.createEmptySov(
                                                                          context,
                                                                          success);
                                                                      Navigator.pop(
                                                                          context);
                                                                    },
                                                                    child: Text(
                                                                      /*LanguageService.getTranslated(
                                                                      context,
                                                                      "account_list_app_empty_sov_create"),*/
                                                                      'Create',
                                                                      style: typography
                                                                          .ButtonLarge,
                                                                    ),
                                                                    type: ButtonType
                                                                        .elevated,
                                                                  );
                                                          }),
                                                          CustomButton(
                                                            onPressed: () {
                                                              Navigator.pop(
                                                                  context);
                                                            },
                                                            child: Text(
                                                              /*LanguageService.getTranslated(
                                                                  context,
                                                                  "account_list_app_empty_sov_abort")*/
                                                              'Abort',
                                                              style: typography
                                                                  .ButtonLarge,
                                                            ),
                                                            type:
                                                                ButtonType.text,
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              });
                                        } else if (success.isNotEmpty) {
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (_) => MappingScreen(
                                                        tempId: success,
                                                        accountId:
                                                            widget.accountID ??
                                                                "",
                                                        accountName: widget
                                                                .accountName ??
                                                            "",
                                                        subAccountId: widget
                                                            .subAccountID!,
                                                      )));
                                        }
                                      },
                                      type: ButtonType.filled,
                                      child: Text(
                                        LanguageService.getTranslated(
                                            context, "login_submit_button"),
                                        style: typography.ButtonLarge,
                                      ),
                                    ),
                                  );
                          }),
                          Container(
                            width: MediaQuery.of(context).size.width / 1.2,
                            child: TextButton(
                              onPressed: () {
                                setState(() {
                                  _uploadedFileName = null;
                                  _sovNameController.clear();
                                });
                                Navigator.of(context).pop();
                              },
                              child: Text(
                                  LanguageService.getTranslated(
                                      context, "account_list_app_cancel_text"),
                                  style: typography.Body1),
                            ),
                          ),
                          SizedBox(width: 10),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          });
        });
  }
}

Widget _buildBarItem(
    String name, double value, double percent, double maxValue) {
  // Normalize value width safely
  final normalizedWidth =
      maxValue > 0 ? (value / maxValue).clamp(0.0, 1.0) : 0.0;
  Color barColor;
  if (percent <= 20) {
    barColor = Colors.red[900]!; // Darker red
  } else if (percent <= 40) {
    barColor = Colors.redAccent; //Colors.yellowAccent;
  } else if (percent <= 60) {
    barColor = Colors.orangeAccent;
  } else if (percent <= 80) {
    barColor = Colors.yellowAccent;
  } else if (percent <= 85) {
    barColor = Colors.greenAccent;
  } else {
    barColor = Colors.green;
  }
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        // Name + percentage
        Expanded(
          flex: 2,
          child: Text(
            "$name",
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ),

        Expanded(
          flex: 5,
          child: Stack(
            children: [
              Container(
                height: 35,
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              FractionallySizedBox(
                widthFactor: normalizedWidth,
                child: Container(
                  height: 35,
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              Positioned(
                width: 100,
                top: 10,
                child: Center(
                  child: Text(
                    value == 0 ? "" : value.toStringAsFixed(0),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 8),

        // Value text (right-aligned)
      ],
    ),
  );
}

Widget _buildBarItem1(
  String name,
  double value,
  double percent,
  double maxValue,
  Color color,
) {
  final normalizedWidth =
      maxValue > 0 ? (value / maxValue).clamp(0.0, 1.0) : 0.0;
  // ✅ Pick text color dynamically based on bar color brightness
  final textColor = _getTextColorForBackground(color);
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            name,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
        Expanded(
          flex: 5,
          child: Stack(
            children: [
              Container(
                height: 35,
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              FractionallySizedBox(
                widthFactor: normalizedWidth,
                child: Container(
                  height: 35,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              Positioned(
                width: 100,
                top: 10,
                child: Center(
                  child: Text(
                    value == 0 ? "" : value.toStringAsFixed(0),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Color _getTextColorForBackground(Color background) {
  final brightness = (background.red * 0.299 +
          background.green * 0.587 +
          background.blue * 0.114) /
      255;
  return brightness > 0.6 ? Colors.black : Colors.white;
}

Color getColorByValue(
  double value,
  double minValue,
  double maxValue,
  int itemCount,
) {
  // Handle case where all values are same
  if (maxValue == minValue) return hexToColor('#90CAF9'); // mid color (blue)

  // Normalize value to 0–1 range
  final normalized =
      ((value - minValue) / (maxValue - minValue)).clamp(0.0, 1.0);

  // Define your palette based on the uploaded image
  final List<Color> colors = [
    hexToColor('#EF5350'), // Red
    hexToColor('#FFF176'), // Yellow
    hexToColor('#90CAF9'), // Blue
    hexToColor('#81C784'), // Light Green
    hexToColor('#2E7D32'), // Dark Green
  ];

  // Determine which segment the value falls into
  final segmentCount = colors.length - 1;
  final segmentSize = 1 / segmentCount;
  final segmentIndex =
      (normalized / segmentSize).floor().clamp(0, segmentCount - 1);

  final t = (normalized - (segmentIndex * segmentSize)) / segmentSize;
  return Color.lerp(colors[segmentIndex], colors[segmentIndex + 1], t)!;
}

Color hexToColor(String hex) {
  var h = hex.replaceAll('#', '').trim();
  if (h.length == 6) h = 'FF$h'; // Add alpha
  return Color(int.parse('0x$h'));
}

class PieColorData {
  final String fill;
  final String text;

  const PieColorData({
    required this.fill,
    required this.text,
  });
}
