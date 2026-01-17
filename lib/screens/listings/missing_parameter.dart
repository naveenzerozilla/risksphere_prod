import 'package:RiskSphere/screens/listings/udpate_parameter.dart';
import 'package:RiskSphere/screens/listings/widgets/auto_complete_options.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:tuple/tuple.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/global_imports.dart';
import 'package:flutter/cupertino.dart';
import 'package:RiskSphere/models/account_list_model.dart';

class MissingParameterScreen extends StatefulWidget {
  final String sovId;

  MissingParameterScreen({Key? key, required this.sovId}) : super(key: key);

  @override
  State<MissingParameterScreen> createState() => _MissingParameterScreenState();
}

class _MissingParameterScreenState extends State<MissingParameterScreen>
    with TickerProviderStateMixin {
  /// 🔥 HazardHub multi-selection state
  final Set<String> selectedHazardLocationIds = {};

  /// cache visible list for checkbox logic
  List<Data> _cachedFilteredItems = [];

  bool get hasHazardSelection => selectedHazardLocationIds.isNotEmpty;

  bool get hasSelection => selectedHazardLocationIds.isNotEmpty;

  Set<String> _getVisibleLocationIds(List<Data> visibleItems) {
    return visibleItems
        .where((e) => e.usFlag == true) // only selectable items
        .map((e) => e.locationId!)
        .toSet();
  }

  bool _isAllSelected(Set<String> visibleIds) {
    return visibleIds.isNotEmpty &&
        selectedHazardLocationIds.containsAll(visibleIds);
  }

  bool _isPartiallySelected(Set<String> visibleIds) {
    return selectedHazardLocationIds.isNotEmpty && !_isAllSelected(visibleIds);
  }

  /// Visible IDs based on filter
  Set<String> get filteredVisibleIds =>
      _applyLocationFilter(_cachedFilteredItems)
          .map((e) => e.locationId!)
          .toSet();

  bool hasAnyPlan = false;
  TabController? _tabController;
  Screens _selectedScreen = Screens.accountList;
  TextEditingController _textEditingController = TextEditingController();
  TextEditingController mobileController = TextEditingController();
  TextEditingController _messageController = TextEditingController();
  TextEditingController _sovNameController = TextEditingController();
  bool isLoading = false;
  bool isUpdating = false;
  final List<String> locationFilters = [
    "All Locations",
    "HazardHub Eligible",
    "Non HazardHub Eligible",
  ];

  String selectedLocation = "All Locations";

  final TextEditingController _filePathController = TextEditingController();

  String? _uploadedFileName;

  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool showCheckbox = false;

  Timer? deBouncer;

  Timer? _debounce;
  String _accountQuery = "";
  bool _accountAlreadyExists = false;
  Accounts? _selectedAccount;
  String _autocompleteText = "";
  bool isPgAdmin = false;
  bool isAdmin = false;
  bool isSuperAdmin = false;
  bool isIndivudual = false;

  ScrollController _scrollController = ScrollController();
  String? hasHazardHubCount = "1";
  Timer? autoCompleteDeBouncer;

  late File files;

  void debounce(
    VoidCallback callback, {
    Duration duration = const Duration(seconds: 1),
  }) {
    if (deBouncer != null) {
      deBouncer!.cancel();
    }
    deBouncer = Timer(duration, callback);
  }

  void accountsSearchClient(String query) async {
    debounce(() async {
      if (!mounted) return;
      _accountQuery = query;
      print("Query set to: $_accountQuery");
      var provider = Provider.of<AccountListProvider>(context, listen: false);
      provider.page = 1;
      await provider.fetchMissingParameterList(context, widget.sovId);
    });
  }

  void autoCompleteDebounce(
    VoidCallback callback, {
    Duration duration = const Duration(seconds: 1),
  }) {
    if (autoCompleteDeBouncer != null) {
      autoCompleteDeBouncer!.cancel();
    }
    autoCompleteDeBouncer = Timer(duration, callback);
  }

  Future<void> autoCompleteAccountsSearchClient(String query) async {
    if (query.isEmpty) {
      return;
    }
    print("autoCompleteAccountsSearchClient called with query: $query");
    autoCompleteDebounce(() async {
      if (!mounted) return;
      var provider = Provider.of<AccountListProvider>(context, listen: false);
      await provider.fetchMissingParameterList(context, widget.sovId);

      // Force UI update after API call
      if (mounted) {
        setState(() {
          print("setState called after fetchAutoCompleteAccountList");
        });
      }
    });
  }

  GlobalKey keyFeature1 = GlobalKey();
  GlobalKey keyFeature2 = GlobalKey();
  GlobalKey keyFeature3 = GlobalKey();
  List<TargetFocus> targets = [];
  TutorialCoachMark? tutorialCoachMark;
  bool _showOverlay = false;

  @override
  void initState() {
    super.initState();

    var userProfileProvider =
        Provider.of<UserProfileProvider>(context, listen: false);
    final trialStatus = userProfileProvider.trialInfo['status'] ?? '';
    int tabCount = (trialStatus.isEmpty) ? 4 : 3;
    _tabController = TabController(length: tabCount, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AccountListProvider>(context, listen: false);

      if (widget.sovId != null && widget.sovId!.isNotEmpty) {
        // 🔥 START FIRESTORE LISTENER (like web)
        provider.listenToLocationRecommendations(widget.sovId!);

        // 🔥 FETCH API DATA
        _getData(widget.sovId!);
      }
    });
  }

  Future<void> _closeOverlay() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
        'isFirstTime', false); // 👈 save only when user closes it
    setState(() => _showOverlay = false);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _filePathController.dispose();
    super.dispose();
  }

  Future<void> _refreshHazardHubCredits() async {
    final credits = await SharedPreferenceService.getHazardHubLicense();

    if (!mounted) return;

    setState(() {
      hasHazardHubCount = credits;
    });
  }

  Future<void> _getData(String sovId) async {
    final accountListProvider =
        Provider.of<AccountListProvider>(context, listen: false);
    String? hazardLicenseStatus =
        await SharedPreferenceService.getHazardHubLicense();
    setState(() {
      hasHazardHubCount = hazardLicenseStatus;
    });

    await accountListProvider.fetchMissingParameterList(context, sovId);
    setState(() => _selectedScreen = Screens.accountList);
  }

  @override
  Widget build(BuildContext context1) {
    var typography = CustomTypography(context);
    return SafeArea(
      child: Consumer<ThemeProvider>(
          builder: (buildContext, themeProvider, child) {
        return PopScope(
          onPopInvokedWithResult: (canPop, result) {
            print('Can Pop: $canPop, Selected Screen: $_selectedScreen');
            Provider.of<DrawerSelectionProvider>(context, listen: false)
                .setSelectedItem("dashboard");
          },
          child: Scaffold(
            key: _scaffoldKey,
            backgroundColor: themeProvider.getTheme.colorScheme.background,
            body: Consumer<UserProfileProvider>(
                builder: (context, userProfileProvider, child) {
              return PopScope(
                canPop: /*_selectedScreen == Screens.connectionList ||
                          _selectedScreen == Screens.corporateConnectionList,*/
                    true,
                onPopInvoked: (canPop) {
                  print('Can Pop: $canPop, Selected Screen: $_selectedScreen');
                },
                child: Stack(
                  children: [
                    // Background image
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.3,
                        child: Image.asset(
                          'assets/images/mesh.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Column(
                      children: [
                        Expanded(
                          child: Container(
                            margin: EdgeInsets.symmetric(horizontal: 15),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                //
                                SizedBox(height: CustomSpacing.two),

                                Expanded(
                                  child: TabBarView(
                                    controller: _tabController,
                                    children: [
                                      _getAccountUI(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    /// 🔥 BOTTOM UNLOCK BAR (GLOBAL)
                    if (hasSelection)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          height: 50,
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.4),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: SafeArea(
                            top: false,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryMain,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                showInsufficientCreditsBottomSheet(
                                  context,
                                  hasHazardHubCount: hasHazardHubCount,
                                  selectedLocationIds:
                                      selectedHazardLocationIds.toList(),
                                  onSuccess: () async {
                                    selectedHazardLocationIds.clear();
                                    // 🔄 reload data after unlock
                                    await _refreshHazardHubCredits();
                                    await _getData(widget.sovId);

                                    setState(() {});
                                  },
                                );
                              },
                              child: Text(
                                "Unlock Hazard Data",
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (_showOverlay) _buildOverlay(),
                  ],
                ),
              );
            }),
          ),
        );
      }),
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
                InkWell(
                  onTap: () async {
                    const url = 'https://www.youtube.com/watch?v=7kvdDtowGM0';
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
                  "New Account",
                  style: TextStyle(
                    color: AppColors.primaryMain,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  "Set up a primary account for your client or commercial entity. Add key company info to start building their digital risk data. ",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryMain,
                          side: const BorderSide(color: AppColors.primaryMain),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _closeOverlay,
                        child:
                            const Text("Skip", style: TextStyle(fontSize: 14)),
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryMain,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        _closeOverlay();
                        _showAddAccountDialog(context);
                      }, //_closeOverlay,
                      child: const Text("Add Account",
                          style: TextStyle(color: Colors.black)),
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

  Widget _buildMissingParameterCard(Data item) {
    final typography = CustomTypography(context);
    final provider = context.watch<AccountListProvider>();

    final String locationId = item.locationId ?? '';
    final bool isBlocked = provider.blockedLocationIds.contains(locationId);
    final bool isSelected = selectedHazardLocationIds.contains(locationId);

    return Opacity(
      opacity: isBlocked ? 0.6 : 1,
      child: IgnorePointer(
        ignoring: isBlocked,
        child: GestureDetector(
          onLongPress: () {
            if (item.usFlag == true) {
              setState(() {
                selectedHazardLocationIds.add(locationId);
              });
            }
          },
          onTap: () {
            if (hasSelection && item.usFlag == true) {
              setState(() {
                if (isSelected) {
                  selectedHazardLocationIds.remove(locationId);
                } else {
                  selectedHazardLocationIds.add(locationId);
                }
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.grey.withOpacity(0.15)
                  : const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? Colors.grey : const Color(0xFF2C2C2C),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// HEADER

                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4), // square corners
                      child: CachedNetworkImage(
                        imageUrl:
                            "https://maps.googleapis.com/maps/api/streetview?size=600x300&location=${item.latitude},${item.longitude}&key=AIzaSyBA8NoBrHa9JwGQT8Mk1s9lXqElfON_NGI",
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.error),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            SizedBox(
                              width: MediaQuery.of(context).size.width / 4,
                              child: Text(
                                item.locationName ?? "-",
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: typography.Body2.copyWith(
                                  color: Colors.blue[300],
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            item.usFlag == true
                                ? InkWell(
                                    borderRadius: BorderRadius.circular(20),
                                    onTap: () {
                                      // 🔥 Select only this location
                                      selectedHazardLocationIds.clear();
                                      selectedHazardLocationIds.add(locationId);

                                      showInsufficientCreditsBottomSheet(
                                        context,
                                        hasHazardHubCount: hasHazardHubCount,
                                        selectedLocationIds: [locationId],
                                        onSuccess: () async {
                                          selectedHazardLocationIds.clear();
                                          await _refreshHazardHubCredits();
                                          await _getData(widget.sovId);
                                          setState(() {});
                                        },
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: const Color(0xFF2ECC71),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          SizedBox(
                                            width: 6,
                                            height: 6,
                                            child: DecoratedBox(
                                              decoration: BoxDecoration(
                                                color: Color(0xFF2ECC71),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 6),
                                          Text(
                                            'Unlock Hazard',
                                            style: TextStyle(
                                              color: Color(0xFF2ECC71),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : Container(),

                            // item.usFlag.toString() !="true" ?Container():
                            // Container(
                            //   padding: const EdgeInsets.symmetric(
                            //       horizontal: 6, vertical: 3),
                            //   decoration: BoxDecoration(
                            //     borderRadius: BorderRadius.circular(20),
                            //     border: Border.all(
                            //       color: const Color(0xFF2ECC71),
                            //       width: 1,
                            //     ),
                            //   ),
                            //   child: Row(
                            //     mainAxisSize: MainAxisSize.min,
                            //     children: [
                            //       Container(
                            //         width: 6,
                            //         height: 6,
                            //         decoration: const BoxDecoration(
                            //           color: Color(0xFF2ECC71),
                            //           shape: BoxShape.circle,
                            //         ),
                            //       ),
                            //       const SizedBox(width: 6),
                            //       const Text(
                            //         'Unlock Hazard',
                            //         style: TextStyle(
                            //           color: Color(0xFF2ECC71),
                            //           fontSize: 12,
                            //           fontWeight: FontWeight.w500,
                            //         ),
                            //       ),
                            //     ],
                            //   ),
                            // ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        SizedBox(
                          width: MediaQuery.of(context).size.width / 2,
                          child: Text(
                            item.address ?? "-",
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: typography.Body2.copyWith(
                              color: Colors.blue[300],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                /// MISSING PARAMETERS
                Text(
                  "${item.totalUnfilledParameters} missing fields",
                  style: typography.Caption.copyWith(
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),

                _buildHighRiskText(
                  context,
                  item.highRiskUnfilledParameterNames,
                  typography.Caption.copyWith(
                    color: Colors.red,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 5),

                /// ✅ HIDE BUTTON ONLY FOR SELECTED ITEM
                // item.usFlag == true
                //     ? Container()
                //     :
                SizedBox(
                  width: double.infinity,
                  height: 33,
                  child: CustomButton(
                    type: ButtonType.elevated,
                    onPressed: () {
                      // if (item.usFlag == true) {
                      //   showInsufficientCreditsBottomSheet(
                      //     context,
                      //     hasHazardHubCount: hasHazardHubCount,
                      //     selectedLocationIds:
                      //         selectedHazardLocationIds.toList(),
                      //     onSuccess: () async {
                      //       // 🔄 reload data after unlock
                      //       await _getData(widget.sovId);
                      //       selectedHazardLocationIds.clear();
                      //       setState(() {});
                      //     },
                      //   );
                      // } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UpdateParameterScreen(item: item),
                        ),
                      );
                      // }
                    },
                    child: Text(
                      // item.usFlag == true ? "Unlock" : "Update",
                      "Update",
                      style: typography.ButtonLargeBlack,
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

  Widget _buildHighRiskText(
    BuildContext context,
    List<String>? names,
    TextStyle style,
  ) {
    if (names == null || names.isEmpty) {
      return const SizedBox(height: 30);
    }

    final first = names.first;
    final remaining = names.skip(1).toList();
    final GlobalKey anchorKey = GlobalKey();

    return SizedBox(
      height: 30,
      child: Row(
        children: [
          Flexible(
            child: Text(
              first,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
          if (remaining.isNotEmpty) ...[
            GestureDetector(
              key: anchorKey,
              onTap: () => _showHighRiskCenterToast(context, names),
              child: Text(
                '+${remaining.length}',
                style: style.copyWith(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showHighRiskCenterToast(
    BuildContext context,
    List<String> items,
  ) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => entry.remove(),
        child: Stack(
          children: [
            Container(color: Colors.black.withOpacity(0.4)),
            Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  constraints: const BoxConstraints(maxHeight: 300),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black54,
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      /// HEADER
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "High Risk Fields",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => entry.remove(),
                              child: const Icon(
                                Icons.close,
                                size: 20,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Divider(height: 1, color: Color(0xFF3A3A3A)),

                      /// ALL ITEMS
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            // 👈 LEFT
                            children: items.map((e) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "•",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        e,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
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

    overlay.insert(entry);
  }

  Future<List<TransferAutocompleteModel>> fetchAutocompleteUsers(
      String query) async {
    try {
      ApiService apiService =
          ApiService(AppConstant.TRANSFER_USER_AUTOCOMPLETE);
      String url = '?search=$query';
      var response = await apiService.get(url);

      // The response has 'result' array instead of 'users'
      List<TransferAutocompleteModel> users = (response['result'] as List)
          .map((user) => TransferAutocompleteModel.fromJson(user))
          .toList();

      return users;
    } catch (e) {
      print('Error fetching users: ${e.toString()}');
      return [];
    }
  }

  Future<void> _showAddAccountDialog(BuildContext context) async {
    var typography = CustomTypography(context);
    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              clipBehavior: Clip.antiAliasWithSaveLayer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 500,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        LanguageService.getTranslated(
                            context, "account_list_app_add_account_title"),
                        style: typography.H5_Regular,
                      ),
                      SizedBox(height: 16.0),
                      Consumer<AccountListProvider>(
                        builder: (context, accountListProvider, child) {
                          return Column(
                            children: [
                              TextField(
                                controller: _textEditingController,
                                onChanged: (value) {
                                  setState(() {
                                    _accountAlreadyExists = false;
                                    _selectedAccount = null;
                                    accountListProvider.clearAutoCompleteList();
                                  });

                                  _autocompleteText = value;

                                  // Cancel the previous debounce timer
                                  if (_debounce?.isActive ?? false)
                                    _debounce!.cancel();

                                  // Start a new debounce timer
                                  _debounce =
                                      Timer(const Duration(milliseconds: 500),
                                          () async {
                                    await autoCompleteAccountsSearchClient(
                                        _autocompleteText);
                                  });
                                },
                                decoration: InputDecoration(
                                  suffixIcon: _textEditingController
                                          .text.isNotEmpty
                                      ? IconButton(
                                          icon: Icon(Icons.clear),
                                          onPressed: () {
                                            setState(() {
                                              _textEditingController.clear();
                                              _accountAlreadyExists = false;
                                              _selectedAccount = null;
                                              accountListProvider
                                                  .clearAutoCompleteList();
                                            });
                                          },
                                        )
                                      : null,
                                  labelText: LanguageService.getTranslated(
                                      context,
                                      "account_list_app_add_account_title"),
                                  hintText: LanguageService.getTranslated(
                                      context,
                                      "account_list_app_add_account_title"),
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                              if (_textEditingController.text.isNotEmpty &&
                                  !_accountAlreadyExists)
                                AutocompleteOptions(
                                  options: accountListProvider
                                      .autoCompleteAccountList,
                                  onSelected: (Accounts selection) {
                                    setState(() {
                                      _accountAlreadyExists = true;
                                      _selectedAccount = selection;
                                      _textEditingController.text =
                                          selection.accountName!;
                                      // Clear the autocomplete list when an option is selected
                                      accountListProvider
                                          .clearAutoCompleteList();
                                    });
                                  },
                                  isLoading:
                                      accountListProvider.isAutoCompleteLoading,
                                ),
                            ],
                          );
                        },
                      ),
                      SizedBox(height: CustomSpacing.six),
                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Consumer<AccountListProvider>(
                                    builder: (context, accountListProvider, _) {
                                  return accountListProvider.isAddAccountLoading
                                      ? Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                                width: 25,
                                                height: 25,
                                                child:
                                                    CircularProgressIndicator()),
                                          ],
                                        )
                                      : CustomButton(
                                          onPressed: () async {
                                            if (_autocompleteText.isEmpty) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(SnackBar(
                                                      content: Text(
                                                LanguageService.getTranslated(
                                                    context,
                                                    "account_list_app_add_account_empty_text_error"),
                                                style: typography.Body1,
                                              )));
                                              return;
                                            }

                                            if (!_accountAlreadyExists) {
                                              // Add account
                                              await accountListProvider
                                                  .addAccount(context,
                                                      _autocompleteText);
                                            } else {
                                              // Request access
                                              if (_messageController
                                                  .text.isEmpty) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(SnackBar(
                                                        content: Text(
                                                  LanguageService.getTranslated(
                                                      context,
                                                      "account_list_app_add_account_empty_text_error"),
                                                  style: TextStyle(
                                                      color: Colors.black),
                                                )));
                                                return;
                                              }
                                              await accountListProvider
                                                  .requestAccess(
                                                      context,
                                                      _selectedAccount
                                                              ?.accountId ??
                                                          "",
                                                      _messageController.text);
                                            }
                                            Navigator.pop(context);
                                          },
                                          child: Text(
                                            // _accountAlreadyExists
                                            //     ? LanguageService.getTranslated(
                                            //         context,
                                            //         "account_list_app_request_access_text")
                                            //     :
                                            LanguageService.getTranslated(
                                                context,
                                                "account_list_app_submit_text"),
                                            style: typography.ButtonLargeBlack,
                                          ),
                                          type: ButtonType.elevated,
                                        );
                                }),
                              ),
                            ],
                          ),
                          CustomButton(
                            onPressed: () {
                              // Cancel
                              _uploadedFileName = null;
                              _sovNameController.clear();
                              Navigator.pop(context);
                            },
                            child: Text(
                              LanguageService.getTranslated(
                                  context, "account_list_app_cancel_text"),
                              style: typography.ButtonLarge,
                            ),
                            type: ButtonType.text,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      // Clear the autocomplete list when the dialog is dismissed
      Provider.of<AccountListProvider>(context, listen: false)
          .clearAutoCompleteList();
      _textEditingController.clear();
      _messageController.clear();
      _accountAlreadyExists = false;
    });
  }

  _getComingSoonUI(String title) {
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

  List<Data> _applyLocationFilter(List<Data> list) {
    switch (selectedLocation) {
      case "HazardHub Eligible":
        return list.where((e) => e.usFlag == true).toList();

      case "Non HazardHub Eligible":
        return list.where((e) => e.usFlag == false).toList();

      case "All Locations":
      default:
        return list;
    }
  }

  Widget _getAccountUI() {
    var typography = CustomTypography(context);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2C2C2C), width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Builder(
                builder: (context) {
                  final provider = context.watch<AccountListProvider>();

                  final allItems = provider.missingParameterList
                      .where((e) => (e.totalUnfilledParameters ?? 0) > 0)
                      .toList();

                  final visibleItems = _applyLocationFilter(allItems);
                  final visibleIds = _getVisibleLocationIds(visibleItems);

                  IconData icon;
                  if (_isAllSelected(visibleIds)) {
                    icon = Icons.check_box;
                  } else if (_isPartiallySelected(visibleIds)) {
                    icon = Icons.indeterminate_check_box;
                  } else {
                    icon = Icons.check_box_outline_blank;
                  }

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_isAllSelected(visibleIds)) {
                          selectedHazardLocationIds.removeAll(visibleIds);
                        } else {
                          selectedHazardLocationIds.addAll(visibleIds);
                        }
                      });
                    },
                    child: Icon(icon, color: Colors.white, size: 22),
                  );
                },
              ),
              const SizedBox(width: 8),
              Text(
                LanguageService.getTranslated(context, "missing_parameter"),
                style: typography.Body1,
              ),
              const Spacer(),
              Text(
                "$hasHazardHubCount Credits Remaining",
                style: typography.Body1,
              )
            ],
          ),
          SizedBox(height: CustomSpacing.four),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: MediaQuery.of(context).size.width / 1.8,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade700),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton2<String>(
                    isExpanded: true,
                    value: selectedLocation,
                    iconStyleData: const IconStyleData(
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: Colors.white,
                      ),
                    ),
                    dropdownStyleData: DropdownStyleData(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    buttonStyleData: const ButtonStyleData(
                      padding: EdgeInsets.zero,
                      height: 40,
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    items: locationFilters.map(
                      (item) {
                        return DropdownMenuItem<String>(
                          value: item,
                          child: Text(
                            item,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      },
                    ).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedLocation = value!;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: CustomSpacing.two),
          Expanded(
            child:
                Selector<AccountListProvider, Tuple3<bool, bool, List<Data>>>(
              selector: (_, provider) => Tuple3(
                provider.isLoading,
                provider.isRefreshPending,
                provider.missingParameterList,
              ),
              builder: (context, data, _) {
                final bool isLoading = data.item1;

                /// 1️⃣ Base list (only missing parameters)
                final List<Data> allItems = data.item3
                    .where((e) => (e.totalUnfilledParameters ?? 0) > 0)
                    .toList();

                /// 2️⃣ Apply dropdown filter
                final List<Data> filteredList = _applyLocationFilter(allItems);

                /// 🔹 Initial loading
                if (isLoading && filteredList.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                /// 🔹 No data after filter
                if (filteredList.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        "No data found",
                        textAlign: TextAlign.center,
                        style: CustomTypography(context).Body1,
                      ),
                    ),
                  );
                }

                /// 🔹 List
                return RefreshIndicator(
                  onRefresh: () async {
                    await context
                        .read<AccountListProvider>()
                        .fetchMissingParameterList(
                          context,
                          widget.sovId!,
                          isRefresh: true,
                        );
                  },
                  child: ListView.builder(
                    key: const PageStorageKey('missingParameterListView'),
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 90),
                    // space for bottom unlock bar
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final item = filteredList[index];
                      return Container(
                        padding: const EdgeInsets.all(4),
                        margin: const EdgeInsets.symmetric(vertical: 1),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _buildMissingParameterCard(item),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

Widget _chip(String text, {bool isPrimary = false}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: isPrimary
          ? Colors.red.withOpacity(0.15)
          : Colors.grey.withOpacity(0.15),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: isPrimary ? Colors.red : Colors.grey[300],
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}

Widget _countChip(String text) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.grey.withOpacity(0.2),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: Colors.white70,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}

void showInsufficientCreditsBottomSheet(
  BuildContext context, {
  required String? hasHazardHubCount,
  required List<String> selectedLocationIds,
  required VoidCallback onSuccess,
}) {
  bool isChecked = true;

  final int length = selectedLocationIds.length;
  final int availableCredits = int.tryParse(hasHazardHubCount ?? '0') ?? 0;
  final int remainingCredits = availableCredits;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF0F0F0F),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// TITLE
                    const Text(
                      "Confirm Unlock HazardHub Data",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      "You are about to unlock HazardHub data for this locations.",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 16),

                    Text(
                      "This action will consume $length credits from your available balance.",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      "Credits remaining after unlock: $remainingCredits",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      "Please ensure you want to proceed with this action.",
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// CONFIRM BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: Consumer<AccountListProvider>(
                        builder: (context, provider, _) {
                          return ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8EC9FF),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),

                            onPressed: (!provider.isUpdating &&
                                    isChecked &&
                                    remainingCredits >= 0)
                                ? () async {
                                    try {
                                      /// 🔥 CALL API
                                      await provider.unlockHazardHubData(
                                        context,
                                        locationIds: selectedLocationIds,
                                      );

                                      onSuccess();
                                      Navigator.of(context).pop();

                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              "HazardHub unlocked successfully"),
                                        ),
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content:
                                              Text("Unlock failed. Try again"),
                                        ),
                                      );
                                    }
                                  }
                                : null,

                            /// 🔄 BUTTON CONTENT
                            child: provider.isUpdating
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.black),
                                    ),
                                  )
                                : const Text(
                                    "Confirm Unlock",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 5),

                    /// BUY CREDIT (only if no credits)
                    // if (availableCredits == 0)
                    //   SizedBox(
                    //     width: double.infinity,
                    //     child: OutlinedButton(
                    //       style: OutlinedButton.styleFrom(
                    //         side: const BorderSide(color: Color(0xFF8EC9FF)),
                    //         foregroundColor: const Color(0xFF8EC9FF),
                    //         padding: const EdgeInsets.symmetric(vertical: 14),
                    //         shape: RoundedRectangleBorder(
                    //           borderRadius: BorderRadius.circular(10),
                    //         ),
                    //       ),
                    //       onPressed: () => Navigator.pop(context),
                    //       child: const Text(
                    //         "Buy Credit",
                    //         style: TextStyle(fontSize: 16),
                    //       ),
                    //     ),
                    //   ),

                    const SizedBox(height: 5),

                    /// CANCEL
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade600),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
