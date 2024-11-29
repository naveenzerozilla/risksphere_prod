import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:green/design_system/components/rating_half_stars.dart';
import 'package:green/design_system/components/rating_slider.dart';
import 'package:green/models/my_location_list_model.dart';
import 'package:green/providers/connections_provider.dart';
import 'package:green/providers/location_list_provider.dart';
import 'package:green/providers/location_profile_provider.dart';
import 'package:green/providers/my_location_list_provider.dart';
import 'package:green/screens/listings/add_location_screen.dart';
import 'package:green/screens/listings/location_profile.dart';
import 'package:green/screens/listings/sov_location_list.dart';
import 'package:green/screens/listings/widgets/adaptive_tab_bar_locations.dart';
import 'package:green/screens/listings/widgets/animated_progress_indicatiors.dart';
import 'package:green/screens/listings/widgets/export_dialog.dart';
import 'package:green/screens/listings/widgets/listings_filter_screen.dart';
import 'package:green/screens/listings/widgets/location_card.dart';
import 'package:green/screens/listings/widgets/location_list_map_view.dart';
import 'package:green/screens/listings/widgets/maintenance_widget.dart';
import 'package:green/screens/listings/widgets/mapping_screen.dart';
import 'package:green/screens/listings/widgets/overall_score_table.dart';
import 'package:green/screens/processMonitoringScreen/process_monitoring_system.dart';
import 'package:green/service/shared_preference_service.dart';
import 'package:lottie/lottie.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:remixicon/remixicon.dart';
import 'package:rxdart/rxdart.dart';
import 'package:screenshot/screenshot.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../constants/enums.dart';
import '../../design_system/components/custom_appbar.dart';
import '../../design_system/components/custom_button.dart';
import '../../design_system/components/custom_drawer.dart';
import '../../design_system/components/custom_gradient_circular_progress_bar.dart';
import '../../design_system/components/rating_bar.dart';
import '../../design_system/primitives/app_colors.dart';
import '../../design_system/primitives/custom_typography.dart';
import '../../design_system/primitives/utilities/custom_spacing.dart';
import '../../models/location_list_model.dart';
import '../../models/sov_list_model.dart';
import '../../models/transfer_autocomplete_model.dart';
import '../../providers/job_monitoring_provier.dart';
import '../../providers/sov_list_provider.dart';
import '../../providers/sub_account_list_provider.dart';
import '../../providers/theme_provider.dart';
import 'package:green/models/role_model.dart' as roleModel;
import '../../providers/upload_sov_provider.dart';
import '../../service/api_service.dart';
import '../../service/language_service.dart';
import '../../utils/api_constants.dart';
import 'widgets/auto_complete_options_sovs.dart';

class MyLocationList extends StatefulWidget {
  final String accountID;
  final String subAccountID;
  final String accountName;
  final String subAccountName;

  const MyLocationList({
    super.key,
    this.accountID = '',
    this.subAccountID = '',
    this.accountName = '',
    this.subAccountName = '',
  });

  @override
  State<MyLocationList> createState() => _MyLocationListState();
}

class _MyLocationListState extends State<MyLocationList>
    with TickerProviderStateMixin {
  bool _isExpanded = false;
  bool _showNotificationDot = true;
  TabController? _masterTabController;
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

  TabController? _mainTabController;
  int selectedMainTab = 0;
  int selectedTab = 0;

  bool isMaintenance = false;

  /// Sov Things
  TextEditingController _textEditingController = TextEditingController();
  String _sovQuery = "";
  bool showCheckbox = false;
  TextEditingController _sovEditNameController = TextEditingController();

  bool addToSOVCheck = false;

  String selectedSovId = "";
  TextEditingController sovController = TextEditingController();
  TextEditingController tagController = TextEditingController();

  void debounce(VoidCallback callback,
      {Duration duration = const Duration(seconds: 1)}) {
    if (deBouncer != null) {
      deBouncer!.cancel();
    }
    deBouncer = Timer(duration, callback);
  }

  @override
  void initState() {
    super.initState();
    // Initially clear all filters
    Provider.of<MyLocationListProvider>(context, listen: false)
        .clearAllFilters();

    _mainTabController = TabController(length: 3, vsync: this);
    _mainTabController?.addListener(() {
      setState(() {
        selectedMainTab = _mainTabController?.index ?? 0;
      }); // This ensures that the widget rebuilds when the tab changes
    });
    _masterTabController = TabController(length: 4, vsync: this);
    _tabController = TabController(length: 2, vsync: this);
    _tabController?.addListener(() {
      setState(() {
        selectedTab = _tabController?.index ?? 0;
      });
      if (_tabController?.index == 0) {
        _selectedScreen = Screens.locationList;
        var locationListProvider =
            Provider.of<MyLocationListProvider>(context, listen: false);
        locationListProvider.page = 0;
        Provider.of<MyLocationListProvider>(context, listen: false)
            .fetchLocationList(
              context,
              "",
              1,
              40,
              widget.accountID,
              widget.subAccountID,
            )
            .then((value) => setState(() {}));
      } else {
        _selectedScreen = Screens.certifiedLocationList;
        var locationListProvider =
            Provider.of<MyLocationListProvider>(context, listen: false);
        locationListProvider.page = 0;
        locationListProvider.clearRatingsFilter();
        Provider.of<MyLocationListProvider>(context, listen: false)
            .fetchCertifiedLocationList(
              context,
              "",
              1,
              40,
              widget.accountID,
              widget.subAccountID,
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
    _getMaintainancePeriod();
  }

  @override
  void dispose() {
    // Dispose of all controllers to prevent ticker leaks
    _mainTabController?.dispose();
    _masterTabController?.dispose();
    _tabController?.dispose();
    Provider.of<MyLocationListProvider>(context, listen: false).clearAllFilters();
    Provider.of<MyLocationListProvider>(context, listen: false).clearSelection();
    Provider.of<MyLocationListProvider>(context, listen: false).clearRatingsFilter();
    Provider.of<MyLocationListProvider>(context, listen: false).myLocationList.clear();
    Provider.of<MyLocationListProvider>(context, listen: false).certifiedLocationList.clear();
    Provider.of<MyLocationListProvider>(context, listen: false).selectedLocations.clear();
    Provider.of<MyLocationListProvider>(context, listen: false).summaryList.clear();
    Provider.of<MyLocationListProvider>(context, listen: false).certifiedLocationHits;
    Provider.of<MyLocationListProvider>(context, listen: false).locationHits;
    super.dispose();
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
        )
        .then((value) => WidgetsBinding.instance!.addPostFrameCallback((_) {
              setState(() {});
            }));
    //Provider.of<LocationListProvider>(context, listen: false).fetchCampusIds("widget.accountId", "widget.subAccountId", "widget.sovId");
    Provider.of<SOVListProvider>(context, listen: false).page = 0;
    Provider.of<SOVListProvider>(context, listen: false).fetchSovList(
        context, widget.accountID, widget.subAccountID, "", 0, 10);
    Provider.of<SOVListProvider>(context, listen: false)
        .fetchAutoCompleteSovListLocations(
            context, widget.accountID, widget.subAccountID);
    Provider.of<MyLocationListProvider>(context, listen: false)
        .fetchAllLocationList(context, widget.accountID, widget.subAccountID);
    // Initialize the JobMonitoringProvider and fetch the company IDs
    Provider.of<JobMonitoringProvider>(context, listen: false)
        .fetchCompanyIds();
  }

  ScrollController _scrollController = ScrollController();

  void _scrollLeft() {
    _scrollController.animateTo(
      _scrollController.offset - 100, // Scroll left by 100 pixels
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _scrollRight() {
    _scrollController.animateTo(
      _scrollController.offset + 100, // Scroll right by 100 pixels
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context1) {
    var typography = CustomTypography(context);
    return SafeArea(
      child: Consumer<ThemeProvider>(
        builder: (buildContext, themeProvider, child) {
          return Scaffold(
            key: _scaffoldKey,
            backgroundColor:
                themeProvider.getTheme.colorScheme.surfaceContainerLowest,
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
            floatingActionButton: SpeedDial(
              animatedIcon: AnimatedIcons.menu_close,
              animatedIconTheme: IconThemeData(size: 22.0),
              backgroundColor: AppColors.primaryMain,
              foregroundColor: themeProvider.getTheme.colorScheme.onPrimary,
              children: [
                SpeedDialChild(
                  child: Icon(Icons.add),
                  backgroundColor: AppColors.primaryMain,
                  foregroundColor: themeProvider.getTheme.colorScheme.onPrimary,
                  label: 'Add Location',
                  labelStyle: typography.Body1,
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => AddLocationScreen(
                        accountId: widget.accountID,
                        subAccountId: widget.subAccountID,
                        sovId: "",
                        accountName: widget.accountName,
                        subAccountName: widget.subAccountName,
                      ),
                    )).then((value) {
                      if (value != null) {
                        if (value) {
                          Provider.of<MyLocationListProvider>(context,
                                  listen: false)
                              .fetchLocationList(
                                context,
                                "",
                                1,
                                40,
                                widget.accountID,
                                widget.subAccountID,
                              )
                              .then((value) => setState(() {}));
                        }
                      }
                    });
                  },
                ),
                SpeedDialChild(
                  child: Icon(Icons.upload),
                  backgroundColor: AppColors.primaryMain,
                  foregroundColor: themeProvider.getTheme.colorScheme.onPrimary,
                  label: 'Upload SOV',
                  labelStyle: typography.Body1,
                  onTap: () {
                    if (isMaintenance) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'SOV upload is disabled during maintenance period.'),
                        ),
                      );
                    } else {
                      _showUploadBottomSheet(
                          widget.accountID, widget.subAccountID, "");
                    }
                  },
                ),
                SpeedDialChild(
                  child: Icon(Icons.download),
                  backgroundColor: AppColors.primaryMain,
                  foregroundColor: themeProvider.getTheme.colorScheme.onPrimary,
                  label: 'Export Locations',
                  labelStyle: typography.Body1,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return ExportDialog(
                          accountId: widget.accountID,
                          subAccountId: widget.subAccountID,
                          sovId: "",
                          locationId: selectedMainTab == 0
                              ? Provider.of<MyLocationListProvider>(context,
                                      listen: false)
                                  .myLocationList
                                  .map((location) => location.id ?? "")
                                  .toList()
                              : Provider.of<MyLocationListProvider>(context,
                                      listen: false)
                                  .certifiedLocationList
                                  .map((location) => location.id ?? "")
                                  .toList(),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
            body: Stack(
              children: [
                /*  Positioned.fill(
                  child: Image.asset(
                    'assets/images/mesh.png',
                    fit: BoxFit.cover,
                  ),
                ),*/
                Column(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          SizedBox(height: CustomSpacing.two),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Row(
                              children: [
                                Text(widget.accountName,
                                    style: typography.InputLabel),
                                Text(' > ', style: typography.InputLabel),
                                Text(widget.subAccountName,
                                    style: typography.InputLabel),
                              ],
                            ),
                          ),
                          SizedBox(height: CustomSpacing.four),
                          // Master TabBar
                          Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHigh,
                              borderRadius:
                                  BorderRadius.circular(16), // Rounded edges
                            ),
                            margin: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 0),
                            child: DefaultTabController(
                              length: 4,
                              child: Column(
                                children: <Widget>[
                                  // Container for the TabBar with arrows
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHigh,
                                    ),
                                    height: 50,
                                    child: Row(
                                      children: <Widget>[
                                        // Left arrow button
                                        IconButton(
                                          icon: Icon(Icons.arrow_left,
                                              color: Colors.grey),
                                          onPressed: _scrollLeft,
                                        ),
                                        // Scrollable TabBar
                                        Expanded(
                                          child: SingleChildScrollView(
                                            controller: _scrollController,
                                            scrollDirection: Axis.horizontal,
                                            child: TabBar(
                                              controller: _masterTabController,
                                              tabAlignment: TabAlignment.start,
                                              labelStyle: typography.Subtitle2,
                                              isScrollable: true,
                                              indicatorColor:
                                                  Colors.lightBlueAccent,
                                              labelColor:
                                                  Colors.lightBlueAccent,
                                              unselectedLabelColor: Colors.grey,
                                              tabs: [
                                                Tab(
                                                  text: 'Locations',
                                                ),
                                                Tab(
                                                  text: 'SOVs',
                                                ),
                                                Tab(text: 'Shared'),
                                                Tab(text: 'Access Requests'),
                                              ],
                                            ),
                                          ),
                                        ),
                                        // Right arrow button
                                        IconButton(
                                          icon: Icon(Icons.arrow_right,
                                              color: Colors.grey),
                                          onPressed: _scrollRight,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Master TabBarView for the Tab Content
                          Expanded(
                            child: TabBarView(
                              physics: NeverScrollableScrollPhysics(),
                              controller: _masterTabController,
                              children: [
                                Consumer<MyLocationListProvider>(builder:
                                    (context, myLocationListProvider, child) {
                                  return _getLocationListBodyUI(
                                      myLocationListProvider, "");
                                }),
                                Container(
                                  margin: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  child: sovBody(typography),
                                ),
                                _getComingSoonUI(),
                                _getComingSoonUI(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            endDrawer: Drawer(
              child: SafeArea(
                child: ListingsFilterScreen(
                  accountId: widget.accountID,
                  subAccountId: widget.subAccountID,
                  sovId: "widget.sovId",
                  searchQuery: locationQuery,
                  showGeoRatings: selectedMainTab == 0 && selectedTab != 1,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _getLocationListBodyUI(
      MyLocationListProvider myLocationListProvider, String sovID) {
    final isSelectionMode = myLocationListProvider.selectedLocations.isNotEmpty;

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
                  .surfaceContainerHighest, // Set your border color here
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
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHigh,
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
                      if (_selectedScreen == Screens.locationList) {
                        if (locationListProvider.selectedLocations.length <
                            locationListProvider.myLocationList.length) {
                          locationListProvider.selectAllLocations(false);
                        } else {
                          locationListProvider.clearSelection();
                        }
                      } else if (_selectedScreen ==
                          Screens.certifiedLocationList) {
                        if (locationListProvider.selectedLocations.length <
                            locationListProvider.certifiedLocationList.length) {
                          locationListProvider.selectAllLocations(true);
                        } else {
                          locationListProvider.clearSelection();
                        }
                      }
                    },
                    child: Text(
                      _selectedScreen == Screens.locationList
                          ? locationListProvider.selectedLocations.length <
                                  locationListProvider.myLocationList.length
                              ? 'Select All'
                              : 'Deselect All'
                          : locationListProvider.selectedLocations.length <
                                  locationListProvider
                                      .certifiedLocationList.length
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
                          title: Text('Export Selected Locations'),
                          content: Text(
                              'Are you sure you want to export ${locationListProvider.selectedLocations.length} locations?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                if (_selectedScreen == Screens.locationList) {
                                  // On export button click
                                  List<String> selectedSovIds =
                                      Provider.of<MyLocationListProvider>(
                                              context,
                                              listen: false)
                                          .myLocationList
                                          .where((location) =>
                                              location.isSelected ?? false)
                                          .map((sov) => sov.id!)
                                          .toList();

                                  if (selectedSovIds.isNotEmpty) {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return ExportDialog(
                                          accountId: widget.accountID,
                                          subAccountId: widget.subAccountID,
                                          locationId: selectedSovIds,
                                        );
                                      },
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(SnackBar(
                                      content: Text(
                                        LanguageService.getTranslated(
                                            context, "no_items_selected_error"),
                                        style: typography.Body1,
                                      ),
                                    ));
                                  }
                                } else if (_selectedScreen ==
                                    Screens.certifiedLocationList) {
                                  // On export button click
                                  List<String> selectedLoactionIds =
                                      Provider.of<MyLocationListProvider>(
                                              context,
                                              listen: false)
                                          .certifiedLocationList
                                          .where((location) =>
                                              location.isSelected ?? false)
                                          .map((sov) => sov.id!)
                                          .toList();

                                  if (selectedLoactionIds.isNotEmpty) {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return ExportDialog(
                                          accountId: widget.accountID,
                                          subAccountId: widget.subAccountID,
                                          locationId: selectedLoactionIds,
                                        );
                                      },
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(SnackBar(
                                      content: Text(
                                        LanguageService.getTranslated(
                                            context, "no_items_selected_error"),
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
                        locationListProvider.addTagsToSelectedLocations(
                            context, widget.accountID, widget.subAccountID);
                      },
                      icon: Icon(Symbols.note_stack_add),
                      tooltip: 'Add Tag'),
                  IconButton(
                    onPressed: () {
                      // Implement bulk add to SOV
                      locationListProvider.addSelectedToSOV(
                          context,
                          widget.accountID,
                          widget.subAccountID,
                          widget.accountName,
                          widget.subAccountName,
                          _masterTabController);
                    },
                    icon: Icon(Symbols.list_alt_add),
                    tooltip: 'Add to SOV',
                  ),
                  IconButton(
                    onPressed: () {
                      // Show delete confirmation dialog
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Delete Selected Locations'),
                          content: Text(
                              'Are you sure you want to delete ${locationListProvider.selectedLocations.length} locations?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                locationListProvider.deleteSelectedLocations(
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
                                      Scaffold.of(context).openEndDrawer();
                                    },
                                    child: Icon(
                                      Icons.filter_list,
                                      size: 24,
                                    ),
                                  ),
                                  SizedBox(width: CustomSpacing.two),
                                ],
                              )
                            : SizedBox(),
                        // if selected main tab is 1 then show the Generate Heatmap button
                        SizedBox(width: CustomSpacing.two),
                        TooltipTheme(
                          data: TooltipThemeData(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            textStyle: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
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
                                    i < locationListProvider.summaryList.length;
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
                          leading: Icon(Icons.upload),
                          title: Text('Upload SOV', style: typography.Body1),
                          onTap: () {
                            // Add your logic for uploading SOV
                            if (isMaintenance) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'SOV upload is disabled during maintenance period.'),
                                ),
                              );
                            } else {
                              /* _showUploadDialog(
                                  widget.accountID, widget.subAccountID, "");*/
                              _showUploadBottomSheet(
                                  widget.accountID, widget.subAccountID, "");
                            }
                          },
                        ),
                      ),
                      PopupMenuItem(
                        child: ListTile(
                          leading: Icon(Icons.add),
                          title: Text('Add Location', style: typography.Body1),
                          onTap: () {
                            print(
                                "sending account name: ${widget.accountName}");
                            if (isMaintenance) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Adding locations is disabled during maintenance period.'),
                                ),
                              );
                            } else {
                              _selectedScreen = Screens.addLocation;
                              print(
                                  "sending account name: ${widget.accountName}");
                              print(
                                  "sending sub account name: ${widget.subAccountName}");
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => AddLocationScreen(
                                  accountId: widget.accountID,
                                  subAccountId: widget.subAccountID,
                                  sovId: "",
                                  accountName: widget.accountName,
                                  subAccountName: widget.subAccountName,
                                ),
                              ));
                            }
                          },
                        ),
                      ),
                      PopupMenuItem(
                        child: ListTile(
                          leading: Icon(Icons.download),
                          title:
                              Text('Export Locations', style: typography.Body1),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return ExportDialog(
                                  accountId: widget.accountID,
                                  subAccountId: widget.subAccountID,
                                  sovId: "",
                                  locationId: selectedMainTab == 0
                                      ? myLocationListProvider.myLocationList
                                          .map((location) => location.id ?? "")
                                          .toList()
                                      : myLocationListProvider
                                          .certifiedLocationList
                                          .map((location) => location.id ?? "")
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
        Consumer<JobMonitoringProvider>(
            builder: (context, jobMonitoringProvider, child) {
          return Container(
            child: _getLiveUI(jobMonitoringProvider),
          );
        }),
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
                              Provider.of<LocationListProvider>(context,
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
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(8),
          ),
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          child: ClipRRect(
            clipBehavior: Clip.antiAlias,
            borderRadius: BorderRadius.circular(8),
            child: GNav(
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
             // backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                rippleColor: Colors.grey[800]!, // tab button ripple color when pressed
                hoverColor: Colors.grey[700]!, // tab button hover color
                haptic: true, // haptic feedback
                duration: Duration(milliseconds: 100), // tab animation duration
                tabBorderRadius: 8,
                //tabActiveBorder: Border.all(color: Colors.black, width: 1), // tab button border
                //tabBorder: Border.all(color: Colors.grey, width: 1), // tab button border
                //tabShadow: [BoxShadow(color: Colors.grey.withOpacity(0.5), blurRadius: 8)], // tab button shadow
                curve: Curves.easeOutExpo, // tab animation curves

                gap: 8, // the tab button gap between icon and text
                color: Colors.grey[300], // unselected icon color
                activeColor: AppColors.primaryMain, // selected icon and text color
                iconSize: 24, // tab button icon size
                tabBackgroundColor: AppColors.primaryMain.withOpacity(
                0.16), // selected tab background color

                onTabChange: (index) {
                  setState(() {
                    selectedMainTab = index;
                    if (index == 0) {
                      _mainTabController?.animateTo(0);
                    } else if (index == 1) {
                      _mainTabController?.animateTo(1);
                    } else if (index == 2) {
                      _mainTabController?.animateTo(2);
                    }
                  });
                },
                tabs: [
                  GButton(
                    icon: Remix.file_list_3_line,
                    text: 'Location List',
                  ),
                  GButton(
                    icon: Remix.road_map_line,
                    text: 'Map View',
                  ),
                  GButton(
                    icon: Remix.bar_chart_box_ai_line,
                    text: 'Overall Score',
                  ),
                ]
            ),
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
                    builder: (context, locationListProvider, child) {
                      return TabBar(
                        controller: _tabController,
                        labelStyle: typography.BottomNavigationActiveLabel,
                        tabs: [
                          Tab(
                            child: InkWell(
                              onTap: () {
                                _tabController?.animateTo(0);
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Tab(
                                    text: LanguageService.getTranslated(context,
                                        "locationlist_app_connections_tab_all"),
                                  ),
                                  SizedBox(width: CustomSpacing.two),
                                  SizedBox(
                                    height: 25,
                                    child: Chip(
                                      labelPadding: EdgeInsets.all(0),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      label: Text(
                                        locationListProvider.locationHits
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
                                    "No certified locations.",
                                    style: typography.Body1,
                                  ),
                                ));
                              }
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Tab(
                                  text: LanguageService.getTranslated(context,
                                      "locationlist_app_connections_tab_certified"),
                                ),
                                SizedBox(width: CustomSpacing.two),
                                SizedBox(
                                  height: 25,
                                  child: Chip(
                                    labelPadding: EdgeInsets.all(0),
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    label: Text(
                                      locationListProvider.certifiedLocationHits
                                          .toString(),
                                      style:
                                          typography.BottomNavigationActiveLabel
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
                      locations: locationListProvider.myLocationList);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _getLiveUI(JobMonitoringProvider provider) {
    var typography = CustomTypography(context);

    // Define the secondary stream
    Stream<QuerySnapshot<Map<String, dynamic>>> processStream;

    if (provider.isSuperAdmin) {
      processStream = FirebaseFirestore.instance
          .collection('processes')
          .orderBy('created_at', descending: true)
          .limit(5)
          .snapshots();
    } else if (provider.docIds.isNotEmpty) {
      // Split docIds into chunks of 30 to avoid Firestore's 'whereIn' limit
      List<List<String>> chunks = [];
      for (var i = 0; i < provider.docIds.length; i += 30) {
        chunks.add(provider.docIds.sublist(
          i,
          i + 30 > provider.docIds.length ? provider.docIds.length : i + 30,
        ));
      }

      // Combine streams for each chunk
      List<Stream<QuerySnapshot<Map<String, dynamic>>>> chunkStreams = chunks
          .map((chunk) => FirebaseFirestore.instance
              .collection('processes')
              .where(FieldPath.documentId, whereIn: chunk)
              .orderBy('created_at', descending: true)
              .limit(5)
              .snapshots())
          .toList();

      // Merge all chunk streams into a single stream
      processStream = Rx.merge(chunkStreams);
    } else {
      processStream = Stream.empty();
    }

    // Combine both streams using Rx.combineLatest2
    var combinedStream = Rx.combineLatest2<
        DocumentSnapshot<Map<String, dynamic>>,
        QuerySnapshot<Map<String, dynamic>>,
        Map<String, dynamic>>(
      FirebaseFirestore.instance
          .collection('subaccount')
          .doc(widget.subAccountID)
          .snapshots(),
      processStream,
      (heatmapSnapshot, processSnapshot) {
        return {
          'heatmapData': heatmapSnapshot.data(),
          'processData': processSnapshot.docs.isNotEmpty
              ? processSnapshot.docs.first.data()
              : null,
        };
      },
    );

    return StreamBuilder<Map<String, dynamic>>(
      stream: combinedStream,
      builder: (context, snapshot) {
        print('Live UI snapshot: ${snapshot.data}');
        print('Live UI snapshot connection state: ${snapshot.connectionState}');
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Display a loading indicator while waiting for data
          return const SizedBox
              .shrink(); // Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          // Handle error case
          return const SizedBox.shrink();
        }

        if (snapshot.hasData) {
          var data = snapshot.data!;
          var heatmapStatus = data['heatmapData']?['heatmap_status'] ?? '';
          var processStatus = data['processData']?['status'] ?? '';

          print('Heatmap status: $heatmapStatus');
          print('Process status: $processStatus');

          return Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Priority given to "Processing"
              if (processStatus.toString().toLowerCase() != 'completed')
                GestureDetector(
                  onTap: () {
                    Navigator.of(context)
                        .push(MaterialPageRoute(
                          builder: (_) => ProcessMonitoringScreen(),
                        ))
                        .then((value) => _getData());
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Lottie.asset(
                          'assets/lottie/loading.json',
                          // Lottie file for 'in-progress' animation
                          width: 24,
                          height: 24,
                        ),
                        SizedBox(width: 8.0),
                        Text(
                          'Processing',
                          style: typography.Body2.copyWith(
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                )
              // "Generating Heatmap" is only shown if "Processing" is completed
              else if (heatmapStatus.toString().toLowerCase() == 'initiated')
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
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

              //SizedBox(height: CustomSpacing.two),
            ],
          );
        }

        // Return an empty widget if no data is available
        return SizedBox.shrink();
      },
    );
  }

  _getComingSoonUI() {
    var typography = CustomTypography(context);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            child: Center(
              child: Column(
                children: [
                  Expanded(
                    child: Text(
                        LanguageService.getTranslated(
                            context, 'coming_soon_title'),
                        style: typography.H4),
                  ),
                  SizedBox(
                    height: CustomSpacing.two,
                  ),
                  Text(
                      LanguageService.getTranslated(
                          context, 'coming_soon_subtitle'),
                      style: typography.Body1),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabIcon(BuildContext context, String iconPath, String label,
      int tabIndex, double iconSize) {
    // Check if TabController exists and whether this tab is selected
    bool isSelected = _mainTabController?.index == tabIndex;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0.0),
      // Adjust padding to control spacing
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: 12), // Add space between icon and label
          SvgPicture.asset(
            iconPath,
            height: iconSize,
            colorFilter: ColorFilter.mode(
              isSelected
                  ? AppColors.primaryMain
                  : Colors.white.withOpacity(0.56),
              BlendMode.srcIn,
            ),
          ),
          SizedBox(width: 8), // Add spacejjjjjjjj between icon and label
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
                                  print("Clearing ratings filter");
                                  locationListProvider.clearRatingsFilter();
                                  locationListProvider.fetchLocationList(
                                    context,
                                    locationQuery,
                                    1,
                                    40,
                                    widget.accountID,
                                    widget.subAccountID,
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
                                      imageUrl: (locationListProvider
                                                  .myLocationList[index]
                                                  .screenshots
                                                  ?.isNotEmpty ??
                                              false)
                                          ? locationListProvider
                                                  .myLocationList[index]
                                                  .screenshots![0]
                                                  .imageUrl ??
                                              ''
                                          : '',
                                      index: index,
                                      campusId: locationListProvider
                                              .myLocationList[index]
                                              .finalAddress
                                              ?.campusId ??
                                          '',
                                      accountId: widget.accountID,
                                      subAccountId: widget.subAccountID,
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
                                      dataCompletenessScore: 2,
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
                                                    "",
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
                                            );

                                            Navigator.of(context).pop();
                                          },
                                          [locationId],
                                        );
                                      },
                                      onAddToSOV: (locationId) {
                                        // Show add to SOV dialog
                                        // Implement bulk add to SOV
                                        locationListProvider.addSelectedToSOV(
                                            context,
                                            widget.accountID,
                                            widget.subAccountID,
                                            widget.accountName,
                                            widget.subAccountName,
                                            _masterTabController,
                                            locationId);
                                      },
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
                                      getData: _getData,
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
                                  40, // Page size
                                  widget.accountID,
                                  widget.subAccountID,
                                );
                                return SizedBox();
                              }
                            }

                            return MyLocationCard(
                              imageUrl: locationListProvider
                                          .myLocationList[index]
                                          .screenshots
                                          ?.isNotEmpty ==
                                      true
                                  ? locationListProvider.myLocationList[index]
                                          .screenshots![0].imageUrl ??
                                      ''
                                  : '',
                              campusId: locationListProvider
                                      .myLocationList[index]
                                      .finalAddress
                                      ?.campusId ??
                                  '',
                              index: index,
                              accountId: widget.accountID,
                              subAccountId: widget.subAccountID,
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
                              dataCompletenessScore: 2,
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
                                            "",
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
                                    );

                                    Navigator.of(context).pop();
                                  },
                                  [locationId],
                                );
                              },
                              onAddToSOV: (locationId) {
                                // Show add to SOV dialog
                                // Implement bulk add to SOV
                                locationListProvider.addSelectedToSOV(
                                    context,
                                    widget.accountID,
                                    widget.subAccountID,
                                    widget.accountName,
                                    widget.subAccountName,
                                    _masterTabController,
                                    locationId);
                              },
                              onAddTag: (locationId) {
                                // Show add tag dialog
                                // Implement bulk add tag
                                locationListProvider.addTagsToSelectedLocations(
                                    context,
                                    widget.accountID,
                                    widget.subAccountID,
                                    locationId);
                              },
                              getData: _getData,
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

  MyLocationCard myLocationCertifiedCard(
      MyLocationListProvider locationListProvider,
      int index,
      BuildContext context) {
    return MyLocationCard(
      campusId: locationListProvider
              .certifiedLocationList[index].finalAddress?.campusId ??
          '',
      imageUrl:
          (locationListProvider.certifiedLocationList[index].screenshots !=
                      null &&
                  locationListProvider
                      .certifiedLocationList[index].screenshots!.isNotEmpty)
              ? locationListProvider
                      .certifiedLocationList[index].screenshots![0].imageUrl ??
                  ''
              : '',
      index: index,
      accountId: widget.accountID,
      subAccountId: widget.subAccountID,
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
      dataCompletenessScore: 2,
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
                    "", [locationId]);

            // Refresh the list after deletion
            Provider.of<MyLocationListProvider>(context, listen: false)
                .fetchLocationList(
              context,
              locationQuery,
              1,
              40,
              widget.accountID,
              widget.subAccountID,
            );

            Navigator.of(context).pop();
          },
          [locationId],
        );
      },
      onAddToSOV: (locationId) {
        // Show add to SOV dialog
        // Implement bulk add to SOV
        locationListProvider.addSelectedToSOV(
            context,
            widget.accountID,
            widget.subAccountID,
            widget.accountName,
            widget.subAccountName,
            _masterTabController,
            locationId);
      },
      onAddTag: (locationId) {
        // Show add tag dialog
        // Implement bulk add tag
        locationListProvider.addTagsToSelectedLocations(
            context, widget.accountID, widget.subAccountID, locationId);
      },
      getData: _getData,
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

  void _showUploadBottomSheet(
      String accountId, String subAccountId, String sovId) {
    var typography = CustomTypography(context);
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      backgroundColor: Colors.black87,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, StateSetter setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    SizedBox(height: 40),
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
                                  _sovNameController.text = _uploadedFileName!;
                                });
                              }
                            },
                            child: Container(
                              height: 150,
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
                                      "Click to upload or drag and drop",
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
                        : Center(
                            child: Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 150,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
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
                                            "Cancel",
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
                                ),
                              ],
                            ),
                          ),
                    SizedBox(height: 20),
                    if (!addToSOVCheck) ...[
                      TextField(
                        controller: tagController,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: "Enter Tags (separated by comma)",
                          labelStyle: TextStyle(color: Colors.white),
                          enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey)),
                          focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.blue)),
                          hintStyle: TextStyle(color: Colors.white54),
                        ),
                      ),
                    ],
                    if (addToSOVCheck) ...[
                      // Fields displayed only if checkbox is checked
                      TextField(
                        controller: _sovNameController,
                        /*
                        readOnly: _uploadedFileName != null,*/
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: "Name of the SoV",
                          labelStyle: TextStyle(color: Colors.white),
                          enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey)),
                          focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.blue)),
                          hintStyle: TextStyle(color: Colors.white54),
                        ),
                      ),
                      SizedBox(height: 10),
                      TextField(
                        controller: tagController,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: "Enter Tags (separated by comma)",
                          labelStyle: TextStyle(color: Colors.white),
                          enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey)),
                          focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.blue)),
                          hintStyle: TextStyle(color: Colors.white54),
                        ),
                      ),
                      SizedBox(height: 10),
                      TextField(
                        controller:
                            TextEditingController(text: widget.accountName),
                        style: TextStyle(color: Colors.white),
                        enabled: false,
                        decoration: InputDecoration(
                          labelText: "Enter Account Name",
                          labelStyle: TextStyle(color: Colors.white),
                          enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey)),
                          disabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey)),
                          focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.blue)),
                          hintStyle: TextStyle(color: Colors.white54),
                        ),
                      ),
                      SizedBox(height: 10),
                      TextField(
                        enabled: false,
                        controller:
                            TextEditingController(text: widget.subAccountName),
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: "Enter Sub-account Name",
                          labelStyle: TextStyle(color: Colors.white),
                          enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey)),
                          disabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey)),
                          focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.blue)),
                          hintStyle: TextStyle(color: Colors.white54),
                        ),
                      ),
                      SizedBox(height: 10),
                    ],
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 0.0),
                      child: Row(
                        children: [
                          Checkbox(
                            value: addToSOVCheck,
                            onChanged: (bool? value) {
                              setState(() {
                                addToSOVCheck = value ?? false;
                              });
                            },
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Add to SoV",
                            style: typography.Body1,
                          ),
                        ],
                      ),
                    ),
                    /* if (addToSOVCheck)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: TextEditingController(text: widget.accountName),
                              enabled: false,
                              decoration: InputDecoration(
                                labelText: "Account Name",
                                border: OutlineInputBorder(),
                              ),
                            ),
                            SizedBox(height: 8.0),
                            TextField(
                              controller: TextEditingController(text: widget.subAccountName),
                              enabled: false,
                              decoration: InputDecoration(
                                labelText: "Sub-account Name",
                                border: OutlineInputBorder(),
                              ),
                            ),
                            SizedBox(height: 8.0),
                          ],
                        ),
                      ),*/
                    SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Column(
                        children: [
                          Consumer<MyLocationListProvider>(
                            builder: (_, locationListProvider, child) {
                              return locationListProvider.isImageUploadLoading
                                  ? Center(child: CircularProgressIndicator())
                                  : Row(
                                      children: [
                                        Expanded(
                                            child: CustomButton(
                                                type: ButtonType.elevated,
                                                onPressed: () async {
                                                  // Upload the file
                                                  // return if file is null
                                                  if (files.path.isEmpty) {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(SnackBar(
                                                            content: Text(
                                                                "Please select a file to upload")));
                                                    return;
                                                  }
                                                  // return if file is not xlsx
                                                  if (!files.path
                                                      .endsWith('.xlsx')) {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(SnackBar(
                                                            content: Text(
                                                                "Please select a valid file to upload")));
                                                    return;
                                                  }
                                                  String success =
                                                      await locationListProvider
                                                          .uploadSov(
                                                              context,
                                                              files,
                                                              accountId,
                                                              subAccountId,
                                                              sovId,
                                                              tagController
                                                                  .text,
                                                              _sovNameController
                                                                  .text);
                                                  Navigator.pop(context);

                                                  print('Success: $success');
                                                  // contain symbol +
                                                  if (success.isNotEmpty &&
                                                      success.contains('+')) {
                                                    print(
                                                        'Inside + success: $success');
                                                    // Show popup with title Empty SoV, body: Looks Like, Data has not been specified!! Do you want to continue creating an empty SOV, or abort? with 2 buttons: [create empty SOV]   [abort]
                                                    showDialog(
                                                        context: context,
                                                        builder: (BuildContext
                                                            context) {
                                                          return AlertDialog(
                                                            title: Text(
                                                              /*LanguageService.getTranslated(
                                                        context,
                                                        "account_list_app_empty_sov_title")*/
                                                              'Empty SOV',
                                                              style: typography
                                                                  .H5_Regular,
                                                            ),
                                                            content: Column(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                Text(
                                                                  /* LanguageService.getTranslated(
                                                            context,
                                                            "account_list_app_empty_sov_text"),*/
                                                                  'Looks Like, Data has not been specified!! Do you want to continue creating an empty SOV, or abort?',
                                                                  style:
                                                                      typography
                                                                          .Body1,
                                                                ),
                                                                SizedBox(
                                                                  height:
                                                                      CustomSpacing
                                                                          .two,
                                                                ),
                                                                Column(
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .stretch,
                                                                  children: [
                                                                    Consumer<UploadSovProvider>(builder:
                                                                        (context,
                                                                            uploadSovProvider,
                                                                            child) {
                                                                      return uploadSovProvider
                                                                              .isLoading
                                                                          ? const Center(
                                                                              child: CircularProgressIndicator(),
                                                                            )
                                                                          : CustomButton(
                                                                              onPressed: () async {
                                                                                // Create empty SOV
                                                                                var provider = Provider.of<UploadSovProvider>(context, listen: false);
                                                                                await provider.createEmptySov(context, success);
                                                                                Navigator.pop(context);
                                                                              },
                                                                              child: Text(
                                                                                /*LanguageService.getTranslated(
                                                                      context,
                                                                      "account_list_app_empty_sov_create"),*/
                                                                                'Create',
                                                                                style: typography.ButtonLarge,
                                                                              ),
                                                                              type: ButtonType.elevated,
                                                                            );
                                                                    }),
                                                                    CustomButton(
                                                                      onPressed:
                                                                          () {
                                                                        Navigator.pop(
                                                                            context);
                                                                      },
                                                                      child:
                                                                          Text(
                                                                        /*LanguageService.getTranslated(
                                                                  context,
                                                                  "account_list_app_empty_sov_abort")*/
                                                                        'Abort',
                                                                        style: typography
                                                                            .ButtonLarge,
                                                                      ),
                                                                      type: ButtonType
                                                                          .text,
                                                                    ),
                                                                  ],
                                                                ),
                                                              ],
                                                            ),
                                                          );
                                                        });
                                                  } else if (success
                                                      .isNotEmpty) {
                                                    Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                            builder: (_) =>
                                                                MappingScreen(
                                                                  tempId:
                                                                      success,
                                                                  accountId: widget
                                                                      .accountID,
                                                                  accountName:
                                                                      widget.accountName ??
                                                                          "",
                                                                )));
                                                  }
                                                },
                                                child: Text("Upload",
                                                    style:
                                                        typography.ButtonLarge
                                                            .copyWith(
                                                                color: Colors
                                                                    .white)))),
                                      ],
                                    );
                            },
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _uploadedFileName = null;
                                _sovNameController.clear();
                              });
                              Navigator.of(context).pop();
                            },
                            child: Text("Close", style: typography.Body1),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void sovSearchClient(String query) async {
    debounce(() async {
      if (!mounted) return;
      _sovQuery = query;
      var provider = Provider.of<SOVListProvider>(context, listen: false);
      provider.page = 0;
      await provider.fetchSovList(context, widget.accountID,
          widget.subAccountID, _sovQuery, provider.page, 10);
    });
  }

  Widget sovBody(CustomTypography typography) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: CustomSpacing.two),
        Text(
          '${LanguageService.getTranslated(context, "sov_list_app_title")} ',
          style: typography.Body1,
        ),
        SizedBox(height: CustomSpacing.four),
        // Search
        SizedBox(
          height: 50,
          child: TextField(
            controller: _textEditingController,
            onChanged: (query) {
              sovSearchClient(query);
            },
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              hintText: LanguageService.getTranslated(
                  context, "sov_list_search_hint"),
              hintStyle: typography.Body2,
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
        SizedBox(height: CustomSpacing.four),
        // List of accounts
        Expanded(
          child:
              Consumer<SOVListProvider>(builder: (context, sovListProvider, _) {
            return sovListProvider.isLoading
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
                : sovListProvider.sovList.isEmpty
                    ? Center(
                        child: Text(
                          LanguageService.getTranslated(
                              context, "sov_list_app_no_sov_text"),
                          style: typography.Body1,
                        ),
                      )
                    : ListView.builder(
                        itemCount: sovListProvider.sovList.length,
                        itemBuilder: (context, index) {
                          if (index == sovListProvider.sovList.length - 1) {
                            // Check if it's the last item
                            if (sovListProvider.isNextPageLoading) {
                              // Display loading indicator
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            } else if (sovListProvider.page >=
                                    sovListProvider.totalPages &&
                                sovListProvider.sovList.isNotEmpty) {
                              // Display end of list message
                              return Column(
                                children: [
                                  _buildSovCard(index, sovListProvider),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Center(
                                      child: Text(
                                        LanguageService.getTranslated(context,
                                            "sov_list_app_end_of_list_text"),
                                        style: typography.Body1,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            } else {
                              // Trigger fetching the next page
                              sovListProvider.page = sovListProvider.page + 1;
                              sovListProvider.fetchSovList(
                                context,
                                widget.accountID,
                                widget.subAccountID,
                                _sovQuery,
                                sovListProvider.page,
                                10, // Page size
                              );
                              return SizedBox();
                            }
                          }

                          return _buildSovCard(index, sovListProvider);
                        },
                      );
          }),
        ),
      ],
    );
  }

  Widget _buildSovCard(int index, SOVListProvider sOVListProvider) {
    var typography = CustomTypography(context);
    bool isDisabled = sOVListProvider.sovList[index].disabled ?? false;
    return Container(
      margin: EdgeInsets.only(top: 0.0, bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: isDisabled
            ? null
            : () {
                // On tap of card
                /*if (showCheckbox) {
                  setState(() {
                    sOVListProvider.sovList[index].isChecked =
                        !(sOVListProvider.sovList[index].isChecked ?? false);
                  });
                }
                // if all are unselected then hide checkbox
                if (sOVListProvider.sovList
                    .every((element) => element.isChecked == false)) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    setState(() {
                      showCheckbox = false;
                    });
                  });
                }*/
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return SovLocationList(
                    accountID: widget.accountID,
                    subAccountID: widget.subAccountID,
                    accountName: widget.accountName,
                    subAccountName: widget.subAccountName,
                    sovID: sOVListProvider.sovList[index].id ?? "",
                    sovName: sOVListProvider.sovList[index].name ?? "",
                  );
                }));
              },
        /* onLongPress: () {
          setState(() {
            if (showCheckbox) {
              showCheckbox = false;
              sOVListProvider.sovList[index].isChecked = false;
            } else {
              sOVListProvider.sovList.forEach((element) {
                element.isChecked = false;
              });
              showCheckbox = true;
              sOVListProvider.sovList[index].isChecked = true;
            }
          });
        },*/
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /*// Add Checkbox here
            showCheckbox
                ? Checkbox(
                    value: sOVListProvider.sovList[index].isChecked ?? false,
                    onChanged: isDisabled
                        ? null
                        : (value) {
                            setState(() {
                              sOVListProvider.sovList[index].isChecked =
                                  value ?? false;
                            });
                          },
                  )
                : SizedBox(),*/
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Card(
                    color: isDisabled
                        ? Theme.of(context).colorScheme.scrim
                        : Theme.of(context).colorScheme.surface,
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: CustomSpacing.three,
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: CustomSpacing.two,
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          (sOVListProvider.sovList[index]
                                                          .name ??
                                                      "")
                                                  .isNotEmpty
                                              ? sOVListProvider
                                                      .sovList[index].name!
                                                      .substring(0, 1)
                                                      .toUpperCase() +
                                                  sOVListProvider
                                                      .sovList[index].name!
                                                      .substring(1)
                                              : "",
                                          //sOVListProvider.sovList[index].id??"",
                                          style: typography.Body2.copyWith(
                                            color:
                                                Theme.of(context).brightness ==
                                                        Brightness.dark
                                                    ? AppColors.white
                                                    : AppColors.black,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      // Add edit icon and on tap show edit dialog
                                      SizedBox(
                                        width: CustomSpacing.two,
                                      ),
                                      isDisabled
                                          ? SizedBox()
                                          : InkWell(
                                              onTap: () {
                                                _sovEditNameController
                                                    .text = (sOVListProvider
                                                                .sovList[index]
                                                                .name ??
                                                            "")
                                                        .isNotEmpty
                                                    ? sOVListProvider
                                                            .sovList[index]
                                                            .name!
                                                            .substring(0, 1)
                                                            .toUpperCase() +
                                                        sOVListProvider
                                                            .sovList[index]
                                                            .name!
                                                            .substring(1)
                                                    : "";
                                                // Show edit dialog
                                                showDialog(
                                                  context: context,
                                                  builder: (context) {
                                                    return AlertDialog(
                                                      title: Text(
                                                        LanguageService
                                                            .getTranslated(
                                                                context,
                                                                "sov_list_app_edit_sov_title"),
                                                        style: typography
                                                            .H5_Regular,
                                                      ),
                                                      content: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Column(
                                                            children: [
                                                              Chip(
                                                                label: Text(
                                                                  widget.accountName +
                                                                      " / " +
                                                                      widget
                                                                          .subAccountName,
                                                                  style:
                                                                      typography
                                                                          .Body1,
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                height:
                                                                    CustomSpacing
                                                                        .two,
                                                              ),
                                                              TextField(
                                                                controller:
                                                                    _sovEditNameController,
                                                                decoration:
                                                                    InputDecoration(
                                                                  border:
                                                                      OutlineInputBorder(),
                                                                  labelText: LanguageService
                                                                      .getTranslated(
                                                                          context,
                                                                          "sov_list_app_edit_label_text"),
                                                                  labelStyle:
                                                                      typography
                                                                          .Body1,
                                                                  hintText: LanguageService
                                                                      .getTranslated(
                                                                          context,
                                                                          "sov_list_app_edit_label_hint_text"),
                                                                  hintStyle:
                                                                      typography
                                                                          .Body1,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          SizedBox(
                                                            height:
                                                                CustomSpacing
                                                                    .two,
                                                          ),
                                                          Row(
                                                            children: [
                                                              Expanded(
                                                                child:
                                                                    CustomButton(
                                                                  onPressed:
                                                                      () {
                                                                    // Cancel
                                                                    Navigator.pop(
                                                                        context);
                                                                  },
                                                                  child: Text(
                                                                    LanguageService.getTranslated(
                                                                        context,
                                                                        "sov_list_app_edit_cancel_text"),
                                                                    style: typography
                                                                        .ButtonLarge,
                                                                  ),
                                                                  type:
                                                                      ButtonType
                                                                          .text,
                                                                ),
                                                              ),
                                                              Consumer<
                                                                      SOVListProvider>(
                                                                  builder: (context,
                                                                      sovListProvider,
                                                                      _) {
                                                                return sovListProvider
                                                                        .isRenameLoading
                                                                    ? const Expanded(
                                                                        child:
                                                                            Row(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.center,
                                                                        children: [
                                                                          SizedBox(
                                                                              width: 25,
                                                                              height: 25,
                                                                              child: CircularProgressIndicator()),
                                                                        ],
                                                                      ))
                                                                    : Expanded(
                                                                        child:
                                                                            CustomButton(
                                                                          onPressed:
                                                                              () async {
                                                                            if (_sovEditNameController.text.isEmpty) {
                                                                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                                                                  content: Text(
                                                                                LanguageService.getTranslated(context, "sub_account_list_app_rename_sub_account_empty_text_error"),
                                                                                style: typography.Body1,
                                                                              )));
                                                                              return;
                                                                            }
                                                                            // Update account details
                                                                            await sovListProvider.renameSov(
                                                                                context,
                                                                                widget.accountID,
                                                                                widget.subAccountID,
                                                                                sovListProvider.sovList[index].id ?? "",
                                                                                _sovEditNameController.text);
                                                                            Navigator.pop(context);
                                                                          },
                                                                          child:
                                                                              Text(
                                                                            LanguageService.getTranslated(context,
                                                                                "sov_list_app_edit_update_text"),
                                                                            style:
                                                                                typography.ButtonLarge,
                                                                          ),
                                                                          type:
                                                                              ButtonType.elevated,
                                                                        ),
                                                                      );
                                                              }),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                );
                                              },
                                              child: Icon(
                                                Icons.edit,
                                                size: 16,
                                              ),
                                            ),
                                    ],
                                  ),
                                  /*!sOVListProvider.showLocationCount
                                      ? SizedBox()
                                      : */
                                  Row(
                                    children: [
                                      Text(
                                          sOVListProvider.sovList[index]
                                                          .locationCount !=
                                                      null &&
                                                  sOVListProvider.sovList[index]
                                                          .locationCount ==
                                                      1
                                              ? LanguageService.getTranslated(
                                                  context,
                                                  "sov_list_app_column_location_count_text")
                                              : sOVListProvider.sovList[index]
                                                          .locationCount ==
                                                      null
                                                  ? ""
                                                  : LanguageService.getTranslated(
                                                      context,
                                                      "sov_list_app_column_location_count_text"),
                                          style: typography.Caption),
                                      SizedBox(
                                        width: CustomSpacing.two,
                                      ),
                                      Text(
                                          sOVListProvider
                                                  .sovList[index].locationCount
                                                  ?.toString() ??
                                              "",
                                          style: typography.Caption),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            !sOVListProvider.showOverallScore
                                ? SizedBox()
                                : Padding(
                                    padding:
                                        EdgeInsets.only(top: CustomSpacing.one),
                                    child: CustomGradientCircularProgressBar(
                                      radius: 23,
                                      value: double.parse(sOVListProvider
                                              .sovList[index].overAllScore
                                              ?.toString() ??
                                          "0"),
                                      strokeWidth: 6,
                                      showText: true,
                                      textColor: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? AppColors.white
                                          : AppColors.black,
                                      text: sOVListProvider
                                              .sovList[index].overAllScore
                                              ?.toStringAsFixed(2) ??
                                          "0",
                                    ),
                                  ),
                            SizedBox(
                              width: CustomSpacing.four,
                            ),
                          ],
                        ),
                        SizedBox(
                          height: CustomSpacing.two,
                        ),
                      ],
                    ),
                  ),
                  isDisabled
                      ? SizedBox()
                      : Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceVariant,
                            // bottom left and right corners curved
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(8),
                              bottomRight: Radius.circular(8),
                            ),
                          ),
                          child: Row(
                            children: [
                              TextButton.icon(
                                onPressed: () {
                                  // Transfer account
                                  _showTransferDialog(
                                      context, sOVListProvider.sovList[index]);
                                },
                                icon: const Icon(Symbols.share_windows),
                                label: Text('Transfer',
                                    style: typography.Caption.copyWith(
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? AppColors.white
                                            : AppColors.black)),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.file_copy_rounded),
                                color: AppColors.primaryMain,
                                onPressed: () {
                                  // Show duplicate dialog
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: Text(
                                          LanguageService.getTranslated(context,
                                              "sov_list_app_duplicate_title"),
                                          style: typography.H5_Regular,
                                        ),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              LanguageService.getTranslated(
                                                  context,
                                                  "sov_list_app_duplicate_text"),
                                              style: typography.Body1,
                                            ),
                                            SizedBox(
                                              height: CustomSpacing.two,
                                            ),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: CustomButton(
                                                    onPressed: () {
                                                      // Cancel
                                                      Navigator.pop(context);
                                                    },
                                                    child: Text(
                                                      LanguageService.getTranslated(
                                                          context,
                                                          "sov_list_app_duplicate_cancel"),
                                                      style: typography
                                                          .ButtonLarge,
                                                    ),
                                                    type: ButtonType.text,
                                                  ),
                                                ),
                                                sOVListProvider
                                                        .isDuplicateLoading
                                                    ? const Expanded(
                                                        child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          SizedBox(
                                                              width: 25,
                                                              height: 25,
                                                              child:
                                                                  CircularProgressIndicator()),
                                                        ],
                                                      ))
                                                    : Expanded(
                                                        child: CustomButton(
                                                          onPressed: () async {
                                                            // Duplicate
                                                            await sOVListProvider.duplicateSov(
                                                                context,
                                                                widget
                                                                    .accountID,
                                                                widget
                                                                    .subAccountID,
                                                                sOVListProvider
                                                                        .sovList[
                                                                            index]
                                                                        .id ??
                                                                    "");
                                                            Navigator.pop(
                                                                context);
                                                          },
                                                          child: Text(
                                                            LanguageService
                                                                .getTranslated(
                                                                    context,
                                                                    "sov_list_app_duplicate_duplicate"),
                                                            style: typography
                                                                .ButtonLarge,
                                                          ),
                                                          type: ButtonType
                                                              .elevated,
                                                        ),
                                                      ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                                tooltip: LanguageService.getTranslated(context,
                                    "sov_list_app_duplicate_tooltip_text"),
                              ),
                              /*IconButton(
                                icon: Icon(
                                  Icons.settings,
                                  color: AppColors.primaryMain,
                                ),
                                onPressed: () {
                                  _showSettingsModal(context, index);
                                },
                                tooltip: LanguageService.getTranslated(context,
                                    "sov_list_app_settings_tooltip_text"),
                              ),*/
                            ],
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showTransferDialog(BuildContext context, SovAccount sov) async {
    var typography = CustomTypography(context);
    TextEditingController _userSearchController = TextEditingController();
    TransferAutocompleteModel? _selectedUser;
    List<TransferAutocompleteModel> _autocompleteUsersList = [];
    bool _isTransferLoading = false;
    bool _isSearching = false;
    Timer? _debounce;

    void _onSearchChanged(String query, StateSetter setState) {
      if (_debounce?.isActive ?? false) _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 500), () async {
        if (query.isNotEmpty) {
          setState(() {
            _isSearching = true;
          });

          _autocompleteUsersList = await fetchAutocompleteUsers(query);

          setState(() {
            _isSearching = false;
          });
        } else {
          setState(() {
            _autocompleteUsersList.clear();
            _isSearching = false;
          });
        }
      });
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Dialog(
              child: Container(
                width: 304,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Transfer SOV',
                        style: typography.H5_Regular.copyWith(height: 1.2),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _userSearchController,
                        onChanged: (query) {
                          setState(() {
                            _selectedUser = null;
                          });
                          _onSearchChanged(query, setState);
                        },
                        decoration: InputDecoration(
                          hintText: 'Search for a user to transfer sov',
                          border: OutlineInputBorder(),
                          suffixIcon: _isSearching
                              ? Container(
                                  margin: EdgeInsets.fromLTRB(0, 8, 16, 8),
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator())
                              : null,
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Flexible(
                      child: _selectedUser == null
                          ? ListView.builder(
                              shrinkWrap: true,
                              itemCount: _autocompleteUsersList.length,
                              itemBuilder: (context, index) {
                                final user = _autocompleteUsersList[index];
                                return ListTile(
                                  leading: user.imageUrl.isNotEmpty
                                      ? CircleAvatar(
                                          backgroundImage:
                                              NetworkImage(user.imageUrl),
                                        )
                                      : CircleAvatar(
                                          child: Text(user.displayName[0]
                                              .toUpperCase()),
                                        ),
                                  title: Text(user.displayName),
                                  subtitle: Text(user.email),
                                  onTap: () {
                                    setState(() {
                                      _selectedUser = user;
                                      _userSearchController.text =
                                          user.displayName;
                                    });
                                  },
                                );
                              },
                            )
                          : Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                  'Selected User: ${_selectedUser!.displayName}'),
                            ),
                    ),
                    ButtonBar(
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: Text('Cancel'),
                        ),
                        TextButton(
                          onPressed:
                              _selectedUser != null && !_isTransferLoading
                                  ? () async {
                                      setState(() {
                                        _isTransferLoading = true;
                                      });
                                      var provider =
                                          Provider.of<SOVListProvider>(context,
                                              listen: false);
                                      await provider.transferSOV(
                                          context,
                                          widget.accountID,
                                          widget.subAccountID,
                                          sov.id,
                                          _selectedUser!.id);
                                      setState(() {
                                        _isTransferLoading = false;
                                      });
                                      Navigator.pop(dialogContext);
                                    }
                                  : null,
                          child: _isTransferLoading
                              ? CircularProgressIndicator(strokeWidth: 2.0)
                              : Text('Transfer'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      if (_debounce?.isActive ?? false) _debounce?.cancel();
    });
  }

  Future<List<TransferAutocompleteModel>> fetchAutocompleteUsers(
      String query) async {
    try {
      ApiService apiService = ApiService(AppConstant.ADD_TEAM_MEMBERS);
      String url = '?search=$query&within_company=true';
      var response = await apiService.get(url);

      // Parse the response to extract user data
      List<TransferAutocompleteModel> users = (response['users'] as List)
          .map((user) => TransferAutocompleteModel.fromJson(user))
          .toList();

      return users;
    } catch (e) {
      print(e.toString());
      return [];
    }
  }
}

class OverallListCard extends StatelessWidget {
  const OverallListCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Color(0xFF2D2D2D),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Image, 100% Indicator, RS Code
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.network(
                    'https://via.placeholder.com/50', // Replace with your image
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
                SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'C-231',
                      style: TextStyle(color: Colors.white),
                    ),
                    Text(
                      'RS/00003',
                      style: TextStyle(color: Colors.blue[300]),
                    ),
                  ],
                ),
                Spacer(),
                CircularPercentIndicator(),
                // Replace with your circular progress indicator widget
              ],
            ),
            SizedBox(height: 20),

            // Scores Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ScoreWidget(
                  icon: Icons.electric_bolt,
                  label: 'Risk Score',
                  score: 4,
                  color: Colors.green,
                ),
                ScoreWidget(
                  icon: Icons.people_alt,
                  label: 'Occupancy',
                  score: 2,
                  color: Colors.red,
                ),
                ScoreWidget(
                  icon: Icons.construction,
                  label: 'Construction',
                  score: 3,
                  color: Colors.yellow,
                ),
              ],
            ),

            SizedBox(height: 10),

            // Geocoding Score
            ScoreWidget(
              icon: Icons.gps_fixed,
              label: 'Geocoding Score',
              score: 5,
              color: Colors.green,
            ),
          ],
        ),
      ),
    );
  }
}

class ScoreWidget extends StatelessWidget {
  final IconData icon;
  final String label;
  final int score;
  final Color color;

  ScoreWidget({
    required this.icon,
    required this.label,
    required this.score,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: color),
            SizedBox(width: 8),
            Text(
              '$label',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
        SizedBox(height: 8),
        Row(
          children: [
            for (var i = 0; i < 5; i++)
              Icon(
                Icons.circle,
                size: 10,
                color: i < score ? color : Colors.grey,
              ),
            SizedBox(width: 8),
            Text(
              '$score',
              style: TextStyle(color: color),
            ),
          ],
        ),
      ],
    );
  }
}

class CircularPercentIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                value: 1.0, // This should be in the range of 0.0 to 1.0
                strokeWidth: 5,
                color: Colors.green,
              ),
            ),
            Text(
              '100%',
              style: TextStyle(color: Colors.green, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }
}

class GeoCodingListCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Left Section: Badge Icon and Image
            Row(
              children: [
                SvgPicture.asset(
                  'assets/images/certified.svg',
                  semanticsLabel: 'Location',
                ),
                SizedBox(width: 8),
                ClipOval(
                  child: Image.asset(
                    'assets/images/location_thumbnail.png',
                    // Replace with your image
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),

            SizedBox(width: 10),

            // Middle Section: RS Code and C-231
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'RS/00002',
                        style: TextStyle(color: Colors.blue[300], fontSize: 16),
                      ),
                      SizedBox(width: 5),
                      Icon(
                        Icons.info_outline,
                        color: Colors.grey,
                        size: 16,
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Chip(
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainerHigh,
                    label: Text(
                      'C-231',
                      style: CustomTypography(context).Body2,
                    ),
                  ),
                ],
              ),
            ),

            // Right Section: Geocoding Score
            Row(
              children: [
                ScoreBar(),
                SizedBox(width: 5),
                Text(
                  '5',
                  style: TextStyle(color: Colors.green, fontSize: 16),
                ),
              ],
            ),

            // Optional: More icon on the right
            SizedBox(width: 10),
            Icon(
              Icons.more_vert,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}

class ScoreBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Color(0xFF323232),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          for (var i = 0; i < 5; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: Icon(
                Icons.circle,
                size: 12,
                color: i < 5 ? Colors.green : Colors.grey,
              ),
            ),
        ],
      ),
    );
  }

}
