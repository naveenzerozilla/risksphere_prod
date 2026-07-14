import 'package:RiskSphere/screens/listings/udpate_parameter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:tuple/tuple.dart';
import '../../utils/env.dart';
import '../../utils/global_imports.dart';
import 'package:RiskSphere/models/account_list_model.dart';

import '../payments/purchase_license.dart';
import 'location_profile.dart';

class MissingParameterScreen extends StatefulWidget {
  final String sovId;

  MissingParameterScreen({Key? key, required this.sovId}) : super(key: key);

  @override
  State<MissingParameterScreen> createState() => _MissingParameterScreenState();
}

class _MissingParameterScreenState extends State<MissingParameterScreen>
    with TickerProviderStateMixin {
  final Set<String> selectedHazardLocationIds = {};

  List<Data> _cachedFilteredItems = [];
  final Set<String> _optimisticProcessingIds = {};
  final Set<String> _optimisticUnlockedHazards = {};

  bool get hasHazardSelection => selectedHazardLocationIds.isNotEmpty;

  bool get hasSelection => selectedHazardLocationIds.isNotEmpty;

  Set<String> _getVisibleLocationIds(List<Data> visibleItems) {
    return visibleItems
        .where((e) =>
            e.usFlag == true &&
            e.hasVendorHazards != true &&
            !_optimisticProcessingIds.contains(e.locationId))
        .map((e) => e.locationId!)
        .toSet();
  }

  // Set<String> _getVisibleLocationIds(List<Data> visibleItems) {
  //   return visibleItems
  //       .where((e) => e.usFlag == true)
  //       .map((e) => e.locationId!)
  //       .toSet();
  // }

  bool _isAllSelected(Set<String> visibleIds) {
    return visibleIds.isNotEmpty &&
        selectedHazardLocationIds.containsAll(visibleIds);
  }

  bool _isPartiallySelected(Set<String> visibleIds) {
    return selectedHazardLocationIds.isNotEmpty && !_isAllSelected(visibleIds);
  }

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
  void initState() {
    super.initState();

    var userProfileProvider =
        Provider.of<UserProfileProvider>(context, listen: false);
    final trialStatus = userProfileProvider.trialInfo['status'] ?? '';
    int tabCount = (trialStatus.isEmpty) ? 4 : 3;
    _tabController = TabController(length: tabCount, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AccountListProvider>(context, listen: false);

      if (widget.sovId.isNotEmpty) {
        provider.listenToLocationRecommendations(widget.sovId);

        _getData(widget.sovId);
      }
    });
  }

  Future<void> _closeOverlay() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
        'isFirstTime', false); // 👈 save only when user closes it
    setState(() => _showOverlay = false);
  }

  Future<void> _refreshHazardHubCredits() async {
    final credits = await SharedPreferenceService.getHazardHubLicense();

    if (!mounted) return;

    setState(() {
      hasHazardHubCount = credits;
    });
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
                                  onConfirmStart: () {
                                    setState(() {
                                      _optimisticProcessingIds
                                          .addAll(selectedHazardLocationIds);
                                    });
                                  },
                                  onFinish: () async {
                                    setState(() {
                                      _optimisticUnlockedHazards.clear();
                                      _optimisticProcessingIds.clear();
                                      selectedHazardLocationIds.clear();
                                    });

                                    await context
                                        .read<AccountListProvider>()
                                        .fetchMissingParameterList(
                                          context,
                                          widget.sovId,
                                          isRefresh: true,
                                        );

                                    await _refreshHazardHubCredits();
                                    await _getData(widget.sovId);
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
                  ],
                ),
              );
            }),
          ),
        );
      }),
    );
  }

  Widget _buildMissingParameterCard(
    Data item,
    Map<String, String> accountMap,
    Map<String, String> subAccountMap,
  ) {
    final typography = CustomTypography(context);
    final provider = context.read<AccountListProvider>();

    final String locationId = item.locationId ?? '';
    // final bool isBlocked = provider.blockedLocationIds.contains(locationId);

    final bool isBlocked = _optimisticProcessingIds.contains(locationId) ||
        provider.blockedLocationIds.contains(locationId);
    final bool canSelect =
        item.usFlag == true && item.hasVendorHazards != true && !isBlocked;
    final bool isSelected =
        canSelect && selectedHazardLocationIds.contains(locationId);
    final String accountName = accountMap[item.accountId] ?? "-";

    final String subAccountName = subAccountMap[item.subAccountId] ?? "-";
    final bool hasHazard = item.hasVendorHazards == true ||
        _optimisticUnlockedHazards.contains(locationId);
    return GestureDetector(
      /// future implementations
      onLongPress: () {
        if (item.usFlag == true && item.hasVendorHazards != true) {
          if (selectedHazardLocationIds.length >= 5) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("You can select a maximum of 5 locations."),
              ),
            );
            return;
          }

          setState(() {
            selectedHazardLocationIds.add(locationId);
          });
        }
      },
      // onLongPress: () {
      //   if (item.usFlag == true && item.hasVendorHazards != true) {
      //     setState(() {
      //       selectedHazardLocationIds.add(locationId);
      //     });
      //   }
      // },
      onTap: () {
        if (!canSelect) return;

        setState(() {
          if (isSelected) {
            selectedHazardLocationIds.remove(locationId);
          } else {
            if (selectedHazardLocationIds.length >= 5) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("You can select a maximum of 5 locations."),
                  duration: Duration(seconds: 2),
                ),
              );
              return;
            }
            selectedHazardLocationIds.add(locationId);
          }
        });
      },
      // onTap: () {
      //   if (!canSelect) return;
      //
      //   setState(() {
      //     if (isSelected) {
      //       selectedHazardLocationIds.remove(locationId);
      //     } else {
      //       selectedHazardLocationIds.add(locationId);
      //     }
      //   });
      // },

      child: Container(
          padding: const EdgeInsets.all(10),
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
          child: IgnorePointer(
            ignoring: isBlocked,
            child: Opacity(
              opacity: isBlocked ? 0.6 : 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        // square corners
                        child: CachedNetworkImage(
                          imageUrl:
                              "https://maps.googleapis.com/maps/api/streetview?size=600x300&location=${item.latitude},${item.longitude}&key=${Env.get('GOOGLE_MAPS_API_KEY')}",
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
                      const SizedBox(width: 2),
                      Container(
                        // color: Colors.red,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width / 3.1,
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
                                item.usFlag == true
                                    ? InkWell(
                                        borderRadius: BorderRadius.circular(20),
                                        onTap: isBlocked
                                            ? null
                                            : () {
                                                if (item.hasVendorHazards ==
                                                    true) {
                                                  Navigator.of(context).push(
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                          LocationProfile(
                                                        accountId:
                                                            item.accountId!,
                                                        accountName:
                                                            accountName,
                                                        subAccountId:
                                                            item.subAccountId!,
                                                        subAccountName:
                                                            subAccountName,
                                                        sovId: "",
                                                        sovName: "test",
                                                        searchQuery: "",
                                                        locationId:
                                                            item.locationId,
                                                        page: "1",
                                                        totalPages: "1",
                                                        tab: 2,
                                                      ),
                                                    ),
                                                  );
                                                } else {
                                                  showInsufficientCreditsBottomSheet(
                                                    context,
                                                    hasHazardHubCount:
                                                        hasHazardHubCount,
                                                    selectedLocationIds: [
                                                      locationId
                                                    ],
                                                    onConfirmStart: () {
                                                      setState(() {
                                                        _optimisticProcessingIds
                                                            .add(locationId);
                                                      });
                                                    },
                                                    onFinish: () async {
                                                      setState(() {
                                                        _optimisticUnlockedHazards
                                                            .clear();
                                                        _optimisticProcessingIds
                                                            .clear();
                                                        selectedHazardLocationIds
                                                            .clear();
                                                      });

                                                      await context
                                                          .read<
                                                              AccountListProvider>()
                                                          .fetchMissingParameterList(
                                                            context,
                                                            widget.sovId,
                                                            isRefresh: true,
                                                          );

                                                      await _refreshHazardHubCredits();
                                                      await _getData(
                                                          widget.sovId);
                                                    },
                                                  );
                                                }
                                              },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 6),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                              color: const Color(0xFF2ECC71),
                                              width: 1,
                                            ),
                                          ),

                                          child: isBlocked
                                              ? const SizedBox(
                                                  height: 14,
                                                  width: 14,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                                Color>(
                                                            Color(0xFF2ECC71)),
                                                  ),
                                                )
                                              : Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [

                                                    Text(
                                                      hasHazard
                                                          ? 'View HazardHub'
                                                          : 'Unlock HazardHub',
                                                      style: const TextStyle(
                                                        color:
                                                            Color(0xFF2ECC71),
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),

                                                  ],
                                                ),
                                        ),
                                      )
                                    : const SizedBox(),
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
                      onPressed: isBlocked
                          ? null
                          : () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      UpdateParameterScreen(item: item),
                                ),
                              );

                              setState(() {
                                _optimisticUnlockedHazards.clear();
                                _optimisticProcessingIds.clear();
                                selectedHazardLocationIds.clear();
                              });

                              await context
                                  .read<AccountListProvider>()
                                  .fetchMissingParameterList(
                                    context,
                                    widget.sovId,
                                    isRefresh: true,
                                  );

                              await _refreshHazardHubCredits();
                            },
                      // onPressed: isBlocked
                      //     ? null
                      //     : () {
                      //         // if (item.usFlag == true) {
                      //         //   showInsufficientCreditsBottomSheet(
                      //         //     context,
                      //         //     hasHazardHubCount: hasHazardHubCount,
                      //         //     selectedLocationIds:
                      //         //         selectedHazardLocationIds.toList(),
                      //         //     onSuccess: () async {
                      //         //       // 🔄 reload data after unlock
                      //         //       await _getData(widget.sovId);
                      //         //       selectedHazardLocationIds.clear();
                      //         //       setState(() {});
                      //         //     },
                      //         //   );
                      //         // } else {
                      //         Navigator.push(
                      //           context,
                      //           MaterialPageRoute(
                      //             builder: (_) =>
                      //                 UpdateParameterScreen(item: item),
                      //           ),
                      //         ).then(value){
                      //           setState(() {
                      //             _optimisticUnlockedHazards.clear();
                      //             _optimisticProcessingIds.clear();
                      //             selectedHazardLocationIds.clear();
                      //           });
                      //
                      //           await context
                      //               .read<AccountListProvider>()
                      //               .fetchMissingParameterList(
                      //             context,
                      //             widget.sovId!,
                      //             isRefresh: true,
                      //           );
                      //
                      //           await _refreshHazardHubCredits();
                      //         }
                      //
                      //         // }
                      //       },
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
          )),
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
              // Builder(
              //   builder: (context) {
              //     final provider = context.watch<AccountListProvider>();
              //
              //     final allItems = provider.missingParameterList
              //         .where((e) => (e.totalUnfilledParameters ?? 0) > 0)
              //         .toList();
              //
              //     final visibleItems = _applyLocationFilter(allItems);
              //     final visibleIds = _getVisibleLocationIds(visibleItems);
              //
              //     IconData icon;
              //     if (_isAllSelected(visibleIds)) {
              //       icon = Icons.check_box;
              //     } else if (_isPartiallySelected(visibleIds)) {
              //       icon = Icons.indeterminate_check_box;
              //     } else {
              //       icon = Icons.check_box_outline_blank;
              //     }
              //
              //     return GestureDetector(
              //       onTap: () {
              //         setState(() {
              //           /// If all selected → unselect
              //           if (_isAllSelected(visibleIds)) {
              //             selectedHazardLocationIds.removeAll(visibleIds);
              //           } else {
              //             /// Remaining slots available
              //             final remaining =
              //                 5 - selectedHazardLocationIds.length;
              //
              //             if (remaining <= 0) {
              //               ScaffoldMessenger.of(context).showSnackBar(
              //                 const SnackBar(
              //                   content: Text(
              //                       "You can select a maximum of 5 locations."),
              //                   duration: Duration(seconds: 2),
              //                 ),
              //               );
              //               return;
              //             }
              //
              //             /// Only add up to remaining limit
              //             final idsToAdd = visibleIds
              //                 .where((id) =>
              //                     !selectedHazardLocationIds.contains(id))
              //                 .take(remaining);
              //
              //             selectedHazardLocationIds.addAll(idsToAdd);
              //           }
              //         });
              //       },
              //       child: Icon(
              //         icon,
              //         color: Colors.white,
              //         size: 22,
              //       ),
              //     );
              //   },
              // ),

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
            child: Selector<
                AccountListProvider,
                Tuple5<bool, bool, List<Data>, AccountIdToName?,
                    SubAccountIdToName?>>(
              selector: (_, provider) => Tuple5(
                provider.isLoading,
                provider.isRefreshPending,
                provider.missingParameterList,
                provider.accountListModel?.accountIdToName,
                provider.accountListModel?.subAccountIdToName,
              ),
              builder: (context, data, _) {
                final bool isLoading = data.item1;

                final List<Data> allItems = data.item3
                    .where((e) => (e.totalUnfilledParameters ?? 0) > 0)
                    .toList();
                final accountMap = data.item4?.map ?? {};
                final subAccountMap = data.item5?.map ?? {};

                final List<Data> filteredList = _applyLocationFilter(allItems);

                if (isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

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

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {
                      _optimisticUnlockedHazards.clear();
                      _optimisticProcessingIds.clear();
                      selectedHazardLocationIds.clear();
                    });

                    await context
                        .read<AccountListProvider>()
                        .fetchMissingParameterList(
                          context,
                          widget.sovId,
                          isRefresh: true,
                        );

                    await _refreshHazardHubCredits();

                    // await context
                    //     .read<AccountListProvider>()
                    //     .fetchMissingParameterList(
                    //       context,
                    //       widget.sovId!,
                    //       isRefresh: true,
                    //     );
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
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: _buildMissingParameterCard(
                              item, accountMap, subAccountMap));
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

void showInsufficientCreditsBottomSheet(
  BuildContext context, {
  required String? hasHazardHubCount,
  required List<String> selectedLocationIds,
  required VoidCallback onConfirmStart,
  required VoidCallback onFinish,
}) {
  final int length = selectedLocationIds.length;
  final int availableCredits = int.tryParse(hasHazardHubCount ?? '0') ?? 0;

  final int remainingCredits = availableCredits;
  final int remainingAfterUnlock = remainingCredits - length;

  final bool insufficientCredits = remainingAfterUnlock < 0;

  /// how many locations we can unlock
  final int unlockableCount =
      availableCredits.clamp(0, selectedLocationIds.length);

  bool understandResetChecked = false;

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
                    Text(
                      insufficientCredits
                          ? "Insufficient Credits"
                          : "Confirm Unlock HazardHub Data",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      insufficientCredits
                          ? "You've selected $length locations, but only $availableCredits credits are available."
                          : "You are about to unlock HazardHub data for these locations.",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 16),

                    Text(
                      insufficientCredits
                          ? "To continue, you can purchase more credits."
                          : "This action will consume $length credits from your available balance.",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      insufficientCredits
                          ? "During payment, your current location selection will not be saved. After purchase, you'll need to reselect locations to unlock HazardHub data."
                          : "Credits remaining after unlock: $remainingAfterUnlock",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 20),

                    if (insufficientCredits)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              value: understandResetChecked,
                              onChanged: (value) {
                                setState(() {
                                  understandResetChecked = value ?? false;
                                });
                              },
                              activeColor: const Color(0xFF8EC9FF),
                              checkColor: Colors.black,
                              side: const BorderSide(color: Colors.white70),
                            ),
                            const Expanded(
                              child: Text(
                                "I understand my selection will reset after payment",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 20),

                    /// BUTTON SECTION
                    if (insufficientCredits)
                      Row(
                        children: [
                          /// Cancel
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.grey.shade600),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Cancel"),
                            ),
                          ),

                          const SizedBox(width: 10),

                          /// Buy Credit
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8EC9FF),
                                foregroundColor: Colors.black,
                              ),
                              onPressed: understandResetChecked
                                  ? () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const PurchaseLicensePage(),
                                        ),
                                      );
                                    }
                                  : null,
                              child: const Text("Buy Credit"),
                            ),
                          ),

                          const SizedBox(width: 10),

                          /// Unlock available credits
                          Expanded(
                            child: Consumer<AccountListProvider>(
                              builder: (context, provider, _) {
                                return ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: const Color(0xFF8EC9FF),
                                    side: const BorderSide(
                                        color: Color(0xFF8EC9FF)),
                                  ),
                                  onPressed: (!provider.isUpdating &&
                                          unlockableCount > 0)
                                      ? () async {
                                          try {
                                            onConfirmStart();

                                            await provider.unlockHazardHubData(
                                              context,
                                              locationIds: selectedLocationIds
                                                  .take(unlockableCount)
                                                  .toList(),
                                            );

                                            Navigator.pop(context);
                                            onFinish();
                                          } catch (e) {
                                            onFinish();
                                          }
                                        }
                                      : null,
                                  child: provider.isUpdating
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        )
                                      : Text("Unlock $unlockableCount"),
                                );
                              },
                            ),
                          ),
                        ],
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: Consumer<AccountListProvider>(
                          builder: (context, provider, _) {
                            return ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8EC9FF),
                                foregroundColor: Colors.black,
                              ),
                              onPressed: (!provider.isUpdating)
                                  ? () async {
                                      try {
                                        onConfirmStart();

                                        await provider.unlockHazardHubData(
                                          context,
                                          locationIds: selectedLocationIds,
                                        );

                                        Navigator.pop(context);
                                        onFinish();
                                      } catch (e) {
                                        onFinish();
                                      }
                                    }
                                  : null,
                              child: provider.isUpdating
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2.5),
                                    )
                                  : const Text("Confirm Unlock"),
                            );
                          },
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

