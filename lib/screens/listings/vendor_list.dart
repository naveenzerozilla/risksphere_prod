import 'package:RiskSphere/screens/listings/widgets/vertical_bar_indicator.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../design_system/repo/constants.dart';
import '../../models/my_location_list_model.dart';
import '../../utils/global_imports.dart';
import '../../models/sov_list_model.dart';
import 'package:RiskSphere/models/role_model.dart' as roleModel;
import 'package:http/http.dart' as http;

import '../payments/purchase_license.dart';
import 'export_dialogsov.dart';

class VendorList extends StatefulWidget {
  final String? status;
  final String? accountID;
  final String? subAccountID;
  final String accountName;
  final String subAccountName;
  final String? initialProcessId;
  final String? initialSubProcessId;

  const VendorList({
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
  State<VendorList> createState() => _VendorListState();
}

class _VendorListState extends State<VendorList> with TickerProviderStateMixin {
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

  bool isHasAnyPlan = false;
  Screens _selectedScreen = Screens.locationList;
  TextEditingController _sovNameEditNameController = TextEditingController();
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

// State fields
  final _processIndex$ = BehaviorSubject<int>.seeded(0);

  @override
  void initState() {
    super.initState();

    final provider = context.read<SOVListProvider>();

    provider.page = 1;
    provider.totalPages = 1;
    _setClaims();
    provider.fetchvendorList(
      context,
      _sovQuery,
      1,
      5,
      widget.status,
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

    if (mounted) setState(() {});
  }

  String? _activeAccountKey; // track which account/subaccount timer belongs to

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
        1, // Always start from page 1 for new searches
        5,
        widget.status ?? "my",
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

      return sovListProvider.isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : (trialStatus.contains('Expired') && isHasAnyPlan == false)
              ? Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surface.withOpacity(0.95),
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
                                  'We hope you\'ve enjoyed your trial period! To continue accessing your account and keep your data safe, please upgrade before December 31, 2025. After this date, we will need to delete your data. Thank you for being with us!',
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
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Back icon
                        // Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),

                        const SizedBox(width: 10),

                        // Title
                        const Text(
                          'Credit Usage',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        //
                        // const SizedBox(width: 12),

                        // Push right content to end
                        // Expanded(
                        //   child: Column(
                        //     mainAxisAlignment: MainAxisAlignment.end,
                        //     children: [
                        //       Text(
                        //         '12,480 Credits Remaining',
                        //         style: TextStyle(
                        //           color: Colors.white,
                        //           fontSize: 12,
                        //         ),
                        //       ),
                        //
                        //       // const SizedBox(width: 10),
                        //
                        //       // Progress bar
                        //       SizedBox(
                        //         width: 140,
                        //         height: 8,
                        //         child: ClipRRect(
                        //           borderRadius: BorderRadius.circular(4),
                        //           child: LinearProgressIndicator(
                        //             value: 0.65, // progress value
                        //             backgroundColor: Colors.grey.shade700,
                        //             valueColor: const AlwaysStoppedAnimation<Color>(
                        //                 AppColors.primaryMain),
                        //           ),
                        //         ),
                        //       ),
                        //     ],
                        //   ),
                        // ),
                        //
                        // // Info icon
                        // const Icon(
                        //   Icons.info_outline,
                        //   color: AppColors.primaryMain,
                        //   size: 18,
                        // ),
                      ],
                    ),

                    SizedBox(height: CustomSpacing.two),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Consumer<SOVListProvider>(
                          builder: (context, sovListProvider, _) {
                        return Row(
                          children: [
                            InfoCard(
                              title: "Total APIs Used",
                              count: sovListProvider.cardlist!.totalApisUsed
                                      .toString() ??
                                  "",
                              icon: Icons.checklist,
                              growthText: "increase vs last month",
                            ),
                            InfoCard(
                              title: "Total Cost Incurred",
                              count: sovListProvider.cardlist!.totalApiCost
                                      .toString() ??
                                  "",
                              icon: Icons.attach_money,
                              growthText: "increase vs last month",
                            ),
                            InfoCard(
                              title: "Average Cost per API",
                              count: sovListProvider.cardlist!.avgCostPerApi
                                      .toString() ??
                                  "",
                              icon: Icons.attach_money,
                              growthText: "increase vs last month",
                            ),
                            InfoCard(
                              title: "Active Users",
                              count: sovListProvider.cardlist!.activeVendors
                                      .toString() ??
                                  "",
                              icon: Icons.attach_money,
                              growthText: "increase vs last month",
                            ),
                          ],
                        );
                      }),
                    ),

                    usageDetailsHeader(),
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

                          return RefreshIndicator(
                            onRefresh: () async {
                              sovListProvider.page = 1;
                              await sovListProvider.fetchvendorList(
                                context,
                                // sovListProvider.sovList.first.accountId!,
                                // sovListProvider.sovList.first.subAccountId!,
                                _sovQuery,
                                1,
                                7,
                                widget.status,
                              );
                            },
                            child: ListView.builder(
                              controller: _scrollController1,
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: sovListProvider
                                  .filteredAutoCompleteList1.length,
                              itemBuilder: (context, index) {
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

  Widget _buildSovCard(int index, SOVListProvider provider) {
    final vendorData = provider.filteredAutoCompleteList1[index];
    return Card(
      color: const Color(0xFFFFFFFF).withOpacity(0.12),
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade800, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 52,
                    width: 52,
                    color: Colors.grey.shade800,
                    child:
                        const Icon(Icons.location_city, color: Colors.white70),
                  ),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vendorData.companyName.toString(),
                        style: const TextStyle(
                          color: Color(0xFF90CAF9),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        vendorData.vendorName ?? "",
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                /// Date
                Text(
                  vendorData.date.toString(),
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _infoRow("User", vendorData?.name ?? "N/A"),
            _infoRow("Role", "Admin" ?? "—"),
            _infoRow("Vendor", vendorData.vendorName.toString() ?? "—"),
            const SizedBox(height: 8),
            Divider(color: Colors.white.withOpacity(0.2)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _metricBlock(
                  title: "API Accessed",
                  value: vendorData.apisUsed.toString(),
                ),
                _metricBlock(
                  title: "Total Cost",
                  value: vendorData.totalCost.toString(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: "$label : ",
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 12,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget usageDetailsHeader() {
    return Row(
      children: [
        /// Title
        const Text(
          "Usage Details",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),

        const Spacer(),

        /// Filter icon
        IconButton(
          onPressed: () {
            // filter action
          },
          icon: const Icon(
            Icons.filter_list_alt,
            color: Color(0xFF90CAF9),
            size: 20,
          ),
          splashRadius: 20,
        ),

        /// Share icon
        IconButton(
          onPressed: () {
            // share action
          },
          icon: const Icon(
            Icons.download_rounded,
            color: Colors.white70,
            size: 20,
          ),
          splashRadius: 20,
        ),
      ],
    );
  }

  Widget _metricBlock({required String title, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // Widget _buildSovCard(int index, SOVListProvider sOVListProvider) {
  //   var typography = CustomTypography(context);
  //
  //   final sov = sOVListProvider.sovList[index];
  //   final sovId = sov.sovId ?? "";
  //
  //   final meta = sOVListProvider.sovMeta[sovId];
  //   final isRefreshPending = meta?['refresh_pending'] == true;
  //   final sharedUsersWithEmail = sov.sharingStatus?.users.values
  //           .where((u) => u.email != null && u.email!.trim().isNotEmpty)
  //           .toList() ??
  //       [];
  //   return Opacity(
  //     opacity: isRefreshPending ? 0.5 : 1.0, // Fade UI
  //     child: IgnorePointer(
  //       ignoring: isRefreshPending, // Disable touch
  //       child: Container(
  //         margin: EdgeInsets.only(top: 0.0, bottom: 8),
  //         child: InkWell(
  //           borderRadius: BorderRadius.circular(8),
  //           onTap: () {
  //             setState(() {
  //               if (isSelectionMode) {
  //                 selectedList[index] = !selectedList[index];
  //                 if (!selectedList.contains(true)) {
  //                   isSelectionMode = false;
  //                 }
  //
  //                 selectedSovIds = sOVListProvider.sovList
  //                     .asMap()
  //                     .entries
  //                     .where((entry) => selectedList[entry.key])
  //                     .map((entry) => entry.value.sovId)
  //                     .whereType<String>()
  //                     .toSet();
  //               } else {
  //                 Navigator.push(context, MaterialPageRoute(builder: (context) {
  //                   return SovLocationList(
  //                     accountID: sov.accountId,
  //                     subAccountID: sov.subAccountId,
  //                     accountName: "",
  //                     subAccountName: "",
  //                     sovID: sov.sovId ?? "",
  //                     sovName: sov.name ?? "",
  //                   );
  //                 }));
  //                 _isDisposed = true;
  //                 _refreshTimer?.cancel();
  //                 deBouncer?.cancel();
  //               }
  //             });
  //           },
  //           onLongPress: () {
  //             setState(() {
  //               if (selectedList.length != sOVListProvider.sovList.length) {
  //                 selectedList = List.generate(
  //                   sOVListProvider.sovList.length,
  //                   (_) => false,
  //                 );
  //               }
  //
  //               if (isSelectionMode) {
  //                 selectedList[index] = !selectedList[index];
  //                 if (!selectedList.contains(true)) {
  //                   isSelectionMode = false;
  //                 }
  //               } else {
  //                 selectedList[index] = true;
  //                 isSelectionMode = true;
  //               }
  //
  //               selectedSovIds = sOVListProvider.sovList
  //                   .asMap()
  //                   .entries
  //                   .where((entry) => selectedList[entry.key])
  //                   .map((entry) => entry.value.sovId)
  //                   .whereType<String>()
  //                   .toSet();
  //             });
  //           },
  //           child: Stack(
  //             children: [
  //               Row(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   Expanded(
  //                     child: Column(
  //                       mainAxisAlignment: MainAxisAlignment.start,
  //                       crossAxisAlignment: CrossAxisAlignment.start,
  //                       children: [
  //                         SizedBox(
  //                           height: 230,
  //                           width: MediaQuery.of(context).size.width,
  //                           child: Card(
  //                             color: Colors.white12,
  //                             margin: EdgeInsets.zero,
  //                             shape: RoundedRectangleBorder(
  //                               borderRadius: BorderRadius.circular(8),
  //                             ),
  //                             child: Column(
  //                               crossAxisAlignment: CrossAxisAlignment.start,
  //                               children: [
  //                                 Row(
  //                                   crossAxisAlignment:
  //                                       CrossAxisAlignment.start,
  //                                   children: [
  //                                     SizedBox(width: CustomSpacing.two),
  //                                     Expanded(
  //                                       child: Column(
  //                                         crossAxisAlignment:
  //                                             CrossAxisAlignment.start,
  //                                         children: [
  //                                           Row(
  //                                             mainAxisAlignment:
  //                                                 MainAxisAlignment
  //                                                     .spaceBetween,
  //                                             children: [
  //                                               Expanded(
  //                                                 child: Row(
  //                                                   children: [
  //                                                     if (isSelectionMode)
  //                                                       Checkbox(
  //                                                         value: (index <
  //                                                                 selectedList
  //                                                                     .length)
  //                                                             ? selectedList[
  //                                                                 index]
  //                                                             : false,
  //                                                         onChanged: (value) {
  //                                                           setState(() {
  //                                                             if (selectedList
  //                                                                     .length !=
  //                                                                 sOVListProvider
  //                                                                     .sovList
  //                                                                     .length) {
  //                                                               selectedList =
  //                                                                   List.generate(
  //                                                                 sOVListProvider
  //                                                                     .sovList
  //                                                                     .length,
  //                                                                 (_) => false,
  //                                                               );
  //                                                             }
  //                                                             selectedList[
  //                                                                     index] =
  //                                                                 value ??
  //                                                                     false;
  //
  //                                                             if (!selectedList
  //                                                                 .contains(
  //                                                                     true)) {
  //                                                               isSelectionMode =
  //                                                                   false;
  //                                                             }
  //                                                           });
  //                                                         },
  //                                                       ),
  //                                                     Chip(
  //                                                       label: Text(
  //                                                         sov.status ??
  //                                                             "Pending",
  //                                                         style: typography
  //                                                             .Body2.copyWith(
  //                                                           color: sov.status ==
  //                                                                   "completed"
  //                                                               ? Colors.white
  //                                                               : Color(
  //                                                                   0xFFFFA726),
  //                                                           fontWeight:
  //                                                               FontWeight.w500,
  //                                                         ),
  //                                                       ),
  //                                                       backgroundColor: sov
  //                                                                   .status ==
  //                                                               "completed"
  //                                                           ? Colors.green
  //                                                           : Color(0xFFFFA726)
  //                                                               .withOpacity(
  //                                                                   0.2),
  //                                                     ),
  //                                                     IconButton(
  //                                                       icon: const Icon(Icons
  //                                                           .file_copy_rounded),
  //                                                       color: AppColors
  //                                                           .primaryMain,
  //                                                       onPressed: () {
  //                                                         // Show duplicate dialog
  //                                                         showDialog(
  //                                                           context: context,
  //                                                           barrierDismissible:
  //                                                               false,
  //                                                           builder: (context) {
  //                                                             return AlertDialog(
  //                                                               title: Text(
  //                                                                 LanguageService
  //                                                                     .getTranslated(
  //                                                                         context,
  //                                                                         "duplicate_sov_account"),
  //                                                                 style: typography
  //                                                                     .H5_Regular,
  //                                                               ),
  //                                                               content: Column(
  //                                                                 mainAxisSize:
  //                                                                     MainAxisSize
  //                                                                         .min,
  //                                                                 children: [
  //                                                                   Text(
  //                                                                     LanguageService.getTranslated(
  //                                                                         context,
  //                                                                         "sov_list_app_duplicate_text"),
  //                                                                     style: typography
  //                                                                         .Body1,
  //                                                                   ),
  //                                                                   SizedBox(
  //                                                                     height:
  //                                                                         CustomSpacing
  //                                                                             .two,
  //                                                                   ),
  //                                                                   Row(
  //                                                                     children: [
  //                                                                       Expanded(
  //                                                                         child:
  //                                                                             CustomButton(
  //                                                                           onPressed:
  //                                                                               () {
  //                                                                             // Cancel
  //                                                                             Navigator.pop(context);
  //                                                                           },
  //                                                                           child:
  //                                                                               Text(
  //                                                                             LanguageService.getTranslated(context, "cancel"),
  //                                                                             style: typography.ButtonLarge,
  //                                                                           ),
  //                                                                           type:
  //                                                                               ButtonType.text,
  //                                                                         ),
  //                                                                       ),
  //                                                                       Expanded(
  //                                                                         child:
  //                                                                             Consumer<SOVListProvider>(
  //                                                                           builder: (context,
  //                                                                               provider,
  //                                                                               child) {
  //                                                                             if (provider.isDuplicateLoading) {
  //                                                                               return Center(
  //                                                                                 child: SizedBox(
  //                                                                                   height: 28,
  //                                                                                   width: 28,
  //                                                                                   child: CircularProgressIndicator(strokeWidth: 2),
  //                                                                                 ),
  //                                                                               );
  //                                                                             }
  //
  //                                                                             return CustomButton(
  //                                                                               onPressed: () async {
  //                                                                                 provider.isDuplicateLoading = true;
  //                                                                                 provider.notifyListeners();
  //
  //                                                                                 try {
  //                                                                                   // 1️⃣ Duplicate Sub Account
  //                                                                                   await provider.duplicateSov(
  //                                                                                     context,
  //                                                                                     sov.sovId!,
  //                                                                                   );
  //
  //                                                                                   final sovProvider = Provider.of<SOVListProvider>(context, listen: false);
  //                                                                                   Navigator.pop(context);
  //                                                                                   await sovProvider.fetchSovList(
  //                                                                                     context,
  //                                                                                     "",
  //                                                                                     1,
  //                                                                                     5,
  //                                                                                     widget.status,
  //                                                                                   );
  //                                                                                   sOVListProvider.notifyListeners();
  //
  //                                                                                   /// STOP LOADER
  //                                                                                   // accountListProvider.isRenameLoading = false;
  //                                                                                   // accountListProvider.notifyListeners();
  //                                                                                 } finally {
  //                                                                                   provider.isDuplicateLoading = false;
  //                                                                                   provider.notifyListeners();
  //                                                                                 }
  //                                                                               },
  //                                                                               child: Text(
  //                                                                                 LanguageService.getTranslated(
  //                                                                                   context,
  //                                                                                   "duplicate",
  //                                                                                 ),
  //                                                                               ),
  //                                                                               type: ButtonType.elevated,
  //                                                                             );
  //                                                                           },
  //                                                                         ),
  //                                                                       )
  //                                                                     ],
  //                                                                   ),
  //                                                                 ],
  //                                                               ),
  //                                                             );
  //                                                           },
  //                                                         );
  //                                                       },
  //                                                       tooltip: LanguageService
  //                                                           .getTranslated(
  //                                                               context,
  //                                                               "sub_account_list_app_duplicate_tooltip_text"),
  //                                                     ),
  //                                                   ],
  //                                                 ),
  //                                               ),
  //                                               _buildMoreMenu(index),
  //                                             ],
  //                                           ),
  //                                           SizedBox(height: 4),
  //                                           Row(
  //                                             crossAxisAlignment:
  //                                                 CrossAxisAlignment.center,
  //                                             children: [
  //                                               /// LEFT
  //                                               Expanded(
  //                                                 child: Row(
  //                                                   children: [
  //                                                     Flexible(
  //                                                       child: Text(
  //                                                         sov.name ?? "",
  //                                                         style: typography
  //                                                             .Body2.copyWith(
  //                                                           fontSize: 20,
  //                                                           fontWeight:
  //                                                               FontWeight.w400,
  //                                                           color: const Color(
  //                                                               0xFF90CAF9),
  //                                                         ),
  //                                                         overflow: TextOverflow
  //                                                             .ellipsis,
  //                                                       ),
  //                                                     ),
  //                                                     const SizedBox(width: 6),
  //                                                     InkWell(
  //                                                       onTap: () =>
  //                                                           _showRenameDialog(
  //                                                               index, sov),
  //                                                       child: const Icon(
  //                                                         Icons.edit,
  //                                                         size: 16,
  //                                                         color: Colors.white70,
  //                                                       ),
  //                                                     ),
  //                                                   ],
  //                                                 ),
  //                                               ),
  //
  //                                               /// RIGHT
  //                                               widget.status
  //                                                           .toString()
  //                                                           .toLowerCase() ==
  //                                                       "shared"
  //                                                   ? InkWell(
  //                                                       onTap: () =>
  //                                                           _showSharedWithDialog(
  //                                                               context,
  //                                                               sov.sharingStatus),
  //                                                       child: Container(
  //                                                         padding:
  //                                                             const EdgeInsets
  //                                                                 .symmetric(
  //                                                                 horizontal: 5,
  //                                                                 vertical: 6),
  //                                                         decoration:
  //                                                             BoxDecoration(
  //                                                           color: const Color(
  //                                                               0xFF2A2A2A),
  //                                                           borderRadius:
  //                                                               BorderRadius
  //                                                                   .circular(
  //                                                                       8),
  //                                                           border: Border.all(
  //                                                               color: const Color(
  //                                                                   0xFF3A3A3A)),
  //                                                         ),
  //                                                         child: Row(
  //                                                           mainAxisSize:
  //                                                               MainAxisSize
  //                                                                   .min,
  //                                                           children: [
  //                                                             const Icon(
  //                                                               Icons.mail,
  //                                                               size: 16,
  //                                                               color: Colors
  //                                                                   .white,
  //                                                             ),
  //                                                             const SizedBox(
  //                                                                 width: 4),
  //                                                             Text(
  //                                                               "${sov.sharingStatus!.users.values.toList().length ?? 0}",
  //                                                               style: typography
  //                                                                       .Body2
  //                                                                   .copyWith(
  //                                                                 color: Colors
  //                                                                     .white,
  //                                                                 fontWeight:
  //                                                                     FontWeight
  //                                                                         .w500,
  //                                                               ),
  //                                                             ),
  //                                                           ],
  //                                                         ),
  //                                                       ),
  //                                                     )
  //                                                   : Container(),
  //                                               SizedBox(width: 4),
  //                                             ],
  //                                           ),
  //                                           SizedBox(height: 4),
  //                                           Row(
  //                                             children: [
  //                                               CircleAvatar(
  //                                                 radius: 16,
  //                                                 backgroundColor:
  //                                                     Colors.grey[800],
  //                                                 child: Text(
  //                                                   sov.owner?.name
  //                                                           ?.substring(0, 2)
  //                                                           .toUpperCase() ??
  //                                                       "?",
  //                                                   style: TextStyle(
  //                                                       color: Colors.white),
  //                                                 ),
  //                                               ),
  //                                               SizedBox(width: 10),
  //                                               Expanded(
  //                                                 child: Text(
  //                                                   sov.owner?.name ??
  //                                                       "Unknown",
  //                                                   style: TextStyle(
  //                                                     fontWeight:
  //                                                         FontWeight.bold,
  //                                                     fontSize: 16,
  //                                                     color: Colors.white,
  //                                                   ),
  //                                                   overflow:
  //                                                       TextOverflow.ellipsis,
  //                                                 ),
  //                                               ),
  //                                               SizedBox(width: 10),
  //                                               Container(
  //                                                 padding: const EdgeInsets
  //                                                     .symmetric(
  //                                                     horizontal: 5,
  //                                                     vertical: 6),
  //                                                 decoration: BoxDecoration(
  //                                                   color:
  //                                                       const Color(0xFF2A2A2A),
  //                                                   borderRadius:
  //                                                       BorderRadius.circular(
  //                                                           8),
  //                                                   border: Border.all(
  //                                                       color: const Color(
  //                                                           0xFF3A3A3A)),
  //                                                 ),
  //                                                 child: Row(
  //                                                   mainAxisSize:
  //                                                       MainAxisSize.min,
  //                                                   children: [
  //                                                     const Icon(
  //                                                         Icons.location_on,
  //                                                         size: 18,
  //                                                         color: Colors.white),
  //                                                     const SizedBox(width: 2),
  //                                                     Text(
  //                                                       "${sov.locationCount ?? 0}",
  //                                                       style: typography.Body2
  //                                                           .copyWith(
  //                                                         color: Colors.white,
  //                                                         fontWeight:
  //                                                             FontWeight.w500,
  //                                                       ),
  //                                                     ),
  //                                                   ],
  //                                                 ),
  //                                               ),
  //                                               SizedBox(width: 4),
  //                                             ],
  //                                           ),
  //                                           SizedBox(height: 8),
  //                                           if ((sov.companyName ?? "")
  //                                               .isNotEmpty)
  //                                             Text(
  //                                               "Company: ${sov.companyName}",
  //                                               style:
  //                                                   typography.Body2.copyWith(
  //                                                 color: Colors.white,
  //                                                 fontSize: 14,
  //                                                 fontWeight: FontWeight.w500,
  //                                               ),
  //                                             ),
  //                                           SizedBox(height: 8),
  //                                           _buildScrollableScores(
  //                                             context,
  //                                             sov.geocodeAvg.toString(),
  //                                             sov.overallAvg.toString(),
  //                                             sov.dataCompleteness.toString(),
  //                                           ),
  //                                         ],
  //                                       ),
  //                                     ),
  //                                   ],
  //                                 ),
  //                               ],
  //                             ),
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //               if (isRefreshPending)
  //                 Positioned(
  //                   top: 10,
  //                   right: 10,
  //                   child: SizedBox(
  //                     height: 22,
  //                     width: 22,
  //                     child: CircularProgressIndicator(
  //                       strokeWidth: 2,
  //                       color: Colors.blue,
  //                     ),
  //                   ),
  //                 ),
  //             ],
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Widget _buildMoreMenu(int index) {
    return Consumer2<SubAccountListProvider, SOVListProvider>(
      builder: (context, subAccountListProvider, sovProvider, child) {
        return PopupMenuButton<String>(
          color: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: (value) async {
            if (value == 'delete') {
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
                        title: Text(
                          LanguageService.getTranslated(
                              context, "confirm_deletion"),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        content: Text(
                          LanguageService.getTranslated(
                              context, "confirm_delete_sov_message"),
                          style: TextStyle(color: Colors.white70),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              LanguageService.getTranslated(context, "cancel"),
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              setState(() => loading = true);

                              bool isSuccess = false;

                              try {
                                isSuccess = await subAccountListProvider
                                    .deleteSOVAccount(
                                  context,
                                  sovProvider.sovList[index].accountId!,
                                  sovProvider.sovList[index].subAccountId!,
                                  sovProvider.sovList[index].sovId!,
                                );
                              } catch (e) {
                                debugPrint("Error deleting SOV: $e");
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        "Failed to delete SOV. Please try again."),
                                  ),
                                );
                              }

                              if (isSuccess) {
                                Navigator.pop(context);

                                await sovProvider.fetchSovList(
                                  context,
                                  "",
                                  1,
                                  5,
                                  widget.status,
                                );

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("SOV deleted successfully."),
                                  ),
                                );
                              }

                              setState(() => loading = false);
                            },
                            child: loading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.red,
                                    ),
                                  )
                                : Text(
                                    LanguageService.getTranslated(
                                        context, "delete"),
                                    style: TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 16,
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
          itemBuilder: (context) => [
            PopupMenuItem<String>(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.redAccent),
                  SizedBox(width: 8),
                  Text(
                    LanguageService.getTranslated(context, "delete"),
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
                                    context,
                                    "",
                                    1,
                                    5,
                                    widget.status,
                                  );

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
          // if (MediaQuery.of(context).size.width > 400) SizedBox(width: 10),
          SizedBox(width: 10),
          InkWell(
            onTap: () {},
            child: _buildScoreCard(
              context,
              LanguageService.getTranslated(context, "hazard_score"),
              int.tryParse(riskScore) ?? 1,
            ),
          ),
          // if (MediaQuery.of(context).size.width > 400)
          SizedBox(width: 10),
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
                    DropdownButtonFormField2<SignUpOptions>(
                      value: _selectedOption,
                      isExpanded: true,
                      // avoids overflow
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 5,
                        ),
                      ),
                      hint: const Text("Select Account Type"),
                      items: const [
                        DropdownMenuItem(
                          value: SignUpOptions.corporate,
                          child: Text("Corporate"),
                        ),
                        DropdownMenuItem(
                          value: SignUpOptions.individual,
                          child: Text("Individual"),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedOption = value!);
                      },

                      // Dropdown styling
                      dropdownStyleData: DropdownStyleData(
                        maxHeight: 121,
                        decoration: BoxDecoration(
                          color: Color(0xFF1E1E1E), // your dropdownColor
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),

                      // Menu item padding
                      menuItemStyleData: const MenuItemStyleData(
                        padding:
                            EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                      ),

                      // Button style (main field)
                      buttonStyleData: const ButtonStyleData(
                        height: 40,
                        padding: EdgeInsets.zero,
                      ),
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
                                        // Role dropdown (enabled only if checkbox selected)
                                        const SizedBox(height: 12),

                                        IgnorePointer(
                                          ignoring: !isSelected,
                                          child: Opacity(
                                            opacity: isSelected ? 1 : 0.4,
                                            child: Builder(
                                              builder: (context) {
                                                final roles = user.roles ?? [];

                                                // 🔥 Reset when unchecked
                                                if (!isSelected) {
                                                  _selectedRoles[index] = null;
                                                }

                                                // 🔥 CASE 1: Only ONE role → show STATIC field but full width
                                                if (isSelected &&
                                                    roles.length == 1) {
                                                  final roleName =
                                                      roles.first.name ?? "";

                                                  // Auto assign when checkbox selected
                                                  _selectedRoles[index] =
                                                      roleName;

                                                  return Container(
                                                    width: double.infinity,
                                                    // ⬅ FULL WIDTH
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 12,
                                                        vertical: 14),
                                                    decoration: BoxDecoration(
                                                      border: Border.all(
                                                          color: Colors
                                                              .grey.shade700),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                    ),
                                                    child: Text(
                                                      roleName,
                                                      style: const TextStyle(
                                                          color: Colors.white),
                                                    ),
                                                  );
                                                }

                                                // 🔥 CASE 2: MULTIPLE roles → show dropdown with same width
                                                return Container(
                                                  width: double.infinity,
                                                  // ⬅ FULL WIDTH
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 12),
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                        color: Colors
                                                            .grey.shade700),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child:
                                                      DropdownButtonHideUnderline(
                                                    child:
                                                        DropdownButton<String>(
                                                      value: isSelected
                                                          ? _selectedRoles[
                                                              index]
                                                          : null,
                                                      hint: const Text(
                                                        'Select Role',
                                                        style: TextStyle(
                                                            color:
                                                                Colors.white70),
                                                      ),
                                                      dropdownColor:
                                                          const Color(
                                                              0xFF2C2C2C),
                                                      icon: const Icon(
                                                          Icons.arrow_drop_down,
                                                          color:
                                                              Colors.white70),
                                                      isExpanded: true,
                                                      items: roles
                                                          .map(
                                                            (role) =>
                                                                DropdownMenuItem<
                                                                    String>(
                                                              value: role.name,
                                                              child: Text(
                                                                role.name ?? '',
                                                                style: const TextStyle(
                                                                    color: Colors
                                                                        .white),
                                                              ),
                                                            ),
                                                          )
                                                          .toList(),
                                                      onChanged: (value) {
                                                        if (!isSelected) return;

                                                        setInnerState(() {
                                                          _selectedRoles[
                                                              index] = value;
                                                          roleError = null;
                                                        });

                                                        updateSelectedUsersJson();
                                                      },
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

String formatCount(String value, {bool isCurrency = false}) {
  final number = double.tryParse(value.replaceAll(',', '')) ?? 0;
  final formatter = NumberFormat('#,##0');
  return isCurrency
      ? '\$ ${formatter.format(number)}'
      : formatter.format(number);
}

class InfoCard extends StatelessWidget {
  final String title;
  final String count;
  final IconData icon;
  final String growthText; // eg: "12.4% increase vs last month"

  const InfoCard({
    super.key,
    required this.title,
    required this.count,
    required this.icon,
    required this.growthText,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Card(
        color: const Color(0xFFFFFFFF).withOpacity(0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            width: 2,
            color: Colors.white.withOpacity(0.11),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Icon
              const SizedBox(height: 12),
              Container(
                margin: EdgeInsets.only(left: 16),
                // padding: const EdgeInsets.only(right: 16,left: 16),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: Colors.white70,
                ),
              ),

              const SizedBox(height: 12),

              /// Title
              Container(
                padding: const EdgeInsets.only(right: 16, left: 16),
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(height: 5),

              /// Count
              Container(
                padding: const EdgeInsets.only(right: 16, left: 16),
                child: Text(
                  formatCount(
                    count,
                    isCurrency: title == "Total Cost Incurred" ||
                        title == "Average Cost per API",
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),


              const SizedBox(height: 4),
              Divider(color: Colors.white.withOpacity(0.08)),
              const SizedBox(height: 2),

              /// Growth Info
              /// Growth Info
              Container(
                padding: const EdgeInsets.only(right: 16, left: 16, bottom: 2),
                child: Row(
                  children: [
                    const Icon(
                      Icons.trending_up,
                      size: 18,
                      color: Color(0xFF4CAF50),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '12.4% ',
                              style: const TextStyle(
                                color: Color(0xFF4CAF50),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(
                              text: growthText,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }
}

void _showSharedWithDialog(
  BuildContext context,
  SharingStatus? sharingStatus,
) {
  final users = sharingStatus?.users.values.toList() ?? [];

  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) {
      return Dialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🔹 Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  "Shared With",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),

              const Divider(color: Color(0xFF2C2C2C), height: 1),

              /// 🔹 Email List
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const Divider(
                    color: Color(0xFF2C2C2C),
                    height: 1,
                  ),
                  itemBuilder: (_, index) {
                    final user = users[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: Text(
                        user.email ?? "-",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                            ),
                      ),
                    );
                  },
                ),
              ),

              const Divider(color: Color(0xFF2C2C2C), height: 1),

              /// 🔹 Footer
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFF90CAF9),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Text(
                      "Close",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
