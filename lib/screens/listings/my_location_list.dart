import 'package:RiskSphere/screens/listings/widgets/location_list_map_view.dart';
import 'package:RiskSphere/screens/listings/widgets/vertical_bar_indicator.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../design_system/repo/constants.dart';
import '../../models/my_location_list_model.dart';
import '../../utils/global_imports.dart';
import '../../models/sov_list_model.dart';
import 'package:RiskSphere/models/role_model.dart' as roleModel;
import 'package:http/http.dart' as http;

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
  String? _activeSubAccountId;
  String? _activeProcessId;
  String? _selectedMapView;
  Timer? _refreshTimer;
  static bool _hasActiveTimer = false;
  bool _isExpanded = false;
  bool sovDeleteStatus = false;
  bool _showNotificationDot = true;
  TabController? _masterTabController;
  late TabController _tabController;
  String selectedProcessId = "";
  bool isSelectionMode = false;
  List<bool> selectedList = [];
  String isMaintenance = "";
  Screens _selectedScreen = Screens.locationList;
  TextEditingController _locationSearchController = TextEditingController();
  TextEditingController mobileController = TextEditingController();
  String selectedDropdown = 'TPV';
  int? touchedIndex; // For showing overlay info
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
  String _lastProcessStatus = '';
  Set<String> selectedSovIds = {};

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
  late final Stream<Map<String, dynamic>> _combinedStream;
  String? _streamAcct;
  String? _streamSub;

// State fields
  final _processIndex$ = BehaviorSubject<int>.seeded(0);
  int _currentProcessIndex = 0;

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
    _buildCombinedStream();
  }

  void _buildCombinedStream() {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    // 🔹 Firestore streams
    final userStream =
        FirebaseFirestore.instance.collection('users').doc(uid).snapshots();

    final subaccountStream = FirebaseFirestore.instance
        .collection('subaccount')
        .where('sub_account_id', isEqualTo: widget.subAccountID!)
        .snapshots();

    // 🔹 Combine user + subaccount + process updates
    _combinedStream = Rx.combineLatest3(
      userStream,
      subaccountStream,
      _processIndex$.distinct(), // current selected process index
      (userSnap, subSnap, selIndex) {
        final userData = (userSnap.data() as Map<String, dynamic>?) ?? {};

        // Active processes for this account/subaccount
        final activeProcesses =
            (userData['on_going_processes'] as List<dynamic>? ?? [])
                .cast<Map<String, dynamic>>()
                .where((p) =>
                    p['last_account'] == widget.accountID &&
                    p['last_sub_account'] == widget.subAccountID)
                .toList();

        final heatmapData =
            subSnap.docs.isNotEmpty ? subSnap.docs.first.data() : {};

        if (activeProcesses.isEmpty) {
          return Stream.value({
            'processData': null,
            'heatmapData': heatmapData,
            'activeProcesses': const <Map<String, dynamic>>[],
            'currentProcessIndex': 0,
          });
        }

        // Clamp index
        final clampedIndex = selIndex.clamp(0, activeProcesses.length - 1);
        final currentProcess = activeProcesses[clampedIndex];
        final String? lastProcessId = currentProcess['last_process_id'];

        if (lastProcessId == null) {
          return Stream.value({
            'processData': null,
            'heatmapData': heatmapData,
            'activeProcesses': activeProcesses,
            'currentProcessIndex': clampedIndex,
          });
        }

        // 🔹 Always listen to process doc updates
        final processStream = FirebaseFirestore.instance
            .collection('processes')
            .where('process_id', isEqualTo: lastProcessId)
            .limit(1)
            .snapshots()
            .map((processSnap) => processSnap.docs.isNotEmpty
                ? processSnap.docs.first.data()
                : {});

        // 🔹 Merge outer data + live process stream
        return processStream.map((processData) => {
              'processData': processData,
              'heatmapData': heatmapData,
              'activeProcesses': activeProcesses,
              'currentProcessIndex': clampedIndex,
            });
      },
    )
        .switchMap((inner) => inner) // flatten nested streams
        .throttleTime(const Duration(milliseconds: 500)); // smooth updates
  }

  void _initializeData() {
    _setClaims();
    getdata(widget.accountID!, widget.subAccountID!);
    _startRefreshTimer(widget.accountID!, widget.subAccountID!);
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
          10,
          widget.accountID,
          widget.subAccountID,
          widget.initialProcessId,
          widget.initialSubProcessId,
          '');
    } else {
      _selectedScreen = Screens.certifiedLocationList;
      locationListProvider.clearRatingsFilter();
      locationListProvider.fetchCertifiedLocationList(
        context,
        "",
        1,
        10,
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

  // @override
  // void didChangeDependencies() {
  //   super.didChangeDependencies();
  //   _myLocationProvider ??=
  //       Provider.of<MyLocationListProvider>(context, listen: false);
  // }

  @override
  void didUpdateWidget(covariant MyLocationList old) {
    super.didUpdateWidget(old);
    if (old.accountID != widget.accountID ||
        old.subAccountID != widget.subAccountID) {
      _currentProcessIndex = 0;
      _processIndex$.add(0);
      // stop anything tied to the old page
      _refreshTimer?.cancel();
      _activeAccountKey = null;
      _lastProcessStatus = '';
      _buildCombinedStream();
      setState(() {});
    }
  }

  @override
  void dispose() {
    _processIndex$.close();
    _refreshTimer?.cancel();
    _refreshTimer?.cancel();
    _activeAccountKey = null;
    _isDisposed = true;
    _mainTabController?.dispose();
    _masterTabController?.dispose();
    _tabController?.dispose();
    _refreshTimer?.cancel();
    _hasActiveTimer = false;
    _isDisposed = true;

    // deBouncer?.cancel();

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
  String? _activeAccountKey; // track which account/subaccount timer belongs to

  // void _startRefreshTimer(String accountId, String subAccountId) {
  //   final currentKey = "$accountId-$subAccountId";
  //
  //   // if already running for the same account/subaccount → skip
  //   if (_activeAccountKey == currentKey && _refreshTimer?.isActive == true)
  //     return;
  //
  //   // cancel any old timer
  //   _refreshTimer?.cancel();
  //   _hasActiveTimer = false;
  //
  //   _activeAccountKey = currentKey;
  //   _hasActiveTimer = true;
  //
  //   // 👇 Immediately refresh once
  //   final provider = Provider.of<JobMonitoringProvider>(context, listen: false);
  //   if (mounted && provider.isProcessing) {
  //     getdata(accountId, subAccountId);
  //   }
  //
  //   // 👇 Schedule periodic refresh
  //   _refreshTimer = Timer.periodic(const Duration(seconds: 20), (timer) {
  //     final provider =
  //         Provider.of<JobMonitoringProvider>(context, listen: false);
  //
  //     if (mounted && provider.isProcessing) {
  //       setState(() {
  //         isUploadInProgress = false;
  //       });
  //       getdata(accountId, subAccountId);
  //     } else {
  //       _refreshTimer?.cancel();
  //       _activeAccountKey = null;
  //       _hasActiveTimer = false;
  //     }
  //   });
  // }

  Future<void> getdata(String accountId, String subAccountId) async {
    if (!mounted) return;
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
    final sovListProvider =
        Provider.of<SOVListProvider>(context, listen: false);
    final locationListProvider =
        Provider.of<MyLocationListProvider>(context, listen: false);

    locationListProvider.certifiedPage = 1;

    await locationListProvider.fetchLocationList(context, "", 1, 8, accountId,
        subAccountId, widget.initialProcessId, widget.initialSubProcessId, '');
    sovListProvider.fetchSovList(
        context, widget.accountID!, widget.subAccountID!, "", 1, 10, 'all');
    // sovListProvider.fetchAutoCompleteSovListLocations(
    //   context,
    //   widget.accountID!,
    //   widget.subAccountID!,
    // );

    await locationListProvider.fetchAllLocationList(
      context,
      accountId,
      subAccountId,
      processId: widget.initialProcessId,
      subProcessId: widget.initialSubProcessId,
    );
    await locationListProvider.fetchLocationList1(
      context,
      1,
      500,  accountId,
      subAccountId,
      widget.initialProcessId,
      widget.initialSubProcessId,
      ""
    );




    await locationListProvider.fetchCertifiedLocationList(
      context,
      "",
      locationListProvider.certifiedPage,
      8,
      accountId,
      subAccountId,
      widget.initialProcessId,
      widget.initialSubProcessId,
    );

    if (mounted) {
      setState(() {});
    }
  }

//   void _startRefreshTimer() {
//     if (_refreshTimer != null && _refreshTimer!.isActive) return;
//     if (_hasActiveTimer) return;
//
//     _hasActiveTimer = true;
//
//     // 👇 Immediately refresh once when timer starts
//     final provider = Provider.of<JobMonitoringProvider>(context, listen: false);
//     if (mounted && provider.isProcessing) {
//       _refreshData();
//     }
//
//     // 👇 Then schedule periodic refresh
//     _refreshTimer = Timer.periodic(const Duration(seconds: 20), (timer) {
//       final provider =
//           Provider.of<JobMonitoringProvider>(context, listen: false);
//       if (mounted && provider.isProcessing) {
//         setState(() {
//           isUploadInProgress = false;
//         });
//         _refreshData();
//       } else {
//         _refreshTimer?.cancel();
//         _hasActiveTimer = false;
//       }
//     });
//   }
//
//   Future<void> _refreshData() async {
//     if (!mounted) return; // Ensure the widget is still in the tree
//
//     final locationListProvider =
//         Provider.of<MyLocationListProvider>(context, listen: false);
//
//     locationListProvider.certifiedPage = 1;
//
//
//     await locationListProvider.fetchLocationList(
//       context,
//       "",
//       1,
//       10,
//       widget.accountID,
//       widget.subAccountID,
//       widget.initialProcessId,
//       widget.initialSubProcessId,
//     );
//
//     await locationListProvider.fetchAllLocationList(
//       context,
//       widget.accountID,
//       widget.subAccountID,
//       processId: widget.initialProcessId,
//       subProcessId: widget.initialSubProcessId,
//     );
//     await locationListProvider.fetchCertifiedLocationList(
//       context,
//       "",
//       locationListProvider.certifiedPage,
//       8,
//       widget.accountID,
//       widget.subAccountID,
//       widget.initialProcessId,
//       widget.initialSubProcessId,
//     );
//
//
//     if (mounted) {
//       setState(() {}); // Trigger UI update after fetching data
//     }
//   }
//
//   Future<void> _getData() async {
//     isPgAdmin = await SharedPreferenceService.getClaimForSubfeature(
//             SharedPreferenceService.IS_PG_ADMIN) ??
//         false;
//     isSuperAdmin = await SharedPreferenceService.getClaimForSubfeature(
//             SharedPreferenceService.IS_SUPER_ADMIN) ??
//         false;
//     bool? hasAnyPlans = await SharedPreferenceService.getHasAnyPlan();
//     String? geoCodingStatus =
//         await SharedPreferenceService.getGeocodingLicense();
//     String? userLicenseStatus = await SharedPreferenceService.getUserLicense();
//     String? hazardLicenseStatus =
//         await SharedPreferenceService.getHazardLicense();
//     setState(() {
//       isPgAdmin = isPgAdmin;
//       isSuperAdmin = isSuperAdmin;
//       hasAnyPlan = hasAnyPlans ?? false;
//       hasLicenseStatus = userLicenseStatus ?? "1";
//       hasGeocodingStatus = geoCodingStatus ?? "1";
//       hasHazardLicenseStatus = hazardLicenseStatus ?? "1";
//     });
//     final myLocationProvider =
//         Provider.of<MyLocationListProvider>(context, listen: false);
//     final sovListProvider =
//         Provider.of<SOVListProvider>(context, listen: false);
//     final jobMonitoringProvider =
//         Provider.of<JobMonitoringProvider>(context, listen: false);
//
//     await Future.wait([
//
//       myLocationProvider
//           .fetchLocationList(
//             context,
//             "",
//             1,
//             8,
//             widget.accountID,
//             widget.subAccountID,
//             widget.initialProcessId,
//             widget.initialSubProcessId,
//           )
//           .then((_) => setState(() {})),
//       myLocationProvider
//           .fetchLocationConflictList(
//         context,
//         "",
//         1,
//         30,
//         widget.accountID,
//         widget.subAccountID,
//         widget.initialProcessId,
//         widget.initialSubProcessId,
//       )
//           .then((_) => setState(() {})),
//
//       myLocationProvider.fetchCertifiedLocationList(
//         context,
//         "",
//         1,
//         10,
//         widget.accountID,
//         widget.subAccountID,
//         widget.initialProcessId,
//         widget.initialSubProcessId,
//       ),
//       // .then((_) => WidgetsBinding.instance!.addPostFrameCallback(
//       //     (_) => setState(() {}))), // Update UI after frame rendering
//
//       sovListProvider.fetchSovList(
//         context,
//         widget.accountID!,
//         widget.subAccountID!,
//         "",
//         1,
//         10,
//       ),
//
//       sovListProvider.fetchAutoCompleteSovListLocations(
//         context,
//         widget.accountID!,
//         widget.subAccountID!,
//       ),
// //future
//       // myLocationProvider.fetchAllLocationList(
//       //   context,
//       //   widget.accountID,
//       //   widget.subAccountID,
//       //   processId: widget.initialProcessId,
//       //   subProcessId: widget.initialSubProcessId,
//       // ),
//
//       jobMonitoringProvider.fetchCompanyIds(),
//     ]);
//   }

  ScrollController _scrollController = ScrollController();
  String selectedSov = 'My SOVs';
  final List<String> sovOptions = ['My SOVs', 'Shared SOVs', 'Received SOVs'];

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
                floatingActionButton: ((_masterTabController?.index ?? 0) == 0)
                    ? Builder(builder: (context) {
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
                                                themeProvider.getTheme
                                                    .colorScheme.onPrimary,
                                              ),
                                            ),
                                          )
                                        : Icon(Icons.add),
                                    backgroundColor: AppColors.primaryMain,
                                    foregroundColor: themeProvider
                                        .getTheme.colorScheme.onPrimary,
                                    label: 'Add Location',
                                    labelStyle: typography.Body1,
                                    onTap: () async {
                                      setState(() {
                                        _isLoading = true;
                                      });

                                      await _setClaims();
                                      await Future.delayed(
                                          Duration(seconds: 1));

                                      // Cancel timers and debounce before navigating
                                      _isDisposed = true;
                                      _refreshTimer?.isActive;
                                      deBouncer?.cancel();

                                      final result = await Navigator.of(context)
                                          .push(MaterialPageRoute(
                                              builder: (_) => AddLocationScreen(
                                                    accountId:
                                                        widget.accountID!,
                                                    subAccountId:
                                                        widget.subAccountID!,
                                                    sovId: "",
                                                    accountName:
                                                        widget.accountName,
                                                    subAccountName:
                                                        widget.subAccountName,
                                                  )));

                                      _isDisposed = false;
                                      _startRefreshTimer(
                                          widget.accountID!,
                                          widget
                                              .subAccountID!); // recreate timer
                                      // deBouncer = Debouncer(milliseconds: 500);// ✅ Re-create debounce instance
                                      _getSovUploadStatus();
                                      setState(() => _isLoading = false);

                                      if (result == true) {
                                        await getdata(widget.accountID!,
                                            widget.subAccountID!);
                                        _startRefreshTimer(widget.accountID!,
                                            widget.subAccountID!);
                                        await Provider.of<
                                                    MyLocationListProvider>(
                                                context,
                                                listen: false)
                                            .fetchLocationList(
                                                context,
                                                "",
                                                1,
                                                10,
                                                widget.accountID,
                                                widget.subAccountID,
                                                widget.initialProcessId,
                                                widget.initialSubProcessId,
                                                '');
                                        setState(() {});
                                      }
                                    }),
                              SpeedDialChild(
                                child: Icon(Icons.upload),
                                backgroundColor: AppColors.primaryMain,
                                foregroundColor: themeProvider
                                    .getTheme.colorScheme.onPrimary,
                                label: isUploadInProgress
                                    ? 'Continue'
                                    : 'Import Locations',
                                labelStyle: typography.Body1,
                                onTap: () async {
                                  tagController.text = "";
                                  if (isMaintenance.toString() ==
                                      'in_progress') {
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
                                    await Provider.of<UploadSovProvider>(
                                            context,
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
                                    _showUploadBottomSheet(widget.accountID!,
                                        widget.subAccountID!, "");
                                  }
                                },
                              ),
                              if ((_masterTabController?.index ?? 0) == 0)
                                SpeedDialChild(
                                  child: Icon(Icons.download),
                                  backgroundColor: trialStatus.isNotEmpty
                                      ? Colors.grey
                                      : AppColors.primaryMain,
                                  foregroundColor: themeProvider
                                      .getTheme.colorScheme.onPrimary,
                                  label: 'Export Locations',
                                  labelStyle: typography.Body1,
                                  onTap: trialStatus.isNotEmpty
                                      ? null
                                      : () async {
                                          await getdata(
                                              widget.accountID!,
                                              widget
                                                  .subAccountID!); // API call only when tapped
                                          setState(() {});

                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return ExportDialog(
                                                accountId: widget.accountID!,
                                                subAccountId:
                                                    widget.subAccountID!,
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
                      })
                    : null,
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
                                      // Consumer<JobMonitoringProvider>(
                                      //   builder: (context,
                                      //       jobMonitoringProvider, child) {
                                      //     return _getLiveUI(
                                      //         jobMonitoringProvider);
                                      //   },
                                      // ),
                                      _getLiveUI(),
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
                                                    const Tab(
                                                        text: 'Locations'),

                                                    // 🔽 Tab with dropdown
                                                    Tab(
                                                      child: Builder(
                                                        builder: (context) {
                                                          return GestureDetector(
                                                            behavior:
                                                                HitTestBehavior
                                                                    .translucent,
                                                            onTapDown:
                                                                (TapDownDetails
                                                                    details) async {
                                                              final tabController =
                                                                  _masterTabController;
                                                              final tabIndex =
                                                                  1; // index for this tab

                                                              // 🟡 Don't switch tab immediately — first show dropdown
                                                              final RenderBox
                                                                  button =
                                                                  context.findRenderObject()
                                                                      as RenderBox;
                                                              final RenderBox
                                                                  overlay =
                                                                  Overlay.of(context)
                                                                          .context
                                                                          .findRenderObject()
                                                                      as RenderBox;

                                                              // dropdown below the tab
                                                              final position =
                                                                  RelativeRect
                                                                      .fromRect(
                                                                Rect.fromPoints(
                                                                  button.localToGlobal(
                                                                      Offset(
                                                                          0,
                                                                          button
                                                                              .size
                                                                              .height),
                                                                      ancestor:
                                                                          overlay),
                                                                  button.localToGlobal(
                                                                      button
                                                                          .size
                                                                          .bottomRight(Offset
                                                                              .zero),
                                                                      ancestor:
                                                                          overlay),
                                                                ),
                                                                Offset.zero &
                                                                    overlay
                                                                        .size,
                                                              );

                                                              // show dropdown
                                                              final selected =
                                                                  await showMenu<
                                                                      String>(
                                                                context:
                                                                    context,
                                                                position:
                                                                    position,
                                                                color: const Color(
                                                                    0xFF1E1E1E),
                                                                items: sovOptions
                                                                    .map(
                                                                      (item) =>
                                                                          PopupMenuItem<
                                                                              String>(
                                                                        value:
                                                                            item,
                                                                        child:
                                                                            Text(
                                                                          item,
                                                                          style:
                                                                              const TextStyle(color: Colors.white),
                                                                        ),
                                                                      ),
                                                                    )
                                                                    .toList(),
                                                              );

                                                              // 🟢 Only when dropdown item is selected → go to tab
                                                              if (selected !=
                                                                  null) {
                                                                setState(() =>
                                                                    selectedSov =
                                                                        selected);

                                                                // Switch to tab after selection
                                                                tabController!
                                                                    .animateTo(
                                                                        tabIndex);

                                                                // Fetch data based on selection
                                                                final sovListProvider =
                                                                    Provider.of<
                                                                            SOVListProvider>(
                                                                        context,
                                                                        listen:
                                                                            false);

                                                                sovListProvider
                                                                    .fetchSovList(
                                                                  context,
                                                                  widget.accountID ??
                                                                      '',
                                                                  widget.subAccountID ??
                                                                      '',
                                                                  "",
                                                                  1,
                                                                  10,
                                                                  selected ==
                                                                          'Shared SOVs'
                                                                      ? 'shared'
                                                                      : selected ==
                                                                              'My SOVs'
                                                                          ? 'my'
                                                                          : 'received',
                                                                );
                                                              }
                                                            },
                                                            child: Row(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                Flexible(
                                                                  child: Text(
                                                                    selectedSov,
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                    style: const TextStyle(
                                                                        color: Colors
                                                                            .white),
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                    width: 4),
                                                                const Icon(
                                                                    Icons
                                                                        .arrow_drop_down,
                                                                    color: Colors
                                                                        .grey,
                                                                    size: 22),
                                                              ],
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ),

                                                    const Tab(text: 'Shared'),

                                                    if (isSuperAdmin ||
                                                        isPgAdmin)
                                                      const Tab(
                                                          text:
                                                              'Configuration'),

                                                    const Tab(text: 'Data'),
                                                  ],
                                                ),
                                              ),
                                            ),

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
                                              _buildCombinedStream();
                                              myLocationListProvider
                                                  .fetchLocationList(
                                                      context,
                                                      "",
                                                      1,
                                                      10,
                                                      widget.accountID,
                                                      widget.subAccountID,
                                                      widget.initialProcessId,
                                                      widget
                                                          .initialSubProcessId,
                                                      '');
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
                                                10,
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
                      onPressed:
                          // trialStatus.isNotEmpty
                          //     ? null
                          //     :
                          () {
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
                                  if (_selectedScreen == Screens.locationList) {
                                    print(
                                        'Selected ids: ${locationListProvider.selectedLocations.map((sov) => sov.id).toList()}');
                                    // On export button click
                                    List<String> selectedSovIds =
                                        Provider.of<MyLocationListProvider>(
                                                context,
                                                listen: false)
                                            .selectedLocations
                                            .map((sov) => sov.id!)
                                            .toList();
                                    print('Selected ids: $selectedSovIds');

                                    if (selectedSovIds.isNotEmpty) {
                                      Navigator.pop(context);
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return ExportDialog(
                                            accountId: widget.accountID!,
                                            subAccountId: widget.subAccountID!,
                                            locationId: selectedSovIds,
                                          );
                                        },
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                        content: Text(
                                          LanguageService.getTranslated(context,
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
                                                location.isSelected ?? false)
                                            .map((sov) => sov.id!)
                                            .toList();

                                    if (selectedLoactionIds.isNotEmpty) {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return ExportDialog(
                                            accountId: widget.accountID!,
                                            subAccountId: widget.subAccountID!,
                                            locationId: selectedLoactionIds,
                                          );
                                        },
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                        content: Text(
                                          LanguageService.getTranslated(context,
                                              "no_items_selected_error"),
                                          style: typography.Body1,
                                        ),
                                      ));
                                    }
                                  }
                                },
                                child: Text('Export', style: typography.Body1),
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
                    // Consumer<SOVListProvider>(
                    //   builder: (context, provider, child) {
                    //     return provider.isLoading
                    //         ? SizedBox(
                    //             height: 24,
                    //             width: 24,
                    //             child:
                    //                 CircularProgressIndicator(strokeWidth: 2),
                    //           )
                    //         : IconButton(
                    //             onPressed: trialStatus.isNotEmpty
                    //                 ? null
                    //                 : () {
                    //                     // provider.setLoading(true); // Start loading
                    //
                    //                     locationListProvider
                    //                         .addSelectedToSOV(
                    //                       context,
                    //                       widget.accountID!,
                    //                       widget.subAccountID!,
                    //                       widget.accountName,
                    //                       widget.subAccountName,
                    //                       _masterTabController,
                    //                     )
                    //                         .then((value) {
                    //                       provider.fetchSovList(
                    //                           context,
                    //                           widget.accountID!,
                    //                           widget.subAccountID!,
                    //                           "",
                    //                           1,
                    //                           10,
                    //                           'all');
                    //                     }).whenComplete(() {
                    //                       // Stop loading after API call
                    //                     });
                    //                   },
                    //             icon: Icon(Symbols.list_alt_add),
                    //             tooltip: 'Add to SOV',
                    //           );
                    //   },
                    // ),
                    IconButton(
                      onPressed:
                          // trialStatus.isNotEmpty
                          //     ? null
                          () {
                        var provider = Provider.of<SOVListProvider>(context,
                            listen: false);
                        // Implement bulk add to SOV
                        locationListProvider
                            .addSelectedToSOV(
                                context,
                                widget.accountID!,
                                widget.subAccountID!,
                                widget.accountName,
                                widget.subAccountName,
                                _masterTabController)
                            .then((value) {
                          provider.fetchSovList(context, widget.accountID!,
                              widget.subAccountID!, "", 1, 10, "");
                        });
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
                  // Replace the third GButton with a GestureDetector or PopupMenuButton
                  // GButton(
                  //   key: keyFeature3,
                  //   icon: Remix.road_map_line,
                  //   text: _selectedMapView ?? 'Map View',
                  //   onPressed: () async {
                  //     // Show dropdown when this button is pressed
                  //     final selected = await showMenu<String>(
                  //       context: context,
                  //       position: RelativeRect.fromLTRB(100, 1, 0, 100),
                  //       // adjust as needed
                  //       items: [
                  //         const PopupMenuItem(
                  //           value: 'Geocoding',
                  //           child: Text('Geocoding'),
                  //         ),
                  //         const PopupMenuItem(
                  //           value: 'RiskScore',
                  //           child: Text('Risk Score'),
                  //         ),
                  //       ],
                  //     );
                  //
                  //     if (selected != null) {
                  //       setState(() {
                  //         _selectedMapView = selected;
                  //         selectedMainTab =
                  //             2; // ensure Map View tab is selected
                  //         _mainTabController?.animateTo(2);
                  //       });
                  //     }
                  //   },
                  // ),

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
              // Consumer<MyLocationListProvider>(
              //   builder: (context, locationListProvider, child) {
              //     if (locationListProvider.isLoading && locationListProvider.page == 1) {
              //       return const Center(child: CircularProgressIndicator());
              //     }
              //
              //     final locations = locationListProvider.myLocationList;
              //     if (locations.isEmpty) {
              //       return const Center(child: Text("No Locations Found"));
              //     }
              //
              //     List<String> hazardColumns = locations.first.hazard?.keys.toList() ?? [];
              //     final Map<String, int> hazardOrder = {
              //       'Hurricane': 1,
              //       'Earthquake': 2,
              //       'Wildfire': 3,
              //       'CoastalFlood': 4,
              //       'RiverineFlood': 5,
              //       'Avalanche': 6,
              //       'ColdWave': 7,
              //       'Drought': 8,
              //       'Hail': 9,
              //       'HeatWave': 10,
              //       'IceStorm': 11,
              //       'Landslide': 12,
              //       'Lightning': 13,
              //       'StrongWind': 14,
              //       'Tornado': 15,
              //       'Tsunami': 16,
              //       'VolcanicActivity': 17,
              //       'WinterWeather': 18,
              //     };
              //
              //     final sortedHazardColumns = hazardColumns
              //         .where((hazard) => hazard != 'Overall')
              //         .toList()
              //       ..sort((a, b) => (hazardOrder[a] ?? 999)
              //           .compareTo(hazardOrder[b] ?? 999));
              //
              //     final showRiskScoreNotifier = ValueNotifier<bool>(true);
              //
              //     ScrollController scrollController = ScrollController();
              //     scrollController.addListener(() {
              //       if (scrollController.position.pixels >=
              //           scrollController.position.maxScrollExtent - 200 &&
              //           !locationListProvider.isNextPageLoading &&
              //           locationListProvider.page < locationListProvider.totalPages) {
              //         // Fetch next page
              //         locationListProvider.page += 1;
              //         locationListProvider.fetchLocationList(
              //           context,
              //           locationQuery,
              //           locationListProvider.page,
              //           10, // page size
              //           widget.accountID,
              //           widget.subAccountID,
              //           widget.initialProcessId,
              //           widget.initialSubProcessId,
              //           '',
              //         );
              //       }
              //     });
              //
              //     return ValueListenableBuilder<bool>(
              //       valueListenable: showRiskScoreNotifier,
              //       builder: (context, showRiskScore, _) {
              //         return Column(
              //           children: [
              //             Text("${locations.length} Locations"),
              //             Expanded(
              //               child: RefreshIndicator(
              //                 onRefresh: () async {
              //                   locationListProvider.page = 1;
              //                   await locationListProvider.fetchLocationList(
              //                     context,
              //                     locationQuery,
              //                     1,
              //                     10,
              //                     widget.accountID,
              //                     widget.subAccountID,
              //                     widget.initialProcessId,
              //                     widget.initialSubProcessId,
              //                     '',
              //                   );
              //                 },
              //                 child: ListView.builder(
              //                   controller: scrollController,
              //                   physics: const ClampingScrollPhysics(),
              //                   itemCount: locations.length + 1, // extra for loader
              //                   itemBuilder: (context, index) {
              //                     if (index == locations.length) {
              //                       // show loader at bottom
              //                       return locationListProvider.isNextPageLoading
              //                           ? const Padding(
              //                         padding: EdgeInsets.all(8.0),
              //                         child: Center(
              //                             child: CircularProgressIndicator()),
              //                       )
              //                           : const SizedBox.shrink();
              //                     }
              //
              //                     final location = locations[index];
              //
              //                     return Container(
              //                       margin: const EdgeInsets.symmetric(
              //                           horizontal: 16, vertical: 4),
              //                       decoration: BoxDecoration(
              //                         color: Theme.of(context).colorScheme.surface,
              //                         borderRadius: BorderRadius.circular(12),
              //                         boxShadow: const [
              //                           BoxShadow(
              //                             color: Colors.black12,
              //                             blurRadius: 8,
              //                             spreadRadius: 2,
              //                             offset: Offset(0, 2),
              //                           ),
              //                         ],
              //                       ),
              //                       child: DataTable2(
              //                         minWidth: MediaQuery.of(context).size.width * 1.5,
              //                         headingRowColor: WidgetStateProperty.all(
              //                             Theme.of(context)
              //                                 .colorScheme
              //                                 .surfaceContainerLowest),
              //                         columnSpacing: 0,
              //                         fixedTopRows: 1,
              //                         fixedLeftColumns: 1,
              //                         columns: [
              //                           DataColumn2(
              //                             fixedWidth:
              //                             MediaQuery.of(context).size.width * 0.3,
              //                             label: Text('Location'),
              //                           ),
              //                           DataColumn2(
              //                             fixedWidth:
              //                             MediaQuery.of(context).size.width * 0.3,
              //                             label: Text('Geocoding Score'),
              //                           ),
              //                           DataColumn2(
              //                             fixedWidth:
              //                             MediaQuery.of(context).size.width * 0.3,
              //                             label: Text('Hazard Score'),
              //                           ),
              //                           ...sortedHazardColumns.map(
              //                                 (hazard) => DataColumn2(
              //                               label: Text(hazard),
              //                             ),
              //                           ),
              //                         ],
              //                         rows: [
              //                           DataRow(
              //                             cells: [
              //                               DataCell(Text(location.geocodedAddress ?? '')),
              //                               DataCell(_renderRiskScore(
              //                                   int.tryParse(location.geocodingScore
              //                                       ?.toString() ??
              //                                       '') ??
              //                                       0)),
              //                               DataCell(_renderRiskScore(
              //                                   int.tryParse(location.overallScore
              //                                       ?.toString() ??
              //                                       '') ??
              //                                       0)),
              //                               ...sortedHazardColumns.map(
              //                                     (hazard) => DataCell(
              //                                   _renderRiskScore(int.tryParse(location
              //                                       .hazard?[hazard]?.rating
              //                                       ?.toString() ??
              //                                       '') ??
              //                                       0),
              //                                 ),
              //                               ),
              //                             ],
              //                           ),
              //                         ],
              //                       ),
              //                     );
              //                   },
              //                 ),
              //               ),
              //             ),
              //           ],
              //         );
              //       },
              //     );
              //   },
              // ),
              Consumer<MyLocationListProvider>(
                builder: (context, locationListProvider, child) {
                  return locationListProvider.isLoading
                      ? Center(child: CircularProgressIndicator())
                      : LocationTable(
                      locations: locationListProvider.overallLocationList);
                },
              ),
              // LocationTable(
              //   locations:
              //  //  accountID: widget.accountID!,
              //  //  subAccountID: widget.subAccountID!,
              //  // initialProcessId: widget.initialProcessId,
              //  //  initialSubProcessId: widget.initialSubProcessId,
              // ),


              LocationListMapView(
                accountId: widget.accountID!,
                subAccountId: widget.subAccountID!,
                // accountName: widget.accountName,
                // subAccountName: widget.subAccountName,
                // sovName:"",
              ),
            ],
          ),
        ),
      ],
    );
  }
  Widget _renderRiskScore(int? score) {
    if (score == null || score == 0) {
      return Center(
        child: Text(
          "-",
          style: CustomTypography(context).Body2.copyWith(color: Colors.grey),
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      alignment: Alignment.center,
      color: _getColorForRating(context, score),
      child: Text(
        score.toString(),
        style: CustomTypography(context)
            .Body2
            .copyWith(color: _getTextColorForRating(context, score)),
      ),
    );
  }
  Color _getColorForRating(BuildContext context, int? rating) {
    if (rating == null) return Colors.grey;
    if (rating == 5) return Color(0xFF2E7D32);
    if (rating == 4) return Color(0xFF81C784);
    if (rating == 3) return Color(0xFFFFEE58);
    if (rating == 2) return Color(0xFFE57373);
    if (rating == 1) return Color(0xFFF44336);
    return Colors.transparent;
  }

  Color _getTextColorForRating(BuildContext context, int? rating) {
    if (rating == null || rating == 0) {
      return Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    }
    return (rating >= 4) ? Colors.white : Colors.black;
  }

  // Widget _renderFormattedHazardData(HazardDetails? hazardDetails, int? score) {
  //   if (score == null || score == 0) {
  //     return Text(
  //       "-",
  //       style: CustomTypography(context).Body2.copyWith(color: Colors.grey),
  //     );
  //   }
  //
  //   if (hazardDetails == null || hazardDetails.others == null) {
  //     return Text(
  //       "-",
  //       style: CustomTypography(context).Body2.copyWith(color: Colors.grey),
  //     );
  //   }
  //
  //   List<Widget> vendorDataWidgets = [];
  //
  //   // **Coastal Flood**
  //   // if (hazardDetails.others!.containsKey("Kineticast")) {
  //   //   var mainValue = hazardDetails.others!["Kineticast"]!.value;
  //   //   vendorDataWidgets.add(_buildVendorDataWidget(
  //   //       key: "Flood depth (ft)",
  //   //       value: _formatNumber(mainValue),
  //   //       vendorName: "KinetiCast",
  //   //       score: score));
  //   // }
  //   if (hazardDetails.others!.containsKey("MarshMcLennan")) {
  //     var mainValue = hazardDetails.others!["MarshMcLennan"]!.value;
  //     vendorDataWidgets.add(_buildVendorDataWidget(
  //       key: "Flood Risk Score",
  //       value: mainValue.toString(),
  //       vendorName: hazardDetails.vendorName.toString() == "MM FRI"
  //           ? "MM FRI **"
  //           : "MM FRI", //"MM FRI",
  //       score: score,
  //     ));
  //   }
  //
  //   // **Earthquake**
  //   if (hazardDetails.others!.containsKey("GlobalEarthquakeModel")) {
  //     var mainValue = hazardDetails.others!["GlobalEarthquakeModel"]!.value;
  //     vendorDataWidgets.add(_buildVendorDataWidget(
  //       key: "PGA (%g)",
  //       value: _formatNumber(mainValue),
  //       vendorName: hazardDetails.vendorName.toString() == "GEM"
  //           ? "GEM **"
  //           : "GEM", //"GEM",
  //       score: score,
  //     ));
  //   }
  //
  //   // **Hurricane**
  //   if (hazardDetails.others!.containsKey("Kineticast")) {
  //     var mainValue = hazardDetails.others!["Kineticast"]!.value;
  //     vendorDataWidgets.add(_buildVendorDataWidget(
  //       key: "Wind Speed (mph)",
  //       value: _formatNumber(mainValue),
  //       vendorName: hazardDetails.vendorName.toString() == "KinetiCast"
  //           ? "KinetiCast **"
  //           : "Kineticast",
  //       score: score,
  //     ));
  //   }
  //   // **Wildfire**
  //   if (hazardDetails.others!.containsKey("Modis")) {
  //     var mainValue = hazardDetails.others!["Modis"]!.value;
  //     vendorDataWidgets.add(_buildVendorDataWidget(
  //       key: "Temp(K) / FRP",
  //       value: _formatNumber(mainValue),
  //       vendorName: hazardDetails.vendorName.toString() == "MODIS"
  //           ? "MODIS **"
  //           : "MODIS", //"MODIS",
  //       score: score,
  //     ));
  //   }
  //
  //   // **Riverine Flood**
  //   if (hazardDetails.others!.containsKey("JRCOD")) {
  //     var mainValue = hazardDetails.others!["JRCOD"]!.value;
  //     vendorDataWidgets.add(_buildVendorDataWidget(
  //       key: "Flood Depth (ft)",
  //       value: _formatNumber(mainValue, decimalPlaces: 1),
  //       vendorName: hazardDetails.vendorName.toString() == "EU JRC"
  //           ? "EU JRC **"
  //           : "EU JRC", //"EU JRC",
  //       score: score,
  //     ));
  //   }
  //
  //   // if (hazardDetails.others!.containsKey("MarshMcLennan")) {
  //   //   var mainValue = hazardDetails.others!["MarshMcLennan"]!.value;
  //   //   vendorDataWidgets.add(_buildVendorDataWidget(
  //   //     key: "Flood Risk Score2",
  //   //     value: _formatNumber(mainValue, decimalPlaces: 1),
  //   //     vendorName: "MarshMcLennan",
  //   //     score: score,
  //   //   ));
  //   // }
  //
  //   // **USGS Risk Index**
  //   if (hazardDetails.others!.containsKey("USGS")) {
  //     var mainValue = hazardDetails.others!["USGS"]!.value.toString();
  //     String formattedValue = _formatUSGSValue(mainValue);
  //     vendorDataWidgets.add(_buildVendorDataWidget(
  //       key: "Risk Index",
  //       value: formattedValue,
  //       vendorName: hazardDetails.vendorName.toString() == "USGS"
  //           ? "USGS **"
  //           : "USGS", //"USGS",
  //       score: score,
  //     ));
  //   }
  //
  //   return Container(
  //     width: double.infinity,
  //     height: double.infinity,
  //     color: _getColorForRating(context, score),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       mainAxisAlignment: MainAxisAlignment.center,
  //       children: vendorDataWidgets,
  //     ),
  //   );
  // }
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
          10,
          widget.accountID,
          widget.subAccountID,
          widget.initialProcessId,
          widget.initialSubProcessId,
          '');
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
          10,
          widget.accountID,
          widget.subAccountID,
          widget.initialProcessId,
          widget.initialSubProcessId,
          '');
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
  Widget _getLiveUI() {
    num _toNum(dynamic v) {
      if (v is num) return v;
      if (v is String) return num.tryParse(v) ?? 0;
      return 0;
    }

    final stream = _combinedStream;
    if (stream == null) return const SizedBox.shrink();

    // static locals to persist across rebuilds
    // (avoids adding new state fields outside this range)
    // ignore: prefer_final_locals
    String? _lastHeatmapStatusLocal;

    return StreamBuilder<Map<String, dynamic>>(
      key: ValueKey('${widget.accountID}-${widget.subAccountID}'),
      stream: stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final data = snapshot.data!;
        final heatmapStatus = (data['heatmapData']?['heatmap_status'] ?? '')
            .toString()
            .toLowerCase();
        final newStatus =
            (data['processData']?['status'] ?? '').toString().toLowerCase();

        // Progress derivation (defensive)
        final num totalCompletedRaw = _toNum(data['processData']
                ?['total_processes_completed'] ??
            data['processData']?['completed']);
        final num totalProcessesRaw = _toNum(data['processData']
                ?['total_processes'] ??
            data['processData']?['total']);
        // final num totalCompletedRaw = (data['processData']
        //         ?['total_processes_completed'] ??
        //     data['processData']?['completed'] ??
        //     0) as num;
        // final num totalProcessesRaw = (data['processData']
        //         ?['total_processes'] ??
        //     data['processData']?['total'] ??
        //     1) as num;
        final bool isProcessing = newStatus == 'processing';
        final double progressPct = totalProcessesRaw > 0
            ? (totalCompletedRaw / totalProcessesRaw) * 100
            : 0.0;
        final bool forceCompleted = isProcessing && progressPct >= 99.5;

        final bool isCompleted = newStatus == 'completed' || forceCompleted;
        final bool isFailed = newStatus == 'failed' || newStatus == 'error';

        // final bool isProcessing = newStatus == 'processing';

        // final bool isCompleted =
        //     newStatus.toLowerCase() == 'completed' || forceCompleted;
        // final bool isFailed = newStatus.toLowerCase() == 'failed' ||
        //     newStatus.toLowerCase() == 'error';

        // Defer side-effects to post-frame to avoid losing the final snapshot rebuild.
        if (newStatus != _lastProcessStatus) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _lastProcessStatus = newStatus;
            _onProcessStatusChange(newStatus);
          });
        }

        if (heatmapStatus != _lastHeatmapStatusLocal) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context
                .read<MyLocationListProvider>()
                .setHeatmapGeneratingLive(heatmapStatus == 'initiated');
            _lastHeatmapStatusLocal = heatmapStatus;
          });
        }

        return Column(
          children: [
            // Text(isProcessing.toString()),
            // Debug / status text (remove if not needed)
            // Text(
            //   isCompleted
            //       ? 'completed'
            //       : isFailed
            //           ? newStatus
            //           : isProcessing
            //               ? 'processing ${(forceCompleted ? 100 : progressPct).toStringAsFixed(0)}%'
            //               : newStatus,
            // ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Builder(
                key: ValueKey(newStatus), // 👈 ensures widget refreshes
                builder: (_) {
                  if (isFailed) return const SizedBox.shrink();
                  if (isCompleted) return _CompletedRow(data);
                  if (isProcessing) return _ProcessingRow(data);
                  // if (heatmapStatus == 'initiated') return _HeatmapRow();
                  return const SizedBox.shrink();
                },
              ),
            ),
            // AnimatedSwitcher(
            //   duration: const Duration(milliseconds: 250),
            //   child: () {
            //     if (isFailed) return const SizedBox.shrink();
            //     if (isCompleted) return _CompletedRow(data);
            //     if (isProcessing) return _ProcessingRow(data);
            //     if (heatmapStatus == 'initiated') return _HeatmapRow();
            //     return const SizedBox.shrink();
            //   }(),
            // ),
          ],
        );
      },
    );
  }

  // Widget _getLiveUI() {
  //   final stream = _combinedStream; // local alias
  //   if (stream == null) return const SizedBox.shrink();
  //
  //   return StreamBuilder<Map<String, dynamic>>(
  //     key: ValueKey('${widget.accountID}-${widget.subAccountID}'),
  //     stream: stream,
  //     builder: (context, snapshot) {
  //       if (!snapshot.hasData) return const SizedBox.shrink();
  //       final data = snapshot.data!;
  //       final heatmapStatus = (data['heatmapData']?['heatmap_status'] ?? '')
  //           .toString()
  //           .toLowerCase();
  //       final newStatus =
  //           (data['processData']?['status'] ?? '').toString().toLowerCase();
  //       final isProcessing = newStatus == 'processing';
  //
  //       // 🔒 Side-effects outside of provider/consumer loop
  //       if (newStatus != _lastProcessStatus) {
  //         _lastProcessStatus = newStatus;
  //         _onProcessStatusChange(newStatus);
  //       }
  //
  //
  //       context
  //           .read<MyLocationListProvider>()
  //           .setHeatmapGeneratingLive(heatmapStatus == 'initiated');
  //
  //       // … render UI only (no timers, no provider updates, no getdata here) …
  //       return Column(
  //         children: [
  //           Text(newStatus.toString()),
  //           AnimatedSwitcher(
  //             duration: const Duration(milliseconds: 250),
  //             child: () {
  //               if (isProcessing) return _ProcessingRow(data);
  //               if (newStatus == 'completed') return _CompletedRow(data);
  //               if (newStatus == 'failed' || newStatus == 'error') return Container();
  //               if (heatmapStatus == 'initiated') return _HeatmapRow();
  //               // Fallback if an unexpected / stale state occurs
  //               return const SizedBox.shrink();
  //             }(),
  //           ),
  //           // AnimatedSwitcher(
  //           //   duration: const Duration(milliseconds: 250),
  //           //   child: isProcessing
  //           //       ? _ProcessingRow(data)
  //           //       : newStatus == 'completed'
  //           //           ? _CompletedRow(data) // ✅ show 100% or "done"
  //           //           : heatmapStatus == 'initiated'
  //           //               ? _HeatmapRow()
  //           //               : const SizedBox.shrink(),
  //           // ),
  //         ],
  //       );
  //     },
  //   );
  // }

  Widget _CompletedRow(Map<String, dynamic> data) {
    final percentage = data['processData']?['progress'] ?? 100;
    return _AutoHideCompletedRow(percentage: percentage);
  }

  Widget _ProcessingRow(Map<String, dynamic> data) {
    final typography = CustomTypography(context);

    // ✅ Safely handle list and index
    final List<dynamic> activeProcesses = data['activeProcesses'] ?? [];
    final int totalProcessesCount = activeProcesses.length;
    int currentIndex = (data['currentProcessIndex'] ?? 0) as int;

    // Clamp index safely
    currentIndex = currentIndex.clamp(
        0, totalProcessesCount == 0 ? 0 : totalProcessesCount - 1);

    // ✅ Defensive conversion for numbers (avoids int/double/null issues)
    num _toNum(dynamic v) {
      if (v is num) return v;
      if (v is String) return num.tryParse(v) ?? 0;
      return 0;
    }

    final num totalCompleted =
        _toNum(data['processData']?['total_processes_completed']);
    final num totalProcesses =
        _toNum(data['processData']?['total_processes'] ?? 1);
    final double percentage =
        totalProcesses > 0 ? (totalCompleted / totalProcesses) * 100 : 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProcessMonitoringScreen(
              accountId: widget.accountID,
              subAccountId: widget.subAccountID,
            ),
          ),
        ).then((_) {
          // Safe refresh after returning
          getdata(widget.accountID!, widget.subAccountID!);
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/lottie/loading.json',
              width: 20,
              height: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Processing ${percentage.toStringAsFixed(0)}%',
              style: typography.Caption.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.blue,
              ),
            ),

            // ✅ Show navigation only if there are multiple processes
            if (totalProcessesCount > 1) ...[
              const SizedBox(width: 12),
              InkWell(
                child: Icon(
                  Icons.arrow_back_ios,
                  size: 18,
                  color: currentIndex > 0 ? Colors.white : Colors.grey,
                ),
                onTap: currentIndex > 0
                    ? () {
                        setState(() {
                          _currentProcessIndex = (currentIndex - 1)
                              .clamp(0, totalProcessesCount - 1);
                        });
                        _processIndex$.add(_currentProcessIndex);
                      }
                    : null,
              ),
            ],

            const SizedBox(width: 5),

            // ✅ Safe index display (prevents 2/1 issue)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.lightBlue[500],
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                "${(currentIndex.clamp(0, totalProcessesCount - 1) + 1)}/${totalProcessesCount}",
                style: typography.Caption?.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            if (totalProcessesCount > 1) ...[
              InkWell(
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 18,
                  color: currentIndex < totalProcessesCount - 1
                      ? Colors.white
                      : Colors.grey,
                ),
                onTap: currentIndex < totalProcessesCount - 1
                    ? () {
                        setState(() {
                          _currentProcessIndex = (currentIndex + 1)
                              .clamp(0, totalProcessesCount - 1);
                        });
                        _processIndex$.add(_currentProcessIndex);
                      }
                    : null,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Widget _ProcessingRow(Map<String, dynamic> data) {
  //   final typography = CustomTypography(context);
  //   final activeProcesses = data['activeProcesses'] ?? [];
  //   final currentIndex = data['currentProcessIndex'] ?? 0;
  //   final totalCompleted =
  //       data['processData']?['total_processes_completed'] ?? 0;
  //   final totalProcesses = data['processData']?['total_processes'] ?? 1;
  //   final percentage = (totalCompleted / totalProcesses) * 100;
  //
  //   return GestureDetector(
  //     onTap: () {
  //       Navigator.push(
  //         context,
  //         MaterialPageRoute(
  //           builder: (context) => ProcessMonitoringScreen(
  //             accountId: widget.accountID,
  //             subAccountId: widget.subAccountID,
  //           ),
  //         ),
  //       ).then((_) {
  //         // safe refresh after returning
  //         getdata(widget.accountID!, widget.subAccountID!);
  //       });
  //     },
  //     child: Padding(
  //       padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
  //       child: Row(
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         children: [
  //           Lottie.asset(
  //             'assets/lottie/loading.json',
  //             width: 20,
  //             height: 20,
  //           ),
  //           const SizedBox(width: 8),
  //           Text(
  //             'Processing ${percentage.toStringAsFixed(0)}%',
  //             style: typography.Caption.copyWith(
  //               fontWeight: FontWeight.w600,
  //               color: Colors.blue,
  //             ),
  //           ),
  //
  //           // ✅ Only show arrows if there are multiple processes
  //           if (activeProcesses.length > 1) ...[
  //             const SizedBox(width: 12),
  //             InkWell(
  //               child: Icon(
  //                 Icons.arrow_back_ios,
  //                 size: 18,
  //                 color: _currentProcessIndex > 0 ? Colors.white : Colors.grey,
  //               ),
  //               onTap: _currentProcessIndex > 0
  //                   ? () {
  //                 setState(() {
  //                   _currentProcessIndex =
  //                       (_currentProcessIndex - 1).clamp(0, activeProcesses.length - 1);
  //                 });
  //                 _processIndex$.add(_currentProcessIndex);
  //               }
  //                   : null,
  //             ),
  //           ],
  //
  //           const SizedBox(width: 5),
  //
  //           // ✅ Safe index display (prevents 2/1 issue)
  //           Container(
  //             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  //             decoration: BoxDecoration(
  //               color: Colors.lightBlue[500],
  //               borderRadius: BorderRadius.circular(7),
  //             ),
  //             child: Text(
  //               "${(_currentProcessIndex.clamp(0, activeProcesses.length - 1) + 1)}/${activeProcesses.length}",
  //               style: typography.Caption?.copyWith(
  //                 color: Colors.black,
  //                 fontWeight: FontWeight.w500,
  //               ),
  //             ),
  //           ),
  //
  //           if (activeProcesses.length > 1) ...[
  //             InkWell(
  //               child: Icon(
  //                 Icons.arrow_forward_ios,
  //                 size: 18,
  //                 color: _currentProcessIndex < activeProcesses.length - 1
  //                     ? Colors.white
  //                     : Colors.grey,
  //               ),
  //               onTap: _currentProcessIndex < activeProcesses.length - 1
  //                   ? () {
  //                 setState(() {
  //                   _currentProcessIndex =
  //                       (_currentProcessIndex + 1).clamp(0, activeProcesses.length - 1);
  //                 });
  //                 _processIndex$.add(_currentProcessIndex);
  //               }
  //                   : null,
  //             ),
  //           ],
  //         ],
  //       ),
  //
  //       // child: Row(
  //       //   mainAxisAlignment: MainAxisAlignment.center,
  //       //   children: [
  //       //     Lottie.asset(
  //       //       'assets/lottie/loading.json',
  //       //       width: 20,
  //       //       height: 20,
  //       //     ),
  //       //     const SizedBox(width: 8),
  //       //     Text(
  //       //       'Processing ${percentage.toStringAsFixed(0)} %',
  //       //       style: typography.Caption.copyWith(
  //       //         fontWeight: FontWeight.w600,
  //       //         color: Colors.blue,
  //       //       ),
  //       //     ),
  //       //     if (activeProcesses.length > 1) ...[
  //       //       const SizedBox(width: 12),
  //       //       InkWell(
  //       //         child: Icon(
  //       //           Icons.arrow_back_ios,
  //       //           size: 18,
  //       //           color: _currentProcessIndex > 0 ? Colors.white : Colors.grey,
  //       //         ),
  //       //         onTap: _currentProcessIndex > 0
  //       //             ? () {
  //       //                 setState(() {
  //       //                   _currentProcessIndex = (_currentProcessIndex - 1)
  //       //                       .clamp(0, activeProcesses.length - 1)
  //       //                       .toInt();
  //       //                 });
  //       //                 _processIndex$.add(
  //       //                     _currentProcessIndex); // 👈 switch inner stream now
  //       //               }
  //       //             : null,
  //       //         // onTap: _currentProcessIndex > 0
  //       //         //     ? () => setState(() {
  //       //         //           _currentProcessIndex = (_currentProcessIndex - 1)
  //       //         //               .clamp(0, activeProcesses.length - 1)
  //       //         //               .toInt();
  //       //         //         })
  //       //         //     : null,
  //       //       ),
  //       //     ],
  //       //     const SizedBox(width: 5),
  //       //     Container(
  //       //       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  //       //       decoration: BoxDecoration(
  //       //         color: Colors.lightBlue[500],
  //       //         // background color (adjust as needed)
  //       //         borderRadius: BorderRadius.circular(7), // rounded corners
  //       //       ),
  //       //       child: Text(
  //       //         "${_currentProcessIndex + 1}/${activeProcesses.length}",
  //       //         style: typography.Caption?.copyWith(
  //       //           color: Colors.black, // text color (adjust if needed)
  //       //           fontWeight: FontWeight.w500,
  //       //         ),
  //       //       ),
  //       //     ),
  //       //     if (activeProcesses.length > 1) ...[
  //       //       InkWell(
  //       //         child: Icon(
  //       //           Icons.arrow_forward_ios,
  //       //           size: 18,
  //       //           color: _currentProcessIndex < activeProcesses.length - 1
  //       //               ? Colors.white
  //       //               : Colors.grey,
  //       //         ),
  //       //         onTap: _currentProcessIndex < activeProcesses.length - 1
  //       //             ? () {
  //       //                 setState(() {
  //       //                   _currentProcessIndex = (_currentProcessIndex + 1)
  //       //                       .clamp(0, activeProcesses.length - 1)
  //       //                       .toInt();
  //       //                 });
  //       //                 _processIndex$.add(
  //       //                     _currentProcessIndex); // 👈 switch inner stream now
  //       //               }
  //       //             : null,
  //       //         // onTap: _currentProcessIndex < activeProcesses.length - 1
  //       //         //     ? () => setState(() {
  //       //         //           _currentProcessIndex = (_currentProcessIndex + 1)
  //       //         //               .clamp(0, activeProcesses.length - 1)
  //       //         //               .toInt();
  //       //         //         })
  //       //         //     : null,
  //       //       ),
  //       //     ],
  //       //   ],
  //       // ),
  //     ),
  //   );
  // }

  Widget _HeatmapRow() {
    final typography = CustomTypography(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/lottie/loading.json',
            width: 20,
            height: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Generating Heatmap',
            style: typography.Caption.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  void _onProcessStatusChange(String status) {
    if (!mounted || _isDisposed) return;
    final key = '${widget.accountID}/${widget.subAccountID}';

    if (status == 'processing') {
      // start a single keyed timer
      if (_activeAccountKey != key) {
        _refreshTimer?.cancel();
        _activeAccountKey = key;
        _startRefreshTimer(widget.accountID!, widget.subAccountID!);
      } else if (!(_refreshTimer?.isActive ?? false)) {
        _startRefreshTimer(widget.accountID!, widget.subAccountID!);
      }
    } else {
      _refreshTimer?.cancel();
      _activeAccountKey = null;
      // safe follow-up fetch, not inside build
      Future.microtask(() {
        if (!mounted || _isDisposed) return;
        getdata(widget.accountID!, widget.subAccountID!);
      });
    }
  }

  void _startRefreshTimer(String accountId, String subAccountId) {
    final key = '$accountId/$subAccountId';
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 20), (_) async {
      if (!mounted || _isDisposed) return;
      if (_activeAccountKey != key) return; // don't leak across pages
      await context
          .read<MyLocationListProvider>()
          .fetchLocationConflictList(
            context,
            "",
            1,
            20,
            widget.accountID,
            widget.subAccountID,
            widget.initialProcessId,
            widget.initialSubProcessId,
          )
          .then((_) => setState(() {}));
      await context.read<MyLocationListProvider>().fetchLocationList(
          context,
          locationQuery,
          1,
          8,
          accountId,
          subAccountId,
          widget.initialProcessId,
          widget.initialSubProcessId,
          '');
      setState(() {
        _buildCombinedStream(); // rebuild the stream
      });
    });
  }

  // void _onProcessStatusChange(String status) {
  //   if (!mounted || _isDisposed) return;
  //   final key = '${widget.accountID}/${widget.subAccountID}';
  //
  //   if (status == 'processing') {
  //     // start a single keyed timer
  //     if (_activeAccountKey != key) {
  //       _refreshTimer?.cancel();
  //       _activeAccountKey = key;
  //       _startRefreshTimer(widget.accountID!, widget.subAccountID!);
  //     } else if (!(_refreshTimer?.isActive ?? false)) {
  //       _startRefreshTimer(widget.accountID!, widget.subAccountID!);
  //     }
  //   } else {
  //     _refreshTimer?.cancel();
  //     _activeAccountKey = null;
  //     // safe follow-up fetch, not inside build
  //     Future.microtask(() {
  //       if (!mounted || _isDisposed) return;
  //       getdata(widget.accountID!, widget.subAccountID!);
  //     });
  //   }
  // }
  //
  // void _startRefreshTimer(String accountId, String subAccountId) {
  //   final key = '$accountId/$subAccountId';
  //   _refreshTimer?.cancel();
  //   _refreshTimer = Timer.periodic(const Duration(seconds: 20), (_) async {
  //     if (!mounted || _isDisposed) return;
  //     if (_activeAccountKey != key) return; // don't leak across pages
  //     await context.read<MyLocationListProvider>().fetchLocationList(
  //           context,
  //           locationQuery,
  //           1,
  //           8,
  //           accountId,
  //           subAccountId,
  //           widget.initialProcessId,
  //           widget.initialSubProcessId,
  //         );
  //   });
  // }

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
  //         return const SizedBox.shrink();
  //       }
  //
  //       if (snapshot.hasError || !snapshot.hasData) {
  //         return const SizedBox.shrink();
  //       }
  //
  //       final data = snapshot.data!;
  //       final heatmapStatus = data['heatmapData']?['heatmap_status'] ?? '';
  //       final processStatus = data['processData']?['status'] ?? '';
  //
  //       final bool isCurrentlyProcessing =
  //           processStatus.toLowerCase() == 'processing';
  //       final String newProcessStatus = data['processData']?['status'] ?? '';
  //
  //       final jobProvider =
  //           Provider.of<JobMonitoringProvider>(context, listen: false);
  //
  //       // 🔹 Update provider only when process status changes
  //       if (!_isDisposed && jobProvider.processStatus != newProcessStatus) {
  //         WidgetsBinding.instance.addPostFrameCallback((_) {
  //           if (!_isDisposed) {
  //             jobProvider.updateProcessStatus(newProcessStatus);
  //
  //             if (isCurrentlyProcessing) {
  //               setState(() {
  //                 isUploadInProgress = false;
  //               });
  //               // ✅ Start refresh timer only if not already running
  //               if (_refreshTimer == null || !_refreshTimer!.isActive) {
  //                 _startRefreshTimer(widget.accountID!, widget.subAccountID!);
  //               }
  //             } else {
  //               // ✅ Cancel timer when processing stops
  //               _refreshTimer?.cancel();
  //               _activeAccountKey = null;
  //
  //               // ✅ Call getdata safely (not on every rebuild)
  //               Future.microtask(() {
  //                 if (!_isDisposed) {
  //                   getdata(widget.accountID!, widget.subAccountID!);
  //                 }
  //               });
  //             }
  //           }
  //         });
  //       }
  //
  //       final locationProvider =
  //           Provider.of<MyLocationListProvider>(context, listen: false);
  //       locationProvider.isHeatMapGeneratingLive =
  //           heatmapStatus.toString().toLowerCase() == 'initiated';
  //
  //       final int totalCompleted =
  //           data['processData']?['total_processes_completed'] ?? 0;
  //       final int totalProcesses = data['processData']?['total_processes'] ?? 1;
  //       final double percentage = (totalCompleted / totalProcesses) * 100;
  //
  //       final List activeProcesses = data['activeProcesses'] ?? [];
  //       final int currentIndex = data['currentProcessIndex'] ?? 0;
  //
  //       return AnimatedSwitcher(
  //         duration: const Duration(milliseconds: 250),
  //         child: Column(
  //           key: ValueKey('$processStatus-$heatmapStatus'),
  //           crossAxisAlignment: CrossAxisAlignment.center,
  //           mainAxisAlignment: MainAxisAlignment.center,
  //           children: [
  //             if (activeProcesses.isNotEmpty)
  //               Row(
  //                 mainAxisAlignment: MainAxisAlignment.center,
  //                 children: [],
  //               ),
  //             const SizedBox(height: 8),
  //             if (isCurrentlyProcessing)
  //               GestureDetector(
  //                 onTap: () {
  //                   Navigator.push(
  //                     context,
  //                     MaterialPageRoute(
  //                       builder: (context) => ProcessMonitoringScreen(
  //                         accountId: widget.accountID,
  //                         subAccountId: widget.subAccountID,
  //                       ),
  //                     ),
  //                   ).then((_) {
  //                     // ✅ Refresh only after navigation completes
  //                     getdata(widget.accountID!, widget.subAccountID!);
  //                   });
  //                 },
  //                 child: Padding(
  //                   padding: const EdgeInsets.symmetric(horizontal: 16.0),
  //                   child: Row(
  //                     mainAxisAlignment: MainAxisAlignment.center,
  //                     children: [
  //                       Lottie.asset(
  //                         'assets/lottie/loading.json',
  //                         width: 20,
  //                         height: 20,
  //                       ),
  //                       const SizedBox(width: 8.0),
  //                       Text(
  //                         'Processing ${percentage.toStringAsFixed(0)} %',
  //                         style: typography.Caption.copyWith(
  //                           fontWeight: FontWeight.w600,
  //                           color: Colors.blue,
  //                         ),
  //                       ),
  //                       if (activeProcesses.length > 1) ...[
  //                         const SizedBox(width: 12.0),
  //                         InkWell(
  //                           onTap: _currentProcessIndex > 0
  //                               ? () {
  //                                   setState(() {
  //                                     _currentProcessIndex =
  //                                         (_currentProcessIndex - 1).clamp(
  //                                             0, activeProcesses.length - 1);
  //                                   });
  //                                 }
  //                               : null,
  //                           child: Icon(
  //                             Icons.arrow_back_ios_new,
  //                             size: 18,
  //                             color: _currentProcessIndex > 0
  //                                 ? Colors.white
  //                                 : Colors.grey,
  //                           ),
  //                         ),
  //                         const SizedBox(width: 10),
  //                         Container(
  //                           padding: const EdgeInsets.symmetric(
  //                               horizontal: 8, vertical: 3),
  //                           decoration: BoxDecoration(
  //                             color: Colors.blue.shade200,
  //                             borderRadius: BorderRadius.circular(8),
  //                           ),
  //                           child: Text(
  //                             "${_currentProcessIndex + 1}/${activeProcesses.length}",
  //                             style: typography.Caption.copyWith(
  //                               fontWeight: FontWeight.w500,
  //                               color: Colors.black,
  //                             ),
  //                           ),
  //                         ),
  //                         const SizedBox(width: 10),
  //                         InkWell(
  //                           onTap: _currentProcessIndex <
  //                                   activeProcesses.length - 1
  //                               ? () {
  //                                   setState(() {
  //                                     _currentProcessIndex =
  //                                         (_currentProcessIndex + 1).clamp(
  //                                             0, activeProcesses.length - 1);
  //                                   });
  //                                 }
  //                               : null,
  //                           child: Icon(
  //                             Icons.arrow_forward_ios,
  //                             size: 18,
  //                             color: _currentProcessIndex <
  //                                     activeProcesses.length - 1
  //                                 ? Colors.white
  //                                 : Colors.grey,
  //                           ),
  //                         ),
  //                       ],
  //                     ],
  //                   ),
  //                 ),
  //               )
  //             else if (heatmapStatus.toString().toLowerCase() == 'initiated')
  //               Padding(
  //                 padding: const EdgeInsets.symmetric(horizontal: 16.0),
  //                 child: Row(
  //                   mainAxisAlignment: MainAxisAlignment.center,
  //                   children: [
  //                     Lottie.asset(
  //                       'assets/lottie/loading.json',
  //                       width: 20,
  //                       height: 20,
  //                     ),
  //                     const SizedBox(width: 8.0),
  //                     Text(
  //                       'Generating Heatmap',
  //                       style: typography.Caption.copyWith(
  //                         fontWeight: FontWeight.w500,
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //           ],
  //         ),
  //       );
  //     },
  //   );
  // }

// // 🔹 Live UI-2
//   Widget _getLiveUI(JobMonitoringProvider provider) {
//     var typography = CustomTypography(context);
//     FirebaseAuth auth = FirebaseAuth.instance;
//     String uid = auth.currentUser!.uid;
//
//     final combinedStream = _createLiveProcessStream(
//       userId: uid,
//       accountId: widget.accountID!,
//       subAccountId: widget.subAccountID!,
//     );
//
//     return StreamBuilder<Map<String, dynamic>>(
//       stream: combinedStream,
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting &&
//             !snapshot.hasData) {
//           return const SizedBox.shrink();
//         }
//
//         if (snapshot.hasError || !snapshot.hasData) {
//           return const SizedBox.shrink();
//         }
//
//         final data = snapshot.data!;
//         final heatmapStatus = data['heatmapData']?['heatmap_status'] ?? '';
//         final processStatus = data['processData']?['status'] ?? '';
//
//         final bool isCurrentlyProcessing =
//             processStatus.toLowerCase() == 'processing';
//         final String newProcessStatus = data['processData']?['status'] ?? '';
//
//         final jobProvider =
//         Provider.of<JobMonitoringProvider>(context, listen: false);
//
//         // ✅ Timer tied to current account + subaccount
//         _startRefreshTimer(widget.accountID!, widget.subAccountID!);
//
//         if (!_isDisposed && jobProvider.processStatus != newProcessStatus) {
//           WidgetsBinding.instance.addPostFrameCallback((_) {
//             if (!_isDisposed) {
//               jobProvider.updateProcessStatus(newProcessStatus);
//
//               if (isCurrentlyProcessing) {
//                 setState(() {
//                   isUploadInProgress = false;
//                 });
//                 _startRefreshTimer(widget.accountID!, widget.subAccountID!);
//               } else {
//                 _refreshTimer?.cancel();
//                 _activeAccountKey = null;
//                 getdata(widget.accountID!,widget.subAccountID!);
//               }
//             }
//           });
//         }
//
//         final locationProvider =
//         Provider.of<MyLocationListProvider>(context, listen: false);
//         locationProvider.isHeatMapGeneratingLive =
//             heatmapStatus.toString().toLowerCase() == 'initiated';
//
//         final int totalCompleted =
//             data['processData']?['total_processes_completed'] ?? 0;
//         final int totalProcesses = data['processData']?['total_processes'] ?? 1;
//         final double percentage = (totalCompleted / totalProcesses) * 100;
//
//         final List activeProcesses = data['activeProcesses'] ?? [];
//         final int currentIndex = data['currentProcessIndex'] ?? 0;
//
//         return AnimatedSwitcher(
//           duration: const Duration(milliseconds: 250),
//           child: Column(
//             key: ValueKey('$processStatus-$heatmapStatus'),
//             crossAxisAlignment: CrossAxisAlignment.center,
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               // 🔹 Navigation arrows if multiple processes
//               if (activeProcesses.isNotEmpty)
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [],
//                 ),
//               const SizedBox(height: 8),
//               if (isCurrentlyProcessing)
//                 GestureDetector(
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => ProcessMonitoringScreen(
//                           accountId: widget.accountID,
//                           subAccountId: widget.subAccountID,
//                         ),
//                       ),
//                     ).then((value) => getdata(widget.accountID!, widget.subAccountID!));
//                   },
//                   child: Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 16.0),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         // 🔄 Loader
//                         Lottie.asset(
//                           'assets/lottie/loading.json',
//                           width: 20,
//                           height: 20,
//                         ),
//                         const SizedBox(width: 8.0),
//
//                         // 📊 Processing %
//                         Text(
//                           'Processing ${percentage.toStringAsFixed(0)} %',
//                           style: typography.Caption.copyWith(
//                             fontWeight: FontWeight.w600,
//                             color: Colors.blue,
//                           ),
//                         ),
//
//                         if (activeProcesses.length > 1) ...[
//                           const SizedBox(width: 12.0),
//                           InkWell(
//                             onTap: _currentProcessIndex > 0
//                                 ? () {
//                               setState(() {
//                                 _currentProcessIndex =
//                                     (_currentProcessIndex - 1).clamp(
//                                         0, activeProcesses.length - 1);
//                               });
//                             }
//                                 : null,
//                             child: Icon(
//                               Icons.arrow_back_ios_new,
//                               size: 18,
//                               color: _currentProcessIndex > 0
//                                   ? Colors.white
//                                   : Colors.grey,
//                             ),
//                           ),
//                           const SizedBox(width: 10),
//                           Container(
//                             padding: const EdgeInsets.symmetric(
//                                 horizontal: 8, vertical: 3),
//                             decoration: BoxDecoration(
//                               color: Colors.blue.shade200,
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                             child: Text(
//                               "${_currentProcessIndex + 1}/${activeProcesses.length}",
//                               style: typography.Caption.copyWith(
//                                 fontWeight: FontWeight.w500,
//                                 color: Colors.black,
//                               ),
//                             ),
//                           ),
//                           const SizedBox(width: 10),
//                           InkWell(
//                             onTap: _currentProcessIndex <
//                                 activeProcesses.length - 1
//                                 ? () {
//                               setState(() {
//                                 _currentProcessIndex =
//                                     (_currentProcessIndex + 1).clamp(
//                                         0, activeProcesses.length - 1);
//                               });
//                             }
//                                 : null,
//                             child: Icon(
//                               Icons.arrow_forward_ios,
//                               size: 18,
//                               color: _currentProcessIndex <
//                                   activeProcesses.length - 1
//                                   ? Colors.white
//                                   : Colors.grey,
//                             ),
//                           ),
//                         ],
//                       ],
//                     ),
//                   ),
//                 )
//               else if (heatmapStatus.toString().toLowerCase() == 'initiated')
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 16.0),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Lottie.asset(
//                         'assets/lottie/loading.json',
//                         width: 20,
//                         height: 20,
//                       ),
//                       const SizedBox(width: 8.0),
//                       Text(
//                         'Generating Heatmap',
//                         style: typography.Caption.copyWith(
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//             ],
//           ),
//         );
//       },
//     );
//   }

// 🔹 Live UI
//   Widget _getLiveUI(JobMonitoringProvider provider) {
//     var typography = CustomTypography(context);
//     FirebaseAuth auth = FirebaseAuth.instance;
//     String uid = auth.currentUser!.uid;
//
//     final combinedStream = _createLiveProcessStream(
//       userId: uid,
//       accountId: widget.accountID!,
//       subAccountId: widget.subAccountID!,
//     );
//
//     return StreamBuilder<Map<String, dynamic>>(
//       stream: combinedStream,
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting &&
//             !snapshot.hasData) {
//           return const SizedBox.shrink();
//         }
//
//         if (snapshot.hasError || !snapshot.hasData) {
//           return const SizedBox.shrink();
//         }
//
//         final data = snapshot.data!;
//         final heatmapStatus = data['heatmapData']?['heatmap_status'] ?? '';
//         final processStatus = data['processData']?['status'] ?? '';
//
//         final bool isCurrentlyProcessing =
//             processStatus.toLowerCase() == 'processing';
//         final String newProcessStatus = data['processData']?['status'] ?? '';
//
//         final jobProvider =
//             Provider.of<JobMonitoringProvider>(context, listen: false);
//         _startRefreshTimer();
//         if (!_isDisposed && jobProvider.processStatus != newProcessStatus) {
//           WidgetsBinding.instance.addPostFrameCallback((_) {
//             if (!_isDisposed) {
//               jobProvider.updateProcessStatus(newProcessStatus);
//
//               if (isCurrentlyProcessing) {
//                 setState(() {
//                   isUploadInProgress = false;
//                 });
//                 _startRefreshTimer();
//               } else {
//                 _refreshTimer?.cancel();
//                 _getData();
//               }
//             }
//           });
//         }
//
//         final locationProvider =
//             Provider.of<MyLocationListProvider>(context, listen: false);
//         locationProvider.isHeatMapGeneratingLive =
//             heatmapStatus.toString().toLowerCase() == 'initiated';
//
//         final int totalCompleted =
//             data['processData']?['total_processes_completed'] ?? 0;
//         final int totalProcesses = data['processData']?['total_processes'] ?? 1;
//         final double percentage = (totalCompleted / totalProcesses) * 100;
//
//         final List activeProcesses = data['activeProcesses'] ?? [];
//         final int currentIndex = data['currentProcessIndex'] ?? 0;
//
//         return AnimatedSwitcher(
//           duration: const Duration(milliseconds: 250),
//           child: Column(
//             key: ValueKey('$processStatus-$heatmapStatus'),
//             crossAxisAlignment: CrossAxisAlignment.center,
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               // 🔹 Counter + Navigation
//               if (activeProcesses.isNotEmpty)
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [],
//                 ),
//               const SizedBox(height: 8),
//               if (isCurrentlyProcessing)
//                 GestureDetector(
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => ProcessMonitoringScreen(
//                           accountId: widget.accountID,
//                           subAccountId: widget.subAccountID,
//                         ),
//                       ),
//                     ).then((value) => _getData());
//                   },
//                   child: Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 16.0),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         // 🔄 Loader
//                         Lottie.asset(
//                           'assets/lottie/loading.json',
//                           width: 20,
//                           height: 20,
//                         ),
//                         const SizedBox(width: 8.0),
//
//                         // 📊 Processing %
//                         Text(
//                           'Processing ${percentage.toStringAsFixed(0)} %',
//                           style: typography.Caption.copyWith(
//                             fontWeight: FontWeight.w600,
//                             color: Colors.blue, // blue like in screenshot
//                           ),
//                         ),
//                         // const SizedBox(width: 12.0),
//                         if (activeProcesses.length > 1) ...[
//                           InkWell(
//                             onTap: _currentProcessIndex > 0
//                                 ? () {
//                                     setState(() {
//                                       _currentProcessIndex =
//                                           (_currentProcessIndex - 1).clamp(
//                                               0, activeProcesses.length - 1);
//                                     });
//                                   }
//                                 : null,
//                             child: Icon(
//                               Icons.arrow_back_ios_new,
//                               size: 18,
//                               color: _currentProcessIndex > 0
//                                   ? Colors.white
//                                   : Colors.grey, // visually disabled
//                             ),
//                           ),],
//                           SizedBox(width: 10),
//                           Container(
//                             padding: const EdgeInsets.symmetric(
//                                 horizontal: 8, vertical: 3),
//                             decoration: BoxDecoration(
//                               color: Colors.blue.shade200,
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                             child: Text(
//                               "${_currentProcessIndex + 1}/${activeProcesses.length}",
//                               style: typography.Caption.copyWith(
//                                 fontWeight: FontWeight.w500,
//                                 color: Colors.black,
//                               ),
//                             ),
//                           ),
//                           SizedBox(width: 10),
//                         if (activeProcesses.length > 1) ...[
//                           InkWell(
//                             onTap: _currentProcessIndex <
//                                     activeProcesses.length - 1
//                                 ? () {
//                                     setState(() {
//                                       _currentProcessIndex =
//                                           (_currentProcessIndex + 1).clamp(
//                                               0, activeProcesses.length - 1);
//                                     });
//                                   }
//                                 : null,
//                             child: Icon(
//                               Icons.arrow_forward_ios,
//                               size: 18,
//                               color: _currentProcessIndex <
//                                       activeProcesses.length - 1
//                                   ? Colors.white
//                                   : Colors.grey, // visually disabled
//                             ),
//                           ),
//
//                         ],
//                       ],
//                     ),
//                   ),
//                 )
//               else if (heatmapStatus.toString().toLowerCase() == 'initiated')
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 16.0),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Lottie.asset(
//                         'assets/lottie/loading.json',
//                         width: 20,
//                         height: 20,
//                       ),
//                       const SizedBox(width: 8.0),
//                       Text(
//                         'Generating Heatmap',
//                         style: typography.Caption.copyWith(
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//             ],
//           ),
//         );
//       },
//     );
//   }

  // 🔹 Stream
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

      // Get raw on_going_processes
      final rawProcesses =
          (userData['on_going_processes'] as List<dynamic>? ?? [])
              .cast<Map<String, dynamic>>();

      // Filter for this account + subaccount
      final activeProcesses = rawProcesses.where((p) {
        return p['last_account'] == accountId &&
            p['last_sub_account'] == subAccountId;
      }).toList();

      // 🔹 Print counts
      print("📌 Total on_going_processes: ${rawProcesses.length}");
      print(
          "✅ Active processes for subAccount($subAccountId): ${activeProcesses.length}");
      for (var i = 0; i < activeProcesses.length; i++) {
        print(
            "   ➡️ Process ${i + 1}: ${activeProcesses[i]['last_process_id']}");
      }

      final heatmapData =
          subSnap.docs.isNotEmpty ? subSnap.docs.first.data() : {};

      if (activeProcesses.isNotEmpty) {
        // clamp index if out of range
        if (_currentProcessIndex >= activeProcesses.length) {
          _currentProcessIndex = 0;
        }

        final currentProcess = activeProcesses[_currentProcessIndex];
        final String? lastProcessId = currentProcess['last_process_id'];

        if (lastProcessId != null) {
          final processDocStream = FirebaseFirestore.instance
              .collection('processes')
              .where('process_id', isEqualTo: lastProcessId)
              .limit(1)
              .snapshots();

          return processDocStream.map((processSnap) {
            final processData = processSnap.docs.isNotEmpty
                ? processSnap.docs.first.data()
                : {};

            return {
              'processData': processData,
              'heatmapData': heatmapData,
              'activeProcesses': activeProcesses,
              'currentProcessIndex': _currentProcessIndex,
            };
          });
        }
      }

      // No process case
      return Stream.value({
        'processData': null,
        'heatmapData': heatmapData,
        'activeProcesses': activeProcesses,
        'currentProcessIndex': _currentProcessIndex,
      });
    }).switchMap((stream) => stream);
  }

//=> Single process
//   Widget _getLiveUI(JobMonitoringProvider provider) {
//     var typography = CustomTypography(context);
//     FirebaseAuth auth = FirebaseAuth.instance;
//     String uid = auth.currentUser!.uid;
//
//     final combinedStream = _createLiveProcessStream(
//       userId: uid,
//       accountId: widget.accountID!,
//       subAccountId: widget.subAccountID!,
//     );
//
//     return StreamBuilder<Map<String, dynamic>>(
//       stream: combinedStream,
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting &&
//             !snapshot.hasData) {
//           return SizedBox(
//             height: CustomSpacing.six,
//             child: Text(""),
//           );
//         }
//
//         if (snapshot.hasError || !snapshot.hasData) {
//           return SizedBox.shrink(
//             child: Text(""),
//           );
//         }
//
//         final data = snapshot.data!;
//         final heatmapStatus = data['heatmapData']?['heatmap_status'] ?? '';
//         final processStatus = data['processData']?['status'] ?? '';
//
//         final bool isCurrentlyProcessing =
//             processStatus.toLowerCase() == 'processing';
//         final String newProcessStatus = data['processData']?['status'] ?? '';
//
//         final jobProvider =
//             Provider.of<JobMonitoringProvider>(context, listen: false);
//         _startRefreshTimer();
//         if (!_isDisposed && jobProvider.processStatus != newProcessStatus) {
//           WidgetsBinding.instance.addPostFrameCallback((_) {
//             if (!_isDisposed) {
//               jobProvider.updateProcessStatus(newProcessStatus);
//
//               if (isCurrentlyProcessing) {
//                 setState(() {
//                   isUploadInProgress = false;
//                 });
//                 _startRefreshTimer();
//               } else {
//                 _refreshTimer?.cancel();
//                 _getData();
//               }
//             }
//           });
//         }
//
//         final locationProvider =
//             Provider.of<MyLocationListProvider>(context, listen: false);
//         locationProvider.isHeatMapGeneratingLive =
//             heatmapStatus.toString().toLowerCase() == 'initiated';
//
//         final int totalCompleted =
//             data['processData']?['total_processes_completed'] ?? 0;
//         final int totalProcesses = data['processData']?['total_processes'] ?? 1;
//         final double percentage = (totalCompleted / totalProcesses) * 100;
//
//         return AnimatedSwitcher(
//           duration: const Duration(milliseconds: 250),
//           child: Column(
//             key: ValueKey('$processStatus-$heatmapStatus'),
//             crossAxisAlignment: CrossAxisAlignment.center,
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Text(data['processData'].toString(),
//               // maxLines: 2,
//               //
//               ),
//               if (isCurrentlyProcessing)
//                 GestureDetector(
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => ProcessMonitoringScreen(
//                           accountId: widget.accountID,
//                           subAccountId: widget.subAccountID,
//                         ),
//                       ),
//                     ).then((value) => _getData());
//                   },
//                   child: Padding(
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
//                           'Processing ${percentage.toStringAsFixed(0)}%',
//                           style: typography.Caption.copyWith(
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 )
//               else if (heatmapStatus.toString().toLowerCase() == 'initiated')
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 16.0),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Lottie.asset(
//                         'assets/lottie/loading.json',
//                         width: 20,
//                         height: 20,
//                       ),
//                       const SizedBox(width: 8.0),
//                       Text(
//                         'Generating Heatmap',
//                         style: typography.Caption.copyWith(
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//             ],
//           ),
//         );
//       },
//     );
//   }
//
//   Stream<Map<String, dynamic>> _createLiveProcessStream({
//     required String userId,
//     required String accountId,
//     required String subAccountId,
//   }) {
//     final userStream =
//     FirebaseFirestore.instance.collection('users').doc(userId).snapshots();
//
//     final subaccountStream = FirebaseFirestore.instance
//         .collection('subaccount')
//         .where('sub_account_id', isEqualTo: subAccountId)
//         .snapshots();
//
//     return Rx.combineLatest2(userStream, subaccountStream,
//             (userSnap, subSnap) {
//           final userData = userSnap.data() as Map<String, dynamic>? ?? {};
//
//           // Get raw on_going_processes
//           final rawProcesses =
//           (userData['on_going_processes'] as List<dynamic>? ?? [])
//               .cast<Map<String, dynamic>>();
//
//           // Filter for this account + subaccount
//           final activeProcesses = rawProcesses.where((p) {
//             return p['last_account'] == accountId &&
//                 p['last_sub_account'] == subAccountId;
//           }).toList();
//
//           // 🔹 Print counts
//           print("📌 Total on_going_processes: ${rawProcesses.length}");
//           print("✅ Active processes for subAccount($subAccountId): ${activeProcesses.length}");
//           for (var i = 0; i < activeProcesses.length; i++) {
//             print("   ➡️ Process ${i + 1}: ${activeProcesses[i]['last_process_id']}");
//           }
//
//           final heatmapData =
//           subSnap.docs.isNotEmpty ? subSnap.docs.first.data() : {};
//
//           if (activeProcesses.isNotEmpty) {
//             final currentProcess = activeProcesses[_currentProcessIndex];
//             final String? lastProcessId = currentProcess['last_process_id'];
//
//             if (lastProcessId != null) {
//               final processDocStream = FirebaseFirestore.instance
//                   .collection('processes')
//                   .where('process_id', isEqualTo: lastProcessId)
//                   .limit(1)
//                   .snapshots();
//
//               return processDocStream.map((processSnap) {
//                 final processData = processSnap.docs.isNotEmpty
//                     ? processSnap.docs.first.data()
//                     : {};
//
//                 return {
//                   'processData': processData,
//                   'heatmapData': heatmapData,
//                   'activeProcesses': activeProcesses,
//                   'currentProcessIndex': _currentProcessIndex,
//                 };
//               });
//             }
//           }
//
//           // No process case
//           return Stream.value({
//             'processData': null,
//             'heatmapData': heatmapData,
//             'activeProcesses': activeProcesses,
//             'currentProcessIndex': _currentProcessIndex,
//           });
//         }).switchMap((stream) => stream);
//   }
// o/d above
//   Stream<Map<String, dynamic>> _createLiveProcessStream({
//     required String userId,
//     required String accountId,
//     required String subAccountId,
//   }) {
//     final userStream =
//         FirebaseFirestore.instance.collection('users').doc(userId).snapshots();
//
//     final subaccountStream = FirebaseFirestore.instance
//         .collection('subaccount')
//         .where('sub_account_id', isEqualTo: subAccountId)
//         .snapshots();
//
//     return Rx.combineLatest2(userStream, subaccountStream, (userSnap, subSnap) {
//       final userData = userSnap.data() as Map<String, dynamic>? ?? {};
//       final onGoingProcesses = userData['on_going_processes'] ?? [];
//       print("onGoingProcesses");
//       print("Count: ${onGoingProcesses.length}");
//       print("Count: ${onGoingProcesses}");
// print("onGoingProcesses");
//       final activeProcess = onGoingProcesses.firstWhere(
//         (p) =>
//             p['last_account'] == accountId &&
//             p['last_sub_account'] == subAccountId,
//         orElse: () => null,
//       );
//
//       final String? lastProcessId = activeProcess?['last_process_id'];
//
//       final heatmapData =
//           subSnap.docs.isNotEmpty ? subSnap.docs.first.data() : {};
//
//       if (lastProcessId != null) {
//         final processDocStream = FirebaseFirestore.instance
//             .collection('processes')
//             .where('process_id', isEqualTo: lastProcessId)
//             .limit(1)
//             .snapshots();
//
//         return processDocStream.map((processSnap) {
//           final processData =
//               processSnap.docs.isNotEmpty ? processSnap.docs.first.data() : {};
//
//           return {
//             'processData': processData,
//             'heatmapData': heatmapData,
//             'on_going_processes': onGoingProcesses,
//           };
//         });
//       }
//
//       return Stream.value({
//         'processData': null,
//         'heatmapData': heatmapData,
//         'on_going_processes': onGoingProcesses,
//       });
//     }).switchMap((stream) => stream); // flatten nested stream
//   }

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
      _startRefreshTimer(widget.accountID!, widget.subAccountID!);
    }
    // if (success) {
    //   _startRefreshTimer();
    //
    //
    // }
  }

  Future<List<Object?>> handleFetchConflict(bool conflictsCheck) async {
    final url = Uri.parse(
      '${AppConstant.HANDLE_CONFLICT}?page=0&pageSize=10'
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
        final conflictLocations = locationListProvider.myLocationConflictList
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
                                      10,
                                      widget.accountID,
                                      widget.subAccountID,
                                      widget.initialProcessId,
                                      widget.initialSubProcessId,
                                      '');
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
                                      10,
                                      widget.accountID,
                                      widget.subAccountID,
                                      widget.initialProcessId,
                                      widget.initialSubProcessId,
                                      '');
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
                                        10,
                                        widget.accountID,
                                        widget.subAccountID,
                                        widget.initialProcessId,
                                        widget.initialSubProcessId,
                                        '');
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
                                      8,
                                      widget.accountID,
                                      widget.subAccountID,
                                      widget.initialProcessId,
                                      widget.initialSubProcessId,
                                      '');
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
                              8,
                              widget.accountID,
                              widget.subAccountID,
                              widget.initialProcessId,
                              widget.initialSubProcessId,
                              '');
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
                        conflictLocations.length.toString() == "0"
                            ? Container()
                            : MessageCard(
                                messageTextSpans: [
                                  TextSpan(
                                    text:
                                        "We’ve found ${conflictLocations.length} potential matches for the provided location. Please review them and select the correct match to ",
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
                                            subAccountId:
                                                widget.subAccountID ?? "",
                                            sovId: "null",
                                            accountName:
                                                widget.accountName ?? "",
                                            subAccountName:
                                                widget.subAccountName ?? "",
                                            tempId: "tempId",
                                            lat: conflictLocations[0]
                                                .location
                                                .latitude
                                                .toString(),

                                            long: conflictLocations
                                                .first.location.longitude
                                                .toString(),
                                            geocodingAddress: conflictLocations
                                                    .first
                                                    .finalAddress
                                                    ?.address ??
                                                "",
                                            conflict: conflictLocations
                                                .first.conflicts,
                                            // Optional or just first one
                                            location: conflictLocations,

                                            startHazard: false,
                                          ),
                                        ))
                                            .then((value) {
                                          if (value == true) {
                                            _StartHazardConflict(
                                                conflictLocations:
                                                    conflictLocations);
                                            locationListProvider
                                                .fetchLocationList(
                                                    context,
                                                    locationQuery,
                                                    1,
                                                    1,
                                                    widget.accountID,
                                                    widget.subAccountID,
                                                    widget.initialProcessId,
                                                    widget.initialSubProcessId,
                                                    '');
                                            locationListProvider
                                                .fetchLocationConflictList(
                                                  context,
                                                  "",
                                                  1,
                                                  20,
                                                  widget.accountID,
                                                  widget.subAccountID,
                                                  widget.initialProcessId,
                                                  widget.initialSubProcessId,
                                                )
                                                .then((_) => setState(() {}));
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
                              locationListProvider
                                  .fetchLocationConflictList(
                                    context,
                                    "",
                                    1,
                                    3,
                                    widget.accountID,
                                    widget.subAccountID,
                                    widget.initialProcessId,
                                    widget.initialSubProcessId,
                                  )
                                  .then((_) => setState(() {})),
                              locationListProvider.fetchLocationList(
                                  context,
                                  locationQuery,
                                  1,
                                  8,
                                  widget.accountID,
                                  widget.subAccountID,
                                  widget.initialProcessId,
                                  widget.initialSubProcessId,
                                  ''),

                              // locationListProvider.fetchAllLocationList(
                              //   context,
                              //   widget.accountID,
                              //   widget.subAccountID,
                              //   processId: widget.initialProcessId,
                              //   subProcessId: widget.initialSubProcessId,
                              // ),
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
                                        companyName: locationListProvider
                                                .myLocationList[index]
                                                .finalAddress
                                                ?.companyName ??
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
                                        riskScore: int.tryParse(
                                                locationListProvider
                                                        .myLocationList[index]
                                                        .overallScore
                                                        ?.toString() ??
                                                    '') ??
                                            5,
                                        // riskScore: locationListProvider.myLocationList[index].overallScore == null
                                        //     ? 0
                                        //     : int.tryParse(locationListProvider.myLocationList[index].overallScore.toString()) ?? 0,
                                        dataCompletenessScore: int.parse(
                                            locationListProvider
                                                .myLocationList[index]
                                                .dataCompleteness!
                                                .scorePd
                                                .toString()),
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
                                                      8,
                                                      widget.accountID,
                                                      widget.subAccountID,
                                                      widget.initialProcessId,
                                                      widget
                                                          .initialSubProcessId,
                                                      '');

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
                                        getData: () {
                                          getdata(widget.accountID!,
                                              widget.subAccountID!);
                                        },
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
                                                  8,
                                                  widget.accountID,
                                                  widget.subAccountID,
                                                  widget.initialProcessId,
                                                  widget.initialSubProcessId,
                                                  '');
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
                                      8,
                                      // Page size
                                      widget.accountID,
                                      widget.subAccountID,
                                      widget.initialProcessId,
                                      widget.initialSubProcessId,
                                      '');
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
                                companyName: locationListProvider
                                        .myLocationList[index]
                                        .finalAddress
                                        ?.companyName ??
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
                                riskScore: int.tryParse(locationListProvider
                                            .myLocationList[index].overallScore
                                            ?.toString() ??
                                        '0') ??
                                    0,

                                // locationListProvider
                                //         .myLocationList[index].overallScore ??
                                //     0,
                                dataCompletenessScore: int.parse(
                                    locationListProvider.myLocationList[index]
                                        .dataCompleteness!.scorePd
                                        .toString()),

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
                                              8,
                                              widget.accountID,
                                              widget.subAccountID,
                                              widget.initialProcessId,
                                              widget.initialSubProcessId,
                                              '');

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
                                getData: () {
                                  getdata(
                                      widget.accountID!, widget.subAccountID!);
                                },
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
                                      5,
                                      widget.accountID,
                                      widget.subAccountID,
                                      widget.initialProcessId,
                                      widget.initialSubProcessId,
                                      '');
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
                            5,
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
                              5,
                              widget.accountID,
                              widget.subAccountID,
                              widget.initialProcessId,
                              widget.initialSubProcessId,
                            );
                            locationListProvider.fetchLocationList(
                                context,
                                locationQuery,
                                1,
                                8,
                                widget.accountID,
                                widget.subAccountID,
                                widget.initialProcessId,
                                widget.initialSubProcessId,
                                '');
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
      companyName: locationListProvider
              .certifiedLocationList[index].finalAddress?.companyName ??
          '',
      percentage: double.parse(locationListProvider
              .certifiedLocationList[index].finalAddress?.percent ??
          '0'),
      geocodingScore:
          locationListProvider.certifiedLocationList[index].geocodingScore ?? 0,
      riskScore: int.parse(locationListProvider
          .certifiedLocationList[index].overallScore
          .toString()),

      dataCompletenessScore: int.parse(locationListProvider
          .certifiedLocationList[index].dataCompleteness!.scorePd
          .toString()),
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
                    5,
                    widget.accountID,
                    widget.subAccountID,
                    widget.initialProcessId,
                    widget.initialSubProcessId,
                    '');

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
      getData: () {
        getdata(widget.accountID!, widget.subAccountID!);
      },
      onNavigateStart: () {
        _isDisposed = true;
        _refreshTimer?.cancel();
        deBouncer?.cancel();
      },

      onNavigateBack: () {
        _StartHazardConflict(conflictLocations: conflictLocations);
        locationListProvider.fetchLocationList(
            context,
            locationQuery,
            1,
            5,
            widget.accountID,
            widget.subAccountID,
            widget.initialProcessId,
            widget.initialSubProcessId,
            '');
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
                            // if (int.parse(hasHazardLicenseStatus.toString()) >=
                            //         1 &&
                            //     int.parse(hasHazardLicenseStatus.toString()) <=
                            //         10)
                            //   Text(
                            //     'The system will only process the first ${hasHazardLicenseStatus} locations.',
                            //     style: typography.Body1,
                            //   ),
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
                                onChanged: (trialStatus.isNotEmpty &&
                                        !hasAnyPlan)
                                    ? null // Disable checkbox if `areFieldsDisabled` is true
                                    : (bool? value) {
                                        setState(() {
                                          addToSOVCheck = !addToSOVCheck;
                                        });
                                      },
                                // onChanged: trialStatus.isNotEmpty
                                //     ? null
                                //     : (bool? value) {
                                //         setState(() {
                                //           addToSOVCheck = value ?? false;
                                //         });
                                //       },
                              ),
                              SizedBox(width: 8),
                              Text(
                                "Add to SoV",
                                style: typography.Body1,
                              ),
                              if (trialStatus.isNotEmpty && !hasAnyPlan)
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

                        if (int.parse(hasHazardLicenseStatus.toString()) >
                            0) ...[
                          Container(
                            padding: const EdgeInsets.only(left: 10),
                            child: Text(
                              "Available Locations: $hasHazardLicenseStatus",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                              ),
                            ),
                          )
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.only(left: 10),
                            child: const Text(
                              "No locations. Upgrade Now to create SOV!",
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],

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
                                                                        getdata(
                                                                            widget.accountID!,
                                                                            widget.accountID!);
                                                                        _getSovUploadStatus();
                                                                      });
                                                                    }
                                                                  });
                                                                } else {
                                                                  print(
                                                                      'Location Upload Failed: $success');
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

// ✅ Search API call
  void sovSearchClient(String query) async {
    debounce(() async {
      if (!mounted) return;

      setState(() => _sovQuery = query.trim());

      final provider = Provider.of<SOVListProvider>(context, listen: false);
      provider.page = 0;

      await provider.fetchSovList(
        context,
        widget.accountID!,
        widget.subAccountID!,
        _sovQuery,
        provider.page,
        10,
        selectedSov,
      );
    });
  }

  // void sovSearchClient(String query) async {
  //   debounce(() async {
  //     if (!mounted) return;
  //     _sovQuery = query;
  //     var provider = Provider.of<SOVListProvider>(context, listen: false);
  //     provider.page = 0;
  //     await provider.fetchSovList(context, widget.accountID!,
  //         widget.subAccountID!, _sovQuery, provider.page, 10, 'my');
  //   });
  // }

  String safeParseInt(dynamic value) {
    if (value == null) return "00";
    try {
      int parsed = int.parse(value.toString());
      return parsed.toString().padLeft(2, '0');
    } catch (e) {
      return "00";
    }
  }

  Widget sovBody(CustomTypography typography) {
    return Consumer<SOVListProvider>(builder: (context, sovListProvider, _) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ Show "Select All" only when any item is selected
          if (selectedList.contains(true)) ...[
            Container(
              margin: const EdgeInsets.fromLTRB(4, 8, 4, 8),
              padding: const EdgeInsets.fromLTRB(8, 8, 0, 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  // Set your border color here
                  width: 1.0, // Set the width of the border
                ),
                //color: Theme.of(context).colorScheme.surfaceContainerHigh,
              ),
              child: Consumer<UserProfileProvider>(
                  builder: (context, userProfileProvider, child) {
                final trialStatus =
                    userProfileProvider.trialInfo['status'] ?? '';
                return Consumer<MyLocationListProvider>(
                    builder: (context, locationListProvider, child) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (selectedList.contains(true)) ...[
                        // Show selection count and select all button
                        SizedBox(width: CustomSpacing.two),
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "${selectedList.where((s) => s).length}",
                            style: typography.Body1.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(width: 2),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              final bool selectAll =
                                  selectedList.any((s) => s == false);

                              // Apply the same toggle logic as Checkbox
                              for (int i = 0; i < selectedList.length; i++) {
                                selectedList[i] = selectAll;
                              }
                              if (!selectAll) {
                                isSelectionMode = false;
                              }
                            });
                          },
                          child: Text(
                            // Dynamically show "Select All" or "Deselect All"
                            selectedList.any((s) => s == false)
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
                                          onPressed: () =>
                                              Navigator.pop(context),
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
                                              List<
                                                  String> selectedSovIds = Provider
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
                                                  builder:
                                                      (BuildContext context) {
                                                    return ExportDialog(
                                                      accountId:
                                                          widget.accountID!,
                                                      subAccountId:
                                                          widget.subAccountID!,
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

                                              if (selectedLoactionIds
                                                  .isNotEmpty) {
                                                showDialog(
                                                  context: context,
                                                  builder:
                                                      (BuildContext context) {
                                                    return ExportDialog(
                                                      accountId:
                                                          widget.accountID!,
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
                            if (selectedList.length !=
                                sovListProvider.sovList.length) {
                              selectedList = List.generate(
                                sovListProvider.sovList.length,
                                (_) => false,
                              );
                            }

                            final selectedSovs = sovListProvider.sovList
                                .asMap()
                                .entries
                                .where((entry) => selectedList[entry.key])
                                .map((entry) => entry.value)
                                .toList();

                            if (selectedSovs.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        "Please select at least one SOV to share.")),
                              );
                              return;
                            }

                            _showTransferDialog(context, selectedSovs);
                          },
                          icon: const Icon(
                            Symbols.share,
                            color: Color(0xFF90CAF9),
                          ),
                          tooltip: 'Share Selected',
                        ),
                      ]
                    ],
                  );
                });
              }),
            ),
          ],
          // Search
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            height: 50,
            child: TextField(
              controller: _textEditingController,
              onChanged: (query) => sovSearchClient(query),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                hintText: "Search Keyword",
                hintStyle: typography.Body2,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _textEditingController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _textEditingController.clear();
                          sovSearchClient('');
                        },
                      )
                    : null,
              ),
            ),
          ),
          SizedBox(height: CustomSpacing.four),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Consumer<SOVListProvider>(
                builder: (context, sovListProvider, _) {
              // if (sovListProvider.isLoading) {
              return Row(
                children: [
                  InfoCard(
                    title: "Total SOVs",
                    count: safeParseInt(
                        sovListProvider.sovCounterList.all.toString()),
                    icon: Icons.file_copy_outlined,
                  ),
                  InfoCard(
                    title: "My SOVs",
                    count: safeParseInt(sovListProvider.sovCounterList.my),
                    icon: Icons.file_copy_outlined,
                  ),
                  InfoCard(
                    title: "Shared SOVs",
                    count: safeParseInt(sovListProvider.sovCounterList.shared),
                    icon: Icons.ios_share_outlined,
                  ),
                  InfoCard(
                    title: "Received SOVs",
                    count:
                        safeParseInt(sovListProvider.sovCounterList.received),
                    icon: Icons.call_received,
                  ),
                  InfoCard(
                    title: "Completed SOVs",
                    count:
                        safeParseInt(sovListProvider.sovCounterList.completed),
                    icon: Icons.done_all,
                  ),
                ],
              );
            }),
          ),

          SizedBox(height: CustomSpacing.four),

          // List of accounts
          Expanded(
            child: Consumer<SOVListProvider>(
              builder: (context, sovListProvider, _) {
                if (sovListProvider.isLoading) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 100),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (sovListProvider.sovList.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () async {
                      sovListProvider.page = 0;
                      await sovListProvider.fetchSovList(
                        context,
                        widget.accountID!,
                        widget.subAccountID!,
                        _sovQuery,
                        sovListProvider.page,
                        10,
                        'all',
                      );
                    },
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: Center(
                            child: Text(
                              "Looks like you don’t have a sov yet. No worries! Just create a new one and start adding your locations.",
                              style: typography.Body1,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await sovListProvider.fetchSovList(
                      context,
                      widget.accountID!,
                      widget.subAccountID!,
                      _sovQuery,
                      1,
                      10,
                      "my",
                    );
                  },
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: sovListProvider.sovList.length,
                          itemBuilder: (context, index) {
                            return _buildSovCard(index, sovListProvider);
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      );
    });
  }

  Widget _buildSovCard(int index, SOVListProvider sOVListProvider) {
    var typography = CustomTypography(context);
    Offset _tapPosition = Offset.zero;
    // bool isDisabled = sOVListProvider.sovList[index].disabled ?? false;
    return Container(
      margin: EdgeInsets.only(top: 0.0, bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          setState(() {
            if (isSelectionMode) {
              selectedList[index] = !selectedList[index];
              if (!selectedList.contains(true)) {
                isSelectionMode = false;
              }
              // Update selectedSovIds and selectedCount
              selectedSovIds = sOVListProvider.sovList
                  .asMap()
                  .entries
                  .where((entry) => selectedList[entry.key])
                  .map((entry) => entry.value.sovId)
                  .whereType<String>()
                  .toSet();
              final selectedCount = selectedSovIds.length;
              print('Selected SOV IDs: $selectedSovIds');
              print('Selected count: $selectedCount');
            } else {
              Navigator.push(context, MaterialPageRoute(builder: (context) {
                return SovLocationList(
                  accountID: widget.accountID!,
                  subAccountID: widget.subAccountID!,
                  accountName: widget.accountName,
                  subAccountName: widget.subAccountName,
                  sovID: sOVListProvider.sovList[index].sovId ?? "",
                  sovName: sOVListProvider.sovList[index].name ?? "",
                );
              }));
            }
          });
        },
        onLongPress: () {
          setState(() {
            if (selectedList.length != sOVListProvider.sovList.length) {
              selectedList = List.generate(
                sOVListProvider.sovList.length,
                (_) => false,
              );
            }

            if (isSelectionMode) {
              selectedList[index] = !selectedList[index];
              if (!selectedList.contains(true)) {
                isSelectionMode = false;
              }
            } else {
              selectedList[index] = true;
              isSelectionMode = true;
            }

            // Collect selected SOV IDs and count
            selectedSovIds = sOVListProvider.sovList
                .asMap()
                .entries
                .where((entry) => selectedList[entry.key])
                .map((entry) => entry.value.sovId)
                .whereType<String>()
                .toSet();

            final selectedCount = selectedSovIds.length;
          });
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 230,
                    width: MediaQuery.of(context).size.width,
                    child: Card(
                      color: Colors.white12,
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(8),
                            bottomLeft: Radius.circular(8),
                            bottomRight: Radius.circular(8)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // if (isSelectionMode)
                              //   Checkbox(
                              //     value: (index < selectedList.length)
                              //         ? selectedList[index]
                              //         : false,
                              //     onChanged: (value) {
                              //       setState(() {
                              //         if (selectedList.length !=
                              //             sOVListProvider.sovList.length) {
                              //           selectedList = List.generate(
                              //             sOVListProvider.sovList.length,
                              //             (_) => false,
                              //           );
                              //         }
                              //         selectedList[index] = value ?? false;
                              //
                              //         if (!selectedList.contains(true)) {
                              //           isSelectionMode = false;
                              //         }
                              //       });
                              //     },
                              //   ),

                              SizedBox(
                                width: CustomSpacing.two,
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Row(
                                            children: [
                                              if (isSelectionMode)
                                                Checkbox(
                                                  value: (index <
                                                          selectedList.length)
                                                      ? selectedList[index]
                                                      : false,
                                                  onChanged: (value) {
                                                    setState(() {
                                                      if (selectedList.length !=
                                                          sOVListProvider
                                                              .sovList.length) {
                                                        selectedList =
                                                            List.generate(
                                                          sOVListProvider
                                                              .sovList.length,
                                                          (_) => false,
                                                        );
                                                      }
                                                      selectedList[index] =
                                                          value ?? false;

                                                      if (!selectedList
                                                          .contains(true)) {
                                                        isSelectionMode = false;
                                                      }
                                                    });
                                                  },
                                                ),
                                              Chip(
                                                label: Text(
                                                  sOVListProvider
                                                          .sovList[index].status
                                                          ?.toString() ??
                                                      'Pending',
                                                  style:
                                                      typography.Body2.copyWith(
                                                    color: sOVListProvider
                                                                .sovList[index]
                                                                .status
                                                                ?.toString() ==
                                                            'completed'
                                                        ? Colors.white
                                                        : Color(0xFFFFA726),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 0, vertical: 0),
                                                backgroundColor: sOVListProvider
                                                            .sovList[index]
                                                            .status
                                                            ?.toString() ==
                                                        'completed'
                                                    ? Colors.green
                                                    : Color(0xFFFFA726)
                                                        .withOpacity(0.2),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding:
                                              const EdgeInsets.only(right: 10),
                                          child: Consumer2<
                                              SubAccountListProvider,
                                              SOVListProvider>(
                                            builder: (context,
                                                subAccountListProvider,
                                                sovprovider,
                                                child) {
                                              return PopupMenuButton<String>(
                                                color: const Color(0xFF1E1E1E),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                icon: const Icon(
                                                    Icons.more_vert,
                                                    color: Colors.white),
                                                onSelected: (value) async {
                                                  if (value == 'delete') {
                                                    bool sovDeleteStatus =
                                                        false;

                                                    showDialog(
                                                      context: context,
                                                      barrierDismissible: false,
                                                      builder: (context) {
                                                        return StatefulBuilder(
                                                          builder: (context,
                                                              setState) {
                                                            return AlertDialog(
                                                              backgroundColor:
                                                                  const Color(
                                                                      0xFF1E1E1E),
                                                              shape:
                                                                  RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            12),
                                                              ),
                                                              title: const Text(
                                                                'Confirm Deletion',
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .white,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold),
                                                              ),
                                                              content:
                                                                  const Text(
                                                                'This action will permanently delete the SOV and its data. Proceed?',
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .white70),
                                                              ),
                                                              actions: [
                                                                TextButton(
                                                                  onPressed: () =>
                                                                      Navigator.pop(
                                                                          context),
                                                                  child: const Text(
                                                                      'Cancel',
                                                                      style: TextStyle(
                                                                          color:
                                                                              Colors.grey)),
                                                                ),
                                                                TextButton(
                                                                  onPressed:
                                                                      () async {
                                                                    setState(
                                                                        () {
                                                                      sovDeleteStatus =
                                                                          true;
                                                                    });

                                                                    bool
                                                                        isSuccess =
                                                                        false;
                                                                    try {
                                                                      isSuccess =
                                                                          await subAccountListProvider
                                                                              .deleteSOVAccount(
                                                                        context,
                                                                        subAccountListProvider
                                                                            .subAccountList[index]
                                                                            .accountId!,
                                                                        subAccountListProvider
                                                                            .subAccountList[index]
                                                                            .subAccountId!,
                                                                        sovprovider
                                                                            .sovList[index]
                                                                            .sovId!,
                                                                      );
                                                                    } catch (e) {
                                                                      debugPrint(
                                                                          "Error deleting account: $e");
                                                                      ScaffoldMessenger.of(
                                                                              context)
                                                                          .showSnackBar(
                                                                        const SnackBar(
                                                                          content:
                                                                              Text("Failed to delete SOV. Please try again."),
                                                                        ),
                                                                      );
                                                                    }

                                                                    if (isSuccess) {
                                                                      Navigator.pop(
                                                                          context);
                                                                      await sovprovider
                                                                          .fetchSovList(
                                                                        context,
                                                                        widget
                                                                            .accountID!,
                                                                        widget
                                                                            .subAccountID!,
                                                                        _sovQuery,
                                                                        1,
                                                                        100,
                                                                        selectedSov,
                                                                      );
                                                                      ScaffoldMessenger.of(
                                                                              context)
                                                                          .showSnackBar(
                                                                        const SnackBar(
                                                                          content:
                                                                              Text("SOV deleted successfully."),
                                                                        ),
                                                                      );
                                                                    }

                                                                    setState(
                                                                        () {
                                                                      sovDeleteStatus =
                                                                          false;
                                                                    });
                                                                  },
                                                                  child: sovDeleteStatus
                                                                      ? const SizedBox(
                                                                          width:
                                                                              24,
                                                                          height:
                                                                              24,
                                                                          child:
                                                                              CircularProgressIndicator(
                                                                            strokeWidth:
                                                                                2,
                                                                            color:
                                                                                Colors.red,
                                                                          ),
                                                                        )
                                                                      : const Text(
                                                                          'Delete',
                                                                          style: TextStyle(
                                                                              color: Colors.redAccent,
                                                                              fontSize: 16),
                                                                        ),
                                                                ),
                                                              ],
                                                            );
                                                          },
                                                        );
                                                      },
                                                    );
                                                  }
                                                },
                                                itemBuilder:
                                                    (BuildContext context) => [
                                                  PopupMenuItem<String>(
                                                    value: 'delete',
                                                    child: Row(
                                                      children: const [
                                                        Icon(Icons.delete,
                                                            color: Colors
                                                                .redAccent),
                                                        SizedBox(width: 8),
                                                        Text(
                                                          'Delete',
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.white),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      sOVListProvider.sovList[index].name
                                          .toString(),
                                      style: typography.Body2.copyWith(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w400,
                                        color: const Color(0xFF90CAF9),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 4),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        // Owner info
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: Colors.grey[800],
                                          child: Text(
                                            (sOVListProvider.sovList[index]
                                                            .owner?.name !=
                                                        null &&
                                                    sOVListProvider
                                                        .sovList[index]
                                                        .owner!
                                                        .name!
                                                        .isNotEmpty)
                                                ? sOVListProvider
                                                    .sovList[index].owner!.name!
                                                    .substring(0, 2)
                                                    .toUpperCase()
                                                : "?",
                                            style: const TextStyle(
                                                color: Colors.white),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            sOVListProvider.sovList[index].owner
                                                    ?.name ??
                                                "Unknown",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Colors.white,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        // Location count
                                        Text(
                                          "Locations: ${sOVListProvider.sovList[index].locationCount?.toString() ?? ""}",
                                          style: typography.Body2.copyWith(
                                            color:
                                                Theme.of(context).brightness ==
                                                        Brightness.dark
                                                    ? AppColors.white
                                                    : AppColors.black,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(width: 10),
                                      ],
                                    ),

                                    SizedBox(height: 8),
                                    if (sOVListProvider
                                                .sovList[index].companyName !=
                                            null &&
                                        sOVListProvider.sovList[index]
                                            .companyName!.isNotEmpty) ...[
                                      Text(
                                        "Company: ${sOVListProvider.sovList[index].companyName}",
                                        style: typography.Body2.copyWith(
                                            color:
                                                Theme.of(context).brightness ==
                                                        Brightness.dark
                                                    ? AppColors.white
                                                    : AppColors.black,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500),
                                        overflow: TextOverflow.ellipsis,
                                      )
                                    ],

                                    SizedBox(height: 8),
                                    _buildScrollableScores(
                                      context,
                                      sOVListProvider
                                          .sovList[index]
                                          .sovGraphData!
                                          .sovResults![0]
                                          .geocodeAvg
                                          .toString(),
                                      sOVListProvider
                                          .sovList[index]
                                          .sovGraphData!
                                          .sovResults![0]
                                          .overallAvg
                                          .toString(),
                                      sOVListProvider.sovList[index]
                                          .totalDataCompleteness!.averageScorePd
                                          .toString(),
                                    ),
                                    SizedBox(height: 4),
                                    // Row(
                                    //   children: [
                                    //     Text(
                                    //       "Role:  ",
                                    //       style: typography.Body2.copyWith(
                                    //         color: Theme.of(context)
                                    //                     .brightness ==
                                    //                 Brightness.dark
                                    //             ? AppColors.white
                                    //             : AppColors.black,
                                    //       ),
                                    //       overflow: TextOverflow.ellipsis,
                                    //     ),
                                    //     Text(
                                    //       "${sOVListProvider}",
                                    //       style: typography.Body2.copyWith(
                                    //         color: const Color(0xFF90CAF9),
                                    //       ),
                                    //       overflow: TextOverflow.ellipsis,
                                    //     ),
                                    //   ],
                                    // ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          // SizedBox(
                          //   height: CustomSpacing.two,
                          // ),
                        ],
                      ),
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

  Widget _buildScrollableScores(BuildContext context, String geocoding,
      String riskScore, String completeness) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          InkWell(
            onTap: () {},
            child: _buildScoreCard(
              context,
              'Geocoding',
              int.tryParse(geocoding) ?? 0,
            ),
          ),
          if (MediaQuery.of(context).size.width > 400) SizedBox(width: 5),
          InkWell(
            onTap: () {},
            child: _buildScoreCard(
              context,
              'Risk Score',
              int.tryParse(riskScore) ?? 0,
            ),
          ),
          if (MediaQuery.of(context).size.width > 400) SizedBox(width: 5),
          InkWell(
            onTap: () {},
            child: _buildScoreCard(
              context,
              'Completeness',
              int.tryParse(completeness) ?? 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard(
    BuildContext context,
    String title,
    int score,
  ) {
    bool isCertified = score == 5; // Logic to check if it shows a certificate.
    List<Color> scoreColors = [
      Colors.grey[300]!, // Default color for unfilled bars
      Colors.red[900]!, // Dark Red for 1
      Colors.red[300]!, // Light Red for 2
      Colors.yellow[300]!, // Light Yellow for 3
      Colors.green[300]!, // Light Green for 4
      Colors.green[600]!, // Green for 5
    ];

    var typography = CustomTypography(context);
    return Container(
      margin: EdgeInsets.fromLTRB(0, 3, 1, 2),
      padding: EdgeInsets.all(8),
      width: MediaQuery.of(context).size.width < 400 ? 165 : 145,
      height: MediaQuery.of(context).size.height < 400 ? 80 : 75,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1.5,
        ),
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        boxShadow: [
          BoxShadow(
            color: Colors.transparent,
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryMain,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    textAlign: MediaQuery.of(context).size.width < 400
                        ? TextAlign.center
                        : TextAlign.left,
                  ),
                ),
                SizedBox(width: 8),
                // if (title == 'Risk Score' || title == 'Geocoding') ...[
                //   InkWell(
                //     onTap: () {
                //       showDialog(
                //         context: context,
                //         builder: (context) => GeocodingDialog(title: title),
                //       );
                //     },
                //     child: Icon(Icons.info),
                //   ),
                // ] else ...[
                //   Icon(Icons.info, color: Colors.transparent),
                // ]
              ],
            ),
          ),
          SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InkWell(
                  onTap: () {},
                  //     // if (title == 'Geocoding') {
                  //     //   showLocationDetailsPopup(
                  //     //       context,
                  //     //       widget.lat,
                  //     //       widget.long!,
                  //     //       widget.imageUrl,
                  //     //       widget.address,
                  //     //       widget.locationId,
                  //     //       widget.geocodingScore,
                  //     //       widget.overallScore!,
                  //     //       widget.dataCompletenessScore,
                  //     //       widget.hazards,
                  //     //       "MAc",
                  //     //       widget.accountId!,
                  //     //       widget.subAccountId!,
                  //     //       "widget.sovId!",
                  //     //       widget.accountName,
                  //     //       widget.subAccountName!,
                  //     //       widget.hazardProcess!,
                  //     //       widget.rented);
                  //     // }
                  //   },
                  child: VerticalBarIndicator(score: score),
                ),
                SizedBox(width: 1),
                isCertified
                    ? SvgPicture.asset('assets/images/certified_five.svg',
                        width: 24, height: 24)
                    : Container(
                        margin: EdgeInsets.only(left: 4),
                        child: CircleAvatar(
                          radius: 10,
                          backgroundColor: scoreColors[score].withOpacity(0.6),
                          child: Center(
                            child: Text(
                              score.toString(),
                              style: typography.Body1.copyWith(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: MediaQuery.of(context).size.width < 400
                                  ? TextAlign.center
                                  : TextAlign.left,
                            ),
                          ),
                        ),
                      ),
              ],
            ),
          ),
          SizedBox(height: 4),
        ],
      ),
    );
  }

  Future<void> _showTransferDialog(
      BuildContext context, List<Result> sovs) async {
    final _userSearchController = TextEditingController();
    List<TransferAutocompleteModel> _autocompleteUsersList = [];
    SignUpOptions _selectedOption = SignUpOptions.corporate;
    Set<int> _selectedIndexes = {};
    List<String?> _selectedRoles = [];
    List<DateTime?> _selectedDeadlines = [];
    Timer? _debounce;
    bool _isSearching = false;
    bool _isShareEnabled = false;

    List<Map<String, dynamic>> selectedUsersJson = []; // Store selected data
    void _onSearchChanged(String query, StateSetter setState, String type) {
      if (_debounce?.isActive ?? false) _debounce?.cancel();

      _debounce = Timer(const Duration(milliseconds: 500), () async {
        if (query.isNotEmpty) {
          setState(() => _isSearching = true);
          final results = await fetchAutocompleteUsers(query, type);

          // Update autocomplete list but preserve existing selections
          setState(() {
            _autocompleteUsersList = results;

            // Expand lists if new items appear (without resetting old ones)
            if (_selectedRoles.length < results.length) {
              _selectedRoles.addAll(
                List<String?>.filled(
                    results.length - _selectedRoles.length, null),
              );
            }

            if (_selectedDeadlines.length < results.length) {
              _selectedDeadlines.addAll(
                List<DateTime?>.filled(
                    results.length - _selectedDeadlines.length, null),
              );
            }

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

    // void _onSearchChanged(String query, StateSetter setState, String type) {
    //   if (_debounce?.isActive ?? false) _debounce?.cancel();
    //   _debounce = Timer(const Duration(milliseconds: 500), () async {
    //     if (query.isNotEmpty) {
    //       setState(() => _isSearching = true);
    //       _autocompleteUsersList = await fetchAutocompleteUsers(query, type);
    //
    //       // Initialize role & deadline lists to match result length
    //       _selectedRoles =
    //           List<String?>.filled(_autocompleteUsersList.length, null);
    //       _selectedDeadlines =
    //           List<DateTime?>.filled(_autocompleteUsersList.length, null);
    //
    //       setState(() => _isSearching = false);
    //     } else {
    //       setState(() {
    //         _autocompleteUsersList.clear();
    //         // _selectedRoles.clear();
    //         // _selectedDeadlines.clear();
    //         _isSearching = false;
    //       });
    //     }
    //   });
    // }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Share SOV",
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    const SizedBox(height: 16),

                    // --- User Type Dropdown ---
                    DropdownButtonFormField<SignUpOptions>(
                      value: _selectedOption,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: SignUpOptions.corporate,
                            child: Text("Corporate")),
                        DropdownMenuItem(
                            value: SignUpOptions.individual,
                            child: Text("Individual")),
                      ],
                      onChanged: (value) =>
                          setState(() => _selectedOption = value!),
                      dropdownColor: const Color(0xFF1E1E1E),
                      alignment: Alignment.bottomLeft,
                    ),
                    const SizedBox(height: 16),

                    // --- Search Box ---
                    TextField(
                      controller: _userSearchController,
                      onChanged: (value) => _onSearchChanged(
                          value, setState, _selectedOption.name),
                      decoration: InputDecoration(
                        labelText: "Search user",
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (_isSearching)
                      const Center(child: CircularProgressIndicator())
                    else if (_autocompleteUsersList.isNotEmpty)
                      SizedBox(
                        height: 300,
                        child: SingleChildScrollView(
                          child: Column(
                            children: List.generate(
                                _autocompleteUsersList.length, (index) {
                              final user = _autocompleteUsersList[index];
                              final isSelected =
                                  _selectedIndexes.contains(index);
                              final selectedRole = _selectedRoles[index];
                              final deadline = _selectedDeadlines[index];

                              String? roleError;
                              String? deadlineError;

                              bool canShareAll() {
                                for (int i in _selectedIndexes) {
                                  if (_selectedRoles[i] == null ||
                                      _selectedDeadlines[i] == null) {
                                    return false;
                                  }
                                }
                                return _selectedIndexes.isNotEmpty;
                              }

                              void updateSelectedUsersJson() {
                                selectedUsersJson.clear();
                                for (var i in _selectedIndexes) {
                                  final selectedUser =
                                      _autocompleteUsersList[i];
                                  final selectedRole = _selectedRoles[i];
                                  final selectedDeadline =
                                      _selectedDeadlines[i];

                                  if (selectedRole != null &&
                                      selectedDeadline != null) {
                                    final roleObj =
                                        selectedUser.roles!.firstWhere(
                                      (r) => r.name == selectedRole,
                                    );

                                    selectedUsersJson.add({
                                      "user_id": selectedUser.userid ?? '',
                                      "role": {
                                        "role_id": roleObj.role ?? '',
                                        "role_name": roleObj.name ?? '',
                                      },
                                      "share_expiry": selectedDeadline
                                          .toUtc()
                                          .toIso8601String(),
                                    });
                                  }
                                }

                                // Enable/disable Share button
                                setState(() {
                                  _isShareEnabled = canShareAll();
                                });

                                debugPrint(
                                    "✅ Selected Users JSON: $selectedUsersJson");
                              }

                              void toggleSelection(bool? value) {
                                setState(() {
                                  if (value == true) {
                                    _selectedIndexes.add(index);
                                  } else {
                                    _selectedIndexes.remove(index);
                                    _selectedRoles[index] = null;
                                    _selectedDeadlines[index] = null;
                                  }
                                  updateSelectedUsersJson();
                                });
                              }

                              return StatefulBuilder(
                                builder: (context, setInnerState) {
                                  return Container(
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E1E1E),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected
                                            ? Colors.blue
                                            : Colors.grey.shade700,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            CircleAvatar(
                                              backgroundColor: Colors.grey[800],
                                              child: Text(
                                                (user.name != null &&
                                                        user.name!.isNotEmpty)
                                                    ? user.name!
                                                        .substring(0, 2)
                                                        .toUpperCase()
                                                    : "?",
                                                style: const TextStyle(
                                                    color: Colors.white),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                user.name ?? "Unknown",
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                            Checkbox(
                                              value: isSelected,
                                              activeColor:
                                                  const Color(0xFF90CAF9),
                                              onChanged: (value) =>
                                                  toggleSelection(value),
                                            ),
                                          ],
                                        ),

                                        // Role dropdown (enabled only if checkbox selected)
                                        const SizedBox(height: 12),
                                        IgnorePointer(
                                          ignoring: !isSelected,
                                          child: Opacity(
                                            opacity: isSelected ? 1 : 0.4,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12),
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                    color:
                                                        Colors.grey.shade700),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child:
                                                  DropdownButtonHideUnderline(
                                                child: DropdownButton<String>(
                                                  value: selectedRole,
                                                  hint: const Text(
                                                    'Select Role',
                                                    style: TextStyle(
                                                        color: Colors.white70),
                                                  ),
                                                  dropdownColor:
                                                      const Color(0xFF2C2C2C),
                                                  icon: const Icon(
                                                      Icons.arrow_drop_down,
                                                      color: Colors.white70),
                                                  isExpanded: true,
                                                  items: user.roles!
                                                      .map(
                                                        (role) =>
                                                            DropdownMenuItem<
                                                                String>(
                                                          value: role.name,
                                                          child: Text(
                                                            role.name ?? '',
                                                            style:
                                                                const TextStyle(
                                                                    color: Colors
                                                                        .white),
                                                          ),
                                                        ),
                                                      )
                                                      .toList(),
                                                  onChanged: (value) {
                                                    setInnerState(() {
                                                      _selectedRoles[index] =
                                                          value;
                                                      roleError = null;
                                                    });
                                                    updateSelectedUsersJson();
                                                  },
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),

                                        if (roleError != null)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                top: 4, left: 12),
                                            child: Text(
                                              roleError!,
                                              style: const TextStyle(
                                                  color: Colors.redAccent,
                                                  fontSize: 12),
                                            ),
                                          ),

                                        const SizedBox(height: 12),
                                        const Text("Set Deadline",
                                            style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey)),
                                        const SizedBox(height: 6),

                                        // Deadline picker (enabled only if checkbox selected)
                                        IgnorePointer(
                                          ignoring: !isSelected,
                                          child: Opacity(
                                            opacity: isSelected ? 1 : 0.4,
                                            child: InkWell(
                                              onTap: () async {
                                                if (!isSelected) return;
                                                final now = DateTime.now();
                                                final pickedDate =
                                                    await showDatePicker(
                                                  context: context,
                                                  initialDate: now,
                                                  firstDate: DateTime(now.year,
                                                      now.month, now.day),
                                                  lastDate: DateTime(2100),
                                                );
                                                if (pickedDate != null) {
                                                  setInnerState(() {
                                                    _selectedDeadlines[index] =
                                                        pickedDate;
                                                    deadlineError = null;
                                                  });
                                                  updateSelectedUsersJson();
                                                }
                                              },
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 12),
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                      color:
                                                          Colors.grey.shade700),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        deadline != null
                                                            ? DateFormat(
                                                                    'MM/dd/yyyy')
                                                                .format(
                                                                    deadline)
                                                            : "Select Date",
                                                        style: const TextStyle(
                                                            color:
                                                                Colors.white70),
                                                      ),
                                                    ),
                                                    const Icon(
                                                        Icons
                                                            .calendar_today_outlined,
                                                        color: Colors.white70,
                                                        size: 20),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        if (deadlineError != null)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                top: 4, left: 12),
                                            child: Text(
                                              deadlineError!,
                                              style: const TextStyle(
                                                  color: Colors.redAccent,
                                                  fontSize: 12),
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            }),
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),

                    const Text(
                      "Note: Users with multiple roles must be assigned one role per SOV.",
                      style: TextStyle(fontSize: 14, color: Color(0xFF9FA6AD)),
                    ),
                    const SizedBox(height: 24),

                    // --- Share Button ---
                    Row(
                      children: [
                        Expanded(
                          child: Consumer<SOVListProvider>(
                            builder: (context, sovListProvider, _) {
                              return CustomButton(
                                type: ButtonType.elevated,
                                onPressed: (!_isShareEnabled ||
                                        sovListProvider.isLoading)
                                    ? null
                                    : () async {
                                        List<Map<String, dynamic>>
                                            shareWithList = [];

                                        for (int index in _selectedIndexes) {
                                          final user =
                                              _autocompleteUsersList[index];
                                          final roleName =
                                              _selectedRoles[index];
                                          final deadline =
                                              _selectedDeadlines[index];

                                          final selectedRole = user.roles
                                              ?.firstWhere(
                                                  (r) => r.name == roleName);

                                          shareWithList.add({
                                            "user_id": user.userid ?? '',
                                            "role": {
                                              "role_id":
                                                  selectedRole?.role ?? '',
                                              "role_name":
                                                  selectedRole?.name ?? '',
                                            },
                                            "share_expiry":
                                                deadline!.toIso8601String(),
                                          });
                                        }

                                        bool success =
                                            await sovListProvider.shareSov(
                                          sovId: selectedSovIds,
                                          shareWithList: shareWithList,
                                        );

                                        if (success) {
                                          Navigator.pop(context);
                                          setState(() {
                                            selectedList = List.filled(
                                                selectedList.length, false);
                                            isSelectionMode = false;
                                          });
                                          // setState(() {
                                          //   isSelectionMode = false;
                                          // });
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    "Failed to share SOV.")),
                                          );
                                        }
                                      },
                                child: sovListProvider.isLoading
                                    ? const CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2)
                                    : const Text("Share",
                                        style: TextStyle(color: Colors.black)),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            type: ButtonType.outlined,
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Cancel"),
                          ),
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
}

Widget _buildButtonChild(BuildContext context) {
  final locationListProvider = Provider.of<LocationListProvider>(context);
  final locationProfileProvider = Provider.of<MyLocationListProvider>(context);

  var typography = CustomTypography(context);
  if (locationListProvider.isAddLocationLoading ||
      locationProfileProvider.isLoading) {
    return Center(
      child: SizedBox(
        height: 25,
        width: 25,
        child: CircularProgressIndicator(
          color: AppColors.black,
        ),
      ),
    );
  } else {
    return Text(
      "Share SOV",
      style: typography.ButtonLarge.copyWith(
        color: Colors.black,
      ),
    );
  }
}

//
Future<List<TransferAutocompleteModel>> fetchAutocompleteUsers(
    String query, String type) async {
  try {
    ApiService apiService = ApiService(AppConstant.GET_SEARCH_LIST_BY_SOV);
    String url = type != "individual"
        ? '/user_search?search=$query'
        : '/individual_user_search?search=$query';
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
//

class _AutoHideCompletedRow extends StatefulWidget {
  final int percentage;

  const _AutoHideCompletedRow({required this.percentage});

  @override
  State<_AutoHideCompletedRow> createState() => _AutoHideCompletedRowState();
}

class _AutoHideCompletedRowState extends State<_AutoHideCompletedRow> {
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _visible = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    return Row(
      children: [
        const Icon(Icons.check_circle, color: Colors.green),
        const SizedBox(width: 8),
        Text("Completed (${widget.percentage}%)"),
      ],
    );
  }
}

class InfoCard extends StatelessWidget {
  final String title;
  final dynamic count;
  final IconData icon;

  const InfoCard({
    super.key,
    required this.title,
    required this.count,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      width: 170,
      child: Card(
        color: Colors.white12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.white38, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.white38,
                  borderRadius:
                      BorderRadius.circular(15), // adjust radius as needed
                ),
                child: Icon(
                  icon,
                  color: Colors.white60,
                  size: 20,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.17),
              ),
              const SizedBox(height: 8),
              Text(
                count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildBarItem(String title, double value, Color color) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(title,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              FractionallySizedBox(
                widthFactor: value / 166, // normalize based on max
                child: Container(
                  height: 33,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
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
