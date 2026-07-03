import 'package:RiskSphere/screens/listings/widgets/auto_complete_options.dart';
import 'package:tuple/tuple.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/global_imports.dart';
import 'package:flutter/cupertino.dart';
import 'package:RiskSphere/models/account_list_model.dart';
import '../payments/purchase_license.dart';

class AccountListScreen extends StatefulWidget {
  static const String routeName = '/accountList';

  const AccountListScreen({
    super.key,
  });

  @override
  State<AccountListScreen> createState() => _AccountListScreenState();
}

class _AccountListScreenState extends State<AccountListScreen>
    with TickerProviderStateMixin {
  bool _isExpanded = false;
  bool _showNotificationDot = true;

  bool isHasAnyPlan = false;
  String? trialMap;
  TabController? _tabController;
  Screens _selectedScreen = Screens.accountList;
  TextEditingController _textEditingController = TextEditingController();
  TextEditingController mobileController = TextEditingController();
  TextEditingController _messageController = TextEditingController();
  TextEditingController _sovNameController = TextEditingController();
  bool isLoading = false;

  final TextEditingController _filePathController = TextEditingController();

  String? _uploadedFileName;
  late final typography = CustomTypography(context);
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool showCheckbox = false;
  Timer? deBouncer;
  TextEditingController _accountEditNameController = TextEditingController();
  Timer? _debounce;
  String _accountQuery = "";
  bool _accountAlreadyExists = false;
  Accounts? _selectedAccount;
  String _autocompleteText = "";
  bool isPgAdmin = false;
  bool isAdmin = false;
  bool isSuperAdmin = false;
  ScrollController _scrollController = ScrollController();
  Timer? autoCompleteDeBouncer;

  late File files;

  void _scrollLeft() {
    _scrollController.animateTo(
      _scrollController.offset - 100,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _scrollRight() {
    _scrollController.animateTo(
      _scrollController.offset + 100,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void debounce(
    VoidCallback callback, {
    Duration duration = const Duration(milliseconds: 300),
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
      var provider = Provider.of<AccountListProvider>(context, listen: false);
      provider.page = 1;
      provider.forceReload = true;
      await provider.fetchAccountList(context, _accountQuery, provider.page, 5);
    });
  }

  void autoCompleteDebounce(
    VoidCallback callback, {
    Duration duration = const Duration(milliseconds: 300),
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
      var provider = Provider.of<AccountListProvider>(context, listen: false);
      await provider.fetchAutoCompleteAccountList(context, query);

      if (mounted) {}
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setClaims();
      _getData();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFirstTime();
    });

    _tabController = TabController(length: 2, vsync: this);
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

  Future<void> _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstTime = prefs.getBool('isFirstTime') ?? true;
    if (isFirstTime) {
      setState(() => _showOverlay = true);
    }
  }

  Future<void> _closeOverlay() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstTime', false);
    setState(() => _showOverlay = false);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _filePathController.dispose();
    super.dispose();
  }

  _getData() async {
    final accountListProvider =
        Provider.of<AccountListProvider>(context, listen: false);

    accountListProvider.fetchAccountList(context, "", 1, 5);

    if (mounted) setState(() => _selectedScreen = Screens.accountList);
  }

  @override
  Widget build(BuildContext context1) {
    var typography = CustomTypography(context);
    return SafeArea(
      child: Consumer<ThemeProvider>(
          builder: (buildContext, themeProvider, child) {
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
            floatingActionButton: _selectedScreen == Screens.accountList
                ? showCheckbox
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
                    : _tabController?.index != 0
                        ? SizedBox()
                        : Container(
                            key: keyFeature1,
                            margin: EdgeInsets.only(bottom: 42.0),
                            child: FloatingActionButton(
                              backgroundColor: AppColors.primaryMain,
                              onPressed: () {
                                _closeOverlay();
                                _showAddAccountDialog(context);
                              },
                              child: Icon(
                                Icons.add,
                                color: Theme.of(context).colorScheme.surface,
                              ),
                            ),
                          )
                : SizedBox(),
            body: Consumer<UserProfileProvider>(
                builder: (context, userProfileProvider, child) {
              final trialStatus = userProfileProvider.trialInfo['status'] ?? '';

              return (trialStatus.contains('Expired') && isHasAnyPlan == false)
                  ? Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surface
                            .withOpacity(0.95),
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
                                      Navigator.of(context).push(
                                          MaterialPageRoute(
                                              builder: (_) =>
                                                  PurchaseLicensePage()));
                                    },
                                ),
                              ],
                              isError: true,
                            ),
                          ),
                        ],
                      ),
                    )
                  : PopScope(
                      canPop: /*_selectedScreen == Screens.connectionList ||
                          _selectedScreen == Screens.corporateConnectionList,*/
                          true,
                      onPopInvoked: (canPop) {},
                      child: Stack(
                        children: [
                          // Background image
                          Positioned.fill(
                            child: Image.asset(
                              'assets/images/mesh.png',
                              fit: BoxFit.cover,
                              color: Colors.white.withOpacity(0.3),
                              colorBlendMode: BlendMode.modulate,
                            ),
                          ),
                          Column(
                            children: [
                              Expanded(
                                child: Container(
                                  margin: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      //
                                      SizedBox(height: CustomSpacing.two),

                                      Container(
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .surfaceContainerHigh,
                                          borderRadius: BorderRadius.circular(
                                              16), // Rounded edges
                                        ),
                                        margin: EdgeInsets.symmetric(
                                            horizontal: 0, vertical: 0),
                                        child: DefaultTabController(
                                          length: _tabController!.length,
                                          child: Column(
                                            children: <Widget>[
                                              // Container for the TabBar with arrows
                                              Container(
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .surfaceContainerHigh,
                                                ),
                                                height: 50,
                                                child: Row(
                                                  children: <Widget>[
                                                    // Left arrow button
                                                    IconButton(
                                                      icon: Icon(
                                                          Icons.arrow_left,
                                                          color: Colors.grey),
                                                      onPressed: _scrollLeft,
                                                    ),
                                                    // Scrollable TabBar
                                                    Expanded(
                                                      child:
                                                          SingleChildScrollView(
                                                        controller:
                                                            _scrollController,
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
                                                          controller:
                                                              _tabController,
                                                          tabAlignment:
                                                              TabAlignment
                                                                  .start,
                                                          labelStyle:
                                                              typography
                                                                  .Subtitle2,
                                                          isScrollable: true,
                                                          indicatorColor: Colors
                                                              .lightBlueAccent,
                                                          labelColor: Colors
                                                              .lightBlueAccent,
                                                          unselectedLabelColor:
                                                              Colors.white,
                                                          tabs: [
                                                            Tab(
                                                              child: Row(
                                                                children: [
                                                                  Text(
                                                                    LanguageService.getTranslated(
                                                                        context,
                                                                        'my_accounts'),
                                                                  ),
                                                                  Consumer<AccountListProvider>(
                                                                    builder: (context, provider, _) {
                                                                      if (provider.isLoading || provider.accountHits == 0) {
                                                                        return const SizedBox();
                                                                      }
                                                                      return Row(
                                                                        mainAxisSize: MainAxisSize.min,
                                                                        children: [
                                                                          SizedBox(
                                                                            width:
                                                                                CustomSpacing.two,
                                                                          ),
                                                                          SizedBox(
                                                                            height:
                                                                                25,
                                                                            child:
                                                                                Chip(
                                                                              labelPadding: const EdgeInsets.all(0),
                                                                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                                              label: Text(
                                                                                provider.accountHits.toString(),
                                                                                style: typography.BottomNavigationActiveLabel.copyWith(height: -0.6),
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      );
                                                                    },
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                            Tab(
                                                              text: LanguageService
                                                                  .getTranslated(
                                                                      context,
                                                                      'configuration'),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                    // Right arrow button
                                                    IconButton(
                                                      icon: Icon(
                                                          Icons.arrow_right,
                                                          color: Colors.grey),
                                                      onPressed: _scrollRight,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      // TabBarView for the tab content
                                      Expanded(
                                        child: TabBarView(
                                          controller: _tabController,
                                          children: [
                                            _getAccountUI(),
                                            Selector<AccountListProvider,
                                                String>(
                                              selector: (_, provider) =>
                                                  provider.showAccountName,
                                              builder: (_, accountName, __) {
                                                return ConfigurationTab(
                                                  accountName: accountName,
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
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
                      child: Text(
                          LanguageService.getTranslated(context, "add_account"),
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

  Widget _buildAccountCard(int index, AccountListProvider accountListProvider) {
    // Option to multiple select using checkbox, show company name, type, Admin Details (Admin Name, Email), Status switch and 2 action icons for Employees and Edit
    bool isDisabled = accountListProvider.accountList[index].disabled ?? false;
    var typography = CustomTypography(context);
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
        onTap: isDisabled
            ? null
            : () {
                // On tap of card

                if (showCheckbox) {
                  setState(() {
                    accountListProvider.accountList[index].isChecked =
                        !(accountListProvider.accountList[index].isChecked ??
                            false);
                  });
                }
                // if all are unselected then hide checkbox
                if (accountListProvider.accountList
                    .every((element) => element.isChecked == false)) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    setState(() {
                      showCheckbox = false;
                    });
                  });
                }
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return /* LocationProfile(
              account: accountListProvider.accountList[index],
            );*/
                      SubAccountListScreen(
                    accountId:
                        accountListProvider.accountList[index].accountId ?? "",
                    accountName:
                        accountListProvider.accountList[index].accountName ??
                            "",
                  );
                }));
              },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /*showCheckbox
                ? Checkbox(
              value: accountListProvider.accountList[index].isChecked??false,
              onChanged: (value) {
                // Handle checkbox value change
                WidgetsBinding.instance
                    .addPostFrameCallback((_) {
                  setState(() {
                    accountListProvider.accountList[index].isChecked = value;
                  });
                });
              },
            )
                : */
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
                          children: [
                            SizedBox(
                              width: CustomSpacing.two,
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Flexible(
                                              child: Text(
                                                (accountListProvider
                                                                .accountList[
                                                                    index]
                                                                .accountName ??
                                                            "")
                                                        .isNotEmpty
                                                    ? accountListProvider
                                                        .accountList[index]
                                                        .accountName!
                                                    : "",
                                                style:
                                                    typography.Body2.copyWith(
                                                  color: Theme.of(context)
                                                              .brightness ==
                                                          Brightness.dark
                                                      ? AppColors.white
                                                      : AppColors.black,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            SizedBox(width: CustomSpacing.two),
                                            if (!isDisabled)
                                              InkWell(
                                                onTap: () {
                                                  _accountEditNameController
                                                      .text = (accountListProvider
                                                                  .accountList[
                                                                      index]
                                                                  .accountName ??
                                                              "")
                                                          .isNotEmpty
                                                      ? accountListProvider
                                                              .accountList[
                                                                  index]
                                                              .accountName!
                                                              .substring(0, 1)
                                                              .toUpperCase() +
                                                          accountListProvider
                                                              .accountList[
                                                                  index]
                                                              .accountName!
                                                              .substring(1)
                                                      : "";
                                                  showDialog(
                                                    barrierDismissible: false,
                                                    context: context,
                                                    builder: (context) {
                                                      return AlertDialog(
                                                        title: Text(
                                                          LanguageService
                                                              .getTranslated(
                                                                  context,
                                                                  "edit_account"),
                                                          style: typography
                                                              .H5_Regular,
                                                        ),
                                                        content: Column(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            TextField(
                                                              controller:
                                                                  _accountEditNameController,
                                                              decoration:
                                                                  InputDecoration(
                                                                border:
                                                                    OutlineInputBorder(),
                                                                labelText: LanguageService
                                                                    .getTranslated(
                                                                        context,
                                                                        "account_name"),
                                                                labelStyle:
                                                                    typography
                                                                        .Body1,
                                                                hintText:
                                                                    'Enter Account Name',
                                                                hintStyle:
                                                                    typography
                                                                        .Body1,
                                                              ),
                                                            ),
                                                            SizedBox(
                                                                height:
                                                                    CustomSpacing
                                                                        .two),
                                                            Row(
                                                              children: [
                                                                Expanded(
                                                                  child:
                                                                      CustomButton(
                                                                    onPressed:
                                                                        () {
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
                                                                    type: ButtonType
                                                                        .text,
                                                                  ),
                                                                ),
                                                                Consumer<
                                                                        AccountListProvider>(
                                                                    builder:
                                                                        (context,
                                                                            accountListProvider,
                                                                            _) {
                                                                  return accountListProvider
                                                                          .isRenameLoading
                                                                      ? const Expanded(
                                                                          child:
                                                                              Row(
                                                                            mainAxisAlignment:
                                                                                MainAxisAlignment.center,
                                                                            children: [
                                                                              SizedBox(width: 25, height: 25, child: CircularProgressIndicator()),
                                                                            ],
                                                                          ),
                                                                        )
                                                                      : Expanded(
                                                                          child:
                                                                              CustomButton(
                                                                            onPressed:
                                                                                () async {
                                                                              if (_accountEditNameController.text.isEmpty) {
                                                                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                                                                  content: Text(
                                                                                    LanguageService.getTranslated(context, "account_list_app_rename_account_empty_text_error"),
                                                                                    style: typography.Body1,
                                                                                  ),
                                                                                ));
                                                                                return;
                                                                              }
                                                                              await accountListProvider.renameAccount(context, accountListProvider.accountList[index].accountId!, _accountEditNameController.text);
                                                                              Navigator.pop(context);
                                                                            },
                                                                            child:
                                                                                Text(
                                                                              LanguageService.getTranslated(context, "submit"),
                                                                              style: typography.ButtonLargeBlack,
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
                                                  padding: const EdgeInsets.all(
                                                      10.0),
                                                  child: Icon(
                                                    Icons.edit,
                                                    color:
                                                        AppColors.primaryMain,
                                                    size: 16,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Spacer(),
                                      Selector<AccountListProvider, bool>(
                                        selector: (_, p) =>
                                            p.accountList[index].isDefault ??
                                            false,
                                        builder: (_, isDefault, __) {
                                          final provider =
                                              Provider.of<AccountListProvider>(
                                                  context,
                                                  listen: false);

                                          return IconButton(
                                            icon: Icon(
                                              isDefault
                                                  ? Icons.star
                                                  : Icons.star_border,
                                              size: 26,
                                              color: AppColors.primaryMain,
                                            ),
                                            onPressed: () async {
                                              final account =
                                                  provider.accountList[index];

                                              if (isDefault) {
                                                _showRemoveFavoriteBottomSheet(
                                                  context,
                                                  provider,
                                                  account.accountId!,
                                                  isDefault,
                                                );
                                              } else {
                                                await provider
                                                    .updateDefaultAccount(
                                                  context,
                                                  account.accountId!,
                                                  isDefault,
                                                );
                                              }
                                            },
                                          );
                                        },
                                      )
                                    ],
                                  ),
                                  !accountListProvider.showSubAccountCount
                                      ? SizedBox()
                                      : Row(
                                          children: [
                                            Text(
                                                accountListProvider
                                                                .accountList[
                                                                    index]
                                                                .subAccountCount !=
                                                            null &&
                                                        accountListProvider
                                                                .accountList[
                                                                    index]
                                                                .subAccountCount ==
                                                            1
                                                    ? LanguageService
                                                        .getTranslated(context,
                                                            "sub_account")
                                                    : accountListProvider
                                                                .accountList[
                                                                    index]
                                                                .subAccountCount ==
                                                            null
                                                        ? ""
                                                        : LanguageService
                                                            .getTranslated(
                                                                context,
                                                                "sub_account"),
                                                style: typography.Caption),
                                            SizedBox(
                                              width: CustomSpacing.two,
                                            ),
                                            Text(
                                                accountListProvider
                                                        .accountList[index]
                                                        .subAccountCount
                                                        ?.toString() ??
                                                    "",
                                                style: typography.Caption),
                                          ],
                                        ),
                                  // !accountListProvider.showSOVCount
                                  //     ? SizedBox()
                                  //     : Row(
                                  //         children: [
                                  //           Text(
                                  //               accountListProvider
                                  //                               .accountList[
                                  //                                   index]
                                  //                               .sovCount !=
                                  //                           null &&
                                  //                       accountListProvider
                                  //                               .accountList[
                                  //                                   index]
                                  //                               .sovCount ==
                                  //                           1
                                  //                   ? LanguageService.getTranslated(
                                  //                       context,
                                  //                       "account_list_app_sov_text")
                                  //                   : accountListProvider
                                  //                               .accountList[
                                  //                                   index]
                                  //                               .sovCount ==
                                  //                           null
                                  //                       ? ""
                                  //                       : LanguageService
                                  //                           .getTranslated(
                                  //                               context,
                                  //                               "account_list_app_sovs_text"),
                                  //               style: typography.Caption),
                                  //           SizedBox(
                                  //             width: CustomSpacing.two,
                                  //           ),
                                  //           Text(
                                  //               accountListProvider
                                  //                       .accountList[index]
                                  //                       .sovCount
                                  //                       ?.toString() ??
                                  //                   "",
                                  //               style: typography.Caption),
                                  //         ],
                                  //       ),
                                  !accountListProvider.showOwner
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
                                                  1.5,
                                              child: Text(
                                                  /*accountListProvider.accountList[index].locationCount?.toString() ??
                                                ""*/
                                                  accountListProvider
                                                          .accountList[index]
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
                            //!accountListProvider.showOverallScore
                            true
                                ? SizedBox()
                                : Padding(
                                    padding:
                                        EdgeInsets.only(top: CustomSpacing.one),
                                    child: CustomGradientCircularProgressBar(
                                      radius: 23,
                                      value: double.parse(accountListProvider
                                              .accountList[index].overallScore
                                              ?.toString() ??
                                          "0"),
                                      strokeWidth: 6,
                                      showText: true,
                                      textColor: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? AppColors.white
                                          : AppColors.black,
                                      text: accountListProvider
                                              .accountList[index].overallScore
                                              ?.toString() ??
                                          "0",
                                    ),
                                  ),
                            SizedBox(
                              width: CustomSpacing.four,
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
                              //     _showTransferDialog(context,
                              //         accountListProvider.accountList[index]);
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
                                  _showUploadDialog(accountListProvider
                                      .accountList[index].accountId
                                      .toString());
                                },
                                tooltip: LanguageService.getTranslated(context,
                                    "account_list_app_export_tooltip_text"),
                              ),*/
                              IconButton(
                                icon: const Icon(Icons.file_copy_rounded),
                                color: AppColors.primaryMain,
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: Text(
                                          LanguageService.getTranslated(
                                              context, "duplicate_account"),
                                          style: typography.H5_Regular,
                                        ),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              LanguageService.getTranslated(
                                                  context,
                                                  "confirm_duplicate_account"),
                                              style: typography.Body1,
                                            ),
                                            SizedBox(height: CustomSpacing.two),

                                            /// BUTTON ROW
                                            Row(
                                              children: [
                                                // CANCEL BUTTON
                                                Expanded(
                                                  child: CustomButton(
                                                    onPressed: () =>
                                                        Navigator.pop(context),
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

                                                SizedBox(width: 12),

                                                Expanded(
                                                    child: Selector<
                                                        AccountListProvider,
                                                        bool>(
                                                  selector: (_, p) =>
                                                      p.isDuplicateLoading,
                                                  builder: (_, isLoading, __) {
                                                    final provider = Provider
                                                        .of<AccountListProvider>(
                                                            context,
                                                            listen: false);

                                                    return isLoading
                                                        ? const Center(
                                                            child: SizedBox(
                                                              height: 28,
                                                              width: 28,
                                                              child:
                                                                  CircularProgressIndicator(
                                                                      strokeWidth:
                                                                          2),
                                                            ),
                                                          )
                                                        : CustomButton(
                                                            onPressed:
                                                                () async {
                                                              provider.isDuplicateLoading =
                                                                  true;
                                                              provider
                                                                  .notifyListeners();

                                                              try {
                                                                await provider
                                                                    .duplicateAccount(
                                                                  context,
                                                                  provider
                                                                      .accountList[
                                                                          index]
                                                                      .accountId!,
                                                                );

                                                                provider.forceReload =
                                                                    true;

                                                                provider
                                                                    .fetchAccountList(
                                                                  context,
                                                                  _accountQuery,
                                                                  1,
                                                                  5,
                                                                );
                                                              } finally {
                                                                provider.isDuplicateLoading =
                                                                    false;
                                                                provider
                                                                    .notifyListeners();
                                                              }

                                                              Navigator.pop(
                                                                  context);
                                                            },
                                                            child: Text(
                                                                "Duplicate"),
                                                            type: ButtonType
                                                                .elevated,
                                                          );
                                                  },
                                                )),
                                              ],
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                                tooltip: LanguageService.getTranslated(
                                    context, "duplicate"),
                              ),
                              // Selector<AccountListProvider, bool>(
                              //   selector: (_, p) => p.isDeleteLocationLoading,
                              //   builder: (_, isLoading, __) {
                              //     final provider =
                              //         Provider.of<AccountListProvider>(context,
                              //             listen: false);
                              //
                              //     return IconButton(
                              //       icon: const Icon(Icons.delete),
                              //       color: AppColors.primaryMain,
                              //       onPressed: () {
                              //         showDialog(
                              //           barrierDismissible: false,
                              //           context: context,
                              //           builder: (context) {
                              //             return AlertDialog(
                              //               content: isLoading
                              //                   ? const Center(
                              //                       child:
                              //                           CircularProgressIndicator())
                              //                   : CustomButton(
                              //                       onPressed: () async {
                              //                         provider.isDeleteLocationLoading =
                              //                             true;
                              //                         provider
                              //                             .notifyListeners();
                              //
                              //                         try {
                              //                           await provider
                              //                               .deleteAccount(
                              //                             context,
                              //                             provider
                              //                                 .accountList[
                              //                                     index]
                              //                                 .accountId!,
                              //                           );
                              //
                              //                           provider.forceReload =
                              //                               true;
                              //                           provider
                              //                               .fetchAccountList(
                              //                             context,
                              //                             _accountQuery,
                              //                             1,
                              //                             5,
                              //                           );
                              //                         } finally {
                              //                           provider.isDeleteLocationLoading =
                              //                               false;
                              //                           provider
                              //                               .notifyListeners();
                              //                         }
                              //
                              //                         Navigator.pop(context);
                              //                       },
                              //                       child: Text("Delete"),
                              //                       type: ButtonType.elevated,
                              //                     ),
                              //             );
                              //           },
                              //         );
                              //       },
                              //     );
                              //   },
                              // )
                              Consumer<AccountListProvider>(
                                builder: (context, accountListProvider, _) {
                                  return IconButton(
                                    icon: const Icon(Icons.delete),
                                    color: AppColors.primaryMain,
                                    onPressed: () {
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
                                                    Expanded(child: Consumer<
                                                            AccountListProvider>(
                                                        builder: (context,
                                                            accountListProvider,
                                                            child) {
                                                      return CustomButton(
                                                          onPressed: () {
                                                            Navigator.pop(
                                                                context);
                                                          },
                                                          child: Text(
                                                            LanguageService
                                                                .getTranslated(
                                                                    context,
                                                                    "cancel"),
                                                            style: typography
                                                                .ButtonLarge,
                                                          ),
                                                          type:
                                                              ButtonType.text);
                                                    })),
                                                    Expanded(
                                                      child: Consumer<
                                                          AccountListProvider>(
                                                        builder: (context,
                                                            provider, child) {
                                                          return provider
                                                                  .isDeleteLocationLoading
                                                              ? Center(
                                                                  child:
                                                                      SizedBox(
                                                                    height: 28,
                                                                    width: 28,
                                                                    child: CircularProgressIndicator(
                                                                        strokeWidth:
                                                                            2),
                                                                  ),
                                                                )
                                                              : CustomButton(
                                                                  onPressed:
                                                                      () async {
                                                                    provider.isDeleteLocationLoading =
                                                                        true;
                                                                    provider
                                                                        .notifyListeners();

                                                                    bool
                                                                        isSuccess =
                                                                        false;

                                                                    try {
                                                                      isSuccess =
                                                                          await provider
                                                                              .deleteAccount(
                                                                        context,
                                                                        provider
                                                                            .accountList[index]
                                                                            .accountId!,
                                                                      );
                                                                      if (isSuccess) {
                                                                        provider.forceReload =
                                                                            true;
                                                                        await provider
                                                                            .fetchAccountList(
                                                                          context,
                                                                          _accountQuery,
                                                                          1,
                                                                          5,
                                                                        );

                                                                        Navigator.pop(
                                                                            context);
                                                                      }
                                                                    } finally {
                                                                      provider.isDeleteLocationLoading =
                                                                          false;
                                                                      provider
                                                                          .notifyListeners();
                                                                    }
                                                                  },
                                                                  child: Text(
                                                                    LanguageService.getTranslated(
                                                                        context,
                                                                        "delete"),
                                                                  ),
                                                                  type: ButtonType
                                                                      .elevated,
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
                                    tooltip: LanguageService.getTranslated(
                                        context, "delete"),
                                  );
                                },
                              )
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

  Future<List<TransferAutocompleteModel>> fetchAutocompleteUsers(
      String query) async {
    try {
      ApiService apiService =
          ApiService(AppConstant.TRANSFER_USER_AUTOCOMPLETE);
      String url = '?search=$query';
      var response = await apiService.get(url);
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
    final viewInsets = MediaQuery.of(context).viewInsets;
    await showDialog(
      barrierDismissible: false,
      context: context,
      useSafeArea: true,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              clipBehavior: Clip.antiAliasWithSaveLayer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              contentPadding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: viewInsets.bottom > 0 ? 8 : 20,
              ),
              content: SingleChildScrollView(
                padding: EdgeInsets.only(bottom: viewInsets.bottom),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 500,
                    maxHeight: MediaQuery.of(context).size.height * 0.7,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          LanguageService.getTranslated(context, "add_account"),
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
                                      accountListProvider
                                          .clearAutoCompleteList();
                                    });

                                    _autocompleteText = value;

                                    if (_debounce?.isActive ?? false)
                                      _debounce!.cancel();

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
                                        context, "add_account"),
                                    hintText: LanguageService.getTranslated(
                                        context, "add_account"),
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
                                        accountListProvider
                                            .clearAutoCompleteList();
                                      });
                                    },
                                    isLoading: accountListProvider
                                        .isAutoCompleteLoading,
                                  ),
                              ],
                            );
                          },
                        ),
                        SizedBox(
                            height:
                                viewInsets.bottom > 0 ? 8 : CustomSpacing.six),
                        Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Consumer<AccountListProvider>(builder:
                                      (context, accountListProvider, _) {
                                    return accountListProvider
                                            .isAddAccountLoading
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
                                                            LanguageService
                                                                .getTranslated(
                                                                    context,
                                                                    "account_list_app_add_account_empty_text_error"),
                                                            style: typography
                                                                .ButtonLargeBlack)));
                                                return;
                                              }

                                              if (!_accountAlreadyExists) {
                                                await accountListProvider
                                                    .addAccount(context,
                                                        _autocompleteText);
                                              } else {
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
                                                        _messageController
                                                            .text);
                                              }
                                              Navigator.pop(context);
                                            },
                                            child: Text(
                                              LanguageService.getTranslated(
                                                  context, "submit"),
                                              style:
                                                  typography.ButtonLargeBlack,
                                            ),
                                            type: ButtonType.elevated,
                                          );
                                  }),
                                ),
                              ],
                            ),
                            CustomButton(
                              onPressed: () {
                                _uploadedFileName = null;
                                _sovNameController.clear();
                                Navigator.pop(context);
                              },
                              child: Text(
                                LanguageService.getTranslated(
                                    context, "cancel"),
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
              ),
            );
          },
        );
      },
    ).then((_) {
      Provider.of<AccountListProvider>(context, listen: false)
          .clearAutoCompleteList();
      _textEditingController.clear();
      _messageController.clear();
      _accountAlreadyExists = false;
    });
  }

  Widget _getAccountUI() {
    var typography = CustomTypography(context);
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        SizedBox(height: CustomSpacing.six),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${LanguageService.getTranslated(context, "my_accounts")} ',
              style: typography.Body1,
            ),
          ],
        ),
        SizedBox(height: CustomSpacing.four),
        // Search
        SizedBox(
          height: 50,
          child: TextField(
            controller: _textEditingController,
            onChanged: (query) {
              accountsSearchClient(query);
              setState(() {
                _accountQuery = query;
              });
            },
            decoration: InputDecoration(
              suffixIcon: _accountQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        _textEditingController.clear();
                        accountsSearchClient("");
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              hintText: LanguageService.getTranslated(context, "search"),
              hintStyle: typography.Body2,
            ),
          ),
        ),
        SizedBox(height: CustomSpacing.four),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Consumer<AccountListProvider>(
                builder: (context, accountListProvider, _) {
              return Text(
                accountListProvider.showAccountName.trim().isNotEmpty == true
                    ? accountListProvider.showAccountName.toString() == "null"
                        ? "Account Name"
                        : accountListProvider.showAccountName.toString()
                    : 'Account Name',
              );
            }),
          ],
        ),
        // List of accounts
        Expanded(
          child: Selector<AccountListProvider,
              Tuple4<bool, bool, int, List<Accounts>>>(
            selector: (_, provider) => Tuple4(
              provider.isLoading,
              provider.isNextPageLoading,
              provider.page,
              provider.accountList,
            ),
            builder: (context, data, _) {
              final isLoading = data.item1;
              final isNextPageLoading = data.item2;
              final currentPage = data.item3;
              final accountList = data.item4;

              if (isLoading && accountList.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (accountList.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "Looks like you don't have an account yet. No worries! Just create a new one and start adding your locations.",
                      textAlign: TextAlign.center,
                      style: CustomTypography(context).Body1,
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  final provider =
                      Provider.of<AccountListProvider>(context, listen: false);

                  provider.forceReload = true;

                  provider.fetchAccountList(
                    context,
                    provider.lastSearchQuery,
                    1,
                    5,
                  );
                },
                child: NotificationListener<ScrollNotification>(
                  onNotification: (scrollInfo) {
                    if (scrollInfo is ScrollUpdateNotification &&
                        scrollInfo.metrics.pixels >=
                            scrollInfo.metrics.maxScrollExtent - 150) {
                      final provider = Provider.of<AccountListProvider>(context,
                          listen: false);
                      if (!provider.isNextPageLoading &&
                          provider.accountList.length < provider.accountHits) {
                        provider.fetchAccountList(
                          context,
                          _accountQuery,
                          provider.page + 1,
                          5,
                        );
                      }
                    }

                    return false;
                  },
                  child: ListView.builder(
                    key: const PageStorageKey('accountListView'),
                    physics: const AlwaysScrollableScrollPhysics(),
                    addRepaintBoundaries: true,
                    addAutomaticKeepAlives: false,
                    cacheExtent: 500,
                    itemCount: accountList.length + (isNextPageLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= accountList.length) {
                        return const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final provider = Provider.of<AccountListProvider>(context,
                          listen: false);

                      return RepaintBoundary(
                        child: _buildAccountCard(index, provider),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        )
      ],
    );
  }
}

void _showRemoveFavoriteBottomSheet(
  BuildContext context,
  AccountListProvider provider,
  String accountId,
  bool currentStatus,
) {
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
                const SizedBox(height: 8),
                const Text(
                  "Remove Favorite Status?",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "This account is a favorite because of its sub-accounts. "
                  "Removing it here will remove it from all sub-accounts. "
                  "To reapply, mark the sub-account as a favorite in the Sub-Account page.",
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 100),
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

                            final success = await provider.updateDefaultAccount(
                              context,
                              accountId,
                              currentStatus,
                            );

                            if (success) {
                              Navigator.pop(context); // close sheet
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
                    onPressed: isLoading
                        ? null
                        : () {
                            Navigator.pop(context);
                          },
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
