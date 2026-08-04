import 'package:RiskSphere/screens/listings/widgets/location_list_map_view.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../../design_system/repo/constants.dart';
import '../../models/my_location_list_model.dart';
import '../../service/firestore_service.dart';
import '../../utils/env.dart';
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
  bool _hasReloaded = false;

  static bool _hasActiveTimer = false;
  bool isSovSelected = false;
  bool _isExpanded = false;
  bool sovDeleteStatus = false;
  bool _showNotificationDot = true;
  TabController? _masterTabController;
  late TabController _tabController;
  String selectedProcessId = "";
  bool isSelectionMode = false;
  List<bool> selectedList = [];
  String isMaintenance = "";
  Timer? _debounce;
  Screens _selectedScreen = Screens.locationList;
  TextEditingController _locationSearchController = TextEditingController();
  TextEditingController mobileController = TextEditingController();
  String selectedDropdown = 'TPV';
  int? touchedIndex; // For showing overlay info
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _showOverlay_mylocation = false;
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
  String? hasHazardHubCount = "0";
  String? eathquakeLicenseCount = "0";
  String? hurricaneLicensecount = "0";
  String mononitoringsovId = "";
  ScrollController _scrollController = ScrollController();
  ScrollController _scrollController1 = ScrollController();
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
  String? hazardLicenseStatus1 = "1";
  String? hazardLicenseStatus2 = "1";
  List<TargetFocus> targets = [];
  GlobalKey keyFeature1 = GlobalKey();
  GlobalKey keyFeature2 = GlobalKey();
  GlobalKey keyFeature3 = GlobalKey();
  GlobalKey keyFeature4 = GlobalKey();
  final ValueNotifier<String> fabStatusNotifier = ValueNotifier("idle");

  String selectedSovId = "";
  TextEditingController sovController = TextEditingController();
  TextEditingController tagController = TextEditingController();
  final _tagFormKey = GlobalKey<FormState>();
  final List<String> tags = [];
  bool isUploadInProgress = false;

  void debounce(VoidCallback callback,
      {Duration duration = const Duration(seconds: 1)}) {
    if (deBouncer != null) {
      deBouncer!.cancel();
    }
    deBouncer = Timer(duration, callback);
  }

  bool isProcessing = false;
  Stream<Map<String, dynamic>>? _combinedStream;
  String? _streamAcct;
  String? _streamSub;

// State fields
  final _processIndex$ = BehaviorSubject<int>.seeded(0);
  int _currentProcessIndex = 0;
  bool _isReloaded = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _setClaims();
    Future.microtask(() {
      Provider.of<MyLocationListProvider>(
        context,
        listen: false,
      ).clearSelection();
    });
    _initPgAdmin();

    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);

    _mainTabController = TabController(length: 3, vsync: this);
    _mainTabController?.addListener(_onMainTabChanged);

    _updateMasterTabController();

    // --- 2. Heavy operations AFTER first frame ---
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFirstTime(); // SharedPreferences (heavy)
      _initializeData(); // Your main startup API
      _triggerInitialApiLoad(); // Your list map conflict APIs
    });

    // --- 3. Streams can start instantly ---
    _buildCombinedStream();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final locationListProvider =
      Provider.of<MyLocationListProvider>(context, listen: false);

      // Run every 30 seconds
      _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
        final list = locationListProvider.myLocationList;

        if (list.isEmpty) return;

        // True only when [true, true, true]
        bool allAreTrue = list.every((item) => item.isHazardProcess == true);

        // Reload when NOT all true
        if (!allAreTrue) {
          _reloadPage();
        }
      });
    });
  }

  void _reloadPage() {
    if (!mounted || _isDisposed) return;
    if (ModalRoute
        .of(context)
        ?.isCurrent != true) return;
    if (widget.accountID == null || widget.subAccountID == null) return;

    getdata(widget.accountID!, widget.subAccountID!);
  }

  void _triggerInitialApiLoad() {
    final provider =
    Provider.of<MyLocationListProvider>(context, listen: false);

    Future.microtask(() {
      provider.page = 1;
      provider.myLocationList.clear();

      Future.wait([
        provider.fetchLocationList(
          context,
          "",
          1,
          10,
          widget.accountID,
          widget.subAccountID,
          widget.initialProcessId,
          widget.initialSubProcessId,
          "",
        ),
        provider.fetchLocationConflictList(
          context,
          "",
          1,
          1,
          widget.accountID,
          widget.subAccountID,
          widget.initialProcessId,
          widget.initialSubProcessId,
        ),
        provider.fetchAllLocationList(
          context,
          widget.accountID!,
          widget.subAccountID!,
          processId: widget.initialProcessId,
          subProcessId: widget.initialSubProcessId,
        ),
      ]).then((_) {
        if (mounted);
      });
    });
  }

  void _onMainTabChanged() {
    if (!_mainTabController!.indexIsChanging) return;

    selectedMainTab = _mainTabController!.index;

    final provider =
    Provider.of<MyLocationListProvider>(context, listen: false);

    switch (selectedMainTab) {
      case 0:
        provider.page = 1;
        provider.myLocationList.clear();
        provider.fetchLocationList(
            context,
            "",
            1,
            10,
            widget.accountID,
            widget.subAccountID,
            widget.initialProcessId,
            widget.initialSubProcessId,
            "");
        provider
            .fetchLocationConflictList(
            context,
            "",
            1,
            1,
            widget.accountID,
            widget.subAccountID,
            widget.initialProcessId,
            widget.initialSubProcessId)
            .then((_) => setState(() {}));
        break;

      case 2:
      // provider.fetchAllLocationList(
      //   context,
      //   widget.accountID!,
      //   widget.subAccountID!,
      //   processId: widget.initialProcessId,
      //   subProcessId: widget.initialSubProcessId,
      // );
        break;
    }

    setState(() {});
  }

  void _buildCombinedStream() {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final firestore = FirestoreService.db;

    final userStream = firestore.collection('users').doc(uid).snapshots();

    final subaccountStream = firestore
        .collection('subaccount')
        .where('sub_account_id', isEqualTo: widget.subAccountID!)
        .snapshots();

    _combinedStream = Rx.combineLatest3(
      userStream,
      subaccountStream,
      _processIndex$.distinct(),
          (userSnap, subSnap, selIndex) {
        final userData = userSnap.data() ?? {};

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
            'activeProcesses': const [],
            'currentProcessIndex': 0,
          });
        }

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

        final processStream = firestore
            .collection('processes')
            .where('process_id', isEqualTo: lastProcessId)
            .limit(1)
            .snapshots()
            .map((snap) => snap.docs.isNotEmpty ? snap.docs.first.data() : {});

        return processStream.map((processData) =>
        {
          'processData': processData,
          'heatmapData': heatmapData,
          'activeProcesses': activeProcesses,
          'currentProcessIndex': clampedIndex,
        });
      },
    )
        .switchMap((inner) => inner)
        .throttleTime(const Duration(milliseconds: 500));
  }

  Future<void> _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstTime = prefs.getBool('isFirstTimeMylocation') ?? true;
    if (isFirstTime) {
      setState(() => _showOverlay_mylocation = true);
    }
  }

  Future<void> _closeOverlay() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstTimeMylocation', false);
    setState(() => _showOverlay_mylocation = false);
  }

  void _initializeData() {
    _setClaims();
    getdata(widget.accountID!, widget.subAccountID!);
    _startRefreshTimer(widget.accountID!, widget.subAccountID!);
    _getSovUploadStatus();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) return;

    final provider =
    Provider.of<MyLocationListProvider>(context, listen: false);

    provider.page = 1; // RESET PAGINATION
    provider.certifiedPage = 1;
    provider.isLoading = false;

    if (_tabController.index == 0) {
      // ALL LOCATIONS TAB
      provider.myLocationList.clear();
      provider.fetchLocationList(
        context,
        "",
        1,
        10,
        widget.accountID,
        widget.subAccountID,
        widget.initialProcessId,
        widget.initialSubProcessId,
        "",
      );
    } else {
      // CERTIFIED TAB
      provider.certifiedLocationList.clear();
      provider.clearRatingsFilter();
      provider.fetchCertifiedLocationList(
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
  void didUpdateWidget(covariant MyLocationList old) {
    super.didUpdateWidget(old);
    if (old.accountID != widget.accountID ||
        old.subAccountID != widget.subAccountID) {
      _currentProcessIndex = 0;
      _processIndex$.add(0);
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
    _activeAccountKey = null;
    _isDisposed = true;
    _timer?.cancel();
    _mainTabController?.dispose();
    _masterTabController?.dispose();
    _tabController.dispose();
    _hasActiveTimer = false;
    _debounce?.cancel();
    _myLocationProvider?.clearAllFilters();
    Provider.of<MyLocationListProvider>(
      context,
      listen: false,
    ).clearSelection();
    _myLocationProvider?.clearRatingsFilter();
    _myLocationProvider?.myLocationList.clear();
    _myLocationProvider?.certifiedLocationList.clear();
    _myLocationProvider?.selectedLocations.clear();
    _myLocationProvider?.summaryList.clear();

    super.dispose();
  }

  String? _activeAccountKey;
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
    var hazardLicenseStatus11 =
    await SharedPreferenceService.getTrialMaxLocations();
    var hazardLicenseStatus22 =
    await SharedPreferenceService.getTrialLocations();
    mononitoringsovId =
    (await SharedPreferenceService.getDefaultMonitoringSov())!;
    String? hazardLicense = await SharedPreferenceService.getHazardHubLicense();
    String? hurricancelicense = await SharedPreferenceService.getHurricane();
    String? eathquakeLicense = await SharedPreferenceService.getEathquake();
    setState(() {
      isPgAdmin = isPgAdmin;
      isSuperAdmin = isSuperAdmin;
      hasAnyPlan = hasAnyPlans ?? false;
      hasLicenseStatus = userLicenseStatus ?? "1";
      hasGeocodingStatus = geoCodingStatus ?? "1";
      hasHazardLicenseStatus = hazardLicenseStatus ?? "1";
      hazardLicenseStatus1 = hazardLicenseStatus11.toString() ?? "";
      hazardLicenseStatus2 = hazardLicenseStatus22.toString();
      mononitoringsovId = mononitoringsovId;
      hasHazardHubCount = hazardLicense.toString();
      eathquakeLicenseCount = hurricancelicense.toString();
      hurricaneLicensecount = eathquakeLicense.toString();
    });
    final locationListProvider =
    Provider.of<MyLocationListProvider>(context, listen: false);

    locationListProvider.certifiedPage = 1;

    await locationListProvider.fetchLocationList(
        context,
        "",
        1,
        8,
        accountId,
        subAccountId,
        widget.initialProcessId,
        widget.initialSubProcessId,
        '');

    final provider =
    Provider.of<MyLocationListProvider>(context, listen: false);
    provider
        .fetchLocationConflictList(
      context,
      "",
      1,
      1,
      widget.accountID,
      widget.subAccountID,
      widget.initialProcessId,
      widget.initialSubProcessId,
    )
        .then((_) => setState(() {}));

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _initPgAdmin() async {
    hasAnyPlan = await SharedPreferenceService.getHasAnyPlan();
    String? geoCodingStatus =
    await SharedPreferenceService.getGeocodingLicense();
    String? userLicenseStatus = await SharedPreferenceService.getUserLicense();
    String? hazardLicenseStatus =
    await SharedPreferenceService.getHazardLicense();
    var hazardLicenseStatus11 =
    await SharedPreferenceService.getTrialMaxLocations();
    var hazardLicenseStatus22 =
    await SharedPreferenceService.getTrialLocations();
    var getLicenseImprovementCount =
    await SharedPreferenceService.getHasImpromentLicenseCount();
    String? hazardLicensecount =
    await SharedPreferenceService.getHazardHubLicense();
    // trialMap = await SharedPreferenceService.getTrialPeriodStartRaw();
    String? hazardLicense = await SharedPreferenceService.getHazardHubLicense();
    if (mounted)
      setState(() {
        hasAnyPlan = hasAnyPlan;
        hasLicenseStatus = userLicenseStatus ?? "";
        hasGeocodingStatus = geoCodingStatus ?? "";
        hasHazardLicenseStatus = hazardLicenseStatus ?? "";
        hazardLicenseStatus1 = hazardLicenseStatus11.toString() ?? "";
        hazardLicenseStatus2 = hazardLicenseStatus22.toString();
        hasHazardHubCount = hazardLicense.toString();
        // getLocationImprovementCount = getLicenseImprovementCount.toString();
      });
  }

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
    String? lastProcessState =
    await SharedPreferenceService.getSovUploadState();
    String? lastAccount = await SharedPreferenceService.getSovAccountId();
    String? lastSubAccount = await SharedPreferenceService.getSovSubAccountId();
    String? tempProcessId = await SharedPreferenceService.getSovUploadTempId();

    if (tempProcessId == null || tempProcessId.isEmpty) {
      setState(() => isUploadInProgress = false);
      return;
    }

    bool showContinue = (lastProcessState == "upload" ||
        lastProcessState == "duplication_check") &&
        lastAccount == widget.accountID &&
        lastSubAccount == widget.subAccountID;

    setState(() => isUploadInProgress = showContinue);

    print("Upload Continue Available: $isUploadInProgress");
  }

  void _updateMasterTabController() {
    final int expectedLength = (isSuperAdmin || isPgAdmin) ? 2 : 1;
    if (_masterTabController == null || _masterTabController!.length != expectedLength) {
      final oldIndex = _masterTabController?.index ?? 0;
      _masterTabController?.dispose();
      _masterTabController = TabController(
        length: expectedLength,
        vsync: this,
        initialIndex: oldIndex < expectedLength ? oldIndex : 0,
      );
      _masterTabController!.addListener(() {
        if (mounted) {
          setState(() {
            selectedMasterTab = _masterTabController!.index;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context1) {
    _updateMasterTabController();
    var typography = CustomTypography(context);
    return SafeArea(
      child: PopScope(
        onPopInvokedWithResult: (canPop, result) {
          final provider = Provider.of<MyLocationListProvider>(
            context,
            listen: false,
          );

          provider.clearSelection();
        },
        // onPopInvokedWithResult: (canPop, result) {
        //   print('Can Pop: $canPop, Selected Screen: $_selectedScreen');
        //   Provider.of<MyLocationListProvider>(context, listen: false)
        //       .clearSelection();
        // },
        child: Consumer<UserProfileProvider>(
            builder: (context, userProfileProvider, child) {
              final trialStatus = userProfileProvider.trialInfo['status'] ?? '';
              return Consumer2<ThemeProvider, MyLocationListProvider>(
                builder:
                    (buildContext, themeProvider, locationProfileProvider,
                    child) {
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
                    floatingActionButton: (selectedMainTab == 0)
                        ? ValueListenableBuilder<String>(
                      valueListenable: fabStatusNotifier,
                      builder: (context, fabState, child) {
                        String buttonLabel = fabState == "processing"
                            ? LanguageService.getTranslated(
                            context, "continue")
                            : LanguageService.getTranslated(
                            context, "import_locations");

                        return Builder(builder: (context) {
                          return Container(
                            key: keyFeature4,
                            margin: EdgeInsets.only(bottom: 42.0),
                            child: SpeedDial(
                              animatedIcon: AnimatedIcons.menu_close,
                              animatedIconTheme: IconThemeData(size: 22.0),
                              backgroundColor: AppColors.primaryMain,
                              foregroundColor: themeProvider
                                  .getTheme.colorScheme.onPrimary,
                              children: [
                                if (selectedMasterTab == 0)
                                  SpeedDialChild(
                                    child: _isLoading
                                        ? SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                        AlwaysStoppedAnimation<
                                            Color>(
                                          themeProvider.getTheme
                                              .colorScheme.onPrimary,
                                        ),
                                      ),
                                    )
                                        : Icon(Icons.add),
                                    backgroundColor: AppColors.primaryMain,
                                    foregroundColor: themeProvider
                                        .getTheme.colorScheme.onPrimary,
                                    label: LanguageService.getTranslated(
                                        context, "add_location"),
                                    labelStyle: typography.Body1,
                                    onTap: () async {
                                      setState(() => _isLoading = true);

                                      await _setClaims();
                                      await Future.delayed(
                                          Duration(seconds: 1));

                                      _isDisposed = true;
                                      _refreshTimer?.cancel();
                                      _timer?.cancel();
                                      deBouncer?.cancel();

                                      final result =
                                      await Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              AddLocationScreen(
                                                accountId: widget.accountID!,
                                                subAccountId:
                                                widget.subAccountID!,
                                                sovId: "",
                                                accountName: widget.accountName,
                                                subAccountName:
                                                widget.subAccountName,
                                              ),
                                        ),
                                      );

                                      _isDisposed = false;
                                      _startRefreshTimer(widget.accountID!,
                                          widget.subAccountID!);

                                      _getSovUploadStatus();
                                      setState(() => _isLoading = false);

                                      if (result == true) {
                                        await getdata(widget.accountID!,
                                            widget.subAccountID!);

                                        fabStatusNotifier.value =
                                            fabStatusNotifier.value;
                                      }
                                    },
                                  ),

                                SpeedDialChild(
                                    child: Icon(Icons.upload),
                                    backgroundColor: AppColors.primaryMain,
                                    foregroundColor: themeProvider
                                        .getTheme.colorScheme.onPrimary,
                                    label: buttonLabel,
                                    // << dynamic label
                                    labelStyle: typography.Body1,
                                    onTap: () async {
                                      tagController.text = "";

                                      print(fabState.toString());

                                      if (fabState.toString().toLowerCase() ==
                                          "processing") {
                                        String tempProcessId =
                                            await SharedPreferenceService
                                                .getSovUploadTempId() ??
                                                "";
                                        String state =
                                            await SharedPreferenceService
                                                .getSovUploadState() ??
                                                "";

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
                                          state,
                                          onProcessCompleted: () {
                                            _getSovUploadStatus();
                                            fabStatusNotifier.value = "idle";
                                          },
                                        );
                                      } else {
                                        setState(() {
                                          files = null;
                                          _uploadedFileName = null;
                                          _sovNameController.clear();
                                          tags.clear();
                                          addToSOVCheck = false;
                                          selectedSovId = "";
                                          isSovSelected = false;
                                        });

                                        _showUploadBottomSheet(
                                          widget.accountID!,
                                          widget.subAccountID!,
                                          "",
                                        );
                                      }
                                    }),
// future reference
                                // if ((_masterTabController?.index ?? 0) == 0)
                                //   SpeedDialChild(
                                //     child: Icon(Icons.download),
                                //
                                //     backgroundColor: (() {
                                //       final provider =
                                //           Provider.of<MyLocationListProvider>(
                                //               context,
                                //               listen: false);
                                //
                                //       if (selectedMainTab == 0) {
                                //         // My Locations Tab
                                //         return provider
                                //                 .myLocationList.isNotEmpty
                                //             ? AppColors.primaryMain
                                //             : Colors.grey;
                                //       } else {
                                //         // Certified Locations Tab
                                //         return provider.certifiedLocationList
                                //                 .isNotEmpty
                                //             ? AppColors.primaryMain
                                //             : Colors.grey;
                                //       }
                                //     })(),
                                //
                                //     // Adjust icon color
                                //     foregroundColor: themeProvider
                                //         .getTheme.colorScheme.onPrimary,
                                //
                                //     label: 'Export Locations',
                                //     labelStyle: typography.Body1,
                                //
                                //     // ---------- CORRECT TAP LOGIC ----------
                                //     onTap: (() {
                                //       final provider =
                                //           Provider.of<MyLocationListProvider>(
                                //               context,
                                //               listen: false);
                                //
                                //       bool canExport = selectedMainTab == 0
                                //           ? provider.myLocationList.isNotEmpty
                                //           : provider.certifiedLocationList
                                //               .isNotEmpty;
                                //
                                //       if (!canExport) return null; // disable
                                //
                                //       return () async {
                                //         showDialog(
                                //           context: context,
                                //           builder: (BuildContext context) {
                                //             return ExportDialog(
                                //               accountId: widget.accountID!,
                                //               subAccountId:
                                //                   widget.subAccountID!,
                                //               sovId: "",
                                //               locationId: selectedMainTab == 0
                                //                   ? provider.myLocationList
                                //                       .map((loc) =>
                                //                           loc.id ?? "")
                                //                       .toList()
                                //                   : provider
                                //                       .certifiedLocationList
                                //                       .map((loc) =>
                                //                           loc.id ?? "")
                                //                       .toList(),
                                //             );
                                //           },
                                //         );
                                //       };
                                //     })(),
                                //   ),
                              ],
                            ),
                          );
                        });
                      },
                    )
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
                                  // Text(widget.accountID.toString()),
                                  // Text(widget.subAccountID.toString()),
                                  // SizedBox(height: CustomSpacing.one),
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
                                                    style: typography
                                                        .InputLabel),
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
                                                            widget.accountID ??
                                                                "",
                                                            accountName:
                                                            widget
                                                                .accountName ??
                                                                "",
                                                          ),
                                                    ),
                                                        (route) => false,
                                                  );
                                                },
                                                child: Text(
                                                    widget.subAccountName,
                                                    style: typography
                                                        .InputLabel),
                                              ),
                                              Text(' > ',
                                                  style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.white70)),
                                              Text(
                                                _masterTabController!.index == 0
                                                    ? "Location list"
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
                                        mainAxisAlignment: MainAxisAlignment
                                            .end,
                                        children: [
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
                                                        .of<
                                                        JobMonitoringProvider>(
                                                        context,
                                                        listen: false);
                                                    try {
                                                      Map<String, dynamic>?
                                                      summaryData =
                                                      await provider
                                                          .fetchLocationSummary(
                                                          widget
                                                              .accountID!,
                                                          widget
                                                              .subAccountID!,
                                                          '');

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
                                                                width: MediaQuery
                                                                    .of(
                                                                    context)
                                                                    .size
                                                                    .width *
                                                                    2.5,
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
                                                              style: Theme
                                                                  .of(
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
                                                            style: Theme
                                                                .of(
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
                                      color: Theme
                                          .of(context)
                                          .colorScheme
                                          .surfaceContainerHigh,
                                      borderRadius: BorderRadius.circular(
                                          16), // Rounded edges
                                    ),
                                    margin: EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 0),
                                    child: DefaultTabController(
                                      length: _masterTabController?.length ?? 1,
                                      child: Column(
                                        children: <Widget>[
                                          // Container for the TabBar with arrows
                                          Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                              BorderRadius.circular(16),
                                              color: Theme
                                                  .of(context)
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
                                                        Tab(
                                                          text: LanguageService
                                                              .getTranslated(
                                                              context,
                                                              "drawer_menu_locations"),
                                                        ),

                                                        // 🔽 Tab with dropdown

                                                        // const Tab(text: 'Shared'),

                                                        if (isSuperAdmin ||
                                                            isPgAdmin)
                                                          Tab(
                                                            text: LanguageService
                                                                .getTranslated(
                                                                context,
                                                                "configuration"),
                                                          ),
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
                                    child: RepaintBoundary(
                                      child: TabBarView(
                                        physics: NeverScrollableScrollPhysics(),
                                        controller: _masterTabController,
                                        children: [
                                          Consumer<MyLocationListProvider>(
                                            builder: (context,
                                                myLocationListProvider, child) {
                                              return RefreshIndicator(
                                                onRefresh: () async {
                                                  myLocationListProvider.page =
                                                  1;
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
                                                      Screens
                                                          .certifiedLocationList) {
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
                                                      widget
                                                          .initialSubProcessId,
                                                    );
                                                  }
                                                },
                                                child: _getLocationListBodyUI(
                                                    myLocationListProvider, ""),
                                              );
                                            },
                                          ),
                                          // _getSharedComingSoonUI("shared"),
                                          if (isSuperAdmin || isPgAdmin)
                                            ConfigurationTab(
                                              accountId: widget.accountID,
                                              subaccountId: widget.subAccountID,
                                              updateallflag: "false",
                                              level: "local",
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (_showOverlay_mylocation) _buildOverlay(),
                        // Positioned(
                        //   bottom: 110, // adjust above SpeedDial
                        //   right: 16,
                        //   child: GestureDetector(
                        //     onTap: () {
                        //       showModalBottomSheet(
                        //         context: context,
                        //         isScrollControlled: true,
                        //         useSafeArea: true,
                        //         backgroundColor: Colors.transparent,
                        //         builder: (_) =>
                        //             _ChatbotBottomSheet(
                        //               locationId: locationProfileProvider
                        //                   .locationProfile?.finalAddress
                        //                   ?.locationId
                        //                   .toString(),
                        //               accountId: widget.accountID!,
                        //               subAccountId: widget.subAccountID!,
                        //               accountName: widget.accountName,
                        //               subAccountName: widget.subAccountName,
                        //             ),
                        //       );
                        //     },
                        //     child: Container(
                        //       padding:
                        //       EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                        //       decoration: BoxDecoration(
                        //         color: Colors.black87,
                        //         borderRadius: BorderRadius.circular(25),
                        //         boxShadow: [
                        //           BoxShadow(
                        //             color: Colors.black26,
                        //             blurRadius: 6,
                        //           ),
                        //         ],
                        //       ),
                        //       child: Row(
                        //         mainAxisSize: MainAxisSize.min,
                        //         children: [
                        //           Text(
                        //             "Need Help?",
                        //             style: TextStyle(color: Colors.white),
                        //           ),
                        //           SizedBox(width: 8),
                        //           CircleAvatar(
                        //             radius: 16,
                        //             backgroundColor: AppColors.primaryMain,
                        //             child: Icon(Icons.smart_toy,
                        //                 color: Colors.white, size: 18),
                        //           )
                        //         ],
                        //       ),
                        //     ),
                        //   ),
                        // ),
                      ],
                    ),
                    endDrawer: Drawer(
                      child: SafeArea(
                        child: ListingsFilterScreen(
                          accountId: widget.accountID!,
                          subAccountId: widget.subAccountID!,
                          sovId: widget.accountID!,
                          searchQuery: locationQuery,
                          showGeoRatings: selectedMainTab == 0 &&
                              selectedTab != 1,
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

  Widget _buildOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.7), // dim background/ dim background
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF232323),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(11),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// Play icon + logo area
                InkWell(
                  onTap: () async {
                    const url = 'https://youtu.be/v11B3l3Fyuc';
                    if (await canLaunchUrl(Uri.parse(url))) {
                      await launchUrl(Uri.parse(url),
                          mode: LaunchMode.externalApplication);
                    }
                    ;
                  },
                  child: SizedBox(
                    width: double.infinity,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SvgPicture.asset(
                        'assets/images/userguide.svg',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                const Text(
                  "Create Location & Bulk Upload",
                  style: TextStyle(
                    color: AppColors.primaryMain,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  "Add a new location under your sub-account to track and manage usage. Quickly add multiple locations at once with bulk upload.",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryMain,
                        side: const BorderSide(color: AppColors.primaryMain),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _closeOverlay,
                      child: const Text("Skip", style: TextStyle(fontSize: 14)),
                    ),
                    Spacer(),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryMain,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12), // Reduce horizontal space
                      ),
                      onPressed: () async {
                        _closeOverlay();
                        setState(() {
                          _isLoading = true;
                        });

                        await _setClaims();
                        await Future.delayed(Duration(seconds: 1));

                        // Cancel timers and debounce before navigating
                        _isDisposed = true;
                        _refreshTimer?.cancel();
                        _timer?.cancel();
                        deBouncer?.cancel();

                        final result =
                        await Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) =>
                                AddLocationScreen(
                                  accountId: widget.accountID!,
                                  subAccountId: widget.subAccountID!,
                                  sovId: "",
                                  accountName: widget.accountName,
                                  subAccountName: widget.subAccountName,
                                )));

                        _isDisposed = false;
                        _startRefreshTimer(widget.accountID!,
                            widget.subAccountID!); // recreate timer
                        // deBouncer = Debouncer(milliseconds: 500);//  Re-create debounce instance
                        _getSovUploadStatus();
                        setState(() => _isLoading = false);

                        if (result == true) {
                          await getdata(
                              widget.accountID!, widget.subAccountID!);
                          _startRefreshTimer(
                              widget.accountID!, widget.subAccountID!);
                          await Provider.of<MyLocationListProvider>(context,
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
                      },
                      child: const Text("Add Location",
                          style: TextStyle(color: Colors.black)),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryMain,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12), // Reduce horizontal space
                        ),
                        onPressed: () async {
                          _closeOverlay();
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
                            String tempProcessId = await SharedPreferenceService
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
                        }, //_closeOverlay,
                        child: Icon(
                          Icons.upload,
                          color: Colors.black,
                        )
                      //const Text("Bulk Upload",
                      //     style: TextStyle(color: Colors.black)),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _getLocationListBodyUI(MyLocationListProvider myLocationListProvider,
      String sovID) {
    final isSelectionMode =
        myLocationListProvider.selectedLocationIds.isNotEmpty ||
            myLocationListProvider.isGlobalSelectAll;

    List<String> selectedIds = [];
    var typography = CustomTypography(context);
    return Column(
      children: [
        SizedBox(height: CustomSpacing.two),
        selectedMainTab == 0
            ? Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          padding: const EdgeInsets.fromLTRB(8, 8, 0, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme
                  .of(context)
                  .colorScheme
                  .surfaceContainerHighest, // Set your border color here
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
                          if (isSelectionMode) ...[
                            SizedBox(width: CustomSpacing.two),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 1, vertical: 4),
                              decoration: BoxDecoration(
                                color: Theme
                                    .of(context)
                                    .colorScheme
                                    .surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                locationListProvider.selectedCount.toString(),
                                style: typography.Body1.copyWith(
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            // const SizedBox(width: 2),
                            TextButton(
                              onPressed: () {
                                final isCertified = _selectedScreen ==
                                    Screens.certifiedLocationList;

                                if (!locationListProvider.isGlobalSelectAll) {
                                  locationListProvider.selectAllGlobal(
                                    totalCount: isCertified
                                        ? locationListProvider
                                        .certifiedLocationHits
                                        : locationListProvider.locationHits,
                                  );
                                } else {
                                  locationListProvider.clearSelection();
                                }
                              },
                              child: Text(
                                locationListProvider.isGlobalSelectAll
                                    ? 'Deselect All'
                                    : 'Select All',
                                style: typography.Body1.copyWith(
                                  color: AppColors.primaryMain,
                                ),
                              ),
                            ),
                            const Spacer(),
                            if (locationListProvider.isGlobalSelectAll ||
                                locationListProvider
                                    .selectedLocationIds.isNotEmpty) ...[
                              // if (locationListProvider.isGlobalSelectAll ||
                              //     locationListProvider.selectedLocationIds.length >
                              //         1) ...[
                              Consumer<MyLocationListProvider>(
                                builder: (context, provider, _) {
                                  return IconButton(
                                    tooltip: 'Add to SOV Monitoring',
                                    icon: provider.isMonitorLoading
                                        ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                        : const Icon(Icons.track_changes),
                                    onPressed: provider.isMonitorLoading
                                        ? null
                                        : () async {
                                      try {
                                        if (!context.mounted) return;

                                        /// STEP 1 - SHOW MENU FIRST
                                        final action =
                                        await showMenu<String>(
                                          context: context,
                                          position:
                                          const RelativeRect.fromLTRB(
                                            100,
                                            300,
                                            20,
                                            0,
                                          ),
                                          items: const [
                                            PopupMenuItem(
                                              value: 'selected',
                                              child: Text(
                                                'Add Selected to SOV Monitoring',
                                              ),
                                            ),
                                            PopupMenuItem(
                                              value: 'all',
                                              child: Text(
                                                'Add All Locations to SOV Monitoring',
                                              ),
                                            ),
                                          ],
                                        );

                                        if (action == null) {
                                          return;
                                        }

                                        /// STEP 2 - START LOADER AFTER SELECTION
                                        provider.isMonitorLoading = true;
                                        provider.notifyListeners();

                                        List<MyLocation>
                                        monitoringLocations = [];

                                        /// ADD SELECTED LOCATIONS
                                        if (action == 'selected') {
                                          if (provider.selectedLocationIds
                                              .isEmpty) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Please select at least one location',
                                                ),
                                              ),
                                            );
                                            return;
                                          }

                                          monitoringLocations =
                                              provider.myLocationList
                                                  .where(
                                                    (location) =>
                                                    provider
                                                        .selectedLocationIds
                                                        .contains(
                                                      location.locationId,
                                                    ),
                                              )
                                                  .toList();
                                        }

                                        /// ADD ALL LOCATIONS
                                        else {
                                          await provider
                                              .fetchAllLocationList(
                                            context,
                                            widget.accountID!,
                                            widget.subAccountID!,
                                            processId:
                                            widget.initialProcessId,
                                            subProcessId:
                                            widget.initialSubProcessId,
                                          );

                                          monitoringLocations =
                                          List<MyLocation>.from(provider
                                              .fullLocationList);
                                        }

                                        if (!context.mounted) return;

                                        /// STEP 3 - OPEN MONITORING BOTTOM SHEET
                                        final result =
                                        await showModalBottomSheet<
                                            bool>(
                                          context: context,
                                          isScrollControlled: true,
                                          backgroundColor:
                                          Colors.transparent,
                                          builder: (_) =>
                                              SizedBox(
                                                height: MediaQuery
                                                    .of(context)
                                                    .size
                                                    .height *
                                                    .80,
                                                child: MonitoringBottomSheet(
                                                  locations:
                                                  monitoringLocations,
                                                  sovId: mononitoringsovId,
                                                  eathquakCount:
                                                  eathquakeLicenseCount!,
                                                  hurricaneCount:
                                                  hurricaneLicensecount!,
                                                ),
                                              ),
                                        );

                                        /// STEP 4 - REFRESH AFTER SUCCESS
                                        if (result == true &&
                                            context.mounted) {
                                          final locationListProvider =
                                          Provider.of<
                                              MyLocationListProvider>(
                                            context,
                                            listen: false,
                                          );

                                          final selectedIds =
                                          Set<String>.from(
                                            locationListProvider
                                                .selectedLocationIds,
                                          );

                                          locationListProvider.page = 1;
                                          locationListProvider
                                              .certifiedPage = 1;
                                          locationListProvider
                                              .myLocationList
                                              .clear();

                                          await Future.wait([
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
                                              '',
                                            ),
                                            locationListProvider
                                                .fetchAllLocationList(
                                              context,
                                              widget.accountID!,
                                              widget.subAccountID!,
                                              processId:
                                              widget.initialProcessId,
                                              subProcessId: widget
                                                  .initialSubProcessId,
                                            ),
                                          ]);

                                          await getdata(
                                            widget.accountID!,
                                            widget.subAccountID!,
                                          );

                                          for (final loc
                                          in locationListProvider
                                              .myLocationList) {
                                            loc.isSelected =
                                                selectedIds.contains(
                                                  loc.locationId,
                                                );
                                          }

                                          locationListProvider
                                              .notifyListeners();
                                        }
                                      } catch (e) {
                                        debugPrint(
                                          "Monitoring Error => $e",
                                        );
                                      } finally {
                                        provider.isMonitorLoading = false;
                                        provider.notifyListeners();
                                      }
                                    },
                                  );
                                },
                              ),

                              hasAnyPlan
                                  ? Consumer<MyLocationListProvider>(
                                builder: (context, provider, _) {
                                  final isBusy =
                                      provider.isAddToSOVPreparing;

                                  return InkWell(
                                    onTap: isBusy
                                        ? null
                                        : () async {
                                      final p = Provider.of<
                                          MyLocationListProvider>(
                                          context,
                                          listen: false);

                                      try {
                                        p.setPreparing(
                                            true); // 🔹 ONLY here

                                        List<String> locationIds;

                                        if (p.isGlobalSelectAll) {
                                          locationIds = await p
                                              .fetchAllLocationIdsForAddTag(
                                            accountId:
                                            widget.accountID!,
                                            subAccountId:
                                            widget.subAccountID!,
                                          );
                                        } else {
                                          locationIds = p
                                              .selectedLocationIds
                                              .toList();
                                        }

                                        if (locationIds.isEmpty) {
                                          ScaffoldMessenger.of(
                                              context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    "Please select at least one location")),
                                          );
                                          return;
                                        }
                                        print(locationIds);

                                        await p.addSelectedToSOV1(
                                          context,
                                          widget.accountID!,
                                          widget.subAccountID!,
                                          widget.accountName,
                                          widget.subAccountName,
                                          _masterTabController,
                                          locationIds,
                                        );
                                      } finally {
                                        p.setPreparing(
                                            false); // 🔹 STOP loader BEFORE dialog submit
                                      }
                                    },
                                    child: provider.isAddToSOVLoading
                                        ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child:
                                      CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                        : const Icon(Icons.ballot),
                                  );
                                },
                              )
                                  : SizedBox(),

                              Consumer<MyLocationListProvider>(
                                builder: (context, provider, _) {
                                  return IconButton(
                                    tooltip: 'Export Selected',
                                    icon: provider.isExportLoading
                                        ? const SizedBox(
                                      width: 8,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                        : const Icon(Icons.download),
                                    onPressed: provider.isExportLoading
                                        ? null
                                        : () async {
                                      provider.isExportLoading = true;
                                      provider.notifyListeners();

                                      try {
                                        if (provider.isGlobalSelectAll) {
                                          showDialog(
                                            context: context,
                                            builder: (_) =>
                                                ExportDialog(
                                                  accountId: widget.accountID!,
                                                  subAccountId:
                                                  widget.subAccountID!,
                                                  locationId: const [],
                                                  sovId: 'GLOBAL_SELECT_ALL',
                                                ),
                                          );
                                        } else {
                                          final selectedIds = provider
                                              .selectedLocationIds
                                              .toList();

                                          if (selectedIds.isEmpty) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                    "Please select at least one location"),
                                              ),
                                            );
                                            return;
                                          }

                                          showDialog(
                                            context: context,
                                            builder: (_) =>
                                                ExportDialog(
                                                  accountId: widget.accountID!,
                                                  subAccountId:
                                                  widget.subAccountID!,
                                                  locationId: selectedIds,
                                                  sovId: '',
                                                ),
                                          );
                                        }
                                      } finally {
                                        provider.isExportLoading = false;
                                        provider.notifyListeners();
                                      }
                                    },
                                  );
                                },
                              ),
                              Consumer<MyLocationListProvider>(
                                builder: (context, provider, _) {
                                  final bool isBusy =
                                      provider.isAddTagFetchingIds ||
                                          provider.isAddTagsLoading;

                                  return IconButton(
                                    tooltip: 'Add Tag',
                                    icon: isBusy
                                        ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                        : const Icon(Symbols.note_stack_add),
                                    onPressed: isBusy
                                        ? null
                                        : () async {
                                      if (provider.isGlobalSelectAll) {
                                        await provider.showAddTagDialog(
                                          context,
                                          widget.accountID!,
                                          widget.subAccountID!,
                                          const [],
                                          isGlobal: true,
                                        );
                                        return;
                                      }

                                      final selectedIds = provider
                                          .selectedLocationIds
                                          .toList();

                                      if (selectedIds.isEmpty) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                "Please select at least one location"),
                                          ),
                                        );
                                        return;
                                      }

                                      await provider.showAddTagDialog(
                                        context,
                                        widget.accountID!,
                                        widget.subAccountID!,
                                        selectedIds,
                                        isGlobal: false,
                                      );
                                    },
                                  );
                                },
                              ),

                              // Consumer<MyLocationListProvider>(
                              //   builder: (context, provider, _) {
                              //     final bool isBusy =
                              //         provider.isAddTagFetchingIds ||
                              //             provider.isAddTagsLoading;
                              //
                              //     return IconButton(
                              //       tooltip: 'Add Tag',
                              //       icon: isBusy
                              //           ? const SizedBox(
                              //               width: 18,
                              //               height: 18,
                              //               child: CircularProgressIndicator(
                              //                   strokeWidth: 2),
                              //             )
                              //           : const Icon(Symbols.note_stack_add),
                              //       onPressed: isBusy
                              //           ? null
                              //           : () async {
                              //               if (provider.isGlobalSelectAll) {
                              //                 final allIds = await provider
                              //                     .fetchAllLocationIdsForAddTag(
                              //                   accountId: widget.accountID!,
                              //                   subAccountId:
                              //                       widget.subAccountID!,
                              //                 );
                              //
                              //                 debugPrint(
                              //                     "ALL IDS COUNT: ${allIds.length}");
                              //
                              //                 if (allIds.isEmpty) {
                              //                   ScaffoldMessenger.of(context)
                              //                       .showSnackBar(
                              //                     const SnackBar(
                              //                       content: Text(
                              //                           "No locations found"),
                              //                     ),
                              //                   );
                              //                   return;
                              //                 }
                              //
                              //                 await provider.showAddTagDialog(
                              //                   context,
                              //                   widget.accountID!,
                              //                   widget.subAccountID!,
                              //                   allIds,
                              //                   isGlobal: false, // explicit IDs
                              //                 );
                              //               } else {
                              //                 final selectedIds = provider
                              //                     .selectedLocationIds
                              //                     .toList();
                              //
                              //                 debugPrint(
                              //                     "ADD TAG → IDS: $selectedIds");
                              //
                              //                 if (selectedIds.isEmpty) {
                              //                   ScaffoldMessenger.of(context)
                              //                       .showSnackBar(
                              //                     const SnackBar(
                              //                       content: Text(
                              //                           "Please select at least one location"),
                              //                     ),
                              //                   );
                              //                   return;
                              //                 }
                              //
                              //                 await provider.showAddTagDialog(
                              //                   context,
                              //                   widget.accountID!,
                              //                   widget.subAccountID!,
                              //                   selectedIds,
                              //                   isGlobal: false,
                              //                 );
                              //               }
                              //             },
                              //     );
                              //   },
                              // ),
                              Consumer<MyLocationListProvider>(
                                builder: (context, provider, _) {
                                  return IconButton(
                                    icon: provider.isDeleteLocationLoading
                                        ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                        : const Icon(Icons.delete_outline),
                                    tooltip: 'Delete Selected',
                                    onPressed: provider.isDeleteLocationLoading
                                        ? null
                                        : () {
                                      showDialog(
                                        context: context,
                                        builder: (_) =>
                                            AlertDialog(
                                              title: const Text(
                                                  'Delete Selected Locations'),
                                              content: Text(
                                                'Are you sure you want to delete '
                                                    '${provider
                                                    .isGlobalSelectAll
                                                    ? provider
                                                    .totalLocationCount
                                                    : provider
                                                    .selectedLocationIds
                                                    .length}'
                                                    ' locations?',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  child: const Text('Cancel'),
                                                ),
                                                TextButton(
                                                  onPressed: () async {
                                                    Navigator.pop(context);

                                                    await provider
                                                        .deleteSelectedLocations1(
                                                      context,
                                                      widget.accountID!,
                                                      widget.subAccountID!,
                                                    );
                                                  },
                                                  child: const Text('Delete'),
                                                ),
                                              ],
                                            ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ] else
                            ...[
                              SizedBox(
                                width: 8,
                              ),
                              Expanded(
                                child: Row(
                                  children: [
                                    //SizedBox(width: CustomSpacing.two),
                                    Text(
                                      LanguageService.getTranslated(
                                          context, "my_locations"),
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
                              // SizedBox(height: CustomSpacing.eight),
                            ]
                        ],
                      );
                    });
              }),
        )
            : Container(),
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
                        Provider
                            .of<LocationListProvider>(context,
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
            color: Theme
                .of(context)
                .colorScheme
                .surfaceContainerHigh,
            borderRadius: BorderRadius.circular(8),
          ),
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          child: ClipRRect(
            clipBehavior: Clip.antiAlias,
            borderRadius: BorderRadius.circular(8),
            child: GNav(
                backgroundColor:
                Theme
                    .of(context)
                    .colorScheme
                    .surfaceContainerHigh,
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
                color: Theme
                    .of(context)
                    .brightness == Brightness.dark
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
                    text:
                    LanguageService.getTranslated(context, "location_list"),
                  ),
                  GButton(
                    key: keyFeature2,
                    icon: Remix.bar_chart_box_ai_line,
                    text:
                    LanguageService.getTranslated(context, "overall_score"),
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
                    text: LanguageService.getTranslated(context, "map_view"),
                  ),
                ]),
          ),
        ),
        SizedBox(height: CustomSpacing.two),
        Expanded(
          child: RepaintBoundary(
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
                                    "all",
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
                                        style: typography
                                            .BottomNavigationActiveLabel
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
                                    "certified",
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
                        physics: NeverScrollableScrollPhysics(),
                        children: [
                          _getLocationListAllUI(),
                          _getLocationListCertifiedUI(),
                        ],
                      ),
                    ),
                  ],
                ),
                LocationTable(
                  // locations:
                  accountID: widget.accountID!,
                  subAccountID: widget.subAccountID!,
                  initialProcessId: widget.initialProcessId,
                  initialSubProcessId: widget.initialSubProcessId,
                ),

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
      return Theme
          .of(context)
          .textTheme
          .bodyLarge
          ?.color ?? Colors.black;
    }
    return (rating >= 4) ? Colors.white : Colors.black;
  }

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

        final bool isProcessing = newStatus == 'processing';
        final double progressPct = totalProcessesRaw > 0
            ? (totalCompletedRaw / totalProcessesRaw) * 100
            : 0.0;
        final bool forceCompleted = isProcessing && progressPct >= 99.5;

        final bool isCompleted = newStatus == 'completed' || forceCompleted;
        final bool isFailed = newStatus == 'failed' || newStatus == 'error';

        if (newStatus != _lastProcessStatus) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _lastProcessStatus = newStatus;

            // 🔥 Update FAB based on process status
            if (newStatus == "processing") {
              fabStatusNotifier.value = "processing";
            } else if (newStatus == "completed") {
              fabStatusNotifier.value = "completed";
            } else {
              fabStatusNotifier.value = "idle"; // normal
            }

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
            //
            // Text(isProcessing.toString()),
            // Text(isProcessing.toString()),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Builder(
                key: ValueKey(newStatus),
                builder: (_) {
                  if (isFailed) return const SizedBox.shrink();
                  if (isProcessing) return _ProcessingRow(data);

                  if (isCompleted && !_hasReloaded) {
                    _hasReloaded = true;

                    WidgetsBinding.instance.addPostFrameCallback((_) async {
                      await Future.delayed(
                          const Duration(seconds: 10)); // optional delay

                      _masterTabController?.animateTo(0);
                      final provider = Provider.of<MyLocationListProvider>(
                          context,
                          listen: false);

                      provider.page = 1;
                      provider.myLocationList.clear();

                      provider.fetchLocationList(
                        context,
                        "",
                        1,
                        10,
                        widget.accountID,
                        widget.subAccountID,
                        widget.initialProcessId,
                        widget.initialSubProcessId,
                        "",
                      );
                    });

                    return _CompletedRow(data);
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _CompletedRow(Map<String, dynamic> data) {
    final percentage = data['processData']?['progress'] ?? 100;
    return _AutoHideCompletedRow(percentage: percentage);
  }

  Widget _ProcessingRow(Map<String, dynamic> data) {
    final typography = CustomTypography(context);

    final List<dynamic> activeProcesses = data['activeProcesses'] ?? [];
    final int totalProcessesCount = activeProcesses.length;
    int currentIndex = (data['currentProcessIndex'] ?? 0) as int;

    // Clamp index safely
    currentIndex = currentIndex.clamp(
        0, totalProcessesCount == 0 ? 0 : totalProcessesCount - 1);
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
            builder: (context) =>
                ProcessMonitoringScreen(
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.lightBlue[500],
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                "${(currentIndex.clamp(0, totalProcessesCount - 1) +
                    1)}/${totalProcessesCount}",
                style: typography.Caption.copyWith(
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
      if (ModalRoute
          .of(context)
          ?.isCurrent != true) return;

      if (_activeAccountKey != key) return; // don't leak across pages
      await context
          .read<MyLocationListProvider>()
          .fetchLocationConflictList(
        context,
        "",
        1,
        1,
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
          10,
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

  Widget _buildProcessSummary(Map<String, dynamic>? summaryData) {
    if (summaryData == null || summaryData.isEmpty) {
      return Container(
          decoration: BoxDecoration(
            color: Theme
                .of(context)
                .hoverColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(child: CircularProgressIndicator())); // Show loader
    }

    var typography = CustomTypography(context);
    final hazardVendorData = summaryData['hazard_rating_summary'] ?? {};
    return Container(
      decoration: BoxDecoration(
        color: Theme
            .of(context)
            .hoverColor,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Container(
        padding: EdgeInsets.all(16), // Add padding for better spacing
        decoration: BoxDecoration(
          color: Theme
              .of(context)
              .hoverColor,
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
              height: MediaQuery
                  .of(context)
                  .size
                  .height / 2.8,
              child: _buildHazardVendorSummary(hazardVendorData, typography),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHazardVendorSummary(Map<dynamic, dynamic> hazardVendorData,
      CustomTypography typography) {
    // if (hazardVendorData.isEmpty) {
    //   return SizedBox.shrink();
    // }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            LanguageService.getTranslated(context, "hazard_rating_summary"),
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
                    color: Theme
                        .of(context)
                        .hoverColor,
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
                            color: Theme
                                .of(context)
                                .colorScheme
                                .onSurface,
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
                                  color: Theme
                                      .of(context)
                                      .disabledColor,
                                ),
                                initiallyExpanded: false,
                                title: Text(
                                  LanguageService.getTranslated(context,
                                      "hazard_risk_score_wise_locations"),
                                  style: typography.Body2.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Theme
                                        .of(context)
                                        .disabledColor,
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

  Widget _buildHazardDetailRow(String label, String value,
      CustomTypography typography) {
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
                        color: Theme
                            .of(context)
                            .colorScheme
                            .onSurface,
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
      // margin: const EdgeInsets.symmetric(horizontal: 1.0),
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

  Widget _buildRatingCard(String title, int count,
      CustomTypography typography) {
    return Container(
      width: MediaQuery
          .sizeOf(context)
          .width * 0.4,
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 22),
      decoration: BoxDecoration(
        color: Theme
            .of(context)
            .colorScheme
            .surfaceContainerHighest,
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
                                    "Country: ${locationListProvider.countries
                                        .join(', ')}"),
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
                                    "Certifications: ${locationListProvider
                                        .certifications.join(', ')}"),
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
                          // 🔹 DATA COMPLETENESS FILTER CHIP
                          if (locationListProvider.hasDataCompletenessFilter)
                            Padding(
                              padding:
                              const EdgeInsets.symmetric(horizontal: 4.0),
                              child: Chip(
                                label: Text(
                                  "Data Completeness: ${locationListProvider
                                      .dataCompletenessScore}",
                                ),
                                onDeleted: () {
                                  locationListProvider
                                      .clearDataCompletenessScore();

                                  locationListProvider.fetchLocationList(
                                    context,
                                    locationQuery,
                                    1,
                                    10,
                                    widget.accountID,
                                    widget.subAccountID,
                                    widget.initialProcessId,
                                    widget.initialSubProcessId,
                                    '',
                                  );
                                },
                              ),
                            ),

                          if (locationListProvider.rating.isNotEmpty)
                            Padding(
                              padding:
                              const EdgeInsets.symmetric(horizontal: 4.0),
                              child: Chip(
                                label: Text(
                                    "Ratings: ${locationListProvider.rating
                                        .join(', ')}"),
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
                              "We’ve found ${conflictLocations
                                  .length} potential matches for the provided location. Please review them and select the correct match to ",
                              style: typography.Body2,
                            ),
                            TextSpan(
                              text: "resolve the conflict",
                              style: typography.Body2.copyWith(
                                color: (_lastProcessStatus.toString() ==
                                    'processing')
                                    ? Colors
                                    .grey // Disabled color when processing
                                    : AppColors.primaryMain,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: (_lastProcessStatus
                                  .toString() ==
                                  'processing')
                                  ? null
                                  : (TapGestureRecognizer()
                                ..onTap = () {
                                  for (int i = 0;
                                  i < conflictLocations.length;
                                  i++) {
                                    print(
                                        'Item $i - Geocoded Address: ${conflictLocations[i]
                                            .geocodedAddress}');
                                  }

                                  Navigator.of(context)
                                      .push(MaterialPageRoute(
                                    builder: (_) =>
                                        ConflictsTab(
                                          processId:
                                          widget.accountID ?? "",
                                          accountId:
                                          widget.accountID ?? "",
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
                                          geocodingAddress:
                                          conflictLocations
                                              .first
                                              .finalAddress
                                              ?.address ??
                                              "",
                                          conflict: conflictLocations
                                              .first.conflicts,
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
                                          widget
                                              .initialSubProcessId,
                                          '');
                                      locationListProvider
                                          .fetchLocationConflictList(
                                        context,
                                        "",
                                        1,
                                        1,
                                        widget.accountID,
                                        widget.subAccountID,
                                        widget.initialProcessId,
                                        widget
                                            .initialSubProcessId,
                                      )
                                          .then(
                                              (_) => setState(() {}));
                                    }
                                  });
                                }),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ] else
                if (locationListProvider.isConflict == true) ...[
                  // ] else if (locationListProvider.isHazardCanStart == true) ...[
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
                                  onTap: (_lastProcessStatus.toString() ==
                                      'processing')
                                      ? null
                                      : () async {
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
                                      color: (_lastProcessStatus
                                          .toString() ==
                                          'processing')
                                          ? Colors
                                          .grey // Disabled color when processing
                                          : AppColors.primaryMain,
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
                  final selectedIds = Set<String>.from(
                      locationListProvider.selectedLocationIds);

                  // Store selected item IDs before refreshing
                  // List<String?> selectedItemIds = locationListProvider
                  //     .selectedLocations
                  //     .map((item) => item.id)
                  //     .toList();
                  //
                  // // Clear existing selections before the refresh starts
                  // locationListProvider.selectedLocations.clear();
                  // locationListProvider
                  //     .notifyListeners(); // Update UI immediately

                  // Refresh data in parallel
                  locationListProvider.certifiedPage = 1;
                  await Future.wait([
                    locationListProvider.fetchLocationConflictList(
                      context,
                      "",
                      1,
                      1,
                      widget.accountID,
                      widget.subAccountID,
                      widget.initialProcessId,
                      widget.initialSubProcessId,
                    ),
                    // .then((_) => setState(() {})),
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

                    locationListProvider.fetchAllLocationList(
                      context,
                      widget.accountID,
                      widget.subAccountID,
                      processId: widget.initialProcessId,
                      subProcessId: widget.initialSubProcessId,
                    ),
                  ]);

                  // Restore selection after refresh
                  for (final loc
                  in locationListProvider.myLocationList) {
                    loc.isSelected = locationListProvider
                        .selectedLocationIds
                        .contains(loc.id);
                  }

                  // locationListProvider.selectedLocations.addAll(
                  //   locationListProvider.myLocationList.where(
                  //       (item) => selectedItemIds.contains(item.id)),
                  // );

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
                              hasHazardHubCount: hasHazardHubCount,
                              hasVendorData: locationListProvider
                                  .myLocationList[index]
                                  .hasVendorData,
                              usFlag: locationListProvider
                                  .myLocationList[index].usFlag,
                              hasSov: locationListProvider
                                  .myLocationList[index].hasSov,
                              hasAnyPlan: hasAnyPlan.toString(),
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
                              dataCompletenessScore:
                              locationListProvider
                                  .myLocationList[index]
                                  .dataCompleteness
                                  ?.toString() ??
                                  1,
                              isAutoCertified: true,
                              tags: (locationListProvider
                                  .myLocationList[index].tags ??
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
                                // ✅ SINGLE LOCATION TAG
                                locationListProvider.showAddTagDialog(
                                  context,
                                  widget.accountID!,
                                  widget.subAccountID!,
                                  [locationId], // ⬅️ wrap in list
                                  isGlobal:
                                  false, // ⬅️ explicitly NOT global
                                );
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
                              onNavigateBack: () async {
                                await locationListProvider
                                    .fetchLocationList(
                                  context,
                                  locationQuery,
                                  1,
                                  8,
                                  widget.accountID,
                                  widget.subAccountID,
                                  widget.initialProcessId,
                                  widget.initialSubProcessId,
                                  '',
                                );

                                if (mounted) {
                                  setState(() {});
                                }
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
                            "Query: $locationQuery, Page: ${locationListProvider
                                .page}");
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
                      hasHazardHubCount: hasHazardHubCount,
                      hasVendorData: locationListProvider
                          .myLocationList[index].hasVendorData,
                      usFlag: locationListProvider
                          .myLocationList[index].usFlag,
                      hasSov: locationListProvider
                          .myLocationList[index].hasSov,
                      hasAnyPlan: hasAnyPlan.toString(),
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
                      dataCompletenessScore: locationListProvider
                          .myLocationList[index]
                          .dataCompleteness !=
                          null
                          ? locationListProvider
                          .myLocationList[index].dataCompleteness!
                          : 1,

                      isAutoCertified: true,
                      tags: (locationListProvider
                          .myLocationList[index].tags ??
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
                        // ✅ SINGLE LOCATION TAG
                        locationListProvider.showAddTagDialog(
                          context,
                          widget.accountID!,
                          widget.subAccountID!,
                          [locationId], // ⬅️ wrap in list
                          isGlobal: false, // ⬅️ explicitly NOT global
                        );
                      },

                      // onAddTag: (locationId) {
                      //   // Show add tag dialog
                      //   // Implement bulk add tag
                      //   locationListProvider
                      //       .addTagsToSelectedLocations(
                      //           context,
                      //           widget.accountID!,
                      //           widget.subAccountID!,
                      //           locationId);
                      // },
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
                                    "Country: ${locationListProvider.countries
                                        .join(', ')}"),
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
                                    "Certifications: ${locationListProvider
                                        .certifications.join(', ')}"),
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
                                    "Ratings: ${locationListProvider.rating
                                        .join(', ')}"),
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
                          locationListProvider.fetchCertifiedLocationList(
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
                          10,
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
      hasHazardHubCount: hasHazardHubCount,
      hasVendorData: locationListProvider.myLocationList[index].hasVendorData,
      usFlag: locationListProvider.myLocationList[index].usFlag,
      hasSov: locationListProvider.myLocationList[index].hasSov,
      hasAnyPlan: hasAnyPlan.toString(),
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
      lat: (locationListProvider.certifiedLocationList.isNotEmpty &&
          index < locationListProvider.certifiedLocationList.length)
          ? locationListProvider
          .certifiedLocationList[index].finalAddress?.latitude
          .toString() ??
          ""
          : "",

      long: (locationListProvider.certifiedLocationList.isNotEmpty &&
          index < locationListProvider.certifiedLocationList.length)
          ? locationListProvider
          .certifiedLocationList[index].finalAddress?.longitude
          ?.toString() ??
          ""
          : "",

      overallScore: (locationListProvider.certifiedLocationList.isNotEmpty &&
          index < locationListProvider.certifiedLocationList.length)
          ? locationListProvider.certifiedLocationList[index].overallScore
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
      riskScore: int.tryParse(
        locationListProvider.certifiedLocationList[index].overallScore
            ?.toString() ??
            '',
      ) ??
          0,
      // riskScore: int.parse(locationListProvider
      //     .certifiedLocationList[index].overallScore
      //     .toString()),

      dataCompletenessScore: locationListProvider
          .certifiedLocationList[index].dataCompleteness
          ?.toString() ??
          '1',
      isAutoCertified: true,
      tags: (locationListProvider.certifiedLocationList[index].tags ?? []),
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
        // ✅ SINGLE LOCATION TAG
        locationListProvider.showAddTagDialog(
          context,
          widget.accountID!,
          widget.subAccountID!,
          [locationId], // ⬅️ wrap in list
          isGlobal: false, // ⬅️ explicitly NOT global
        );
      },

      // onAddTag: (locationId) {
      //   // Show add tag dialog
      //   // Implement bulk add tag
      //   locationListProvider.addTagsToSelectedLocations(
      //       context, widget.accountID!, widget.subAccountID!, locationId);
      // },
      // hazardProcess:
      //     (locationListProvider.myLocationList[index].isHazardProcess is bool)
      //         ? locationListProvider.myLocationList[index].isHazardProcess
      //         : false,
      hazardProcess: (locationListProvider.certifiedLocationList.isNotEmpty &&
          index < locationListProvider.certifiedLocationList.length)
          ? (locationListProvider.certifiedLocationList[index].isHazardProcess
      is bool
          ? locationListProvider
          .certifiedLocationList[index].isHazardProcess
          : false)
          : false,
      rented: (index < locationListProvider.certifiedLocationList.length)
          ? locationListProvider
          .certifiedLocationList[index].finalAddress?.rented ??
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

  void showDeleteConfirmationDialog(BuildContext context, Function onDelete,
      List<String> locationIds) {
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

  void _showUploadBottomSheet(String accountId, String subAccountId,
      String sovId) {
    var typography = CustomTypography(context);
    final _formKey = GlobalKey<FormState>();

    String? _sovError;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery
            .of(context)
            .size
            .height * 0.8,
      ),
      backgroundColor: Colors.black87,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext dialogContext) {
        return Consumer<UserProfileProvider>(
            builder: (context, userProfileProvider, child) {
              String? _fileError; // (if needed)
              void _handleTagInput(String value) {
                if (!value.contains(',')) return;

                final tag = value.replaceAll(',', '').trim();
                if (tag.isEmpty || tags.contains(tag)) return;

                setState(() {
                  tags.add(tag);
                });

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  tagController.clear();
                });
              }

              final trialStatus = userProfileProvider.trialInfo['status'] ?? '';
              int locations = userProfileProvider.trialInfo['locations'] ?? 0;
              int total = userProfileProvider.trialInfo['maxLocations'] ?? 0;
              return StatefulBuilder(
                builder: (sheetContext, StateSetter setState) {
                  return Padding(
                    padding: EdgeInsets.only(
                      left: 6,
                      right: 6,
                      bottom: MediaQuery
                          .of(sheetContext)
                          .viewInsets
                          .bottom,
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
                                    _fileError = null;
                                    String fileNameWithExtension =
                                        file.path
                                            .split('/')
                                            .last;
                                    _uploadedFileName = fileNameWithExtension
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
                                        LanguageService.getTranslated(
                                            context, "upload_hint"),
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
                                          Text('Max file size is 50 MB',
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
                                              LanguageService.getTranslated(
                                                  context, "cancel"),
                                              style: TextStyle(
                                                  color: Theme
                                                      .of(context)
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
                            if (_fileError != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8, left: 4),
                                child: Text(
                                  _fileError!,
                                  style: TextStyle(
                                      color: Colors.red, fontSize: 12),
                                ),
                              ),
                            // SizedBox(height: 20),
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
                              Form(
                                key: _tagFormKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // TextFormField(
                                    //   controller: tagController,
                                    //   style: const TextStyle(color: Colors.white),
                                    //   decoration: InputDecoration(
                                    //     labelText: LanguageService.getTranslated(
                                    //         context, "enter_tags"),
                                    //     labelStyle:
                                    //         const TextStyle(color: Colors.white),
                                    //     enabledBorder: const OutlineInputBorder(
                                    //       borderSide:
                                    //           BorderSide(color: Colors.grey),
                                    //     ),
                                    //     focusedBorder: const OutlineInputBorder(
                                    //       borderSide:
                                    //           BorderSide(color: Colors.blue),
                                    //     ),
                                    //     hintText: "Type tag and press ,",
                                    //     hintStyle:
                                    //         const TextStyle(color: Colors.white54),
                                    //   ),
                                    //   onChanged: (value) {
                                    //     if (value.contains(',')) {
                                    //       final tag =
                                    //           value.replaceAll(',', '').trim();
                                    //
                                    //       if (tag.isNotEmpty &&
                                    //           !tags.contains(tag)) {
                                    //         setState(() {
                                    //           tags.add(tag);
                                    //         });
                                    //       }
                                    //
                                    //       tagController.clear();
                                    //     }
                                    //   },
                                    //   onFieldSubmitted: (value) {
                                    //     final tag = value.trim();
                                    //     if (tag.isNotEmpty && !tags.contains(tag)) {
                                    //       setState(() {
                                    //         tags.add(tag);
                                    //       });
                                    //     }
                                    //     tagController.clear();
                                    //   },
                                    // ),
                                    //
                                    // const SizedBox(height: 10),
                                    //
                                    // /// 🔹 TAG LIST SHOWN BELOW
                                    // Wrap(
                                    //   spacing: 8,
                                    //   runSpacing: 33,
                                    //   children: tags.map((tag) {
                                    //     return Chip(
                                    //       label: Text(
                                    //         tag,
                                    //         style: const TextStyle(
                                    //             color: Colors.white),
                                    //       ),
                                    //       backgroundColor: Colors.grey,
                                    //       deleteIconColor: Colors.white,
                                    //       onDeleted: () {
                                    //         setState(() {
                                    //           tags.remove(tag);
                                    //         });
                                    //       },
                                    //     );
                                    //   }).toList(),
                                    // ),
                                  ],
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
                                  labelText: LanguageService.getTranslated(
                                      context, "account_name"),
                                  labelStyle: TextStyle(color: Colors.white54),
                                  enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: Colors.grey)),
                                  disabledBorder: OutlineInputBorder(
                                      borderSide:
                                      BorderSide(color: Colors.white54)),
                                  focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: Colors.blue)),
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
                                  labelText: LanguageService.getTranslated(
                                      context, "sub_account_name"),
                                  labelStyle: TextStyle(color: Colors.white54),
                                  enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: Colors.grey)),
                                  disabledBorder: OutlineInputBorder(
                                      borderSide:
                                      BorderSide(color: Colors.white54)),
                                  focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: Colors.blue)),
                                  hintStyle: TextStyle(color: Colors.white54),
                                ),
                              ),
                              SizedBox(height: 14),

                              Consumer<SOVListProvider>(
                                builder: (context, sovProvider, child) {
                                  return Column(
                                    children: [
                                      Autocomplete<String>(
                                        optionsBuilder:
                                            (
                                            TextEditingValue textEditingValue) {
                                          if (textEditingValue.text == '') {
                                            return const Iterable<
                                                String>.empty();
                                          }
                                          sovProvider.fetchSovList(
                                            context,
                                            textEditingValue.text,
                                            1,
                                            100,
                                            '',
                                          );
                                          return sovProvider.filtersovlist
                                              .map((sov) => sov.name ?? '')
                                              .where((name) =>
                                              name
                                                  .toLowerCase()
                                                  .contains(
                                                  textEditingValue.text
                                                      .toLowerCase()))
                                              .toList();
                                        },
                                        onSelected: (String selection) {
                                          final sov = sovProvider.filtersovlist
                                              .firstWhere(
                                                  (s) => s.name == selection);

                                          setState(() {
                                            selectedSovId = sov.sovId ?? "";
                                            _sovNameController.text =
                                                sov.name ?? "";
                                            isSovSelected = true;

                                            _sovError = null; // ✅ ADD THIS
                                          });

                                          sovProvider.clearAutoCompleteList();
                                        },
                                        fieldViewBuilder: (context, controller,
                                            focusNode, onFieldSubmitted) {
                                          return TextFormField(
                                            controller: _sovNameController,
                                            focusNode: focusNode,
                                            decoration: InputDecoration(
                                              labelText:
                                              LanguageService.getTranslated(
                                                  context, "name_of_sov"),
                                              border: OutlineInputBorder(),
                                              errorText: _sovError,
                                              suffixIcon: sovProvider.isLoading
                                                  ? Padding(
                                                padding:
                                                const EdgeInsets.all(10),
                                                child: SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child:
                                                  CircularProgressIndicator(
                                                      strokeWidth: 2),
                                                ),
                                              )
                                                  : Icon(Icons.search),
                                            ),
                                            onChanged: (value) {
                                              setState(() {
                                                selectedSovId = "";
                                                isSovSelected = false;

                                                if (value
                                                    .trim()
                                                    .isNotEmpty) {
                                                  _sovError = null;
                                                }
                                              });

                                              _debounce?.cancel();
                                              _debounce = Timer(
                                                  Duration(
                                                      milliseconds: 300), () {
                                                sovProvider.fetchSovList(
                                                    context, value, 1, 100, '');
                                              });
                                            },
                                          );
                                          // return TextFormField(
                                          //   controller: controller,
                                          //   focusNode: focusNode,
                                          //   decoration: InputDecoration(
                                          //     labelText:
                                          //         LanguageService.getTranslated(
                                          //             context, "name_of_sov"),
                                          //     border: OutlineInputBorder(),
                                          //     errorText: _sovError,
                                          //     suffixIcon: sovProvider.isLoading
                                          //         ? Padding(
                                          //             padding:
                                          //                 const EdgeInsets.all(10),
                                          //             child: SizedBox(
                                          //               width: 20,
                                          //               height: 20,
                                          //               child:
                                          //                   CircularProgressIndicator(
                                          //                       strokeWidth: 2),
                                          //             ),
                                          //           )
                                          //         : Icon(Icons.search),
                                          //   ),
                                          //   onChanged: (value) {
                                          //     setState(() {
                                          //       selectedSovId = "";
                                          //       isSovSelected = false;
                                          //
                                          //       // ✅ clear error while typing
                                          //       if (value.trim().isNotEmpty) {
                                          //         _sovError = null;
                                          //       }
                                          //     });
                                          //
                                          //     _debounce?.cancel();
                                          //     _debounce = Timer(
                                          //         Duration(milliseconds: 300), () {
                                          //       sovProvider.fetchSovList(
                                          //           context, value, 1, 100, '');
                                          //     });
                                          //   },
                                          // );
                                        },
                                        // fieldViewBuilder: (context, controller,
                                        //     focusNode, onFieldSubmitted) {
                                        //   controller.text = _sovNameController.text;
                                        //   return TextFormField(
                                        //     controller: controller,
                                        //     focusNode: focusNode,
                                        //     decoration: InputDecoration(
                                        //       labelText:
                                        //           LanguageService.getTranslated(
                                        //               context, "name_of_sov"),
                                        //       border: OutlineInputBorder(),
                                        //       errorText: _sovError,
                                        //       suffixIcon: sovProvider.isLoading
                                        //           ? Padding(
                                        //               padding:
                                        //                   const EdgeInsets.all(10),
                                        //               child: SizedBox(
                                        //                 width: 20,
                                        //                 height: 20,
                                        //                 child:
                                        //                     CircularProgressIndicator(
                                        //                         strokeWidth: 2),
                                        //               ),
                                        //             )
                                        //           : Icon(Icons.search),
                                        //     ),
                                        //     onChanged: (value) {
                                        //       setState(() {
                                        //         selectedSovId = "";
                                        //         isSovSelected = false;
                                        //
                                        //         // ✅ CLEAR ERROR WHEN USER TYPES
                                        //         if (value.trim().isNotEmpty) {
                                        //           _sovError = null;
                                        //         }
                                        //       });
                                        //
                                        //       _debounce?.cancel();
                                        //       _debounce = Timer(
                                        //           Duration(milliseconds: 300), () {
                                        //         sovProvider.fetchSovList(
                                        //             context, value, 1, 100, '');
                                        //       });
                                        //     },
                                        //   );
                                        // },
                                      ),
                                      if (!isSovSelected &&
                                          sovProvider.isLoading)
                                        SizedBox(),
                                    ],
                                  );
                                },
                              ),

                              SizedBox(height: 14),
                            ],
                            TextField(
                              controller: tagController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: "Enter tags separated by commas",
                                labelStyle: const TextStyle(
                                    color: Colors.white),
                                enabledBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.grey),
                                ),
                                focusedBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.blue),
                                ),
                                hintStyle: const TextStyle(
                                    color: Colors.white54),
                              ),
                              onChanged: (value) {
                                if (value.contains(',')) {
                                  final tag = value.replaceAll(',', '').trim();

                                  if (tag.isNotEmpty && !tags.contains(tag)) {
                                    setState(() {
                                      tags.add(tag);
                                    });
                                  }

                                  tagController.clear();
                                }
                              },
                            ),

                            const SizedBox(height: 12),

                            ///  TAG CHIPS
                            if (tags.isNotEmpty)
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: tags.map((tag) {
                                  return Chip(
                                    label: Text(
                                      tag,
                                      style: const TextStyle(
                                          color: Colors.white),
                                    ),
                                    backgroundColor: Colors.grey[700],
                                    deleteIconColor: Colors.white,
                                    onDeleted: () {
                                      setState(() {
                                        tags.remove(tag);
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 0.0),
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: addToSOVCheck,
                                    onChanged:
                                    (trialStatus.isNotEmpty && !hasAnyPlan)
                                        ? null
                                        : (bool? value) {
                                      setState(() {
                                        addToSOVCheck = value ?? false;
                                      });
                                      if (addToSOVCheck &&
                                          _sovNameController.text
                                              .trim()
                                              .isEmpty) {
                                        _sovError = "Please add SOV name";
                                      } else {
                                        _sovError = null;
                                      }
                                    },
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    LanguageService.getTranslated(
                                        context, "name_of_sov"),
                                    style: typography.Body1,
                                  ),
                                  if (trialStatus.isNotEmpty && !hasAnyPlan)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 5.0),
                                      child: InkWell(
                                        onTap: () {
                                          if (Platform.isIOS) {
                                            Fluttertoast.showToast(
                                              msg:
                                              "Please complete the payment on the website.",
                                              toastLength: Toast.LENGTH_SHORT,
                                              gravity: ToastGravity.BOTTOM,
                                            );
                                          } else {
                                            Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        PurchaseLicensePage()));
                                          }
                                        },
                                        child: Text(
                                          "Upgrade Now to create SOV!",
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: typography.Body1.copyWith(
                                            fontSize: 16,
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
                                  LanguageService.getTranslated(
                                      context, "available_locations") +
                                      " : " +
                                      hasHazardLicenseStatus.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                  ),
                                ),
                              )
                            ] else
                              if (!hasAnyPlan) ...[
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.only(left: 10),
                                      child: Text(
                                        LanguageService.getTranslated(
                                            context, "available_locations") +
                                            " : " +
                                            hazardLicenseStatus2.toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 5),
                                    InkWell(
                                        onTap: () {
                                          if (Platform.isIOS) {
                                            Fluttertoast.showToast(
                                              msg:
                                              "Please complete the payment on the website.",
                                              toastLength: Toast.LENGTH_SHORT,
                                              gravity: ToastGravity.BOTTOM,
                                            );
                                          } else {
                                            Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        PurchaseLicensePage()));
                                          }
                                        },
                                        child: Text(
                                          "Upgrade Now",
                                          style: TextStyle(
                                              color: Colors.orange,
                                              fontSize: 16),
                                        ))
                                  ],
                                ),
                              ] else
                                ...[
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
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0),
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
                                                  onPressed: () async {
                                                    if (!_formKey
                                                        .currentState!
                                                        .validate()) return;

                                                    if (addToSOVCheck) {
                                                      if (_sovNameController
                                                          .text
                                                          .trim()
                                                          .isEmpty) {
                                                        // ✅ TOP SNACKBAR
                                                        ScaffoldMessenger.of(
                                                            sheetContext)
                                                            .showSnackBar(
                                                          SnackBar(
                                                            content: Text(
                                                                "Please add SOV name"),
                                                            behavior:
                                                            SnackBarBehavior
                                                                .floating,
                                                          ),
                                                        );

                                                        // ✅ INLINE ERROR
                                                        setState(() {
                                                          _sovError =
                                                          "Please add SOV name";
                                                        });

                                                        return;
                                                      } else {
                                                        setState(() {
                                                          _sovError = null;
                                                        });
                                                      }
                                                    }

                                                    if (files == null ||
                                                        files!.path.isEmpty) {
                                                      ScaffoldMessenger.of(
                                                          sheetContext)
                                                          .showSnackBar(
                                                        SnackBar(
                                                            content: Text(
                                                                "Please select a file to upload")),
                                                      );
                                                      return;
                                                    }

                                                    if (!files!.path
                                                        .endsWith('.xlsx')) {
                                                      ScaffoldMessenger.of(
                                                          sheetContext)
                                                          .showSnackBar(
                                                        SnackBar(
                                                            content: Text(
                                                                "Please select a valid file to upload")),
                                                      );
                                                      return;
                                                    }

                                                    String success =
                                                    await locationListProvider
                                                        .uploadSov(
                                                      sheetContext,
                                                      files!,
                                                      accountId,
                                                      subAccountId,
                                                      sovId,
                                                      tagController.text,
                                                      _sovNameController.text,
                                                    );

                                                    _sovNameController
                                                        .clear();

                                                    print(
                                                        'Success: $success');

                                                    if (success.isNotEmpty &&
                                                        success
                                                            .contains('+')) {
                                                      showDialog(
                                                        context: sheetContext,
                                                        builder: (BuildContext
                                                        context) {
                                                          return AlertDialog(
                                                            title: Text(
                                                                'Empty SOV',
                                                                style: typography
                                                                    .H5_Regular),
                                                            content: Column(
                                                              mainAxisSize:
                                                              MainAxisSize
                                                                  .min,
                                                              children: [
                                                                Text(
                                                                  'Looks Like, Data has not been specified!! Do you want to continue creating an empty SOV, or abort?',
                                                                  style: typography
                                                                      .Body1,
                                                                ),
                                                                SizedBox(
                                                                    height: CustomSpacing
                                                                        .two),
                                                                Column(
                                                                  crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .stretch,
                                                                  children: [
                                                                    Consumer<
                                                                        UploadSovProvider>(
                                                                      builder: (
                                                                          dialogContext,
                                                                          uploadSovProvider,
                                                                          child) {
                                                                        return uploadSovProvider
                                                                            .isLoading
                                                                            ? const Center(
                                                                            child: CircularProgressIndicator())
                                                                            : CustomButton(
                                                                          onPressed: () async {
                                                                            var provider = Provider
                                                                                .of<
                                                                                UploadSovProvider>(
                                                                                dialogContext,
                                                                                listen: false);
                                                                            await provider
                                                                                .createEmptySov(
                                                                                dialogContext,
                                                                                success);
                                                                            Navigator
                                                                                .pop(
                                                                                dialogContext);
                                                                          },
                                                                          child: Text(
                                                                            LanguageService
                                                                                .getTranslated(
                                                                                dialogContext,
                                                                                "create"),
                                                                            style: typography
                                                                                .ButtonLarge,
                                                                          ),
                                                                          type: ButtonType
                                                                              .elevated,
                                                                        );
                                                                      },
                                                                    ),
                                                                    // Consumer<
                                                                    //     UploadSovProvider>(
                                                                    //   builder: (context,
                                                                    //       uploadSovProvider,
                                                                    //       child) {
                                                                    //     return uploadSovProvider.isLoading
                                                                    //         ? const Center(child: CircularProgressIndicator())
                                                                    //         : CustomButton(
                                                                    //             onPressed: () async {
                                                                    //               var provider = Provider.of<UploadSovProvider>(context, listen: false);
                                                                    //               await provider.createEmptySov(context, success);
                                                                    //               Navigator.pop(context);
                                                                    //             },
                                                                    //             child: Text(
                                                                    //               LanguageService.getTranslated(context, "create"),
                                                                    //               style: typography.ButtonLarge,
                                                                    //             ),
                                                                    //             type: ButtonType.elevated,
                                                                    //           );
                                                                    //   },
                                                                    // ),
                                                                    CustomButton(
                                                                      onPressed:
                                                                          () {
                                                                        Navigator
                                                                            .pop(
                                                                            sheetContext);
                                                                      },
                                                                      child:
                                                                      Text(
                                                                        'Abort',
                                                                        style:
                                                                        typography
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
                                                        },
                                                      );
                                                    } else if (success
                                                        .isNotEmpty) {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (_) =>
                                                              MappingScreen(
                                                                tempId: success,
                                                                accountId: widget
                                                                    .accountID!,
                                                                accountName: widget
                                                                    .accountName ??
                                                                    "",
                                                                subAccountName:
                                                                widget
                                                                    .subAccountName ??
                                                                    "",
                                                                subAccountId: widget
                                                                    .subAccountID!,
                                                              ),
                                                        ),
                                                      ).then((value) {
                                                        if (value == true) {
                                                          setState(() {
                                                            getdata(
                                                                widget
                                                                    .accountID!,
                                                                widget
                                                                    .subAccountID!);
                                                            _getSovUploadStatus();
                                                          });
                                                        }
                                                      });
                                                    } else {
                                                      print(
                                                          'Location Upload Failed: $success');
                                                    }
                                                  },
                                                  child: Text(
                                                      LanguageService
                                                          .getTranslated(
                                                          context,
                                                          "upload"),
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
                                      Navigator.of(sheetContext).pop();
                                    },
                                    child: Text(
                                        LanguageService.getTranslated(
                                            context, "close"),
                                        style: typography.Body1),
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

  String safeParseInt(dynamic value) {
    if (value == null) return "00";
    try {
      int parsed = int.parse(value.toString());
      return parsed.toString().padLeft(2, '0');
    } catch (e) {
      return "00";
    }
  }

  Future<void> _showTransferDialog(BuildContext context,
      List<Result> sovs) async {
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
                bottom: MediaQuery
                    .of(context)
                    .viewInsets
                    .bottom + 16,
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
                      onChanged: (value) =>
                          _onSearchChanged(
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
                    else
                      if (_autocompleteUsersList.isNotEmpty)
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
                                                backgroundColor: Colors
                                                    .grey[800],
                                                child: Text(
                                                  (user.name.isNotEmpty)
                                                      ? user.name
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
                                                          color: Colors
                                                              .white70),
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
                                                    firstDate: DateTime(
                                                        now.year,
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
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(SnackBar(
                                        content: Text(
                                            "SOV shared successfully")));
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

Future<List<TransferAutocompleteModel>> fetchAutocompleteUsers(String query,
    String type) async {
  try {
    ApiService apiService = ApiService(AppConstant.GET_SEARCH_LIST_BY_SOV);
    String url = type != "individual"
        ? '/user_search?search=$query'
        : '/individual_user_search?search=$query';
    var response = await apiService.get(url);

    List<TransferAutocompleteModel> users = (response['result'] as List)
        .map((user) => TransferAutocompleteModel.fromJson(user))
        .toList();

    return users;
  } catch (e) {
    print(e.toString());
    return [];
  }
}

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

Future<void> showAddToSovMonitoringDialog({
  required BuildContext context,
  required String accountId,
  required String subAccountId,
}) async {
  final provider = Provider.of<MyLocationListProvider>(context, listen: false);

  List<String> locationIds;
  if (provider.isGlobalSelectAll) {
    locationIds = await provider.fetchAllLocationIdsForAddTag(
      accountId: accountId,
      subAccountId: subAccountId,
    );
  } else {
    locationIds = provider.selectedLocationIds.toList();
  }

  if (locationIds.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please select at least one location')),
    );
    return;
  }

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) =>
        _AddToSovMonitoringDialog(
          locationIds: locationIds,
          accountId: accountId,
          subAccountId: subAccountId,
        ),
  );
}

class _AddToSovMonitoringDialog extends StatefulWidget {
  final List<String> locationIds;
  final String accountId;
  final String subAccountId;

  const _AddToSovMonitoringDialog({
    required this.locationIds,
    required this.accountId,
    required this.subAccountId,
  });

  @override
  State<_AddToSovMonitoringDialog> createState() =>
      _AddToSovMonitoringDialogState();
}

class _AddToSovMonitoringDialogState extends State<_AddToSovMonitoringDialog> {
  final TextEditingController _sovIdController = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _sovIdController.dispose();
    super.dispose();
  }

  void _validate() {
    setState(() {
      _errorText =
      _sovIdController.text
          .trim()
          .isEmpty ? 'Please enter a SOV ID' : null;
    });
  }

  Future<void> _submit() async {
    _validate();
    if (_errorText != null) return;
  }

  @override
  Widget build(BuildContext context) {
    final typography = CustomTypography(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.monitor, size: 22),
          const SizedBox(width: 8),
          Text('Add to SOV Monitoring', style: typography.H5_Regular),
        ],
      ),
      content: SizedBox(
        width: MediaQuery
            .of(context)
            .size
            .width * 0.85,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Location count badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme
                    .of(context)
                    .colorScheme
                    .primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${widget.locationIds.length} location(s) selected',
                style: typography.Body2.copyWith(
                  color: Theme
                      .of(context)
                      .colorScheme
                      .onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // SOV ID input
            Text('SOV ID', style: typography.Body2),
            const SizedBox(height: 6),
            TextField(
              controller: _sovIdController,
              onChanged: (_) {
                if (_errorText != null) _validate();
              },
              decoration: InputDecoration(
                hintText: 'Enter SOV ID',
                errorText: _errorText,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.folder_outlined),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'The selected locations will be added to the specified SOV for monitoring.',
              style: typography.Body2.copyWith(color: Colors.grey),
            ),
          ],
        ),
      ),
      actions: [
        // Cancel
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel', style: typography.ButtonLarge),
        ),

        // Submit
        Consumer<MyLocationListProvider>(
          builder: (context, provider, _) {
            return provider.isMonitorLoading
                ? const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
                : CustomButton(
              type: ButtonType.elevated,
              onPressed: _submit,
              child: const Text(
                'Add to Monitoring',
                style: TextStyle(color: Colors.black),
              ),
            );
          },
        ),
      ],
    );
  }
}

class MonitoringBottomSheet extends StatefulWidget {
  final List<MyLocation> locations;
  final String sovId;
  final String hurricaneCount;
  final String eathquakCount;

  const MonitoringBottomSheet({
    super.key,
    required this.locations,
    required this.sovId,
    required this.hurricaneCount,
    required this.eathquakCount,
  });

  @override
  State<MonitoringBottomSheet> createState() => _MonitoringBottomSheetState();
}

class _MonitoringBottomSheetState extends State<MonitoringBottomSheet> {
  final Map<String, bool> hurricaneSelections = {};
  final Map<String, bool> earthquakeSelections = {};

  final ScrollController _scrollController = ScrollController();

  bool isLoadingMore = false;

  int currentPage = 1;
  final int pageSize = 10;

  List<MyLocation> get visibleLocations {
    final end = currentPage * pageSize;

    if (end >= widget.locations.length) {
      return widget.locations;
    }

    return widget.locations.sublist(0, end);
  }

  @override
  void initState() {
    super.initState();

    for (final location in widget.locations) {
      final id = location.locationId ?? "";

      hurricaneSelections[id] = true;
      earthquakeSelections[id] = true;
    }

    _scrollController.addListener(
      _onScroll,
    );
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200 &&
        !isLoadingMore) {
      loadMore();
    }
  }

  Future<void> loadMore() async {
    if (visibleLocations.length >= widget.locations.length) {
      return;
    }

    setState(() {
      isLoadingMore = true;
    });

    await Future.delayed(
      const Duration(milliseconds: 300),
    );

    setState(() {
      currentPage++;
      isLoadingMore = false;
    });
  }

  int get hurricaneCredits => int.tryParse(widget.hurricaneCount) ?? 0;

  int get earthquakeCredits => int.tryParse(widget.eathquakCount) ?? 0;

  int get selectedHurricaneCount =>
      hurricaneSelections.values
          .where((e) => e)
          .length;

  int get selectedEarthquakeCount =>
      earthquakeSelections.values
          .where((e) => e)
          .length;

  bool get isHurricaneExceeded => selectedHurricaneCount > hurricaneCredits;

  bool get isEarthquakeExceeded => selectedEarthquakeCount > earthquakeCredits;

  /// NEW
  bool get canAddToMonitoring {
    return !isHurricaneExceeded &&
        !isEarthquakeExceeded &&
        (selectedHurricaneCount > 0 || selectedEarthquakeCount > 0);
  }

  bool isSubmitting = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme
          .of(context)
          .colorScheme
          .surface,
      appBar: AppBar(
        title: const Text(
          "Add to Monitoring",
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.close),
          )
        ],
      ),
      body: Column(
        children: [

          /// TOP COUNTS
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: isHurricaneExceeded
                          ? Colors.red.shade900
                          : const Color(0xff001A24),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Colors.lightBlue,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Hurricane Credits: ${widget
                                .hurricaneCount} | Selected: $selectedHurricaneCount",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: isEarthquakeExceeded
                          ? Colors.red.shade900
                          : const Color(0xff001A24),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Colors.lightBlue,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Earthquake Credits: ${widget
                                .eathquakCount} | Selected: $selectedEarthquakeCount",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!canAddToMonitoring)
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PurchaseLicensePage(),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xff001A24),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Colors.lightBlue,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          "Need more credits? Purchase additional credits",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          /// LOCATION LIST
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: visibleLocations.length + (isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == visibleLocations.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final location = visibleLocations[index];

                final locationId = location.locationId ?? "";

                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xff111111),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white10,
                    ),
                  ),
                  child: Column(
                    children: [

                      /// LOCATION IMAGE + NAME + ADDRESS
                      buildLocationHeader(
                        location,
                      ),

                      const SizedBox(height: 14),

                      /// CHECKBOXES
                      Row(
                        children: [
                          Expanded(
                            child: CheckboxListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              value: hurricaneSelections[locationId] ?? false,
                              onChanged: (value) {
                                setState(() {
                                  hurricaneSelections[locationId] =
                                      value ?? false;
                                });
                              },
                              title: const Text(
                                "Hurricane",
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                              activeColor: Colors.lightBlue,
                              controlAffinity: ListTileControlAffinity.leading,
                            ),
                          ),
                          Expanded(
                            child: CheckboxListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              value: earthquakeSelections[locationId] ?? false,
                              onChanged: (value) {
                                setState(() {
                                  earthquakeSelections[locationId] =
                                      value ?? false;
                                });
                              },
                              title: const Text(
                                "Earthquake",
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                              activeColor: Colors.lightBlue,
                              controlAffinity: ListTileControlAffinity.leading,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "Cancel",
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: CustomButton(
                    type: ButtonType.elevated,
                    onPressed: isSubmitting || !canAddToMonitoring
                        ? null
                        : () async {
                      setState(() {
                        isSubmitting = true;
                      });

                      try {
                        final hurricaneIds = hurricaneSelections.entries
                            .where((e) => e.value)
                            .map((e) => e.key)
                            .toList();

                        final earthquakeIds = earthquakeSelections.entries
                            .where((e) => e.value)
                            .map((e) => e.key)
                            .toList();

                        final provider = Provider.of<MyLocationListProvider>(
                          context,
                          listen: false,
                        );

                        final success = await provider.addToSovMonitoring(
                          context: context,
                          hurricaneIds: hurricaneIds,
                          earthquakeIds: earthquakeIds,
                          sovId: widget.sovId,
                        );

                        if (success) {
                          if (mounted) {
                            Navigator.pop(context, true);
                          }
                        }
                      } finally {
                        if (mounted) {
                          setState(() {
                            isSubmitting = false;
                          });
                        }
                      }
                    },
                    child: isSubmitting
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                        : const Text(
                      "Add to Event Monitoring",
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildLocationHeader(MyLocation location) {
    final imageUrl =
    location.screenshots != null && location.screenshots!.isNotEmpty
        ? location.screenshots!.first.imageUrl ?? ""
        : "";

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: location.geocodingScore == 5
              ? CachedNetworkImage(
            imageUrl:
            "https://maps.googleapis.com/maps/api/streetview?size=600x300&location=${location.finalAddress!.latitude},${location.finalAddress!.longitude}&key=${Env.get('GOOGLE_MAPS_API_KEY')}",
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            placeholder: (context, url) =>
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
            errorWidget: (context, url, error) =>
            const Icon(
              Icons.location_on,
            ),
          )
              : imageUrl.isNotEmpty
              ? CachedNetworkImage(
            imageUrl: imageUrl,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            placeholder: (context, url) =>
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
            errorWidget: (context, url, error) =>
            const Icon(
              Icons.location_on,
            ),
          )
              : Container(
            width: 50,
            height: 50,
            color: Colors.lightBlueAccent,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                location.locationName ?? "",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryMain,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                location.finalAddress?.address ?? "",
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildLocationImage(MyLocation location,) {
    String imageUrl = "";

    if (location.screenshots != null && location.screenshots!.isNotEmpty) {
      imageUrl = location.screenshots!.first.imageUrl ?? "";
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 50,
        height: 50,
        child: imageUrl.isNotEmpty
            ? CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) =>
          const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          ),
          errorWidget: (context, url, error) =>
              Container(
                color: Colors.grey.shade300,
                child: const Icon(
                  Icons.location_on,
                ),
              ),
        )
            : Container(
          color: Colors.grey.shade300,
          child: const Icon(
            Icons.location_on,
          ),
        ),
      ),
    );
  }
}

class _ChatbotContent extends StatefulWidget {
  final String? locationId;
  final String? accountId;
  final String? subaccountId;
  final String? accountName;
  final String? subAccountName;

  _ChatbotContent({this.locationId,
    this.accountId,
    this.subaccountId,
    this.accountName,
    this.subAccountName});

  @override
  State<_ChatbotContent> createState() => _ChatbotContentState();
}

class _ChatbotContentState extends State<_ChatbotContent> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _sessionId;
  bool _isTyping = false;
  bool _hasText = false;
  bool _showEligibilityButton = true;
  bool _showLocationsButton = true;
  List<Map<String, dynamic>> messages = [];
  bool get _showSuggestions =>
      messages.where((m) => m["isBot"] == false).isEmpty;
  @override
  void initState() {
    super.initState();
    _sessionId = const Uuid().v4();
    messages.add({
      "isBot": true,
      "text":
      "Hi, I'm RiskBuddy your personalized Assistant.\n\n",
    });
    _controller.addListener(() {
      final hasText = _controller.text
          .trim()
          .isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _currentTime() {
    final now = DateTime.now();
    final hour = now.hour > 12
        ? now.hour - 12
        : now.hour == 0
        ? 12
        : now.hour;
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? "PM" : "AM";
    return "$hour:$minute $period";
  }

  Future<void> _sendMessage() async {
    if (_controller.text
        .trim()
        .isEmpty) return;
    final userMessage = _controller.text.trim();

    setState(() {
      messages.add({"isBot": false, "text": userMessage});
      _isTyping = true;
    });

    _controller.clear();
    _scrollToBottom();

    final provider =
    Provider.of<MyLocationListProvider>(context, listen: false);

    try {
      final reply = await provider.sendChatMessage(
        context: context,
        message: userMessage,
        isLocationProfile: false,
        accountId: widget.accountId,
        subAccountId: widget.subaccountId,
        accountName: widget.accountName,
        subAccountName: widget.subAccountName,
      );

      debugPrint("BOT REPLY => $reply");
      setState(() {
        _isTyping = false;
        messages.add({"isBot": true, "text": reply ?? "No response"});
      });
      _scrollToBottom();
    } catch (e) {
      setState(() => _isTyping = false);
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [

        /// ── Header ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primaryMain,
                child:
                const Icon(Icons.smart_toy, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "RiskBuddy",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    children: [
                      SvgPicture.asset(
                        "assets/images/ai.svg",
                        color: AppColors.primaryMain,
                        width: 12,
                        height: 12,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        "Smarter decisions, lower risk.",
                        style: TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  // IconButton(
                  //   icon: const Icon(Icons.open_in_full,
                  //       color: Colors.grey, size: 18),
                  //   onPressed: () {
                  //     // Navigator.pop(context);
                  //     // Navigator.push(
                  //     //   context,
                  //     //   MaterialPageRoute(
                  //     //     builder: (_) =>
                  //     //         ChatbotPage(locationId: widget.locationId),
                  //     //   ),
                  //     // );
                  //   },
                  // ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ],
          ),
        ),

        const Divider(color: Color(0xFF2A2A2A), height: 1),

        /// ── Messages ──
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            itemCount: messages.length + (_isTyping ? 1 : 0),
            itemBuilder: (context, index) {
              if (_isTyping && index == messages.length) {
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Text("...",
                        style: TextStyle(color: Colors.white)),
                  ),
                );
              }

              final message = messages[index];
              final isBot = message["isBot"] as bool;

              return Column(
                crossAxisAlignment:
                isBot ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery
                          .of(context)
                          .size
                          .width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color: isBot
                          ? const Color(0xFF1E1E1E)
                          : const Color(0xFF2D2D2D),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: isBot
                        ? _buildFormattedText(context, message["text"])
                        : Text(
                      message["text"],
                      style: const TextStyle(
                          color: Colors.white, fontSize: 13),
                    ),
                    // child: Text(
                    //   message["text"],
                    //   style: const TextStyle(color: Colors.white, fontSize: 13),
                    // ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      _currentTime(),
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        if (_showSuggestions)
          _buildSuggestionContainer(),
        /// ── Input Bar ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          color: Colors.black,
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: const Color(0xFF3A3A3A), width: 1),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: "Ask about risk data, eligibility...",
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                      border: InputBorder.none,
                      isCollapsed: true,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                GestureDetector(
                  onTap: _hasText ? _sendMessage : null,
                  child: Icon(
                    Icons.telegram_sharp,
                    color: _hasText ? AppColors.primaryMain : Colors.grey,
                    size: 38,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          height: 25,
        )
      ],
    );
  }
  Widget _buildSuggestionContainer() {
    final suggestions = [
      "Tell me about my locations",
      "Tell me about my top 5 best locations with respect to Hazard Score",
      "Tell me about my top 5 worst locations with respect to Hazard Score",
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: suggestions.map((text) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                _controller.text = text;
                _sendMessage();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryMain,
                    width: 1,
                  ),
                ),
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.primaryMain,
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

Widget _buildFormattedText(BuildContext context, String rawText) {
  final text = rawText.replaceAll('**', '');
  final lines = text.split('\n');
  final List<Widget> elements = [];

  for (int i = 0; i < lines.length; i++) {
    final trimmed = lines[i].trim();

    // Skip lines that are just "4." etc.
    if (RegExp(r'^\d+\.$').hasMatch(trimmed)) continue;

    if (trimmed.isEmpty) {
      elements.add(const SizedBox(height: 8));
      continue;
    }

    if (trimmed.endsWith(':') && !trimmed.startsWith('*')) {
      elements.add(Padding(
        padding: EdgeInsets.only(top: i > 0 ? 8.0 : 0, bottom: 4),
        child: Text(
          trimmed,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: AppColors.primaryMain,
          ),
        ),
      ));
    } else if (trimmed.startsWith('*')) {
      final bulletText = trimmed.substring(1).trim();
      elements.add(Padding(
        padding: const EdgeInsets.only(left: 8, bottom: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '• ',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
            ),
            Expanded(
              child: Text(
                bulletText,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ));
    } else {
      final isHighRisk =
          trimmed.contains('Very High') || trimmed.contains('High');
      elements.add(Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          trimmed,
          style: TextStyle(
            fontSize: 13,
            height: 1.5,
            color: isHighRisk ? Colors.white : Colors.white,
          ),
        ),
      ));
    }
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: elements,
  );
}

class _ChatbotBottomSheet extends StatefulWidget {
  final String? locationId;
  final String? accountId;
  final String? subAccountId;
  final String? accountName;
  final String? subAccountName;

  _ChatbotBottomSheet({this.locationId,
    this.accountId,
    this.subAccountId,
    this.accountName,
    this.subAccountName});

  @override
  State<_ChatbotBottomSheet> createState() => _ChatbotBottomSheetState();
}

class _ChatbotBottomSheetState extends State<_ChatbotBottomSheet> {
  bool _isFullScreen = false;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery
        .of(context)
        .size
        .height;

    return Padding(
      padding: MediaQuery
          .of(context)
          .viewInsets,
      child: Container(
        height: _isFullScreen ? screenHeight : screenHeight * 0.62,
        decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            GestureDetector(
              onTap: () => setState(() => _isFullScreen = !_isFullScreen),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade600,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Icon(
                      _isFullScreen
                          ? Icons.keyboard_arrow_down
                          : Icons.keyboard_arrow_up,
                      color: Colors.grey,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: _ChatbotContent(
                  locationId: widget.locationId,
                  accountId: widget.accountId,
                  subaccountId: widget.subAccountId,
                  accountName: widget.accountName,
                  subAccountName: widget.subAccountName),
            ),
          ],
        ),
      ),
    );
  }
}
