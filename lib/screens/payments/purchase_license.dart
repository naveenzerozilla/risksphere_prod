import 'package:uuid/uuid.dart';

import '../../design_system/repo/constants.dart';
import '../../utils/global_imports.dart';
import 'package:RiskSphere/models/PricingModel.dart';
import 'package:RiskSphere/screens/payments/pricing_summary.dart';
import '../../utils/readmoreWidget.dart';
import 'LocationManagementscreen.dart';

class PurchaseLicensePage extends StatefulWidget {
  static const String routeName = '/pricingList';

  const PurchaseLicensePage({
    super.key,
  });

  @override
  State<PurchaseLicensePage> createState() => _PurchaseLicensePageState();
}

class _PurchaseLicensePageState extends State<PurchaseLicensePage>
    with TickerProviderStateMixin {
  bool _isExpanded = false;
  bool _showNotificationDot = true;
  bool isEventCost = true;
  Screens _selectedScreen = Screens.accountList;
  TextEditingController mobileController = TextEditingController();
  bool isLoading = false;
  bool isExpanded = false;
  String selectedUserCount = '0';
  String selectedPlanType = '';
  String planId = '';
  String? selectedHazard;
  bool showMissingDataDropdown1 = false;
  int? totalPrice;
  Map<int, SelectedPlanState> subscriptionSelections = {};
  final _userSearchController = TextEditingController();
  final _expireDateController = TextEditingController();
  final locationCountController = TextEditingController();
  final TextEditingController _filePathController = TextEditingController();

  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool showCheckbox = false;
  bool _isSharing = false;
  Timer? _debounce;

  bool _isSearching = false;
  Timer? deBouncer;
  bool isSuperAdmin = false;
  bool isIndivudual = false;
  bool isPgAdmin = false;
  bool isAdmin = false;
  bool showTotalCorporates = false;
  List<TransferAutocompleteModel> _autocompleteUsersList = [];
  List<TransferAutocompleteModel> _selectedUsers = [];
  List<String?> _selectedRoles = [];
  List<DateTime?> _selectedDeadlines = [];
  Timer? autoCompleteDeBouncer;
  int? expandedCardIndex;
  Map<int, SelectedPlanState> cardSelections = {};

  late File files;
  List<dynamic> vendorList = [];

  String? selectedVendor;
  String? hazardName = "";
  String? vendorName = "";
  String? hasHazardLicenseStatus = "1";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getData();
      _setClaims();
    });
  }

  @override
  void dispose() {
    _filePathController.dispose();
    _userSearchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  _getData() async {
    final accountListProvider =
        Provider.of<AccountListProvider>(context, listen: false);
    await accountListProvider.fetchPricingList(context, "", 1, 5);
    String? hazardLicenseStatus =
        await SharedPreferenceService.getHazardLicense();
    setState(() {
      hasHazardLicenseStatus = hazardLicenseStatus ?? "1";
    });
  }

  Future<void> _setClaims() async {
    final prefsFutures = await Future.wait([
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
      SharedPreferenceService.getClaimForSubfeature(
          SharedPreferenceService.INTERNAL),
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

    isPgAdmin = prefsFutures[9] ?? false;
    isAdmin = prefsFutures[10] ?? false;
    isSuperAdmin = prefsFutures[11] ?? false;
    isIndivudual = prefsFutures[12] ?? false;

    showTotalCorporates = prefsFutures[0] ?? false;
  }

  @override
  Widget build(BuildContext context1) {
    var typography = CustomTypography(context);
    return SafeArea(
      child: Consumer<ThemeProvider>(
          builder: (buildContext, themeProvider, child) {
        Map<String, dynamic> getSummary() {
          dynamic total = 0;
          List<String> titles = [];
          List<String> planId = [];
          List<String> planTypes = [];
          List<String> licensePrice = [];
          List<String> userCounts = [];
          List<String> selectedPlanType = [];
          List<String> priceperuser = [];
          List<String> displayTitles = [];
          // selection.selectedPlanType
          for (var selection in cardSelections.values) {
            if (selection.totalPrice != null) {
              // total += num.parse(selection.totalPrice.toString());
              total +=
                  num.tryParse(selection.totalPrice?.toString() ?? '0') ?? 0;

              if (selection.title.isNotEmpty) {
                titles.add(selection.title);
              }
              if (selection.planId.isNotEmpty) {
                planId.add(selection.planId);
              }

              if (selection.userCount != null &&
                  selection.userCount!.isNotEmpty) {
                userCounts.add(selection.userCount!);
              }

              if (selection.selectedPlanType != null &&
                  selection.selectedPlanType!.isNotEmpty) {
                selectedPlanType.add(selection.selectedPlanType!);
              }
              if (selection.priceperuser != null &&
                  selection.priceperuser!.isNotEmpty) {
                priceperuser.add(selection.priceperuser!);
              }
              if (selection.planType == "event_cost") {
                licensePrice.add(selection.licensePrice);
              } else if (selection.licensePrice.isNotEmpty) {
                licensePrice.add(selection.licensePrice);
              }

              if (selection.planType.isNotEmpty) {
                planTypes.add(selection.planType);
              }
            }
          }

          return {
            'total': total,
            'planId': planId,
            'titles': titles,
            'descriptions': "descriptions",
            'priceperuser': priceperuser,
            'licenseprice': licensePrice,
            'usercount': userCounts,
            'selectedPlanType': selectedPlanType,
            'planType': planTypes,
          };
        }

        return PopScope(
          onPopInvokedWithResult: (canPop, result) {
            Provider.of<DrawerSelectionProvider>(context, listen: false)
                .setSelectedItem("dashboard");
          },
          child: Scaffold(
            key: _scaffoldKey,
            backgroundColor: themeProvider.getTheme.colorScheme.background,
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
            floatingActionButton: getSummary()['titles'].isEmpty
                ? null
                : GestureDetector(
                    onTap: () {
                      final summary = getSummary();

                      final titles = List<String>.from(summary['titles'] ?? []);

                      if (titles.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Please select at least one subscription plan.",
                            ),
                          ),
                        );
                        return;
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PricingSummary(
                            statusflag: "single",
                            title: titles,
                            summary: summary,
                            hazardName: hazardName ?? "",
                            vendorName: vendorName ?? "",
                          ),
                        ),
                      ).then((value) {
                        if (value != false) {
                          _getData();

                          setState(() {
                            cardSelections.clear();
                            expandedCardIndex = null;
                          });
                        }
                      });
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 62,
                          height: 62,
                          decoration: BoxDecoration(
                            color: const Color(0xFF99CCFF),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(.25),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.shopping_cart_checkout,
                            color: Colors.black87,
                            size: 30,
                          ),
                        ),
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            constraints: const BoxConstraints(
                              minWidth: 22,
                              minHeight: 22,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                "${getSummary()['titles'].length}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
            body: Stack(
              children: [
                Consumer2<AccountListProvider, MyLocationListProvider>(
                  builder: (
                    context,
                    pricingProvider,
                    locationProfileProvider,
                    child,
                  ) {
                    final typography = CustomTypography(context);

                    return pricingProvider.isLoading
                        ? const Center(
                            child: CircularProgressIndicator(),
                          )
                        : pricingProvider.pricingList.isEmpty
                            ? Center(
                                child: Text(
                                  "No Pricing Plans Available",
                                  style: typography.Body1.copyWith(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            : Padding(
                                padding: EdgeInsets.zero,
                                child: Column(
                                  children: [
                                    SizedBox(height: CustomSpacing.three),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHigh,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        "Bring your business to the safest at scale",
                                        style: typography.Body1.copyWith(
                                          fontWeight: FontWeight.w400,
                                          fontSize: 12,
                                          letterSpacing: 0.4,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: CustomSpacing.three),
                                    Text(
                                      "Uncover What RiskSphere Can Do for You",
                                      textAlign: TextAlign.center,
                                      style: typography.Body1.copyWith(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 26,
                                      ),
                                    ),
                                    SizedBox(height: CustomSpacing.three),
                                    Expanded(
                                      child: Card(
                                        elevation: 2,
                                        child: Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              0, 0, 0, 5),
                                          child: ListView.builder(
                                            itemCount: pricingProvider
                                                .pricingList.length,
                                            itemBuilder: (context, index) {
                                              final Result item =
                                                  pricingProvider
                                                      .pricingList[index];

                                              return Consumer<
                                                  UserProfileProvider>(
                                                builder: (
                                                  context,
                                                  userProfileProvider,
                                                  child,
                                                ) {
                                                  final bool isNotIndividual =
                                                      (userProfileProvider
                                                              .userData
                                                              .isIndividual ??
                                                          true);

                                                  if (item.planName ==
                                                          "User License" &&
                                                      isNotIndividual) {
                                                    return const SizedBox
                                                        .shrink();
                                                  }

                                                  return _buildSubscriptionCard(
                                                    item,
                                                    index,
                                                    pricingProvider
                                                        .pricingList.length,
                                                    pricingProvider,
                                                  );
                                                },
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                  },
                ),
                Positioned(
                  bottom: 80,
                  right: 16,
                  child: GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => _ChatbotBottomSheet(),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 5,
                      ),
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
                        children: const [
                          Text(
                            "Need Help?",
                            style: TextStyle(color: Colors.white),
                          ),
                          SizedBox(width: 8),
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: AppColors.primaryMain,
                            child: Icon(
                              Icons.smart_toy,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Future<List<TransferAutocompleteModel>> fetchAutocompleteUsers(
      String query, String type) async {
    try {
      ApiService apiService = ApiService(AppConstant.GET_SEARCH_LIST_BY_SOV);
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

  void _onSearchChanged(String query, StateSetter setState, String type) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.isNotEmpty) {
        this.setState(() => _isSearching = true);

        final results = await fetchAutocompleteUsers(
          query.trim().toLowerCase(),
          type,
        );

        this.setState(() {
          _autocompleteUsersList = results.where((user) {
            final nameLower = (user.name ?? '').toLowerCase();
            final emailLower = (user.email ?? '').toLowerCase();
            final queryLower = query.trim().toLowerCase();
            return nameLower.contains(queryLower) ||
                emailLower.contains(queryLower);
          }).toList();
          _isSearching = false;
        });
      } else {
        this.setState(() {
          _autocompleteUsersList.clear();
          _isSearching = false;
        });
      }
    });
  }

  Widget _buildSubscriptionCard(
    Result item,
    int index,
    int totalCount,
    AccountListProvider pricingProvider,
  ) {
    var typography = CustomTypography(context);
    cardSelections.putIfAbsent(index, () => SelectedPlanState());
    final selection = cardSelections[index]!;
    SignUpOptions _selectedOption = SignUpOptions.corporate;
    List<String> userCountOptions = [];
    List<RangeYear> selectedRangeList = [];
    if (selection.selectedPlanType == 'Monthly' && item.rangeMonth != null) {
      selectedRangeList = item.rangeMonth!;
      userCountOptions = selectedRangeList
          .map((range) => '${range.startCount!}-${range.endCount!}')
          .toList();
    } else if (selection.selectedPlanType == 'Yearly' &&
        item.rangeYear != null) {
      selectedRangeList = item.rangeYear!;
      userCountOptions = selectedRangeList
          .map((range) => '${range.startCount}-${range.endCount}')
          .toList();
    }

    if (selection.selectedUserCount.isNotEmpty) {
      final selectedRange = selectedRangeList.firstWhere(
        (range) =>
            '${range.startCount}-${range.endCount}' ==
            selection.selectedUserCount,
        orElse: () => RangeYear(
          startCount: '0',
          endCount: '0',
          pricePerUser: "0",
          rangePrice: 0,
        ),
      );

      int end = selectedRange.endCount is int
          ? selectedRange.endCount
          : int.tryParse(selectedRange.endCount.toString()) ?? 0;

      int numberOfUsers = end - 0;
      print(numberOfUsers);
    }
    final availablePlans = <String>[
      if (item.rangeMonth != null &&
          item.rangeMonth!.isNotEmpty &&
          item.rangeMonth!.any((e) => (e.rangePrice ?? 0) > 0))
        'Monthly',
      if (item.rangeYear != null &&
          item.rangeYear!.isNotEmpty &&
          item.rangeYear!.any((e) => (e.rangePrice ?? 0) > 0))
        'Yearly',
    ];

// Default selection
    if (selection.selectedPlanType == null ||
        selection.selectedPlanType!.isEmpty) {
      if (availablePlans.contains('Yearly')) {
        selection.selectedPlanType = 'Yearly';
      } else if (availablePlans.isNotEmpty) {
        selection.selectedPlanType = availablePlans.first;
      }
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          expandedCardIndex = expandedCardIndex == index ? null : index;
        });
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            index == 0 && !Platform.isIOS
                ? _buildBasicPackageCard(context, pricingProvider)
                : SizedBox(),

            if (Platform.isAndroid && !showTotalCorporates) ...[
              index == 0
                  ? Card(
                      color: Theme.of(context).colorScheme.surfaceContainerHigh,
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              index == 0
                                  ? Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                "Digital SOV",
                                                maxLines: 2,
                                                style:
                                                    typography.Body1.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF99CCFF),
                                                  fontSize: 18,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              "",
                                              style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w800),
                                            )
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        SingleChildScrollView(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              ReadMoreText(
                                                text:
                                                    "• Create and share digital SOVs\n"
                                                    "• Basic document management\n"
                                                    "• Limited processing\n"
                                                    "• Up to 1,000 locations\n"
                                                    "• Community support",
                                              ),
                                              const SizedBox(height: 10),
                                              Divider(
                                                color: Colors.white
                                                    .withOpacity(.08),
                                                thickness: 1,
                                              ),
                                              const SizedBox(height: 5),
                                              Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    "\$0",
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 35,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      height: 1,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            bottom: 6),
                                                    child: Text(
                                                      item.planName ==
                                                              "User License"
                                                          ? "/ share"
                                                          : "",
                                                      style: TextStyle(
                                                        color: Colors
                                                            .grey.shade400,
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w400,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 5),
                                              Divider(
                                                color: Colors.white
                                                    .withOpacity(.08),
                                                thickness: 1.2,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    )
                                  : Container(),
                            ]),
                      ),
                    )
                  : Container(),
              index == 0 ? const SizedBox(height: 15) : Container(),
              Card(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.planName ?? "Location Count (Hazard)",
                              maxLines: 2,
                              style: typography.Body1.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF99CCFF),
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ReadMoreText(
                              text:
                                  item.description ?? "Default description...",
                            ),
                          ],
                        ),
                      ),
                      if (Platform.isIOS) ...[
                        SizedBox(height: 16),
                        Container(
                          child: Text(
                            "Please visit https://app.risksphere.ai/ and sign in with your credentials to upgrade your account.",
                            style: typography.Body1.copyWith(
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                                color: Color(0xFFFDBE71)),
                          ),
                        )
                      ] else ...[
                        Divider(
                          color: Colors.white.withOpacity(.08),
                          thickness: 1,
                        ),
                        const SizedBox(height: 5),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              selection.totalPrice != null &&
                                      selection.totalPrice.toString() != '0'
                                  ? "\$${selection.totalPrice}"
                                  : "\$0",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 35,
                                fontWeight: FontWeight.bold,
                                height: 1,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text(
                                item.planName == "User License"
                                    ? "/ share"
                                    : "",
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Divider(
                          color: Colors.white.withOpacity(.08),
                          thickness: 1.2,
                        ),
                        const SizedBox(height: 20),

                        DropdownButtonFormField<String>(
                          value: selection.selectedPlanType,
                          decoration: InputDecoration(
                            filled: true,
                            labelText: "Subscription Type",
                            border: item.planName == "Event Count Cost"
                                ? const OutlineInputBorder(
                                    borderRadius: BorderRadius.zero,
                                  )
                                : const OutlineInputBorder(),
                            enabledBorder: item.planName == "Event Count Cost"
                                ? OutlineInputBorder(
                                    borderRadius: BorderRadius.zero,
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade500,
                                    ),
                                  )
                                : null,
                            focusedBorder: item.planName == "Event Count Cost"
                                ? OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: const BorderSide(
                                      color: Colors.white,
                                    ),
                                  )
                                : null,
                          ),
                          borderRadius: BorderRadius.circular(
                            item.planName == "Event Count Cost" ? 6 : 4,
                          ),
                          items: availablePlans.map((plan) {
                            return DropdownMenuItem<String>(
                              value: plan,
                              child: Text(plan),
                            );
                          }).toList(),

                          // Disable dropdown when only one option exists
                          onChanged: availablePlans.length == 1
                              ? null
                              : (value) {
                                  if (value != null) {
                                    setState(() {
                                      selection.selectedPlanType = value;
                                      selection.selectedUserCount = '1-1';
                                      selection.totalPrice = null;

                                      if (item.planName == "Event Count Cost") {
                                        selection.title = "Event Count Cost";
                                        selection.planId = item.planId ?? "";
                                        selection.planType =
                                            item.planType ?? "";

                                        if (value == "Monthly") {
                                          selection.totalPrice =
                                              item.rangeMonth![0].rangePrice;
                                          selection.priceperuser =
                                              item.rangeMonth![0].pricePerUser;
                                          selection.licensePrice =
                                              item.rangeMonth![0].pricePerUser;

                                          selection.userCount =
                                              '${item.rangeMonth![0].startCount}-${item.rangeMonth![0].endCount}';
                                        } else {
                                          selection.totalPrice =
                                              item.rangeYear![0].rangePrice;
                                          selection.priceperuser =
                                              item.rangeYear![0].pricePerUser;
                                          selection.licensePrice =
                                              item.rangeYear![0].pricePerUser;

                                          selection.userCount =
                                              '${item.rangeYear![0].startCount}-${item.rangeYear![0].endCount}';
                                        }
                                      }
                                    });
                                  }
                                },
                        ),
                        // item.planName == "Event Count Cost"
                        //     ? DropdownButtonFormField<String>(
                        //         value: selection.selectedPlanType,
                        //         decoration: InputDecoration(
                        //           filled: true,
                        //           labelText: "Subscription Type",
                        //           border: OutlineInputBorder(
                        //             borderRadius:
                        //                 BorderRadius.zero, // reduced radius
                        //           ),
                        //           enabledBorder: OutlineInputBorder(
                        //             borderRadius: BorderRadius.zero,
                        //             borderSide: BorderSide(
                        //               color: Colors.grey.shade500,
                        //             ),
                        //           ),
                        //           focusedBorder: OutlineInputBorder(
                        //             borderRadius: BorderRadius.circular(6),
                        //             borderSide: BorderSide(
                        //               color: Colors.white,
                        //             ),
                        //           ),
                        //         ),
                        //         borderRadius: BorderRadius.circular(6),
                        //         hint: const Text("Subscription Type"),
                        //         items: [
                        //           if (item.rangeMonth != null &&
                        //               item.rangeMonth!.isNotEmpty &&
                        //               item.rangeMonth!.any(
                        //                 (e) => (e.rangePrice ?? 0) > 0,
                        //               ))
                        //             const DropdownMenuItem<String>(
                        //               value: 'Monthly',
                        //               child: Text('Monthly'),
                        //             ),
                        //           if (item.rangeYear != null &&
                        //               item.rangeYear!.isNotEmpty &&
                        //               item.rangeYear!.any(
                        //                 (e) => (e.rangePrice ?? 0) > 0,
                        //               ))
                        //             const DropdownMenuItem<String>(
                        //               value: 'Yearly',
                        //               child: Text('Yearly'),
                        //             ),
                        //         ],
                        //         onChanged: (value) {
                        //           if (value != null) {
                        //             setState(() {
                        //               selection.selectedPlanType = value;
                        //             });
                        //           }
                        //         },
                        //       )
                        //     : DropdownButtonFormField<String>(
                        //         value: selection.selectedPlanType,
                        //         decoration: const InputDecoration(
                        //           border: OutlineInputBorder(),
                        //           filled: true,
                        //           labelText: "Subscription Type",
                        //         ),
                        //         hint: const Text("Subscription Type"),
                        //         borderRadius: BorderRadius.circular(4),
                        //         items: [
                        //           if (item.rangeMonth != null &&
                        //               item.rangeMonth!.isNotEmpty &&
                        //               item.rangeMonth!.any(
                        //                 (e) => (e.rangePrice ?? 0) > 0,
                        //               ))
                        //             const DropdownMenuItem<String>(
                        //               value: 'Monthly',
                        //               child: Text('Monthly'),
                        //             ),
                        //           if (item.rangeYear != null &&
                        //               item.rangeYear!.isNotEmpty &&
                        //               item.rangeYear!.any(
                        //                 (e) => (e.rangePrice ?? 0) > 0,
                        //               ))
                        //             const DropdownMenuItem<String>(
                        //               value: 'Yearly',
                        //               child: Text('Yearly'),
                        //             ),
                        //         ],
                        //         onChanged: (value) {
                        //           if (value != null) {
                        //             setState(() {
                        //               selection.selectedPlanType = value;
                        //               selection.selectedUserCount = '1-1';
                        //               selection.totalPrice = null;
                        //
                        //               item.planName == "Event Count Cost"
                        //                   ? value == 'Monthly'
                        //                       ? selection.totalPrice =
                        //                           item.rangeMonth![0].rangePrice
                        //                       : selection.totalPrice =
                        //                           item.rangeYear![0].rangePrice
                        //                   : "";
                        //               item.planName == "Event Count Cost"
                        //                   ? selection.title = "Event Count Cost"
                        //                   : "";
                        //               item.planName == "Event Count Cost"
                        //                   ? selection.planId = item.planId!
                        //                   : '';
                        //               item.planName == "Event Count Cost"
                        //                   ? selection.planType = item.planType!
                        //                   : '';
                        //               item.planName == "Event Count Cost"
                        //                   ? value == 'Monthly'
                        //                       ? selection.priceperuser = item
                        //                           .rangeMonth![0].pricePerUser
                        //                       : selection.priceperuser = item
                        //                           .rangeYear![0].pricePerUser
                        //                   : "";
                        //               item.planName == "Event Count Cost"
                        //                   ? value == 'Monthly'
                        //                       ? selection.licensePrice = item
                        //                           .rangeMonth![0].pricePerUser
                        //                       : selection.priceperuser = item
                        //                           .rangeYear![0].pricePerUser
                        //                   : "";
                        //               selection.userCount = item.planName ==
                        //                       "Event Count Cost"
                        //                   ? (value == 'Monthly'
                        //                       ? '${item.rangeMonth![0].startCount}-${item.rangeMonth![0].endCount}'
                        //                       : '${item.rangeYear![0].startCount}-${item.rangeYear![0].endCount}')
                        //                   : selection.userCount;
                        //             });
                        //           }
                        //         },
                        //       ),
                        const SizedBox(height: 16),
                        // item.planName == "Event Count Cost"
                        (item.planName?.contains("Event Count") ?? false)
                            ? SizedBox()
                            : item.planName.toString() ==
                                        "Earthquake Event(USGS)" ||
                                    item.planName.toString() ==
                                        "Hurricane Event(Kineticast)"
                                ? TextFormField(
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: "Location Count",
                                      border: OutlineInputBorder(),
                                      filled: true,
                                    ),
                                    onChanged: (value) {
                                      int count = int.tryParse(value) ?? 0;

                                      final rangeList =
                                          selection.selectedPlanType == "Yearly"
                                              ? item.rangeYear
                                              : item.rangeMonth;

                                      if (rangeList == null ||
                                          rangeList.isEmpty) return;

                                      final selectedRange = rangeList.first;

                                      double pricePerLocation = double.tryParse(
                                            selectedRange.pricePerUser
                                                .toString(),
                                          ) ??
                                          0;
                                      setState(() {
                                        selection.title = item.planName ?? "";

                                        selection.planId = item.planId ?? "";

                                        selection.planType =
                                            item.planType ?? "";
                                        selection.userCount = "1-$count";

                                        selection.selectedPlanType =
                                            selection.selectedPlanType;

                                        selection.priceperuser =
                                            pricePerLocation.toString();

                                        selection.totalPrice =
                                            (count * pricePerLocation)
                                                .toStringAsFixed(2);

                                        selection.licensePrice =
                                            selection.totalPrice.toString();
                                      });
                                      // setState(() {
                                      //   selection.totalPrice =
                                      //       (count * pricePerLocation)
                                      //           .toStringAsFixed(2);
                                      // });

                                      print("Count => $count");
                                      print("Price => $pricePerLocation");
                                      print("Total => ${selection.totalPrice}");
                                    },
                                  )
                                : DropdownButtonFormField<String>(
                                    value: userCountOptions.contains(
                                            selection.selectedUserCount)
                                        ? selection.selectedUserCount
                                        : null,
                                    decoration: InputDecoration(
                                      labelText: item.planName == "User License"
                                          ? "Select User"
                                          : "Select Locations",
                                      border: OutlineInputBorder(),
                                      filled: true,
                                    ),
                                    items: userCountOptions.map((rangeLabel) {
                                      return DropdownMenuItem<String>(
                                          value: rangeLabel,
                                          child: Text(
                                              '$rangeLabel ${item.planName == "User License" ? "User" : "Locations"}'));
                                    }).toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() {
                                          // Set the selected user count from dropdown value
                                          selection.selectedUserCount = value;

                                          // Set title from the item
                                          selection.title = item.planName ??
                                              "Location Count (Hazard)";

                                          // Find the selected range from the list
                                          final selectedRange =
                                              selectedRangeList.firstWhere(
                                            (range) =>
                                                '${range.startCount}-${range.endCount}' ==
                                                value,
                                            orElse: () => RangeYear(
                                              startCount: '0',
                                              endCount: '0',
                                              pricePerUser: "0",
                                              rangePrice: 0,
                                            ),
                                          );
                                          // Reformat selected user count (for consistency)
                                          selection.selectedUserCount =
                                              '${selectedRange.endCount}-${selectedRange.startCount}';
                                          selection.planId = item.planId ?? '';
                                          selection.planType =
                                              item.planType ?? '';

                                          // Parse start and end counts
                                          int start = int.tryParse(selectedRange
                                                  .startCount
                                                  .toString()) ??
                                              0;
                                          int end = int.tryParse(selectedRange
                                                  .endCount
                                                  .toString()) ??
                                              0;
                                          int numberOfUsers = end - 0;
                                          selection.userCount =
                                              start.toString() +
                                                  '-' +
                                                  end.toString();

                                          print(
                                              'Selected Range → Start: $start, End: $end');
                                          print(selection.planType.toString());
                                          print(selection.priceperuser
                                              .toString());
                                          print(selectedRange.rangePrice
                                              .toString());

                                          int pricePerUser = int.tryParse(
                                                  selectedRange.pricePerUser
                                                      .toString()) ??
                                              0;
                                          print(pricePerUser.toString());
                                          selection.totalPrice = selectedRange
                                              .rangePrice
                                              .toString();
                                          print(totalPrice.toString());
                                          selection.licensePrice = selectedRange
                                              .rangePrice
                                              .toString();
                                          selection.priceperuser =
                                              selection.licensePrice.toString();
                                        });
                                      }
                                    },
                                  ),
                        SizedBox(height: 2),
                        if (item.planName == "Event Count Cost" ||
                            item.planName!.contains('event')) ...[
                          SizedBox(height: 10),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 2.0),
                            child: DropdownButtonFormField<String>(
                              value: (selection.selectedPlanType.toString() ==
                                                  "Yearly"
                                              ? item.rangeYear
                                              : item.rangeMonth)
                                          ?.any((rangeItem) =>
                                              rangeItem.vendorId ==
                                              selectedVendor) ==
                                      true
                                  ? selectedVendor
                                  : null,
                              isExpanded: true,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.grey[800],
                                labelText: 'Select Vendor',
                                labelStyle:
                                    const TextStyle(color: Colors.white),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              dropdownColor: Colors.grey[850],
                              icon: const Icon(Icons.arrow_drop_down,
                                  color: Colors.white),
                              items: (selection.selectedPlanType.toString() ==
                                          "Yearly"
                                      ? item.rangeYear
                                      : item.rangeMonth)!
                                  .fold<List<DropdownMenuItem<String>>>([],
                                      (prev, rangeItem) {
                                if (!prev.any(
                                    (e) => e.value == rangeItem.vendorId)) {
                                  prev.add(DropdownMenuItem<String>(
                                    value: rangeItem.vendorId,
                                    child: Text(
                                      rangeItem.vendorNameLabel ?? 'Unknown',
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  ));
                                }
                                return prev;
                              }),
                              onChanged: (value) {
                                setState(() {
                                  selectedVendor = value;
                                  selectedHazard = null;
                                  // hazardName = '';

                                  final rangeList =
                                      selection.selectedPlanType.toString() ==
                                              "Yearly"
                                          ? item.rangeYear
                                          : item.rangeMonth;

                                  final selected = (rangeList?.any(
                                              (r) => r.vendorId == value) ??
                                          false)
                                      ? rangeList!.firstWhere(
                                          (r) => r.vendorId == value)
                                      : null;

                                  vendorName =
                                      selected?.vendorNameLabel ?? 'Unknown';
                                  hazardName = selected?.hazardNameLabel ?? '';
                                  item.planName == "Event Count Cost"
                                      ? selection.title = "Event Count Cost"
                                      : "";
                                  if (selectedVendor != null) {
                                    final vendorData = vendorList.firstWhere(
                                      (v) => v['vendor_id'] == selectedVendor,
                                      orElse: () => {},
                                    );

                                    final hazards =
                                        (vendorData['hazard_commercials']
                                                as List?) ??
                                            [];

                                    if (hazards.length == 1) {
                                      selectedHazard = hazards[0]['hazard_id'];
                                      // hazardName = hazards[0]['hazard_name_label'] ?? '';
                                    }
                                  }
                                });
                              },
                              validator: (value) {
                                if (isEventCost &&
                                    (value == null || value.isEmpty)) {
                                  return 'Vendor is required';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 20),
                          hazardName.toString().isEmpty
                              ? SizedBox()
                              : Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 2.0),
                                  child: DropdownButtonFormField<String>(
                                    value: (selection.selectedPlanType
                                                            .toString() ==
                                                        "Yearly"
                                                    ? item.rangeYear
                                                    : item.rangeMonth)
                                                ?.any((rangeItem) =>
                                                    rangeItem.hazardNameLabel ==
                                                    hazardName) ==
                                            true
                                        ? selectedHazard
                                        : null,
                                    isExpanded: true,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.grey[800],
                                      labelText: 'Select Hazard',
                                      labelStyle:
                                          const TextStyle(color: Colors.white),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    dropdownColor: Colors.grey[850],
                                    icon: const Icon(Icons.arrow_drop_down,
                                        color: Colors.white),
                                    items: (selection.selectedPlanType
                                                    .toString() ==
                                                "Yearly"
                                            ? item.rangeYear
                                            : item.rangeMonth)!
                                        .where((rangeItem) =>
                                            rangeItem.hazardNameLabel ==
                                            hazardName) // Filter here
                                        .fold<List<DropdownMenuItem<String>>>(
                                            [], (prev, rangeItem) {
                                      if (!prev.any((e) =>
                                          e.value == rangeItem.hazardId)) {
                                        prev.add(DropdownMenuItem<String>(
                                          value: rangeItem.hazardId,
                                          child: Text(
                                            rangeItem.hazardNameLabel ??
                                                'Unknown',
                                            style: const TextStyle(
                                                color: Colors.white),
                                          ),
                                        ));
                                      }
                                      return prev;
                                    }),
                                    onChanged: (value) {
                                      setState(() {
                                        selectedHazard = value;
                                        final rangeList = selection
                                                    .selectedPlanType
                                                    .toString() ==
                                                "Yearly"
                                            ? item.rangeYear
                                            : item.rangeMonth;

                                        final selected = (rangeList?.any((r) =>
                                                    r.hazardId == value &&
                                                    r.hazardNameLabel ==
                                                        hazardName) ??
                                                false)
                                            ? rangeList!.firstWhere((r) =>
                                                r.hazardId == value &&
                                                r.hazardNameLabel == hazardName)
                                            : null;

                                        vendorName =
                                            selected?.vendorNameLabel ??
                                                'Unknown';
                                        hazardName =
                                            selected?.hazardNameLabel ?? '';
                                        item.planName == "Event Count Cost"
                                            ? selection.title =
                                                "Event Count Cost"
                                            : "";

                                        print(
                                            "Selected Hazard: $selectedHazard, Name: $hazardName");

                                        if (selectedVendor != null) {
                                          final vendorData =
                                              vendorList.firstWhere(
                                            (v) =>
                                                v['vendor_id'] ==
                                                selectedVendor,
                                            orElse: () => {},
                                          );

                                          final hazards =
                                              (vendorData['hazard_commercials']
                                                      as List?) ??
                                                  [];

                                          if (hazards.length == 1) {
                                            selectedHazard =
                                                hazards[0]['hazard_id'];
                                          }
                                        }
                                      });
                                    },
                                    validator: (value) {
                                      if (isEventCost &&
                                          (value == null || value.isEmpty)) {
                                        return 'Hazard is required';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                          const SizedBox(height: 20),
                          hazardName.toString().isEmpty
                              ? const SizedBox()
                              : Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 2.0),
                                  child: TextFormField(
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: "Location Count",
                                      border: OutlineInputBorder(),
                                    ),
                                    onChanged: (value) {
                                      int count = int.tryParse(value) ?? 0;
                                      final rangeList =
                                          selection.selectedPlanType == "Yearly"
                                              ? item.rangeYear
                                              : item.rangeMonth;

                                      final selectedRange =
                                          rangeList?.firstWhere(
                                        (r) =>
                                            r.vendorId == selectedVendor &&
                                            r.hazardId == selectedHazard,
                                      );

                                      double pricePerLocation = double.tryParse(
                                            selectedRange?.pricePerUser
                                                    .toString() ??
                                                "0",
                                          ) ??
                                          0;

                                      setState(() {
                                        selection.totalPrice =
                                            (count * pricePerLocation)
                                                .toStringAsFixed(2);
                                      });
                                    },
                                  ),
                                ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ],

            //OLD NEW
            Card(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Consumer2<DashboardProvider, UserProfileProvider>(
                  builder:
                      (context, dashboardProvider, userProfileProvider, child) {
                    final bool isAdminUser =
                        (userProfileProvider.userData.role != null &&
                                userProfileProvider.userData.role!.isNotEmpty &&
                                userProfileProvider.userData.role![0].name
                                        .toString()
                                        .toLowerCase() ==
                                    "admin") &&
                            (isSuperAdmin || isPgAdmin || isAdmin);

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if ((isAdminUser || showTotalCorporates) &&
                            index == totalCount - 1) ...[
                          // if (isAdminUser && index == 2 ||
                          //     showTotalCorporates && index == 2) ...[
                          SizedBox(height: CustomSpacing.four),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Share Location',
                                style: typography.Body1.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 22,
                                ),
                              ),
                              Text(
                                "Location Count: $hasHazardLicenseStatus",
                                style: typography.Body1.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),
                          SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ReadMoreText(
                                    text:
                                        "• Give locations to clients and partners \n"
                                        "• Buy in bulk for you clients and partners"),
                                const SizedBox(height: 10),
                              ],
                            ),
                          ),

                          TextField(
                            controller: _userSearchController,
                            style: const TextStyle(color: Colors.white),
                            onChanged: (value) {
                              _onSearchChanged(
                                value,
                                this.setState,
                                _selectedOption.name,
                              );
                            },
                            decoration: InputDecoration(
                              labelText: "Search User",
                              labelStyle:
                                  const TextStyle(color: Colors.white54),
                              hintText: 'Choose a user to share locations with',
                              hintStyle: const TextStyle(color: Colors.white38),
                              prefixIcon: const Icon(Icons.search,
                                  color: Colors.white54),
                              suffixIcon: _isSearching
                                  ? const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white54,
                                        ),
                                      ),
                                    )
                                  : null,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: _autocompleteUsersList.isNotEmpty
                                    ? const BorderRadius.only(
                                        topLeft: Radius.circular(12),
                                        topRight: Radius.circular(12),
                                      )
                                    : BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: Colors.white24, width: 1),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: _autocompleteUsersList.isNotEmpty
                                    ? const BorderRadius.only(
                                        topLeft: Radius.circular(12),
                                        topRight: Radius.circular(12),
                                      )
                                    : BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: AppColors.primaryMain, width: 1.5),
                              ),
                              filled: true,
                              fillColor: const Color(0xFF1E1E1E),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                            ),
                          ),

                          if (_selectedUsers.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: _selectedUsers.map((user) {
                                  return Chip(
                                    backgroundColor:
                                        AppColors.primaryMain.withOpacity(0.15),
                                    side: BorderSide(
                                        color: AppColors.primaryMain,
                                        width: 0.8),
                                    label: Text(
                                      user.email ?? user.name ?? '',
                                      style: TextStyle(
                                        color: AppColors.primaryMain,
                                        fontSize: 13,
                                      ),
                                    ),
                                    deleteIcon:
                                        const Icon(Icons.close, size: 14),
                                    deleteIconColor: AppColors.primaryMain,
                                    onDeleted: () {
                                      this.setState(() {
                                        _selectedUsers.remove(user);
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                            ),

                          if (_autocompleteUsersList.isNotEmpty)
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E1E),
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(12),
                                  bottomRight: Radius.circular(12),
                                ),
                                border:
                                    Border.all(color: Colors.white24, width: 1),
                              ),
                              constraints: const BoxConstraints(maxHeight: 280),
                              child: ListView.separated(
                                shrinkWrap: true,
                                padding: EdgeInsets.zero,
                                itemCount: _autocompleteUsersList.length,
                                separatorBuilder: (_, __) => const Divider(
                                    color: Colors.white12, height: 1),
                                itemBuilder: (context, i) {
                                  final user = _autocompleteUsersList[i];
                                  final bool isSelected = _selectedUsers
                                      .any((u) => u.email == user.email);

                                  String getInitials(String? name) {
                                    if (name == null || name.isEmpty)
                                      return 'U';
                                    final parts = name.trim().split(' ');
                                    if (parts.length >= 2) {
                                      return '${parts[0][0]}${parts[1][0]}'
                                          .toUpperCase();
                                    }
                                    return parts[0][0].toUpperCase();
                                  }

                                  return InkWell(
                                    onTap: () {
                                      this.setState(() {
                                        _selectedUsers.clear();
                                        _selectedUsers.add(user);
                                        _autocompleteUsersList.clear();
                                        _userSearchController.clear();
                                      });
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 10),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 22,
                                            height: 22,
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? AppColors.primaryMain
                                                  : Colors.transparent,
                                              border: Border.all(
                                                color: isSelected
                                                    ? AppColors.primaryMain
                                                    : Colors.white54,
                                                width: 1.5,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: isSelected
                                                ? const Icon(Icons.check,
                                                    color: Colors.white,
                                                    size: 14)
                                                : null,
                                          ),
                                          const SizedBox(width: 10),
                                          CircleAvatar(
                                            radius: 22,
                                            backgroundColor: Colors.grey[600],
                                            child: Text(
                                              getInitials(user.name),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  user.name ?? '',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 15,
                                                  ),
                                                ),
                                                Text(
                                                  user.email ?? '',
                                                  style: TextStyle(
                                                    color: (user.email ?? '')
                                                            .toLowerCase()
                                                            .contains(
                                                                _userSearchController
                                                                    .text
                                                                    .trim()
                                                                    .toLowerCase())
                                                        ? AppColors.primaryMain
                                                        : Colors.white54,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          const SizedBox(height: 16),

                          // ─── Location Count ───
                          TextField(
                            controller: locationCountController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Location Count',
                              labelStyle:
                                  const TextStyle(color: Colors.white54),
                              hintText: 'Enter the number of Locations',
                              hintStyle: const TextStyle(color: Colors.white38),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: Colors.white24, width: 1),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: AppColors.primaryMain, width: 1.5),
                              ),
                              filled: true,
                              fillColor: const Color(0xFF1E1E1E),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // ─── Expire Days ───
                          TextField(
                            controller: _expireDateController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Expire Days',
                              labelStyle:
                                  const TextStyle(color: Colors.white54),
                              hintText: 'Enter number of expire days',
                              hintStyle: const TextStyle(color: Colors.white38),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: Colors.white24, width: 1),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: AppColors.primaryMain, width: 1.5),
                              ),
                              filled: true,
                              fillColor: const Color(0xFF1E1E1E),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                            ),
                          ),
                          const SizedBox(height: 28),

                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: _isSharing
                                  ? null
                                  : () async {
                                      final emails = _selectedUsers
                                          .map((u) => u.email ?? '')
                                          .where((e) => e.isNotEmpty)
                                          .join(',');
                                      final credits = int.tryParse(
                                              locationCountController.text
                                                  .trim()) ??
                                          0;
                                      final expireDays = int.tryParse(
                                              _expireDateController.text
                                                  .trim()) ??
                                          0;

                                      if (emails.isEmpty) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Please select at least one user.'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                        return;
                                      }
                                      if (credits <= 0) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Please enter a valid location count.'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                        return;
                                      }
                                      if (expireDays <= 0) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Please enter valid expire days.'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                        return;
                                      }

                                      setState(() => _isSharing = true);

                                      await Provider.of<AccountListProvider>(
                                              context,
                                              listen: false)
                                          .shareLocation(
                                        context,
                                        recipientEmails: emails,
                                        credits: credits,
                                        expireDays: expireDays,
                                        message: "",
                                      );

                                      setState(() {
                                        _isSharing = false;
                                        _selectedUsers.clear();
                                        locationCountController.clear();
                                        _expireDateController.clear();
                                        _userSearchController.clear();
                                      });
                                    },
                              icon: _isSharing
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.black87,
                                      ),
                                    )
                                  : const Icon(Icons.share,
                                      color: Colors.black87),
                              label: Text(
                                _isSharing ? 'Sharing...' : 'Share Now',
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isSharing
                                    ? AppColors.primaryMain.withOpacity(0.6)
                                    : AppColors.primaryMain,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                          SizedBox(height: CustomSpacing.four),

                          // ─── Manage Button ───
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            LocationManagementScreen()));
                              },
                              icon: Icon(Icons.history,
                                  color: AppColors.primaryMain),
                              label: Text(
                                'Manage',
                                style: TextStyle(
                                  color: AppColors.primaryMain,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                    color: AppColors.primaryMain, width: 1.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: CustomSpacing.four),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),

            if (Platform.isIOS && index == totalCount - 1)
              Consumer2<DashboardProvider, UserProfileProvider>(builder:
                  (context, dashboardProvider, userProfileProvider, child) {
                final bool isAdminUser =
                    (userProfileProvider.userData.role != null &&
                            userProfileProvider.userData.role!.isNotEmpty &&
                            userProfileProvider.userData.role![0].name
                                    .toString()
                                    .toLowerCase() ==
                                "admin") &&
                        (isSuperAdmin || isPgAdmin || isAdmin);

                return Center(
                  child: Container(
                    padding: EdgeInsets.only(top: !isAdminUser ? 200 : 10),
                    child: Text(
                      "Please visit https://app.risksphere.ai/ and sign in with your credentials to upgrade your account.",
                      style: typography.Body1.copyWith(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                          color: Color(0xFFFDBE71)),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

Widget _buildBasicPackageCard(
  BuildContext context,
  AccountListProvider pricingProvider,
) {
  double totalYearlyPrice = 0;
  for (var plan in pricingProvider.pricingList) {
    if (plan.rangeYear == null || plan.rangeYear!.isEmpty) {
      continue;
    }

    if (plan.planName == "Event Count Cost") {
      for (var event in plan.rangeYear!) {
        totalYearlyPrice += (event.rangePrice ?? 0).toDouble();
      }
    } else {
      totalYearlyPrice += (plan.rangeYear!.first.rangePrice ?? 0).toDouble();
    }
  }

  return Card(
    elevation: 2,
    color: const Color(0xFF99CCFF),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(1, 1, 2, 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: const Text(
              "Basic Package",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Get full access to all RiskSphere licenses and features.",
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 20),
                ...pricingProvider.pricingList.map(
                  (plan) {
                    // Event Count Cost Special Handling
                    if (plan.planName == "Event Count Cost") {
                      return Column(
                        children: (plan.rangeYear ?? []).map((event) {
                          String description = "";

                          if (event.hazardNameLabel == "Hurricane") {
                            description = event.hazardNameLabel!;
                          } else if (event.hazardNameLabel == "Earthquake") {
                            description = event.hazardNameLabel!;
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        event.vendorNameLabel ?? "",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      (int.tryParse(event.endCount ?? "0") ?? 0)
                                          .toString()
                                          .padLeft(2, '0'),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    }

                    final yearly = plan.rangeYear?.first;
                    String description = "";

                    if (plan.planName == "Hazard Hub") {
                      description = "Hazard scoring, profiles, lookups & data";
                    } else if (plan.planName == "Location Processing") {
                      description = "Geocoding, hazard and Data Completeness";
                    } else if (plan.planName == "User License") {
                      description =
                          "User License for adding users in your corporate account";
                    } else if (plan.planName == "Location Improvement Cost") {
                      description = "Edit Locations and add Campus.";
                    } else if (plan.planName == "Hurricane") {
                      description =
                          "Understand wind, surge, and storm-related risks.";
                    } else if (plan.planName == "Earthquake") {
                      description =
                          "Evaluate seismic exposure across your portfolio.";
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  plan.planName ?? "",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Container(
                                width: 34,
                                height: 24,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2D3E52),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFF60758C),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  (int.parse(yearly?.endCount) ?? 0)
                                      .toInt()
                                      .toString()
                                      .padLeft(2, '0'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              )
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Divider(
                  color: Colors.white.withOpacity(.15),
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Text(
                      "\$${totalYearlyPrice.toStringAsFixed(0)}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      " /Year",
                      style: TextStyle(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                Text("All licenses included - Maximum value"),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      double total = 0;

                      List<String> titles = [];
                      List<String> displayTitles = [];
                      List<String> planIds = [];
                      List<String> userCounts = [];
                      List<String> licensePrices = [];
                      List<String> planTypes = [];
                      List<String> selectedPlanType = [];
                      List<String> pricePerUser = [];
                      List<String> vendors = [];
                      List<String> eventTypes = [];

                      for (var plan in pricingProvider.pricingList) {
                        print("PLAN => ${plan.planName}");

                        if (plan.rangeYear == null || plan.rangeYear!.isEmpty) {
                          print("SKIPPED => ${plan.planName}");
                          continue;
                        }

                        // Event Plans
                        if ((plan.planName ?? "").contains("Event")) {
                          print("EVENT PLAN FOUND => ${plan.planName}");

                          for (var event in plan.rangeYear!) {
                            total += (event.rangePrice ?? 0).toDouble();

                            titles.add(plan.planName ?? "");
                            displayTitles.add(event.hazardNameLabel ?? "");
                            vendors.add(event.vendorNameLabel ?? "");
                            eventTypes.add(event.hazardNameLabel ?? "");
                            planIds.add(plan.planId ?? "");

                            userCounts.add(
                              "${event.startCount}-${event.endCount}",
                            );

                            licensePrices.add(
                              event.rangePrice.toString(),
                            );

                            planTypes.add(
                              plan.planType ?? "",
                            );

                            selectedPlanType.add("Yearly");

                            pricePerUser.add(
                              event.pricePerUser ?? "0",
                            );

                            print(
                              "Added Event => ${event.vendorNameLabel} | ${event.hazardNameLabel}",
                            );
                          }

                          continue;
                        }

                        final yearly = plan.rangeYear!.first;

                        total += (yearly.rangePrice ?? 0).toDouble();

                        titles.add(
                          plan.planName ?? "",
                        );

                        displayTitles.add(
                          plan.planName ?? "",
                        );

                        vendors.add(""); // ADD THIS

                        eventTypes.add(""); // ADD THIS

                        planIds.add(
                          plan.planId ?? "",
                        );

                        userCounts.add(
                          "${yearly.startCount}-${yearly.endCount}",
                        );

                        licensePrices.add(
                          yearly.rangePrice.toString(),
                        );

                        planTypes.add(
                          plan.planType ?? "",
                        );

                        selectedPlanType.add(
                          "Yearly",
                        );

                        pricePerUser.add(
                          yearly.pricePerUser ?? "0",
                        );

                        print("Added Normal Plan => ${plan.planName}");
                      }

                      final summary = {
                        "total": total,
                        "titles": titles,
                        "displayTitles": displayTitles,
                        "planId": planIds,
                        "usercount": userCounts,
                        "licenseprice": licensePrices,
                        "planType": planTypes,
                        "selectedPlanType": selectedPlanType,
                        "priceperuser": pricePerUser,
                        "vendors": vendors,
                        "eventTypes": eventTypes,
                      };

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PricingSummary(
                            statusflag: "basic",
                            title: titles,
                            summary: summary,
                            hazardName: "",
                            vendorName: "",
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF99CCFF),
                    ),
                    child: const Text(
                      "Purchase",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                )
                // SizedBox(
                //   width: double.infinity,
                //   height: 50,
                //   child: ElevatedButton(
                //     onPressed: () {
                //       double total = 0;
                //
                //       List<String> titles = [];
                //       List<String> displayTitles = [];
                //       List<String> planIds = [];
                //       List<String> userCounts = [];
                //       List<String> licensePrices = [];
                //       List<String> planTypes = [];
                //       List<String> selectedPlanType = [];
                //       List<String> pricePerUser = [];
                //       List<String> vendors = [];
                //       List<String> eventTypes = [];
                //
                //       for (var plan in pricingProvider.pricingList) {
                //         if (plan.rangeYear == null || plan.rangeYear!.isEmpty) {
                //           continue;
                //         }
                //
                //         // Event Count Cost
                //         if (plan.planName == "Event Count Cost") {
                //           for (var event in plan.rangeYear!) {
                //             total += (event.rangePrice ?? 0).toDouble();
                //
                //             // For API
                //             titles.add(
                //               plan.planName ?? "",
                //             );
                //
                //             // For UI
                //             displayTitles.add(
                //               event.hazardNameLabel ?? "",
                //             );
                //
                //             vendors.add(
                //               event.vendorNameLabel ?? "",
                //             );
                //
                //             eventTypes.add(
                //               event.hazardNameLabel ?? "",
                //             );
                //
                //             planIds.add(
                //               plan.planId ?? "",
                //             );
                //
                //             userCounts.add(
                //               "${event.startCount}-${event.endCount}",
                //             );
                //
                //             licensePrices.add(
                //               event.rangePrice.toString(),
                //             );
                //
                //             planTypes.add(
                //               plan.planType ?? "",
                //             );
                //
                //             selectedPlanType.add(
                //               "Yearly",
                //             );
                //
                //             pricePerUser.add(
                //               event.pricePerUser ?? "0",
                //             );
                //           }
                //
                //           continue;
                //         }
                //
                //         final yearly = plan.rangeYear!.first;
                //
                //         total += (yearly.rangePrice ?? 0).toDouble();
                //         planTypes.add(
                //           plan.planType ?? "",
                //         );
                //
                //         selectedPlanType.add(
                //           "Yearly",
                //         );
                //
                //         pricePerUser.add(
                //           yearly.pricePerUser ?? "0",
                //         );
                //       }
                //
                //       final summary = {
                //         "total": total,
                //         "titles": titles,
                //         "displayTitles": displayTitles,
                //         "planId": planIds,
                //         "usercount": userCounts,
                //         "licenseprice": licensePrices,
                //         "planType": planTypes,
                //         "selectedPlanType": selectedPlanType,
                //         "priceperuser": pricePerUser,
                //         "vendors": vendors,
                //         "eventTypes": eventTypes,
                //       };
                //
                //       print("displayTitles => $displayTitles");
                //       print("vendors => $vendors");
                //       print("eventTypes => $eventTypes");
                //
                //       Navigator.push(
                //         context,
                //         MaterialPageRoute(
                //           builder: (_) => PricingSummary(
                //             statusflag: "basic",
                //             title: titles,
                //             summary: summary,
                //             hazardName: "",
                //             vendorName: "",
                //           ),
                //         ),
                //       );
                //     },
                //     style: ElevatedButton.styleFrom(
                //       backgroundColor: const Color(0xFF99CCFF),
                //     ),
                //     child: const Text(
                //       "Purchase ",
                //       style: TextStyle(
                //         fontSize: 18,
                //         color: Colors.black87,
                //       ),
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _ChatbotBottomSheet extends StatefulWidget {
  _ChatbotBottomSheet();

  @override
  State<_ChatbotBottomSheet> createState() => _ChatbotBottomSheetState();
}

class _ChatbotBottomSheetState extends State<_ChatbotBottomSheet> {
  bool _isFullScreen = false;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Padding(
      padding: MediaQuery.of(context).viewInsets,
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
              child: _ChatbotContent(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatbotContent extends StatefulWidget {
  _ChatbotContent();

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

  @override
  void initState() {
    super.initState();
    _sessionId = const Uuid().v4();
    messages.add({
      "isBot": true,
      "text":
          "Hi, I'm RiskBuddy. I can help with package selection, explain pricing, and guide you through checkout. Ask me about plan differences, billing cycles, or how bundle discounts work.",
    });
    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
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
    if (_controller.text.trim().isEmpty) return;
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
      final reply = await provider.sendChatPurchaseMessage(
        context: context,
        message: userMessage,
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
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
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
