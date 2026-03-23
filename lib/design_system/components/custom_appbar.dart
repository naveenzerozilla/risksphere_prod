import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:RiskSphere/design_system/components/profile_image_widget.dart';
import 'package:RiskSphere/providers/auth_provider.dart';
import 'package:RiskSphere/screens/userManagement/connections_screen.dart';
import 'package:RiskSphere/screens/userManagement/user_profile.dart';
import 'package:provider/provider.dart';

import '../../providers/dashboard_provider.dart';
import '../../providers/drawer_selection_provider.dart';
import '../../providers/news_feed_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../screens/listings/news_feed_screen.dart';
import '../../service/shared_preference_service.dart';
import '../../utils/global_imports.dart';
import '../primitives/custom_typography.dart';
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
  bool INTERNAL = false;
  bool isLoggingOut = false;
  bool isPgAdmin = false;
  bool isAdmin = false;
  bool showTotalCorporates = false;
  bool showAllUsers = false;
  bool showConnectionRequests = false;
  bool showCompanyOnboardingStats = false;
  bool showUserOnboardingStats = false;
  bool showVerificationRequests = false;
  bool _initialRoleApiCalled = false;

  @override
  void initState() {
    super.initState();

    // Run both async in microtask (after init)
    Future.microtask(() async {
      await Future.wait([
        _getData(),
        _setClaims(),
      ]);

      if (mounted) setState(() {});
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

    showTotalCorporates = prefsFutures[0] ?? false;
    showAllUsers = prefsFutures[1] ?? false;
    showConnectionRequests = prefsFutures[2] ?? false;
    showCompanyOnboardingStats = prefsFutures[3] ?? false;
    showUserOnboardingStats = prefsFutures[4] ?? false;

    showVerificationRequests =
        (prefsFutures[5] ?? false) || (prefsFutures[6] ?? false);

    isPgAdmin = prefsFutures[9] ?? false;
    isAdmin = prefsFutures[10] ?? false;
    isSuperAdmin = prefsFutures[11] ?? false;
    isIndivudual = prefsFutures[12] ?? false;

    hasAnyPlan = prefsFutures[13] ?? false;
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

    // print("geoCodingStatus: $geoCodingStatus");
    // print("userLicenseStatus: $userLicenseStatus");
    // print("hazardLicenseStatus: $hazardLicenseStatus");
    // print("userCount: $userCount");
    // print("locationleft: $trailLocation");

    setState(() {
      hasAnyPlan = hasAnyPlans ?? false;
      hasLicenseStatus = userLicenseStatus ?? "1";
      hasGeocodingStatus = geoCodingStatus ?? "1";
      hasHazardLicenseStatus = hazardLicenseStatus ?? "1";
      getTrailUserCount = userCount ?? "1";
      getTrailLocation = trailLocation ?? "1";
    });
  }

  String? selectedRole;

  String _getInitials(String? firstName, String? lastName) {
    if ((firstName == null || firstName.isEmpty) &&
        (lastName == null || lastName.isEmpty)) return '';
    String firstInitial =
        firstName?.isNotEmpty == true ? firstName![0].toUpperCase() : '';
    String lastInitial =
        lastName?.isNotEmpty == true ? lastName![0].toUpperCase() : '';
    return '$firstInitial$lastInitial';
  }

  bool isLoadingRoleSwitch = false;

  @override
  Widget build(BuildContext context) {
    var typography = CustomTypography(context);

    return Consumer2<DashboardProvider, UserProfileProvider>(
        builder: (context, dashboardProvider, userProfileProvider, child) {
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
            (userProfileProvider.userData.role == null ||
                    userProfileProvider.userData.role!.isEmpty)
                ? const SizedBox.shrink() // or Container()
                : (userProfileProvider.userData.role![0].name
                                .toString()
                                .toLowerCase() ==
                            "admin" &&
                        (isSuperAdmin || isPgAdmin || isAdmin))
                    ? const SizedBox.shrink()
                    : Center(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton2<String>(
                            customButton: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border:
                                    Border.all(color: Colors.white30, width: 1),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.switch_account,
                                      color: Colors.grey, size: 20),
                                  SizedBox(width: 4),
                                  Icon(Icons.arrow_drop_down,
                                      color: Colors.grey, size: 18),
                                ],
                              ),
                            ),
                            items: userProfileProvider.userData.role!
                                .map<DropdownMenuItem<String>>((role) {
                              return DropdownMenuItem<String>(
                                value: role.name.toString(),
                                child: Text(
                                  role.name.toString(),
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: Colors.grey.shade400),
                                ),
                              );
                            }).toList(),
                            onChanged: (newValue) async {
                              if (newValue == null) return;
                              setState(() {
                                isLoadingRoleSwitch = true;
                              });
                              try {
                                final selectedRoleObj = userProfileProvider
                                    .userData.role!
                                    .firstWhere((role) =>
                                        role.name.toString() == newValue);

                                final payload = {
                                  "user_id":
                                      userProfileProvider.userData.userId,
                                  "last_selected_role": {
                                    "role": selectedRoleObj.id,
                                    "name": selectedRoleObj.name
                                  }
                                };

                                await userProfileProvider.signInRoleBasedSwitch(
                                    context, payload);
                              } finally {
                                setState(() {
                                  isLoadingRoleSwitch = false;
                                });
                              }
                            },
                            dropdownStyleData: DropdownStyleData(
                              width: 200,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 6, horizontal: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.black26,
                                border:
                                    Border.all(color: Colors.grey, width: 1),
                              ),
                              offset: const Offset(0, 0),
                            ),
                            menuItemStyleData: MenuItemStyleData(
                              customHeights: List<double>.filled(
                                  userProfileProvider.userData.role!.length,
                                  48),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                            ),
                          ),
                        ),
                      ),
            SizedBox(width: 5),
            Consumer<AuthNotifier>(
              builder: (context, authNotifier, child) {
                return InkWell(
                  onTap: () {
                    if (widget.canNavigateToNewsFeed ?? true) {
                      Provider.of<DrawerSelectionProvider>(context,
                              listen: false)
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
                              final count = provider.activityHits;
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
                                child: Container(),
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
    });
  }
}
