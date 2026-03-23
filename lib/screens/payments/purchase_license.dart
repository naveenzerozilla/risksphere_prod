import 'package:easy_localization/easy_localization.dart';

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

          // selection.selectedPlanType
          for (var selection in cardSelections.values) {
            if (selection.totalPrice != null) {
              // total += num.parse(selection.totalPrice.toString());
              total +=
                  num.tryParse(selection.totalPrice?.toString() ?? '0') ?? 0;

              if (selection.title != null && selection.title!.isNotEmpty) {
                titles.add(selection.title!);
              }
              if (selection.planId != null && selection.planId!.isNotEmpty) {
                planId.add(selection.planId!);
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
                licensePrice.add(selection.licensePrice!);
              } else if (selection.licensePrice != null &&
                  selection.licensePrice!.isNotEmpty) {
                licensePrice.add(selection.licensePrice!);
              }

              if (selection.planType != null &&
                  selection.planType!.isNotEmpty) {
                planTypes.add(selection.planType!);
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
            bottomNavigationBar: Consumer<AccountListProvider>(
                builder: (context, pricingProvider, child) {
              return pricingProvider.isLoading ||
                      pricingProvider.pricingList.isEmpty
                  ? Container(
                      height: 10,
                    )
                  : Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(),
                      child: Platform.isIOS
                          ? Container(height: 10)
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SizedBox(height: 10),
                                getSummary()['total'] == 0
                                    ? Container(height: 0)
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Total Pricing',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            '\$${getSummary()['total'].toStringAsFixed(2)}',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: () {
                                    final summary = getSummary();
                                    final titles = List<String>.from(
                                        summary['titles'] ?? []);
                                    if (titles.isEmpty) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                          "Please select at least one subscription plan.",
                                        )),
                                      );
                                      return;
                                    }
                                    print(summary);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PricingSummary(
                                          title: titles,
                                          summary: summary,
                                          hazardName: hazardName ?? "",
                                          vendorName: vendorName ?? "",
                                        ),
                                      ),
                                    ).then((value) {
                                      if (value == false) {
                                      } else {
                                        _getData();
                                        setState(() {
                                          cardSelections.clear();
                                          expandedCardIndex = null;
                                        });
                                      }
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF99CCFF),
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Next',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black,
                                          fontSize: 16,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(Icons.arrow_forward_ios,
                                          color: Colors.black, size: 16),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                    );
            }),
            body: Consumer<AccountListProvider>(
              builder: (context, pricingProvider, child) {
                var typography = CustomTypography(context);
                return pricingProvider.isLoading
                    ? Center(
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
                            padding: EdgeInsets.all(0), // optional for spacing
                            child: Column(
                              children: [
                                SizedBox(height: CustomSpacing.three),
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHigh,
                                    borderRadius: BorderRadius.circular(
                                        12), // Rounded corners
                                  ),
                                  child: Text(
                                    "Bring your business to the safest at scale",
                                    style: typography.Body1.copyWith(
                                        fontWeight: FontWeight.w400,
                                        fontSize: 12,
                                        letterSpacing: 0.4,
                                        color: Colors.white),
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
                                Text(
                                  "Activate your platform license for a tailored experience.",
                                  textAlign: TextAlign.center,
                                  style: typography.Body1.copyWith(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: CustomSpacing.three),
                                Expanded(
                                  child: Card(
                                    margin:
                                        EdgeInsets.only(right: 18, left: 20),
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      side: BorderSide(
                                        color: Color(0xFF8A3A75),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.all(0),
                                      child: pricingProvider.isLoading
                                          ? Center(
                                              child:
                                                  CircularProgressIndicator())
                                          : ListView.builder(
                                              itemCount: pricingProvider
                                                  .pricingList.length,
                                              itemBuilder: (context, index) {
                                                Result item = pricingProvider
                                                    .pricingList[index];
                                                return Column(
                                                  children: [
                                                    index == 0
                                                        ? _buildSubscriptionHeaderCard()
                                                        : SizedBox(),
                                                    index == 0
                                                        ? SizedBox(
                                                            height:
                                                                CustomSpacing
                                                                    .four)
                                                        : Container(),
                                                    Consumer<
                                                        UserProfileProvider>(
                                                      builder: (context,
                                                          userProfileProvider,
                                                          child) {
                                                        bool isNotIndividual =
                                                            (userProfileProvider
                                                                    .userData
                                                                    .isIndividual ??
                                                                true);

                                                        if (item.planName ==
                                                                "User License" &&
                                                            isNotIndividual) {
                                                          return AbsorbPointer(
                                                              absorbing: true,
                                                              child:
                                                                  Container());
                                                        }
                                                        return _buildSubscriptionCard(
                                                            item, index);
                                                      },
                                                    ),
                                                  ],
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
          ),
        );
      }),
    );
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

  void _onSearchChanged(String query, StateSetter setState, String type) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.isNotEmpty) {
        this.setState(() => _isSearching = true); // ✅ use this.setState

        final results = await fetchAutocompleteUsers(
          query.trim().toLowerCase(),
          type,
        );

        this.setState(() {
          // ✅ use this.setState
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
          // ✅ use this.setState
          _autocompleteUsersList.clear();
          _isSearching = false;
        });
      }
    });
  }

  Widget _buildSubscriptionCard(Result item, int index) {
    var typography = CustomTypography(context);
    bool isExpanded = expandedCardIndex == index;
    DateTime? selectedDate;
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
    final filteredRanges = selectedRangeList
        .where((range) => range.vendorNameLabel == vendorName)
        .toList();
    // Helper function to get price based on plan type
    Map<String, dynamic> getPriceData(
        Map<String, dynamic> vendor, String planType) {
      final rangePrice = vendor['range_price'] ?? 0;

      if (planType == 'Monthly') {
        return {
          'range_month': rangePrice,
          'range_year': rangePrice * 12,
        };
      } else {
        return {
          'range_month': (rangePrice / 12).round(),
          'range_year': rangePrice,
        };
      }
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          expandedCardIndex = expandedCardIndex == index ? null : index;
        });
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(22, 0, 22, 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Consumer2<DashboardProvider, UserProfileProvider>(
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
                    // Text(isSuperAdmin.toString()),

                    // ─── Share Location section (hide for Admin) ───
                    if (isAdminUser && index == 0) ...[
                      // ✅ THIS IS THE FIX
                      Text(
                        'Share Location',
                        style: typography.Body1.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ─── Search User TextField ───
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
                          labelStyle: const TextStyle(color: Colors.white54),
                          hintText: 'Choose a user to share locations with',
                          hintStyle: const TextStyle(color: Colors.white38),
                          prefixIcon:
                              const Icon(Icons.search, color: Colors.white54),
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

                      // ─── Selected Users Chips ───
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
                                    color: AppColors.primaryMain, width: 0.8),
                                label: Text(
                                  user.email ?? user.name ?? '',
                                  style: TextStyle(
                                    color: AppColors.primaryMain,
                                    fontSize: 13,
                                  ),
                                ),
                                deleteIcon: const Icon(Icons.close, size: 14),
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

                      // ─── Suggestions Dropdown ───
                      if (_autocompleteUsersList.isNotEmpty)
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                            border: Border.all(color: Colors.white24, width: 1),
                          ),
                          constraints: const BoxConstraints(maxHeight: 280),
                          child: ListView.separated(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            itemCount: _autocompleteUsersList.length,
                            separatorBuilder: (_, __) =>
                                const Divider(color: Colors.white12, height: 1),
                            itemBuilder: (context, i) {
                              final user = _autocompleteUsersList[i];
                              final bool isSelected = _selectedUsers
                                  .any((u) => u.email == user.email);

                              String getInitials(String? name) {
                                if (name == null || name.isEmpty) return 'U';
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
                                                color: Colors.white, size: 14)
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
                          labelStyle: const TextStyle(color: Colors.white54),
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
                          labelStyle: const TextStyle(color: Colors.white54),
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

                      // ─── Share Now Button ───
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
                                          _expireDateController.text.trim()) ??
                                      0;

                                  if (emails.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Please select at least one user.'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }
                                  if (credits <= 0) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Please enter a valid location count.'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }
                                  if (expireDays <= 0) {
                                    ScaffoldMessenger.of(context).showSnackBar(
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
                              : const Icon(Icons.share, color: Colors.black87),
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
                      const SizedBox(height: 12),

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
                          icon:
                              Icon(Icons.history, color: AppColors.primaryMain),
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
                    ],
                  ],
                );
              },
            ),
            // Consumer2<DashboardProvider, UserProfileProvider>(
            //   builder:
            //       (context, dashboardProvider, userProfileProvider, child) {
            //     final bool isAdminUser = (userProfileProvider.userData.role !=
            //                 null &&
            //             userProfileProvider.userData.role!.isNotEmpty &&
            //             userProfileProvider.userData.role![0].name.toString().toLowerCase() ==
            //                 "admin") &&
            //         (isSuperAdmin || isPgAdmin || isAdmin);
            //
            //     return Column(
            //       mainAxisAlignment: MainAxisAlignment.start,
            //       crossAxisAlignment: CrossAxisAlignment.start,
            //       children: [
            //         // ─── Share Location section (hide for Admin) ───
            //         if (index == 0) ...[
            //           Text(
            //             'Share Location',
            //             style: typography.Body1.copyWith(
            //               color: Colors.white,
            //               fontWeight: FontWeight.w600,
            //               fontSize: 22,
            //             ),
            //           ),
            //           const SizedBox(height: 20),
            //
            //           // ─── Search User TextField ───
            //           TextField(
            //             controller: _userSearchController,
            //             style: const TextStyle(color: Colors.white),
            //             onChanged: (value) {
            //               _onSearchChanged(
            //                 value,
            //                 this.setState,
            //                 // ✅ pass widget's setState, not Consumer2's
            //                 _selectedOption.name,
            //               );
            //             },
            //             decoration: InputDecoration(
            //               labelText: "Search User",
            //               labelStyle: const TextStyle(color: Colors.white54),
            //               hintText: 'Choose a user to share locations with',
            //               hintStyle: const TextStyle(color: Colors.white38),
            //               prefixIcon:
            //                   const Icon(Icons.search, color: Colors.white54),
            //               suffixIcon: _isSearching
            //                   ? const Padding(
            //                       padding: EdgeInsets.all(12),
            //                       child: SizedBox(
            //                         width: 18,
            //                         height: 18,
            //                         child: CircularProgressIndicator(
            //                           strokeWidth: 2,
            //                           color: Colors.white54,
            //                         ),
            //                       ),
            //                     )
            //                   : null,
            //               enabledBorder: OutlineInputBorder(
            //                 borderRadius: _autocompleteUsersList.isNotEmpty
            //                     ? const BorderRadius.only(
            //                         topLeft: Radius.circular(12),
            //                         topRight: Radius.circular(12),
            //                       )
            //                     : BorderRadius.circular(12),
            //                 borderSide: const BorderSide(
            //                     color: Colors.white24, width: 1),
            //               ),
            //               focusedBorder: OutlineInputBorder(
            //                 borderRadius: _autocompleteUsersList.isNotEmpty
            //                     ? const BorderRadius.only(
            //                         topLeft: Radius.circular(12),
            //                         topRight: Radius.circular(12),
            //                       )
            //                     : BorderRadius.circular(12),
            //                 borderSide: BorderSide(
            //                     color: AppColors.primaryMain, width: 1.5),
            //               ),
            //               filled: true,
            //               fillColor: const Color(0xFF1E1E1E),
            //               contentPadding: const EdgeInsets.symmetric(
            //                   horizontal: 16, vertical: 14),
            //             ),
            //           ),
            //
            //           // ─── Selected Users Chips ───
            //           if (_selectedUsers.isNotEmpty)
            //             Padding(
            //               padding: const EdgeInsets.only(top: 8),
            //               child: Wrap(
            //                 spacing: 8,
            //                 runSpacing: 6,
            //                 children: _selectedUsers.map((user) {
            //                   return Chip(
            //                     backgroundColor:
            //                         AppColors.primaryMain.withOpacity(0.15),
            //                     side: BorderSide(
            //                         color: AppColors.primaryMain, width: 0.8),
            //                     label: Text(
            //                       user.email ?? user.name ?? '',
            //                       style: TextStyle(
            //                         color: AppColors.primaryMain,
            //                         fontSize: 13,
            //                       ),
            //                     ),
            //                     deleteIcon: const Icon(Icons.close, size: 14),
            //                     deleteIconColor: AppColors.primaryMain,
            //                     onDeleted: () {
            //                       this.setState(() {
            //                         _selectedUsers.remove(user);
            //                       });
            //                     },
            //                   );
            //                 }).toList(),
            //               ),
            //             ),
            //
            //           if (_autocompleteUsersList.isNotEmpty)
            //             Container(
            //               decoration: BoxDecoration(
            //                 color: const Color(0xFF1E1E1E),
            //                 borderRadius: const BorderRadius.only(
            //                   bottomLeft: Radius.circular(12),
            //                   bottomRight: Radius.circular(12),
            //                 ),
            //                 border: Border.all(color: Colors.white24, width: 1),
            //               ),
            //               constraints: const BoxConstraints(maxHeight: 280),
            //               child: ListView.separated(
            //                 shrinkWrap: true,
            //                 padding: EdgeInsets.zero,
            //                 itemCount: _autocompleteUsersList.length,
            //                 separatorBuilder: (_, __) =>
            //                     const Divider(color: Colors.white12, height: 1),
            //                 itemBuilder: (context, i) {
            //                   final user = _autocompleteUsersList[i];
            //                   final bool isSelected = _selectedUsers
            //                       .any((u) => u.email == user.email);
            //
            //                   String getInitials(String? name) {
            //                     if (name == null || name.isEmpty) return 'U';
            //                     final parts = name.trim().split(' ');
            //                     if (parts.length >= 2) {
            //                       return '${parts[0][0]}${parts[1][0]}'
            //                           .toUpperCase();
            //                     }
            //                     return parts[0][0].toUpperCase();
            //                   }
            //
            //                   return InkWell(
            //                     onTap: () {
            //                       this.setState(() {
            //                         _selectedUsers.clear();
            //                         _selectedUsers.add(user);
            //                         _autocompleteUsersList.clear();
            //                         _userSearchController.clear();
            //                       });
            //                     },
            //                     child: Padding(
            //                       padding: const EdgeInsets.symmetric(
            //                           horizontal: 12, vertical: 10),
            //                       child: Row(
            //                         children: [
            //                           Container(
            //                             width: 22,
            //                             height: 22,
            //                             decoration: BoxDecoration(
            //                               color: isSelected
            //                                   ? AppColors.primaryMain
            //                                   : Colors.transparent,
            //                               border: Border.all(
            //                                 color: isSelected
            //                                     ? AppColors.primaryMain
            //                                     : Colors.white54,
            //                                 width: 1.5,
            //                               ),
            //                               borderRadius:
            //                                   BorderRadius.circular(4),
            //                             ),
            //                             child: isSelected
            //                                 ? const Icon(Icons.check,
            //                                     color: Colors.white, size: 14)
            //                                 : null,
            //                           ),
            //                           const SizedBox(width: 10),
            //                           CircleAvatar(
            //                             radius: 22,
            //                             backgroundColor: Colors.grey[600],
            //                             child: Text(
            //                               getInitials(user.name),
            //                               style: const TextStyle(
            //                                 color: Colors.white,
            //                                 fontWeight: FontWeight.w600,
            //                                 fontSize: 13,
            //                               ),
            //                             ),
            //                           ),
            //                           const SizedBox(width: 12),
            //                           Expanded(
            //                             child: Column(
            //                               crossAxisAlignment:
            //                                   CrossAxisAlignment.start,
            //                               children: [
            //                                 Text(
            //                                   user.name ?? '',
            //                                   style: const TextStyle(
            //                                     color: Colors.white,
            //                                     fontWeight: FontWeight.w500,
            //                                     fontSize: 15,
            //                                   ),
            //                                 ),
            //                                 Text(
            //                                   user.email ?? '',
            //                                   style: TextStyle(
            //                                     color: (user.email ?? '')
            //                                             .toLowerCase()
            //                                             .contains(
            //                                                 _userSearchController
            //                                                     .text
            //                                                     .trim()
            //                                                     .toLowerCase())
            //                                         ? AppColors.primaryMain
            //                                         : Colors.white54,
            //                                     fontSize: 13,
            //                                   ),
            //                                 ),
            //                               ],
            //                             ),
            //                           ),
            //                         ],
            //                       ),
            //                     ),
            //                   );
            //                 },
            //               ),
            //             ),
            //           const SizedBox(height: 16),
            //           TextField(
            //             controller: locationCountController,
            //             keyboardType: TextInputType.number,
            //             inputFormatters: [
            //               FilteringTextInputFormatter.digitsOnly,
            //               // ✅ only positive integers
            //             ],
            //             style: const TextStyle(color: Colors.white),
            //             decoration: InputDecoration(
            //               labelText: 'Location Count',
            //               labelStyle: const TextStyle(color: Colors.white54),
            //               hintText: 'Enter the number of Locations',
            //               hintStyle: const TextStyle(color: Colors.white38),
            //               enabledBorder: OutlineInputBorder(
            //                 borderRadius: BorderRadius.circular(12),
            //                 borderSide: const BorderSide(
            //                     color: Colors.white24, width: 1),
            //               ),
            //               focusedBorder: OutlineInputBorder(
            //                 borderRadius: BorderRadius.circular(12),
            //                 borderSide: BorderSide(
            //                     color: AppColors.primaryMain, width: 1.5),
            //               ),
            //               filled: true,
            //               fillColor: const Color(0xFF1E1E1E),
            //               contentPadding: const EdgeInsets.symmetric(
            //                   horizontal: 16, vertical: 14),
            //             ),
            //           ),
            //           const SizedBox(height: 16),
            //
            //           TextField(
            //             controller: _expireDateController,
            //             keyboardType: TextInputType.number,
            //             inputFormatters: [
            //               FilteringTextInputFormatter.digitsOnly,
            //               // ✅ only positive integers
            //             ],
            //             style: const TextStyle(color: Colors.white),
            //             decoration: InputDecoration(
            //               labelText: 'Expire Days',
            //               labelStyle: const TextStyle(color: Colors.white54),
            //               hintText: 'Enter number of expire days',
            //               hintStyle: const TextStyle(color: Colors.white38),
            //               enabledBorder: OutlineInputBorder(
            //                 borderRadius: BorderRadius.circular(12),
            //                 borderSide: const BorderSide(
            //                     color: Colors.white24, width: 1),
            //               ),
            //               focusedBorder: OutlineInputBorder(
            //                 borderRadius: BorderRadius.circular(12),
            //                 borderSide: BorderSide(
            //                     color: AppColors.primaryMain, width: 1.5),
            //               ),
            //               filled: true,
            //               fillColor: const Color(0xFF1E1E1E),
            //               contentPadding: const EdgeInsets.symmetric(
            //                   horizontal: 16, vertical: 14),
            //             ),
            //           ),
            //           const SizedBox(height: 28),
            //
            //           // ─── Share Now Button ───
            //           SizedBox(
            //             width: double.infinity,
            //             height: 52,
            //             child: ElevatedButton.icon(
            //               onPressed: _isSharing
            //                   ? null
            //                   : () async {
            //                       final emails = _selectedUsers
            //                           .map((u) => u.email ?? '')
            //                           .where((e) => e.isNotEmpty)
            //                           .join(',');
            //                       final credits = int.tryParse(
            //                               locationCountController.text
            //                                   .trim()) ??
            //                           0;
            //                       final expireDays = int.tryParse(
            //                               _expireDateController.text.trim()) ??
            //                           0;
            //
            //                       if (emails.isEmpty) {
            //                         ScaffoldMessenger.of(context).showSnackBar(
            //                           const SnackBar(
            //                             content: Text(
            //                                 'Please select at least one user.'),
            //                             backgroundColor: Colors.red,
            //                           ),
            //                         );
            //                         return;
            //                       }
            //                       if (credits <= 0) {
            //                         ScaffoldMessenger.of(context).showSnackBar(
            //                           const SnackBar(
            //                             content: Text(
            //                                 'Please enter a valid location count.'),
            //                             backgroundColor: Colors.red,
            //                           ),
            //                         );
            //                         return;
            //                       }
            //                       if (expireDays <= 0) {
            //                         ScaffoldMessenger.of(context).showSnackBar(
            //                           const SnackBar(
            //                             content: Text(
            //                                 'Please enter valid expire days.'),
            //                             backgroundColor: Colors.red,
            //                           ),
            //                         );
            //                         return;
            //                       }
            //
            //                       setState(() => _isSharing = true);
            //
            //                       await Provider.of<AccountListProvider>(
            //                               context,
            //                               listen: false)
            //                           .shareLocation(
            //                         context,
            //                         recipientEmails: emails,
            //                         credits: credits,
            //                         expireDays: expireDays,
            //                         message: "",
            //                       );
            //
            //                       setState(() {
            //                         _isSharing = false;
            //                         _selectedUsers.clear();
            //                         locationCountController.clear();
            //                         _expireDateController.clear();
            //                         _userSearchController.clear();
            //                       });
            //                     },
            //               icon: _isSharing
            //                   ? const SizedBox(
            //                       width: 18,
            //                       height: 18,
            //                       child: CircularProgressIndicator(
            //                         strokeWidth: 2,
            //                         color: Colors.black87,
            //                       ),
            //                     )
            //                   : const Icon(Icons.share, color: Colors.black87),
            //               label: Text(
            //                 _isSharing ? 'Sharing...' : 'Share Now',
            //                 style: const TextStyle(
            //                   color: Colors.black87,
            //                   fontWeight: FontWeight.w600,
            //                   fontSize: 16,
            //                 ),
            //               ),
            //               style: ElevatedButton.styleFrom(
            //                 backgroundColor: _isSharing
            //                     ? AppColors.primaryMain.withOpacity(0.6)
            //                     : AppColors.primaryMain,
            //                 shape: RoundedRectangleBorder(
            //                   borderRadius: BorderRadius.circular(14),
            //                 ),
            //                 elevation: 0,
            //               ),
            //             ),
            //           ),
            //           const SizedBox(height: 12),
            //
            //           // ─── Manage Button ───
            //           SizedBox(
            //             width: double.infinity,
            //             height: 52,
            //             child: OutlinedButton.icon(
            //               onPressed: () {
            //                 Navigator.push(
            //                     context,
            //                     MaterialPageRoute(
            //                         builder: (context) =>
            //                             LocationManagementScreen()));
            //               },
            //               icon:
            //                   Icon(Icons.history, color: AppColors.primaryMain),
            //               label: Text(
            //                 'Manage',
            //                 style: TextStyle(
            //                   color: AppColors.primaryMain,
            //                   fontWeight: FontWeight.w600,
            //                   fontSize: 16,
            //                 ),
            //               ),
            //               style: OutlinedButton.styleFrom(
            //                 side: BorderSide(
            //                     color: AppColors.primaryMain, width: 1.5),
            //                 shape: RoundedRectangleBorder(
            //                   borderRadius: BorderRadius.circular(14),
            //                 ),
            //               ),
            //             ),
            //           ),
            //         ],
            //       ],
            //     );
            //   },
            // ),
            const SizedBox(height: 12),
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
                                ? Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          "SOV Sharing at Zero Cost",
                                          maxLines: 2,
                                          style: typography.Body1.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF99CCFF),
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        "\$0",
                                        style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800),
                                      )
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
                        Icon(
                          isExpanded
                              ? Icons.arrow_drop_up
                              : Icons.arrow_drop_down_circle_outlined,
                          color: Colors.white,
                          size: 28,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ReadMoreText(
                            text: item.description ?? "Default description...",
                            trimLines: 10,
                            colorClickableText: Colors.blueAccent,
                            trimCollapsedText: 'Read more',
                            trimExpandedText: 'Show less',
                            style: typography.Body1.copyWith(
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                              color: Colors.white,
                            ),
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
                    ] else if (isExpanded) ...[
                      const SizedBox(height: 16),
                      item.planName == "Event Count Cost"
                          ? DropdownButtonFormField<String>(
                              value: selection.selectedPlanType,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                filled: true,
                                labelText: "Subscription Type",
                              ),
                              hint: const Text("Subscription Type"),
                              items: [
                                if (item.rangeMonth != null &&
                                    item.rangeMonth!.isNotEmpty)
                                  DropdownMenuItem<String>(
                                    value: 'Monthly',
                                    child: Text('Monthly'),
                                  ),
                                if (item.rangeYear != null &&
                                    item.rangeYear!.isNotEmpty)
                                  DropdownMenuItem<String>(
                                    value: 'Yearly',
                                    child: Text('Yearly'),
                                  ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  print(value);
                                  print("value");
                                  setState(() {
                                    selection.selectedPlanType = value;

                                    item.planName == "Event Count Cost"
                                        ? selection.title = "Event Count Cost"
                                        : "";
                                    item.planName == "Event Count Cost"
                                        ? selection.planId = item.planId!
                                        : '';
                                    item.planName == "Event Count Cost"
                                        ? selection.planType = item.planType!
                                        : '';
                                    // item.planName == "Event Count Cost"
                                    //     ? value == 'Monthly'
                                    //         ? selection.priceperuser =
                                    //             item.rangeMonth![0].pricePerUser
                                    //         : selection.priceperuser =
                                    //             item.rangeYear![0].pricePerUser
                                    //     : "";
                                    // item.planName == "Event Count Cost"
                                    //     ? value == 'Monthly'
                                    //         ? selection.licensePrice =
                                    //             item.rangeMonth![0].pricePerUser
                                    //         : selection.priceperuser =
                                    //             item.rangeYear![0].pricePerUser
                                    //     : "";
                                    // selection.userCount = item.planName ==
                                    //         "Event Count Cost"
                                    //     ? (value == 'Monthly'
                                    //         ? '${item.rangeMonth![0].startCount}-${item.rangeMonth![0].endCount}'
                                    //         : '${item.rangeYear![0].startCount}-${item.rangeYear![0].endCount}')
                                    //     : selection.userCount;
                                  });
                                }
                              },
                            )
                          : DropdownButtonFormField<String>(
                              value: selection.selectedPlanType,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                filled: true,
                                labelText: "Subscription Type",
                              ),
                              hint: const Text("Subscription Type"),
                              items: [
                                if (item.rangeMonth != null &&
                                    item.rangeMonth!.isNotEmpty)
                                  DropdownMenuItem<String>(
                                    value: 'Monthly',
                                    child: Text('Monthly'),
                                  ),
                                if (item.rangeYear != null &&
                                    item.rangeYear!.isNotEmpty)
                                  DropdownMenuItem<String>(
                                    value: 'Yearly',
                                    child: Text('Yearly'),
                                  ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  print(value);
                                  print("value");
                                  setState(() {
                                    selection.selectedPlanType = value;
                                    selection.selectedUserCount = '1-1';
                                    selection.totalPrice = null;

                                    item.planName == "Event Count Cost"
                                        ? value == 'Monthly'
                                            ? selection.totalPrice =
                                                item.rangeMonth![0].rangePrice
                                            : selection.totalPrice =
                                                item.rangeYear![0].rangePrice
                                        : "";
                                    item.planName == "Event Count Cost"
                                        ? selection.title = "Event Count Cost"
                                        : "";
                                    item.planName == "Event Count Cost"
                                        ? selection.planId = item.planId!
                                        : '';
                                    item.planName == "Event Count Cost"
                                        ? selection.planType = item.planType!
                                        : '';
                                    item.planName == "Event Count Cost"
                                        ? value == 'Monthly'
                                            ? selection.priceperuser =
                                                item.rangeMonth![0].pricePerUser
                                            : selection.priceperuser =
                                                item.rangeYear![0].pricePerUser
                                        : "";
                                    item.planName == "Event Count Cost"
                                        ? value == 'Monthly'
                                            ? selection.licensePrice =
                                                item.rangeMonth![0].pricePerUser
                                            : selection.priceperuser =
                                                item.rangeYear![0].pricePerUser
                                        : "";
                                    selection.userCount = item.planName ==
                                            "Event Count Cost"
                                        ? (value == 'Monthly'
                                            ? '${item.rangeMonth![0].startCount}-${item.rangeMonth![0].endCount}'
                                            : '${item.rangeYear![0].startCount}-${item.rangeYear![0].endCount}')
                                        : selection.userCount;
                                  });
                                }
                              },
                            ),
                      const SizedBox(height: 16),
                      item.planName == "Event Count Cost"
                          ? SizedBox()
                          : DropdownButtonFormField<String>(
                              value: userCountOptions
                                      .contains(selection.selectedUserCount)
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
                                    selection.planType = item.planType ?? '';

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
                                        start.toString() + '-' + end.toString();

                                    print(
                                        'Selected Range → Start: $start, End: $end');
                                    print(selection.planType.toString());
                                    print(selection.priceperuser.toString());
                                    print(selectedRange.rangePrice.toString());

                                    int pricePerUser = int.tryParse(
                                            selectedRange.pricePerUser
                                                .toString()) ??
                                        0;
                                    print(pricePerUser.toString());
                                    selection.totalPrice =
                                        selectedRange.rangePrice.toString();
                                    print(totalPrice.toString());
                                    selection.licensePrice =
                                        selectedRange.rangePrice.toString();
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
                          padding: const EdgeInsets.symmetric(horizontal: 2.0),
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
                              labelStyle: const TextStyle(color: Colors.white),
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
                              if (!prev
                                  .any((e) => e.value == rangeItem.vendorId)) {
                                prev.add(DropdownMenuItem<String>(
                                  value: rangeItem.vendorId,
                                  child: Text(
                                    rangeItem.vendorNameLabel ?? 'Unknown',
                                    style: const TextStyle(color: Colors.white),
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

                                final selected = (rangeList
                                            ?.any((r) => r.vendorId == value) ??
                                        false)
                                    ? rangeList!
                                        .firstWhere((r) => r.vendorId == value)
                                    : null;

                                vendorName =
                                    selected?.vendorNameLabel ?? 'Unknown';
                                hazardName = selected?.hazardNameLabel ?? '';
                                item.planName == "Event Count Cost"
                                    ? selection.title = "Event Count Cost"
                                    : "";

                                print(
                                    "Selected Hazard: $selectedHazard, Name: $hazardName");
                                // Automatically set hazardName if vendor has only 1 hazard
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
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 2.0),
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
                                      .fold<List<DropdownMenuItem<String>>>([],
                                          (prev, rangeItem) {
                                    if (!prev.any(
                                        (e) => e.value == rangeItem.hazardId)) {
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

                                      vendorName = selected?.vendorNameLabel ??
                                          'Unknown';
                                      hazardName =
                                          selected?.hazardNameLabel ?? '';
                                      item.planName == "Event Count Cost"
                                          ? selection.title = "Event Count Cost"
                                          : "";

                                      print(
                                          "Selected Hazard: $selectedHazard, Name: $hazardName");

                                      if (selectedVendor != null) {
                                        final vendorData =
                                            vendorList.firstWhere(
                                          (v) =>
                                              v['vendor_id'] == selectedVendor,
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
                            ? SizedBox()
                            : Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 2.0),
                                child: DropdownButtonFormField<String>(
                                  value: selection.selectedUserCount != null &&
                                          userCountOptions.contains(
                                              selection.selectedUserCount)
                                      ? selection.selectedUserCount
                                      : null,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.grey[800],
                                    labelText: 'Select Locations',
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
                                              hazardName // filter by hazardName
                                          )
                                      .map((rangeItem) {
                                    return DropdownMenuItem<String>(
                                      value:
                                          '${rangeItem.startCount}-${rangeItem.endCount}',
                                      // Use this as value
                                      child: Text(
                                        '${rangeItem.startCount}-${rangeItem.endCount} Locations',
                                        style: const TextStyle(
                                            color: Colors.white),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      selection.selectedUserCount = value!;
                                      final selectedRange = (selection
                                                      .selectedPlanType
                                                      .toString() ==
                                                  "Yearly"
                                              ? item.rangeYear
                                              : item.rangeMonth)!
                                          .firstWhere(
                                        (range) =>
                                            '${range.startCount}-${range.endCount}' ==
                                                value &&
                                            range.hazardNameLabel == hazardName,
                                        // ensure hazardName match
                                        orElse: () => RangeYear(
                                          startCount: '0',
                                          endCount: '0',
                                          pricePerUser: "0",
                                          rangePrice: 0,
                                        ),
                                      );

                                      selection.selectedUserCount =
                                          '${selectedRange.startCount}-${selectedRange.endCount}';

                                      selection.planId = item.planId ?? '';
                                      selection.planType = item.planType ?? '';
                                      selection.title = item.planName ??
                                          "Location Count (Hazard)";

                                      int start = int.tryParse(
                                              selectedRange.startCount) ??
                                          0;
                                      int end = int.tryParse(
                                              selectedRange.endCount) ??
                                          0;
                                      int pricePerUser = int.tryParse(
                                              selectedRange.pricePerUser) ??
                                          0;

                                      selection.userCount = '${start}-${end}';
                                      selection.totalPrice =
                                          selectedRange.rangePrice.toString();
                                      selection.licensePrice =
                                          selectedRange.rangePrice.toString();
                                      selection.priceperuser =
                                          selectedRange.pricePerUser.toString();

                                      print(
                                          'Selected Range → Start: $start, End: $end');
                                      print('Price per user → $pricePerUser');
                                      print(
                                          'Total price → ${selectedRange.rangePrice}');
                                      print(
                                          'Total price → ${selection.totalPrice}');
                                      print(
                                          'Total price1 → ${selectedRange.pricePerUser}');
                                    });
                                  },
                                  validator: (value) {
                                    if (isEventCost &&
                                        (value == null || value.isEmpty)) {
                                      return 'Location is required';
                                    }
                                    return null;
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
        ),
      ),
    );
  }

  Widget _buildSubscriptionHeaderCard() {
    var typography = CustomTypography(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.amber,
        gradient: LinearGradient(
          colors: [
            Color.fromRGBO(120, 100, 117, 0.16),
            Color.fromRGBO(236, 118, 116, 0.07),
            Color.fromRGBO(253, 195, 123, 0.12),
          ],
        ),
      ),
      child: Card(
        color: Colors.transparent,
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {},
                child: Text(
                  "Risksphere Global License ",
                  style: typography.Body1.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 20,
                    color: Color(0xFFFDBE71),
                  ),
                ),
              ),
              SizedBox(height: CustomSpacing.three),
              GestureDetector(
                onTap: () {},
                child: Text(
                  "Risksphere Global License is applicable for the following",
                  style: typography.Body1.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
