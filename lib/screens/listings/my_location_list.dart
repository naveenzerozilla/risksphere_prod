import 'package:RiskSphere/screens/listings/widgets/location_list_map_view.dart';

import '../../utils/global_imports.dart';
import '../../models/sov_list_model.dart';
import 'package:RiskSphere/models/role_model.dart' as roleModel;
import 'package:http/http.dart' as http;
import '../payments/purchase_license.dart';

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
    this.subAccountName = '',
    this.initialProcessId,
    this.initialSubProcessId,
  });

  @override
  State<MyLocationList> createState() => _MyLocationListState();
}

class _MyLocationListState extends State<MyLocationList>
    with TickerProviderStateMixin {
  Timer? _refreshTimer;
  static bool _hasActiveTimer = false;
  bool _isExpanded = false;
  bool _showNotificationDot = true;
  TabController? _masterTabController;
  late TabController _tabController;
  String selectedProcessId = "";

  String isMaintenance = "";
  Screens _selectedScreen = Screens.locationList;
  TextEditingController _locationSearchController = TextEditingController();
  TextEditingController mobileController = TextEditingController();

  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int requestActionIndex = 0;
  bool _isLoading = false;
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
  bool isAllSelected = false;
  bool _isHazardLoading = false;
  bool isPgAdmin = false;
  bool isAdmin = false;
  bool isSuperAdmin = false;
  bool isIndivudual = false;

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
  bool showNonCorporateManagementTab = true;
  bool showCorporateManagementTab = true;
  bool showEmployeeManagementTab = true;
  bool showCorporateList = true;
  bool showCorporateUserListDropdown = true;
  bool showCorporateVerificationTab = true;
  bool showCorporateProfile = true;
  bool addToSOVCheck = false;
  bool isLoading = false;
  var conflictLocations;
  bool hasAnyPlan = false;
  String? hasLicenseStatus = "1";
  String? hasGeocodingStatus = "1";
  String? hasHazardLicenseStatus = "1";
  List<TargetFocus> targets = [];
  GlobalKey keyFeature1 = GlobalKey();
  GlobalKey keyFeature2 = GlobalKey();
  GlobalKey keyFeature3 = GlobalKey();
  GlobalKey keyFeature4 = GlobalKey();

  String selectedSovId = "";
  TextEditingController sovController = TextEditingController();
  TextEditingController tagController = TextEditingController();

  bool isUploadInProgress = false;

  void debounce(VoidCallback callback,
      {Duration duration = const Duration(seconds: 1)}) {
    if (deBouncer != null) {
      deBouncer!.cancel();
    }
    deBouncer = Timer(duration, callback);
  }

  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);

    _mainTabController = TabController(length: 3, vsync: this);
    _mainTabController?.addListener(() {
      setState(() {
        selectedMainTab = _mainTabController?.index ?? 0;
      });
    });

    var userProfileProvider =
        Provider.of<UserProfileProvider>(context, listen: false);

    final trialStatus = userProfileProvider.trialInfo['status'] ?? '';
    int tabCount = trialStatus.isEmpty ? 6 : 5;
    _masterTabController = TabController(length: tabCount, vsync: this);
    _masterTabController?.addListener(() {
      setState(() {
        selectedMasterTab = _masterTabController?.index ?? 0;
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData(); // Load all data after first render
    });
    _tryShowTutorialOnce();
  }

  void _initializeData() {
    _setClaims();
    _getData();
    _startRefreshTimer();
    _getSovUploadStatus();
    // _getMaintainancePeriod();

    // final locationListProvider =
    //     Provider.of<MyLocationListProvider>(context, listen: false);
    // locationListProvider.clearAllFilters();
    // locationListProvider.page = 1;
    //
    // Provider.of<LocationListProvider>(context, listen: false)
    //     .fetchLocationSummary(
    //   widget.accountID!,
    //   widget.subAccountID!,
    //   "widget.sovId!",
    // );
    // _fetchTabData(0); // Load default tab data
  }

  void _tryShowTutorialOnce() async {
    final prefs = await SharedPreferences.getInstance();
    bool isFirstTime = prefs.getBool('myLocation') ?? true;

    if (!isFirstTime) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(Duration(milliseconds: 500));
      await WidgetsBinding.instance.endOfFrame;

      initTargets();

      if (targets.isNotEmpty) {
        await Future.delayed(Duration(milliseconds: 300));
        if (mounted) {
          showTutorial();
          await prefs.setBool('myLocation', false);
        }
      } else {
        print('No targets were set. Skipping tutorial.');
      }
    });
  }

  void showTutorial() {
    TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.transparent,
      opacityShadow: 0.9,
      paddingFocus: 5,
      textSkip: "Skip",
      textStyleSkip: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      onFinish: () {
        print("Tutorial Finished");
      },
      onClickTarget: (target) {
        print("Clicked on target: ${target.identify}");
      },
    ).show(context: context);
  }

  void initTargets() {
    targets.addAll([
      TargetFocus(
        identify: "Location list",
        keyTarget: keyFeature1,
        alignSkip: Alignment.topRight,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Container(
              margin: EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.fromLTRB(10.0, 60, 10, 10),
              child: Text(
                "View all your added property locations in one place. Get a quick overview of geocoding accuracy, hazard risk score, data completeness, & more. ",
                maxLines: 3,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),
            ),
          )
        ],
      ),
      TargetFocus(
        identify: "Overall Score Table",
        keyTarget: keyFeature2,
        alignSkip: Alignment.topRight,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Container(
              margin: EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.fromLTRB(10.0, 10, 10, 30),
              child: Text(
                "View the hazard risk score for each property from 1 to 5. 1 means highest risk, 5 means lowest risk to the property. ",
                maxLines: 3,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),
            ),
          )
        ],
      ),
      TargetFocus(
        identify: "Map View",
        keyTarget: keyFeature3,
        alignSkip: Alignment.topRight,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Container(
              margin: EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.fromLTRB(10.0, 10, 10, 40),
              child: Text(
                "See property locations and nearby hazards like fire, cyclone, earthquake & more at a glance. Get the full context for better risk evaluation. ",
                maxLines: 3,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),
            ),
          )
        ],
      ),
      TargetFocus(
        identify: "Add location, Import locations adn export locations",
        keyTarget: keyFeature4,
        alignSkip: Alignment.topRight,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Container(
              margin: EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.fromLTRB(10.0, 50, 10, 60),
              child: Text(
                "You can add new locations, import locations from a file, or export the current list of locations. Use the buttons below to perform these actions.",
                maxLines: 3,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),
            ),
          )
        ],
      ),
    ]);
  }

  void _onTabChanged() {
    // setState(() {
    //   selectedTab = _tabController?.index ?? 0;
    // });

    final locationListProvider =
        Provider.of<MyLocationListProvider>(context, listen: false);
    locationListProvider.page = 1;

    if (_tabController?.index == 0) {
      _selectedScreen = Screens.locationList;
      locationListProvider.fetchLocationList(
        context,
        "",
        1,
        10000,
        widget.accountID,
        widget.subAccountID,
        widget.initialProcessId,
        widget.initialSubProcessId,
      );
    } else {
      _selectedScreen = Screens.certifiedLocationList;
      locationListProvider.clearRatingsFilter();
      locationListProvider.fetchCertifiedLocationList(
        context,
        "",
        1,
        10000,
        widget.accountID,
        widget.subAccountID,
        widget.initialProcessId,
        widget.initialSubProcessId,
      );
    }
  }

  Future<void> _setClaims() async {
    final results = await Future.wait([
      SharedPreferenceService.getClaimForSubfeature(
          SharedPreferenceService.DASTC),
      SharedPreferenceService.getClaimForSubfeature(
          SharedPreferenceService.DASTU),
      SharedPreferenceService.getClaimForSubfeature(
          SharedPreferenceService.DASCR),
      SharedPreferenceService.getClaimForSubfeature(
          SharedPreferenceService.DASCO),
      SharedPreferenceService.getClaimForSubfeature(
          SharedPreferenceService.DASUO),
      SharedPreferenceService.getClaimForSubfeature(
          SharedPreferenceService.CAMLL),
      SharedPreferenceService.getClaimForSubfeature(
          SharedPreferenceService.CAMVU),
      SharedPreferenceService.getClaimForSubfeature(
          SharedPreferenceService.DASVR),
    ]);

    print(results.toString());

    print("results.toString()");

    bool showCorporateVerificationRequests = results[5] ?? false;
    bool showUserVerificationRequests = results[6] ?? false;

    _getData1();
    _getMaintainancePeriod();
    setState(() {});
  }

  Future<void> _getData1() async {
    final dashboardProvider =
        Provider.of<DashboardProvider>(context, listen: false);
    final userProfileProvider =
        Provider.of<UserProfileProvider>(context, listen: false);
    final configurationProvider =
        Provider.of<ConfigurationProvider>(context, listen: false);

    try {
      final results = await Future.wait([
        dashboardProvider.getDashboardData(context),
        userProfileProvider.getAllUserData(context, "", ""),
        configurationProvider.getConfiguration(
            accountId: null, subAccountId: null),
        configurationProvider.getVendors(),
      ]);

      userProfileProvider.fetchTrialInfo();

      var config = configurationProvider.configurations['result'] ?? {};
      // subscriptions = config['subscribe'] ?? {};

      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            // vendorList = configurationProvider.vendors['result'] ?? [];
          });
        });
      }
    } catch (error) {
      // print("Error fetching data: $error");
    }
  }

  Future<void> _getMaintainancePeriod() async {
    isMaintenance =
        await SharedPreferenceService.getScheduleInProgress() ?? "false";
  }

  bool _isDisposed = false;
  MyLocationListProvider? _myLocationProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _myLocationProvider ??=
        Provider.of<MyLocationListProvider>(context, listen: false);
  }

  @override
  void dispose() {
    _mainTabController?.dispose();
    _masterTabController?.dispose();
    _tabController?.dispose();
    _refreshTimer?.cancel();
    _hasActiveTimer = false;
    _isDisposed = true;

    deBouncer?.cancel();

    // Safely use the cached reference
    _myLocationProvider?.clearAllFilters();
    _myLocationProvider?.clearSelection();
    _myLocationProvider?.clearRatingsFilter();
    _myLocationProvider?.myLocationList.clear();
    _myLocationProvider?.certifiedLocationList.clear();
    _myLocationProvider?.selectedLocations.clear();
    _myLocationProvider?.summaryList.clear();

    super.dispose();
  }

  // @override
  // void dispose() {
  //   _mainTabController?.dispose();
  //   _masterTabController?.dispose();
  //   _tabController?.dispose();
  //   // _refreshTimer?.cancel();
  //   _isDisposed = true;
  //   _refreshTimer?.cancel();
  //   _hasActiveTimer = false;
  //   super.dispose();
  //   deBouncer?.cancel();
  //
  //   final myLocationProvider =
  //       Provider.of<MyLocationListProvider>(context, listen: false);
  //   myLocationProvider.clearAllFilters();
  //   myLocationProvider.clearSelection();
  //   myLocationProvider.clearRatingsFilter();
  //   myLocationProvider.myLocationList.clear();
  //   myLocationProvider.certifiedLocationList.clear();
  //   myLocationProvider.selectedLocations.clear();
  //   myLocationProvider.summaryList.clear();
  //
  //   super.dispose();
  // }

  // void _startRefreshTimer() {
  //   // Cancel any existing timer before starting a new one
  //
  //   _refreshTimer = Timer.periodic(const Duration(seconds: 20), (timer) {
  //     if (!mounted) {
  //       timer.cancel();
  //       return;
  //     }
  //
  //     var provider = Provider.of<JobMonitoringProvider>(context, listen: false);
  //
  //     if (provider.isProcessing) {
  //       _refreshData(); // Call refresh function only if processing is ongoing
  //     } else {
  //       timer.cancel(); // Stop the timer if processing is not happening
  //     }
  //   });
  // }
  void _startRefreshTimer() {
    if (_refreshTimer != null && _refreshTimer!.isActive) return;
    if (_hasActiveTimer) return;

    _hasActiveTimer = true;

    // 👇 Immediately refresh once when timer starts
    final provider = Provider.of<JobMonitoringProvider>(context, listen: false);
    if (mounted && provider.isProcessing) {
      _refreshData();
    }

    // 👇 Then schedule periodic refresh
    _refreshTimer = Timer.periodic(const Duration(seconds: 20), (timer) {
      final provider =
          Provider.of<JobMonitoringProvider>(context, listen: false);
      if (mounted && provider.isProcessing) {
        setState(() {
          isUploadInProgress = false;
        });
        _refreshData();
      } else {
        _refreshTimer?.cancel();
        _hasActiveTimer = false;
      }
    });
  }

  Future<void> _refreshData() async {
    if (!mounted) return; // Ensure the widget is still in the tree

    final locationListProvider =
        Provider.of<MyLocationListProvider>(context, listen: false);

    locationListProvider.certifiedPage = 1;

    await locationListProvider.fetchCertifiedLocationList(
      context,
      "",
      locationListProvider.certifiedPage,
      20,
      widget.accountID,
      widget.subAccountID,
      widget.initialProcessId,
      widget.initialSubProcessId,
    );

    await locationListProvider.fetchLocationList(
      context,
      "",
      1,
      10000,
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

  Future<void> _getData() async {
    isPgAdmin = await SharedPreferenceService.getClaimForSubfeature(
            SharedPreferenceService.IS_PG_ADMIN) ??
        false;
    isSuperAdmin = await SharedPreferenceService.getClaimForSubfeature(
            SharedPreferenceService.IS_SUPER_ADMIN) ??
        false;
    bool? hasAnyPlans = await SharedPreferenceService.getHasAnyPlan();
    String? geoCodingStatus =
        await SharedPreferenceService.getGeocodingLicense();
    String? userLicenseStatus = await SharedPreferenceService.getUserLicense();
    String? hazardLicenseStatus =
        await SharedPreferenceService.getHazardLicense();
    setState(() {
      isPgAdmin = isPgAdmin;
      isSuperAdmin = isSuperAdmin;
      hasAnyPlan = hasAnyPlans ?? false;
      hasLicenseStatus = userLicenseStatus ?? "1";
      hasGeocodingStatus = geoCodingStatus ?? "1";
      hasHazardLicenseStatus = hazardLicenseStatus ?? "1";
    });
    final myLocationProvider =
        Provider.of<MyLocationListProvider>(context, listen: false);
    final sovListProvider =
        Provider.of<SOVListProvider>(context, listen: false);
    final jobMonitoringProvider =
        Provider.of<JobMonitoringProvider>(context, listen: false);

    await Future.wait([
      myLocationProvider
          .fetchLocationList(
            context,
            "",
            1,
            10000,
            widget.accountID,
            widget.subAccountID,
            widget.initialProcessId,
            widget.initialSubProcessId,
          )
          .then(
              (_) => setState(() {})), // Update UI after fetching location list

      myLocationProvider.fetchCertifiedLocationList(
        context,
        "",
        1,
        1000,
        widget.accountID,
        widget.subAccountID,
        widget.initialProcessId,
        widget.initialSubProcessId,
      ),
      // .then((_) => WidgetsBinding.instance!.addPostFrameCallback(
      //     (_) => setState(() {}))), // Update UI after frame rendering

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

  Future<void> _getSovUploadStatus() async {
    // _getSovUploadStatus() async {
    String? tempProcessId = await SharedPreferenceService.getSovUploadTempId();
    String? accountId = await SharedPreferenceService.getSovAccountId();

    String? subAccountId =
        await SharedPreferenceService.getSovSubAccountId() ?? "";

    if (tempProcessId == null || accountId == null) {
      print("Error: Missing values from Shared Preferences.");
      return;
    }

    setState(() {
      isUploadInProgress = false;
      // tempProcessId.isNotEmpty &&
      // widget.accountID == accountId &&
      // widget.subAccountID == subAccountId;
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
                  hasAnyPlan: hasAnyPlan,
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
                floatingActionButton: Builder(builder: (context) {
                  return Container(
                    key: keyFeature4,
                    margin: EdgeInsets.only(bottom: 42.0),
                    child: SpeedDial(
                      animatedIcon: AnimatedIcons.menu_close,
                      animatedIconTheme: IconThemeData(size: 22.0),
                      backgroundColor: AppColors.primaryMain,
                      foregroundColor:
                          themeProvider.getTheme.colorScheme.onPrimary,
                      children: [
                        if ((selectedMasterTab) == 0)
                          // Add this to your state

                          SpeedDialChild(
                              child: _isLoading
                                  ? SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          themeProvider
                                              .getTheme.colorScheme.onPrimary,
                                        ),
                                      ),
                                    )
                                  : Icon(Icons.add),
                              backgroundColor: AppColors.primaryMain,
                              foregroundColor:
                                  themeProvider.getTheme.colorScheme.onPrimary,
                              label: 'Add Location',
                              labelStyle: typography.Body1,
                              onTap: () async {
                                setState(() {
                                  _isLoading = true;
                                });

                                await _setClaims();
                                await Future.delayed(Duration(seconds: 1));

                                // Cancel timers and debounce before navigating
                                _isDisposed = true;
                                _refreshTimer?.isActive;
                                deBouncer?.cancel();

                                final result = await Navigator.of(context)
                                    .push(MaterialPageRoute(
                                        builder: (_) => AddLocationScreen(
                                              accountId: widget.accountID!,
                                              subAccountId:
                                                  widget.subAccountID!,
                                              sovId: "",
                                              accountName: widget.accountName,
                                              subAccountName:
                                                  widget.subAccountName,
                                            )));

                                _isDisposed = false;
                                _startRefreshTimer(); // recreate timer
                                // deBouncer = Debouncer(milliseconds: 500);// ✅ Re-create debounce instance
                                _getSovUploadStatus();
                                setState(() => _isLoading = false);

                                if (result == true) {
                                  await _getData();
                                  _startRefreshTimer();
                                  await Provider.of<MyLocationListProvider>(
                                          context,
                                          listen: false)
                                      .fetchLocationList(
                                    context,
                                    "",
                                    1,
                                    10000,
                                    widget.accountID,
                                    widget.subAccountID,
                                    widget.initialProcessId,
                                    widget.initialSubProcessId,
                                  );
                                  setState(() {});
                                }
                              }

                              // onTap: () async {
                              //   setState(() {
                              //     _isLoading = true;
                              //   });
                              //   // setState(() => _isLoading = true);
                              //
                              //   await _setClaims(); // Step 1
                              //   // deBouncer!.cancel();
                              //
                              //
                              //   await Future.delayed(
                              //       Duration(seconds: 1)); // Step 2
                              //   _isDisposed = true;
                              //   _refreshTimer?.cancel();
                              //   deBouncer?.cancel();
                              //   final result = await Navigator.of(context).push(
                              //     MaterialPageRoute(
                              //       builder: (_) =>
                              //           StaticDropdownExample(),
                              //       //     AddLocationScreen(
                              //       //   accountId: widget.accountID!,
                              //       //   subAccountId: widget.subAccountID!,
                              //       //   sovId: "",
                              //       //   accountName: widget.accountName,
                              //       //   subAccountName: widget.subAccountName,
                              //       // ),
                              //     ),
                              //   );
                              //
                              //   setState(
                              //       () => _isLoading = false); // Reset loading
                              //
                              //   if (result == true) {
                              //     await _getData();
                              //     await Provider.of<MyLocationListProvider>(
                              //             context,
                              //             listen: false)
                              //         .fetchLocationList(
                              //       context,
                              //       "",
                              //       1,
                              //       40,
                              //       widget.accountID,
                              //       widget.subAccountID,
                              //       widget.initialProcessId,
                              //       widget.initialSubProcessId,
                              //     );
                              //     setState(() {});
                              //   }
                              // },
                              ),

                        // SpeedDialChild(
                        //   child: Icon(Icons.add),
                        //   backgroundColor: AppColors.primaryMain,
                        //   foregroundColor: themeProvider.getTheme.colorScheme.onPrimary,
                        //   label: 'Add Location',
                        //   labelStyle: typography.Body1,
                        //     onTap: () async {
                        //       await _setClaims(); // Step 1: Run your setup method
                        //
                        //       // Step 2: Wait for 2 seconds before showing the loader
                        //       await Future.delayed(Duration(seconds: 1));
                        //
                        //       // Step 3: Show loader
                        //       showDialog(
                        //         context: context,
                        //         barrierDismissible: false,
                        //         builder: (_) => Center(
                        //           child: CircularProgressIndicator(),
                        //         ),
                        //       );
                        //
                        //       // Step 4: Navigate to AddLocationScreen
                        //       final result = await Navigator.of(context).push(
                        //         MaterialPageRoute(
                        //           builder: (_) => AddLocationScreen(
                        //             accountId: widget.accountID!,
                        //             subAccountId: widget.subAccountID!,
                        //             sovId: "",
                        //             accountName: widget.accountName,
                        //             subAccountName: widget.subAccountName,
                        //           ),
                        //         ),
                        //       );
                        //
                        //       // Step 5: Dismiss loader
                        //       Navigator.of(context, rootNavigator: true).pop();
                        //
                        //       if (result == true) {
                        //         await _getData();
                        //         await Provider.of<MyLocationListProvider>(context, listen: false).fetchLocationList(
                        //           context,
                        //           "",
                        //           1,
                        //           40,
                        //           widget.accountID,
                        //           widget.subAccountID,
                        //           widget.initialProcessId,
                        //           widget.initialSubProcessId,
                        //         );
                        //         setState(() {});
                        //       }
                        //     }
                        //
                        //   // onTap: () {
                        //     //   _setClaims().then((_) async {
                        //     //     final result = await Navigator.of(context).push(
                        //     //       MaterialPageRoute(
                        //     //         builder: (_) => AddLocationScreen(
                        //     //           accountId: widget.accountID!,
                        //     //           subAccountId: widget.subAccountID!,
                        //     //           sovId: "",
                        //     //           accountName: widget.accountName,
                        //     //           subAccountName: widget.subAccountName,
                        //     //         ),
                        //     //       ),
                        //     //     );
                        //     //
                        //     //     if (result == true) {
                        //     //       await _getData();
                        //     //       await Provider.of<MyLocationListProvider>(context, listen: false)
                        //     //           .fetchLocationList(
                        //     //         context,
                        //     //         "",
                        //     //         1,
                        //     //         40,
                        //     //         widget.accountID,
                        //     //         widget.subAccountID,
                        //     //         widget.initialProcessId,
                        //     //         widget.initialSubProcessId,
                        //     //       );
                        //     //       setState(() {});
                        //     //     }
                        //     //   });
                        //     // }
                        //
                        // ),
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
                                        'SOV upload is disabled during maintenance period.')),
                              );
                            } else if (isUploadInProgress) {
                              print("TestA");
                              print(isUploadInProgress);
                              String tempProcessId =
                                  await SharedPreferenceService
                                          .getSovUploadTempId() ??
                                      "";
                              String state = await SharedPreferenceService
                                      .getSovUploadState() ??
                                  "";

                              // Fetch API data when tapped
                              await Provider.of<UploadSovProvider>(context,
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
                                : () async {
                                    await _getData(); // API call only when tapped
                                    setState(() {});

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
                  );
                }),
                body: Stack(
                  children: [
                    /*  Positioned.fill(
                        child: Image.asset(
                          'assets/images/mesh.png',
                          fit: BoxFit.cover,
                        ),
                      ),*/
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: CustomSpacing.one),
                              Row(
                                children: [
                                  // 70% Width Side - Breadcrumbs (with scroll if overflow)
                                  Expanded(
                                    flex: 8,
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: [
                                          SizedBox(width: 10),
                                          InkWell(
                                            onTap: () {
                                              Navigator.pushAndRemoveUntil(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      AccountListScreen(),
                                                ),
                                                (route) => false,
                                              );
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
                                                        widget.accountName ??
                                                            "",
                                                  ),
                                                ),
                                                (route) => false,
                                              );
                                            },
                                            child: Text(widget.subAccountName,
                                                style: typography.InputLabel),
                                          ),
                                          Text(' > ',
                                              style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.white70)),
                                          Text(
                                            _masterTabController!.index == 0
                                                ? "Location list"
                                                : _masterTabController!.index ==
                                                        1
                                                    ? "Sovs"
                                                    : _masterTabController!
                                                                .index ==
                                                            2
                                                        ? "Shared"
                                                        : "Configure",
                                            style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.white),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Consumer<JobMonitoringProvider>(
                                        builder: (context,
                                            jobMonitoringProvider, child) {
                                          return _getLiveUI(
                                              jobMonitoringProvider);
                                        },
                                      ),
                                      Consumer<MyLocationListProvider>(
                                        builder: (context,
                                            myLocationListProvider, child) {
                                          if (myLocationListProvider
                                              .myLocationList.isNotEmpty) {
                                            return IconButton(
                                              icon: isLoading
                                                  ? SizedBox(
                                                      height: 30,
                                                      width: 30,
                                                      child:
                                                          CircularProgressIndicator(
                                                              strokeWidth: 2),
                                                    )
                                                  : SvgPicture.asset(
                                                      'assets/images/contract.svg'),
                                              onPressed: isLoading
                                                  ? null
                                                  : () async {
                                                      setState(() =>
                                                          isLoading = true);
                                                      var provider = Provider
                                                          .of<JobMonitoringProvider>(
                                                              context,
                                                              listen: false);
                                                      try {
                                                        Map<String, dynamic>?
                                                            summaryData =
                                                            await provider.fetchLocationSummary(
                                                                widget
                                                                    .accountID!,
                                                                widget
                                                                    .subAccountID!);

                                                        if (summaryData !=
                                                            null) {
                                                          showDialog(
                                                            context: context,
                                                            builder: (context) {
                                                              return Dialog(
                                                                shape:
                                                                    RoundedRectangleBorder(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              16),
                                                                ),
                                                                child:
                                                                    Container(
                                                                  width: MediaQuery.of(
                                                                              context)
                                                                          .size
                                                                          .width *
                                                                      0.8,
                                                                  child: _buildProcessSummary(
                                                                      summaryData),
                                                                ),
                                                              );
                                                            },
                                                          );
                                                        } else {
                                                          ScaffoldMessenger.of(
                                                                  context)
                                                              .showSnackBar(
                                                            SnackBar(
                                                              content: Text(
                                                                'Failed to fetch summary',
                                                                style: Theme.of(
                                                                        context)
                                                                    .textTheme
                                                                    .bodyMedium
                                                                    ?.copyWith(
                                                                        color: Colors
                                                                            .white),
                                                              ),
                                                              backgroundColor:
                                                                  Colors.red,
                                                            ),
                                                          );
                                                        }
                                                      } catch (e) {
                                                        ScaffoldMessenger.of(
                                                                context)
                                                            .showSnackBar(
                                                          SnackBar(
                                                            content: Text(
                                                              'Error: $e',
                                                              style: Theme.of(
                                                                      context)
                                                                  .textTheme
                                                                  .bodyMedium
                                                                  ?.copyWith(
                                                                      color: Colors
                                                                          .white),
                                                            ),
                                                            backgroundColor:
                                                                Colors.red,
                                                          ),
                                                        );
                                                      } finally {
                                                        setState(() =>
                                                            isLoading = false);
                                                      }
                                                    },
                                            );
                                          } else {
                                            return SizedBox.shrink();
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              SizedBox(height: CustomSpacing.one),
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
                                                      Colors.white,
                                                  tabs: [
                                                    Tab(
                                                      text: 'Locations',
                                                    ),
                                                    Tab(
                                                      text: 'SOVs',
                                                    ),
                                                    Tab(text: 'Shared'),
                                                    if (isSuperAdmin ||
                                                        isPgAdmin)
                                                      Tab(
                                                          text:
                                                              'Configuration'),
                                                    Tab(text: 'Data'),
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
                                                10000,
                                                widget.accountID,
                                                widget.subAccountID,
                                                widget.initialProcessId,
                                                widget.initialSubProcessId,
                                              );
                                              myLocationListProvider
                                                  .fetchLocationList(
                                                context,
                                                "",
                                                1,
                                                10000,
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
                                                10000,
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
                                    Container(
                                      margin: EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      child: sovBody(typography),
                                    ),
                                    _getSharedComingSoonUI("shared"),
                                    if (isSuperAdmin || isPgAdmin)
                                      ConfigurationTab(
                                        accountId: widget.accountID,
                                        subaccountId: widget.subAccountID,
                                        updateallflag: "false",
                                        level: "local",
                                      ),
                                    Consumer2<AccountListProvider,
                                        SubAccountListProvider>(
                                      builder: (context, accountListProvider,
                                          subAccountListProvider, _) {
                                        final accountList =
                                            accountListProvider.accountList;
                                        final subAccountList =
                                            subAccountListProvider
                                                .subAccountList;
                                        final accountId = accountList.isNotEmpty
                                            ? accountList[0].accountId ?? ""
                                            : "";
                                        final accountName = accountList
                                                .isNotEmpty
                                            ? accountList[0].accountName ?? ""
                                            : "";
                                        final subaccountId = subAccountList
                                                .isNotEmpty
                                            ? subAccountList[0].subAccountId ??
                                                ""
                                            : "";
                                        return DataTab(
                                          accountId: accountId,
                                          accountName: accountName,
                                          subaccountId: subaccountId,
                                        );
                                      },
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
                    Consumer<SOVListProvider>(
                      builder: (context, provider, child) {
                        return provider.isLoading
                            ? SizedBox(
                                height: 24,
                                width: 24,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : IconButton(
                                onPressed: trialStatus.isNotEmpty
                                    ? null
                                    : () {
                                        // provider.setLoading(true); // Start loading

                                        locationListProvider
                                            .addSelectedToSOV(
                                          context,
                                          widget.accountID!,
                                          widget.subAccountID!,
                                          widget.accountName,
                                          widget.subAccountName,
                                          _masterTabController,
                                        )
                                            .then((value) {
                                          provider.fetchSovList(
                                            context,
                                            widget.accountID!,
                                            widget.subAccountID!,
                                            "",
                                            1,
                                            10,
                                          );
                                        }).whenComplete(() {
                                          // Stop loading after API call
                                        });
                                      },
                                icon: Icon(Symbols.list_alt_add),
                                tooltip: 'Add to SOV',
                              );
                      },
                    ),
                    // IconButton(
                    //   onPressed: trialStatus.isNotEmpty
                    //       ? null
                    //       : () {
                    //     var provider = Provider.of<SOVListProvider>(context, listen: false);
                    //           // Implement bulk add to SOV
                    //           locationListProvider.addSelectedToSOV(
                    //               context,
                    //               widget.accountID!,
                    //               widget.subAccountID!,
                    //               widget.accountName,
                    //               widget.subAccountName,
                    //               _masterTabController)  .then((value) {
                    //             provider.fetchSovList(
                    //               context,
                    //               widget.accountID!,
                    //               widget.subAccountID!,
                    //               "",
                    //               1,
                    //               10,
                    //             );
                    //           });
                    //
                    //
                    //
                    //
                    //   },
                    //   icon: Icon(Symbols.list_alt_add),
                    //   tooltip: 'Add to SOV',
                    // ),
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
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
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
                    key: keyFeature1,
                    icon: Remix.file_list_3_line,
                    text: 'Location List',
                  ),
                  GButton(
                    key: keyFeature2,
                    icon: Remix.bar_chart_box_ai_line,
                    text: 'Overall Score',
                  ),
                  GButton(
                    key: keyFeature3,
                    icon: Remix.road_map_line,
                    text: 'Map View',
                  ),
                ]),
          ),
        ),
        SizedBox(height: CustomSpacing.two),
        Expanded(
          child: TabBarView(
            controller: _mainTabController,
            physics: NeverScrollableScrollPhysics(),
            children: [
              // First Tab: List View with Nested Tabs
              Column(
                children: [
                  Consumer<MyLocationListProvider>(
                    builder: (context, locationListProvider, child) {
                      return TabBar(
                        controller: _tabController,
                        labelStyle: typography.BottomNavigationActiveLabel,
                        tabs: [
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(LanguageService.getTranslated(
                                  context,
                                  "locationlist_app_connections_tab_all",
                                )),
                                SizedBox(width: CustomSpacing.two),
                                SizedBox(
                                  height: 25,
                                  child: Chip(
                                    labelPadding: EdgeInsets.zero,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    label: Text(
                                      locationListProvider.isLoading
                                          ? "0"
                                          : locationListProvider.locationHits
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
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(LanguageService.getTranslated(
                                  context,
                                  "locationlist_app_connections_tab_certified",
                                )),
                                SizedBox(width: CustomSpacing.two),
                                SizedBox(
                                  height: 25,
                                  child: Chip(
                                    labelPadding: EdgeInsets.zero,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    label: Text(
                                      locationListProvider.isLoading
                                          ? "0"
                                          : locationListProvider
                                              .certifiedLocationHits
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
                      physics: NeverScrollableScrollPhysics(),
                      children: [
                        _getLocationListAllUI(),
                        _getLocationListCertifiedUI(),
                      ],
                    ),
                  ),
                ],
              ),

              // Second Tab: Table View
              Consumer<MyLocationListProvider>(
                builder: (context, locationListProvider, child) {
                  return locationListProvider.isLoading
                      ? Center(child: CircularProgressIndicator())
                      : LocationTable(
                          locations: locationListProvider.myLocationList);
                },
              ),
              // Third Tab: Map View
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

  void _fetchTabData(int index) {
    final locationListProvider =
        Provider.of<MyLocationListProvider>(context, listen: false);
    locationListProvider.page = 0;

    if (index == 0) {
      // Fetch All locations
      _selectedScreen = Screens.locationList;
      locationListProvider.fetchLocationList(
        context,
        "",
        1,
        10000,
        widget.accountID,
        widget.subAccountID,
        widget.initialProcessId,
        widget.initialSubProcessId,
      );
    } else {
      // Fetch Certified locations
      _selectedScreen = Screens.certifiedLocationList;
      locationListProvider.clearRatingsFilter();
      locationListProvider.fetchCertifiedLocationList(
        context,
        "",
        1,
        40,
        widget.accountID,
        widget.subAccountID,
        widget.initialProcessId,
        widget.initialSubProcessId,
      );
      locationListProvider.fetchLocationList(
        context,
        "",
        1,
        10000,
        widget.accountID,
        widget.subAccountID,
        widget.initialProcessId,
        widget.initialSubProcessId,
      );
    }
  }

  // Widget _getLiveUI(JobMonitoringProvider provider) {
  //   var typography = CustomTypography(context);
  //   FirebaseAuth auth = FirebaseAuth.instance;
  //   String uid = auth.currentUser!.uid;
  //
  //   final combinedStream = _createLiveProcessStream(
  //     userId: uid,
  //     accountId: widget.accountID!,
  //     subAccountId: widget.subAccountID!,
  //   );
  //
  //   return StreamBuilder<Map<String, dynamic>>(
  //     stream: combinedStream,
  //     builder: (context, snapshot) {
  //       if (snapshot.connectionState == ConnectionState.waiting &&
  //           !snapshot.hasData) {
  //         return const SizedBox(height: 20);
  //       }
  //
  //       if (snapshot.hasError || !snapshot.hasData) {
  //         return const SizedBox.shrink();
  //       }
  //
  //       final data = snapshot.data!;
  //       final heatmapStatus = data['heatmapData']?['heatmap_status'] ?? '';
  //       final List<dynamic> onGoingProcesses =
  //           data['on_going_processes'] is List
  //               ? data['on_going_processes']
  //               : [];
  //
  //       // 🔹 Manage multiple processes
  //       if (onGoingProcesses.isEmpty) {
  //         return const SizedBox.shrink();
  //       }
  //
  //       return StatefulBuilder(
  //         builder: (context, setState) {
  //           int currentProcessIndex = 0;
  //
  //           void updateIndex(int newIndex) {
  //             setState(() {
  //               currentProcessIndex = newIndex;
  //             });
  //           }
  //
  //           final currentProcess = onGoingProcesses[currentProcessIndex];
  //           final processStatus = currentProcess['status'] ?? '';
  //           final totalCompleted =
  //               currentProcess['total_processes_completed'] ?? 0;
  //           final totalProcesses = currentProcess['total_processes'] ?? 1;
  //           final percentage = (totalCompleted / totalProcesses) * 100;
  //
  //           return AnimatedSwitcher(
  //             duration: const Duration(milliseconds: 250),
  //             child: Column(
  //               key: ValueKey('$processStatus-$heatmapStatus'),
  //               crossAxisAlignment: CrossAxisAlignment.center,
  //               mainAxisAlignment: MainAxisAlignment.center,
  //               children: [
  //                 if (processStatus.toString().toLowerCase() == 'processing')
  //                   GestureDetector(
  //                     onTap: () {
  //                       Navigator.push(
  //                         context,
  //                         MaterialPageRoute(
  //                           builder: (context) => ProcessMonitoringScreen(
  //                             accountId: widget.accountID,
  //                             subAccountId: widget.subAccountID,
  //                           ),
  //                         ),
  //                       ).then((value) => _getData());
  //                     },
  //                     child: Padding(
  //                       padding: const EdgeInsets.symmetric(horizontal: 16.0),
  //                       child: Row(
  //                         mainAxisAlignment: MainAxisAlignment.center,
  //                         children: [
  //                           Lottie.asset(
  //                             'assets/lottie/loading.json',
  //                             width: 20,
  //                             height: 20,
  //                           ),
  //                           const SizedBox(width: 8.0),
  //                           Text(
  //                             'Processing ${percentage.toStringAsFixed(0)}%',
  //                             style: typography.Caption.copyWith(
  //                               fontWeight: FontWeight.w500,
  //                             ),
  //                           ),
  //                           if (onGoingProcesses.length > 1) ...[
  //                             IconButton(
  //                               icon:
  //                                   const Icon(Icons.arrow_back_ios, size: 14),
  //                               onPressed: currentProcessIndex > 0
  //                                   ? () => updateIndex(currentProcessIndex - 1)
  //                                   : null,
  //                             ),
  //                             Text(
  //                               '${currentProcessIndex + 1}/${onGoingProcesses.length}',
  //                               style: typography.Caption,
  //                             ),
  //                             IconButton(
  //                               icon: const Icon(Icons.arrow_forward_ios,
  //                                   size: 14),
  //                               onPressed: currentProcessIndex <
  //                                       onGoingProcesses.length - 1
  //                                   ? () => updateIndex(currentProcessIndex + 1)
  //                                   : null,
  //                             ),
  //                           ],
  //                         ],
  //                       ),
  //                     ),
  //                   )
  //                 else if (heatmapStatus.toString().toLowerCase() ==
  //                     'initiated')
  //                   Padding(
  //                     padding: const EdgeInsets.symmetric(horizontal: 16.0),
  //                     child: Row(
  //                       mainAxisAlignment: MainAxisAlignment.center,
  //                       children: [
  //                         Lottie.asset(
  //                           'assets/lottie/loading.json',
  //                           width: 20,
  //                           height: 20,
  //                         ),
  //                         const SizedBox(width: 8.0),
  //                         Text(
  //                           'Generating Heatmap',
  //                           style: typography.Caption.copyWith(
  //                             fontWeight: FontWeight.w500,
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //                   ),
  //               ],
  //             ),
  //           );
  //         },
  //       );
  //     },
  //   );
  // }

  Widget _getLiveUI(JobMonitoringProvider provider) {
    var typography = CustomTypography(context);
    FirebaseAuth auth = FirebaseAuth.instance;
    String uid = auth.currentUser!.uid;

    final combinedStream = _createLiveProcessStream(
      userId: uid,
      accountId: widget.accountID!,
      subAccountId: widget.subAccountID!,
    );

    return StreamBuilder<Map<String, dynamic>>(
      stream: combinedStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return SizedBox(
            height: CustomSpacing.six,
            child: Text(""),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return SizedBox.shrink(
            child: Text(""),
          );
        }

        final data = snapshot.data!;
        final heatmapStatus = data['heatmapData']?['heatmap_status'] ?? '';
        final processStatus = data['processData']?['status'] ?? '';

        final List<dynamic> onGoingProcesses =
            data['on_going_processes'] is List
                ? data['on_going_processes']
                : [];

        final bool isCurrentlyProcessing =
            processStatus.toLowerCase() == 'processing';
        final String newProcessStatus = data['processData']?['status'] ?? '';

        final jobProvider =
            Provider.of<JobMonitoringProvider>(context, listen: false);
        _startRefreshTimer();
        if (!_isDisposed && jobProvider.processStatus != newProcessStatus) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!_isDisposed) {
              jobProvider.updateProcessStatus(newProcessStatus);

              if (isCurrentlyProcessing) {
                setState(() {
                  isUploadInProgress = false;
                });
                _startRefreshTimer();
              } else {
                _refreshTimer?.cancel();
                _getData();
              }
            }
          });
        }

        final locationProvider =
            Provider.of<MyLocationListProvider>(context, listen: false);
        locationProvider.isHeatMapGeneratingLive =
            heatmapStatus.toString().toLowerCase() == 'initiated';

        final int totalCompleted =
            data['processData']?['total_processes_completed'] ?? 0;
        final int totalProcesses = data['processData']?['total_processes'] ?? 1;
        final double percentage = (totalCompleted / totalProcesses) * 100;

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Column(
            key: ValueKey('$processStatus-$heatmapStatus'),
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Text(data['processData'].toString(),
              // maxLines: 2,
              //
              // ),
              if (isCurrentlyProcessing)
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProcessMonitoringScreen(
                          accountId: widget.accountID,
                          subAccountId: widget.subAccountID,
                        ),
                      ),
                    ).then((value) => _getData());
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Lottie.asset(
                          'assets/lottie/loading.json',
                          width: 20,
                          height: 20,
                        ),
                        const SizedBox(width: 8.0),
                        Text(
                          'Processing ${percentage.toStringAsFixed(0)}%',
                          style: typography.Caption.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (heatmapStatus.toString().toLowerCase() == 'initiated')
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
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
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Stream<Map<String, dynamic>> _createLiveProcessStream({
    required String userId,
    required String accountId,
    required String subAccountId,
  }) {
    final userStream =
        FirebaseFirestore.instance.collection('users').doc(userId).snapshots();

    final subaccountStream = FirebaseFirestore.instance
        .collection('subaccount')
        .where('sub_account_id', isEqualTo: subAccountId)
        .snapshots();

    return Rx.combineLatest2(userStream, subaccountStream, (userSnap, subSnap) {
      final userData = userSnap.data() as Map<String, dynamic>? ?? {};
      final onGoingProcesses = userData['on_going_processes'] ?? [];

      final activeProcess = onGoingProcesses.firstWhere(
        (p) =>
            p['last_account'] == accountId &&
            p['last_sub_account'] == subAccountId,
        orElse: () => null,
      );

      final String? lastProcessId = activeProcess?['last_process_id'];

      final heatmapData =
          subSnap.docs.isNotEmpty ? subSnap.docs.first.data() : {};

      if (lastProcessId != null) {
        final processDocStream = FirebaseFirestore.instance
            .collection('processes')
            .where('process_id', isEqualTo: lastProcessId)
            .limit(1)
            .snapshots();

        return processDocStream.map((processSnap) {
          final processData =
              processSnap.docs.isNotEmpty ? processSnap.docs.first.data() : {};

          return {
            'processData': processData,
            'heatmapData': heatmapData,
            'on_going_processes': onGoingProcesses,
          };
        });
      }

      return Stream.value({
        'processData': null,
        'heatmapData': heatmapData,
        'on_going_processes': onGoingProcesses,
      });
    }).switchMap((stream) => stream); // flatten nested stream
  }

  Widget _buildProcessSummary(Map<String, dynamic>? summaryData) {
    if (summaryData == null || summaryData.isEmpty) {
      return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).hoverColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(child: CircularProgressIndicator())); // Show loader
    }

    var typography = CustomTypography(context);
    final hazardVendorData = summaryData['hazard_rating_summary'] ?? {};
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).hoverColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: EdgeInsets.all(16), // Add padding for better spacing
        decoration: BoxDecoration(
          color: Theme.of(context).hoverColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Geo Rating Summary",
                  style: typography.Body1.copyWith(fontWeight: FontWeight.w600),
                ),
                IconButton(
                  icon: Icon(Symbols.cancel, color: Colors.red),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            SizedBox(height: 10),
            _buildDynamicGeoRatingSummary(summaryData),
            Container(
              height: MediaQuery.of(context).size.height / 2.8,
              child: _buildHazardVendorSummary(hazardVendorData, typography),
            ),
          ],
        ),
      ),
    );
  }

  // Widget _buildProcessSummary(Map<String, dynamic>? summaryData) {
  //   if (summaryData == null || summaryData.isEmpty) {
  //     return Container(
  //         decoration: BoxDecoration(
  //           color: Theme.of(context).hoverColor,
  //           borderRadius: BorderRadius.circular(10),
  //         ),
  //         height: 180,
  //         child: Center(child: CircularProgressIndicator())); // Show loader
  //   }
  //
  //   var typography = CustomTypography(context);
  //   final hazardVendorData = summaryData['hazard_rating_summary'] ?? {};
  //   return Container(
  //     margin: EdgeInsets.all(0.0),
  //     decoration: BoxDecoration(
  //       color: Theme.of(context).hoverColor,
  //       borderRadius: BorderRadius.circular(16),
  //     ),
  //     child: Container(
  //       height: MediaQuery.of(context).size.height,
  //       width: MediaQuery.of(context).size.width,
  //       decoration: BoxDecoration(
  //         color: Theme.of(context).hoverColor,
  //         borderRadius: BorderRadius.circular(16),
  //       ),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           // Summary Header
  //           ListTile(
  //             trailing: IconButton(
  //               icon: Icon(Symbols.cancel, color: Colors.red),
  //               onPressed: () {
  //                 Navigator.pop(context);
  //               },
  //             ),
  //           ),
  //
  //           Padding(
  //             padding: const EdgeInsets.only(left: 16.0, bottom: 16),
  //             child: Text(
  //               "Geo Rating Summary",
  //               style: typography.Body1.copyWith(fontWeight: FontWeight.w600),
  //             ),
  //           ),
  //           _buildDynamicGeoRatingSummary(summaryData),
  //
  //           Container(
  //               height: MediaQuery.of(context).size.height / 2.8,
  //               width: MediaQuery.of(context).size.width,
  //               child: _buildHazardVendorSummary(hazardVendorData, typography)),
  //         ],
  //       ),
  //     ),
  //   );
  // }

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
                                  "Source: $vendor",
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

  Future<void> _StartHazardConflict(
      {required List<MyLocation> conflictLocations}) async {
    final conflictData = await handleFetchConflict(false);
    final provider = Provider.of<UploadSovProvider>(context, listen: false);
    final selectedData = {
      'location_id': conflictData.toList(),
      'account_id': widget.accountID,
      'sub_account_id': widget.subAccountID,
      'account_name': widget.accountName,
      'sub_account_name': widget.subAccountName,
    };

    print('Selected Data: $selectedData');

    final success = await provider.startHazard(selectedData);
    if (success) {
      Provider.of<JobMonitoringProvider>(context, listen: false)
          .updateProcessStatus('processing');
      _startRefreshTimer();
    }
    // if (success) {
    //   _startRefreshTimer();
    //
    //
    // }
  }

  Future<List<Object?>> handleFetchConflict(bool conflictsCheck) async {
    final url = Uri.parse(
      '${AppConstant.HANDLE_CONFLICT}?page=0&pageSize=50'
      '&account_id=${widget.accountID}'
      '&sub_account_id=${widget.subAccountID}'
      '&show_full_list=true'
      '&conflicts=false',
    );

    try {
      final headers =
          await CommonHeaders.createHeaders(); // Use your auth/token headers
      final response = await http.get(url, headers: headers);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        final List<dynamic> resultJson = data['result'] ?? [];

        final List<MyLocation> locations =
            resultJson.map((item) => MyLocation.fromJson(item)).toList();

        final List<String?> locationIds =
            locations.map((loc) => loc.id).toList();
        print(locationIds);
        print("locationIds");

        final bool isConflict = data['is_conflict'] ?? false;
        final bool canStartHazardProcess = data['hazard_can_start'] ?? false;
        return locationIds;
      } else {
        print("Failed to fetch conflict locations");
        throw Exception("Failed to load conflict locations");
      }
    } catch (e, stackTrace) {
      print(stackTrace);
      print('Error fetching conflict locations: $e');
      return [];
    }
  }

  _getSharedComingSoonUI(String title) {
    var typography = CustomTypography(context);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: Column(
              children: [
                Text(
                    title == "shared"
                        ? 'A smarter way to track shared files-Coming Soon! '
                        : 'A smarter way to track access requests – Coming Soon!',
                    textAlign: TextAlign.center,
                    style: typography.H5_Regular),
                SizedBox(height: 10),
                Text(
                    LanguageService.getTranslated(
                        context, 'coming_soon_subtitle'),
                    textAlign: TextAlign.center,
                    style: typography.Body1),
              ],
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
        final conflictLocations = locationListProvider.myLocationList
            .where((location) => location.isConflict == true)
            .toList();
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
                                    10000,
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
                                    10000,
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
                                      10000,
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
                                    10000,
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
                            10000,
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
            if (locationListProvider.myLocationList.length > 1) ...[
              if (locationListProvider.isConflict == true) ...[
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        MessageCard(
                          messageTextSpans: [
                            TextSpan(
                              text:
                                  "We've found several potential matches for some of the provided location. Please review them and select the correct match to ",
                              style: typography.Body2,
                            ),
                            TextSpan(
                              text: "resolve the conflict",
                              style: typography.Body2.copyWith(
                                color: AppColors.primaryMain,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  for (int i = 0;
                                      i < conflictLocations.length;
                                      i++) {
                                    print(
                                        'Item $i - Geocoded Address: ${conflictLocations[i].geocodedAddress}');
                                  }

                                  Navigator.of(context)
                                      .push(MaterialPageRoute(
                                    builder: (_) => ConflictsTab(
                                      processId: widget.accountID ?? "",
                                      accountId: widget.accountID ?? "",
                                      subAccountId: widget.subAccountID ?? "",
                                      sovId: "null",
                                      accountName: widget.accountName ?? "",
                                      subAccountName:
                                          widget.subAccountName ?? "",
                                      tempId: "tempId",
                                      lat: conflictLocations
                                          .first.location.latitude
                                          .toString(),

                                      long: conflictLocations
                                          .first.location.longitude
                                          .toString(),
                                      geocodingAddress: conflictLocations
                                              .first.finalAddress?.address ??
                                          "",
                                      conflict:
                                          conflictLocations.first.conflicts,
                                      // Optional or just first one
                                      location: conflictLocations,

                                      startHazard:
                                          locationListProvider.isHazardCanStart,
                                    ),
                                  ))
                                      .then((value) {
                                    if (value == true) {
                                      _StartHazardConflict(
                                          conflictLocations: conflictLocations);
                                      locationListProvider.fetchLocationList(
                                        context,
                                        locationQuery,
                                        1,
                                        10000,
                                        widget.accountID,
                                        widget.subAccountID,
                                        widget.initialProcessId,
                                        widget.initialSubProcessId,
                                      );
                                    }
                                  });
                                },
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ] else if (locationListProvider.isHazardCanStart == true) ...[
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        MessageCard1(
                          messageTextSpans: [
                            TextSpan(
                              text:
                                  "Great news, there are no conflicts to resolve!, Click here to ",
                              style: typography.Body2,
                            ),
                            WidgetSpan(
                              child: _isHazardLoading
                                  ? SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.primaryMain,
                                      ),
                                    )
                                  : GestureDetector(
                                      onTap: () async {
                                        setState(() {
                                          _isHazardLoading = true;
                                        });
                                        await _StartHazardConflict(
                                            conflictLocations:
                                                conflictLocations);

                                        setState(() {
                                          _isHazardLoading = false;
                                        });
                                      },
                                      child: Text(
                                        "Update Hazard scores",
                                        style: typography.Body2.copyWith(
                                          color: AppColors.primaryMain,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ],
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
                                "It looks like you haven't added any locations yet. Let's get started! You can add locations by importing an XLS file or by clicking on \"Add Location.\"",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 13, color: Colors.grey)),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () async {
                            // Store selected item IDs before refreshing
                            List<String?> selectedItemIds = locationListProvider
                                .selectedLocations
                                .map((item) => item.id)
                                .toList();

                            // Clear existing selections before the refresh starts
                            locationListProvider.selectedLocations.clear();
                            locationListProvider
                                .notifyListeners(); // Update UI immediately

                            // Refresh data in parallel
                            locationListProvider.certifiedPage = 1;
                            await Future.wait([
                              locationListProvider.fetchLocationList(
                                context,
                                locationQuery,
                                1,
                                10000,
                                widget.accountID,
                                widget.subAccountID,
                                widget.initialProcessId,
                                widget.initialSubProcessId,
                              ),
                              locationListProvider.fetchAllLocationList(
                                context,
                                widget.accountID,
                                widget.subAccountID,
                                processId: widget.initialProcessId,
                                subProcessId: widget.initialSubProcessId,
                              ),
                            ]);

                            // Restore selection after refresh
                            locationListProvider.selectedLocations.addAll(
                              locationListProvider.myLocationList.where(
                                  (item) => selectedItemIds.contains(item.id)),
                            );

                            locationListProvider
                                .notifyListeners(); // Ensure UI updates immediately
                          },
                          child: ListView.builder(
                            physics: ClampingScrollPhysics(),
                            shrinkWrap: true,
                            itemCount:
                                locationListProvider.myLocationList.length,
                            itemBuilder: (context, index) {
                              var location =
                                  locationListProvider.myLocationList[index];
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
                                        isHazardCanStart: locationListProvider
                                            .isHazardCanStart,
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
                                        geocodingScore: locationListProvider
                                                .myLocationList[index]
                                                .finalAddress
                                                ?.score ??
                                            0,
                                        riskScore: locationListProvider
                                                .myLocationList[index]
                                                .overallScore ??
                                            5,
                                        dataCompletenessScore: scoreToStar(
                                            locationListProvider
                                                        .myLocationList[index]
                                                        .dataCompleteness ==
                                                    null
                                                ? 1
                                                : locationListProvider
                                                        .myLocationList[index]
                                                        .dataCompleteness ??
                                                    1),
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
                                                10000,
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
                                        rented: locationListProvider
                                            .myLocationList[index]
                                            .finalAddress
                                            ?.rented,
                                        getData: _getData,
                                        onNavigateStart: () {
                                          _isDisposed = true;
                                          _refreshTimer?.cancel();
                                          deBouncer?.cancel();
                                        },
                                        onNavigateBack: () {
                                          _StartHazardConflict(
                                              conflictLocations:
                                                  conflictLocations);
                                          locationListProvider
                                              .fetchLocationList(
                                            context,
                                            locationQuery,
                                            1,
                                            10000,
                                            widget.accountID,
                                            widget.subAccountID,
                                            widget.initialProcessId,
                                            widget.initialSubProcessId,
                                          );
                                        },
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
                                    10000,
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
                                hazards: locationListProvider
                                        .myLocationList[index].hazard ??
                                    {},
                                isConflict: locationListProvider
                                    .myLocationList[index].isConflict,
                                isHazardCanStart:
                                    locationListProvider.isHazardCanStart,

                                conflict: locationListProvider
                                    .myLocationList[index].conflicts,

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
                                        .myLocationList[index].overallScore ??
                                    0,

                                // locationListProvider
                                //         .myLocationList[index].overallScore ??
                                //     0,
                                dataCompletenessScore: scoreToStar(
                                    locationListProvider.myLocationList[index]
                                                .dataCompleteness ==
                                            null
                                        ? 1
                                        : locationListProvider
                                            .myLocationList[index]
                                            .dataCompleteness),

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
                                        10000,
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
                                        .myLocationList[index].overallScore ??
                                    5,

                                hazardProcess: locationListProvider
                                    .myLocationList[index].isHazardProcess,
                                getData: _getData,
                                onNavigateStart: () {
                                  _isDisposed = true;
                                  _refreshTimer?.cancel();
                                  deBouncer?.cancel();
                                },
                                onNavigateBack: () {
                                  _StartHazardConflict(
                                      conflictLocations: conflictLocations);
                                  locationListProvider.fetchLocationList(
                                    context,
                                    locationQuery,
                                    1,
                                    10000,
                                    widget.accountID,
                                    widget.subAccountID,
                                    widget.initialProcessId,
                                    widget.initialSubProcessId,
                                  );
                                },
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

  int scoreToStar(int? score) {
    if (score == null) return 0;
    if (score >= 80) return 5;
    if (score >= 60) return 4;
    if (score >= 40) return 3;
    if (score >= 20) return 2;
    return 0;
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
                            10000,
                            widget.accountID,
                            widget.subAccountID,
                            widget.initialProcessId,
                            widget.initialSubProcessId,
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
                                "It looks like you haven't added any locations yet. Let's get started! You can add locations by importing an XLS file or by clicking on \"Add Location.\"",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 13, color: Colors.grey)),
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
                              10000,
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
      isHazardCanStart: locationListProvider.isHazardCanStart,
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
      overallScore: (locationListProvider.myLocationList.isNotEmpty &&
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
      dataCompletenessScore: scoreToStar(locationListProvider
                  .certifiedLocationList[index].dataCompleteness ==
              null
          ? 1
          : locationListProvider.certifiedLocationList[index].dataCompleteness),
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
              10000,
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
      hazardProcess: (locationListProvider.myLocationList.isNotEmpty &&
              index < locationListProvider.myLocationList.length)
          ? (locationListProvider.myLocationList[index].isHazardProcess is bool
              ? locationListProvider.myLocationList[index].isHazardProcess
              : false)
          : false,
      rented: (index < locationListProvider.myLocationList.length)
          ? locationListProvider.myLocationList[index].finalAddress?.rented ??
              false
          : false,

      // Provide a default boolean value // hazardProcess: locationListProvider.myLocationList[index].isHazardProcess ??"",
      getData: _getData,
      onNavigateStart: () {
        _isDisposed = true;
        _refreshTimer?.cancel();
        deBouncer?.cancel();
      },

      onNavigateBack: () {
        print("Hello1");
        _StartHazardConflict(conflictLocations: conflictLocations);
        locationListProvider.fetchLocationList(
          context,
          locationQuery,
          1,
          10000,
          widget.accountID,
          widget.subAccountID,
          widget.initialProcessId,
          widget.initialSubProcessId,
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
                  left: 6,
                  right: 6,
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
                        // if (trialStatus.isNotEmpty)
                        Column(
                          children: [
                            // Text(hasGeocodingStatus.toString()),
                            // Text(hasHazardLicenseStatus.toString()),
                            // Text(hasLicenseStatus.toString()),
                            SizedBox(height: 16),
                            if (int.parse(hasHazardLicenseStatus.toString()) >=
                                    1 &&
                                int.parse(hasHazardLicenseStatus.toString()) <=
                                    10)
                              Text(
                                'The system will only process the first ${hasHazardLicenseStatus} locations.',
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

                        if (int.parse(hasHazardLicenseStatus.toString()) > 10)
                          Text(
                              "Available Locations: " +
                                  hasHazardLicenseStatus.toString(),
                              style: typography.Body1),
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
                                                                // Navigator.pop(
                                                                //     context);

                                                                print(
                                                                    'Success: $success');

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
                                                                  print("Nan");
                                                                  Navigator.push(
                                                                      context,
                                                                      MaterialPageRoute(
                                                                          builder: (_) => MappingScreen(
                                                                                tempId: success,
                                                                                accountId: widget.accountID!,
                                                                                accountName: widget.accountName ?? "",
                                                                                subAccountName: widget.subAccountName ?? "",
                                                                                subAccountId: widget.subAccountID!,
                                                                              ))).then((value) {
                                                                    if (value) {
                                                                      setState(
                                                                          () {
                                                                        _getData();
                                                                        _getSovUploadStatus();
                                                                      });
                                                                    }
                                                                  });
                                                                }
                                                              }
                                                            }
                                                          },
                                                    child: Text("Upload",
                                                        style: typography
                                                                .ButtonLarge
                                                            .copyWith(
                                                                color: Colors
                                                                    .black)))),
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
