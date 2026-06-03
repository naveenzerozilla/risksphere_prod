import 'package:tuple/tuple.dart';
import '../../utils/global_imports.dart';
import 'dart:developer';
import 'package:easy_localization/easy_localization.dart';
import '../../design_system/components/expandable_card_container.dart';
import '../../providers/news_feed_provider.dart';
import '../listings/my_location_list.dart';
import '../payments/purchase_license.dart';
import '../userManagement/connections_screen.dart';
import '../userManagement/user_management.dart';

class DashboardScreen extends StatefulWidget {
  final String? newUser;
  final String? defaultTab;
  final bool openAddLocation;
  final String? latitude;
  final String? longitude;

  DashboardScreen({
    super.key,
    this.newUser,
    this.defaultTab,
    this.openAddLocation = false,
    this.latitude,
    this.longitude,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // App Bar
  bool _isExpanded = false;
  bool _showNotificationDot = true;
  List<Map<String, dynamic>> subscriptionMeta = [];
  late final String? accountId;
  late final String? monitoringSovId;
  late final String? subAccountId;
  late final String? accountName;
  late final String? subAccountName;
  late final String? sovName;
  late final String? sovid;

  // Dashboard Body
  bool isCompanyOnboardingStatsExpanded = false;
  bool isUserOnboardingStatsExpanded = true;
  DateTime? _selectedDateCompany;
  DateTime? _selectedDateUser;

  bool showTotalCorporates = false;
  bool showAllUsers = false;
  bool showConnectionRequests = false;
  bool showCompanyOnboardingStats = false;
  bool showUserOnboardingStats = false;
  bool showVerificationRequests = false;
  Set<String> loadingSubscriptions = {};

  List<dynamic> vendorList = [];
  var subscriptions = {};
  String isMaintenance = "";
  String startDate = "";
  String endDate = "";
  bool isPgAdmin = false;
  bool isAdmin = false;
  bool isSuperAdmin = false;
  bool isIndivudual = false;
  bool isHasAnyPlan = false;
  String? trialMap;
  ScrollController? _scrollController;
  GlobalKey keyFeature1 = GlobalKey();
  GlobalKey keyFeature2 = GlobalKey();
  GlobalKey keyFeature3 = GlobalKey();
  List<TargetFocus> targets = [];
  bool _showFirstTimeLoader = true;
  bool _initialRoleApiCalled = false;
  String? selectedRole;
  bool isLoadingRoleSwitch = false;
  bool _showOverlay = false;
  bool _hasNavigated = false;
  bool _isSubscriptionsLoading = true;

  @override
  void initState() {
    super.initState();

    _initialize();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasNavigated) {
        _hasNavigated = true;

        _handleFirstTimeNavigation();

        if (widget.openAddLocation &&
            widget.latitude != null &&
            widget.longitude != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AddLocationScreen(
                accountId: accountId,
                subAccountId: subAccountId,
                sovId: "",
                accountName: accountName,
                subAccountName: subAccountName,
                sovName: "sovName",
                locationId: "",
                locationName: "",
                locationIdForRef: "",
                searchQuery: "",
                page: "1",
                totalPages: "1",
              ),
            ),
          );
        }
      }
    });
  }

  Future<void> _initialize() async {
    await _loadAsyncData();
    await _setClaims();
    await _checkFirstTimeLoader();
  }

  Future<void> _handleFirstTimeNavigation() async {
    if (!mounted) return;
    if (widget.defaultTab == "dashboard") {
      debugPrint("Default tab is dashboard. Staying on current page.");
      return;
    }

    bool isNewUser = await SharedPreferenceService.getHasNewUser();
    isNewUser = widget.newUser == "false" ? false : isNewUser;

    accountId = await SharedPreferenceService.getDefaultAccountID();
    subAccountId = await SharedPreferenceService.getDefaultSubAccountID();
    accountName = await SharedPreferenceService.GetDefaultAccountName();
    subAccountName = await SharedPreferenceService.GetDefaultSUBAccountName();

    debugPrint("isNewUser: $isNewUser");
    debugPrint("accountId: $accountId");
    debugPrint("subAccountId: $subAccountId");

    if (!mounted) return;

    if (isNewUser) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => AddLocationScreen(
            newUser: isNewUser.toString(),
            accountId: accountId,
            subAccountId: subAccountId,
            accountName: accountName,
            subAccountName: subAccountName,
            sovId: '',
          ),
        ),
        (route) => false,
      );
      return;
    }
    if (!isNewUser &&
        accountId != null &&
        accountId!.isNotEmpty &&
        subAccountId != null &&
        subAccountId!.isNotEmpty) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => MyLocationList(
            accountID: accountId,
            subAccountID: subAccountId,
            accountName: accountName ?? "",
            subAccountName: subAccountName ?? "",
          ),
        ),
        (route) => false,
      );
      return;
    }
    debugPrint(
        "Existing user but no account/subAccount ID. Staying on same page.");
  }

  Future<void> _checkFirstTimeLoader() async {
    final pref = await SharedPreferences.getInstance();

    bool isFirstTime = pref.getBool("first_dashboard_loader") ?? true;

    if (isFirstTime) {
      setState(() => _showFirstTimeLoader = true);

      await Future.delayed(Duration(seconds: 4));

      setState(() => _showFirstTimeLoader = false);

      pref.setBool("first_dashboard_loader", false);
    } else {
      _showFirstTimeLoader = false;
    }
  }

  _setClaims() async {
    final values = await Future.wait([
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
    ]);

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

    showTotalCorporates = values[0] ?? false;
    showAllUsers = values[1] ?? false;
    showConnectionRequests = values[2] ?? false;
    showCompanyOnboardingStats = values[3] ?? false;
    showUserOnboardingStats = values[4] ?? false;

    isPgAdmin = adminValues[0] ?? false;
    isAdmin = adminValues[1] ?? false;
    isSuperAdmin = adminValues[2] ?? false;
    isIndivudual = adminValues[3] ?? false;
    isHasAnyPlan = adminValues[4] ?? false;
    trialMap = await SharedPreferenceService.getTrialPeriodStartRaw();
    if (mounted) setState(() {});
  }

  Future<void> _loadAsyncData() async {
    final dashboardProvider =
        Provider.of<DashboardProvider>(context, listen: false);
    final userProfileProvider =
        Provider.of<UserProfileProvider>(context, listen: false);
    final configProvider =
        Provider.of<ConfigurationProvider>(context, listen: false);
    final newsProvider = Provider.of<NewsFeedProvider>(context, listen: false);

    try {
      await Future.wait([
        dashboardProvider.getDashboardData(context),
        configProvider.getConfiguration(accountId: null, subAccountId: null),
        userProfileProvider.getAllUserData(context, "", ""),
        newsProvider.fetchNewsFeed(),
        configProvider.getVendors(),
      ]);

      userProfileProvider.fetchTrialInfo();

      vendorList = configProvider.vendors['result'] ?? [];
      subscriptions =
          (configProvider.configurations['result'] ?? {})['subscribe'] ?? {};

      _isSubscriptionsLoading = false;

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Dashboard load error → $e");
      _isSubscriptionsLoading = false;
      if (mounted) setState(() {});
    }
  }

  List<Map<String, dynamic>> _buildSubscriptionList(
      List<dynamic> vendorList, Map subs) {
    final List<Map<String, dynamic>> list = [];

    for (final entry in subs.entries) {
      final key = entry.key;
      final value = entry.value;

      final parts = key.split('_');
      if (parts.length != 2) continue;

      final vendorId = parts[0];
      final hazardName = parts[1];

      final vendor = vendorList.firstWhere(
        (v) => v['vendor_id'] == vendorId,
        orElse: () => null,
      );
      if (vendor == null) continue;

      final hazards = vendor['hazard_commercials'] as List?;
      if (hazards == null) continue;

      final hazard = hazards.firstWhere(
        (h) => h['hazard_name'] == hazardName,
        orElse: () => null,
      );
      if (hazard == null) continue;

      list.add({
        "key": key,
        "vendorId": vendorId,
        "vendorName": vendor['vendor_name_label'],
        "vendorImage": vendor['display_image_url'],
        "hazardLabel": hazard['hazard_name_label'],
        "description": value['description'] ?? "",
        "isSubscribed":
            value['is_subscribed'] == true || value['is_subscribed'] == "true"
      });
    }

    return list;
  }

  void initTargets() {
    targets.addAll([
      TargetFocus(
        identify: "Add User",
        keyTarget: keyFeature1,
        alignSkip: Alignment.topRight,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Container(
              margin: EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.fromLTRB(10.0, 60, 10, 10),
              child: Text(
                "Need to onboard someone new? Tap here to create a user and manage their access as an admin.",
                maxLines: 3,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),
            ),
          )
        ],
      ),
      TargetFocus(
        identify: "See All Users",
        keyTarget: keyFeature2,
        alignSkip: Alignment.topRight,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Container(
              margin: EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.fromLTRB(10.0, 10, 10, 30),
              child: Text(
                "Need to manage your users? Tap here to see all user details, verify pending accounts, and assign roles easily.",
                maxLines: 3,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),
            ),
          )
        ],
      ),
      TargetFocus(
        identify: "See Connection Requests",
        keyTarget: keyFeature3,
        alignSkip: Alignment.topRight,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Container(
              margin: EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.fromLTRB(10.0, 10, 10, 40),
              child: Text(
                "Manage incoming connection requests here. Review pending approvals and take appropriate action.",
                maxLines: 3,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),
            ),
          )
        ],
      ),
    ]);
  }

  void showTutorial() {
    TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.transparent,
      opacityShadow: 0.9,
      paddingFocus: 5,
      textSkip: "Skip",
      textStyleSkip: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      onFinish: () {
        print("Tutorial Finished");
      },
      onClickTarget: (target) {
        print("Clicked on target: ${target.identify}");
      },
    ).show(context: context);
  }

  Future<void> _getData() async {
    // final dashboardProvider =
    //     Provider.of<DashboardProvider>(context, listen: false);
    final userProfileProvider =
        Provider.of<UserProfileProvider>(context, listen: false);
    final configurationProvider =
        Provider.of<ConfigurationProvider>(context, listen: false);

    try {
      final results = await Future.wait([
        // dashboardProvider.getDashboardData(context),
        userProfileProvider.getAllUserData(context, "", ""),
        configurationProvider.getConfiguration(
            accountId: null, subAccountId: null),
        configurationProvider.getVendors(),
      ]);

      userProfileProvider.fetchTrialInfo();

      var config = configurationProvider.configurations['result'] ?? {};
      subscriptions = config['subscribe'] ?? {};

      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            vendorList = configurationProvider.vendors['result'] ?? [];
          });
        });
      }
    } catch (error) {
      print("Error fetching data: $error");
    }
  }

  Future<void> _handleRefresh() async {
    _getData();
  }

  @override
  void dispose() {
    _scrollController!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var typography = CustomTypography(context);
    return WillPopScope(
      onWillPop: () async {
        bool shouldExit = await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text('Exit App'),
            content: Text('Are you sure you want to exit?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Yes'),
              ),
            ],
          ),
        );

        if (shouldExit) {
          SystemNavigator.pop();
          return false;
        }
        return false;
      },
      child: Consumer<ThemeProvider>(builder: (context, themeProvider, child) {
        return SafeArea(
          child: Scaffold(
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
            body: RefreshIndicator(
              onRefresh: _handleRefresh,
              child: _showFirstTimeLoader
                  ? Container(
                      color: Colors.black.withOpacity(0.7),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : Stack(
                      children: [
                        Positioned.fill(
                          child: Image.asset(
                            'assets/images/mesh.png',
                            fit: BoxFit.cover,
                          ),
                        ),

                        SizedBox(height: 20),
                        _homeScreenBody(typography),

                        // Overlay for trial expiration
                        Consumer<UserProfileProvider>(
                          builder: (context, userProfile, child) {
                            final trialStatus =
                                userProfile.trialInfo['status'] ?? '';
                            if (trialStatus.contains('Expired') &&
                                isHasAnyPlan == false) {
                              return Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surface
                                      .withOpacity(0.95),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(height: CustomSpacing.four),
                                    // Text(isHasAnyPlan.toString()),
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
                              );
                            }
                            return SizedBox.shrink();
                          },
                        ),
                      ],
                    ),
            ),
          ),
        );
      }),
    );
  }

  _homeScreenBody(CustomTypography typography) {
    return Consumer2<DashboardProvider, UserProfileProvider>(
        builder: (context, dashboardProvider, userProfileProvider, child) {
      return SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.only(
              top: CustomSpacing.four,
              left: CustomSpacing.four,
              right: CustomSpacing.four),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              if (isMaintenance.toString() == 'in_progress') ...[
                Container(
                  child: MaintenanceUI(
                      isMaintenance: "isMaintenance",
                      startDate: startDate,
                      endDate: endDate),
                )
              ],
              Text(
                LanguageService.getTranslated(
                    context, 'usermanagement_dash_overview'),
                style: typography.H5_Regular,
              ),
              SizedBox(height: CustomSpacing.six),
              !showTotalCorporates
                  ? SizedBox()
                  : _overviewCardHorizontal(
                      title: LanguageService.getTranslated(
                          context, 'usermanagement_dash_total_corps'),
                      amount: dashboardProvider
                          .dashboard!.signups!.current!.csignup
                          .toString(),
                      icon: 'assets/images/total_corporates_list_check.svg',
                      bottomWidget: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          (dashboardProvider.dashboardModel?.signups?.current
                                          ?.csignup ??
                                      0) >
                                  (dashboardProvider.dashboardModel?.signups
                                          ?.past?.csignup ??
                                      0)
                              ? Icon(Icons.trending_up, color: Colors.green)
                              : Icon(Icons.trending_down, color: Colors.red),
                          SizedBox(width: CustomSpacing.two),
                          Flexible(
                            child: Text(
                              _getTotalCorporatePercentage(dashboardProvider),
                              style: typography.Subtitle1,
                              maxLines: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
              !showTotalCorporates
                  ? SizedBox()
                  : SizedBox(width: CustomSpacing.four),
              !showAllUsers
                  ? SizedBox()
                  : _overviewCardHorizontal(
                      title: LanguageService.getTranslated(
                          context, 'usermanagement_dash_signups'),
                      amount: dashboardProvider
                              .dashboardModel?.signups?.current?.signup
                              .toString() ??
                          '0',
                      icon: 'assets/images/sign_ups_users.svg',
                      bottomWidget: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          (dashboardProvider.dashboardModel?.signups?.current
                                          ?.signup ??
                                      0) >
                                  (dashboardProvider.dashboardModel?.signups
                                          ?.past?.signup ??
                                      0)
                              ? Icon(Icons.trending_up, color: Colors.green)
                              : Icon(Icons.trending_down, color: Colors.red),
                          SizedBox(width: CustomSpacing.two),
                          Flexible(
                            child: Text(
                              _getSignupsPercentage(dashboardProvider),
                              style: typography.Subtitle1,
                            ),
                          ),
                        ],
                      ),
                    ),
              (userProfileProvider.userData.role != null &&
                      userProfileProvider.userData.role!.isNotEmpty &&
                      userProfileProvider.userData.role![0].name
                              .toString()
                              .toLowerCase() ==
                          "admin" &&
                      (isSuperAdmin || isPgAdmin || isAdmin))
                  ? _overviewCardHorizontal(
                      title: LanguageService.getTranslated(
                          context, 'usermanagement_dash_verification_req'),
                      amount: ((dashboardProvider
                                      .dashboardModel?.verificationCount ??
                                  0) +
                              (dashboardProvider
                                      .dashboardModel?.companyUserLeadCount ??
                                  0))
                          .toString(),
                      icon: 'assets/images/verification_req_checks.svg',
                      bottomWidget: Row(
                        children: [
                          /// ➕ Add User
                          Expanded(
                            child: CustomButton(
                              key: keyFeature1,
                              type: ButtonType.outlined,
                              onPressed: () {
                                Provider.of<DrawerSelectionProvider>(context,
                                        listen: false)
                                    .setSelectedItem('user_management');

                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => UserManagementScreen(
                                      initialIndex: 0,
                                      subIndex: 0,
                                      initialScreen:
                                          Screens.corporateEmployeeAdd,
                                    ),
                                  ),
                                );
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      LanguageService.getTranslated(
                                          context, 'dashboard_add_user_text'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: typography.Body1,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.person_add_alt_1, size: 18),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          /// ➡️ See All
                          Expanded(
                            child: CustomButton(
                              key: keyFeature2,
                              type: ButtonType.outlined,
                              onPressed: () {
                                Provider.of<DrawerSelectionProvider>(context,
                                        listen: false)
                                    .setSelectedItem('user_management');

                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => UserManagementScreen(
                                      initialIndex: 0,
                                      subIndex: 0,
                                      initialScreen: Screens.verificationList,
                                    ),
                                  ),
                                );
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      LanguageService.getTranslated(
                                          context, 'dashboard_see_all_text'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: typography.Body1,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.arrow_forward_ios, size: 14),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : showTotalCorporates.toString() == "true"
                      ? _overviewCardHorizontal(
                          title: LanguageService.getTranslated(
                              context, 'usermanagement_dash_verification_req'),
                          amount: ((dashboardProvider
                                          .dashboardModel?.verificationCount ??
                                      0) +
                                  (dashboardProvider.dashboardModel
                                          ?.companyUserLeadCount ??
                                      0))
                              .toString(),
                          icon: 'assets/images/verification_req_checks.svg',
                          bottomWidget: Row(
                            children: [
                              /// ➕ Add User
                              Expanded(
                                child: CustomButton(
                                  key: keyFeature1,
                                  type: ButtonType.outlined,
                                  onPressed: () {
                                    Provider.of<DrawerSelectionProvider>(
                                            context,
                                            listen: false)
                                        .setSelectedItem('user_management');

                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            UserManagementScreen(
                                          initialIndex: 0,
                                          subIndex: 0,
                                          initialScreen:
                                              Screens.corporateEmployeeAdd,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          LanguageService.getTranslated(context,
                                              'dashboard_add_user_text'),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: typography.Body1,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Icon(Icons.person_add_alt_1,
                                          size: 18),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(width: 12),

                              /// ➡️ See All
                              Expanded(
                                child: CustomButton(
                                  key: keyFeature2,
                                  type: ButtonType.outlined,
                                  onPressed: () {
                                    Provider.of<DrawerSelectionProvider>(
                                            context,
                                            listen: false)
                                        .setSelectedItem('user_management');

                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            UserManagementScreen(
                                          initialIndex: 0,
                                          subIndex: 0,
                                          initialScreen:
                                              Screens.verificationList,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          LanguageService.getTranslated(context,
                                              'dashboard_see_all_text'),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: typography.Body1,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Icon(Icons.arrow_forward_ios,
                                          size: 14),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Container(),
              !showConnectionRequests
                  ? SizedBox()
                  : SizedBox(width: CustomSpacing.four),
              _overviewCardHorizontal(
                title: LanguageService.getTranslated(
                    context, 'usermanagement_dash_connection_request'),
                amount:
                    dashboardProvider.dashboardModel?.requests?.toString() ??
                        '0',
                icon: 'assets/images/connection_request_people.svg',
                bottomWidget: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    //reduce border radius
                    CustomButton(
                      key: keyFeature3,
                      type: ButtonType.outlined,
                      onPressed: () async {
                        FirebaseAuth auth = FirebaseAuth.instance;
                        String uid = auth.currentUser!.uid;
                        IdTokenResult token =
                            await auth.currentUser!.getIdTokenResult();
                        Map<String, dynamic>? claims = token.claims ?? {};
                        log(claims.toString());
                        log(auth.currentUser.toString());
                        String name = claims['name'] ?? ''; //name of the user
                        Provider.of<DrawerSelectionProvider>(context,
                                listen: false)
                            .setSelectedItem('user_management');
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ConnectionsScreen(
                              userId: uid,
                              userName: name,
                              selectedTabIndex: 1,
                            ),
                          ),
                        );
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            LanguageService.getTranslated(context,
                                'usermanagement_dash_connection_req_list_btn'),
                            style: typography.Body1,
                          ),
                          SizedBox(width: CustomSpacing.two),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Text(isPgAdmin.toString()),
              // Text(isAdmin.toString()),
              // Text(isSuperAdmin.toString()),
              SizedBox(
                height: CustomSpacing.one,
              ),
              // (userProfileProvider.userData.role != null &&
              //         userProfileProvider.userData.role!.isNotEmpty &&
              //         userProfileProvider.userData.role![0].name
              //                 .toString() ==
              //             "Admin" &&
              //         (isSuperAdmin || isPgAdmin || isAdmin))
              // InkWell(
              //   onTap: () async {
              //     final status = await Permission.camera.request();
              //     if (status.isGranted) {
              //       final pickedFile = await ImagePicker()
              //           .pickImage(source: ImageSource.camera);
              //       if (pickedFile != null) {
              //         // Use pickedFile.path
              //         print('Image path: ${pickedFile.path}');
              //       }
              //     } else {
              //       ScaffoldMessenger.of(context).showSnackBar(
              //         SnackBar(content: Text('Camera permission denied')),
              //       );
              //     }
              //   },
              //   child: Text("Camera", style: typography.H5_Regular),
              // ),
              showAllUsers
                  ? SizedBox()
                  : Consumer2<UserProfileProvider, ConfigurationProvider>(
                      builder: (context, userProfileProvider, provider, child) {
                        // if (provider.isLoading) {
                        //   return Container(
                        //     padding: const EdgeInsets.symmetric(horizontal: 50),
                        //     alignment: Alignment.center,
                        //     width: MediaQuery.of(context).size.width,
                        //     height: MediaQuery.of(context).size.height / 2,
                        //     child: const CircularProgressIndicator(),
                        //   );
                        // }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                LanguageService.getTranslated(
                                    context, 'dashboard_my_subscription_text'),
                                style: typography.H5_Regular),
                            SizedBox(height: CustomSpacing.two),
                            Selector<ConfigurationProvider,
                                List<Map<String, dynamic>>>(
                              selector: (_, provider) {
                                final vendorList =
                                    provider.vendors['result'] ?? [];
                                final subs =
                                    (provider.configurations['result'] ??
                                            {})['subscribe'] ??
                                        {};
                                return _buildSubscriptionList(vendorList, subs);
                              },
                              builder: (_, subList, __) {
                                return _subscriptionList(subList);
                              },
                            ),
                          ],
                        );
                      },
                    ),
              SizedBox(height: CustomSpacing.one),
              !showCompanyOnboardingStats
                  ? SizedBox()
                  : dashboardProvider.isCompanyLoading
                      ? Column(
                          children: [
                            Center(
                              child: SizedBox(
                                  height: 25,
                                  width: 25,
                                  child: CircularProgressIndicator()),
                            )
                          ],
                        )
                      : ExpandableCardContainer(
                          isExpanded: isCompanyOnboardingStatsExpanded,
                          collapsedChild: _collapsedCompanyCardWidget(
                            title: Text(
                              LanguageService.getTranslated(context,
                                  'usermanagement_dash_company_onboarding_status_title'),
                              style: typography.Body1,
                            ),
                          ),
                          expandedChild: _expandedCompanyOnboardingStatsWidget(
                              dashboardProvider),
                        ),
              SizedBox(height: CustomSpacing.one),
              !showUserOnboardingStats
                  ? SizedBox()
                  : dashboardProvider.isRoleLoading
                      ? Column(
                          children: [
                            Center(
                              child: SizedBox(
                                  height: 25,
                                  width: 25,
                                  child: CircularProgressIndicator()),
                            )
                          ],
                        )
                      : ExpandableCardContainer(
                          isExpanded: isUserOnboardingStatsExpanded,
                          collapsedChild: _collapsedUserCardWidget(
                            title: Text(
                              LanguageService.getTranslated(context,
                                  'usermanagement_dash_user_on_boarding_status'),
                              style: typography.Body1,
                            ),
                          ),
                          expandedChild: _expandedUserOnboardingStatsWidget(
                              dashboardProvider),
                        ),
              SizedBox(height: CustomSpacing.eight),
            ],
          ),
        ),
      );
    });
  }

  Widget _subscriptionList(List<Map<String, dynamic>> list) {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: list.length,
      itemBuilder: (context, i) {
        final data = list[i];
        return SubscriptionCard(
          title: "${data['hazardLabel']} (${data['vendorName']})",
          description: data['description'],
          iconPath: data['vendorImage'],
          isSubscribed: data['isSubscribed'],
          isPgAdmin: isPgAdmin,
          isAdmin: isAdmin,
          isSuperAdmin: isSuperAdmin,
          onSubscribe: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PurchaseLicensePage()),
            );
          },
        );
      },
    );
  }

  // Widget _subscriptionBody() {
  //   return ListView.builder(
  //     itemCount: subscriptionMeta.length,
  //     shrinkWrap: true,
  //     physics: NeverScrollableScrollPhysics(),
  //     itemBuilder: (context, index) {
  //       final data = subscriptionMeta[index];
  //
  //       return Padding(
  //         padding: EdgeInsets.only(bottom: CustomSpacing.one),
  //         child: SubscriptionCard(
  //           title: "${data['hazardLabel']} (${data['vendorName']})",
  //           description: data['description'],
  //           iconPath: data['vendorImage'],
  //           isSubscribed: data['isSubscribed'],
  //           isPgAdmin: isPgAdmin,
  //           isAdmin: isAdmin,
  //           isSuperAdmin: isSuperAdmin,
  //           onSubscribe: () {
  //             Navigator.push(
  //               context,
  //               MaterialPageRoute(builder: (_) => PurchaseLicensePage()),
  //             );
  //           },
  //         ),
  //       );
  //     },
  //   );
  // }

  // Widget _subscriptionBody() {
  //   return Selector2<UserProfileProvider, ConfigurationProvider,
  //       Tuple4<bool, Map<String, dynamic>?, bool, String>>(
  //     selector: (_, userProfile, config) => Tuple4(
  //         config.isLoading,
  //         userProfile.trialInfo,
  //         (userProfile.trialInfo['status']?.toString() ?? '') == 'active',
  //         ''
  //
  //         // userProfile.isSubscribed,
  //         // userProfile.subscriptionStatus ?? '',
  //         ),
  //     builder: (context, data, child) {
  //       final isConfigLoading = data.item1;
  //       final trialInfo = data.item2;
  //       final isSubscribed = data.item3;
  //       final subscriptionStatus = data.item4;
  //
  //       if (isConfigLoading) {
  //         return Container(
  //           padding: const EdgeInsets.symmetric(horizontal: 50),
  //           alignment: Alignment.center,
  //           width: MediaQuery.of(context).size.width,
  //           height: MediaQuery.of(context).size.height / 2,
  //           child: const CircularProgressIndicator(),
  //         );
  //       }
  //
  //       return Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: subscriptions.keys.map((key) {
  //           return FutureBuilder<Map<String, dynamic>?>(
  //             future: _fetchSubscriptionData(key),
  //             builder: (context, snapshot) {
  //               if (snapshot.connectionState == ConnectionState.waiting ||
  //                   loadingSubscriptions.contains(key)) {
  //                 return const Center(child: CircularProgressIndicator());
  //               }
  //
  //               if (!snapshot.hasData) {
  //                 return const SizedBox.shrink();
  //               }
  //
  //               final data = snapshot.data!;
  //               final trialStatus = trialInfo?['status'] ?? '';
  //
  //               return Column(
  //                 children: [
  //                   SubscriptionCard(
  //                     title: '${data['hazardLabel']} (${data['vendorName']})',
  //                     description:
  //                         data['description'] ?? "Basic Subscription plan",
  //                     iconPath: data['vendorImage'],
  //                     isSubscribed: data['isSubscribed'],
  //                     onSubscribe: () async {
  //                       setState(() => loadingSubscriptions.add(key));
  //                       Navigator.of(context).push(MaterialPageRoute(
  //                           builder: (_) => const PurchaseLicensePage()));
  //                       setState(() => loadingSubscriptions.remove(key));
  //                     },
  //                     isPgAdmin: isPgAdmin,
  //                     isAdmin: isAdmin,
  //                     isSuperAdmin: isSuperAdmin,
  //                   ),
  //                   SizedBox(height: CustomSpacing.one),
  //                 ],
  //               );
  //             },
  //           );
  //         }).toList(),
  //       );
  //     },
  //   );
  // }

  /// Fetch vendor and hazard data for each subscription key
  Future<Map<String, dynamic>?> _fetchSubscriptionData(String key) async {
    final parts = key.split('_');
    if (parts.length != 2) return null;

    final vendorId = parts[0];
    final hazardName = parts[1];

    final vendor = vendorList.firstWhere(
      (v) => v['vendor_id'] == vendorId,
      orElse: () => null,
    );

    if (vendor == null) return null;

    final hazard = (vendor['hazard_commercials'] as List?)
        ?.firstWhere((h) => h['hazard_name'] == hazardName, orElse: () => null);

    if (hazard == null) return null;

    final subscription = subscriptions[key];
    final config = Provider.of<ConfigurationProvider>(context, listen: false)
            .configurations['result'] ??
        {};

    return {
      'vendorName': vendor['vendor_name_label'] ?? '',
      'vendorImage':
          vendor['display_image_url'] ?? 'assets/images/default_vendor.png',
      'hazardLabel': hazard['hazard_name_label'] ?? 'Unknown Hazard',
      'description': subscription['description'] ?? '',
      'isSubscribed': subscription['is_subscribed'] == true ||
          subscription['is_subscribed'] == 'true',
      'mainId': config['id'] ?? '',
      'level': config['level'] ?? '',
    };
  }

  _overviewCardHorizontal(
      {required String title,
      required String amount,
      required String icon,
      required Row bottomWidget}) {
    var typography = CustomTypography(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.only(
                top: CustomSpacing.two,
                left: CustomSpacing.four,
                right: CustomSpacing.four),
            child: Row(
              children: [
                Row(
                  children: [
                    Card(
                      elevation: 100,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Container(
                        padding: EdgeInsets.all(CustomSpacing.two),
                        child: SvgPicture.asset(
                          icon,
                          width: 24,
                          height: 24,
                          colorFilter: ColorFilter.mode(
                              Theme.of(context).colorScheme.onBackground,
                              BlendMode.srcIn),
                        ),
                      ),
                    ),
                    SizedBox(height: CustomSpacing.four),
                    Text(
                      title,
                      style: typography.Body1,
                    ),
                    SizedBox(height: CustomSpacing.two),
                  ],
                ),
                Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      amount,
                      style: typography.H4,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(
            color: AppColors.black,
            thickness: 2,
          ),
          SizedBox(height: CustomSpacing.one),
          Container(
              padding: EdgeInsets.only(
                  bottom: CustomSpacing.two,
                  left: CustomSpacing.four,
                  right: CustomSpacing.four),
              child: Center(child: bottomWidget)),
        ],
      ),
    );
  }

  _collapsedCompanyCardWidget({required Text title}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Container(
        padding: EdgeInsets.all(CustomSpacing.two),
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              children: [
                Row(
                  children: [
                    //Circular Icon button
                    IconButton(
                      icon: Icon(
                        Icons.keyboard_arrow_down_outlined,
                        size: 24,
                      ),
                      onPressed: () {
                        setState(() {
                          isCompanyOnboardingStatsExpanded =
                              !isCompanyOnboardingStatsExpanded;
                        });
                      },
                    ),
                    SizedBox(width: CustomSpacing.two),
                    Flexible(child: title),
                    Spacer(),
                  ],
                ),
                SizedBox(height: CustomSpacing.two),

                // Select Period Datetime Picker
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        readOnly: true, // Make the field read-only
                        controller: TextEditingController(
                            text: _selectedDateCompany == null
                                ? ''
                                : DateFormat('MMMM yyyy')
                                    .format(_selectedDateCompany!)),
                        decoration: InputDecoration(
                          labelText: LanguageService.getTranslated(context,
                              'usermanagement_dash_select_period_label'),
                          hintText: LanguageService.getTranslated(
                              context, 'usermanagement_dash_calendar'),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onTap: () async {
                          final DateTime? pickedDate = await showMonthPicker(
                            context: context,
                            initialDate: _selectedDateCompany ?? DateTime.now(),
                            firstDate: DateTime(DateTime.now().year - 10),
                            lastDate: DateTime.now(),
                          );

                          if (pickedDate != null &&
                              pickedDate != _selectedDateCompany) {
                            setState(() {
                              _selectedDateCompany = pickedDate;
                            });
                            Provider.of<DashboardProvider>(context,
                                    listen: false)
                                .getDashboardDataForCompanies(
                                    context, pickedDate);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  _expandedCompanyOnboardingStatsWidget(DashboardProvider dashboardProvider) {
    var typography = CustomTypography(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Container(
        padding: EdgeInsets.all(CustomSpacing.two),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                //Circular Icon button
                IconButton(
                  icon: Icon(
                    Icons.keyboard_arrow_up_outlined,
                    size: 24,
                  ),
                  onPressed: () {
                    setState(() {
                      isCompanyOnboardingStatsExpanded =
                          !isCompanyOnboardingStatsExpanded;
                    });
                  },
                ),
                SizedBox(width: CustomSpacing.two),
                Flexible(
                  child: Text(
                    LanguageService.getTranslated(context,
                        'usermanagement_dash_company_onboarding_status_title'),
                    style: typography.Body1,
                  ),
                ),
              ],
            ),
            SizedBox(height: CustomSpacing.two),

            // Select Period Datetime Picker
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    readOnly: true, // Make the field read-only
                    controller: TextEditingController(
                        text: _selectedDateCompany == null
                            ? ''
                            : DateFormat('MMMM yyyy')
                                .format(_selectedDateCompany!)),
                    decoration: InputDecoration(
                      labelText: LanguageService.getTranslated(
                          context, 'usermanagement_dash_select_period_label'),
                      hintText: LanguageService.getTranslated(
                          context, 'usermanagement_dash_calendar'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onTap: () async {
                      final DateTime? pickedDate = await showMonthPicker(
                        context: context,
                        initialDate: _selectedDateCompany ?? DateTime.now(),
                        firstDate: DateTime(DateTime.now().year - 10),
                        lastDate: DateTime.now(),
                      );

                      if (pickedDate != null &&
                          pickedDate != _selectedDateCompany) {
                        setState(() {
                          _selectedDateCompany = pickedDate;
                        });
                        Provider.of<DashboardProvider>(context, listen: false)
                            .getDashboardDataForCompanies(context, pickedDate);
                      }
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: CustomSpacing.six),
            Container(
              margin: EdgeInsets.symmetric(horizontal: CustomSpacing.two),
              child: ListView(
                shrinkWrap: true,
                physics: ClampingScrollPhysics(),
                children: []..addAll(dashboardProvider
                        .dashboardModel?.companyType
                        ?.map((corporate) {
                      return companyOnboardingStatsProgressCards(
                          corporate, dashboardProvider);
                    }) ??
                    []),
              ),
            ),
            SizedBox(height: CustomSpacing.four),
            Container(
              margin: EdgeInsets.symmetric(horizontal: CustomSpacing.four),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getPercentConversions(
                        dashboardProvider.dashboardModel?.companyPercent ??
                            "0"),
                    style: typography.H4.copyWith(
                      color: Colors.red,
                    ),
                  ),
                  SizedBox(height: CustomSpacing.two),
                  Text(
                    LanguageService.getTranslated(
                        context, 'usermanagement_dash_conversions'),
                    style: typography.Body1,
                  ),
                  SizedBox(height: CustomSpacing.two),
                  Row(
                    children: [
                      Flexible(
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: LanguageService.getTranslated(context,
                                    'usermanagement_dash_forcast_part_1'),
                                style: typography.Body1.copyWith(
                                  color: AppColors.primaryMain,
                                ),
                              ),
                              TextSpan(
                                text: LanguageService.getTranslated(context,
                                    'usermanagement_dash_forcast_part_2'),
                                style: typography.Body1,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget companyOnboardingStatsProgressCards(
      CompanyType corporate, DashboardProvider dashboardProvider) {
    var typography = CustomTypography(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          corporate.name ?? '',
          style: typography.Body1,
        ),
        SizedBox(height: CustomSpacing.two),
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: corporate.count == null
                    ? 0
                    : corporate.count! /
                        (dashboardProvider.dashboardModel?.max ?? 1),
              ),
            ),
            SizedBox(width: CustomSpacing.two),
            Text(
              corporate.count.toString(),
              style: typography.Subtitle1,
            ),
          ],
        ),
      ],
    );
  }

  _collapsedUserCardWidget({required Text title}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Container(
        padding: EdgeInsets.all(CustomSpacing.two),
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              children: [
                Row(
                  children: [
                    //Circular Icon button
                    IconButton(
                      icon: Icon(
                        Icons.keyboard_arrow_down_outlined,
                        size: 24,
                      ),
                      onPressed: () {
                        setState(() {
                          isUserOnboardingStatsExpanded =
                              !isUserOnboardingStatsExpanded;
                        });
                      },
                    ),
                    SizedBox(width: CustomSpacing.two),
                    Flexible(child: title),
                    Spacer(),
                  ],
                ),
                SizedBox(height: CustomSpacing.two),

                // Select Period Datetime Picker
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        readOnly: true, // Make the field read-only
                        controller: TextEditingController(
                            text: _selectedDateUser == null
                                ? ''
                                : DateFormat('MMMM yyyy')
                                    .format(_selectedDateUser!)),
                        decoration: InputDecoration(
                          labelText: LanguageService.getTranslated(context,
                              'usermanagement_dash_select_period_label'),
                          hintText: LanguageService.getTranslated(
                              context, 'usermanagement_dash_calendar'),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onTap: () async {
                          final DateTime? pickedDate = await showMonthPicker(
                            context: context,
                            initialDate: _selectedDateUser ?? DateTime.now(),
                            firstDate: DateTime(DateTime.now().year - 10),
                            lastDate: DateTime.now(),
                          );

                          if (pickedDate != null &&
                              pickedDate != _selectedDateUser) {
                            setState(() {
                              _selectedDateUser = pickedDate;
                            });
                            Provider.of<DashboardProvider>(context,
                                    listen: false)
                                .getDashboardDataForRoles(context, pickedDate);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  _expandedUserOnboardingStatsWidget(DashboardProvider dashboardProvider) {
    var typography = CustomTypography(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Container(
        padding: EdgeInsets.all(CustomSpacing.two),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                //Circular Icon button
                IconButton(
                  icon: Icon(
                    Icons.keyboard_arrow_up_outlined,
                    size: 24,
                  ),
                  onPressed: () {
                    setState(() {
                      isUserOnboardingStatsExpanded =
                          !isUserOnboardingStatsExpanded;
                    });
                  },
                ),
                SizedBox(width: CustomSpacing.two),
                Flexible(
                  child: Text(
                    LanguageService.getTranslated(
                        context, 'usermanagement_dash_user_on_boarding_status'),
                    style: typography.Body1,
                  ),
                ),
              ],
            ),
            SizedBox(height: CustomSpacing.two),

            // Select Period Datetime Picker
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    readOnly: true, // Make the field read-only
                    controller: TextEditingController(
                        text: _selectedDateUser == null
                            ? ''
                            : DateFormat('MMMM yyyy')
                                .format(_selectedDateUser!)),
                    decoration: InputDecoration(
                      labelText: LanguageService.getTranslated(
                          context, 'usermanagement_dash_select_period_label'),
                      hintText: LanguageService.getTranslated(
                          context, 'usermanagement_dash_calendar'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onTap: () async {
                      final DateTime? pickedDate = await showMonthPicker(
                        context: context,
                        initialDate: _selectedDateUser ?? DateTime.now(),
                        firstDate: DateTime(DateTime.now().year - 10),
                        lastDate: DateTime.now(),
                      );

                      if (pickedDate != null &&
                          pickedDate != _selectedDateUser) {
                        setState(() {
                          _selectedDateUser = pickedDate;
                        });
                        Provider.of<DashboardProvider>(context, listen: false)
                            .getDashboardDataForRoles(context, pickedDate);
                      }
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: CustomSpacing.four),
            Container(
              margin: EdgeInsets.symmetric(horizontal: CustomSpacing.four),
              child: ListView(
                shrinkWrap: true,
                physics: ClampingScrollPhysics(),
                children: []
                  ..addAll(dashboardProvider.dashboardModel?.roles?.map((role) {
                        return userOnboardingStatsProgressCards(
                            role, dashboardProvider);
                      }) ??
                      []),
              ),
            ),
            SizedBox(height: CustomSpacing.four),
            Container(
              margin: EdgeInsets.symmetric(horizontal: CustomSpacing.four),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getPercentConversions(
                        dashboardProvider.dashboardModel?.rolePercent ?? "0"),
                    style: typography.H4.copyWith(
                      color: Colors.red,
                    ),
                  ),
                  SizedBox(height: CustomSpacing.two),
                  Text(
                    LanguageService.getTranslated(
                        context, 'usermanagement_dash_conversions'),
                    style: typography.Body1,
                  ),
                  SizedBox(height: CustomSpacing.two),
                  Row(
                    children: [
                      Flexible(
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: LanguageService.getTranslated(context,
                                    'usermanagement_dash_forcast_part_1'),
                                style: typography.Body1.copyWith(
                                  color: AppColors.primaryMain,
                                ),
                              ),
                              TextSpan(
                                text: LanguageService.getTranslated(context,
                                    'usermanagement_dash_forcast_part_2'),
                                style: typography.Body1,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget userOnboardingStatsProgressCards(
      DashboardRoles role, DashboardProvider dashboardProvider) {
    var typography = CustomTypography(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          role.name ?? '',
          style: typography.Body1,
        ),
        SizedBox(height: CustomSpacing.two),
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: role.count == null
                    ? 0
                    : role.count! /
                        (dashboardProvider.dashboardModel?.max ?? 1),
              ),
            ),
            SizedBox(width: CustomSpacing.two),
            Text(
              role.count.toString(),
              style: typography.Subtitle1,
            ),
          ],
        ),
      ],
    );
  }

  List<String> generateOptions() {
    List<String> options = [];
    final currentDate = DateTime.now();
    final formatter = DateFormat('MMMM yyyy');

    for (int i = 0; i < 120; i++) {
      final date = currentDate.subtract(Duration(days: i * 30));
      options.add(formatter.format(date));
    }

    return options;
  }

  String _getTotalCorporatePercentage(DashboardProvider dashboardProvider) {
    double changePercentage = getChangePercentage(
        dashboardProvider.dashboardModel?.signups?.current?.csignup ?? 0,
        dashboardProvider.dashboardModel?.signups?.past?.csignup ?? 0);

    print('changePercentage: $changePercentage');

    String changeText = changePercentage >= 0
        ? '${changePercentage.toStringAsFixed(2)}% ${LanguageService.getTranslated(context, 'usermanagement_dash_increase')}'
        : '${(-changePercentage).toStringAsFixed(2)}% ${LanguageService.getTranslated(context, 'usermanagement_dash_decrease')}';

    String output = changeText +
        LanguageService.getTranslated(
            context, 'usermanagement_dash_vs_last_month');

    return output;
  }

  String _getSignupsPercentage(DashboardProvider dashboardProvider) {
    double changePercentage = getChangePercentage(
        dashboardProvider.dashboardModel?.signups?.current?.signup ?? 0,
        dashboardProvider.dashboardModel?.signups?.past?.signup ?? 0);

    String changeText = changePercentage >= 0
        ? '${changePercentage.toStringAsFixed(2)}% ${LanguageService.getTranslated(context, 'usermanagement_dash_increase')}'
        : '${(-changePercentage).toStringAsFixed(2)}% ${LanguageService.getTranslated(context, 'usermanagement_dash_decrease')}';

    String output = changeText +
        LanguageService.getTranslated(
            context, 'usermanagement_dash_vs_last_month');

    return output;
  }

  double getChangePercentage(int current, int past) {
    print('current: $current');
    print('past: $past');
    double changePercentage = ((current - past) * 100) / (past == 0 ? 1 : past);
    return changePercentage;
  }

  String _getPercentConversions(String percent) {
    String rolePercentText = percent ?? "0";

    // Remove '%' sign but keep negative signs and decimal points
    String rolePercentCleaned =
        rolePercentText.replaceAll(RegExp(r'[^0-9.-]'), '');

    if (rolePercentCleaned.isEmpty) {
      rolePercentCleaned = "0";
    }

    print("rolePercentCleaned: $rolePercentCleaned");

    double rolePercent = double.tryParse(rolePercentCleaned) ?? 0.0;

    String changeText;
    if (rolePercent < 0) {
      rolePercent = -rolePercent; // Make it positive
      changeText =
          "${rolePercent.toStringAsFixed(2)}% ${LanguageService.getTranslated(context, 'usermanagement_dash_decrease_cap')}";
    } else {
      changeText =
          "${rolePercent.toStringAsFixed(2)}% ${LanguageService.getTranslated(context, 'usermanagement_dash_increase_cap')}";
    }

    print(changeText);
    return changeText;
  }

  Map<String, dynamic>? parseJwt(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      return null;
    }

    final payload = parts[1];
    final String normalized = base64Url.normalize(payload);
    final String decoded = utf8.decode(base64Url.decode(normalized));
    return json.decode(decoded);
  }

  _updateSubscription(
      String vendorId, bool isSubscribed, String mainId, String level) {
    var typography = CustomTypography(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final provider =
            Provider.of<ConfigurationProvider>(context, listen: false);
        bool isLoading = false; // Loader for "Yes" button
        bool isLoading1 = false; // Loader for "No" button

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width / 2,
                    child: Text(
                      'Do you want to apply this change globally?',
                      maxLines: 2,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: Icon(Icons.close),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading1
                      ? null
                      : () async {
                          setState(() {
                            isLoading1 = true;
                          });

                          String key = 'subscribe.$vendorId.is_subscribed';

                          await provider.updateConfiguration(
                            context,
                            mainId,
                            key,
                            level,
                            !isSubscribed,
                            "false",
                          );

                          setState(() {
                            isLoading1 = false;
                          });

                          if (!provider.isLoading) Navigator.pop(context);
                          _getData();
                        },
                  style: TextButton.styleFrom(
                    side: BorderSide(color: AppColors.primaryMain, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isLoading1
                      ? SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: AppColors.primaryMain,
                            strokeWidth: 3,
                          ),
                        )
                      : Text(
                          'No',
                          style: typography.Body1.copyWith(
                              color: AppColors.primaryMain),
                        ),
                ),
                SizedBox(width: 10),
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          setState(() {
                            isLoading = true;
                          });

                          String key = 'subscribe.$vendorId.is_subscribed';

                          await provider.updateConfiguration(
                            context,
                            mainId,
                            key,
                            level,
                            !isSubscribed,
                            "true",
                          );

                          setState(() {
                            isLoading = false;
                          });

                          if (!provider.isLoading) Navigator.pop(context);
                          _getData();
                        },
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.primaryMain,
                    side: BorderSide(color: AppColors.primaryMain, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  ),
                  child: isLoading
                      ? SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : Text(
                          'Yes',
                          style: typography.Body1.copyWith(color: Colors.black),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
