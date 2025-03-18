import 'dart:developer';

import 'package:country_pickers/country.dart';
import 'package:country_pickers/country_picker_dropdown.dart';
import 'package:country_pickers/utils/utils.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:RiskSphare/design_system/components/profile_image_widget.dart';
import 'package:RiskSphare/design_system/primitives/app_colors.dart';
import 'package:RiskSphare/providers/auth_provider.dart';
import 'package:RiskSphare/screens/onboarding/splash_screen.dart';
import 'package:RiskSphare/screens/processMonitoringScreen/process_monitoring_system.dart';
import 'package:RiskSphare/screens/userManagement/connections_screen.dart';
import 'package:RiskSphare/screens/userManagement/user_profile.dart';
import 'package:provider/provider.dart';

import '../../providers/drawer_selection_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../screens/listings/hazard_proto.dart';
import '../../screens/listings/news_feed_screen.dart';
import '../primitives/custom_typography.dart';
import '../primitives/utilities/custom_spacing.dart';
import 'profile_dropdown.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
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
  Size get preferredSize => Size.fromHeight(70);



  @override
  Widget build(BuildContext context) {
    var typography =
        CustomTypography(context); // Use context to initialize typography

    return Container(
      margin: EdgeInsets.fromLTRB(margin, 8, margin, 8),
      padding: EdgeInsets.fromLTRB(0, 1, 0, 1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
      ),
      child: AppBar(
        toolbarHeight: 100,
        backgroundColor: Colors.transparent,
        titleSpacing: 0,
        title: isExpanded
            ? Container(
                //padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    hintStyle:
                        typography.Subtitle1, // Use the typography instance
                    border: InputBorder.none,
                  ),
                ),
              )
            : GestureDetector(
                onTap: () {
                  //onExpandPressed(!isExpanded);
                },
                child:
                Container(

                  padding: EdgeInsets.all(8),
                  child: SvgPicture.asset(
                    'assets/images/logoHalf.svg',
                    width: 28,
                    height: 28,
                  ),
                ),
              ),
        actions: <Widget>[
          /*GestureDetector(
            child: Icon(Icons.search, size: 28, color: Colors.grey),
            onTap: onSearchPressed,
          ),*/
          SizedBox(
            width: CustomSpacing.two,
          ),
          Consumer<AuthNotifier>(builder: (context, authNotifier, child) {
            return InkWell(
              onTap: () {
                /* SnackBar snackBar = SnackBar(
                  content: Text('Coming Soon!'),
                  duration: Duration(seconds: 2),
                );*/
                /*ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Coming Soon!',
                      style: typography.Body1.copyWith(color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.black
                          : Colors.white), // Use the typography instance
                    ),
                  ),
                );*/
                if(canNavigateToNewsFeed??true) {
                  Provider.of<DrawerSelectionProvider>(context, listen: false)
                      .setSelectedItem("news");
                  Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => NewsFeedScreen()));
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
                      BlendMode.srcIn, // Blend mode to apply the color
                    ),
                  ),
                  if (showNotificationDot)
                    Positioned(
                      top: -5,
                      right: -3,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
          SizedBox(
            width: CustomSpacing.two,
          ),
          IconButton(
            padding: EdgeInsets.zero,
            tooltip: 'Connections',
            icon: Icon(Icons.people_alt_outlined),
            onPressed: !(canNavigateToConnections ?? true)
                ? null
                : () async {
                    FirebaseAuth auth = FirebaseAuth.instance;
                    String uid = auth.currentUser!.uid;
                    IdTokenResult token =
                        await auth.currentUser!.getIdTokenResult();
                    Map<String, dynamic>? claims = token.claims ?? {};
                    log(claims.toString());
                    log(auth.currentUser.toString());
                    String name = claims['name'] ?? ''; //name of the user
                    //Provider.of<DrawerSelectionProvider>(context, listen: false).setSelectedItem('user_management');
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ConnectionsScreen(
                          userId: uid,
                          userName: name,
                          selectedTabIndex: 0,
                        ),
                      ),
                    );
                  },
          ),
          /*SizedBox(
            width: CustomSpacing.four,
          ),
          CountryPickerDropdown(
            initialValue: _getInitialCountry(context),
            itemBuilder: (Country country) {
              return CircleAvatar(
                radius: 16.0,
                backgroundImage: AssetImage(
                  CountryPickerUtils.getFlagImageAssetPath(country.isoCode),
                  package: 'country_pickers',
                ),
              );
            },
            itemFilter: (Country country) {
              // Only include countries with these ISO codes
              return ['US', 'ES', 'FR', 'JP', 'CN'].contains(country.isoCode);
            },
            icon: SizedBox(),
            onValuePicked: (Country country) {
              switch (country.isoCode) {
                case 'US':
                  context.setLocale(Locale('en'));
                  break;
                case 'ES':
                  context.setLocale(Locale('es'));
                  break;
                case 'FR':
                  context.setLocale(Locale('fr'));
                  break;
                case 'JP':
                  context.setLocale(Locale('ja'));
                  break;
                case 'CN':
                  context.setLocale(Locale('zh'));
                  break;
              }
            },
          ),*/
          VerticalDivider(
            thickness: 1,
            width: 20,
            indent: 12,
            endIndent: 10,
          ),
          showDropdown
              ? Center(
                  child: ProfileMenu(),
                )
              : Center(
                  child: InkWell(
                    onTap: stopNavigateToProfile!
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => ProfileScreen()),
                            );
                          },
                    child: Consumer<UserProfileProvider>(
                      builder: (context, userProfile, child) {
                        final trialStatus = userProfile.trialInfo['status'] ?? '';

                        if (trialStatus.isEmpty) {
                          // Show normal profile icon if no trial period
                          return ProfileImageWidget();
                        }

                        return Stack(
                          clipBehavior: Clip.none,  // Allow overlap outside the container
                          children: [
                            Container(
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.3,
                              ),
                              padding: EdgeInsets.fromLTRB(12, 4, 32, 4),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: trialStatus.contains('Trial')
                                      ? (AppColors.warning)
                                      : AppColors.warning,
                                  width: 1,
                                ),
                                color: trialStatus.contains('Trial')
                                    ? (AppColors.warning.withOpacity(0.1))
                                    : AppColors.warning.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                trialStatus,
                                maxLines: 2,
                                style: typography.BottomNavigationActiveLabel.copyWith(color: trialStatus.contains('Trial')
                                    ? (AppColors.warning)
                                    : AppColors.warning,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 10,
                                ),
                              ),
                            ),

                            // Profile image overlapping the container
                            Positioned(
                              right: -6,  // Overlap adjustment
                              top: -5,     // Slight elevation for better UI
                              child: ProfileImageWidget(),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
          SizedBox(width: 8),
        ],
      ),
    );
  }

  String _getInitialCountry(BuildContext context) {
    // ['US', 'ES', 'FR', 'JP', 'CN']
    if (context.locale == Locale('es')) return 'ES';
    if (context.locale == Locale('fr')) return 'FR';
    if (context.locale == Locale('ja')) return 'JP';
    if (context.locale == Locale('zh')) return 'CN';
    return 'US';
  }
}
