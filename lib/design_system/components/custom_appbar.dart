import 'dart:developer';

import 'package:country_pickers/country.dart';
import 'package:country_pickers/country_picker_dropdown.dart';
import 'package:country_pickers/utils/utils.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:RiskSphere/design_system/components/profile_image_widget.dart';
import 'package:RiskSphere/design_system/primitives/app_colors.dart';
import 'package:RiskSphere/providers/auth_provider.dart';
import 'package:RiskSphere/screens/onboarding/splash_screen.dart';
import 'package:RiskSphere/screens/processMonitoringScreen/process_monitoring_system.dart';
import 'package:RiskSphere/screens/userManagement/connections_screen.dart';
import 'package:RiskSphere/screens/userManagement/user_profile.dart';
import 'package:provider/provider.dart';

import '../../providers/drawer_selection_provider.dart';
import '../../providers/news_feed_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../screens/listings/hazard_proto.dart';
import '../../screens/listings/news_feed_screen.dart';
import '../../service/shared_preference_service.dart';
import '../primitives/custom_typography.dart';
import '../primitives/utilities/custom_spacing.dart';
import 'profile_dropdown.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final bool? hasAnyPlan;
  final bool isExpanded;
  final bool showNotificationDot;
  final Function(bool) onExpandPressed;
  final Function() onSearchPressed;
  final bool showDropdown;
  final double margin;
  final bool? stopNavigateToProfile;
  final bool? canNavigateToConnections;
  final bool? canNavigateToNewsFeed;

  const CustomAppBar({
    Key? key,
    this.hasAnyPlan,
    required this.isExpanded,
    required this.showNotificationDot,
    required this.onExpandPressed,
    required this.onSearchPressed,
    this.showDropdown = false,
    this.margin = 16.0,
    this.stopNavigateToProfile = false,
    this.canNavigateToConnections = true,
    this.canNavigateToNewsFeed = true,
  }) : super(key: key);

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();

  @override
  Size get preferredSize => Size.fromHeight(70);
}

class _CustomAppBarState extends State<CustomAppBar> {
  int _currentIndex = 0;
  bool hasAnyPlan = false;
  String hasLicenseStatus = "1";
  String hasGeocodingStatus = "1";
  String hasHazardLicenseStatus = "1";
  String getTrailUserCount = "0";
  String getTrailLocation = "0";
  bool isSuperAdmin = false;
  bool isIndivudual = false;
  bool isLoggingOut = false;
  bool isPgAdmin = false;
  bool isAdmin = false;
  bool showTotalCorporates = false;
  bool showAllUsers = false;
  bool showConnectionRequests = false;
  bool showCompanyOnboardingStats = false;
  bool showUserOnboardingStats = false;
  bool showVerificationRequests = false;

  @override
  void initState() {
    super.initState();
    _getData();
    _setClaims();
  }

  Future<void> _setClaims() async {
    final results = await Future.wait([
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
    ]);
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

    print(results.toString());
    print(isIndivudual);

    showTotalCorporates = results[0] ?? false;
    showAllUsers = results[1] ?? false;
    showConnectionRequests = results[2] ?? false;
    showCompanyOnboardingStats = results[3] ?? false;
    showUserOnboardingStats = results[4] ?? false;

    bool showCorporateVerificationRequests = results[5] ?? false;
    bool showUserVerificationRequests = results[6] ?? false;

    showVerificationRequests =
        showCorporateVerificationRequests || showUserVerificationRequests;

    setState(() {});
  }

  Future<void> _getData() async {
    bool? hasAnyPlans = await SharedPreferenceService.getHasAnyPlan();
    String? geoCodingStatus =
        await SharedPreferenceService.getGeocodingLicense();
    String? userLicenseStatus = await SharedPreferenceService.getUserLicense();
    String? userCount = await SharedPreferenceService.getTrialUser();
    String? trailLocation = await SharedPreferenceService.getTrailLocation();
    String? hazardLicenseStatus =
        await SharedPreferenceService.getHazardLicense();

    print("geoCodingStatus: $geoCodingStatus");
    print("userLicenseStatus: $userLicenseStatus");
    print("hazardLicenseStatus: $hazardLicenseStatus");
    print("userCount: $userCount");
    print("locationleft: $trailLocation");

    setState(() {
      hasAnyPlan = hasAnyPlans ?? false;
      hasLicenseStatus = userLicenseStatus ?? "1";
      hasGeocodingStatus = geoCodingStatus ?? "1";
      hasHazardLicenseStatus = hazardLicenseStatus ?? "1";
      getTrailUserCount = userCount ?? "1";
      getTrailLocation = trailLocation ?? "1";
    });
  }

  @override
  Widget build(BuildContext context) {
    var typography = CustomTypography(context);

    return Container(
      margin: EdgeInsets.fromLTRB(widget.margin, 8, widget.margin, 8),
      padding: const EdgeInsets.fromLTRB(0, 1, 0, 1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
      ),
      child: AppBar(
        toolbarHeight: 100,
        backgroundColor: Colors.transparent,
        titleSpacing: 0,
        title: widget.isExpanded
            ? TextField(
                decoration: InputDecoration(
                  hintText: 'Search...',
                  hintStyle: typography.Subtitle1,
                  border: InputBorder.none,
                ),
              )
            : GestureDetector(
                onTap: () {},
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: SvgPicture.asset(
                    'assets/images/logoHalf.svg',
                    width: 28,
                    height: 28,
                  ),
                ),
              ),
        actions: <Widget>[
          const SizedBox(width: 8),
          Consumer<AuthNotifier>(
            builder: (context, authNotifier, child) {
              return InkWell(
                onTap: () {
                  if (widget.canNavigateToNewsFeed ?? true) {
                    Provider.of<DrawerSelectionProvider>(context, listen: false)
                        .setSelectedItem("news");
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => NewsFeedScreen(),
                    ));
                  }
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    SvgPicture.asset(
                      'assets/images/notificationIcon.svg',
                      height: 26,
                      colorFilter: ColorFilter.mode(
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                        BlendMode.srcIn,
                      ),
                    ),
                    if (widget.showNotificationDot)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Consumer<NewsFeedProvider>(
                          builder: (context, provider, child) {
                            final count = provider.newsFeed?.length ?? 0;
                            if (count == 0) return SizedBox.shrink();
                            return Container(
                              width: 18,
                              height: 18,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.red,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                count > 99 ? '99+' : count.toString(),
                                textAlign: TextAlign.center,
                                style: typography.Caption.copyWith(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          IconButton(
            padding: EdgeInsets.zero,
            tooltip: 'Connections',
            icon: const Icon(Icons.people_alt_outlined),
            onPressed: !(widget.canNavigateToConnections ?? true)
                ? null
                : () async {
                    final auth = FirebaseAuth.instance;
                    final uid = auth.currentUser!.uid;
                    final token = await auth.currentUser!.getIdTokenResult();
                    final claims = token.claims ?? {};
                    final name = claims['name'] ?? '';
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => ConnectionsScreen(
                        userId: uid,
                        userName: name,
                        selectedTabIndex: 0,
                      ),
                    ));
                  },
          ),
          const VerticalDivider(
            thickness: 1,
            width: 15,
            indent: 12,
            endIndent: 10,
          ),
          widget.showDropdown
              ? Center(child: ProfileMenu())
              : Center(
                  child: InkWell(
                    onTap: widget.stopNavigateToProfile == true
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProfileScreen(),
                              ),
                            );
                          },
                    child: Consumer<UserProfileProvider>(
                      builder: (context, userProfile, child) {
                        final trialStatus =
                            userProfile.trialInfo['status'] ?? '';
                        bool isIndividual =
                            userProfile.userData.isIndividual ?? true;
                        if (trialStatus.isEmpty) {
                          return ProfileImageWidget();
                        }

                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              alignment: Alignment.centerLeft,
                              height: 30,
                              constraints: BoxConstraints(maxWidth: 30),
                              padding: EdgeInsets.fromLTRB(12, 4, 32, 4),
                              // decoration: BoxDecoration(
                              //   border: Border.all(
                              //     color: trialStatus.contains('Trial')
                              //         ? (AppColors.warning)
                              //         : AppColors.warning,
                              //     width: 1,
                              //   ),
                              //   color: trialStatus.contains('Trial')
                              //       ? (AppColors.warning.withOpacity(0.1))
                              //       : AppColors.warning.withOpacity(0.1),
                              //   borderRadius: BorderRadius.circular(20),
                              // ),
                              child: Container(),
                            // Container(
                            //   constraints: BoxConstraints(
                            //     maxWidth:
                            //         MediaQuery.of(context).size.width * 0.3,
                            //   ),
                            //   padding: EdgeInsets.fromLTRB(12, 4, 32, 4),
                            //   decoration: BoxDecoration(
                            //     border: Border.all(
                            //       color: trialStatus.contains('Trial')
                            //           ? AppColors.warning
                            //           : AppColors.warning,
                            //       width: 1,
                            //     ),
                            //     color: trialStatus.contains('Trial')
                            //         ? AppColors.warning.withOpacity(0.1)
                            //         : AppColors.warning.withOpacity(0.1),
                            //     borderRadius: BorderRadius.circular(20),
                            //   ),
                            //   child: TweenAnimationBuilder<int>(
                            //     key: ValueKey(_currentIndex),
                            //     tween: IntTween(begin: 0, end: 100),
                            //     duration: Duration(seconds: 6),
                            //     onEnd: () {
                            //       setState(() {
                            //         final items = [
                            //           trialStatus.isNotEmpty ? trialStatus : '',
                            //           !isIndividual
                            //               ? (getTrailUserCount != null &&
                            //                       getTrailUserCount != 'null'
                            //                   ? '$getTrailUserCount Users Left'
                            //                   : '')
                            //               : '',
                            //           (hasAnyPlan == true
                            //                   ? (hasGeocodingStatus != null &&
                            //                           hasGeocodingStatus !=
                            //                               'null'
                            //                       ? hasGeocodingStatus
                            //                       : '')
                            //                   : (getTrailLocation != null &&
                            //                           getTrailLocation != 'null'
                            //                       ? getTrailLocation
                            //                       : '')) +
                            //               ((hasAnyPlan == true ||
                            //                       (getTrailLocation != null &&
                            //                           getTrailLocation !=
                            //                               'null'))
                            //                   ? ' Locations Left'
                            //                   : ''),
                            //         ].where((item) => item.isNotEmpty).toList();
                            //         _currentIndex = (items.isEmpty
                            //             ? 0
                            //             : ((_currentIndex + 1) % items.length));
                            //       });
                            //     },
                            //     builder: (context, value, child) {
                            //       final items = [
                            //         if (trialStatus.isNotEmpty) trialStatus,
                            //         if (!isIndividual && getTrailUserCount != null && getTrailUserCount != 'null' && getTrailUserCount != '0')
                            //           '$getTrailUserCount Users Left',
                            //         if ((hasAnyPlan == true && hasGeocodingStatus != null && hasGeocodingStatus != 'null' && hasGeocodingStatus != '0') ||
                            //             (hasAnyPlan != true && getTrailLocation != null && getTrailLocation != 'null' && getTrailLocation != '0'))
                            //           ((hasAnyPlan == true
                            //               ? hasGeocodingStatus
                            //               : getTrailLocation) ?? '') +
                            //               ' Locations Left',
                            //       ].where((item) => item.isNotEmpty).toList();
                            //       // final items = [
                            //       //   trialStatus.isNotEmpty ? trialStatus : '',
                            //       //   !isIndividual
                            //       //       ? (getTrailUserCount != null &&
                            //       //               getTrailUserCount != 'null'
                            //       //           ? '$getTrailUserCount Users Left'
                            //       //           : '')
                            //       //       : '',
                            //       //   (hasAnyPlan == true
                            //       //           ? (hasGeocodingStatus != null &&
                            //       //                   hasGeocodingStatus != 'null'
                            //       //               ? hasGeocodingStatus
                            //       //               : '')
                            //       //           : (getTrailLocation != null &&
                            //       //                   getTrailLocation != 'null'
                            //       //               ? getTrailLocation
                            //       //               : '')) +
                            //       //       ((hasAnyPlan == true ||
                            //       //               (getTrailLocation != null &&
                            //       //                   getTrailLocation != 'null'))
                            //       //           ? ' Locations Left'
                            //       //           : ''),
                            //       // ].where((item) => item.isNotEmpty).toList();
                            //       return AnimatedSwitcher(
                            //         duration: const Duration(milliseconds: 300),
                            //         child: Text(
                            //           items.isNotEmpty
                            //               ? items[_currentIndex % items.length]
                            //               : '',
                            //           key: ValueKey(_currentIndex),
                            //           maxLines: 1,
                            //           style: typography
                            //               .BottomNavigationActiveLabel.copyWith(
                            //             color: trialStatus.contains('Trial')
                            //                 ? AppColors.warning
                            //                 : AppColors.warning,
                            //             fontWeight: FontWeight.w500,
                            //             fontSize: 10,
                            //           ),
                            //         ),
                            //       );
                            //     },
                            //   ),

                            ),
                            Positioned(
                              right: -6,
                              top: -5,
                              child: ProfileImageWidget(),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}
