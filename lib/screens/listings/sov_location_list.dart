import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:green/models/my_location_list_model.dart';
import 'package:green/providers/location_list_provider.dart';
import 'package:green/providers/my_location_list_provider.dart';
import 'package:green/screens/listings/widgets/export_dialog.dart';
import 'package:green/screens/listings/widgets/listings_filter_screen.dart';
import 'package:green/screens/listings/widgets/location_card.dart';
import 'package:green/screens/listings/widgets/location_list_map_view.dart';
import 'package:green/screens/listings/widgets/mapping_screen.dart';
import 'package:green/screens/listings/widgets/overall_score_table.dart';
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
import 'package:green/models/role_model.dart' as roleModel;
import '../../providers/upload_sov_provider.dart';
import '../../service/language_service.dart';
import '../../service/shared_preference_service.dart';
import '../processMonitoringScreen/process_monitoring_system.dart';
import 'widgets/maintenance_widget.dart';

class SovLocationList extends StatefulWidget {
  final String accountID;
  final String subAccountID;
  final String accountName;
  final String subAccountName;
  final String sovID;
  final String sovName;
  final String? initialProcessId;
  final String? initialSubProcessId;

  const SovLocationList({
    super.key,
    this.accountID = '',
    this.subAccountID = '',
    this.accountName = '',
    this.subAccountName = '',
    this.sovID = '',
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

  int requestActionIndex = 0;

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
        "widget.accountId",
        "widget.subAccountId",
        widget.sovID,
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
              40,
              widget.accountID,
              widget.subAccountID,
              widget.sovID,
              widget.initialProcessId,
              widget.initialSubProcessId,
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
              40,
              widget.accountID,
              widget.subAccountID,
              widget.sovID,
              widget.initialProcessId,
              widget.initialSubProcessId,
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

  _getMaintainancePeriod() async {
    isMaintenance =
        await SharedPreferenceService.getScheduleInProgress() ?? false;
  }

  _getData() async {
    // Fetch data from API
    Provider.of<MyLocationListProvider>(context, listen: false)
        .fetchLocationList(
          context,
          "",
          1,
          40,
          widget.accountID,
          widget.subAccountID,
          widget.sovID,
          widget.initialProcessId,
          widget.initialSubProcessId,
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
          widget.sovID,
          widget.initialProcessId,
          widget.initialSubProcessId,
        )
        .then((value) => setState(() {}));
    //Provider.of<LocationListProvider>(context, listen: false).fetchCampusIds("widget.accountId", "widget.subAccountId", "widget.sovId");
    _getMaintainancePeriod();
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
                                            .selectAllLocations(false);
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
                                                            widget.accountID,
                                                        subAccountId:
                                                            widget.subAccountID,
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
                                                            widget.accountID,
                                                        subAccountId:
                                                            widget.subAccountID,
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
                                              widget.accountID,
                                              widget.subAccountID);
                                    },
                                    icon: Icon(Symbols.note_stack_add),
                                    tooltip: 'Add Tag'),
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
                                                widget.accountID,
                                                widget.subAccountID,
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
                                        "My Locations",
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
                                      TooltipTheme(
                                        data: TooltipThemeData(
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .surface,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          textStyle: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface,
                                            fontSize: 14,
                                          ),
                                          padding: EdgeInsets.all(8),
                                          verticalOffset: 20,
                                          preferBelow: false,
                                        ),
                                        child: Tooltip(
                                          showDuration: Duration(seconds: 5),
                                          triggerMode: TooltipTriggerMode.tap,
                                          preferBelow: true,
                                          richMessage: TextSpan(
                                            children: [
                                              for (int i = 0;
                                                  i <
                                                      locationListProvider
                                                          .summaryList.length;
                                                  i++)
                                                TextSpan(
                                                  text:
                                                      '• ${locationListProvider.summaryList[i]}\n',
                                                  style: typography.Subtitle1,
                                                ),
                                            ],
                                            style: typography.Subtitle1,
                                          ),
                                          child: Icon(
                                            Icons.info,
                                          ),
                                        ),
                                      ),
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
                                                accountId: widget.accountID,
                                                subAccountId:
                                                    widget.subAccountID,
                                                sovId: widget.sovID,
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
                      Container(
                        child: MaintenanceUI(isMaintenance: isMaintenance),
                      ),
                      Container(
                        child: _getLiveUI(),
                      ),
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
                                            'assets/images/map_view_icon.svg',
                                            'Map View',
                                            1,
                                            18),
                                      ),
                                      Tab(
                                        icon: _buildTabIcon(
                                            context,
                                            'assets/images/overall_tab_icon.svg',
                                            'Overall Score',
                                            2,
                                            30),
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
                          physics: NeverScrollableScrollPhysics(),
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
                                                          .locationHits
                                                          .toString(),
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
                            // Map View
                            LocationListMapView(
                              accountId: widget.accountID,
                              subAccountId: widget.subAccountID,
                            ),
                            // Overall Score
                            Consumer<MyLocationListProvider>(
                              builder: (context, locationListProvider, child) {
                                return LocationTable(
                                    locations:
                                        locationListProvider.myLocationList);
                              },
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
                  accountId: widget.accountID,
                  subAccountId: widget.subAccountID,
                  sovId: widget.sovID,
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
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Row(
                children: [
                  // Horizontally scrollable row for all chips
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          // Show country options as chips
                          if (locationListProvider.countries.isNotEmpty)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4.0),
                              child: Chip(
                                label: Text(
                                    "Country: ${locationListProvider.countries.join(', ')}"),
                                onDeleted: () {
                                  locationListProvider.clearCountryFilter();
                                  locationListProvider.fetchLocationList(
                                    context,
                                    locationQuery,
                                    1,
                                    40,
                                    widget.accountID,
                                    widget.subAccountID,
                                    widget.sovID,
                                    widget.initialProcessId,
                                    widget.initialSubProcessId,
                                  );
                                },
                              ),
                            ),

                          // Show certifications as chips
                          if (locationListProvider.certifications.isNotEmpty)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4.0),
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
                                    widget.sovID,
                                    widget.initialProcessId,
                                    widget.initialSubProcessId,
                                  );
                                },
                              ),
                            ),

                          // Show hazard ratings as chips with circles for selected ratings
                          if (locationListProvider.hazardRatings.isNotEmpty)
                            for (var hazard
                                in locationListProvider.hazardRatings.keys)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4.0),
                                child: Chip(
                                  label: Row(
                                    children: [
                                      Text(hazard),
                                      // Hazard name
                                      const SizedBox(width: 8),
                                      // Space before ratings
                                      if (locationListProvider
                                          .hazardRatings[hazard]!.isEmpty)
                                        Text(
                                            'All') // If no ratings are selected
                                      else
                                        Row(
                                          children: locationListProvider
                                              .hazardRatings[hazard]!
                                              .map((rating) {
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 4.0),
                                              child: CircleAvatar(
                                                radius: 10,
                                                backgroundColor:
                                                    _getRatingColor(rating),
                                                child: Text(
                                                  '$rating',
                                                  style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                    ],
                                  ),
                                  onDeleted: () {
                                    locationListProvider
                                        .clearHazardFilter(hazard);
                                    locationListProvider.fetchLocationList(
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

                          // Show ratings as chips
                          if (locationListProvider.rating.isNotEmpty)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4.0),
                              child: Chip(
                                label: Text(
                                    "Ratings: ${locationListProvider.rating.join(', ')}"),
                                onDeleted: () {
                                  locationListProvider.clearRatingsFilter();
                                  locationListProvider.fetchLocationList(
                                    context,
                                    locationQuery,
                                    1,
                                    40,
                                    widget.accountID,
                                    widget.subAccountID,
                                    widget.sovID,
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

                  // Clear all filters button (text button at the end)
                  if (locationListProvider
                      .hasAnyFilterApplied()) // Check if any filter is applied
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
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
                          );
                        },
                        child: const Text(
                          'Clear All',
                          style: TextStyle(
                              color: Colors.red), // Color for emphasis
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: locationListProvider.isLoading
                  ? Column(
                      children: [
                        SizedBox(
                          height: 100,
                        ),
                        Center(
                          child: CircularProgressIndicator(),
                        ),
                      ],
                    )
                  : locationListProvider.myLocationList.isEmpty
                      ? Center(
                          child: Text(
                            LanguageService.getTranslated(
                                context, "location_list_app_no_accounts_text"),
                            style: typography.Body1,
                          ),
                        )
                      : ListView.builder(
                          physics: ClampingScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: locationListProvider.myLocationList.length,
                          itemBuilder: (context, index) {
                            if (index ==
                                locationListProvider.myLocationList.length -
                                    1) {
                              // Check if it's the last item
                              if (locationListProvider.isNextPageLoading) {
                                // Display loading indicator
                                return Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              } else if (locationListProvider.page >=
                                      locationListProvider.totalPages &&
                                  locationListProvider
                                      .myLocationList.isNotEmpty) {
                                // Display end of list message
                                print(
                                    "location list: ${locationListProvider.myLocationList}");
                                return Column(
                                  children: [
                                    MyLocationCard(
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
                                      riskScore: locationListProvider
                                              .myLocationList[index]
                                              .overallScore ??
                                          0,
                                      dataCompletenessScore: 0,
                                      isAutoCertified: true,
                                      tags: (locationListProvider
                                              .myLocationList[index]?.tags ??
                                          []),
                                      onDelete: (locationId) {
                                        // Show delete confirmation dialog
                                        showDeleteConfirmationDialog(
                                          context,
                                          () async {
                                            print(
                                                "Deleting location $locationId");
                                            // Delete the location
                                            await Provider.of<
                                                        MyLocationListProvider>(
                                                    context,
                                                    listen: false)
                                                .deleteLocations(
                                                    context,
                                                    widget.accountID,
                                                    widget.subAccountID,
                                                    widget.sovID,
                                                    [locationId]);

                                            // Refresh the list after deletion
                                            Provider.of<MyLocationListProvider>(
                                                    context,
                                                    listen: false)
                                                .fetchLocationList(
                                              context,
                                              locationQuery,
                                              1,
                                              40,
                                              widget.accountID,
                                              widget.subAccountID,
                                              widget.sovID,
                                              widget.initialProcessId,
                                              widget.initialSubProcessId,
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
                                        locationListProvider
                                            .addTagsToSelectedLocations(
                                                context,
                                                widget.accountID,
                                                widget.subAccountID,
                                                locationId);
                                      },
                                      getData: () {
                                        locationListProvider.fetchLocationList(
                                          context,
                                          locationQuery,
                                          1,
                                          40,
                                          widget.accountID,
                                          widget.subAccountID,
                                          widget.sovID,
                                          widget.initialProcessId,
                                          widget.initialSubProcessId,
                                        );
                                      },
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Center(
                                        child: Text(
                                          LanguageService.getTranslated(context,
                                              "location_list_end_of_list"),
                                          style: typography.Body1,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              } else {
                                // Trigger fetching the next page
                                locationListProvider.page =
                                    locationListProvider.page + 1;
                                print(
                                    "Fetching page ${locationListProvider.page}");
                                print(
                                    "Query: $locationQuery, Page: ${locationListProvider.page}");
                                locationListProvider.fetchLocationList(
                                  context,
                                  locationQuery,
                                  // Pass the search query if any
                                  locationListProvider.page,
                                  40,
                                  // Page size
                                  widget.accountID,
                                  widget.subAccountID,
                                  widget.initialProcessId,
                                  widget.initialSubProcessId,
                                );
                                return SizedBox();
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
                                              .screenshots !=
                                          null &&
                                      locationListProvider.myLocationList[index]
                                          .screenshots!.isNotEmpty
                                  ? locationListProvider.myLocationList[index]
                                          .screenshots![0].imageUrl ??
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
                              address: locationListProvider
                                      .myLocationList[index]
                                      .finalAddress
                                      ?.address ??
                                  '',
                              percentage: double.parse(locationListProvider
                                      .myLocationList[index]
                                      .finalAddress
                                      ?.percent ??
                                  '0'),
                              geocodingScore: locationListProvider
                                      .myLocationList[index]
                                      .finalAddress
                                      ?.score ??
                                  0,
                              riskScore: locationListProvider
                                      .myLocationList[index].overallScore ??
                                  0,
                              dataCompletenessScore: 0,
                              isAutoCertified: true,
                              tags: (locationListProvider
                                      .myLocationList[index]?.tags ??
                                  []),
                              onDelete: (locationId) {
                                // Show delete confirmation dialog
                                showDeleteConfirmationDialog(
                                  context,
                                  () async {
                                    print("Deleting location $locationId");
                                    // Delete the location
                                    await Provider.of<MyLocationListProvider>(
                                            context,
                                            listen: false)
                                        .deleteLocations(
                                            context,
                                            widget.accountID,
                                            widget.subAccountID,
                                            widget.sovID,
                                            [locationId]);

                                    // Refresh the list after deletion
                                    Provider.of<MyLocationListProvider>(context,
                                            listen: false)
                                        .fetchLocationList(
                                      context,
                                      locationQuery,
                                      1,
                                      40,
                                      widget.accountID,
                                      widget.subAccountID,
                                      widget.initialProcessId,
                                      widget.initialSubProcessId,
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
                                    context,
                                    widget.accountID,
                                    widget.subAccountID,
                                    locationId);
                              },
                              getData: () {
                                locationListProvider.fetchLocationList(
                                  context,
                                  locationQuery,
                                  1,
                                  40,
                                  widget.accountID,
                                  widget.subAccountID,
                                  widget.sovID,
                                  widget.initialProcessId,
                                  widget.initialSubProcessId,
                                );
                              },
                            );
                          },
                        ),
            ),
          ],
        );
      },
    );
  }

  _getLocationListCertifiedUI() {
    var typography = CustomTypography(context);
    return Consumer<MyLocationListProvider>(
      builder: (context, locationListProvider, child) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Row(
                children: [
                  // Horizontally scrollable row for all chips
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          // Show country options as chips
                          if (locationListProvider.countries.isNotEmpty)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4.0),
                              child: Chip(
                                label: Text(
                                    "Country: ${locationListProvider.countries.join(', ')}"),
                                onDeleted: () {
                                  locationListProvider.clearCountryFilter();
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

                          // Show certifications as chips
                          if (locationListProvider.certifications.isNotEmpty)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4.0),
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

                          // Show hazard ratings as chips with circles for selected ratings
                          if (locationListProvider.hazardRatings.isNotEmpty)
                            for (var hazard
                                in locationListProvider.hazardRatings.keys)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4.0),
                                child: Chip(
                                  label: Row(
                                    children: [
                                      Text(hazard),
                                      // Hazard name
                                      const SizedBox(width: 8),
                                      // Space before ratings
                                      if (locationListProvider
                                          .hazardRatings[hazard]!.isEmpty)
                                        Text(
                                            'All') // If no ratings are selected
                                      else
                                        Row(
                                          children: locationListProvider
                                              .hazardRatings[hazard]!
                                              .map((rating) {
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 4.0),
                                              child: CircleAvatar(
                                                radius: 10,
                                                backgroundColor:
                                                    _getRatingColor(rating),
                                                child: Text(
                                                  '$rating',
                                                  style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12),
                                                ),
                                              ),
                                            );
                                          }).toList(),
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
                              ),

                          // Show ratings as chips
                          if (locationListProvider.rating.isNotEmpty)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4.0),
                              child: Chip(
                                label: Text(
                                    "Ratings: ${locationListProvider.rating.join(', ')}"),
                                onDeleted: () {
                                  locationListProvider.clearRatingsFilter();
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

                  // Clear all filters button (text button at the end)
                  if (locationListProvider
                      .hasAnyFilterApplied()) // Check if any filter is applied
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
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
                          );
                        },
                        child: const Text(
                          'Clear All',
                          style: TextStyle(
                              color: Colors.red), // Color for emphasis
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: locationListProvider.isCertifiedLoading
                  ? Column(
                      children: [
                        SizedBox(height: 100),
                        Center(child: CircularProgressIndicator()),
                      ],
                    )
                  : locationListProvider.certifiedLocationList.isEmpty
                      ? Center(
                          child: Text(
                              LanguageService.getTranslated(context,
                                  "location_list_app_no_accounts_text"),
                              style: typography.Body1),
                        )
                      : ListView.builder(
                          physics: ClampingScrollPhysics(),
                          shrinkWrap: true,
                          itemCount:
                              locationListProvider.certifiedLocationList.length,
                          itemBuilder: (context, index) {
                            if (index ==
                                locationListProvider
                                        .certifiedLocationList.length -
                                    1) {
                              if (locationListProvider
                                  .isNextPageCertifiedLoading) {
                                return Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Center(
                                      child: CircularProgressIndicator()),
                                );
                              } else if (locationListProvider.certifiedPage >=
                                      locationListProvider
                                          .certifiedTotalPages &&
                                  locationListProvider
                                      .certifiedLocationList.isNotEmpty) {
                                return Column(
                                  children: [
                                    myLocationCertifiedCard(
                                        locationListProvider, index, context),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Center(
                                          child: Text(
                                              LanguageService.getTranslated(
                                                  context,
                                                  "location_list_end_of_list"),
                                              style: typography.Body1)),
                                    ),
                                  ],
                                );
                              } else {
                                locationListProvider.certifiedPage =
                                    locationListProvider.certifiedPage + 1;
                                locationListProvider.fetchCertifiedLocationList(
                                  context,
                                  "",
                                  locationListProvider.certifiedPage,
                                  40,
                                  widget.accountID,
                                  widget.subAccountID,
                                  widget.initialProcessId,
                                  widget.initialSubProcessId,
                                );
                                return SizedBox();
                              }
                            }

                            /*return locationListCard(index,
                      locationListProvider.certifiedLocationList);*/
                            return myLocationCertifiedCard(
                                locationListProvider, index, context);
                          },
                        ),
            ),
          ],
        );
      },
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
      address: locationListProvider
              .certifiedLocationList[index].finalAddress?.address ??
          '',
      percentage: double.parse(locationListProvider
              .certifiedLocationList[index].finalAddress?.percent ??
          '0'),
      geocodingScore:
          locationListProvider.certifiedLocationList[index].geocodingScore ?? 0,
      riskScore:
          locationListProvider.certifiedLocationList[index].overallScore ?? 0,
      dataCompletenessScore: 0,
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
                .deleteLocations(context, widget.accountID, widget.subAccountID,
                    widget.sovID, [locationId]);

            // Refresh the list after deletion
            Provider.of<MyLocationListProvider>(context, listen: false)
                .fetchLocationList(
              context,
              locationQuery,
              1,
              40,
              widget.accountID,
              widget.subAccountID,
              widget.sovID,
              widget.initialProcessId,
              widget.initialSubProcessId,
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
            context, widget.accountID, widget.subAccountID, locationId);
      },
      getData: () {
        locationListProvider.fetchLocationList(
          context,
          locationQuery,
          1,
          40,
          widget.accountID,
          widget.subAccountID,
          widget.sovID,
          widget.initialProcessId,
          widget.initialSubProcessId,
        );
      },
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
          .deleteLocations(context, "widget.accountId", "widget.subAccountId",
              widget.sovID, locationList);

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
                                                        subAccountId:
                                                            widget.subAccountID,
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
