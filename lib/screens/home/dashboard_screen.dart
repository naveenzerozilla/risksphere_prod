import 'dart:convert';
import 'dart:developer';

import 'package:country_pickers/country.dart';
import 'package:country_pickers/country_pickers.dart';
import 'package:country_pickers/utils/utils.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:RiskSphare/design_system/components/custom_button.dart';
import 'package:RiskSphare/design_system/primitives/utilities/custom_spacing.dart';
import 'package:RiskSphare/models/dashboard_model.dart';
import 'package:RiskSphare/providers/connections_provider.dart';
import 'package:RiskSphare/providers/drawer_selection_provider.dart';
import 'package:RiskSphare/providers/theme_provider.dart';
import 'package:RiskSphare/providers/user_profile_provider.dart';
import 'package:RiskSphare/screens/home/widgets/subscription_cards.dart';
import 'package:RiskSphare/screens/listings/widgets/maintenance_widget.dart';
import 'package:mat_month_picker_dialog/mat_month_picker_dialog.dart';

// import 'package:mat_month_picker_dialog/mat_month_picker_dialog.dart';
import 'package:provider/provider.dart';

import '../../constants/enums.dart';
import '../../design_system/components/custom_appbar.dart';
import '../../design_system/components/custom_drawer.dart';
import '../../design_system/components/custom_month_year_picker.dart';
import '../../design_system/components/expandable_card_container.dart';
import '../../design_system/primitives/app_colors.dart';
import '../../design_system/primitives/custom_typography.dart';
import '../../providers/configuration_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../service/language_service.dart';
import '../../service/shared_preference_service.dart';
import '../listings/widgets/message_card.dart';
import '../userManagement/connections_screen.dart';
import '../userManagement/user_management.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // App Bar
  bool _isExpanded = false;
  bool _showNotificationDot = true;

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

  List<dynamic> vendorList = [];
  var subscriptions = {};
  String isMaintenance = "";

  @override
  void initState() {
    _setClaims();
    _getMaintainancePeriod();
    super.initState();
  }

  _setClaims() async {
    showTotalCorporates = await SharedPreferenceService.getClaimForSubfeature(
            SharedPreferenceService.DASTC) ??
        false;
    showAllUsers = await SharedPreferenceService.getClaimForSubfeature(
            SharedPreferenceService.DASTU) ??
        false;
    showConnectionRequests =
        await SharedPreferenceService.getClaimForSubfeature(
                SharedPreferenceService.DASCR) ??
            false;
    showCompanyOnboardingStats =
        await SharedPreferenceService.getClaimForSubfeature(
                SharedPreferenceService.DASCO) ??
            false;
    showUserOnboardingStats =
        await SharedPreferenceService.getClaimForSubfeature(
                SharedPreferenceService.DASUO) ??
            false;
    bool showCorporateVerificationRequests =
        await SharedPreferenceService.getClaimForSubfeature(
                SharedPreferenceService.CAMLL) ??
            false;
    bool showUserVerificationRequests =
        await SharedPreferenceService.getClaimForSubfeature(
                SharedPreferenceService.CAMVU) ??
            false;
    showVerificationRequests =
        showCorporateVerificationRequests || showUserVerificationRequests;
    await SharedPreferenceService.getClaimForSubfeature(
            SharedPreferenceService.DASVR) ??
        false;

    _getData();
    setState(() {});
  }

  _getData() {
    Provider.of<DashboardProvider>(context, listen: false)
        .getDashboardData(context);
    Provider.of<UserProfileProvider>(context, listen: false)
        .getAllUserData(context, "", "")
        .then((value) {
      Provider.of<UserProfileProvider>(context, listen: false).fetchTrialInfo();
    });

    final provider = Provider.of<ConfigurationProvider>(context, listen: false);
    Future.wait([
      provider.getConfiguration(
        accountId: null,
        subAccountId: null,
      ),
      provider.getVendors()
    ]).then((value) {
      var config = provider.configurations['result'] ?? {};
      subscriptions = config['subscribe'] ?? {};
      if (mounted) {
        WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
          setState(() {
            vendorList = provider.vendors['result'] ?? [];
          });
        });
      }
    });
  }

  Future<void> _handleRefresh() async {
    _getData();
  }

  _getMaintainancePeriod() async {
    isMaintenance =
        await SharedPreferenceService.getScheduleInProgress() ?? "false";
  }

  @override
  Widget build(BuildContext context) {
    var typography = CustomTypography(context);
    return SafeArea(
      child: Consumer<ThemeProvider>(builder: (context, themeProvider, child) {
        return Scaffold(
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
            child: Stack(
              children: [
                // Background image
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
                    final trialStatus = userProfile.trialInfo['status'] ?? '';

                    if (trialStatus.contains('Expired')) {
                      return Container(
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
                            SizedBox(height: CustomSpacing.four),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: MessageCard(
                                messageTextSpans: [
                                  TextSpan(
                                    text:
                                        'We hope you\'ve enjoyed your trial period! To continue accessing your account and keep your data safe, please upgrade before December 24, 2024. After this date, we will need to delete your data. Thank you for being with us!',
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
                                        // Handle subscription logic
                                        //Coming soon Snackbar
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text('Coming soon!',
                                                style:
                                                    typography.Body1.copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .surface,
                                                )),
                                          ),
                                        );
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
        );
      }),
    );
  }

  _homeScreenBody(CustomTypography typography) {
    return Consumer<DashboardProvider>(
        builder: (context, dashboardProvider, child) {
      return dashboardProvider.isLoading
          ? Column(
              children: [
                Expanded(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ],
            )
          : SingleChildScrollView(
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
                        child: MaintenanceUI(isMaintenance: isMaintenance),
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
                            icon:
                                'assets/images/total_corporates_list_check.svg',
                            bottomWidget: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                (dashboardProvider.dashboardModel?.signups
                                                ?.current?.csignup ??
                                            0) >
                                        (dashboardProvider.dashboardModel
                                                ?.signups?.past?.csignup ??
                                            0)
                                    ? Icon(Icons.trending_up,
                                        color: Colors.green)
                                    : Icon(Icons.trending_down,
                                        color: Colors.red),
                                SizedBox(width: CustomSpacing.two),
                                Flexible(
                                  child: Text(
                                    _getTotalCorporatePercentage(
                                        dashboardProvider),
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
                                (dashboardProvider.dashboardModel?.signups
                                                ?.current?.signup ??
                                            0) >
                                        (dashboardProvider.dashboardModel
                                                ?.signups?.past?.signup ??
                                            0)
                                    ? Icon(Icons.trending_up,
                                        color: Colors.green)
                                    : Icon(Icons.trending_down,
                                        color: Colors.red),
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
                    !showVerificationRequests
                        ? SizedBox()
                        : _overviewCardHorizontal(
                            title: LanguageService.getTranslated(context,
                                'usermanagement_dash_verification_req'),
                            amount: ((dashboardProvider.dashboardModel
                                                ?.verificationCount ??
                                            0) +
                                        (dashboardProvider.dashboardModel
                                                ?.companyUserLeadCount ??
                                            0))
                                    .toString() ??
                                '0',
                            icon: 'assets/images/verification_req_checks.svg',
                            bottomWidget: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                CustomButton(
                                  type: ButtonType.outlined,
                                  onPressed: () {
                                    //Navigate to user management, 1st tab, verification requests from dropdown and 2nd tab users
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
                                          initialScreen: Screens.corporateAdd,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Add User',
                                        style: typography.Body1,
                                      ),
                                      SizedBox(width: CustomSpacing.two),
                                      Icon(
                                        Icons.person_add_alt_1,
                                        size: 18,
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 10),
                                CustomButton(
                                  type: ButtonType.outlined,
                                  onPressed: () {
                                    //Navigate to user management, 1st tab, verification requests from dropdown and 2nd tab users
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
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'See All',
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
                    !showConnectionRequests
                        ? SizedBox()
                        : SizedBox(width: CustomSpacing.four),
                    _overviewCardHorizontal(
                      title: LanguageService.getTranslated(
                          context, 'usermanagement_dash_connection_request'),
                      amount: dashboardProvider.dashboardModel?.requests
                              ?.toString() ??
                          '0',
                      icon: 'assets/images/connection_request_people.svg',
                      bottomWidget: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          //reduce border radius
                          CustomButton(
                            type: ButtonType.outlined,
                            onPressed: () async {
                              FirebaseAuth auth = FirebaseAuth.instance;
                              String uid = auth.currentUser!.uid;
                              IdTokenResult token =
                                  await auth.currentUser!.getIdTokenResult();
                              Map<String, dynamic>? claims = token.claims ?? {};
                              log(claims.toString());
                              log(auth.currentUser.toString());
                              String name =
                                  claims['name'] ?? ''; //name of the user
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
                    SizedBox(
                      height: CustomSpacing.one,
                    ),
                    Text(
                      "My Subscriptions",
                      style: typography.H5_Regular,
                    ),
                    SizedBox(
                      height: CustomSpacing.two,
                    ),
                    _subscriptionBody(typography),
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
                                expandedChild:
                                    _expandedCompanyOnboardingStatsWidget(
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
                                expandedChild:
                                    _expandedUserOnboardingStatsWidget(
                                        dashboardProvider),
                              ),
                    SizedBox(height: CustomSpacing.eight),
                  ],
                ),
              ),
            );
    });
  }

  Widget _subscriptionBody(CustomTypography typography) {
    int itemCount = 0;
    debugPrint('Subscription Keys: ${subscriptions.keys.toList()}');

    return Consumer<ConfigurationProvider>(builder: (context, provider, child) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        // Counter for valid items

        children: subscriptions.keys.map((key) {
          final parts = key.split('_');
          if (parts.length != 2) {
            debugPrint('Invalid subscription key format: $key');
            return SizedBox.shrink();
          }

          final vendorId = parts[0];
          final hazardName = parts[1];

          final vendor = vendorList.firstWhere(
            (vendor) => vendor['vendor_id'] == vendorId,
            orElse: () {
              debugPrint('Vendor not found for ID: $vendorId');
              return null;
            },
          );

          if (vendor == null) return SizedBox.shrink();

          final hazardCommercials = vendor['hazard_commercials'] as List?;
          final hazard = hazardCommercials?.firstWhere(
            (commercial) => commercial['hazard_name'] == hazardName,
            orElse: () {
              debugPrint(
                  'Hazard not found for name: $hazardName in Vendor ID: $vendorId');
              return null;
            },
          );

          if (hazard == null) return SizedBox.shrink();

          // If we reach this point, the item is valid
          itemCount++;

          final subscription = subscriptions[key];
          final vendorName = vendor['vendor_name_label'] ?? '';
          final vendorImage =
              vendor['display_image_url'] ?? 'assets/images/default_vendor.png';
          final hazardLabel = hazard['hazard_name_label'] ?? 'Unknown Hazard';
          final description = subscription['description'] ?? '';

          var config = provider.configurations['result'] ?? {};
          var mainId = config['id'] ?? '';
          var level = config['level'] ?? '';

          return Column(
            children: [
              SubscriptionCard(
                title: '$hazardLabel ($vendorName)',
                description: description.isNotEmpty ? description : vendorName,
                iconPath: vendorImage,
                isSubscribed: subscription['is_subscribed'] == true ||
                    subscription['is_subscribed'] == 'true',
                onSubscribe: () {
                  print('Subscribing to $key');
                  print('Main ID: $mainId');
                  print('Level: $level');
                  print('Subscription: ${subscription['is_subscribed']}');
                  _updateSubscription(
                      key, subscription['is_subscribed'], mainId, level);
                },
              ),
              SizedBox(height: CustomSpacing.one),
            ],
          );
        }).toList(),

        // debugPrint('Total valid items: $itemCount'); // Print the count

        // children: subscriptions.keys.map((key) {
        //   // Split the subscription key into vendor_id and hazard_name
        //   final parts = key.split('_');
        //   if (parts.length != 2) {
        //     debugPrint('Invalid subscription key format: $key');
        //     return SizedBox.shrink();
        //   }
        //
        //   final vendorId = parts[0];
        //   final hazardName = parts[1];
        //
        //   // Find the vendor by vendor_id
        //   final vendor = vendorList.firstWhere(
        //     (vendor) => vendor['vendor_id'] == vendorId,
        //     orElse: () {
        //       debugPrint('Vendor not found for ID: $vendorId');
        //       return null;
        //     },
        //   );
        //
        //   if (vendor == null) return SizedBox.shrink();
        //
        //   // Find the hazard in the vendor's hazard_commercials by hazard_name
        //   final hazardCommercials = vendor['hazard_commercials'] as List?;
        //   final hazard = hazardCommercials?.firstWhere(
        //     (commercial) => commercial['hazard_name'] == hazardName,
        //     orElse: () {
        //       debugPrint(
        //           'Hazard not found for name: $hazardName in Vendor ID: $vendorId');
        //       return null;
        //     },
        //   );
        //
        //   if (hazard == null) return SizedBox.shrink();
        //
        //   // Extract subscription and hazard details
        //   final subscription = subscriptions[key];
        //   final vendorName = vendor['vendor_name_label'] ?? '';
        //   final vendorImage =
        //       vendor['display_image_url'] ?? 'assets/images/default_vendor.png';
        //   final hazardLabel = hazard['hazard_name_label'] ?? 'Unknown Hazard';
        //   final description = subscription['description'] ?? '';
        //
        //   var config = provider.configurations['result'] ?? {};
        //   var mainId = config['id'] ?? '';
        //   var level = config['level'] ?? '';
        //
        //   return Column(
        //     children: [
        //       SubscriptionCard(
        //         title: '$hazardLabel ($vendorName)',
        //         description: description.isNotEmpty ? description : vendorName,
        //         iconPath: vendorImage,
        //         isSubscribed: subscription['is_subscribed'] == true ||
        //             subscription['is_subscribed'] == 'true',
        //         onSubscribe: () {
        //           print('Subscribing to $key');
        //           print('Main ID: $mainId');
        //           print('Level: $level');
        //           print('Subscription: ${subscription['is_subscribed']}');
        //           _updateSubscription(
        //               key, subscription['is_subscribed'], mainId, level);
        //         },
        //       ),
        //       SizedBox(height: CustomSpacing.one),
        //     ],
        //   );
        // }).toList(),
      );
    });
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
                    SizedBox(width: CustomSpacing.two),
                    SizedBox(height: CustomSpacing.two),
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

//   String _getPercentConversions(String percent) {
//     //double.parse(dashboardProvider.dashboardModel?.rolePercent??"0")>=0?"${dashboardProvider.dashboardModel?.rolePercent??0}% Increase":"${dashboardProvider.dashboardModel?.rolePercent??0}% Decrease",
//     String rolePercentText = percent ?? "0";
// // Remove '%' sign and any other non-digit characters
//     String rolePercentCleaned =
//         rolePercentText.replaceAll(RegExp(r'[^0-9-]'), '');
//     if (rolePercentCleaned.runtimeType != String) {
//       rolePercentCleaned = rolePercentCleaned.toString();
//     }
//     if (rolePercentCleaned.isEmpty) {
//       rolePercentCleaned = "0";
//     }
//     print("rolePercentCleaned: $rolePercentCleaned");
//     double rolePercent = double.parse(rolePercentCleaned);
//
//     String changeText;
//     if (rolePercent < 0) {
//       rolePercent = -rolePercent; // Make it positive
//       changeText =
//           "${rolePercent.toStringAsFixed(0)}% ${LanguageService.getTranslated(context, 'usermanagement_dash_decrease_cap')}";
//     } else {
//       changeText =
//           "${rolePercent.toStringAsFixed(0)}% ${LanguageService.getTranslated(context, 'usermanagement_dash_increase_cap')}";
//     }
//
//     print(changeText);
//     return changeText;
//   }

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

  void _updateSubscription(
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

    // showDialog(
    //   context: context,
    //   barrierDismissible: false,
    //   builder: (context) {
    //     final provider =
    //         Provider.of<ConfigurationProvider>(context, listen: false);
    //     bool isLoading = false;
    //     bool isLoading1 = false;
    //
    //     return StatefulBuilder(
    //       builder: (context, setState) {
    //         return AlertDialog(
    //           title: Row(
    //             children: [
    //               Container(
    //                 width: MediaQuery.of(context).size.width / 2,
    //                 child: Text(
    //                   'Do you want to apply this change globally?',
    //                   maxLines: 2,
    //                 ),
    //               ),
    //               IconButton(
    //                   onPressed: () {
    //                     Navigator.pop(context);
    //                   },
    //                   icon: Icon(Icons.close))
    //             ],
    //           ),
    //           actions: [
    //             TextButton(
    //               onPressed: provider.isLoading
    //                   ? null
    //                   : () async {
    //                       setState(() {
    //                         isLoading1 = true;
    //                       });
    //
    //                       String key = 'subscribe.$vendorId.is_subscribed';
    //
    //                       await provider.updateConfiguration(context, mainId,
    //                           key, level, !isSubscribed, "false");
    //
    //                       setState(() {
    //                         isLoading1 = false;
    //                       });
    //
    //                       if (!provider.isLoading) Navigator.pop(context);
    //                       _getData();
    //                     },
    //               style: TextButton.styleFrom(
    //                 side: BorderSide(color: AppColors.primaryMain, width: 1.5),
    //                 // Border color and width
    //                 shape: RoundedRectangleBorder(
    //                   borderRadius:
    //                       BorderRadius.circular(8), // Adjust border radius
    //                 ),
    //               ),
    //               child: Text(
    //                 'No',
    //                 style:
    //                     typography.Body1.copyWith(color: AppColors.primaryMain),
    //               ),
    //             ),
    //             SizedBox(width: 10),
    //             TextButton(
    //               onPressed: provider.isLoading
    //                   ? null
    //                   : () async {
    //                       setState(() {
    //                         isLoading = true;
    //                       });
    //
    //                       String key = 'subscribe.$vendorId.is_subscribed';
    //
    //                       await provider.updateConfiguration(context, mainId,
    //                           key, level, !isSubscribed, "true");
    //
    //                       setState(() {
    //                         isLoading = false;
    //                       });
    //
    //                       if (!provider.isLoading) Navigator.pop(context);
    //                       _getData();
    //                     },
    //               style: TextButton.styleFrom(
    //                 backgroundColor: AppColors.primaryMain,
    //                 // Button background color
    //                 side: BorderSide(color: AppColors.primaryMain, width: 2),
    //                 // Border color
    //                 shape: RoundedRectangleBorder(
    //                   borderRadius:
    //                       BorderRadius.circular(8), // Optional: rounded corners
    //                 ),
    //                 padding: EdgeInsets.symmetric(
    //                     vertical: 12, horizontal: 24), // Adjust padding
    //               ),
    //               child: provider.isLoading
    //                   ? SizedBox(
    //                       height: 24,
    //                       width: 24,
    //                       child: CircularProgressIndicator(
    //                         color:
    //                             Colors.white, // Adjust loader color if needed
    //                         strokeWidth: 3,
    //                       ),
    //                     )
    //                   : Text(
    //                       'Yes',
    //                       style: typography.Body1.copyWith(
    //                           color: Colors.black), // Adjust text color
    //                     ),
    //             ),
    //
    //             // TextButton(
    //             //   onPressed: provider.isLoading
    //             //       ? null
    //             //       : () async {
    //             //           setState(() {
    //             //             isLoading = true;
    //             //           });
    //             //
    //             //           String key = 'subscribe.$vendorId.is_subscribed';
    //             //
    //             //           await provider.updateConfiguration(
    //             //             context,
    //             //             mainId,
    //             //             key,
    //             //             level,
    //             //             !isSubscribed,
    //             //           );
    //             //
    //             //           setState(() {
    //             //             isLoading = false;
    //             //           });
    //             //
    //             //           if (!provider.isLoading) Navigator.pop(context);
    //             //           _getData();
    //             //         },
    //             //   child: provider.isLoading
    //             //       ? Row(
    //             //           mainAxisSize: MainAxisSize.min,
    //             //           children: [
    //             //             SizedBox(
    //             //                 height: 38,
    //             //                 width: 38,
    //             //                 child: CircularProgressIndicator()),
    //             //           ],
    //             //         )
    //             //       : Text(
    //             //           'Yes',
    //             //           style: typography.Body1.copyWith(
    //             //               color: AppColors.primaryMain),
    //             //         ),
    //             // ),
    //           ],
    //         );
    //       },
    //     );
    //   },
    // );
  }
}
