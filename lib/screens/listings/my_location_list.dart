import 'dart:async';
import 'dart:io';
import 'package:RiskSphare/screens/listings/account_list.dart';
import 'package:RiskSphare/screens/listings/sub_account_list.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:RiskSphare/models/my_location_list_model.dart';
import 'package:RiskSphare/providers/location_list_provider.dart';
import 'package:RiskSphare/providers/my_location_list_provider.dart';
import 'package:RiskSphare/providers/user_profile_provider.dart';
import 'package:RiskSphare/screens/listings/add_location_screen.dart';
import 'package:RiskSphare/screens/listings/sov_location_list.dart';
import 'package:RiskSphare/screens/listings/widgets/configurations_tab.dart';
import 'package:RiskSphare/screens/listings/widgets/data_tab.dart';
import 'package:RiskSphare/screens/listings/widgets/export_dialog.dart';
import 'package:RiskSphare/screens/listings/widgets/listings_filter_screen.dart';
import 'package:RiskSphare/screens/listings/widgets/location_card.dart';
import 'package:RiskSphare/screens/listings/widgets/location_list_map_view.dart';
import 'package:RiskSphare/screens/listings/widgets/maintenance_widget.dart';
import 'package:RiskSphare/screens/listings/widgets/mapping_screen.dart';
import 'package:RiskSphare/screens/listings/widgets/message_card.dart';
import 'package:RiskSphare/screens/listings/widgets/overall_score_table.dart';
import 'package:RiskSphare/screens/processMonitoringScreen/process_monitoring_system.dart';
import 'package:RiskSphare/service/shared_preference_service.dart';
import 'package:lottie/lottie.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:remixicon/remixicon.dart';
import 'package:rxdart/rxdart.dart';

import '../../constants/enums.dart';
import '../../design_system/components/custom_appbar.dart';
import '../../design_system/components/custom_button.dart';
import '../../design_system/components/custom_drawer.dart';
import '../../design_system/components/custom_gradient_circular_progress_bar.dart';
import '../../design_system/primitives/app_colors.dart';
import '../../design_system/primitives/custom_typography.dart';
import '../../design_system/primitives/utilities/custom_spacing.dart';
import '../../models/sov_list_model.dart';
import '../../models/transfer_autocomplete_model.dart';
import '../../providers/job_monitoring_provier.dart';
import '../../providers/sov_list_provider.dart';
import '../../providers/theme_provider.dart';
import 'package:RiskSphare/models/role_model.dart' as roleModel;
import '../../providers/upload_sov_provider.dart';
import '../../service/api_service.dart';
import '../../service/language_service.dart';
import '../../utils/api_constants.dart';

class MyLocationList extends StatefulWidget {
  final String? accountID;
  final String? subAccountID;
  final String accountName;
  final String subAccountName;
  final String? initialProcessId;
  final String? initialSubProcessId;

  const MyLocationList({
    super.key,
    this.accountID,
    this.subAccountID,
    this.accountName = '',
    this.subAccountName= '',
    this.initialProcessId,
    this.initialSubProcessId,
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
  String selectedProcessId = "";

  String isMaintenance = "";
  Screens _selectedScreen = Screens.locationList;
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
  TextEditingController _locationNameController = TextEditingController();
  File? files;

  TabController? _mainTabController;
  int selectedMainTab = 0;
  int selectedTab = 0;
  int selectedMasterTab = 0;

  /// Sov Things
  TextEditingController _textEditingController = TextEditingController();
  String _sovQuery = "";
  bool showCheckbox = false;
  TextEditingController _sovEditNameController = TextEditingController();

  bool addToSOVCheck = false;
  bool isLoading = false;

  String selectedSovId = "";
  TextEditingController sovController = TextEditingController();
  TextEditingController tagController = TextEditingController();

  bool isUploadInProgress = false;
  late Timer _refreshTimer;

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
    // Auto refresh every 15 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (mounted) {
        _refreshData(); // Call refresh function
      }
    });
    _getSovUploadStatus();
    // Initially clear all filters
    Provider.of<MyLocationListProvider>(context, listen: false)
        .clearAllFilters();
    Provider.of<LocationListProvider>(context, listen: false)
        .fetchLocationSummary(
            widget.accountID!, widget.subAccountID!, "widget.sovId!");

    var userProfileProvider =
        Provider.of<UserProfileProvider>(context, listen: false);
    final trialStatus = userProfileProvider.trialInfo['status'] ?? '';
    // Determine the number of tabs based on trial status
    int tabCount = trialStatus.isEmpty ? 6 : 5;
    _mainTabController = TabController(length: 3, vsync: this);
    _mainTabController?.addListener(() {
      setState(() {
        selectedMainTab = _mainTabController?.index ?? 0;
      }); // This ensures that the widget rebuilds when the tab changes
    });
    _masterTabController = TabController(length: tabCount, vsync: this);
    _masterTabController?.addListener(() {
      setState(() {
        selectedMasterTab = _masterTabController?.index ?? 0;
      });
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

    _getMaintainancePeriod();
  }

  @override
  void dispose() {
    // Dispose of all controllers to prevent ticker leaks
    _mainTabController?.dispose();
    _masterTabController?.dispose();
    _tabController?.dispose();

    WidgetsBinding.instance!.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<MyLocationListProvider>(context, listen: false)
            .clearAllFilters();
        Provider.of<MyLocationListProvider>(context, listen: false)
            .clearSelection();
        Provider.of<MyLocationListProvider>(context, listen: false)
            .clearRatingsFilter();
        Provider.of<MyLocationListProvider>(context, listen: false)
            .myLocationList
            .clear();
        Provider.of<MyLocationListProvider>(context, listen: false)
            .certifiedLocationList
            .clear();
        Provider.of<MyLocationListProvider>(context, listen: false)
            .selectedLocations
            .clear();
        Provider.of<MyLocationListProvider>(context, listen: false)
            .summaryList
            .clear();
        Provider.of<MyLocationListProvider>(context, listen: false)
            .certifiedLocationHits;
        Provider.of<MyLocationListProvider>(context, listen: false)
            .locationHits;
      }
    });
    _refreshTimer.cancel();
    super.dispose();
  }

  Future<void> _refreshData() async {
    if (!mounted) return; // Ensure the widget is still in the tree

    final locationListProvider = Provider.of<MyLocationListProvider>(context, listen: false);

    locationListProvider.certifiedPage = 1;

    await locationListProvider.fetchCertifiedLocationList(
      context,
      "",
      locationListProvider.certifiedPage,
      40,
      widget.accountID,
      widget.subAccountID,
      widget.initialProcessId,
      widget.initialSubProcessId,
    );

    await locationListProvider.fetchLocationList(
      context,
      "",
      1,
      40,
      widget.accountID,
      widget.subAccountID,
      widget.initialProcessId,
      widget.initialSubProcessId,
    );

    await locationListProvider.fetchAllLocationList(
      context,
      widget.accountID,
      widget.subAccountID,
      processId: widget.initialProcessId,
      subProcessId: widget.initialSubProcessId,
    );

    if (mounted) {
      setState(() {}); // Trigger UI update after fetching data
    }
  }



  _getMaintainancePeriod() async {
    isMaintenance = (await SharedPreferenceService.getScheduleInProgress())!;
  }

  Future<void> _getData() async {
    final myLocationProvider =
        Provider.of<MyLocationListProvider>(context, listen: false);
    final sovListProvider =
        Provider.of<SOVListProvider>(context, listen: false);
    final jobMonitoringProvider =
        Provider.of<JobMonitoringProvider>(context, listen: false);

    // Run all API calls in parallel
    await Future.wait([
      myLocationProvider
          .fetchLocationList(
            context,
            "",
            1,
            40,
            widget.accountID,
            widget.subAccountID,
            widget.initialProcessId,
            widget.initialSubProcessId,
          )
          .then(
              (_) => setState(() {})), // Update UI after fetching location list

      myLocationProvider
          .fetchCertifiedLocationList(
            context,
            "",
            1,
            40,
            widget.accountID,
            widget.subAccountID,
            widget.initialProcessId,
            widget.initialSubProcessId,
          )
          .then((_) => WidgetsBinding.instance!.addPostFrameCallback(
              (_) => setState(() {}))), // Update UI after frame rendering

      sovListProvider.fetchSovList(
        context,
        widget.accountID!,
        widget.subAccountID!,
        "",
        1,
        10,
      ),

      sovListProvider.fetchAutoCompleteSovListLocations(
        context,
        widget.accountID!,
        widget.subAccountID!,
      ),

      myLocationProvider.fetchAllLocationList(
        context,
        widget.accountID,
        widget.subAccountID,
        processId: widget.initialProcessId,
        subProcessId: widget.initialSubProcessId,
      ),

      jobMonitoringProvider.fetchCompanyIds(),
    ]);
  }

  // _getData() async {
  //   // Fetch data from API
  //   Provider.of<MyLocationListProvider>(context, listen: false)
  //       .fetchLocationList(
  //         context,
  //         "",
  //         1,
  //         40,
  //         widget.accountID,
  //         widget.subAccountID,
  //         widget.initialProcessId,
  //         widget.initialSubProcessId,
  //       )
  //       .then((value) => setState(() {}));
  //   Provider.of<MyLocationListProvider>(context, listen: false)
  //       .fetchCertifiedLocationList(
  //         context,
  //         "",
  //         1,
  //         40,
  //         widget.accountID,
  //         widget.subAccountID,
  //         widget.initialProcessId,
  //         widget.initialSubProcessId,
  //       )
  //       .then((value) => WidgetsBinding.instance!.addPostFrameCallback((_) {
  //             setState(() {});
  //           }));
  //   //Provider.of<LocationListProvider>(context, listen: false).fetchCampusIds("widget.accountId", "widget.subAccountId", "widget.sovId");
  //   Provider.of<SOVListProvider>(context, listen: false).page = 1;
  //   Provider.of<SOVListProvider>(context, listen: false).fetchSovList(
  //       context, widget.accountID!, widget.subAccountID!, "", 1, 10);
  //   Provider.of<SOVListProvider>(context, listen: false)
  //       .fetchAutoCompleteSovListLocations(
  //           context, widget.accountID!, widget.subAccountID!);
  //   Provider.of<MyLocationListProvider>(context, listen: false)
  //       .fetchAllLocationList(
  //     context,
  //     widget.accountID,
  //     widget.subAccountID,
  //     processId: widget.initialProcessId,
  //     subProcessId: widget.initialSubProcessId,
  //   );
  //   // Initialize the JobMonitoringProvider and fetch the company IDs
  //   Provider.of<JobMonitoringProvider>(context, listen: false)
  //       .fetchCompanyIds();
  // }

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

  _getSovUploadStatus() async {
    String? tempProcessId = await SharedPreferenceService.getSovUploadTempId();
    String? accountId = await SharedPreferenceService.getSovAccountId();
    String? subAccountId =
        await SharedPreferenceService.getSovSubAccountId() ?? "";

    print("tempProcessId: $tempProcessId");
    print("current sov accountId: $accountId");
    print("widget.accountID: ${widget.accountID}");
    print("sov subAccountId: $subAccountId");
    print("widget.subAccountID: ${widget.subAccountID}");

    if (tempProcessId == null || accountId == null) {
      print("Error: Missing values from Shared Preferences.");
      return;
    }

    setState(() {
      isUploadInProgress = tempProcessId.isNotEmpty &&
          widget.accountID == accountId &&
          widget.subAccountID == subAccountId;
    });

    print("Upload in Progress: $isUploadInProgress");
  }

  @override
  Widget build(BuildContext context1) {
    var typography = CustomTypography(context);
    return SafeArea(
      child: PopScope(
        onPopInvokedWithResult: (canPop, result) {
          print('Can Pop: $canPop, Selected Screen: $_selectedScreen');
          Provider.of<MyLocationListProvider>(context, listen: false)
              .clearSelection();
        },
        child: Consumer<UserProfileProvider>(
            builder: (context, userProfileProvider, child) {
          final trialStatus = userProfileProvider.trialInfo['status'] ?? '';
          return Consumer<ThemeProvider>(
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
                floatingActionButton: Container(
                  margin: EdgeInsets.only(bottom: 42.0),
                  child: SpeedDial(
                    animatedIcon: AnimatedIcons.menu_close,
                    animatedIconTheme: IconThemeData(size: 22.0),
                    backgroundColor: AppColors.primaryMain,
                    foregroundColor:
                        themeProvider.getTheme.colorScheme.onPrimary,
                    children: [
                      if ((selectedMasterTab) == 0)
                        SpeedDialChild(
                            child: Icon(Icons.add),
                            backgroundColor: AppColors.primaryMain,
                            foregroundColor:
                                themeProvider.getTheme.colorScheme.onPrimary,
                            label: 'Add Location',
                            labelStyle: typography.Body1,
                            onTap: () async {
                              final result = await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => AddLocationScreen(
                                    accountId: widget.accountID!,
                                    subAccountId: widget.subAccountID!,
                                    sovId: "",
                                    accountName: widget.accountName,
                                    subAccountName: widget.subAccountName,
                                  ),
                                ),
                              );

                              // Check if result is returned from AddLocationScreen
                              if (result != null && result == true) {
                                _getData(); // Refresh data if needed

                                // Fetch updated location list without full reload
                                await Provider.of<MyLocationListProvider>(
                                        context,
                                        listen: false)
                                    .fetchLocationList(
                                  context,
                                  "",
                                  1,
                                  40,
                                  widget.accountID,
                                  widget.subAccountID,
                                  widget.initialProcessId,
                                  widget.initialSubProcessId,
                                );

                                setState(() {}); // Update UI
                              }
                            }

                            // onTap: () {
                            //   Navigator.of(context)
                            //       .push(MaterialPageRoute(
                            //     builder: (_) => AddLocationScreen(
                            //       accountId: widget.accountID!,
                            //       subAccountId: widget.subAccountID!,
                            //       sovId: "",
                            //       accountName: widget.accountName,
                            //       subAccountName: widget.subAccountName,
                            //     ),
                            //   ))
                            //       .then((value) {
                            //     if (value != null) {
                            //       _getData();
                            //       if (value) {
                            //         Provider.of<MyLocationListProvider>(context,
                            //                 listen: false)
                            //             .fetchLocationList(
                            //               context,
                            //               "",
                            //               1,
                            //               40,
                            //               widget.accountID,
                            //               widget.subAccountID,
                            //               widget.initialProcessId,
                            //               widget.initialSubProcessId,
                            //             )
                            //             .then((value) => setState(() {}));
                            //       }
                            //     }
                            //   });
                            // },
                            ),
                      SpeedDialChild(
                        child: Icon(Icons.upload),
                        backgroundColor: AppColors.primaryMain,
                        foregroundColor:
                            themeProvider.getTheme.colorScheme.onPrimary,
                        label: isUploadInProgress
                            ? 'Continue'
                            : 'Import Locations',
                        labelStyle: typography.Body1,
                        onTap: () async {
                          tagController.text = "";
                          if (isMaintenance.toString() == 'in_progress') {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'SOV upload is disabled during maintenance period.'),
                              ),
                            );
                          } else if (isUploadInProgress) {
                            String tempProcessId = await SharedPreferenceService
                                    .getSovUploadTempId() ??
                                "";
                            String state = await SharedPreferenceService
                                    .getSovUploadState() ??
                                "";
                            // Call API to get get necessary data and navigate to the respective screen
                            Provider.of<UploadSovProvider>(context,
                                    listen: false)
                                .fetchSovUploadData(
                                    context,
                                    widget.accountID!,
                                    widget.accountName,
                                    widget.subAccountName,
                                    widget.subAccountID!,
                                    tempProcessId,
                                    state);
                          } else {
                            _showUploadBottomSheet(
                                widget.accountID!, widget.subAccountID!, "");
                          }
                        },
                      ),
                      if ((_masterTabController?.index ?? 0) == 0)
                        SpeedDialChild(
                          child: Icon(Icons.download),
                          backgroundColor: trialStatus.isNotEmpty
                              ? Colors.grey
                              : AppColors.primaryMain,
                          foregroundColor:
                              themeProvider.getTheme.colorScheme.onPrimary,
                          label: 'Export Locations',
                          labelStyle: typography.Body1,
                          onTap: trialStatus.isNotEmpty
                              ? null
                              : () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return ExportDialog(
                                        accountId: widget.accountID!,
                                        subAccountId: widget.subAccountID!,
                                        sovId: "",
                                        locationId: selectedMainTab == 0
                                            ? Provider.of<
                                                        MyLocationListProvider>(
                                                    context,
                                                    listen: false)
                                                .myLocationList
                                                .map((location) =>
                                                    location.id ?? "")
                                                .toList()
                                            : Provider.of<
                                                        MyLocationListProvider>(
                                                    context,
                                                    listen: false)
                                                .certifiedLocationList
                                                .map((location) =>
                                                    location.id ?? "")
                                                .toList(),
                                      );
                                    },
                                  );
                                },
                        ),
                    ],
                  ),
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
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: CustomSpacing.one),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10.0),
                                    child: Text(widget.accountName,
                                        style: typography.Base_Bold),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Consumer<JobMonitoringProvider>(builder:
                                          (context, jobMonitoringProvider,
                                              child) {
                                        return Container(
                                          child:
                                              _getLiveUI(jobMonitoringProvider),
                                        );
                                      }),
                                      // Consumer<JobMonitoringProvider>(
                                      //     builder: (context,
                                      //         jobMonitoringProvider,
                                      //         child) {
                                      //   return Container(
                                      //     child:Icon(Icons.info),
                                      //   );
                                      // }),
                                      Consumer<MyLocationListProvider>(
                                        builder: (context,
                                            myLocationListProvider, child) {
                                          return myLocationListProvider
                                                  .myLocationList.isNotEmpty
                                              ? IconButton(
                                                  icon: isLoading
                                                      ? SizedBox(
                                                          height: 24,
                                                          width: 24,
                                                          child:
                                                              CircularProgressIndicator(
                                                                  strokeWidth:
                                                                      2),
                                                        )
                                                      : SvgPicture.asset(
                                                          'assets/images/contract.svg'),
                                                  onPressed: isLoading
                                                      ? null // Disable button while loading
                                                      : () async {
                                                          setState(() {
                                                            isLoading =
                                                                true; // Show loader
                                                          });

                                                          var provider = Provider
                                                              .of<JobMonitoringProvider>(
                                                                  context,
                                                                  listen:
                                                                      false);

                                                          try {
                                                            Map<String,
                                                                    dynamic>?
                                                                summaryData =
                                                                await provider.fetchLocationSummary(
                                                                    widget
                                                                        .accountID!,
                                                                    widget
                                                                        .subAccountID!);

                                                            if (summaryData !=
                                                                null) {
                                                              showDialog(
                                                                context:
                                                                    context,
                                                                builder:
                                                                    (context) {
                                                                  return Dialog(
                                                                    shape:
                                                                        RoundedRectangleBorder(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              16),
                                                                    ),
                                                                    child: _buildProcessSummary(
                                                                        summaryData),
                                                                  );
                                                                },
                                                              );
                                                            } else {
                                                              ScaffoldMessenger
                                                                      .of(context)
                                                                  .showSnackBar(
                                                                SnackBar(
                                                                  content: Text(
                                                                    'Failed to fetch summary',
                                                                    style: Theme.of(
                                                                            context)
                                                                        .textTheme
                                                                        .bodyMedium
                                                                        ?.copyWith(
                                                                            color:
                                                                                Colors.white),
                                                                  ),
                                                                  backgroundColor:
                                                                      Colors
                                                                          .red,
                                                                ),
                                                              );
                                                            }
                                                          } catch (e) {
                                                            ScaffoldMessenger
                                                                    .of(context)
                                                                .showSnackBar(
                                                              SnackBar(
                                                                content: Text(
                                                                  'Error: $e',
                                                                  style: Theme.of(
                                                                          context)
                                                                      .textTheme
                                                                      .bodyMedium
                                                                      ?.copyWith(
                                                                          color:
                                                                              Colors.white),
                                                                ),
                                                                backgroundColor:
                                                                    Colors.red,
                                                              ),
                                                            );
                                                          } finally {
                                                            setState(() {
                                                              isLoading =
                                                                  false; // Hide loader after API call
                                                            });
                                                          }
                                                        },
                                                )
                                              : Container();
                                        },
                                      ),
                                      // Consumer<MyLocationListProvider>(
                                      //   builder: (context, myLocationListProvider, child) {
                                      //     return myLocationListProvider.myLocationList.isNotEmpty
                                      //         ? IconButton(
                                      //       icon: SvgPicture.asset('assets/images/contract.svg'),
                                      //       onPressed: () async {
                                      //         var provider =
                                      //         Provider.of<JobMonitoringProvider>(context, listen: false);
                                      //
                                      //         Map<String, dynamic>? summaryData =
                                      //         await provider.fetchLocationSummary(
                                      //             widget.accountID!, widget.subAccountID!);
                                      //
                                      //         if (summaryData != null) {
                                      //           showDialog(
                                      //             context: context,
                                      //             builder: (context) {
                                      //               return Dialog(
                                      //                 shape: RoundedRectangleBorder(
                                      //                   borderRadius: BorderRadius.circular(16),
                                      //                 ),
                                      //                 child: _buildProcessSummary(summaryData),
                                      //               );
                                      //             },
                                      //           );
                                      //         } else {
                                      //           ScaffoldMessenger.of(context).showSnackBar(
                                      //             SnackBar(
                                      //               content: Text(
                                      //                 'Failed to fetch summary',
                                      //                 style: typography.Body1.copyWith(color: Colors.white),
                                      //               ),
                                      //               backgroundColor: Colors.red,
                                      //             ),
                                      //           );
                                      //         }
                                      //       },
                                      //     )
                                      //         : Container();
                                      //   },
                                      // ),
                                    ],
                                  ),
                                ],
                              ),

                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10.0),
                                child: Row(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          top: 2.0, bottom: 6),
                                      child: Row(
                                        children: [
                                          InkWell(
                                            onTap: () {
                                              Navigator.pushAndRemoveUntil(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        AccountListScreen()),
                                                (route) =>
                                                    false, // This removes all previous routes
                                              ).then((_) {
                                                // Optional: Add any actions to perform after navigation
                                              });
                                            },
                                            child: Text(widget.accountName,
                                                style: typography.InputLabel),
                                          ),
                                          Text(' > ',
                                              style: typography.InputLabel),
                                          InkWell(
                                            onTap: () {
                                              Navigator.pushAndRemoveUntil(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      SubAccountListScreen(
                                                    accountId:
                                                        widget.accountID ?? "",
                                                    accountName:
                                                        widget.subAccountName ??
                                                            "",
                                                  ),
                                                ),
                                                (route) =>
                                                    false, // This removes all previous routes
                                              ).then((_) {
                                                // Optional: Add any actions to perform after navigation
                                              });
                                            },
                                            child: Text(widget.subAccountName,
                                                style: typography.InputLabel),
                                          ),
                                          Text(' > ',
                                              style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.white70)),
                                          Text(
                                              _masterTabController!.index
                                                          .toString() ==
                                                      "0"
                                                  ? "Location list"
                                                  : _masterTabController!.index
                                                              .toString() ==
                                                          "1"
                                                      ? "Sovs"
                                                      : _masterTabController!
                                                                  .index
                                                                  .toString() ==
                                                              "2"
                                                          ? "Shared"
                                                          : "Configure",
                                              style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.white)),
                                        ],
                                      ),
                                    ),
                                    // Container(
                                    //   child: MaintenanceUI(isMaintenance: isMaintenance),
                                    // ),
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
                                  borderRadius: BorderRadius.circular(
                                      16), // Rounded edges
                                ),
                                margin: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 0),
                                child: DefaultTabController(
                                  length: _masterTabController?.length ?? 4,
                                  child: Column(
                                    children: <Widget>[
                                      // Container for the TabBar with arrows
                                      Container(
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(16),
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
                                                scrollDirection:
                                                    Axis.horizontal,
                                                child: TabBar(
                                                  controller:
                                                      _masterTabController,
                                                  tabAlignment:
                                                      TabAlignment.start,
                                                  labelStyle:
                                                      typography.Subtitle2,
                                                  isScrollable: true,
                                                  indicatorColor:
                                                      Colors.lightBlueAccent,
                                                  labelColor:
                                                      Colors.lightBlueAccent,
                                                  unselectedLabelColor:
                                                      Colors.grey,
                                                  tabs: [
                                                    Tab(
                                                      text: 'Locations',
                                                    ),
                                                    Tab(
                                                      text: 'SOVs',
                                                    ),
                                                    Tab(text: 'Shared'),
                                                    // Tab(
                                                    //     text:
                                                    //         'Access Requests'),
                                                    // Tab(text: 'Data'),
                                                    if (userProfileProvider
                                                            .trialInfo['status']
                                                            ?.isEmpty ??
                                                        true)
                                                      Tab(
                                                          text:
                                                              'Configuration'),
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
                                    // Consumer<MyLocationListProvider>(
                                    //   builder: (context, myLocationListProvider, child) {
                                    //     return RefreshIndicator(
                                    //       onRefresh: () async {
                                    //         myLocationListProvider.page = 1;
                                    //         if (_selectedScreen == Screens.locationList) {
                                    //           myLocationListProvider.myLocationList.clear();
                                    //           myLocationListProvider.fetchLocationList(
                                    //             context,
                                    //             "",
                                    //             1,
                                    //             40,
                                    //             widget.accountID,
                                    //             widget.subAccountID,
                                    //             widget.initialProcessId,
                                    //             widget.initialSubProcessId,
                                    //           );
                                    //         } else if (_selectedScreen == Screens.certifiedLocationList) {
                                    //           myLocationListProvider.certifiedLocationList.clear();
                                    //           myLocationListProvider.fetchCertifiedLocationList(
                                    //             context,
                                    //             "",
                                    //             1,
                                    //             40,
                                    //             widget.accountID,
                                    //             widget.subAccountID,
                                    //             widget.initialProcessId,
                                    //             widget.initialSubProcessId,
                                    //           );
                                    //         }
                                    //       },
                                    //       child: SingleChildScrollView(
                                    //         physics: AlwaysScrollableScrollPhysics(), // Ensures scrolling
                                    //         child: _getLocationListBodyUI(myLocationListProvider, ""),
                                    //       ),
                                    //     );
                                    //   },
                                    // ),
                                    Consumer<MyLocationListProvider>(
                                      builder: (context, myLocationListProvider,
                                          child) {
                                        return RefreshIndicator(
                                          onRefresh: () async {
                                            myLocationListProvider.page = 1;
                                            if (_selectedScreen ==
                                                Screens.locationList) {
                                              myLocationListProvider
                                                  .myLocationList
                                                  .clear();
                                              myLocationListProvider
                                                  .fetchLocationList(
                                                context,
                                                "",
                                                1,
                                                40,
                                                widget.accountID,
                                                widget.subAccountID,
                                                widget.initialProcessId,
                                                widget.initialSubProcessId,
                                              );
                                            } else if (_selectedScreen ==
                                                Screens.certifiedLocationList) {
                                              myLocationListProvider
                                                  .certifiedLocationList
                                                  .clear();
                                              myLocationListProvider
                                                  .fetchCertifiedLocationList(
                                                context,
                                                "",
                                                1,
                                                40,
                                                widget.accountID,
                                                widget.subAccountID,
                                                widget.initialProcessId,
                                                widget.initialSubProcessId,
                                              );
                                            }
                                          },
                                          child: _getLocationListBodyUI(
                                              myLocationListProvider, ""),
                                        );
                                      },
                                    ),

                                    // Consumer<MyLocationListProvider>(
                                    //     builder:
                                    //         (context,
                                    //         myLocationListProvider,
                                    //         child) {
                                    //       return _getLocationListBodyUI(
                                    //           myLocationListProvider, "");
                                    //     }),
                                    Container(
                                      margin: EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      child: sovBody(typography),
                                    ),
                                    // _getComingSoonUI(),
                                    _getComingSoonUI(),
                                    // DataTab(
                                    //   accountId: widget.accountID,
                                    //   subaccountId: widget.subAccountID,
                                    // ),
                                    if (userProfileProvider
                                            .trialInfo['status']?.isEmpty ??
                                        true)
                                      ConfigurationTab(
                                        accountId: widget.accountID,
                                        subaccountId: widget.subAccountID,
                                      ),
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
                      accountId: widget.accountID!,
                      subAccountId: widget.subAccountID!,
                      sovId: widget.accountID!,
                      searchQuery: locationQuery,
                      showGeoRatings: selectedMainTab == 0 && selectedTab != 1,
                      initialProcessId: widget.initialProcessId,
                      initialSubProcessId: widget.initialSubProcessId,
                    ),
                  ),
                ),
              );
            },
          );
        }),
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
          child: Consumer<UserProfileProvider>(
              builder: (context, userProfileProvider, child) {
            final trialStatus = userProfileProvider.trialInfo['status'] ?? '';
            return Consumer<MyLocationListProvider>(
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
                        color:
                            Theme.of(context).colorScheme.surfaceContainerHigh,
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
                              locationListProvider
                                  .certifiedLocationList.length) {
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
                      onPressed: trialStatus.isNotEmpty
                          ? null
                          : () {
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
                                        print(_selectedScreen);
                                        if (_selectedScreen ==
                                            Screens.locationList) {
                                          print(
                                              'Selected ids: ${locationListProvider.selectedLocations.map((sov) => sov.id).toList()}');
                                          // On export button click
                                          List<String> selectedSovIds = Provider
                                                  .of<MyLocationListProvider>(
                                                      context,
                                                      listen: false)
                                              .selectedLocations
                                              .map((sov) => sov.id!)
                                              .toList();
                                          print(
                                              'Selected ids: $selectedSovIds');

                                          if (selectedSovIds.isNotEmpty) {
                                            Navigator.pop(context);
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return ExportDialog(
                                                  accountId: widget.accountID!,
                                                  subAccountId:
                                                      widget.subAccountID!,
                                                  locationId: selectedSovIds,
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
                                            Screens.certifiedLocationList) {
                                          // On export button click
                                          List<String> selectedLoactionIds =
                                              Provider.of<MyLocationListProvider>(
                                                      context,
                                                      listen: false)
                                                  .certifiedLocationList
                                                  .where((location) =>
                                                      location.isSelected ??
                                                      false)
                                                  .map((sov) => sov.id!)
                                                  .toList();

                                          if (selectedLoactionIds.isNotEmpty) {
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return ExportDialog(
                                                  accountId: widget.accountID!,
                                                  subAccountId:
                                                      widget.subAccountID!,
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
                                      child: Text('Export',
                                          style: typography.Body1),
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
                              context, widget.accountID!, widget.subAccountID!);
                        },
                        icon: Icon(Symbols.note_stack_add),
                        tooltip: 'Add Tag'),
                    IconButton(
                      onPressed: trialStatus.isNotEmpty
                          ? null
                          : () {
                              // Implement bulk add to SOV
                              locationListProvider.addSelectedToSOV(
                                  context,
                                  widget.accountID!,
                                  widget.subAccountID!,
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
                                child: Text('Cancel', style: typography.Body1),
                              ),
                              TextButton(
                                onPressed: () {
                                  locationListProvider.deleteSelectedLocations(
                                    context,
                                    widget.accountID!,
                                    widget.subAccountID!,
                                  );
                                  Navigator.pop(context);
                                },
                                child: Text('Delete', style: typography.Body1),
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
                          /*SizedBox(width: CustomSpacing.two),
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
                          ),*/
                        ],
                      ),
                    ),
                    SizedBox(width: CustomSpacing.four),
                    SizedBox(height: CustomSpacing.eight),
                    // Options are Upload SOV, Add Location, Export Locations
                    /*PopupMenuButton(
                        icon: Icon(Icons.more_vert),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            child: ListTile(
                              leading: Icon(Icons.upload),
                              title: Text(
                                isUploadInProgress?'Continue': 'Upload SOV',
                                style: typography.Body1,
                              ),
                              onTap: () async {
                                // Add your logic for uploading SOV
                                if (isMaintenance) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'SOV upload is disabled during maintenance period.'),
                                    ),
                                  );
                                } else if (isUploadInProgress) {
                                  String tempProcessId =
                                      await SharedPreferenceService
                                              .getSovUploadTempId() ??
                                          "";
                                  String state = await SharedPreferenceService
                                          .getSovUploadState() ??
                                      "";
                                  // Call API to get get necessary data and navigate to the respective screen
                                  Provider.of<UploadSovProvider>(context,
                                          listen: false)
                                      .fetchSovUploadData(
                                          context,
                                          widget.accountID,
                                          widget.accountName,
                                          widget.subAccountID,
                                          tempProcessId,
                                          state);
                                } else {
                                  */
                    /* _showUploadDialog(
                                      widget.accountID, widget.subAccountID, "");*/
                    /*
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
                      ),*/
                  ]
                ],
              );
            });
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
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHigh,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                // backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                rippleColor: Colors.grey[800]!,
                // tab button ripple color when pressed
                hoverColor: Colors.grey[700]!,
                // tab button hover color
                haptic: true,
                // haptic feedback
                duration: Duration(milliseconds: 100),
                // tab animation duration
                tabBorderRadius: 8,
                //tabActiveBorder: Border.all(color: Colors.black, width: 1), // tab button border
                //tabBorder: Border.all(color: Colors.grey, width: 1), // tab button border
                //tabShadow: [BoxShadow(color: Colors.grey.withOpacity(0.5), blurRadius: 8)], // tab button shadow
                curve: Curves.easeOutExpo,
                // tab animation curves

                gap: 8,
                // the tab button gap between icon and text
                color: Colors.grey[300],
                // unselected icon color
                activeColor: AppColors.primaryMain,
                // selected icon and text color
                iconSize: 24,
                // tab button icon size
                tabBackgroundColor: AppColors.primaryMain.withOpacity(0.16),
                // selected tab background color

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
                    icon: Remix.bar_chart_box_ai_line,
                    text: 'Overall Score',
                  ),
                  GButton(
                    icon: Remix.road_map_line,
                    text: 'Map View',
                  ),
                ]),
          ),
        ),
        SizedBox(height: CustomSpacing.two),
        Expanded(
          child: TabBarView(
            physics: NeverScrollableScrollPhysics(), // Prevents scrolling in main TabBarView
            controller: _mainTabController,
            children: [
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
                                        locationListProvider.locationHits.toString(),
                                        style: typography.BottomNavigationActiveLabel
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
                              _tabController?.animateTo(1);
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
                                      style: typography.BottomNavigationActiveLabel
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
                      physics: NeverScrollableScrollPhysics(), // Prevents scrolling in nested TabBarView
                      children: [
                        _getLocationListAllUI(),
                        _getLocationListCertifiedUI(),
                      ],
                    ),
                  ),
                ],
              ),
              // Map View
              Consumer<MyLocationListProvider>(
                builder: (context, locationListProvider, child) {
                  return LocationTable(
                      locations: locationListProvider.myLocationList);
                },
              ),
              LocationListMapView(
                accountId: widget.accountID!,
                subAccountId: widget.subAccountID!,
              ),
            ],
          ),
        ),

      ],
    );
  }

  Widget _getLiveUI(JobMonitoringProvider provider) {
    var typography = CustomTypography(context);

    // Define the secondary stream with proper caching
    Stream<QuerySnapshot<Map<String, dynamic>>> processStream;
    print('docids: ${provider.docIds}');
    processStream = FirebaseFirestore.instance
        .collection('processes')
        .where('location_data.account_id', isEqualTo: widget.accountID)
        .where('location_data.sub_account_id', isEqualTo: widget.subAccountID)
        .where('process_type', isEqualTo: 'hazard')
        .orderBy('created_at', descending: true)
        .limit(1)
        .snapshots()
        .asBroadcastStream(); // Convert to broadcast stream to prevent multiple subscriptions

    // if (provider.isSuperAdmin) {
    //   processStream = FirebaseFirestore.instance
    //       .collection('processes')
    //       .where('process_type', isEqualTo: 'hazard')
    //       .orderBy('created_at', descending: true)
    //       .limit(1)
    //       .snapshots()
    //       .asBroadcastStream(); // Convert to broadcast stream to prevent multiple subscriptions
    // }
    // else if (provider.docIds.isNotEmpty) {
    //   processStream = FirebaseFirestore.instance
    //       .collection('processes')
    //       .where('company_id', whereIn: provider.docIds) // Filter by company_id
    //       .where('process_type',
    //           isEqualTo: 'hazard') // Skip documents with heatmap
    //       .orderBy('created_at', descending: true)
    //       .limit(1)
    //       .snapshots()
    //       .asBroadcastStream();
    // } else {
    //   processStream = Stream.empty();
    // }

    // Cache the subaccount stream
    final subaccountStream = FirebaseFirestore.instance
        .collection('subaccount')
        .doc(widget.subAccountID)
        .snapshots()
        .asBroadcastStream();

    // Combine streams with debounce to prevent rapid UI updates
    var combinedStream = Rx.combineLatest2<
        DocumentSnapshot<Map<String, dynamic>>,
        QuerySnapshot<Map<String, dynamic>>,
        Map<String, dynamic>>(
      subaccountStream,
      processStream,
      (heatmapSnapshot, processSnapshot) {
        return {
          'heatmapData': heatmapSnapshot.data(),
          'processData': processSnapshot.docs.isNotEmpty
              ? processSnapshot.docs.first.data()
              : null,
        };
      },
    ).debounceTime(
        const Duration(milliseconds: 500)); // Add debounce to stabilize updates

    return StreamBuilder<Map<String, dynamic>>(
      stream: combinedStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return SizedBox(height: CustomSpacing.six);
        }

        if (snapshot.hasError) {
          return SizedBox.shrink();
        }

        if (!snapshot.hasData) {
          return SizedBox(height: CustomSpacing.sixteen);
        }

        var data = snapshot.data!;
        var heatmapStatus = data['heatmapData']?['heatmap_status'] ?? '';
        var processStatus = data['processData']?['status'] ?? 'completed';

        print('Heatmap Status: $heatmapStatus');

        var provider =
            Provider.of<MyLocationListProvider>(context, listen: false);
        provider.isHeatMapGeneratingLive =
            heatmapStatus.toString().toLowerCase() == 'initiated';

        // Extract process count and calculate percentage
        int totalCompleted =
            data['processData']?['total_processes_completed'] ?? 0;
        int totalProcesses = data['processData']?['total_processes'] ?? 1;
        double percentage = (totalCompleted / totalProcesses) * 100;

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Column(
            key: ValueKey('$processStatus-$heatmapStatus'),
            // Add key for proper animation
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (processStatus.toString().toLowerCase() == 'processing')
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ProcessMonitoringScreen(
                                      accountId: widget.accountID,
                                      subAccountId: widget.subAccountID,
                                    )))
                        // Navigator.push(MaterialPageRoute(
                        //         builder: (_) => ProcessMonitoringScreen(
                        //           accountId: widget.accountID,
                        //           subAccountId: widget.subAccountID,
                        //         ),
                        //       ))

                        .then((value) => _getData());
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Lottie.asset(
                                  'assets/lottie/loading.json',
                                  width: 20,
                                  height: 20,
                                ),
                                const SizedBox(width: 8.0),
                                Text(
                                  'Processing '
                                  '${percentage.toStringAsFixed(0)}%',
                                  style: typography.Caption.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                // Text(
                                //   'Processing $totalCompleted/$totalProcesses',
                                //   style: typography.Caption.copyWith(
                                //       fontWeight: FontWeight.w500),
                                // ),
                              ],
                            ), /*
                            CircularProgressIndicator(
                              value: percentage / 100,
                            ),*/
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              else if (heatmapStatus.toString().toLowerCase() == 'initiated')
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Lottie.asset(
                                'assets/lottie/loading.json',
                                width: 20,
                                height: 20,
                              ),
                              const SizedBox(width: 8.0),
                              Text(
                                'Generating Heatmap',
                                style: typography.Caption.copyWith(
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProcessSummary(Map<String, dynamic>? summaryData) {
    if (summaryData == null || summaryData.isEmpty) {
      return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).hoverColor,
            borderRadius: BorderRadius.circular(10),
          ),
          // margin: EdgeInsets.all(10.0),
          // padding: EdgeInsets.all(10.0),
          height: 200,
          child: Center(child: CircularProgressIndicator())); // Show loader
    }

    var typography = CustomTypography(context);
    final hazardVendorData = summaryData['hazard_rating_summary'] ?? {};
    return Container(
      margin: EdgeInsets.all(0.0),
      decoration: BoxDecoration(
        color: Theme.of(context).hoverColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          color: Theme.of(context).hoverColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Header
            ListTile(
              trailing: IconButton(
                icon: Icon(Symbols.cancel, color: Colors.red),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),

            // Padding(
            //   padding:
            //       const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0.0),
            //   child: Divider(),
            // ),
            // SizedBox(height: 8),

            // _buildRunTimeSummary(summaryData['result']),
            // SizedBox(height: 8),
            // Padding(
            //   padding:
            //       const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0.0),
            //   child: Divider(),
            // ),
            // SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 16.0, bottom: 16),
              child: Text(
                "Geo Rating Summary",
                style: typography.Body1.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            _buildDynamicGeoRatingSummary(summaryData),

            // Padding(
            //   padding:
            //       const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0.0),
            //   child: Divider(),
            // ),
            //_buildHazardSummary(summaryData),
            Container(
                height: MediaQuery.of(context).size.height / 2.5,
                width: MediaQuery.of(context).size.width,
                child: _buildHazardVendorSummary(hazardVendorData, typography)),
          ],
        ),
      ),
    );
  }

  Widget _buildHazardVendorSummary(
      Map<dynamic, dynamic> hazardVendorData, CustomTypography typography) {
    // if (hazardVendorData.isEmpty) {
    //   return SizedBox.shrink();
    // }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            "Hazard Rating Summary",
            style: typography.Body1.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          // Ensure scrolling behavior is properly handled
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Column(
              children: hazardVendorData.keys.map((hazard) {
                final vendors =
                    hazardVendorData[hazard] as Map<String, dynamic>;

                return Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).hoverColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: Text(
                          hazard,
                          style: typography.Body2.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      if (vendors.isNotEmpty)
                        ...vendors.keys.map((vendor) {
                          final scores =
                              vendors[vendor] as Map<String, dynamic>;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 8, 16, 0),
                                child: Text(
                                  "Source $vendor",
                                  style: typography.Body2.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 8, 16, 0),
                                child: _buildHazardDetailRow(
                                  "Locations with Score",
                                  scores.entries
                                      .where((entry) => entry.key != "None")
                                      .map((entry) {
                                        final value = entry.value;
                                        if (value is int) {
                                          return value;
                                        } else if (value
                                            is Map<String, dynamic>) {
                                          return value.values.fold(
                                              0,
                                              (prev, next) =>
                                                  prev + (next as int));
                                        } else {
                                          return 0;
                                        }
                                      })
                                      .fold(0, (prev, next) => prev + next)
                                      .toString(),
                                  typography,
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 0, 16, 8),
                                child: _buildHazardDetailRow(
                                  "Locations without Score",
                                  scores['None']?.toString() ?? "0",
                                  typography,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0),
                                child: Divider(),
                              ),
                              ExpansionTile(
                                tilePadding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                collapsedShape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                controlAffinity:
                                    ListTileControlAffinity.trailing,
                                trailing: Icon(
                                  Icons.add_circle_outline,
                                  color: Theme.of(context).disabledColor,
                                ),
                                initiallyExpanded: false,
                                title: Text(
                                  "Hazard Risk Score Wise Locations",
                                  style: typography.Body2.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).disabledColor,
                                  ),
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0, vertical: 8.0),
                                    child: _buildHazardRiskScores(
                                        scores, typography),
                                  ),
                                ],
                              ),
                            ],
                          );
                        }).toList(),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Padding(
  //         padding: const EdgeInsets.all(16.0),
  //         child: Text(
  //           "Hazard Rating Summary",
  //           style: typography.Body1.copyWith(fontWeight: FontWeight.w600),
  //         ),
  //       ),
  //   SingleChildScrollView(
  //   child: Column(
  //   children: hazardVendorData.keys.map((hazard) {
  //   final vendors = hazardVendorData[hazard] as Map<String, dynamic>;
  //
  //   // If the hazard has no vendors, still show the hazard name
  //   return Container(
  //   margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
  //   decoration: BoxDecoration(
  //   color: Theme.of(context).hoverColor,
  //   borderRadius: BorderRadius.circular(16),
  //   ),
  //   child: Column(
  //   crossAxisAlignment: CrossAxisAlignment.center,
  //   mainAxisAlignment: MainAxisAlignment.center,
  //   children: [
  //   Padding(
  //   padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
  //   child: Text(
  //   hazard, // Display hazard name
  //   style: typography.Body2.copyWith(
  //   fontWeight: FontWeight.w600,
  //   color: Theme.of(context).colorScheme.onSurface,
  //   ),
  //   ),
  //   ),
  //   if (vendors.isNotEmpty) // Only show vendors if available
  //   ...vendors.keys.map((vendor) {
  //   final scores = vendors[vendor] as Map<String, dynamic>;
  //
  //   return Column(
  //   crossAxisAlignment: CrossAxisAlignment.start,
  //   children: [
  //   Padding(
  //   padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
  //   child: Text(
  //   "$hazard ($vendor)",
  //   style: typography.Body2.copyWith(
  //   fontWeight: FontWeight.w500,
  //   ),
  //   ),
  //   ),
  //   Padding(
  //   padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
  //   child: _buildHazardDetailRow(
  //   "Locations with Score",
  //   scores.entries
  //       .where((entry) => entry.key != "None")
  //       .map((entry) {
  //   final value = entry.value;
  //   if (value is int) {
  //   return value;
  //   } else if (value is Map<String, dynamic>) {
  //   return value.values.fold(0, (prev, next) => prev + (next as int));
  //   } else {
  //   return 0;
  //   }
  //   }).fold(0, (prev, next) => prev + next).toString(),
  //   typography,
  //   ),
  //   ),
  //   Padding(
  //   padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
  //   child: _buildHazardDetailRow(
  //   "Locations without Score",
  //   scores['None']?.toString() ?? "0",
  //   typography,
  //   ),
  //   ),
  //   Padding(
  //   padding: const EdgeInsets.symmetric(horizontal: 16.0),
  //   child: Divider(),
  //   ),
  //   ExpansionTile(
  //   tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
  //   shape: RoundedRectangleBorder(
  //   borderRadius: BorderRadius.circular(12),
  //   ),
  //   collapsedShape: RoundedRectangleBorder(
  //   borderRadius: BorderRadius.circular(12),
  //   ),
  //   controlAffinity: ListTileControlAffinity.trailing,
  //   trailing: Icon(
  //   Icons.add_circle_outline,
  //   color: Theme.of(context).disabledColor,
  //   ),
  //   initiallyExpanded: false,
  //   title: Text(
  //   "Hazard Risk Score Wise Locations",
  //   style: typography.Body2.copyWith(
  //   fontWeight: FontWeight.w600,
  //   color: Theme.of(context).disabledColor,
  //   ),
  //   ),
  //   children: [
  //   Padding(
  //   padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
  //   child: _buildHazardRiskScores(scores, typography),
  //   ),
  //   ],
  //   ),
  //   ],
  //   );
  //   }).toList(),
  //   ],
  //   ),
  //   );
  //   }).toList(),
  //   ),
  //   ),
  //
  //
  //     ],
  //   );
  // }
  Widget _buildHazardDetailRow(
      String label, String value, CustomTypography typography) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: typography.Body2),
        Text(
          value,
          style: typography.Body1.copyWith(
            color: AppColors.primaryMain,
            fontWeight: FontWeight.w300,
          ),
        ),
      ],
    );
  }

  Widget _buildHazardRiskScores(Map<String, dynamic> scores, typography) {
    final riskScores = [
      {"label": "Severe impact", "key": "1", "color": Colors.red, "star": "★"},
      {"label": "High impact", "key": "2", "color": Colors.orange, "star": "★"},
      {
        "label": "Medium impact",
        "key": "3",
        "color": Colors.yellow,
        "star": "★"
      },
      {
        "label": "Low impact",
        "key": "4",
        "color": Colors.lightGreen,
        "star": "★"
      },
      {"label": "No impact", "key": "5", "color": Colors.green, "star": "★"},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: riskScores.map((score) {
        final count = scores[score['key']]?.toString() ?? "0";
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: "${score['key']}   ",
                      style: typography.Body2,
                    ),
                    TextSpan(
                      text: "${score['star']!}",
                      style: typography.Body2.copyWith(
                        color: score['color'] as Color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: score['key'] == 1
                          ? " (${score['label']})"
                          : " (${score['label']})",
                      style: typography.Body2.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                count,
                style: typography.Body1.copyWith(
                  fontWeight: FontWeight.w300,
                  color: AppColors.primaryMain,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildUsageAndGEESummary(
      Map<String, dynamic> apiData, CustomTypography typography,
      {required String type}) {
    if (apiData.isEmpty || apiData['result'] == null) {
      return const SizedBox.shrink();
    }

    final result = type == "process"
        ? apiData['result']
        : apiData['result']?['subprocesses'];
    if (result == null) return const SizedBox.shrink();

    // Extract dynamic keys and data
    final totalProcessesCompleted =
        result['total_processes_completed']?.toString() ?? "0";
    final totalTimeElapsed =
        result['total_time_elapsed_in_earth_engine']?.toString() ?? "0";
    final assetIngestionTime =
        _formatTime(result['asset_upload_summary']?['time_taken'] ?? 0.0);

    // Fetch hazard file summary dynamically
    final hazardFileKey = result['hazard_file_summary']?.keys?.first ?? "";
    final hazardProcessingTime = _formatTime(
        result['hazard_file_summary']?[hazardFileKey]?['time_taken'] ?? 0.0);

    // Calculate Wait Time
    final totalWaitTime = _formatTime(
      (result['total_time_taken'] ?? 0.0) -
          (result['asset_upload_summary']?['time_taken'] ?? 0.0) -
          (result['hazard_file_summary']?[hazardFileKey]?['time_taken'] ?? 0.0),
    );

    final usageSummary = {
      "Number of Batch Process": totalProcessesCompleted,
      "Number of GEE Process": totalTimeElapsed,
    };

    final geeSummary = {
      "Asset Ingestion Time": assetIngestionTime,
      "Hazard Processing Time": hazardProcessingTime,
      "Wait Time": totalWaitTime,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child:
              _buildSummarySection("Usage Summary", usageSummary, typography),
        ),
        const SizedBox(height: 8),
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: _buildSummarySection("GEE Summary", geeSummary, typography),
        ),
      ],
    );
  }

  Widget _buildSummarySection(String title, Map<String, String> summaryData,
      CustomTypography typography) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            title,
            style: typography.Body1.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8.0),
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
          decoration: BoxDecoration(
            color: Theme.of(context).hoverColor,
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Column(
            children: summaryData.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key, style: typography.Body2),
                    Text(entry.value,
                        style: typography.Body1.copyWith(
                          color: AppColors.primaryMain,
                          fontWeight: FontWeight.w300,
                        )),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(Map<String, dynamic> timestamp) {
    DateTime dateTime =
        DateTime.fromMillisecondsSinceEpoch(timestamp['_seconds'] * 1000);
    return "${dateTime.day.toString().padLeft(2, '0')}-"
        "${dateTime.month.toString().padLeft(2, '0')}-"
        "${dateTime.year.toString().substring(2)} "
        "${dateTime.hour.toString().padLeft(2, '0')}:"
        "${dateTime.minute.toString().padLeft(2, '0')}:"
        "${dateTime.second.toString().padLeft(2, '0')}";
  }

  String _formatTime(double seconds) {
    int hours = (seconds ~/ 3600);
    int minutes = ((seconds % 3600) ~/ 60);
    int secs = (seconds % 60).toInt();
    return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
  }

  Widget _buildRunTimeSummary(Map<String, dynamic> processData) {
    // Extract time data
    if (processData == null ||
        processData.isEmpty ||
        processData['geocode_starting_time'] == null ||
        processData['geocode_ending_time'] == null) {
      return const SizedBox.shrink();
    }
    String startedAt = _formatTimestamp(processData['geocode_starting_time']);
    String finishedAt = _formatTimestamp(processData['geocode_ending_time']);
    Duration totalRunTime =
        Duration(seconds: processData['total_time_taken'] ?? 0);
    Duration geocodingRunTime = Duration(
        seconds: processData['geocode_ending_time']['_seconds'] -
            processData['geocode_starting_time']['_seconds']);
    Duration hazardRunTime = totalRunTime - geocodingRunTime;

    var typography = CustomTypography(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row with Start and End Times
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTimeColumn('Started at', startedAt, typography),
                _buildTimeColumn('Finished at', finishedAt, typography),
              ],
            ),
          ),
          Divider(color: Colors.white12),
          SizedBox(height: 8),
          // Run Time Details
          _buildRunTimeRow(
              'Total Run Time', _formatDuration(totalRunTime), typography),
          _buildRunTimeRow('Geocoding Run Time',
              _formatDuration(geocodingRunTime), typography),
          _buildRunTimeRow(
              'Hazard Run Time', _formatDuration(hazardRunTime), typography),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    return duration.toString().split('.').first.padLeft(8, '0');
  }

  Widget _buildRunTimeRow(
      String label, String duration, CustomTypography typography) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: typography.Body2),
          Text(
            duration,
            style: typography.Body1.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeColumn(
      String label, String time, CustomTypography typography) {
    return Column(
      crossAxisAlignment: label == 'Started at'
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end, // Align 'Finished at' to the right
      children: [
        Text(label, style: typography.Caption),
        SizedBox(height: 4),
        Text(
          time,
          style: typography.Body1.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildDynamicGeoRatingSummary(Map<String, dynamic> apiData,
      {bool isSubProcess = false}) {
    // Map<String, int> aggregatedScores = {
    //   "5": 0,
    //   "4": 0,
    //   "3": 0,
    //   "2": 0,
    //   "1": 0,
    // };

    final result = apiData['geo_rating_summary'];
    print('Result section: $result');

    if (result == null) {
      print('No "result" key found in apiData.');
      return _buildGeoRatingSummary(result);
    }

    if (isSubProcess) {
      final subprocesses = result['subprocesses'];
      print('Subprocesses: $subprocesses');

      if (subprocesses != null && subprocesses.isNotEmpty) {
        subprocesses.forEach((key, process) {
          final subScore = process['result']?['total_score_counts'];
          if (subScore != null) {
            subScore.forEach((rating, count) {
              result[rating] = (result[rating] ?? 0) + (count as int);
            });
          }
        });
      } else {
        // Fallback to use direct result scores if no subprocesses are present
        print('No subprocess data, using direct scores from result.');
        final Map<String, dynamic> directScores =
            result['total_score_counts'] ?? {};
        directScores.forEach((rating, count) {
          result[rating] = (result[rating] ?? 0) + (count as int);
        });
      }
    } else {
      final Map<String, dynamic> topLevelScore =
          result['summary']?['score'] ?? {};
      topLevelScore.forEach((rating, count) {
        result[rating] = (count ?? 0).toInt();
      });
    }

    print('Final aggregated scores: $result');
    return _buildGeoRatingSummary(result);
  }

  Widget _buildGeoRatingSummary(Map<String, dynamic> ratings) {
    var typography = CustomTypography(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Grid Layout for Star Ratings
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Row for 5 Star and 4 Star Locations
              Row(
                children: [
                  Expanded(
                      child: _buildRatingCard(
                          "1 Star Locations", ratings['1'] ?? 0, typography)),
                  SizedBox(width: 8), // Spacing between the two cards
                  Expanded(
                      child: _buildRatingCard(
                          "2 Star Locations", ratings['2'] ?? 0, typography)),
                ],
              ),
              SizedBox(height: 8), // Spacing between rows

              // Row for 3 Star and 2 Star Locations
              Row(
                children: [
                  Expanded(
                      child: _buildRatingCard(
                          "3 Star Locations", ratings['3'] ?? 0, typography)),
                  SizedBox(width: 8),
                  Expanded(
                      child: _buildRatingCard(
                          "4 Star Locations", ratings['4'] ?? 0, typography)),
                ],
              ),
              SizedBox(height: 8),

              // Single expanded row for 1 Star Locations
              _buildRatingCard(
                  "5 Star Locations", ratings['5'] ?? 0, typography),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildRatingCard(
      String title, int count, CustomTypography typography) {
    return Container(
      width: MediaQuery.sizeOf(context).width * 0.4,
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 22),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: typography.Body2,
          ),
          SizedBox(height: 4),
          Text(
            count.toString(),
            style: typography.Body1.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
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
                                  print("Clearing ratings filter");
                                  locationListProvider.clearRatingsFilter();
                                  print("Calling api after filter");
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
                          child: Container(
                            padding: EdgeInsets.only(right: 20, left: 20),
                            child: Text(
                              "It looks like you haven't added any locations yet. Let's get started! You can add locations by importing an XLS file or by clicking on \"Create New.\"",
                              textAlign: TextAlign.justify,
                              style: typography.Body1,
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () async {
                            locationListProvider.certifiedPage = 1;
                            // locationListProvider.fetchCertifiedLocationList(
                            //   context,
                            //   "",
                            //   locationListProvider.certifiedPage,
                            //   40,
                            //   widget.accountID,
                            //   widget.subAccountID,
                            //   widget.initialProcessId,
                            //   widget.initialSubProcessId,
                            // );
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
                            locationListProvider.fetchAllLocationList(
                              context,
                              widget.accountID,
                              widget.subAccountID,
                              processId: widget.initialProcessId,
                              subProcessId: widget.initialSubProcessId,
                            );
                          },
                          child: ListView.builder(
                            physics: ClampingScrollPhysics(),
                            shrinkWrap: true,
                            itemCount:
                                locationListProvider.myLocationList.length,
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
                                  /*print(
                                      "location list: ${locationListProvider.myLocationList}");*/
                                  return Column(
                                    children: [
                                      MyLocationCard(
                                        hazards: locationListProvider
                                            .myLocationList[index].hazard,
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
                                                .geocodedAddress ??
                                            '',
                                        percentage: double.parse(
                                            locationListProvider
                                                    .myLocationList[index]
                                                    .finalAddress
                                                    ?.percent ??
                                                '0'),
                                        geocodingScore:
                                        locationListProvider
                                                .myLocationList[index]
                                                .finalAddress
                                                ?.score ??
                                            0,
                                        riskScore: locationListProvider
                                                .myLocationList[index]
                                                .overallScore ??
                                            5,
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
                                                      widget.accountID!,
                                                      widget.subAccountID!,
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
                                                widget.initialProcessId,
                                                widget.initialSubProcessId,
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
                                              widget.accountID!,
                                              widget.subAccountID!,
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
                                                  widget.accountID!,
                                                  widget.subAccountID!,
                                                  locationId);
                                        },
                                        lat: locationListProvider
                                                .myLocationList[index]
                                                .finalAddress
                                                ?.latitude
                                                .toString() ??
                                            "",
                                        long: locationListProvider
                                                .myLocationList[index]
                                                .finalAddress
                                                ?.longitude
                                                .toString() ??
                                            "",
                                        overallScore: locationListProvider
                                                .myLocationList[index]
                                                .overallScore
                                                ?.toString() ??
                                            "0",
                                        hazardProcess: locationListProvider
                                            .myLocationList[index]
                                            .isHazardProcess,
                                        getData: _getData,
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Center(
                                          child: Text(
                                            LanguageService.getTranslated(
                                                context,
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

                              return
                                MyLocationCard(
                                hazards: locationListProvider
                                        .myLocationList[index].hazard ??
                                    {},
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
                                // "123",
                                address: locationListProvider
                                        .myLocationList[index]
                                        .geocodedAddress ??
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
                                        .myLocationList[index]
                                        .overallScore ??
                                    0,

                                // locationListProvider
                                //         .myLocationList[index].overallScore ??
                                //     0,
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
                                              widget.accountID!,
                                              widget.subAccountID!,
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
                                        widget.initialProcessId,
                                        widget.initialSubProcessId,
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
                                      widget.accountID!,
                                      widget.subAccountID!,
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
                                          widget.accountID!,
                                          widget.subAccountID!,
                                          locationId);
                                },
                                lat: locationListProvider.myLocationList[index]
                                        .finalAddress?.latitude
                                        .toString() ??
                                    "",
                                long: locationListProvider.myLocationList[index]
                                        .finalAddress?.longitude
                                        .toString() ??
                                    "",
                                overallScore: locationListProvider
                                    .myLocationList[index]
                                    .overallScore ??
                                    5,

                                hazardProcess: locationListProvider
                                    .myLocationList[index].isHazardProcess,
                                getData: _getData,
                              );
                            },
                          ),
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
                                      Text(locationListProvider
                                          .hazardRatings[hazard]!.length
                                          .toString()),
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
                          child: Container(
                            padding: EdgeInsets.only(right: 20, left: 20),
                            child: Text(
                                "It looks like you haven't added any locations yet. Let's get started! You can add locations by importing an XLS file or by clicking on \"Create New.\"",
                                textAlign: TextAlign.justify,
                                style: typography.Body1),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () async {
                            locationListProvider.certifiedPage = 1;
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
                            locationListProvider.fetchAllLocationList(
                              context,
                              widget.accountID,
                              widget.subAccountID,
                              processId: widget.initialProcessId,
                              subProcessId: widget.initialSubProcessId,
                            );
                          },
                          child: ListView.builder(
                            physics: ClampingScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: locationListProvider
                                .certifiedLocationList.length,
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
            ),
          ],
        );
      },
    );
  }

  MyLocationCard myLocationCertifiedCard(
      MyLocationListProvider locationListProvider,
      int index,
      BuildContext context1) {
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
      lat: (locationListProvider.myLocationList.isNotEmpty &&
              index < locationListProvider.myLocationList.length)
          ? locationListProvider.myLocationList[index].finalAddress?.latitude
                  .toString() ??
              ""
          : "",
      // lat: locationListProvider.myLocationList[index].hazard[index].
      //     .toString() ??
      //     "",

      // lat: locationListProvider
      //     .myLocationList[index]
      //     .finalAddress
      //     ?.latitude.toString() ??
      //     "",
      long: (locationListProvider.myLocationList.isNotEmpty &&
              index < locationListProvider.myLocationList.length)
          ? locationListProvider.myLocationList[index].finalAddress?.longitude
                  ?.toString() ??
              ""
          : "",
      // long:   locationListProvider
      //   .myLocationList[index]
      //   .finalAddress
      //   ?.longitude.toString() ??
      //   "",
      overallScore:
      (locationListProvider.myLocationList.isNotEmpty &&
              index < locationListProvider.myLocationList.length)
          ? locationListProvider.myLocationList[index].overallScore
                  ?.toString() ??
              "0"
          : "0",
      // overallScore: locationListProvider
      //   .myLocationList[index].overallScore?.toString() ?? "0",
      subAccountName: widget.subAccountName,
      isCertified: true,
      locationId: locationListProvider.certifiedLocationList[index].id ?? '',
      accountName: locationListProvider
              .certifiedLocationList[index].finalAddress?.accountName ??
          '',
      ownerName: locationListProvider
              .certifiedLocationList[index].finalAddress?.ownerName ??
          '',
      address:
          locationListProvider.certifiedLocationList[index].geocodedAddress ??
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
                .deleteLocations(context, widget.accountID!,
                    widget.subAccountID!, "", [locationId]);

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
            widget.accountID!,
            widget.subAccountID!,
            widget.accountName,
            widget.subAccountName,
            _masterTabController,
            locationId);
      },
      onAddTag: (locationId) {
        // Show add tag dialog
        // Implement bulk add tag
        locationListProvider.addTagsToSelectedLocations(
            context, widget.accountID!, widget.subAccountID!, locationId);
      },
      // hazardProcess:
      //     (locationListProvider.myLocationList[index].isHazardProcess is bool)
      //         ? locationListProvider.myLocationList[index].isHazardProcess
      //         : false,
      hazardProcess: (locationListProvider.myLocationList.isNotEmpty && index < locationListProvider.myLocationList.length)
          ? (locationListProvider.myLocationList[index].isHazardProcess is bool
          ? locationListProvider.myLocationList[index].isHazardProcess
          : false)
          : false,

      // Provide a default boolean value // hazardProcess: locationListProvider.myLocationList[index].isHazardProcess ??"",
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
    final _formKey = GlobalKey<FormState>();
    //Navigator.pop(context);
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
        return Consumer<UserProfileProvider>(
            builder: (context, userProfileProvider, child) {
          final trialStatus = userProfileProvider.trialInfo['status'] ?? '';
          int locations = userProfileProvider.trialInfo['locations'] ?? 0;
          int total = userProfileProvider.trialInfo['maxLocations'] ?? 0;
          return StatefulBuilder(
            builder: (context, StateSetter setState) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        SizedBox(height: 40),
                        _uploadedFileName == null
                            ? GestureDetector(
                                onTap: locations < 0
                                    //&& trailStatus.isNotEmpty
                                    ? null
                                    : () async {
                                        FilePickerResult? result =
                                            await FilePicker.platform.pickFiles(
                                          type: FileType.custom,
                                          allowedExtensions: ['xls', 'xlsx'],
                                        );
                                        if (result != null) {
                                          File file =
                                              File(result.files.single.path!);
                                          setState(() {
                                            files = file;
                                            String fileNameWithExtension =
                                                file.path.split('/').last;
                                            _uploadedFileName =
                                                fileNameWithExtension
                                                    .split('.')
                                                    .first;
                                            _locationNameController.text =
                                                _uploadedFileName!;
                                            // _sovNameController.text =
                                            //     _uploadedFileName!;
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
                                          border:
                                              Border.all(color: Colors.grey),
                                          borderRadius:
                                              BorderRadius.circular(8),
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
                                              _locationNameController.text,
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
                        if (trialStatus.isNotEmpty)
                          Column(
                            children: [
                              MessageCard(
                                  isError: locations < 1,
                                  messageTextSpans: [
                                    TextSpan(
                                      text:
                                          '$locations of $total locations left to upload.',
                                    ),
                                    TextSpan(
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                "Coming Soon!",
                                                style:
                                                    typography.Body1.copyWith(
                                                  color: AppColors.primaryMain,
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      text: ' Upgrade Now!',
                                      style: TextStyle(
                                        color: AppColors.primaryMain,
                                      ),
                                    ),
                                  ]),
                              SizedBox(height: 16),
                              if (!(locations < 1))
                                Text(
                                  'The system will only process the first ${locations} locations.',
                                  style: typography.Body1,
                                ),
                              SizedBox(height: 16),
                            ],
                          ),
                        if (!addToSOVCheck) ...[
                          TextField(
                            controller: tagController,
                            // enabled: locations > 0,
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

                          SizedBox(height: 14),
                          TextFormField(
                            controller:
                                TextEditingController(text: widget.accountName),
                            style: TextStyle(color: Colors.white54),
                            enabled: false,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Please enter account name";
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              labelText: "Account Name",
                              labelStyle: TextStyle(color: Colors.white54),
                              enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.grey)),
                              disabledBorder: OutlineInputBorder(
                                  borderSide:
                                      BorderSide(color: Colors.white54)),
                              focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.blue)),
                              hintStyle: TextStyle(color: Colors.white54),
                            ),
                          ),
                          SizedBox(height: 14),
                          TextField(
                            enabled: false,
                            readOnly: false,
                            controller: TextEditingController(
                                text: widget.subAccountName),
                            style: TextStyle(color: Colors.white54),
                            decoration: InputDecoration(
                              labelText: "Sub-account Name",
                              labelStyle: TextStyle(color: Colors.white54),
                              enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.grey)),
                              disabledBorder: OutlineInputBorder(
                                  borderSide:
                                      BorderSide(color: Colors.white54)),
                              focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.blue)),
                              hintStyle: TextStyle(color: Colors.white54),
                            ),
                          ),
                          SizedBox(height: 14),
                          TextFormField(
                            controller: _sovNameController,
                            validator: (value) {
                              if (addToSOVCheck) {
                                if (value == null || value.isEmpty) {
                                  return 'Only alphanumeric characters, "_", "-", and "/" are allowed.';
                                }
                              }
                              return null;
                            },
                            style: TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: "Name of the SoV",
                              labelStyle: TextStyle(color: Colors.white),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: Colors.grey), // Normal border
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: Colors.blue), // Border when focused
                              ),
                              errorBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: Colors.red,
                                    width: 2.0), // Border on error
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: Colors.red,
                                    width: 2.5), // Focused border on error
                              ),
                              hintStyle: TextStyle(color: Colors.white54),
                            ),
                          ),

                          // TextFormField(
                          //   // readOnly: true,
                          //   controller: _sovNameController,
                          //   // enabled: locations > 0,
                          //   //   readOnly: _uploadedFileName != null,
                          //   validator: (value) {
                          //     if (addToSOVCheck) {
                          //       if (value == null || value.isEmpty) {
                          //         return "Account Name is required"; // Add your validation message
                          //       }
                          //     }
                          //     return null;
                          //   },
                          //   style: TextStyle(color: Colors.white),
                          //   decoration: InputDecoration(
                          //     labelText: "Name of the SoV",
                          //     labelStyle: TextStyle(color: Colors.white),
                          //     enabledBorder: OutlineInputBorder(
                          //         borderSide: BorderSide(color: Colors.grey)),
                          //     focusedBorder: OutlineInputBorder(
                          //         borderSide: BorderSide(color: Colors.blue)),
                          //     hintStyle: TextStyle(color: Colors.white54),
                          //   ),
                          // ),
                          SizedBox(height: 14),
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
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 0.0),
                          child: Row(
                            children: [
                              Checkbox(
                                value: addToSOVCheck,
                                onChanged: trialStatus.isNotEmpty
                                    ? null
                                    : (bool? value) {
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
                              if (trialStatus.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(left: 16.0),
                                  child: InkWell(
                                    onTap: () {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            "Coming Soon!",
                                            style: typography.Body1.copyWith(
                                              color: AppColors.primaryMain,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      "Upgrade Now to create SOV!",
                                      style: typography.Body1.copyWith(
                                        color: AppColors.primaryMain,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Column(
                            children: [
                              Consumer<MyLocationListProvider>(
                                builder: (_, locationListProvider, child) {
                                  return locationListProvider
                                          .isImageUploadLoading
                                      ? Center(
                                          child: CircularProgressIndicator())
                                      : Row(
                                          children: [
                                            Expanded(
                                                child: CustomButton(
                                                    type: ButtonType.elevated,
                                                    onPressed: (locations < 0)
                                                        ? null
                                                        : () async {
                                                            // Upload the file
                                                            // return if file is null

                                                            if (_formKey
                                                                .currentState!
                                                                .validate()) {
                                                              if (files ==
                                                                      null ||
                                                                  files!.path
                                                                      .isEmpty) {
                                                                ScaffoldMessenger.of(
                                                                        context)
                                                                    .showSnackBar(
                                                                  SnackBar(
                                                                      content: Text(
                                                                          "Please select a file to upload")),
                                                                );
                                                                return;
                                                              }
                                                              if (_formKey
                                                                  .currentState!
                                                                  .validate()) {
                                                                // return if file is not xlsx
                                                                if (!files!.path
                                                                    .endsWith(
                                                                        '.xlsx')) {
                                                                  ScaffoldMessenger.of(
                                                                          context)
                                                                      .showSnackBar(SnackBar(
                                                                          content:
                                                                              Text("Please select a valid file to upload")));
                                                                  return;
                                                                }
                                                                String success = await locationListProvider.uploadSov(
                                                                    context,
                                                                    files!,
                                                                    accountId,
                                                                    subAccountId,
                                                                    sovId,
                                                                    tagController
                                                                        .text,
                                                                    _sovNameController
                                                                        .text);
                                                                _sovNameController
                                                                    .clear();
                                                                Navigator.pop(
                                                                    context);

                                                                print(
                                                                    'Success: $success');
                                                                // contain symbol +
                                                                if (success
                                                                        .isNotEmpty &&
                                                                    success.contains(
                                                                        '+')) {
                                                                  print(
                                                                      'Inside + success: $success');
                                                                  // Show popup with title Empty SoV, body: Looks Like, Data has not been specified!! Do you want to continue creating an empty SOV, or abort? with 2 buttons: [create empty SOV]   [abort]
                                                                  showDialog(
                                                                      context:
                                                                          context,
                                                                      builder:
                                                                          (BuildContext
                                                                              context) {
                                                                        return AlertDialog(
                                                                          title:
                                                                              Text(
                                                                            /*LanguageService.getTranslated(
                                                              context,
                                                              "account_list_app_empty_sov_title")*/
                                                                            'Empty SOV',
                                                                            style:
                                                                                typography.H5_Regular,
                                                                          ),
                                                                          content:
                                                                              Column(
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
                                                                                height: CustomSpacing.two,
                                                                              ),
                                                                              Column(
                                                                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                                                                children: [
                                                                                  Consumer<UploadSovProvider>(builder: (context, uploadSovProvider, child) {
                                                                                    return uploadSovProvider.isLoading
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
                                                                                    onPressed: () {
                                                                                      Navigator.pop(context);
                                                                                    },
                                                                                    child: Text(
                                                                                      /*LanguageService.getTranslated(
                                                                        context,
                                                                        "account_list_app_empty_sov_abort")*/
                                                                                      'Abort',
                                                                                      style: typography.ButtonLarge,
                                                                                    ),
                                                                                    type: ButtonType.text,
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
                                                                          builder: (_) => MappingScreen(
                                                                                tempId: success,
                                                                                accountId: widget.accountID!,
                                                                                accountName: widget.accountName ?? "",
                                                                                subAccountId: widget.subAccountID!,
                                                                              )));
                                                                }
                                                              }
                                                            }
                                                          },
                                                    child: Text("Upload",
                                                        style: typography
                                                                .ButtonLarge
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
                ),
              );
            },
          );
        });
      },
    );
  }

  void sovSearchClient(String query) async {
    debounce(() async {
      if (!mounted) return;
      _sovQuery = query;
      var provider = Provider.of<SOVListProvider>(context, listen: false);
      provider.page = 0;
      await provider.fetchSovList(context, widget.accountID!,
          widget.subAccountID!, _sovQuery, provider.page, 10);
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
                          "Looks like you don't have a sov yet. No worries! Just create a new one and start adding your locations.",
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
                                widget.accountID!,
                                widget.subAccountID!,
                                _sovQuery,
                                sovListProvider.page,
                                10, // Page size
                              );
                              return SizedBox();
                            }
                          } else {
                            return _buildSovCard(index, sovListProvider);
                          }
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
                    accountID: widget.accountID!,
                    subAccountID: widget.subAccountID!,
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
                                          sOVListProvider.sovList[index].name
                                              .toString(),
                                          // (sOVListProvider.sovList[index]
                                          //                 .name ??
                                          //             "")
                                          //         .isNotEmpty
                                          //     ? sOVListProvider
                                          //             .sovList[index].name!
                                          //             .substring(0, 1)
                                          //             .toUpperCase() +
                                          //         sOVListProvider
                                          //             .sovList[index].name!
                                          //             .substring(1)
                                          //     : "",
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
                                                                                widget.accountID!,
                                                                                widget.subAccountID!,
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
                            true
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
                                                                    .accountID!,
                                                                widget
                                                                    .subAccountID!,
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
                          hintStyle: typography.Body1,
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
                                          child:
                                              Text(user.name[0].toUpperCase()),
                                        ),
                                  title: Text(user.name),
                                  subtitle: Text(user.email),
                                  onTap: () {
                                    setState(() {
                                      _selectedUser = user;
                                      _userSearchController.text = user.name;
                                    });
                                  },
                                );
                              },
                            )
                          : Padding(
                              padding: EdgeInsets.all(16),
                              child:
                                  Text('Selected User: ${_selectedUser!.name}'),
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: Text(
                              'Cancel',
                              style: CustomTypography(context).Body1,
                            ),
                          ),
                          CustomButton(
                            type: ButtonType.elevated,
                            onPressed: _selectedUser != null &&
                                    !_isTransferLoading
                                ? () async {
                                    setState(() {
                                      _isTransferLoading = true;
                                    });
                                    var provider = Provider.of<SOVListProvider>(
                                        context,
                                        listen: false);
                                    await provider
                                        .transferSOV(
                                            context,
                                            widget.accountID!,
                                            widget.subAccountID,
                                            sov.id,
                                            _selectedUser!.id)
                                        .then((value) {
                                      if (value) {
                                        _getData();
                                      }
                                    });
                                    setState(() {
                                      _isTransferLoading = false;
                                    });

                                    Navigator.pop(dialogContext);
                                  }
                                : null,
                            child: _isTransferLoading
                                ? CircularProgressIndicator(strokeWidth: 2.0)
                                : Text(
                                    'Transfer',
                                    style: CustomTypography(context).Body1,
                                  ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 10),
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
      ApiService apiService =
          ApiService(AppConstant.TRANSFER_USER_AUTOCOMPLETE);
      String url = '?search=$query';
      var response = await apiService.get(url);

      // Parse the response to extract user data
      List<TransferAutocompleteModel> users = (response['result'] as List)
          .map((user) => TransferAutocompleteModel.fromJson(user))
          .toList();

      return users;
    } catch (e) {
      print(e.toString());
      return [];
    }
  }
}
