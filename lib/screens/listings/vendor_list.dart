import 'package:RiskSphere/screens/listings/widgets/vertical_bar_indicator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../design_system/repo/constants.dart';
import '../../models/my_location_list_model.dart';
import '../../utils/global_imports.dart';
import '../../models/sov_list_model.dart';
import 'package:RiskSphere/models/role_model.dart' as roleModel;

import '../payments/purchase_license.dart';

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
  String selectedVendor = '';
  List<Results> _dedupedVendors = [];
  String? trialMap;
  bool isFilterApplied = false; // 🔥 controls filter icon highlight
  List<Result> allVendorList = [];
  List<Result> filteredAutoCompleteList1 = [];

// Defaults (single source of truth)
  static const String _defaultDateView = 'yearly';
  static const String _defaultSort = 'all';

  String locationQuery = '';
  String dateView = 'yearly'; // ✅ DECLARE HERE
  String corporateSort = 'asc'; // asc | desc
  String userSort = 'asc';
  bool isHasAnyPlan = false;
  List<String> vendorList = [];
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
  int? selectedVendorIndex; // null = All

// State fields
  final _processIndex$ = BehaviorSubject<int>.seeded(0);

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<SOVListProvider>();

      provider.page = 1;
      provider.totalPages = 1;

      provider.fetchvendorList(
        context,
        _sovQuery,
        1,
        5,
        widget.status,
      );
    });

    _setClaims();
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

    trialMap = await SharedPreferenceService.getTrialPeriodStartRaw();
    if (mounted) setState(() {});
  }

  String? _activeAccountKey; // track which account/subaccount timer belongs to

  String selectedSov = 'my';

  String buildQuery() {
    final params = <String>[];

    // REQUIRED (always)
    params.add('page=1');
    params.add('pageSize=10');

    // REQUIRED (send even if empty)
    params.add('search=${locationQuery.trim()}');

    // Vendor (send only if selected)
    if (selectedVendorIndex != null &&
        selectedVendorIndex! < _dedupedVendors.length) {
      final vendorName =
          _dedupedVendors[selectedVendorIndex!].vendorName?.trim();

      if (vendorName != null && vendorName.isNotEmpty) {
        params.add('vendor=$vendorName');
      }
    }

    // REQUIRED
    params.add('dateMode=$dateView');

    // 🔥 MUST MATCH WEB
    params.add('corporateSort=all');
    params.add('usersSort=all');

    return '?${params.join('&')}';
  }

  void _applyFilters() async {
    Navigator.pop(context);

    setState(() {
      isFilterApplied = true;
    });

    final provider = context.read<SOVListProvider>();

    provider.page = 1;
    // provider.clearVendorList();

    final query = buildQuery();

    debugPrint(' FINAL URL QUERY: $query');

    await provider.fetchvendorList(
      context,
      query,
      1,
      10,
      widget.status,
    );
  }

  void _resetFilters() {
    setState(() {
      locationQuery = '';
      selectedVendorIndex = null;
      dateView = _defaultDateView;
      corporateSort = _defaultSort;
      userSort = _defaultSort;
      isFilterApplied = false;
    });
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
                  endDrawer: _buildFilterDrawer(),
                  body: Stack(
                    children: [
                      // Text(widget.status.toString()),
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

  Widget _buildFilterDrawer() {
    return Drawer(
      width: 360,
      backgroundColor: const Color(0xFF1E1E1E),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Header
              const Text(
                "Filters",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 12),

              /// Search
              TextField(
                decoration: InputDecoration(
                  hintText: "Search",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: const Color(0xFF2C2C2C),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (v) => locationQuery = v,
              ),

              const SizedBox(height: 16),

              /// Vendor
              _sectionTitle("Vendor"),
              Consumer2<SOVListProvider, UserProfileProvider>(
                builder: (context, sovProvider, userProvider, _) {
                  final rawVendors =
                      sovProvider.filteredAutoCompleteList1 ?? [];

                  // 1️⃣ Deduplicate locally
                  final deduped = {
                    for (final v in rawVendors) (v.vendorName ?? '').trim(): v
                  }.values.toList();

                  // 2️⃣ Sync with state ONLY if changed
                  if (!listEquals(
                    deduped.map((e) => e.vendorName).toList(),
                    _dedupedVendors.map((e) => e.vendorName).toList(),
                  )) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      setState(() {
                        _dedupedVendors = deduped;
                      });
                    });
                  }

                  if (deduped.isEmpty) {
                    return const Text(
                      "No vendors available",
                      style: TextStyle(color: Colors.white70),
                    );
                  }

                  return DropdownButtonHideUnderline(
                    child: DropdownButton2<int>(
                      isExpanded: true,

                      /// null = All
                      value: selectedVendorIndex,

                      hint: const Text(
                        "All",
                        style: TextStyle(color: Colors.white70),
                      ),

                      items: [
                        const DropdownMenuItem<int>(
                          value: null,
                          child: Text("All"),
                        ),
                        ...List.generate(
                          deduped.length,
                          (index) => DropdownMenuItem<int>(
                            value: index,
                            child: Text(deduped[index].vendorName ?? "-"),
                          ),
                        ),
                      ],

                      onChanged: (index) {
                        setState(() {
                          selectedVendorIndex = index;
                        });

                        debugPrint(
                          '🟢 Selected vendor: ${index == null ? "ALL" : deduped[index].vendorName}',
                        );
                      },

                      buttonStyleData: ButtonStyleData(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF3A3A3A)),
                        ),
                      ),

                      iconStyleData: const IconStyleData(
                        icon: Icon(Icons.keyboard_arrow_down),
                        iconSize: 22,
                        iconEnabledColor: Colors.white70,
                      ),

                      dropdownStyleData: DropdownStyleData(
                        maxHeight: 260,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF3A3A3A)),
                        ),
                      ),

                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),

                      selectedItemBuilder: (context) {
                        return [
                          const _CenteredDropdownText("All"),
                          ...deduped.map(
                            (e) => _CenteredDropdownText(e.vendorName ?? "-"),
                          ),
                        ];
                      },
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              /// Date
              _sectionTitle("Date"),
              CheckboxListTile(
                title:
                    const Text("Yearly", style: TextStyle(color: Colors.white)),
                value: dateView == 'yearly',
                onChanged: (_) => setState(() => dateView = 'yearly'),
              ),
              CheckboxListTile(
                title: const Text("Monthly",
                    style: TextStyle(color: Colors.white)),
                value: dateView == 'monthly',
                onChanged: (_) => setState(() => dateView = 'monthly'),
              ),

              const SizedBox(height: 16),

              /// Corporate Admin
              _sectionTitle("Corporate Admin"),
              RadioListTile(
                title: const Text("A-Z", style: TextStyle(color: Colors.white)),
                value: 'asc',
                groupValue: corporateSort,
                onChanged: (v) => setState(() => corporateSort = v!),
              ),
              RadioListTile(
                title: const Text("Z-A", style: TextStyle(color: Colors.white)),
                value: 'desc',
                groupValue: corporateSort,
                onChanged: (v) => setState(() => corporateSort = v!),
              ),

              const SizedBox(height: 16),

              /// Users
              _sectionTitle("Users"),
              RadioListTile(
                title: const Text("A-Z", style: TextStyle(color: Colors.white)),
                value: 'asc',
                groupValue: userSort,
                onChanged: (v) => setState(() => userSort = v!),
              ),
              RadioListTile(
                title: const Text("Z-A", style: TextStyle(color: Colors.white)),
                value: 'desc',
                groupValue: userSort,
                onChanged: (v) => setState(() => userSort = v!),
              ),

              const Spacer(),

              /// Footer Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _resetFilters();
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(
                          color: Color(0xFF3A3A3A),
                          width: 1.2,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8), // 🔥 SAME radius
                        ),
                      ),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _applyFilters,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF90CAF9), // 🔥 Blue background
                        foregroundColor: Colors.black,            // Text color
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "Submit",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  // Expanded(
                  //   child: ElevatedButton(
                  //     onPressed: _applyFilters,
                  //     child: const Text("Submit"),
                  //   ),
                  // ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _vendorItem({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF90CAF9).withOpacity(0.15)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF90CAF9) : Colors.white,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check, color: Color(0xFF90CAF9), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white70,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFF2C2C2C),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
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

  void _updateVendorList(SOVListProvider provider) {
    final vendors = provider.allVendorList
        .map((e) => e.vendorName)
        .where((v) => v != null && v.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();

    vendors.sort();

    if (!listEquals(vendorList, vendors)) {
      setState(() {
        vendorList = vendors;
      });
    }
  }

  Widget sovBody(CustomTypography typography) {
    return Consumer2<SOVListProvider, UserProfileProvider>(
        builder: (context, sovListProvider, user, _) {
      _updateVendorList(sovListProvider);
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
                          count: sovListProvider.cardlist?.totalApisUsed
                                  .toString() ??
                              "",
                          icon: Icons.checklist,
                          growthText: "increase vs last month",
                        ),
                        InfoCard(
                          title: "Total Cost Incurred",
                          count: sovListProvider.cardlist?.totalApiCost
                                  .toString() ??
                              "",
                          icon: Icons.attach_money,
                          growthText: "increase vs last month",
                        ),
                        InfoCard(
                          title: "Average Cost per API",
                          count: sovListProvider.cardlist?.avgCostPerApi
                                  .toString() ??
                              "",
                          icon: Icons.trending_up,
                          growthText: "increase vs last month",
                        ),
                        InfoCard(
                          title: "Active Users",
                          count: sovListProvider.cardlist?.activeVendors
                                  .toString() ??
                              "",
                          icon: Icons.accessibility,
                          growthText: "increase vs last month",
                        ),
                      ],
                    );
                  }),
                ),
                usageDetailsHeader(),
                sovListProvider.cardlist?.totalApiCost
                    .toString()=="0" ?Center(
                  child: Container(

                    alignment: Alignment.center,
                    height: 400,
                    child: Text("No data found"),
                  ),
                ):
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
                          itemCount:
                              sovListProvider.filteredAutoCompleteList1.length,
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
                    child: CachedNetworkImage(
                      imageUrl:
                          "https://maps.googleapis.com/maps/api/streetview?size=600x300&location=${vendorData.locationLatitude},${vendorData.locationLongitude}&key=${dotenv.env['GOOGLE_MAPS_API_KEY']}",
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          CircularProgressIndicator(strokeWidth: 2),
                      errorWidget: (context, url, error) => Icon(Icons.error),
                    )),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vendorData.locationName.toString(),
                        style: TextStyle(
                          color: AppColors.primaryMain,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        vendorData.locationAddress.toString() ?? "",
                        style: TextStyle(
                          color: AppColors.primaryMain,
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
            _infoRow("User", vendorData.userName ?? "NA"),
            _infoRow(
              "Role",
              vendorData.userRole?.name ?? "NA",
            ),
            _infoRow("Vendor", vendorData.vendorName.toString() ?? "—"),
            const SizedBox(height: 2),
            Divider(color: Colors.white.withOpacity(0.2)),
            const SizedBox(height: 2),
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
        const Text(
          "Usage Details",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () {
            _scaffoldKey.currentState?.openEndDrawer();
          },
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isFilterApplied
                  ? const Color(0xFF90CAF9).withOpacity(0.2) // 🔥 active bg
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.filter_list_alt,
              color: isFilterApplied
                  ? const Color(0xFF90CAF9) // 🔥 active color
                  : Colors.white70,
              size: 20,
            ),
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
      ? '\$${formatter.format(number)}'
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
      width: 160,
      height: 150,
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
                  color: AppColors.primaryMain,
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

              const SizedBox(height: 2),
//future implementation for growth text
              // Container(
              //   padding: const EdgeInsets.only(right: 16, left: 16, bottom: 2),
              //   child: Row(
              //     children: [
              //       const Icon(
              //         Icons.trending_up,
              //         size: 18,
              //         color: Color(0xFF4CAF50),
              //       ),
              //       const SizedBox(width: 6),
              //       Expanded(
              //         child: Text.rich(
              //           TextSpan(
              //             children: [
              //               TextSpan(
              //                 text: '12.4% ',
              //                 style: const TextStyle(
              //                   color: Color(0xFF4CAF50),
              //                   fontSize: 12,
              //                   fontWeight: FontWeight.w600,
              //                 ),
              //               ),
              //               TextSpan(
              //                 text: growthText,
              //                 style: TextStyle(
              //                   color: Colors.white.withOpacity(0.85),
              //                   fontSize: 12,
              //                   fontWeight: FontWeight.w400,
              //                 ),
              //               ),
              //             ],
              //           ),
              //         ),
              //       ),
              //     ],
              //   ),
              // ),

              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }
}

// void _showSharedWithDialog(
//   BuildContext context,
//   SharingStatus? sharingStatus,
// ) {
//   final users = sharingStatus?.users.values.toList() ?? [];
//
//   showDialog(
//     context: context,
//     barrierDismissible: true,
//     builder: (_) {
//       return Dialog(
//         backgroundColor: const Color(0xFF1E1E1E),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(8),
//         ),
//         child: SizedBox(
//           width: 420,
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               /// 🔹 Header
//               Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Text(
//                   "Shared With",
//                   style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                         color: Colors.white,
//                         fontWeight: FontWeight.w600,
//                       ),
//                 ),
//               ),
//
//               const Divider(color: Color(0xFF2C2C2C), height: 1),
//
//               /// 🔹 Email List
//               Flexible(
//                 child: ListView.separated(
//                   shrinkWrap: true,
//                   itemCount: users.length,
//                   separatorBuilder: (_, __) => const Divider(
//                     color: Color(0xFF2C2C2C),
//                     height: 1,
//                   ),
//                   itemBuilder: (_, index) {
//                     final user = users[index];
//                     return Padding(
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 16, vertical: 14),
//                       child: Text(
//                         user.email ?? "-",
//                         style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                               color: Colors.white,
//                             ),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//
//               const Divider(color: Color(0xFF2C2C2C), height: 1),
//
//               /// 🔹 Footer
//               Align(
//                 alignment: Alignment.centerRight,
//                 child: Padding(
//                   padding: const EdgeInsets.all(12),
//                   child: TextButton(
//                     onPressed: () => Navigator.pop(context),
//                     style: TextButton.styleFrom(
//                       backgroundColor: const Color(0xFF90CAF9),
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 20, vertical: 10),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(6),
//                       ),
//                     ),
//                     child: const Text(
//                       "Close",
//                       style: TextStyle(
//                         color: Colors.black,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       );
//     },
//   );
// }

class _CenteredDropdownText extends StatelessWidget {
  final String text;

  const _CenteredDropdownText(this.text);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft, // horizontal alignment
      child: Center(
        // 🔥 vertical centering
        heightFactor: 1,
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
