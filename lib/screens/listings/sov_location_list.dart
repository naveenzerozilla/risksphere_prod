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
import '../processMonitoringScreen/process_monitoring_system.dart';
import 'missing_parameter.dart';

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
  ScrollController? _scrollController;
  bool _isExpanded = false;
  String? userRoleName;
  bool _showNotificationDot = true;
  TabController? _tabController;
  Screens _selectedScreen = Screens.sovList;
  TextEditingController _locationSearchController = TextEditingController();
  TextEditingController mobileController = TextEditingController();

  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String selectedDropdown = 'TPV';
  int? touchedIndex; // For showing overlay info
  bool longPressed = false;
  int requestActionIndex = 0;
  String selectedMetric = 'PD Value';
  String selectedMetric_pie = 'PD Value';
  String selectedView = "Geocoding";
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
        11,
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
    _scrollController = ScrollController();
    _scrollController!.addListener(_scrollListener);
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
        _selectedScreen = Screens.sovList;
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
      }
      setState(() {});
    });
    _getData();
  }

  void _scrollListener() {
    final provider =
        Provider.of<MyLocationListProvider>(context, listen: false);

    if (_scrollController!.position.pixels >=
        _scrollController!.position.maxScrollExtent - 300) {
      // Handle pagination for regular location list (All tab)
      if (_tabController?.index == 0 &&
          !provider.isNextPageLoading &&
          provider.page < provider.totalPages) {
        provider.fetchLocationList(
          context,
          locationQuery,
          provider.page + 1,
          11,
          widget.accountID,
          widget.subAccountID,
          widget.initialProcessId,
          widget.initialSubProcessId,
          widget.sovID,
        );
      }
      // Handle pagination for certified location list (Certified tab)
      else if (_tabController?.index == 1 &&
          !provider.isNextPageCertifiedLoading &&
          provider.certifiedPage < provider.certifiedTotalPages) {
        provider.fetchCertifiedLocationList(
          context,
          locationQuery,
          provider.certifiedPage + 1,
          11,
          widget.accountID,
          widget.subAccountID,
          widget.initialProcessId,
          widget.initialSubProcessId,
          widget.sovID,
        );
      }
    }
  }

  Future<void> _getData() async {
    final locationProvider =
        Provider.of<MyLocationListProvider>(context, listen: false);

    await Future.wait([
      locationProvider.fetchUserManagement(),
      locationProvider.fetchLocationList(
        context,
        "",
        1,
        11,
        widget.accountID,
        widget.subAccountID,
        widget.initialProcessId,
        widget.initialSubProcessId,
        widget.sovID,
      ),
      locationProvider.fetchCertifiedLocationList(
        context,
        "",
        1,
        11,
        widget.accountID,
        widget.subAccountID,
        widget.initialProcessId,
        widget.initialSubProcessId,
        widget.sovID,
      ),
    ]);

    userRoleName = locationProvider.userManagement?.user.roles.first.name;

    if (mounted) setState(() {});
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
                        padding: isSelectionMode
                            ? const EdgeInsets.fromLTRB(8, 10, 0, 10)
                            : const EdgeInsets.fromLTRB(8, 2, 0, 0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            // Set your border color here
                            width: 1.0, // Set the width of the border
                          ),
                        ),
                        child: Consumer<MyLocationListProvider>(
                            builder: (context, locationListProvider, child) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Text(userRoleName.toString()),
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
                                SizedBox(width: 8),

                                InkWell(
                                  onTap: () {
                                    if (_selectedScreen == Screens.sovList) {
                                      print("Locationlist");
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
                                      print("certifiedLocationlist");
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
                                  child: Text(
                                    _selectedScreen == Screens.sovList
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
                                      fontSize: 16,
                                      color: AppColors.primaryMain,
                                    ),
                                  ),
                                ),
                                Spacer(),
                                SizedBox(width: 10),
                                //next release
                                // InkWell(
                                //     onTap: () {
                                //       Navigator.push(
                                //           context,
                                //           MaterialPageRoute(
                                //               builder: (context) =>
                                //                   MissingParameterScreen()));
                                //     },
                                //     child: Icon(Icons.edit_outlined)),
                                // SizedBox(width: 10),
                                InkWell(
                                  onTap: () {
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
                                  child: Icon(Icons.download),
                                  // tooltip: 'Export Selected',
                                ),
                                SizedBox(width: 10),
                                InkWell(
                                  onTap: () {
                                    // Implement bulk add to SOV
                                    locationListProvider
                                        .addTagsToSelectedLocations(
                                            context,
                                            widget.accountID!,
                                            widget.subAccountID!);
                                  },
                                  child: Icon(Symbols.note_stack_add),
                                ),
                                SizedBox(width: 10),
                                InkWell(
                                  onTap: () async {
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
                                      11,
                                      widget.accountID,
                                      widget.subAccountID,
                                      widget.initialProcessId,
                                      widget.initialSubProcessId,
                                      widget.sovID,
                                    );
                                  },
                                  child: locationListProvider.isLoading
                                      ? CircularProgressIndicator()
                                      : Icon(Symbols.done_all_rounded,
                                          color: Colors.green),
                                  // tooltip: 'Mark as Complete',
                                ),
                                SizedBox(width: 10),

                                InkWell(
                                  onTap: () {
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
                                  child: Icon(Icons.delete_outline),
                                  // tooltip: 'Delete Selected',
                                ),
                                SizedBox(width: 10),
                              ] else ...[
                                SizedBox(
                                  width: 8,
                                ),
                                Expanded(
                                  child: Row(
                                    children: [
                                      //SizedBox(width: CustomSpacing.two),
                                      Text(
                                        "SOV Locations",
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
                          : SizedBox(),
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
                                            'Hazard Score',
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
                                SizedBox(height: CustomSpacing.two),
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
                                          11,
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
                                          11,
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
                                                  11,
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
                                          11,
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
                                  11,
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
                            11,
                            widget.accountID,
                            widget.subAccountID,
                            widget.initialProcessId,
                            widget.initialSubProcessId,
                            widget.sovID,
                          );
                        },
                        child: CustomScrollView(
                          controller: _scrollController,
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

                                          // 🔥 Correct mapping for all 3 tabs
                                          Map<String, dynamic> sourceData = {};

                                          if (pdValues != null) {
                                            if (selectedView == "Hazard") {
                                              sourceData =
                                                  pdValues.byOverallScore ?? {};
                                            } else if (selectedView ==
                                                "Geocoding") {
                                              sourceData =
                                                  pdValues.byGeocodeScore ?? {};
                                            } else if (selectedView ==
                                                "Completeness") {
                                              sourceData = pdValues
                                                      .byDataCompletenessScore ??
                                                  {}; // ✅ ADDED
                                            }
                                          }

                                          // 🔥 FIX LABEL + DATA EXTRACTION (Unified for all views)
                                          final chartEntries =
                                              sourceData.entries.map((entry) {
                                            final data = entry.value;

                                            String label = "";
                                            if (selectedView == "Hazard") {
                                              label = "Score ${entry.key}";
                                            } else if (selectedView ==
                                                "Geocoding") {
                                              label = "Geocode ${entry.key}";
                                            } else {
                                              label =
                                                  "Completeness ${entry.key}";
                                            }

                                            return {
                                              'label': label,
                                              'value': data.totalPdValue ?? 0.0,
                                              'pct': data.pctOfTotal ?? 0.0,
                                              'rawKey': entry.key.toString(),
                                            };
                                          }).toList();

                                          // 🔥 FIX TOTAL CALCULATION
                                          double total = chartEntries.fold(
                                            0.0,
                                            (sum, item) =>
                                                sum + (item['value'] as double),
                                          );

                                          // 🔥 Chart sections
                                          final sections = chartEntries
                                              .asMap()
                                              .entries
                                              .map((entry) {
                                            final idx = entry.key;
                                            final value =
                                                entry.value['value'] as double;
                                            final pct = total > 0
                                                ? (value / total) * 100
                                                : 0;
                                            final selected =
                                                idx == touchedIndex;

                                            return PieChartSectionData(
                                              color: _getPieColorByKey(
                                                entry.value['rawKey']
                                                        ?.toString() ??
                                                    "0",
                                              ),
                                              value: value,
                                              radius: selected ? 120 : 100,
                                              title:
                                                  "${pct.toStringAsFixed(1)}%",
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
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    const Text(
                                                      "Weighted Distribution (PD Value)",
                                                      style: TextStyle(
                                                        color:
                                                            Color(0xFF90CAF9),
                                                        fontSize: 13,
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
                                                  padding:
                                                      const EdgeInsets.all(4),
                                                  child: ToggleButtons(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    borderColor: Colors.white24,
                                                    selectedBorderColor:
                                                        AppColors.primaryMain,
                                                    fillColor: AppColors
                                                        .primaryMain
                                                        .withOpacity(0.16),
                                                    selectedColor:
                                                        AppColors.primaryMain,
                                                    color: Colors.white,
                                                    constraints:
                                                        const BoxConstraints(
                                                            minHeight: 36,
                                                            minWidth: 110),
                                                    isSelected: [
                                                      selectedView ==
                                                          "Geocoding",
                                                      selectedView == "Hazard",
                                                      selectedView ==
                                                          "Completeness",
                                                    ],
                                                    onPressed: (index) {
                                                      setState(() {
                                                        if (index == 0)
                                                          selectedView =
                                                              "Geocoding";
                                                        if (index == 1)
                                                          selectedView =
                                                              "Hazard";

                                                        if (index == 2)
                                                          selectedView =
                                                              "Completeness";
                                                      });
                                                    },
                                                    children: const [
                                                      Text("Geocode"),
                                                      Text("Hazard"),
                                                      Text("Completeness"),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(height: 25),
                                                if (chartEntries.isEmpty ||
                                                    total == 0) ...[
                                                  Center(
                                                    child: Container(
                                                      height: 100,
                                                      alignment:
                                                          Alignment.center,
                                                      margin:
                                                          const EdgeInsets.all(
                                                              12),
                                                      child: const Text(
                                                        "No data found",
                                                        style: TextStyle(
                                                            color:
                                                                Colors.white70,
                                                            fontSize: 16),
                                                      ),
                                                    ),
                                                  ),
                                                ] else ...[
                                                  Center(
                                                    child: Column(
                                                      children: [
                                                        Row(
                                                          children: [
                                                            SizedBox(
                                                              width: 180,
                                                              height: 200,
                                                              child: PieChart(
                                                                PieChartData(
                                                                  centerSpaceRadius:
                                                                      0,
                                                                  sectionsSpace:
                                                                      0.3,
                                                                  sections:
                                                                      sections,
                                                                  pieTouchData:
                                                                      PieTouchData(
                                                                    touchCallback:
                                                                        (event,
                                                                            res) {
                                                                      setState(
                                                                          () {
                                                                        if (!event.isInterestedForInteractions ||
                                                                            res?.touchedSection ==
                                                                                null)
                                                                          return;

                                                                        final idx = res!
                                                                            .touchedSection!
                                                                            .touchedSectionIndex;

                                                                        touchedIndex = touchedIndex ==
                                                                                idx
                                                                            ? -1
                                                                            : idx;
                                                                      });
                                                                    },
                                                                  ),
                                                                ),
                                                              ),
                                                            ),

                                                            const SizedBox(
                                                                width: 30),

                                                            // Legends
                                                            Column(
                                                              children: [
                                                                _buildLegendBox(
                                                                    '1',
                                                                    '0–20%',
                                                                    Colors.red),
                                                                const SizedBox(
                                                                    height: 8),
                                                                _buildLegendBox(
                                                                    '2',
                                                                    '21–40%',
                                                                    Colors
                                                                        .yellow),
                                                                const SizedBox(
                                                                    height: 8),
                                                                _buildLegendBox(
                                                                    '3',
                                                                    '41–60%',
                                                                    Colors
                                                                        .blue),
                                                                const SizedBox(
                                                                    height: 8),
                                                                _buildLegendBox(
                                                                    '4',
                                                                    '61–80%',
                                                                    Colors
                                                                        .greenAccent),
                                                                const SizedBox(
                                                                    height: 8),
                                                                _buildLegendBox(
                                                                    '5',
                                                                    '81–100%',
                                                                    Colors
                                                                        .green),
                                                              ],
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(
                                                            height: 25),
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
                                            if (locationListProvider
                                                        .grapDataProfile ==
                                                    null ||
                                                locationListProvider
                                                        .grapDataProfile
                                                        ?.pdValues ==
                                                    null) {
                                              return Container();
                                            }
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
                                                            'count': e.value ==
                                                                    null
                                                                ? 0.0
                                                                : (e.value
                                                                        as num)
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
                                  if (locationListProvider.isLoading &&
                                      index == 0) {
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

                                  // Check if this is the loading indicator item
                                  if (index >=
                                      locationListProvider
                                          .myLocationList.length) {
                                    // If we're at the end and no more pages, show end message
                                    if (locationListProvider.page >=
                                        locationListProvider.totalPages) {
                                      // if (locationListProvider.certifiedPage >=
                                      //     locationListProvider
                                      //         .certifiedTotalPages) {
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
                                    }

                                    // If currently loading next page, show loader
                                    if (locationListProvider
                                        .isNextPageLoading) {
                                      return const Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Center(
                                            child: CircularProgressIndicator()),
                                      );
                                    }

                                    // If we need to load more and not currently loading, trigger load
                                    if (!locationListProvider
                                        .isNextPageLoading) {
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                        locationListProvider.fetchLocationList(
                                          context,
                                          locationQuery,
                                          locationListProvider.page + 1,
                                          11,
                                          widget.accountID,
                                          widget.subAccountID,
                                          widget.initialProcessId,
                                          widget.initialSubProcessId,
                                          widget.sovID,
                                        );
                                      });
                                    }

                                    return const SizedBox();
                                  }
                                  return myLocationlist(
                                      locationListProvider, index, context);
                                },
                                childCount: locationListProvider
                                        .myLocationList.isEmpty
                                    ? 1 // For empty state
                                    : locationListProvider
                                            .myLocationList.length +
                                        (locationListProvider.page <
                                                locationListProvider.totalPages
                                            ? 1
                                            : 0),
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
                                          11,
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
                                          11,
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
                                                  11,
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
                                          11,
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
                                  11,
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
                            11,
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
                                height: 430,
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

                                          // 🔥 Correct mapping for all 3 tabs
                                          Map<String, dynamic> sourceData = {};

                                          if (pdValues != null) {
                                            if (selectedView == "Hazard") {
                                              sourceData =
                                                  pdValues.byOverallScore ?? {};
                                            } else if (selectedView ==
                                                "Geocoding") {
                                              sourceData =
                                                  pdValues.byGeocodeScore ?? {};
                                            } else if (selectedView ==
                                                "Completeness") {
                                              sourceData = pdValues
                                                      .byDataCompletenessScore ??
                                                  {}; // ✅ ADDED
                                            }
                                          }

                                          // 🔥 FIX LABEL + DATA EXTRACTION (Unified for all views)
                                          final chartEntries =
                                              sourceData.entries.map((entry) {
                                            final data = entry.value;

                                            String label = "";
                                            if (selectedView == "Hazard") {
                                              label = "Score ${entry.key}";
                                            } else if (selectedView ==
                                                "Geocoding") {
                                              label = "Geocode ${entry.key}";
                                            } else {
                                              label =
                                                  "Completeness ${entry.key}";
                                            }

                                            return {
                                              'label': label,
                                              'value': data.totalPdValue ?? 0.0,
                                              'pct': data.pctOfTotal ?? 0.0,
                                              'rawKey': entry.key.toString(),
                                            };
                                          }).toList();

                                          double total = chartEntries.fold(
                                            0.0,
                                            (sum, item) =>
                                                sum + (item['value'] as double),
                                          );

                                          final sections = chartEntries
                                              .asMap()
                                              .entries
                                              .map((entry) {
                                            final idx = entry.key;
                                            final value =
                                                entry.value['value'] as double;
                                            final pct = total > 0
                                                ? (value / total) * 100
                                                : 0;
                                            final selected =
                                                idx == touchedIndex;

                                            return PieChartSectionData(
                                              color: _getPieColorByKey(
                                                entry.value['rawKey']
                                                        ?.toString() ??
                                                    "0",
                                              ),
                                              value: value,
                                              radius: selected ? 120 : 100,
                                              title:
                                                  "${pct.toStringAsFixed(1)}%",
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
                                              //     CrossAxisAlignment.s,
                                              children: [
                                                // ===== HEADER =====
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    const Text(
                                                      "Weighted Distribution (PD Value)",
                                                      style: TextStyle(
                                                        color:
                                                            Color(0xFF90CAF9),
                                                        fontSize: 13,
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

                                                // ===== Toggle Buttons (FIXED 3 ITEMS) =====
                                                Container(
                                                  height: 40,
                                                  padding:
                                                      const EdgeInsets.all(4),
                                                  child: ToggleButtons(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    borderColor: Colors.white24,
                                                    selectedBorderColor:
                                                        AppColors.primaryMain,
                                                    fillColor: AppColors
                                                        .primaryMain
                                                        .withOpacity(0.16),
                                                    selectedColor:
                                                        AppColors.primaryMain,
                                                    color: Colors.white,
                                                    constraints:
                                                        const BoxConstraints(
                                                            minHeight: 36,
                                                            minWidth: 110),

                                                    // 🔥 MUST BE 3 ITEMS
                                                    isSelected: [
                                                      selectedView ==
                                                          "Geocoding",
                                                      selectedView == "Hazard",
                                                      selectedView ==
                                                          "Completeness",
                                                    ],

                                                    onPressed: (index) {
                                                      setState(() {
                                                        if (index == 0)
                                                          selectedView =
                                                              "Geocoding";
                                                        if (index == 1)
                                                          selectedView =
                                                              "Hazard";

                                                        if (index == 2)
                                                          selectedView =
                                                              "Completeness";
                                                      });
                                                    },

                                                    children: const [
                                                      Text("Geocode"),
                                                      Text("Hazard"),
                                                      Text("Completeness"),
                                                    ],
                                                  ),
                                                ),
                                                if (chartEntries.isEmpty ||
                                                    total == 0) ...[
                                                  Center(
                                                    child: Container(
                                                      height: 100,
                                                      alignment:
                                                          Alignment.center,
                                                      margin:
                                                          const EdgeInsets.all(
                                                              12),
                                                      child: const Text(
                                                        "No data found",
                                                        style: TextStyle(
                                                            color:
                                                                Colors.white70,
                                                            fontSize: 16),
                                                      ),
                                                    ),
                                                  ),
                                                ] else ...[
                                                  const SizedBox(height: 25),
                                                  Center(
                                                    child: Column(
                                                      children: [
                                                        Row(
                                                          children: [
                                                            SizedBox(
                                                              width: 180,
                                                              height: 200,
                                                              child: PieChart(
                                                                PieChartData(
                                                                  centerSpaceRadius:
                                                                      0,
                                                                  sectionsSpace:
                                                                      0.3,
                                                                  sections:
                                                                      sections,
                                                                  pieTouchData:
                                                                      PieTouchData(
                                                                    touchCallback:
                                                                        (event,
                                                                            res) {
                                                                      setState(
                                                                          () {
                                                                        if (!event.isInterestedForInteractions ||
                                                                            res?.touchedSection ==
                                                                                null)
                                                                          return;

                                                                        final idx = res!
                                                                            .touchedSection!
                                                                            .touchedSectionIndex;

                                                                        touchedIndex = touchedIndex ==
                                                                                idx
                                                                            ? -1
                                                                            : idx;
                                                                      });
                                                                    },
                                                                  ),
                                                                ),
                                                              ),
                                                            ),

                                                            const SizedBox(
                                                                width: 30),

                                                            // Legends
                                                            Column(
                                                              children: [
                                                                _buildLegendBox(
                                                                    '1',
                                                                    '0–20%',
                                                                    Colors.red),
                                                                const SizedBox(
                                                                    height: 8),
                                                                _buildLegendBox(
                                                                    '2',
                                                                    '21–40%',
                                                                    Colors
                                                                        .yellow),
                                                                const SizedBox(
                                                                    height: 8),
                                                                _buildLegendBox(
                                                                    '3',
                                                                    '41–60%',
                                                                    Colors
                                                                        .blue),
                                                                const SizedBox(
                                                                    height: 8),
                                                                _buildLegendBox(
                                                                    '4',
                                                                    '61–80%',
                                                                    Colors
                                                                        .greenAccent),
                                                                const SizedBox(
                                                                    height: 8),
                                                                _buildLegendBox(
                                                                    '5',
                                                                    '81–100%',
                                                                    Colors
                                                                        .green),
                                                              ],
                                                            ),
                                                          ],
                                                        ),

                                                        const SizedBox(
                                                            height: 25),

                                                        // ===== Info Card =====
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
                                                ]
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
                                                            'count': e.value ==
                                                                    null
                                                                ? 0.0
                                                                : (e.value
                                                                        as num)
                                                                    .toDouble(),
                                                          })
                                                      .toList()
                                                    ..sort((a, b) => (b['count']
                                                            as double)
                                                        .compareTo(a['count']
                                                            as double));

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
                                                    const SizedBox(height: 3),
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
                                  if (locationListProvider.isCertifiedLoading &&
                                      index == 0) {
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

                                  if (index >=
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
                                      // Trigger next page load
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                        locationListProvider
                                            .fetchCertifiedLocationList(
                                          context,
                                          locationQuery,
                                          locationListProvider.certifiedPage +
                                              1,
                                          11,
                                          widget.accountID,
                                          widget.subAccountID,
                                          widget.initialProcessId,
                                          widget.initialSubProcessId,
                                          widget.sovID,
                                        );
                                      });
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
      lat: locationListProvider
              .certifiedLocationList[index].finalAddress?.latitude
              .toString() ??
          '',
      long: locationListProvider
              .certifiedLocationList[index].finalAddress?.longitude
              .toString() ??
          '',
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
      dataCompletenessScore:
          locationListProvider.certifiedLocationList[index].dataCompleteness ??
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
              11,
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
          11,
          widget.accountID,
          widget.subAccountID,
          widget.initialProcessId,
          widget.initialSubProcessId,
          widget.sovID,
        );
      },
      hazardProcess: true,
      role: userRoleName.toString(),
    );
  }

  MyLocationCard myLocationlist(MyLocationListProvider locationListProvider,
      int index, BuildContext context) {
    return MyLocationCard(
      imageUrl:
          locationListProvider.myLocationList[index].screenshots?.isNotEmpty ==
                  true
              ? locationListProvider
                      .myLocationList[index].screenshots![0].imageUrl ??
                  ''
              : '',
      campusId:
          locationListProvider.myLocationList[index].finalAddress?.campusId ??
              '',
      index: index,
      accountId: widget.accountID,
      subAccountId: widget.subAccountID,
      sovId: widget.sovID,
      lat: locationListProvider.myLocationList[index].finalAddress?.latitude
              .toString() ??
          '',
      long: locationListProvider.myLocationList[index].finalAddress?.longitude
              .toString() ??
          '',
      sovName: widget.sovName,
      subAccountName: widget.subAccountName,
      isCertified: false,
      locationId: locationListProvider.myLocationList[index].id ?? '',
      accountName: locationListProvider
              .myLocationList[index].finalAddress?.accountName ??
          '',
      ownerName:
          locationListProvider.myLocationList[index].finalAddress?.ownerName ??
              '',
      companyName: locationListProvider
              .myLocationList[index].finalAddress?.companyName ??
          '',
      address:
          locationListProvider.myLocationList[index].finalAddress?.address ??
              '',
      percentage: double.parse(
          locationListProvider.myLocationList[index].finalAddress?.percent ??
              '0'),
      geocodingScore:
          locationListProvider.myLocationList[index].geocodingScore ?? 0,
      riskScore: int.tryParse(locationListProvider
                  .myLocationList[index].overallScore
                  ?.toString() ??
              '0') ??
          0,
      dataCompletenessScore:
          locationListProvider.myLocationList[index].dataCompleteness ?? 0,
      isAutoCertified: false,
      tags: (locationListProvider.myLocationList[index]?.tags ?? []),
      onDelete: (locationId) {
        showDeleteConfirmationDialog(
          context,
          () async {
            await Provider.of<MyLocationListProvider>(context, listen: false)
                .deleteLocations(context, widget.accountID!,
                    widget.subAccountID!, widget.sovID!, [locationId]);

            Provider.of<MyLocationListProvider>(context, listen: false)
                .fetchLocationList(
              context,
              locationQuery,
              1,
              11,
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
        locationListProvider.addTagsToSelectedLocations(
            context, widget.accountID!, widget.subAccountID!, locationId);
      },
      getData: () {
        locationListProvider.fetchLocationList(
          context,
          locationQuery,
          1,
          11,
          widget.accountID,
          widget.subAccountID,
          widget.initialProcessId,
          widget.initialSubProcessId,
          widget.sovID,
        );
      },
      hazardProcess: true,
      role: userRoleName,
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

Widget _buildLegendBox(String label, String range, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        // const SizedBox(width: 4),
        // Text(
        //   range,
        //   style: const TextStyle(color: Colors.white, fontSize: 13),
        // ),
      ],
    ),
  );
}

Color _getPieColorByKey(String key) {
  int k = int.tryParse(key) ?? 0;

  if (k == 0 || k == 1) return Colors.red; // 0–20%
  if (k == 2) return Colors.yellow; // 20–40%
  if (k == 3) return Colors.blue; // 40–60%
  if (k == 4) return Colors.greenAccent; // 60–80%
  if (k == 5) return Colors.green; // 80–100%

  return Colors.grey;
}
