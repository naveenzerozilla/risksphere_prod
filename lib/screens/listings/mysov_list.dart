import 'package:RiskSphere/screens/listings/processing_summary.dart';
import 'package:RiskSphere/screens/listings/widgets/location_list_map_view.dart';
import 'package:RiskSphere/screens/listings/widgets/vertical_bar_indicator.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../design_system/repo/constants.dart';
import '../../models/my_location_list_model.dart';
import '../../utils/global_imports.dart';
import '../../models/sov_list_model.dart';
import 'package:RiskSphere/models/role_model.dart' as roleModel;
import 'package:http/http.dart' as http;

class MySovList extends StatefulWidget {
  final String? status;
  final String? accountID;
  final String? subAccountID;
  final String accountName;
  final String subAccountName;
  final String? initialProcessId;
  final String? initialSubProcessId;

  const MySovList({
    super.key,
    this.status,
    this.accountID,
    this.subAccountID,
    this.accountName = '',
    this.subAccountName = '',
    this.initialProcessId,
    this.initialSubProcessId,
  });

  @override
  State<MySovList> createState() => _MySovListState();
}

class _MySovListState extends State<MySovList> with TickerProviderStateMixin {
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

    // 👉 FETCH FIRST PAGE when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<SOVListProvider>(context, listen: false);

      provider.page = 1; // reset page
      provider.totalPages = 1; // optional, depends on your provider logic

      provider.fetchSovList(
        context,
        widget.accountID ?? '',
        widget.subAccountID ?? '',
        _sovQuery,
        1,
        // first page
        5,
        // page size
        widget.status, // default type
      );
    });

    // 👉 ADD SCROLL LISTENER FOR PAGINATION
    _scrollController1.addListener(() {
      final provider = Provider.of<SOVListProvider>(context, listen: false);

      if (!_scrollController1.hasClients) return;

      if (_scrollController1.position.pixels >=
              _scrollController1.position.maxScrollExtent - 300 &&
          !provider.isNextPageLoading &&
          provider.page < provider.totalPages) {
        provider.page = provider.page + 1;

        provider.fetchSovList(
          context,
          widget.accountID ?? '',
          widget.subAccountID ?? '',
          _sovQuery,
          provider.page,
          5,
          widget.status,
        );
      }
    });
  }

  bool _isDisposed = false;
  MyLocationListProvider? _myLocationProvider;

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

  String? _activeAccountKey; // track which account/subaccount timer belongs to

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

    // locationListProvider.certifiedPage = 1;

    // await locationListProvider.fetchLocationList(context, "", 1, 8, accountId,
    //     subAccountId, widget.initialProcessId, widget.initialSubProcessId, '');
    // sovListProvider.fetchSovList(
    //     context, widget.accountID!, widget.subAccountID!, "", 1, 5, 'my');
    //
    // await locationListProvider.fetchAllLocationList(
    //   context,
    //   accountId,
    //   subAccountId,
    //   processId: widget.initialProcessId,
    //   subProcessId: widget.initialSubProcessId,
    // );
    // await locationListProvider.fetchLocationList1(context, 1, 500, accountId,
    //     subAccountId, widget.initialProcessId, widget.initialSubProcessId, "");
    //
    // await locationListProvider.fetchCertifiedLocationList(
    //   context,
    //   "",
    //   locationListProvider.certifiedPage,
    //   8,
    //   accountId,
    //   subAccountId,
    //   widget.initialProcessId,
    //   widget.initialSubProcessId,
    // );

    if (mounted) {
      setState(() {});
    }
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
          Provider.of<MyLocationListProvider>(context, listen: false)
              .clearSelection();
        },
        child: Consumer<UserProfileProvider>(
          builder: (context, userProfileProvider, child) {
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
                  body: Stack(
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                              padding: EdgeInsets.only(left: 20),
                              child: Text(
                                widget.status.toString() == "received"
                                    ? "Received SOVs"
                                    : widget.status.toString() == "my"
                                        ? "My SOVs"
                                        : widget.status.toString() == "shared"
                                            ? "Shared SOVs"
                                            : "SOVs",
                                style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600),
                              )),

                          // FULL PAGE SOV BODY (TabBar Removed Completely)
                          Expanded(
                            child: Container(
                              margin: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: sovBody(typography),
                            ),
                          ),
                        ],
                      ),

                      // if (_showOverlay_mylocation) _buildOverlay(),
                    ],
                  ),
                );
              },
            );
          },
        ),
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

  int scoreToStar(int? score) {
    if (score == null) return 0;
    if (score >= 80) return 5;
    if (score >= 60) return 4;
    if (score >= 40) return 3;
    if (score >= 20) return 2;
    return 0;
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
        5,
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
                          onPressed: () {
                            // Get selected SOV IDs from the local selectedList
                            List<String> selectedSovIds = [];
                            for (int i = 0; i < selectedList.length; i++) {
                              if (selectedList[i] &&
                                  i < sovListProvider.sovList.length) {
                                final sov = sovListProvider.sovList[i];
                                if (sov.sovId != null) {
                                  selectedSovIds.add(sov.sovId!);
                                }
                              }
                            }

                            // print('Selected SOV IDs: $selectedSovIds');

                            if (selectedSovIds.isEmpty) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                content: Text(
                                  LanguageService.getTranslated(
                                      context, "no_items_selected_error"),
                                  style: typography.Body1,
                                ),
                              ));
                              return;
                            }

                            // Implement bulk export
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Export Selected Locations'),
                                content: Text(
                                    'Are you sure you want to export ${selectedSovIds.length} locations?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      print(
                                          'Selected SOV IDs:11 $selectedSovIds');
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
                                    },
                                    child:
                                        Text('Export', style: typography.Body1),
                                  ),
                                ],
                              ),
                            );
                          },
                          icon: Icon(Icons.download),
                          tooltip: 'Export Selected',
                        ),
                        // IconButton(
                        //   onPressed: () {
                        //     // Implement bulk export
                        //     showDialog(
                        //       context: context,
                        //       builder: (context) => AlertDialog(
                        //         title: Text('Export Selected Locations'),
                        //         content: Text(
                        //             'Are you sure you want to export ${selectedList.where((s) => s).length} locations?'),
                        //         actions: [
                        //           TextButton(
                        //             onPressed: () => Navigator.pop(context),
                        //             child: Text('Cancel'),
                        //           ),
                        //           TextButton(
                        //             onPressed: () {
                        //               print(_selectedScreen);
                        //
                        //               print(
                        //                   'Selected id1s: ${locationListProvider.selectedLocations.map((sov) => sov.id).toList()}');
                        //               // On export button click
                        //               List<String> selectedSovIds =
                        //                   Provider.of<MyLocationListProvider>(
                        //                           context,
                        //                           listen: false)
                        //                       .selectedLocations
                        //                       .map((sov) => sov.id!)
                        //                       .toList();
                        //               print('Selected ids: $selectedSovIds');
                        //
                        //               if (selectedSovIds.isNotEmpty) {
                        //                 Navigator.pop(context);
                        //                 showDialog(
                        //                   context: context,
                        //                   builder: (BuildContext context) {
                        //                     return ExportDialog(
                        //                       accountId: widget.accountID!,
                        //                       subAccountId:
                        //                           widget.subAccountID!,
                        //                       locationId: selectedSovIds,
                        //                     );
                        //                   },
                        //                 );
                        //               } else {
                        //                 ScaffoldMessenger.of(context)
                        //                     .showSnackBar(SnackBar(
                        //                   content: Text(
                        //                     LanguageService.getTranslated(
                        //                         context,
                        //                         "no_items_selected_error"),
                        //                     style: typography.Body1,
                        //                   ),
                        //                 ));
                        //               }
                        //             },
                        //             child:
                        //                 Text('Export', style: typography.Body1),
                        //           ),
                        //         ],
                        //       ),
                        //     );
                        //   },
                        //   icon: Icon(Icons.download),
                        //   tooltip: 'Export Selected',
                        // ),
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
                hintText: "Search by SOV name",
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
                      sovListProvider.page = 1;
                      await sovListProvider.fetchSovList(
                        context,
                        widget.accountID!,
                        widget.subAccountID!,
                        _sovQuery,
                        1,
                        7,
                        "my",
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
                    sovListProvider.page = 1;
                    await sovListProvider.fetchSovList(
                      context,
                      sovListProvider.sovList.first.accountId!,
                      sovListProvider.sovList.first.subAccountId!,
                      _sovQuery,
                      1,
                      7,
                      widget.status,
                    );
                  },
                  child: ListView.builder(
                    controller: _scrollController1,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: sovListProvider.isNextPageLoading
                        ? sovListProvider.sovList.length + 1
                        : sovListProvider.sovList.length,
                    itemBuilder: (context, index) {
                      if (index == sovListProvider.sovList.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return _buildSovCard(index, sovListProvider);
                    },
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
                  accountID: sOVListProvider.sovList[index].accountId,
                  subAccountID: sOVListProvider.sovList[index].subAccountId,
                  accountName: sOVListProvider.sovList[index].accountName!,
                  subAccountName:
                      sOVListProvider.sovList[index].subAccountName!,
                  sovID: sOVListProvider.sovList[index].sovId ?? "",
                  sovName: sOVListProvider.sovList[index].name ?? "",
                );
              }));
              _isDisposed = true;
              _refreshTimer?.cancel();
              deBouncer?.cancel();
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
                                                    showDialog(
                                                      context: context,
                                                      barrierDismissible: false,
                                                      builder: (context) {
                                                        bool loading =
                                                            false; // Move here so StatefulBuilder controls it

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
                                                                style:
                                                                    TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
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
                                                                  child:
                                                                      const Text(
                                                                    'Cancel',
                                                                    style: TextStyle(
                                                                        color: Colors
                                                                            .grey),
                                                                  ),
                                                                ),
                                                                TextButton(
                                                                  onPressed:
                                                                      () async {
                                                                    print(sovprovider
                                                                        .sovList[
                                                                            index]
                                                                        .sovId!);
                                                                    setState(() =>
                                                                        loading =
                                                                            true);

                                                                    bool
                                                                        isSuccess =
                                                                        false;

                                                                    try {
                                                                      isSuccess =
                                                                          await subAccountListProvider
                                                                              .deleteSOVAccount(
                                                                        context,
                                                                        sovprovider
                                                                            .sovList[index]
                                                                            .accountId!,
                                                                        sovprovider
                                                                            .sovList[index]
                                                                            .subAccountId!,
                                                                        sovprovider
                                                                            .sovList[index]
                                                                            .sovId!,
                                                                      );
                                                                    } catch (e) {
                                                                      debugPrint(
                                                                          "Error deleting SOV: $e");
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
                                                                        sovprovider
                                                                            .sovList[index]
                                                                            .accountId!,
                                                                        sovprovider
                                                                            .sovList[index]
                                                                            .subAccountId!,
                                                                        _sovQuery,
                                                                        1,
                                                                        4,
                                                                        widget
                                                                            .status!,
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

                                                                    setState(() =>
                                                                        loading =
                                                                            false);
                                                                  },
                                                                  child: loading
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
                                                                          style:
                                                                              TextStyle(
                                                                            color:
                                                                                Colors.redAccent,
                                                                            fontSize:
                                                                                16,
                                                                          ),
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
                                      sOVListProvider.sovList[index].geocodeAvg
                                              .toString() ??
                                          "1",
                                      sOVListProvider.sovList[index].overallAvg
                                              .toString() ??
                                          "1",
                                      sOVListProvider
                                              .sovList[index].dataCompleteness
                                              ?.toString() ??
                                          "1",
                                    ),
                                    SizedBox(height: 4),
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
              int.tryParse(geocoding) ?? 1,
            ),
          ),
          // if (MediaQuery.of(context).size.width > 400) SizedBox(width: 10),
          SizedBox(width: 10),
          InkWell(
            onTap: () {},
            child: _buildScoreCard(
              context,
              'Hazard Score',
              int.tryParse(riskScore) ?? 1,
            ),
          ),
          // if (MediaQuery.of(context).size.width > 400)
          SizedBox(width: 10),
          InkWell(
            onTap: () {},
            child: _buildScoreCard(
              context,
              'Completeness',
              int.tryParse(completeness) == 0
                  ? 1
                  : int.tryParse(completeness) ?? 1,
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
      width: MediaQuery.of(context).size.width < 400 ? 150 : 150,
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
                  child: VerticalBarIndicator(score: score == 0 ? 1 : score),
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
                              score == 0 ? '1' : score.toString(),
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
