import 'package:RiskSphere/screens/chatbot/chatbot.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../../utils/global_imports.dart';
import 'dart:developer';
import 'package:easy_localization/easy_localization.dart';
import '../listings/my_location_list.dart';
import '../payments/purchase_license.dart';
import '../userManagement/connections_screen.dart';
import '../userManagement/user_management.dart';
import 'widgets/overview_card.dart';
import 'widgets/company_onboarding_stats_card.dart';
import 'widgets/user_onboarding_stats_card.dart';

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

  // Expansion and selected period dates are now encapsulated inside CompanyOnboardingStatsCard and UserOnboardingStatsCard

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
      child: Consumer2<ThemeProvider, MyLocationListProvider>(builder: (
        context,
        themeProvider,
        locationProfileProvider,
        child,
      ) {
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
            floatingActionButton: Padding(
              padding: const EdgeInsets.only(bottom: 50),
              child: SafeArea(
                child: GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => ChatbotBottomSheet(
                        locationId: locationProfileProvider
                            .locationProfile?.finalAddress?.locationId
                            .toString(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
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
                      children: [
                        Text(
                          "Need Help?",
                          style: TextStyle(color: Colors.white),
                        ),
                        SizedBox(width: 8),
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.primaryMain,
                          child: Icon(Icons.smart_toy,
                              color: Colors.white, size: 18),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
                        // Positioned(
                        //   right: 16,
                        //   bottom: 16,
                        //   child: SafeArea(
                        //     child: GestureDetector(
                        //       onTap: () {
                        //         showModalBottomSheet(
                        //           context: context,
                        //           isScrollControlled: true,
                        //           useSafeArea: true,
                        //           backgroundColor: Colors.transparent,
                        //           builder: (_) => ChatbotBottomSheet(
                        //             locationId: locationProfileProvider
                        //                 .locationProfile?.finalAddress?.locationId
                        //                 .toString(),
                        //           ),
                        //         );
                        //       },
                        //       child: Container(
                        //         padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        //         decoration: BoxDecoration(
                        //           color: Colors.black87,
                        //           borderRadius: BorderRadius.circular(25),
                        //           boxShadow: const [
                        //             BoxShadow(
                        //               color: Colors.black26,
                        //               blurRadius: 6,
                        //             ),
                        //           ],
                        //         ),
                        //         child: Row(
                        //           mainAxisSize: MainAxisSize.min,
                        //           children: const [
                        //             Text(
                        //               "Need Help?",
                        //               style: TextStyle(color: Colors.white),
                        //             ),
                        //             SizedBox(width: 8),
                        //             CircleAvatar(
                        //               radius: 16,
                        //               child: Icon(Icons.smart_toy, size: 18),
                        //             ),
                        //           ],
                        //         ),
                        //       ),
                        //     ),
                        //   ),
                        // ),
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
              InkWell(
                onTap: () {
                  FirebaseCrashlytics.instance.crash();
                },
                child: Text(
                  LanguageService.getTranslated(
                      context, 'usermanagement_dash_overview'),
                  style: typography.H5_Regular,
                ),
              ),
              SizedBox(height: CustomSpacing.six),
              !showTotalCorporates
                  ? SizedBox()
                  : OverviewCardHorizontal(
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
                  : OverviewCardHorizontal(
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
                  ? OverviewCardHorizontal(
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
                      ? OverviewCardHorizontal(
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
              OverviewCardHorizontal(
                title: LanguageService.getTranslated(
                    context, 'usermanagement_dash_connection_request'),
                amount:
                    dashboardProvider.dashboardModel?.requests?.toString() ??
                        '0',
                icon: 'assets/images/connection_request_people.svg',
                bottomWidget: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
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

              showAllUsers
                  ? SizedBox()
                  : Consumer2<UserProfileProvider, ConfigurationProvider>(
                      builder: (context, userProfileProvider, provider, child) {
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
                      : const CompanyOnboardingStatsCard(),
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
                      : const UserOnboardingStatsCard(),
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
}
