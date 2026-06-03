import 'package:RiskSphere/screens/listings/widgets/score_card_layout.dart';
import 'package:RiskSphere/screens/listings/widgets/vertical_bar_indicator.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../design_system/repo/constants.dart';
import '../../models/my_location_list_model.dart';
import '../../utils/enum.dart';
import '../../utils/global_imports.dart';
import '../../models/sov_list_model.dart';
import 'package:RiskSphere/models/role_model.dart' as roleModel;
import '../payments/purchase_license.dart';
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
  DateTime? _selectedDeadline;
  String? trialMap;
  Screens _selectedScreen = Screens.locationList;
  TextEditingController _sovNameEditNameController = TextEditingController();
  TextEditingController mobileController = TextEditingController();
  String selectedDropdown = 'TPV';
  int? touchedIndex; // For showing overlay info
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _showOverlay_mylocation = false;
  bool _isSendingInvite1 = false;
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
  bool isPgAdmin = false;
  bool isAdmin = false;
  bool isSuperAdmin = false;
  bool isIndivudual = false;
  ScrollController _scrollController = ScrollController();
  ScrollController _scrollController1 = ScrollController();
  Timer? deBouncer;
  List<MyLocation> selectedLocations = [];
  File? files;
  TabController? _mainTabController;
  int selectedMainTab = 0;
  int selectedTab = 0;
  int selectedMasterTab = 0;
  Set<String> selectedSovIds = {};

  /// Sov Things
  TextEditingController _textEditingController = TextEditingController();
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

  final _processIndex$ = BehaviorSubject<int>.seeded(0);
  String selectedSov = 'my';

  @override
  void initState() {
    super.initState();

    _setClaims();

    selectedSov = widget.status ?? "my";
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<SOVListProvider>();

      provider.page = 1;
      provider.totalPages = 1;

      provider.fetchSovList(context, _sovQuery, 1, 5, selectedSov);
    });

    _scrollController1.addListener(() {
      if (!_scrollController1.hasClients) return;

      final provider = context.read<SOVListProvider>();

      if (_scrollController1.position.pixels >=
              _scrollController1.position.maxScrollExtent - 300 &&
          !provider.isNextPageLoading &&
          provider.page < provider.totalPages) {
        provider.page++;

        provider.fetchSovList(
            context, _sovQuery, provider.page, 5, selectedSov);
      }
    });
  }

  Future<void> _reloadSovByStatus(
    String status,
  ) async {
    final provider = context.read<SOVListProvider>();

    provider.page = 1;
    provider.totalPages = 1;

    provider.sovList.clear();

    provider.notifyListeners();

    await provider.fetchSovList(
      context,
      _sovQuery,
      1,
      5,
      status,
    );
  }

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

    trialMap = await SharedPreferenceService.getTrialPeriodStartRaw();
    if (mounted) setState(() {});
  }

  String? _activeAccountKey; // track which account/subaccount timer belongs to

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
                          Row(
                            children: [
                              Container(
                                  padding: EdgeInsets.only(left: 20),
                                  child: Text(
                                    selectedSov == "received"
                                        ? "Received SOVs"
                                        : selectedSov == "my"
                                            ? "My SOVs"
                                            : selectedSov == "shared"
                                                ? "Shared SOVs"
                                                : "SOVs",
                                    style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600),
                                  )),
                              Spacer(),
                              if (!selectedList.contains(true)) ...[
                                IconButton(
                                  icon: Icon(Icons.share),
                                  onPressed: () {
                                    if (!selectedList.contains(true)) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Please select an SOV to share. long-press the SOV card to share it.')),
                                      );
                                    } else {}
                                  },
                                ),
                              ],
                              SizedBox(width: 30),
                            ],
                          ),
                          Expanded(
                            child: Container(
                              margin: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: sovBody(typography),
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

  void sovSearchClient(String query) {
    if (deBouncer?.isActive ?? false) deBouncer!.cancel();

    deBouncer = Timer(const Duration(milliseconds: 500), () async {
      if (!mounted) return;

      setState(() => _sovQuery = query.trim());

      final provider = Provider.of<SOVListProvider>(context, listen: false);
      provider.page = 1; // Reset to page 1 when searching

      await provider.fetchSovList(
        context,
        _sovQuery,
        1,
        5,
        selectedSov ?? "my",
      );
    });
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

  Widget sovBody(CustomTypography typography) {
    return Consumer2<SOVListProvider, UserProfileProvider>(
        builder: (context, sovListProvider, user, _) {
      final String trialStatus = user.trialInfo?['status'] ?? '';

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
                if (selectedList.contains(true)) _buildSelectionBar(typography),
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
                      hintText: LanguageService.getTranslated(
                          context, "search_by_sov_name"),
                      prefixIcon: const Icon(Icons.search),
                    ),
                  ),
                ),
                SizedBox(height: CustomSpacing.three),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Consumer<SOVListProvider>(
                    builder: (context, sovListProvider, _) {
                      return Row(
                        children: [
                          InkWell(
                            onTap: () async {},
                            child: InfoCard(
                              title: LanguageService.getTranslated(
                                  context, "total_sovs"),
                              count: safeParseInt(sovListProvider
                                  .sovCounterList.all
                                  .toString()),
                              icon: Icons.file_copy_outlined,
                              status: false,
                            ),
                          ),
                          const SizedBox(width: 12),
                          InkWell(
                            onTap: () async {
                              selectedSov = "my";

                              await _reloadSovByStatus(
                                "my",
                              );

                              if (mounted) {
                                setState(() {});
                              }
                            },
                            child: InfoCard(
                              title: LanguageService.getTranslated(
                                  context, "drawer_menu_mysovs"),
                              count: safeParseInt(
                                  sovListProvider.sovCounterList.my),
                              icon: Icons.file_copy_outlined,
                              status: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          InkWell(
                            onTap: () async {
                              selectedSov = "shared";

                              await _reloadSovByStatus(
                                "shared",
                              );

                              if (mounted) {
                                setState(() {});
                              }
                            },
                            child: InfoCard(
                              title: LanguageService.getTranslated(
                                  context, "drawer_menu_sharedsovs"),
                              count: safeParseInt(
                                  sovListProvider.sovCounterList.shared),
                              icon: Icons.ios_share_outlined,
                              status: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          InkWell(
                            onTap: () async {
                              selectedSov = "received";

                              await _reloadSovByStatus(
                                "received",
                              );

                              if (mounted) {
                                setState(() {});
                              }
                            },
                            child: InfoCard(
                              title: LanguageService.getTranslated(
                                  context, "drawer_menu_receivedsovs"),
                              count: safeParseInt(
                                  sovListProvider.sovCounterList.received),
                              icon: Icons.call_received_outlined,
                              status: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          InkWell(
                            onTap: () async {
                              // selectedSov = "completed";
                              //
                              // await _reloadSovByStatus(
                              //   "completed",
                              // );
                              //
                              // if (mounted) {
                              //   setState(() {});
                              // }
                            },
                            child: InfoCard(
                              title: LanguageService.getTranslated(
                                  context, "completed_sovs"),
                              count: safeParseInt(
                                  sovListProvider.sovCounterList.completed),
                              icon: Icons.ios_share_outlined,
                              status: false,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                SizedBox(height: CustomSpacing.four),
                Consumer<SOVListProvider>(
                  builder: (context, sovListProvider, _) {
                    if (sovListProvider.isLoading) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 100),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (sovListProvider.sovList.isEmpty) {
                      return SizedBox(
                        height: MediaQuery.of(context).size.height * 0.5,
                        child: Center(
                          child: Text(
                            "Looks like you don’t have a sov yet.",
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),

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
                    );
                  },
                ),
              ],
            );
    });
  }

  Widget _buildSelectionBar(CustomTypography typography) {
    return Consumer2<SOVListProvider, MyLocationListProvider>(
      builder: (context, sovListProvider, locationListProvider, _) {
        if (!selectedList.contains(true)) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              width: 1,
            ),
            color: Theme.of(context).colorScheme.surface,
          ),
          child: Row(
            children: [
              /// 🔹 Selected count
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "${selectedList.where((e) => e).length}",
                  style: typography.Body1.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              /// 🔹 Select / Deselect All
              TextButton(
                onPressed: () {
                  setState(() {
                    final bool selectAll = selectedList.any((e) => e == false);

                    for (int i = 0; i < selectedList.length; i++) {
                      selectedList[i] = selectAll;
                    }

                    if (!selectAll) {
                      isSelectionMode = false;
                    }
                  });
                },
                child: Text(
                  selectedList.any((e) => e == false)
                      ? 'Select All'
                      : 'Deselect All',
                  style: typography.Body1.copyWith(
                    color: AppColors.primaryMain,
                  ),
                ),
              ),

              const Spacer(),

              /// 🔹 Export
              IconButton(
                tooltip: 'Export Selected',
                icon: const Icon(Icons.download),
                onPressed: () {
                  final selectedSovIds = <String>[];

                  for (int i = 0;
                      i < selectedList.length &&
                          i < sovListProvider.sovList.length;
                      i++) {
                    if (selectedList[i]) {
                      final sov = sovListProvider.sovList[i];
                      if (sov.sovId != null) {
                        selectedSovIds.add(sov.sovId!);
                      }
                    }
                  }

                  if (selectedSovIds.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("No items selected")),
                    );
                    return;
                  }

                  final firstIndex = selectedList.indexWhere((e) => e);

                  final selectedSov = sovListProvider.sovList[firstIndex];

                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Export Selected Sov'),
                      content: Text('Export ${selectedSovIds.length} Sov(s)?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);

                            Provider.of<SOVListProvider>(context, listen: false)
                                .exportDataSov(
                              context,
                              selectedSov.accountId!,
                              selectedSov.subAccountId!,
                              {
                                "fileType": "profile",
                                "format": "excel",
                                "includeImage": false,
                                "sov_ids": selectedSovIds,
                              },
                              selectedSov.sovId!,
                            );
                          },
                          child: const Text('Export'),
                        ),
                      ],
                    ),
                  );
                },
              ),

              /// 🔹 Share (hide for received)
              if (selectedSov != "received")
                IconButton(
                  tooltip: 'Share Selected',
                  icon: const Icon(
                    Symbols.share,
                    color: Color(0xFF90CAF9),
                  ),
                  onPressed: () {
                    final selectedSovs = sovListProvider.sovList
                        .asMap()
                        .entries
                        .where((e) =>
                            e.key < selectedList.length && selectedList[e.key])
                        .map((e) => e.value)
                        .toList();

                    if (selectedSovs.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text("Please select at least one SOV to share."),
                        ),
                      );
                      return;
                    }

                    List<Map<String, dynamic>> selectedSovData = selectedSovs
                        .where((s) => s.sovId != null)
                        .map((s) => {
                              "sov_id": s.sovId,
                              "sov_name": s.name,
                            })
                        .toList();

                    _showTransferDialog(context, selectedSovData);
                  },
                ),
              // IconButton(
              //   tooltip: 'Share Selected',
              //   icon: const Icon(
              //     Symbols.share,
              //     color: Color(0xFF90CAF9),
              //   ),
              //   onPressed: () {
              //     final selectedSovs = sovListProvider.sovList
              //         .asMap()
              //         .entries
              //         .where((e) =>
              //             e.key < selectedList.length && selectedList[e.key])
              //         .map((e) => e.value)
              //         .toList();
              //
              //     if (selectedSovs.isEmpty) {
              //       ScaffoldMessenger.of(context).showSnackBar(
              //         const SnackBar(
              //           content:
              //               Text("Please select at least one SOV to share."),
              //         ),
              //       );
              //       return;
              //     }
              //
              //     // ✅ Sync selectedSovIds with all currently selected sovs
              //     selectedSovIds = selectedSovs
              //         .where((s) => s.sovId != null)
              //         .map((s) => s.sovId!)
              //         .toSet();
              //     List<Map<String, dynamic>> selectedSovData = selectedSovs
              //         .where((s) => s.sovId != null)
              //         .map((s) => {
              //       "sov_id": s.sovId,
              //       "sov_name": s.name,
              //     })
              //         .toList();
              //
              //     // _showTransferDialog(context, selectedSovs);
              //     _showTransferDialog(context, selectedSovs);
              //
              //   },
              //
              // ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSovCard(int index, SOVListProvider sOVListProvider) {
    var typography = CustomTypography(context);

    final sov = sOVListProvider.sovList[index];
    final sovId = sov.sovId ?? "";

    final meta = sOVListProvider.sovMeta[sovId];
    final isRefreshPending = meta?['refresh_pending'] == true;
    // final sharedUsersWithEmail = sov.sharingStatus.users.values
    //         .where((u) => u.email != null && u.email!.trim().isNotEmpty)
    //         .toList() ??
    //     [];
    final bool isExpanded = expandedIndexes.contains(index);

    return Opacity(
      opacity: isRefreshPending ? 0.5 : 1.0, // Fade UI
      child: IgnorePointer(
        ignoring: isRefreshPending, // Disable touch
        child: Container(
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

                  selectedSovIds = sOVListProvider.sovList
                      .asMap()
                      .entries
                      .where((entry) => selectedList[entry.key])
                      .map((entry) => entry.value.sovId)
                      .whereType<String>()
                      .toSet();
                } else {
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return SovLocationList(
                      status: selectedSov == "received"
                          ? "Received SOVs"
                          : selectedSov == "my"
                              ? "My SOVs"
                              : selectedSov == "shared"
                                  ? "Shared SOVs"
                                  : "SOVs",
                      accountID: sov.accountId,
                      subAccountID: sov.subAccountId,
                      accountName: "",
                      subAccountName: "",
                      sovID: sov.sovId ?? "",
                      sovName: sov.name ?? "",
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

                selectedSovIds = sOVListProvider.sovList
                    .asMap()
                    .entries
                    .where((entry) => selectedList[entry.key])
                    .map((entry) => entry.value.sovId)
                    .whereType<String>()
                    .toSet();
              });
            },
            child: Stack(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: isExpanded ? 220 : 132,
                            width: MediaQuery.of(context).size.width,
                            child: Card(
                              color: Colors.white12,
                              margin: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(width: CustomSpacing.two),
                                      Expanded(
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
                                                  child: Row(
                                                    children: [
                                                      if (isSelectionMode)
                                                        Checkbox(
                                                          value: (index <
                                                                  selectedList
                                                                      .length)
                                                              ? selectedList[
                                                                  index]
                                                              : false,
                                                          onChanged: (value) {
                                                            setState(() {
                                                              if (selectedList
                                                                      .length !=
                                                                  sOVListProvider
                                                                      .sovList
                                                                      .length) {
                                                                selectedList =
                                                                    List.generate(
                                                                  sOVListProvider
                                                                      .sovList
                                                                      .length,
                                                                  (_) => false,
                                                                );
                                                              }
                                                              selectedList[
                                                                      index] =
                                                                  value ??
                                                                      false;

                                                              if (!selectedList
                                                                  .contains(
                                                                      true)) {
                                                                isSelectionMode =
                                                                    false;
                                                              }
                                                            });
                                                          },
                                                        ),
                                                      Expanded(
                                                        child: Row(
                                                          children: [
                                                            Flexible(
                                                              child: Text(
                                                                sov.name ?? "",
                                                                style: typography
                                                                        .Body2
                                                                    .copyWith(
                                                                  fontSize: 20,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w400,
                                                                  color: const Color(
                                                                      0xFF90CAF9),
                                                                ),
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                width: 6),
                                                            // InkWell(
                                                            //   onTap: () =>
                                                            //       _showRenameDialog(
                                                            //           index,
                                                            //           sov),
                                                            //   child: const Icon(
                                                            //     Icons.edit,
                                                            //     size: 16,
                                                            //     color: Colors
                                                            //         .white70,
                                                            //   ),
                                                            // ),
                                                          ],
                                                        ),
                                                      ),
                                                      Chip(
                                                        label: Text(
                                                          sov.status ??
                                                              "Pending",
                                                          style: typography
                                                              .Body2.copyWith(
                                                            color: sov.status ==
                                                                    "completed"
                                                                ? Colors.white
                                                                : Color(
                                                                    0xFFFFA726),
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                        ),
                                                        backgroundColor: sov
                                                                    .status ==
                                                                "completed"
                                                            ? Colors.green
                                                            : Color(0xFFFFA726)
                                                                .withOpacity(
                                                                    0.2),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: AnimatedRotation(
                                                    turns: isExpanded
                                                        ? 0.5
                                                        : 0.0, // 180°
                                                    duration: const Duration(
                                                        milliseconds: 200),
                                                    child: Icon(
                                                      Icons.expand_circle_down,
                                                      color:
                                                          AppColors.primaryMain,
                                                    ),
                                                  ),
                                                  onPressed: () {
                                                    setState(() {
                                                      if (isExpanded) {
                                                        expandedIndexes
                                                            .remove(index);
                                                      } else {
                                                        expandedIndexes
                                                            .add(index);
                                                      }
                                                    });
                                                  },
                                                ),
                                                _buildMoreMenu(index, sov),
                                              ],
                                            ),
                                            if (isExpanded) ...[
                                              Row(
                                                children: [
                                                  CircleAvatar(
                                                    radius: 16,
                                                    backgroundColor:
                                                        Colors.grey[800],
                                                    child: Text(
                                                      sov.owner?.name
                                                              ?.substring(0, 2)
                                                              .toUpperCase() ??
                                                          "?",
                                                      style: TextStyle(
                                                          color: Colors.white),
                                                    ),
                                                  ),
                                                  SizedBox(width: 10),
                                                  Expanded(
                                                    child: Text(
                                                      sov.owner?.name ??
                                                          "Unknown",
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                        color: Colors.white,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  SizedBox(width: 10),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 5,
                                                        vertical: 6),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                          0xFF2A2A2A),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                      border: Border.all(
                                                          color: const Color(
                                                              0xFF3A3A3A)),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        const Icon(
                                                            Icons.location_on,
                                                            size: 18,
                                                            color:
                                                                Colors.white),
                                                        const SizedBox(
                                                            width: 2),
                                                        Text(
                                                          "${sov.locationCount ?? 0}",
                                                          style: typography
                                                              .Body2.copyWith(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  SizedBox(width: 6),
                                                  selectedSov
                                                              .toString()
                                                              .toLowerCase() ==
                                                          "shared"
                                                      ? InkWell(
                                                          // onTap: () =>
                                                          // _showSharedWithDialog(
                                                          //     context,
                                                          //     sov.sharingStatus),
                                                          child: Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        5,
                                                                    vertical:
                                                                        6),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: const Color(
                                                                  0xFF2A2A2A),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8),
                                                              border: Border.all(
                                                                  color: const Color(
                                                                      0xFF3A3A3A)),
                                                            ),
                                                            child: Row(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                const Icon(
                                                                  Icons.mail,
                                                                  size: 16,
                                                                  color: Colors
                                                                      .white,
                                                                ),
                                                                const SizedBox(
                                                                    width: 4),
                                                                Text(
                                                                  "${sov.sharingStatus!.email?.length ?? ""}",
                                                                  style: typography
                                                                          .Body2
                                                                      .copyWith(
                                                                    color: Colors
                                                                        .white,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        )
                                                      : Container(),
                                                  SizedBox(width: 4),
                                                ],
                                              ),
                                              SizedBox(height: 8),
                                              if ((sov.companyName ?? "")
                                                  .isNotEmpty)
                                                Text(
                                                  "Company: ${sov.companyName}",
                                                  style:
                                                      typography.Body2.copyWith(
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              SizedBox(height: 8),
                                              Container(
                                                  padding: EdgeInsets.only(
                                                      right: 5, left: 5),
                                                  child: Divider()),
                                              SizedBox(height: 8),
                                            ],
                                            _buildScrollableScores(
                                              context,
                                              sov.geocodeAvg.toString(),
                                              sov.overallAvg.toString(),
                                              sov.dataCompleteness.toString(),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
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
                if (isRefreshPending)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.blue,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMoreMenu(int index, Result sov) {
    return Consumer2<SubAccountListProvider, SOVListProvider>(
      builder: (context, subAccountListProvider, sovProvider, child) {
        return PopupMenuButton<MoreMenuAction>(
          color: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: (value) async {
            switch (value) {
              case MoreMenuAction.rename:
                _showRenameDialog(index, sov);
                break;
              case MoreMenuAction.duplicate:
                _showDuplicateDialog(
                  context,
                  sovProvider,
                  index,
                );
                break;
              case MoreMenuAction.delete:
                _showDeleteDialog(
                  context,
                  subAccountListProvider,
                  sovProvider,
                  index,
                );
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem<MoreMenuAction>(
              value: MoreMenuAction.rename,
              child: Row(
                children: const [
                  Icon(Icons.edit, color: Colors.white70),
                  SizedBox(width: 8),
                  Text(
                    "Rename",
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            PopupMenuItem<MoreMenuAction>(
              value: MoreMenuAction.duplicate,
              child: Row(
                children: const [
                  Icon(Icons.file_copy_rounded, color: Colors.white70),
                  SizedBox(width: 8),
                  Text(
                    "Duplicate",
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            if (selectedSov.toString() != "received")
              PopupMenuItem<MoreMenuAction>(
                value: MoreMenuAction.delete,
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.redAccent),
                    SizedBox(width: 8),
                    Text(
                      "Delete",
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    SubAccountListProvider subAccountListProvider,
    SOVListProvider sovProvider,
    int index,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool loading = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: const Text(
                "Confirm Deletion",
                style: TextStyle(color: Colors.white),
              ),
              content: const Text(
                "Are you sure you want to delete this SOV?",
                style: TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel",
                      style: TextStyle(color: Colors.grey)),
                ),
                TextButton(
                  onPressed: () async {
                    setState(() => loading = true);

                    final success =
                        await subAccountListProvider.deleteSOVAccount(
                      context,
                      sovProvider.sovList[index].accountId!,
                      sovProvider.sovList[index].subAccountId!,
                      sovProvider.sovList[index].sovId!,
                    );

                    if (success) {
                      Navigator.pop(context);
                      await sovProvider.fetchSovList(
                          context, "", 1, 5, selectedSov);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("SOV deleted successfully"),
                        ),
                      );
                    }

                    setState(() => loading = false);
                  },
                  child: loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          "Delete",
                          style: TextStyle(color: Colors.redAccent),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDuplicateDialog(
    BuildContext context,
    SOVListProvider sovProvider,
    int index,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool loading = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              title: const Text(
                "Duplicate SOV",
                style: TextStyle(color: Colors.white),
              ),
              content: const Text(
                "Are you sure you want to duplicate this SOV?",
                style: TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: loading ? null : () => Navigator.pop(context),
                  child: const Text("Cancel",
                      style: TextStyle(color: Colors.grey)),
                ),
                TextButton(
                  onPressed: () async {
                    setState(() => loading = true);

                    final success = await sovProvider.duplicateSov(
                      context,
                      sovProvider.sovList[index].sovId!,
                    );

                    if (success) {
                      Navigator.pop(context);
                      await sovProvider.fetchSovList(
                          context, "", 1, 5, selectedSov);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("SOV duplicated successfully"),
                        ),
                      );
                    }

                    setState(() => loading = false);
                  },
                  child: loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          "Duplicate",
                          style: TextStyle(color: Colors.lightBlueAccent),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showRenameDialog(int index, Result sov) {
    final typography = CustomTypography(context);

    _sovNameEditNameController.text = sov.name ?? "";

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(LanguageService.getTranslated(context, "edit_sov"),
              style: typography.H5_Regular),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _sovNameEditNameController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: LanguageService.getTranslated(context, "sov_name"),
                  labelStyle: typography.Body1,
                  hintText:
                      LanguageService.getTranslated(context, "enter_sov_name"),
                  hintStyle: typography.Body1,
                ),
              ),
              SizedBox(height: CustomSpacing.two),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                          LanguageService.getTranslated(context, "cancel"),
                          style: typography.ButtonLarge),
                      type: ButtonType.text,
                    ),
                  ),

                  /// 🔥 RENAME BUTTON
                  Consumer<AccountListProvider>(
                    builder: (context, accountListProvider, _) {
                      return accountListProvider.isRenameLoading
                          ? const Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 25,
                                    height: 25,
                                    child: CircularProgressIndicator(),
                                  ),
                                ],
                              ),
                            )
                          : Expanded(
                              child: CustomButton(
                                onPressed: () async {
                                  final newName =
                                      _sovNameEditNameController.text.trim();

                                  if (newName.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("Name cannot be empty"),
                                      ),
                                    );
                                    return;
                                  }

                                  /// START LOADER
                                  accountListProvider.isRenameLoading = true;
                                  accountListProvider.notifyListeners();

                                  /// 1️⃣ SEND RENAME REQUEST
                                  await accountListProvider.renameSov(
                                    context,
                                    sov.sovId.toString(),
                                    newName,
                                  );

                                  /// 2️⃣ REFRESH LIST
                                  final sovProvider =
                                      Provider.of<SOVListProvider>(context,
                                          listen: false);

                                  await sovProvider.fetchSovList(
                                      context, "", 1, 5, selectedSov);

                                  /// STOP LOADER
                                  accountListProvider.isRenameLoading = false;
                                  accountListProvider.notifyListeners();

                                  Navigator.pop(context);
                                },
                                child: Text(
                                  LanguageService.getTranslated(
                                      context, "update"),
                                  style: typography.ButtonLargeBlack,
                                ),
                                type: ButtonType.elevated,
                              ),
                            );
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScrollableScores(BuildContext context, String geocoding,
      String riskScore, String completeness) {
    final layout = ScoreCardLayout.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          InkWell(
            onTap: () {},
            child: _buildScoreCard(
              context,
              LanguageService.getTranslated(context, "geocoding"),
              int.tryParse(geocoding) ?? 1,
            ),
          ),
          SizedBox(width: layout.cardSpacing),
          InkWell(
            onTap: () {},
            child: _buildScoreCard(
              context,
              LanguageService.getTranslated(context, "hazard_score"),
              int.tryParse(riskScore) ?? 1,
            ),
          ),
          SizedBox(width: layout.cardSpacing),
          InkWell(
            onTap: () {},
            child: _buildScoreCard(
              context,
              LanguageService.getTranslated(context, "completeness"),
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
    final layout = ScoreCardLayout.of(context);
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
      padding: EdgeInsets.all(layout.cardPadding),
      width: layout.cardWidth,
      height: layout.cardHeight,
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
                      fontSize: layout.titleFontSize,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryMain,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    textAlign: layout.compactLayout
                        ? TextAlign.center
                        : TextAlign.left,
                  ),
                ),
                SizedBox(width: 4),
              ],
            ),
          ),
          // SizedBox(height: 2),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InkWell(
                  onTap: () {},
                  child: VerticalBarIndicator(score: score == 0 ? 1 : score),
                ),
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
                              textAlign: layout.compactLayout
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
      BuildContext context, List<Map<String, dynamic>> sovs) async {
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
          // final results = await fetchAutocompleteUsers(query, type);
          final results =
              await fetchAutocompleteUsers(query.trim().toLowerCase(), type);

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

    String buildSovTitle(List<Map<String, dynamic>> sovs) {
      if (sovs.isEmpty) return "Share SOV";

      String firstName = (sovs.first["sov_name"] ?? "").toString();

      if (sovs.length == 1) {
        return 'Share "$firstName" SOV';
      }

      return 'Share "$firstName" +${sovs.length - 1} SOV';
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // IMPORTANT
      elevation: 0,
      // handled by Material
      builder: (BuildContext dialogContext) {
        return Material(
          color: const Color(0xFF121212),
          elevation: 12,
          shadowColor: Colors.black.withOpacity(0.6),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: StatefulBuilder(
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
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade600,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Text(
                        buildSovTitle(sovs),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),

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
                                          "role_id": user.lastSelectedRole!.role
                                              .toString(),
                                          "role_name": roleObj.name ?? '',
                                        },
                                        "share_expiry": selectedDeadline
                                            .toUtc()
                                            .toIso8601String(),
                                      });
                                    }
                                  }
                                  setState(() {
                                    _isShareEnabled = canShareAll();
                                  });
                                  debugPrint(
                                      " Selected Users JSON: $selectedUsersJson");
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
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 8),
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
                                                backgroundColor:
                                                    Colors.grey[800],
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
                                              user.isConnected == false &&
                                                      user.belongsToCompany ==
                                                          false &&
                                                      user.isIndividual == false
                                                  ? Container()
                                                  : Checkbox(
                                                      value: isSelected,
                                                      activeColor: const Color(
                                                          0xFF90CAF9),
                                                      onChanged: (value) =>
                                                          toggleSelection(
                                                              value),
                                                    )
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6),
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                    color: const Color(
                                                        0xFF4FC3F7)),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                user.isIndividual == false
                                                    ? "Other Company"
                                                    : "Individual",
                                                style: const TextStyle(
                                                  color: Color(0xFF4FC3F7),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          if (user.isConnected == false &&
                                              user.belongsToCompany == false &&
                                              user.isIndividual == false) ...[
                                            const SizedBox(height: 12),
                                            Consumer<SOVListProvider>(
                                              builder: (context, provider, _) {
                                                final isRequested = provider
                                                    .requestedUserIds
                                                    .contains(user.userid);

                                                return SizedBox(
                                                  width: double.infinity,
                                                  height: 44,
                                                  child: OutlinedButton.icon(
                                                    onPressed: isRequested
                                                        ? null
                                                        : () {
                                                            _showRequestConnectionDialog(
                                                              context,
                                                              userId:
                                                                  user.userid ??
                                                                      "",
                                                              userName:
                                                                  user.name ??
                                                                      "Naveen",
                                                              userRole: user
                                                                      .role ??
                                                                  "Insurance Broker",
                                                              sovName:
                                                                  "SOV Name",
                                                            );
                                                          },
                                                    icon: Icon(
                                                      isRequested
                                                          ? Icons
                                                              .check_circle_outline
                                                          : Icons
                                                              .person_add_alt_1,
                                                      color: isRequested
                                                          ? Colors.grey
                                                          : const Color(
                                                              0xFF4FC3F7),
                                                    ),
                                                    label: Text(
                                                      isRequested
                                                          ? "Request Sent"
                                                          : "Connect",
                                                      style: TextStyle(
                                                        color: isRequested
                                                            ? Colors.grey
                                                            : const Color(
                                                                0xFF4FC3F7),
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                    style: OutlinedButton
                                                        .styleFrom(
                                                      side: BorderSide(
                                                        color: isRequested
                                                            ? Colors.grey
                                                            : const Color(
                                                                0xFF4FC3F7),
                                                      ),
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10),
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ] else ...[
                                            const SizedBox(height: 12),
                                            IgnorePointer(
                                              ignoring: !isSelected,
                                              child: Opacity(
                                                opacity: isSelected ? 1 : 0.4,
                                                child: Builder(
                                                  builder: (context) {
                                                    final roles =
                                                        user.roles ?? [];

                                                    //  Reset when unchecked
                                                    if (!isSelected) {
                                                      _selectedRoles[index] =
                                                          null;
                                                    }

                                                    // 🔥 CASE 1: Only ONE role → show STATIC field but full width
                                                    if (isSelected &&
                                                        roles.length == 1) {
                                                      final roleName =
                                                          roles.first.name ??
                                                              "";

                                                      // Auto assign when checkbox selected
                                                      _selectedRoles[index] =
                                                          roleName;

                                                      return Container(
                                                        width: double.infinity,
                                                        // ⬅ FULL WIDTH
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 12,
                                                                vertical: 14),
                                                        decoration:
                                                            BoxDecoration(
                                                          border: Border.all(
                                                              color: Colors.grey
                                                                  .shade700),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                        ),
                                                        child: Text(
                                                          roleName,
                                                          style:
                                                              const TextStyle(
                                                                  color: Colors
                                                                      .white),
                                                        ),
                                                      );
                                                    }

                                                    //  CASE 2: MULTIPLE roles → show dropdown with same width
                                                    return Container(
                                                      width: double.infinity,
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 12),
                                                      decoration: BoxDecoration(
                                                        border: Border.all(
                                                            color: Colors
                                                                .grey.shade700),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                      ),
                                                      child:
                                                          DropdownButtonHideUnderline(
                                                        child: DropdownButton<
                                                            String>(
                                                          value: _selectedRoles[
                                                              index],
                                                          hint: const Text(
                                                            'Select Role',
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .white70),
                                                          ),
                                                          dropdownColor:
                                                              const Color(
                                                                  0xFF2C2C2C),
                                                          icon: const Icon(
                                                            Icons
                                                                .arrow_drop_down,
                                                            color:
                                                                Colors.white70,
                                                          ),
                                                          isExpanded: true,
                                                          items: roles
                                                              .map(
                                                                (role) =>
                                                                    DropdownMenuItem<
                                                                        String>(
                                                                  value:
                                                                      role.name,
                                                                  child: Text(
                                                                    role.name ??
                                                                        '',
                                                                    style: const TextStyle(
                                                                        color: Colors
                                                                            .white),
                                                                  ),
                                                                ),
                                                              )
                                                              .toList(),
                                                          onChanged: isSelected
                                                              ? (value) {
                                                                  setInnerState(
                                                                      () {
                                                                    _selectedRoles[
                                                                            index] =
                                                                        value;
                                                                    roleError =
                                                                        null;
                                                                  });

                                                                  updateSelectedUsersJson();
                                                                }
                                                              : null,
                                                        ),
                                                      ),
                                                    );
                                                  },
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
                                                      initialDate:
                                                          _selectedDeadlines[
                                                                  index] ??
                                                              now,
                                                      firstDate: DateTime(
                                                          now.year,
                                                          now.month,
                                                          now.day),
                                                      lastDate: DateTime(2100),
                                                    );
                                                    if (pickedDate != null) {
                                                      final cleanDate =
                                                          DateTime(
                                                        pickedDate.year,
                                                        pickedDate.month,
                                                        pickedDate.day,
                                                      );
                                                      setState(() {
                                                        _selectedDeadlines[
                                                            index] = cleanDate;
                                                        deadlineError = null;
                                                      });
                                                      updateSelectedUsersJson();
                                                    }
                                                  },
                                                  child: Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 12,
                                                        vertical: 12),
                                                    decoration: BoxDecoration(
                                                      border: Border.all(
                                                          color: Colors
                                                              .grey.shade700),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            _selectedDeadlines[
                                                                        index] !=
                                                                    null
                                                                ? DateFormat(
                                                                        'MM/dd/yyyy')
                                                                    .format(_selectedDeadlines[
                                                                        index]!)
                                                                : "Select Date",
                                                            style: const TextStyle(
                                                                color: Colors
                                                                    .white70),
                                                          ),
                                                        ),
                                                        const Icon(
                                                          Icons
                                                              .calendar_today_outlined,
                                                          color: Colors.white70,
                                                          size: 20,
                                                        ),
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
                                        ],
                                      ),
                                    );
                                  },
                                );
                              }),
                            ),
                          ),
                        )
                      else if (_userSearchController.text.trim().isNotEmpty &&
                          !_isSearching &&
                          RegExp(r'^[\w.-]+@[\w.-]+\.[a-zA-Z]{2,}$')
                              .hasMatch(_userSearchController.text.trim())) ...[
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade700),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.grey[800],
                                    child: Text(
                                      _userSearchController.text
                                          .trim()[0]
                                          .toUpperCase(),
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _userSearchController.text.trim(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Text("Set Deadline",
                                  style: TextStyle(
                                      fontSize: 13, color: Colors.grey)),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () async {
                                  final now = DateTime.now();

                                  final pickedDate = await showDatePicker(
                                    context: context,
                                    initialDate: _selectedDeadline ?? now,
                                    firstDate:
                                        DateTime(now.year, now.month, now.day),
                                    lastDate: DateTime(2100),
                                  );

                                  if (pickedDate != null) {
                                    setState(() {
                                      _selectedDeadline = DateTime(
                                        pickedDate.year,
                                        pickedDate.month,
                                        pickedDate.day,
                                      );
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 12),
                                  decoration: BoxDecoration(
                                    border:
                                        Border.all(color: Colors.grey.shade700),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _selectedDeadline != null
                                              ? DateFormat('MM/dd/yyyy')
                                                  .format(_selectedDeadline!)
                                              : "Select Date",
                                          style: const TextStyle(
                                              color: Colors.white70),
                                        ),
                                      ),
                                      const Icon(
                                        Icons.calendar_today_outlined,
                                        color: Colors.white70,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Consumer<SOVListProvider>(
                                builder: (context, sovListProvider, _) {
                                  final bool isDisabled =
                                      _selectedDeadline == null ||
                                          _isSendingInvite1;

                                  return SizedBox(
                                    width: double.infinity,
                                    height: 48,
                                    child: OutlinedButton(
                                      onPressed: isDisabled
                                          ? null
                                          : () async {
                                              final email =
                                                  _userSearchController.text
                                                      .trim();

                                              if (email.isEmpty) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                      content:
                                                          Text("Enter email")),
                                                );
                                                return;
                                              }

                                              ///  SHOW LOADER
                                              setState(() =>
                                                  _isSendingInvite1 = true);

                                              try {
                                                final deadline =
                                                    _selectedDeadline!;

                                                List<Map<String, dynamic>>
                                                    shareWithList = [
                                                  {
                                                    "user_id": "",
                                                    "email": email,
                                                    "role": {
                                                      "role_id": "invite",
                                                      "role_name": "invite"
                                                    },
                                                    "share_expiry":
                                                        DateFormat('yyyy-MM-dd')
                                                            .format(deadline),
                                                  }
                                                ];

                                                final Set<String>
                                                    sovIdsToShare = sovs
                                                        .where((s) =>
                                                            s["sov_id"] != null)
                                                        .map((s) => s["sov_id"]
                                                            .toString())
                                                        .toSet();

                                                bool success =
                                                    await sovListProvider
                                                        .shareSov(
                                                  sovId: sovIdsToShare,
                                                  shareWithList: shareWithList,
                                                );

                                                if (!mounted) return;

                                                setState(() =>
                                                    _isSendingInvite1 = false);

                                                if (success) {
                                                  setState(() {
                                                    _selectedDeadline = null;
                                                    _userSearchController
                                                        .clear(); // optional
                                                    isSelectionMode = false;
                                                  });

                                                  Navigator.pop(dialogContext);
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                        content: Text(
                                                            "Invite sent successfully")),
                                                  );
                                                } else {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                        content: Text(
                                                            "Failed to send invite")),
                                                  );
                                                }
                                              } catch (e) {
                                                setState(() =>
                                                    _isSendingInvite1 = false);
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                      content: Text(
                                                          "Something went wrong")),
                                                );
                                              }
                                            },
                                      style: OutlinedButton.styleFrom(
                                        backgroundColor: _isSendingInvite1
                                            ? Colors.transparent
                                            : Colors.transparent,
                                        side: BorderSide(
                                          color: isDisabled
                                              ? Colors.grey
                                              : const Color(0xFF4FC3F7),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                      child: _isSendingInvite1
                                          ? Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: const [
                                                SizedBox(
                                                  width: 18,
                                                  height: 18,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: Color(0xFF4FC3F7),
                                                  ),
                                                ),
                                                SizedBox(width: 10),
                                                Text(
                                                  "Sending...",
                                                  style: TextStyle(
                                                    color: Color(0xFF4FC3F7),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            )
                                          : Text(
                                              "Send Invite",
                                              style: TextStyle(
                                                color: isDisabled
                                                    ? Colors.grey
                                                    : const Color(0xFF4FC3F7),
                                                fontWeight: FontWeight.w600,
                                                fontSize: 15,
                                              ),
                                            ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),

                      const Text(
                        "Note: Users with multiple roles must be assigned one role per SOV.",
                        style:
                            TextStyle(fontSize: 14, color: Color(0xFF9FA6AD)),
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
                                  onPressed: (!_isShareEnabled || _isSharingSov)
                                      ? null
                                      : () async {
                                          setState(() => _isSharingSov =
                                              true); // ✅ local loader

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
                                              "email": user.email ?? '',
                                              "role": {
                                                "role_id": user
                                                    .lastSelectedRole!.role
                                                    .toString(),
                                                "role_name":
                                                    selectedRole?.name ?? '',
                                              },
                                              "share_expiry":
                                                  DateFormat('yyyy-MM-dd')
                                                      .format(deadline!),
                                            });
                                          }

                                          final Set<String> sovIdsToShare = sovs
                                              .where((s) => s["sov_id"] != null)
                                              .map(
                                                  (s) => s["sov_id"].toString())
                                              .toSet();

                                          bool success =
                                              await sovListProvider.shareSov(
                                            sovId: sovIdsToShare,
                                            shareWithList: shareWithList,
                                          );

                                          if (!mounted) return;

                                          setState(() => _isSharingSov =
                                              false); // ✅ stop loader

                                          if (success) {
                                            Navigator.pop(dialogContext);

                                            setState(() {
                                              selectedList = List.filled(
                                                  selectedList.length, false);
                                              isSelectionMode = false;
                                            });

                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                    "SOV shared successfully"),
                                              ),
                                            );
                                          } else {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                    "Failed to share SOV."),
                                              ),
                                            );
                                          }
                                        },

                                  /// ✅ FIXED LOADER
                                  child: _isSharingSov
                                      ? const CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        )
                                      : const Text("Share SOV",
                                          style:
                                              TextStyle(color: Colors.black)),
                                );
                              },
                            ),
                          ),
                          // Expanded(
                          //   child: Consumer<SOVListProvider>(
                          //     builder: (context, sovListProvider, _) {
                          //       return CustomButton(
                          //         type: ButtonType.elevated,
                          //         onPressed: (!_isShareEnabled ||
                          //                 sovListProvider.isLoading)
                          //             ? null
                          //             : () async {
                          //                 List<Map<String, dynamic>>
                          //                     shareWithList = [];
                          //
                          //                 for (int index in _selectedIndexes) {
                          //                   final user =
                          //                       _autocompleteUsersList[index];
                          //                   final roleName =
                          //                       _selectedRoles[index];
                          //                   final deadline =
                          //                       _selectedDeadlines[index];
                          //
                          //                   final selectedRole = user.roles
                          //                       ?.firstWhere(
                          //                           (r) => r.name == roleName);
                          //
                          //                   shareWithList.add({
                          //                     "user_id": user.userid ?? '',
                          //                     "email": user.email ?? '',
                          //                     "role": {
                          //                       "role_id": user
                          //                           .lastSelectedRole!.role
                          //                           .toString(),
                          //                       "role_name":
                          //                           selectedRole?.name ?? '',
                          //                     },
                          //                     "share_expiry":
                          //                         DateFormat('yyyy-MM-dd')
                          //                             .format(deadline!),
                          //                   });
                          //                 }
                          //
                          //                 final Set<String> sovIdsToShare = sovs
                          //                     .where((s) => s["sov_id"] != null)
                          //                     .map(
                          //                         (s) => s["sov_id"].toString())
                          //                     .toSet();
                          //
                          //                 bool success =
                          //                     await sovListProvider.shareSov(
                          //                   sovId: sovIdsToShare,
                          //                   shareWithList: shareWithList,
                          //                 );
                          //
                          //                 if (!mounted) return;
                          //
                          //                 if (success) {
                          //                   Navigator.pop(dialogContext);
                          //                   setState(() {
                          //                     selectedList = List.filled(
                          //                         selectedList.length, false);
                          //                     isSelectionMode = false;
                          //                   });
                          //                   ScaffoldMessenger.of(context)
                          //                       .showSnackBar(
                          //                     const SnackBar(
                          //                       content: Text(
                          //                           "SOV shared successfully"),
                          //                     ),
                          //                   );
                          //                 } else {
                          //                   ScaffoldMessenger.of(context)
                          //                       .showSnackBar(
                          //                     const SnackBar(
                          //                       content: Text(
                          //                           "Failed to share SOV."),
                          //                     ),
                          //                   );
                          //                 }
                          //               },
                          //         child: sovListProvider.isLoading
                          //             ? const CircularProgressIndicator(
                          //                 color: Colors.white, strokeWidth: 2)
                          //             : const Text("Share SOV",
                          //                 style:
                          //                     TextStyle(color: Colors.black)),
                          //       );
                          //     },
                          //   ),
                          // ),
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
          ),
//             StatefulBuilder(
//               builder: (BuildContext context, StateSetter setState) {
//                 return Padding(
//                   padding: EdgeInsets.only(
//                     left: 16,
//                     right: 16,
//                     top: 16,
//                     bottom: MediaQuery.of(context).viewInsets.bottom + 16,
//                   ),
//                   child: SingleChildScrollView(
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Container(
//                           width: 40,
//                           height: 4,
//                           margin: const EdgeInsets.only(bottom: 12),
//                           decoration: BoxDecoration(
//                             color: Colors.grey.shade600,
//                             borderRadius: BorderRadius.circular(4),
//                           ),
//                         ),
//                         Text(
//                           buildSovTitle(sovs),
//                           style: const TextStyle(
//                             fontSize: 20,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.white,
//                           ),
//                         ),
//                         SizedBox(height: 4),
//
//                         TextField(
//                           controller: _userSearchController,
//                           onChanged: (value) => _onSearchChanged(
//                               value, setState, _selectedOption.name),
//                           decoration: InputDecoration(
//                             labelText: "Search user",
//                             prefixIcon: const Icon(Icons.search),
//                             border: OutlineInputBorder(
//                                 borderRadius: BorderRadius.circular(8)),
//                           ),
//                         ),
//                         const SizedBox(height: 16),
//
//                         if (_isSearching)
//                           const Center(child: CircularProgressIndicator())
//                         else if (_autocompleteUsersList.isNotEmpty)
//                           SizedBox(
//                             height: 300,
//                             child: SingleChildScrollView(
//                               child: Column(
//                                 children: List.generate(
//                                     _autocompleteUsersList.length, (index) {
//                                   final user = _autocompleteUsersList[index];
//                                   final isSelected =
//                                       _selectedIndexes.contains(index);
//                                   final selectedRole = _selectedRoles[index];
//                                   final deadline = _selectedDeadlines[index];
//
//                                   String? roleError;
//                                   String? deadlineError;
//
//                                   bool canShareAll() {
//                                     for (int i in _selectedIndexes) {
//                                       if (_selectedRoles[i] == null ||
//                                           _selectedDeadlines[i] == null) {
//                                         return false;
//                                       }
//                                     }
//                                     return _selectedIndexes.isNotEmpty;
//                                   }
//
//                                   void updateSelectedUsersJson() {
//                                     selectedUsersJson.clear();
//                                     for (var i in _selectedIndexes) {
//                                       final selectedUser =
//                                           _autocompleteUsersList[i];
//                                       final selectedRole = _selectedRoles[i];
//                                       final selectedDeadline =
//                                           _selectedDeadlines[i];
//
//                                       if (selectedRole != null &&
//                                           selectedDeadline != null) {
//                                         final roleObj =
//                                             selectedUser.roles!.firstWhere(
//                                           (r) => r.name == selectedRole,
//                                         );
//
//                                         selectedUsersJson.add({
//                                           "user_id": selectedUser.userid ?? '',
//                                           "role": {
//                                             // "role_id": roleObj.role ?? '',
//                                             "role_id": user
//                                                 .lastSelectedRole!.role
//                                                 .toString(),
//                                             "role_name": roleObj.name ?? '',
//                                           },
//                                           "share_expiry": selectedDeadline
//                                               .toUtc()
//                                               .toIso8601String(),
//                                         });
//                                       }
//                                     }
//
//                                     // Enable/disable Share button
//                                     setState(() {
//                                       _isShareEnabled = canShareAll();
//                                     });
//
//                                     debugPrint(
//                                         "✅ Selected Users JSON: $selectedUsersJson");
//                                   }
//
//                                   void toggleSelection(bool? value) {
//                                     setState(() {
//                                       if (value == true) {
//                                         _selectedIndexes.add(index);
//                                       } else {
//                                         _selectedIndexes.remove(index);
//                                         _selectedRoles[index] = null;
//                                         _selectedDeadlines[index] = null;
//                                       }
//                                       updateSelectedUsersJson();
//                                     });
//                                   }
//
//                                   return StatefulBuilder(
//                                     builder: (context, setInnerState) {
//                                       return Container(
//                                         margin: const EdgeInsets.symmetric(
//                                             vertical: 8),
//                                         padding: const EdgeInsets.all(12),
//                                         decoration: BoxDecoration(
//                                           color: const Color(0xFF1E1E1E),
//                                           borderRadius:
//                                               BorderRadius.circular(12),
//                                           border: Border.all(
//                                             color: isSelected
//                                                 ? Colors.blue
//                                                 : Colors.grey.shade700,
//                                             width: 1.5,
//                                           ),
//                                         ),
//                                         child: Column(
//                                           crossAxisAlignment:
//                                               CrossAxisAlignment.start,
//                                           children: [
//                                             Row(
//                                               crossAxisAlignment:
//                                                   CrossAxisAlignment.center,
//                                               children: [
//                                                 CircleAvatar(
//                                                   backgroundColor:
//                                                       Colors.grey[800],
//                                                   child: Text(
//                                                     (user.name != null &&
//                                                             user.name!
//                                                                 .isNotEmpty)
//                                                         ? user.name!
//                                                             .substring(0, 2)
//                                                             .toUpperCase()
//                                                         : "?",
//                                                     style: const TextStyle(
//                                                         color: Colors.white),
//                                                   ),
//                                                 ),
//                                                 const SizedBox(width: 10),
//                                                 Expanded(
//                                                   child: Text(
//                                                     user.name ?? "Unknown",
//                                                     style: const TextStyle(
//                                                       fontWeight:
//                                                           FontWeight.bold,
//                                                       fontSize: 16,
//                                                       color: Colors.white,
//                                                     ),
//                                                   ),
//                                                 ),
//                                                 user.isConnected == false &&
//                                                         user.belongsToCompany ==
//                                                             false &&
//                                                         user.isIndividual ==
//                                                             false
//                                                     ? Container()
//                                                     : Checkbox(
//                                                         value: isSelected,
//                                                         activeColor:
//                                                             const Color(
//                                                                 0xFF90CAF9),
//                                                         onChanged: (value) =>
//                                                             toggleSelection(
//                                                                 value),
//                                                       )
//                                               ],
//                                             ),
//                                             const SizedBox(height: 8),
//                                             Align(
//                                               alignment: Alignment.centerLeft,
//                                               child: Container(
//                                                 padding:
//                                                     const EdgeInsets.symmetric(
//                                                         horizontal: 12,
//                                                         vertical: 6),
//                                                 decoration: BoxDecoration(
//                                                   border: Border.all(
//                                                       color: const Color(
//                                                           0xFF4FC3F7)),
//                                                   borderRadius:
//                                                       BorderRadius.circular(20),
//                                                 ),
//                                                 child: Text(
//                                                   user.isIndividual == false
//                                                       ? "Other Company"
//                                                       : "Individual",
//                                                   style: TextStyle(
//                                                     color: Color(0xFF4FC3F7),
//                                                     fontSize: 12,
//                                                     fontWeight: FontWeight.w500,
//                                                   ),
//                                                 ),
//                                               ),
//                                             ),
//                                             const SizedBox(height: 8),
//                                             if (user.isConnected == false &&
//                                                 user.belongsToCompany ==
//                                                     false &&
//                                                 user.isIndividual == false) ...[
//                                               const SizedBox(height: 12),
//
// // --- Connect Button ---
//                                               Consumer<SOVListProvider>(
//                                                 builder:
//                                                     (context, provider, _) {
//                                                   final isRequested = provider
//                                                       .requestedUserIds
//                                                       .contains(user.userid);
//
//                                                   return SizedBox(
//                                                     width: double.infinity,
//                                                     height: 44,
//                                                     child: OutlinedButton.icon(
//                                                       onPressed: isRequested
//                                                           ? null
//                                                           : () {
//                                                               _showRequestConnectionDialog(
//                                                                 context,
//                                                                 userId:
//                                                                     user.userid ??
//                                                                         "",
//                                                                 userName: user
//                                                                         .name ??
//                                                                     "Naveen",
//                                                                 userRole: user
//                                                                         .role ??
//                                                                     "Insurance Broker",
//                                                                 sovName:
//                                                                     "SOV Name",
//                                                               );
//                                                             },
//                                                       icon: Icon(
//                                                         isRequested
//                                                             ? Icons
//                                                                 .check_circle_outline
//                                                             : Icons
//                                                                 .person_add_alt_1,
//                                                         color: isRequested
//                                                             ? Colors.grey
//                                                             : const Color(
//                                                                 0xFF4FC3F7),
//                                                       ),
//                                                       label: Text(
//                                                         isRequested
//                                                             ? "Request Sent"
//                                                             : "Connect",
//                                                         style: TextStyle(
//                                                           color: isRequested
//                                                               ? Colors.grey
//                                                               : const Color(
//                                                                   0xFF4FC3F7),
//                                                           fontWeight:
//                                                               FontWeight.w600,
//                                                         ),
//                                                       ),
//                                                       style: OutlinedButton
//                                                           .styleFrom(
//                                                         side: BorderSide(
//                                                           color: isRequested
//                                                               ? Colors.grey
//                                                               : const Color(
//                                                                   0xFF4FC3F7),
//                                                         ),
//                                                         shape:
//                                                             RoundedRectangleBorder(
//                                                           borderRadius:
//                                                               BorderRadius
//                                                                   .circular(10),
//                                                         ),
//                                                       ),
//                                                     ),
//                                                   );
//                                                 },
//                                               ),
//                                             ] else ...[
//                                               // Role dropdown (enabled only if checkbox selected)
//                                               const SizedBox(height: 12),
//
//                                               IgnorePointer(
//                                                 ignoring: !isSelected,
//                                                 child: Opacity(
//                                                   opacity: isSelected ? 1 : 0.4,
//                                                   child: Builder(
//                                                     builder: (context) {
//                                                       final roles =
//                                                           user.roles ?? [];
//
//                                                       // 🔥 Reset when unchecked
//                                                       if (!isSelected) {
//                                                         _selectedRoles[index] =
//                                                             null;
//                                                       }
//
//                                                       // 🔥 CASE 1: Only ONE role → show STATIC field but full width
//                                                       if (isSelected &&
//                                                           roles.length == 1) {
//                                                         final roleName =
//                                                             roles.first.name ??
//                                                                 "";
//
//                                                         // Auto assign when checkbox selected
//                                                         _selectedRoles[index] =
//                                                             roleName;
//
//                                                         return Container(
//                                                           width:
//                                                               double.infinity,
//                                                           // ⬅ FULL WIDTH
//                                                           padding:
//                                                               const EdgeInsets
//                                                                   .symmetric(
//                                                                   horizontal:
//                                                                       12,
//                                                                   vertical: 14),
//                                                           decoration:
//                                                               BoxDecoration(
//                                                             border: Border.all(
//                                                                 color: Colors
//                                                                     .grey
//                                                                     .shade700),
//                                                             borderRadius:
//                                                                 BorderRadius
//                                                                     .circular(
//                                                                         8),
//                                                           ),
//                                                           child: Text(
//                                                             roleName,
//                                                             style:
//                                                                 const TextStyle(
//                                                                     color: Colors
//                                                                         .white),
//                                                           ),
//                                                         );
//                                                       }
//
//                                                       // 🔥 CASE 2: MULTIPLE roles → show dropdown with same width
//                                                       return Container(
//                                                         width: double.infinity,
//                                                         padding:
//                                                             const EdgeInsets
//                                                                 .symmetric(
//                                                                 horizontal: 12),
//                                                         decoration:
//                                                             BoxDecoration(
//                                                           border: Border.all(
//                                                               color: Colors.grey
//                                                                   .shade700),
//                                                           borderRadius:
//                                                               BorderRadius
//                                                                   .circular(8),
//                                                         ),
//                                                         child:
//                                                             DropdownButtonHideUnderline(
//                                                           child: DropdownButton<
//                                                               String>(
//                                                             value:
//                                                                 _selectedRoles[
//                                                                     index],
//                                                             hint: const Text(
//                                                               'Select Role',
//                                                               style: TextStyle(
//                                                                   color: Colors
//                                                                       .white70),
//                                                             ),
//                                                             dropdownColor:
//                                                                 const Color(
//                                                                     0xFF2C2C2C),
//                                                             icon: const Icon(
//                                                               Icons
//                                                                   .arrow_drop_down,
//                                                               color: Colors
//                                                                   .white70,
//                                                             ),
//                                                             isExpanded: true,
//                                                             items: roles
//                                                                 .map(
//                                                                   (role) =>
//                                                                       DropdownMenuItem<
//                                                                           String>(
//                                                                     value: role
//                                                                         .name,
//                                                                     child: Text(
//                                                                       role.name ??
//                                                                           '',
//                                                                       style: const TextStyle(
//                                                                           color:
//                                                                               Colors.white),
//                                                                     ),
//                                                                   ),
//                                                                 )
//                                                                 .toList(),
//                                                             onChanged:
//                                                                 isSelected
//                                                                     ? (value) {
//                                                                         setInnerState(
//                                                                             () {
//                                                                           _selectedRoles[index] =
//                                                                               value;
//                                                                           roleError =
//                                                                               null;
//                                                                         });
//
//                                                                         updateSelectedUsersJson();
//                                                                       }
//                                                                     : null,
//                                                           ),
//                                                         ),
//                                                       );
//                                                     },
//                                                   ),
//                                                 ),
//                                               ),
//
//                                               if (roleError != null)
//                                                 Padding(
//                                                   padding:
//                                                       const EdgeInsets.only(
//                                                           top: 4, left: 12),
//                                                   child: Text(
//                                                     roleError!,
//                                                     style: const TextStyle(
//                                                         color: Colors.redAccent,
//                                                         fontSize: 12),
//                                                   ),
//                                                 ),
//
//                                               const SizedBox(height: 12),
//                                               const Text("Set Deadline",
//                                                   style: TextStyle(
//                                                       fontSize: 13,
//                                                       color: Colors.grey)),
//                                               const SizedBox(height: 6),
//
//                                               // Deadline picker (enabled only if checkbox selected)
//                                               IgnorePointer(
//                                                 ignoring: !isSelected,
//                                                 child: Opacity(
//                                                   opacity: isSelected ? 1 : 0.4,
//                                                   child: InkWell(
//                                                     onTap: () async {
//                                                       if (!isSelected) return;
//
//                                                       final now =
//                                                           DateTime.now();
//
//                                                       final pickedDate =
//                                                           await showDatePicker(
//                                                         context: context,
//                                                         initialDate:
//                                                             _selectedDeadlines[
//                                                                     index] ??
//                                                                 now,
//                                                         firstDate: DateTime(
//                                                             now.year,
//                                                             now.month,
//                                                             now.day),
//                                                         lastDate:
//                                                             DateTime(2100),
//                                                       );
//
//                                                       if (pickedDate != null) {
//                                                         // 🔥 IMPORTANT: Remove time part completely
//                                                         final cleanDate =
//                                                             DateTime(
//                                                           pickedDate.year,
//                                                           pickedDate.month,
//                                                           pickedDate.day,
//                                                         );
//
//                                                         setState(() {
//                                                           _selectedDeadlines[
//                                                                   index] =
//                                                               cleanDate;
//                                                           deadlineError = null;
//                                                         });
//
//                                                         updateSelectedUsersJson();
//                                                       }
//                                                     },
//                                                     child: Container(
//                                                       padding: const EdgeInsets
//                                                           .symmetric(
//                                                           horizontal: 12,
//                                                           vertical: 12),
//                                                       decoration: BoxDecoration(
//                                                         border: Border.all(
//                                                             color: Colors
//                                                                 .grey.shade700),
//                                                         borderRadius:
//                                                             BorderRadius
//                                                                 .circular(8),
//                                                       ),
//                                                       child: Row(
//                                                         children: [
//                                                           Expanded(
//                                                             child: Text(
//                                                               _selectedDeadlines[
//                                                                           index] !=
//                                                                       null
//                                                                   ? DateFormat(
//                                                                           'MM/dd/yyyy')
//                                                                       .format(_selectedDeadlines[
//                                                                           index]!)
//                                                                   : "Select Date",
//                                                               style: const TextStyle(
//                                                                   color: Colors
//                                                                       .white70),
//                                                             ),
//                                                           ),
//                                                           const Icon(
//                                                             Icons
//                                                                 .calendar_today_outlined,
//                                                             color:
//                                                                 Colors.white70,
//                                                             size: 20,
//                                                           ),
//                                                         ],
//                                                       ),
//                                                     ),
//                                                   ),
//                                                 ),
//                                               ),
//
//                                               if (deadlineError != null)
//                                                 Padding(
//                                                   padding:
//                                                       const EdgeInsets.only(
//                                                           top: 4, left: 12),
//                                                   child: Text(
//                                                     deadlineError!,
//                                                     style: const TextStyle(
//                                                         color: Colors.redAccent,
//                                                         fontSize: 12),
//                                                   ),
//                                                 ),
//                                             ],
//                                           ],
//                                         ),
//                                       );
//                                     },
//                                   );
//                                 }),
//                               ),
//                             ),
//                           ),
//                         const SizedBox(height: 24),
//
//                         const Text(
//                           "Note: Users with multiple roles must be assigned one role per SOV.",
//                           style:
//                               TextStyle(fontSize: 14, color: Color(0xFF9FA6AD)),
//                         ),
//                         const SizedBox(height: 24),
//
//                         // --- Share Button ---
//                         Row(
//                           children: [
//                             Expanded(
//                               child: Consumer<SOVListProvider>(
//                                 builder: (context, sovListProvider, _) {
//                                   return CustomButton(
//                                     type: ButtonType.elevated,
//                                     onPressed: (!_isShareEnabled ||
//                                             sovListProvider.isLoading)
//                                         ? null
//                                         : () async {
//                                             List<Map<String, dynamic>>
//                                                 shareWithList = [];
//
//                                             for (int index
//                                                 in _selectedIndexes) {
//                                               final user =
//                                                   _autocompleteUsersList[index];
//                                               final roleName =
//                                                   _selectedRoles[index];
//                                               final deadline =
//                                                   _selectedDeadlines[index];
//
//                                               final selectedRole = user.roles
//                                                   ?.firstWhere((r) =>
//                                                       r.name == roleName);
//
//                                               shareWithList.add({
//                                                 "user_id": user.userid ?? '',
//                                                 // "role_id":
//                                                 "email": user.email ?? '',
//                                                 "role": {
//                                                   "role_id": user
//                                                       .lastSelectedRole!.role
//                                                       .toString(),
//                                                   "role_name":
//                                                       selectedRole?.name ?? '',
//                                                 },
//                                                 "share_expiry":
//                                                     DateFormat('yyyy-MM-dd')
//                                                         .format(deadline!),
//
//                                                 // "share_expiry":
//                                                 //     deadline!.toIso8601String(),
//                                               });
//                                             }
//                                             final Set<String> sovIdsToShare =
//                                                 sovs
//                                                     .where((s) =>
//                                                         s["sov_id"] != null)
//                                                     .map((s) =>
//                                                         s["sov_id"].toString())
//                                                     .toSet();
//                                             // final Set<String> sovIdsToShare =
//                                             //     sovs
//                                             //         .where(
//                                             //             (s) => s.sovId != null)
//                                             //         .map((s) => s.sovId!)
//                                             //         .toSet();
//
//                                             bool success =
//                                                 await sovListProvider.shareSov(
//                                               sovId: sovIdsToShare,
//                                               shareWithList: shareWithList,
//                                             );
//                                             // bool success =
//                                             //     await sovListProvider.shareSov(
//                                             //   sovId: selectedSovIds,
//                                             //   shareWithList: shareWithList,
//                                             // );
//
//                                             if (!mounted) return;
//
//                                             if (success) {
//                                               Navigator.pop(dialogContext);
//
//                                               setState(() {
//                                                 selectedList = List.filled(
//                                                     selectedList.length, false);
//                                                 isSelectionMode = false;
//                                               });
//
//                                               ScaffoldMessenger.of(context)
//                                                   .showSnackBar(
//                                                 const SnackBar(
//                                                   content: Text(
//                                                       "SOV shared successfully"),
//                                                 ),
//                                               );
//                                             } else {
//                                               ScaffoldMessenger.of(context)
//                                                   .showSnackBar(
//                                                 const SnackBar(
//                                                   content: Text(
//                                                       "Failed to share SOV."),
//                                                 ),
//                                               );
//                                             }
//                                           },
//                                     child: sovListProvider.isLoading
//                                         ? const CircularProgressIndicator(
//                                             color: Colors.white, strokeWidth: 2)
//                                         : const Text("Share SOV",
//                                             style:
//                                                 TextStyle(color: Colors.black)),
//                                   );
//                                 },
//                               ),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 16),
//
//                         Row(
//                           children: [
//                             Expanded(
//                               child: CustomButton(
//                                 type: ButtonType.outlined,
//                                 onPressed: () => Navigator.pop(context),
//                                 child: const Text("Cancel"),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             )
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
    // String url = "/v2/search_users?search=$query";
    String url = "/v2/search_users?search=${Uri.encodeComponent(query)}";
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
  final bool? status;

  const InfoCard({
    super.key,
    required this.title,
    required this.count,
    required this.icon,
    this.status,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      width: 130,
      child: Card(
        color: Colors.white12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
              color: status! ? AppColors.primaryMain : Colors.white38,
              width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 1, 8, 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                  SizedBox(width: CustomSpacing.three),
                  Text(
                    count.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: CustomSpacing.two),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 14,
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

void _showRequestConnectionDialog(
  BuildContext context, {
  required String userId,
  required String userName,
  required String userRole,
  required String sovName,
}) {
  final TextEditingController messageController = TextEditingController();

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return Dialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---- Title ----
                  const Text(
                    "Request Connection",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),

                  const Text(
                    "You need to be connected with this user to share SOV data.",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ---- User Card ----
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.grey.shade700,
                          child: Text(
                            userName.substring(0, 1).toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600),
                            ),
                            Text(
                              userRole,
                              style: const TextStyle(
                                  color: Colors.white60, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ---- Message Box ----
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade700),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: messageController,
                      maxLength: 500,
                      maxLines: 4,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        counterText: "",
                        border: InputBorder.none,
                        hintText:
                            'Add a note to your connection request (optional)',
                        hintStyle: const TextStyle(color: Colors.white54),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),

                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      "${messageController.text.length}/500",
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ---- Buttons ----
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF4FC3F7)),
                            foregroundColor: const Color(0xFF4FC3F7),
                          ),
                          child: const Text("Cancel"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Consumer<SOVListProvider>(
                          builder: (dialogContext, provider, _) {
                            return ElevatedButton(
                              onPressed: provider.isConnectRequestLoading
                                  ? null
                                  : () async {
                                      final text =
                                          messageController.text.trim();

                                      // if (text.isEmpty) {
                                      //   setState(() {
                                      //     messageError = "Message is required";
                                      //   });
                                      //   return;
                                      // }
                                      //
                                      // setState(() {
                                      //   messageError = null;
                                      // });

                                      print("🔥 BUTTON CLICKED"); // DEBUG

                                      final success =
                                          await provider.sendConnectionRequest(
                                        dialogContext,
                                        userId: userId,
                                        message: text,
                                      );

                                      if (success) {
                                        Navigator.pop(dialogContext);

                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content:
                                                Text("Connection request sent"),
                                          ),
                                        );
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF90CAF9),
                                foregroundColor: Colors.black,
                              ),
                              child: provider.isConnectRequestLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.black,
                                      ),
                                    )
                                  : const Text("Connect"),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      );
    },
  );
}
