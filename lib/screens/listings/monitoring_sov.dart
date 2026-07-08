import 'package:easy_localization/easy_localization.dart';

import '../../models/my_location_list_model.dart';
import '../../utils/global_imports.dart';
import 'package:RiskSphere/models/role_model.dart' as roleModel;
import '../chatbot/chatbot.dart';
import '../event/event_visualisations.dart';
import '../payments/purchase_license.dart';

class MontoringSovList extends StatefulWidget {
  final String? status;
  final String? accountID;
  final String? subAccountID;
  final String accountName;
  final String subAccountName;
  final String? initialProcessId;
  final String? initialSubProcessId;
  final String? monitoringSovId;

  const MontoringSovList({
    super.key,
    this.status,
    this.accountID,
    this.subAccountID,
    this.accountName = '',
    this.subAccountName = '',
    this.initialProcessId,
    this.initialSubProcessId,
    this.monitoringSovId,
  });

  @override
  State<MontoringSovList> createState() => _MySovListState();
}

class _MySovListState extends State<MontoringSovList>
    with TickerProviderStateMixin {
  Timer? _refreshTimer;
  static bool _hasActiveTimer = false;
  bool _isSharingSov = false;
  bool _isExpanded = false;
  bool sovDeleteStatus = false;
  bool _showNotificationDot = true;
  TabController? _masterTabController;
  late TabController _tabController;
  String selectedProcessId = "";
  bool isSelectionMode = false;
  List<bool> selectedList = [];
  String isMaintenance = "";
  Set<int> expandedIndexes = {};
  bool isHasAnyPlan = false;
  String? trialMap;
  TextEditingController mobileController = TextEditingController();
  String selectedDropdown = 'TPV';
  int? touchedIndex;
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
  bool isAllSelected = false;
  bool isPgAdmin = false;
  bool isAdmin = false;
  bool isSuperAdmin = false;
  bool isIndivudual = false;
  ScrollController _scrollController1 = ScrollController();
  Timer? deBouncer;
  List<MyLocation> selectedLocations = [];
  File? files;
  TabController? _mainTabController;
  int selectedMainTab = 0;
  int selectedTab = 0;
  int selectedMasterTab = 0;
  Set<String> selectedSovIds = {};

  String _sovQuery = "";
  bool showCheckbox = false;
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

  bool _isDisposed = false;

// State fields
  final _processIndex$ = BehaviorSubject<int>.seeded(0);

  @override
  void initState() {
    super.initState();

    _setClaims();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<SOVListProvider>();

      provider.page = 1;
      provider.totalPages = 1;

      provider.fetchMonitoringSovList(
        context,
        _sovQuery,
        1,
        5,
        widget.status,
        widget.monitoringSovId,
      );
    });

    _scrollController1.addListener(() {
      if (!_scrollController1.hasClients) return;

      final provider = context.read<SOVListProvider>();

      if (_scrollController1.position.pixels >=
              _scrollController1.position.maxScrollExtent - 300 &&
          !provider.isNextPageLoading &&
          provider.page < provider.totalPages) {
        provider.page++;

        provider.fetchMonitoringSovList(
          context,
          _sovQuery,
          provider.page,
          5,
          widget.status,
          widget.monitoringSovId,
        );
      }
    });
  }

  MyLocationListProvider? _myLocationProvider;

  @override
  void dispose() {
    _processIndex$.close();
    _refreshTimer?.cancel();
    _refreshTimer?.cancel();
    _isDisposed = true;
    _mainTabController?.dispose();
    _masterTabController?.dispose();
    _tabController.dispose();
    _refreshTimer?.cancel();
    _hasActiveTimer = false;
    _isDisposed = true;

    _myLocationProvider?.clearAllFilters();
    _myLocationProvider?.clearSelection();
    _myLocationProvider?.clearRatingsFilter();
    _myLocationProvider?.myLocationList.clear();
    _myLocationProvider?.certifiedLocationList.clear();
    _myLocationProvider?.selectedLocations.clear();
    _myLocationProvider?.summaryList.clear();

    super.dispose();
  }

  void _setClaims() async {
    final adminValues = await Future.wait([
      SharedPreferenceService.getClaimForSubfeature(
          SharedPreferenceService.IS_PG_ADMIN),
      SharedPreferenceService.getClaimForSubfeature(
          SharedPreferenceService.IS_ADMIN),
      SharedPreferenceService.getClaimForSubfeature(
          SharedPreferenceService.IS_SUPER_ADMIN),
      SharedPreferenceService.getClaimForSubfeature(
          SharedPreferenceService.Is_Indivudual),
      SharedPreferenceService.getHasAnyPlan(),
    ]);

    isPgAdmin = adminValues[0] ?? false;
    isAdmin = adminValues[1] ?? false;
    isSuperAdmin = adminValues[2] ?? false;
    isHasAnyPlan = adminValues[4] ?? false;
    isHasAnyPlan = adminValues[4] ?? false;

    trialMap = await SharedPreferenceService.getTrialPeriodStartRaw();
    if (mounted) setState(() {});
  }

  String selectedSov = 'my';

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
            return Consumer2<ThemeProvider, MyLocationListProvider>(
              builder: (
                context,
                themeProvider,
                locationProfileProvider,
                child,
              ) {
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
                  floatingActionButton: Padding(
                    padding: const EdgeInsets.only(bottom: 50),
                    child: SafeArea(
                      child: GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            useSafeArea: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => ChatbotBottomSheet(
                              locationId: locationProfileProvider
                                  .locationProfile?.finalAddress?.locationId
                                  .toString(),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Need Help?",
                                style: TextStyle(color: Colors.white),
                              ),
                              SizedBox(width: 8),
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: AppColors.primaryMain,
                                child: Icon(Icons.smart_toy,
                                    color: Colors.white, size: 18),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
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
                                "Monitoring SoV",
                                style: TextStyle(
                                    fontSize: 20,
                                    color: const Color.fromRGBO(
                                        255, 255, 255, 0.7),
                                    fontWeight: FontWeight.w400),
                              )),
                          SizedBox(height: CustomSpacing.one),
                          Container(
                              padding: EdgeInsets.only(left: 20),
                              child: Text(
                                "Create focused monitoring groups for live natural catastrophe tracking. Maximum 5 SoVs, up to 15 locations each.",
                                style: TextStyle(
                                    fontSize: 14,
                                    color: const Color.fromRGBO(
                                        255, 255, 255, 0.7),
                                    fontWeight: FontWeight.w400),
                              )),
                          Expanded(
                            child: Container(
                              margin: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: monitoringsovBody(typography),
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
        ),
      ),
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

  Widget monitoringsovBody(CustomTypography typography) {
    return Consumer2<SOVListProvider, UserProfileProvider>(
        builder: (context, sovListProvider, user, _) {
      final String trialStatus = user.trialInfo['status'] ?? '';

      return (trialStatus.contains('Expired') && isHasAnyPlan == false)
          ? Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.95),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: MessageCard(
                      messageTextSpans: [
                        TextSpan(
                          text:
                              'We hope you\'ve enjoyed your trial period! To continue accessing your account and keep your data safe, please upgrade before ${trialMap ?? 'your trial end date'}. After this date, we will need to delete your data. Thank you for being with us!',
                          style: typography.Body1,
                        ),
                        // tappable
                        TextSpan(
                          text: ' Upgrade Now!',
                          style: typography.Body1.copyWith(
                            color: AppColors.primaryMain,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => PurchaseLicensePage()));
                            },
                        ),
                      ],
                      isError: true,
                    ),
                  ),
                ],
              ),
            )
          : ListView(
              controller: _scrollController1,
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Consumer<SOVListProvider>(
                  builder: (context, sovListProvider, _) {
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final isMobile = constraints.maxWidth < 600;

                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            SizedBox(
                              width: isMobile
                                  ? (constraints.maxWidth / 2) - 18
                                  : 220,
                              child: InfoCard(
                                title: "Total Events",
                                count: safeParseInt(
                                  sovListProvider.totalEvent.toString(),
                                ),
                                icon: Icons.gas_meter_outlined,
                              ),
                            ),
                            SizedBox(
                              width: isMobile
                                  ? (constraints.maxWidth / 2) - 18
                                  : 220,
                              child: InfoCard(
                                title: "Impacted Locations of Total",
                                count: safeParseInt(
                                  sovListProvider.totalImpactLocation,
                                ),
                                icon: Icons.flash_on,
                              ),
                            ),
                            SizedBox(
                              width: isMobile
                                  ? (constraints.maxWidth / 2) - 18
                                  : 220,
                              child: InfoCard(
                                title: "Hurricane Monitoring Locations",
                                count: safeParseInt(
                                  sovListProvider.hurricaneMonitoringLocations,
                                ),
                                icon: Icons.gas_meter_outlined,
                              ),
                            ),
                            SizedBox(
                              width: isMobile
                                  ? (constraints.maxWidth / 2) - 18
                                  : 220,
                              child: InfoCard(
                                title: "Earthquake Monitoring Locations",
                                count: safeParseInt(
                                  sovListProvider.earthquakeMonitoringLocations,
                                ),
                                icon: Icons.crisis_alert,
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
                monitoringLimitCard(),
                SizedBox(height: CustomSpacing.two),
                Consumer<SOVListProvider>(
                  builder: (context, sovListProvider, _) {
                    if (sovListProvider.isLoading) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 100),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (sovListProvider.monitoringSovList.isEmpty) {
                      return SizedBox(
                        height: MediaQuery.of(context).size.height * 0.5,
                        child: Center(
                          child: Text("Looks like you don’t have a sov yet."),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sovListProvider.isNextPageLoading
                          ? sovListProvider.monitoringSovList.length + 1
                          : sovListProvider.monitoringSovList.length,
                      itemBuilder: (context, index) {
                        if (index == sovListProvider.monitoringSovList.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        final sov = sovListProvider.monitoringSovList[index];

                        return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EventVisulisationScreen(
                                      notificationData: {
                                        'title':
                                            sov.hazardName ?? "Event Details",
                                        'body': "body",
                                        'timestamp':
                                            DateTime.fromMillisecondsSinceEpoch(
                                                (sov.updatedAt?.iSeconds ?? 0) *
                                                    1000),
                                        'eventId': sov.id,
                                        'lat':
                                            sov.locationCoordinates?.latitude ??
                                                20.5937,
                                        'long': sov.locationCoordinates
                                                ?.longitude ??
                                            78.9629,
                                        'frontendUrls': sov.frontendUrls,
                                      }),
                                ),
                              );

                            },
                            child: _buildMonitoringSovCard(
                                index, sovListProvider));
                      },
                    );
                  },
                ),
              ],
            );
    });
  }

  Widget monitoringLimitCard() {
    return Container(
      margin: const EdgeInsets.all(6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFFA726),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFA726).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFFFA726),
                  size: 22,
                ),
              ),
              SizedBox(width: 5),
              Text(
                "Monitoring Mode Limits Apply",
                style: TextStyle(
                  color: Color(0xFFFFA726),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(width: 12),

          SizedBox(height: 8),

          // Bullet Points
          _BulletText(
            text: "Maximum 5 Monitoring SoVs allowed per workspace",
          ),
          _BulletText(
            text: "Maximum 15 locations per Monitoring SoV",
          ),
          _BulletText(
            text:
                "Only Monitoring-tagged SoVs can be pushed to live monitoring",
          ),
        ],
      ),
    );
  }

  Widget _buildMonitoringSovCard(int index, SOVListProvider sOVListProvider) {
    var typography = CustomTypography(context);
    final sov = sOVListProvider.monitoringSovList[index];
    final sovId = sov.id ?? "";

    final meta = sOVListProvider.sovMeta[sovId];
    final isRefreshPending = meta?['refresh_pending'] == true;

    return Opacity(
      opacity: isRefreshPending ? 0.5 : 1.0,
      child: IgnorePointer(
        ignoring: isRefreshPending,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF2B2B2B),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white24,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: "Event Name : ",
                        style: typography.Body2.copyWith(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      TextSpan(
                        text: sov.eventName ?? "",
                        style: typography.Body2.copyWith(
                          color: const Color(0xFF64B5F6),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 6),

                /// 🔹 Locations Impacted
                Text(
                  "Locations Impacted : ${sov.impactedLocCount ?? 0}",
                  style: typography.Body2.copyWith(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 10),

                Container(
                  height: 1,
                  color: Colors.white24,
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    Text(
                      "Event Type : ",
                      style: typography.Body2.copyWith(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      sov.vendorName.toString(),
                      style: typography.Body2.copyWith(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    Text(
                      "Last Updated : ",
                      style: typography.Body2.copyWith(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '${DateFormat('MMM dd,yyyy HH:mm').format(DateTime.fromMillisecondsSinceEpoch(sov.updatedAt!.iSeconds! * 1000))}',
                      style: typography.Body2.copyWith(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<List<TransferAutocompleteModel>> fetchAutocompleteUsers(
    String query, String type) async {
  try {
    ApiService apiService = ApiService(AppConstant.GET_SEARCH_LIST_BY_SOV);
    String url = "/v2/search_users?search=${Uri.encodeComponent(query)}";
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
      height: 120,
      width: 180,
      child: Card(
        color: Colors.white12,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 1, 0, 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.white38,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white60,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: CustomSpacing.two),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: CustomSpacing.two),
              Text(
                count.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.17),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String? messageError;

class _BulletText extends StatelessWidget {
  final String text;

  const _BulletText({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "• ",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
