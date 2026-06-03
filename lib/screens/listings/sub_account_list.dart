import 'package:RiskSphere/screens/listings/widgets/auto_complete_options_sub_accounts.dart';
import 'package:tuple/tuple.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/sub_account_list_model.dart';
import '../../utils/global_imports.dart';
import 'package:flutter/cupertino.dart';
import 'my_location_list.dart';

class SubAccountListScreen extends StatefulWidget {
  final String accountId;
  final String? accountName;

  const SubAccountListScreen({
    super.key,
    required this.accountId,
    required this.accountName,
  });

  @override
  State<SubAccountListScreen> createState() => _SubAccountListScreenState();
}

class _SubAccountListScreenState extends State<SubAccountListScreen>
    with TickerProviderStateMixin {
  bool _isExpanded = false;
  Timer? _debounce;
  bool _showNotificationDot = true;
  TabController? _tabController;
  Screens _selectedScreen = Screens.subAccountList;
  TextEditingController _textEditingController = TextEditingController();
  TextEditingController mobileController = TextEditingController();
  TextEditingController _messageController = TextEditingController();

  String? _uploadedFileName;
  TextEditingController _sovNameController = TextEditingController();

  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

// Add a new controller at the top of the state class:
  TextEditingController _subAccountSearchController = TextEditingController();
  bool showCheckbox = false;
  bool isLoading = false;

  Timer? deBouncer;

  TextEditingController _subAccountEditNameController = TextEditingController();

  int _selectedAccountIndex = 0;

  late File files;

  String _subAccountQuery = "";
  bool _subAccountAlreadyExists = false;
  SubAccounts? _selectedSubAccount;
  String _autocompleteText = "";
  bool isPgAdmin = false;
  bool isAdmin = false;
  bool isSuperAdmin = false;
  bool isIndivudual = false;
  List<TargetFocus> targets = [];
  GlobalKey keyFeature1 = GlobalKey();
  bool _showOverlay_subaccount = false;
  Timer? autoCompleteDeBouncer;

  ScrollController _scrollController = ScrollController();

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
      _subAccountQuery = query;
      var provider =
          Provider.of<SubAccountListProvider>(context, listen: false);
      provider.page = 1;
      await provider.fetchSubAccountList(
          context, widget.accountId, _subAccountQuery, provider.page, 6);
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
    autoCompleteDebounce(() async {
      if (!mounted) return;
      var provider =
          Provider.of<SubAccountListProvider>(context, listen: false);
      await provider.fetchAutoCompleteSubAccountList(
          context, query, widget.accountId);

      // Force UI update after API call
      if (mounted) {
        setState(() {
          print("setState called after fetchAutoCompleteAccountList");
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();

    Future.microtask(() => _getData());

    // Delay until after first frame for Provider + TabController
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFirstTime();

      final userProfileProvider =
          Provider.of<UserProfileProvider>(context, listen: false);

      final trialStatus = userProfileProvider.trialInfo['status'] ?? '';
      int tabCount = trialStatus.isEmpty ? 2 : 2;
      _scrollController = ScrollController();
      // 🟢 Create TabController ONLY after UI is mounted
      _tabController = TabController(length: tabCount, vsync: this);

      if (mounted) setState(() {});
    });
  }

  Future<void> _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstTime = prefs.getBool('isFirstTimeSubAccount') ?? true;
    if (isFirstTime) {
      setState(() => _showOverlay_subaccount = true);
    }
  }

  Future<void> _closeOverlay() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
        'isFirstTimeSubAccount', false); // 👈 save only when user closes it
    setState(() => _showOverlay_subaccount = false);
  }

  _getData() async {
    isPgAdmin = await SharedPreferenceService.getClaimForSubfeature(
            SharedPreferenceService.IS_PG_ADMIN) ??
        false;
    isAdmin = await SharedPreferenceService.getClaimForSubfeature(
            SharedPreferenceService.IS_ADMIN) ??
        false;
    isSuperAdmin = await SharedPreferenceService.getClaimForSubfeature(
            SharedPreferenceService.IS_SUPER_ADMIN) ??
        false;
    isIndivudual = await SharedPreferenceService.getClaimForSubfeature(
            SharedPreferenceService.Is_Indivudual) ??
        false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SubAccountListProvider>(context, listen: false).page = 1;
      Provider.of<SubAccountListProvider>(context, listen: false)
          .fetchSubAccountList(context, widget.accountId, "", 1, 3);
    });
    setState(() {
      _selectedScreen = Screens.accountList;
    });
  }

  @override
  Widget build(BuildContext context1) {
    var typography = CustomTypography(context1);
    return SafeArea(
      child: Consumer<ThemeProvider>(
          builder: (buildContext, themeProvider, child) {
        return Scaffold(
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
          floatingActionButton: showCheckbox
              ? Builder(builder: (contextLocal) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FloatingActionButton(
                        onPressed: () {
                          // On export button click
                        },
                        child: Icon(CupertinoIcons.tray_arrow_down),
                      ),
                      SizedBox(
                        height: CustomSpacing.two,
                      ),
                      FloatingActionButton(
                        onPressed: () {
                          _tabController?.animateTo(1);
                          _selectedScreen = Screens.networkList;
                        },
                        child: Icon(Icons.add),
                      ),
                    ],
                  );
                })
              : Container(
                  key: keyFeature1,
                  padding: EdgeInsets.only(bottom: 43),
                  child: FloatingActionButton(
                    onPressed: () {
                      // Add sub account dialog with autocomplete from api and create account
                      _closeOverlay();
                      _showAddSubAccountDialog(context);
                    },
                    child: Icon(Icons.add),
                  ),
                ),
          // : SizedBox(),
          body: Selector<UserProfileProvider, Tuple3<bool, bool, bool>>(
            selector: (_, provider) => Tuple3(
              provider.isLoading,
              provider.hasError,
              provider.isDataFetched,
            ),
            builder: (context, tuple, child) {
              final isLoading = tuple.item1;
              final hasError = tuple.item2;
              final isDataFetched = tuple.item3;

              return PopScope(
                canPop: true,
                onPopInvoked: (canPop) {
                  debugPrint(
                      'Can Pop: $canPop, Selected Screen: $_selectedScreen');
                },
                child: Stack(
                  children: [
                    // ✅ Keep background image OUTSIDE rebuild scope (using child)
                    if (child != null) child,
                    Column(
                      children: [
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: CustomSpacing.one),

                                // Header Row
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10.0),
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: [
                                        InkWell(
                                          onTap: () {
                                            Navigator.pushAndRemoveUntil(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    AccountListScreen(),
                                              ),
                                              (route) => false,
                                            );
                                          },
                                          child: Text(
                                            widget.accountName.toString(),
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          ' > ',
                                          style: typography.InputLabel,
                                        ),
                                        Text(
                                          LanguageService.getTranslated(
                                              context, "sub_accounts"),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Padding(
                                //   padding: const EdgeInsets.symmetric(
                                //       horizontal: 10.0),
                                //   child: Row(
                                //     children: [
                                //       InkWell(
                                //         onTap: () {
                                //           Navigator.pushAndRemoveUntil(
                                //             context,
                                //             MaterialPageRoute(
                                //                 builder: (_) =>
                                //                     AccountListScreen()),
                                //             (route) => false,
                                //           );
                                //         },
                                //         child: Text(
                                //           widget.accountName.toString(),
                                //           style: const TextStyle(
                                //               fontSize: 14,
                                //               color: Colors.white70),
                                //         ),
                                //       ),
                                //       Text(' > ', style: typography.InputLabel),
                                //       Text(
                                //           LanguageService.getTranslated(
                                //               context, "sub_accounts"),
                                //           style: TextStyle(
                                //               fontSize: 14,
                                //               color: Colors.white)),
                                //     ],
                                //   ),
                                // ),

                                SizedBox(height: CustomSpacing.two),

                                Container(
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHigh,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  margin: EdgeInsets.symmetric(
                                      horizontal: 0, vertical: 0),
                                  child: DefaultTabController(
                                    length: _tabController!.length,
                                    child: Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.arrow_left,
                                              color: Colors.grey),
                                          onPressed: _scrollLeft,
                                        ),
                                        Expanded(
                                          child: Selector<
                                              SubAccountListProvider,
                                              Tuple2<bool, int>>(
                                            selector: (_, subAccountList) =>
                                                Tuple2(
                                              subAccountList.isLoading,
                                              subAccountList.totalRecords,
                                            ),
                                            builder: (context, subTuple, _) {
                                              final isSubLoading =
                                                  subTuple.item1;
                                              final total = subTuple.item2;

                                              return SingleChildScrollView(
                                                controller: _scrollController,
                                                scrollDirection:
                                                    Axis.horizontal,
                                                child: TabBar(
                                                  onTap: (index) {
                                                    debugPrint(
                                                        'Tab clicked: $index');

                                                    if (index == 0) {
                                                      _getData();
                                                    }
                                                  },
                                                  controller: _tabController,
                                                  isScrollable: true,
                                                  tabAlignment:
                                                      TabAlignment.start,
                                                  labelStyle:
                                                      typography.Subtitle2,
                                                  indicatorColor:
                                                      Colors.lightBlueAccent,
                                                  labelColor:
                                                      Colors.lightBlueAccent,
                                                  unselectedLabelColor:
                                                      Colors.white,
                                                  tabs: [
                                                    Tab(
                                                      child: Row(
                                                        children: [
                                                          Text(
                                                            LanguageService
                                                                .getTranslated(
                                                                    context,
                                                                    "my_sub_accounts"),
                                                          ),
                                                          if (!isSubLoading &&
                                                              total > 0)
                                                            SizedBox(
                                                                width:
                                                                    CustomSpacing
                                                                        .two),
                                                          if (!isSubLoading &&
                                                              total > 0)
                                                            SizedBox(
                                                              height: 25,
                                                              child: Chip(
                                                                labelPadding:
                                                                    EdgeInsets
                                                                        .zero,
                                                                materialTapTargetSize:
                                                                    MaterialTapTargetSize
                                                                        .shrinkWrap,
                                                                label: Text(
                                                                  total
                                                                      .toString(),
                                                                  style: typography
                                                                          .BottomNavigationActiveLabel
                                                                      .copyWith(
                                                                          height:
                                                                              -0.6),
                                                                ),
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                    // const Tab(text: 'Shared'),
                                                    // if (isSuperAdmin ||
                                                    //     isPgAdmin)
                                                    Tab(
                                                      text: LanguageService
                                                          .getTranslated(
                                                              context,
                                                              "configuration"),
                                                    ),
                                                    // const Tab(
                                                    //     text:
                                                    //         'Access Requested'),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.arrow_right,
                                              color: Colors.grey),
                                          onPressed: _scrollRight,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Consumer<SubAccountListProvider>(
                                    builder:
                                        (context, subaccountlistprovider, _) {
                                      return TabBarView(
                                        controller: _tabController,
                                        children: [
                                          _getSubAccountUI(),
                                          // if (isSuperAdmin || isPgAdmin)
                                          ConfigurationTab(
                                            subAccountName:
                                                subaccountlistprovider
                                                    .showAccountName,
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (_showOverlay_subaccount) _buildOverlay(),
                  ],
                ),
              );
            },

            // ✅ Background image outside rebuild
            child: Positioned.fill(
              child: Image.asset(
                'assets/images/mesh.png',
                fit: BoxFit.cover,
              ),
            ),
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
                  "Add a Sub Account",
                  style: TextStyle(
                    color: AppColors.primaryMain,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  "Create multiple portfolios under a single primary client entity. Perfect for managing different regions, teams, or buildings separately. ",
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
                        _showAddSubAccountDialog(context);
                      }, //_closeOverlay,
                      child: const Text("Add Sub Account",
                          style: TextStyle(color: Colors.black)),
                    ),
                  ],
                ),
                // const SizedBox(height: 16),
                // const Text(
                //   "New Account",
                //   style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                // ),
                // const SizedBox(height: 8),
                // const Text(
                //   "Create a primary account to organize your sub accounts and locations.",
                //   // textAlign: TextAlign.center,
                // ),
                // const SizedBox(height: 20),
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //   children: [
                //     TextButton(
                //       onPressed: _closeOverlay,
                //       child: const Text("Skip"),
                //     ),
                //     ElevatedButton(
                //       onPressed: _closeOverlay,
                //       child: const Text("Add Account"),
                //     ),
                //   ],
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubAccountCard(
      int index, SubAccountListProvider subAccountListProvider) {
    var typography = CustomTypography(context);
    bool isDisabled = subAccountListProvider.subAccountList[index].disabled;
    return Container(
      margin: EdgeInsets.only(top: 0.0, bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        /*onLongPress: () {
          // Show checkbox
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              showCheckbox = !showCheckbox;
            });
          });
          setState(() {
            accountListProvider.accountList[index].isChecked =
            !(accountListProvider.accountList[index].isChecked??false);
          });

        },*/
        // In _buildSubAccountCard, replace the onTap navigation block:
        onTap: isDisabled
            ? null
            : () {
                if (showCheckbox) {
                  setState(() {
                    subAccountListProvider.subAccountList[index].isChecked =
                        !(subAccountListProvider
                                .subAccountList[index].isChecked ??
                            false);
                  });
                }
                if (subAccountListProvider.subAccountList
                    .every((element) => element.isChecked == false)) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    setState(() => showCheckbox = false);
                  });
                }

                // ✅ FIX: Clear stale location data BEFORE navigating
                final locationProvider =
                    Provider.of<MyLocationListProvider>(context, listen: false);
                locationProvider.myLocationList.clear();
                locationProvider.certifiedLocationList.clear();
                locationProvider.page = 1;
                locationProvider.certifiedPage = 1;

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MyLocationList(
                      accountID: subAccountListProvider
                          .subAccountList[index].accountId
                          .toString(),
                      subAccountID: subAccountListProvider
                          .subAccountList[index].subAccountId
                          .toString(),
                      accountName: widget.accountName ?? "",
                      subAccountName:
                          subAccountListProvider.subAccountList[index].name ??
                              "",
                    ),
                  ),
                );
              },
        // onTap: isDisabled
        //     ? null
        //     : () {
        //         // On tap of card
        //
        //         if (showCheckbox) {
        //           setState(() {
        //             subAccountListProvider.subAccountList[index].isChecked =
        //                 !(subAccountListProvider
        //                         .subAccountList[index].isChecked ??
        //                     false);
        //           });
        //         }
        //         // if all are unselected then hide checkbox
        //         if (subAccountListProvider.subAccountList
        //             .every((element) => element.isChecked == false)) {
        //           WidgetsBinding.instance.addPostFrameCallback((_) {
        //             setState(() {
        //               showCheckbox = false;
        //             });
        //           });
        //         }
        //         Navigator.push(
        //             context,
        //             MaterialPageRoute(
        //                 builder: (context) => MyLocationList(
        //                       accountID: subAccountListProvider
        //                           .subAccountList[index].accountId
        //                           .toString(),
        //                       subAccountID: subAccountListProvider
        //                           .subAccountList[index].subAccountId
        //                           .toString(),
        //                       accountName: widget.accountName ?? "",
        //                       subAccountName: subAccountListProvider
        //                               .subAccountList[index].name ??
        //                           "",
        //                     )));
        //         // Navigator.push(context, MaterialPageRoute(builder: (context) {
        //         //   return /* LocationProfile(
        //         //     account: accountListProvider.accountList[index],
        //         //   );*/
        //         //     MyLocationList(accountID: widget.accountId, subAccountID: subAccountListProvider.subAccountList[index].subAccountId ?? "", accountName: widget.accountName??"", subAccountName: subAccountListProvider.subAccountList[index].name??"",);
        //         // }));
        //       },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Card(
                    color: isDisabled
                        ? Theme.of(context).colorScheme.scrim
                        : Theme.of(context).colorScheme.surface,
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: CustomSpacing.three,
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: CustomSpacing.two,
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          (subAccountListProvider
                                                          .subAccountList[index]
                                                          .name ??
                                                      "")
                                                  .isNotEmpty
                                              ? subAccountListProvider
                                                  .subAccountList[index].name!
                                              : "",
                                          style: typography.Body2.copyWith(
                                            color:
                                                Theme.of(context).brightness ==
                                                        Brightness.dark
                                                    ? AppColors.white
                                                    : AppColors.black,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      // Add edit icon and on tap show edit dialog
                                      SizedBox(
                                        width: CustomSpacing.two,
                                      ),
                                      isDisabled
                                          ? SizedBox()
                                          : InkWell(
                                              onTap: () {
                                                _subAccountEditNameController
                                                    .text = (subAccountListProvider
                                                                .subAccountList[
                                                                    index]
                                                                .name ??
                                                            "")
                                                        .isNotEmpty
                                                    ? subAccountListProvider
                                                            .subAccountList[
                                                                index]
                                                            .name!
                                                            .substring(0, 1)
                                                            .toUpperCase() +
                                                        subAccountListProvider
                                                            .subAccountList[
                                                                index]
                                                            .name!
                                                            .substring(1)
                                                    : "";
                                                // Show edit dialog
                                                showDialog(
                                                  barrierDismissible: false,
                                                  context: context,
                                                  builder: (context) {
                                                    return AlertDialog(
                                                      title: Text(
                                                        LanguageService
                                                            .getTranslated(
                                                                context,
                                                                "edit_sub_account"),
                                                        style: typography
                                                            .H5_Regular,
                                                      ),
                                                      content: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          TextField(
                                                            controller:
                                                                _subAccountEditNameController,
                                                            decoration:
                                                                InputDecoration(
                                                              border:
                                                                  OutlineInputBorder(),
                                                              labelText: LanguageService
                                                                  .getTranslated(
                                                                      context,
                                                                      "sub_account_name"),
                                                              labelStyle:
                                                                  typography
                                                                      .Body1,
                                                              hintText: LanguageService
                                                                  .getTranslated(
                                                                      context,
                                                                      "sub_account_list_app_edit_label_hint_text"),
                                                              hintStyle:
                                                                  typography
                                                                      .Body1,
                                                            ),
                                                          ),
                                                          SizedBox(
                                                            height:
                                                                CustomSpacing
                                                                    .two,
                                                          ),
                                                          Row(
                                                            children: [
                                                              Expanded(
                                                                child:
                                                                    CustomButton(
                                                                  onPressed:
                                                                      () {
                                                                    // Cancel
                                                                    Navigator.pop(
                                                                        context);
                                                                  },
                                                                  child: Text(
                                                                    LanguageService.getTranslated(
                                                                        context,
                                                                        "cancel"),
                                                                    style: typography
                                                                        .ButtonLarge,
                                                                  ),
                                                                  type:
                                                                      ButtonType
                                                                          .text,
                                                                ),
                                                              ),
                                                              Consumer<
                                                                      SubAccountListProvider>(
                                                                  builder: (context,
                                                                      subAccountListProvider,
                                                                      _) {
                                                                return subAccountListProvider
                                                                        .isRenameLoading
                                                                    ? const Expanded(
                                                                        child:
                                                                            Row(
                                                                          mainAxisAlignment:
                                                                              MainAxisAlignment.center,
                                                                          children: [
                                                                            SizedBox(
                                                                                width: 25,
                                                                                height: 25,
                                                                                child: CircularProgressIndicator()),
                                                                          ],
                                                                        ),
                                                                      )
                                                                    : Expanded(
                                                                        child:
                                                                            CustomButton(
                                                                          onPressed:
                                                                              () async {
                                                                            if (_subAccountEditNameController.text.isEmpty) {
                                                                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                                                                  content: Text(
                                                                                LanguageService.getTranslated(context, "sub_account_list_app_rename_sub_account_empty_text_error"),
                                                                              )));
                                                                              return;
                                                                            }
                                                                            // Update account details
                                                                            await subAccountListProvider.renameSubAccount(
                                                                                context,
                                                                                widget.accountId,
                                                                                subAccountListProvider.subAccountList[index].subAccountId!,
                                                                                _subAccountEditNameController.text);
                                                                            Navigator.pop(context);
                                                                          },
                                                                          child:
                                                                              Text(
                                                                            LanguageService.getTranslated(context,
                                                                                "submit"),
                                                                            style:
                                                                                typography.ButtonLargeBlack,
                                                                          ),
                                                                          type:
                                                                              ButtonType.elevated,
                                                                        ),
                                                                      );
                                                              }),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                );
                                              },
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(10.0),
                                                child: Icon(
                                                  Icons.edit,
                                                  color: Theme.of(context)
                                                              .brightness ==
                                                          Brightness.dark
                                                      ? AppColors.primaryMain
                                                      : AppColors.primaryMain,
                                                  size:
                                                      16, // icon size stays same
                                                ),
                                              ),
                                            ),
                                    ],
                                  ),
                                  !subAccountListProvider.showSovCount
                                      ? SizedBox()
                                      : Row(
                                          children: [
                                            Text(
                                                LanguageService.getTranslated(
                                                    context, "locations_count"),
                                                style: typography.Caption),
                                            SizedBox(
                                              width: CustomSpacing.two,
                                            ),
                                            Text(
                                                subAccountListProvider
                                                        .subAccountList[index]
                                                        .locationCount
                                                        ?.toString() ??
                                                    "0",
                                                style: typography.Caption),
                                          ],
                                        ),
                                  // !subAccountListProvider.showSovCount
                                  //     ? SizedBox()
                                  //     : Row(
                                  //         children: [
                                  //           Text(
                                  //               subAccountListProvider
                                  //                               .subAccountList[
                                  //                                   index]
                                  //                               .sovCount !=
                                  //                           null &&
                                  //                       subAccountListProvider
                                  //                               .subAccountList[
                                  //                                   index]
                                  //                               .sovCount ==
                                  //                           1
                                  //                   ? LanguageService.getTranslated(
                                  //                       context,
                                  //                       "sub_account_list_app_sov_text")
                                  //                   : subAccountListProvider
                                  //                               .subAccountList[
                                  //                                   index]
                                  //                               .sovCount ==
                                  //                           null
                                  //                       ? ""
                                  //                       : LanguageService
                                  //                           .getTranslated(
                                  //                               context,
                                  //                               "sub_account_list_app_sovs_text"),
                                  //               style: typography.Caption),
                                  //           SizedBox(
                                  //             width: CustomSpacing.two,
                                  //           ),
                                  //           Text(
                                  //               subAccountListProvider
                                  //                       .subAccountList[index]
                                  //                       .sovCount
                                  //                       ?.toString() ??
                                  //                   "",
                                  //               style: typography.Caption),
                                  //         ],
                                  //       ),
                                  !subAccountListProvider.showOwner
                                      ? SizedBox()
                                      : Row(
                                          children: [
                                            Text(
                                                LanguageService.getTranslated(
                                                    context, "owner"),
                                                style: typography.Caption),
                                            SizedBox(
                                              width: CustomSpacing.two,
                                            ),
                                            Container(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width /
                                                  1.8,
                                              child: Text(
                                                  subAccountListProvider
                                                          .subAccountList[index]
                                                          .owner
                                                          ?.name
                                                          .toString() ??
                                                      "",
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: typography.Caption),
                                            ),
                                          ],
                                        ),
                                ],
                              ),
                            ),
                            // Favourite icon on the right side corner
                            Consumer<SubAccountListProvider>(
                              builder: (context, provider, child) {
                                final subAccount =
                                    provider.subAccountList[index];

                                return Container(
                                  padding: EdgeInsets.only(bottom: 4),
                                  child:
                                      // provider.loadingSubAccountId ==
                                      //         subAccount.subAccountId
                                      //     ? SizedBox(
                                      //         height: 26,
                                      //         width: 26,
                                      //         child: CircularProgressIndicator(
                                      //             strokeWidth: 2),
                                      //       )
                                      //     :
                                      IconButton(
                                    icon: Icon(
                                      subAccount.isDefault == true
                                          ? Icons.star
                                          : Icons.star_border,
                                      size: 26,
                                      color: subAccount.isDefault == true
                                          ? AppColors.primaryMain
                                          : AppColors.primaryMain,
                                    ),
                                    onPressed: () async {
                                      final hasExistingFavorite = provider
                                          .subAccountList
                                          .any((e) => e.isDefault == true);

                                      if (!hasExistingFavorite) {
                                        _showSubAccountBottomSheet(
                                          context: context,
                                          provider: provider,
                                          accountId: widget.accountId,
                                          subAccountId:
                                              subAccount.subAccountId!,
                                          currentStatus:
                                              subAccount.isDefault ?? false,
                                          title: "Mark as Favorite?",
                                          description:
                                              "This sub-account will be saved as your preferred view and will be redirected to this page by default on future logins. The parent account will be automatically marked as favorite.",
                                        );
                                      } else if (subAccount.isDefault == true) {
                                        _showSubAccountBottomSheet(
                                          context: context,
                                          provider: provider,
                                          accountId: widget.accountId,
                                          subAccountId:
                                              subAccount.subAccountId!,
                                          currentStatus:
                                              subAccount.isDefault ?? false,
                                          title: "Remove Favorite Sub-Account?",
                                          description:
                                              "Removing the favorite status from this sub-account will update your default landing view. If no other sub-accounts under this account are marked as favorite, the parent account will also lose its favorite status.",
                                        );
                                      } else {
                                        _showSubAccountBottomSheet(
                                          context: context,
                                          provider: provider,
                                          accountId: widget.accountId,
                                          subAccountId:
                                              subAccount.subAccountId!,
                                          currentStatus:
                                              subAccount.isDefault ?? false,
                                          title: "Change Favorite Sub-Account?",
                                          description:
                                              "This sub-account will be saved as your preferred view and will be redirected to this page by default on future logins. The parent account will be automatically marked as favorite.",
                                        );
                                      }
                                    },
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        SizedBox(
                          height: CustomSpacing.two,
                        ),
                      ],
                    ),
                  ),
                  isDisabled
                      ? SizedBox()
                      : Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceVariant,
                            // bottom left and right corners curved
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(8),
                              bottomRight: Radius.circular(8),
                            ),
                          ),
                          child: Row(
                            children: [
                              // Icon with text
                              // TextButton.icon(
                              //   onPressed: () {
                              //     // Transfer account
                              //     _showTransferDialog(
                              //         context,
                              //         subAccountListProvider
                              //             .subAccountList[index]);
                              //   },
                              //   icon: const Icon(Symbols.share_windows),
                              //   label: Text('Transfer',
                              //       style: typography.Caption.copyWith(
                              //           color: Theme.of(context).brightness ==
                              //                   Brightness.dark
                              //               ? AppColors.white
                              //               : AppColors.black)),
                              // ),
                              //SizedBox(),
                              const Spacer(),
                              /*IconButton(
                          icon: const Icon(Icons.upload_rounded),
                          color: AppColors.primaryMain,
                          onPressed: () async {
                            setState(() {
                              _uploadedFileName = null;
                              _sovNameController.clear();
                            });
                            _showUploadDialog(subAccountListProvider.subAccountList[index].accountId.toString(), subAccountListProvider.subAccountList[index].subAccountId.toString());
                          },
                          tooltip: LanguageService.getTranslated(
                              context, "sub_account_list_app_export_tooltip_text"),
                        ),*/
                              IconButton(
                                icon: const Icon(Icons.file_copy_rounded),
                                color: AppColors.primaryMain,
                                onPressed: () {
                                  // Show duplicate dialog
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: Text(
                                          LanguageService.getTranslated(
                                              context, "duplicate_sub_account"),
                                          style: typography.H5_Regular,
                                        ),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              LanguageService.getTranslated(
                                                  context,
                                                  "confirm_duplicate_sub_account"),
                                              style: typography.Body1,
                                            ),
                                            SizedBox(
                                              height: CustomSpacing.two,
                                            ),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: CustomButton(
                                                    onPressed: () {
                                                      // Cancel
                                                      Navigator.pop(context);
                                                    },
                                                    child: Text(
                                                      LanguageService
                                                          .getTranslated(
                                                              context,
                                                              "cancel"),
                                                      style: typography
                                                          .ButtonLarge,
                                                    ),
                                                    type: ButtonType.text,
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Consumer<
                                                      SubAccountListProvider>(
                                                    builder: (context, provider,
                                                        child) {
                                                      if (provider
                                                          .isDuplicateLoading) {
                                                        return Center(
                                                          child: SizedBox(
                                                            height: 28,
                                                            width: 28,
                                                            child:
                                                                CircularProgressIndicator(
                                                                    strokeWidth:
                                                                        2),
                                                          ),
                                                        );
                                                      }

                                                      return CustomButton(
                                                        onPressed: () async {
                                                          // 👉 START LOADER
                                                          provider.isDuplicateLoading =
                                                              true;
                                                          provider
                                                              .notifyListeners();

                                                          try {
                                                            // 1️⃣ Duplicate Sub Account
                                                            await provider
                                                                .duplicateSubAccount(
                                                              context,
                                                              widget.accountId,
                                                              provider
                                                                  .subAccountList[
                                                                      index]
                                                                  .subAccountId!,
                                                            );

                                                            // 2️⃣ Refresh Sub Account List
                                                            await provider
                                                                .fetchSubAccountList(
                                                              context,
                                                              widget.accountId,
                                                              _subAccountQuery,
                                                              1,
                                                              3,
                                                            );

                                                            // 3️⃣ Close dialog after everything completes
                                                            Navigator.pop(
                                                                context);
                                                          } finally {
                                                            // 👉 STOP LOADER
                                                            provider.isDuplicateLoading =
                                                                false;
                                                            provider
                                                                .notifyListeners();
                                                          }
                                                        },
                                                        child: Text(
                                                          LanguageService
                                                              .getTranslated(
                                                            context,
                                                            "duplicate",
                                                          ),
                                                        ),
                                                        type:
                                                            ButtonType.elevated,
                                                      );
                                                    },
                                                  ),
                                                )
                                              ],
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                                tooltip: LanguageService.getTranslated(context,
                                    "sub_account_list_app_duplicate_tooltip_text"),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                color: AppColors.primaryMain,
                                onPressed: () {
                                  // Show Delete Account dialog
                                  showDialog(
                                    barrierDismissible: false,
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: Text(
                                          LanguageService.getTranslated(
                                              context, "delete_account"),
                                          style: typography.H5_Regular,
                                        ),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              LanguageService.getTranslated(
                                                  context,
                                                  "confirm_delete_account"),
                                              style: typography.Body1,
                                            ),
                                            SizedBox(
                                              height: CustomSpacing.two,
                                            ),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: CustomButton(
                                                    onPressed: () {
                                                      // Cancel
                                                      Navigator.pop(context);
                                                    },
                                                    child: Text(
                                                      LanguageService
                                                          .getTranslated(
                                                              context,
                                                              "cancel"),
                                                      style: typography
                                                          .ButtonLarge,
                                                    ),
                                                    type: ButtonType.text,
                                                  ),
                                                ),
                                                subAccountListProvider
                                                        .isDuplicateLoading
                                                    ? const Expanded(
                                                        child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            SizedBox(
                                                                width: 25,
                                                                height: 25,
                                                                child:
                                                                    CircularProgressIndicator()),
                                                          ],
                                                        ),
                                                      )
                                                    : Expanded(
                                                        child: Consumer<
                                                            SubAccountListProvider>(
                                                          builder: (context,
                                                              provider, child) {
                                                            final isLoading =
                                                                provider
                                                                    .isDeleting; // ✅ use provider state

                                                            return CustomButton(
                                                              type: ButtonType
                                                                  .elevated,
                                                              onPressed: isLoading
                                                                  ? null // disable button during loading
                                                                  : () async {
                                                                      provider.setDeleting(
                                                                          true); // START LOADER

                                                                      bool
                                                                          isSuccess =
                                                                          false;

                                                                      try {
                                                                        isSuccess =
                                                                            await provider.deleteAccount(
                                                                          context,
                                                                          provider
                                                                              .subAccountList[index]
                                                                              .accountId!,
                                                                          provider
                                                                              .subAccountList[index]
                                                                              .subAccountId!,
                                                                        );
                                                                      } catch (e) {
                                                                        print(
                                                                            "Delete error: $e");
                                                                      }

                                                                      if (isSuccess) {
                                                                        Navigator.pop(
                                                                            context);

                                                                        await provider
                                                                            .fetchSubAccountList(
                                                                          context,
                                                                          widget
                                                                              .accountId,
                                                                          _subAccountQuery,
                                                                          1,
                                                                          6,
                                                                        );
                                                                      }

                                                                      provider.setDeleting(
                                                                          false); // STOP LOADER
                                                                    },
                                                              child: isLoading
                                                                  ? SizedBox(
                                                                      height:
                                                                          22,
                                                                      width: 22,
                                                                      child:
                                                                          CircularProgressIndicator(
                                                                        strokeWidth:
                                                                            2,
                                                                        color: Colors
                                                                            .white,
                                                                      ),
                                                                    )
                                                                  : Text(LanguageService
                                                                      .getTranslated(
                                                                          context,
                                                                          "delete")),
                                                            );
                                                          },
                                                        ),
                                                      )
                                              ],
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                                tooltip: 'Delete',
                              ),
                            ],
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

  Future<void> _showAddSubAccountDialog(BuildContext context) async {
    var typography = CustomTypography(context);
    await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 500,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        LanguageService.getTranslated(
                            context, "add_sub_account"),
                        style: typography.H5_Regular,
                      ),
                      SizedBox(height: 8.0),
                      Consumer<SubAccountListProvider>(
                        builder: (context, subAccountListProvider, child) {
                          return Column(
                            children: [
                              // Chip with Account Name
                              Chip(
                                label: Text(
                                  widget.accountName ?? "",
                                  style: typography.Body1,
                                ),
                              ),
                              SizedBox(
                                height: 8,
                              ),
                              TextField(
                                controller: _textEditingController,
                                // focusNode: FocusNode(),
                                onChanged: (value) {
                                  setState(() {
                                    _subAccountAlreadyExists = false;
                                    _selectedSubAccount = null;
                                    subAccountListProvider
                                        .clearAutoCompleteList();
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
                                  labelText: LanguageService.getTranslated(
                                      context, "sub_account_name"),
                                  hintText: LanguageService.getTranslated(
                                      context,
                                      "sub_account_list_app_account_name_field_hint"),
                                  border: const OutlineInputBorder(),
                                ),
                              ),

                              if (_textEditingController.text.isNotEmpty &&
                                  !_subAccountAlreadyExists)
                                AutocompleteOptionsSubAccount(
                                  options: subAccountListProvider
                                      .autoCompleteSubAccountList,
                                  onSelected: (SubAccounts selection) {
                                    setState(() {
                                      _subAccountAlreadyExists = true;
                                      _selectedSubAccount = selection;
                                      _textEditingController.text =
                                          selection.name!;
                                      // Clear the autocomplete list when an option is selected
                                      subAccountListProvider
                                          .clearAutoCompleteList();
                                    });
                                  },
                                  isLoading: subAccountListProvider
                                      .isAutoCompleteLoading,
                                ),
                              // if (_subAccountAlreadyExists)
                              //   Padding(
                              //     padding: const EdgeInsets.only(top: 16.0),
                              //     child: TextField(
                              //       controller: _messageController,
                              //       decoration: InputDecoration(
                              //         labelText: LanguageService.getTranslated(
                              //             context,
                              //             "sub_account_list_app_comment_text"),
                              //         hintText: LanguageService.getTranslated(
                              //             context,
                              //             "sub_account_list_app_comment_placeholder"),
                              //         border: const OutlineInputBorder(),
                              //       ),
                              //       maxLines: 3,
                              //     ),
                              //   ),
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
                                child: Consumer<SubAccountListProvider>(builder:
                                    (context, subAccountListProvider, _) {
                                  return subAccountListProvider
                                          .isAddSubAccountLoading
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
                                                    "sub_account_list_app_add_sub_account_empty_text_error"),
                                                style: TextStyle(
                                                    color: Colors.black),
                                              )));
                                              return;
                                            }
                                            if (!_subAccountAlreadyExists) {
                                              await subAccountListProvider
                                                  .addSubAccount(
                                                      context,
                                                      _autocompleteText,
                                                      widget.accountId);
                                            } else {
                                              if (_messageController
                                                  .text.isEmpty) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(SnackBar(
                                                        content: Text(
                                                  LanguageService.getTranslated(
                                                      context,
                                                      "sub_account_list_app_add_sub_account_empty_text_error"),
                                                  style: TextStyle(
                                                      color: Colors.black),
                                                )));
                                                return;
                                              }
                                              await subAccountListProvider
                                                  .requestAccess(
                                                      context,
                                                      _selectedSubAccount
                                                              ?.subAccountId ??
                                                          "",
                                                      _messageController.text,
                                                      widget.accountId);
                                            }
                                            Navigator.pop(context);
                                          },
                                          child: Text(
                                            LanguageService.getTranslated(
                                                context, "submit"),
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
                              Navigator.pop(context);
                            },
                            child: Text(
                              LanguageService.getTranslated(context, "cancel"),
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
      _subAccountAlreadyExists = false;
    });
  }

  void _showUploadDialog(String accountId, String subAccountId) {
    var typography = CustomTypography(context);
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, StateSetter setState) {
            return WillPopScope(
              onWillPop: () async {
                return false; // Disable the back button
              },
              child: AlertDialog(
                backgroundColor: Colors.black87,
                content: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                          LanguageService.getTranslated(
                              context, "account_list_app_account_upload_sov"),
                          textAlign: TextAlign.start,
                          style: typography.Body1),
                      SizedBox(height: 20),
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
                                    String fileNameWithExtension =
                                        file.path.split('/').last;
                                    _uploadedFileName =
                                        fileNameWithExtension.split('.').first;
                                    _sovNameController.text =
                                        _uploadedFileName!;
                                  });
                                }
                              },
                              child: Container(
                                height: 150,
                                width: MediaQuery.of(context).size.width / 1.2,
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
                                        LanguageService.getTranslated(context,
                                            "account_list_app_account_upload_drag_and_drop"),
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
                          : Container(
                              height: 150,
                              width: MediaQuery.of(context).size.width / 1.2,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(Icons.description, size: 25),
                                  SizedBox(height: 10),
                                  Text(
                                    _sovNameController.text,
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
                                      LanguageService.getTranslated(context,
                                          "account_list_app_cancel_text"),
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
                      SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                              LanguageService.getTranslated(context,
                                  "account_list_app_account_sov_name_1"),
                              textAlign: TextAlign.start,
                              style: typography.Body1),
                          Flexible(
                            child: Center(
                              child: Text(widget.accountName ?? "",
                                  textAlign: TextAlign.start,
                                  style: typography.Body1),
                            ),
                          ),
                          Text(
                              LanguageService.getTranslated(context,
                                  "account_list_app_account_sov_name_2"),
                              textAlign: TextAlign.start,
                              style: typography.Body1),
                        ],
                      ),
                      SizedBox(height: 10),
                      TextField(
                        controller: _sovNameController,
                        readOnly: false,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: LanguageService.getTranslated(
                              context, "account_list_app_sov_name"),
                          labelStyle: TextStyle(color: Colors.white),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.blue),
                          ),
                          hintText: LanguageService.getTranslated(
                              context, "account_list_app_account_name_of_sov"),
                          hintStyle: TextStyle(color: Colors.white54),
                        ),
                      ),
                      SizedBox(height: 20),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Consumer<SubAccountListProvider>(
                              builder: (_, subAccountProvider, child) {
                            return subAccountProvider.isImageUploadLoading
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : Container(
                                    width:
                                        MediaQuery.of(context).size.width / 1.2,
                                    child: CustomButton(
                                      onPressed: () async {
                                        String success = (await Provider.of<
                                                    SubAccountListProvider>(
                                                context,
                                                listen: false)
                                            .uploadSovAccount(
                                                context,
                                                files,
                                                accountId,
                                                subAccountId,
                                                _sovNameController.text));

                                        print('Success: $success');
                                        // contain symbol +
                                        if (success.isNotEmpty &&
                                            success.contains('+')) {
                                          print('Inside + success: $success');
                                          // Show popup with title Empty SoV, body: Looks Like, Data has not been specified!! Do you want to continue creating an empty SOV, or abort? with 2 buttons: [create empty SOV]   [abort]
                                          showDialog(
                                              barrierDismissible: false,
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  title: Text(
                                                    /*LanguageService.getTranslated(
                                                        context,
                                                        "account_list_app_empty_sov_title")*/
                                                    'Empty SOV',
                                                    style:
                                                        typography.H5_Regular,
                                                  ),
                                                  content: Column(
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
                                                        height:
                                                            CustomSpacing.two,
                                                      ),
                                                      Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .stretch,
                                                        children: [
                                                          Consumer<
                                                                  UploadSovProvider>(
                                                              builder: (context,
                                                                  uploadSovProvider,
                                                                  child) {
                                                            return uploadSovProvider
                                                                    .isLoading
                                                                ? const Center(
                                                                    child:
                                                                        CircularProgressIndicator(),
                                                                  )
                                                                : CustomButton(
                                                                    onPressed:
                                                                        () async {
                                                                      // Create empty SOV
                                                                      var provider = Provider.of<
                                                                              UploadSovProvider>(
                                                                          context,
                                                                          listen:
                                                                              false);
                                                                      await provider.createEmptySov(
                                                                          context,
                                                                          success);
                                                                      Navigator.pop(
                                                                          context);
                                                                    },
                                                                    child: Text(
                                                                      /*LanguageService.getTranslated(
                                                                      context,
                                                                      "account_list_app_empty_sov_create"),*/
                                                                      'Create',
                                                                      style: typography
                                                                          .ButtonLarge,
                                                                    ),
                                                                    type: ButtonType
                                                                        .elevated,
                                                                  );
                                                          }),
                                                          CustomButton(
                                                            onPressed: () {
                                                              Navigator.pop(
                                                                  context);
                                                            },
                                                            child: Text(
                                                              /*LanguageService.getTranslated(
                                                                  context,
                                                                  "account_list_app_empty_sov_abort")*/
                                                              'Abort',
                                                              style: typography
                                                                  .ButtonLarge,
                                                            ),
                                                            type:
                                                                ButtonType.text,
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              });
                                        } else if (success.isNotEmpty) {
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (_) => MappingScreen(
                                                        tempId: success,
                                                        accountId:
                                                            widget.accountId,
                                                        accountName: widget
                                                                .accountName ??
                                                            "",
                                                      )));
                                        }
                                      },
                                      type: ButtonType.filled,
                                      child: Text(
                                        LanguageService.getTranslated(
                                            context, "login_submit_button"),
                                        style: typography.ButtonLarge,
                                      ),
                                    ),
                                  );
                          }),
                          Container(
                            width: MediaQuery.of(context).size.width / 1.2,
                            child: TextButton(
                              onPressed: () {
                                setState(() {
                                  _uploadedFileName = null;
                                  _sovNameController.clear();
                                });
                                Navigator.of(context).pop();
                              },
                              child: Text(
                                  LanguageService.getTranslated(
                                      context, "account_list_app_cancel_text"),
                                  style: typography.Body1),
                            ),
                          ),
                          SizedBox(width: 10),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          });
        });
  }

  Future<void> _showTransferDialog(
      BuildContext context, SubAccounts subAccount) async {
    var typography = CustomTypography(context);
    TextEditingController _userSearchController = TextEditingController();
    TransferAutocompleteModel? _selectedUser;
    List<TransferAutocompleteModel> _autocompleteUsersList = [];
    bool _isTransferLoading = false;
    bool _isSearching = false;
    Timer? _debounce;

    void _onSearchChanged(String query, StateSetter setState) {
      if (_debounce?.isActive ?? false) _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 500), () async {
        if (query.isNotEmpty) {
          setState(() {
            _isSearching = true;
          });

          _autocompleteUsersList = await fetchAutocompleteUsers(query);

          setState(() {
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

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Dialog(
              child: Container(
                width: 304,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Transfer Sub-Account',
                        style: typography.H5_Regular.copyWith(height: 1.2),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _userSearchController,
                        onChanged: (query) {
                          setState(() {
                            _selectedUser = null;
                          });
                          _onSearchChanged(query, setState);
                        },
                        decoration: InputDecoration(
                          hintText: 'Search for a user to transfer sub-account',
                          border: OutlineInputBorder(),
                          suffixIcon: _isSearching
                              ? Container(
                                  margin: EdgeInsets.fromLTRB(0, 8, 16, 8),
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator())
                              : null,
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Flexible(
                      child: _selectedUser == null
                          ? ListView.builder(
                              shrinkWrap: true,
                              itemCount: _autocompleteUsersList.length,
                              itemBuilder: (context, index) {
                                final user = _autocompleteUsersList[index];
                                return ListTile(
                                  leading: user.imageUrl.isNotEmpty
                                      ? CircleAvatar(
                                          backgroundImage:
                                              NetworkImage(user.imageUrl),
                                        )
                                      : CircleAvatar(
                                          child:
                                              Text(user.name[0].toUpperCase()),
                                        ),
                                  title: Text(user.name),
                                  subtitle: Text(user.email),
                                  onTap: () {
                                    setState(() {
                                      _selectedUser = user;
                                      _userSearchController.text = user.name;
                                    });
                                  },
                                );
                              },
                            )
                          : Padding(
                              padding: EdgeInsets.all(16),
                              child:
                                  Text('Selected User: ${_selectedUser!.name}'),
                            ),
                    ),
                    ButtonBar(
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: Text('Cancel'),
                        ),
                        TextButton(
                          onPressed:
                              _selectedUser != null && !_isTransferLoading
                                  ? () async {
                                      setState(() {
                                        _isTransferLoading = true;
                                      });
                                      var provider =
                                          Provider.of<SubAccountListProvider>(
                                              context,
                                              listen: false);
                                      await provider.transferSubAccount(
                                          context,
                                          widget.accountId,
                                          subAccount.subAccountId!,
                                          _selectedUser!.id);
                                      setState(() {
                                        _isTransferLoading = false;
                                      });
                                      Navigator.pop(dialogContext);
                                    }
                                  : null,
                          child: _isTransferLoading
                              ? CircularProgressIndicator(strokeWidth: 2.0)
                              : Text('Transfer'),
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

  Future<List<TransferAutocompleteModel>> fetchAutocompleteUsers(
      String query) async {
    try {
      ApiService apiService =
          ApiService(AppConstant.TRANSFER_USER_AUTOCOMPLETE);
      String url = '?search=$query';
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

  Widget _getSubAccountUI() {
    var typography = CustomTypography(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: CustomSpacing.four),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${LanguageService.getTranslated(context, "sub_account")} ',
              style: typography.Body1,
            ),
          ],
        ),
        SizedBox(height: CustomSpacing.four),
        // Search
        TextField(
          controller: _subAccountSearchController, // ✅ dedicated controller
          onChanged: (query) {
            accountsSearchClient(query);
          },
          decoration: InputDecoration(
            suffixIcon: _subAccountQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () {
                      _subAccountSearchController
                          .clear(); // ✅ clear correct controller
                      accountsSearchClient("");
                    },
                  )
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            hintText: LanguageService.getTranslated(context, "search"),
            hintStyle: typography.Body2,
          ),
        ),
        // SizedBox(
        //   height: 50,
        //   child: TextField(
        //     controller: _textEditingController,
        //     onChanged: (query) {
        //       accountsSearchClient(query);
        //     },
        //     decoration: InputDecoration(
        //       suffixIcon: _subAccountQuery.isNotEmpty
        //           ? IconButton(
        //               icon: Icon(Icons.clear),
        //               onPressed: () {
        //                 _textEditingController.clear();
        //                 accountsSearchClient("");
        //               },
        //             )
        //           : null,
        //       border: OutlineInputBorder(
        //         borderRadius: BorderRadius.circular(8),
        //       ),
        //       hintText: LanguageService.getTranslated(context, "search"),
        //       hintStyle: typography.Body2,
        //     ),
        //   ),
        // ),
        SizedBox(height: CustomSpacing.two),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Consumer<SubAccountListProvider>(
                builder: (context, subaccountlist, _) {
              return Text(
                  subaccountlist.showAccountName?.trim().isNotEmpty == true
                      ? subaccountlist.showAccountName.toString() == "null"
                          ? "Sub Account Name"
                          : subaccountlist.showAccountName.toString()
                      : 'Sub Account Name');
            }),
          ],
        ),
        SizedBox(height: CustomSpacing.two),
        // List of sub accounts
        Expanded(
          child: Consumer<SubAccountListProvider>(
              builder: (context, subAccountListProvider, _) {
            return RefreshIndicator(
              onRefresh: () async {
                // Call the function to refresh data
                await subAccountListProvider.fetchSubAccountList(
                  context,
                  widget.accountId,
                  _subAccountQuery,
                  1, // Reset to the first page
                  6, // Page size
                  // isRefresh: true, // Optional flag for refresh
                );
              },
              child: subAccountListProvider.isLoading
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
                  : subAccountListProvider.subAccountList.isEmpty
                      ? Center(
                          child: Text(
                            "Looks like you don't have a sub-account yet. No worries! Just create a new one and start adding your locations.",
                            style: typography.Body1,
                          ),
                        )
                      : ListView.builder(
                          itemCount:
                              subAccountListProvider.subAccountList.length,
                          itemBuilder: (context, index) {
                            if (index ==
                                subAccountListProvider.subAccountList.length -
                                    1) {
                              if (subAccountListProvider.isNextPageLoading) {
                                return Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              } else if (subAccountListProvider.page >=
                                      subAccountListProvider.totalPages &&
                                  subAccountListProvider
                                      .subAccountList.isNotEmpty) {
                                // Display end of list message
                                print(
                                    "sub account list: ${subAccountListProvider.subAccountList}");
                                return Column(
                                  children: [
                                    // Text(widget.accountId.toString()),
                                    // Text(subAccountListProvider
                                    //     .subAccountList[0].subAccountId
                                    //     .toString()),Text(subAccountListProvider
                                    //     .subAccountList[1].subAccountId
                                    //     .toString()),
                                    // Text(subAccountListProvider.subaccooun.toString()),
                                    _buildSubAccountCard(
                                        index, subAccountListProvider),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Center(
                                        child: Text(
                                          LanguageService.getTranslated(
                                              context, "end_of_list"),
                                          style: typography.Body1,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              } else {
                                // Trigger fetching the next page
                                subAccountListProvider.page =
                                    subAccountListProvider.page + 1;
                                print(
                                    "Fetching page ${subAccountListProvider.page}");
                                print(
                                    "Query: $_subAccountQuery, Page: ${subAccountListProvider.page}");
                                subAccountListProvider.fetchSubAccountList(
                                  context,
                                  widget.accountId,
                                  _subAccountQuery,
                                  // Pass the search query if any
                                  subAccountListProvider.page,
                                  3, // Page size
                                );
                                return SizedBox();
                              }
                            }

                            return _buildSubAccountCard(
                                index, subAccountListProvider);
                          },
                        ),
            );
          }),
        ),
      ],
    );
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
}

void _showSubAccountBottomSheet({
  required BuildContext context,
  required SubAccountListProvider provider,
  required String accountId,
  required String subAccountId,
  required bool currentStatus,
  required String title,
  required String description,
}) {
  bool isLoading = false;

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isDismissible: !isLoading,
    enableDrag: !isLoading,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF1C1C1E),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),

                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 80),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8BB8E8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: isLoading
                        ? null
                        : () async {
                            setModalState(() {
                              isLoading = true;
                            });

                            final success =
                                await provider.updateDefaultSubAccount(
                              context,
                              accountId,
                              subAccountId,
                              currentStatus,
                            );

                            if (success) {
                              Navigator.pop(context);
                            } else {
                              setModalState(() {
                                isLoading = false;
                              });
                            }
                          },
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Text(
                            "Confirm",
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 12),

                /// CANCEL
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white30),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: isLoading ? null : () => Navigator.pop(context),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),
              ],
            ),
          );
        },
      );
    },
  );
}
